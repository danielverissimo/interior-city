-- Lixeiro - cliente
-- Coleta cooperativa, marcação dos lixos e posições traseiras do caminhão.

local onjob = false
local carryingTrash = false
local carriedTrashProp = nil
local carriedTrashKey = nil
local carriedTrashEntity = nil
local HashKeyBox = 600967813
local TRASH_VEHICLE_MODEL = GetHashKey("trash")

local fallbackTrashModels = {
    1388308576,
    1948359883,
    897494494,
    1098827230,
    -1681329307
}

local trashModels = {}
local trashModelSet = {}
local trashBlips = {}
local collectedTrashKeys = {}
local rearRide = nil
local rearExitNotifyAt = 0

-- Altura do trabalhador preso na traseira do caminhão.
-- Aumente este valor para subir o player; diminua para baixar.
-- É aplicado sobre a base inferior do modelo do caminhão.
local REAR_RIDE_HEIGHT_OFFSET = 0.95

local function roundHalf(value)
    value = tonumber(value) or 0.0
    if value >= 0 then
        return math.floor((value * 2.0) + 0.5) / 2.0
    end
    return math.ceil((value * 2.0) - 0.5) / 2.0
end

local function makeTrashKey(coords)
    return ("%.1f:%.1f:%.1f"):format(
        roundHalf(coords.x),
        roundHalf(coords.y),
        roundHalf(coords.z)
    )
end

local function refreshTrashModels()
    trashModels = {}
    trashModelSet = {}

    local configured = cfg.extra and cfg.extra["Lixeiro"] and cfg.extra["Lixeiro"].modelos_lixo
    if type(configured) == "table" and #configured > 0 then
        for _, value in pairs(configured) do
            local hash = tonumber(value)
            if hash and not trashModelSet[hash] then
                trashModelSet[hash] = true
                trashModels[#trashModels + 1] = hash
            end
        end
    end

    if #trashModels == 0 then
        for _, hash in ipairs(fallbackTrashModels) do
            trashModelSet[hash] = true
            trashModels[#trashModels + 1] = hash
        end
    end
end

refreshTrashModels()

local function removeTrashBlip(key)
    local blip = trashBlips[key]
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
    trashBlips[key] = nil
end

local function clearTrashBlips()
    for key, blip in pairs(trashBlips) do
        if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
        trashBlips[key] = nil
    end
end

local function addTrashBlip(coords)
    local key = makeTrashKey(coords)
    if collectedTrashKeys[key] or trashBlips[key] then return end
    if math.abs(coords.x) < 1.0 and math.abs(coords.y) < 1.0 then return end

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 2)
    SetBlipScale(blip, 0.28)
    SetBlipAlpha(blip, 185)
    SetBlipAsShortRange(blip, false)
    SetBlipDisplay(blip, 4)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Lixo para coleta")
    EndTextCommandSetBlipName(blip)
    trashBlips[key] = blip
end

local function scanLoadedTrash()
    if not onjob then return end

    local objects = GetGamePool("CObject")
    for _, object in ipairs(objects) do
        if DoesEntityExist(object) and trashModelSet[GetEntityModel(object)] then
            local coords = GetEntityCoords(object)
            addTrashBlip(coords)
        end
    end
end

local function clearCarriedTrash()
    carryingTrash = false
    carriedTrashKey = nil
    carriedTrashEntity = nil

    if carriedTrashProp and DoesEntityExist(carriedTrashProp) then
        DetachEntity(carriedTrashProp, true, true)
        DeleteEntity(carriedTrashProp)
    end
    carriedTrashProp = nil

    local ped = PlayerPedId()
    StopAnimTask(ped, "missfbi4prepp1", "_bag_walk_garbage_man", 1.0)
end

local function createCarriedTrashProp()
    if carriedTrashProp and DoesEntityExist(carriedTrashProp) then return end

    RequestModel(HashKeyBox)
    local deadline = GetGameTimer() + 3000
    while not HasModelLoaded(HashKeyBox) and GetGameTimer() < deadline do
        Wait(0)
    end
    if not HasModelLoaded(HashKeyBox) then return end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    carriedTrashProp = CreateObject(HashKeyBox, coords.x, coords.y, coords.z, true, true, false)
    AttachEntityToEntity(
        carriedTrashProp,
        ped,
        GetPedBoneIndex(ped, 0x6F06),
        0.00, 0.0, -0.70,
        0.0, 0.0, 0.0,
        true, true, false, true, 1, true
    )
    SetModelAsNoLongerNeeded(HashKeyBox)
end

local function startCarryAnimation()
    RequestAnimDict("missfbi4prepp1")
    while not HasAnimDictLoaded("missfbi4prepp1") do Wait(0) end
    TaskPlayAnim(PlayerPedId(), "missfbi4prepp1", "_bag_walk_garbage_man", 8.0, -8.0, -1, 49, 0.0, false, false, false)
end

local function playerServerIdFromPed(ped)
    if not ped or ped == 0 or not IsPedAPlayer(ped) then return nil end
    local player = NetworkGetPlayerIndexFromPed(ped)
    if player == -1 then return nil end
    return GetPlayerServerId(player)
end

local function getNearestTrashVehicle(radius)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closest, closestDistance = 0, tonumber(radius) or 10.0

    for _, vehicle in ipairs(GetGamePool("CVehicle")) do
        if DoesEntityExist(vehicle) and GetEntityModel(vehicle) == TRASH_VEHICLE_MODEL then
            local distance = #(coords - GetEntityCoords(vehicle))
            if distance < closestDistance then
                closest = vehicle
                closestDistance = distance
            end
        end
    end

    return closest, closestDistance
end

local function rearMountOffset(vehicle, slot)
    local minDim, maxDim = GetModelDimensions(GetEntityModel(vehicle))
    local halfWidth = math.max(math.abs(minDim.x), math.abs(maxDim.x))
    local x = (slot == 1 and -1 or 1) * math.max(0.60, halfWidth * 0.62)
    local y = minDim.y + 0.35
    local z = minDim.z + REAR_RIDE_HEIGHT_OFFSET
    return x, y, z
end

local function detachRearRide(notifyServer)
    if not rearRide then return end

    local ped = PlayerPedId()
    local vehicle = rearRide.vehicle
    local slot = rearRide.slot

    DetachEntity(ped, true, true)
    SetEntityCollision(ped, true, true)
    SetPedCanRagdoll(ped, true)
    ClearPedTasksImmediately(ped)

    if vehicle and DoesEntityExist(vehicle) then
        local x, y, _ = rearMountOffset(vehicle, slot)
        local out = GetOffsetFromEntityInWorldCoords(vehicle, x * 1.55, y - 0.65, 0.0)
        SetEntityCoordsNoOffset(ped, out.x, out.y, out.z + 0.15, false, false, false)
    end

    rearRide = nil
    if notifyServer then
        vSERVER.lixeiroReleaseRearRide()
    end
end

local function attachRearRide(vehicle, slot)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end

    local ped = PlayerPedId()
    local x, y, z = rearMountOffset(vehicle, slot)

    ClearPedTasksImmediately(ped)
    SetPedCanRagdoll(ped, false)
    SetEntityCollision(ped, false, false)
    AttachEntityToEntity(ped, vehicle, 0, x, y, z, 0.0, 0.0, 0.0, false, false, false, true, 2, true)

    RequestAnimDict("anim@heists@box_carry@")
    local deadline = GetGameTimer() + 2000
    while not HasAnimDictLoaded("anim@heists@box_carry@") and GetGameTimer() < deadline do Wait(0) end
    if HasAnimDictLoaded("anim@heists@box_carry@") then
        TaskPlayAnim(ped, "anim@heists@box_carry@", "idle", 4.0, -4.0, -1, 49, 0.0, false, false, false)
    end

    rearRide = {
        vehicle = vehicle,
        netId = NetworkGetNetworkIdFromEntity(vehicle),
        slot = slot
    }
    return true
end

RegisterNetEvent("m_empregos:lixeiroTrashCollected")
AddEventHandler("m_empregos:lixeiroTrashCollected", function(key, point, model)
    key = tostring(key or "")
    if key ~= "" then
        collectedTrashKeys[key] = true
        removeTrashBlip(key)
    end

    if type(point) == "table" and tonumber(model) and trashModelSet[tonumber(model)] then
        local x = tonumber(point.x or point[1])
        local y = tonumber(point.y or point[2])
        local z = tonumber(point.z or point[3])
        if x and y and z then
            local object = GetClosestObjectOfType(x, y, z, 1.75, tonumber(model), false, false, false)
            if object and object ~= 0 and DoesEntityExist(object) then
                SetEntityVisible(object, false, false)
                SetEntityCollision(object, false, false)
                SetEntityCoordsNoOffset(object, 0.0, 0.0, -100.0, false, false, false)
            end
        end
    end
end)

RegisterNetEvent("m_empregos:lixeiroForceRearDetach")
AddEventHandler("m_empregos:lixeiroForceRearDetach", function()
    detachRearRide(false)
end)

RegisterNetEvent("m_empregos:clientConfigUpdated")
AddEventHandler("m_empregos:clientConfigUpdated", function()
    refreshTrashModels()
    if onjob then
        clearTrashBlips()
        scanLoadedTrash()
    end
end)

-- Descobre os objetos de lixo que o mapa já carregou no client e mantém pequenos pontos no mapa.
-- Conforme o jogador percorre a cidade, novos lixos carregados são descobertos e permanecem marcados.
CreateThread(function()
    while true do
        if onjob then
            scanLoadedTrash()
            Wait(2500)
        else
            Wait(1000)
        end
    end
end)

-- Interação com os objetos de lixo.
CreateThread(function()
    while true do
        local sleep = 700

        if onjob and not carryingTrash and not rearRide then
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)
            local closestObject = 0
            local closestDistance = 2.2

            for _, model in ipairs(trashModels) do
                local object = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 2.2, model, false, false, false)
                if object and object ~= 0 and DoesEntityExist(object) then
                    local objectCoords = GetEntityCoords(object)
                    local key = makeTrashKey(objectCoords)
                    if not collectedTrashKeys[key] then
                        local distance = #(playerCoords - objectCoords)
                        if distance < closestDistance then
                            closestDistance = distance
                            closestObject = object
                        end
                    end
                end
            end

            if closestObject ~= 0 and closestDistance < 1.55 then
                sleep = 0
                drawTxtLX("PRESSIONE ~g~E~s~ PARA COLETAR O LIXO", 1, 1, 0.5, 0.8, 0.6, 255, 255, 255, 255)

                if IsControlJustPressed(0, 38) then
                    local objectCoords = GetEntityCoords(closestObject)
                    local model = GetEntityModel(closestObject)
                    local result = vSERVER.lixeiroClaimTrash({ x = objectCoords.x, y = objectCoords.y, z = objectCoords.z }, model)

                    if result and result.ok then
                        RequestAnimDict("missfbi4prepp1")
                        while not HasAnimDictLoaded("missfbi4prepp1") do Wait(0) end
                        TaskPlayAnim(ped, "missfbi4prepp1", "_bag_pickup_garbage_man", 1.0, -1.0, 1200, 50, 0.0, false, false, false)
                        Wait(900)

                        carriedTrashKey = tostring(result.key or makeTrashKey(objectCoords))
                        carriedTrashEntity = closestObject
                        carryingTrash = true
                        collectedTrashKeys[carriedTrashKey] = true
                        removeTrashBlip(carriedTrashKey)

                        if DoesEntityExist(closestObject) then
                            SetEntityVisible(closestObject, false, false)
                            SetEntityCollision(closestObject, false, false)
                            SetEntityCoordsNoOffset(closestObject, 0.0, 0.0, -100.0, false, false, false)
                        end

                        createCarriedTrashProp()
                        startCarryAnimation()
                    elseif result and result.message then
                        TriggerEvent("Notify", "negado", result.message, 5)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- Traseira do caminhão: guardar lixo ou subir como ajudante.
CreateThread(function()
    while true do
        local sleep = 700

        if onjob and not rearRide then
            local ped = PlayerPedId()
            local vehicle = getNearestTrashVehicle(12.0)

            if vehicle and vehicle ~= 0 then
                local rearCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -3.75, 0.0)
                local distance = #(GetEntityCoords(ped) - rearCoords)

                if distance <= 2.2 then
                    sleep = 0

                    if carryingTrash then
                        drawTxtLX("PRESSIONE ~g~E~s~ PARA GUARDAR O LIXO", 1, 1, 0.5, 0.8, 0.6, 255, 255, 255, 255)

                        if IsControlJustPressed(0, 38) then
                            local driverPed = GetPedInVehicleSeat(vehicle, -1)
                            local driverSource = playerServerIdFromPed(driverPed)
                            local netId = NetworkGetNetworkIdFromEntity(vehicle)
                            local result = vSERVER.lixeiroDepositTrash(netId, driverSource)

                            if result and result.ok then
                                SetVehicleDoorOpen(vehicle, 5, false, false)
                                clearCarriedTrash()

                                RequestAnimDict("missfbi4prepp1")
                                while not HasAnimDictLoaded("missfbi4prepp1") do Wait(0) end
                                TaskPlayAnim(ped, "missfbi4prepp1", "_bag_throw_garbage_man", 8.0, -8.0, 1600, 48, 0.0, false, false, false)
                                Wait(1350)
                                StopAnimTask(ped, "missfbi4prepp1", "_bag_throw_garbage_man", 1.0)
                                SetVehicleDoorsShut(vehicle, false)
                            elseif result and result.message then
                                TriggerEvent("Notify", "negado", result.message, 5)
                            end
                        end
                    else
                        local driverPed = GetPedInVehicleSeat(vehicle, -1)
                        local driverSource = playerServerIdFromPed(driverPed)

                        if driverSource and driverPed ~= ped and GetEntitySpeed(vehicle) <= 1.5 then
                            drawTxtLX("PRESSIONE ~g~E~s~ PARA SUBIR NA TRASEIRA DO CAMINHÃO", 1, 1, 0.5, 0.8, 0.52, 255, 255, 255, 255)

                            if IsControlJustPressed(0, 38) then
                                local result = vSERVER.lixeiroRequestRearRide(NetworkGetNetworkIdFromEntity(vehicle), driverSource)
                                if result and result.ok and tonumber(result.slot) then
                                    attachRearRide(vehicle, tonumber(result.slot))
                                elseif result and result.message then
                                    TriggerEvent("Notify", "negado", result.message, 5)
                                end
                            end
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- Mantém o player preso com segurança à traseira e permite descer somente com o caminhão devagar.
CreateThread(function()
    while true do
        if rearRide then
            Wait(0)
            local ped = PlayerPedId()
            local vehicle = rearRide.vehicle

            if not onjob or IsEntityDead(ped) or not vehicle or not DoesEntityExist(vehicle) then
                detachRearRide(true)
            else
                DisableControlAction(0, 21, true) -- sprint
                DisableControlAction(0, 22, true) -- pulo
                DisableControlAction(0, 23, true) -- entrar em veículo
                DisableControlAction(0, 75, true) -- sair de veículo
                DisableControlAction(0, 24, true) -- ataque
                DisableControlAction(0, 25, true) -- mira

                if not IsEntityAttachedToEntity(ped, vehicle) then
                    local x, y, z = rearMountOffset(vehicle, rearRide.slot)
                    AttachEntityToEntity(ped, vehicle, 0, x, y, z, 0.0, 0.0, 0.0, false, false, false, true, 2, true)
                end

                if not IsEntityPlayingAnim(ped, "anim@heists@box_carry@", "idle", 3) then
                    RequestAnimDict("anim@heists@box_carry@")
                    if HasAnimDictLoaded("anim@heists@box_carry@") then
                        TaskPlayAnim(ped, "anim@heists@box_carry@", "idle", 4.0, -4.0, -1, 49, 0.0, false, false, false)
                    end
                end

                drawTxtLXX("~y~E ~w~PARA DESCER DA TRASEIRA", 4, 0.5, 0.875, 0.40, 255, 255, 255, 220)

                if IsControlJustPressed(0, 38) then
                    if GetEntitySpeed(vehicle) <= 1.5 then
                        detachRearRide(true)
                    elseif GetGameTimer() > rearExitNotifyAt then
                        rearExitNotifyAt = GetGameTimer() + 2500
                        TriggerEvent("Notify", "aviso", "Aguarde o caminhão reduzir a velocidade para descer com segurança.", 4)
                    end
                end
            end
        else
            Wait(500)
        end
    end
end)

-- Ponto de início/fim do serviço.
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)
        local start = cfg.list["Lixeiro"] and cfg.list["Lixeiro"].inicio

        if start then
            local distance = #(playerCoords - vector3(start[1], start[2], start[3]))

            if distance < 10.0 then
                sleep = 0
                DrawText3D(start[1], start[2], start[3], "Bem-Vindo a Central de Lixeiro\n")
                DrawMarker(27, start[1], start[2], start[3] - 0.97, 0,0,0,0,0,0, 8.0,8.0,1.0, 40,34,213,200, 0,0,0,0)
                DrawMarker(39, start[1], start[2], start[3] - 0.50, 0,0,0,0.0,0,0, 0.8,0.8,0.8, 40,34,213,200, 0,0,0,1)
            end

            if distance < 2.0 then
                sleep = 0
                if not onjob then
                    if IsControlJustReleased(0, 38) and vSERVER.checkEmp('Lixeiro') then
                        if MageJobsBeginService("Lixeiro") then
                            onjob = true
                            refreshTrashModels()
                            scanLoadedTrash()
                            TriggerEvent("Notify", "sucesso", "Você entrou em serviço! Os lixos carregados no mapa foram marcados. Pegue o caminhão na garagem.", 7)
                        end
                    end
                else
                    drawTxtLX("PRESSIONE ~g~E~s~ PARA SAIR DE SERVIÇO", 1, 1, 0.5, 0.8, 0.6, 255, 255, 255, 255)
                    if IsControlJustReleased(0, 38) then
                        local ended = MageJobsEndService("Lixeiro")
                        if ended then
                            detachRearRide(false)
                            clearCarriedTrash()
                            clearTrashBlips()
                            onjob = false
                            TriggerEvent("Notify", "aviso", "Expediente encerrado. O veículo de serviço será devolvido em 30 segundos.", 7)
                            SetWaypointOff()
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        if onjob then
            Wait(0)
            drawTxtLXX("~y~Siga coletando o~r~ LIXO ~w~ espalhado pela cidade", 4, 0.270, 0.905, 0.45, 255,255,255,200)
            drawTxtLXX("~w~Volte ao local de serviço para ~y~Finalizar ~w~ o trabalho", 4, 0.270, 0.93, 0.45, 255,255,255,200)
        else
            Wait(1000)
        end
    end
end)

function drawTxtLX(text, font, centre, x, y, scale, r, g, b, a)
    SetTextFont(6)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(centre)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

function drawTxtLXX(text, font, x, y, scale, r, g, b, a)
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextOutline()
    SetTextCentre(1)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    detachRearRide(true)
    clearCarriedTrash()
    clearTrashBlips()
end)
