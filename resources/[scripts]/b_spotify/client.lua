local display = false
local prop = nil
local propNetId = nil
local Config = {}
local SharedConfig = {}
local isPlaying = false
local currentVolume = 100
local inVehicle = false
local currentVehicle = nil
local lastVehicle = nil
local lastPropCheck = 0
local propCheckInterval = 500 -- AUMENTADO: de 100ms para 500ms
local soundEnabled = true
local bluetoothMode = 'prop'
local audioSources = {}
local djAudioSources = {} -- Fontes de áudio de DJ
local isMuted = false -- Status de mute do jogador
local djBlips = {} -- Blips das mesas de DJ
local debugMode = true
local isDJMode = false -- Variável para controlar modo DJ
local lastPlayerPosition = nil -- Para sincronização de posição
local lastVehiclePosition = nil -- Para sincronização de veículo
local currentStereoPan = 0 -- Para controle de estéreo

-- NOVO: Variáveis para controle de throttling
local lastNetworkUpdate = 0
local networkUpdateInterval = 250 -- OTIMIZADO: Atualizar rede a cada 250ms em vez de 1ms
local lastVolumeUpdate = 0
local volumeUpdateInterval = 100 -- OTIMIZADO: Volume a cada 100ms
local positionUpdateThreshold = 2.0 -- OTIMIZADO: Só atualizar se mover mais de 2 metros
local manualVolume = nil
local userLockedMaxVolume = false
local lastPosition = nil
local currentDJStation = nil
local deleteProp

-- NOVO: Variáveis para mini player
local miniPlayerData = {
    isVisible = false,
    currentTrack = nil,
    isDJMode = false,
    isPlaying = false
}

-- MODIFICAÇÃO 2: Variável para controlar bluetooth automático
local autoBluetoothEnabled = false

-- Carregar configurações de DJ
local djStationsFile = LoadResourceFile(GetCurrentResourceName(), "config/dj_stations.lua")
if djStationsFile then
    load(djStationsFile)()
else
    print("^1[ERRO] Não foi possível carregar config/dj_stations.lua^0")
    DJStations = {}
    DJConfig = {}
end

-- Função auxiliar para debug
function DebugLog(message)
    if debugMode then
        --print('[DEBUG] ' .. message)
    end
end

-- Load configs
Citizen.CreateThread(function()
    Config = LoadResourceFile(GetCurrentResourceName(), "config.lua")
    Config = load(Config)()
    
    SharedConfig = LoadResourceFile(GetCurrentResourceName(), "shared/config.lua")
    SharedConfig = load(SharedConfig)()
    
    DebugLog("Configurações carregadas com sucesso")
end)

-- NOVO: Callback para retomar reprodução e reanexar prop se necessário
RegisterNUICallback('resumePlayback', function(data, cb)
    DebugLog("🎵 === CALLBACK resumePlayback RECEBIDO ===")

    -- Ao retomar, se estiver fora do veículo e no modo prop:
    if not inVehicle then
        -- Se não existir prop, criar
        if not prop then
            DebugLog("🎵 Sem prop ao retomar - criando prop")
            createProp()
        -- Se existir prop e estiver no chão (desanexado), reanexar na mão
        elseif prop and not IsEntityAttached(prop) then
            AttachEntityToEntity(prop, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.30, 0, 0, 0, 260.0, 60.0, true, true, false, true, 1, true)
            DebugLog("🎵 Prop reanexado à mão ao retomar música")
        end
    else
        DebugLog("🚗 Em veículo ou não é modo prop - não reanexar")
    end

    cb('ok')
end)

-- Criar blips das mesas de DJ
Citizen.CreateThread(function()
    if not DJConfig.showBlips then return end
    
    for i, station in ipairs(DJStations) do
        if station.blip and station.blip.display then
            local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
            SetBlipSprite(blip, station.blip.sprite)
            SetBlipColour(blip, station.blip.color)
            SetBlipScale(blip, station.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Mesa de DJ - " .. station.name)
            EndTextCommandSetBlipName(blip)
            
            djBlips[i] = blip
            DebugLog("Blip criado para mesa de DJ: " .. station.name)
        end
    end
end)

-- OTIMIZADO: Thread para mostrar marcadores das mesas de DJ (reduzida frequência)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(20) -- OTIMIZADO: de 0ms para 100ms
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local nearDJ = false
        
        for i, station in ipairs(DJStations) do
            local distance = #(playerCoords - station.coords)
            
            if distance <= 15.0 then
                -- Desenhar marcador
                DrawMarker(27, station.coords.x, station.coords.y, station.coords.z - 1.0, 
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                    1.0, 1.0, 0.10, 
                    255, 20, 51, 150,
                    false, true, 2, false, nil, nil, false)
                
                if distance <= (DJConfig.interactionDistance or 3.0) then
                    nearDJ = true
                    DrawText3D(station.coords.x, station.coords.y, station.coords.z + 0.10, 
                        "[E] Mesa de DJ - " .. station.name, 0.3)
                    
                    if IsControlJustPressed(0, 38) then -- E key
                        DebugLog("🎧 Jogador pressionou E na mesa DJ: " .. station.name)
                        TriggerServerEvent('music:requestDJMenu', i)
                    end
                end
            end
        end
        
        if not nearDJ then
            Citizen.Wait(500) -- OTIMIZADO: Esperar mais quando não há DJ próximo
        end
    end
end)

-- Função para desenhar texto 3D
function DrawText3D(x, y, z, text, scale)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Evento para definir status de mute
RegisterNetEvent('music:setMuteStatus')
AddEventHandler('music:setMuteStatus', function(muteStatus)
    isMuted = muteStatus
    DebugLog("Status de mute alterado: " .. tostring(isMuted))
    
    if isMuted then
        SendNUIMessage({
            type = "setGlobalMute",
            muted = true
        })
    else
        SendNUIMessage({
            type = "setGlobalMute",
            muted = false
        })
    end
end)

-- NOVO: Evento para atualizar volume de uma fonte específica
RegisterNetEvent('music:updateSourceVolume')
AddEventHandler('music:updateSourceVolume', function(data)
    local sourcePlayer = data.sourcePlayer
    local volume = data.volume
    
    DebugLog("Atualizando volume da fonte " .. sourcePlayer .. " para " .. volume .. "%")
    
    -- Atualizar volume no NUI se for uma fonte externa
    if audioSources[sourcePlayer] then
        SendNUIMessage({
            type = "updateExternalTrack",
            sourceId = sourcePlayer,
            volume = volume,
            realTime = false
        })
    end
end)

-- Prop handling functions
local function loadModel(modelName)
    local modelHash = type(modelName) == 'string' and GetHashKey(modelName) or modelName

    -- Valida se o modelo existe no CD image
    if not IsModelInCdimage(modelHash) or not IsModelValid(modelHash) then
        DebugLog("Modelo JBL não encontrado: " .. tostring(modelName))
        return nil
    end

    -- Requisita o modelo com timeout para evitar loop infinito
    RequestModel(modelHash)
    local start = GetGameTimer()
    while not HasModelLoaded(modelHash) do
        Wait(10)
        if GetGameTimer() - start > 8000 then
            DebugLog("Timeout ao carregar modelo JBL: " .. tostring(modelName))
            return nil
        end
    end

    return modelHash
end

-- Constrói possíveis variações do nome do modelo para tentar carregar
local function getModelCandidates(base)
    local list = {}
    local function add(name)
        if name and name ~= '' then
            for _, n in ipairs(list) do
                if n == name then return end
            end
            table.insert(list, name)
        end
    end

    add(base)
    if type(base) == 'string' then
        -- Variações comuns: com e sem underscore antes do sufixo 01
        add(base:gsub('_', ''))
        add(base:gsub('01$', '_01'))
        add(base:gsub('_01$', '01'))
        -- Modelos conhecidos deste recurso
        add('rojo_jblboombox')
        add('rojo_jblboombox01')
    end

    return list
end

local function createProp()
    if prop or inVehicle then return end

    local baseName = (SharedConfig and SharedConfig.prop) or "rojo_jblboombox01"
    local candidates = getModelCandidates(baseName)
    local modelName, modelHash

    for _, name in ipairs(candidates) do
        DebugLog("Tentando carregar modelo JBL: " .. tostring(name))
        modelHash = loadModel(name)
        if modelHash then
            modelName = name
            break
        end
    end

    if not modelHash then
        local fallbackName = (SharedConfig and SharedConfig.propFallback) or "prop_boombox_01"
        DebugLog("Falha nas tentativas de modelo JBL, usando fallback: " .. tostring(fallbackName))
        local fallbackHash = loadModel(fallbackName)
        if not fallbackHash then
            DebugLog("Falha ao carregar modelo JBL e fallback: " .. tostring(baseName) .. " / " .. tostring(fallbackName))
            return
        end
        modelName = fallbackName
        modelHash = fallbackHash
    end

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    prop = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, true)
    propNetId = NetworkGetNetworkIdFromEntity(prop)
    SetModelAsNoLongerNeeded(modelHash)

    AttachEntityToEntity(prop, playerPed, GetPedBoneIndex(playerPed, 57005), 0.30, 0, 0, 0, 260.0, 60.0, true, true, false, true, 1, true)
    DebugLog("Prop criado e anexado ao jogador: " .. tostring(modelName))
end

-- Evento para trocar o modelo do prop dinamicamente
RegisterNetEvent('foxzinlafy:setPropModel')
AddEventHandler('foxzinlafy:setPropModel', function(newModel)
    if type(newModel) ~= 'string' or newModel == '' then return end
    SharedConfig = SharedConfig or {}
    SharedConfig.prop = newModel

    -- Reinicia o prop se já estiver criado para aplicar o novo modelo
    if prop then
        deleteProp()
        createProp()
    end

    TriggerEvent('Notify','aviso','Modelo JBL atualizado para: '..tostring(newModel))
    DebugLog('Modelo JBL atualizado dinamicamente para: '..tostring(newModel))
end)

-- MODIFICAÇÃO 1: Função deleteProp modificada para ser chamada quando pausar
deleteProp = function()
    if prop then
        DetachEntity(prop, true, true)
        DeleteObject(prop)
        prop = nil
        propNetId = nil
        DebugLog("Prop removido")
    end
end

-- NOVO: Funções do Mini Player
function ShowMiniPlayerIfNeeded(trackData, isDJMode)
    if not IsNuiFocused() and trackData and isPlaying then
        miniPlayerData.isVisible = true
        miniPlayerData.currentTrack = trackData
        miniPlayerData.isDJMode = isDJMode or false
        miniPlayerData.isPlaying = true
        
        SendNUIMessage({
            type = 'showMiniPlayer',
            trackData = trackData,
            djMode = isDJMode,
            isPlaying = true
        })
        
        DebugLog("🎵 Mini player mostrado: " .. trackData.title)
    end
end

function HideMiniPlayer()
    if miniPlayerData.isVisible then
        miniPlayerData.isVisible = false
        
        SendNUIMessage({
            type = 'hideMiniPlayer'
        })
        
        DebugLog("🔽 Mini player escondido")
    end
end

function UpdateMiniPlayerDJMode(isDJModeActive, stationData)
    miniPlayerData.isDJMode = isDJModeActive
    
    if miniPlayerData.isVisible then
        SendNUIMessage({
            type = 'setMiniDJMode',
            enabled = isDJModeActive,
            stationData = stationData
        })
    end
end

function UpdateMiniPlayerTrackInfo(trackData)
    if miniPlayerData.isVisible then
        miniPlayerData.currentTrack = trackData
        
        SendNUIMessage({
            type = 'updateMiniPlayer',
            trackData = trackData,
            djMode = miniPlayerData.isDJMode
        })
    end
end

function SetMiniPlayerPlayState(playing)
    miniPlayerData.isPlaying = playing
    
    if miniPlayerData.isVisible then
        SendNUIMessage({
            type = 'updateMiniPlayState',
            isPlaying = playing
        })
    end
    
    -- MODIFICADO: Esconder mini player imediatamente quando pausar
    if not playing then
        HideMiniPlayer()
    end
end

-- NOVO: Callbacks para ações do mini player
RegisterNUICallback('miniPlayerAction', function(data, cb)
    local action = data.action
    DebugLog("🎵 Ação do mini player recebida: " .. action)
    
    if action == 'playPause' then
        -- Alternar play/pause
        if isPlaying then
            DebugLog("🎵 Mini player: Pausando música")
            
            -- Pausar no NUI principal
            SendNUIMessage({
                type = "pausePlayback"
            })
            
            -- Enviar comando de pause para o servidor
            if isDJMode and currentDJStation then
                TriggerServerEvent('music:stopDJAudio', currentDJStation.stationIndex)
            else
                TriggerServerEvent('music:stopAudio')
            end
            
            isPlaying = false
            SetMiniPlayerPlayState(false)
        else
            DebugLog("🎵 Mini player: Retomando música")
            
            -- Retomar no NUI principal
            SendNUIMessage({
                type = "resumePlayback"
            })
            
            isPlaying = true
            SetMiniPlayerPlayState(true)
        end
        
    elseif action == 'previous' then
        DebugLog("🎵 Mini player: Música anterior")
        
        -- Enviar comando para tocar música anterior
        SendNUIMessage({
            type = "playPrevious"
        })
        
    elseif action == 'next' then
        DebugLog("🎵 Mini player: Próxima música")
        
        -- Enviar comando para tocar próxima música
        SendNUIMessage({
            type = "playNext"
        })
    end
    
    cb('ok')
end)

-- NOVO: Callback para abrir UI principal do mini player
RegisterNUICallback('openMainUI', function(data, cb)
    DebugLog("🎵 Mini player: Abrindo UI principal")
    
    -- Esconder mini player
    HideMiniPlayer()
    
    -- Abrir UI principal
    SetDisplay(true)
    
    cb('ok')
end)

-- SUPER OTIMIZADO: Thread para sincronização de posição (MUITO menos frequente)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100) -- ATUALIZADO: 10ms em vez de 250ms

        if isPlaying then
            local currentTime = GetGameTimer()

            -- OTIMIZADO: Só atualizar se passou tempo suficiente
            if currentTime - lastNetworkUpdate < networkUpdateInterval then
                goto continue
            end

            local shouldUpdate = false
            local updateData = {
                playerCoords = GetEntityCoords(PlayerPedId()),
                sourceCoords = nil,
                sourceType = nil,
                propNetId = nil,
                vehicleNetId = nil,
                stationIndex = nil
            }

            -- OTIMIZADO: Verificar se posição mudou significativamente
            if lastPlayerPosition then
                local distance = #(updateData.playerCoords - lastPlayerPosition)
                if distance < positionUpdateThreshold then
                    goto continue -- Não atualizar se não se moveu muito
                end
            end

            lastPlayerPosition = updateData.playerCoords

            -- DJ - Sincronização menos frequente
            if isDJMode and currentDJStation then
                local stationData = DJStations[currentDJStation.stationIndex]
                if stationData then
                    updateData.sourceCoords = stationData.coords
                    updateData.sourceType = "dj"
                    updateData.stationIndex = currentDJStation.stationIndex
                    shouldUpdate = true
                end
            elseif prop and bluetoothMode == 'prop' then
                local propCoords = GetEntityCoords(prop)
                updateData.sourceCoords = propCoords
                updateData.sourceType = "prop"
                updateData.propNetId = propNetId
                shouldUpdate = true
            elseif (currentVehicle or lastVehicle) and bluetoothMode == 'car' then
                local vehicle = currentVehicle or lastVehicle
                if vehicle and DoesEntityExist(vehicle) then
                    local vehicleCoords = GetEntityCoords(vehicle)
                    updateData.sourceCoords = vehicleCoords
                    updateData.sourceType = "vehicle"
                    updateData.vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
                    shouldUpdate = true
                end
            end

            -- OTIMIZADO: Só enviar se realmente necessário
            if shouldUpdate and updateData.sourceCoords then
                TriggerServerEvent('music:updateAudioSource', updateData)
                lastNetworkUpdate = currentTime
            end
        end

        ::continue::
    end
end)


-- Função auxiliar para calcular a posição relativa entre dois pontos considerando o heading
function GetPositionBetweenPoints(playerPos, targetPos, heading)
    local distance = #(playerPos - targetPos)
    
    local dx = targetPos.x - playerPos.x
    local dy = targetPos.y - playerPos.y
    local angle = math.atan2(dy, dx)
    
    local headingRad = math.rad(heading)
    local relativeAngle = angle - headingRad
    
    local relX = distance * math.cos(relativeAngle)
    local relY = distance * math.sin(relativeAngle)
    
    return distance, relX, relY
end

-- Função de utilidade para limitar um valor entre min e max
function math.clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

-- Register NUI Callback for Bluetooth toggle
RegisterNUICallback('toggleBluetooth', function(data, cb)
    if inVehicle then
        if bluetoothMode == 'car' then
            bluetoothMode = 'prop'
            createProp()
        else
            bluetoothMode = 'car'
            deleteProp()
        end
    else
        if bluetoothMode == 'prop' then
            bluetoothMode = 'none'
            if isPlaying then
                SendNUIMessage({
                    type = "pausePlayback"
                })
            end
            deleteProp()
        else
            bluetoothMode = 'prop'
            createProp()
            if isPlaying then
                SendNUIMessage({
                    type = "resumePlayback"
                })
            end
        end
    end
    
    DebugLog("Bluetooth modo alterado: " .. bluetoothMode)
    
    cb({
        success = true,
        mode = bluetoothMode
    })
end)

-- MODIFICAÇÃO 2: Vehicle check thread modificado para bluetooth automático
Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local time = 250 -- OTIMIZADO: de 500ms para 1000ms

        if IsPedInAnyVehicle(ped, false) and vehicle ~= 0 then
            if not inVehicle then
                inVehicle = true
                currentVehicle = vehicle
                lastVehicle = vehicle
                if prop then
                    deleteProp()
                    prop = nil
                    propNetId = nil
                end
                
                -- MODIFICAÇÃO 2: Ativar bluetooth automaticamente ao entrar no carro
                bluetoothMode = 'car'
                autoBluetoothEnabled = true
                
                TriggerEvent('Notify', 'sucesso', 'Bluetooth conectado automaticamente ao veículo!')
                DebugLog("Jogador entrou no veículo: " .. vehicle .. " - Bluetooth ativado automaticamente")
            end            
        else
            if inVehicle then
                lastVehicle = currentVehicle
                DebugLog("Jogador saiu do veículo - Música continua se modo carro ativo")
            end
            inVehicle = false
            currentVehicle = nil
            
            if isPlaying and bluetoothMode == 'car' and lastVehicle and DoesEntityExist(lastVehicle) then
                DebugLog("🚗 Mantendo música ativa - modo carro fora do veículo")
            end
        end

        if lastVehicle and not DoesEntityExist(lastVehicle) then
            if isPlaying and bluetoothMode == 'car' then
                isPlaying = false
                SendNUIMessage({
                    type = "forceStop"
                })
                DebugLog("Veículo removido, música parada")
                
                -- NOVO: Esconder mini player quando música para
                HideMiniPlayer()
            end
            lastVehicle = nil
        end

        Wait(time)
    end
end)

-- OTIMIZADO: Verificação de distância do prop menos frequente
local function checkPropDistance()
    if not isPlaying or not prop or inVehicle then return end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local propCoords = GetEntityCoords(prop)
    local distance = #(playerCoords - propCoords)
    
    if distance > (SharedConfig.maxDistance or math.huge) then
        isPlaying = false
        SendNUIMessage({
            type = "forceStop"
        })
        if not IsEntityAttached(prop) then
            deleteProp()
        end
        DebugLog("Prop muito distante, música parada")
        
        -- NOVO: Esconder mini player quando música para
        HideMiniPlayer()
    end
end

RegisterCommand("volume", function(source, args)
    local vol = tonumber(args[1])
    if vol and vol >= 0 and vol <= 100 then
        manualVolume = vol
        
        -- MODIFICAÇÃO 3: Sincronizar volume com servidor para outros jogadores
        TriggerServerEvent('music:syncPlayerVolume', vol)
        
        TriggerEvent("chat:addMessage", {
            args = { "🔊 Volume definido para: " .. vol .. ". Modo automático será reativado ao se mover." }
        })
        DebugLog("Volume manual definido: " .. vol)
    else
        TriggerEvent("chat:addMessage", {
            args = { "⚠️ Use: /volume [0-100]" }
        })
    end
end, false)

-- OTIMIZADO: Receber áudio de DJ com menos processamento
RegisterNetEvent('music:receiveDJAudio')
AddEventHandler('music:receiveDJAudio', function(audioData)
    if isMuted then 
        DebugLog("Áudio ignorado - usuário está mutado.")
        return 
    end

    local sourcePlayer = audioData.sourcePlayer
    local stationIndex = audioData.stationIndex
    local coords = audioData.sourceCoords
    local stationData = audioData.stationData

    DebugLog(("🎧 Áudio de DJ recebido de %s - Mesa: %s"):format(sourcePlayer, stationIndex))

    djAudioSources[stationIndex] = {
        videoId = audioData.videoId,
        title = audioData.title,
        thumbnail = audioData.thumbnail,
        duration = audioData.duration,
        sourcePlayer = sourcePlayer,
        sourceCoords = coords,
        sourceType = "dj",
        stationIndex = stationIndex,
        stationData = stationData,
        lastUpdate = GetGameTimer(),
        isRealTime = true
    }

    SendNUIMessage({
        type = "addDJTrack",
        sourceId = stationIndex,
        videoId = audioData.videoId,
        title = audioData.title,
        thumbnail = audioData.thumbnail,
        duration = audioData.duration,
        stationName = stationData.name,
        realTime = true
    })

    TriggerEvent('Notify', 'info', '🎧 DJ ' .. stationData.name .. ' está tocando música')
    DebugLog("🎧 Áudio de DJ processado.")

    -- NOVO: Mostrar mini player para DJ se não estiver visível
    if not miniPlayerData.isVisible then
        ShowMiniPlayerIfNeeded({
            title = audioData.title,
            artist = "DJ " .. stationData.name,
            thumbnail = audioData.thumbnail,
            videoId = audioData.videoId
        }, true)
    end
end)

-- Atualizar áudio de DJ
RegisterNetEvent('music:updateDJAudioSource')
AddEventHandler('music:updateDJAudioSource', function(updateData)
    local stationIndex = updateData.stationIndex
    
    if djAudioSources[stationIndex] then
        djAudioSources[stationIndex].sourceCoords = updateData.sourceCoords
        djAudioSources[stationIndex].lastUpdate = GetGameTimer()
        
        DebugLog("🎧 Coordenadas DJ atualizadas para mesa " .. stationIndex .. ": " .. 
            updateData.sourceCoords.x .. ", " .. updateData.sourceCoords.y .. ", " .. updateData.sourceCoords.z)
    end
end)

-- Remover áudio de DJ
RegisterNetEvent('music:removeDJAudioSource')
AddEventHandler('music:removeDJAudioSource', function(stationIndex)
    if djAudioSources[stationIndex] then
        djAudioSources[stationIndex] = nil
        
        SendNUIMessage({
            type = "removeDJTrack",
            sourceId = stationIndex
        })
        DebugLog("🎧 Fonte de áudio de DJ removida: " .. stationIndex)
    end
end)

-- OTIMIZADO: Receber áudio de outros jogadores
RegisterNetEvent('music:receiveAudio')
AddEventHandler('music:receiveAudio', function(audioData)
    if isMuted then return end
    
    local sourcePlayer = audioData.sourcePlayer
    
    DebugLog("🎵 Áudio recebido de " .. sourcePlayer .. " - Tipo: " .. (audioData.sourceType or "unknown"))
    
    audioSources[sourcePlayer] = {
        videoId = audioData.videoId,
        title = audioData.title,
        thumbnail = audioData.thumbnail,
        duration = audioData.duration,
        sourcePlayer = sourcePlayer,
        sourceCoords = audioData.sourceCoords,
        sourceType = audioData.sourceType,
        propNetId = audioData.propNetId,
        vehicleNetId = audioData.vehicleNetId,
        lastUpdate = GetGameTimer(),
        isRealTime = true
    }
    
    SendNUIMessage({
        type = "addExternalTrack",
        sourceId = sourcePlayer,
        videoId = audioData.videoId,
        title = audioData.title,
        thumbnail = audioData.thumbnail,
        duration = audioData.duration,
        realTime = true
    })
    
    DebugLog("🎵 Áudio externo recebido de " .. sourcePlayer)

    -- NOVO: Mostrar mini player para áudio externo se não estiver visível
    if not miniPlayerData.isVisible then
        ShowMiniPlayerIfNeeded({
            title = audioData.title,
            artist = "Jogador " .. sourcePlayer,
            thumbnail = audioData.thumbnail,
            videoId = audioData.videoId
        }, false)
    end
end)

-- Evento para atualizar coordenadas de uma fonte de áudio
RegisterNetEvent('music:updateAudioSource')
AddEventHandler('music:updateAudioSource', function(updateData)
    local sourcePlayer = updateData.sourcePlayer
    
    if audioSources[sourcePlayer] then
        audioSources[sourcePlayer].sourceCoords = updateData.sourceCoords
        audioSources[sourcePlayer].sourceType = updateData.sourceType
        audioSources[sourcePlayer].lastUpdate = GetGameTimer()
        
        DebugLog("🎵 Coordenadas atualizadas para fonte " .. sourcePlayer .. ": " .. 
            updateData.sourceCoords.x .. ", " .. updateData.sourceCoords.y .. ", " .. updateData.sourceCoords.z)
    end
end)

-- Adicionar evento para remover uma fonte de áudio
RegisterNetEvent('music:removeAudioSource')
AddEventHandler('music:removeAudioSource', function(sourcePlayerId)
    if audioSources[sourcePlayerId] then
        audioSources[sourcePlayerId] = nil
        
        SendNUIMessage({
            type = "removeExternalTrack",
            sourceId = sourcePlayerId
        })
        DebugLog("🎵 Fonte de áudio removida: " .. sourcePlayerId)
    end
end)

-- SUPER OTIMIZADO: Thread principal para verificar fontes de áudio (MUITO menos frequente)
-- SUPER OTIMIZADO: Thread principal para verificar fontes de áudio (MUITO menos frequente)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(20)

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local currentTime = GetGameTimer()

        local processedCount = 0
        local maxProcessPerFrame = 3

        -- Fontes normais
        for sourceId, sourceData in pairs(audioSources) do
            if processedCount >= maxProcessPerFrame then break end
            processedCount = processedCount + 1

            if isMuted then goto continue end

            local sourcePed = GetPlayerPed(GetPlayerFromServerId(sourceId))
            if not DoesEntityExist(sourcePed) then
                audioSources[sourceId] = nil
                SendNUIMessage({
                    type = "removeExternalTrack",
                    sourceId = sourceId
                })
                DebugLog("🎵 Fonte de áudio inválida removida: " .. sourceId)
            else
                local sourceCoords = sourceData.sourceCoords
                if sourceCoords then
                    local distance = #(playerCoords - sourceCoords)

                    local function getRangeForExternal(sourceType)
                        local ranges = SharedConfig.range
                        if sourceType == 'vehicle' then
                            if ranges and ranges.vehicle and type(ranges.vehicle.default) == 'number' then
                                return ranges.vehicle.default
                            end
                            return 20.0
                        elseif sourceType == 'prop' then
                            if ranges and ranges.radio then
                                local r = ranges.radio
                                if type(r) == 'table' then return r[1] elseif type(r) == 'number' then return r end
                            end
                            return 12.0
                        elseif sourceType == 'dj' then
                            if SharedConfig.dj and SharedConfig.dj[1] and SharedConfig.dj[1].range then
                                return SharedConfig.dj[1].range
                            end
                            return 35.0
                        end
                        return 10.0
                    end

                    local maxDistance = getRangeForExternal(sourceData.sourceType)

                    -- Atenuação externa com zona neutra e suavização
                    local att = SharedConfig.attenuation or {}
                    local perType = att.external or att[sourceData.sourceType] or {}
                    local nearRadius = perType.nearRadius or att.nearRadius or 1.5
                    local fadeStartRatio = perType.fadeStartRatio or att.fadeStartRatio or 0.5
                    local smoothing = perType.smoothingFactor or att.smoothingFactor or 0.2

                    local targetVolume = 100
                    if distance > maxDistance then
                        -- Fora do alcance: zera imediatamente (sem suavização)
                        targetVolume = 0
                    else
                        local fadeStart = maxDistance * fadeStartRatio
                        if distance <= nearRadius then
                            targetVolume = sourceData.lastVolume or 100
                        elseif distance > fadeStart then
                            local fadeRatio = (distance - fadeStart) / (maxDistance - fadeStart)
                            fadeRatio = fadeRatio * fadeRatio
                            targetVolume = math.floor(100 * (1.0 - fadeRatio))
                        else
                            targetVolume = 100
                        end
                    end

                    targetVolume = math.max(0, math.min(100, targetVolume))

                    local function smooth(prev, target, factor)
                        prev = prev or target
                        local f = math.clamp(factor or 0.2, 0.0, 1.0)
                        return prev + (target - prev) * f
                    end
                    local newVolume
                    if targetVolume == 0 then
                        newVolume = 0
                    else
                        newVolume = smooth(sourceData.lastVolume, targetVolume, smoothing)
                    end

                    if not sourceData.lastVolume or math.abs(newVolume - sourceData.lastVolume) >= 3 then
                        SendNUIMessage({
                            type = "updateExternalTrack",
                            sourceId = sourceId,
                            volume = math.floor(newVolume + 0.5),
                            realTime = false
                        })
                        sourceData.lastVolume = newVolume
                    end

                    audioSources[sourceId].lastUpdate = currentTime
                end
            end
            ::continue::
        end

        -- Fontes de DJ
        if processedCount < maxProcessPerFrame then
            for stationIndex, djData in pairs(djAudioSources) do
                if processedCount >= maxProcessPerFrame then break end
                processedCount = processedCount + 1

                if isMuted then goto continue_dj end

                local sourceCoords = djData.sourceCoords
                local distance = #(playerCoords - sourceCoords)
                local function getDJRange()
                    if SharedConfig.dj and SharedConfig.dj[1] and SharedConfig.dj[1].range then
                        return SharedConfig.dj[1].range
                    end
                    return 35.0
                end
                local maxRange = getDJRange()

                local maxVolume = 85

                -- Atenuação DJ com zona neutra e suavização
                local att = SharedConfig.attenuation or {}
                local perType = att.dj or {}
                local nearRadius = perType.nearRadius or att.nearRadius or 2.0
                local fadeStartRatio = perType.fadeStartRatio or att.fadeStartRatio or 0.6
                local smoothing = perType.smoothingFactor or att.smoothingFactor or 0.2

                local targetVolume = maxVolume
                if distance > maxRange then
                    -- Fora do alcance: zera imediatamente
                    targetVolume = 0
                else
                    local fadeStart = maxRange * fadeStartRatio
                    if distance <= nearRadius then
                        targetVolume = djData.lastVolume or maxVolume
                    elseif distance > fadeStart then
                        local fadeRatio = (distance - fadeStart) / (maxRange - fadeStart)
                        fadeRatio = fadeRatio * fadeRatio
                        targetVolume = math.floor(maxVolume * (1.0 - fadeRatio))
                    else
                        targetVolume = maxVolume
                    end
                end

                targetVolume = math.max(0, math.min(maxVolume, targetVolume))

                local function smooth(prev, target, factor)
                    prev = prev or target
                    local f = math.clamp(factor or 0.2, 0.0, 1.0)
                    return prev + (target - prev) * f
                end
                local newVolume
                if targetVolume == 0 then
                    newVolume = 0
                else
                    newVolume = smooth(djData.lastVolume, targetVolume, smoothing)
                end

                if not djData.lastVolume or math.abs(newVolume - djData.lastVolume) >= 3 then
                    SendNUIMessage({
                        type = "updateDJTrack",
                        sourceId = stationIndex,
                        volume = math.floor(newVolume + 0.5),
                        realTime = false
                    })
                    djData.lastVolume = newVolume
                end

                djAudioSources[stationIndex].lastUpdate = currentTime
                ::continue_dj::
            end
        end

        -- 🔴 BLOCO DE LIMPEZA REMOVIDO PARA MANTER REPRODUÇÃO INFINITA 🔴
        -- Nada será mais removido automaticamente

    end
end)

-- OTIMIZADO: Thread de volume com menos frequência
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) -- Atualização fixa a cada 20ms

        if isPlaying then
            local currentTime = GetGameTimer()

            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            -- Movimento para reativar automático
            if lastPosition and manualVolume ~= nil then
                local reactivateThreshold = (SharedConfig.attenuation and SharedConfig.attenuation.autoReactivateMovement) or 0.5
                if #(playerCoords - lastPosition) > reactivateThreshold then
                    manualVolume = nil
                    TriggerEvent("chat:addMessage", {
                        args = { "🔄 Movimento detectado. Volume automático reativado." }
                    })
                    DebugLog("Volume automático reativado devido ao movimento")
                end
            end
            lastPosition = playerCoords

            local volume = 0
            local stereoPan = 0

            if manualVolume ~= nil then
                volume = manualVolume
            else
                local targetVolume
                targetVolume, stereoPan = calculateDynamicVolumeOptimized(playerCoords, playerPed)

                -- Se alvo for 0 (fora de alcance), zera imediatamente
                if targetVolume == 0 then
                    volume = 0
                else
                    -- Suavização de volume para evitar picos ao começar a se mexer
                    local smoothing = (SharedConfig.attenuation and SharedConfig.attenuation.smoothingFactor) or 0.15
                    local function smooth(prev, target, factor)
                        local f = math.clamp(factor or 0.15, 0.0, 1.0)
                        prev = prev or target or 0
                        target = target or 0
                        return prev + (target - prev) * f
                    end
                    volume = smooth(currentVolume, targetVolume, smoothing)
                end
            end

            -- Checagem de prop menos frequente
            if currentTime - lastPropCheck > propCheckInterval then
                checkPropDistance()
                lastPropCheck = currentTime
            end

            if not soundEnabled or isMuted then
                volume = 0
            end

            volume = math.floor(volume + 0.5)

            -- Só atualiza se mudou significativamente
            if math.abs(volume - currentVolume) >= 3 then
                currentVolume = volume
                SendNUIMessage({
                    type = "setVolume",
                    volume = volume,
                    realTime = false
                })
                lastVolumeUpdate = currentTime
            end
        end
    end
end)


-- OTIMIZADA: Função de cálculo de volume otimizada
function calculateDynamicVolumeOptimized(playerCoords, playerPed)
    local volume = 0
    local stereoPan = 0

    if isDJMode and currentDJStation then
        local stationData = DJStations[currentDJStation.stationIndex]
        if stationData then
            local function getRangeAndMaxVolumeFor(sourceType, vehicle)
                local range, maxVolume
                local ranges = SharedConfig.range

                if sourceType == 'prop' then
                    if ranges and ranges.radio then
                        local r = ranges.radio
                        if type(r) == 'table' then
                            if #r >= 2 then range = r[1]; maxVolume = r[2] else range = r[1]; maxVolume = 100 end
                        elseif type(r) == 'number' then
                            range = r; maxVolume = 100
                        end
                    end
                    range = range or 12.0
                    maxVolume = maxVolume or 100
                elseif sourceType == 'vehicle' then
                    range = 20.0; maxVolume = 85
                    -- Se houver um padrão em ranges.vehicle.default, usar
                    if ranges and ranges.vehicle and type(ranges.vehicle.default) ~= 'nil' then
                        local v = ranges.vehicle.default
                        if type(v) == 'table' then
                            if #v >= 2 then range = v[1]; maxVolume = v[2] elseif #v >= 1 then range = v[1] end
                        elseif type(v) == 'number' then
                            range = v
                        end
                    end
                elseif sourceType == 'dj' then
                    range = 35.0; maxVolume = 100
                    if SharedConfig.dj and SharedConfig.dj[1] then
                        range = SharedConfig.dj[1].range or range
                        maxVolume = math.min(SharedConfig.dj[1].volume or maxVolume, 100)
                    end
                end
                return range, maxVolume
            end

            local djRange, djMax = getRangeAndMaxVolumeFor('dj')
            return calculateEntityVolumeOptimized(playerCoords, stationData.coords, playerPed, djRange, djMax, "dj")
        end
    elseif (inVehicle and currentVehicle and bluetoothMode == 'car') or 
           (not inVehicle and lastVehicle and DoesEntityExist(lastVehicle) and bluetoothMode == 'car') then
        local vehicle = currentVehicle or lastVehicle
        local function getRangeAndMaxVolumeFor(sourceType, vehicle)
            local range, maxVolume
            local ranges = SharedConfig.range
            if sourceType == 'vehicle' then
                range = 20.0; maxVolume = 85
                if ranges and ranges.vehicle and type(ranges.vehicle.default) ~= 'nil' then
                    local v = ranges.vehicle.default
                    if type(v) == 'table' then
                        if #v >= 2 then range = v[1]; maxVolume = v[2] elseif #v >= 1 then range = v[1] end
                    elseif type(v) == 'number' then
                        range = v
                    end
                end
            end
            return range, maxVolume
        end
        local vehRange, vehMax = getRangeAndMaxVolumeFor('vehicle', vehicle)
        return calculateEntityVolumeOptimized(playerCoords, GetEntityCoords(vehicle), playerPed, vehRange, vehMax, "vehicle")
    elseif prop and bluetoothMode == 'prop' then
        local function getRangeAndMaxVolumeFor(sourceType)
            local range, maxVolume
            local ranges = SharedConfig.range
            if sourceType == 'prop' then
                if ranges and ranges.radio then
                    local r = ranges.radio
                    if type(r) == 'table' then
                        if #r >= 2 then range = r[1]; maxVolume = r[2] else range = r[1]; maxVolume = 100 end
                    elseif type(r) == 'number' then
                        range = r; maxVolume = 100
                    end
                end
                range = range or 12.0
                maxVolume = maxVolume or 100
            end
            return range, maxVolume
        end
        local propRange, propMax = getRangeAndMaxVolumeFor('prop')
        return calculateEntityVolumeOptimized(playerCoords, GetEntityCoords(prop), playerPed, propRange, propMax, "prop")
    end

    return volume, stereoPan
end

-- OTIMIZADA: Função de cálculo de volume por entidade otimizada
function calculateEntityVolumeOptimized(playerCoords, entityCoords, playerPed, range, maxVolume, sourceType)
    local distance = #(playerCoords - entityCoords)
    local volume = 0
    local stereoPan = 0

    if distance <= range then
        -- Parâmetros de atenuação
        local att = SharedConfig.attenuation or {}
        local perType = att[sourceType] or {}
        local nearRadius = perType.nearRadius or att.nearRadius or 1.5
        local fadeStartRatio = perType.fadeStartRatio or att.fadeStartRatio or 0.5

        local fadeStart = range * fadeStartRatio

        -- Zona neutra: mantém o volume atual se estiver muito perto
        if distance <= nearRadius then
            volume = math.min(maxVolume, currentVolume or maxVolume)
        elseif distance <= fadeStart then
            volume = maxVolume
        else
            local fadeRatio = (distance - fadeStart) / (range - fadeStart)
            fadeRatio = fadeRatio * fadeRatio
            volume = math.floor(maxVolume * (1.0 - fadeRatio))
        end

        volume = math.max(0, math.min(volume, maxVolume))
    end

    return volume, stereoPan
end

RegisterNetEvent('foxzin:openMusicMenu')
AddEventHandler('foxzin:openMusicMenu', function(playerName)
    SetDisplay(true)
    -- Garantir criação imediata do prop ao abrir o menu /som
    if not inVehicle and bluetoothMode == 'prop' and not isDJMode and not prop then
        createProp()
    end
    
    -- Solicitar dados do perfil do jogador
    TriggerServerEvent('music:getPlayerProfile')
    
    SendNUIMessage({
        type = "action",
        action = "mostrarNome",
        nome = playerName
    })

    -- Carregar dados imediatamente ao abrir
    Citizen.SetTimeout(100, function()
        DebugLog("Solicitando dados iniciais...")
        TriggerServerEvent('music:getPlaylists')
        TriggerServerEvent('music:getFavorites')
        TriggerServerEvent('music:getHistory')
    end)
end)

-- Evento para abrir menu de DJ
RegisterNetEvent('foxzin:openDJMenu')
AddEventHandler('foxzin:openDJMenu', function(djData)
    DebugLog("🎧 === ABRINDO MENU DJ ===")
    DebugLog("🎧 Dados do DJ: " .. json.encode(djData))
    
    -- GARANTIR que está no modo DJ
    isDJMode = true
    currentDJStation = {
        stationIndex = djData.stationIndex,
        stationData = djData.stationData
    }
    
    DebugLog("🎧 Modo DJ ativado - Mesa: " .. djData.stationData.name .. " (Índice: " .. djData.stationIndex .. ")")
    
    SetDisplay(true)
    
    -- Enviar informação do nome do player
    SendNUIMessage({
        type = "action",
        action = "mostrarNome",
        nome = djData.playerName
    })
    
    -- IMPORTANTE: Informar ao NUI que está no modo DJ
    SendNUIMessage({
        type = "setDJMode",
        enabled = true,
        stationIndex = djData.stationIndex,
        stationData = djData.stationData,
        realTime = true
    })

    -- Carregar dados iniciais
    Citizen.SetTimeout(100, function()
        DebugLog("🎧 Solicitando dados para DJ...")
        TriggerServerEvent('music:getPlaylists')
        TriggerServerEvent('music:getFavorites') 
        TriggerServerEvent('music:getHistory')
    end)
    
    DebugLog("🎧 Menu DJ aberto com sucesso!")
end)

RegisterNetEvent('foxzin:noPermission')
AddEventHandler('foxzin:noPermission', function()
    TriggerEvent("Notify", "negado", "Você não tem permissão para usar este comando.")
    DebugLog("Permissão negada para o comando 'som'")
end)
RegisterNetEvent('foxzin:licenseBlocked')
AddEventHandler('foxzin:licenseBlocked', function()
    TriggerEvent("Notify", "negado", "Licença inválida para o sistema de música. Contate o administrador.")
    DebugLog("Licença bloqueada: impedindo abertura do menu de música")
end)

function SetDisplay(bool)
    display = bool
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        type = "ui",
        status = bool,
        realTime = true
    })
    
    -- Enviar imagens configuráveis para a NUI ao abrir
    if bool then
        local banner = nil
        local avatar = nil
        if SharedConfig and SharedConfig.uiImages then
            banner = SharedConfig.uiImages.bannerUrl
            avatar = SharedConfig.uiImages.avatarUrl
        end
        SendNUIMessage({
            type = "setUIImages",
            bannerUrl = banner,
            avatarUrl = avatar
        })
    end
    
    if bool then
        -- Só criar prop se NÃO estiver no modo DJ
        if not inVehicle and bluetoothMode == 'prop' and not isDJMode then
            createProp()
        end
        
        -- Se estava no modo DJ, reenviar informações para a NUI
        if isDJMode and currentDJStation then
            DebugLog("🎧 Reabrindo interface - Restaurando modo DJ")
            
            -- Reenviar dados do modo DJ para a interface
            SendNUIMessage({
                type = "setDJMode",
                enabled = true,
                stationIndex = currentDJStation.stationIndex,
                stationData = currentDJStation.stationData,
                realTime = true
            })
        end
    else
        DebugLog("🎧 Interface fechada - Modo DJ mantido: " .. tostring(isDJMode))
    end
    
    DebugLog("Interface " .. (bool and "aberta" or "fechada") .. " - Modo DJ mantido: " .. tostring(isDJMode))
end

RegisterNUICallback('exit', function(data, cb)
    SetDisplay(false)
    DebugLog("Saindo da interface")
    cb('ok')
end)

RegisterNUICallback('playTrack', function(data, cb)
    DebugLog("🎵 === CALLBACK playTrack RECEBIDO ===")
    DebugLog("🎵 Dados recebidos: " .. json.encode(data))
    DebugLog("🎵 isDJMode: " .. tostring(isDJMode))
    
    -- Se estiver no modo DJ, redirecionar para playDJTrack
    if isDJMode and currentDJStation then
        DebugLog("🎧 MODO DJ DETECTADO - Redirecionando para playDJTrack")
        
        -- Chamar o callback de DJ diretamente
        local djData = {
            videoId = data.videoId,
            title = data.title,
            thumbnail = data.thumbnail,
            duration = data.duration,
            stationIndex = currentDJStation.stationIndex,
            stationData = currentDJStation.stationData
        }
        
        -- Executar callback DJ
        local success = pcall(function()
            TriggerEvent('__cfx_nui:playDJTrack', djData, function(result)
                DebugLog("🎧 Callback DJ executado: " .. tostring(result))
            end)
        end)
        
        if success then
            DebugLog("🎧 Callback DJ executado com sucesso")
            cb('ok')
        else
            DebugLog("❌ Erro ao executar callback DJ")
            cb('error')
        end
        return
    end
    
    -- MODO NORMAL (Prop/Carro)
    DebugLog("🎵 MODO NORMAL - Executando playTrack")
    
    if not inVehicle and not prop then
        createProp()
    end
    -- NOVO: Se o prop existir mas estiver no chão, reanexar à mão ao dar play
    if not inVehicle and prop and not IsEntityAttached(prop) then
        AttachEntityToEntity(prop, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.30, 0, 0, 0, 260.0, 60.0, true, true, false, true, 1, true)
        DebugLog("Prop reanexado à mão ao iniciar música")
    end
    
    isPlaying = true
    DebugLog("🎵 Reproduzindo faixa: " .. data.title)
    
    local sourceCoords = GetEntityCoords(PlayerPedId())
    local sourceType = "player"
    local propNetId = nil
    local vehicleNetId = nil
    
    if prop and bluetoothMode == 'prop' then
        sourceCoords = GetEntityCoords(prop)
        sourceType = "prop"
        propNetId = NetworkGetNetworkIdFromEntity(prop)
    elseif (currentVehicle or lastVehicle) and bluetoothMode == 'car' then
        local vehicle = currentVehicle or lastVehicle
        if vehicle and DoesEntityExist(vehicle) then
            sourceCoords = GetEntityCoords(vehicle)
            sourceType = "vehicle"
            vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
        end
    end
    
    local syncData = {
        videoId = data.videoId,
        title = data.title,
        thumbnail = data.thumbnail,
        duration = data.duration,
        sourcePlayer = GetPlayerServerId(PlayerId()),
        sourceCoords = sourceCoords,
        sourceType = sourceType,
        propNetId = propNetId,
        vehicleNetId = vehicleNetId,
        realTime = true
    }
    
    DebugLog("🎵 Sincronizando áudio normal: " .. json.encode(syncData))
    TriggerServerEvent('music:syncAudio', syncData)
    
    TriggerServerEvent('music:saveToHistory', data.videoId)
    TriggerServerEvent('music:saveVideo', {
        id = data.videoId,
        title = data.title,
        thumbnail = data.thumbnail,
        duration = data.duration
    })
    
    cb('ok')
end)

-- Callback para tocar música na mesa de DJ
RegisterNUICallback('playDJTrack', function(data, cb)
    DebugLog("🎧 === CALLBACK playDJTrack TEMPO REAL ===")
    DebugLog("🎧 Dados recebidos: " .. json.encode(data))
    
    if not isDJMode or not currentDJStation then
        DebugLog("❌ ERRO: Não está no modo DJ!")
        cb('error')
        return
    end
    
    if not data.videoId or not data.title then
        DebugLog("❌ ERRO: Dados incompletos!")
        cb('error')
        return
    end
    
    isPlaying = true
    DebugLog("🎧 Reproduzindo faixa de DJ: " .. data.title)
    
    local stationIndex = data.stationIndex or currentDJStation.stationIndex
    local stationData = DJStations[stationIndex]
    
    if not stationData then
        DebugLog("❌ ERRO: Mesa de DJ inválida!")
        cb('error')
        return
    end
    
    local syncData = {
        videoId = data.videoId,
        title = data.title,
        thumbnail = data.thumbnail,
        duration = data.duration,
        sourcePlayer = GetPlayerServerId(PlayerId()),
        sourceCoords = stationData.coords,
        sourceType = "dj",
        stationIndex = stationIndex,
        realTime = true
    }
    
    DebugLog("🎧 Sincronizando áudio de DJ (TEMPO REAL): " .. json.encode(syncData))
    
    TriggerServerEvent('music:syncDJAudio', syncData)
    
    TriggerServerEvent('music:saveToHistory', data.videoId)
    TriggerServerEvent('music:saveVideo', {
        id = data.videoId,
        title = data.title,
        thumbnail = data.thumbnail,
        duration = data.duration
    })
    
    DebugLog("🎧 DJ configurado para tempo real!")
    cb('ok')
end)

-- MODIFICAÇÃO 1: Callback pauseTrack modificado para remover prop JBL
RegisterNUICallback('pauseTrack', function(data, cb)
    DebugLog("🎵 === CALLBACK pauseTrack RECEBIDO ===")
    
    isPlaying = false
    DebugLog("🎵 Música pausada")
    
    -- MODIFICAÇÃO: Remover prop JBL SEMPRE quando pausar
    if prop then
        DebugLog("🎵 Removendo prop JBL ao pausar música")
        deleteProp()
    end
    
    -- NOVO: Esconder mini player imediatamente quando pausar
    SendNUIMessage({
        type = 'hideMiniPlayer'
    })
    
    TriggerServerEvent('music:stopAudio')
    
    cb('ok')
end)

-- Callback para pausar música de DJ
RegisterNUICallback('pauseDJTrack', function(data, cb)
    DebugLog("🎧 === CALLBACK pauseDJTrack RECEBIDO ===")
    
    isPlaying = false
    DebugLog("🎧 Música de DJ pausada")

    -- NOVO: Esconder mini player imediatamente quando pausar DJ
    SendNUIMessage({
        type = 'hideMiniPlayer'
    })
    
    local stationIndex = data.stationIndex or (currentDJStation and currentDJStation.stationIndex)
    if stationIndex then
        DebugLog("🎧 Parando áudio da mesa DJ: " .. stationIndex)
        TriggerServerEvent('music:stopDJAudio', stationIndex)
    else
        DebugLog("❌ ERRO: stationIndex não encontrado para pausar DJ")
    end
    
    cb('ok')
end)

RegisterNUICallback('toggleFavorite', function(data, cb)
    if not data.videoId or not data.title then
        DebugLog("Falha ao favoritar: dados incompletos")
        cb({success = false, message = "Dados incompletos"})
        return
    end
    
    DebugLog("Alternando favorito: " .. data.title)
    TriggerServerEvent('music:toggleFavorite', {
        id = data.videoId,
        title = data.title,
        thumbnail = data.thumbnail,
        duration = data.duration
    })
    
    Citizen.SetTimeout(500, function()
        DebugLog("Solicitando atualização de favoritos após toggle")
        TriggerServerEvent('music:getFavorites')
    end)
    
    cb({success = true})
end)

RegisterNUICallback('createPlaylist', function(data, cb)
    DebugLog("Criando playlist: " .. data.name)
    TriggerServerEvent('music:createPlaylist', data.name)
    
    Citizen.SetTimeout(500, function()
        DebugLog("Solicitando atualização de playlists após criar")
        TriggerServerEvent('music:getPlaylists') 
    end)
    
    cb('ok')
end)

RegisterNUICallback('addToPlaylist', function(data, cb)
    DebugLog("Adicionando música à playlist: " .. data.playlistId)
    TriggerServerEvent('music:addToPlaylist', data.playlistId, data.videoId)
    cb('ok')
end)

RegisterNetEvent('music:playlistsData')
AddEventHandler('music:playlistsData', function(playlists)
    DebugLog("Recebendo dados de playlists: " .. (playlists and #playlists or 0) .. " itens")
    SendNUIMessage({
        type = "playlists",
        data = playlists or {}
    })
end)

RegisterNetEvent('music:playlistVideosData')
AddEventHandler('music:playlistVideosData', function(videos)
    DebugLog("Recebendo vídeos da playlist: " .. (videos and #videos or 0) .. " itens")
    SendNUIMessage({
        type = "playlistVideos",
        data = videos or {}
    })
end)

RegisterNetEvent('music:favoritesData')
AddEventHandler('music:favoritesData', function(videos)
    DebugLog("Recebendo dados de favoritos: " .. (videos and #videos or 0) .. " itens")
    SendNUIMessage({
        type = "favorites",
        data = videos or {}
    })
end)

RegisterNetEvent('music:historyData')
AddEventHandler('music:historyData', function(videos)
    DebugLog("Recebendo dados do histórico: " .. (videos and #videos or 0) .. " itens")
    SendNUIMessage({
        type = "history",
        data = videos or {}
    })
end)

function loadFavorites()
    DebugLog("Solicitando favoritos do servidor")
    TriggerServerEvent('music:getFavorites')
end

function loadPlaylists()
    DebugLog("Solicitando playlists do servidor")
    TriggerServerEvent('music:getPlaylists')
end

function loadPlaylistVideos(playlistId)
    DebugLog("Solicitando vídeos da playlist: " .. playlistId)
    TriggerServerEvent('music:getPlaylistVideos', playlistId)
end

-- Drop/pickup prop with G key
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        if prop and not inVehicle and IsControlJustPressed(0, 47) then -- G key
            if IsEntityAttached(prop) then
                DetachEntity(prop, true, true)
                PlaceObjectOnGroundProperly(prop)
                DebugLog("Prop colocado no chão")
            else
                local playerCoords = GetEntityCoords(PlayerPedId())
                local propCoords = GetEntityCoords(prop)
                local distance = #(playerCoords - propCoords)
                
                if distance < 2.0 then
                    AttachEntityToEntity(prop, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.30, 0, 0, 0, 260.0, 60.0, true, true, false, true, 1, true)
                    DebugLog("Prop pego do chão")
                end
            end
        end
    end
end)

RegisterNUICallback('audioDeviceChanged', function(data, cb)
    DebugLog("Dispositivo de áudio alterado")
    cb('ok')
end)

-- Pesquisa de músicas: NUI -> client -> server.
-- A requisição HTTP é executada no server para evitar CORS e bloqueios do CEF/NUI.
local pendingYoutubeSearches = {}
local youtubeSearchSequence = 0

RegisterNUICallback('searchYouTube', function(data, cb)
    local query = tostring((data and data.query) or '')
    query = query:gsub('^%s+', ''):gsub('%s+$', '')

    if #query < 2 then
        cb({ success = true, results = {} })
        return
    end

    if #query > 120 then
        query = query:sub(1, 120)
    end

    youtubeSearchSequence = youtubeSearchSequence + 1
    local requestId = ('%s:%s:%s'):format(GetPlayerServerId(PlayerId()), GetGameTimer(), youtubeSearchSequence)

    pendingYoutubeSearches[requestId] = cb
    TriggerServerEvent('b_spotify:searchYouTube', requestId, query)

    -- Segurança: nunca deixa um callback NUI preso para sempre.
    SetTimeout(16000, function()
        local callback = pendingYoutubeSearches[requestId]
        if callback then
            pendingYoutubeSearches[requestId] = nil
            callback({
                success = false,
                results = {},
                error = 'Tempo limite ao pesquisar músicas.'
            })
        end
    end)
end)

RegisterNetEvent('b_spotify:searchYouTubeResult')
AddEventHandler('b_spotify:searchYouTubeResult', function(requestId, payload)
    local callback = pendingYoutubeSearches[requestId]
    if not callback then return end

    pendingYoutubeSearches[requestId] = nil
    callback(payload or { success = false, results = {}, error = 'Resposta inválida da pesquisa.' })
end)

RegisterNUICallback('saveSearchToJson', function(data, cb)
    local query = data.query
    local results = data.results
    
    if not query or not results then
        DebugLog("Falha ao salvar busca: dados incompletos")
        cb({success = false})
        return
    end
    
    local cacheFile = LoadResourceFile(GetCurrentResourceName(), "youtube_cache.json")
    local cache = {}
    
    if cacheFile then
        local success, parsed = pcall(function()
            return json.decode(cacheFile)
        end)
        
        if success and parsed then
            cache = parsed
        end
    end
    
    cache[query] = results
    
    local success = SaveResourceFile(GetCurrentResourceName(), "youtube_cache.json", json.encode(cache), -1)
    DebugLog("Busca salva no cache: " .. query .. " (" .. (success and "sucesso" or "falha") .. ")")
    
    cb({success = success})
end)

RegisterNUICallback('getFavorites', function(data, cb)
    DebugLog("NUICallback: Solicitando favoritos")
    TriggerServerEvent('music:getFavorites')
    cb('ok')
end)

RegisterNUICallback('getPlaylists', function(data, cb)
    DebugLog("NUICallback: Solicitando playlists")
    TriggerServerEvent('music:getPlaylists')
    cb('ok')
end)

RegisterNUICallback('getPlaylistVideos', function(data, cb)
    DebugLog("NUICallback: Solicitando vídeos da playlist: " .. (data.playlistId or "undefined"))
    TriggerServerEvent('music:getPlaylistVideos', data.playlistId)
    cb('ok')
end)

-- Remover música da playlist
RegisterNUICallback('removeFromPlaylist', function(data, cb)
    local playlistId = data.playlistId
    local videoId = data.videoId
    DebugLog("NUICallback: Remover música da playlist: " .. tostring(playlistId) .. " - video " .. tostring(videoId))
    TriggerServerEvent('music:removeFromPlaylist', playlistId, videoId)
    Citizen.SetTimeout(400, function()
        TriggerServerEvent('music:getPlaylistVideos', playlistId)
    end)
    cb('ok')
end)

-- Excluir playlist completa
RegisterNUICallback('deletePlaylist', function(data, cb)
    local playlistId = data.playlistId
    DebugLog("NUICallback: Excluir playlist: " .. tostring(playlistId))
    TriggerServerEvent('music:deletePlaylist', playlistId)
    Citizen.SetTimeout(500, function()
        TriggerServerEvent('music:getPlaylists')
    end)
    cb('ok')
end)

RegisterNUICallback('fetchFavorites', function(data, cb)
    local userId = data.userId or '1'
    DebugLog("NUICallback: fetchFavorites para usuário: " .. userId)
    TriggerServerEvent('foxzin:getFavorites', userId)
    cb({})
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    deleteProp()
    
    -- Limpar blips de DJ
    for i, blip in pairs(djBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    
    DebugLog("Recurso parado, prop e blips removidos")
end)

RegisterNUICallback('deleteProp', function(data, cb)
    DebugLog("🎵 === CALLBACK deleteProp RECEBIDO ===")
    
    if prop then
        DebugLog("🎵 Deletando prop JBL via callback")
        deleteProp()
    else
        DebugLog("🎵 Prop não existe para deletar")
    end
    
    cb('ok')
end)

-- Handler para receber dados do perfil do jogador
RegisterNetEvent('music:receivePlayerProfile')
AddEventHandler('music:receivePlayerProfile', function(profileData)
    DebugLog("Dados do perfil recebidos: " .. profileData.name)
    
    SendNUIMessage({
        type = "updatePlayerProfile",
        profile = profileData
    })
end)
