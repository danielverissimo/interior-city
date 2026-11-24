-- Regras independentes do transporte NUI/Tunnel, testadas com adaptadores simulados.
function CreatePoliceArsenal(config, deps, initial)
    local state = initial
    local priceRevision = 0
    state.disabled=state.disabled or {}
    state.customItems=state.customItems or {}
    local busy, lastPurchase = {}, {}
    local catalog = {}
    for _, entry in ipairs(config.Items) do catalog[entry.id] = entry end
    for id,entry in pairs(state.customItems) do if not catalog[id] then catalog[id]=entry end end
    local service = {}
    local function integer(value, minimum, maximum)
        return type(value)=='number' and value==value and value%1==0 and value>=minimum and value<=maximum
    end
    local function clone(value)
        if type(value)~='table' then return value end
        local out={};for k,v in pairs(value) do out[k]=clone(v) end;return out
    end
    local function fail(message) return {ok=false,message=message} end
    local function context(player)
        local user=deps.user(player)
        if not user then return nil end
        return user, deps.owner(user), deps.police(user)
    end
    local function nearby(player)
        local pos=deps.position(player)
        if not pos then return false end
        local p=state.location
        if not p then return false end
        return (pos.x-p.x)^2+(pos.y-p.y)^2+(pos.z-p.z)^2 <= config.ServerDistance^2
    end
    local function price(id) return state.prices[id] or config.DefaultPrice end
    local function safeAudit(kind, data) pcall(deps.audit,kind,data) end
    local function entries()
        local result,seen={},{}
        for _,entry in ipairs(config.Items) do result[#result+1]=entry;seen[entry.id]=true end
        local custom={}
        for id,entry in pairs(catalog) do if not seen[id] then custom[#custom+1]=entry end end
        table.sort(custom,function(a,b) return a.name<b.name end)
        for _,entry in ipairs(custom) do result[#result+1]=entry end
        return result
    end
    function service.location() return clone(state.location) end
    function service.open(player)
        local user,owner,police=context(player)
        if not user or not (owner or police) then return fail('Acesso restrito a policiais.') end
        if not owner and not nearby(player) then return fail('Aproxime-se do arsenal.') end
        local items={}
        for _,entry in ipairs(entries()) do
            if not state.disabled[entry.id] and deps.exists(entry.id) then
                local item=clone(entry);item.price=price(item.id);items[#items+1]=item
            end
        end
        return {ok=true,items=items,canManage=owner,canPurchase=police and nearby(player),
            money=deps.money(user),location=clone(state.location),userId=user,priceRevision=priceRevision}
    end
    function service.purchase(player,payload)
        local user,_,police=context(player)
        if not user or not police then return fail('Somente policiais podem comprar equipamentos.') end
        if not nearby(player) then return fail('Aproxime-se do arsenal para comprar.') end
        if type(payload)~='table' or type(payload.id)~='string' then return fail('Compra invalida.') end
        local item=catalog[payload.id]
        if not item or state.disabled[item.id] or not deps.exists(item.id) then return fail('Equipamento indisponivel.') end
        local quantity=payload.quantity
        if not integer(quantity,1,item.maxQuantity) then return fail('Quantidade invalida.') end
        local unitPrice=price(item.id)
        if not integer(unitPrice,1,config.MaxPrice) then return fail('Preco indisponivel.') end
        if payload.expectedPrice~=unitPrice then return fail('O preco mudou. Atualize o catalogo antes de comprar.') end
        local total=unitPrice*quantity
        if total>config.MaxPurchaseTotal then return fail('Valor da compra acima do limite.') end
        if busy[user] then return fail('Aguarde a compra anterior.') end
        local now=deps.clock()
        if lastPurchase[user] and now-lastPurchase[user]<config.PurchaseCooldownMs then return fail('Aguarde um instante para comprar novamente.') end
        busy[user]=true
        lastPurchase[user]=now
        local paid=false
        local before=nil
        local ok,result=xpcall(function()
            local weight,maxWeight=deps.weight(user),deps.maxWeight(user)
            if weight+deps.itemWeight(item.id)*quantity>maxWeight then return fail('Sem espaco na mochila para esta quantidade.') end
            before=deps.count(user,item.id)
            if not deps.pay(user,total) then return fail('Dinheiro em maos insuficiente.') end
            paid=true
            -- Conta antes/depois evita estornar uma entrega que ocorreu antes de um erro de notificacao.
            pcall(deps.give,user,item.id,quantity)
            local after=deps.count(user,item.id)
            if after-before~=quantity then error('Entrega do inventario nao confirmada') end
            safeAudit('purchase',{user=user,item=item.id,quantity=quantity,unitPrice=unitPrice,total=total})
            return {ok=true,message='Compra concluida. Equipamento entregue na mochila.',money=deps.money(user)}
        end,debug.traceback)
        if not ok then
            local readOk,after=pcall(deps.count,user,item.id)
            if paid and readOk and before and after==before then
                local refundOk,refunded=pcall(deps.refund,user,total)
                safeAudit('refund',{user=user,item=item.id,total=total,confirmed=refundOk and refunded==true,error=tostring(result)})
                result=fail(refundOk and refunded==true and 'Entrega falhou. O valor foi devolvido.' or 'Falha no estorno. Avise a administracao para conferir o registro.')
            elseif paid and readOk and before and after-before==quantity then
                result={ok=true,message='Compra entregue na mochila.',money=deps.money(user)}
            elseif paid then
                -- Estado incerto: nao repetir nem estornar automaticamente e duplicar saldo/itens.
                safeAudit('review',{user=user,item=item.id,total=total,quantity=quantity,error=tostring(result)})
                result=fail('Compra em verificacao. Avise a administracao para conferir o registro.')
            else
                safeAudit('error',{user=user,item=item.id,error=tostring(result)})
                result=fail('Nao foi possivel concluir a compra.')
            end
        end
        busy[user]=nil
        return result
    end
    function service.setPrice(player,payload)
        local user,owner=context(player)
        if not user or not owner then return fail('Somente o cargo dono pode editar os valores.') end
        if type(payload)~='table' or not catalog[payload.id] or not integer(payload.price,1,config.MaxPrice) then
            return fail('Informe um preco inteiro entre R$ 1 e R$ 10.000.000.')
        end
        if payload.expectedPrice~=price(payload.id) then return fail('O preco foi alterado por outro administrador. Atualize o catalogo.') end
        local proposed=clone(state);proposed.prices[payload.id]=payload.price
        if not deps.persist(proposed) then return fail('Nao foi possivel salvar o preco. Tente novamente.') end
        local previous=price(payload.id);state=proposed
        priceRevision=priceRevision+1
        local revision=priceRevision
        safeAudit('price',{user=user,item=payload.id,before=previous,after=payload.price})
        return {ok=true,message='Preco salvo.',price=payload.price,priceRevision=revision}
    end
    function service.relocate(player)
        local user,owner=context(player)
        if not user or not owner then return fail('Somente o cargo dono pode mover o arsenal.') end
        -- A posicao vem do ped no servidor, nunca de coordenadas fornecidas pela NUI.
        local pos=deps.position(player)
        if not pos then return fail('Nao foi possivel identificar sua posicao.') end
        for _,key in ipairs({'x','y','z'}) do
            if type(pos[key])~='number' or pos[key]~=pos[key] or math.abs(pos[key])>20000 then return fail('Posicao invalida.') end
        end
        local proposed=clone(state);proposed.location={x=pos.x,y=pos.y,z=pos.z}
        if not deps.persist(proposed) then return fail('Nao foi possivel salvar a localizacao.') end
        local previous=state.location;state=proposed
        safeAudit('location',{user=user,before=previous,after=state.location})
        return {ok=true,message='Arsenal movido para sua posicao. O ponto anterior foi substituido.',location=clone(state.location)}
    end
    function service.clearLocation(player)
        local user,owner=context(player)
        if not user or not owner then return fail('Somente o cargo dono pode remover o ponto.') end
        local proposed=clone(state);proposed.location=false
        if not deps.persist(proposed) then return fail('Nao foi possivel remover a localizacao.') end
        local previous=state.location;state=proposed
        safeAudit('location_removed',{user=user,before=previous})
        return {ok=true,message='Ponto anterior removido. Use sua posicao atual para definir o novo.',location=false}
    end
    function service.management(player)
        local user,owner=context(player)
        if not user or not owner then return fail('Somente o cargo dono pode gerenciar os equipamentos.') end
        local active,candidates,seen={},{},{}
        for _,entry in ipairs(entries()) do
            if deps.exists(entry.id) then
                local row=clone(entry);row.price=price(entry.id);row.active=not state.disabled[entry.id]
                if row.active then active[#active+1]=row else candidates[#candidates+1]=row end
                seen[entry.id]=true
            end
        end
        for _,entry in ipairs(deps.availableItems and deps.availableItems() or {}) do
            if not seen[entry.id] then candidates[#candidates+1]=clone(entry);seen[entry.id]=true end
        end
        table.sort(candidates,function(a,b) return a.name<b.name end)
        return {ok=true,active=active,candidates=candidates}
    end
    function service.setItemEnabled(player,payload)
        local user,owner=context(player)
        if not user or not owner then return fail('Somente o cargo dono pode alterar o catalogo.') end
        if type(payload)~='table' or type(payload.id)~='string' or type(payload.enabled)~='boolean' then return fail('Equipamento invalido.') end
        local id=payload.id
        local item=catalog[id]
        if not item and payload.enabled then
            for _,entry in ipairs(deps.availableItems and deps.availableItems() or {}) do
                if entry.id==id then item=clone(entry);break end
            end
        end
        if not item or not deps.exists(id) then return fail('Escolha um item existente no inventario da base.') end
        local proposed=clone(state)
        if payload.enabled then
            proposed.disabled[id]=nil
            if not catalog[id] then proposed.customItems[id]=item end
        else proposed.disabled[id]=true end
        if not deps.persist(proposed) then return fail('Nao foi possivel salvar a alteracao do catalogo.') end
        state=proposed;catalog[id]=item
        safeAudit(payload.enabled and 'item_added' or 'item_removed',{user=user,item=id})
        return {ok=true,message=payload.enabled and 'Equipamento adicionado ao arsenal.' or 'Equipamento retirado do arsenal.'}
    end
    function service.clear(user) busy[user]=nil;lastPurchase[user]=nil end
    return service
end
