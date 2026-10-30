-- Exercises the real resource modules against FiveM/vRP/export boundaries.
local root=assert(arg[1], 'repository root required')
local convars={ic_config_enabled='true',ic_config_writes_enabled='true'}
local states={mg_config_panel='stopped'}
local groups={developer=true}
local user=41
local handlers,events,responses,calls={},{},{},{}
local fixture={}
local failing=false
local overrides={}
function GetConvar(name,default)return convars[name] or default end
function GetResourceState(name)return states[name] or 'started' end
function module(_,_)return {getInterface=function()return {getUserId=function(src)return src==7 and user or nil end,getUserGroups=function()return groups end,getAllItens=function()return {water={name='Água',weight=0.5}} end} end} end
function RegisterNetEvent(name,fn)events[name]=fn end
function AddEventHandler(name,fn)handlers[name]=fn end
function TriggerClientEvent(name,target,value)assert(name=='ic_config:response');assert(target==7 or target==0);responses[#responses+1]=value end
exports=setmetatable({},{__index=function(_,resource)
    return setmetatable({},{__index=function(_,name)
        return function(receiver,...)
            assert(receiver==nil)
            calls[#calls+1]={resource=resource,name=name,args=table.pack(...)}
            if failing then error('PRIVATE_CONNECTION_AND_TOKEN_MUST_NOT_ESCAPE') end
            if overrides[resource..':'..name] then return overrides[resource..':'..name](...) end
            if name:match('^get') then return fixture[name] or {} end
            return true,'upstream success'
        end
    end})
end})
dofile(root..'/resources/[scriptcore]/ic_config/config.lua')
dofile(root..'/resources/[scriptcore]/ic_config/server/core.lua')
dofile(root..'/resources/[scriptcore]/ic_config/server/adapters.lua')
dofile(root..'/resources/[scriptcore]/ic_config/server/mansions.lua')
local S=ICConfigServer
local serial=0
local function request(method,payload,requestId,src)
    serial=serial+1
    S.request(src or 7,{requestId=requestId or ('test:'..serial),method=method,payload=payload or {}})
    return responses[#responses]
end
local function code(result,expected)assert(not result.ok and result.error.code==expected,tostring(result.error and result.error.code)..' ~= '..expected) end
local function noCalls(fn)local before=#calls;fn();assert(#calls==before,'unauthorized export call') end
local function reset()S.sessions={};states.mg_config_panel='stopped';states.inventory='started';groups={developer=true};user=41;convars.ic_config_enabled='true';convars.ic_config_writes_enabled='true';fixture={};failing=false;overrides={} end
assert(request('hasAccess').data==true)
noCalls(function()
    convars.ic_config_enabled='false';code(request('getChests'),'DISABLED');convars.ic_config_enabled='true'
    states.mg_config_panel='started';code(request('getChests'),'PROVIDER_CONFLICT');states.mg_config_panel='stopped'
    groups={admin=true};code(request('getChests'),'FORBIDDEN')
    groups={dono=true};assert(request('hasAccess').ok)
    groups={};code(request('getChests'),'FORBIDDEN');groups={developer=true}
    code(request('getChests',{},nil,0),'FORBIDDEN')
end)
reset()
fixture.getChests={{name='Alpha',coords={x=1,y=2,z=3},settings={webhook='hidden-value',public=true}}}
local result=request('getChests');assert(result.ok and result.data[1].settings.webhook==nil and result.data[1].settings.public)
states.inventory='stopped';code(request('getChests'),'RESOURCE_UNAVAILABLE');states.inventory='started'
local chest={name='Alpha',weight=100,permission='perm.alpha',coords={x=1,y=2,z=3}}
noCalls(function()convars.ic_config_writes_enabled='false';code(request('createChest',chest),'WRITE_DISABLED');convars.ic_config_writes_enabled='true' end)
assert(request('createChest',chest,'once').ok)
local call=calls[#calls];assert(call.resource=='inventory' and call.name=='addChest');assert(call.args[1]=='Alpha' and call.args[2]==100 and call.args[3]=='perm.alpha' and call.args[4].x==1)
noCalls(function()code(request('createChest',chest,'once'),'DUPLICATE_REQUEST') end)
assert(request('updateChest',chest).ok);call=calls[#calls];assert(call.name=='updateChest' and call.args[3].z==3 and call.args[4]=='perm.alpha')
noCalls(function()
    code(request('createChest',{name='A',weight=1,coords={x=0/0,y=0,z=0}}),'INVALID_INPUT')
    code(request('saveJoalheria',{settings={webhook='private'},displays={},rewards={}}),'PRIVATE_FIELD')
    code(request('saveJoalheria',{settings={},displays={},rewards={},url='https://example.invalid/api/webhooks/private'}),'INVALID_INPUT')
    code(request('getMansions'),'PROVIDER_NOT_SELECTED')
    code(request('saveMansion',{originalId='',data={}}),'PROVIDER_NOT_SELECTED')
end)
fixture.getJoalheriaConfig={settings={webhook='server-secret',cooldown=10},displays={},rewards={}}
assert(request('saveJoalheria',{settings={cooldown=20},displays={},rewards={}}).ok)
call=calls[#calls];assert(call.name=='saveJoalheriaConfig' and call.args[1].settings.webhook=='server-secret' and call.args[1].settings.cooldown==20)
ICConfig.Resources.Mansions='ic_mansions'
fixture.getMansions={version=1,mansions={{id='own',name='Own'}}}
assert(request('getMansions').data.mansions[1].id=='own')
call=calls[#calls];assert(call.name=='getMansions' and call.args[1].source==7 and call.args[1].userId==41)
assert(request('saveMansion',{originalId='own',data={name='Own'}}).ok)
call=calls[#calls];assert(call.args[1]=='own' and call.args[2].name=='Own' and call.args[3].source==7)
overrides['ic_mansions:saveMansion']=function()return false,'Confira o diário.','RECONCILIATION_REQUIRED'end
code(request('saveMansion',{originalId='own',data={name='Own'}}),'RECONCILIATION_REQUIRED')
ICConfig.Resources.Mansions='m_mansions'
fixture.getDesmancheConfig={desmanches={{name='original',log_webhook='private-destination'}},settings={}}
local desmanche={name='renamed',permissao='perm.test',inicio={x=1,y=2,z=3},local_veiculo={x=1,y=2,z=3},local_ferramentas={x=1,y=2,z=3,w=4},local_finalizar={x=1,y=2,z=3}}
result=request('getDesmanches');assert(result.ok and result.data.desmanches[1].log_webhook==nil)
result=request('updateDesmanche',{originalName='original',data=desmanche});assert(result.ok and result.data.log_webhook==nil)
call=calls[#calls];assert(call.name=='updateDesmanche' and call.args[1]=='original' and call.args[2].name=='renamed' and call.args[2].log_webhook=='private-destination')
noCalls(function()code(request('updateDesmanche',{originalName='original',data={name='renamed',log_webhook='injected'}}),'PRIVATE_FIELD') end)
fixture.getJoalheriaConfig={settings={},displays={{id=1,name='first',webhook='first-secret'},{id=2,name='second',webhook='second-secret'}},rewards={}}
assert(request('saveJoalheria',{settings={},displays={{id=2,name='second changed'},{id=1,name='first changed'}},rewards={}}).ok)
call=calls[#calls];assert(call.args[1].displays[1].webhook=='second-secret' and call.args[1].displays[2].webhook=='first-secret')
fixture.getJoalheriaConfig={settings={},displays={{label='unkeyed',webhook='server-secret'}},rewards={}}
before=#calls;code(request('saveJoalheria',{settings={},displays={{label='changed'}},rewards={}}),'PRIVATE_FIELD');assert(calls[#calls].name=='getJoalheriaConfig')
fixture.getVehicleCatalog={alpha={},beta={}}
local before=#calls;code(request('deleteServerVehiclesBatch',{vehicles={'alpha','missing'}}),'CONFLICT');assert(#calls==before+1 and calls[#calls].name=='getVehicleCatalog')
assert(request('deleteServerVehiclesBatch',{vehicles={'alpha','beta'}}).ok);assert(calls[#calls].name=='removeVehicleCatalogEntries')
fixture.getCraftBenches={{name='B',farmRewardType='reward'},{name='Other',farmRewardType='reward'}}
fixture.getFarmConfig={Routes={{rewardType='reward',routeType='city',permissions={}}},Rewards={reward={}},RouteBlips={city={}}}
before=#calls;code(request('saveCraftSetup',{originalName='B',bench={name='B',coords={},craftItems={},armazemItems={}},farm={enabled=false}}),'SHARED_FARM');assert(#calls==before+2 and calls[#calls].name=='getFarmConfig')
reset()
fixture.getCraftBenches={}
fixture.getFarmConfig={Routes={},Rewards={},RouteBlips={city={}}}
overrides['m_farm:upsertFarmLink']=function(link)
    fixture.getFarmConfig.Routes={{rewardType=link.rewardType,routeType=link.routeType,permissions=link.permissions}}
    fixture.getFarmConfig.Rewards[link.rewardType]=link.rewards
    return true
end
overrides['m_craft:upsertCraftBench']=function(original,bench)fixture.getCraftBenches={bench};return true end
local craft={originalName='',bench={name='B',coords={{x=1,y=2,z=3}},craftItems={},armazemItems={}},farm={enabled=true,rewardType='reward',routeType='city',permissions={'perm.b'},rewards={}}}
assert(request('saveCraftSetup',craft).ok)
assert(fixture.getCraftBenches[1].farmRewardType=='reward' and fixture.getFarmConfig.Routes[1].permissions[1]=='perm.b')
overrides['m_farm:removeFarmLink']=function(key)fixture.getFarmConfig.Routes={};fixture.getFarmConfig.Rewards[key]=nil;return true end
overrides['m_craft:removeCraftBench']=function()fixture.getCraftBenches={};return true end
assert(request('deleteCraftSetup',{name='B'}).ok)
assert(#fixture.getCraftBenches==0 and fixture.getFarmConfig.Rewards.reward==nil)
-- A farm export can change memory before returning false; restore its snapshot.
reset()
fixture.getCraftBenches={{name='B',farmRewardType='reward',coords={},craftItems={},armazemItems={}}}
fixture.getFarmConfig={Routes={{rewardType='reward',routeType='city',permissions={'perm.original'}}},Rewards={reward={{item='water'}}},RouteBlips={city={}}}
local farmAttempts=0
overrides['m_farm:upsertFarmLink']=function(link)
    farmAttempts=farmAttempts+1
    fixture.getFarmConfig.Routes={{rewardType=link.rewardType,routeType=link.routeType,permissions=link.permissions}}
    fixture.getFarmConfig.Rewards[link.rewardType]=link.rewards
    return farmAttempts>1
end
local editing={originalName='B',bench={name='B',coords={},craftItems={},armazemItems={}},farm={enabled=true,rewardType='reward',routeType='city',permissions={'perm.changed'},rewards={{item='new'}}}}
code(request('saveCraftSetup',editing),'OPERATION_FAILED')
assert(farmAttempts==2 and fixture.getFarmConfig.Routes[1].permissions[1]=='perm.original' and fixture.getFarmConfig.Rewards.reward[1].item=='water')
assert(fixture.getCraftBenches[1].farmRewardType=='reward')
-- A failed bench write triggers both compensations and remains explicit uncertainty.
reset()
fixture.getCraftBenches={{name='B',farmRewardType='reward',coords={},craftItems={},armazemItems={}}}
fixture.getFarmConfig={Routes={{rewardType='reward',routeType='city',permissions={'perm.original'}}},Rewards={reward={{item='water'}}},RouteBlips={city={}}}
overrides['m_farm:upsertFarmLink']=function(link)
    fixture.getFarmConfig.Routes={{rewardType=link.rewardType,routeType=link.routeType,permissions=link.permissions}}
    fixture.getFarmConfig.Rewards[link.rewardType]=link.rewards
    return true
end
local benchAttempts=0
overrides['m_craft:upsertCraftBench']=function(_,bench)
    benchAttempts=benchAttempts+1
    fixture.getCraftBenches={bench}
    return benchAttempts>1
end
code(request('saveCraftSetup',editing),'PARTIAL_EFFECT')
assert(benchAttempts==2 and fixture.getCraftBenches[1].farmRewardType=='reward')
assert(fixture.getFarmConfig.Routes[1].permissions[1]=='perm.original' and fixture.getFarmConfig.Rewards.reward[1].item=='water')
assert(not S.locked,'failed compensation branch left the global lock held')
-- Revocation during a yielding export prevents every subsequent export, even rollback.
reset()
fixture.getCraftBenches={}
fixture.getFarmConfig={Routes={},Rewards={},RouteBlips={city={}}}
overrides['m_farm:upsertFarmLink']=function(link)
    fixture.getFarmConfig.Routes={{rewardType=link.rewardType,routeType=link.routeType,permissions=link.permissions}}
    fixture.getFarmConfig.Rewards[link.rewardType]=link.rewards
    groups={}
    return true
end
before=#calls
code(request('saveCraftSetup',craft),'PARTIAL_EFFECT')
assert(#calls==before+3 and calls[#calls].name=='upsertFarmLink','revocation allowed a later export')
reset()
fixture.getManagedGroups={}
assert(request('createFacGroups',{orgName='Test',orgType='test',goalItem='water',goalAmount=1,defaultReward=0}).ok)
assert(calls[#calls].name=='addManagedOrganization' and calls[#calls].args[1]=='Test')
overrides['m_orgs_v2:addManagedOrganization']=function()return false end
code(request('createFacGroups',{orgName='Failed',orgType='test',goalItem='water',goalAmount=1,defaultReward=0}),'PARTIAL_EFFECT')
for _,entry in ipairs(calls) do assert(entry.name~='removeFacGroups','must not revoke concurrent group assignments') end
reset()
overrides['m_orgs_v2:canCreateManagedOrganization']=function()return false end
before=#calls
code(request('createFacGroups',{orgName='Present',orgType='test',goalItem='water',goalAmount=1,defaultReward=0}),'CONFLICT')
assert(#calls==before+1 and calls[#calls].name=='canCreateManagedOrganization')
reset()
fixture.getManagedGroups={{name='MembroPresent'}}
before=#calls
code(request('createFacGroups',{orgName='Present',orgType='test',goalItem='water',goalAmount=1,defaultReward=0}),'CONFLICT')
assert(#calls==before+2 and calls[#calls].name=='getManagedGroups')
failing=true
result=request('getChests');code(result,'EXPORT_FAILED');assert(not result.error.message:find('PRIVATE_CONNECTION'))
reset()
for method in pairs(S.methods) do
    groups={admin=true}
    noCalls(function()code(request(method,{}),'FORBIDDEN') end)
end
reset()
S.sessions[7]={userId=41,seen={},count=4096,started=os.time(),requests=0}
noCalls(function()code(request('getChests'),'SESSION_LIMIT') end)
reset()
for _=1,80 do assert(request('hasAccess').ok) end
noCalls(function()code(request('getChests'),'RATE_LIMIT') end)
source=7;handlers.playerDropped();assert(S.sessions[7]==nil)
print('IC Config server: authorization, private data, write gates, adapters and replay checks passed')
