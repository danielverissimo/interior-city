local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

Config = Config or {}

local robberyActive = false
local dispatchSent = false
local policeApproved = {}
local doorAuthorizations = {}
local safeWorking = {}
local moneyCooldown = {}
local resetAt = {}

local function int(value, fallback)
    local n = tonumber(value)
    if not n then return fallback or 0 end
    return math.floor(n)
end

local function policePermission()
    local perm = tostring(Config.PermCops or "perm.policia")
    if perm == "policia.permissao" then perm = "perm.policia" end
    return perm
end

local function policeUsers()
    return vRP.getUsersByPermission(policePermission()) or {}
end

local function countUsers(list)
    local amount = 0
    for _ in pairs(list or {}) do amount = amount + 1 end
    return amount
end

local function validBank(index)
    index = tonumber(index)
    if not index then return nil,nil end
    index = math.floor(index)
    return Config.BankRobbery and Config.BankRobbery[index],index
end

local function isNearVector(source,vec,maxDistance)
    if not vec then return false end
    local ped = GetPlayerPed(source)
    if not ped or ped <= 0 then return false end
    local coords = GetEntityCoords(ped)
    if not coords then return false end
    local dx,dy,dz = coords.x-vec.x,coords.y-vec.y,coords.z-vec.z
    return (dx*dx + dy*dy + dz*dz) <= ((maxDistance or 3.0)^2)
end

local function nearestDoor(source,maxDistance,onlyWeld)
    for bankIndex,bank in ipairs(Config.BankRobbery or {}) do
        for doorIndex,door in ipairs(bank.Doors or {}) do
            local target = onlyWeld and door.WeldPosition and door.WeldPosition.C or door.Coords
            if target and isNearVector(source,target,maxDistance or 3.0) then
                return bankIndex,doorIndex,door
            end
        end
    end
end

local function nearestSafe(source,maxDistance)
    for bankIndex,bank in ipairs(Config.BankRobbery or {}) do
        for safeIndex,safe in ipairs(bank.Safes or {}) do
            if safe.Coords and isNearVector(source,safe.Coords,maxDistance or 3.0) then
                return bankIndex,safeIndex,safe
            end
        end
    end
end

local function safeKey(bank,safe)
    return tostring(bank)..":"..tostring(safe)
end

local function dispatchPolice(source)
    if dispatchSent then return end
    dispatchSent = true

    local ped = GetPlayerPed(source)
    local coords = ped and ped > 0 and GetEntityCoords(ped) or vector3(257.22,220.72,106.28)
    local notifyAvailable = GetResourceState("vrp_notifycall") == "started"

    for _,uid in pairs(policeUsers()) do
        local player = vRP.getUserSource(int(uid))
        if player then
            if notifyAvailable then
                TriggerClientEvent("NotifyPush",player,{
                    code = "911",
                    title = "Roubo ao Banco Central",
                    text = "O sistema de segurança do Banco Central detectou uma tentativa de invasão. Suspeitos no interior da agência.",
                    x = coords.x, y = coords.y, z = coords.z,
                    time = os.date("%H:%M"),
                    rgba = {255,48,66,255},
                    blipSprite = 161,
                    blipColor = 1,
                    blipScale = 0.9,
                    blipDuration = 120000
                })
            else
                vRPclient.playSound(player,"Oneshot_Final","MP_MISSION_COUNTDOWN_SOUNDSET")
                TriggerClientEvent("chatMessage",player,"911",{255,64,64},"Roubo em andamento no Banco Central. Dirija-se até o local.")
            end
        end
    end
end

RegisterNetEvent("loffe_heist:deleteDrill")
AddEventHandler("loffe_heist:deleteDrill",function(coords)
    local source = source
    if type(coords) ~= "vector3" and type(coords) ~= "table" then return end
    -- Evento apenas visual; mantém sincronização somente quando o jogador está dentro da área do banco.
    local bank = nearestSafe(source,8.0)
    if not bank then return end
    TriggerClientEvent("loffe_heist:deleteDrillCl",-1,coords)
end)

RegisterNetEvent("loffe_heist:getBox")
AddEventHandler("loffe_heist:getBox",function(bankIndex)
    local source = source
    local bank = validBank(bankIndex or 1)
    if not bank then return end

    local money = math.max(0,int(bank.Money and bank.Money.Amount,0))
    local startMoney = math.max(1,int(bank.Money and bank.Money.StartMoney,1))
    local box
    if money <= 0 then
        box = Config.Boxes.Empty
    elseif money >= startMoney/2 then
        box = Config.Boxes.Full
    else
        box = Config.Boxes.Half
    end
    TriggerClientEvent("loffe_heist:getBox",source,box)
end)

RegisterNetEvent("loffe_heist:takeMoney")
AddEventHandler("loffe_heist:takeMoney",function(bankIndex)
    local source = source
    local user_id = vRP.getUserId(source)
    local bank,index = validBank(bankIndex)
    if not user_id or not bank or not robberyActive or not bank.Money or not isNearVector(source,bank.Money.BoxPosition,5.0) then return end

    local now = GetGameTimer()
    if moneyCooldown[source] and now-moneyCooldown[source] < 700 then return end
    moneyCooldown[source] = now

    local available = math.max(0,int(bank.Money.Amount,0))
    if available <= 0 then return end

    local minimum = math.max(1,int(Config.MinPegar,2500))
    local maximum = math.max(minimum,int(Config.MaxPegar,5000))
    local amount = math.min(available,math.random(minimum,maximum))

    bank.Money.Amount = available-amount
    vRP.giveInventoryItem(user_id,Config.DinheiroSujo,amount,false)
    TriggerClientEvent("loffe_heist:updateMoney",-1,index,bank.Money.Amount)

    if bank.Money.Amount <= 0 and not resetAt[index] then
        resetAt[index] = os.time()+math.max(1,int(Config.Tempo,1600))
    end
end)

RegisterNetEvent("loffe_heist:getCops")
AddEventHandler("loffe_heist:getCops",function()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return end

    local bankIndex,doorIndex = nearestDoor(source,4.0,true)
    if not bankIndex then
        TriggerClientEvent("loffe_heist:getCops",source,false)
        return
    end

    local minimum = math.max(0,int(Config.Cops,0))
    if countUsers(policeUsers()) < minimum then
        TriggerClientEvent("loffe_heist:getCops",source,false)
        return
    end

    policeApproved[source] = {bank=bankIndex,door=doorIndex,expires=os.time()+10}
    robberyActive = true
    dispatchPolice(source)
    TriggerClientEvent("loffe_heist:getCops",source,true)
end)

RegisterNetEvent("loffe_heist:getSolda")
AddEventHandler("loffe_heist:getSolda",function()
    local source = source
    local user_id = vRP.getUserId(source)
    local approval = policeApproved[source]
    local bankIndex,doorIndex,door = nearestDoor(source,4.0,true)

    if not user_id or not approval or approval.expires < os.time() or approval.bank ~= bankIndex or approval.door ~= doorIndex or not door or door.Hacking then
        TriggerClientEvent("loffe_heist:getSolda",source,false)
        return
    end

    policeApproved[source] = nil
    local amount = math.max(1,int(Config.itemqtd,1))
    local item = tostring(Config.Solda or "c4")
    if int(vRP.getInventoryItemAmount(user_id,item)) < amount or not vRP.tryGetInventoryItem(user_id,item,amount,true) then
        TriggerClientEvent("loffe_heist:getSolda",source,false)
        return
    end

    doorAuthorizations[source] = {bank=bankIndex,door=doorIndex,expires=os.time()+600}
    TriggerClientEvent("loffe_heist:getSolda",source,true)
end)

RegisterNetEvent("loffe_heist:getFuradeira")
AddEventHandler("loffe_heist:getFuradeira",function()
    local source = source
    local user_id = vRP.getUserId(source)
    local bankIndex,safeIndex = nearestSafe(source,3.0)
    if not user_id or not bankIndex then
        TriggerClientEvent("loffe_heist:getFuradeira",source,false)
        return
    end

    local item = tostring(Config.Furadeira or "furadeira")
    local hasItem = int(vRP.getInventoryItemAmount(user_id,item)) >= 1
    TriggerClientEvent("loffe_heist:getFuradeira",source,hasItem)
end)

RegisterNetEvent("loffe_heist:setDoorFreezeStatus")
AddEventHandler("loffe_heist:setDoorFreezeStatus",function(bankIndex,doorIndex,status)
    local source = source
    local bank,b = validBank(bankIndex)
    doorIndex = int(doorIndex,0)
    local door = bank and bank.Doors and bank.Doors[doorIndex]
    if not door or not isNearVector(source,door.Coords,6.0) then return end

    status = status == true
    if not status then
        if door.Hacking then
            -- Porta final: só pode ser aberta estando no terminal/porta correspondente.
            local allowed = isNearVector(source,door.Coords,6.0) or (bank.Hacking and isNearVector(source,bank.Hacking.Coords,5.0))
            if not allowed then return end
        else
            local auth = doorAuthorizations[source]
            if not auth or auth.expires < os.time() or auth.bank ~= b or auth.door ~= doorIndex then return end
            doorAuthorizations[source] = nil
        end
    end

    door.Frozen = status
    TriggerClientEvent("loffe_heist:setDoorFreezeStatusCl",-1,b,doorIndex,status)
end)

RegisterNetEvent("loffe_heist:getDoorFreezeStatus")
AddEventHandler("loffe_heist:getDoorFreezeStatus",function(bankIndex,doorIndex)
    local source = source
    local bank,b = validBank(bankIndex)
    doorIndex = int(doorIndex,0)
    local door = bank and bank.Doors and bank.Doors[doorIndex]
    if door then
        TriggerClientEvent("loffe_heist:setDoorFreezeStatusCl",source,b,doorIndex,door.Frozen)
    end
end)

RegisterNetEvent("loffe_heist:toggleSafe")
AddEventHandler("loffe_heist:toggleSafe",function(bankIndex,safeIndex,toggle)
    local source = source
    local user_id = vRP.getUserId(source)
    local bank,b = validBank(bankIndex)
    safeIndex = int(safeIndex,0)
    local safe = bank and bank.Safes and bank.Safes[safeIndex]
    if not user_id or not safe or not isNearVector(source,safe.Coords,3.0) then return end

    local key = safeKey(b,safeIndex)
    if toggle == true then
        if safe.Looted or safeWorking[key] then return end
        if int(vRP.getInventoryItemAmount(user_id,tostring(Config.Furadeira or "furadeira"))) < 1 then return end
        safeWorking[key] = source
        safe.Looted = true
        TriggerClientEvent("loffe_heist:safeLooted",-1,b,safeIndex,true)
    else
        if safeWorking[key] ~= source then return end
        safeWorking[key] = nil
        safe.Looted = false
        TriggerClientEvent("loffe_heist:safeLooted",-1,b,safeIndex,false)
    end
end)

RegisterNetEvent("loffe_heist:lootSafe")
AddEventHandler("loffe_heist:lootSafe",function(bankIndex,safeIndex)
    local source = source
    local user_id = vRP.getUserId(source)
    local bank,b = validBank(bankIndex)
    safeIndex = int(safeIndex,0)
    local safe = bank and bank.Safes and bank.Safes[safeIndex]
    local key = safeKey(b,safeIndex)
    if not user_id or not safe or safeWorking[key] ~= source or not isNearVector(source,safe.Coords,3.5) then return end

    safeWorking[key] = nil
    safe.Looted = true

    local minimum = math.max(0,int(Config.SafeMinimum,0))
    local maximum = math.max(minimum,int(Config.SafeMax,minimum))
    local amount = maximum > 0 and math.random(minimum,maximum) or 0
    if amount > 0 then
        vRP.giveInventoryItem(user_id,Config.DinheiroSujo,amount,false)
        TriggerClientEvent("Notify",source,"sucesso","Recebido <b>R$"..vRP.format(amount).."</b>.")
    end
    TriggerClientEvent("loffe_heist:safeLooted",-1,b,safeIndex,true)
end)

local function syncState(player)
    if not player or player <= 0 then return end
    for bankIndex,bank in ipairs(Config.BankRobbery or {}) do
        for doorIndex,door in ipairs(bank.Doors or {}) do
            TriggerClientEvent("loffe_heist:setDoorFreezeStatusCl",player,bankIndex,doorIndex,door.Frozen)
        end
        for safeIndex,safe in ipairs(bank.Safes or {}) do
            TriggerClientEvent("loffe_heist:safeLooted",player,bankIndex,safeIndex,safe.Looted)
        end
        TriggerClientEvent("loffe_heist:updateMoney",player,bankIndex,bank.Money.Amount)
    end
end

AddEventHandler("vRP:playerSpawn",function(user_id,source,first_spawn)
    SetTimeout(2500,function()
        if GetPlayerName(source) then syncState(source) end
    end)
end)

CreateThread(function()
    while true do
        Wait(1000)
        local now = os.time()
        for bankIndex,due in pairs(resetAt) do
            if now >= due then
                local bank = Config.BankRobbery and Config.BankRobbery[bankIndex]
                if bank then
                    bank.Money.Amount = bank.Money.StartMoney
                    TriggerClientEvent("loffe_heist:updateMoney",-1,bankIndex,bank.Money.Amount)

                    for doorIndex,door in ipairs(bank.Doors or {}) do
                        door.Frozen = true
                        TriggerClientEvent("loffe_heist:setDoorFreezeStatusCl",-1,bankIndex,doorIndex,true)
                    end

                    for safeIndex,safe in ipairs(bank.Safes or {}) do
                        safe.Looted = false
                        safeWorking[safeKey(bankIndex,safeIndex)] = nil
                        TriggerClientEvent("loffe_heist:safeLooted",-1,bankIndex,safeIndex,false)
                    end
                end
                resetAt[bankIndex] = nil
                robberyActive = false
                dispatchSent = false
            end
        end
    end
end)

-- Sincronização leve das portas para evitar divergência de estado entre clientes.
CreateThread(function()
    while true do
        Wait(30000)
        for bankIndex,bank in ipairs(Config.BankRobbery or {}) do
            for doorIndex,door in ipairs(bank.Doors or {}) do
                TriggerClientEvent("loffe_heist:setDoorFreezeStatusCl",-1,bankIndex,doorIndex,door.Frozen)
            end
        end
    end
end)

AddEventHandler("playerDropped",function()
    local source = source
    policeApproved[source] = nil
    doorAuthorizations[source] = nil
    moneyCooldown[source] = nil
    for key,owner in pairs(safeWorking) do
        if owner == source then
            safeWorking[key] = nil
            local bankIndex,safeIndex = key:match("^(%d+):(%d+)$")
            bankIndex,safeIndex = tonumber(bankIndex),tonumber(safeIndex)
            local bank = bankIndex and Config.BankRobbery and Config.BankRobbery[bankIndex]
            local safe = bank and bank.Safes and bank.Safes[safeIndex]
            if safe then
                safe.Looted = false
                TriggerClientEvent("loffe_heist:safeLooted",-1,bankIndex,safeIndex,false)
            end
        end
    end
end)
