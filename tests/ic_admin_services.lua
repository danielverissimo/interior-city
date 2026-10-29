-- Service behavior harness. No FiveM instance, database, network or credentials are used.
local root=arg[1] or '.'
local function copy(value)
    if type(value)~='table' then return value end
    local out={}; for k,v in pairs(value) do out[k]=copy(v) end; return out
end
local documents,revisions,methods,exported,events,threads={},{},{},{},{},{}
local users={[1]=10,[2]=20,[3]=30}
local groups={vip_gold={_config={gtype='vip',salario=100},'perm.vip_gold'}}
local membership,expirations,subjectKeys={},{},{}
local permissions={[20]={all=true},[30]={['perm.policia']=true}}
local notices,deliveredItems,deliveredVehicles={},0,0
local failItem,failVehicle=false,false
json={encode=function() return '{}' end,decode=function() return {} end}
GetConvar=function(_,default) return default end
GetPlayers=function() return {'1','2','3'} end
GetCurrentResourceName=function() return 'ic_admin' end
TriggerClientEvent=function(name,source,...) notices[#notices+1]={name,source,...} end
AddEventHandler=function(name,fn) events[name]=fn end
CreateThread=function(fn) threads[#threads+1]=fn end
Wait=function() end
GlobalState={}
PerformHttpRequest=function() error('Network must not run in this test') end
GetPlayerPed=function(src)return src end
GetEntityCoords=function()return {x=10,y=20,z=30}end
GetPlayerRoutingBucket=function()return 0 end
SetPlayerRoutingBucket=function()end
exports=setmetatable({vrp={
    saveManagedGroup=function(_,_,payload)
        groups[payload.name]={_config=copy(payload.config)}
        for _,permission in ipairs(payload.permissions or {}) do table.insert(groups[payload.name],permission) end
        return true
    end,
    removeManagedGroup=function(_,name) groups[name]=nil; return true end
}},{__call=function(_,name,fn) exported[name]=fn end})

local I={ready=true,Config={},definitions={},Adapter={},Store={},vRP={},locks={}}
ICAdmin=I
I.copy=copy
I.active=function()return true end
I.fail=function(code,message)error({code=code,message=message},0)end
I.int=function(value,min,max)
    local n=tonumber(value)
    if not n or n~=n or n%1~=0 or n<min or n>max then I.fail('INVALID','Número inválido') end
    return n
end
I.text=function(value,max,required)
    if value==nil and not required then return '' end
    if type(value)~='string' or #value>max or (required and value=='') then I.fail('INVALID','Texto inválido') end
    return value
end
I.register=function(name,descriptor) assert(not methods[name]); methods[name]=descriptor end
I.allowed=function(userId,key)return permissions[userId] and (permissions[userId][key]==true or permissions[userId].all==true) or false end
I.requireOwner=function(ctx)if ctx.role~='dono' and ctx.role~='developer' then I.fail('FORBIDDEN','Owner required')end end
I.withLock=function(key,fn)
    if I.locks[key] then I.fail('BUSY','Busy')end
    I.locks[key]=true; local result=table.pack(pcall(fn));I.locks[key]=nil
    if not result[1] then error(result[2],0)end
    return table.unpack(result,2,result.n)
end
I.effect=function(ctx)if users[ctx.source]~=ctx.userId then I.fail('SESSION_EXPIRED','Source reused')end ctx.effectStarted=true end
I.subject=function(id)return subjectKeys[id] or ('subject-'..id) end
I.snapshot=function(id)return {id=id,name='Jogador '..id}end
I.target=function(id,online)
    id=I.int(id,1,2147483647); local source
    for src,userId in pairs(users)do if id==userId then source=src end end
    if online and not source then I.fail('OFFLINE','Offline')end
    return id,source
end
I.Store.get=function(key,default)return copy(documents[key] or default or {}),revisions[key] or 0 end
I.Store.put=function(key,value,expected)
    if expected~=(revisions[key] or 0) then return false end
    documents[key]=copy(value);revisions[key]=(revisions[key] or 0)+1;return true
end
I.Store.query=function(sql)if sql:find('COUNT',1,true)then return {{total=0}}end return {}end
I.Store.insert=function()return 1 end
I.Store.update=function()return 1 end
I.vRP.getUserId=function(src)return users[src]end
I.vRP.getUserSource=function(id)for src,userId in pairs(users)do if userId==id then return src end end end
I.vRP.getUserIdentity=function(id)return {nome='Jogador',sobrenome=tostring(id)}end
I.vRP.hasPermission=function(id,key)return I.allowed(id,key)end
I.vRP.getGroups=function()return groups end
I.vRP.hasGroup=function(id,group)return membership[id] and membership[id][group] or false end
I.vRP.addUserGroup=function(id,group)
    membership[id]=membership[id] or {};membership[id][group]=true
    expirations[id]=expirations[id] or {};expirations[id][group]=os.time()+2592000;return true
end
I.vRP.getUserGroupExpiration=function(id,group)return expirations[id] and expirations[id][group] or 0 end
I.Adapter.itemCatalog=function()return {radio={name='Rádio'}}end
I.Adapter.vehicleCatalog=function()return {sultan={name='Sultan'},adder={name='Adder'}}end
I.Adapter.validVehicle=function(spawn)if not I.Adapter.vehicleCatalog()[spawn]then I.fail('INVALID','Vehicle')end return spawn end
I.Adapter.giveItem=function()
    deliveredItems=deliveredItems+1
    if failItem then error('simulated item delivery uncertainty')end
    return true
end
I.Adapter.giveVehicle=function()deliveredVehicles=deliveredVehicles+1;if failVehicle then error('simulated vehicle uncertainty')end return true end
local function context(userId,role)
    return {source=assert(I.vRP.getUserSource(userId)),userId=userId,role=role or 'admin',sessionId='test'}
end
local function call(name,ctx,p)return methods[name].handler(ctx,p or {})end
local function rejects(fn,code)
    local ok,err=pcall(fn);assert(not ok,'Expected rejection')
    if code then assert(type(err)=='table' and err.code==code,'Unexpected rejection code')end
end
for _,file in ipairs({'audit','calls','vips','world'})do dofile(root..'/resources/[scriptcore]/ic_admin/server/'..file..'.lua')end

-- Single-owner acceptance, department boundaries and requester-only one-time ratings.
local created=call('calls.create',context(10),{department='staff',message='Ajuda'})
assert(created.call.id==1 and created.call.state=='open')
local openView=call('calls.list',context(20),{})
assert(openView.calls[1].canAccept==true and openView.calls[1].canFinish==false,'Actual call DTO must enable accept')
permissions[20].all=false;permissions[20].view_calls=true;permissions[20].calls_accept=false
assert(call('calls.list',context(20),{}).calls[1].canAccept==false,'View permission must not grant accept')
rejects(function()call('calls.accept',context(20),{callId=1})end,'FORBIDDEN')
permissions[20].all=true

rejects(function()call('calls.accept',context(10),{callId=1})end,'FORBIDDEN')
call('calls.accept',context(20),{callId=1})
assert(call('calls.list',context(20),{}).calls[1].canFinish==true,'Actual call DTO must enable finish')
rejects(function()call('calls.accept',context(30),{callId=1})end,'FORBIDDEN')
permissions[30].all=true
rejects(function()call('calls.accept',context(30),{callId=1})end,'CONFLICT')
permissions[30].all=false
permissions[20].all=false
rejects(function()call('calls.finish',context(20),{callId=1})end,'FORBIDDEN')
permissions[20].all=true
call('calls.finish',context(20),{callId=1})
assert(call('calls.list',context(10),{}).calls[1].canRate==true,'Requester must see rating action')
rejects(function()call('calls.rate',context(20),{callId=1,stars=5})end,'FORBIDDEN')
call('calls.rate',context(10),{callId=1,stars=3,message='Atendido'})
rejects(function()call('calls.rate',context(10),{callId=1,stars=5})end,'CONFLICT')
assert(call('calls.list',context(10),{}).calls[1].canRate==false,'Rated call must not invite another rating')
local staff=call('calls.list',context(20),{})
assert(staff.ranking[1].total==1 and staff.ranking[1].average==3)
local outsider=call('calls.list',context(30),{})
assert(#outsider.calls==0 and #outsider.ratings==0)
subjectKeys[10]='new-subject-10'
assert(#call('calls.list',context(10),{}).calls==0,'Reused passaporte must not inherit calls')
rejects(function()call('calls.rate',context(10),{callId=1,stars=5})end,'FORBIDDEN')
subjectKeys[10]=nil
local noMedic=exported.createSectorCall(1,'hospital','Ajuda',{})
assert(noMedic.ok==false)

-- Server validates world payloads and granular permissions before persistence.
rejects(function()call('world.update',context(20),{weather='BAD'})end,'INVALID')
call('world.update',context(20),{hour=23,minute=59,weather='RAIN'})
assert(documents.climate.hour==23 and GlobalState.time[1]==23)
permissions[20].all=false;permissions[20].view_climate=true
rejects(function()call('world.update',context(20),{hour=1})end,'FORBIDDEN')
permissions[20].all=true
rejects(function()call('locations.save',context(20),{name='A',x=0/0,y=1,z=2})end,'INVALID')
local saved=call('locations.save',context(20),{name='Praça',category='Cidade',x=1,y=2,z=3})
assert(saved.location.id==1 and exported.getLocations()[1].name=='Praça')
local stale=context(20);users[2]=40
rejects(function()call('locations.teleport',stale,{id=1})end,'SESSION_EXPIRED')
users[2]=20

-- Packages cannot turn staff groups into VIPs or deliver twice after uncertainty.
groups.admin={_config={gtype='staff'},'admin.permissao'}
rejects(function()call('vip.save',context(20),{group='admin',title='Oops',salary=0})end,'FORBIDDEN')
call('vip.save',context(20),{group='vip_gold',title='Ouro',salary=100,items={{item='radio',amount=1}},vehicles={{spawn='sultan'}},vehicleChoices=1,garageSlots=2})
local assignment=call('vip.assign',context(20),{targetId=10,group='vip_gold',reason='Entrega autorizada'}).assignment
assert(deliveredItems==1 and assignment.itemsState=='applied')
local pendingChoice=call('vip.mine',context(10),{}).assignments[1]
assert(pendingChoice.assignmentId==assignment.id and pendingChoice.remaining==1,'Public VIP recovery DTO must contain choice ID and remaining count')
rejects(function()call('vip.assign',context(20),{targetId=10,group='vip_gold',reason='Outra entrega'})end,'VIP_ACTIVE')
assert(deliveredItems==1 and exported.getVipGarageSlotsForUser(10)==2)
call('vip.choose',context(10),{assignmentId=assignment.id,vehicle='sultan'})
assert(deliveredVehicles==1)
rejects(function()call('vip.choose',context(10),{assignmentId=assignment.id,vehicle='sultan'})end,'CLAIMED')
assert(deliveredVehicles==1)
call('vip.save',context(20),{group='vip_error',title='Conferir',salary=0,items={{item='radio',amount=1}},vehicles={},vehicleChoices=0,garageSlots=0})
failItem=true
rejects(function()call('vip.assign',context(20),{targetId=30,group='vip_error',reason='Teste de falha'})end,'DELIVERY_UNCERTAIN')
local after=deliveredItems
rejects(function()call('vip.assign',context(20),{targetId=30,group='vip_error',reason='Repetição'})end,'VIP_ACTIVE')
assert(deliveredItems==after)
assert(documents.vip_assignments.assignments[2].state=='uncertain')
call('vip.save',context(20),{group='vip_car',title='Veículo',salary=0,items={},vehicles={{spawn='adder'}},vehicleChoices=1,garageSlots=0})
local carAssignment=call('vip.assign',context(20),{targetId=30,group='vip_car',reason='Entrega de veículo'}).assignment
failVehicle=true
rejects(function()call('vip.choose',context(30),{assignmentId=carAssignment.id,vehicle='adder'})end,'DELIVERY_UNCERTAIN')
local vehicleAttempts=deliveredVehicles
rejects(function()call('vip.choose',context(30),{assignmentId=carAssignment.id,vehicle='adder'})end,'CLAIMED')
assert(deliveredVehicles==vehicleAttempts)

-- Exercise actual world scheduler with controlled time and inert native events.
local realTime=os.time;local clock=realTime();os.time=function()return clock end
Wait=function(ms)return coroutine.yield(ms)end
local worldLoop=coroutine.create(threads[#threads])
assert(coroutine.resume(worldLoop));assert(coroutine.resume(worldLoop))
assert(documents.climate.hour==0 and documents.climate.minute==1,'Clock must roll past midnight')
call('world.update',context(20),{freezeTime=true})
clock=clock+10;assert(coroutine.resume(worldLoop))
assert(documents.climate.hour==0 and documents.climate.minute==1,'Frozen clock must not advance')
call('world.update',context(20),{freezeWeather=false,rotation=true})
clock=clock+301;assert(coroutine.resume(worldLoop))
assert(documents.climate.weather=='CLEARING','Weather rotation must advance the configured type')
os.time=realTime

-- Audit drops credentials and URLs before database/Discord representations.
local cleaned=I.Audit.clean({token='secret',nested={webhook='private'},message='Veja https://example.invalid/private'})
assert(cleaned.token=='[omitido]' and cleaned.nested.webhook=='[omitido]' and not cleaned.message:find('example',1,true))
local legacy=I.Audit.clean('license:fixture_license steam:fixture_steam fivem:fixture_fivem discord:fixture_discord IP 192.0.2.1 token=fixture_token password:fixture_password Bearer fixture_bearer')
assert(not legacy:find('fixture_',1,true) and not legacy:find('192.0.2.1',1,true))
assert(I.Audit.categoryFor('vrp_bank_give_money')=='economy')
print('IC Admin service harness: passed')
