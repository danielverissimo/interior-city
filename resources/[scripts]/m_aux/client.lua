local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
local vRP = Proxy.getInterface("vRP")

local API = {}
Tunnel.bindInterface(GetCurrentResourceName(), API)
local vSERVER = Tunnel.getInterface(GetCurrentResourceName())
local inventorySERVER = Tunnel.getInterface("inventory")

local shownui = false
local placingObject = false
local spawnedObjects = {}
local objectData = {}
local tyreCooldown = {}

local function notify(kind, message, time)
    TriggerEvent("Notify", kind, message, time or 5000)
end


-- Avisos públicos dos setores. A NUI do resource permanece carregada mesmo
-- com o painel F2 fechado, igual ao aviso geral do painel administrativo.
RegisterNetEvent("m_aux:departmentAnnouncement", function(data)
    data = type(data) == "table" and data or {}
    SendNUIMessage({
        action = "departmentAlert",
        title = tostring(data.title or "AVISO"),
        message = tostring(data.message or ""),
        accent = tostring(data.accent or "#4ea8ff"),
        duration = math.max(3, math.min(300, tonumber(data.duration) or 15))
    })
end)

local function closePanel()
    if not shownui then return end
    shownui = false
    SendNUIMessage({ action = "close" })
    SetNuiFocus(false, false)
end

local function openPanel()
    if placingObject then return end

    local role = vSERVER.checkPerm()
    if not role then
        notify("negado", "Você não tem permissão para acessar este painel.")
        return
    end

    shownui = true
    SendNUIMessage({
        action = "open",
        type = role,
        table = cfg.table,
        roleInfo = cfg.roleInfo[role] or {}
    })
    SetNuiFocus(true, true)
end

local function togglePanel()
    if shownui then closePanel() else openPanel() end
end

RegisterCommand("m_aux_panel", togglePanel, false)
RegisterKeyMapping("m_aux_panel", "Abrir painel de serviço", "keyboard", cfg.open)
-- Legacy alias kept for compatibility with the original resource.
RegisterCommand("pad", togglePanel, false)

RegisterNUICallback("close", function(_, cb)
    closePanel()
    cb({ ok = true })
end)

local function nuiResult(cb, result)
    if type(result) ~= "table" then
        result = { ok = result == true }
    end
    -- When the panel was intentionally closed before a server prompt/action,
    -- surface failures through the city's regular notification system.
    if not shownui and result.ok == false and result.message then
        notify("negado", result.message)
    end
    cb(result)
end

RegisterNUICallback("action", function(data, cb)
    if type(data) ~= "table" or type(data.action) ~= "string" then
        return cb({ ok = false, message = "Ação inválida." })
    end

    local action = data.action
    local role = data.role

    if role == "police" then
        if action == "p_cone" or action == "p_spike" or action == "p_barrier" then
            local kind = action == "p_cone" and "cone" or (action == "p_spike" and "spike" or "barrier")
            closePanel()
            CreateThread(function()
                Wait(100)
                TriggerEvent("m_aux:startPlacement", kind)
            end)
            return cb({ ok = true, close = true })
        end

        -- RG/placa return their result inside this NUI. Every other police action
        -- releases focus first so vRP prompts/requests can receive keyboard input.
        if action ~= "p_rg" and action ~= "plate" then closePanel() end
        local result = vSERVER.police(action, data.value)
        if result and result.close == true then closePanel() end
        return nuiResult(cb, result)
    elseif role == "medic" then
        closePanel()
        local result = vSERVER.medic(action, data.value)
        return nuiResult(cb, result)
    elseif role == "mecanic" then
        closePanel()
        local result = vSERVER.mecanic(action, data.value)
        return nuiResult(cb, result)
    end

    cb({ ok = false, message = "Categoria inválida." })
end)

RegisterNUICallback("notify", function(data, cb)
    notify(data and data.kind or "aviso", data and data.message or "Operação inválida.")
    cb({ ok = true })
end)

CreateThread(function()
    while true do
        if shownui then
            DisableControlAction(0, 200, true)
            if IsDisabledControlJustReleased(0, 200) then closePanel() end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- ==========================================================================
-- MEDICAL
-- ==========================================================================
function API.treatment(kind)
    local ped = PlayerPedId()
    local target = kind == "quick" and cfg.table.medic_options[1].quantidade_de_vida or cfg.table.medic_options[2].quantidade_de_vida
    local step = kind == "quick" and 10 or 5
    local delay = kind == "quick" and 1500 or 800

    CreateThread(function()
        while DoesEntityExist(ped) do
            local health = GetEntityHealth(ped)
            if health <= 105 then
                ClearPedTasks(ped)
                return
            end
            if health >= target then
                notify("sucesso", "Tratamento concluído.")
                ClearPedTasks(ped)
                return
            end
            SetEntityHealth(ped, math.min(target, health + step))
            Wait(delay)
        end
    end)
end

function API.removeMask()
    local ped = PlayerPedId()
    SetPedComponentVariation(ped, 1, 0, 0, 2)
end

function API.forceUnarmed()
    -- Keep the custom inventory hotbar state in sync before removing the
    -- physical weapon. This prevents a seized weapon from remaining as the
    -- server-side active weapon after its inventory item was removed.
    if GetResourceState("inventory") == "started" and inventorySERVER then
        inventorySERVER.storeWeapons({})
    end
    local ped = PlayerPedId()
    SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
    RemoveAllPedWeapons(ped, true)
end

-- ==========================================================================
-- VEHICLE HELPERS
-- ==========================================================================
function API.nearestVehicleInfo(radius)
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    local maxDistance = tonumber(radius) or 7.0
    local closest, closestDistance

    for _, vehicle in ipairs(GetGamePool("CVehicle")) do
        if DoesEntityExist(vehicle) then
            local d = #(GetEntityCoords(vehicle) - pcoords)
            if d <= maxDistance and (not closestDistance or d < closestDistance) then
                closest = vehicle
                closestDistance = d
            end
        end
    end

    if not closest then return nil end
    return {
        plate = GetVehicleNumberPlateText(closest),
        vehicle = closest,
        modelHash = GetEntityModel(closest),
        displayName = GetDisplayNameFromVehicleModel(GetEntityModel(closest)),
        distance = closestDistance
    }
end

function API.isFullRepairBlocked(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return true end
    local model = GetEntityModel(vehicle)
    for _, name in ipairs(cfg.blockedFullRepairModels or {}) do
        if model == GetHashKey(name) then return true end
    end
    return false
end

function API.repairVehicle(vehicle, mode)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end
    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(vehicle)) > 7.5 then return false end

    if mode == "engine" then
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleUndriveable(vehicle, false)
    elseif mode == "tires" then
        for i = 0, 7 do SetVehicleTyreFixed(vehicle, i) end
    elseif mode == "full" then
        local fuel = GetVehicleFuelLevel(vehicle)
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehicleDirtLevel(vehicle, 0.0)
        SetVehicleUndriveable(vehicle, false)
        SetVehicleOnGroundProperly(vehicle)
        SetVehicleFuelLevel(vehicle, fuel)
    end
    return true
end

function API.deleteVehicle(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end
    NetworkRequestControlOfEntity(vehicle)
    local timeout = GetGameTimer() + 1000
    while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < timeout do Wait(0) end
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
    if DoesEntityExist(vehicle) then DeleteEntity(vehicle) end
    return not DoesEntityExist(vehicle)
end

-- ==========================================================================
-- 3D POLICE OBJECT PLACEMENT
-- ==========================================================================
local function requestModel(model)
    local hash = type(model) == "number" and model or joaat(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(10)
        RequestModel(hash)
    end
    return HasModelLoaded(hash) and hash or nil
end

local function drawPlacementHelp(label)
    DrawRect(0.5, 0.928, 0.76, 0.052, 8, 11, 17, 190)
    SetTextFont(4)
    SetTextScale(0.32, 0.32)
    SetTextColour(255, 255, 255, 235)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(("~b~%s~s~  |  W/S frente/trás  A/D lados  Q/E girar  PgUp/PgDn altura  G chão  ENTER confirmar  BACKSPACE cancelar"):format(label))
    EndTextCommandDisplayText(0.5, 0.915)
end

local function groundObject(entity, offset)
    PlaceObjectOnGroundProperly(entity)
    if offset and offset ~= 0.0 then
        local c = GetEntityCoords(entity)
        SetEntityCoordsNoOffset(entity, c.x, c.y, c.z + offset, false, false, false)
    end
end

AddEventHandler("m_aux:startPlacement", function(kind)
    if placingObject then return end
    local def = cfg.policeObjects[kind]
    if not def then return end

    local allowed = vSERVER.canPlaceObject(kind)
    if not allowed then
        notify("negado", "Você não possui permissão para posicionar este objeto.")
        return
    end

    local hash = requestModel(def.model)
    if not hash then
        notify("negado", "Não foi possível carregar o objeto.")
        return
    end

    placingObject = true
    local ped = PlayerPedId()
    local initial = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.2, 0.0)
    local entity = CreateObjectNoOffset(hash, initial.x, initial.y, initial.z, false, false, false)
    if entity == 0 then
        placingObject = false
        SetModelAsNoLongerNeeded(hash)
        notify("negado", "Não foi possível criar a prévia do objeto.")
        return
    end

    SetEntityHeading(entity, GetEntityHeading(ped))
    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, false, false)
    SetEntityAlpha(entity, 175, false)
    groundObject(entity, def.groundOffset or 0.0)

    local heading = GetEntityHeading(entity)
    local moveSpeed = 0.035
    local verticalSpeed = 0.025
    local confirmed = false

    while placingObject and DoesEntityExist(entity) do
        Wait(0)
        drawPlacementHelp(def.label or kind)

        for _, control in ipairs({10,11,30,31,32,33,34,35,36,37,44,38,47,172,173,174,175,177,191,200,201,241,242}) do
            DisableControlAction(0, control, true)
        end

        local camHeading = math.rad(GetGameplayCamRot(2).z)
        local forward = vector3(-math.sin(camHeading), math.cos(camHeading), 0.0)
        local right = vector3(math.cos(camHeading), math.sin(camHeading), 0.0)
        local coords = GetEntityCoords(entity)

        local speed = IsControlPressed(0, 21) and moveSpeed * 3.0 or moveSpeed
        if IsDisabledControlPressed(0, 32) then coords = coords + forward * speed end
        if IsDisabledControlPressed(0, 33) then coords = coords - forward * speed end
        if IsDisabledControlPressed(0, 34) then coords = coords - right * speed end
        if IsDisabledControlPressed(0, 35) then coords = coords + right * speed end
        if IsDisabledControlPressed(0, 10) then coords = vector3(coords.x, coords.y, coords.z + verticalSpeed) end
        if IsDisabledControlPressed(0, 11) then coords = vector3(coords.x, coords.y, coords.z - verticalSpeed) end
        if IsDisabledControlPressed(0, 44) then heading = heading + 0.8 end
        if IsDisabledControlPressed(0, 38) then heading = heading - 0.8 end

        SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, false, false, false)
        SetEntityHeading(entity, heading)

        if IsDisabledControlJustPressed(0, 47) then -- G
            groundObject(entity, def.groundOffset or 0.0)
        end

        if IsDisabledControlJustPressed(0, 191) or IsDisabledControlJustPressed(0, 201) then
            local final = GetEntityCoords(entity)
            local distance = #(final - GetEntityCoords(ped))
            if distance > 8.0 then
                notify("negado", "O objeto precisa ficar próximo de você.")
            else
                confirmed = true
                local ok = vSERVER.placeObject(kind, { x = final.x, y = final.y, z = final.z }, heading)
                if not ok then notify("negado", "Não foi possível posicionar o objeto.") end
                placingObject = false
            end
        elseif IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 200) then
            placingObject = false
        end
    end

    if DoesEntityExist(entity) then DeleteEntity(entity) end
    SetModelAsNoLongerNeeded(hash)
    if not confirmed then notify("aviso", "Posicionamento cancelado.", 3000) end
end)

local function createSyncedObject(id, data)
    if spawnedObjects[id] and DoesEntityExist(spawnedObjects[id]) then return end
    if not data or not data.model or not data.coords then return end

    CreateThread(function()
        local hash = requestModel(data.model)
        if not hash then return end
        local c = data.coords
        local obj = CreateObjectNoOffset(hash, c.x + 0.0, c.y + 0.0, c.z + 0.0, false, false, false)
        if obj ~= 0 then
            SetEntityHeading(obj, data.heading + 0.0)
            FreezeEntityPosition(obj, true)
            SetEntityCollision(obj, true, true)
            SetEntityAsMissionEntity(obj, true, false)
            ResetEntityAlpha(obj)
            spawnedObjects[id] = obj
            objectData[id] = data
        end
        SetModelAsNoLongerNeeded(hash)
    end)
end

RegisterNetEvent("m_aux:object:add", function(id, data)
    createSyncedObject(tostring(id), data)
end)

RegisterNetEvent("m_aux:object:remove", function(id)
    id = tostring(id)
    local entity = spawnedObjects[id]
    if entity and DoesEntityExist(entity) then DeleteEntity(entity) end
    spawnedObjects[id] = nil
    objectData[id] = nil
end)

RegisterNetEvent("m_aux:object:clear", function(ids)
    for _, id in ipairs(ids or {}) do
        TriggerEvent("m_aux:object:remove", tostring(id))
    end
end)

CreateThread(function()
    -- Retry a few times because this resource can start before the vRP player
    -- tunnel is fully ready on a fresh connection.
    for _ = 1, 4 do
        Wait(1500)
        local list = vSERVER.getObjects()
        if type(list) == "table" then
            for id, data in pairs(list) do createSyncedObject(tostring(id), data) end
            break
        end
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    for _, entity in pairs(spawnedObjects) do
        if DoesEntityExist(entity) then DeleteEntity(entity) end
    end
end)

-- Spike strips: burst only the wheel that actually touches the strip.
local wheelBones = {
    { "wheel_lf", 0 }, { "wheel_rf", 1 },
    { "wheel_lm1", 2 }, { "wheel_rm1", 3 },
    { "wheel_lr", 4 }, { "wheel_rr", 5 },
    { "wheel_lm2", 4 }, { "wheel_rm2", 5 }
}

CreateThread(function()
    while true do
        local wait = 700
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= 0 and GetEntitySpeed(vehicle) > 0.8 then
            local vcoords = GetEntityCoords(vehicle)
            for id, data in pairs(objectData) do
                if data.kind == "spike" and data.coords then
                    local s = vector3(data.coords.x + 0.0, data.coords.y + 0.0, data.coords.z + 0.0)
                    if #(vcoords - s) <= 5.0 then
                        wait = 80
                        for _, wheel in ipairs(wheelBones) do
                            local bone = GetEntityBoneIndexByName(vehicle, wheel[1])
                            if bone ~= -1 then
                                local wc = GetWorldPositionOfEntityBone(vehicle, bone)
                                local spikeEntity = spawnedObjects[tostring(id)]
                                if spikeEntity and DoesEntityExist(spikeEntity) then
                                    local relative = GetOffsetFromEntityGivenWorldCoords(spikeEntity, wc.x, wc.y, wc.z)
                                    local minDim, maxDim = GetModelDimensions(GetEntityModel(spikeEntity))
                                    local margin = 0.18
                                    -- Use the prop's real local dimensions, so the hitbox follows
                                    -- any rotation chosen by the officer in placement mode.
                                    if relative.x >= minDim.x - margin and relative.x <= maxDim.x + margin
                                        and relative.y >= minDim.y - margin and relative.y <= maxDim.y + margin
                                        and relative.z >= minDim.z - 0.35 and relative.z <= maxDim.z + 0.65 then
                                        local key = tostring(id) .. ":" .. tostring(wheel[2])
                                        local now = GetGameTimer()
                                        if not tyreCooldown[key] or now - tyreCooldown[key] > 1500 then
                                            tyreCooldown[key] = now
                                            SetVehicleTyreBurst(vehicle, wheel[2], true, 1000.0)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        Wait(wait)
    end
end)
