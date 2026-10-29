local I=ICAdmin
I.userLocks={}
-- Explicit ownership registry. New tables are NEVER added to mutation SQL by introspection.
-- Rows in unreviewed candidate relations block maintenance rather than being guessed.
local owned={
    vrp_user_ids='user_id',vrp_user_data='user_id',vrp_user_identities='user_id',vrp_users_infos='user_id',
    vrp_user_veiculos='user_id',vrp_user_vehicles='user_id',flow_attachs='user_id',zo_attachs='user_id',
    user_clothes='user_id',bm_daily='user_id',bm_registration='user_id',mbox_hours='user_id',
    m_pass_v2='user_id',velocity_pass_v2='user_id',vrp_colect='user_id',player_playtime='user_id',
    m_empregos='user_id',m_ponto='user_id',velocity_ponto='user_id'
}
local historical={ic_admin_audit=true,ic_admin_operations=true,ic_admin_discipline=true}
local handled={vrp_users={id=true},ic_admin_subjects={user_id=true},mirtin_bans={user_id=true},mirtin_bans_hwid={id=true},mirtin_bans_ip={user_id=true}}
for tableName,column in pairs(owned) do handled[tableName]={[column]=true} end
local function quote(identifier)
    assert(identifier:match('^[%w_]+$'),'Invalid registry identifier');return '`'..identifier..'`'
end
local function candidate(name)
    return name=='user_id' or name=='owner_id' or name=='player_id' or name=='passaporte' or name=='passport'
        or name=='invite_userid' or name=='sender_id' or name=='receiver_id' or name=='owner' or name=='proprietario'
end
local function preflight(id,changing)
    local rows=I.Store.query('SELECT TABLE_NAME,COLUMN_NAME,DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() ORDER BY TABLE_NAME,ORDINAL_POSITION')
    local actual={};local blockers={};local footprint={}
    local engines={}
    for _,row in ipairs(I.Store.query('SELECT TABLE_NAME,ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE()')) do engines[row.TABLE_NAME]=row.ENGINE end
    for _,row in ipairs(rows) do
        local name,column=row.TABLE_NAME,row.COLUMN_NAME
        actual[name]=actual[name] or {};actual[name][column]=row.DATA_TYPE
        if not historical[name] and candidate(column) and not (handled[name] and handled[name][column]) then
            -- This is a read-only detector, never a source of generated DELETE/UPDATE statements.
            local count=I.Store.query('SELECT COUNT(*) AS n FROM '..quote(name)..' WHERE '..quote(column)..'=?',{id})[1]
            if tonumber(count and count.n)>0 then blockers[#blockers+1]=name..'.'..column end
        end
    end
    for name,column in pairs(owned) do
        if actual[name] and actual[name][column] then
            local count=I.Store.query('SELECT COUNT(*) AS n FROM '..quote(name)..' WHERE '..quote(column)..'=?',{id})[1]
            footprint[#footprint+1]={table=name,column=column,count=tonumber(count and count.n) or 0}
        end
    end
    -- Serialized stores have ownership semantics outside relational columns. A populated
    -- opaque store must be reviewed before rewriting a passport; no substring rewrites.
    for _,name in ipairs({'vrp_srv_data','trafico','mirtin_organization_members','mirtin_users_homes'}) do
        if actual[name] then
            local row=I.Store.query('SELECT COUNT(*) AS n FROM '..quote(name))[1]
            if tonumber(row and row.n)>0 then blockers[#blockers+1]=name..' (armazenamento serializado sem adaptador de manutenção)' end
        end
    end
    -- Existing ban mappings are not reused by a new numeric passport. Active bans block
    -- wipe; changing IDs carries mappings atomically instead.
    local subject=I.subject(id)
    local active=I.Store.query("SELECT id FROM ic_admin_discipline WHERE subject_key=? AND kind='warning' AND state IN ('active','release_pending') LIMIT 1",{subject})
    if active[1] then blockers[#blockers+1]='castigo ativo ou retorno pendente' end
    if not changing and I.Adapter.banActive(id) then blockers[#blockers+1]='banimento ativo' end
    local transactional={'vrp_users','ic_admin_subjects','ic_admin_discipline','ic_admin_documents','mirtin_bans','mirtin_bans_hwid','mirtin_bans_ip'}
    for _,entry in ipairs(footprint) do transactional[#transactional+1]=entry.table end
    for _,name in ipairs(transactional) do if engines[name]~='InnoDB' then blockers[#blockers+1]=name..' (engine não transacional)' end end
    if #blockers>0 then I.fail('UNHANDLED_RELATION','Manutenção recusada. Relações precisam de tratamento: '..table.concat(blockers,', ')) end
    return footprint,subject
end
local function documentsForUser(id,newId,wiping)
    local statements={}
    local function guardedUpdate(key,value,revision)
        statements[#statements+1]={query='INSERT INTO ic_admin_schema(version) SELECT 1 WHERE NOT EXISTS (SELECT 1 FROM ic_admin_documents WHERE doc_key=? AND revision=? FOR UPDATE)',values={key,revision}}
        statements[#statements+1]={query='UPDATE ic_admin_documents SET payload=?,revision=revision+1 WHERE doc_key=? AND revision=?',values={json.encode(value),key,revision}}
    end
    local doc,rev=I.Store.get('vip_assignments',{assignments={}});local changed=false
    for _,row in ipairs(doc.assignments or {}) do
        if tonumber(row.userId)==id then
            if row.state=='applying' or row.state=='uncertain' then I.fail('OPERATION_UNCERTAIN','Há entrega VIP pendente de conferência.') end
            if wiping then row.state='archived';row.archivedUserId=id else row.userId=newId end
            changed=true
        end
    end
    if changed then guardedUpdate('vip_assignments',doc,rev) end
    local calls,callsRev=I.Store.get('calls',{calls={},ratings={}});changed=false
    for _,call in ipairs(calls.calls or {}) do
        if tonumber(call.requesterId)==id or tonumber(call.acceptedBy)==id then
            if call.state=='open' or call.state=='accepted' then I.fail('ACTIVE_CALL','Finalize os chamados que envolvem o passaporte.') end
            if not wiping then
                if tonumber(call.requesterId)==id then call.requesterId=newId end
                if tonumber(call.acceptedBy)==id then call.acceptedBy=newId end
                changed=true
            end
        end
    end
    if not wiping then
        for _,rating in ipairs(calls.ratings or {}) do
            if tonumber(rating.staffId)==id then rating.staffId=newId;changed=true end
            if tonumber(rating.requesterId)==id then rating.requesterId=newId;changed=true end
        end
    end
    if changed then guardedUpdate('calls',calls,callsRev) end
    return statements
end
local function maintenance(ctx,p,changing)
    I.requireOwner(ctx)
    local id=I.target(p.targetId,false);local reason=I.text(p.reason,500,true,'Motivo')
    if I.int(p.confirmId,1,2147483647,'Confirmação')~=id then I.fail('CONFIRMATION_REQUIRED','Digite o passaporte para confirmar.') end
    if I.vRP.getUserSource(id) then I.fail('PLAYER_ONLINE','O jogador precisa estar desconectado.') end
    local newId=changing and I.int(p.newId,1,2147483647,'Novo passaporte') or nil
    if newId==id then I.fail('INVALID_INPUT','O novo passaporte deve ser diferente.') end
    if newId and I.Store.query('SELECT id FROM vrp_users WHERE id=?',{newId})[1] then I.fail('ID_IN_USE','ID JÁ EM USO') end
    return I.withLock('maintenance',function()
        return I.withLock('vip_assignments',function()
            return I.withLock('calls',function()
                I.userLocks[id]=true;if newId then I.userLocks[newId]=true end
                local ok,result=pcall(function()
                    if I.vRP.getUserSource(id) or (newId and I.vRP.getUserSource(newId)) then I.fail('PLAYER_ONLINE','Passaporte conectado durante a preparação.') end
                    local footprint,subject=preflight(id,changing)
                    local statements=documentsForUser(id,newId,not changing)
                    -- Disconnected writer state and the registry are checked before the transaction.
                    for _,entry in ipairs(footprint) do
                        if changing then statements[#statements+1]={query='UPDATE '..quote(entry.table)..' SET '..quote(entry.column)..'=? WHERE '..quote(entry.column)..'=?',values={newId,id}}
                        else statements[#statements+1]={query='DELETE FROM '..quote(entry.table)..' WHERE '..quote(entry.column)..'=?',values={id}} end
                    end
                    if changing then
                        for _,entry in ipairs({{'mirtin_bans','user_id'},{'mirtin_bans_hwid','id'},{'mirtin_bans_ip','user_id'}}) do
                            statements[#statements+1]={query='UPDATE '..quote(entry[1])..' SET '..quote(entry[2])..'=? WHERE '..quote(entry[2])..'=?',values={newId,id}}
                        end
                        statements[#statements+1]={query='UPDATE ic_admin_subjects SET user_id=? WHERE subject_key=?',values={newId,subject}}
                        statements[#statements+1]={query='UPDATE ic_admin_discipline SET user_id=? WHERE subject_key=?',values={newId,subject}}
                        statements[#statements+1]={query='UPDATE vrp_users SET id=? WHERE id=?',values={newId,id}}
                    else
                        for _,entry in ipairs({{'mirtin_bans','user_id'},{'mirtin_bans_hwid','id'},{'mirtin_bans_ip','user_id'}}) do statements[#statements+1]={query='DELETE FROM '..quote(entry[1])..' WHERE '..quote(entry[2])..'=?',values={id}} end
                        statements[#statements+1]={query="UPDATE ic_admin_discipline SET state='archived' WHERE subject_key=?",values={subject}}
                        statements[#statements+1]={query='UPDATE ic_admin_subjects SET user_id=NULL WHERE subject_key=?',values={subject}}
                        statements[#statements+1]={query='DELETE FROM vrp_users WHERE id=?',values={id}}
                    end
                    I.effect(ctx)
                    if not I.Store.transaction(statements) then I.fail('TRANSACTION_FAILED','Manutenção não confirmada; confira o banco antes de repetir.') end
                    exports['vrp']:icAdminForgetUser(id)
                    if newId then exports['vrp']:icAdminForgetUser(newId) end
                    exports['vrp']:icAdminRefreshBanCaches()
                    I.audit(changing and 'maintenance.changeId' or 'maintenance.wipe',ctx,id,{newId=newId,subjectKey=subject,reason=reason,footprint=footprint})
                    return {id=id,newId=newId,completed=true}
                end)
                I.userLocks[id]=nil;if newId then I.userLocks[newId]=nil end
                if not ok then error(result,0) end
                return result
            end)
        end)
    end)
end
I.register('maintenance.wipe',{permission='maintenance.wipe',mutating=true,handler=function(ctx,p)return maintenance(ctx,p,false) end})
I.register('maintenance.changeId',{permission='maintenance.changeId',mutating=true,handler=function(ctx,p)return maintenance(ctx,p,true) end})
-- The vRP resolver also checks this lock after resolving identifiers.
exports('isUserInMaintenance',function(id) return next(I.userLocks)~=nil or I.userLocks[tonumber(id)]==true end)
AddEventHandler('playerConnecting',function(_,setKickReason)
    if next(I.userLocks) then setKickReason('Manutenção administrativa em andamento. Reconecte em instantes.');CancelEvent() end
end)
