local I=ICAdmin
local A=I.Adapter
local actions={}
local function permit(ctx,key)
    if not I.allowed(ctx.userId,key) then I.fail('FORBIDDEN','Você não tem permissão para esta ação.') end
    ctx.permission=key
end
local function reason(p) return I.text(p.reason,500,true,'Motivo') end
local function client(ctx,id,action,data)
    local _,target=I.target(id,true);I.effect(ctx)
    TriggerClientEvent('ic_admin:clientAction',target,action,data or {})
    return {id=id,action=action}
end
local function selfAction(ctx,action,data)
    I.effect(ctx);TriggerClientEvent('ic_admin:clientAction',ctx.source,action,data or {});return {action=action}
end
local function at(source)
    local ped=GetPlayerPed(source)
    if ped==0 then I.fail('NO_PED','Personagem indisponível.') end
    local c=GetEntityCoords(ped);return {x=c.x,y=c.y,z=c.z}
end
function actions.wladd(ctx,p) local id=I.target(p.targetId,false);I.effect(ctx);I.vRP.setWhitelisted(id,true);return {id=id,whitelisted=true} end
function actions.wlrem(ctx,p) local id=I.target(p.targetId,false);reason(p);I.effect(ctx);I.vRP.setWhitelisted(id,false);return {id=id,whitelisted=false} end
function actions.ban(ctx,p) return A.setBan(ctx,I.target(p.targetId,false),true,reason(p)) end
function actions.unban(ctx,p) return A.setBan(ctx,I.target(p.targetId,false),false,reason(p)) end
function actions.kick(ctx,p)
    local id,target=I.target(p.targetId,true);local why=reason(p);I.effect(ctx);I.vRP.kick(target,why);return {id=id}
end
for _,action in ipairs({'god','kill','freeze','unfreeze'}) do
    actions[action]=function(ctx,p) local id=I.target(p.targetId,true);return client(ctx,id,action,{reason=p.reason}) end
end
function actions.godall(ctx)
    I.effect(ctx);for _,player in ipairs(I.onlinePlayers()) do TriggerClientEvent('ic_admin:clientAction',player.source,'god',{}) end
    return {count=#GetPlayers()}
end
function actions.send_dm(ctx,p)
    local id,target=I.target(p.targetId,true);local message=I.text(p.message,1500,true,'Mensagem');local seconds=I.int(p.durationSeconds or 8,1,300,'Duração')
    I.effect(ctx);TriggerClientEvent('ic_admin:notice',target,{message=message,duration=seconds,scope='private'});return {id=id}
end
function actions.send_adm(ctx,p)
    local message=I.text(p.message,1500,true,'Mensagem');local seconds=I.int(p.durationSeconds or 8,1,300,'Duração')
    I.effect(ctx);TriggerClientEvent('ic_admin:notice',-1,{message=message,duration=seconds,scope='general'});return {}
end
function actions.tpto(ctx,p)
    local id,target=I.target(p.targetId,true)
    I.effect(ctx);SetPlayerRoutingBucket(ctx.source,GetPlayerRoutingBucket(target))
    return selfAction(ctx,'teleport',{coords=at(target),bucket=GetPlayerRoutingBucket(target),targetId=id})
end
function actions.tptome(ctx,p)
    local id,target=I.target(p.targetId,true)
    I.effect(ctx);SetPlayerRoutingBucket(target,GetPlayerRoutingBucket(ctx.source))
    return client(ctx,id,'teleport',{coords=at(ctx.source),bucket=GetPlayerRoutingBucket(ctx.source)})
end
function actions.tpway(ctx) return selfAction(ctx,'tpway',{}) end
function actions.tpcds(ctx,p)
    local coords=p.coords
    if type(coords)=='string' then
        local x,y,z=coords:match('^%s*([%d.+-]+)%s*,%s*([%d.+-]+)%s*,%s*([%d.+-]+)%s*$');coords={x=tonumber(x),y=tonumber(y),z=tonumber(z)}
    end
    if type(coords)~='table' then I.fail('INVALID_COORDS','Informe X,Y,Z.') end
    local out={};for _,key in ipairs({'x','y','z'}) do local n=tonumber(coords[key]);if not n or n~=n or math.abs(n)>20000 then I.fail('INVALID_COORDS','Coordenadas inválidas.') end;out[key]=n end
    return selfAction(ctx,'teleport',{coords=out})
end
function actions.spawn_veh(ctx,p) return selfAction(ctx,'spawn_veh',{vehicle=A.validVehicle(p.vehicle)}) end
for _,action in ipairs({'fix','tuning','hash','dv'}) do actions[action]=function(ctx)return selfAction(ctx,action,{}) end end
function actions.give_veh(ctx,p)
    local id=I.target(p.targetId,true);local vehicle=A.validVehicle(p.vehicle);reason(p)
    return I.withLock('vehicle:'..id,function()I.effect(ctx);A.giveVehicle(id,vehicle);return {id=id,vehicle=vehicle} end)
end
function actions.rem_veh(ctx,p)
    local id=I.target(p.targetId,true);local vehicle=A.validVehicle(p.vehicle);reason(p)
    return I.withLock('vehicle:'..id,function()
        I.effect(ctx)
        local n=I.Store.update('DELETE FROM vrp_user_veiculos WHERE user_id=? AND veiculo=?',{id,vehicle})
        if n~=1 then I.fail('NOT_FOUND','Veículo não encontrado na garagem do jogador.') end
        return {id=id,vehicle=vehicle}
    end)
end
function actions.clear_inv(ctx,p)
    local id=I.target(p.targetId,true);reason(p)
    return I.withLock('inventory:'..id,function()
        local before=I.snapshot(id).inventory;I.effect(ctx);I.vRP.clearInventory(id)
        I.audit('clear_inv',ctx,id,{before=before,reason=p.reason});return {id=id}
    end)
end
function actions.clear_weapons(ctx,p)
    local id=I.target(p.targetId,true);reason(p)
    return I.withLock('inventory:'..id,function()
        local entries=I.vRP.getInventory(id) or {};local remove={}
        local catalog=A.itemCatalog()
        for _,entry in pairs(entries) do
            local def=catalog[entry.item] or {};local kind=tostring(def.type or ''):lower()
            if kind=='equip' or kind=='weapon' or kind=='recharge' or tostring(entry.item):match('^WEAPON_') then remove[entry.item]=(remove[entry.item] or 0)+(tonumber(entry.amount) or 0) end
        end
        I.effect(ctx)
        for item,amount in pairs(remove) do if I.vRP.tryGetInventoryItem(id,item,amount,false)~=true then I.fail('INVENTORY_CHANGED','Inventário mudou durante a operação. Confira o resultado.') end end
        client(ctx,id,'clear_weapons',{});return {id=id,removed=remove}
    end)
end
function actions.clear_allveh(ctx)
    I.effect(ctx);TriggerClientEvent('ic_admin:notice',-1,{message='Limpeza de veículos vazios em '..I.Config.cleanupDelay..' segundos.',duration=10})
    SetTimeout(I.Config.cleanupDelay*1000,function()
        if not I.active() or I.vRP.getUserId(ctx.source)~=ctx.userId or not I.allowed(ctx.userId,'clear_allveh') then return end
        local occupied={};for _,s in ipairs(GetPlayers()) do local vehicle=GetVehiclePedIsIn(GetPlayerPed(tonumber(s)),false);if vehicle~=0 then occupied[vehicle]=true end end
        local count=0;for _,vehicle in ipairs(GetAllVehicles()) do
            if not occupied[vehicle] and GetPedInVehicleSeat(vehicle,-1)==0 then DeleteEntity(vehicle);count=count+1 end
        end
        I.audit('clear_allveh.complete',ctx,nil,{count=count})
    end)
    return {scheduled=true,delay=I.Config.cleanupDelay}
end
function actions.clear_props(ctx)
    local coords=at(ctx.source);local count=0;I.effect(ctx)
    for _,entity in ipairs(GetAllObjects()) do
        local c=GetEntityCoords(entity);local d=(c.x-coords.x)^2+(c.y-coords.y)^2+(c.z-coords.z)^2
        if d<=I.Config.propRadius^2 and GetEntityRoutingBucket(entity)==GetPlayerRoutingBucket(ctx.source) then DeleteEntity(entity);count=count+1 end
    end
    return {count=count}
end
function actions.needs_manage(ctx,p)
    if type(p.enabled)~='boolean' then I.fail('INVALID_INPUT','Informe o estado de fome/sede.') end
    I.effect(ctx);I.vRP.setNeedsEnabled(p.enabled);return {enabled=I.vRP.areNeedsEnabled()}
end
for key in pairs(actions) do I.definitions[key]={key=key,label=key} end
I.register('action.execute',{mutating=true,handler=function(ctx,p)
    local name=I.text(p.action,64,true,'Ação');local handler=actions[name]
    if not handler then I.fail('UNKNOWN_ACTION','Ação desconhecida.') end
    permit(ctx,name)
    local result=handler(ctx,p)
    I.audit(name,ctx,tonumber(p.targetId),{reason=p.reason,result=result})
    return result
end})
I.register('catalog.get',{handler=function(ctx)
    local result={items={},weapons={},vehicles={},groups={}}
    if I.allowed(ctx.userId,'view_items') or I.allowed(ctx.userId,'view_weapons') or I.allowed(ctx.userId,'view_players') or I.allowed(ctx.userId,'view_vips') then
        for id,entry in pairs(A.itemCatalog()) do
            local row={id=id,name=entry.name or id,type=entry.type,weight=entry.weight,ammo=A.ammoForWeapon(id)}
            result.items[#result.items+1]=row
            if entry.type=='equip' or entry.type=='weapon' or id:match('^WEAPON_') then result.weapons[#result.weapons+1]=row end
        end
    end
    if I.allowed(ctx.userId,'view_vehicles') or I.allowed(ctx.userId,'view_vips') then
        for id,entry in pairs(A.vehicleCatalog()) do result.vehicles[#result.vehicles+1]={id=id,name=entry.name or id,type=entry.type} end
    end
    if I.allowed(ctx.userId,'view_groups') or I.allowed(ctx.userId,'view_vips') then
        for name,entry in pairs(I.vRP.getGroups() or {}) do
            local permissions={};for _,permission in ipairs(entry) do permissions[#permissions+1]=permission end
            result.groups[#result.groups+1]={name=name,permissions=permissions,config={gtype=entry._config and entry._config.gtype,salario=entry._config and entry._config.salario}}
        end
    end
    for _,list in pairs(result) do table.sort(list,function(a,b)return (a.name or a.id)<(b.name or b.id) end) end
    return result
end})
I.register('identity.get',{permission='view_identity_editor',handler=function(_,p)local snapshot=I.snapshot(p.targetId);snapshot.inventory=nil;return snapshot end})
I.register('identity.update',{mutating=true,handler=function(ctx,p)
    local id=I.target(p.targetId,false);local field=I.text(p.field,32,true,'Campo');reason(p)
    if field=='wallet' or field=='bank' then
        permit(ctx,'edit_identity_balance')
        ctx.identityEditor=true
        return I.methods['economy.change'].handler(ctx,{targetId=id,account=field,mode='set',amount=p.value,reason=p.reason})
    end
    permit(ctx,'edit_identity')
    local fields={nome=50,sobrenome=50,idade=0,telefone=20,registro=50}
    if fields[field]==nil then I.fail('INVALID_FIELD','Campo de identidade inválido.') end
    local value=field=='idade' and I.int(p.value,1,150,'Idade') or I.text(p.value,fields[field],true,'Valor')
    return I.withLock('identity:'..id,function()
        if field=='telefone' or field=='registro' then
            local rows=I.Store.query('SELECT user_id FROM vrp_user_identities WHERE `'..field..'`=? AND user_id<>? LIMIT 1',{value,id})
            if rows[1] then I.fail('VALUE_IN_USE','Esse valor já está em uso.') end
        end
        local before=I.snapshot(id).identity;I.effect(ctx)
        I.Store.update('UPDATE vrp_user_identities SET `'..field..'`=? WHERE user_id=?',{value,id})
        I.vRP.updateIdentity(id);TriggerEvent('identity:atualizar',id)
        TriggerClientEvent('ic_admin:identityLiveUpdated',-1,{id=id})
        I.audit('edit_identity',ctx,id,{field=field,before=before[field],after=value,reason=p.reason})
        local updated=I.snapshot(id)
        if not I.allowed(ctx.userId,'inspect_inventory') then updated.inventory=nil end
        return updated
    end)
end})
I.register('groups.change',{mutating=true,online=true,handler=function(ctx,p)
    local id=I.target(p.targetId,true);local group=I.text(p.group,80,true,'Cargo');reason(p)
    local adding=p.mode=='add';if not adding and p.mode~='remove' then I.fail('INVALID_INPUT','Modo inválido.') end
    permit(ctx,adding and 'set_group' or 'remove_group')
    A.checkGroupHierarchy(ctx,group,id)
    return I.withLock('groups:'..id,function()
        local before=A.groups(id)
        I.effect(ctx)
        if adding then I.vRP.addUserGroup(id,group) else I.vRP.removeUserGroup(id,group) end
        if I.vRP.hasGroup(id,group)~=adding then I.fail('GROUP_FAILED','Alteração de cargo não confirmada.') end
        local after=A.groups(id)
        I.audit(adding and 'set_group' or 'remove_group',ctx,id,{group=group,before=before,after=after,reason=p.reason})
        return {id=id,groups=after}
    end)
end})
I.definitions.set_group={key='set_group',label='Adicionar cargo'};I.definitions.remove_group={key='remove_group',label='Remover cargo'}
I.definitions.edit_identity={key='edit_identity',label='Editar identidade'};I.definitions.edit_identity_balance={key='edit_identity_balance',label='Editar saldo pelo RG'}
I.register('items.change',{mutating=true,online=true,handler=function(ctx,p)
    local id=I.target(p.targetId,true);local item=A.validItem(p.item);local amount=I.int(p.amount,1,1000000,'Quantidade');reason(p)
    local adding=p.mode=='give' or p.mode=='add'
    if not adding and p.mode~='remove' then I.fail('INVALID_INPUT','Modo inválido.') end
    local key=adding and (id==ctx.userId and 'spawn_self_item' or 'give_item') or 'remove_item'
    local entry=A.itemCatalog()[item]
    if adding and id==ctx.userId and (entry.type=='equip' or entry.type=='weapon') then key='spawn_weapon' end
    permit(ctx,key)
    return I.withLock('inventory:'..id,function()
        local before=tonumber(I.vRP.getInventoryItemAmount(id,item)) or 0
        if not adding and before<amount then I.fail('INSUFFICIENT_ITEMS','Quantidade insuficiente no inventário.') end
        I.effect(ctx)
        if adding then A.giveItem(id,item,amount) elseif I.vRP.tryGetInventoryItem(id,item,amount,true)~=true then I.fail('INVENTORY_CHANGED','Não foi possível remover o item.') end
        local after=tonumber(I.vRP.getInventoryItemAmount(id,item)) or 0
        I.audit(key,ctx,id,{item=item,before=before,after=after,reason=p.reason})
        return {id=id,item=item,before=before,after=after}
    end)
end})
for _,key in ipairs({'spawn_self_item','give_item','spawn_weapon','remove_item'}) do I.definitions[key]={key=key,label=key} end
I.register('economy.change',{mutating=true,handler=function(ctx,p)
    local account=p.account;if account~='wallet' and account~='bank' then I.fail('INVALID_ACCOUNT','Conta inválida.') end
    local id=I.target(p.targetId,account=='wallet');local amount=I.int(p.amount,0,2147483647,'Valor');reason(p)
    if p.mode~='give' and p.mode~='add' and p.mode~='remove' and p.mode~='set' then I.fail('INVALID_INPUT','Modo inválido.') end
    if not ctx.identityEditor then permit(ctx,p.mode=='remove' and 'remove_money' or (p.mode=='set' and 'edit_identity_balance' or 'givemoney')) end
    return I.withLock('money:'..id,function()
        local before=tonumber(account=='wallet' and I.vRP.getMoney(id) or I.vRP.getBankMoney(id)) or 0
        local after=p.mode=='set' and amount or p.mode=='remove' and before-amount or before+amount
        if after<0 or after>2147483647 then I.fail('INVALID_BALANCE','Saldo insuficiente ou fora do limite.') end
        I.effect(ctx)
        if account=='bank' then I.vRP.setBankMoney(id,after)
        elseif after>before then A.giveItem(id,'money',after-before)
        elseif after<before and I.vRP.tryGetInventoryItem(id,'money',before-after,false)~=true then I.fail('INVENTORY_CHANGED','Não foi possível retirar o dinheiro.') end
        local confirmed=tonumber(account=='wallet' and I.vRP.getMoney(id) or I.vRP.getBankMoney(id))
        if confirmed~=after then I.fail('BALANCE_UNCONFIRMED','Alteração de saldo exige conferência.') end
        I.audit('economy.change',ctx,id,{account=account,before=before,after=after,reason=p.reason})
        return {id=id,account=account,before=before,after=after}
    end)
end})
for _,key in ipairs({'givemoney','remove_money'}) do I.definitions[key]={key=key,label=key} end
I.register('needs.get',{permission='needs_manage',handler=function()return {enabled=I.vRP.areNeedsEnabled(),settings=I.vRP.getNeedsSettings()} end})
I.register('needs.update',{permission='needs_manage',mutating=true,handler=function(ctx,p)
    local settings={}
    local fields={hungerPerMinute=100,thirstPerMinute=100,hungerDamage=100,thirstDamage=100}
    for key,max in pairs(fields) do
        if p[key]~=nil then local n=tonumber(p[key]);if not n or n~=n or n<0 or n>max then I.fail('INVALID_INPUT','Configuração inválida.') end;settings[key]=n end
    end
    if p.enabled~=nil and type(p.enabled)~='boolean' then I.fail('INVALID_INPUT','Estado inválido.') end
    I.effect(ctx);if p.enabled~=nil then I.vRP.setNeedsEnabled(p.enabled) end
    I.vRP.setNeedsSettings(settings);return {enabled=I.vRP.areNeedsEnabled(),settings=I.vRP.getNeedsSettings()}
end})
I.register('radio.list',{permission='view_radio',handler=function()return {radios=exports['radio']:getPrivateRadios()} end})
for _,mode in ipairs({'save','delete'}) do
    I.register('radio.'..mode,{permission=mode=='save' and 'radio_save' or 'radio_delete',mutating=true,handler=function(ctx,p)
        if GetResourceState('radio')~='started' then I.fail('RESOURCE_UNAVAILABLE','Rádio indisponível.') end
        I.effect(ctx)
        local response=mode=='save' and exports['radio']:upsertPrivateRadio(p) or exports['radio']:deletePrivateRadio(I.int(p.id,1,9999,'Rádio'))
        if not response.ok then I.fail('RADIO_ERROR',response.message or 'Falha ao alterar rádio.') end
        return response
    end})
end

I.register('weapons.give',{permission='spawn_weapon',mutating=true,handler=function(ctx,p)
    local id=I.target(ctx.userId,true)
    local weapon,entry=A.validItem(p.weapon)
    if entry.type~='equip' and entry.type~='weapon' then I.fail('INVALID_WEAPON','Selecione uma arma reconhecida pelo inventário.') end
    local ammoAmount=I.int(p.ammoAmount or 0,0,10000,'Munição');local ammo=A.ammoForWeapon(weapon)
    if ammoAmount>0 and not ammo then I.fail('INVALID_AMMO','Esta arma não possui munição cadastrada.') end
    local why=reason(p)
    return I.withLock('inventory:'..id,function()
        local weight=(tonumber(I.vRP.getItemWeight(weapon)) or 0)+(ammo and (tonumber(I.vRP.getItemWeight(ammo)) or 0)*ammoAmount or 0)
        if (tonumber(I.vRP.computeInvWeight(id)) or 0)+weight>(tonumber(I.vRP.getInventoryMaxWeight(id)) or 0) then I.fail('INVENTORY_FULL','O inventário não comporta a entrega.') end
        I.effect(ctx);A.giveItem(id,weapon,1)
        if ammoAmount>0 then A.giveItem(id,ammo,ammoAmount) end
        I.audit('spawn_weapon',ctx,id,{weapon=weapon,ammo=ammo,ammoAmount=ammoAmount,reason=why})
        return {id=id,weapon=weapon,ammo=ammo,ammoAmount=ammoAmount}
    end)
end})
