-- Real garage configuration owner, with controlled native file failures.
local root=assert(arg[1]);json=dofile(root..'/tests/ic_config_json.lua')
local functions,files,kvp={}, {},{}
local mode,writeCount,applied,broadcasts,oldGarages,oldTypes
local G,T='shared-side/garages.json','shared-side/typeGarages.json'
function GetCurrentResourceName()return 'm_garage' end
function GetResourceKvpString(key)return kvp[key] end
function SetResourceKvp(key,value)kvp[key]=value end
function LoadResourceFile(_,path)return files[path] end
function SaveResourceFile(_,path,value)
    writeCount=writeCount+1
    if mode=='first_fail' and path==G then return false end
    if mode=='second_fail' and path==T then return false end
    if mode=='partial_restore_fail' and path==G then
        if writeCount==1 then files[path]='{"partial":' end
        return false
    end
    files[path]=value
    return mode~='native_false'
end
function ApplyGarageDynamicConfig()applied=applied+1 end
function TriggerClientEvent(name)assert(name=='m_garage:syncConfig');broadcasts=broadcasts+1 end
function exports(name,handler)functions[name]=handler end
local function garage(id,x)return {id=id,type='public',blipDistance=5,coords={x=x or 1,y=2,z=3},spawnCoords={{x=1,y=2,z=3,w=90}}} end
local function reset()
    functions={};files={};kvp={};mode='normal';writeCount=0;applied=0;broadcasts=0
    GarageConfigRaw={garage('A')}
    GarageTypesRaw={public={type='public',blip={showBlip=false,name='Public',blipId=357,blipColor=0,blipScale=.5},listCars={vehicle=true}},unused={type='public',blip={showBlip=false,name='Unused'}}}
    -- Deliberate whitespace proves compensation preserves exact previous bytes.
    oldGarages='\n '..json.encode(GarageConfigRaw)..'\n';oldTypes='\n '..json.encode(GarageTypesRaw)..'\n'
    files[G]=oldGarages;files[T]=oldTypes
    dofile(root..'/resources/[scriptcore]/m_garage/server-side/configManager.lua')
end
local function unchanged()
    assert(files[G]==oldGarages and files[T]==oldTypes,'prior file bytes were not preserved')
    assert(#GarageConfigRaw==1 and GarageConfigRaw[1].id=='A' and GarageTypesRaw.unused~=nil,'memory was not restored')
    assert(applied==0 and broadcasts==0,'failed persistence reached runtime or clients')
end
reset();assert(functions.addGarage(garage('B')));assert(applied==1 and broadcasts==1 and #json.decode(files[G])==2)
reset();mode='native_false';assert(functions.addGarage(garage('B')));assert(applied==1 and broadcasts==1)
reset();mode='first_fail';assert(not functions.addGarage(garage('B')));unchanged();mode='normal';assert(functions.addGarage(garage('B')))
reset();mode='second_fail';assert(not functions.addGarage(garage('B')));unchanged();assert(writeCount>=3,'first file was not compensated after the second failed')
local operations={
    function()return functions.addGarage(garage('B'))end,
    function()return functions.updateGarage('A',garage('A',10))end,
    function()return functions.removeGarage('A')end,
    function()return functions.addGarageType('new',{type='public',blip={}})end,
    function()return functions.updateGarageType('unused',{type='public',blip={name='Changed'}})end,
    function()return functions.removeGarageType('unused')end
}
for _,operation in ipairs(operations) do reset();mode='first_fail';assert(operation()==false,'mutation falsely reported success');unchanged() end
reset();mode='partial_restore_fail';assert(not functions.addGarage(garage('B')))
assert(kvp['ic_config:garage_config_quarantined']=='1' and #GarageConfigRaw==1 and applied==0 and broadcasts==0)
local attempts=writeCount;assert(not functions.addGarage(garage('B')));assert(writeCount==attempts,'quarantine attempted another write')
dofile(root..'/resources/[scriptcore]/m_garage/server-side/configManager.lua');assert(not functions.addGarage(garage('B')),'resource reload erased quarantine')
assert(not functions.reloadGarageConfig(),'invalid persisted partial file cleared quarantine')
mode='normal';files[G]=oldGarages;files[T]=oldTypes
assert(functions.reloadGarageConfig());assert(kvp['ic_config:garage_config_quarantined']=='0' and applied==1 and broadcasts==1)
assert(functions.addGarage(garage('B')))
print('garage owner: all mutation failures, native false success, exact compensation and persistent quarantine/reload passed')
