local I=ICAdmin
local function bootstrap(ctx,public)
    local token=I.newSession(ctx.source,ctx.userId)
    local data={sessionId=token,departments=I.Config.departments,mode=I.active() and 'active' or 'preview',config={brand=I.Config.brand,monitor=I.Config.monitor,tabs=I.Config.tabs}}
    if not public then
        local identity=I.vRP.getUserIdentity(ctx.userId) or {}
        data.admin={id=ctx.userId,name=(identity.nome or '')..' '..(identity.sobrenome or ''),role=ctx.role}
        data.permissions=I.permissions(ctx.userId)
        if I.allowed(ctx.userId,'view_players') then data.players=I.onlinePlayers() end
        data.stats={players=#GetPlayers()}
    end
    return data
end
I.register('bootstrap',{handler=function(ctx)return bootstrap(ctx,false) end})
I.register('player.bootstrap',{public=true,handler=function(ctx)return bootstrap(ctx,true) end})
I.register('players.list',{permission='view_players',handler=function()return {players=I.onlinePlayers(),stats={players=#GetPlayers()}} end})
I.register('map.players',{permission='view_map',handler=function()
    local players={}
    for _,row in ipairs(I.onlinePlayers()) do players[#players+1]={id=row.id,name=row.name,coords=row.coords} end
    return {players=players}
end})
I.definitions.inspect_inventory={key='inspect_inventory',label='Inspecionar inventário'}
I.register('players.snapshot',{permission='view_players',handler=function(ctx,p)
    local snapshot=I.snapshot(p.targetId)
    if not I.allowed(ctx.userId,'inspect_inventory') then snapshot.inventory=nil end
    if not I.allowed(ctx.userId,'view_warnings') then snapshot.warnings=nil end
    return snapshot
end})
I.register('players.lookup',{permission='catch_rg',handler=function(ctx,p)
    local snapshot=I.snapshot(p.targetId)
    if not I.allowed(ctx.userId,'inspect_inventory') then snapshot.inventory=nil end
    if not I.allowed(ctx.userId,'view_warnings') then snapshot.warnings=nil end
    return snapshot
end})
I.register('permissions.get',{handler=function(ctx)I.requireOwner(ctx);return I.permissions(ctx.userId) end})
I.register('permissions.update',{permission='permissions_manage',mutating=true,handler=function(ctx,p)
    I.requireOwner(ctx);local key=I.text(p.key,96,true,'Função')
    if not I.definitions[key] or I.Config.ownerOnly[key] then I.fail('INVALID_PERMISSION','Permissão não configurável.') end
    if type(p.roles)~='table' then I.fail('INVALID_INPUT','Cargos inválidos.') end
    return I.withLock('permissions',function()
        local data,rev=I.Store.get('permissions',{actions={}});data.actions=data.actions or {}
        local roles={};for _,role in ipairs({'admin','moderador','suporte'}) do
            if type(p.roles[role])~='boolean' then I.fail('INVALID_INPUT','Seleção de cargos inválida.') end
            roles[role]=p.roles[role]
        end
        data.actions[key]=roles
        I.requireOwner(ctx);I.effect(ctx)
        if not I.Store.put('permissions',data,rev) then I.fail('CONFLICT','Permissões foram alteradas. Atualize.') end
        for source in pairs(I.sessions) do if source~=ctx.source then I.closeSession(source) end end
        TriggerEvent('ic_admin:permissionsChanged')
        return I.permissions(ctx.userId)
    end)
end})
MySQL.ready(function()
    local ok,rows=pcall(I.Store.query,'SELECT MAX(version) AS version FROM ic_admin_schema')
    if not ok or tonumber(rows[1] and rows[1].version)~=I.Config.schemaVersion then
        print('^3[ic_admin]^7 Esquema indisponível/incompatível. Execute scripts/ic-admin-migrate.py explicitamente; nenhuma migração automática foi aplicada.')
        return
    end
    local required={ic_admin_schema={'version'},ic_admin_documents={'doc_key','payload','revision'},
        ic_admin_operations={'operation_key','actor_id','method','payload','state','result'},
        ic_admin_audit={'id','action','actor_id','actor_name','target_id','target_name','payload','created_at'},
        ic_admin_subjects={'subject_key','user_id'},ic_admin_discipline={'id','subject_key','user_id','actor_id','kind','reason','starts_at','ends_at','state','return_state'},
        mirtin_bans={'user_id','owner','staff'}}
    for _,name in ipairs({'ic_admin_calls','ic_admin_ratings','ic_admin_vip_assignments'}) do
        required[name]={'id','owner_id','subject_key','actor_id','actor_subject','state','department','created_at','expires_at','payload','revision'}
    end
    local checked,valid=pcall(function()
        local columns=I.Store.query("SELECT TABLE_NAME,COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE()")
        local engines=I.Store.query("SELECT TABLE_NAME,ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE()")
        local found,engineMap={},{}
        for _,row in ipairs(columns) do found[row.TABLE_NAME]=found[row.TABLE_NAME] or {};found[row.TABLE_NAME][row.COLUMN_NAME]=true end
        for _,row in ipairs(engines) do engineMap[row.TABLE_NAME]=row.ENGINE end
        for name,fields in pairs(required) do
            if engineMap[name]~='InnoDB' then return false end
            for _,field in ipairs(fields) do if not (found[name] and found[name][field]) then return false end end
        end
        return true
    end)
    if not checked or not valid then print('^1[ic_admin]^7 Esquema parcial ou engine incompatível. Execute a verificação operacional.');return end
    -- Persisted pending operations may have crossed a process boundary: never replay them.
    I.Store.update("UPDATE ic_admin_operations SET state='uncertain' WHERE state='pending'")
    I.ready=true
    print(('^2[ic_admin]^7 Banco pronto. Modo: %s. Homologação GTA ainda é necessária.'):format(GetConvar('ic_admin_mode','preview')))
    TriggerEvent('ic_admin:ready')
    local previous=GetConvar('ic_admin_previous_resource','')
    print('[ic_admin:operational] '..json.encode({schemaVersion=I.Config.schemaVersion,mode=GetConvar('ic_admin_mode','preview'),
        active=I.active(),provider=GetConvar('ic_admin_service_resource',''),legacyState=previous~='' and GetResourceState(previous) or 'absent'}))
end)
CreateThread(function()
    while true do
        Wait(5000)
        for source,session in pairs(I.sessions) do
            if session.expires<os.time() or I.vRP.getUserId(source)~=session.userId then I.closeSession(source) end
        end
    end
end)
