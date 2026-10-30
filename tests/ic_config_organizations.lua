local root=assert(arg[1]);local emit=arg[2]=='emit'
json=dofile(root..'/tests/ic_config_json.lua')
local output=print
if emit then print=function()end end
local convars={ic_config_enabled='true',ic_config_writes_enabled='true'}
local groups={developer=true}
local response,serial,phase,record,transactions,counts,userRows,ownerCalls,groupRaw,orgRaw,online
local transactionFailure,ackLost,ownerFailure
function GetConvar(key,default)return convars[key] or default end
function GetResourceState(name)return name=='mg_config_panel' and 'stopped' or 'started' end
function module()return {getInterface=function()return {getUserId=function()return 7 end,getUserGroups=function()return groups end} end} end
function RegisterNetEvent()end
function AddEventHandler()end
function TriggerClientEvent(_,_,value)response=value end
local ownerMethods={}
exports=setmetatable({},{__index=function(_,resource)
    return setmetatable({},{__index=function(_,method)
        return function(_,...)
            ownerCalls[#ownerCalls+1]={resource=resource,method=method,args={...}}
            if ownerFailure==resource..':'..method then return false end
            return assert(ownerMethods[resource..':'..method],resource..':'..method)(...)
        end
    end})
end})
dofile(root..'/resources/[scriptcore]/ic_config/config.lua')
dofile(root..'/resources/[scriptcore]/ic_config/server/core.lua')
dofile(root..'/resources/[scriptcore]/ic_config/server/organizations.lua')
local S=ICConfigServer;local O=S.Organizations
ownerMethods['vrp:icConfigOrganizationPlan']=function()return {names={'MembroTest'},raw=groupRaw,online=online} end
ownerMethods['m_orgs_v2:icConfigOrganizationPlan']=function()return {exists=true,raw=orgRaw} end
ownerMethods['m_orgs_v2:getManagedOrganizationNames']=function()return {'Test','Other'} end
ownerMethods['vrp:icConfigOrganizationFreeze']=function()return true end
ownerMethods['vrp:icConfigOrganizationArm']=function()return true end
ownerMethods['vrp:icConfigOrganizationFinalize']=function()groupRaw='groups-final';return true end
ownerMethods['m_orgs_v2:icConfigOrganizationFinalize']=function()orgRaw='org-final';return true end
ownerMethods['vrp:icConfigOrganizationRecreate']=function()return true end
ownerMethods['m_orgs_v2:icConfigOrganizationRecreate']=function()return true end
O.query=function(sql,args)
    args=args or {}
    if sql:find('MAX(version)',1,true) then return {{version=1}} end
    if sql:find('information_schema.TABLES',1,true) then
        local rows={}
        for _,name in ipairs({'ic_config_schema','ic_config_org_deletions','ic_config_deleted_groups','vrp_user_data','mirtin_orgs_goals','mirtin_orgs_player_infos','mirtin_orgs_chat','sjr_logs','mirtin_organization_members','mirtin_orgs_info'}) do rows[#rows+1]={TABLE_NAME=name,ENGINE='InnoDB'} end
        return rows
    end
    if sql:find('information_schema.COLUMNS',1,true) then
        local columns={ic_config_schema={'version'},ic_config_org_deletions={'org_name','operation_id','phase','actor_id','payload','updated_at'},ic_config_deleted_groups={'group_name','operation_id'},vrp_user_data={'user_id','dkey','dvalue'},mirtin_orgs_goals={'organization'},mirtin_orgs_player_infos={'organization'},mirtin_orgs_chat={'organization'},sjr_logs={'organization'},mirtin_organization_members={'group_type'},mirtin_orgs_info={'organization'}}
        local rows={};for name,fields in pairs(columns) do for _,field in ipairs(fields) do rows[#rows+1]={TABLE_NAME=name,COLUMN_NAME=field} end end;return rows
    end
    if sql:find('information_schema.TRIGGERS',1,true) then
        local rows={{TRIGGER_NAME='ic_config_userdata_insert'},{TRIGGER_NAME='ic_config_userdata_update'}}
        for i=1,6 do rows[#rows+1]={TRIGGER_NAME='ic_config_org_'..i..'_insert'};rows[#rows+1]={TRIGGER_NAME='ic_config_org_'..i..'_update'} end
        return rows
    end
    if sql:find('SELECT org_name,operation_id',1,true) then return record and {record} or {} end
    if sql:find('equal_name',1,true) then return {{equal_name=args[1]==args[2] and 1 or 0}} end
    if sql:find('SELECT user_id,dvalue',1,true) then return userRows end
    if sql:find('SELECT COUNT(*) count FROM ',1,true) then
        local name=sql:match('FROM ([%w_]+)');return {{count=counts[name] or 0}}
    end
    if sql:find("SET phase='complete'",1,true) then record.phase='complete';return {affectedRows=1} end
    error('Unexpected SQL: '..sql)
end
O.transaction=function(queries)
    transactions[#transactions+1]=S.copy(queries)
    if transactionFailure then return false end
    for _,query in ipairs(queries) do
        if query.query:find('INSERT INTO ic_config_org_deletions(',1,true) then
            record={org_name=query.values[1],operation_id=query.values[2],phase='prepared',actor_id=query.values[3],payload=query.values[4]}
        elseif query.query:find('UPDATE vrp_user_data SET',1,true) then
            for _,row in ipairs(userRows) do if row.user_id==query.values[2] then row.dvalue=query.values[1] end end
        elseif query.query:find('DELETE FROM ',1,true) then
            local name=query.query:match('DELETE FROM ([%w_]+)');counts[name]=0
        elseif query.query:find("SET phase='sql_committed'",1,true) then record.phase='sql_committed'
        elseif query.query:find("SET phase='recreated'",1,true) then record.phase='recreated' end
    end
    if ackLost and record and record.phase=='sql_committed' then error('lost commit acknowledgement') end
    return true
end
local function reset()
    S.sessions={};O.previews={};groups={developer=true};record=nil;transactions={};ownerCalls={};serial=0
    groupRaw='groups-v1';orgRaw='org-v1';online={};transactionFailure=false;ackLost=false;ownerFailure=nil
    counts={mirtin_orgs_goals=1,mirtin_orgs_player_infos=1,mirtin_orgs_chat=1,sjr_logs=1,mirtin_organization_members=1,mirtin_orgs_info=1}
    userRows={{user_id=71001,dvalue=json.encode({groups={MembroTest=true,user=true},vip_group_expirations={MembroTest=1234},other='preserve'})}}
end
local function request(method,payload)
    serial=serial+1;S.request(5,{requestId='orgtest:'..serial,method=method,payload=payload or {}});return response
end
local function code(result,expected)assert(not result.ok and result.error.code==expected,(result.error and result.error.code or 'success')..' ~= '..expected) end
local function preview()local result=request('previewFacDeletion',{orgName='Test'});assert(result.ok,json.encode(result));return result.data end
local function commit(plan,confirmation)return request('deleteFacBundle',{orgName='Test',previewId=plan.previewId,confirmation=confirmation or plan.confirmation}) end
reset()
local plan=preview();assert(plan.counts.groups==1 and plan.counts.offlineUsers==1 and plan.confirmation=='EXCLUIR Test')
code(commit(plan,'Test'),'CONFIRMATION_REQUIRED');assert(#transactions==0)
groupRaw='changed';code(commit(plan),'CONFLICT');assert(#transactions==0)
reset();plan=preview();online={71001};code(commit(plan),'CONFLICT');assert(#transactions==0)
reset();online={71001};plan=preview();code(commit(plan),'ONLINE_MEMBERS');assert(#transactions==0)
reset();plan=preview();groups={};code(commit(plan),'FORBIDDEN');assert(#transactions==0)
reset();plan=preview();O.previews[plan.previewId].expiresAt=0;code(commit(plan),'STALE_PREVIEW');assert(#transactions==0)
reset();plan=preview();local done=commit(plan);assert(done.ok and done.data.state=='complete')
assert(record.phase=='complete' and #transactions==2 and #ownerCalls>0)
local user=json.decode(userRows[1].dvalue);assert(user.groups.MembroTest==nil and user.groups.user and user.other=='preserve' and user.vip_group_expirations.MembroTest==nil)
code(commit(plan),'STALE_PREVIEW');assert(#transactions==2)
O.beforeCreation({source=5,userId=7},'Test');assert(record.phase=='recreated')
-- Crash/failure after durable intent: a new typed deletion is refused; resume finishes it.
reset();plan=preview();ownerFailure='m_orgs_v2:icConfigOrganizationFinalize'
code(commit(plan),'RECOVERY_REQUIRED');assert(record.phase=='prepared' and #transactions==1)
local status=request('getFacDeletionStatus',{orgName='Test'});assert(status.ok and status.data.canResume)
ownerFailure=nil;done=request('resumeFacDeletion',{orgName='Test',operationId=status.data.operationId});assert(done.ok and done.data.state=='complete')
-- DB rollback leaves the prepared journal; no projection can claim full success.
reset();plan=preview();local tx=O.transaction
O.transaction=function(queries) if #transactions>0 then return false end;return tx(queries) end
code(commit(plan),'RECOVERY_REQUIRED');assert(record.phase=='prepared' and counts.mirtin_orgs_goals==1)
O.transaction=tx;done=request('resumeFacDeletion',{orgName='Test',operationId=record.operation_id});assert(done.ok and record.phase=='complete')
-- A lost commit acknowledgement is resolved from the same transaction's durable phase.
reset();plan=preview();ackLost=true;done=commit(plan);assert(done.ok and record.phase=='complete')
if emit then
    -- Emit the actual module's two SQL transaction lists for real MariaDB replay.
    reset();plan=preview();done=commit(plan);assert(done.ok)
    output(json.encode(transactions))
else output('IC Config organizations: previews, stale state, permissions, crash recovery, SQL rollback and name reuse passed') end
