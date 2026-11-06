local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

local vRP = Proxy.getInterface("vRP")
local SERVER = Tunnel.getInterface(GetCurrentResourceName())

local nuiOpen = false

-- UI pública de chamados (F5), notificações de setores e avaliação.
local callMenuOpen = false
local callEvaluationOpen = false
local sectorCallVisible = {}
local sectorFocusActive = false

local punishmentState = { active = false, center = nil, radius = 10.0, endsAt = 0 }
local vipChoiceOpen = false
local vipTestState = { active = false, exiting = false, vehicle = 0, returnPosition = nil, endsAt = 0, center = nil, radius = 150.0, session = 0 }

local function playClick()
    if Config.ClickSound and Config.ClickSound.enabled then
        PlaySoundFrontend(-1, Config.ClickSound.name or "CONFIRM_BEEP", Config.ClickSound.set or "HUD_MINI_GAME_SOUNDSET", true)
    end
end

local function notify(kind, message, duration)
    TriggerEvent("Notify", kind or "aviso", message or "", duration or 7000)
end

local function uiToast(kind, message)
    SendNUIMessage({
        type = "toast",
        kind = kind or "info",
        message = message or ""
    })
end

-- Aviso administrativo em tela. A NUI continua ativa mesmo com o painel
-- fechado, então o jogador recebe o alerta sem chat e sem precisar abrir nada.
RegisterNetEvent("m_paineladm_v2:screenAlert", function(message, seconds, scope)
    SendNUIMessage({
        type = "screenAlert",
        message = tostring(message or "Aviso administrativo"),
        seconds = math.max(1, math.min(300, tonumber(seconds) or 8)),
        scope = scope == "private" and "private" or "general"
    })
end)


RegisterNetEvent("m_paineladm_v2:punishmentStart")
AddEventHandler("m_paineladm_v2:punishmentStart", function(data)
    data = type(data) == "table" and data or {}
    local center = type(data.center) == "table" and data.center or {}

    punishmentState.active = true
    punishmentState.center = vector3(
        tonumber(center.x) or 4501.22,
        tonumber(center.y) or -4546.93,
        tonumber(center.z) or 4.03
    )
    punishmentState.radius = math.max(1.0, tonumber(data.radius) or 10.0)
    punishmentState.endsAt = tonumber(data.endsAt) or 0

    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(
        ped,
        punishmentState.center.x,
        punishmentState.center.y,
        punishmentState.center.z,
        false, false, false
    )

    SendNUIMessage({
        type = "punishmentStart",
        seconds = math.max(1, tonumber(data.remainingSeconds) or 60)
    })
end)

RegisterNetEvent("m_paineladm_v2:punishmentStop")
AddEventHandler("m_paineladm_v2:punishmentStop", function()
    punishmentState.active = false
    punishmentState.center = nil
    punishmentState.endsAt = 0
    SendNUIMessage({ type = "punishmentStop" })
end)

CreateThread(function()
    while true do
        if punishmentState.active and punishmentState.center then
            Wait(200)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            if #(coords - punishmentState.center) > punishmentState.radius then
                SetEntityCoordsNoOffset(
                    ped,
                    punishmentState.center.x,
                    punishmentState.center.y,
                    punishmentState.center.z,
                    false, false, false
                )
            end
        else
            Wait(1000)
        end
    end
end)

local function publicConfig(dynamicLocations, dynamicLocationCategories, dynamicVehicles)
    local vehicles = {}
    if type(dynamicVehicles) == "table" and #dynamicVehicles > 0 then
        for index, vehicle in ipairs(dynamicVehicles) do
            vehicles[#vehicles + 1] = {
                index = vehicle.index or index,
                spawn = vehicle.spawn,
                name = vehicle.name or vehicle.nome or vehicle.spawn,
                category = vehicle.category == "addon" and "addon" or "game"
            }
        end
    else
        for index, vehicle in ipairs(Config.Vehicles or {}) do
            vehicles[#vehicles + 1] = {
                index = index,
                spawn = vehicle.spawn,
                name = vehicle.nome or vehicle.spawn,
                category = "game"
            }
        end
    end

    return {
        brand = Config.Brand,
        images = Config.Images,
        cleanupDelay = Config.VehicleCleanupDelay,
        locations = dynamicLocations or {},
        locationCategories = dynamicLocationCategories or {},
        vehicles = vehicles,
        weather = Config.Weather or {},
        liveMap = Config.LiveMap or {},
        calls = Config.Calls or {}
    }
end

local function closePanel()
    if not nuiOpen then return end

    -- Garante que uma sessão de "Ver Tela" não continue consumindo banda
    -- depois que o administrador fecha o painel.
    SERVER.stopLiveScreen()

    nuiOpen = false
    SetNuiFocus(false, false)
    TransitionFromBlurred(250)
    SendNUIMessage({ type = "close" })
end

local function openPanel()
    if nuiOpen then
        closePanel()
        return
    end
    if callEvaluationOpen then return end

    -- Evita sobreposição entre a interface pública F5 e o painel administrativo.
    callMenuOpen = false
    sectorFocusActive = false
    SendNUIMessage({ type = "callMenuClose" })
    SendNUIMessage({ type = "sectorFocus", active = false })
    SetNuiFocus(false, false)

    local bootstrap = SERVER.bootstrap()
    if not bootstrap or not bootstrap.allowed then
        return
    end

    nuiOpen = true
    SetNuiFocus(true, true)
    -- TransitionToBlurred(250)

    SendNUIMessage({
        type = "open",
        payload = {
            bootstrap = bootstrap,
            config = publicConfig(bootstrap.locations, bootstrap.locationCategories, bootstrap.vehicles)
        }
    })
end

RegisterCommand(Config.Command, function()
    openPanel()
end, false)

RegisterKeyMapping(Config.Command, "Abrir Painel ADM V2", "keyboard", Config.Key)

-- Coordenadas confiáveis para o Mapa ao Vivo. Cada client reporta somente a
-- própria posição em uma frequência baixa; o painel continua atualizando a
-- interface a cada 5s, então isto não cria um loop pesado na NUI.
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if ped and ped ~= 0 and DoesEntityExist(ped) then
            local coords = GetEntityCoords(ped)
            if coords then
                TriggerServerEvent(
                    "m_paineladm_v2:reportMapPosition",
                    coords.x + 0.0, coords.y + 0.0, coords.z + 0.0,
                    GetEntityHeading(ped) + 0.0
                )
            end
        end
        Wait(2500)
    end
end)

RegisterNUICallback("close", function(_, cb)
    closePanel()
    cb({ ok = true })
end)

RegisterNUICallback("refreshPlayers", function(data, cb)
    data = data or {}
    -- refreshPlayers(false) é usado internamente após ações como Alterar RG.
    -- Nessas sincronizações automáticas não tocamos outro CONFIRM_BEEP,
    -- evitando dois bips para uma única ação do administrador.
    if data.silent ~= true then
        playClick()
    end
    cb(SERVER.refreshPlayers())
end)

RegisterNUICallback("mapPlayers", function(_, cb)
    cb(SERVER.getMapPlayers())
end)

RegisterNUICallback("liveScreen", function(data, cb)
    data = data or {}
    local mode = tostring(data.mode or "")
    if mode == "stop" then
        cb(SERVER.stopLiveScreen())
        return
    end
    if mode == "ready" then
        cb(SERVER.readyLiveScreen(data))
        return
    end
    playClick()
    cb(SERVER.startLiveScreen(data))
end)

-- SDP e ICE são pequenos e passam pelo FXServer apenas para sinalização. O vídeo
-- WebRTC usa apenas sinalização por eventos. Se ICE falhar, a v2.81 pode ativar o fallback de frames por eventos latentes do FXServer.
RegisterNUICallback("liveScreenSignal", function(data, cb)
    data = data or {}
    TriggerServerEvent(
        "m_paineladm_v2:liveScreenSignal",
        tostring(data.token or ""),
        tostring(data.kind or ""),
        data.payload or {},
        tostring(data.role or "")
    )
    cb({ ok = true })
end)

RegisterNUICallback("liveScreenRelay", function(data, cb)
    data = data or {}
    local mode = tostring(data.mode or "")
    if mode == "start" then
        cb(SERVER.startLiveScreenRelay(data))
        return
    end
    cb({ ok = false, message = "Modo relay inválido." })
end)

RegisterNUICallback("liveScreenRelayFrame", function(data, cb)
    data = data or {}
    local frame = tostring(data.frame or "")
    local token = tostring(data.token or "")
    local seq = tonumber(data.seq) or 0
    if token == "" or frame == "" then
        cb({ ok = false })
        return
    end

    local mapConfig = Config.LiveMap or {}
    local bandwidth = math.max(128000, math.min(3500000, math.floor(tonumber(mapConfig.screenRelayBandwidth) or 2500000)))
    TriggerLatentServerEvent("m_paineladm_v2:liveScreenRelayFrame", bandwidth, token, seq, frame)
    cb({ ok = true })
end)

RegisterNUICallback("playerSnapshot", function(data, cb)
    playClick()
    cb(SERVER.getPlayerSnapshot(data or {}))
end)

RegisterNUICallback("identityEditor", function(data, cb)
    playClick()
    data = data or {}
    local mode = tostring(data.mode or "get")
    if mode == "update" then
        cb(SERVER.updateIdentity(data))
        return
    end
    cb(SERVER.getIdentityEditor(data))
end)

RegisterNUICallback("execute", function(data, cb)
    playClick()
    data = data or {}
    cb(SERVER.execute(data.action, data.payload or {}))
end)

RegisterNUICallback("needsSettings", function(data, cb)
    playClick()
    cb(SERVER.updateNeedsSettings(data or {}))
end)

RegisterNUICallback("radioAdmin", function(data, cb)
    data = data or {}
    if data.silent ~= true then playClick() end
    cb(SERVER.radioAdmin(data))
end)


RegisterNUICallback("vipAdmin", function(data, cb)
    data = data or {}
    if data.silent ~= true then playClick() end
    cb(SERVER.vipAdmin(data))
end)

RegisterNUICallback("logsAdmin", function(data, cb)
    data = data or {}
    if data.silent ~= true then playClick() end
    cb(SERVER.logsAdmin(data))
end)

RegisterNUICallback("auditAction", function(data, cb)
    data = data or {}
    cb(SERVER.auditPanelAction(data))
end)

RegisterNUICallback("vipPlayer", function(data, cb)
    data = data or {}
    local mode = tostring(data.mode or "")

    local response = SERVER.vipPlayer(data)
    -- Consultas de status são usadas como recuperação silenciosa do modal VIP.
    -- Não exibe erro quando simplesmente não existir escolha pendente.
    if mode ~= "status" and response and response.ok == false then
        notify("negado", response.message or "Não foi possível concluir a ação do VIP.", 6500)
    end
    if mode == "choose" and response and response.data and response.data.completed == true then
        vipChoiceOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ type = "vipChoiceClose" })
    end
    cb(response)
end)

RegisterNUICallback("banHistory", function(_, cb)
    playClick()
    cb(SERVER.getBanHistory())
end)


RegisterNUICallback("warnings", function(data, cb)
    data = data or {}
    if data.silent ~= true then playClick() end
    cb(SERVER.warnings(data))
end)

RegisterNUICallback("changeGroup", function(data, cb)
    playClick()
    cb(SERVER.changeGroup(data or {}))
end)

RegisterNUICallback("changeItem", function(data, cb)
    playClick()
    cb(SERVER.changeItem(data or {}))
end)


RegisterNUICallback("calls", function(data, cb)
    data = data or {}
    local response = SERVER.calls(data)
    if response and response.ok == false and (data.mode == "create" or data.mode == "sectorAccept" or data.mode == "rate") then
        notify("negado", response.message or "Não foi possível concluir a ação.", 6500)
    end
    cb(response)
end)

local function visibleSectorCallCount()
    local count = 0
    for _ in pairs(sectorCallVisible) do count = count + 1 end
    return count
end

local function releasePublicCallFocus()
    if nuiOpen or callEvaluationOpen then return end
    callMenuOpen = false
    sectorFocusActive = false
    SetNuiFocus(false, false)
    -- Garante que a tela principal do F5 nunca fique aberta por baixo das
    -- notificações dos setores. Isso também evita que ela reapareça após
    -- aceitar um chamado de Polícia/Mecânica/Hospital.
    SendNUIMessage({ type = "callMenuClose" })
    SendNUIMessage({ type = "sectorFocus", active = false })
end

RegisterNUICallback("callUi", function(data, cb)
    data = data or {}
    local mode = tostring(data.mode or "")
    if mode == "closeMenu" then
        callMenuOpen = false
        SendNUIMessage({ type = "callMenuClose" })
        releasePublicCallFocus()
    elseif mode == "sectorDismiss" then
        local callId = tonumber(data.callId)
        if callId then sectorCallVisible[callId] = nil end
        if visibleSectorCallCount() <= 0 then releasePublicCallFocus() end
    elseif mode == "evaluationDone" then
        callEvaluationOpen = false
        SendNUIMessage({ type = "callEvaluationClose" })
        releasePublicCallFocus()
    elseif mode == "releaseSectorFocus" then
        sectorFocusActive = false
        releasePublicCallFocus()
    end
    cb({ ok = true })
end)

RegisterNUICallback("addVehicleCatalog", function(data, cb)
    playClick()
    cb(SERVER.addVehicleCatalog(data or {}))
end)

RegisterNUICallback("addLocation", function(data, cb)
    playClick()
    cb(SERVER.addLocation(data or {}))
end)

RegisterNUICallback("addLocationCategory", function(data, cb)
    playClick()
    cb(SERVER.addLocationCategory(data or {}))
end)

RegisterNUICallback("removeLocation", function(data, cb)
    playClick()
    cb(SERVER.removeLocation(data or {}))
end)


RegisterNUICallback("panelPermissions", function(data, cb)
    playClick()
    data = data or {}
    if data.mode == "get" then
        cb(SERVER.getPanelPermissions())
    else
        cb(SERVER.updatePanelPermission(data))
    end
end)

RegisterNetEvent("m_paineladm_v2:permissionsUpdated")
AddEventHandler("m_paineladm_v2:permissionsUpdated", function(payload)
    SendNUIMessage({
        type = "permissionsUpdated",
        payload = payload
    })
end)

-- Sincronização em tempo real das informações de identidade alteradas pelo painel.
-- O NUI do ADM recebe o dado novo imediatamente, e o próprio client do jogador
-- recebe um hook local que pode ser consumido por HUD/identidade sem precisar relogar.
RegisterNetEvent("m_paineladm_v2:identityLiveUpdated")
AddEventHandler("m_paineladm_v2:identityLiveUpdated", function(payload)
    payload = type(payload) == "table" and payload or {}

    if nuiOpen then
        SendNUIMessage({
            type = "identityUpdated",
            payload = payload
        })
    end

    -- Evento local propositalmente separado do evento de rede para não criar loop.
    TriggerEvent("m_paineladm_v2:localIdentityUpdated", payload)
end)

RegisterNetEvent("m_paineladm_v2:playersLiveUpdated")
AddEventHandler("m_paineladm_v2:playersLiveUpdated", function(payload)
    payload = type(payload) == "table" and payload or {}

    if nuiOpen then
        SendNUIMessage({
            type = "playersUpdated",
            payload = payload
        })
    end
end)


RegisterNetEvent("m_paineladm_v2:warningsLiveUpdated")
AddEventHandler("m_paineladm_v2:warningsLiveUpdated", function(payload)
    payload = type(payload) == "table" and payload or {}
    if nuiOpen then
        SendNUIMessage({ type = "warningsUpdated", payload = payload })
    end
end)

RegisterNUICallback("environment", function(data, cb)
    data = data or {}
    -- O slider de horário envia atualizações contínuas; não toca o beep a cada passo.
    if tostring(data.action or "") ~= "setTime" then
        playClick()
    end
    cb(SERVER.updateEnvironment(data))
end)



-- ============================================================================
-- CHAMADOS / F5
-- ============================================================================
RegisterNetEvent("m_paineladm_v2:staffCallAccepted", function(payload)
    payload = payload or {}
    if nuiOpen then closePanel() end
    notify("sucesso", ("Chamado #%s aceito. Noclip da vRP ativado."):format(tostring(payload.callId or "-")), 7000)
end)

-- O estado do noclip é controlado exclusivamente no servidor através de
-- vRPclient._toggleNoclip(source). Este evento permanece apenas por
-- compatibilidade com o fluxo de encerramento do atendimento.
RegisterNetEvent("m_paineladm_v2:staffCallFinished", function(callId)
end)

RegisterNetEvent("m_paineladm_v2:callsUpdated", function()
    SendNUIMessage({ type = "callsUpdated" })
end)

RegisterNetEvent("m_paineladm_v2:staffCallNotice", function(payload)
    notify("aviso", "Há um novo chamado Staff disponível no painel!", 8000)
    if nuiOpen then
        uiToast("info", "Há um novo chamado Staff disponível no painel!")
    end
    SendNUIMessage({ type = "staffCallNotice", payload = payload or {} })
end)

RegisterNetEvent("m_paineladm_v2:sectorCallNew", function(payload)
    payload = payload or {}
    local callId = tonumber(payload.id)
    if not callId then return end
    sectorCallVisible[callId] = true
    SendNUIMessage({ type = "sectorCallNew", payload = payload })
end)

RegisterNetEvent("m_paineladm_v2:sectorCallTaken", function(payload)
    payload = payload or {}
    local callId = tonumber(payload.id)
    if callId then sectorCallVisible[callId] = nil end
    SendNUIMessage({ type = "sectorCallTaken", payload = payload })
    if visibleSectorCallCount() <= 0 and sectorFocusActive then
        releasePublicCallFocus()
    end
end)

RegisterNetEvent("m_paineladm_v2:sectorCallAccepted", function(payload)
    payload = payload or {}

    -- Aceitar um chamado de setor deve somente concluir a interação com a
    -- notificação lateral. Nunca abre o menu geral do F5.
    callMenuOpen = false
    sectorFocusActive = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "callMenuClose" })
    SendNUIMessage({ type = "sectorFocus", active = false })

    local x, y = tonumber(payload.x), tonumber(payload.y)
    if x and y then
        -- Marca a posição atual do solicitante no GPS/mapa do atendente.
        SetNewWaypoint(x + 0.0, y + 0.0)
    end

    local playerName = tostring(payload.playerName or "Jogador")
    local playerId = tonumber(payload.playerId) or 0
    notify("sucesso", ("Chamado aceito. Localização de %s (ID #%d) marcada no GPS."):format(playerName, playerId), 7500)
end)

RegisterNetEvent("m_paineladm_v2:callEvaluation", function(payload)
    payload = payload or {}
    callEvaluationOpen = true
    callMenuOpen = false
    sectorFocusActive = false
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "callMenuClose" })
    SendNUIMessage({ type = "sectorFocus", active = false })
    SendNUIMessage({ type = "callEvaluation", payload = payload })
end)

RegisterCommand("mage_calls_menu", function()
    if nuiOpen or callEvaluationOpen then return end

    if visibleSectorCallCount() > 0 then
        sectorFocusActive = not sectorFocusActive
        callMenuOpen = false
        SetNuiFocus(sectorFocusActive, sectorFocusActive)
        SendNUIMessage({ type = "callMenuClose" })
        SendNUIMessage({ type = "sectorFocus", active = sectorFocusActive })
        return
    end

    callMenuOpen = not callMenuOpen
    SetNuiFocus(callMenuOpen, callMenuOpen)
    SendNUIMessage({ type = callMenuOpen and "callMenuOpen" or "callMenuClose", config = Config.Calls or {} })
end, false)

RegisterKeyMapping("mage_calls_menu", "Abrir / interagir com Chamados", "keyboard", (Config.Calls and Config.Calls.key) or "F5")

local locationCaptureActive = false

local function drawText2D(x, y, scale, text, center)
    SetTextFont(4)
    SetTextScale(scale, scale)
    SetTextColour(235, 238, 255, 255)
    SetTextOutline()
    SetTextCentre(center == true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

local function drawLocationCaptureHelp()
    -- DrawText próprio no rodapé para não usar o HelpText nativo do GTA.
    local x = 0.5
    local y = 0.905

    DrawRect(x, y + 0.018, 0.355, 0.063, 10, 13, 28, 218)
    DrawRect(x - 0.176, y + 0.018, 0.004, 0.063, 108, 44, 255, 255)

    drawText2D(x, y - 0.002, 0.34, "~p~E~s~  SALVAR LOCAL     ~c~|~s~     ~p~BACKSPACE~s~  CANCELAR", true)
end

local function beginLocationCapture(name, category)
    if locationCaptureActive then return false end
    locationCaptureActive = true
    closePanel()
    CreateThread(function()
        Wait(350)
        while locationCaptureActive do
            Wait(0)
            drawLocationCaptureHelp()

            if IsControlJustPressed(0, 38) then -- E
                local coords = GetEntityCoords(PlayerPedId())
                locationCaptureActive = false
                local response = SERVER.addLocation({
                    name = name,
                    category = category,
                    x = coords.x,
                    y = coords.y,
                    z = coords.z
                })

                if response and response.ok then
                    notify("sucesso", response.message or "Local cadastrado.")
                    Wait(350)
                    openPanel()
                else
                    notify("negado", response and response.message or "Não foi possível cadastrar o local.")
                end
                break
            end

            if IsControlJustPressed(0, 177) then -- BACKSPACE
                locationCaptureActive = false
                notify("aviso", "Cadastro de local cancelado.")
                Wait(250)
                openPanel()
                break
            end
        end
    end)

    return true
end

RegisterNUICallback("startLocationCapture", function(data, cb)
    playClick()
    data = data or {}
    local name = tostring(data.name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local category = tostring(data.category or "Geral"):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        cb({ ok = false, message = "Informe um nome para o local." })
        return
    end
    if category == "" then
        cb({ ok = false, message = "Informe uma categoria para o local." })
        return
    end
    if locationCaptureActive then
        cb({ ok = false, message = "Já existe uma captura de coordenada em andamento." })
        return
    end

    beginLocationCapture(name, category)
    cb({ ok = true, message = "Capture a posição no jogo." })
end)

RegisterNUICallback("teleportLocation", function(data, cb)
    playClick()
    cb(SERVER.teleportLocation(data or {}))
end)

RegisterNetEvent("m_paineladm_v2:liveScreenPublisherStart", function(token, options)
    SendNUIMessage({
        type = "liveScreenPublisherStart",
        token = tostring(token or ""),
        options = options or {}
    })
end)

RegisterNetEvent("m_paineladm_v2:liveScreenPublisherStop", function(token)
    SendNUIMessage({
        type = "liveScreenPublisherStop",
        token = tostring(token or "")
    })
end)

RegisterNetEvent("m_paineladm_v2:liveScreenRelayStart", function(token, options)
    SendNUIMessage({
        type = "liveScreenRelayStart",
        token = tostring(token or ""),
        options = options or {}
    })
end)

RegisterNetEvent("m_paineladm_v2:liveScreenRelayStop", function(token)
    SendNUIMessage({
        type = "liveScreenRelayStop",
        token = tostring(token or "")
    })
end)

RegisterNetEvent("m_paineladm_v2:liveScreenRelayFrame", function(token, seq, frame)
    SendNUIMessage({
        type = "liveScreenRelayFrame",
        token = tostring(token or ""),
        seq = tonumber(seq) or 0,
        frame = tostring(frame or "")
    })
end)

RegisterNetEvent("m_paineladm_v2:liveScreenSignal", function(token, kind, payload, destinationRole)
    SendNUIMessage({
        type = "liveScreenSignal",
        token = tostring(token or ""),
        kind = tostring(kind or ""),
        payload = payload or {},
        role = tostring(destinationRole or "")
    })
end)

RegisterNetEvent("m_paineladm_v2:liveScreenError", function(token, message)
    if not nuiOpen then return end
    SendNUIMessage({
        type = "liveScreenError",
        token = token,
        message = message or "Não foi possível atualizar a tela do jogador."
    })
end)

local lastWeatherRevision = -1
local lastEnvironmentStateRevision = -1
local currentEnvironmentState = nil

local function normalizedEnvironmentWeather(state)
    local weather = tostring(type(state) == "table" and state.weather or "CLEAR"):upper()
    if weather == "" then weather = "CLEAR" end
    return weather
end

-- Aplica o clima oficial imediatamente. A partir desta versão o servidor é a fonte
-- única de verdade: nenhum client fica livre para usar o clima aleatório/local do GTA.
-- Isso evita players em CLEAR, FOGGY, RAIN etc. ao mesmo tempo.
local function applyWeatherState(state, hardReset)
    if type(state) ~= "table" then return end

    local weather = normalizedEnvironmentWeather(state)

    if hardReset == true then
        ClearOverrideWeather()
        ClearWeatherTypePersist()
    end

    -- Mesmo com "clima congelado" desligado, o clima atual continua sendo global.
    -- O que muda o clima é apenas o servidor (seleção manual ou modo rotativo).
    -- SetOverrideWeather + Persist impede respawn/interior/GTA de substituir o clima
    -- apenas para um jogador.
    SetWeatherTypePersist(weather)
    SetWeatherTypeNowPersist(weather)
    SetOverrideWeather(weather)
end

local function applyEnvironmentState(state, hardWeatherReset)
    if type(state) ~= "table" then return end

    currentEnvironmentState = state

    local hour = math.max(0, math.min(23, math.floor(tonumber(state.hour) or 12)))
    local minute = math.max(0, math.min(59, math.floor(tonumber(state.minute) or 0)))
    NetworkOverrideClockTime(hour, minute, 0)

    applyWeatherState(state, hardWeatherReset == true)
end


RegisterNetEvent("m_paineladm_v2:needsSync", function(enabled)
    SendNUIMessage({
        type = "needsState",
        payload = { enabled = enabled == true }
    })
end)

RegisterNetEvent("m_paineladm_v2:needsSettingsSync", function(settings)
    if type(settings) ~= "table" then return end
    SendNUIMessage({
        type = "needsSettingsState",
        payload = settings
    })
end)

RegisterNetEvent("m_paineladm_v2:environmentSync", function(state)
    if type(state) ~= "table" then return end

    local incomingWeatherRevision = tonumber(state.weatherRevision) or 0
    local weatherChanged = incomingWeatherRevision ~= lastWeatherRevision

    lastWeatherRevision = incomingWeatherRevision
    lastEnvironmentStateRevision = tonumber(state.stateRevision) or lastEnvironmentStateRevision

    -- Clima e horário são aplicados no mesmo instante em que o sync chega. Antes,
    -- este evento atualizava só o relógio e o clima dependia exclusivamente de uma
    -- leitura posterior do GlobalState, o que deixava uma janela para divergências.
    applyEnvironmentState(state, weatherChanged)

    if nuiOpen then
        SendNUIMessage({ type = "environmentState", payload = state })
    end
end)

-- Solicita o estado oficial assim que a sessão de rede estiver pronta. Isso garante
-- que quit/reconnect e primeiro spawn sempre recebam o último clima persistido.
CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(250)
    end

    Wait(500)
    TriggerServerEvent("m_paineladm_v2:requestEnvironmentSync")
end)

CreateThread(function()
    Wait(750)
    local enforceEveryMs = math.max(250, math.floor(tonumber((Config.Weather or {}).clientEnforceEveryMs) or 750))

    while true do
        local state = GlobalState.mageAdminEnvironment
        if type(state) == "table" then
            currentEnvironmentState = state

            local stateRevision = tonumber(state.stateRevision) or 0
            local weatherRevision = tonumber(state.weatherRevision) or 0
            local weatherChanged = weatherRevision ~= lastWeatherRevision
            local stateChanged = stateRevision ~= lastEnvironmentStateRevision

            if weatherChanged then
                lastWeatherRevision = weatherRevision
            end
            if stateChanged then
                lastEnvironmentStateRevision = stateRevision
            end

            -- Reaplica o estado em todo ciclo, não apenas quando a revision muda.
            -- Assim, se o jogo/respawn/interior/outro resource tentar mudar o clima
            -- localmente, o valor global do painel volta automaticamente em seguida.
            applyEnvironmentState(state, weatherChanged)

            if stateChanged and nuiOpen then
                SendNUIMessage({ type = "environmentState", payload = state })
            end
        elseif currentEnvironmentState then
            -- Durante uma pequena janela sem GlobalState, mantém o último estado
            -- recebido pelo evento em vez de permitir que o clima local varie.
            applyEnvironmentState(currentEnvironmentState, false)
        end

        Wait(enforceEveryMs)
    end
end)

local function getVehicle(radius)
    local ped = PlayerPedId()

    if IsPedInAnyVehicle(ped, false) then
        return GetVehiclePedIsIn(ped, false)
    end

    local coords = GetEntityCoords(ped)
    return GetClosestVehicle(coords.x, coords.y, coords.z, radius or ClientConfig.VehicleRadius or 7.5, 0, 71)
end

local function requestControl(entity)
    if not entity or entity == 0 then return false end
    if not NetworkGetEntityIsNetworked(entity) then return true end

    NetworkRequestControlOfEntity(entity)
    local timeout = GetGameTimer() + 1000

    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeout do
        Wait(0)
        NetworkRequestControlOfEntity(entity)
    end

    return NetworkHasControlOfEntity(entity)
end

RegisterNetEvent("m_paineladm_v2:revive", function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    if IsEntityDead(ped) or GetEntityHealth(ped) <= 101 then
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
    end

    ClearPedBloodDamage(ped)
    ClearPedTasksImmediately(ped)
    SetEntityHealth(ped, 400)
    TriggerEvent("mirtin_survival:updateComa", false)
end)

RegisterNetEvent("m_paineladm_v2:freeze", function(state)
    FreezeEntityPosition(PlayerPedId(), state == true)
end)

RegisterNetEvent("m_paineladm_v2:clearWeapons", function()
    RemoveAllPedWeapons(PlayerPedId(), true)
end)

local function deleteVipTestVehicle()
    local vehicle = tonumber(vipTestState.vehicle) or 0
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        NetworkRequestControlOfEntity(vehicle)
        local timeout = GetGameTimer() + 1000
        while NetworkGetEntityIsNetworked(vehicle) and not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < timeout do
            Wait(0)
            NetworkRequestControlOfEntity(vehicle)
        end
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
        if DoesEntityExist(vehicle) then DeleteEntity(vehicle) end
    end
    vipTestState.vehicle = 0
end

local function clearVipTestOverlay(session)
    local closedSession = tonumber(session) or tonumber(vipTestState.session) or 0
    SendNUIMessage({ type = "vipTestOverlay", active = false, session = closedSession })

    -- Reforça a limpeza apenas enquanto nenhuma nova sessão de teste tiver
    -- iniciado. Isso elimina updates atrasados do mesmo teste sem correr o
    -- risco de esconder o overlay de um teste novo.
    CreateThread(function()
        for _,delay in ipairs({ 75, 200, 500 }) do
            Wait(delay)
            if vipTestState.active or tonumber(vipTestState.session) ~= closedSession then return end
            SendNUIMessage({ type = "vipTestOverlay", active = false, session = closedSession })
        end
    end)
end

local function restoreVipTestPlayer(returnPosition, reopenChoice)
    local closingSession = tonumber(vipTestState.session) or 0
    deleteVipTestVehicle()
    local ped = PlayerPedId()
    local pos = type(returnPosition) == "table" and returnPosition or vipTestState.returnPosition or {}

    DoScreenFadeOut(250)
    local timeout = GetGameTimer() + 1000
    while not IsScreenFadedOut() and GetGameTimer() < timeout do Wait(0) end

    SetEntityCoordsNoOffset(
        ped,
        tonumber(pos.x) or 0.0,
        tonumber(pos.y) or 0.0,
        tonumber(pos.z) or 0.0,
        false, false, false
    )
    SetEntityHeading(ped, tonumber(pos.h) or 0.0)

    vipTestState.active = false
    vipTestState.exiting = false
    vipTestState.returnPosition = nil
    vipTestState.center = nil
    vipTestState.endsAt = 0
    clearVipTestOverlay(closingSession)

    Wait(120)
    DoScreenFadeIn(250)

    if reopenChoice then
        vipChoiceOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ type = "vipChoiceOpen", payload = reopenChoice })
    else
        vipChoiceOpen = false
        SetNuiFocus(false, false)
    end
end

local function finishVipVehicleTest()
    if not vipTestState.active or vipTestState.exiting then return end
    vipTestState.exiting = true

    local response = SERVER.vipPlayer({ mode = "finishTest" })
    if not response or response.ok == false then
        -- Se o Tunnel falhar, libera uma nova tentativa de saída em vez de
        -- deixar o jogador preso na dimensão de teste.
        vipTestState.exiting = false
        notify("negado", response and response.message or "Não foi possível encerrar o teste. Tente F7 novamente.", 5000)
        return
    end

    local data = response.data or nil
    restoreVipTestPlayer(data and data.returnPosition or vipTestState.returnPosition, data and data.choice or nil)
end

-- Atalho dedicado para a saída do test-drive. O polling por control continua
-- existindo como fallback, mas o key mapping faz o F7 responder já no primeiro
-- pressionamento mesmo quando outro resource altera o estado dos controls.
RegisterCommand("m_paineladm_v2_viptest_exit", function()
    if vipTestState.active then
        finishVipVehicleTest()
    end
end, false)
RegisterKeyMapping("m_paineladm_v2_viptest_exit", "Sair do teste de veículo VIP", "keyboard", "F7")

RegisterNetEvent("m_paineladm_v2:vipChoiceOpen", function(payload)
    if vipTestState.active then return end
    clearVipTestOverlay(vipTestState.session)
    vipChoiceOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "vipChoiceOpen", payload = payload or {} })
end)

RegisterNetEvent("m_paineladm_v2:vipChoiceClose", function(message)
    vipChoiceOpen = false
    if not vipTestState.active then
        clearVipTestOverlay(vipTestState.session)
        SetNuiFocus(false, false)
    end
    SendNUIMessage({ type = "vipChoiceClose", message = tostring(message or "") })
end)

RegisterNetEvent("m_paineladm_v2:vipTestStart", function(payload)
    payload = type(payload) == "table" and payload or {}
    local center = type(payload.center) == "table" and payload.center or {}
    local spawn = tostring(payload.vehicle or ""):lower()
    if spawn == "" then return end

    local model = joaat(spawn)
    if not IsModelInCdimage(model) or not IsModelAVehicle(model) then
        notify("negado", "Este veículo não está carregado no servidor.", 7000)
        SERVER.vipPlayer({ mode = "finishTest" })
        return
    end

    -- Se quem recebeu o VIP também estiver com o painel administrativo
    -- aberto (ex.: staff setando o VIP em si mesma), fecha o painel por
    -- completo antes de entrar na dimensão. O seletor VIP fica fora do #app
    -- e será reaberto normalmente quando o teste terminar.
    if nuiOpen then
        closePanel()
    end

    vipChoiceOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "vipChoiceClose" })

    RequestModel(model)
    local modelTimeout = GetGameTimer() + 8000
    while not HasModelLoaded(model) and GetGameTimer() < modelTimeout do Wait(0) end
    if not HasModelLoaded(model) then
        notify("negado", "Não foi possível carregar o veículo para teste.", 7000)
        local response = SERVER.vipPlayer({ mode = "finishTest" })
        local data = response and response.data or nil
        restoreVipTestPlayer(data and data.returnPosition or payload.returnPosition, data and data.choice or nil)
        return
    end

    deleteVipTestVehicle()
    local ped = PlayerPedId()

    -- O veículo em que o jogador estava antes do teste fica no local original.
    -- Isso evita teleportar acidentalmente um veículo pessoal para a dimensão.
    if IsPedInAnyVehicle(ped, false) then
        local previousVehicle = GetVehiclePedIsIn(ped, false)
        TaskLeaveVehicle(ped, previousVehicle, 16)
        local leaveTimeout = GetGameTimer() + 1500
        while IsPedInAnyVehicle(ped, false) and GetGameTimer() < leaveTimeout do Wait(0) end
        if IsPedInAnyVehicle(ped, false) then
            ClearPedTasksImmediately(ped)
        end
    end

    vipTestState.session = (tonumber(vipTestState.session) or 0) + 1
    vipTestState.active = true
    vipTestState.exiting = false
    vipTestState.returnPosition = payload.returnPosition
    vipTestState.center = vector3(tonumber(center.x) or -1291.34, tonumber(center.y) or -2980.99, tonumber(center.z) or 13.93)
    vipTestState.radius = math.max(25.0, tonumber(payload.radius) or 150.0)
    vipTestState.endsAt = GetGameTimer() + (math.max(1, tonumber(payload.seconds) or 60) * 1000)

    DoScreenFadeOut(250)
    local fadeTimeout = GetGameTimer() + 1000
    while not IsScreenFadedOut() and GetGameTimer() < fadeTimeout do Wait(0) end

    SetEntityCoordsNoOffset(ped, vipTestState.center.x, vipTestState.center.y, vipTestState.center.z + 0.3, false, false, false)
    SetEntityHeading(ped, tonumber(center.h) or 330.0)

    local vehicle = CreateVehicle(model, vipTestState.center.x, vipTestState.center.y, vipTestState.center.z + 0.3, tonumber(center.h) or 330.0, true, false)
    SetModelAsNoLongerNeeded(model)
    if not vehicle or vehicle == 0 then
        notify("negado", "Falha ao criar o veículo de teste.", 7000)
        local response = SERVER.vipPlayer({ mode = "finishTest" })
        local data = response and response.data or nil
        restoreVipTestPlayer(data and data.returnPosition or payload.returnPosition, data and data.choice or nil)
        return
    end

    vipTestState.vehicle = vehicle
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetPedIntoVehicle(ped, vehicle, -1)

    Wait(120)
    DoScreenFadeIn(250)

    SendNUIMessage({
        type = "vipTestOverlay",
        active = true,
        vehicleName = tostring(payload.vehicleName or spawn),
        seconds = math.max(1, tonumber(payload.seconds) or 60),
        session = vipTestState.session
    })
end)

RegisterNetEvent("m_paineladm_v2:vipTestForceStop", function(returnPosition)
    if vipTestState.active then
        restoreVipTestPlayer(returnPosition or vipTestState.returnPosition, nil)
    end
end)

CreateThread(function()
    local lastSecond = -1
    while true do
        if vipTestState.active then
            Wait(100)
            local ped = PlayerPedId()
            local entity = (vipTestState.vehicle ~= 0 and DoesEntityExist(vipTestState.vehicle)) and vipTestState.vehicle or ped
            local coords = GetEntityCoords(entity)
            if vipTestState.center and #(coords - vipTestState.center) > vipTestState.radius then
                if vipTestState.vehicle ~= 0 and DoesEntityExist(vipTestState.vehicle) then
                    SetEntityCoordsNoOffset(vipTestState.vehicle, vipTestState.center.x, vipTestState.center.y, vipTestState.center.z + 0.3, false, false, false)
                    SetEntityHeading(vipTestState.vehicle, 330.0)
                    SetVehicleOnGroundProperly(vipTestState.vehicle)
                    SetPedIntoVehicle(ped, vipTestState.vehicle, -1)
                else
                    SetEntityCoordsNoOffset(ped, vipTestState.center.x, vipTestState.center.y, vipTestState.center.z + 0.3, false, false, false)
                end
                notify("aviso", "Você chegou ao limite de 150 metros da área de teste.", 3500)
            end

            local remaining = math.max(0, math.ceil((vipTestState.endsAt - GetGameTimer()) / 1000))
            if remaining ~= lastSecond then
                lastSecond = remaining
                SendNUIMessage({ type = "vipTestOverlay", active = true, seconds = remaining, session = vipTestState.session })
            end

            if IsControlJustPressed(0, 168) or IsDisabledControlJustPressed(0, 168) or remaining <= 0 or IsEntityDead(ped) then -- F7 / tempo / morte
                finishVipVehicleTest()
                lastSecond = -1
            elseif vipTestState.vehicle ~= 0 and (not DoesEntityExist(vipTestState.vehicle) or IsEntityDead(vipTestState.vehicle)) then
                finishVipVehicleTest()
                lastSecond = -1
            end
        else
            lastSecond = -1
            Wait(750)
        end
    end
end)

RegisterNetEvent("m_paineladm_v2:spawnVehicle", function(vehicleName)
    vehicleName = tostring(vehicleName or ""):lower()
    if vehicleName == "" then return end

    local model = joaat(vehicleName)
    if not IsModelInCdimage(model) or not IsModelAVehicle(model) then
        notify("negado", "Veículo inválido: " .. vehicleName)
        uiToast("error", "Veículo inválido: " .. vehicleName)
        return
    end

    RequestModel(model)
    local timeout = GetGameTimer() + 7000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(0)
    end

    if not HasModelLoaded(model) then
        notify("negado", "Não foi possível carregar o veículo.")
        uiToast("error", "Falha ao carregar o veículo.")
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local forward = GetEntityForwardVector(ped)
    local distance = ClientConfig.SpawnDistance or 3.5

    local vehicle = CreateVehicle(
        model,
        coords.x + forward.x * distance,
        coords.y + forward.y * distance,
        coords.z + 0.5,
        heading,
        true,
        false
    )

    if vehicle and vehicle ~= 0 then
        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleOnGroundProperly(vehicle)
        SetVehicleEngineOn(vehicle, true, true, false)
        SetVehicleDirtLevel(vehicle, 0.0)
        SetPedIntoVehicle(ped, vehicle, -1)
        notify("sucesso", "Veículo spawnado: " .. vehicleName)
        uiToast("success", "Veículo spawnado: " .. vehicleName)
    else
        notify("negado", "Falha ao criar o veículo.")
        uiToast("error", "Falha ao criar o veículo.")
    end

    SetModelAsNoLongerNeeded(model)
end)

RegisterNetEvent("m_paineladm_v2:fixVehicle", function()
    local vehicle = getVehicle()
    if not vehicle or vehicle == 0 then
        notify("negado", "Nenhum veículo próximo.")
        uiToast("error", "Nenhum veículo próximo.")
        return
    end

    requestControl(vehicle)
    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
    SetVehicleDirtLevel(vehicle, 0.0)

    notify("sucesso", "Veículo reparado.")
    uiToast("success", "Veículo reparado.")
end)

RegisterNetEvent("m_paineladm_v2:tuneVehicle", function()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        notify("negado", "Entre em um veículo para tuná-lo.")
        uiToast("error", "Entre em um veículo para tuná-lo.")
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    requestControl(vehicle)
    SetVehicleModKit(vehicle, 0)

    for modType = 0, 49 do
        local count = GetNumVehicleMods(vehicle, modType)
        if count and count > 0 then
            SetVehicleMod(vehicle, modType, count - 1, false)
        end
    end

    ToggleVehicleMod(vehicle, 18, true)
    ToggleVehicleMod(vehicle, 20, true)
    ToggleVehicleMod(vehicle, 22, true)
    SetVehicleTyresCanBurst(vehicle, false)
    SetVehicleWindowTint(vehicle, 1)

    notify("sucesso", "Veículo tunado ao máximo.")
    uiToast("success", "Veículo tunado ao máximo.")
end)

RegisterNetEvent("m_paineladm_v2:vehicleHash", function()
    local vehicle = getVehicle()
    if not vehicle or vehicle == 0 then
        notify("negado", "Nenhum veículo próximo.")
        uiToast("error", "Nenhum veículo próximo.")
        return
    end

    local hash = GetEntityModel(vehicle)
    local display = GetDisplayNameFromVehicleModel(hash)
    local label = GetLabelText(display)
    if not label or label == "NULL" then label = display end

    local message = ("%s • Hash: %s"):format(label or "Veículo", tostring(hash))
    notify("importante", message, 10000)
    uiToast("info", message)
end)

RegisterNetEvent("m_paineladm_v2:deleteVehicle", function()
    local vehicle = getVehicle()
    if not vehicle or vehicle == 0 then
        notify("negado", "Nenhum veículo próximo.")
        uiToast("error", "Nenhum veículo próximo.")
        return
    end

    if requestControl(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
        notify("sucesso", "Veículo removido.")
        uiToast("success", "Veículo removido.")
    else
        notify("negado", "Não foi possível obter controle do veículo.")
        uiToast("error", "Sem controle de rede do veículo.")
    end
end)

RegisterNetEvent("m_paineladm_v2:teleportWaypoint", function()
    local waypoint = GetFirstBlipInfoId(8)
    if not DoesBlipExist(waypoint) then
        notify("negado", "Marque um destino no mapa primeiro.")
        uiToast("error", "Nenhum waypoint marcado.")
        return
    end

    local coords = GetBlipInfoIdCoord(waypoint)
    local ped = PlayerPedId()
    local foundGround = false
    local groundZ = 0.0

    for height = 1000.0, 0.0, -50.0 do
        SetEntityCoordsNoOffset(ped, coords.x, coords.y, height, false, false, false)
        RequestCollisionAtCoord(coords.x, coords.y, height)
        Wait(30)

        local found, z = GetGroundZFor_3dCoord(coords.x, coords.y, height, false)
        if found then
            foundGround = true
            groundZ = z + 1.0
            break
        end
    end

    if foundGround then
        SetEntityCoordsNoOffset(ped, coords.x, coords.y, groundZ, false, false, false)
    else
        SetEntityCoordsNoOffset(ped, coords.x, coords.y, 1000.0, false, false, false)
    end

    notify("sucesso", "Teleportado para o waypoint.")
    uiToast("success", "Teleportado para o waypoint.")
end)

RegisterNetEvent("m_paineladm_v2:clearProps", function(x, y, z, radius)
    local center = vector3(tonumber(x) or 0.0, tonumber(y) or 0.0, tonumber(z) or 0.0)
    radius = tonumber(radius) or 2000.0
    local removed = 0

    for _, object in ipairs(GetGamePool("CObject")) do
        if DoesEntityExist(object) then
            local coords = GetEntityCoords(object)
            if #(coords - center) <= radius then
                if requestControl(object) then
                    SetEntityAsMissionEntity(object, true, true)
                    DeleteEntity(object)
                    removed = removed + 1
                end
            end
        end
    end

    if nuiOpen then
        uiToast("success", ("%d props removidos localmente."):format(removed))
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        if vipTestState.active then
            local ped = PlayerPedId()
            local pos = vipTestState.returnPosition or {}
            deleteVipTestVehicle()
            SetEntityCoordsNoOffset(ped, tonumber(pos.x) or 0.0, tonumber(pos.y) or 0.0, tonumber(pos.z) or 0.0, false, false, false)
            SetEntityHeading(ped, tonumber(pos.h) or 0.0)
        end
        SetNuiFocus(false, false)
    end
end)

RegisterNetEvent("m_paineladm_v2:radioUpdated", function(payload)
    SendNUIMessage({ type = "radioUpdated", payload = payload or {} })
end)

