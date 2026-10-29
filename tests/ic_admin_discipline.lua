local root=arg[1] or '.'
local methods,events,threads,record={},{},{},nil
local originalNow=os.time;local now=1000;os.time=function()return now end
local sourceUser=42;local bucket=7;local restored=false
local saved={}
json={encode=function(v)saved.value=v;return 'state'end,decode=function()return saved.value end}
RegisterNetEvent=function()end
AddEventHandler=function(name,fn)events[name]=fn end
CreateThread=function(fn)threads[#threads+1]=coroutine.create(fn)end
Wait=function()coroutine.yield()end
SetTimeout=function(_,fn)fn()end
GetPlayers=function()return {'2'}end
GetPlayerPed=function()return 2 end
GetEntityCoords=function()return {x=1,y=2,z=3}end
GetPlayerRoutingBucket=function()return bucket end
SetPlayerRoutingBucket=function(_,b)bucket=b end
TriggerClientEvent=function(name,_,action)if name=='ic_admin:clientAction' and action=='teleport'then restored=true end end
GetCurrentResourceName=function()return 'ic_admin'end
ICAdmin={Store={},vRP={}}
local I=ICAdmin
I.copy=function(v)local out={};for k,x in pairs(v)do out[k]=x end;return out end
I.fail=function(code,message)error({code=code,message=message},0)end
I.int=function(n,min,max)n=tonumber(n);assert(n and n>=min and n<=max);return n end
I.text=function(v)assert(type(v)=='string'and #v>0);return v end
I.target=function(id)return id,2 end
I.withLock=function(_,fn)return fn()end
I.effect=function()end
I.register=function(name,descriptor)methods[name]=descriptor.handler end
I.active=function()return true end
I.subject=function()return 'person' end
I.vRP.getUserId=function()return sourceUser end
I.vRP.getUserSource=function(id)return id==sourceUser and 2 or nil end
I.Store.query=function(sql)
    if not record then return {}end
    if sql:find('SELECT id',1,true)then return record.state=='active' and {{id=record.id}}or {}end
    if sql:find("state IN ('active','release_pending')",1,true)then return (record.state=='active'or record.state=='release_pending')and {record}or {}end
    return {record}
end
I.Store.insert=function(_,p)record={id=1,subject_key=p[1],user_id=p[2],actor_id=p[3],kind='warning',reason=p[4],starts_at=p[5],ends_at=p[6],state='active',return_state=p[7]};return 1 end
I.Store.update=function(_,p)record.state=p[1];return 1 end
dofile(root..'/resources/[scriptcore]/ic_admin/server/discipline.lua')
local result=methods['warnings.apply']({source=1,userId=12},{targetId=42,reason='Motivo',minutes=1})
assert(result.endsAt==1060 and bucket==1000002,'castigo not applied/persisted')
assert(not pcall(methods['warnings.apply'],{source=1,userId=12},{targetId=42,reason='Duplicado',minutes=1}),'stacked castigo')
now=1070
assert(coroutine.resume(threads[1]));assert(coroutine.resume(threads[1]))
assert(record.state=='expired'and bucket==7 and restored,'castigo did not restore coordinates/bucket')
record.state='active';record.ends_at=1090;sourceUser=99;bucket=0;restored=false;now=1100
assert(coroutine.resume(threads[1]))
assert(not restored and bucket==0,'reused source was punished/restored as previous user')
os.time=originalNow
print('IC Admin discipline: persistent expiry, exclusive castigo, return state and source reuse passed')
