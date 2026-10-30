local root = assert(arg[1])
local events, nui, commands, timers, sent, messages = {}, {}, {}, {}, {}, {}
local focused = false
local threads, pressed = {}, nil
local localEvents = {}
function GetCurrentResourceName() return 'ic_config' end
function GetGameTimer() return 1234 end
function GetConvar(_, fallback) return fallback end
function GetResourceState() return 'started' end
function RegisterNetEvent(name, fn) events[name] = fn end
function AddEventHandler(name, fn) events[name] = fn end
function RegisterNUICallback(name, fn) nui[name] = fn end
function RegisterCommand(name, fn) commands[name] = fn end
function RegisterKeyMapping() end
function CreateThread(fn) threads[#threads+1] = coroutine.create(fn) end
function Wait() coroutine.yield() end
function SetTextFont() end
function SetTextScale() end
function SetTextCentre() end
function SetTextColour() end
function SetTextOutline() end
function BeginTextCommandDisplayText() end
function AddTextComponentSubstringPlayerName() end
function EndTextCommandDisplayText() end
function DisableControlAction() end
function DrawLine() end
function IsControlJustPressed(_,key) return pressed == key end
function SetTimeout(_, fn) timers[#timers+1] = fn end
function SetNuiFocus(a) focused = a end
function SendNUIMessage(value) messages[#messages+1] = value end
function TriggerEvent(name,...)
    localEvents[#localEvents+1] = {name=name,args={...}}
    if events[name] then events[name](...) end
end
function TriggerServerEvent(name, value) sent[#sent+1] = {name=name,value=value} end
function PlayerPedId() return 7 end
function GetEntityCoords() return {x=1,y=2,z=3} end
function GetEntityHeading() return 90 end
function GetEntityModel() return 11 end
function GetHashKey(value) return value == 'mp_m_freemode_01' and 11 or 12 end
function GetPedDrawableVariation(_, i) return i end
function GetPedTextureVariation() return 0 end
function GetPedPaletteVariation() return 0 end
function GetPedPropIndex() return -1 end
function GetPedPropTextureIndex() return 0 end
local function answer(value, origin)
    source = origin or 65535
    events['ic_config:response'](value)
end
local function latest() return sent[#sent].value end
dofile(root .. '/resources/[scriptcore]/ic_config/config.lua')
dofile(root .. '/resources/[scriptcore]/ic_config/client/main.lua')
assert(commands.icconfig and not commands.painelconfig, 'legacy aliases must be opt-in')
commands.icconfig()
local first = latest()
assert(first.method == 'hasAccess' and not focused)
nui.close({}, function() end)
answer({requestId=first.requestId,ok=true,data=true})
assert(not focused, 'late authorization must not reopen a closed UI')
commands.icconfig()
local open = latest()
answer({requestId=open.requestId,ok=true,data=true},1)
assert(not focused, 'nonserver responses must be ignored')
answer({requestId=open.requestId,ok=true,data=true})
assert(focused and messages[#messages].action == 'open')
local result
nui.request({requestId='pos:1',method='getPlayerPosition'}, function(v) result=v end)
assert(result == nil and latest().method == 'hasAccess')
answer({requestId=latest().requestId,ok=true,data=true})
assert(result.ok and result.data.x == 1 and result.data.heading == 90)
result = nil
nui.request({requestId='pos:denied',method='getPlayerPosition'}, function(v) result=v end)
answer({requestId=latest().requestId,ok=false,error={code='FORBIDDEN',message='Sem permissão.'}})
assert(result.requestId == 'pos:denied' and result.error.code == 'FORBIDDEN')
result = nil
nui.request({requestId='outfit:1',method='getCurrentOutfit'},function(v) result=v end)
answer({requestId=latest().requestId,ok=true,data=true})
assert(result.data.gender == 'masculino' and not result.data.outfit['2'])
assert(result.data.outfit.p0[1] == -1)
result = nil
nui.request({requestId='capture:1',method='startPositionCapture',payload={target='editor1:coords'}},function(v) result=v end)
answer({requestId=latest().requestId,ok=true,data=true})
assert(result.ok and not focused and messages[#messages].action == 'suspend')
pressed = 38
assert(coroutine.resume(threads[1]))
pressed = nil
answer({requestId=latest().requestId,ok=true,data=true})
assert(focused and messages[#messages].action == 'resume')
assert(messages[#messages-1].action == 'captureResult' and messages[#messages-1].data.x == 1)
result = nil
nui.request({requestId='polygon:1',method='startSafeZonePolygon',payload={target='editor1:zones'}},function(v) result=v end)
answer({requestId=latest().requestId,ok=true,data=true})
pressed = 38
for _=1,3 do assert(coroutine.resume(threads[1])) end
pressed = 177
assert(coroutine.resume(threads[1]))
pressed = nil
answer({requestId=latest().requestId,ok=true,data=true})
local polygon=messages[#messages-1]
assert(polygon.kind == 'polygon' and #polygon.data.coords == 3)
assert(polygon.data.maxZ > polygon.data.minZ)
result = nil
nui.request({requestId='doors:1',method='startMansionDoorCapture',payload={target='mansion1:doors'}},function(v) result=v end)
answer({requestId=latest().requestId,ok=true,data=true})
assert(result.ok and not focused)
assert(localEvents[#localEvents].name=='doorsv2:startMansionCapture' and localEvents[#localEvents].args[1]=='ic_config')
events['ic_config:mansionDoorsCaptured']({{hash=123,x=1,y=2,z=3,lock=true}})
answer({requestId=latest().requestId,ok=true,data=true})
assert(focused and messages[#messages-1].kind=='doors' and messages[#messages-1].data.doors[1].hash==123)
result = nil
nui.request({requestId='doors:2',method='startMansionDoorCapture',payload={target='mansion1:doors'}},function(v) result=v end)
answer({requestId=latest().requestId,ok=true,data=true})
nui.close({},function() end)
assert(localEvents[#localEvents].name=='doorsv2:cancelMansionCapture')
events['ic_config:mansionDoorsCaptured']({{hash=999}})
assert(not focused, 'late door capture must not reopen closed panel')
commands.icconfig()
answer({requestId=latest().requestId,ok=true,data=true})
result = nil
nui.request({requestId='mutate:1',method='saveManagedGroup',payload={}},function(v) result=v end)
local mutation = latest()
timers[#timers]()
assert(result.error.code == 'TIMEOUT')
result = nil
answer({requestId=mutation.requestId,ok=true,data={}})
assert(result == nil, 'late mutation response must not invoke callback again')
nui.request({requestId='pos:closed',method='getPlayerPosition'},function(v) result=v end)
local check = latest()
nui.close({},function() end)
answer({requestId=check.requestId,ok=true,data=true})
assert(result.error.code == 'CLOSED')
events.onResourceStop('ic_config')
assert(not focused)
print('ic_config client harness passed')
