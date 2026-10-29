local I=ICAdmin
local defaults={staff={label='Staff',permissions={'perm.ptr.staff'}},police={label='Polícia',permissions={'perm.policia','perm.countpolicia'}},
    mechanic={label='Mecânica',permissions={'perm.mecanica'}},hospital={label='Hospital',permissions={'perm.unizk'}}}
local function departments() return I.Config.departments or defaults end
local function get() return I.Store.get('calls',{nextId=1,calls={},ratings={}}) end
local function find(doc,id) for _,call in ipairs(doc.calls or {}) do if tonumber(call.id)==id then return call end end end
local function canAttend(id,dept,action)
    if dept=='staff' then return I.allowed(id,'view_calls') and (not action or I.allowed(id,action)) end
    for _,permission in ipairs((departments()[dept] or {}).permissions or {}) do if I.vRP.hasPermission(id,permission) then return true end end
    return false
end
local function sourceFor(id)
    local src=I.vRP.getUserSource(id)
    return src and tonumber(I.vRP.getUserId(src))==tonumber(id) and src or nil
end
local function ownRequest(call,userId,subject)
    return call.requesterId==userId and call.requesterSubject==(subject or I.subject(userId))
end
local function viewCall(call,id,subject,ratings)
    local row=I.copy(call)
    row.canAccept=call.state=='open' and call.requesterId~=id and canAttend(id,call.department,'calls_accept')
    row.canFinish=call.state=='accepted' and call.acceptedBy==id and call.acceptedSubject==subject and canAttend(id,call.department,'calls_finish')
    local rated=false;for _,rating in ipairs(ratings or {}) do if tonumber(rating.callId)==tonumber(call.id) then rated=true end end
    row.canRate=not rated and call.state=='finished' and call.department=='staff' and ownRequest(call,id,subject)
    return row
end
for _,key in ipairs({'calls_accept','calls_finish','calls_history','calls_ranking','calls_evaluations','calls_staff_notes'}) do I.definitions[key]={key=key,label=key} end
local function notify(call,event)
    for _,src in ipairs(GetPlayers()) do
        local id=tonumber(I.vRP.getUserId(tonumber(src)))
        if id and (ownRequest(call,id) or (id==call.acceptedBy and call.acceptedSubject==I.subject(id)) or canAttend(id,call.department)) then
            TriggerClientEvent('ic_admin:callNotice',tonumber(src),{type=event,call=viewCall(call,id,I.subject(id))})
        end
    end
end
local function save(doc,rev)
    if not I.Store.put('calls',doc,rev) then I.fail('CONFLICT','Chamados alterados; atualize e tente novamente.') end
end
local function create(playerSource,department,message,opts)
    if not I.active() then return {ok=false,message='Sistema de chamados indisponível.'} end
    local userId=tonumber(I.vRP.getUserId(playerSource))
    if not userId then return {ok=false,message='Jogador não identificado.'} end
    department=I.text(department,24,true,'Setor'); message=I.text(message,500,true,'Mensagem')
    if not departments()[department] then I.fail('INVALID','Setor inválido.') end
    return I.withLock('calls',function()
        local doc,rev=get(); doc.calls=doc.calls or {}; doc.ratings=doc.ratings or {}
        local now=os.time(); local subject=I.subject(userId)
        for _,call in ipairs(doc.calls) do
            if call.requesterSubject==subject and call.department==department and (call.state=='open' or call.state=='accepted') then
                return {ok=true,message='Chamado já registrado.',call=call}
            end
            if call.requesterSubject==subject and now-(tonumber(call.createdAt) or 0)<12 then I.fail('COOLDOWN','Aguarde antes de abrir outro chamado.') end
        end
        local available=false
        for _,src in ipairs(GetPlayers()) do
            local id=tonumber(I.vRP.getUserId(tonumber(src)))
            if id and canAttend(id,department) then available=true; break end
        end
        if not available then I.fail('UNAVAILABLE','Não há atendimento disponível neste setor.') end
        local snap=I.snapshot(userId)
        local call={id=tonumber(doc.nextId) or 1,requesterId=userId,requesterSubject=subject,requesterName=snap.name or ('Passaporte '..userId),
            department=department,message=message,state='open',createdAt=now,origin=opts and opts.origin or 'ic_admin'}
        doc.nextId=call.id+1; doc.calls[#doc.calls+1]=call
        if tonumber(I.vRP.getUserId(playerSource))~=userId then I.fail('SESSION_EXPIRED','Jogador desconectado.') end
        if opts and opts.ctx then I.effect(opts.ctx) end
        save(doc,rev)
        I.audit('calls.create',{userId=userId},userId,{callId=call.id,department=department})
        notify(call,'created')
        return {ok=true,message='Chamado enviado.',call=call}
    end)
end

exports('createSectorCall',function(playerSource,department,message,opts)
    local ok,result=pcall(create,tonumber(playerSource),department,message,opts)
    return ok and result or {ok=false,message='Não foi possível abrir o chamado.'}
end)

exports('cancelSectorCall',function(playerSource,department,reason)
    if not I.active() then return false end
    local id=tonumber(I.vRP.getUserId(tonumber(playerSource))); if not id then return false end
    return I.withLock('calls',function()
        local doc,rev=get(); local changed={}; local subject=I.subject(id)
        for _,call in ipairs(doc.calls or {}) do
            if ownRequest(call,id,subject) and call.department==department and (call.state=='open' or call.state=='accepted') then
                call.state='cancelled'; call.finishedAt=os.time(); call.cancelReason=tostring(reason or 'Cancelado.'):sub(1,300)
                changed[#changed+1]=call
            end
        end
        if #changed==0 then return false end
        if tonumber(I.vRP.getUserId(tonumber(playerSource)))~=id then return false end
        save(doc,rev); for _,call in ipairs(changed) do notify(call,'cancelled') end
        return true
    end)
end)

I.register('calls.create',{public=true,mutating=true,handler=function(ctx,p)
    local result=create(ctx.source,p.department,p.message,{origin='ic_admin',ctx=ctx})
    if not result.ok then I.fail('UNAVAILABLE',result.message) end
    return result
end})

I.register('calls.list',{public=true,handler=function(ctx,p)
    local doc=get(); local calls,ranking,ratings,totals={},{},{},{}
    local subject=I.subject(ctx.userId)
    local staff=I.allowed(ctx.userId,'view_calls')
    local history=staff and I.allowed(ctx.userId,'calls_history')
    local rankAllowed=staff and I.allowed(ctx.userId,'calls_ranking')
    local evaluations=staff and I.allowed(ctx.userId,'calls_evaluations')
    local notes=staff and I.allowed(ctx.userId,'calls_staff_notes')
    local attendance={}; for department in pairs(departments()) do attendance[department]=canAttend(ctx.userId,department) end
    for _,call in ipairs(doc.calls or {}) do
        if ownRequest(call,ctx.userId,subject) or (staff and call.department=='staff' and (call.state=='open' or call.state=='accepted' or history)) or (attendance[call.department]
            and (call.state=='open' or (call.acceptedBy==ctx.userId and call.acceptedSubject==subject))) then calls[#calls+1]=viewCall(call,ctx.userId,subject,doc.ratings) end
        if (rankAllowed or notes) and call.department=='staff' and call.state=='finished' and call.acceptedBy then
            local key=call.acceptedSubject or tostring(call.acceptedBy); local row=totals[key] or {staffId=call.acceptedBy,name=call.acceptedName,total=0,stars=0,ratings=0}
            row.total=row.total+1; totals[key]=row
        end
    end
    for _,rating in ipairs(doc.ratings or {}) do
        local call=find(doc,tonumber(rating.callId))
        if evaluations or (call and ownRequest(call,ctx.userId,subject)) then ratings[#ratings+1]=rating end
        local row=totals[rating.staffSubject or tostring(rating.staffId)]; if row then row.stars=row.stars+rating.stars; row.ratings=row.ratings+1 end
    end
    for _,row in pairs(totals) do row.average=(evaluations or notes) and (row.ratings>0 and row.stars/row.ratings or 0) or nil; ranking[#ranking+1]=row end
    table.sort(calls,function(a,b)return a.id>b.id end); table.sort(ranking,function(a,b)return a.total>b.total end)
    local page=I.int(p.page or 1,1,100000,'Página'); local paged={}
    for index=(page-1)*100+1,math.min(page*100,#calls) do paged[#paged+1]=calls[index] end
    return {calls=paged,total=#calls,page=page,ranking=ranking,ratings=ratings,departments=departments()}
end})

I.register('calls.accept',{public=true,mutating=true,handler=function(ctx,p)
    return I.withLock('calls',function()
        local doc,rev=get(); local call=find(doc,I.int(p.callId,1,2147483647,'Chamado'))
        if not call then I.fail('NOT_FOUND','Chamado não encontrado.') end
        if not canAttend(ctx.userId,call.department,'calls_accept') then I.fail('FORBIDDEN','Você não pode aceitar chamados deste setor.') end
        if call.requesterId==ctx.userId then I.fail('INVALID','Você não pode aceitar seu próprio chamado.') end
        if call.state~='open' then I.fail('CONFLICT','Chamado já atendido ou encerrado.') end
        call.state='accepted'; call.acceptedBy=ctx.userId; call.acceptedSubject=I.subject(ctx.userId)
        call.acceptedName=I.snapshot(ctx.userId).name; call.acceptedAt=os.time()
        if not canAttend(ctx.userId,call.department,'calls_accept') then I.fail('FORBIDDEN','Permissão do setor revogada.') end
        if call.department=='staff' then ctx.permission='calls_accept' end
        I.effect(ctx)
        save(doc,rev); notify(call,'accepted'); return {call=call,requesterOnline=sourceFor(call.requesterId)~=nil}
    end)
end})

I.register('calls.finish',{public=true,mutating=true,handler=function(ctx,p)
    return I.withLock('calls',function()
        local doc,rev=get(); local call=find(doc,I.int(p.callId,1,2147483647,'Chamado'))
        if not call then I.fail('NOT_FOUND','Chamado não encontrado.') end
        if call.acceptedBy~=ctx.userId or call.acceptedSubject~=I.subject(ctx.userId) or not canAttend(ctx.userId,call.department,'calls_finish') then I.fail('FORBIDDEN','Somente o responsável autorizado pode concluir.') end
        if call.state~='accepted' then I.fail('CONFLICT','Chamado não está em atendimento.') end
        call.state='finished'; call.finishedAt=os.time();if call.department=='staff' then ctx.permission='calls_finish' end; I.effect(ctx); save(doc,rev); notify(call,'finished')
        return {call=call}
    end)
end})

I.register('calls.rate',{public=true,mutating=true,handler=function(ctx,p)
    return I.withLock('calls',function()
        local doc,rev=get(); local call=find(doc,I.int(p.callId,1,2147483647,'Chamado'))
        if not call or not ownRequest(call,ctx.userId) or call.department~='staff' or call.state~='finished' then I.fail('FORBIDDEN','Avaliação indisponível.') end
        doc.ratings=doc.ratings or {}
        for _,rating in ipairs(doc.ratings) do if rating.callId==call.id then I.fail('CONFLICT','Chamado já avaliado.') end end
        local rating={callId=call.id,staffId=call.acceptedBy,staffSubject=call.acceptedSubject,stars=I.int(p.stars,1,5,'Nota'),message=I.text(p.message or '',500,false,'Comentário'),createdAt=os.time()}
        doc.ratings[#doc.ratings+1]=rating; I.effect(ctx); save(doc,rev); return {rating=rating}
    end)
end})

I.Calls={canAttend=canAttend,find=find}
