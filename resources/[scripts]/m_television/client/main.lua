local RESOURCE = GetCurrentResourceName()

DEFAULT_URL = ("https://cfx-nui-%s/html/screen.html"):format(RESOURCE)
duiUrl = DEFAULT_URL
duiObj = nil
CURRENT_SCREEN = nil
waitForLoad = false

MTelevisionTxdName = nil
MTelevisionTxnName = nil
local duiSequence = 0
local width = (Config.Dui and Config.Dui.Width) or 1280
local height = (Config.Dui and Config.Dui.Height) or 720
local volume = 0.5
local Locations = Config.Locations or {}
local activeRenderTargetName = nil
local menuOpen = false
local previewTV = nil
local isPlacing = false
local editCam = nil

local function clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function MTelevisionNotify(message, kind)
    local prefix = "TV"
    if kind == "error" then prefix = "TV ~r~ERRO~s~" end
    if kind == "success" then prefix = "TV ~g~OK~s~" end

    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(("~b~%s~s~  %s"):format(prefix, tostring(message or "")))
    EndTextCommandThefeedPostTicker(false, false)
end

RegisterNetEvent("m_television:notify", function(message, kind)
    MTelevisionNotify(message, kind)
end)

function getDuiURL()
    return duiUrl
end

function setDuiURL(url)
    if not duiObj or not url then return end
    duiUrl = url
    SetDuiUrl(duiObj, duiUrl)
end

function SetVolume(coords, model, num)
    volume = clamp(num, 0.0, 1.0)
    SetTelevisionLocal(coords, model, "volume", volume)
end

function GetVolume(dist, range)
    local configured = clamp(volume, 0.0, 1.0)
    range = math.max(tonumber(range) or 20.0, 0.1)
    local attenuation = 1.0 - clamp((tonumber(dist) or range) / range, 0.0, 1.0)
    return math.floor(configured * attenuation * 100.0 + 0.5)
end

local function screenDescriptor(screen)
    if not screen then return nil end
    return { coords = screen.coords, model = screen.model }
end

local function sameScreen(a, b)
    if not a or not b then return false end
    return MTelevisionScreenKey(a.coords, a.model) == MTelevisionScreenKey(b.coords, b.model)
end

function ShowScreen(data)
    if not data or not data.entity or not DoesEntityExist(data.entity) then return end
    if duiObj then return end

    CURRENT_SCREEN = data
    duiUrl = DEFAULT_URL
    waitForLoad = true

    duiSequence = duiSequence + 1
    local txdName = ("m_television_txd_%s"):format(duiSequence)
    local txnName = ("m_television_txn_%s"):format(duiSequence)
    MTelevisionTxdName = txdName
    MTelevisionTxnName = txnName

    local txd = CreateRuntimeTxd(txdName)
    duiObj = CreateDui(DEFAULT_URL, width, height)
    local duiHandle = GetDuiHandle(duiObj)
    CreateRuntimeTextureFromDuiHandle(txd, txnName, duiHandle)

    CreateThread(function()
        local entity = data.entity
        local modelData = Config.Models[data.model]
        if not modelData then return end

        local renderTarget = nil
        if modelData.Target then
            renderTarget = MTelevisionCreateNamedRenderTarget(modelData.Target, data.model)
            activeRenderTargetName = modelData.Target
        end

        while duiObj and CURRENT_SCREEN and sameScreen(CURRENT_SCREEN, data) do
            if DoesEntityExist(entity) then
                if renderTarget then
                    MTelevisionRenderTarget(renderTarget, txdName, txnName)
                else
                    MTelevisionRenderWorldQuad(entity, modelData, txdName, txnName)
                end
            end
            Wait(0)
        end
    end)

    CreateThread(function()
        local modelData = Config.Models[data.model]
        local coords = data.coords
        local range = tonumber(modelData.Range) or 20.0
        local _, localStatus = GetTelevisionLocal(coords, data.model)
        SetVolume(coords, data.model, localStatus and localStatus.volume or modelData.DefaultVolume or 0.5)

        while duiObj and CURRENT_SCREEN and sameScreen(CURRENT_SCREEN, data) do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(coords - playerCoords)
            SendDuiMessage(duiObj, json.encode({
                action = "setVolume",
                data = GetVolume(dist, range)
            }))
            Wait(200)
        end
    end)

    CreateThread(function()
        -- Prefer the screenReady handshake, but never leave the television
        -- blocked if a DUI browser misses the NUI callback. IsDuiAvailable + a
        -- short grace period is a safe fallback for CEF page initialization.
        local timeout = GetGameTimer() + 5000
        while duiObj and not IsDuiAvailable(duiObj) and GetGameTimer() < timeout do Wait(25) end

        local readyTimeout = GetGameTimer() + 2500
        while duiObj and waitForLoad and GetGameTimer() < readyTimeout do Wait(25) end
        if duiObj and waitForLoad then
            Wait(350)
            waitForLoad = false
        end

        if duiObj and CURRENT_SCREEN and sameScreen(CURRENT_SCREEN, data) then
            TriggerServerEvent("m_television:requestSync", screenDescriptor(data))
        end
    end)
end

function HideScreen()
    SetInteractScreen(false)
    CURRENT_SCREEN = nil
    waitForLoad = false

    if duiObj then
        DestroyDui(duiObj)
        duiObj = nil
    end

    if activeRenderTargetName then
        MTelevisionReleaseNamedRenderTarget(activeRenderTargetName)
        activeRenderTargetName = nil
    end

    MTelevisionTxdName = nil
    MTelevisionTxnName = nil
    duiUrl = DEFAULT_URL
end

function GetClosestScreen()
    local objectPool = GetGamePool("CObject")
    local playerCoords = GetEntityCoords(PlayerPedId())
    local closest = nil
    local closestDist = math.huge

    for i = 1, #objectPool do
        local entity = objectPool[i]
        if DoesEntityExist(entity) then
            local model = GetEntityModel(entity)
            local modelData = Config.Models[model]
            if modelData then
                local coords = GetEntityCoords(entity)
                local dist = #(playerCoords - coords)
                local range = tonumber(modelData.Range) or 20.0
                if dist <= range and dist < closestDist then
                    closestDist = dist
                    closest = {
                        dist = dist,
                        coords = coords,
                        model = model,
                        entity = entity
                    }
                end
            end
        end
    end

    return closest
end

local function spawnConfiguredLocation(index)
    local data = Locations[index]
    if not data or data.obj then return end
    if not MTelevisionLoadModel(data.Model) then return end

    local pos = data.Position
    local obj = CreateObjectNoOffset(data.Model, pos.x, pos.y, pos.z, false, false, false)
    if obj and obj ~= 0 then
        SetEntityHeading(obj, pos.w or 0.0)
        FreezeEntityPosition(obj, true)
        SetEntityAsMissionEntity(obj, true, true)
        data.obj = obj
    end
    SetModelAsNoLongerNeeded(data.Model)
end

local function deleteConfiguredLocation(index)
    local data = Locations[index]
    if not data or not data.obj then return end
    if DoesEntityExist(data.obj) then DeleteEntity(data.obj) end
    data.obj = nil
end

CreateThread(function()
    Wait(1500)
    TriggerServerEvent("m_television:requestUpdate")

    while true do
        local data = GetClosestScreen()
        if data and not duiObj then
            ShowScreen(data)
        elseif duiObj and (not data or not sameScreen(CURRENT_SCREEN, data)) then
            HideScreen()
            if data then ShowScreen(data) end
        end

        Wait(data and ((Config.Dui and Config.Dui.ScanInterval) or 1200) or ((Config.Dui and Config.Dui.FarScanInterval) or 2500))
    end
end)

CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        for i = 1, #Locations do
            local data = Locations[i]
            local dist = #(playerCoords - MTelevisionVec3(data.Position))
            if not data.obj and dist < 35.0 then
                spawnConfiguredLocation(i)
            elseif data.obj and dist > 45.0 then
                deleteConfiguredLocation(i)
            end
        end
        Wait(2000)
    end
end)

local function closeControlMenu()
    if not menuOpen then return end
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
end

local function openControlMenu()
    if not CURRENT_SCREEN then return end
    local _, localStatus = GetTelevisionLocal(CURRENT_SCREEN.coords, CURRENT_SCREEN.model)
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openTV",
        channels = GetChannelList(),
        volume = math.floor(((localStatus and localStatus.volume) or volume or 0.5) * 100.0 + 0.5)
    })
end

RegisterNetEvent("m_television:menuPermission", function(allowed, syncedChannels)
    if not allowed then return end
    if type(syncedChannels) == "table" then Channels = syncedChannels end
    openControlMenu()
end)

RegisterNetEvent("m_television:broadcastMenu", function(allowed, index, channel)
    if not allowed then return end
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openBroadcast",
        activeIndex = index,
        activeChannel = channel
    })
end)

RegisterNetEvent("m_television:addTelevisionPermission", function(allowed)
    if not allowed then return end

    local models = {}
    for _, item in ipairs(Config.PlaceableModels or {}) do
        models[#models + 1] = { label = item.label, model = item.model }
    end

    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "openModels", models = models })
end)

RegisterNUICallback("close", function(_, cb)
    closeControlMenu()
    cb({ ok = true })
end)

RegisterNUICallback("screenReady", function(_, cb)
    waitForLoad = false
    cb({ ok = true })
end)

RegisterNUICallback("playMedia", function(data, cb)
    if CURRENT_SCREEN and data and data.url then
        TriggerServerEvent("m_television:setState", screenDescriptor(CURRENT_SCREEN), {
            type = "play",
            url = tostring(data.url)
        })
    end
    closeControlMenu()
    cb({ ok = true })
end)

RegisterNUICallback("openBrowser", function(data, cb)
    if CURRENT_SCREEN and data and data.url then
        TriggerServerEvent("m_television:setState", screenDescriptor(CURRENT_SCREEN), {
            type = "browser",
            url = tostring(data.url)
        })
    end
    closeControlMenu()
    cb({ ok = true })
end)

RegisterNUICallback("selectChannel", function(data, cb)
    if CURRENT_SCREEN and data and tonumber(data.index) then
        SetChannel(tonumber(data.index))
    end
    closeControlMenu()
    cb({ ok = true })
end)

RegisterNUICallback("turnOff", function(_, cb)
    if CURRENT_SCREEN then
        TriggerServerEvent("m_television:setState", screenDescriptor(CURRENT_SCREEN), { type = "off" })
    end
    closeControlMenu()
    cb({ ok = true })
end)

RegisterNUICallback("setVolume", function(data, cb)
    if CURRENT_SCREEN and data then
        SetVolume(CURRENT_SCREEN.coords, CURRENT_SCREEN.model, clamp((tonumber(data.volume) or 50) / 100.0, 0.0, 1.0))
    end
    cb({ ok = true })
end)

RegisterNUICallback("interact", function(_, cb)
    closeControlMenu()
    SetInteractScreen(true)
    cb({ ok = true })
end)

RegisterNUICallback("startBroadcast", function(data, cb)
    if data then
        TriggerServerEvent("m_television:startBroadcast", tostring(data.name or ""), tostring(data.url or ""))
    end
    closeControlMenu()
    cb({ ok = true })
end)

RegisterNUICallback("stopBroadcast", function(_, cb)
    TriggerServerEvent("m_television:stopBroadcast")
    closeControlMenu()
    cb({ ok = true })
end)

RegisterNUICallback("selectModel", function(data, cb)
    local model = data and tonumber(data.model)
    closeControlMenu()
    if model and Config.Models[model] then
        StartTVPlacement(model)
    else
        MTelevisionNotify("Modelo de TV inválido.", "error")
    end
    cb({ ok = true })
end)

RegisterCommand((Config.Commands and Config.Commands.Television) or "tv", function()
    local screen = GetClosestScreen()
    if not screen then
        MTelevisionNotify("Nenhuma televisão encontrada próxima.", "error")
        return
    end

    if not CURRENT_SCREEN or not sameScreen(CURRENT_SCREEN, screen) or not duiObj then
        if duiObj then HideScreen() end
        ShowScreen(screen)
    end
    TriggerServerEvent("m_television:requestMenu", screenDescriptor(screen))
end, false)

RegisterCommand((Config.Commands and Config.Commands.Broadcast) or "broadcast", function()
    TriggerServerEvent("m_television:requestBroadcastMenu")
end, false)

RegisterCommand((Config.Commands and Config.Commands.AddTelevision) or "addtv", function()
    if isPlacing then
        MTelevisionNotify("Você já está posicionando uma televisão.", "error")
        return
    end
    TriggerServerEvent("m_television:requestAddTelevision")
end, false)

local function rotationToDirection(rotation)
    local z = math.rad(rotation.z)
    local x = math.rad(rotation.x)
    local cosX = math.abs(math.cos(x))
    return vector3(-math.sin(z) * cosX, math.cos(z) * cosX, math.sin(x))
end

local function rightFromRotation(rotation)
    local z = math.rad(rotation.z + 90.0)
    return vector3(-math.sin(z), math.cos(z), 0.0)
end

local function createEditCamera()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    editCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(editCam, coords.x, coords.y, coords.z + 1.0)
    SetCamRot(editCam, 0.0, 0.0, GetEntityHeading(ped), 2)
    SetCamActive(editCam, true)
    RenderScriptCams(true, false, 0, true, true)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)
end

local function destroyEditCamera()
    if editCam then
        SetCamActive(editCam, false)
        DestroyCam(editCam, true)
        RenderScriptCams(false, false, 0, true, true)
        editCam = nil
    end

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
end

local function finishPlacement(cancelled)
    if previewTV and DoesEntityExist(previewTV) then DeleteEntity(previewTV) end
    previewTV = nil
    isPlacing = false
    destroyEditCamera()
    if cancelled then MTelevisionNotify("Colocação de TV cancelada.", "info") end
end

function StartTVPlacement(modelHash)
    if isPlacing then return end
    if not Config.Models[modelHash] then
        MTelevisionNotify("Modelo não configurado no m_television.", "error")
        return
    end
    if not MTelevisionLoadModel(modelHash) then
        MTelevisionNotify("Não foi possível carregar este modelo.", "error")
        return
    end

    isPlacing = true
    createEditCamera()

    local coords = GetEntityCoords(PlayerPedId())
    previewTV = CreateObjectNoOffset(modelHash, coords.x, coords.y, coords.z, false, false, false)
    if not previewTV or previewTV == 0 then
        finishPlacement(true)
        return
    end

    SetEntityAlpha(previewTV, 210, false)
    FreezeEntityPosition(previewTV, true)
    SetEntityCollision(previewTV, false, false)
    SetModelAsNoLongerNeeded(modelHash)

    CreateThread(function()
        local camSpeed = 0.16
        local preciseSpeed = 0.04
        local rotationOffset = 0.0
        local rotationSpeed = 5.0

        while isPlacing and previewTV and DoesEntityExist(previewTV) and editCam do
            DisableAllControlActions(0)

            local camCoords = GetCamCoord(editCam)
            local camRot = GetCamRot(editCam, 2)
            local moveSpeed = IsDisabledControlPressed(0, 19) and preciseSpeed or camSpeed
            local forward = rotationToDirection(vector3(0.0, 0.0, camRot.z))
            local right = rightFromRotation(camRot)

            if IsDisabledControlPressed(0, 32) then camCoords = camCoords + (forward * moveSpeed) end
            if IsDisabledControlPressed(0, 33) then camCoords = camCoords - (forward * moveSpeed) end
            if IsDisabledControlPressed(0, 34) then camCoords = camCoords - (right * moveSpeed) end
            if IsDisabledControlPressed(0, 35) then camCoords = camCoords + (right * moveSpeed) end
            if IsDisabledControlPressed(0, 10) then camCoords = camCoords + vector3(0.0, 0.0, moveSpeed) end
            if IsDisabledControlPressed(0, 11) then camCoords = camCoords - vector3(0.0, 0.0, moveSpeed) end
            SetCamCoord(editCam, camCoords.x, camCoords.y, camCoords.z)

            if IsDisabledControlPressed(0, 19) then
                if IsDisabledControlJustPressed(0, 15) then rotationOffset = rotationOffset + rotationSpeed end
                if IsDisabledControlJustPressed(0, 14) then rotationOffset = rotationOffset - rotationSpeed end
            end

            local mouseX = GetDisabledControlNormal(1, 1) * 3.0
            local mouseY = GetDisabledControlNormal(1, 2) * 3.0
            if mouseX ~= 0.0 or mouseY ~= 0.0 then
                local newX = clamp(camRot.x - mouseY, -85.0, 85.0)
                local newZ = camRot.z - mouseX
                SetCamRot(editCam, newX, 0.0, newZ, 2)
                camRot = vector3(newX, 0.0, newZ)
            end

            local direction = rotationToDirection(camRot)
            local rayEnd = camCoords + (direction * 100.0)
            local ray = StartExpensiveSynchronousShapeTestLosProbe(
                camCoords.x, camCoords.y, camCoords.z,
                rayEnd.x, rayEnd.y, rayEnd.z,
                -1, previewTV, 7
            )
            local _, hit, endCoords = GetShapeTestResult(ray)

            if hit == 1 then
                local targetPos = endCoords - (direction * 0.12)
                SetEntityCoordsNoOffset(previewTV, targetPos.x, targetPos.y, targetPos.z, false, false, false)

                local dx = camCoords.x - targetPos.x
                local dy = camCoords.y - targetPos.y
                local heading = GetHeadingFromVector_2d(dx, dy) - 90.0 + rotationOffset
                SetEntityHeading(previewTV, heading)
            end

            DrawTxt(0.5, 0.055, "W/A/S/D mover câmera  |  Page Up/Down altura  |  Mouse mirar  |  ALT + Scroll girar TV  |  ENTER confirmar  |  BACKSPACE cancelar")

            if IsDisabledControlJustPressed(0, 18) then
                local finalPos = GetEntityCoords(previewTV)
                local finalHeading = GetEntityHeading(previewTV)
                local archetype = GetEntityArchetypeName(previewTV)
                local configText = string.format(
                    "{\n    Model = `%s`,\n    Position = vector4(%.4f, %.4f, %.4f, %.2f),\n},",
                    archetype, finalPos.x, finalPos.y, finalPos.z, finalHeading
                )

                SendNUIMessage({ action = "copyText", text = configText })
                MTelevisionNotify("Configuração copiada. Cole em Config.Locations.", "success")
                print(("[m_television] Nova TV:\n%s"):format(configText))
                finishPlacement(false)
                break
            end

            if IsDisabledControlJustPressed(0, 177) then
                finishPlacement(true)
                break
            end

            Wait(0)
        end
    end)
end

function DrawTxt(x, y, text)
    SetTextFont(0)
    SetTextProportional(true)
    SetTextScale(0.0, 0.35)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(true)
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

AddEventHandler("onResourceStop", function(name)
    if name ~= RESOURCE then return end

    closeControlMenu()
    HideScreen()
    if isPlacing then finishPlacement(true) end

    for i = 1, #Locations do
        deleteConfiguredLocation(i)
    end
end)
