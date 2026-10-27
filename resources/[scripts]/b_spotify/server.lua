-- SISTEMA DE MÚSICA OTIMIZADO
local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
vRP = Proxy.getInterface("vRP")

-- Carregar configurações de DJ
local djStationsFile = LoadResourceFile(GetCurrentResourceName(), "config/dj_stations.lua")
if djStationsFile then
    load(djStationsFile)()
else
    print("^1[ERRO] Não foi possível carregar config/dj_stations.lua^0")
    DJStations = {}
    DJConfig = {}
end

-- OTIMIZADO: Variáveis para controle de throttling de rede
local lastPositionUpdate = {}
local positionUpdateInterval = 500 -- OTIMIZADO: 500ms entre atualizações de posição
local lastAudioSync = {}
local audioSyncInterval = 1000 -- OTIMIZADO: 1 segundo entre sincronizações de áudio

-- Variáveis para o sistema de música
local Config = {}
local SharedConfig = {}
local audioSources = {} -- Armazena informações das fontes de áudio ativas
local djSources = {} -- Armazena informações das mesas de DJ ativas
local playerMuteStatus = {} -- Status de mute de cada jogador
local playerPositions = {} -- Posições dos jogadores para sincronização
local Debug = true

-- NOVO: Variável para controlar volume global dos jogadores
local playerVolumeSettings = {} -- Armazena configurações de volume de cada jogador

-- Função de debug
function DebugLog(message)
    if Debug then
        --print('[SERVER DEBUG] ' .. message)
    end
end

-- Carrega as configurações
Citizen.CreateThread(function()
    Config = LoadResourceFile(GetCurrentResourceName(), "config.lua")
    Config = load(Config)()
    
    SharedConfig = LoadResourceFile(GetCurrentResourceName(), "shared/config.lua")
    SharedConfig = load(SharedConfig)()
    
    DebugLog("Configurações carregadas")
end)

-- Sistema de armazenamento local (fallback se DB falhar)
local storage = {
    favorites = {},
    playlists = {},
    history = {},
    videos = {}
}

-- Carregar armazenamento ao iniciar
Citizen.CreateThread(function()
    local storageFile = LoadResourceFile(GetCurrentResourceName(), "storage.json")
    if storageFile then
        local success, loadedStorage = pcall(function()
            return json.decode(storageFile)
        end)
        
        if success and loadedStorage then
            storage = loadedStorage
            DebugLog("Armazenamento carregado do arquivo")
        else
            DebugLog("Erro ao carregar armazenamento, usando novo")
        end
    else
        DebugLog("Arquivo de armazenamento não encontrado, usando novo")
    end
end)

-- Função para obter ID do jogador usando vRP
function GetPlayerId(source)
    if source then
        local user_id = vRP.getUserId({source})
        if user_id then
            return tonumber(user_id)
        end
    end
    
    -- Fallback para source
    return tonumber(source)
end

-- Comando para mutar o som
RegisterCommand('somoff', function(source, args, rawCommand)
    
    local user_id = vRP.getUserId(source)
    if not user_id then return end

    playerMuteStatus[source] = true

    TriggerClientEvent('Notify', source, 'sucesso', 'Som mutado! Use /somon para desmutar.')
    TriggerClientEvent('music:setMuteStatus', source, true)
    DebugLog("Jogador " .. source .. " mutou o som")
end)

-- Comando para desmutar o som
RegisterCommand('somon', function(source, args, rawCommand)
    
    local user_id = vRP.getUserId(source)
    if not user_id then return end

    playerMuteStatus[source] = false

    TriggerClientEvent('Notify', source, 'sucesso', 'Som desmutado!')
    TriggerClientEvent('music:setMuteStatus', source, false)
    DebugLog("Jogador " .. source .. " desmutou o som")
end)

-- NOVO: Evento para sincronizar volume entre jogadores
RegisterNetEvent('music:syncPlayerVolume')
AddEventHandler('music:syncPlayerVolume', function(volume)
    local source = source
    
    -- Armazenar configuração de volume do jogador
    playerVolumeSettings[source] = volume
    
    -- Propagar para outros jogadores próximos se o jogador tem uma fonte ativa
    if audioSources[source] then
        local sourceCoords = audioSources[source].sourceCoords
        
        for _, playerID in ipairs(GetPlayers()) do
            local playerNum = tonumber(playerID)
            if playerNum and playerNum ~= source and not playerMuteStatus[playerNum] then
                local targetPed = GetPlayerPed(playerNum)
                if DoesEntityExist(targetPed) then
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(sourceCoords - targetCoords)
                    
                    if distance <= 150.0 then
                        -- Aplicar o volume do jogador fonte aos outros
                        TriggerClientEvent('music:updateSourceVolume', playerNum, {
                            sourcePlayer = source,
                            volume = volume
                        })
                    end
                end
            end
        end
    end
    
    DebugLog("Volume do jogador " .. source .. " sincronizado: " .. volume .. "%")
end)

-- Evento para solicitar menu de DJ
RegisterNetEvent('music:requestDJMenu')
AddEventHandler('music:requestDJMenu', function(stationIndex)
    
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return end
    
    -- Validar se a estação existe
    if not DJStations[stationIndex] then
        TriggerClientEvent('Notify', source, 'negado', 'Mesa de DJ inválida.')
        return
    end
    
    local station = DJStations[stationIndex]
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(playerCoords - station.coords)
    
    -- Verificar distância
    if distance > (DJConfig.interactionDistance or 3.0) then
        TriggerClientEvent('Notify', source, 'negado', 'Você está muito longe da mesa de DJ.')
        return
    end
    
    -- Verificar permissão se necessária
    if station.permission and not vRP.hasPermission(user_id, station.permission) then
        TriggerClientEvent('Notify', source, 'negado', 'Você não tem permissão para usar esta mesa de DJ.')
        return
    end
    
    -- Verificar item se necessário
    if station.requireItem and station.item then
        if not vRP.hasInventoryItem(user_id, station.item, 1) then
            TriggerClientEvent('Notify', source, 'negado', 'Você precisa do item: ' .. station.item)
            return
        end
    end
    
    -- Verificar se já há um DJ ativo nesta mesa
    if not DJConfig.allowMultipleDJs and djSources[stationIndex] then
        TriggerClientEvent('Notify', source, 'negado', 'Esta mesa de DJ já está sendo usada.')
        return
    end
    
    -- Abrir interface de DJ
    local identity = vRP.getUserIdentity(user_id)
    local playerName = GetPlayerName(source)
    
    if identity then
        if identity then
            local nome = identity.nome or identity.name or "SemNome"
            local sobrenome = identity.sobrenome or identity.firstname or ""
            playerName = nome .. " " .. sobrenome
        end
    end
    
    TriggerClientEvent('foxzin:openDJMenu', source, {
        playerName = playerName,
        stationIndex = stationIndex,
        stationData = station
    })
    
    DebugLog("Jogador " .. source .. " abriu a mesa de DJ: " .. station.name)
end)

-- Sistema de Mesa de DJ
RegisterCommand('dj', function(source, args, rawCommand)
    
    local user_id = vRP.getUserId(source)
    if not user_id then return end
    
    -- Verificar se o jogador está próximo de uma mesa de DJ
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local nearestStation = nil
    local nearestDistance = math.huge
    
    for i, station in ipairs(DJStations) do
        local distance = #(playerCoords - station.coords)
        if distance <= (DJConfig.interactionDistance or 3.0) and distance < nearestDistance then
            nearestDistance = distance
            nearestStation = {index = i, data = station}
        end
    end
    
    if not nearestStation then
        TriggerClientEvent('Notify', source, 'negado', 'Você precisa estar próximo de uma mesa de DJ para usar este comando.')
        return
    end
    
    -- Usar o sistema de requisição
    TriggerEvent('music:requestDJMenu', nearestStation.index)
end)

-- SUPER OTIMIZADO: Evento para atualizar posição do jogador (com throttling)
RegisterNetEvent('music:updatePlayerPosition')
AddEventHandler('music:updatePlayerPosition', function(updateData)
    local source = source
    local currentTime = GetGameTimer()
    
    -- OTIMIZADO: Throttling por jogador
    if lastPositionUpdate[source] and (currentTime - lastPositionUpdate[source]) < positionUpdateInterval then
        return -- Ignorar se muito frequente
    end
    
    lastPositionUpdate[source] = currentTime
    
    -- Atualizar posição do jogador
    playerPositions[source] = {
        playerCoords = updateData.playerCoords,
        vehicleCoords = updateData.vehicleCoords,
        propNetId = updateData.propNetId,
        vehicleNetId = updateData.vehicleNetId,
        sourceType = updateData.sourceType,
        lastUpdate = currentTime
    }
    
    -- OTIMIZADO: Só propagar se o jogador tem uma fonte ativa
    if audioSources[source] then
        local sourceCoords = updateData.vehicleCoords or updateData.playerCoords
        
        audioSources[source].sourceCoords = sourceCoords
        audioSources[source].sourceType = updateData.sourceType
        audioSources[source].propNetId = updateData.propNetId
        audioSources[source].vehicleNetId = updateData.vehicleNetId
        audioSources[source].lastUpdate = currentTime
        
        -- OTIMIZADO: Propagar apenas para jogadores próximos (batch processing)
        local nearbyPlayers = {}
        for _, playerID in ipairs(GetPlayers()) do
            local playerNum = tonumber(playerID)
            if playerNum and playerNum ~= source and not playerMuteStatus[playerNum] then
                local targetPed = GetPlayerPed(playerNum)
                if DoesEntityExist(targetPed) then
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(sourceCoords - targetCoords)
                    
                    if distance <= 150.0 then
                        table.insert(nearbyPlayers, playerNum)
                    end
                end
            end
        end
        
        -- OTIMIZADO: Enviar em batch para jogadores próximos
        if #nearbyPlayers > 0 then
            for _, playerNum in ipairs(nearbyPlayers) do
                TriggerClientEvent('music:updateAudioSource', playerNum, {
                    sourcePlayer = source,
                    sourceCoords = sourceCoords,
                    sourceType = updateData.sourceType
                })
            end
        end
    end
end)

-- IMPLEMENTAÇÃO PARA FAVORITOS (LIKES)
function SaveFavorite(source, data)
    local user_id = GetPlayerId(source)
    DebugLog("Salvando favorito para jogador: " .. user_id)
    
    SaveVideo(source, data)
    
    MySQL.query("SELECT * FROM likes WHERE user_id = ? AND video_id = ?", {user_id, data.id}, function(result)
        if result and #result > 0 then
            MySQL.query("DELETE FROM likes WHERE user_id = ? AND video_id = ?", {user_id, data.id}, function()
                DebugLog("Favorito removido: " .. data.id)
                GetFavorites(source)
            end)
        else
            MySQL.query("INSERT INTO likes (user_id, video_id) VALUES (?, ?)", {user_id, data.id}, function()
                DebugLog("Favorito adicionado: " .. data.id)
                GetFavorites(source)
            end)
        end
    end)
end

function SaveToHistory(source, videoId)
    local user_id = GetPlayerId(source)
    DebugLog("Salvando histórico para jogador: " .. user_id)
    
    MySQL.query("INSERT INTO history (user_id, video_id) VALUES (?, ?)", {user_id, videoId}, function()
        GetHistory(source)
    end)
end

function SaveVideo(source, data)
    if not data or not data.id then return end
    DebugLog("Salvando vídeo: " .. data.id)
    
    MySQL.query("SELECT id FROM videos WHERE id = ?", {data.id}, function(result)
        if not result or #result == 0 then
            MySQL.query("INSERT INTO videos (id, title, thumbnail, duration) VALUES (?, ?, ?, ?)", 
                {data.id, data.title, data.thumbnail, data.duration}, function()
                DebugLog("Vídeo adicionado ao banco: " .. data.id)
            end)
        else
            MySQL.query("UPDATE videos SET title = ?, thumbnail = ?, duration = ? WHERE id = ?", 
                {data.title, data.thumbnail, data.duration, data.id}, function()
                DebugLog("Vídeo atualizado no banco: " .. data.id)
            end)
        end
    end)
    
    storage.videos[data.id] = {
        id = data.id,
        videoId = data.id,
        title = data.title,
        thumbnail = data.thumbnail or "https://img.youtube.com/vi/" .. data.id .. "/mqdefault.jpg",
        duration = data.duration or "--:--"
    }
    
    SaveResourceFile(GetCurrentResourceName(), "storage.json", json.encode(storage), -1)
end

function CreatePlaylist(source, name)
    local user_id = GetPlayerId(source)
    DebugLog("Criando playlist para jogador: " .. user_id .. ", nome: " .. name)
    
    MySQL.query("INSERT INTO playlists (user_id, name) VALUES (?, ?)", {user_id, name}, function()
        GetPlaylists(source)
    end)
end

function AddToPlaylist(source, playlistId, videoId)
    local user_id = GetPlayerId(source)
    DebugLog("Adicionando à playlist: " .. playlistId .. ", vídeo: " .. videoId)
    
    MySQL.query("SELECT id FROM playlists WHERE id = ? AND user_id = ?", {playlistId, user_id}, function(result)
        if not result or #result == 0 then
            DebugLog("Playlist não encontrada ou não pertence ao usuário: " .. playlistId)
            return
        end
        
        MySQL.query("SELECT playlist_id FROM playlist_videos WHERE playlist_id = ? AND video_id = ?", {playlistId, videoId}, function(result2)
            if result2 and #result2 > 0 then
                DebugLog("Vídeo já está na playlist")
                return
            end
            
            MySQL.query("INSERT INTO playlist_videos (playlist_id, video_id) VALUES (?, ?)", {playlistId, videoId}, function()
                DebugLog("Vídeo adicionado à playlist")
            end)
        end)
    end)
end

function GetPlaylists(source)
    local user_id = GetPlayerId(source)
    DebugLog("Obtendo playlists para jogador: " .. user_id)
    
    MySQL.query("SELECT id, name FROM playlists WHERE user_id = ?", {user_id}, function(result)
        if not result then result = {} end
        
        DebugLog("Encontradas " .. #result .. " playlists")
        
        TriggerClientEvent('music:playlistsData', source, result)
    end)
end

function GetPlaylistVideos(source, playlistId)
    local user_id = GetPlayerId(source)
    DebugLog("Obtendo vídeos da playlist: " .. playlistId)
    
    local query = [[
        SELECT v.id, v.title, v.thumbnail, v.duration 
        FROM playlist_videos pv 
        JOIN videos v ON pv.video_id = v.id 
        WHERE pv.playlist_id = ?
        ORDER BY pv.added_at DESC
    ]]
    
    MySQL.query(query, {playlistId}, function(result)
        if not result then result = {} end
        
        DebugLog("Encontrados " .. #result .. " vídeos na playlist")
        
        local videos = {}
        for _, video in ipairs(result) do
            table.insert(videos, {
                id = video.id,
                videoId = video.id,
                title = video.title,
                thumbnail = video.thumbnail or "https://img.youtube.com/vi/" .. video.id .. "/mqdefault.jpg",
                duration = video.duration or "--:--"
            })
        end
        
        TriggerClientEvent('music:playlistVideosData', source, videos)
    end)
end

function GetFavorites(source)
    local user_id = GetPlayerId(source)
    DebugLog("Obtendo favoritos para jogador: " .. user_id)
    
    local query = [[
        SELECT v.id, v.title, v.thumbnail, v.duration 
        FROM likes l 
        JOIN videos v ON l.video_id = v.id 
        WHERE l.user_id = ?
        ORDER BY l.created_at DESC
    ]]
    
    MySQL.query(query, {user_id}, function(result)
        if not result then result = {} end
        
        DebugLog("Encontrados " .. #result .. " favoritos")
        
        local favorites = {}
        for _, video in ipairs(result) do
            table.insert(favorites, {
                id = video.id,
                videoId = video.id,
                title = video.title,
                thumbnail = video.thumbnail or "https://img.youtube.com/vi/" .. video.id .. "/mqdefault.jpg",
                duration = video.duration or "--:--"
            })
        end
        
        TriggerClientEvent('music:favoritesData', source, favorites)
    end)
end

function GetHistory(source)
    local user_id = GetPlayerId(source)
    DebugLog("Obtendo histórico para jogador: " .. user_id)
    
    local query = [[
        SELECT v.id, v.title, v.thumbnail, v.duration 
        FROM history h 
        JOIN videos v ON h.video_id = v.id 
        WHERE h.user_id = ?
        ORDER BY h.played_at DESC
        LIMIT 100
    ]]
    
    MySQL.query(query, {user_id}, function(result)
        if not result then result = {} end
        
        DebugLog("Encontrados " .. #result .. " itens no histórico")
        
        local history = {}
        for _, video in ipairs(result) do
            table.insert(history, {
                id = video.id,
                videoId = video.id,
                title = video.title,
                thumbnail = video.thumbnail or "https://img.youtube.com/vi/" .. video.id .. "/mqdefault.jpg",
                duration = video.duration or "--:--"
            })
        end
        
        TriggerClientEvent('music:historyData', source, history)
    end)
end

local oxmysql = exports.oxmysql

function AddToHistory(source, video)
    local user_id = GetPlayerId(source)
    if not user_id or not video or not video.id then return end

    local videoId = video.id
    local title = video.title or "Sem título"
    local thumbnail = video.thumbnail or ("https://img.youtube.com/vi/" .. videoId .. "/mqdefault.jpg")
    local duration = video.duration or "--:--"

    CreateThread(function()
        local result = oxmysql:query_async("SELECT id FROM videos WHERE id = ?", { videoId })

        if not result or #result == 0 then
            oxmysql:execute_async("INSERT INTO videos (id, title, thumbnail, duration) VALUES (?, ?, ?, ?)", {
                videoId, title, thumbnail, duration
            })
        end

        oxmysql:execute_async("INSERT INTO history (user_id, video_id) VALUES (?, ?)", {
            user_id, videoId
        })
    end)
end



RegisterCommand('som', function(source, args, rawCommand)
    
    local user_id = vRP.getUserId(source)
    if user_id then
        local perm = Config.Permissions["som"]
        if vRP.hasPermission(user_id, perm) then
            local identity = vRP.getUserIdentity(user_id)
            local playerName = GetPlayerName(source)

            if identity then
                local nome = identity.nome or identity.name or "SemNome"
                local sobrenome = identity.sobrenome or identity.firstname or ""
                playerName = nome .. " " .. sobrenome
            end

            print("^2[SOM] Player "..playerName.." ("..source..") usou comando som^7")
            TriggerClientEvent('foxzin:openMusicMenu', source, playerName)
        else
            TriggerClientEvent('foxzin:noPermission', source)
        end
    else
        TriggerClientEvent('foxzin:noPermission', source)
    end
end)


-- Eventos do sistema de música normal
RegisterNetEvent('music:toggleFavorite')
AddEventHandler('music:toggleFavorite', function(data)
    local source = source
    DebugLog("Evento toggleFavorite recebido de: " .. source)
    SaveFavorite(source, data)
end)

RegisterNetEvent('music:saveVideo')
AddEventHandler('music:saveVideo', function(data)
    local source = source
    DebugLog("Evento saveVideo recebido de: " .. source)
    SaveVideo(source, data)
end)

RegisterNetEvent('music:saveToHistory')
AddEventHandler('music:saveToHistory', function(videoId)
    local source = source
    DebugLog("Evento saveToHistory recebido de: " .. source)
    SaveToHistory(source, videoId)
end)

RegisterNetEvent('music:createPlaylist')
AddEventHandler('music:createPlaylist', function(name)
    local source = source
    DebugLog("Evento createPlaylist recebido de: " .. source)
    CreatePlaylist(source, name)
end)

RegisterNetEvent('music:addToPlaylist')
AddEventHandler('music:addToPlaylist', function(playlistId, videoId)
    local source = source
    DebugLog("Evento addToPlaylist recebido de: " .. source)
    AddToPlaylist(source, playlistId, videoId)
end)

RegisterNetEvent('music:getPlaylists')
AddEventHandler('music:getPlaylists', function()
    local source = source
    DebugLog("Evento getPlaylists recebido de: " .. source)
    GetPlaylists(source)
end)

RegisterNetEvent('music:getPlaylistVideos')
AddEventHandler('music:getPlaylistVideos', function(playlistId)
    local source = source
    DebugLog("Evento getPlaylistVideos recebido de: " .. source)
    GetPlaylistVideos(source, playlistId)
end)

RegisterNetEvent('music:getFavorites')
AddEventHandler('music:getFavorites', function()
    local source = source
    DebugLog("Evento getFavorites recebido de: " .. source)
    GetFavorites(source)
end)

RegisterNetEvent('music:getHistory')
AddEventHandler('music:getHistory', function()
    local source = source
    DebugLog("Evento getHistory recebido de: " .. source)
    GetHistory(source)
end)

-- OTIMIZADO: Sistema de sincronização de áudio com throttling
RegisterNetEvent('music:syncAudio')
AddEventHandler('music:syncAudio', function(audioData)
    local source = source
    local currentTime = GetGameTimer()
    
    -- OTIMIZADO: Throttling de sincronização de áudio
    if lastAudioSync[source] and (currentTime - lastAudioSync[source]) < audioSyncInterval then
        DebugLog("🎵 Sincronização ignorada - muito frequente para jogador: " .. source)
        return
    end
    
    lastAudioSync[source] = currentTime
    
    DebugLog("🎵 === SINCRONIZANDO ÁUDIO NORMAL (OTIMIZADO) ===")
    DebugLog("🎵 Fonte: " .. source .. " (" .. audioData.sourceType .. ")")

    -- Armazenar informações da fonte de áudio
    audioSources[source] = {
        videoId = audioData.videoId,
        title = audioData.title,
        thumbnail = audioData.thumbnail,
        duration = audioData.duration,
        sourcePlayer = source,
        sourceCoords = audioData.sourceCoords,
        sourceType = audioData.sourceType,
        propNetId = audioData.propNetId,
        vehicleNetId = audioData.vehicleNetId,
        lastUpdate = currentTime
    }

    -- OTIMIZADO: Determinar alcance e coletar jogadores próximos em uma passada
    local maxRange = 15.0 -- REDUZIDO: Alcance padrão menor
    if audioData.sourceType == "vehicle" then
        maxRange = 20.0 -- REDUZIDO: Carro: 20m
    elseif audioData.sourceType == "prop" then
        maxRange = 12.0 -- REDUZIDO: Prop: 12m
    end

    local nearbyPlayers = {}
    for _, playerID in ipairs(GetPlayers()) do
        local playerNum = tonumber(playerID)
        if playerNum and playerNum ~= source and not playerMuteStatus[playerNum] then
            local targetPed = GetPlayerPed(playerNum)
            if DoesEntityExist(targetPed) then
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(audioData.sourceCoords - targetCoords)

                if distance <= maxRange then
                    table.insert(nearbyPlayers, {
                        playerId = playerNum,
                        distance = distance
                    })
                end
            end
        end
    end

    DebugLog("🎵 Propagando áudio para " .. #nearbyPlayers .. " jogadores próximos")

    -- OTIMIZADO: Enviar para jogadores próximos em batch
    for _, playerData in ipairs(nearbyPlayers) do
        TriggerClientEvent('music:receiveAudio', playerData.playerId, audioData)
    end
end)

-- OTIMIZADO: Sistema de sincronização de áudio para DJ com throttling
RegisterNetEvent('music:syncDJAudio')
AddEventHandler('music:syncDJAudio', function(audioData)
    local source = source
    local currentTime = GetGameTimer()
    
    -- OTIMIZADO: Throttling para DJ também
    if lastAudioSync[source] and (currentTime - lastAudioSync[source]) < audioSyncInterval then
        DebugLog("🎧 Sincronização DJ ignorada - muito frequente para jogador: " .. source)
        return
    end
    
    lastAudioSync[source] = currentTime
    
    DebugLog("🎧 Sincronizando áudio de DJ de " .. tostring(source))

    local stationIndex = audioData.stationIndex
    local stationData = DJStations[stationIndex]

    if not stationData then
        DebugLog("Mesa de DJ inválida: " .. tostring(stationIndex))
        return
    end

    local djCoords = stationData.coords

    -- Armazenar informações da mesa de DJ ativa
    djSources[stationIndex] = {
        audioData = audioData,
        sourceCoords = djCoords,
        sourceType = "dj",
        sourcePlayer = source,
        stationData = stationData,
        lastUpdate = currentTime
    }

    local syncData = {
        videoId = audioData.videoId,
        title = audioData.title,
        thumbnail = audioData.thumbnail,
        duration = audioData.duration,
        sourcePlayer = source,
        sourceCoords = djCoords,
        sourceType = "dj",
        stationIndex = stationIndex,
        stationData = stationData
    }

    -- OTIMIZADO: Mesa de DJ com alcance fixo e coleta otimizada
    local maxRange = 30.0
    local nearbyPlayers = {}
    
    for _, playerID in ipairs(GetPlayers()) do
        local playerNum = tonumber(playerID)
        if playerNum and playerNum ~= source and not playerMuteStatus[playerNum] then
            local targetPed = GetPlayerPed(playerNum)
            if DoesEntityExist(targetPed) then
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(djCoords - targetCoords)

                if distance <= maxRange then
                    table.insert(nearbyPlayers, {
                        playerId = playerNum,
                        distance = distance
                    })
                end
            end
        end
    end
    
    DebugLog("🎧 Propagando áudio de DJ para " .. #nearbyPlayers .. " jogadores")
    
    -- OTIMIZADO: Enviar em batch
    for _, playerData in ipairs(nearbyPlayers) do
        TriggerClientEvent('music:receiveDJAudio', playerData.playerId, syncData)
    end
end)

RegisterNetEvent('music:stopAudio')
AddEventHandler('music:stopAudio', function()
    local source = source
    DebugLog("Parando áudio de " .. source)
    
    if audioSources[source] then
        audioSources[source] = nil
        
        for _, playerID in ipairs(GetPlayers()) do
            if tonumber(playerID) ~= source then
                TriggerClientEvent('music:removeAudioSource', playerID, source)
            end
        end
    end
end)

-- Parar áudio de DJ
RegisterNetEvent('music:stopDJAudio')
AddEventHandler('music:stopDJAudio', function(stationIndex)
    local source = source
    DebugLog("Parando áudio de DJ de " .. source .. " na mesa " .. stationIndex)
    
    if djSources[stationIndex] then
        djSources[stationIndex] = nil
        
        for _, playerID in ipairs(GetPlayers()) do
            if tonumber(playerID) ~= source then
                TriggerClientEvent('music:removeDJAudioSource', playerID, stationIndex)
            end
        end
    end
end)

-- OTIMIZADO: Thread para atualizar posições com menos frequência
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000) -- OTIMIZADO: de 1000ms para 2000ms
        
        local currentTime = GetGameTimer()
        
        -- OTIMIZADO: Processar apenas algumas fontes por ciclo
        local processedSources = 0
        local maxProcessPerCycle = 5 -- OTIMIZADO: Máximo 5 fontes por ciclo
        
        -- Atualizar fontes normais
        for sourceId, sourceInfo in pairs(audioSources) do
            if processedSources >= maxProcessPerCycle then break end
            processedSources = processedSources + 1
            
            local playerPed = GetPlayerPed(sourceId)
            if DoesEntityExist(playerPed) then
                local newCoords = nil
                local sourceType = sourceInfo.sourceType
                
                if sourceType == "prop" and sourceInfo.propNetId then
                    local propEntity = NetworkGetEntityFromNetworkId(sourceInfo.propNetId)
                    if propEntity and propEntity ~= 0 and DoesEntityExist(propEntity) then
                        newCoords = GetEntityCoords(propEntity)
                    end
                elseif sourceType == "vehicle" and sourceInfo.vehicleNetId then
                    local vehicleEntity = NetworkGetEntityFromNetworkId(sourceInfo.vehicleNetId)
                    if vehicleEntity and vehicleEntity ~= 0 and DoesEntityExist(vehicleEntity) then
                        newCoords = GetEntityCoords(vehicleEntity)
                    end
                else
                    newCoords = GetEntityCoords(playerPed)
                end
                
                if newCoords then
                    local oldCoords = sourceInfo.sourceCoords
                    local moved = not oldCoords or #(newCoords - oldCoords) > 5.0 -- OTIMIZADO: Threshold maior
                    
                    if moved then
                        sourceInfo.sourceCoords = newCoords
                        sourceInfo.lastUpdate = currentTime
                        
                        -- OTIMIZADO: Atualização menos frequente para jogadores próximos
                        local maxRange = 15.0
                        if sourceType == "vehicle" then
                            maxRange = 20.0
                        elseif sourceType == "prop" then
                            maxRange = 12.0
                        end
                        
                        -- OTIMIZADO: Coletar e processar em batch
                        local playersToUpdate = {}
                        for _, playerID in ipairs(GetPlayers()) do
                            local playerNum = tonumber(playerID)
                            if playerNum and playerNum ~= sourceId and not playerMuteStatus[playerNum] then
                                local targetPed = GetPlayerPed(playerNum)
                                if DoesEntityExist(targetPed) then
                                    local targetCoords = GetEntityCoords(targetPed)
                                    local distance = #(newCoords - targetCoords)
                                    
                                    if distance <= maxRange then
                                        table.insert(playersToUpdate, playerNum)
                                    end
                                end
                            end
                        end
                        
                        -- Enviar atualizações em batch
                        for _, playerNum in ipairs(playersToUpdate) do
                            TriggerClientEvent('music:updateAudioSource', playerNum, {
                                sourcePlayer = sourceId,
                                sourceCoords = newCoords,
                                sourceType = sourceType
                            })
                        end
                    end
                end
            else
                audioSources[sourceId] = nil
                for _, playerID in ipairs(GetPlayers()) do
                    if tonumber(playerID) ~= sourceId then
                        TriggerClientEvent('music:removeAudioSource', playerID, sourceId)
                    end
                end
            end
        end
        
        -- OTIMIZADO: Atualizar fontes de DJ com menos frequência
        if processedSources < maxProcessPerCycle then
            for stationIndex, djInfo in pairs(djSources) do
                if processedSources >= maxProcessPerCycle then break end
                processedSources = processedSources + 1
                
                local sourceId = djInfo.sourcePlayer
                local playerPed = GetPlayerPed(sourceId)
                
                if DoesEntityExist(playerPed) then
                    djInfo.lastUpdate = currentTime
                    
                    local playerCoords = GetEntityCoords(playerPed)
                    local distance = #(playerCoords - djInfo.sourceCoords)
                    
                    if distance > 15.0 then -- AUMENTADO: DJ pode se afastar até 15m
                        djSources[stationIndex] = nil
                        for _, playerID in ipairs(GetPlayers()) do
                            TriggerClientEvent('music:removeDJAudioSource', playerID, stationIndex)
                        end
                        DebugLog("DJ " .. sourceId .. " se afastou da mesa " .. stationIndex)
                    end
                else
                    djSources[stationIndex] = nil
                    for _, playerID in ipairs(GetPlayers()) do
                        TriggerClientEvent('music:removeDJAudioSource', playerID, stationIndex)
                    end
                end
            end
        end
    end
end)

-- OTIMIZADO: Thread para monitorar fontes de áudio com menos frequência
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000) -- OTIMIZADO: de 2000ms para 5000ms
        
        -- Monitorar fontes normais
        for sourceId, sourceInfo in pairs(audioSources) do
            local playerPed = GetPlayerPed(sourceId)
            if not DoesEntityExist(playerPed) then
                audioSources[sourceId] = nil
                for _, playerID in ipairs(GetPlayers()) do
                    if tonumber(playerID) ~= sourceId then
                        TriggerClientEvent('music:removeAudioSource', playerID, sourceId)
                    end
                end
                DebugLog("Fonte de áudio removida (player desconectou): " .. sourceId)
            end
        end
        
        -- Monitorar fontes de DJ
        for stationIndex, djInfo in pairs(djSources) do
            local sourceId = djInfo.sourcePlayer
            local playerPed = GetPlayerPed(sourceId)
            
            if not DoesEntityExist(playerPed) then
                djSources[stationIndex] = nil
                for _, playerID in ipairs(GetPlayers()) do
                    TriggerClientEvent('music:removeDJAudioSource', playerID, stationIndex)
                end
                DebugLog("Fonte de áudio de DJ removida (DJ desconectou): " .. stationIndex)
            end
        end
    end
end)

-- Eventos para o vRP
RegisterNetEvent('foxzin:getFavorites')
AddEventHandler('foxzin:getFavorites', function(userId)
    local source = source
    DebugLog("Evento foxzin:getFavorites recebido para usuário: " .. userId)
    GetFavorites(source)
end)

RegisterNetEvent('music:updateAudioSource')
AddEventHandler('music:updateAudioSource', function(updateData)
    local source = source
    
    if not updateData.sourceCoords then
        DebugLog("ERRO: updateAudioSource sem coordenadas da fonte!")
        return
    end
    
    -- Atualizar fonte se ela existe
    if audioSources[source] then
        audioSources[source].sourceCoords = updateData.sourceCoords
        audioSources[source].sourceType = updateData.sourceType
        audioSources[source].propNetId = updateData.propNetId
        audioSources[source].vehicleNetId = updateData.vehicleNetId
        audioSources[source].lastUpdate = GetGameTimer()
        
        DebugLog("Fonte " .. source .. " (" .. updateData.sourceType .. ") atualizada: " .. 
            string.format("%.1f, %.1f, %.1f", updateData.sourceCoords.x, updateData.sourceCoords.y, updateData.sourceCoords.z))
        
        -- Propagar atualização para jogadores próximos
        local maxRange = 15.0
        if updateData.sourceType == "vehicle" then
            maxRange = 20.0
        elseif updateData.sourceType == "dj" then
            maxRange = 30.0
        end
        
        for _, playerID in ipairs(GetPlayers()) do
            local playerNum = tonumber(playerID)
            if playerNum and playerNum ~= source then
                local targetPed = GetPlayerPed(playerNum)
                if DoesEntityExist(targetPed) then
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(updateData.sourceCoords - targetCoords)
                    
                    if distance <= maxRange and not playerMuteStatus[playerNum] then
                        TriggerClientEvent('music:updateAudioSource', playerNum, {
                            sourcePlayer = source,
                            sourceCoords = updateData.sourceCoords,
                            sourceType = updateData.sourceType
                        })
                    end
                end
            end
        end
    end
end)
