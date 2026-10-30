local root,source=assert(arg[1]),assert(arg[2])
json=dofile(root..'/tests/ic_config_json.lua')
ICMConfig={StateFiles={'state-a.json','state-b.json'}}
function GetCurrentResourceName()return'ic_mansions'end
function LoadResourceFile(_,name)local f=io.open(source..'/'..name,'rb');if not f then return nil end;local raw=f:read('*a');f:close();return raw end
function SaveResourceFile(_,name,raw)local f=assert(io.open(source..'/'..name,'wb'));f:write(raw);f:close();return true end
dofile(root..'/resources/[scriptcore]/ic_mansions/server/store.lua')
local state=ICM.Store.load()
assert(ICM.Store.generation==1)
assert(state.mansions[1].ownerId==101 and state.mansions[1].members[1]==202)
assert(state.mansions[1].iptuPaidUntil==100 and state.mansions[1].furniture[1].paidPrice==750)
assert(state.mansions[1].name=='Mansão Sintética')
ICM.Store.save(state)
assert(ICM.Store.generation==2)
ICM.Store.generation=nil
assert(ICM.Store.load().mansions[1].iptuPaidUntil==100)
print('imported state accepted by real two-slot store')
