-- Exercise the installed doors client routing without running GTA rendering.
local root = assert(arg[1])
local events,threads,emitted={},{},{}
function module() return {getInterface=function()return {}end,bindInterface=function()end}end
function GetCurrentResourceName()return 'doorsv2'end
function RegisterNetEvent(name,fn)if fn then events[name]=fn end end
function AddEventHandler(name,fn)events[name]=fn end
function RegisterCommand()end
function RegisterKeyMapping()end
function CreateThread(fn)threads[#threads+1]=coroutine.create(fn)end
function Wait()coroutine.yield()end
function TriggerEvent(name,...)emitted[#emitted+1]={name=name,args={...}}end
function GetGameTimer()return 100 end
dofile(root..'/resources/[scripts]/doorsv2/doors_client.lua')
local start=assert(events['doorsv2:startMansionCapture'])
local cancel=assert(events['doorsv2:cancelMansionCapture'])
start()
start('ic_config')
assert(emitted[#emitted].name=='ic_config:mansionDoorCaptureCancelled')
cancel('ic_config') -- must not cancel the old panel's active capture
start('ic_config')
assert(emitted[#emitted].name=='ic_config:mansionDoorCaptureCancelled')
cancel('mg_config_panel')
assert(emitted[#emitted].name=='mg_config_panel:mansionDoorCaptureCancelled')
local count=#emitted
start('ic_config')
assert(#emitted==count)
start('arbitrary_untrusted_resource')
assert(emitted[#emitted].name=='mg_config_panel:mansionDoorCaptureCancelled')
events.onResourceStop('ic_config')
count=#emitted
start('ic_config')
assert(#emitted==count, 'resource stop must release the capture owner')
cancel('ic_config')
assert(emitted[#emitted].name=='ic_config:mansionDoorCaptureCancelled')
print('doors capture routing passed')
