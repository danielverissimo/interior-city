local root=assert(arg[1])
json=dofile(root..'/tests/ic_config_json.lua')
local timer,calls,output,legacy=0,0,{},'stopped'
ICConfig={PreviousResource='mg_config_panel'}
ICConfigServer={Organizations={schema=function()calls=calls+1;if calls==1 then error('PRIVATE_FIXTURE')end;return true end}}
function GetGameTimer()return timer end
function Wait(ms)timer=timer+ms end
function GetConvar(name,default)if name=='ic_config_enabled'then return'true'elseif name=='ic_mansions_resource'then return'ic_mansions'end;return default end
function GetResourceState(name)if name=='mg_config_panel'then return legacy end;return'started'end
function CreateThread(fn)fn()end
function print(value)output[#output+1]=value end
local path=root..'/resources/[scriptcore]/ic_config/server/runtime.lua'
dofile(path)
assert(calls==2)
local marker=output[#output]:match('%[ic_config:operational%]%s*(.*)')
assert(json.decode(marker).active==true)
assert(not output[#output]:find('PRIVATE_FIXTURE',1,true))
legacy='started';timer=0;calls=0;dofile(path)
marker=output[#output]:match('%[ic_config:operational%]%s*(.*)')
assert(json.decode(marker).active==false and calls==0)
io.write('operational markers wait for schema and reject legacy provider\n')
