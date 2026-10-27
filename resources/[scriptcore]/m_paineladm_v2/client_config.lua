ClientConfig = ClientConfig or {}

-- Distância usada para localizar um veículo em ações rápidas.
ClientConfig.VehicleRadius = 7.5

-- Distância em que o veículo administrativo será criado à frente do jogador.
ClientConfig.SpawnDistance = 3.5

-- ============================================================================
-- INTERFACES VRP/TUNNEL ESTAVEIS (ARQUIVO ABERTO)
-- O core ofuscado recebe somente a interface Tunnel pronta e nao executa
-- module() ou Tunnel.getInterface().
-- ============================================================================
local MG_TUNNEL = module("vrp", "lib/Tunnel")
local MG_SERVER = MG_TUNNEL["getInterface"](GetCurrentResourceName())
rawset(_G, "MG_PAINEL_SERVER_BRIDGE", MG_SERVER)

-- ============================================================================
-- TRANSPORTE ABERTO / COMPATIVEL COM OFUSCACAO
-- NAO OFUSCAR ESTE ARQUIVO.
-- ============================================================================
local MG_RESOURCE = GetCurrentResourceName()
local MG_LOCAL_REQUEST = MG_RESOURCE .. ":localBridgeRequestOfficial"
local MG_LOCAL_RESPONSE = MG_RESOURCE .. ":localBridgeResponseOfficial"
local MG_CLICK_EVENT = MG_RESOURCE .. ":bridgeClickOfficial"
local MG_RELAY_FRAME_EVENT = MG_RESOURCE .. ":bridgeRelayFrameOfficial"
local MG_VIP_RESPONSE_EVENT = MG_RESOURCE .. ":vipPlayerBridgeResponseOfficial"
local MG_VIP_FINISH_REQUEST = MG_RESOURCE .. ":vipFinishRequestSafe"
local MG_VIP_FINISH_RESPONSE = MG_RESOURCE .. ":vipFinishResponseSafe"

local function mgTransportError(message)
    return {
        ok = false,
        success = false,
        allowed = false,
        message = tostring(message or "Falha de comunicacao com o painel administrativo.")
    }
end

local function mgClientCoreCall(method, data)
    local core = rawget(_G, "MG_PAINEL_CLIENT_CORE")
    local fn = type(core) == "table" and core[tostring(method or "")] or nil
    if type(fn) ~= "function" then
        return mgTransportError(("Client core indisponivel (%s)."):format(tostring(method)))
    end

    local ok, response = pcall(fn, type(data) == "table" and data or {})
    if not ok then
        print(("^1[m_paineladm_v2] Client core '%s' falhou: %s^0"):format(tostring(method), tostring(response)))
        return mgTransportError("Falha interna no client core.")
    end

    return response or { ok = true }
end

AddEventHandler(MG_CLICK_EVENT, function()
    if Config.ClickSound and Config.ClickSound.enabled then
        PlaySoundFrontend(-1, Config.ClickSound.name or "CONFIRM_BEEP", Config.ClickSound.set or "HUD_MINI_GAME_SOUNDSET", true)
    end
end)

AddEventHandler(MG_LOCAL_REQUEST, function(requestId, method, data)
    method = tostring(method or "")
    local response

    if method == "closePanel" then
        response = mgClientCoreCall("closePanel", data)
        if response and response.ok == false then
            SetNuiFocus(false, false)
            SendNUIMessage({ type = "close" })
        end
    elseif method == "callUi" then
        response = mgClientCoreCall("handleCallUi", data)
    elseif method == "startLocationCapture" then
        response = mgClientCoreCall("startLocationCapture", data)
    elseif method == "vipPlayerResponse" then
        response = mgClientCoreCall("vipPlayerResponse", data)
    else
        response = mgTransportError("Acao local invalida.")
    end

    TriggerEvent(MG_LOCAL_RESPONSE, tostring(requestId or ""), response)
end)


-- Respostas VIP sao tratadas abaixo pelas rotinas abertas v2.90.5.

-- Fallback de frames da tela ao vivo. A NUI chama o bridge JS aberto, que
-- encaminha somente o frame para este arquivo Lua aberto.
AddEventHandler(MG_RELAY_FRAME_EVENT, function(data)
    data = type(data) == "table" and data or {}
    local frame = tostring(data.frame or "")
    local token = tostring(data.token or "")
    local seq = tonumber(data.seq) or 0
    if token == "" or frame == "" then return end

    local mapConfig = Config.LiveMap or {}
    local bandwidth = math.max(128000, math.min(3500000, math.floor(tonumber(mapConfig.screenRelayBandwidth) or 2500000)))
    TriggerLatentServerEvent("m_paineladm_v2:liveScreenRelayFrame", bandwidth, token, seq, frame)
end)

-- As chamadas internas do client.lua protegido usam a interface Tunnel da vRP.
-- Este arquivo aberto fica responsável apenas pelos callbacks locais disparados
-- pelo bridge_client.js (close/callUi/captura/VIP) e pelo relay de frames.

CreateThread(function()
    Wait(0)
    print("^2[m_paineladm_v2] Client transport definitivo v2.90.5 carregado antes do client ofuscado.^0")
end)

-- ==========================================================================
-- ROTINAS CLIENT-SIDE CRITICAS FORA DA OFUSCACAO
-- v2.90.5 - spawn administrativo + test-drive VIP resilientes a virtualizador
--
-- IMPORTANTE:
--   - a autorizacao continua 100% no server.lua protegido;
--   - este arquivo apenas executa no GTA/FiveM uma acao que o servidor ja
--     validou e autorizou;
--   - os eventos terminam em "Safe" justamente para nao disputar com os
--     handlers legados que permanecem no client.lua protegido.
-- ==========================================================================

local MG_SAFE_VIP = {
    active = false,
    starting = false,
    exiting = false,
    vehicle = 0,
    session = 0,
    returnPosition = nil,
    center = nil,
    radius = 150.0,
    endsAt = 0,
    finishSeq = 0,
    finishPending = nil
}

local function mgUiToast(kind, message)
    SendNUIMessage({
        type = "toast",
        kind = tostring(kind or "info"),
        message = tostring(message or "")
    })
end

local function mgNotify(kind, message, duration)
    TriggerEvent("Notify", tostring(kind or "aviso"), tostring(message or ""), tonumber(duration) or 5000)
end

local function mgSafeFadeIn()
    if IsScreenFadedOut() or IsScreenFadingOut() then
        DoScreenFadeIn(250)
    end
end

local function mgWaitModel(model, timeoutMs)
    RequestModel(model)
    local deadline = GetGameTimer() + math.max(1000, tonumber(timeoutMs) or 8000)
    while not HasModelLoaded(model) and GetGameTimer() < deadline do
        Wait(0)
        RequestModel(model)
    end
    return HasModelLoaded(model)
end

local function mgRequestEntityControl(entity, timeoutMs)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return false end
    if not NetworkGetEntityIsNetworked(entity) then return true end

    local deadline = GetGameTimer() + math.max(250, tonumber(timeoutMs) or 1500)
    NetworkRequestControlOfEntity(entity)
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < deadline do
        Wait(0)
        NetworkRequestControlOfEntity(entity)
    end
    return NetworkHasControlOfEntity(entity)
end

local function mgPrepareNetworkVehicle(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    if not NetworkGetEntityIsNetworked(vehicle) then
        NetworkRegisterEntityAsNetworked(vehicle)
    end

    local deadline = GetGameTimer() + 1200
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    while (not netId or netId == 0) and GetGameTimer() < deadline do
        Wait(0)
        netId = NetworkGetNetworkIdFromEntity(vehicle)
    end

    if netId and netId ~= 0 then
        SetNetworkIdCanMigrate(netId, true)
        SetNetworkIdExistsOnAllMachines(netId, true)
    end

    mgRequestEntityControl(vehicle, 1200)
end

local function mgWarpPedIntoDriverSeat(ped, vehicle)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return false end
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end

    mgPrepareNetworkVehicle(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)

    -- SetPedIntoVehicle e TaskWarpPedIntoVehicle sao usados em conjunto.
    -- Alguns builds/OneSync ignoram a primeira chamada no mesmo frame em que
    -- a entidade de rede acabou de nascer.
    for attempt = 1, 12 do
        SetPedIntoVehicle(ped, vehicle, -1)
        TaskWarpPedIntoVehicle(ped, vehicle, -1)
        Wait(attempt <= 3 and 0 or 50)

        if GetVehiclePedIsIn(ped, false) == vehicle or GetPedInVehicleSeat(vehicle, -1) == ped then
            SetVehicleEngineOn(vehicle, true, true, false)
            return true
        end
    end

    -- Ultima tentativa: coloca o ped exatamente ao lado/na altura do veiculo
    -- antes do warp para evitar rejeicao por streaming/colisao.
    local coords = GetEntityCoords(vehicle)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z + 0.25, false, false, false)
    Wait(50)
    TaskWarpPedIntoVehicle(ped, vehicle, -1)
    SetPedIntoVehicle(ped, vehicle, -1)
    Wait(100)

    return GetVehiclePedIsIn(ped, false) == vehicle or GetPedInVehicleSeat(vehicle, -1) == ped
end

local function mgDeleteSafeVipVehicle()
    local vehicle = tonumber(MG_SAFE_VIP.vehicle) or 0
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        mgRequestEntityControl(vehicle, 1200)
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end
    MG_SAFE_VIP.vehicle = 0
end

local function mgClearVipOverlay(session)
    SendNUIMessage({
        type = "vipTestOverlay",
        active = false,
        session = tonumber(session) or tonumber(MG_SAFE_VIP.session) or 0
    })
end

local function mgRestoreVipPlayer(returnPosition, reopenChoice)
    local closingSession = tonumber(MG_SAFE_VIP.session) or 0
    mgDeleteSafeVipVehicle()

    local ped = PlayerPedId()
    local pos = type(returnPosition) == "table" and returnPosition or MG_SAFE_VIP.returnPosition or {}

    DoScreenFadeOut(180)
    local deadline = GetGameTimer() + 700
    while not IsScreenFadedOut() and GetGameTimer() < deadline do Wait(0) end

    SetEntityCoordsNoOffset(
        ped,
        tonumber(pos.x) or 0.0,
        tonumber(pos.y) or 0.0,
        tonumber(pos.z) or 0.0,
        false, false, false
    )
    SetEntityHeading(ped, tonumber(pos.h) or 0.0)

    MG_SAFE_VIP.active = false
    MG_SAFE_VIP.starting = false
    MG_SAFE_VIP.exiting = false
    MG_SAFE_VIP.finishPending = nil
    MG_SAFE_VIP.returnPosition = nil
    MG_SAFE_VIP.center = nil
    MG_SAFE_VIP.endsAt = 0
    mgClearVipOverlay(closingSession)

    Wait(80)
    mgSafeFadeIn()

    if type(reopenChoice) == "table" and reopenChoice.completed ~= true then
        SetNuiFocus(true, true)
        SendNUIMessage({ type = "vipChoiceOpen", payload = reopenChoice })
    else
        SetNuiFocus(false, false)
    end
end

local function mgRequestVipFinish(fallbackReturn, failureMessage)
    if MG_SAFE_VIP.finishPending then return end

    MG_SAFE_VIP.exiting = true
    MG_SAFE_VIP.finishSeq = (tonumber(MG_SAFE_VIP.finishSeq) or 0) + 1
    local requestId = tostring(GetPlayerServerId(PlayerId())) .. ":" .. tostring(GetGameTimer()) .. ":" .. tostring(MG_SAFE_VIP.finishSeq)
    MG_SAFE_VIP.finishPending = {
        id = requestId,
        fallbackReturn = type(fallbackReturn) == "table" and fallbackReturn or MG_SAFE_VIP.returnPosition,
        failureMessage = tostring(failureMessage or "")
    }

    TriggerServerEvent(MG_VIP_FINISH_REQUEST, requestId)

    -- Failsafe absoluto: nunca deixa tela preta/foco preso se uma resposta de
    -- rede se perder. O servidor normalmente responde em poucos milissegundos.
    CreateThread(function()
        Wait(5000)
        local pending = MG_SAFE_VIP.finishPending
        if not pending or tostring(pending.id) ~= requestId then return end

        MG_SAFE_VIP.finishPending = nil
        MG_SAFE_VIP.exiting = false
        mgSafeFadeIn()
        mgNotify("negado", pending.failureMessage ~= "" and pending.failureMessage or "O servidor demorou para encerrar o teste. Sua tela foi restaurada.", 6500)
        mgRestoreVipPlayer(pending.fallbackReturn, nil)
    end)
end

local function mgFinishVipTest()
    if not MG_SAFE_VIP.active or MG_SAFE_VIP.exiting then return end
    mgRequestVipFinish(MG_SAFE_VIP.returnPosition, "Nao foi possivel encerrar o teste normalmente.")
end

local function mgAbortVipTest(message, fallbackReturn)
    -- O fade volta ANTES de qualquer round-trip de rede. Mesmo se o servidor
    -- estiver com problema, o jogador nunca permanece em tela preta.
    mgSafeFadeIn()
    if message and message ~= "" then
        mgNotify("negado", message, 7000)
    end

    mgRequestVipFinish(fallbackReturn or MG_SAFE_VIP.returnPosition, "Falha ao finalizar a sessao VIP apos um erro no test-drive.")
end

RegisterNetEvent(MG_VIP_FINISH_RESPONSE)
AddEventHandler(MG_VIP_FINISH_RESPONSE, function(requestId, response)
    requestId = tostring(requestId or "")
    local pending = MG_SAFE_VIP.finishPending
    if not pending or tostring(pending.id) ~= requestId then return end

    MG_SAFE_VIP.finishPending = nil
    response = type(response) == "table" and response or {}
    local data = type(response.data) == "table" and response.data or {}

    -- Mesmo se o server disser que a sessao ja nao existe, restaura localmente
    -- para impedir tela preta/foco travado. Quando ok, tambem reabre a escolha.
    if response.ok == false then
        mgNotify("negado", response.message or pending.failureMessage or "Nao foi possivel encerrar o teste.", 5500)
    end

    mgRestoreVipPlayer(data.returnPosition or pending.fallbackReturn or MG_SAFE_VIP.returnPosition, response.ok ~= false and data.choice or nil)
end)

-- --------------------------------------------------------------------------
-- Spawn administrativo resiliente. O server protegido continua validando a
-- permissao "spawn_veh" e apenas entao dispara este evento.
-- --------------------------------------------------------------------------
RegisterNetEvent("m_paineladm_v2:spawnVehicleSafe")
AddEventHandler("m_paineladm_v2:spawnVehicleSafe", function(vehicleName)
    vehicleName = tostring(vehicleName or ""):lower()
    if vehicleName == "" then return end

    CreateThread(function()
        local ok, err = pcall(function()
            local model = joaat(vehicleName)
            if not IsModelInCdimage(model) or not IsModelAVehicle(model) then
                mgNotify("negado", "Veiculo invalido: " .. vehicleName, 5000)
                mgUiToast("error", "Veiculo invalido: " .. vehicleName)
                return
            end

            if not mgWaitModel(model, 8000) then
                mgNotify("negado", "Nao foi possivel carregar o veiculo.", 5000)
                mgUiToast("error", "Falha ao carregar o veiculo.")
                return
            end

            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            local forward = GetEntityForwardVector(ped)
            local distance = math.max(1.5, math.min(4.0, tonumber(ClientConfig.SpawnDistance) or 2.5))

            RequestCollisionAtCoord(coords.x, coords.y, coords.z)

            local vehicle = CreateVehicle(
                model,
                coords.x + forward.x * distance,
                coords.y + forward.y * distance,
                coords.z + 0.35,
                heading,
                true,
                true
            )
            SetModelAsNoLongerNeeded(model)

            if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
                mgNotify("negado", "Falha ao criar o veiculo.", 5000)
                mgUiToast("error", "Falha ao criar o veiculo.")
                return
            end

            mgPrepareNetworkVehicle(vehicle)
            SetEntityAsMissionEntity(vehicle, true, true)
            SetVehicleOnGroundProperly(vehicle)
            SetVehicleEngineOn(vehicle, true, true, false)
            SetVehicleDirtLevel(vehicle, 0.0)

            local entered = mgWarpPedIntoDriverSeat(ped, vehicle)
            if not entered then
                mgNotify("negado", "O veiculo foi criado, mas nao foi possivel colocar voce no banco do motorista.", 6500)
                mgUiToast("error", "Veiculo criado, mas falhou ao entrar automaticamente.")
                return
            end

            mgNotify("sucesso", "Veiculo spawnado: " .. vehicleName, 4500)
            mgUiToast("success", "Veiculo spawnado: " .. vehicleName)
        end)

        if not ok then
            print(("^1[m_paineladm_v2] Falha no spawn seguro de veiculo: %s^0"):format(tostring(err)))
            mgNotify("negado", "Falha interna ao spawnar o veiculo.", 6000)
        end
    end)
end)

-- --------------------------------------------------------------------------
-- Seletor/test-drive VIP totalmente fora do client.lua ofuscado.
-- --------------------------------------------------------------------------
RegisterNetEvent("m_paineladm_v2:vipChoiceOpenSafe")
AddEventHandler("m_paineladm_v2:vipChoiceOpenSafe", function(payload)
    if MG_SAFE_VIP.active or MG_SAFE_VIP.starting then return end
    mgClearVipOverlay(MG_SAFE_VIP.session)
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "vipChoiceOpen", payload = type(payload) == "table" and payload or {} })
end)

RegisterNetEvent("m_paineladm_v2:vipChoiceCloseSafe")
AddEventHandler("m_paineladm_v2:vipChoiceCloseSafe", function(message)
    if not MG_SAFE_VIP.active and not MG_SAFE_VIP.starting then
        mgClearVipOverlay(MG_SAFE_VIP.session)
        SetNuiFocus(false, false)
    end
    SendNUIMessage({ type = "vipChoiceClose", message = tostring(message or "") })
end)

RegisterNetEvent("m_paineladm_v2:vipTestStartSafe")
AddEventHandler("m_paineladm_v2:vipTestStartSafe", function(payload)
    if MG_SAFE_VIP.active or MG_SAFE_VIP.starting then return end
    MG_SAFE_VIP.starting = true
    payload = type(payload) == "table" and payload or {}

    CreateThread(function()
        local ok, err = pcall(function()
            local center = type(payload.center) == "table" and payload.center or {}
            local spawn = tostring(payload.vehicle or ""):lower()
            if spawn == "" then
                MG_SAFE_VIP.starting = false
                mgAbortVipTest("Veiculo de teste invalido.", payload.returnPosition)
                return
            end

            local model = joaat(spawn)
            if not IsModelInCdimage(model) or not IsModelAVehicle(model) then
                MG_SAFE_VIP.starting = false
                mgAbortVipTest("Este veiculo nao esta carregado no servidor.", payload.returnPosition)
                return
            end

            -- Fecha o painel administrativo, caso o staff tenha entregue o VIP
            -- para si mesmo. Ha fallback direto na NUI para nunca prender foco.
            local closeResponse = mgClientCoreCall("closePanel", {})
            if not closeResponse or closeResponse.ok == false then
                SetNuiFocus(false, false)
                SendNUIMessage({ type = "close" })
            end

            SetNuiFocus(false, false)
            SendNUIMessage({ type = "vipChoiceClose" })

            if not mgWaitModel(model, 9000) then
                MG_SAFE_VIP.starting = false
                mgAbortVipTest("Nao foi possivel carregar o veiculo para teste.", payload.returnPosition)
                return
            end

            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local previousVehicle = GetVehiclePedIsIn(ped, false)
                TaskLeaveVehicle(ped, previousVehicle, 16)
                local leaveDeadline = GetGameTimer() + 1500
                while IsPedInAnyVehicle(ped, false) and GetGameTimer() < leaveDeadline do Wait(0) end
                if IsPedInAnyVehicle(ped, false) then
                    ClearPedTasksImmediately(ped)
                end
            end

            local cx = tonumber(center.x) or -1291.34
            local cy = tonumber(center.y) or -2980.99
            local cz = tonumber(center.z) or 13.93
            local ch = tonumber(center.h) or 330.0

            MG_SAFE_VIP.session = (tonumber(MG_SAFE_VIP.session) or 0) + 1
            MG_SAFE_VIP.returnPosition = type(payload.returnPosition) == "table" and payload.returnPosition or {}
            MG_SAFE_VIP.center = { x = cx, y = cy, z = cz, h = ch }
            MG_SAFE_VIP.radius = math.max(25.0, tonumber(payload.radius) or 150.0)
            MG_SAFE_VIP.endsAt = GetGameTimer() + (math.max(1, tonumber(payload.seconds) or 60) * 1000)

            RequestCollisionAtCoord(cx, cy, cz)
            DoScreenFadeOut(180)
            local fadeDeadline = GetGameTimer() + 800
            while not IsScreenFadedOut() and GetGameTimer() < fadeDeadline do Wait(0) end

            -- Daqui para frente qualquer falha precisa obrigatoriamente fazer
            -- FadeIn via mgAbortVipTest/pcall para nunca deixar tela preta.
            SetEntityCoordsNoOffset(ped, cx, cy, cz + 0.35, false, false, false)
            SetEntityHeading(ped, ch)
            Wait(80)

            local vehicle = CreateVehicle(model, cx, cy, cz + 0.35, ch, true, true)
            SetModelAsNoLongerNeeded(model)

            if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
                MG_SAFE_VIP.starting = false
                mgAbortVipTest("Falha ao criar o veiculo de teste.", payload.returnPosition)
                return
            end

            MG_SAFE_VIP.vehicle = vehicle
            mgPrepareNetworkVehicle(vehicle)
            SetEntityAsMissionEntity(vehicle, true, true)
            SetVehicleOnGroundProperly(vehicle)
            SetVehicleEngineOn(vehicle, true, true, false)
            SetVehicleDirtLevel(vehicle, 0.0)

            if not mgWarpPedIntoDriverSeat(ped, vehicle) then
                MG_SAFE_VIP.starting = false
                mgAbortVipTest("O veiculo de teste foi criado, mas nao foi possivel entrar nele.", payload.returnPosition)
                return
            end

            MG_SAFE_VIP.active = true
            MG_SAFE_VIP.starting = false
            MG_SAFE_VIP.exiting = false

            Wait(80)
            mgSafeFadeIn()

            SendNUIMessage({
                type = "vipTestOverlay",
                active = true,
                vehicleName = tostring(payload.vehicleName or spawn),
                seconds = math.max(1, tonumber(payload.seconds) or 60),
                session = MG_SAFE_VIP.session
            })
        end)

        if not ok then
            print(("^1[m_paineladm_v2] Falha no test-drive VIP seguro: %s^0"):format(tostring(err)))
            MG_SAFE_VIP.starting = false
            MG_SAFE_VIP.active = MG_SAFE_VIP.vehicle ~= 0 and DoesEntityExist(MG_SAFE_VIP.vehicle)
            mgAbortVipTest("Falha interna ao iniciar o test-drive VIP.", payload.returnPosition)
        end
    end)
end)

RegisterNetEvent("m_paineladm_v2:vipTestForceStopSafe")
AddEventHandler("m_paineladm_v2:vipTestForceStopSafe", function(returnPosition)
    if MG_SAFE_VIP.active or MG_SAFE_VIP.starting or (MG_SAFE_VIP.vehicle ~= 0 and DoesEntityExist(MG_SAFE_VIP.vehicle)) then
        mgRestoreVipPlayer(returnPosition or MG_SAFE_VIP.returnPosition, nil)
    else
        mgSafeFadeIn()
        SetNuiFocus(false, false)
        mgClearVipOverlay(MG_SAFE_VIP.session)
    end
end)

RegisterCommand("m_paineladm_v2_viptest_exit_safe", function()
    if MG_SAFE_VIP.active then
        mgFinishVipTest()
    end
end, false)
RegisterKeyMapping("m_paineladm_v2_viptest_exit_safe", "Sair do teste de veiculo VIP", "keyboard", "F7")

CreateThread(function()
    local lastSecond = -1
    while true do
        if MG_SAFE_VIP.active then
            Wait(100)
            local ped = PlayerPedId()
            local vehicle = tonumber(MG_SAFE_VIP.vehicle) or 0
            local entity = (vehicle ~= 0 and DoesEntityExist(vehicle)) and vehicle or ped
            local coords = GetEntityCoords(entity)
            local center = MG_SAFE_VIP.center

            if center then
                local dx = (tonumber(coords.x) or 0.0) - (tonumber(center.x) or 0.0)
                local dy = (tonumber(coords.y) or 0.0) - (tonumber(center.y) or 0.0)
                local dz = (tonumber(coords.z) or 0.0) - (tonumber(center.z) or 0.0)
                local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
                if distance > MG_SAFE_VIP.radius then
                    if vehicle ~= 0 and DoesEntityExist(vehicle) then
                        SetEntityCoordsNoOffset(vehicle, center.x, center.y, center.z + 0.35, false, false, false)
                        SetEntityHeading(vehicle, tonumber(center.h) or 330.0)
                        SetVehicleOnGroundProperly(vehicle)
                        mgWarpPedIntoDriverSeat(ped, vehicle)
                    else
                        SetEntityCoordsNoOffset(ped, center.x, center.y, center.z + 0.35, false, false, false)
                    end
                    mgNotify("aviso", ("Voce chegou ao limite de %d metros da area de teste."):format(math.floor(MG_SAFE_VIP.radius)), 3500)
                end
            end

            local remaining = math.max(0, math.ceil((MG_SAFE_VIP.endsAt - GetGameTimer()) / 1000))
            if remaining ~= lastSecond then
                lastSecond = remaining
                SendNUIMessage({ type = "vipTestOverlay", active = true, seconds = remaining, session = MG_SAFE_VIP.session })
            end

            if IsControlJustPressed(0, 168) or IsDisabledControlJustPressed(0, 168) or remaining <= 0 or IsEntityDead(ped) then
                mgFinishVipTest()
                lastSecond = -1
            elseif vehicle ~= 0 and (not DoesEntityExist(vehicle) or IsEntityDead(vehicle)) then
                mgFinishVipTest()
                lastSecond = -1
            end
        else
            lastSecond = -1
            Wait(500)
        end
    end
end)

-- A resposta do botao "Pegar veiculo" tambem precisa liberar o foco sem
-- depender do client.lua protegido. A propria NUI atualiza os cards/restantes.
AddEventHandler(MG_VIP_RESPONSE_EVENT, function(requestData, responseData)
    requestData = type(requestData) == "table" and requestData or {}
    responseData = type(responseData) == "table" and responseData or {}
    local mode = tostring(requestData.mode or "")

    if mode == "startTest" and responseData.ok == true then
        -- Fallback de foco: o evento vipTestStartSafe tambem faz isso, mas a
        -- resposta do bridge garante que a NUI jamais permaneça capturando o
        -- mouse caso o evento de inicio sofra atraso de rede/streaming.
        SetNuiFocus(false, false)
        SendNUIMessage({ type = "vipChoiceClose" })
    elseif mode == "choose" and responseData.ok == true and type(responseData.data) == "table" and responseData.data.completed == true then
        SetNuiFocus(false, false)
        SendNUIMessage({ type = "vipChoiceClose" })
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    mgDeleteSafeVipVehicle()
    mgSafeFadeIn()
    SetNuiFocus(false, false)
end)

print("^2[m_paineladm_v2] Rotinas client-side criticas v2.90.5 carregadas fora da ofuscacao.^0")
