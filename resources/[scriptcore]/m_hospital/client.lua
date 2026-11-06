local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

local vRP = Proxy.getInterface("vRP")
local emP = Tunnel.getInterface("emp_hospital")
local HospitalAPI = Tunnel.getInterface("m_hospital")

local DiagnosisClient = {}
Tunnel.bindInterface("m_hospital", DiagnosisClient)

local panelOpen = false
local activePanelKey = nil

-- ==========================================================================
-- Painéis de gestão: Hospital + Sport Racer + LS Customs
-- ==========================================================================
local function closeManagementPanel()
    if not panelOpen then return end

    panelOpen = false
    activePanelKey = nil

    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
end

local function openManagementPanel(panelKey)
    local data = panelKey and HospitalAPI.getPanelData(panelKey) or HospitalAPI.getMechanicPanelData()

    if type(data) ~= "table" or data.ok ~= true then
        TriggerEvent(
            "Notify",
            "negado",
            (type(data) == "table" and data.message) or "Não foi possível abrir o painel."
        )
        return
    end

    -- Chave devolvida e validada pelo servidor; nunca confiar em escolha da NUI.
    activePanelKey = data.panel.key
    panelOpen = true

    SetNuiFocus(true, true)
    SendNUIMessage({ action = "open", data = data })
end

local function registerPanelCommand(panelKey, command)
    command = tostring(command or "")
    if command == "" then return end

    RegisterCommand(command, function()
        openManagementPanel(panelKey)
    end)
end

for panelKey, cfg in pairs(HospitalConfig.Panels or {}) do
    registerPanelCommand(panelKey, cfg.command)

    for _, alias in ipairs(cfg.aliases or {}) do
        registerPanelCommand(panelKey, alias)
    end
end

-- O único comando da mecânica identifica a organização do jogador no servidor.
-- Os comandos antigos /mecanica e /sportracer não são registrados.
RegisterCommand("mec", function()
    openManagementPanel(nil)
end)

RegisterNUICallback("close", function(_, cb)
    closeManagementPanel()
    cb({ ok = true })
end)

RegisterNUICallback("refresh", function(_, cb)
    if not activePanelKey then
        return cb({ ok = false, message = "Painel não identificado." })
    end

    cb(HospitalAPI.getPanelData(activePanelKey))
end)

RegisterNUICallback("hire", function(data, cb)
    if not activePanelKey then
        return cb({ ok = false, message = "Painel não identificado." })
    end

    cb(HospitalAPI.hire(activePanelKey, tonumber(data and data.id)))
end)

RegisterNUICallback("promote", function(data, cb)
    if not activePanelKey then
        return cb({ ok = false, message = "Painel não identificado." })
    end

    cb(HospitalAPI.promote(activePanelKey, tonumber(data and data.id)))
end)

RegisterNUICallback("dismiss", function(data, cb)
    if not activePanelKey then
        return cb({ ok = false, message = "Painel não identificado." })
    end

    cb(HospitalAPI.dismiss(activePanelKey, tonumber(data and data.id)))
end)

RegisterNetEvent("m_hospital:refreshPanel")
AddEventHandler("m_hospital:refreshPanel", function(panelKey)
    if not panelOpen or not activePanelKey then return end
    if panelKey and tostring(panelKey) ~= tostring(activePanelKey) then return end

    local data = HospitalAPI.getPanelData(activePanelKey)

    if data and data.ok then
        SendNUIMessage({ action = "update", data = data })
    else
        closeManagementPanel()
    end
end)


-- ==========================================================================
-- DIAGNÓSTICO MÉDICO
-- ==========================================================================
local diagnosisOpen = false
local diagnosisBusy = false
local diagnosisSessionId = nil
local diagnosisTargetServerId = nil
local diagnosisTablet = nil

local function diagnosisNotify(kind, message, time)
    TriggerEvent("Notify", kind or "aviso", tostring(message or ""), time or 5000)
end

local function requestDiagnosisModel(model)
    local hash = type(model) == "number" and model or GetHashKey(tostring(model))
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return nil
    end

    RequestModel(hash)
    local deadline = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < deadline do
        Wait(10)
    end

    return HasModelLoaded(hash) and hash or nil
end

local function requestDiagnosisAnim(dict)
    if not dict or dict == "" then return false end
    RequestAnimDict(dict)
    local deadline = GetGameTimer() + 4000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < deadline do
        Wait(10)
    end
    return HasAnimDictLoaded(dict)
end

local function faceDiagnosisTarget(serverId)
    local ped = PlayerPedId()
    local player = GetPlayerFromServerId(tonumber(serverId) or -1)
    if player == -1 then return false end

    local targetPed = GetPlayerPed(player)
    if targetPed == 0 or not DoesEntityExist(targetPed) then return false end

    local a = GetEntityCoords(ped)
    local b = GetEntityCoords(targetPed)
    SetEntityHeading(ped, GetHeadingFromVector_2d(b.x - a.x, b.y - a.y) + 0.0)
    return true
end

local function deleteDiagnosisTablet()
    if diagnosisTablet and DoesEntityExist(diagnosisTablet) then
        DetachEntity(diagnosisTablet, true, true)
        DeleteEntity(diagnosisTablet)
    end
    diagnosisTablet = nil
end

local function createDiagnosisTablet()
    deleteDiagnosisTablet()

    local cfg = HospitalConfig.Diagnosis or {}
    local tablet = cfg.tablet or {}
    local hash = requestDiagnosisModel(tablet.model or "prop_cs_tablet")
    if not hash then return false end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local object = CreateObject(hash, coords.x, coords.y, coords.z + 0.2, false, false, false)
    if not object or object == 0 then
        SetModelAsNoLongerNeeded(hash)
        return false
    end

    local pos = tablet.position or {}
    local rot = tablet.rotation or {}
    AttachEntityToEntity(
        object,
        ped,
        GetPedBoneIndex(ped, tonumber(tablet.bone) or 28422),
        tonumber(pos.x) or 0.0,
        tonumber(pos.y) or -0.03,
        tonumber(pos.z) or 0.0,
        tonumber(rot.x) or 20.0,
        tonumber(rot.y) or -90.0,
        tonumber(rot.z) or 0.0,
        true, true, false, true, 1, true
    )

    diagnosisTablet = object
    SetModelAsNoLongerNeeded(hash)

    local animation = tablet.animation or {}
    if requestDiagnosisAnim(animation.dict) then
        TaskPlayAnim(
            ped,
            animation.dict,
            animation.anim or "base",
            4.0, -4.0, -1,
            tonumber(animation.flag) or 49,
            0.0, false, false, false
        )
    end

    return true
end

local function stopDiagnosisVisuals(sendCloseMessage)
    diagnosisOpen = false
    diagnosisBusy = false

    if sendCloseMessage ~= false then
        SendNUIMessage({ action = "diagnosis:close" })
    end

    SetNuiFocus(false, false)

    local ped = PlayerPedId()
    if ped ~= 0 and DoesEntityExist(ped) then
        FreezeEntityPosition(ped, false)
        ClearPedTasks(ped)
    end

    deleteDiagnosisTablet()
    diagnosisSessionId = nil
    diagnosisTargetServerId = nil
end

function DiagnosisClient.getHealthSnapshot()
    local ped = PlayerPedId()
    if ped == 0 or not DoesEntityExist(ped) then
        return {
            current = 0,
            maximum = 0,
            percent = 0
        }
    end

    local current = tonumber(GetEntityHealth(ped)) or 0
    local maximum = tonumber(GetEntityMaxHealth(ped)) or 300

    if maximum <= 100 then
        maximum = 300
    end

    local percent = 0.0
    if current > 100 then
        percent = ((current - 100) / math.max(1, maximum - 100)) * 100.0
    end

    percent = math.max(0.0, math.min(100.0, percent))

    return {
        current = current,
        maximum = maximum,
        percent = percent
    }
end

RegisterNetEvent("m_hospital:diagnosis:start")
AddEventHandler("m_hospital:diagnosis:start", function()
    if diagnosisBusy or diagnosisOpen then
        diagnosisNotify("aviso", "Você já está realizando um diagnóstico.")
        return
    end

    diagnosisBusy = true

    local result = HospitalAPI.startDiagnosis()
    if type(result) ~= "table" or result.ok ~= true then
        diagnosisBusy = false
        diagnosisNotify("negado", type(result) == "table" and result.message or "Não foi possível iniciar o diagnóstico.", 6000)
        return
    end

    diagnosisSessionId = result.sessionId
    diagnosisTargetServerId = result.targetServerId

    local ped = PlayerPedId()
    faceDiagnosisTarget(diagnosisTargetServerId)
    FreezeEntityPosition(ped, true)

    local cfg = HospitalConfig.Diagnosis or {}
    local scenario = tostring(cfg.thinkingScenario or "WORLD_HUMAN_STAND_IMPATIENT")
    TaskStartScenarioInPlace(ped, scenario, 0, true)

    local thinkSeconds = math.max(1, math.floor(tonumber(result.thinkSeconds) or tonumber(cfg.thinkSeconds) or 5))
    TriggerEvent("progress", thinkSeconds, "Analisando Paciente")

    CreateThread(function()
        Wait(thinkSeconds * 1000)

        if not diagnosisBusy or not diagnosisSessionId then return end

        ClearPedTasks(ped)
        faceDiagnosisTarget(diagnosisTargetServerId)

        local completed = HospitalAPI.completeDiagnosis(diagnosisSessionId)
        if type(completed) ~= "table" or completed.ok ~= true then
            local message = type(completed) == "table" and completed.message or "O diagnóstico foi interrompido."
            stopDiagnosisVisuals(true)
            diagnosisNotify("negado", message, 6500)
            return
        end

        createDiagnosisTablet()

        diagnosisBusy = false
        diagnosisOpen = true
        SetNuiFocus(true, true)

        SendNUIMessage({
            action = "diagnosis:open",
            data = completed.data or {}
        })
    end)
end)

RegisterNUICallback("diagnosisClose", function(_, cb)
    if diagnosisSessionId then
        HospitalAPI.closeDiagnosis(diagnosisSessionId)
    end

    stopDiagnosisVisuals(true)
    cb({ ok = true })
end)

RegisterNUICallback("diagnosisMedicate", function(data, cb)
    if not diagnosisOpen or not diagnosisSessionId then
        return cb({ ok = false, message = "Nenhum diagnóstico está aberto." })
    end

    local result = HospitalAPI.medicateDiagnosis(diagnosisSessionId)
    if type(result) ~= "table" then
        result = { ok = result == true }
    end

    if result.ok == true then
        stopDiagnosisVisuals(true)
    end

    cb(result)
end)

CreateThread(function()
    while true do
        if diagnosisOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 32, true)
            DisableControlAction(0, 33, true)
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 35, true)
            DisableControlAction(0, 37, true)
            Wait(0)
        else
            Wait(400)
        end
    end
end)

-- ==========================================================================
-- Funções originais do vrp_hospital (macas / tratamento automático)
-- Mantidas no mesmo resource, separadas do painel.
-- ==========================================================================
local BedConfig = HospitalConfig.Beds or {}
local BED_MODEL = tonumber(BedConfig.Model) or 1631638868
local detectedBeds = {}
local bedGeometry = nil

local function normalizeHeading(value)
    value = tonumber(value) or 0.0
    value = value % 360.0
    if value < 0.0 then value = value + 360.0 end
    return value
end

local function getBedGeometry()
    if bedGeometry then return bedGeometry end

    local minDim, maxDim = GetModelDimensions(BED_MODEL)
    local sizeX = math.abs(maxDim.x - minDim.x)
    local sizeY = math.abs(maxDim.y - minDim.y)

    bedGeometry = {
        min = minDim,
        max = maxDim,
        centerX = (minDim.x + maxDim.x) * 0.5,
        centerY = (minDim.y + maxDim.y) * 0.5,
        longAxis = sizeY >= sizeX and "y" or "x",
        halfLength = math.max(sizeX, sizeY) * 0.5
    }

    return bedGeometry
end

-- Macas móveis criadas pelo m_aux usam o mesmo model das macas fixas do
-- hospital. A identificação precisa ser 100% pela STATE BAG da própria entidade.
--
-- NÃO use netId/export como fallback aqui. Objetos fixos de MLO/mapa também podem
-- ser networked pelo jogo, e IDs de rede podem ser reutilizados. O fallback por
-- netId fazia macas normais serem confundidas com macas móveis: os [E]/[G]
-- sumiam e a interação normal ficava instável.
local function isPortableAuxStretcher(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return false
    end

    local okState, entityState = pcall(function()
        return Entity(entity).state
    end)

    return okState
        and entityState ~= nil
        and entityState.m_auxPortableStretcher == true
end

local function makeBedData(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return nil end
    if GetEntityModel(entity) ~= BED_MODEL then return nil end
    if isPortableAuxStretcher(entity) then return nil end

    local geometry = getBedGeometry()
    local heading = GetEntityHeading(entity)
    if geometry.longAxis == "x" then
        heading = heading + 90.0
    end
    heading = normalizeHeading(heading + (tonumber(BedConfig.HeadingOffset) or 0.0))

    -- O centro da área útil é calculado pelas dimensões reais do model.
    -- Dessa forma não dependemos de coordenadas cadastradas manualmente.
    local liePosition = GetOffsetFromEntityInWorldCoords(
        entity,
        geometry.centerX,
        geometry.centerY,
        geometry.max.z + (tonumber(BedConfig.LieZOffset) or 0.03)
    )

    local radians = math.rad(heading)
    local forwardX = -math.sin(radians)
    local forwardY = math.cos(radians)
    local side = tonumber(BedConfig.MarkerSide) or -1
    if side >= 0 then side = 1 else side = -1 end

    local markerDistance = geometry.halfLength + (tonumber(BedConfig.MarkerExtraDistance) or 0.45)
    local entityCoords = GetEntityCoords(entity)
    local markerZ = entityCoords.z + geometry.min.z + (tonumber(BedConfig.MarkerZOffset) or 0.08)

    local markerPosition = vector3(
        liePosition.x + (forwardX * markerDistance * side),
        liePosition.y + (forwardY * markerDistance * side),
        markerZ
    )

    return {
        entity = entity,
        lie = vector3(liePosition.x, liePosition.y, liePosition.z),
        marker = markerPosition,
        heading = heading
    }
end

local function scanAutomaticBeds()
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local radius = tonumber(BedConfig.ScanRadius) or 90.0
    local seen = {}

    -- Atualiza/adiciona sem substituir a tabela inteira. Em alguns MLOs o pool de
    -- objetos pode oscilar por um frame durante streaming/LOD; apagar o cache inteiro
    -- fazia o DrawText3D piscar/sumir mesmo com a maca ainda visível.
    for _, entity in ipairs(GetGamePool("CObject")) do
        if DoesEntityExist(entity) and GetEntityModel(entity) == BED_MODEL and not isPortableAuxStretcher(entity) then
            local coords = GetEntityCoords(entity)
            if #(playerCoords - coords) <= radius then
                local data = makeBedData(entity)
                if data then
                    detectedBeds[entity] = data
                    seen[entity] = true
                end
            end
        end
    end

    -- Limpa apenas entidades que realmente deixaram de existir, viraram maca móvel
    -- ou saíram do raio. Se ela só não apareceu no pool nesta varredura, preservamos
    -- o cache enquanto a entidade continuar válida.
    for entity, bed in pairs(detectedBeds) do
        if not DoesEntityExist(entity)
            or GetEntityModel(entity) ~= BED_MODEL
            or isPortableAuxStretcher(entity) then
            detectedBeds[entity] = nil
        elseif not seen[entity] then
            local coords = GetEntityCoords(entity)
            if #(playerCoords - coords) > radius then
                detectedBeds[entity] = nil
            else
                local refreshed = makeBedData(entity)
                if refreshed then
                    detectedBeds[entity] = refreshed
                end
            end
        end
    end
end

local function DrawText3D(x, y, z, text)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    SetTextFont(4)
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 255, 255, 180)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(sx, sy)
end

local bedActionLock = false

local function placePedOnBed(ped, bed)
    if not bed or not bed.lie or not DoesEntityExist(ped) then return false end
    if bedActionLock then return false end

    bedActionLock = true

    -- Restaura o comportamento estável que as macas fixas já usavam antes da
    -- integração com as macas móveis. O vRP._playAnim mantém a animação em loop;
    -- o TaskPlayAnim/reancoragem adicionados depois estavam fazendo o ped levantar
    -- imediatamente em algumas bases.
    ClearPedTasksImmediately(ped)
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)
    SetEntityCoordsNoOffset(ped, bed.lie.x, bed.lie.y, bed.lie.z, false, false, false)
    SetEntityHeading(ped, bed.heading)
    Wait(80)

    vRP._playAnim(false, {{ "amb@world_human_sunbathe@female@back@idle_a", "idle_a" }}, true)

    CreateThread(function()
        Wait(500)
        bedActionLock = false
    end)

    return true
end

local function findNearestBed(coords, maxDistance)
    local nearest, nearestDistance

    for entity, bed in pairs(detectedBeds) do
        if DoesEntityExist(entity) and not isPortableAuxStretcher(entity) then
            local distance = #(coords - bed.marker)
            if (not nearestDistance or distance < nearestDistance) and distance <= maxDistance then
                nearest = bed
                nearestDistance = distance
            end
        end
    end

    return nearest, nearestDistance
end

-- Resolve a maca no exato frame em que a tecla é pressionada. Se o cache ainda
-- não recebeu a entidade (streaming/MLO), refaz a varredura imediatamente.
local function resolveBedForAction(coords, maxDistance)
    local bed, distance = findNearestBed(coords, maxDistance)
    if bed then return bed, distance end

    scanAutomaticBeds()
    return findNearestBed(coords, maxDistance)
end

-- Varredura leve e periódica. Macas de MLO/mapa aparecem automaticamente assim que
-- entram no streaming do cliente, sem necessidade de cadastrar coordenadas.
CreateThread(function()
    Wait(750)
    while true do
        scanAutomaticBeds()
        Wait(tonumber(BedConfig.ScanInterval) or 1500)
    end
end)

-- Thread exclusiva do DrawText. A distância visual continua curta para não mostrar
-- várias macas ao mesmo tempo.
CreateThread(function()
    while true do
        local wait = 250
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local drawDistance = tonumber(BedConfig.DrawDistance) or 1.0

        for entity, bed in pairs(detectedBeds) do
            if DoesEntityExist(entity) and not isPortableAuxStretcher(entity) then
                local distance = #(coords - bed.marker)
                if distance <= drawDistance then
                    wait = 0
                    local textZ = bed.marker.z + (tonumber(BedConfig.TextZOffset) or 0.55)
                    DrawText3D(bed.marker.x, bed.marker.y, textZ, "~g~[E]~w~ para deitar  ~g~[G]~w~ para tratamento")
                elseif distance <= 4.0 then
                    -- Mantém atualização rápida ao se aproximar sem desenhar o texto ainda.
                    wait = math.min(wait, 25)
                end
            end
        end

        Wait(wait)
    end
end)

-- Thread de input separada do desenho. Dessa forma o primeiro toque de E/G nunca
-- depende do timing do loop de DrawText. IsDisabledControlJustPressed cobre bases
-- que desabilitam a tecla E/G em algum outro resource.
CreateThread(function()
    local pendingAction = nil
    local pendingUntil = 0

    while true do
        Wait(0)

        local now = GetGameTimer()
        local pressedE = IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38)
        local pressedG = IsControlJustPressed(0, 47) or IsDisabledControlJustPressed(0, 47)

        -- Buffer curto de input: se o jogador apertar E/G no instante em que entra
        -- na área (especialmente correndo), o comando não é perdido entre frames.
        if pressedE then
            pendingAction = "lie"
            pendingUntil = now + 450
        elseif pressedG then
            pendingAction = "treat"
            pendingUntil = now + 450
        end

        if pendingAction and now > pendingUntil then
            pendingAction = nil
        end

        if pendingAction and not bedActionLock then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local actionDistance = tonumber(BedConfig.InteractionDistance) or 1.35
            local bed = resolveBedForAction(coords, actionDistance)

            if bed then
                local action = pendingAction
                pendingAction = nil

                if action == "lie" then
                    placePedOnBed(ped, bed)
                elseif action == "treat" then
                    if emP.checkServices() then
                        TriggerEvent("tratamento-macas")
                        TriggerEvent("resetDiagnostic")
                        TriggerEvent("resetWarfarina")
                        placePedOnBed(ped, bed)
                    else
                        TriggerEvent("Notify", "aviso", "Existem paramédicos em serviço.")
                    end
                end
            end
        end
    end
end)

RegisterNetEvent("event:deitarpaciente")
AddEventHandler("event:deitarpaciente", function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local maxDistance = tonumber(BedConfig.PatientDistance) or 3.5
    local nearest = findNearestBed(coords, maxDistance)

    -- Caso a maca tenha acabado de entrar no streaming antes da próxima varredura,
    -- atualiza imediatamente para não obrigar o jogador a esperar o intervalo do scanner.
    if not nearest then
        scanAutomaticBeds()
        nearest = findNearestBed(coords, maxDistance)
    end

    if nearest then
        placePedOnBed(ped, nearest)
    else
        TriggerEvent("Notify", "aviso", "Nenhuma maca foi encontrada próxima.")
    end
end)

RegisterNetEvent("tratamento-macas")
AddEventHandler("tratamento-macas", function()
    local ped = PlayerPedId()
    TriggerEvent("cancelando", true)
    local maxHealth = GetEntityMaxHealth(ped)
    while GetEntityHealth(ped) > 100 and GetEntityHealth(ped) < maxHealth do
        SetEntityHealth(ped, math.min(maxHealth, GetEntityHealth(ped) + 1))
        Wait(60)
    end
    TriggerEvent("Notify", "sucesso", "Tratamento concluído.")
    TriggerEvent("cancelando", false)
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        stopDiagnosisVisuals(false)
        SetNuiFocus(false, false)
    end
end)
