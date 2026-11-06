-- Lixeiro - servidor
-- Coleta validada, pagamento cooperativo e controle dos trabalhadores na traseira do caminhão.

local TRASH_VEHICLE_MODEL = GetHashKey("trash")
local TRASH_RESPAWN_SECONDS = 15 * 60
local CLAIM_DISTANCE = 4.0
local DEPOSIT_DISTANCE = 8.0
local REAR_RIDE_DISTANCE = 6.0

local activeBags = {}          -- [user_id] = { key, claimedAt }
local claimedTrash = {}        -- [coordKey] = expiresAt
local rearRiders = {}          -- [netId] = { [1] = source, [2] = source }
local rearRideBySource = {}    -- [source] = { netId, slot }

local fallbackTrashModels = {
    [1388308576] = true,
    [1948359883] = true,
    [897494494] = true,
    [1098827230] = true,
    [-1681329307] = true
}

local function isAllowedTrashModel(model)
    model = tonumber(model)
    if not model then return false end

    local extra = cfg.extra and cfg.extra["Lixeiro"] or nil
    local list = extra and extra.modelos_lixo or nil
    if type(list) == "table" and #list > 0 then
        for _, hash in pairs(list) do
            if tonumber(hash) == model then return true end
        end
        return false
    end

    return fallbackTrashModels[model] == true
end

local function roundHalf(value)
    value = tonumber(value) or 0.0
    if value >= 0 then
        return math.floor((value * 2.0) + 0.5) / 2.0
    end
    return math.ceil((value * 2.0) - 0.5) / 2.0
end

local function trashKey(x, y, z)
    return ("%.1f:%.1f:%.1f"):format(roundHalf(x), roundHalf(y), roundHalf(z))
end

local function entityDistance(a, b)
    if not a or not b then return math.huge end
    local dx = (a.x or 0.0) - (b.x or 0.0)
    local dy = (a.y or 0.0) - (b.y or 0.0)
    local dz = (a.z or 0.0) - (b.z or 0.0)
    return math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
end

local function cleanupExpiredClaims()
    local now = os.time()
    for key, expiresAt in pairs(claimedTrash) do
        if tonumber(expiresAt) and expiresAt <= now then
            claimedTrash[key] = nil
        end
    end
end

local function getLixeiro(source)
    source = tonumber(source)
    if not source or not GetPlayerName(source) then return nil end

    local userId = vRP.getUserId(source)
    if not userId then return nil end
    if not MageEmpregosHasJob(userId, "Lixeiro") then return nil end
    if not MageEmpregosIsServiceActive(userId, "Lixeiro") then return nil end
    return tonumber(userId)
end

local function getPlayerCoords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

local function getPaymentForLevel(userId)
    local query = mg.query('get_empdata', { user_id = userId })
    if not query[1] or not query[1].dvalue then return nil, nil end

    local jobs = json.decode(query[1].dvalue) or {}
    local progress = jobs["Lixeiro"] or {}
    local level = tonumber(progress.nivel) or 1
    local ranges = cfg.list["Lixeiro"] and cfg.list["Lixeiro"].payment_for_level or {}
    local range = ranges[level]
    if type(range) ~= "table" or range[1] == nil or range[2] == nil then
        return nil, level
    end

    local minPayment = math.floor(tonumber(range[1]) or 0)
    local maxPayment = math.floor(tonumber(range[2]) or 0)
    if maxPayment < minPayment then minPayment, maxPayment = maxPayment, minPayment end
    return math.random(minPayment, maxPayment), level
end

local function resolveDriverSource(vehicle, claimedSource)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return nil end

    local driverPed = GetPedInVehicleSeat(vehicle, -1)
    if driverPed and driverPed ~= 0 then
        local owner = NetworkGetEntityOwner(driverPed)
        if owner and tonumber(owner) and tonumber(owner) > 0 and GetPlayerName(tonumber(owner)) then
            return tonumber(owner)
        end
    end

    claimedSource = tonumber(claimedSource)
    if claimedSource and claimedSource > 0 and GetPlayerName(claimedSource) then
        local ped = GetPlayerPed(claimedSource)
        if ped and ped ~= 0 and GetVehiclePedIsIn(ped, false) == vehicle then
            return claimedSource
        end
    end

    return nil
end

local function releaseRearRide(source, forceClient)
    source = tonumber(source)
    if not source then return end

    local ride = rearRideBySource[source]
    if not ride then return end

    local slots = rearRiders[ride.netId]
    if slots and slots[ride.slot] == source then
        slots[ride.slot] = nil
        if not slots[1] and not slots[2] then
            rearRiders[ride.netId] = nil
        end
    end

    rearRideBySource[source] = nil
    if forceClient and GetPlayerName(source) then
        TriggerClientEvent("m_empregos:lixeiroForceRearDetach", source)
    end
end

local function clearRearRidersFromDriver(driverSource)
    driverSource = tonumber(driverSource)
    if not driverSource then return end

    for netId, slots in pairs(rearRiders) do
        local vehicle = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
        local currentDriver = resolveDriverSource(vehicle, nil)
        if currentDriver == driverSource then
            for slot = 1, 2 do
                local riderSource = slots[slot]
                if riderSource then
                    releaseRearRide(riderSource, true)
                end
            end
            rearRiders[netId] = nil
        end
    end
end

function src.lixeiroClaimTrash(point, model)
    local playerSource = source
    local userId = getLixeiro(playerSource)
    if not userId then
        return { ok = false, message = "Você precisa estar em serviço como Lixeiro." }
    end

    if activeBags[userId] then
        return { ok = false, message = "Você já está carregando um saco de lixo." }
    end

    if type(point) ~= "table" or not isAllowedTrashModel(model) then
        MageEmpregosLogInvalid(playerSource, "coletar lixo", "Modelo ou posição de lixo inválidos.")
        return { ok = false, message = "Este lixo não pode ser coletado." }
    end

    local x = tonumber(point.x or point[1])
    local y = tonumber(point.y or point[2])
    local z = tonumber(point.z or point[3])
    if not x or not y or not z then
        return { ok = false, message = "Posição inválida." }
    end

    local playerCoords = getPlayerCoords(playerSource)
    if not playerCoords or entityDistance(playerCoords, { x = x, y = y, z = z }) > CLAIM_DISTANCE then
        MageEmpregosLogInvalid(playerSource, "coletar lixo", "O jogador estava distante do lixo informado.")
        return { ok = false, message = "Aproxime-se do lixo." }
    end

    cleanupExpiredClaims()
    local key = trashKey(x, y, z)
    if claimedTrash[key] then
        return { ok = false, message = "Este lixo já foi coletado recentemente." }
    end

    claimedTrash[key] = os.time() + TRASH_RESPAWN_SECONDS
    activeBags[userId] = {
        key = key,
        source = playerSource,
        claimedAt = os.time()
    }

    TriggerClientEvent("m_empregos:lixeiroTrashCollected", -1, key, { x = x, y = y, z = z }, tonumber(model))
    return { ok = true, key = key }
end

function src.lixeiroDepositTrash(netId, claimedDriverSource)
    local playerSource = source
    local userId = getLixeiro(playerSource)
    if not userId then
        return { ok = false, message = "Você precisa estar em serviço como Lixeiro." }
    end

    local bag = activeBags[userId]
    if not bag then
        return { ok = false, message = "Você não está carregando lixo." }
    end

    netId = tonumber(netId)
    if not netId then return { ok = false, message = "Caminhão inválido." } end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) or GetEntityModel(vehicle) ~= TRASH_VEHICLE_MODEL then
        MageEmpregosLogInvalid(playerSource, "depositar lixo", "O veículo informado não era um caminhão de lixo válido.")
        return { ok = false, message = "Aproxime-se de um caminhão de lixo válido." }
    end

    local playerCoords = getPlayerCoords(playerSource)
    local vehicleCoords = GetEntityCoords(vehicle)
    if not playerCoords or entityDistance(playerCoords, vehicleCoords) > DEPOSIT_DISTANCE then
        MageEmpregosLogInvalid(playerSource, "depositar lixo", "O jogador estava distante do caminhão informado.")
        return { ok = false, message = "Aproxime-se da traseira do caminhão." }
    end

    -- Consome a coleta antes de pagar. Uma mesma coleta nunca pode pagar duas vezes.
    activeBags[userId] = nil

    local payment, level = getPaymentForLevel(userId)
    if not payment then
        TriggerClientEvent("Notify", playerSource, "negado", "Não foi possível calcular o pagamento deste nível.", 6)
        return { ok = false, message = "Pagamento não configurado." }
    end

    MageEmpregosGrantXp(playerSource, "Lixeiro")
    mg.payment(userId, payment)
    TriggerClientEvent("Notify", playerSource, "sucesso", ("[Lixeiro] Você recebeu R$ %d pela coleta."):format(payment), 7)

    local driverSource = resolveDriverSource(vehicle, claimedDriverSource)
    local driverBonus = 0
    local driverId = nil

    if driverSource and driverSource ~= playerSource then
        driverId = getLixeiro(driverSource)
        if driverId then
            driverBonus = math.max(0, math.floor((payment * 0.70) + 0.5))
            if driverBonus > 0 then
                mg.payment(driverId, driverBonus)
                TriggerClientEvent(
                    "Notify",
                    driverSource,
                    "sucesso",
                    ("[Lixeiro] Você recebeu R$ %d por auxiliar a coleta como motorista."):format(driverBonus),
                    7
                )
            end
        end
    end

    if type(MageEmpregosLog) == "function" then
        MageEmpregosLog("job_lixeiro_payment", {
            actorId = userId,
            details = ("Emprego: Lixeiro\nNível: %d\nPagamento do coletor: %s\nMotorista parceiro: %s\nBônus do motorista (-30%%): %s"):format(
                tonumber(level) or 1,
                type(MageEmpregosMoney) == "function" and MageEmpregosMoney(payment) or tostring(payment),
                driverId and tostring(driverId) or "nenhum",
                driverBonus > 0 and (type(MageEmpregosMoney) == "function" and MageEmpregosMoney(driverBonus) or tostring(driverBonus)) or "nenhum"
            )
        })
    end

    return {
        ok = true,
        payment = payment,
        driverBonus = driverBonus,
        driverSource = driverSource
    }
end

function src.lixeiroRequestRearRide(netId, claimedDriverSource)
    local riderSource = source
    local userId = getLixeiro(riderSource)
    if not userId then
        return { ok = false, message = "Você precisa estar em serviço como Lixeiro." }
    end

    if activeBags[userId] then
        return { ok = false, message = "Guarde o lixo no caminhão antes de subir na traseira." }
    end

    if rearRideBySource[riderSource] then
        return { ok = false, message = "Você já está na traseira de um caminhão." }
    end

    netId = tonumber(netId)
    if not netId then return { ok = false, message = "Caminhão inválido." } end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) or GetEntityModel(vehicle) ~= TRASH_VEHICLE_MODEL then
        return { ok = false, message = "Caminhão de lixo inválido." }
    end

    local riderCoords = getPlayerCoords(riderSource)
    local vehicleCoords = GetEntityCoords(vehicle)
    if not riderCoords or entityDistance(riderCoords, vehicleCoords) > REAR_RIDE_DISTANCE then
        return { ok = false, message = "Aproxime-se da traseira do caminhão." }
    end

    if GetEntitySpeed(vehicle) > 2.0 then
        return { ok = false, message = "O caminhão precisa estar praticamente parado para subir." }
    end

    local driverSource = resolveDriverSource(vehicle, claimedDriverSource)
    if not driverSource or driverSource == riderSource then
        return { ok = false, message = "É necessário outro Lixeiro dirigindo o caminhão." }
    end

    if not getLixeiro(driverSource) then
        return { ok = false, message = "O motorista também precisa estar em serviço como Lixeiro." }
    end

    local slots = rearRiders[netId]
    if not slots then
        slots = {}
        rearRiders[netId] = slots
    end

    -- Limpa ocupantes que já desconectaram ou deixaram o serviço.
    for slot = 1, 2 do
        local occupant = slots[slot]
        if occupant and (not GetPlayerName(occupant) or not getLixeiro(occupant)) then
            rearRideBySource[occupant] = nil
            slots[slot] = nil
        end
    end

    local slot = not slots[1] and 1 or (not slots[2] and 2 or nil)
    if not slot then
        return { ok = false, message = "As duas posições traseiras já estão ocupadas." }
    end

    slots[slot] = riderSource
    rearRideBySource[riderSource] = { netId = netId, slot = slot }

    return { ok = true, slot = slot }
end

function src.lixeiroReleaseRearRide()
    releaseRearRide(source, false)
    return true
end

-- Chamado pelo controle geral de expediente em server.lua.
function MageLixeiroOnServiceEnd(userId, playerSource)
    userId = tonumber(userId)
    playerSource = tonumber(playerSource)

    if userId then
        activeBags[userId] = nil
    end

    if playerSource then
        releaseRearRide(playerSource, true)
        clearRearRidersFromDriver(playerSource)
    end
end

AddEventHandler("playerDropped", function()
    local playerSource = source
    local userId = vRP.getUserId(playerSource)
    if userId then activeBags[tonumber(userId)] = nil end
    releaseRearRide(playerSource, false)
    clearRearRidersFromDriver(playerSource)
end)

CreateThread(function()
    while true do
        Wait(10000)
        cleanupExpiredClaims()

        for netId, slots in pairs(rearRiders) do
            local vehicle = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
            if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
                for slot = 1, 2 do
                    if slots[slot] then releaseRearRide(slots[slot], true) end
                end
                rearRiders[netId] = nil
            else
                for slot = 1, 2 do
                    local rider = slots[slot]
                    if rider and (not GetPlayerName(rider) or not getLixeiro(rider)) then
                        releaseRearRide(rider, true)
                    end
                end
            end
        end
    end
end)
