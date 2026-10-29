local I=ICAdmin
local defaults={staff={label='Staff',permissions={'perm.ptr.staff'}},police={label='Polícia',permissions={'perm.policia','perm.countpolicia'}},
    mechanic={label='Mecânica',permissions={'perm.mecanica'}},hospital={label='Hospital',permissions={'perm.unizk'}}}
local function departments() return I.Config.departments or defaults end
local R=I.Records
local function find(_,id) return R.get('calls',id) end
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
local function create(playerSource,department,message,opts)
    if not I.active() then return {ok=false,message='Sistema de chamados indisponível.'} end
    local userId=tonumber(I.vRP.getUserId(playerSource))
    if not userId then return {ok=false,message='Jogador não identificado.'} end
    department=I.text(department,24,true,'Setor'); message=I.text(message,500,true,'Mensagem')
    if not departments()[department] then I.fail('INVALID','Setor inválido.') end
    return I.withLock('calls',function()
        local subject=I.subject(userId)
        local previous=R.list('calls',"subject_key=? AND (state IN ('open','accepted') OR created_at>?)",{subject,os.time()-12},1,100)
        local now=os.time(); local subject=I.subject(userId)
        for _,call in ipairs(previous) do
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
        local call={requesterId=userId,requesterSubject=subject,requesterName=snap.name or ('Passaporte '..userId),
            department=department,message=message,state='open',createdAt=now,origin=opts and opts.origin or 'ic_admin'}
        if tonumber(I.vRP.getUserId(playerSource))~=userId then I.fail('SESSION_EXPIRED','Jogador desconectado.') end
        if opts and opts.ctx then I.effect(opts.ctx) end
        R.save('calls',call,0)
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
        local subject=I.subject(id)
        local rows=R.list('calls',"subject_key=? AND department=? AND state IN ('open','accepted')",{subject,department},1,100)
        if #rows==0 then return false end
        for _,entry in ipairs(rows) do
            local call,rev=R.get('calls',entry.id)
            call.state='cancelled';call.finishedAt=os.time();call.cancelReason=tostring(reason or 'Cancelado.'):sub(1,300)
            if tonumber(I.vRP.getUserId(tonumber(playerSource)))~=id then return false end
            R.save('calls',call,rev);notify(call,'cancelled')
        end
        return true
    end)
end)

I.register('calls.create',{public=true,mutating=true,handler=function(ctx,p)
    local result=create(ctx.source,p.department,p.message,{origin='ic_admin',ctx=ctx})
    if not result.ok then I.fail('UNAVAILABLE',result.message) end
    return result
end})

I.register('calls.list',{public=true,handler=function(ctx,p)
    local subject=I.subject(ctx.userId)
    local staff=I.allowed(ctx.userId,'view_calls')
    local history=staff and I.allowed(ctx.userId,'calls_history')
    local rankAllowed=staff and I.allowed(ctx.userId,'calls_ranking')
    local evaluations=staff and I.allowed(ctx.userId,'calls_evaluations')
    local notes=staff and I.allowed(ctx.userId,'calls_staff_notes')
    local conditions={'subject_key=?'};local params={subject}
    for department in pairs(departments()) do
        if canAttend(ctx.userId,department) then
            conditions[#conditions+1]="(department=? AND (state='open' OR (actor_subject=? AND state='accepted')"..(department=='staff' and history and " OR state IN ('accepted','finished','cancelled')" or '')..'))'
            params[#params+1]=department;params[#params+1]=subject
        end
    end
    local page=I.int(p.page or 1,1,100000,'Página')
    local where='('..table.concat(conditions,' OR ')..')'
    if p.state and p.state~='' then
        if not ({open=true,accepted=true,finished=true,cancelled=true})[p.state] then I.fail('INVALID','Estado inválido.') end
        where=where..' AND state=?';params[#params+1]=p.state
    end
    local rows,total=R.list('calls',where,params,page,50)
    local calls,ratings,ids={},{},{}
    for _,row in ipairs(rows) do ids[#ids+1]=row.id end
    local rated=R.byIds('ratings',ids)
    for _,row in ipairs(rows) do
        local rating=rated[tostring(row.id)]
        calls[#calls+1]=viewCall(row,ctx.userId,subject,rating and {rating} or {})
        if rating and (evaluations or ownRequest(row,ctx.userId,subject)) then ratings[#ratings+1]=rating end
    end
    local ranking={}
    if rankAllowed or notes then
        ranking=I.Store.query([[SELECT c.actor_id AS staffId,
            MAX(JSON_UNQUOTE(JSON_EXTRACT(c.payload,'$.acceptedName'))) AS name,
            COUNT(*) AS total, COUNT(r.id) AS ratings,
            AVG(CAST(JSON_UNQUOTE(JSON_EXTRACT(r.payload,'$.stars')) AS DECIMAL(5,2))) AS average
            FROM ic_admin_calls c LEFT JOIN ic_admin_ratings r ON r.id=c.id
            WHERE c.department='staff' AND c.state='finished'
            GROUP BY c.actor_subject,c.actor_id ORDER BY total DESC,c.actor_id LIMIT 100]])
        for _,row in ipairs(ranking) do
            row.total=tonumber(row.total);row.average=(evaluations or notes) and tonumber(row.average) or nil
        end
    end
    return {calls=calls,total=total,page=page,pageSize=50,ranking=ranking,ratings=ratings,departments=departments()}
end})

I.register('calls.accept',{public=true,mutating=true,handler=function(ctx,p)
    return I.withLock('calls',function()
        local call,rev=R.get('calls',I.int(p.callId,1,9007199254740991,'Chamado'))
        if not call then I.fail('NOT_FOUND','Chamado não encontrado.') end
        if not canAttend(ctx.userId,call.department,'calls_accept') then I.fail('FORBIDDEN','Você não pode aceitar chamados deste setor.') end
        if call.requesterId==ctx.userId then I.fail('INVALID','Você não pode aceitar seu próprio chamado.') end
        if call.state~='open' then I.fail('CONFLICT','Chamado já atendido ou encerrado.') end
        call.state='accepted'; call.acceptedBy=ctx.userId; call.acceptedSubject=I.subject(ctx.userId)
        call.acceptedName=I.snapshot(ctx.userId).name; call.acceptedAt=os.time()
        if not canAttend(ctx.userId,call.department,'calls_accept') then I.fail('FORBIDDEN','Permissão do setor revogada.') end
        if call.department=='staff' then ctx.permission='calls_accept' end
        I.effect(ctx)
        R.save('calls',call,rev); notify(call,'accepted'); return {call=call,requesterOnline=sourceFor(call.requesterId)~=nil}
    end)
end})

I.register('calls.finish',{public=true,mutating=true,handler=function(ctx,p)
    return I.withLock('calls',function()
        local call,rev=R.get('calls',I.int(p.callId,1,9007199254740991,'Chamado'))
        if not call then I.fail('NOT_FOUND','Chamado não encontrado.') end
        if call.acceptedBy~=ctx.userId or call.acceptedSubject~=I.subject(ctx.userId) or not canAttend(ctx.userId,call.department,'calls_finish') then I.fail('FORBIDDEN','Somente o responsável autorizado pode concluir.') end
        if call.state~='accepted' then I.fail('CONFLICT','Chamado não está em atendimento.') end
        call.state='finished'; call.finishedAt=os.time();if call.department=='staff' then ctx.permission='calls_finish' end; I.effect(ctx); R.save('calls',call,rev); notify(call,'finished')
        return {call=call}
    end)
end})

I.register('calls.rate',{public=true,mutating=true,handler=function(ctx,p)
    return I.withLock('calls',function()
        local call,rev=R.get('calls',I.int(p.callId,1,9007199254740991,'Chamado'))
        if not call or not ownRequest(call,ctx.userId) or call.department~='staff' or call.state~='finished' then I.fail('FORBIDDEN','Avaliação indisponível.') end
        if R.get('ratings',call.id) then I.fail('CONFLICT','Chamado já avaliado.') end
        local rating={id=call.id,callId=call.id,requesterId=ctx.userId,requesterSubject=I.subject(ctx.userId),staffId=call.acceptedBy,staffSubject=call.acceptedSubject,stars=I.int(p.stars,1,5,'Nota'),message=I.text(p.message or '',500,false,'Comentário'),createdAt=os.time()}
        I.effect(ctx); R.save('ratings',rating,0); return {rating=rating}
    end)
end})

I.Calls={canAttend=canAttend,find=find}
