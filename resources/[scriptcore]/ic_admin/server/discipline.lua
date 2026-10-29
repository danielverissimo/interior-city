local I=ICAdmin
local applied={}
local function restore(source,record)
    if tonumber(I.vRP.getUserId(source))~=tonumber(record.user_id) then return false end
    local state=type(record.return_state)=='string' and json.decode(record.return_state) or record.return_state
    if type(state)~='table' or type(state.coords)~='table' then return false end
    SetPlayerRoutingBucket(source,tonumber(state.bucket) or 0)
    TriggerClientEvent('ic_admin:clientAction',source,'teleport',{coords=state.coords})
    TriggerClientEvent('ic_admin:punishment',source,{active=false})
    return true
end
local function apply(source,row)
    local id=I.vRP.getUserId(source)
    if not id or id~=tonumber(row.user_id) then return end
    local bucket=1000000+source
    for _,s in ipairs(GetPlayers()) do
        local other=tonumber(s)
        if other~=source and GetPlayerRoutingBucket(other)==bucket then return end
    end
    SetPlayerRoutingBucket(source,bucket)
    TriggerClientEvent('ic_admin:punishment',source,{active=true,endsAt=tonumber(row.ends_at),reason=row.reason,id=row.id})
    applied[source]=I.copy(row)
end
I.register('warnings.list',{permission='view_warnings',handler=function(_,p)
    local rows
    if p.targetId then
        local id=I.target(p.targetId,false)
        rows=I.Store.query("SELECT id,user_id,actor_id,reason,starts_at,ends_at,state FROM ic_admin_discipline WHERE subject_key=? AND kind='warning' ORDER BY id DESC LIMIT 200",{I.subject(id)})
    else
        rows=I.Store.query("SELECT id,user_id,actor_id,reason,starts_at,ends_at,state FROM ic_admin_discipline WHERE kind='warning' ORDER BY id DESC LIMIT 200")
    end
    return {warnings=rows}
end})
I.register('warnings.apply',{permission='warning',mutating=true,online=true,handler=function(ctx,p)
    local id,target=I.target(p.targetId,true)
    local reason=I.text(p.reason,500,true,'Motivo');local minutes=I.int(p.minutes or 30,1,10080,'Minutos')
    return I.withLock('discipline:'..id,function()
        local subject=I.subject(id)
        local active=I.Store.query("SELECT id FROM ic_admin_discipline WHERE subject_key=? AND kind='warning' AND state='active' LIMIT 1",{subject})
        if active[1] then I.fail('ACTIVE_WARNING','O jogador já possui castigo ativo.') end
        local ped=GetPlayerPed(target);if ped==0 then I.fail('NO_PED','Personagem indisponível.') end
        local coords=GetEntityCoords(ped)
        local state={coords={x=coords.x,y=coords.y,z=coords.z},bucket=GetPlayerRoutingBucket(target)}
        local endsAt=os.time()+minutes*60
        I.effect(ctx)
        local rowId=I.Store.insert("INSERT INTO ic_admin_discipline(subject_key,user_id,actor_id,kind,reason,starts_at,ends_at,state,return_state) VALUES(?,?,?,'warning',?,?,?,'active',?)",{subject,id,ctx.userId,reason,os.time(),endsAt,json.encode(state)})
        apply(target,{id=rowId,user_id=id,ends_at=endsAt,reason=reason,return_state=json.encode(state)})
        return {id=rowId,targetId=id,endsAt=endsAt}
    end)
end})
I.register('warnings.archive',{permission='delete_warning',mutating=true,handler=function(ctx,p)
    local rowId=I.int(p.id or p.warningId,1,9007199254740991,'Advertência');I.text(p.reason,500,true,'Motivo')
    return I.withLock('warning:'..rowId,function()
        local row=I.Store.query("SELECT * FROM ic_admin_discipline WHERE id=? AND kind='warning'",{rowId})[1]
        if not row then I.fail('NOT_FOUND','Advertência não encontrada.') end
        I.effect(ctx)
        local target=I.vRP.getUserSource(tonumber(row.user_id))
        if row.state=='active' and target then
            if not restore(target,row) then I.fail('INVALID_RETURN_STATE','Retorno do castigo precisa de conferência.') end
            applied[target]=nil
        end
        local state=target and 'archived' or 'release_pending'
        if row.state~='active' then state='archived' end
        I.Store.update('UPDATE ic_admin_discipline SET state=? WHERE id=?',{state,rowId})
        return {id=rowId,archived=true}
    end)
end})
I.register('bans.list',{permission='ban_history_view',handler=function()
    return {bans=I.Store.query('SELECT user_id,motivo,banimento,desbanimento,time FROM mirtin_bans ORDER BY user_id LIMIT 500'),history=I.Store.query("SELECT id,user_id,actor_id,kind,reason,starts_at FROM ic_admin_discipline WHERE kind IN ('ban','unban') ORDER BY id DESC LIMIT 200")}
end})
local function reconcile(source)
    if not I.active() then return end
    local id=I.vRP.getUserId(source);if not id then return end
    local subject=I.subject(id)
    local rows=I.Store.query("SELECT * FROM ic_admin_discipline WHERE subject_key=? AND kind='warning' AND state IN ('active','release_pending') ORDER BY id",{subject})
    for _,row in ipairs(rows) do
        if I.vRP.getUserId(source)~=id or tonumber(row.user_id)~=id then return end
        if row.state=='release_pending' or tonumber(row.ends_at)<=os.time() then
            if restore(source,row) then
                I.Store.update('UPDATE ic_admin_discipline SET state=? WHERE id=?',{row.state=='release_pending' and 'archived' or 'expired',row.id});applied[source]=nil
            end
        elseif not applied[source] or tonumber(applied[source].id)~=tonumber(row.id) then apply(source,row) end
    end
end
AddEventHandler('vRP:playerSpawn',function(_,source) SetTimeout(3000,function()local ok=pcall(reconcile,source);if not ok then print('^1[ic_admin]^7 Falha ao restaurar disciplina. Consulte o banco privado.') end end) end)
AddEventHandler('playerDropped',function()applied[source]=nil end)
AddEventHandler('onResourceStop',function(resource)
    if resource~=GetCurrentResourceName() then return end
    for source,row in pairs(applied) do pcall(restore,source,row) end
end)
CreateThread(function()
    while true do
        Wait(10000)
        if I.active() then for _,s in ipairs(GetPlayers()) do pcall(reconcile,tonumber(s)) end end
    end
end)
