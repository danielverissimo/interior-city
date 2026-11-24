local Proxy=module('vrp','lib/Proxy')
local Tunnel=module('vrp','lib/Tunnel')
local vRP=Proxy.getInterface('vRP')
local RESOURCE=GetCurrentResourceName()
local API={}
Tunnel.bindInterface(RESOURCE,API)

local ready=false
local function owner(user) return vRP.hasGroup(user,Config.OwnerGroup)==true end
local function police(user)
    for _,permission in ipairs(Config.PolicePermissions) do
        if vRP.hasPermission(user,permission) then return true end
    end
    return false
end
local function position(player)
    local ped=GetPlayerPed(player)
    if not ped or ped==0 then return nil end
    local p=GetEntityCoords(ped)
    return {x=p.x,y=p.y,z=p.z}
end
local function audit(kind,data)
    data.kind=kind;data.at=os.date('!%Y-%m-%dT%H:%M:%SZ')
    print(('[%s] %s'):format(RESOURCE,json.encode(data)))
    local raw=LoadResourceFile(RESOURCE,'audit.json')
    local ok,rows=pcall(json.decode,raw or '[]')
    rows=ok and type(rows)=='table' and rows or {}
    rows[#rows+1]=data
    while #rows>500 do table.remove(rows,1) end
    if not SaveResourceFile(RESOURCE,'audit.json',json.encode(rows),-1) then
        print('['..RESOURCE..'] Nao foi possivel salvar audit.json; o registro permanece no console.')
    end
end
local function persist(state)
    local encoded=json.encode(state)
    local result=SaveResourceFile(RESOURCE,'settings.json',encoded,#encoded)
    if LoadResourceFile(RESOURCE,'settings.json')==encoded then return true end
    print(('[%s] Não foi possível confirmar a gravação de settings.json (retorno do FiveM: %s).'):format(
        RESOURCE,tostring(result)))
    return false
end
local function knownItem(id)
    local items=vRP.getAllItens()
    return type(items)=='table' and type(items[id])=='table'
end
local function availableItems()
    local all=vRP.getAllItens() or {}
    local rows={}
    local excluded={money=true,dirty_money=true,diamantes=true,makapoints=true}
    for id,item in pairs(all) do
        if type(id)=='string' and type(item)=='table' and not excluded[id]
            and id:match('^[a-z0-9_%-]+$') and (item.type=='equip' or item.type=='recharge' or item.type=='use') then
            local category=id:match('^ammo_') and 'municoes' or id:match('^weapon_') and 'armas' or 'equipamentos'
            rows[#rows+1]={id=id,name=tostring(item.name or id),category=category,
                maxQuantity=category=='armas' and 1 or category=='municoes' and 250 or 10,
                unit=category=='municoes' and 'municao' or 'unidade'}
        end
    end
    return rows
end
local function pay(user,total)
    local before=tonumber(vRP.getMoney(user)) or 0
    if before<total then return false end
    pcall(vRP.tryGetInventoryItem,user,'money',total,false)
    return before-(tonumber(vRP.getMoney(user)) or 0)==total
end
local function refund(user,total)
    local before=tonumber(vRP.getMoney(user)) or 0
    pcall(vRP.giveMoney,user,total)
    return (tonumber(vRP.getMoney(user)) or 0)-before==total
end
local service
local function unavailable() return {ok=false,message='Arsenal indisponivel. Avise a administracao.'} end
CreateThread(function()
    local raw=LoadResourceFile(RESOURCE,'settings.json')
    local ok,state=pcall(json.decode,raw or '')
    if not ok or type(state)~='table' or type(state.prices)~='table' or (state.location~=false and type(state.location)~='table') then
        print('^1['..RESOURCE..'] settings.json invalido. Corrija o arquivo para iniciar o arsenal.^7')
        return
    end
    for _,key in ipairs(state.location and {'x','y','z'} or {}) do
        local value=state.location[key]
        if type(value)~='number' or value~=value or math.abs(value)>20000 then
            print('^1['..RESOURCE..'] Localizacao invalida em settings.json.^7');return
        end
    end
    for _,value in pairs(state.prices) do
        if type(value)~='number' or value~=value or value%1~=0 or value<1 or value>Config.MaxPrice then
            print('^1['..RESOURCE..'] Preco invalido em settings.json. Nenhum item sera entregue.^7');return
        end
    end
    if (state.disabled~=nil and type(state.disabled)~='table') or (state.customItems~=nil and type(state.customItems)~='table') then
        print('^1['..RESOURCE..'] Catalogo personalizado invalido em settings.json.^7');return
    end
    for id,value in pairs(state.disabled or {}) do
        if type(id)~='string' or type(value)~='boolean' then
            print('^1['..RESOURCE..'] Lista de itens retirados invalida.^7');return
        end
    end
    for id,entry in pairs(state.customItems or {}) do
        if type(id)~='string' or type(entry)~='table' or entry.id~=id or type(entry.name)~='string'
            or (entry.category~='armas' and entry.category~='municoes' and entry.category~='equipamentos')
            or type(entry.maxQuantity)~='number' or entry.maxQuantity%1~=0 or entry.maxQuantity<1 or entry.maxQuantity>250 then
            print('^1['..RESOURCE..'] Equipamento personalizado invalido.^7');return
        end
    end
    service=CreatePoliceArsenal(Config,{
        user=vRP.getUserId,owner=owner,police=police,position=position,clock=GetGameTimer,
        exists=knownItem,availableItems=availableItems,money=function(user) return tonumber(vRP.getMoney(user)) or 0 end,
        count=function(user,id) return tonumber(vRP.getInventoryItemAmount(user,id)) or 0 end,
        weight=vRP.computeInvWeight,maxWeight=vRP.getInventoryMaxWeight,itemWeight=vRP.getItemWeight,
        pay=pay,refund=refund,give=function(user,id,quantity) return vRP.giveInventoryItem(user,id,quantity,false) end,
        persist=persist,audit=audit
    },state)
    ready=true
    for _,item in ipairs(Config.Items) do
        if not knownItem(item.id) then print('['..RESOURCE..'] Item ausente no inventario, ocultado: '..item.id) end
    end
    TriggerClientEvent(RESOURCE..':location',-1,service.location())
    print(('[%s] Arsenal carregado com %d itens. Comando /%s.'):format(RESOURCE,#Config.Items,Config.Command))
end)

function API.bootstrap()
    if not ready then return {ok=false} end
    local user=vRP.getUserId(source)
    return {ok=true,allowed=user and (owner(user) or police(user)) or false,location=service.location()}
end
function API.open() if not ready then return unavailable() end;return service.open(source) end
function API.purchase(data) if not ready then return unavailable() end;return service.purchase(source,data) end
function API.setPrice(data)
    if not ready then return unavailable() end
    local result=service.setPrice(source,data)
    if result.ok then TriggerClientEvent(RESOURCE..':catalogChanged',-1) end
    return result
end
function API.relocate()
    if not ready then return unavailable() end
    local result=service.relocate(source)
    if result.ok then TriggerClientEvent(RESOURCE..':location',-1,result.location) end
    return result
end
function API.clearLocation()
    if not ready then return unavailable() end
    local result=service.clearLocation(source)
    if result.ok then TriggerClientEvent(RESOURCE..':location',-1,false) end
    return result
end
function API.management() if not ready then return unavailable() end;return service.management(source) end
function API.setItemEnabled(data)
    if not ready then return unavailable() end
    local result=service.setItemEnabled(source,data)
    if result.ok then TriggerClientEvent(RESOURCE..':catalogChanged',-1) end
    return result
end
AddEventHandler('playerDropped',function()
    local user=vRP.getUserId(source)
    if service and user then service.clear(user) end
end)
