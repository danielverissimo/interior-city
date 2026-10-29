local root=arg[1] or '.'
local methods,items,effects,free={},{},0,30
local catalog={weapon_pistol={type='equip',name='Pistola',weight=3},ammo_pistol={type='recharge',name='Munição',weight=.05},weapon_knife={type='equip',name='Faca',weight=1},water={type='use',weight=.2}}
ICAdmin={Config={},Adapter={},Store={},vRP={},definitions={}}
local I=ICAdmin
I.fail=function(code,message)error({code=code,message=message},0)end
I.text=function(v,max,required)if type(v)~='string'or #v>max or required and v==''then I.fail('INVALID','text')end;return v end
I.int=function(v,min,max)v=tonumber(v);if not v or v%1~=0 or v<min or v>max then I.fail('INVALID','number')end;return v end
I.register=function(name,d)methods[name]=d.handler end
I.allowed=function()return true end
I.target=function(id)return id,2 end
I.withLock=function(_,fn)return fn()end
I.effect=function()effects=effects+1 end
I.audit=function()end
I.vRP.getAllItens=function()return catalog end
I.vRP.getItemWeight=function(id)return catalog[id].weight end
I.vRP.computeInvWeight=function()local weight=0;for id,amount in pairs(items)do weight=weight+catalog[id].weight*amount end;return weight end
I.vRP.getInventoryMaxWeight=function()return free end
I.vRP.giveInventoryItem=function(_,id,amount)items[id]=(items[id]or 0)+amount;return true end
dofile(root..'/resources/[scriptcore]/ic_admin/server/adapters.lua')
dofile(root..'/resources/[scriptcore]/ic_admin/server/actions.lua')
assert(I.Adapter.ammoForWeapon('weapon_pistol')=='ammo_pistol')
assert(I.Adapter.ammoForWeapon('weapon_knife')==nil)
local ctx={source=2,userId=42}
assert(not pcall(methods['weapons.give'],ctx,{weapon='water',ammoAmount=2,reason='Test'}),'nonweapon accepted')
assert(not pcall(methods['weapons.give'],ctx,{weapon='weapon_knife',ammoAmount=2,reason='Test'}),'invented ammo accepted')
free=1;assert(not pcall(methods['weapons.give'],ctx,{weapon='weapon_pistol',ammoAmount=100,reason='Test'}),'overweight delivery accepted')
assert(effects==0 and next(items)==nil,'validation had side effects')
free=30
local result=methods['weapons.give'](ctx,{weapon='weapon_pistol',ammoAmount=100,reason='Authorized test'})
assert(result.id==42 and items.weapon_pistol==1 and items.ammo_pistol==100,'weapon/ammo delivery mismatch')
print('IC Admin inventory: weapon catalog, correct ammo, capacity and self delivery passed')
