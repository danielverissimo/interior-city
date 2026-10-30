-- Actual own modules, synthetic FiveM/vRP/export/filesystem boundaries.
local root=assert(arg[1])
local function copy(v)if type(v)~='table'then return v end;local o={};for k,x in pairs(v)do o[k]=copy(x)end;return o end
local encoded,encoding={},0
json={encode=function(value)encoding=encoding+1;local key='fixture-json-'..encoding;encoded[key]=copy(value);return key end,
    decode=function(raw)if not encoded[raw]then error('invalid fixture JSON')end;return copy(encoded[raw])end}
local files,events,handlers,registered,threads={},{},{},{},{}
local responses,notices={},{}
local convars={ic_mansions_enabled='true',ic_mansions_resource='ic_mansions'}
local legacy='stopped';local invoke='ic_config';local positions={[7]={x=0,y=0,z=0},[8]={x=0,y=0,z=0},[9]={x=0,y=0,z=0}}
local users={[7]=41,[8]=42,[9]=99}
local roles={[41]={},[42]={},[99]={developer=true}}
local bank,vouchers,assigned,groups,chests,garages,doors={},{},{},{},{},{},{}
local persistedGarages,garageReadOnly={},false
local payments,credits,inventoryTakes,saveCount,failAtSave=0,0,0,0,nil
local unavailableAfterSave,creditThrowAfter=nil,false
local groupFailure,groupThrowAfter=false,false
function GetCurrentResourceName()return'ic_mansions'end
function GetConvar(name,fallback)return convars[name]or fallback end
function GetResourceState(name)return name=='m_mansions'and legacy or'started'end
function GetInvokingResource()return invoke end
function GetGameTimer()return 1234 end
function GetPlayerPed(sourceId)return positions[sourceId]and sourceId or 0 end
function GetEntityCoords(ped)return positions[ped]end
function LoadResourceFile(resource,path)
    if resource=='m_garage'and path=='shared-side/garages.json'then local out={};for _,row in pairs(persistedGarages)do out[#out+1]=copy(row)end;return json.encode(out)end
    if unavailableAfterSave and saveCount>=unavailableAfterSave then return nil end;return files[path]
end
function SaveResourceFile(_,path,raw)
    saveCount=saveCount+1
    if failAtSave==saveCount then return false end
    files[path]=raw;return true
end
function RegisterNetEvent(name,fn)events[name]=fn end
function AddEventHandler(name,fn)handlers[name]=fn end
function TriggerClientEvent(name,target,value)
    if name=='ic_mansions:response'then responses[#responses+1]=value else notices[#notices+1]={name=name,target=target,value=copy(value)}end
end
function SetTimeout(_,fn)end
function CreateThread(fn)threads[#threads+1]=fn end
function Wait()end
GlobalState={}
local vrp={
    getUserId=function(src)return users[src]end,getUserGroups=function(id)return roles[id]or{}end,
    getUserIdentity=function(id)if id==41 or id==42 or id==43 or id==99 then return{nome='Fixture',sobrenome=tostring(id)}end end,
    getUserSource=function(id)for src,uid in pairs(users)do if uid==id then return src end end end,
    getInventoryItemAmount=function(id,item)return(vouchers[id]or{})[item]or 0 end,
    tryGetInventoryItem=function(id,item,n)inventoryTakes=inventoryTakes+1;local map=vouchers[id]or{};if(map[item]or 0)<n then return false end;map[item]=map[item]-n;return true end,
    giveInventoryItem=function(id,item,n)vouchers[id]=vouchers[id]or{};vouchers[id][item]=(vouchers[id][item]or 0)+n;return true end,
    tryFullPayment=function(id,amount)payments=payments+1;if(bank[id]or 0)<amount then return false end;bank[id]=bank[id]-amount;return true end,
    getBankMoney=function(id)return bank[id]or 0 end,
    giveBankMoney=function(id,amount)credits=credits+1;bank[id]=(bank[id]or 0)+amount;if creditThrowAfter then error('synthetic post-credit failure')end end,
}
function module()return{getInterface=function()return vrp end}end
local function rows(map)local out={};for _,row in pairs(map)do out[#out+1]=copy(row)end;return out end
local exportMethods={
    vrp={
        getManagedGroups=function()return rows(groups)end,
        getManagedGroupAssignments=function(name)
            local out={group=name,assignments={},count=0}
            for id,map in pairs(assigned)do if map[name]then out.assignments[#out.assignments+1]={userId=id,online=vrp.getUserSource(id)~=nil}end end
            out.count=#out.assignments;return out
        end,
        saveManagedGroup=function(original,row)
            local old=groups[original];groups[original]=nil;groups[row.name]=copy(row)
            if old and original~=row.name then for _,map in pairs(assigned)do if map[original]then map[original]=nil;map[row.name]=true end end end
            return true
        end,
        removeManagedGroup=function(name)groups[name]=nil;return true end,
        addManagedUserGroup=function(id,name)
            if groupFailure then return false end
            assigned[id]=assigned[id]or{};assigned[id][name]=true
            if groupThrowAfter then error('synthetic uncertain group API')end
            return true
        end,
        removeManagedUserGroup=function(id,name)assigned[id]=assigned[id]or{};assigned[id][name]=nil;return true end,
    },
    inventory={
        getChests=function()return rows(chests)end,
        addChest=function(name,weight,permission,coords)chests[name]={name=name,weight=weight,permission=permission,coords=copy(coords)};return true end,
        updateChest=function(name,weight,coords,permission)chests[name]={name=name,weight=weight,permission=permission,coords=copy(coords)};return true end,
        removeChest=function(name)chests[name]=nil;return true end,
    },
    m_garage={getGarages=function()return rows(garages)end,getGarageTypes=function()return{public={type='public'}}end,
        addGarage=function(row)garages[row.id]=copy(row);if not garageReadOnly then persistedGarages[row.id]=copy(row)end;return true end,
        updateGarage=function(id,row)garages[id]=nil;garages[row.id]=copy(row);if not garageReadOnly then persistedGarages[id]=nil;persistedGarages[row.id]=copy(row)end;return true end,
        removeGarage=function(id)garages[id]=nil;if not garageReadOnly then persistedGarages[id]=nil end;return true end},
    doorsv2={getMansionDoors=function(id)return copy(doors[id]or{})end,
        replaceMansionDoors=function(id,permission,value)doors[id]=copy(value);return true end,
        removeMansionDoors=function(id)doors[id]=nil;return true end},
}
exports=setmetatable({},{__call=function(_,name,fn)registered[name]=fn end,__index=function(_,resource)
    return setmetatable({},{__index=function(_,name)return function(_,...)assert(exportMethods[resource]and exportMethods[resource][name],resource..':'..name);return exportMethods[resource][name](...)end end})
end})
local function fixture(owner)
    return{version=1,mansions={{id='fixture-home',name='Fixture home',group='MansaoFixture',permission='perm.mansaofixture',price=1000000,iptuValue=100,maxResidents=3,
        voucher='valemansao1m',purchaseCoords={x=0,y=0,z=0},chest={enabled=false,name='Mansao_fixture-home'},garage={enabled=false,id='Mansao_fixture-home'},doors={},
        ownerId=owner,members={},furniture={},iptuPaidUntil=owner and os.time()+86400 or nil,createdAt=100}},operations={},catalogPrices={}}
end
local function reset(owner)
    files={};saveCount=0;failAtSave=nil;unavailableAfterSave=nil;creditThrowAfter=false;groupFailure=false;groupThrowAfter=false
    bank={[41]=10000,[42]=1000,[99]=10000};vouchers={[41]={valemansao1m=2},[42]={valemansao1m=2}}
    assigned={};if owner then assigned[owner]={MansaoFixture=true}end
    groups={MansaoFixture={name='MansaoFixture',config={title='MansaoFixture'},permissions={'perm.mansaofixture'}}};chests={};garages={};doors={}
    persistedGarages={};garageReadOnly=false
    roles={[41]={},[42]={},[99]={developer=true}};legacy='stopped';convars.ic_mansions_enabled='true';convars.ic_mansions_resource='ic_mansions'
    positions[7]={x=0,y=0,z=0};positions[8]={x=0,y=0,z=0};positions[9]={x=0,y=0,z=0};invoke='ic_config'
    payments=0;credits=0;inventoryTakes=0;responses={};notices={};events={};handlers={};registered={};threads={}
    local state=fixture(owner);files['state-a.json']=json.encode({generation=0,state=state});files['state-b.json']=files['state-a.json']
    files['catalog.json']=json.encode({version=1,items={{id='chair',name='Chair',model='prop_chair_01a',category='Cadeiras',price=500}}})
    dofile(root..'/resources/[scriptcore]/ic_mansions/config.lua')
    for _,name in ipairs({'store','core','admin','gameplay','furniture','bootstrap'})do dofile(root..'/resources/[scriptcore]/ic_mansions/server/'..name..'.lua')end
end
local serial=0
local function request(method,payload,id,src)
    serial=serial+1;ICM.request(src or 7,{requestId=id or('request:'..serial),method=method,payload=payload or{}});return responses[#responses]
end
local function success(value)assert(value and value.ok,value and value.error and(value.error.code..':'..value.error.message));return value.data end
local function code(value,name)assert(value and not value.ok and value.error.code==name,(value and value.error and value.error.code or'success')..' ~= '..name)end
local function row()return ICM.state().mansions[1]end

-- Purchase is voucher-only, confirmed once, and never trusts supplied actor IDs.
reset()
local quote=success(request('requestPurchase',{id='fixture-home',userId=42}))
local bought=success(request('confirmPurchase',{id='fixture-home',quoteToken=quote.quoteToken,confirmed=true},'once'))
assert(row().ownerId==41 and vouchers[41].valemansao1m==1 and assigned[41].MansaoFixture)
assert(payments==0 and bank[41]==10000 and row().iptuPaidUntil>os.time()+19*86400)
for _,op in pairs(ICM.state().operations)do assert(op.phase=='done'and op.detail.before==nil and op.detail.voucher=='valemansao1m')end
code(request('confirmPurchase',{id='fixture-home',quoteToken=quote.quoteToken,confirmed=true},'once'),'DUPLICATE_REQUEST')
assert(vouchers[41].valemansao1m==1)
code(request('requestPurchase',{id='fixture-home'},nil,8),'OCCUPIED')

-- Storage failure after confirmed voucher/group effects compensates exactly once.
reset();quote=success(request('requestPurchase',{id='fixture-home'}));failAtSave=3
code(request('confirmPurchase',{id='fixture-home',quoteToken=quote.quoteToken,confirmed=true}),'STORAGE_ERROR')
assert(not row().ownerId and vouchers[41].valemansao1m==2 and not assigned[41].MansaoFixture and #ICM.pending(row().id)==0)

-- An export that mutates then throws remains journaled and cannot grant access.
reset();quote=success(request('requestPurchase',{id='fixture-home'}));groupThrowAfter=true
code(request('confirmPurchase',{id='fixture-home',quoteToken=quote.quoteToken,confirmed=true}),'RECONCILIATION_REQUIRED')
assert(#ICM.pending(row().id)==1 and assigned[41].MansaoFixture and not row().ownerId)
for _,op in pairs(ICM.state().operations)do assert(op.detail.before and op.phase=='uncertain')end
assert(registered.checkAccessByPermission(7,row().permission)==false)
code(request('requestPurchase',{id='fixture-home'}),'RECONCILIATION_REQUIRED')
local summary=success(request('getPendingOperations',{},nil,9));local pending=summary.operations[1]
code(request('reconcileOperation',{operationId=pending.id,confirmed=true,expectedRevision=summary.revision-1,decision='cancel_after_manual_reconciliation',confirmation='RECONCILIADO '..pending.id},nil,9),'CONFLICT')
code(request('reconcileOperation',{operationId=pending.id,confirmed=true,expectedRevision=summary.revision,decision='cancel_after_manual_reconciliation',confirmation='wrong'},nil,9),'CONFIRMATION_REQUIRED')
-- Simulate explicit operator restoration outside recovery before acknowledging.
assigned[41].MansaoFixture=nil;vouchers[41].valemansao1m=2
success(request('reconcileOperation',{operationId=pending.id,confirmed=true,expectedRevision=summary.revision,decision='cancel_after_manual_reconciliation',confirmation='RECONCILIADO '..pending.id},nil,9))
assert(#ICM.pending(row().id)==0)

-- A possibly committed slot cannot trigger a refund that would create a free house.
reset();quote=success(request('requestPurchase',{id='fixture-home'}));unavailableAfterSave=3
code(request('confirmPurchase',{id='fixture-home',quoteToken=quote.quoteToken,confirmed=true}),'STORAGE_UNCERTAIN')
assert(vouchers[41].valemansao1m==1 and assigned[41].MansaoFixture)
assert(ICM.Store.quarantined)
unavailableAfterSave=nil;ICM.Store.quarantined=false;ICM.Store.generation=nil;ICM.Store.state=nil;ICM.Store.load()
assert(#ICM.pending('fixture-home')==1 and not row().ownerId)
assert(registered.checkAccessByMansionId(7,'fixture-home')==false)

-- Resident controls are owner-only, support offline IDs and count the owner.
reset(41)
code(request('addResident',{mansionId='fixture-home',userId=43},nil,8),'FORBIDDEN')
success(request('addResident',{mansionId='fixture-home',userId=43}))
assert(row().members[1]==43 and assigned[43].MansaoFixture)
code(request('addResident',{mansionId='fixture-home',userId=43}),'DUPLICATE_RESIDENT')
success(request('addResident',{mansionId='fixture-home',userId=42}))
code(request('addResident',{mansionId='fixture-home',userId=99}),'RESIDENT_LIMIT')
success(request('removeResident',{mansionId='fixture-home',userId=43,confirmed=true}))
assert(not assigned[43].MansaoFixture and #row().members==1)

-- Any real resident can pay, and the cycle is renewed from now.
local state=copy(ICM.state());state.mansions[1].iptuPaidUntil=os.time()-1;ICM.Store.save(state)
assert(not registered.checkAccessByPermission(8,row().permission))
local paid=success(request('payIptu',{mansionId='fixture-home',confirmed=true},nil,8))
assert(bank[42]==900 and paid.paidUntil>os.time()+19*86400)
code(request('payIptu',{mansionId='fixture-home',confirmed=true},nil,9),'FORBIDDEN')

-- Placement cancellation is free; a changed quote cannot debit a new price.
reset(41)
local placement=success(request('beginFurniturePurchase',{mansionId='fixture-home',itemId='chair'}));assert(payments==0)
success(request('cancelFurniturePlacement',{placementToken=placement.placementToken}));assert(payments==0)
placement=success(request('beginFurniturePurchase',{mansionId='fixture-home',itemId='chair'}))
success(request('saveFurniturePrices',{prices={chair=800}},nil,9))
code(request('confirmFurniturePlacement',{mansionId='fixture-home',itemId='chair',placementToken=placement.placementToken,coords={x=0,y=0,z=0},heading=90}),'PRICE_CHANGED')
assert(payments==0)
placement=success(request('beginFurniturePurchase',{mansionId='fixture-home',itemId='chair'}))
local placed=success(request('confirmFurniturePlacement',{mansionId='fixture-home',itemId='chair',placementToken=placement.placementToken,coords={x=0,y=0,z=0},heading=90}))
assert(payments==1 and row().furniture[1].paidPrice==800 and bank[41]==9200)
success(request('saveFurniturePrices',{prices={chair=10000}},nil,9))
local sold=success(request('sellFurniture',{mansionId='fixture-home',furnitureId=placed.furnitureId,confirmed=true}))
assert(sold.refundAmount==120 and bank[41]==9320 and #row().furniture==0)
code(request('sellFurniture',{mansionId='fixture-home',furnitureId=placed.furnitureId,confirmed=true}),'FURNITURE_NOT_FOUND')

-- Persist-before-credit sale keeps an uncertain credit from being paid twice.
reset(41);state=copy(ICM.state());state.mansions[1].furniture={{id='credit-fixture',itemId='chair',model='prop_chair_01a',paidPrice=1000,x=0,y=0,z=0,heading=0}};ICM.Store.save(state)
creditThrowAfter=true
code(request('sellFurniture',{mansionId='fixture-home',furnitureId='credit-fixture',confirmed=true}),'RECONCILIATION_REQUIRED')
assert(#row().furniture==0 and bank[41]==10150 and credits==1)
code(request('sellFurniture',{mansionId='fixture-home',furnitureId='credit-fixture',confirmed=true}),'RECONCILIATION_REQUIRED')
ICM.Store.generation=nil;ICM.Store.state=nil;ICM.Store.load()
assert(#ICM.pending('fixture-home')==1 and credits==1)

-- Members cannot decorate; outside-property placement never charges.
reset(41);state=copy(ICM.state());state.mansions[1].members={42};ICM.Store.save(state)
code(request('beginFurniturePurchase',{mansionId='fixture-home',itemId='chair'},nil,8),'FORBIDDEN')
placement=success(request('beginFurniturePurchase',{mansionId='fixture-home',itemId='chair'}))
code(request('confirmFurniturePlacement',{mansionId='fixture-home',itemId='chair',placementToken=placement.placementToken,coords={x=500,y=0,z=0},heading=0}),'OUTSIDE_PROPERTY')
assert(payments==0)

-- Cleanup requires staff, proximity, exact quote and never refunds.
reset(41);state=copy(ICM.state());state.mansions[1].members={42};state.mansions[1].furniture={{id='f',itemId='chair',model='prop_chair_01a',paidPrice=500,x=0,y=0,z=0,heading=0}};ICM.Store.save(state)
code(request('quoteCleanup',{mansionId='fixture-home'}),'FORBIDDEN')
local cleanup=success(request('quoteCleanup',{mansionId='fixture-home'},nil,9))
success(request('cleanupMansion',{mansionId='fixture-home',quoteToken=cleanup.quoteToken,confirmed=true},nil,9))
assert(not row().ownerId and #row().members==0 and #row().furniture==0 and credits==0 and inventoryTakes==0)

-- Administrative edits preserve runtime fields and complete integration shapes.
reset(41)
local original=copy(row());local data=copy(original);data.name='Renamed';data.ownerId=99;data.members={99};data.iptuPaidUntil=1
data.chest={enabled=true,weight=100,coords={x=1,y=2,z=3}}
data.garage={enabled=true,type='public',blipDistance=5,coords={x=0,y=0,z=0},spawnCoords={{x=0,y=0,z=0,w=0}}}
local ok,msg=registered.saveMansion('fixture-home',data,{source=9,userId=99});assert(ok,msg)
assert(row().ownerId==41 and row().iptuPaidUntil==original.iptuPaidUntil and row().name=='Renamed')
assert(chests.Mansao_fixture_home==nil and chests['Mansao_fixture-home'].permission==row().permission)
assert(garages['Mansao_fixture-home'].permiss==row().permission)
ok,msg=registered.removeMansion(row().id,{source=9,userId=99});assert(not ok and msg:find('dono'))
invoke='untrusted';ok=registered.saveMansion(row().id,data,{source=9,userId=99});assert(not ok)
invoke='dm_spawn';local homes=registered.getUserMansions(41);assert(#homes==1 and homes[1].ownerId==41)

-- An upstream garage exporter reporting success without persistence cannot
-- commit the mansion or leave a falsely successful local configuration.
reset(41);data=copy(row());data.name='Unpersisted change'
data.garage={enabled=true,type='public',blipDistance=5,coords={x=0,y=0,z=0},spawnCoords={{x=0,y=0,z=0,w=0}}}
garageReadOnly=true
local saved,message,failure=registered.saveMansion('fixture-home',data,{source=9,userId=99})
assert(not saved and failure=='PERSISTENCE_UNVERIFIED')
assert(row().name=='Fixture home'and not row().garage.enabled and not garages['Mansao_fixture-home'])
assert(#ICM.pending('fixture-home')==0)

-- Journalled permission changes publish before effects and private contexts stay private.
reset(41);state=copy(ICM.state());state.mansions[1].members={43};state.mansions[1].furniture={{id='private-f',model='prop_chair_01a',paidPrice=50,x=0,y=0,z=0,heading=0}}
state.operations.private={id='private',kind='admin_save',mansionId='fixture-home',actorId=99,phase='applying',createdAt=1,detail={before=copy(state.mansions[1]),after={permission='perm.pendingnew'}}}
ICM.Store.save(state)
assert(GlobalState.ic_mansions_permissions['perm.pendingnew']==true)
assert(registered.checkAccessByPermission(7,'perm.pendingnew')==false)
local guest=success(request('getContext',{mansionId='fixture-home'},nil,8))
assert(guest.ownerId==nil and#guest.members==0 and#guest.furniture==0 and#guest.pendingOperations==0)
assert(not guest.canManage and not guest.canFurniture)
local ownerContext=success(request('getContext',{mansionId='fixture-home'}))
assert(ownerContext.ownerId==41 and#ownerContext.members==2 and#ownerContext.pendingOperations==1)
local count=#notices;source=7;events['ic_mansions:requestSync']();events['ic_mansions:requestFurnitureSync']()
assert(#notices==count+2,'full syncs must coalesce within the throttle window')

-- Price/recovery tools remain reachable before the first mansion is committed.
reset();state=copy(ICM.state());state.mansions={};state.operations.first={id='first',kind='admin_save',mansionId='uncommitted',phase='uncertain',detail={after={permission='perm.uncommitted'}}};ICM.Store.save(state)
code(request('getContext',{}),'NOT_FOUND')
local administration=success(request('getContext',{},nil,9))
assert(administration.canConfigure and not administration.canPurchase and not administration.mansionId)
assert(#success(request('getPendingOperations',{},nil,9)).operations==1)

-- Missing legacy tax dates receive the original grace period without a debit.
reset(41);state=copy(ICM.state());state.mansions[1].iptuPaidUntil=nil;ICM.Store.save(state)
local grace=success(request('payIptu',{mansionId='fixture-home',confirmed=true}))
assert(grace.chargedAmount==0 and payments==0 and row().iptuPaidUntil>os.time()+19*86400)

-- Readback corruption retains the prior valid slot, never resets stored state.
reset(41);state=copy(ICM.state());state.mansions[1].name='Durable';ICM.Store.save(state)
local currentSlot=ICM.Store.slot;local alternate=currentSlot==1 and 2 or 1
files[ICMConfig.StateFiles[alternate]]='truncated'
ICM.Store.state=nil;ICM.Store.generation=nil;ICM.Store.load();assert(row().name=='Durable')
files[ICMConfig.StateFiles[alternate]]=json.encode({generation=99,state=fixture(41),payload='tampered',checksum='00000000'})
ICM.Store.state=nil;ICM.Store.generation=nil;ICM.Store.load();assert(row().name=='Durable')
files[ICMConfig.StateFiles[alternate]]='truncated'
files[ICMConfig.StateFiles[currentSlot]]='truncated';ICM.Store.state=nil;ICM.Store.generation=nil
local valid=pcall(ICM.Store.load);assert(not valid,'both bad slots must fail closed')

-- Provider conflicts and user identities are checked server-side.
reset();legacy='started';code(request('getContext',{}),'PROVIDER_CONFLICT')
legacy='stopped';convars.ic_mansions_enabled='false';code(request('getContext',{}),'DISABLED')
print('IC Mansions: lifecycle, economy, roles, tax, integrations, recovery and durable slots passed')
