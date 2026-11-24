local Proxy = module("vrp", "lib/Proxy")
local vRP = Proxy.getInterface("vRP")
local cfg = FuelConfig
local sessions = {}
local occupied = {}
local serial = 0
local lastCall = {}

local function close(source, session)
    if sessions[source] ~= session then return end
    sessions[source] = nil
    if occupied[session.vehicle] == session then occupied[session.vehicle] = nil end
end

local function failure(source, token, message)
    TriggerClientEvent("m_abastecimento:failed", source, token, message)
end

local function driverAtPump(source, session)
    local ped = GetPlayerPed(source)
    local vehicle = session.vehicle
    return ped ~= 0 and DoesEntityExist(vehicle)
        and GetEntityType(vehicle) == 2 and GetPedInVehicleSeat(vehicle, -1) == ped
        and GetPlayerRoutingBucket(source) == GetEntityRoutingBucket(vehicle)
        and GetEntitySpeed(vehicle) <= cfg.maxSpeed
        and #(GetEntityCoords(vehicle) - session.pump) <= cfg.maxPumpDistance
end

RegisterNetEvent("m_abastecimento:call", function(netId, x, y, z, capacity, fuel)
    local source = source
    local now = os.time()
    if (lastCall[source] or 0) + 2 > now then return end
    lastCall[source] = now
    if sessions[source] then return end
    if type(netId) ~= "number" or netId % 1 ~= 0 or netId < 1 or netId > 65535
        or type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number"
        or not (math.abs(x) < 10000 and math.abs(y) < 10000 and math.abs(z) < 2000)
        or type(capacity) ~= "number" or not (capacity >= 1 and capacity <= 500)
        or type(fuel) ~= "number" or not (fuel >= 0 and fuel <= capacity + 0.1) then return end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    local pump = vector3(x, y, z)
    local session = { vehicle = vehicle, pump = pump, netId = netId }
    if not driverAtPump(source, session) then
        return failure(source, nil, "Pare o veículo ao lado da bomba para chamar o frentista.")
    end

    local atStation = false
    for _, station in ipairs(cfg.stations) do
        if #(pump - station) <= cfg.stationRadius then atStation = true break end
    end
    if not atStation then return failure(source, nil, "Essa bomba está fora da área de atendimento.") end
    if occupied[vehicle] then return failure(source, nil, "Esse veículo já está em atendimento.") end

    local limit = math.floor(math.max(0, capacity - fuel) * cfg.pricePerLiter)
    if limit < 1 then return failure(source, nil, "O tanque já está cheio.") end

    serial = serial + 1
    session.token = serial
    session.limit = limit
    session.phase = "quote"
    sessions[source] = session
    occupied[vehicle] = session
    SetTimeout(cfg.sessionSeconds * 1000, function()
        if sessions[source] ~= session or session.phase ~= "quote" then return end
        close(source, session)
        failure(source, session.token, "O atendimento expirou. Buzine para chamar novamente.")
    end)
    TriggerClientEvent("m_abastecimento:attendant", source, session.token, cfg.pricePerLiter, limit)
end)

RegisterNetEvent("m_abastecimento:order", function(token, amount)
    local source = source
    local session = sessions[source]
    if not session or session.token ~= token or session.phase ~= "quote" then return end
    if type(amount) ~= "number" or not (amount >= 1 and amount <= session.limit) or amount % 1 ~= 0 then
        return failure(source, token, "Informe um valor inteiro dentro do limite do tanque.")
    end
    if not driverAtPump(source, session) then
        close(source, session)
        return failure(source, token, "O veículo saiu da área da bomba.")
    end

    session.amount = amount
    session.liters = amount / cfg.pricePerLiter
    session.phase = "approaching"
    TriggerClientEvent("m_abastecimento:approaching", source, token, session.amount, session.liters)
    SetTimeout(cfg.approachSeconds * 1000, function()
        if sessions[source] ~= session or session.phase ~= "approaching" then return end
        close(source, session)
        failure(source, token, "O frentista não conseguiu chegar ao tanque. Reposicione o veículo e buzine.")
    end)
end)

RegisterNetEvent("m_abastecimento:ready", function(token)
    local source = source
    local session = sessions[source]
    if not session or session.token ~= token or session.phase ~= "approaching" then return end
    if not driverAtPump(source, session) then
        close(source, session)
        return failure(source, token, "O veículo saiu da área da bomba.")
    end

    local amount, liters = session.amount, session.liters
    local seconds = math.max(cfg.minFillSeconds, math.ceil(liters / cfg.litersPerSecond))
    session.phase = "filling"
    TriggerClientEvent("m_abastecimento:filling", source, token, amount, liters, seconds)
    SetTimeout(seconds * 1000, function()
        if sessions[source] ~= session then return end
        if not driverAtPump(source, session) then
            close(source, session)
            return failure(source, token, "Abastecimento cancelado. O veículo saiu da bomba.")
        end
        session.phase = "paying"
        local userId = vRP.getUserId(source)
        local paid = userId and vRP.tryFullPayment(userId, amount)
        close(source, session)
        if not paid then return failure(source, token, "Saldo insuficiente. Nenhum combustível foi adicionado.") end
        TriggerClientEvent("m_abastecimento:finished", source, token, session.netId, amount, liters)
    end)
end)

RegisterNetEvent("m_abastecimento:cancel", function(token)
    local source = source
    local session = sessions[source]
    if session and session.token == token and session.phase ~= "paying" then close(source, session) end
end)

AddEventHandler("playerDropped", function()
    local source = source
    lastCall[source] = nil
    if sessions[source] then close(source, sessions[source]) end
end)
