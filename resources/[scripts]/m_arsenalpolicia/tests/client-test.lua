local commands,callbacks,timers,messages={},{},{},{}
local focus=false
local eventHandlers={}
local blips,blipSequence={},0
local keepInput=false
local response={ok=true,canManage=true,location={x=1,y=2,z=3}}
function module() return {getInterface=function() return {open=function() return response end} end} end
function GetCurrentResourceName() return 'm_arsenalpolicia' end
function RegisterCommand(name,fn) commands[name]=fn end
function RegisterNUICallback(name,fn) callbacks[name]=fn end
function RegisterNetEvent(name,fn) eventHandlers[name]=fn end
function AddEventHandler() end
function CreateThread() end
function SetTimeout(_,fn) timers[#timers+1]=fn end
function SetNuiFocus(value) focus=value end
function SetNuiFocusKeepInput(value) keepInput=value end
function SendNUIMessage(message) messages[#messages+1]=message end
function TriggerEvent() end
function DoesBlipExist(id) return blips[id]~=nil end
function RemoveBlip(id) blips[id]=nil end
function AddBlipForCoord(x,y,z) blipSequence=blipSequence+1;blips[blipSequence]={x=x,y=y,z=z};return blipSequence end
function SetBlipSprite() end
function SetBlipColour() end
function SetBlipScale() end
function SetBlipAsShortRange() end
function BeginTextCommandSetBlipName() end
function AddTextComponentString() end
function EndTextCommandSetBlipName() end
assert(load(CLIENT_SOURCE))()
assert(not focus and #messages==0,'starting the resource must not take focus')
commands[Config.Command]()
assert(not focus,'must not take focus before UI renders')
assert(blips[blipSequence].x==1,'map blip must appear at active point')
local oldBlip=blipSequence
eventHandlers['m_arsenalpolicia:location']({x=100,y=200,z=30})
assert(not blips[oldBlip] and blips[blipSequence].x==100,'old map blip must be replaced')
eventHandlers['m_arsenalpolicia:location'](false)
assert(next(blips)==nil,'clear location must remove the map blip')
local token=messages[#messages].token
local reply=nil
callbacks.visible({token=token},function(r) reply=r end)
assert(focus and reply.ok,'render acknowledgement must enable focus')
commands.fechararsenal()
assert(not focus and not keepInput and messages[#messages].action=='close','emergency close must release focus')
callbacks.visible({token=token},function(r) reply=r end)
assert(not focus and not reply.ok,'stale acknowledgement must not reopen the UI')
commands[Config.Command]()
assert(not focus,'missing UI must never lock controls')
timers[#timers]()
assert(not focus and messages[#messages].action=='close','render timeout must release UI')
response={ok=false,message='denied'}
commands[Config.Command]()
assert(not focus and messages[#messages].action=='close','failed server open must not take focus')
response={ok=true,canManage=true,location={x=1,y=2,z=3}}
commands[Config.Command]()
commands[Config.Command]()
assert(not focus and messages[#messages].action=='close','command repeated during loading must close')
return 'PASS: transparent startup/focus handshake; emergency close; timeout; stale messages; map blip creation, replacement and removal.'
