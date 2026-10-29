local I=ICAdmin
I.userLocks={}
-- Explicit ownership registry. New tables are NEVER added to mutation SQL by introspection.
-- Rows in unreviewed candidate relations block maintenance rather than being guessed.
local owned={
    vrp_user_ids='user_id',vrp_user_data='user_id',vrp_user_identities='user_id',vrp_users_infos='user_id',
    vrp_user_veiculos='user_id',vrp_user_vehicles='user_id',flow_attachs='user_id',zo_attachs='user_id',
    user_clothes='user_id',bm_daily='user_id',bm_registration='user_id',mbox_hours='user_id',
    m_pass_v2='user_id',velocity_pass_v2='user_id',vrp_colect='user_id',player_playtime='user_id',
    m_empregos='user_id',m_ponto='user_id',velocity_ponto='user_id',
    mirtin_organization_members='user_id',mirtin_orgs_player_infos='user_id',mirtin_orgs_rewards='user_id',core_homes='user_id'
}
local historical={ic_admin_audit=true,ic_admin_operations=true,ic_admin_discipline=true,ic_admin_calls=true,ic_admin_ratings=true,ic_admin_vip_assignments=true}
local handled={vrp_users={id=true},ic_admin_subjects={user_id=true},mirtin_bans={user_id=true},mirtin_bans_hwid={id=true},mirtin_bans_ip={user_id=true}}
handled.mirtin_users_homes={proprietario=true};handled.trafico={user_id=true}
-- core_homes.owner is a boolean flag, not a passport (residences/server-side/prepares.lua).
handled.core_homes={user_id=true,owner=true}
for tableName,column in pairs(owned) do handled[tableName]=handled[tableName] or {};handled[tableName][column]=true end
local function quote(identifier)
    assert(identifier:match('^[%w_]+$'),'Invalid registry identifier');return '`'..identifier..'`'
end
local function candidate(name)
    return name=='user_id' or name=='owner_id' or name=='player_id' or name=='passaporte' or name=='passport'
        or name=='invite_userid' or name=='sender_id' or name=='receiver_id' or name=='owner' or name=='proprietario'
        or name=='requested_by' or name=='passport_id' or name=='target_id' or name=='para' or name=='de'
        or name=='author_id' or name=='staff_id' or name=='userId' or name=='playerId' or name=='citizenid'
end
local function preflight(id,changing,newId)
    local rows=I.Store.query('SELECT TABLE_NAME,COLUMN_NAME,DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() ORDER BY TABLE_NAME,ORDINAL_POSITION')
    local actual={};local blockers={};local footprint={}
    local engines={}
    for _,row in ipairs(I.Store.query('SELECT TABLE_NAME,ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE()')) do engines[row.TABLE_NAME]=row.ENGINE end
    local foreign={}
    for _,row in ipairs(I.Store.query("SELECT TABLE_NAME,COLUMN_NAME FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA=DATABASE() AND REFERENCED_TABLE_NAME='vrp_users' AND REFERENCED_COLUMN_NAME='id'")) do
        foreign[row.TABLE_NAME..'.'..row.COLUMN_NAME]=true
    end
    for _,row in ipairs(rows) do
        local name,column=row.TABLE_NAME,row.COLUMN_NAME
        actual[name]=actual[name] or {};actual[name][column]=row.DATA_TYPE
        if not historical[name] and (candidate(column) or foreign[name..'.'..column]) and not (handled[name] and handled[name][column]) then
            -- This is a read-only detector, never a source of generated DELETE/UPDATE statements.
            local count=I.Store.query('SELECT COUNT(*) AS n FROM '..quote(name)..' WHERE '..quote(column)..'=?',{id})[1]
            if tonumber(count and count.n)>0 then blockers[#blockers+1]=name..'.'..column end
        end
        if newId and not historical[name] and name~='vrp_users' and (foreign[name..'.'..column] or (candidate(column) and not (name=='core_homes' and column=='owner'))) then
            local count=I.Store.query('SELECT COUNT(*) AS n FROM '..quote(name)..' WHERE '..quote(column)..'=?',{newId})[1]
            if tonumber(count and count.n)>0 then blockers[#blockers+1]=name..'.'..column..' (destino com vínculos)' end
        end
    end
    for name,column in pairs(owned) do
        if actual[name] and actual[name][column] then
            local count=I.Store.query('SELECT COUNT(*) AS n FROM '..quote(name)..' WHERE '..quote(column)..'=?',{id})[1]
            footprint[#footprint+1]={table=name,column=column,count=tonumber(count and count.n) or 0}
        end
    end
    -- Existing ban mappings are not reused by a new numeric passport. Active bans block
    -- wipe; changing IDs carries mappings atomically instead.
    local subject=I.subject(id)
    local active=I.Store.query("SELECT id FROM ic_admin_discipline WHERE subject_key=? AND kind='warning' AND state IN ('active','release_pending') LIMIT 1",{subject})
    if active[1] then blockers[#blockers+1]='castigo ativo ou retorno pendente' end
    if not changing and I.Adapter.banActive(id) then blockers[#blockers+1]='banimento ativo' end
    local extra,extraTables,extraSummary=I.Ownership.prepare(actual,id,newId,not changing)
    for _,entry in ipairs(extraSummary) do footprint[#footprint+1]=entry end
    local transactional={'ic_admin_calls','ic_admin_ratings','ic_admin_vip_assignments','vrp_users','ic_admin_subjects','ic_admin_discipline','ic_admin_documents','mirtin_bans','mirtin_bans_hwid','mirtin_bans_ip'}
    for _,entry in ipairs(footprint) do transactional[#transactional+1]=entry.table end
    for _,name in ipairs(transactional) do if engines[name]~='InnoDB' then blockers[#blockers+1]=name..' (engine não transacional)' end end
    if #blockers>0 then I.fail('UNHANDLED_RELATION','Manutenção recusada. Relações precisam de tratamento: '..table.concat(blockers,', ')) end
    return footprint,subject,extra
end
local function recordsForUser(id,newId,wiping,subject)
    local statements={}
    I.Records.each('vip_assignments','owner_id=? AND subject_key=?',{id,subject},function(row,rev)
        if row.state=='applying' or row.state=='uncertain' then I.fail('OPERATION_UNCERTAIN','Há entrega VIP pendente de conferência.') end
        for _,claim in ipairs(row.claims or {}) do if claim.state=='applying' or claim.state=='uncertain' then I.fail('OPERATION_UNCERTAIN','Há resgate pendente de conferência.') end end
        if wiping then row.state='archived';row.archivedUserId=id else row.userId=newId end
        I.Records.guarded('vip_assignments',row,rev,statements)
    end)
    I.Records.each('calls','(owner_id=? AND subject_key=?) OR (actor_id=? AND actor_subject=?)',{id,subject,id,subject},function(row,rev)
        if row.state=='open' or row.state=='accepted' then I.fail('ACTIVE_CALL','Finalize os chamados deste passaporte.') end
        if not wiping then
            if row.requesterId==id then row.requesterId=newId end;if row.acceptedBy==id then row.acceptedBy=newId end
            I.Records.guarded('calls',row,rev,statements)
        end
    end)
    if not wiping then I.Records.each('ratings','(owner_id=? AND subject_key=?) OR (actor_id=? AND actor_subject=?)',{id,subject,id,subject},function(row,rev)
        if row.staffId==id then row.staffId=newId end;if row.requesterId==id then row.requesterId=newId end
        I.Records.guarded('ratings',row,rev,statements)
    end) end
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
                    local footprint,subject,extra=preflight(id,changing,newId)
                    local statements=recordsForUser(id,newId,not changing,subject)
                    for _,statement in ipairs(extra) do statements[#statements+1]=statement end
                    -- Disconnected writer state and the registry are checked before the transaction.
                    for _,entry in ipairs(footprint) do
                        if entry.column then
                        if changing then statements[#statements+1]={query='UPDATE '..quote(entry.table)..' SET '..quote(entry.column)..'=? WHERE '..quote(entry.column)..'=?',values={newId,id}}
                        else statements[#statements+1]={query='DELETE FROM '..quote(entry.table)..' WHERE '..quote(entry.column)..'=?',values={id}} end
                        end
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
                    I.Ownership.finished(id,newId)
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
I.register('maintenance.inspect',{handler=function(ctx,p)
    I.requireOwner(ctx)
    local id=I.target(p.targetId,false)
    if I.vRP.getUserSource(id) then I.fail('PLAYER_ONLINE','O jogador precisa estar desconectado.') end
    local changing=p.mode=='changeId'
    local newId=changing and I.int(p.newId,1,2147483647,'Novo passaporte') or nil
    if newId and (newId==id or I.Store.query('SELECT id FROM vrp_users WHERE id=?',{newId})[1]) then I.fail('ID_IN_USE','Destino inválido ou ocupado.') end
    local footprint,subject=preflight(id,changing,newId)
    recordsForUser(id,newId,not changing,subject)
    I.requireOwner(ctx)
    return {targetId=id,newId=newId,footprint=footprint,ready=true,message='Pré-verificação concluída. Todos os vínculos serão verificados novamente ao confirmar.'}
end})
-- The vRP resolver also checks this lock after resolving identifiers.
exports('isUserInMaintenance',function(id) return next(I.userLocks)~=nil or I.userLocks[tonumber(id)]==true end)
AddEventHandler('playerConnecting',function(_,setKickReason)
    if next(I.userLocks) then setKickReason('Manutenção administrativa em andamento. Reconecte em instantes.');CancelEvent() end
end)
