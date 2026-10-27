local actionBusy = false

local function makeActionResponse(ok, message, extra)
    local response = extra or {}
    response.ok = ok == true
    if message then response.message = message end
    return response
end

local function safeCallback(routeName, fn)
    RegisterNUICallback(routeName, function(data, cb)
        local responded = false
        local function reply(value)
            if responded then return end
            responded = true
            cb(value == nil and false or value)
        end

        local ok, result = xpcall(function()
            return fn(type(data) == "table" and data or {})
        end, debug.traceback)

        if not ok then
            print(("^1[m_dealership]^7 Erro na rota NUI '%s': %s"):format(routeName, result))
            reply(makeActionResponse(false, "Ocorreu um erro interno na concessionária."))
            return
        end

        reply(result)
    end)
end

local function buildVehiclePayload(vehicle, data)
    local vehicleModel = GetHashKey(vehicle)
    local attributes = {
        acceleration = GetVehicleModelAcceleration(vehicleModel) or 0,
        braking = GetVehicleModelMaxBraking(vehicleModel) or 0,
        agility = GetVehicleModelEstimatedAgility(vehicleModel) or 0
    }

    return {
        name = data.name,
        value = tonumber(data.price) or 0,
        image = Default.imagesDir .. vehicle .. '.png',
        trunk = tonumber(data.trunk) or 0,
        acceleration = ClassifyAttribute(attributes.acceleration, Thresholds.acceleration),
        speed = math.floor((GetVehicleModelEstimatedMaxSpeed(vehicleModel) or 0) * 3.605936),
        brake = ClassifyAttribute(attributes.braking, Thresholds.braking),
        agility = ClassifyAttribute(attributes.agility, Thresholds.agility),
        seats = GetVehicleModelNumberOfSeats(vehicleModel) or 1,
        category = data.category or (data.vip and "vips" or GetVehicleCategory(vehicleModel)),
        stock = tonumber(data.stock) or 0,
        spawn = vehicle,
    }
end

local function RegisterRoutes()
    safeCallback('CLOSE', function()
        SendNUIMessage({ action = 'close' })
        SetNuiFocus(false, false)
        DealerShipIndexOpen = nil
        return true
    end)

    safeCallback('GET_VEHICLES', function()
        local vehiclesNotProcessed = Server.getVehicles()
        if type(vehiclesNotProcessed) ~= "table" or not next(vehiclesNotProcessed) then
            return {}
        end

        local tempTable = {}
        for vehicle, data in pairs(vehiclesNotProcessed) do
            if type(vehicle) == "string" and type(data) == "table" then
                tempTable[#tempTable + 1] = buildVehiclePayload(vehicle, data)
            end
        end

        table.sort(tempTable, function(a, b)
            return tostring(a.name):lower() < tostring(b.name):lower()
        end)

        return tempTable
    end)

    safeCallback('CAN_BUY', function(data)
        if actionBusy then
            return makeActionResponse(false, "Já existe uma operação em andamento.")
        end

        local vehicle = data.vehicle
        if type(vehicle) ~= "table" or type(vehicle.spawn) ~= "string" or vehicle.spawn == "" then
            return makeActionResponse(false, "Veículo inválido.")
        end

        actionBusy = true
        local ok, response = xpcall(function()
            return Server.buyVehicle({ spawn = vehicle.spawn }, tostring(data.color or ""))
        end, debug.traceback)
        actionBusy = false

        if not ok then
            print("^1[m_dealership]^7 Falha ao comprar veículo: " .. tostring(response))
            return makeActionResponse(false, "Não foi possível concluir a compra.")
        end

        if type(response) == "table" then return response end
        return makeActionResponse(response == true)
    end)

    safeCallback('TEST_DRIVE', function(data)
        if actionBusy or InTestDrive then
            return makeActionResponse(false, "Já existe uma operação em andamento.")
        end

        local vehicle = data.vehicle
        if type(vehicle) ~= "table" or type(vehicle.spawn) ~= "string" or vehicle.spawn == "" then
            return makeActionResponse(false, "Veículo inválido.")
        end

        if type(DealerShipIndexOpen) ~= "number" then
            return makeActionResponse(false, "Local da concessionária não identificado.")
        end

        actionBusy = true
        local ok, started = xpcall(function()
            return InitializeTestDrive(vehicle.spawn, DealerShipIndexOpen)
        end, debug.traceback)
        actionBusy = false

        if not ok then
            print("^1[m_dealership]^7 Falha ao iniciar test-drive: " .. tostring(started))
            return makeActionResponse(false, "Não foi possível iniciar o test-drive.")
        end

        return makeActionResponse(started == true)
    end)

    safeCallback('GET_MOST_SOLD', function()
        local topMostSold = Server.getMostSold()
        if type(topMostSold) ~= "table" then return {} end

        local tempTable = {}
        for _, vehicle in pairs(topMostSold) do
            if type(vehicle) == "table" and type(vehicle.index) == "string" and type(vehicle.data) == "table" then
                local payload = buildVehiclePayload(vehicle.index, vehicle.data)
                tempTable[#tempTable + 1] = payload
            end
        end
        return tempTable
    end)

    safeCallback('GET_MY_VEHICLES', function()
        local myVehicles = Server.getMyVehicles()
        if type(myVehicles) ~= "table" or not next(myVehicles) then return {} end

        local tempTable = {}
        for vehicle, data in pairs(myVehicles) do
            if type(vehicle) == "string" and type(data) == "table" then
                local payload = buildVehiclePayload(vehicle, data)
                payload.category = "meus-veiculos"
                payload.stock = 0
                tempTable[#tempTable + 1] = payload
            end
        end

        table.sort(tempTable, function(a, b)
            return tostring(a.name):lower() < tostring(b.name):lower()
        end)

        return tempTable
    end)

    safeCallback('SELL_VEHICLE', function(data)
        if actionBusy then
            return makeActionResponse(false, "Já existe uma operação em andamento.")
        end

        local vehicle = data.vehicle
        if type(vehicle) ~= "table" or type(vehicle.spawn) ~= "string" or vehicle.spawn == "" then
            return makeActionResponse(false, "Veículo inválido.")
        end

        actionBusy = true
        local ok, response = xpcall(function()
            return Server.sellVehicle(vehicle.spawn)
        end, debug.traceback)
        actionBusy = false

        if not ok then
            print("^1[m_dealership]^7 Falha ao vender veículo: " .. tostring(response))
            return makeActionResponse(false, "Não foi possível concluir a venda.")
        end

        if type(response) == "table" then return response end
        return makeActionResponse(response == true)
    end)
end

CreateThread(RegisterRoutes)

function Client.openDealership()
    if InTestDrive then return false end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    return true
end

function Client.closeDealership()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    return true
end
