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

-- Estado autoritativo das duas portas internas do cofre.
local innerVaultDoors = { [1] = { false, false } }
local innerWeldWorking = {}
local INNER_WELD_SECONDS = 10
local INNER_DOOR_COORDS = {
    [1] = {
        vector3(252.52,221.23,101.67),
        vector3(261.68,215.11,101.67)
    }
}

local function innerDoorKey(bankIndex,doorIndex)
    return tostring(bankIndex)..':'..tostring(doorIndex)
end
local function innerDoorsOpen(bankIndex)
    local states = innerVaultDoors[tonumber(bankIndex)]
    if not states then return true end
    for i=1,#states do if states[i] ~= true then return false end end
    return true
end

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

    local bank = Config.BankRobbery and Config.BankRobbery[1]
    local coords = bank and bank.Doors and bank.Doors[1] and bank.Doors[1].Coords or vector3(257.22,220.72,106.28)
    local notifyAvailable = GetResourceState("vrp_notifycall") == "started"

    for _,uid in pairs(policeUsers()) do
        local player = vRP.getUserSource(int(uid))
        if player then
            if notifyAvailable then
                TriggerClientEvent("NotifyPush",player,{
                    code = "911",
                    title = "BANCO CENTRAL",
                    text = "Roubo em andamento no Banco Central. A primeira porta foi violada com explosivos.",
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
    if not user_id or not bank or not robberyActive or not bank.Money or not innerDoorsOpen(index) or not isNearVector(source,bank.Money.BoxPosition,5.0) then return end

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
    local pending = doorAuthorizations[source]
    if pending and pending.expires >= os.time() then
        TriggerClientEvent("loffe_heist:getSolda",source,false)
        TriggerClientEvent("Notify",source,"aviso","Uma C4 já foi posicionada por você.",4000)
        return
    end
    if door.Frozen == false or (doorIndex > 1 and bankIndex and Config.BankRobbery[bankIndex].Doors[doorIndex - 1].Frozen) then
        TriggerClientEvent("loffe_heist:getSolda",source,false)
        return
    end
    if countUsers(policeUsers()) < math.max(0,int(Config.Cops,0)) then
        TriggerClientEvent("loffe_heist:getSolda",source,false)
        return
    end
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
    if not user_id or not bankIndex or not innerDoorsOpen(bankIndex) then
        TriggerClientEvent("loffe_heist:getFuradeira",source,false)
        return
    end

    local item = tostring(Config.Furadeira or "furadeira")
    local hasItem = int(vRP.getInventoryItemAmount(user_id,item)) >= 1
    TriggerClientEvent("loffe_heist:getFuradeira",source,hasItem)
end)

-- Retorna a C4 consumida se o jogador cancelar ANTES da explosão.
RegisterNetEvent("loffe_heist:cancelC4")
AddEventHandler("loffe_heist:cancelC4",function()
    local src=source
    local auth=doorAuthorizations[src]
    local uid=vRP.getUserId(src)
    if not uid or not auth then return end
    local bank=Config.BankRobbery and Config.BankRobbery[auth.bank]
    local door=bank and bank.Doors and bank.Doors[auth.door]
    if not door or not door.Frozen or not isNearVector(src,door.Coords,8.0) then return end
    doorAuthorizations[src]=nil
    vRP.giveInventoryItem(uid,tostring(Config.Solda or "c4"),math.max(1,int(Config.itemqtd,1)),false)
end)

-- Autorização de C4 é registrada pelo servidor em getSolda, APÓS verificar
-- quantidade de policiais, item no inventário e a porta correta. A conclusão
-- não deve repetir validação da posição do jogador: depois da animação,
-- a posição replicada pelo OneSync pode estar defasada. Isso era diferente
-- da implementação funcional de m_roubos e impedia a primeira grade de abrir.
local function c4Reject(src, reason)
    local message = tostring(reason or "Explosão não autorizada.")
    TriggerClientEvent("loffe_heist:c4ExplosionRejected",src,message)
end

RegisterNetEvent("loffe_heist:confirmC4Explosion")
AddEventHandler("loffe_heist:confirmC4Explosion",function(clientBank,clientDoor)
    local src = source
    local auth = doorAuthorizations[src]
    if not auth then
        c4Reject(src,"C4 sem autorização pendente. Verifique a instalação do recurso.")
        return
    end
    if auth.expires < os.time() then
        doorAuthorizations[src]=nil
        c4Reject(src,"Autorização da C4 expirou antes da explosão.")
        return
    end

    local bank,bankIndex=validBank(auth.bank)
    local doorIndex=int(auth.door,0)
    local door=bank and bank.Doors and bank.Doors[doorIndex]
    if not door or door.Hacking then
        doorAuthorizations[src]=nil
        c4Reject(src,"Porta autorizada inválida.")
        return
    end
    if clientBank ~= nil and (int(clientBank,-1)~=bankIndex or int(clientDoor,-1)~=doorIndex) then
        -- Nunca permitir que a C4 abra outra porta por dados enviados do cliente.
        c4Reject(src,"Identificação da porta divergiu da autorização no servidor.")
        return
    end

    -- Porta só é aberta se a C4 foi consumida e autorizada para esta etapa.
    -- Não repetir distância/posição depois da animação (fluxo m_roubos).
    if doorIndex > 1 and bank.Doors[doorIndex-1] and bank.Doors[doorIndex-1].Frozen then
        c4Reject(src,"A porta anterior ainda está fechada.")
        return
    end
    doorAuthorizations[src]=nil
    door.Frozen=false
    TriggerClientEvent("loffe_heist:setDoorFreezeStatusCl",-1,bankIndex,doorIndex,false)
    TriggerClientEvent("loffe_heist:c4ExplosionConfirmed",src,bankIndex,doorIndex)
    -- Evita que uma sincronização anterior deixe temporariamente a grade fechada.
    SetTimeout(500,function()
        if Config.BankRobbery and Config.BankRobbery[bankIndex]
            and Config.BankRobbery[bankIndex].Doors[doorIndex]
            and Config.BankRobbery[bankIndex].Doors[doorIndex].Frozen == false then
            TriggerClientEvent("loffe_heist:setDoorFreezeStatusCl",-1,bankIndex,doorIndex,false)
        end
    end)
    if doorIndex==1 then
        robberyActive=true
        dispatchPolice(src)
        resetAt[bankIndex]=os.time()+math.max(1,int(Config.Tempo,1600))
    end
end)

-- Conclusão autoritativa do hack do PC.
-- O terminal fica distante fisicamente da porta do cofre, portanto esta etapa
-- NÃO pode reutilizar a validação de proximidade da porta usada pelas C4.
RegisterNetEvent("loffe_heist:hackCompleted")
AddEventHandler("loffe_heist:hackCompleted",function(bankIndex)
    local source = source
    local bank,b = validBank(bankIndex)

    -- Fallback: se o índice vier inválido/nulo, identifica o banco pelo próprio PC.
    if not bank then
        for idx,candidate in ipairs(Config.BankRobbery or {}) do
            if candidate.Hacking and isNearVector(source,candidate.Hacking.Coords,5.0) then
                bank,b = candidate,idx
                break
            end
        end
    end
    if not robberyActive or not bank or not bank.Hacking or not bank.Doors or #bank.Doors < 1 then return end

    -- A conclusão só é válida junto ao terminal do banco.
    if not isNearVector(source,bank.Hacking.Coords,5.0) then return end

    local vaultIndex = #bank.Doors
    local vaultDoor = bank.Doors[vaultIndex]
    if not vaultDoor or not vaultDoor.Hacking then return end

    -- Sequência obrigatória: as C4 anteriores precisam ter sido concluídas.
    for doorIndex=1,vaultIndex-1 do
        local previous = bank.Doors[doorIndex]
        if previous and previous.Frozen then return end
    end

    -- Idempotente: mesmo se já estiver false, reenvia o estado para corrigir clientes.
    vaultDoor.Frozen = false
    TriggerClientEvent("loffe_heist:setDoorFreezeStatusCl",-1,b,vaultIndex,false)
    SetTimeout(350,function()
        TriggerClientEvent("loffe_heist:setDoorFreezeStatusCl",-1,b,vaultIndex,false)
    end)
    TriggerClientEvent("Notify",source,"sucesso","Sistema invadido. <b>Cofre aberto.</b>",5000)
end)

-- Etapa pós-hack: duas portas internas precisam ser abertas com maçarico.
RegisterNetEvent("loffe_heist:getInnerVaultDoorState")
AddEventHandler("loffe_heist:getInnerVaultDoorState",function(bankIndex,doorIndex)
    local source=source
    bankIndex,doorIndex=int(bankIndex,0),int(doorIndex,0)
    local states=innerVaultDoors[bankIndex]
    if states and states[doorIndex] ~= nil then
        TriggerClientEvent("loffe_heist:syncInnerVaultDoor",source,bankIndex,doorIndex,states[doorIndex])
    end
end)

RegisterNetEvent("loffe_heist:requestInnerVaultWeld")
AddEventHandler("loffe_heist:requestInnerVaultWeld",function(bankIndex,doorIndex)
    local source=source
    local user_id=vRP.getUserId(source)
    bankIndex,doorIndex=int(bankIndex,0),int(doorIndex,0)
    local bank=Config.BankRobbery and Config.BankRobbery[bankIndex]
    local states=innerVaultDoors[bankIndex]
    local coords=INNER_DOOR_COORDS[bankIndex] and INNER_DOOR_COORDS[bankIndex][doorIndex]
    local vaultDoor=bank and bank.Doors and bank.Doors[#bank.Doors]
    if not user_id or not bank or not states or states[doorIndex] == nil or not coords or not vaultDoor then return end

    if vaultDoor.Frozen then
        TriggerClientEvent("loffe_heist:cancelInnerVaultWeld",source,"Hackeie o cofre primeiro.")
        return
    end
    if states[doorIndex] == true then return end
    if not isNearVector(source,coords,2.6) then return end

    local key=innerDoorKey(bankIndex,doorIndex)
    if innerWeldWorking[key] then
        TriggerClientEvent("loffe_heist:cancelInnerVaultWeld",source,"Alguém já está passando o maçarico nesta porta.")
        return
    end
    innerWeldWorking[key]={source=source,started=os.time()}
    TriggerClientEvent("loffe_heist:beginInnerVaultWeld",source,bankIndex,doorIndex)
end)

RegisterNetEvent("loffe_heist:completeInnerVaultWeld")
AddEventHandler("loffe_heist:completeInnerVaultWeld",function(bankIndex,doorIndex)
    local source=source
    bankIndex,doorIndex=int(bankIndex,0),int(doorIndex,0)
    local bank=Config.BankRobbery and Config.BankRobbery[bankIndex]
    local states=innerVaultDoors[bankIndex]
    local coords=INNER_DOOR_COORDS[bankIndex] and INNER_DOOR_COORDS[bankIndex][doorIndex]
    local key=innerDoorKey(bankIndex,doorIndex)
    local work=innerWeldWorking[key]
    if not bank or not states or states[doorIndex] == nil or not coords or not work or work.source ~= source then return end
    if os.time() - int(work.started,os.time()) < (INNER_WELD_SECONDS-1) then
        innerWeldWorking[key]=nil
        return
    end
    if not isNearVector(source,coords,3.5) then
        innerWeldWorking[key]=nil
        return
    end
    states[doorIndex]=true
    innerWeldWorking[key]=nil
    TriggerClientEvent("loffe_heist:syncInnerVaultDoor",-1,bankIndex,doorIndex,true)
    if innerDoorsOpen(bankIndex) then
        TriggerClientEvent("Notify",source,"sucesso","As duas portas internas foram abertas. <b>O dinheiro está liberado.</b>",5000)
    else
        TriggerClientEvent("Notify",source,"sucesso","Porta interna aberta. Falta abrir a outra porta.",4000)
    end
end)

-- Kept for compatibility with external police locks; all robber door openings must
-- go through confirmC4Explosion or hackCompleted on the server.
RegisterNetEvent("loffe_heist:setDoorFreezeStatus")
AddEventHandler("loffe_heist:setDoorFreezeStatus",function(bankIndex,doorIndex,status)
    local source=source
    local uid=vRP.getUserId(source)
    local bank,b=validBank(bankIndex)
    doorIndex=int(doorIndex,0)
    local door=bank and bank.Doors and bank.Doors[doorIndex]
    if status ~= true or not uid or not door or not isNearVector(source,door.Coords,6.0)
        or not vRP.hasPermission(uid,policePermission()) then return end
    door.Frozen=true
    TriggerClientEvent("loffe_heist:setDoorFreezeStatusCl",-1,b,doorIndex,true)
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
    if not user_id or not safe or not innerDoorsOpen(b) or not isNearVector(source,safe.Coords,3.0) then return end

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
    if not user_id or not safe or not innerDoorsOpen(b) or safeWorking[key] ~= source or not isNearVector(source,safe.Coords,3.5) then return end

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
        local inner=innerVaultDoors[bankIndex]
        if inner then
            for doorIndex=1,#inner do
                TriggerClientEvent("loffe_heist:syncInnerVaultDoor",player,bankIndex,doorIndex,inner[doorIndex])
            end
        end
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

                    local inner=innerVaultDoors[bankIndex]
                    if inner then
                        for doorIndex=1,#inner do
                            inner[doorIndex]=false
                            innerWeldWorking[innerDoorKey(bankIndex,doorIndex)]=nil
                            TriggerClientEvent("loffe_heist:syncInnerVaultDoor",-1,bankIndex,doorIndex,false)
                        end
                    end
                end
                resetAt[bankIndex] = nil
                robberyActive = false
                dispatchSent = false
            end
        end
    end
end)

-- Encerramento por derrota dos bandidos: a ação termina imediatamente, mas
-- o cenário do Banco Central só volta ao estado 0 após o tempo solicitado.
AddEventHandler("loffe_heist:scheduleFullReset",function(bankIndex,seconds)
    bankIndex=int(bankIndex,1)
    seconds=math.max(1,int(seconds,600))
    if Config.BankRobbery and Config.BankRobbery[bankIndex] then
        resetAt[bankIndex]=os.time()+seconds
        robberyActive=false
        dispatchSent=false
        policeApproved={}
        doorAuthorizations={}
        for key in pairs(innerWeldWorking) do innerWeldWorking[key]=nil end
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

