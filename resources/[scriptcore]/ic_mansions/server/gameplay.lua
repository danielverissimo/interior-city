local M=ICM
local function cycle()return(ICMConfig.IptuCycleDays or 20)*86400 end
local function confirmed(p)if p.confirmed~=true then M.fail('CONFIRMATION_REQUIRED','Confirme a operação antes de continuar.')end end
local function snapshotRow(state,id)local row,index=M.find(id,state);return row,index end
-- Persist intent before every external effect. Recovery never guesses whether a
-- debit/group mutation happened between the API call and its durable marker.
function M.change(ctx,id,kind,detail,effect,mutate,compensate)
    M.noPending(id)
    local before=M.copy(M.state());local state=M.copy(before)
    local row,index=snapshotRow(state,id)
    detail=M.copy(detail or{});detail.before=M.copy(row)
    local op=M.operation(state,kind,ctx,id,detail)
    M.phase(state,op,'applying')
    local ok,result=pcall(function()
        M.user(ctx.source,ctx.userId)
        effect(row,state)
        M.phase(state,op,'effects_confirmed')
        M.user(ctx.source,ctx.userId)
        local value=mutate(row,state,index)
        M.complete(state,op)
        return value
    end)
    if not ok then
        if M.Store.quarantined then error(result,0)end
        local restored=false
        if compensate then local good,value=pcall(compensate);restored=good and value==true end
        local recovery=M.copy(before);recovery.operations[op]=M.copy(state.operations[op]);recovery.operations[op].phase=restored and'cancelled'or'uncertain'
        recovery.operations[op].updatedAt=os.time()
        local saved=pcall(M.Store.save,recovery)
        if not restored or not saved then M.fail('RECONCILIATION_REQUIRED','A operação requer conferência dos efeitos registrados. Não repita pagamentos ou entregas.')end
        error(result,0)
    end
    M.broadcast();return result
end
function M.refundCash(id,amount)
    if amount==0 then return true end
    local before=tonumber(M.vRP.getBankMoney(id))
    if before==nil then return false end
    M.vRP.giveBankMoney(id,amount)
    return tonumber(M.vRP.getBankMoney(id))==before+amount
end
function M.pay(id,amount)
    local ok=M.vRP.tryFullPayment(id,amount)
    if ok~=true then M.fail('INSUFFICIENT_FUNDS','Saldo insuficiente para esta operação.')end
end
function M.taxValid(row,ctx,initialize)
    if not row.ownerId or not M.isMember(row,ctx.userId)then return true end
    local due=tonumber(row.iptuPaidUntil)or 0
    if due<=0 and initialize then
        if M.locked then return false end
        M.lock(function()
            local state=M.copy(M.state());local current=M.find(row.id,state)
            if(tonumber(current.iptuPaidUntil)or 0)<=0 then current.lastIptuPaidAt=os.time();current.iptuPaidUntil=os.time()+cycle();M.Store.save(state)end
        end)
        return true
    end
    return due>os.time()
end
function M.requireTax(row,ctx)
    if not M.taxValid(row,ctx,false)then
        TriggerClientEvent('ic_mansions:taxDue',ctx.source,{id=row.id,name=row.name,amount=row.iptuValue})
        M.fail('IPTU_OVERDUE','Pague o IPTU desta mansão antes de acessar seus serviços.')
    end
end
local function nearest(ctx,id,radius)
    if id then local row=M.find(id);M.near(ctx.source,row,radius);return row end
    local position=M.position(ctx.source);local selected,distance
    for _,row in ipairs(M.state().mansions)do
        local d=M.distance(position,row.purchaseCoords)
        if d<=radius and(not distance or d<distance)then selected,distance=row,d end
    end
    if not selected then M.fail('NOT_FOUND','Nenhuma mansão próxima.')end
    return selected
end
M.nearest=nearest
M.register('requestPurchase',false,function(ctx,p)
    local row=M.find(p.id);M.noPending(row.id);M.near(ctx.source,row,ICMConfig.PurchaseDistance or 2)
    if row.ownerId then M.fail('OCCUPIED','Esta mansão já possui proprietário.')end
    if(tonumber(M.vRP.getInventoryItemAmount(ctx.userId,row.voucher))or 0)<1 then M.fail('VOUCHER_REQUIRED','Você não possui o vale necessário.')end
    local token=M.token('purchase');M.quotes[token]={kind='purchase',source=ctx.source,userId=ctx.userId,mansionId=row.id,expires=os.time()+30,revision=M.Store.generation,voucher=row.voucher}
    return{quoteToken=token,id=row.id,name=row.name,price=row.price,voucher=row.voucher,voucherLabel=(ICMConfig.AllowedVouchers or{})[row.voucher],maxResidents=row.maxResidents}
end)

M.register('getPendingOperations',false,function(ctx)
    M.admin(ctx);local out={}
    for id,op in pairs(M.state().operations)do if op.phase~='done'and op.phase~='cancelled'then out[#out+1]=M.copy(op)end end
    return{operations=out,revision=M.Store.generation}
end)
M.register('reconcileOperation',true,function(ctx,p)
    M.admin(ctx);confirmed(p)
    if p.expectedRevision~=M.Store.generation then M.fail('CONFLICT','O estado mudou desde a consulta. Revise a operação novamente.')end
    local id=M.text(p.operationId);local state=M.copy(M.state());local op=state.operations[id]
    if not op or op.phase=='done'or op.phase=='cancelled'then M.fail('NOT_PENDING','Operação não pendente.')end
    if p.confirmation~=('RECONCILIADO '..id)or p.decision~='cancel_after_manual_reconciliation'then M.fail('CONFIRMATION_REQUIRED','Confirme a reconciliação manual dos pagamentos, grupos e integrações.')end
    local before=op.detail and op.detail.before
    local found=false
    for i,row in ipairs(state.mansions)do
        if row.id==op.mansionId then
            if before then state.mansions[i]=M.copy(before)else table.remove(state.mansions,i)end
            found=true;break
        end
    end
    if before and not found then state.mansions[#state.mansions+1]=M.copy(before)end
    op.phase='cancelled';op.reconciledBy=ctx.userId;op.reconciledAt=os.time()
    M.Store.save(state);M.broadcast()
    return{message='Registro liberado após declaração explícita de reconciliação manual.'}
end)
local function quote(ctx,p,kind)
    local token=M.text(p.quoteToken);local q=M.quotes[token];M.quotes[token]=nil
    if not q or q.kind~=kind or q.source~=ctx.source or q.userId~=ctx.userId or q.mansionId~=(p.id or p.mansionId)or q.expires<os.time()or q.revision~=M.Store.generation then M.fail('STALE_QUOTE','A confirmação expirou ou os dados mudaram. Consulte novamente.')end
    return q
end
M.register('confirmPurchase',true,function(ctx,p)
    confirmed(p);quote(ctx,p,'purchase')
    local row=M.find(p.id);M.near(ctx.source,row,ICMConfig.PurchaseDistance or 2)
    if row.ownerId then M.fail('OCCUPIED','Esta mansão já possui dono.')end
    local charged,grouped,known=false,false,true
    return M.change(ctx,row.id,'purchase',{voucher=row.voucher,quantity=1},function(current)
        known=false
        local took=M.vRP.tryGetInventoryItem(ctx.userId,current.voucher,1,true)
        known=true
        if took~=true then M.fail('VOUCHER_REQUIRED','Você não possui o vale necessário.')end
        charged=true
        known=false;M.group(ctx.userId,current.group,true);known=true;grouped=true
    end,function(current)
        current.ownerId=ctx.userId;current.members={};current.purchasedAt=os.time();current.lastIptuPaidAt=os.time();current.iptuPaidUntil=os.time()+cycle();current.updatedAt=os.time()
        return{message='Mansão adquirida com um vale.',mansionId=current.id}
    end,function()
        if not known then return false end
        if grouped then M.group(ctx.userId,row.group,false)end
        if charged then return M.vRP.giveInventoryItem(ctx.userId,row.voucher,1,true)==true end
        return true
    end)
end)
M.register('payIptu',true,function(ctx,p)
    confirmed(p);local row=M.find(p.mansionId)
    if not M.isMember(row,ctx.userId)then M.fail('FORBIDDEN','Somente proprietário ou morador pode pagar este IPTU.')end
    if(tonumber(row.iptuPaidUntil)or 0)<=0 then
        M.noPending(row.id);local initial=M.copy(M.state());local current=M.find(row.id,initial)
        current.lastIptuPaidAt=os.time();current.iptuPaidUntil=os.time()+cycle();M.Store.save(initial);M.broadcast()
        return{message='Prazo inicial do IPTU regularizado, sem cobrança.',paidUntil=current.iptuPaidUntil,chargedAmount=0}
    end
    if(tonumber(row.iptuPaidUntil)or 0)>os.time()then M.fail('NOT_DUE','O IPTU desta mansão está em dia.')end
    local amount=M.integer(row.iptuValue,0,1000000000000);local charged,known=false,true
    return M.change(ctx,row.id,'iptu',{amount=amount},function()
        known=false;local paid=M.vRP.tryFullPayment(ctx.userId,amount);known=true
        if paid~=true then M.fail('INSUFFICIENT_FUNDS','Saldo insuficiente para o IPTU.')end;charged=true
    end,function(current)
        current.lastIptuPaidAt=os.time();current.iptuPaidUntil=os.time()+cycle();current.updatedAt=os.time();return{message='IPTU pago.',paidUntil=current.iptuPaidUntil}
    end,function()return known and(not charged or M.refundCash(ctx.userId,amount))end)
end)
M.register('addResident',true,function(ctx,p)
    local row=M.find(p.mansionId);M.owner(ctx,row);local target=M.integer(p.userId);M.identity(target)
    if M.isMember(row,target)then M.fail('DUPLICATE_RESIDENT','Este passaporte já pertence à mansão.')end
    if 1+#(row.members or{})>=row.maxResidents then M.fail('RESIDENT_LIMIT','Limite de moradores atingido.')end
    local assigned,known=false,false
    local result=M.change(ctx,row.id,'add_resident',{userId=target},function(current)
        M.group(target,current.group,true);assigned=true;known=true
    end,function(current)
        current.members=current.members or{};current.members[#current.members+1]=target;current.updatedAt=os.time()
        return{message='Morador adicionado.'}
    end,function()if not known then return false end;if assigned then M.group(target,row.group,false)end;return true end)
    M.notify(M.vRP.getUserSource(target),'Você foi adicionado como morador de '..row.name..'.','sucesso')
    return result
end)
M.register('removeResident',true,function(ctx,p)
    confirmed(p);local row=M.find(p.mansionId);M.owner(ctx,row);local target=M.integer(p.userId)
    if target==row.ownerId or not M.isMember(row,target)then M.fail('INVALID_RESIDENT','Selecione um morador adicional válido.')end
    local removed,known=false,false
    local result=M.change(ctx,row.id,'remove_resident',{userId=target},function(current)M.group(target,current.group,false);removed=true;known=true end,function(current)
        for i,id in ipairs(current.members or{})do if id==target then table.remove(current.members,i);break end end
        current.updatedAt=os.time()
        return{message='Morador removido.'}
    end,function()if not known then return false end;if removed then M.group(target,row.group,true)end;return true end)
    M.notify(M.vRP.getUserSource(target),'Seu vínculo com '..row.name..' foi removido.')
    return result
end)
M.register('quoteCleanup',false,function(ctx,p)
    if not M.inGroups(ctx.userId,ICMConfig.CleanupGroups or{developer=true,dono=true,admin=true})then M.fail('FORBIDDEN','Sem cargo para limpar mansões.')end
    local row=nearest(ctx,p.mansionId,ICMConfig.CleanupDistance or 10);M.noPending(row.id)
    if not row.ownerId then M.fail('NOT_OCCUPIED','Esta mansão já está livre.')end
    local token=M.token('cleanup');M.quotes[token]={kind='cleanup',source=ctx.source,userId=ctx.userId,mansionId=row.id,expires=os.time()+45,revision=M.Store.generation}
    return{quoteToken=token,mansionId=row.id,name=row.name,residents=M.residents(row),furnitureCount=#(row.furniture or{}),message='Remove ocupantes e mobílias, sem devolução de vale ou dinheiro.'}
end)
M.register('cleanupMansion',true,function(ctx,p)
    confirmed(p);quote(ctx,p,'cleanup')
    if not M.inGroups(ctx.userId,ICMConfig.CleanupGroups or{developer=true,dono=true,admin=true})then M.fail('FORBIDDEN','Sem cargo para limpar mansões.')end
    local row=nearest(ctx,p.mansionId,ICMConfig.CleanupDistance or 10)
    if not row.ownerId then M.fail('NOT_OCCUPIED','Mansão já livre.')end
    local users={row.ownerId};for _,id in ipairs(row.members or{})do users[#users+1]=id end
    local removed,known={},true
    local result=M.change(ctx,row.id,'cleanup',{userIds=users,furnitureCount=#(row.furniture or{})},function(current)
        for _,id in ipairs(users)do known=false;M.group(id,current.group,false);known=true;removed[#removed+1]=id end
    end,function(current)
        current.ownerId=nil;current.members={};current.furniture={};current.purchasedAt=nil;current.lastIptuPaidAt=nil;current.iptuPaidUntil=nil;current.updatedAt=os.time()
        return{message='Mansão limpa e disponível para nova compra.'}
    end,function()if not known then return false end;for _,id in ipairs(removed)do M.group(id,row.group,true)end;return true end)
    for _,id in ipairs(users)do M.notify(M.vRP.getUserSource(id),'A mansão '..row.name..' foi liberada pela administração; seu vínculo foi removido.')end
    return result
end)
