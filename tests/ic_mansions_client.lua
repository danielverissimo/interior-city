-- Execute the real FiveM client with deterministic native/RPC boundaries.
local root=assert(arg[1])
local function fixture()
    local s={events={},nui={},commands={},timers={},sent={},messages={},threads={},entities={},blips={},deleted={},focus=false,now=1000,nextEntity=100,nextBlip=200,validModel=true,loadedModel=true,pressed=nil,held={},position={x=1,y=2,z=3},notify={}}
    local env=setmetatable({}, {__index=_G});env._G=env
    local function noop()end
    env.GetCurrentResourceName=function()return'ic_mansions'end
    env.GetGameTimer=function()return s.now end
    env.RegisterNetEvent=function(name,fn)s.events[name]=fn end
    env.AddEventHandler=function(name,fn)s.events[name]=fn end
    env.RegisterNUICallback=function(name,fn)s.nui[name]=fn end
    env.RegisterCommand=function(name,fn)s.commands[name]=fn end
    env.CreateThread=function(fn)s.threads[#s.threads+1]=coroutine.create(fn)end
    env.Wait=function(milliseconds)s.now=s.now+math.max(milliseconds or 0,16);coroutine.yield(milliseconds)end
    env.SetTimeout=function(ms,fn)s.timers[#s.timers+1]={ms=ms,fn=fn}end
    env.SetNuiFocus=function(focus)s.focus=focus end
    env.SendNUIMessage=function(message)s.messages[#s.messages+1]=message end
    env.TriggerEvent=function(name,... )s.notify[#s.notify+1]={name=name,args={...}}end
    env.TriggerServerEvent=function(name,value)s.sent[#s.sent+1]={name=name,value=value}end
    env.PlayerPedId=function()return 7 end
    env.GetEntityCoords=function(entity)return entity==7 and s.position or s.entities[entity]or{x=0,y=0,z=0}end
    env.GetEntityHeading=function(entity)return entity==7 and 90 or(s.entities[entity]or{}).heading or 0 end
    env.GetOffsetFromEntityInWorldCoords=function(_,x,y,z)return{x=s.position.x+x,y=s.position.y+y,z=s.position.z+z}end
    env.DoesEntityExist=function(entity)return s.entities[entity]~=nil end
    env.DeleteEntity=function(entity)s.deleted[#s.deleted+1]=entity;s.entities[entity]=nil end
    env.GetHashKey=function(name)return type(name)=='string'and #name+100 or name end
    env.IsModelInCdimage=function()return s.validModel end
    env.IsModelValid=function()return s.validModel end
    env.RequestModel=function()s.modelRequests=(s.modelRequests or 0)+1 end
    env.HasModelLoaded=function()return s.loadedModel end
    env.SetModelAsNoLongerNeeded=function()s.modelReleased=(s.modelReleased or 0)+1 end
    env.CreateObjectNoOffset=function(hash,x,y,z)
        if s.failCreate then return 0 end
        s.nextEntity=s.nextEntity+1;s.entities[s.nextEntity]={hash=hash,x=x,y=y,z=z};return s.nextEntity
    end
    env.SetEntityCoordsNoOffset=function(entity,x,y,z)if s.entities[entity]then s.entities[entity].x=x;s.entities[entity].y=y;s.entities[entity].z=z end end
    env.SetEntityHeading=function(entity,heading)if s.entities[entity]then s.entities[entity].heading=heading end end
    env.SetEntityAlpha=function(entity,alpha)if s.entities[entity]then s.entities[entity].alpha=alpha end end
    env.FreezeEntityPosition=noop;env.SetEntityCollision=noop
    env.IsControlPressed=function(_,key)return s.held[key]==true end
    env.IsControlJustPressed=function(_,key)return s.pressed==key end
    env.AddBlipForCoord=function(x,y,z)s.nextBlip=s.nextBlip+1;s.blips[s.nextBlip]={x=x,y=y,z=z};return s.nextBlip end
    env.DoesBlipExist=function(blip)return s.blips[blip]~=nil end
    env.RemoveBlip=function(blip)s.blips[blip]=nil end
    for _,name in ipairs({'SetTextFont','SetTextScale','SetTextCentre','SetTextColour','SetTextOutline','BeginTextCommandDisplayText','AddTextComponentSubstringPlayerName','EndTextCommandDisplayText','DrawMarker','SetBlipSprite','SetBlipColour','SetBlipScale','SetBlipAsShortRange','BeginTextCommandSetBlipName','EndTextCommandSetBlipName'})do env[name]=noop end
    assert(loadfile(root..'/resources/[scriptcore]/ic_mansions/config.lua','t',env))()
    assert(loadfile(root..'/resources/[scriptcore]/ic_mansions/client/main.lua','t',env))()
    s.env=env
    function s:last(method)
        for index=#self.sent,1,-1 do local event=self.sent[index];if event.name=='ic_mansions:request'and(not method or event.value.method==method)then return event.value end end
    end
    function s:count(method)local count=0;for _,event in ipairs(self.sent)do if event.name=='ic_mansions:request'and event.value.method==method then count=count+1 end end;return count end
    function s:answer(request,data,origin,error)
        local thread=coroutine.create(function()env.source=origin or 65535;s.events['ic_mansions:response']({requestId=request.requestId,ok=error==nil,data=data,error=error})end)
        local ok,message=coroutine.resume(thread);assert(ok,message);return thread
    end
    function s:event(name,value,origin)env.source=origin or 65535;assert(self.events['ic_mansions:'..name],name)(value)end
    function s:tick(index,key)
        self.pressed=key;local ok,message=coroutine.resume(self.threads[index]);self.pressed=nil;assert(ok,message)
    end
    function s:frame(key)self:tick(1,key);self:tick(1,key)end
    function s:open(section)
        self.commands[section or'mansao']();local request=self:last('getContext');self:answer(request,{mansionId='m1',mansionName='Test Mansion',canFurniture=true,furniture={}});assert(self.focus,'open must focus NUI')
    end
    function s:startBuy(id)
        local callback;s.nui.request({requestId=id or'ui:buy',method='startFurniturePlacement',payload={mansionId='m1',itemId='chair'}},function(value)callback=value end)
        local request=self:last('beginFurniturePurchase');assert(request.payload.itemId=='chair')
        return request,function()return callback end
    end
    function s:readyBuy(request)
        self:answer(request,{placementToken='placement-fixture',mansionId='m1',item={id='chair',name='Chair',model='prop_chair',price=1000}})
    end
    return s
end

do
    local s=fixture();s.commands.mansao();local pending=s:last()
    s.nui.close({},function()end);s:answer(pending,{mansionId='m1'})
    assert(not s.focus and s.messages[#s.messages].action=='close','late context must not reopen closed UI')
    s.commands.mobilias();pending=s:last();s:answer(pending,{mansionId='m1'},1);assert(not s.focus,'local source cannot spoof server response')
    s:answer(pending,{mansionId='m1'});assert(s.focus and s.messages[#s.messages].view=='catalog','mobilias must open existing catalogue view')
    s.nui.close({},function()end);s:open('addmorador');assert(s.messages[#s.messages].view=='residents')
    s:event('sync',{{id='m1',name='Spoof',purchaseCoords={x=1,y=2,z=3}}},1);assert(next(s.blips)==nil,'local source cannot inject world blips')
    s.nui.close({},function()end);s.commands.mansao();pending=s:last();s.commands.mansao();s:answer(pending,{mansionId='m1'})
    assert(not s.focus,'toggling a pending open must invalidate its later response')
end

do
    local s=fixture();s:open();local request,result=s:startBuy();assert(result()==nil)
    s:readyBuy(request);assert(result().ok and result().requestId=='ui:buy'and not s.focus and s.messages[#s.messages].action=='suspend')
    assert(s:count('confirmFurniturePlacement')==0,'begin placement must not confirm or debit')
    s:frame(177);assert(s.focus and s.messages[#s.messages].action=='resume'and next(s.entities)==nil,'cancel must remove ghost and restore focus')
    assert(s:count('confirmFurniturePlacement')==0,'cancel must never send economic confirmation')
end

do
    local s=fixture();s:open();local request=s:startBuy();s:readyBuy(request)
    s:frame(38);local confirmation=s:last('confirmFurniturePlacement');assert(confirmation,'E must confirm placement')
    assert(confirmation.payload.mansionId=='m1'and confirmation.payload.itemId=='chair'and confirmation.payload.placementToken=='placement-fixture')
    assert(confirmation.payload.coords.x==1 and confirmation.payload.coords.y==4 and confirmation.payload.heading==90)
    s:frame(38);assert(s:count('confirmFurniturePlacement')==1,'held confirm must send once while response pending')
    s:answer(confirmation,{furnitureId='placed-fixture'});assert(s.focus and next(s.entities)==nil and s.messages[#s.messages].action=='resume')
    local before=#s.messages;s:answer(confirmation,{furnitureId='duplicate'});assert(#s.messages==before,'duplicate server result must be ignored')
end

do
    local s=fixture();s:open();local request,result=s:startBuy('late:begin');s.nui.close({},function()end);s:readyBuy(request)
    assert(result().error.code=='CLOSED'and next(s.entities)==nil and not s.focus,'late begin must never create a ghost or refocus')
    s=fixture();s:open();request,result=s:startBuy('denied:begin');s:answer(request,nil,nil,{code='FORBIDDEN',message='Revoked.'})
    assert(result().requestId=='denied:begin'and result().error.code=='FORBIDDEN'and next(s.entities)==nil and s.focus,'server refusal must preserve original NUI id with no preview')
    s=fixture();s:open();s.validModel=false;request,result=s:startBuy('bad:model');s:readyBuy(request)
    assert(result().error.code=='INVALID_MODEL'and next(s.entities)==nil and s:count('confirmFurniturePlacement')==0,'invalid model must never charge')
    s=fixture();s:open();s.failCreate=true;request,result=s:startBuy('bad:entity');s:readyBuy(request)
    assert(result().error.code=='INVALID_MODEL'and next(s.entities)==nil,'failed entity creation must return an error')
    s=fixture();s:open();s.loadedModel=false;request,result=s:startBuy('model:timeout')
    local loader=s:answer(request,{placementToken='fixture',item={id='chair',model='prop_chair'}})
    assert(coroutine.status(loader)=='suspended');s.now=s.now+6000;local ok,message=coroutine.resume(loader);assert(ok,message)
    assert(result().error.code=='INVALID_MODEL'and s:count('confirmFurniturePlacement')==0,'model timeout must not confirm purchase')
    s=fixture();s:open();s.loadedModel=false;request,result=s:startBuy('model:closed')
    loader=s:answer(request,{placementToken='fixture',item={id='chair',model='prop_chair'}});s.nui.close({},function()end);s.loadedModel=true
    ok,message=coroutine.resume(loader);assert(ok,message)
    assert(result().error.code=='CLOSED'and next(s.entities)==nil and not s.focus,'model readiness after close must not create preview')
end

do
    local s=fixture();s:open();local result
    s.nui.request({requestId='move:1',method='startFurnitureMove',payload={mansionId='m1',furnitureId='existing'}},function(value)result=value end)
    local request=s:last('getContext');s:answer(request,{canFurniture=true,furniture={{id='existing',model='prop_chair',heading=40}}})
    assert(result.ok and not s.focus and s:count('beginFurniturePurchase')==0,'move must use existing furniture without a purchase')
    s:frame(38);local update=s:last('updateFurniture');assert(update.payload.furnitureId=='existing'and update.payload.heading==40 and not update.payload.itemId)
    s:answer(update,nil,nil,{code='FORBIDDEN',message='Ownership revoked.'})
    assert(s.focus and next(s.entities)==nil and s.messages[#s.messages-1].action=='operationResult'and s.messages[#s.messages-1].ok==false,'revoked finish must report failure and delete preview')
end

do
    local s=fixture();s:open();local result
    s.nui.request({requestId='timeout:1',method='payIptu',payload={mansionId='m1',confirmed=true}},function(value)result=value end)
    local request=s:last();s.timers[#s.timers].fn();assert(result.error.code=='TIMEOUT'and s:count('payIptu')==1)
    result=nil;s:answer(request,{});assert(result==nil,'late timed-out responses must not repeat callbacks')
    s.nui.request({requestId='dup:1',method='getContext',payload={}},function(value)result=value end)
    s.nui.request({requestId='dup:1',method='getContext',payload={}},function(value)result=value end)
    assert(result.error.code=='BUSY','duplicate active UI id must be refused')
end

do
    local s=fixture();s:open();s:event('sync',{{id='m1',name='Mansion',purchaseCoords={x=1,y=2,z=3}}})
    s:event('furnitureSync',{{id='existing',mansionId='m1',model='prop_chair',x=1,y=2,z=3,heading=10}})
    s:tick(3);assert(next(s.entities)~=nil and next(s.blips)~=nil,'real streamer must create local furniture and map blips')
    local request=s:startBuy();s:readyBuy(request)
    local stopped;s.nui.request({requestId='stop:pending',method='getContext',payload={}},function(value)stopped=value end)
    s.events.onResourceStop('ic_mansions')
    assert(not s.focus and next(s.entities)==nil and next(s.blips)==nil,'stop must delete ghost, streamed objects and blips and release focus')
    assert(stopped.error.code=='STOPPED','stop must resolve pending callbacks exactly once')
end

-- A close may occur while the placement coroutine is yielded at Wait(0).
do
    local s=fixture();s:open();local request=s:startBuy();s:readyBuy(request)
    s:tick(1);s.nui.close({},function()end);s:frame(38)
    assert(s:count('confirmFurniturePlacement')==0,'closed placement must not process a stale E press after Wait')
    assert(not s.focus and next(s.entities)==nil)
end

do
    local s=fixture();s.loadedModel=false
    s:event('furnitureSync',{{id='existing',mansionId='m1',model='prop_chair',x=1,y=2,z=3}})
    s:tick(3);assert(coroutine.status(s.threads[3])=='suspended','streamer should wait for model')
    s.events.onResourceStop('ic_mansions');s.loadedModel=true;s:tick(3)
    assert(next(s.entities)==nil and not s.focus,'model stream completing after stop must not resurrect entities')
end
print('ic_mansions client lifecycle harness passed')
