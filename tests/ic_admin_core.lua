-- Real core dispatcher with an in-memory database boundary. No server/player is executed.
local root=arg[1] or '.'
local encoded,seq={},0
json={encode=function(v)
    if type(v)=='table' then seq=seq+1;local key='encoded'..seq;encoded[key]=v;return key end
    if type(v)=='string' then return string.format('%q',v) end
    return tostring(v)
end,decode=function(v)return encoded[v]end}
local users={[1]=10,[2]=20,[3]=30}
local roles={[10]='dono',[20]='admin',[30]='suporte'}
local groupDefs={dono={_config={gtype='staff'}},admin={_config={gtype='staff'}},vip_gold={_config={gtype='vip'}}}
local balance,inventory={[20]=100},{[20]={}}
local vrp={getUserId=function(s)return users[s]end,getUserSource=function(id)for src,uid in pairs(users)do if uid==id then return src end end end,
    hasGroup=function(id,role)return roles[id]==role end,
    getUserIdentity=function(id)return {nome='Nome',sobrenome=tostring(id)}end,
    getBankMoney=function(id)return balance[id] or 0 end,setBankMoney=function(id,amount)balance[id]=amount end,
    getMoney=function()return 0 end,getInventory=function(id)return inventory[id] or {}end,
    getInventoryItemAmount=function()return 0 end,getGroups=function()return groupDefs end}
module=function()return {getInterface=function()return vrp end}end
GetConvar=function(_,default) if _=='ic_admin_mode' then return 'active' end return default end
GetGameTimer=function()return 1000 end
GetPlayerName=function()return 'Jogador'end
local callbacks={}
RegisterNetEvent=function(name,fn)callbacks[name]=fn end
AddEventHandler=function(name,fn)callbacks[name]=fn end
TriggerClientEvent=function()end
TriggerEvent=function()end
SetTimeout=function()end
GetPlayers=function()return {'1','2','3'}end
exports={}
dofile(root..'/resources/[scriptcore]/ic_admin/config.lua')
dofile(root..'/resources/[scriptcore]/ic_admin/server/core.lua')
local I=ICAdmin;I.ready=true
local operations,inserted={},0
I.Store={get=function()return {actions={economy={admin=true},edit_identity_balance={admin=false},givemoney={admin=false}}},0 end,
    query=function(sql,p)
        if sql:find('ic_admin_operations',1,true)then return operations[p[1]] and {operations[p[1]]} or {}end
        if sql:find('vrp_users',1,true)then return {{id=p[1]}}end
        return {}
    end,
    update=function(sql,p)
        if sql:find('INSERT IGNORE INTO ic_admin_operations',1,true) then
            if operations[p[1]]then return 0 end
            inserted=inserted+1;operations[p[1]]={method=p[3],payload=p[4],state='pending'};return 1
        elseif sql:find("SET state='applied'",1,true)then operations[p[2]].state='applied';operations[p[2]].result=p[1];return 1
        elseif sql:find('SET state=?',1,true)then operations[p[3]].state=p[1];operations[p[3]].result=p[2];return 1 end
        return 1
    end}
I.audit=function()end
I.Adapter={}
local calls=0
I.register('test.mutate',{permission='economy',mutating=true,handler=function(ctx,p)
    calls=calls+1
    if p.failBefore then I.fail('INVALID','Inválido')end
    I.effect(ctx)
    if p.failAfter then error('simulated DB failure')end
    return {count=calls}
end})
I.register('test.secret',{permission='forbidden',handler=function()return {}end})
local token=I.newSession(2,20)
local function request(id,p,method,src,session)
    return I.dispatch(src or 2,{requestId=id,sessionId=session or token,method=method or 'test.mutate',payload=p or {}})
end
assert(not request('missing',{},'unknown').ok,'unknown method accepted')
assert(not request('guest',{},'test.secret',3,I.newSession(3,30)).ok,'staff role bypass')
assert(not request('bad-session',{},nil,2,'wrong').ok,'session bypass')
-- Refill rate via distinct timer advances to exercise dispatcher rather than limiter.
local now=1000;GetGameTimer=function()now=now+1000;return now end
local first=request('once',{amount=5});assert(first.ok and calls==1)
local again=request('once',{amount=5});assert(again.ok and calls==1,'duplicate effect executed')
assert(not request('once',{amount=6}).ok,'same ID accepted different payload')
local before=request('before',{failBefore=true});assert(not before.ok)
assert(operations['20:'..token..':before'].state=='failed','validation failure not terminal')
local after=request('after',{failAfter=true});assert(not after.ok)
assert(operations['20:'..token..':after'].state=='uncertain','partial failure should require reconciliation')
local n=calls;assert(not request('after',{failAfter=true}).ok and calls==n,'uncertain replayed')
local old=request('once',{amount=5});assert(old.ok,'duplicate must not corrupt completed record')
local raced=0
I.register('test.race',{permission='economy',mutating=true,handler=function(ctx,p)
    raced=raced+1
    local duplicate=I.dispatch(2,{requestId='race',sessionId=token,method='test.race',payload={}})
    assert(not duplicate.ok and duplicate.error.code=='OPERATION_UNCERTAIN','pending duplicate accepted')
    I.effect(ctx);return {done=true}
end})
assert(request('race',{},'test.race').ok and raced==1,'pending duplicate rewrote operation')
assert(operations['20:'..token..':race'].state=='applied','duplicate corrupted owner state')

users[2]=99
assert(not request('reuse',{}).ok,'reused source inherited session')
users[2]=20
local ctx={source=2,userId=20,permission='givemoney'}
assert(not pcall(I.effect,ctx),'permission revocation bypass')
-- Test actual economy handler against client-controlled identityEditor bypass.
dofile(root..'/resources/[scriptcore]/ic_admin/server/actions.lua')
local bypass=request('editor',{targetId=20,account='bank',amount=900,mode='set',reason='test',identityEditor=true},'economy.change')
assert(not bypass.ok and balance[20]==100,'client identityEditor flag bypassed authorization')
I.Store.get=function()return {actions={weather_manage={admin=false},radio_manage={admin=false},ban_history={admin=false}}},0 end
assert(not I.allowed(20,'set_weather') and not I.allowed(20,'radio_delete') and not I.allowed(20,'ban_history_view'),'imported permissions alias bypass')
I.Store.get=function()return {actions={economy={admin=true},edit_identity_balance={admin=false},givemoney={admin=false}}},0 end
local oldGet=I.Store.get
I.Store.get=function(...) roles[20]='suporte';I.sessions[2]=nil;return oldGet(...)end
assert(not pcall(I.effect,{source=2,userId=20,sessionId=token,permission='economy'}),'revocation during permission await accepted')
roles[20]='admin';I.Store.get=oldGet;I.newSession(2,20)
local fresh=I.newSession(2,20)
I.register('test.slowRead',{permission='view_players',handler=function()users[2]=99;return {private='old actor data'}end})
local late=request('late-read',{},'test.slowRead',2,fresh)
assert(not late.ok and late.error.code=='SESSION_EXPIRED' and late.data==nil,'Late read leaked data to a reused source')
users[2]=20
local lockOkay=pcall(I.withLock,'failure',function()error('expected')end)
assert(not lockOkay and I.locks.failure==nil,'failed lock leaked')
print('IC Admin core: authorization, sessions, replay, uncertainty, privilege bypass and locks passed')
