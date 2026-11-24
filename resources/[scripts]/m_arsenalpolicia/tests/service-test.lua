-- O runner injeta config.lua e server/service.lua antes deste arquivo.
local function clone(v)
    if type(v)~='table' then return v end
    local o={};for k,x in pairs(v) do o[k]=clone(x) end;return o
end
local tick=10000
local wallet,inventory,audits={}, {}, {}
local pos={[10]=clone(Config.DefaultLocation),[20]={x=1,y=2,z=3},[30]=clone(Config.DefaultLocation)}
local mode='normal'
local saved=nil
local persisted={version=1,prices={},location=clone(Config.DefaultLocation)}
local service
local deps={
    user=function(player) return ({[10]=1,[20]=2,[30]=3,[40]=4})[player] end,
    owner=function(user) return user==2 or user==3 end,
    police=function(user) return user==1 or user==3 end,
    position=function(player) return pos[player] end,
    clock=function() return tick end,
    exists=function(id) return mode~='unknown-item' end,
    availableItems=function() return {{id='weapon_assaultrifle',name='AK 47',category='armas',maxQuantity=1,unit='unidade'}} end,
    money=function(user) return wallet[user] or 0 end,
    count=function(user,id) return inventory[id] or 0 end,
    weight=function() return mode=='full' and 1000 or 0 end,
    maxWeight=function() return 100 end,
    itemWeight=function() return 1 end,
    pay=function(user,amount)
        if (wallet[user] or 0)<amount then return false end
        wallet[user]=wallet[user]-amount;return true
    end,
    give=function(user,id,quantity)
        if mode=='no-delivery' then return false end
        if mode=='give-error' then error('inventory offline') end
        if mode=='reentry' then
            assert(not service.purchase(10,{id=id,quantity=1,expectedPrice=1000}).ok,'concurrent purchase accepted')
        end
        inventory[id]=(inventory[id] or 0)+quantity
        if mode=='error-after-delivery' then error('notification failed after delivery') end
        return true
    end,
    refund=function(user,amount) wallet[user]=wallet[user]+amount;return true end,
    persist=function(state) if mode=='disk-failure' then return false end;saved=clone(state);return true end,
    audit=function(kind,data) audits[#audits+1]={kind=kind,data=data} end
}
service=CreatePoliceArsenal(Config,deps,persisted)
local weapon='weapon_parafal'
local function reset(nextMode)
    mode=nextMode or 'normal';tick=tick+1100;wallet[1]=100000;wallet[3]=100000;inventory={};audits={}
end
local function buy(player,overrides)
    local p={id=weapon,quantity=1,expectedPrice=1000}
    for k,v in pairs(overrides or {}) do p[k]=v end
    return service.purchase(player or 10,p)
end
assert(#service.open(10).items==64,'catalog count')
assert(not service.open(40).ok and not buy(40).ok,'civilian access')
assert(service.open(20).canManage and not service.open(20).canPurchase,'owner management away from point')
assert(not buy(20).ok,'owner without police must not buy')
assert(not service.setPrice(10,{id=weapon,price=1,expectedPrice=1000}).ok,'police price editor')
assert(not service.relocate(10).ok,'police relocation')
pos[10]={x=0,y=0,z=0};assert(not service.open(10).ok and not buy().ok,'remote purchase')
pos[10]=clone(Config.DefaultLocation)
for _,q in ipairs({0,-1,1.5,2,1000000,'1'}) do reset();assert(not buy(10,{quantity=q}).ok and wallet[1]==100000,'invalid weapon quantity') end
reset();assert(not buy(10,{id='money'}).ok and wallet[1]==100000,'item injection')
reset();assert(not buy(10,{expectedPrice=1}).ok,'client-controlled price')
reset('full');assert(not buy().ok and wallet[1]==100000,'weight check before payment')
reset();wallet[1]=999;assert(not buy().ok and not inventory[weapon],'insufficient money')
reset();assert(buy().ok and wallet[1]==99000 and inventory[weapon]==1,'paid delivery')
assert(not buy().ok,'purchase cooldown')
for _,scenario in ipairs({'no-delivery','give-error'}) do
    reset(scenario);assert(not buy().ok and wallet[1]==100000 and not inventory[weapon],'refund on delivery failure')
end
reset('error-after-delivery');assert(buy().ok and wallet[1]==99000 and inventory[weapon]==1,'no free item after notification error')
reset('reentry');assert(buy().ok and wallet[1]==99000 and inventory[weapon]==1,'concurrency lock')
reset();assert(buy(10,{id='ammo_parafal',quantity=10}).ok and wallet[1]==90000 and inventory.ammo_parafal==10,'ammo price per unit')
for _,value in ipairs({0,-1,1.5,10000001,'1000'}) do
    assert(not service.setPrice(20,{id=weapon,price=value,expectedPrice=1000}).ok,'invalid/free price accepted')
end
mode='disk-failure';assert(not service.setPrice(20,{id=weapon,price=2500,expectedPrice=1000}).ok,'save failure')
mode='normal';local function currentPrice()
    for _,item in ipairs(service.open(20).items) do if item.id==weapon then return item.price end end
end
assert(currentPrice()==1000,'failed save mutated price')
assert(service.setPrice(20,{id=weapon,price=2500,expectedPrice=1000}).ok and currentPrice()==2500,'owner price save')
assert(not service.setPrice(20,{id=weapon,price=3000,expectedPrice=1000}).ok,'stale editor overwrote price')
reset();assert(not buy().ok,'stale purchase quote')
assert(buy(10,{expectedPrice=2500}).ok and wallet[1]==97500,'updated price not charged')
mode='disk-failure';assert(not service.relocate(20).ok and service.location().x==447.3,'failed move changed point')
mode='normal';assert(service.relocate(20).ok and service.location().x==1,'owner position not saved')
assert(not service.open(10).ok,'old point still active')
pos[10]={x=1,y=2,z=3};assert(service.open(10).ok,'new point inactive')
local restarted=CreatePoliceArsenal(Config,deps,saved)
assert(restarted.location().x==1,'location not retained on restart')
local found=false;for _,item in ipairs(restarted.open(20).items) do if item.id==weapon then found=item.price==2500 end end
assert(found,'price not retained on restart')
mode='unknown-item';assert(#service.open(20).items==0,'unknown inventory items must be hidden')
mode='normal'
assert(not service.management(10).ok,'police must not access catalog editor')
assert(not service.setItemEnabled(10,{id=weapon,enabled=false}).ok,'police must not remove an item')
assert(not service.clearLocation(10).ok,'police must not clear the point')
mode='disk-failure';assert(not service.setItemEnabled(20,{id=weapon,enabled=false}).ok,'failed removal save')
mode='normal';assert(service.setItemEnabled(20,{id=weapon,enabled=false}).ok,'owner removal')
reset();assert(not buy(10,{expectedPrice=2500}).ok and wallet[1]==100000,'removed item still purchasable')
local management=service.management(20);assert(#management.active==63,'removed item still public')
local removedRestart=CreatePoliceArsenal(Config,deps,saved)
assert(#removedRestart.management(20).active==63,'removal must survive restart')
assert(service.setItemEnabled(20,{id=weapon,enabled=true}).ok,'restore item')
assert(currentPrice()==2500,'restoring an item must preserve its price')
assert(not service.setItemEnabled(20,{id='invented',enabled=true}).ok,'unknown custom item accepted')
assert(not service.setItemEnabled(20,{id='money',enabled=true}).ok,'arbitrary id injection accepted')
assert(service.setItemEnabled(20,{id='weapon_assaultrifle',enabled=true}).ok,'adding inventory item')
assert(#service.management(20).active==65,'custom item absent')
local customRestart=CreatePoliceArsenal(Config,deps,saved)
assert(#customRestart.management(20).active==65,'custom item must survive restart')
assert(service.clearLocation(20).ok and service.location()==false,'clear location')
assert(not service.open(10).ok and service.open(20).ok,'cleared point must deny police and allow owner management')
local noPointRestart=CreatePoliceArsenal(Config,deps,saved)
assert(noPointRestart.location()==false,'point removal must survive restart')
assert(service.relocate(20).ok and service.open(10).ok,'new point after clearing')
return 'PASS: paid purchases, permissions, inventory/price validation, refunds, concurrency, owner-only catalog additions/removals, persistence, cleared/replaced locations, stale quotes and saved prices.'
