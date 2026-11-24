local cfg = FuelConfig
local current
local lastDelivered = 0
local appliedConsumption = false

local function notify(message)
    TriggerEvent("Notify", "importante", message, 5)
end

local function close(notifyServer)
    local session = current
    if not session then return end
    current = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    if session.npc and DoesEntityExist(session.npc) then DeletePed(session.npc) end
    if notifyServer and session.token then
        TriggerServerEvent("m_abastecimento:cancel", session.token)
    end
end

local function closestPump(vehicle)
    local coords = GetEntityCoords(vehicle)
    local nearStation = false
    for _, station in ipairs(cfg.stations) do
        if #(coords - station) <= cfg.stationRadius + cfg.maxPumpDistance then nearStation = true break end
    end
    if not nearStation then return end

    local closest
    local distance = cfg.maxPumpDistance
    for _, model in ipairs(cfg.pumpModels) do
        local object = GetClosestObjectOfType(coords.x, coords.y, coords.z, cfg.maxPumpDistance, joaat(model), false, false, false)
        if object ~= 0 then
            local pump = GetEntityCoords(object)
            local gap = #(coords - pump)
            if gap < distance then closest, distance = pump, gap end
        end
    end
    return closest
end

local function stillAtPump(session)
    local vehicle = session.vehicle
    local ped = PlayerPedId()
    return DoesEntityExist(vehicle) and GetVehiclePedIsIn(ped, false) == vehicle
        and GetPedInVehicleSeat(vehicle, -1) == ped and not IsEntityDead(ped)
        and GetEntitySpeed(vehicle) <= cfg.maxSpeed
        and #(GetEntityCoords(vehicle) - session.pump) <= cfg.maxPumpDistance
end

local function walkTo(npc, point, distance)
    TaskFollowNavMeshToCoord(npc, point.x, point.y, point.z, 1.2, 9500, distance, false, 0.0)
end

local function fuelPosition(vehicle, npc, oppositeSide)
    local model = GetEntityModel(vehicle)
    local bike = IsThisModelABike(model)
    local boundsMin, boundsMax = GetModelDimensions(model)
    local length = boundsMax.y - boundsMin.y
    local tankX, tankY = 0.0, bike and boundsMin.y + length * 0.65 or math.max(boundsMin.y, -1.5)
    local npcCoords = GetEntityCoords(npc)
    local npcOffset = GetOffsetFromEntityGivenWorldCoords(vehicle, npcCoords.x, npcCoords.y, npcCoords.z)
    local side = bike and npcOffset.x > 0 and 1 or -1

    for _, name in ipairs({ "petrolcap", "petroltank", "petroltank_l", "petroltank_r" }) do
        local bone = GetEntityBoneIndexByName(vehicle, name)
        if bone ~= -1 then
            local world = GetWorldPositionOfEntityBone(vehicle, bone)
            local offset = GetOffsetFromEntityGivenWorldCoords(vehicle, world.x, world.y, world.z)
            if not bike or offset.y >= boundsMin.y + length * 0.48 then
                tankX, tankY = offset.x, offset.y
                if not bike and math.abs(tankX) > 0.20 then side = tankX > 0 and 1 or -1 end
                break
            end
        end
    end

    if oppositeSide then side = -side end
    local edge = side == 1 and boundsMax.x or boundsMin.x
    local standX = edge + side * (bike and 0.38 or 0.52)
    local stand = GetOffsetFromEntityInWorldCoords(vehicle, standX, tankY, boundsMin.z)
    local target = GetOffsetFromEntityInWorldCoords(vehicle, tankX, tankY, 0.0)
    return stand, target, bike
end

local function reached(npc, point, tolerance)
    local coords = GetEntityCoords(npc)
    local dx, dy = coords.x - point.x, coords.y - point.y
    return dx * dx + dy * dy <= tolerance * tolerance and math.abs(coords.z - point.z) < 2.0
end

RegisterNetEvent("m_abastecimento:attendant", function(token, price, limit)
    local session = current
    if not session or session.token or not stillAtPump(session) then
        TriggerServerEvent("m_abastecimento:cancel", token)
        return
    end

    session.token = token
    local model = joaat(cfg.attendantModel)
    RequestModel(model)
    local deadline = GetGameTimer() + 4500
    while current == session and not HasModelLoaded(model) and GetGameTimer() < deadline do Wait(30) end
    if current ~= session or not HasModelLoaded(model) then
        SetModelAsNoLongerNeeded(model)
        if current == session then
            notify("O frentista não conseguiu chegar. Buzine para tentar novamente.")
            close(true)
        end
        return
    end

    local start = session.pump + vector3(3.5, 3.5, 0.0)
    local found, spawn = GetSafeCoordForPed(start.x, start.y, start.z, false, 16)
    if found and #(spawn - session.pump) < 12.0 then start = spawn end
    local npc = CreatePed(4, model, start.x, start.y, start.z, 0.0, false, false)
    SetModelAsNoLongerNeeded(model)
    if npc == 0 then
        notify("O frentista não está disponível.")
        close(true)
        return
    end
    session.npc = npc
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)

    local window = GetOffsetFromEntityInWorldCoords(session.vehicle, -1.5, 0.5, 0.0)
    walkTo(npc, window, 1.1)
    deadline = GetGameTimer() + 10000
    while current == session and #(GetEntityCoords(npc) - window) > 1.7 and GetGameTimer() < deadline do Wait(120) end
    if current ~= session then return end
    if #(GetEntityCoords(npc) - window) > 2.5 then
        notify("O frentista não conseguiu chegar à janela. Reposicione o veículo e buzine.")
        close(true)
        return
    end

    ClearPedTasks(npc)
    TaskTurnPedToFaceEntity(npc, session.vehicle, 1800)
    session.ui = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "open", price = price, limit = limit })
end)

RegisterNUICallback("order", function(data, cb)
    if not current or not current.ui or current.ordered or not current.token then
        cb({ ok = false })
        return
    end
    current.ordered = true
    TriggerServerEvent("m_abastecimento:order", current.token, tonumber(data.amount))
    cb({ ok = true })
end)

RegisterNUICallback("close", function(_, cb)
    close(true)
    cb({ ok = true })
end)

RegisterNetEvent("m_abastecimento:approaching", function(token, amount, liters)
    local session = current
    if not session or session.token ~= token then return end
    local npc = session.npc
    if not npc or not DoesEntityExist(npc) then return end

    SendNUIMessage({ action = "approaching", amount = amount, liters = liters })
    local stand, target, bike = fuelPosition(session.vehicle, npc, false)
    local alternate
    if bike then alternate = fuelPosition(session.vehicle, npc, true) end
    local tolerance = bike and 0.38 or 0.60
    local started = GetGameTimer()
    local deadline = started + (cfg.approachSeconds - 1) * 1000
    walkTo(npc, stand, 0.2)

    while current == session and DoesEntityExist(npc) and GetGameTimer() < deadline do
        if reached(npc, stand, tolerance) then
            ClearPedTasks(npc)
            TaskTurnPedToFaceCoord(npc, target.x, target.y, target.z, 450)
            TriggerServerEvent("m_abastecimento:ready", token)
            return
        end
        if alternate and GetGameTimer() - started >= 4800 then
            stand, alternate = alternate, nil
            walkTo(npc, stand, 0.2)
        end
        Wait(100)
    end
end)

RegisterNetEvent("m_abastecimento:filling", function(token, amount, liters, seconds)
    local session = current
    if not session or session.token ~= token then return end
    SendNUIMessage({ action = "filling", amount = amount, liters = liters, seconds = seconds })

    local npc = session.npc
    local refuelDict = "timetable@gardener@filling_can"
    RequestAnimDict(refuelDict)
    Wait(450)
    local deadline = GetGameTimer() + 1200
    while current == session and not session.finished and not HasAnimDictLoaded(refuelDict)
        and GetGameTimer() < deadline do Wait(30) end
    if current == session and not session.finished and npc and DoesEntityExist(npc) and HasAnimDictLoaded(refuelDict) then
        TaskPlayAnim(npc, refuelDict, "gar_ig_5_filling_can", 4.0, -4.0, -1, 1, 0.0, false, false, false)
    end
    RemoveAnimDict(refuelDict)
end)

RegisterNetEvent("m_abastecimento:finished", function(token, netId, amount, liters)
    if token <= lastDelivered then return end
    lastDelivered = token
    local vehicle = NetToVeh(netId)
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        local capacity = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fPetrolTankVolume")
        SetVehicleFuelLevel(vehicle, math.min(capacity, math.max(0.0, GetVehicleFuelLevel(vehicle)) + liters))
    end
    local session = current
    if not session or session.token ~= token then return end
    session.finished = true
    if session.npc and DoesEntityExist(session.npc) then
        ClearPedTasks(session.npc)
        walkTo(session.npc, session.pump + vector3(3.5, 3.5, 0.0), 0.7)
    end
    SendNUIMessage({ action = "finished", amount = amount, liters = liters })
    SetTimeout(3500, function() if current == session then close(false) end end)
end)

RegisterNetEvent("m_abastecimento:failed", function(token, message)
    if not current or (token and current.token ~= token) then return end
    notify(message)
    close(true)
end)

CreateThread(function()
    if cfg.enableConsumption then
        SetFuelConsumptionState(true)
        SetFuelConsumptionRateMultiplier(cfg.consumptionMultiplier)
        appliedConsumption = true
    end
    while true do
        local wait = 350
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if current then
            if not current.finished and not stillAtPump(current) then close(true) end
        elseif vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped
            and GetEntitySpeed(vehicle) <= cfg.maxSpeed and not IsEntityDead(ped) then
            wait = 0
            if IsControlJustPressed(0, 86) then
                local pump = closestPump(vehicle)
                if pump and NetworkGetEntityIsNetworked(vehicle) then
                    local capacity = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fPetrolTankVolume")
                    if capacity > 0 and DoesVehicleUseFuel(vehicle) then
                        local session = { vehicle = vehicle, pump = pump }
                        current = session
                        local fuel = math.min(capacity, math.max(0.0, GetVehicleFuelLevel(vehicle)))
                        TriggerServerEvent("m_abastecimento:call", VehToNet(vehicle), pump.x, pump.y, pump.z, capacity, fuel)
                        SetTimeout(5000, function()
                            if current == session and not session.token then close(false) end
                        end)
                    else
                        notify("Este veículo não usa combustível.")
                    end
                end
            end
        end
        Wait(wait)
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    close(false)
    if appliedConsumption then SetFuelConsumptionState(false) end
end)
