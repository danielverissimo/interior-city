-- Organization deletion: durable intent, guarded SQL commit, forward-only projections.
-- All operations use existing owning formats; no vendor protected code is loaded.
local S=ICConfigServer
local O={previews={}}
S.Organizations=O
local tables={
    {'mirtin_orgs_goals','organization'}, {'mirtin_orgs_player_infos','organization'},
    {'mirtin_orgs_chat','organization'}, {'sjr_logs','organization'},
    {'mirtin_organization_members','group_type'}, {'mirtin_orgs_info','organization'}
}
function O.query(sql,values) return MySQL.query.await(sql,values or {}) or {} end
function O.transaction(queries) return MySQL.transaction.await(queries)==true end
local function canonical(value)
    if type(value)~='table' then return json.encode(value) end
    local keys={};for key in pairs(value) do keys[#keys+1]=key end
    table.sort(keys,function(a,b)return tostring(a)<tostring(b) end)
    local out={}
    for _,key in ipairs(keys) do out[#out+1]=json.encode(tostring(key))..':'..canonical(value[key]) end
    return '{'..table.concat(out,',')..'}'
end
local function decoded(value)
    local ok,data=pcall(json.decode,value or '')
    if not ok or type(data)~='table' then S.fail('CORRUPT_STATE','Há dados de organização ou jogador inválidos; nada foi excluído.') end
    return data
end
function O.schema(optional)
    local ok,rows=pcall(O.query,'SELECT MAX(version) version FROM ic_config_schema')
    if ok and rows[1] and rows[1].version~=nil and tonumber(rows[1].version)~=1 then
        S.fail('SCHEMA_REQUIRED','Versão de esquema IC Config incompatível; confira a migração antes de continuar.')
    end
    if not ok or tonumber(rows[1] and rows[1].version)~=1 then
        if optional then return false end
        S.fail('SCHEMA_REQUIRED','Instale e verifique o esquema IC Config v1 antes de excluir organizações.')
    end
    local required={ic_config_schema=true,ic_config_org_deletions=true,ic_config_deleted_groups=true,vrp_user_data=true}
    for _,entry in ipairs(tables) do required[entry[1]]=true end
    for _,row in ipairs(O.query('SELECT TABLE_NAME,ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE()')) do
        if required[row.TABLE_NAME] and row.ENGINE=='InnoDB' then required[row.TABLE_NAME]=nil end
    end
    if next(required) then S.fail('SCHEMA_REQUIRED','As tabelas da exclusão precisam existir e usar InnoDB.') end
    local columns={
        ic_config_schema={version=true},
        ic_config_org_deletions={org_name=true,operation_id=true,phase=true,actor_id=true,payload=true,updated_at=true},
        ic_config_deleted_groups={group_name=true,operation_id=true},
        vrp_user_data={user_id=true,dkey=true,dvalue=true}
    }
    for _,entry in ipairs(tables) do columns[entry[1]]={[entry[2]]=true} end
    for _,row in ipairs(O.query('SELECT TABLE_NAME,COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE()')) do
        if columns[row.TABLE_NAME] then columns[row.TABLE_NAME][row.COLUMN_NAME]=nil end
    end
    for _,fields in pairs(columns) do if next(fields) then S.fail('SCHEMA_REQUIRED','Uma tabela possui contrato incompatível com a exclusão.') end end
    local triggers={ic_config_userdata_insert=true,ic_config_userdata_update=true}
    for i=1,6 do triggers['ic_config_org_'..i..'_insert']=true;triggers['ic_config_org_'..i..'_update']=true end
    for _,row in ipairs(O.query('SELECT TRIGGER_NAME FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA=DATABASE()')) do triggers[row.TRIGGER_NAME]=nil end
    if next(triggers) then S.fail('SCHEMA_REQUIRED','As proteções contra gravações atrasadas não estão instaladas.') end
    return true
end
local function journal(orgName)
    return O.query('SELECT org_name,operation_id,phase,actor_id,payload FROM ic_config_org_deletions WHERE org_name=?',{orgName})[1]
end
local function countsFor(orgName)
    local counts={}
    for _,entry in ipairs(tables) do
        local rows=O.query('SELECT COUNT(*) count FROM '..entry[1]..' WHERE '..entry[2]..'=?',{orgName})
        counts[entry[1]]=tonumber(rows[1] and rows[1].count) or 0
    end
    return counts
end
local function userChanges(names)
    local chosen={};for _,name in ipairs(names) do chosen[name]=true end
    local changes={}
    for _,row in ipairs(O.query('SELECT user_id,dvalue FROM vrp_user_data WHERE dkey=? ORDER BY user_id',{'vRP:datatable'})) do
        local data=decoded(row.dvalue);local changed=false
        for _,field in ipairs({'groups','vip_group_expirations'}) do
            if data[field]~=nil and type(data[field])~='table' then S.fail('CORRUPT_STATE','Um datatable possui cargos em formato inválido.') end
            for name in pairs(chosen) do if data[field] and data[field][name]~=nil then data[field][name]=nil;changed=true end end
        end
        if changed then changes[#changes+1]={userId=tonumber(row.user_id),before=row.dvalue,after=json.encode(data)} end
    end
    return changes
end
local function collect(ctx,orgName)
    O.schema()
    local current=journal(orgName)
    if current and current.phase~='recreated' then S.fail('RECOVERY_REQUIRED','Existe uma exclusão registrada para este nome; consulte o estado e retome a operação.') end
    local groupPlan=S.call(ctx,'Vrp','icConfigOrganizationPlan',orgName)
    local orgPlan=S.call(ctx,'Orgs','icConfigOrganizationPlan',orgName)
    if type(groupPlan)~='table' or type(orgPlan)~='table' or not orgPlan.exists or #groupPlan.names==0 then
        S.fail('NOT_FOUND','A organização e seus cargos não foram encontrados em conjunto.')
    end
    if type(groupPlan.raw)~='string' or type(orgPlan.raw)~='string' then S.fail('CORRUPT_STATE','Configuração persistida indisponível.') end
    local names={}
    for _,name in ipairs(S.call(ctx,'Orgs','getManagedOrganizationNames')) do
        local rows=O.query('SELECT ? = ? equal_name',{orgName,name})
        if name~=orgName and tonumber(rows[1] and rows[1].equal_name)==1 then S.fail('CONFLICT','Há organizações cujos nomes colidem na comparação do banco.') end
        names[#names+1]=name
    end
    local changes=userChanges(groupPlan.names)
    local counts={groups=#groupPlan.names,onlineUsers=#(groupPlan.online or {}),offlineUsers=#changes,tables=countsFor(orgName)}
    return {orgName=orgName,groups=groupPlan.names,counts=counts,changes=changes,
        groupsRaw=groupPlan.raw,orgRaw=orgPlan.raw}
end
local function publicPreview(plan,id)
    return {previewId=id,orgName=plan.orgName,confirmation='EXCLUIR '..plan.orgName,expiresAt=plan.expiresAt,
        groups=plan.groups,counts=plan.counts,warnings={
            'A exclusão remove cargos, membros, metas, chat, logs e informações da organização.',
            'A organização não pode ter membros conectados. Uma intenção confirmada é retomada até concluir; não restaura dados SQL já excluídos.'}}
end
local function owner(key,method,...)
    local resource=ICConfig.Resources[key]
    if GetResourceState(resource)~='started' then S.fail('RECOVERY_REQUIRED','Inicie os recursos de cargos e organizações para concluir a projeção.') end
    local args=table.pack(...)
    local ok,result=pcall(function()return exports[resource][method](nil,table.unpack(args,1,args.n)) end)
    if not ok or result~=true then S.fail('RECOVERY_REQUIRED','Uma projeção de configuração não foi confirmada. A operação continua registrada para retomada.') end
end
function O.finish(row)
    local payload=decoded(row.payload)
    local names=payload.groups
    if type(names)~='table' or payload.orgName~=row.org_name then S.fail('CORRUPT_STATE','Diário de exclusão inválido.') end
    -- After durable intent these internal owner calls complete that intent even if
    -- the initiating player disconnects. They cannot be called through the NUI.
    owner('Vrp','icConfigOrganizationFreeze',row.operation_id,row.org_name,names)
    if row.phase=='prepared' then
        -- This also drains the organization's live membership/cache projection.
        owner('Orgs','icConfigOrganizationFinalize',row.org_name,row.operation_id)
        local queries={
            {query="INSERT INTO ic_config_schema(version) SELECT 1 WHERE NOT EXISTS (SELECT 1 FROM ic_config_org_deletions WHERE operation_id=? AND phase='prepared' FOR UPDATE)",values={row.operation_id}}
        }
        for _,change in ipairs(userChanges(names)) do
            queries[#queries+1]={query='INSERT INTO ic_config_schema(version) SELECT 1 WHERE NOT EXISTS (SELECT 1 FROM vrp_user_data WHERE user_id=? AND dkey=? AND BINARY dvalue=BINARY ? FOR UPDATE)',values={change.userId,'vRP:datatable',change.before}}
            queries[#queries+1]={query='UPDATE vrp_user_data SET dvalue=? WHERE user_id=? AND dkey=?',values={change.after,change.userId,'vRP:datatable'}}
        end
        for _,entry in ipairs(tables) do queries[#queries+1]={query='DELETE FROM '..entry[1]..' WHERE '..entry[2]..'=?',values={row.org_name}} end
        queries[#queries+1]={query="UPDATE ic_config_org_deletions SET phase='sql_committed' WHERE operation_id=? AND phase='prepared'",values={row.operation_id}}
        local ok=pcall(function() if not O.transaction(queries) then S.fail('RECOVERY_REQUIRED','O banco recusou a transação; retome após conferir os escritores.') end end)
        local actual=journal(row.org_name)
        if not actual or actual.operation_id~=row.operation_id or actual.phase=='prepared' then
            S.fail('RECOVERY_REQUIRED',ok and 'O commit não foi confirmado; consulte e retome a operação.' or 'A exclusão SQL não foi confirmada. A intenção está registrada e pode ser retomada.')
        end
        row=actual
    end
    if row.phase~='sql_committed' and row.phase~='complete' then S.fail('CONFLICT','Estado de exclusão incompatível.') end
    owner('Vrp','icConfigOrganizationFinalize',row.operation_id,row.org_name,names)
    owner('Orgs','icConfigOrganizationFinalize',row.org_name,row.operation_id)
    O.query("UPDATE ic_config_org_deletions SET phase='complete' WHERE operation_id=? AND phase IN ('sql_committed','complete')",{row.operation_id})
    local actual=journal(row.org_name)
    if not actual or actual.phase~='complete' then S.fail('RECOVERY_REQUIRED','Finalize novamente para confirmar a conclusão do diário.') end
    return {operationId=row.operation_id,state='complete',orgName=row.org_name,counts=payload.counts,message='Organização, cargos e vínculos excluídos; configurações persistentes confirmadas.'}
end

S.register('previewFacDeletion',false,function(ctx,p)
    local orgName=S.text(p.orgName)
    local plan=collect(ctx,orgName)
    local id=('%x:%x:%x'):format(os.time(),ctx.source,math.random(1,0x7fffffff))
    plan.previewId=id;plan.source=ctx.source;plan.actor=ctx.userId;plan.expiresAt=os.time()+120
    for key,old in pairs(O.previews) do if old.expiresAt<os.time() or old.source==ctx.source then O.previews[key]=nil end end
    O.previews[id]=plan
    return publicPreview(plan,id)
end)

S.register('deleteFacBundle',true,function(ctx,p)
    local orgName=S.text(p.orgName);local previewId=S.text(p.previewId)
    local plan=O.previews[previewId]
    if not plan or plan.source~=ctx.source or plan.actor~=ctx.userId or plan.orgName~=orgName or plan.expiresAt<os.time() then
        S.fail('STALE_PREVIEW','Refaça a prévia antes de confirmar a exclusão.')
    end
    if p.confirmation~='EXCLUIR '..orgName then S.fail('CONFIRMATION_REQUIRED','Digite exatamente a frase apresentada na prévia.') end
    local fresh=collect(ctx,orgName)
    if canonical(fresh)~=canonical({orgName=plan.orgName,groups=plan.groups,counts=plan.counts,changes=plan.changes,groupsRaw=plan.groupsRaw,orgRaw=plan.orgRaw}) then
        S.fail('CONFLICT','O estado mudou desde a prévia; confira uma nova prévia.')
    end
    if fresh.counts.onlineUsers>0 then S.fail('ONLINE_MEMBERS','Desconecte os membros desta organização antes de excluir.') end
    S.authorize(ctx.source,ctx.userId)
    local operationId='org:'..previewId
    local payload=json.encode({orgName=orgName,groups=fresh.groups,counts=fresh.counts})
    if S.call(ctx,'Vrp','icConfigOrganizationArm')~=true then
        S.fail('RECOVERY_REQUIRED','Não foi possível preparar a recuperação persistente de permissões; nenhuma intenção SQL foi criada.')
    end
    local queries={
        {query="INSERT INTO ic_config_schema(version) SELECT 1 WHERE EXISTS (SELECT 1 FROM ic_config_org_deletions WHERE org_name=? AND phase<>'recreated' FOR UPDATE)",values={orgName}},
        {query="INSERT INTO ic_config_org_deletions(org_name,operation_id,phase,actor_id,payload) VALUES(?,?,'prepared',?,?) ON DUPLICATE KEY UPDATE operation_id=VALUES(operation_id),phase='prepared',actor_id=VALUES(actor_id),payload=VALUES(payload)",values={orgName,operationId,ctx.userId,payload}}
    }
    for _,name in ipairs(fresh.groups) do queries[#queries+1]={query='INSERT INTO ic_config_deleted_groups(group_name,operation_id) VALUES(?,?)',values={name,operationId}} end
    O.previews[previewId]=nil
    local ok=pcall(O.transaction,queries)
    local row=journal(orgName)
    if not row or row.operation_id~=operationId then S.fail('CONFLICT',ok and 'A intenção não foi confirmada; refaça a prévia.' or 'O banco recusou a intenção; refaça a prévia.') end
    return O.finish(row)
end)

S.register('getFacDeletionStatus',false,function(_,p)
    O.schema()
    local row=journal(S.text(p.orgName))
    if not row then return {state='none'} end
    local payload=decoded(row.payload)
    return {operationId=row.operation_id,orgName=row.org_name,state=row.phase,counts=payload.counts,
        canResume=row.phase=='prepared' or row.phase=='sql_committed'}
end)
S.register('resumeFacDeletion',true,function(_,p)
    O.schema()
    local row=journal(S.text(p.orgName))
    if not row or row.operation_id~=S.text(p.operationId) or row.phase=='recreated' then S.fail('NOT_FOUND','Operação de exclusão não encontrada.') end
    return O.finish(row)
end)

-- Reusing a deleted name is an explicit new creation. Archive completed guards
-- only after checking the deletion, then clear the owning tombstones idempotently.
function O.beforeCreation(ctx,orgName)
    if not O.schema(true) then return end
    local row=journal(orgName)
    if not row then return end
    if row.phase~='complete' and row.phase~='recreated' then S.fail('RECOVERY_REQUIRED','Conclua a exclusão registrada antes de recriar a organização.') end
    local payload=decoded(row.payload)
    if #userChanges(payload.groups)>0 then S.fail('CONFLICT','Ainda há vínculos antigos; retome a exclusão antes de recriar.') end
    for _,count in pairs(countsFor(orgName)) do if count>0 then S.fail('CONFLICT','Ainda há dados da organização anterior; confira a exclusão.') end end
    owner('Vrp','icConfigOrganizationRecreate',row.operation_id,orgName,payload.groups)
    owner('Orgs','icConfigOrganizationRecreate',orgName,row.operation_id)
    if not O.transaction({
        {query="UPDATE ic_config_org_deletions SET phase='recreated' WHERE operation_id=? AND phase IN ('complete','recreated')",values={row.operation_id}},
        {query='DELETE FROM ic_config_deleted_groups WHERE operation_id=?',values={row.operation_id}}
    }) then S.fail('RECOVERY_REQUIRED','A liberação do nome não foi confirmada; confira o diário antes de continuar.') end
    S.authorize(ctx.source,ctx.userId)
end
