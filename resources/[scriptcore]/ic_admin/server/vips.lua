local I=ICAdmin
local testSessions={}
local forbidden={['developer.permissao']=true,['admin.permissao']=true,['moderador.permissao']=true,['suporte.permissao']=true,['perm.ptr.staff']=true}
local function packages() return I.Store.get('vip_packages',{packages={}}) end
local function assignments() return I.Store.get('vip_assignments',{assignments={}}) end
local function saveAssignments(doc,rev)
    if not I.Store.put('vip_assignments',doc,rev) then I.fail('CONFLICT','Benefícios alterados; atualize a tela.') end
end
local function groupDefinition(name)
    local groups=I.vRP.getGroups() or {}; return groups[name]
end
local function permittedGroup(name)
    if type(name)~='string' or not name:match('^[%w_%-]+$') or #name>80 then I.fail('INVALID','Nome de cargo VIP inválido.') end
    local definition=groupDefinition(name)
    if definition then
        if not definition._config or definition._config.gtype~='vip' then I.fail('FORBIDDEN','O cargo informado não é VIP.') end
        for _,permission in ipairs(definition) do if forbidden[permission] then I.fail('FORBIDDEN','Cargo VIP contém permissão de equipe.') end end
    elseif not name:match('^vip_[a-z0-9_]+$') then I.fail('INVALID','Novos cargos VIP precisam do prefixo vip_.') end
    return definition
end
local function packagePayload(p)
    local group=I.text(p.group,80,true,'Cargo'); permittedGroup(group)
    local out={group=group,title=I.text(p.title,80,true,'Nome'),salary=I.int(p.salary or 0,0,2147483647,'Salário'),
        items={},vehicles={},garageSlots=I.int(p.garageSlots or 0,0,1000,'Vagas')}
    if type(p.items or {})~='table' or type(p.vehicles or {})~='table' then I.fail('INVALID','Benefícios inválidos.') end
    local itemCatalog=I.Adapter.itemCatalog(); local seen={}
    for _,row in ipairs(p.items or {}) do
        if #out.items>=100 then I.fail('LIMIT','Máximo de 100 itens por pacote.') end
        local item=I.text(row.item,80,true,'Item')
        if not itemCatalog[item] or seen[item] then I.fail('INVALID','Item inexistente ou repetido.') end
        seen[item]=true; out.items[#out.items+1]={item=item,amount=I.int(row.amount,1,1000000,'Quantidade')}
    end
    seen={}
    for _,row in ipairs(p.vehicles or {}) do
        if #out.vehicles>=100 then I.fail('LIMIT','Máximo de 100 veículos por pacote.') end
        local spawn=I.Adapter.validVehicle(row.spawn or row.vehicle)
        if seen[spawn] then I.fail('INVALID','Veículo repetido.') end
        seen[spawn]=true
        local entry=I.Adapter.vehicleCatalog()[spawn] or {}
        out.vehicles[#out.vehicles+1]={spawn=spawn,name=entry.name or spawn}
    end
    out.vehicleChoices=I.int(p.vehicleChoices or 0,0,#out.vehicles,'Escolhas de veículos')
    if #out.vehicles>0 and out.vehicleChoices<1 then I.fail('INVALID','Defina ao menos uma escolha de veículo.') end
    return out
end
local function listFor(userId,includeAll)
    local doc=packages(); local values={}
    for _,value in pairs(doc.packages or {}) do values[#values+1]=value end
    table.sort(values,function(a,b)return tostring(a.title)<tostring(b.title) end)
    local data=assignments(); local own={}; local subject=I.subject(userId)
    for _,value in ipairs(data.assignments or {}) do
        if includeAll or (value.userId==userId and value.subjectKey==subject and value.state=='active' and (tonumber(value.expiresAt) or 0)>os.time()) then
            local row=I.copy(value)
            if row.state=='active' and (tonumber(row.expiresAt) or 0)<=os.time() then row.state='expired' end
            own[#own+1]=row
        end
    end
    table.sort(own,function(a,b)return (tonumber(a.assignedAt) or 0)>(tonumber(b.assignedAt) or 0) end)
    local total=#own
    while #own>100 do table.remove(own) end
    return {packages=values,assignments=own,totalAssignments=total}
end
local function findAssignment(doc,id)
    for _,value in ipairs(doc.assignments or {}) do if tostring(value.id)==id then return value end end
end
local function remaining(value)
    local count=0
    for _,claim in ipairs(value.claims or {}) do if claim.state=='applied' or claim.state=='applying' or claim.state=='uncertain' then count=count+1 end end
    return math.max(0,(tonumber(value.vehicleChoices) or 0)-count)
end
local function playerChoice(value)
    return {assignmentId=value.id,group=value.group,vehicles=value.vehicles or {},remaining=remaining(value),expiresAt=value.expiresAt}
end
local function requireAssignment(ctx,p)
    local doc,rev=assignments(); local value=findAssignment(doc,I.text(tostring(p.assignmentId or ''),96,true,'Entrega'))
    if not value or value.userId~=ctx.userId or value.subjectKey~=I.subject(ctx.userId) then I.fail('FORBIDDEN','Entrega não encontrada para este jogador.') end
    I.target(ctx.userId,true)
    if value.state~='active' or (tonumber(value.expiresAt) or 0)<=os.time() or not I.vRP.hasGroup(ctx.userId,value.group) then
        I.fail('EXPIRED','Benefício expirado ou indisponível.')
    end
    return doc,rev,value
end
local function selectedVehicle(value,p)
    local wanted=I.Adapter.validVehicle(p.vehicle)
    for _,row in ipairs(value.vehicles or {}) do if row.spawn==wanted then return wanted end end
    I.fail('INVALID','Veículo não pertence a esta entrega.')
end

I.register('vip.list',{permission='view_vips',handler=function(ctx) return listFor(ctx.userId,true) end})
I.register('vip.mine',{public=true,handler=function(ctx)
    local choices={}
    for _,row in ipairs(listFor(ctx.userId).assignments) do if remaining(row)>0 then choices[#choices+1]=playerChoice(row) end end
    return {assignments=choices}
end})

I.register('vip.save',{permission='view_vips',mutating=true,handler=function(ctx,p)
    return I.withLock('vip_packages',function()
        local package=packagePayload(p); local doc,rev=packages(); doc.packages=doc.packages or {}
        local original=I.text(p.originalGroup or '',80,false,'Cargo original')
        if original~='' and original~=package.group then I.fail('INVALID','O cargo do pacote não pode ser renomeado. Crie outro pacote.') end
        local exists=doc.packages[package.group]~=nil
        local permission=exists and 'edit_vip' or 'create_vip'
        if not I.allowed(ctx.userId,permission) then I.fail('FORBIDDEN','Sem permissão para salvar este pacote VIP.') end
        if original~='' and not exists then I.fail('NOT_FOUND','Pacote não encontrado.') end
        local definition=groupDefinition(package.group)
        local permissions={}
        if definition then for _,permission in ipairs(definition) do permissions[#permissions+1]=permission end
        else permissions={'perm.'..package.group} end
        ctx.permission=permission; I.effect(ctx)
        local ok,message=exports['vrp']:saveManagedGroup(definition and package.group or '',{
            name=package.group,permissions=permissions,config={gtype='vip',title=package.title,salario=package.salary}})
        if not ok then I.fail('GROUP_SAVE_FAILED',message or 'Não foi possível salvar o cargo VIP.') end
        doc.packages[package.group]=package
        if not I.Store.put('vip_packages',doc,rev) then I.fail('RECONCILE','Cargo salvo, mas o pacote precisa de conferência antes de nova tentativa.') end
        return listFor(ctx.userId,true)
    end)
end})
I.definitions.edit_vip={key='edit_vip',label='Editar pacote VIP'}
I.definitions.create_vip={key='create_vip',label='Criar pacote VIP'}

I.register('vip.assign',{permission='assign_vip',mutating=true,online=true,handler=function(ctx,p)
    local userId,playerSource=I.target(p.targetId,true)
    local group=I.text(p.group,80,true,'Cargo'); local reason=I.text(p.reason,500,true,'Motivo')
    return I.withLock('vip_assignments',function()
        local sourceDoc=packages(); local package=(sourceDoc.packages or {})[group]
        if not package then I.fail('NOT_FOUND','Pacote não encontrado.') end
        permittedGroup(group)
        if I.vRP.hasGroup(userId,group) then
            I.fail('VIP_ACTIVE','Este VIP já está ativo. A entrega não será repetida.')
        end
        local doc,rev=assignments(); doc.assignments=doc.assignments or {}; local subject=I.subject(userId)
        for _,value in ipairs(doc.assignments) do
            if value.userId==userId and value.subjectKey==subject and value.group==group and (value.state=='uncertain' or value.state=='applying'
                or (value.state=='active' and (tonumber(value.expiresAt) or 0)>os.time())) then I.fail('VIP_ACTIVE','Entrega ativa ou pendente de conferência.') end
        end
        local value={id=('%d-%x-%x'):format(userId,os.time(),math.random(1,0x7fffffff)),userId=userId,group=group,
            subjectKey=subject,assignedAt=os.time(),expiresAt=0,state='applying',itemsState='pending',claims={},
            items=I.copy(package.items or {}),vehicles=I.copy(package.vehicles or {}),vehicleChoices=package.vehicleChoices or 0,
            garageSlots=package.garageSlots or 0,actorId=ctx.userId,reason=reason}
        doc.assignments[#doc.assignments+1]=value; saveAssignments(doc,rev)
        local ok,err=pcall(function()
            I.target(userId,true); I.effect(ctx)
            if I.vRP.addUserGroup(userId,group)~=true then I.fail('GROUP_FAILED','Não foi possível atribuir o cargo VIP.') end
            value.expiresAt=tonumber(I.vRP.getUserGroupExpiration(userId,group)) or 0
            if value.expiresAt<=os.time() then I.fail('EXPIRATION_FAILED','Expiração VIP não foi confirmada.') end
            local latest,currentRev=assignments(); local persisted=findAssignment(latest,value.id)
            persisted.expiresAt=value.expiresAt; persisted.itemsState='applying'; saveAssignments(latest,currentRev)
            for _,item in ipairs(value.items) do
                I.target(userId,true); I.effect(ctx)
                if I.Adapter.giveItem(userId,item.item,item.amount)~=true then I.fail('DELIVERY_FAILED','Entrega de itens incompleta; solicite conferência.') end
            end
            local final,finalRev=assignments(); local row=findAssignment(final,value.id)
            row.state='active'; row.itemsState='applied'; row.expiresAt=value.expiresAt; saveAssignments(final,finalRev)
            value=row
        end)
        if not ok then
            local failed,failedRev=assignments(); local row=findAssignment(failed,value.id)
            if row then row.state='uncertain';row.itemsState='uncertain';saveAssignments(failed,failedRev) end
            if type(err)=='table' then error(err,0) end
            I.fail('DELIVERY_UNCERTAIN','Entrega pendente de conferência. Não repita o pacote.')
        end
        if tonumber(I.vRP.getUserId(playerSource))==userId and remaining(value)>0 then TriggerClientEvent('ic_admin:vipChoice',playerSource,playerChoice(value)) end
        return {assignment=value,message='VIP entregue; validade administrada pela vRP.'}
    end)
end})

I.register('vip.choose',{public=true,mutating=true,handler=function(ctx,p)
    return I.withLock('vip_assignments',function()
        local doc,rev,value=requireAssignment(ctx,p)
        if remaining(value)<1 then I.fail('CLAIMED','Todas as escolhas já foram utilizadas ou estão em conferência.') end
        local vehicle=selectedVehicle(value,p); value.claims=value.claims or {}
        for _,claim in ipairs(value.claims) do if claim.vehicle==vehicle then I.fail('CLAIMED','Este veículo já foi escolhido.') end end
        value.claims[#value.claims+1]={vehicle=vehicle,state='applying',at=os.time()}; saveAssignments(doc,rev)
        I.target(ctx.userId,true); I.effect(ctx)
        local ok,result=pcall(I.Adapter.giveVehicle,ctx.userId,vehicle)
        local final,finalRev=assignments(); local row=findAssignment(final,value.id)
        local claim=row.claims[#row.claims]
        claim.state=ok and result==true and 'applied' or 'uncertain'; saveAssignments(final,finalRev)
        if claim.state~='applied' then I.fail('DELIVERY_UNCERTAIN','Entrega do veículo pendente de conferência. Não repita a escolha.') end
        TriggerClientEvent('ic_admin:vipChoice',ctx.source,playerChoice(row))
        return {assignment=playerChoice(row),vehicle=vehicle}
    end)
end})

I.register('vip.delete',{permission='delete_vip',mutating=true,handler=function(ctx,p)
    local group=I.text(p.group,80,true,'Cargo'); I.text(p.reason,500,true,'Motivo')
    return I.withLock('vip_packages',function()
        local doc,rev=packages(); if not (doc.packages or {})[group] then I.fail('NOT_FOUND','Pacote não encontrado.') end
        permittedGroup(group)
        return I.withLock('vip_assignments',function()
            local data,dataRev=assignments()
            I.effect(ctx)
            local ok,message=exports['vrp']:removeManagedGroup(group)
            if not ok then I.fail('GROUP_DELETE_FAILED',message or 'Não foi possível excluir o cargo.') end
            doc.packages[group]=nil
            if not I.Store.put('vip_packages',doc,rev) then I.fail('RECONCILE','Cargo removido; pacote precisa de conferência.') end
            for _,row in ipairs(data.assignments or {}) do if row.group==group and row.state=='active' then row.state='archived';row.archivedAt=os.time() end end
            saveAssignments(data,dataRev)
            return listFor(ctx.userId,true)
        end)
    end)
end})

I.register('vip.test',{public=true,mutating=true,handler=function(ctx,p)
    if p.mode=='finish' then
        local session=testSessions[ctx.source]
        if not session or session.userId~=ctx.userId then I.fail('NOT_FOUND','Teste não encontrado.') end
        SetPlayerRoutingBucket(ctx.source,session.bucket)
        TriggerClientEvent('ic_admin:clientAction',ctx.source,'vipTestStop',{returnCoords=session.coords})
        testSessions[ctx.source]=nil; return {finished=true}
    end
    if testSessions[ctx.source] then I.fail('BUSY','Finalize o teste atual.') end
    local _,_,value=requireAssignment(ctx,p); local vehicle=selectedVehicle(value,p)
    if remaining(value)<1 then I.fail('CLAIMED','Nenhuma escolha disponível.') end
    local ped=GetPlayerPed(ctx.source)
    if ped==0 then I.fail('UNAVAILABLE','Personagem indisponível.') end
    local coords=GetEntityCoords(ped); local current=GetPlayerRoutingBucket(ctx.source)
    local session={userId=ctx.userId,bucket=current,coords={x=coords.x,y=coords.y,z=coords.z},expiresAt=os.time()+60}
    I.effect(ctx); testSessions[ctx.source]=session
    SetPlayerRoutingBucket(ctx.source,700000+ctx.source)
    TriggerClientEvent('ic_admin:clientAction',ctx.source,'vipTest',{vehicle=vehicle,seconds=60,returnCoords=session.coords})
    return {seconds=60,vehicle=vehicle}
end})

exports('getVipGarageSlotsForUser',function(userId)
    if not I.active() then return 0 end
    userId=tonumber(userId); if not userId then return 0 end
    local doc=packages(); local total=0
    for group,package in pairs(doc.packages or {}) do
        if I.vRP.hasGroup(userId,group) then
            local expires=tonumber(I.vRP.getUserGroupExpiration(userId,group)) or 0
            if expires==0 or expires>os.time() then total=total+math.max(0,math.floor(tonumber(package.garageSlots) or 0)) end
        end
    end
    return total
end)

local function stopTest(source,send)
    local session=testSessions[source]
    if not session then return end
    if tonumber(I.vRP.getUserId(source))==session.userId then
        SetPlayerRoutingBucket(source,session.bucket)
        if send then TriggerClientEvent('ic_admin:clientAction',source,'vipTestStop',{returnCoords=session.coords}) end
    end
    testSessions[source]=nil
end
AddEventHandler('playerDropped',function() stopTest(source,false) end)
AddEventHandler('ic_admin:sessionRevoked',function(playerSource) stopTest(playerSource,true) end)
AddEventHandler('onResourceStop',function(name)
    if name==GetCurrentResourceName() then for playerSource in pairs(testSessions) do stopTest(playerSource,true) end end
end)
AddEventHandler('vRP:playerSpawn',function(userId,playerSource)
    if not I.active() then return end
    local doc=assignments()
    for _,row in ipairs(doc.assignments or {}) do
        if row.userId==userId and row.subjectKey==I.subject(userId) and row.state=='active' and row.expiresAt>os.time() and remaining(row)>0 then
            if tonumber(I.vRP.getUserId(playerSource))==tonumber(userId) then TriggerClientEvent('ic_admin:vipChoice',playerSource,playerChoice(row)) end; break
        end
    end
end)
CreateThread(function()
    while true do
        Wait(1000)
        for playerSource,session in pairs(testSessions) do if session.expiresAt<=os.time() or not I.active() then stopTest(playerSource,true) end end
    end
end)

I.Vips={remaining=remaining,findAssignment=findAssignment,packagePayload=packagePayload}
