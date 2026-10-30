-- Execute the real owning resource modules, including file/KVP/cache projections.
local root=assert(arg[1]);json=dofile(root..'/tests/ic_config_json.lua')
local registered,files,kvp={}, {},{}
local invoking='ic_config';local resource='vrp';local failedWrite=false
function GetCurrentResourceName()return resource end
function GetInvokingResource()return invoking end
function GetConvar(_,default)return default end
function GetResourceKvpString(key)return kvp[resource..':'..key] end
function SetResourceKvp(key,value)kvp[resource..':'..key]=value end
function LoadResourceFile(owner,path)return files[owner..':'..path] end
function SaveResourceFile(owner,path,value)
    if failedWrite then return false end
    files[owner..':'..path]=value;return true
end
function TriggerEvent()end
function CreateThread()end
function AddEventHandler()end
function module()return {users={},selectors={}} end
exports=setmetatable({oxmysql=setmetatable({},{__index=function()return function()return {} end end})},{__call=function(_,name,handler)registered[resource..':'..name]=handler end})
exports.oxmysql.query_async=function()error('An unarmed read-only installation must not query deletion schema') end
vRP={user_tables={[41]={groups={MembroTest=true,user=true},vip_group_expirations={MembroTest=555},wallet=99}},rusers={}}
function vRP.getUserDataTable(id)return vRP.user_tables[id] end
function vRP.getUserSource(id)return id==41 and 5 or nil end
files['vrp:cfg/groups.json']=json.encode({groups={
    {name='user',config={},permissions={}},
    {name='MembroTest',config={gtype='org',orgName='Test'},permissions={'perm.test'}},
    {name='MembroOther',config={gtype='org',orgName='Other'},permissions={'perm.other'}}}})
local function group(name,...)return assert(registered['vrp:'..name])(...) end
dofile(root..'/resources/[vrp]/vrp/server-side/group.lua')
invoking='ic_mansions'
exports.oxmysql.executeSync=function()
    return {
        {user_id=41,dvalue=json.encode({groups={MembroTest=true},vip_group_expirations={MembroTest=1},inventory={private='must not be returned'}})},
        {user_id=42,dvalue=json.encode({groups={MembroTest=true,user=true},vip_group_expirations={MembroTest=999},private='must not be returned'})},
        {user_id=43,dvalue=json.encode({groups={MembroOther=true},private='must not be returned'})}
    }
end
local assignments=group('getManagedGroupAssignments','MembroTest')
assert(assignments.count==2 and assignments.assignments[1].userId==41 and assignments.assignments[1].online and assignments.assignments[1].expiresAt==555)
assert(assignments.assignments[2].userId==42 and not assignments.assignments[2].online and assignments.assignments[2].expiresAt==999)
assert(not json.encode(assignments):find('must not') and not json.encode(assignments):find('inventory') and assignments.groups==nil)
local validAssignmentQuery=exports.oxmysql.executeSync
exports.oxmysql.executeSync=function()return {{user_id=44,dvalue='malformed-json'}} end
assert(group('getManagedGroupAssignments','MembroTest')==false)
exports.oxmysql.executeSync=validAssignmentQuery
invoking='ic_config';assert(group('getManagedGroupAssignments','MembroTest')==false)
invoking='untrusted';assert(group('icConfigOrganizationPlan','Test')==false);invoking='ic_config'
local plan=group('icConfigOrganizationPlan','Test');assert(#plan.names==1 and #plan.online==1)
assert(group('icConfigOrganizationFreeze','operation1','Test',plan.names))
assert(not vRP.addUserGroup(41,'MembroTest'))
assert(vRP.getUserGroups(41).MembroTest==nil and vRP.user_tables[41].wallet==99)
assert(vRP.user_tables[41].vip_group_expirations.MembroTest==nil)
local ok=group('saveManagedGroup','',{name='NewTest',config={gtype='org',orgName='Test'},permissions={}});assert(not ok)
failedWrite=true;assert(not group('icConfigOrganizationFinalize','operation1','Test',plan.names));failedWrite=false
assert(group('icConfigOrganizationFinalize','operation1','Test',plan.names))
local stored=json.decode(files['vrp:cfg/groups.json']);assert(#stored.groups==2)
assert(stored.groups[1].name=='user' and stored.groups[2].name=='MembroOther')
dofile(root..'/resources/[vrp]/vrp/server-side/group.lua') -- restart retains KVP gates
assert(not vRP.addUserGroup(41,'MembroTest'))
assert(group('icConfigOrganizationRecreate','operation1','Test',plan.names))
assert(group('saveManagedGroup','',{name='MembroTest',config={gtype='org',orgName='Test'},permissions={'perm.test'}}))
assert(vRP.addUserGroup(41,'MembroTest'))

-- Crash between SQL intent and KVP projection: a failed first DB read must not
-- expose the old group; subsequent permission reads retry and apply the journal.
kvp['vrp:ic_config:organization_schema_active']='1'
local dbQueries=0;local failDb=true
exports.oxmysql.query_async=function()
    dbQueries=dbQueries+1
    if failDb then error('simulated transient unavailable database') end
    return {{group_name='MembroTest',operation_id='operation2',org_name='Test'}}
end
dofile(root..'/resources/[vrp]/vrp/server-side/group.lua')
local permitted=pcall(vRP.hasPermission,41,'perm.test');assert(not permitted and dbQueries>=2)
assert(not group('saveManagedGroup','',{name='Unsafe',config={},permissions={}}))
assert(vRP.user_tables[41].groups.MembroTest==true,'failure should not rewrite unrelated/live state')
failDb=false
assert(not vRP.hasPermission(41,'perm.test'))
assert(vRP.user_tables[41].groups.MembroTest==nil)
local recoveredQueries=dbQueries;assert(not vRP.hasPermission(41,'perm.test'));assert(dbQueries==recoveredQueries)

resource='m_orgs_v2'
Config={Groups={Test={List={MembroTest={tier=7}}},Other={List={MembroOther={tier=7}}}}}
Organizations={List={MembroTest='Test',MembroOther='Other'},Members={[41]={groupType='Test'}},MembersList={Test={[41]=true}},Permissions={Test={}},goalsConfig={Test={}},payDayOrg={Test={}}}
files['m_orgs_v2:dynamic_orgs.json']=json.encode({organizations={},deleted={}})
dofile(root..'/resources/[scripts]/m_orgs_v2/server/00_dynamic_orgs.lua')
local function org(name,...)return assert(registered['m_orgs_v2:'..name])(...) end
assert(org('icConfigOrganizationPlan','Test').exists)
failedWrite=true;assert(not org('icConfigOrganizationFinalize','Test','operation1'));failedWrite=false
assert(org('icConfigOrganizationFinalize','Test','operation1'))
assert(Config.Groups.Test==nil and Config.Groups.Other~=nil)
assert(Organizations.List.MembroTest==nil and Organizations.List.MembroOther=='Other')
assert(Organizations.Members[41]==nil and Organizations.MembersList.Test==nil)
assert(not org('canCreateManagedOrganization','Test'))
assert(org('icConfigOrganizationRecreate','Test','operation1'))
assert(org('canCreateManagedOrganization','Test'))
Organizations=nil -- runtime registration is exercised elsewhere; verify owning persistence.
assert(org('addManagedOrganization','Test','water',10,20))
local persisted=json.decode(files['m_orgs_v2:dynamic_orgs.json'])
assert(persisted.organizations.Test~=nil and #persisted.deleted==0)
print('IC Config owning modules: file failures, KVP restart, live cache cleanup, caller checks and organization recreation passed')
