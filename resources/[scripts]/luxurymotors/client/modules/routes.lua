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
            print(("^1[luxurymotors]^7 Erro na rota NUI '%s': %s"):format(routeName, result))
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
        currency = data.currency or 'cash',
        diamondPrice = tonumber(data.diamondPrice) or 0,
        image = data.image or (data.category ~= 'blindados' and Default.imagesDir .. vehicle .. '.png' or nil),
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
    safeCallback('SHOWROOM_EDITOR', function()
        local result = Server.getShowroomEditor()
        for spawn, entry in pairs(result.catalog or {}) do
            local hash = GetHashKey(spawn)
            if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
                result.catalog[spawn] = nil
            elseif entry.category ~= 'blindados' then
                entry.image = entry.image or Default.imagesDir .. spawn .. '.png'
            end
        end
        return result
    end)
    safeCallback('DIAMOND_BALANCE', function() return Server.getDiamondBalance() end)
    safeCallback('REMOVE_SHOWROOM_VEHICLE', function(data) return Server.removeShowroomVehicle(data) end)
    safeCallback('ADD_SHOWROOM_VEHICLE', function(data)
        local spawn = tostring(data.spawn or ''):lower():gsub('^%s+', ''):gsub('%s+$', '')
        -- Apelidos do pack tambem podem ser usados no cadastro.
        local aliases = {f250='baller',fordf250='baller',celta='ingot',s10='chevys10',golgts='blista2',monza='exemplar',saveirodeboche='zion',saveiroestilodub='vwsava',saveirosummer='oracle'}
        local added = {unoescada='unoservice',patinete='serv_electricscooter',mix150='150',hondamix='150',twister='bati',cbx150='bati',cbx250='bati',cbxtwister='bati',bros='bros150',hondabros150='bros150',hornet='hornetagstore'}
        spawn = added[spawn] or aliases[spawn] or spawn
        local model = GetHashKey(spawn)
        if not IsModelInCdimage(model) or not IsModelAVehicle(model) then
            return {ok=false, message='Modelo indisponivel. Instale e carregue o veiculo antes de cadastrar.'}
        end
        data.spawn = spawn
        return Server.addShowroomVehicle(data)
    end)
    safeCallback('CLOSE', function()
        StopLuxuryPreview()
        SendNUIMessage({ action = 'close' })
        SetNuiFocus(false, false)
        DealerShipIndexOpen = nil
        return true
    end)

    safeCallback('GET_CATEGORIES', function()
        return DealershipCategories or {}
    end)

    safeCallback('DELUXE_SETTINGS', function()
        local location = DealerShipIndexOpen and TestDrive.Locations[DealerShipIndexOpen]
        return { testDriveEnabled = location and location.test_drive ~= nil or false }
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
            print("^1[luxurymotors]^7 Falha ao comprar veículo: " .. tostring(response))
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
            StopLuxuryPreview()
            return InitializeTestDrive(vehicle.spawn, DealerShipIndexOpen, tostring(data.color or ''))
        end, debug.traceback)
        actionBusy = false

        if not ok then
            print("^1[luxurymotors]^7 Falha ao iniciar test-drive: " .. tostring(started))
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
            print("^1[luxurymotors]^7 Falha ao vender veículo: " .. tostring(response))
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
    local location = DealerShipIndexOpen and TestDrive.Locations[DealerShipIndexOpen]
    SendNUIMessage({ action = location and location.panel == 'deluxe' and 'openDeluxe' or 'open' })
    return true
end

function Client.closeDealership()
    StopLuxuryPreview()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    return true
end
