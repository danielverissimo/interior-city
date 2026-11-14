local Tunnel = module('vrp', 'lib/Tunnel')
local Proxy = module('vrp', 'lib/Proxy')

local vRP = Proxy.getInterface('vRP')
local vRPclient = Tunnel.getInterface('vRP')
local inventoryClient = Tunnel.getInterface(Config.InventoryResource)

local activeVehicles = {}      -- [netId] = source
local openSessions = {}        -- [source] = { chestId, netId, maxWeight }
local activeAlerts = {}        -- [alertId] = { source, coords }
local alertBySource = {}       -- [source] = alertId
local requestCooldown = {}     -- [source] = game timer aproximado (os.time)
local activeTrackers = {}       -- [alertId] = { source, expiresAt }
local trackerBySource = {}      -- [source] = alertId
local playerVehicleCooldowns = {} -- [ownerId:plate] = unix timestamp em que poderá ser roubado novamente
local protectedRadarLocks = {} -- [source] = { userId = id, alerts = { [alertId] = true } }
local activeDrugDeals = {}      -- [source] = { token, netId, item, label, quantity, payment, expiresAt }
local drugRequestCooldown = {}   -- anti-spam server-side para abordagens de NPC
local drugInventoryCheckCooldown = {} -- anti-spam da consulta que controla a exibição do prompt

local function notify(source, kind, text, time)
    TriggerClientEvent('Notify', source, kind, text, time or 5)
end

local function setEntityState(entity, key, value)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end
    pcall(function()
        Entity(entity).state:set(key, value, true)
    end)
end

local function getEntityState(entity, key)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return nil end
    local ok, value = pcall(function()
        return Entity(entity).state[key]
    end)
    if ok then return value end
    return nil
end

local function coordsTable(coords)
    return { x = coords.x + 0.0, y = coords.y + 0.0, z = coords.z + 0.0 }
end

local function toVector3(data)
    if type(data) ~= 'table' then return nil end
    local x, y, z = tonumber(data.x), tonumber(data.y), tonumber(data.z)
    if not x or not y or not z then return nil end
    return vec3(x, y, z)
end

local function getVehicleFromNetId(netId)
    netId = tonumber(netId)
    if not netId or netId <= 0 then return 0 end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity and entity ~= 0 and DoesEntityExist(entity) and GetEntityType(entity) == 2 then
        return entity
    end
    return 0
end

local function normalizePlate(plate)
    if not plate then return '' end
    return tostring(plate):gsub('^%s+', ''):gsub('%s+$', '')
end


local function radarPlate(plate)
    return string.upper(normalizePlate(plate))
end

local function getRadarStorageKey(ownerId, plate, prefix)
    if not ownerId then return nil end
    plate = radarPlate(plate)
    if plate == '' then return nil end
    return ('%s%s:%s'):format(prefix or Config.RadarStoragePrefix or 'm_robbernpc:radar:', tostring(ownerId), plate)
end

local function getLegacyRadarStorageKey(ownerId, plate)
    local prefix = Config.LegacyRadarStoragePrefix
    if not prefix or prefix == '' then return nil end
    return getRadarStorageKey(ownerId, plate, prefix)
end

local function getPlayerVehicleCooldownKey(ownerId, entity)
    if not ownerId or not entity or entity == 0 or not DoesEntityExist(entity) then return nil end
    local plate = radarPlate(GetVehicleNumberPlateText(entity))
    if plate == '' then return nil end
    return ('%s:%s'):format(tostring(ownerId), plate)
end

local function getPlayerVehicleCooldownRemaining(ownerId, entity)
    if Config.limite_de_tempo ~= true then return 0 end

    local key = getPlayerVehicleCooldownKey(ownerId, entity)
    if not key then return 0 end

    local expiresAt = tonumber(playerVehicleCooldowns[key]) or 0

    -- Também lê o state bag para manter o cooldown se a entidade continuar viva
    -- durante restart apenas do resource.
    local stateExpires = tonumber(getEntityState(entity, 'trunkrobberCooldownUntil')) or 0
    if stateExpires > expiresAt then
        expiresAt = stateExpires
        playerVehicleCooldowns[key] = expiresAt
    end

    local remaining = expiresAt - os.time()
    if remaining <= 0 then
        playerVehicleCooldowns[key] = nil
        if stateExpires > 0 then
            setEntityState(entity, 'trunkrobberCooldownUntil', 0)
        end
        return 0
    end

    return remaining
end

local function startPlayerVehicleCooldown(ownerId, entity)
    -- Sempre limpa o marcador permanente antigo, pois veículos de jogador
    -- não usam mais o bloqueio definitivo reservado aos NPCs.
    setEntityState(entity, 'trunkrobberRobbed', false)
    setEntityState(entity, 'trunkrobberRobbedNPC', false)

    local key = getPlayerVehicleCooldownKey(ownerId, entity)
    if not key then return end

    if Config.limite_de_tempo ~= true then
        playerVehicleCooldowns[key] = nil
        setEntityState(entity, 'trunkrobberCooldownUntil', 0)
        return
    end

    local seconds = math.max(1, tonumber(Config.tempo_limite_roubo) or 600)
    local expiresAt = os.time() + seconds
    playerVehicleCooldowns[key] = expiresAt
    setEntityState(entity, 'trunkrobberCooldownUntil', expiresAt)
end

local function clearRobberyStateFromVehicle(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end

    setEntityState(entity, 'trunkrobberRobbed', false)
    setEntityState(entity, 'trunkrobberRobbedNPC', false)
    setEntityState(entity, 'trunkrobberCooldownUntil', 0)
    setEntityState(entity, 'trunkrobberBusy', false)
end

local function clearAllRobberyHistory()
    -- Cooldowns dos veículos pertencentes a jogadores existem apenas em memória
    -- e também no state bag da entidade enquanto ela está spawnada.
    playerVehicleCooldowns = {}
    activeVehicles = {}

    local ok, vehicles = pcall(GetAllVehicles)
    if ok and type(vehicles) == 'table' then
        for _, vehicle in ipairs(vehicles) do
            clearRobberyStateFromVehicle(vehicle)
        end
    end
end

local function vehicleHasRadar(ownerId, entity)
    if not ownerId or not entity or entity == 0 or not DoesEntityExist(entity) then return false end

    local plate = GetVehicleNumberPlateText(entity)
    local key = getRadarStorageKey(ownerId, plate)
    if not key then return false end

    local stored = vRP.getSData(key)
    if stored == '1' or stored == 'true' or stored == true then return true end

    -- Migração transparente: preserva radares instalados quando o resource ainda
    -- se chamava m_trunkrobber.
    local legacyKey = getLegacyRadarStorageKey(ownerId, plate)
    if legacyKey and legacyKey ~= key then
        local legacy = vRP.getSData(legacyKey)
        if legacy == '1' or legacy == 'true' or legacy == true then
            return true
        end
    end

    return false
end

local function removeVehicleRadar(ownerId, entity)
    if not ownerId or not entity or entity == 0 or not DoesEntityExist(entity) then return false end

    local plate = GetVehicleNumberPlateText(entity)
    local key = getRadarStorageKey(ownerId, plate)
    if not key then return false end
    local legacyKey = getLegacyRadarStorageKey(ownerId, plate)

    local ok = pcall(function()
        -- Zera tanto a chave nova quanto a antiga para impedir que um radar legado
        -- reapareça após a migração do resource para m_robbernpc.
        vRP.setSData(key, '0')
        if legacyKey and legacyKey ~= key then
            vRP.setSData(legacyKey, '0')
        end
    end)

    return ok
end

local function lockRecoveredRadarItem(source, userId, alertId)
    source = tonumber(source)
    userId = tonumber(userId)
    if not source or not userId or not alertId then return end

    local lock = protectedRadarLocks[source]
    if not lock or tonumber(lock.userId) ~= userId then
        lock = { userId = userId, alerts = {} }
        protectedRadarLocks[source] = lock
    end

    lock.alerts[tostring(alertId)] = true
end

local function unlockRecoveredRadarItem(source, alertId)
    source = tonumber(source)
    if not source then return end

    local lock = protectedRadarLocks[source]
    if not lock then return end

    if alertId then
        lock.alerts[tostring(alertId)] = nil
        if next(lock.alerts) then return end
    end

    protectedRadarLocks[source] = nil
end

local function isRecoveredRadarItemLocked(userId, source, item)
    source = tonumber(source)
    userId = tonumber(userId)

    if not source or not userId then return false end
    if tostring(item or ''):lower() ~= tostring(Config.RadarItem or 'rastreador_carro'):lower() then return false end

    local lock = protectedRadarLocks[source]
    return lock ~= nil and tonumber(lock.userId) == userId and next(lock.alerts) ~= nil
end

-- Usado pelo pequeno módulo de integração do inventory incluído nesta versão.
-- Enquanto retornar true, o rastreador roubado não pode ser dropado, enviado
-- para outro jogador ou guardado em baús.
exports('isProtectedRadarItem', function(userId, source, item)
    return isRecoveredRadarItemLocked(userId, source, item)
end)

local function getVehicleOwner(entity)
    local plate = GetVehicleNumberPlateText(entity)
    if not plate or plate == '' then return nil end

    -- O inventory usa a própria matrícula para descobrir o dono.
    -- Tentamos primeiro como ela vem do veículo e depois sem espaços nas pontas.
    return vRP.getUserByRegistration(plate) or vRP.getUserByRegistration(normalizePlate(plate))
end

local function isPlayerPedServer(ped)
    if not ped or ped == 0 then return false end

    for _, playerSource in ipairs(GetPlayers()) do
        if GetPlayerPed(tonumber(playerSource) or playerSource) == ped then
            return true
        end
    end

    return false
end

local function hasBlockingOccupant(entity)
    local okSeats, maxPassengers = pcall(GetVehicleMaxNumberOfPassengers, entity)
    if not okSeats or maxPassengers == nil then
        -- Caso a build não exponha o native no servidor, o client continua
        -- fazendo a mesma validação antes de sequer mostrar o prompt.
        return false
    end

    for seat = -1, maxPassengers - 1 do
        local okPed, occupant = pcall(GetPedInVehicleSeat, entity, seat)
        if okPed and occupant and occupant ~= 0 then
            if isPlayerPedServer(occupant) then
                return true
            end

            local okHealth, health = pcall(GetEntityHealth, occupant)
            if okHealth and tonumber(health) and tonumber(health) > 0 then
                return true
            end
        end
    end

    return false
end

local function isVehicleStationary(entity)
    local okSpeed, speed = pcall(GetEntitySpeed, entity)
    if okSpeed and tonumber(speed) then
        return tonumber(speed) <= (tonumber(Config.MaxVehicleSpeed) or 0.25)
    end

    -- Fallback para builds onde GetEntitySpeed não esteja disponível no server.
    return true
end

local function getGarageVehicleData(entity)
    if GetResourceState(Config.GarageResource or 'm_garage') ~= 'started' then
        return nil
    end

    local ok, vehicles = pcall(function()
        return exports[Config.GarageResource or 'm_garage']:getListVehicles()
    end)

    if not ok or type(vehicles) ~= 'table' then
        return nil
    end

    local modelHash = GetEntityModel(entity)
    local data = vehicles[modelHash]

    if not data then
        -- Alguns exports serializam chaves numéricas como string.
        data = vehicles[tostring(modelHash)]
    end

    if not data or not data.model then
        return nil
    end

    return {
        spawn = tostring(data.model):lower(),
        trunk = tonumber(data.trunk) or tonumber(Config.TrunkWeight) or 50,
        name = data.name
    }
end

local function getOwnedVehicleChest(entity)
    local ownerId = getVehicleOwner(entity)
    if not ownerId then return nil end

    local vehicleData = getGarageVehicleData(entity)
    if not vehicleData then return nil end

    return {
        ownerId = ownerId,
        chestKey = ('chest:u%sveh_%s'):format(ownerId, vehicleData.spawn),
        maxWeight = vehicleData.trunk,
        spawn = vehicleData.spawn
    }
end

local function validateDistance(source, entity, maxDistance)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return false end
    return #(GetEntityCoords(ped) - GetEntityCoords(entity)) <= (maxDistance or Config.ServerMaxDistance)
end

local function cleanupTempChest(chestId, delay)
    if not chestId then return end
    SetTimeout(delay or 1500, function()
        local key = 'WAREHOUSES:' .. chestId
        pcall(function()
            exports.oxmysql:execute('DELETE FROM vrp_srv_data WHERE dkey = ?', { key })
        end)
    end)
end

local function decodeChest(raw)
    if not raw or raw == '' then return {} end

    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == 'table' then
        return data
    end

    return {}
end

local function syncOwnedVehicleChest(session, delay)
    if not session or session.type ~= 'player' or not session.realChestKey or not session.chestId then
        return
    end

    -- O inventory salva o WAREHOUSES no fechamento. Esperamos um pouco antes
    -- de copiar o resultado de volta para o baú REAL do veículo do jogador.
    SetTimeout(delay or 1600, function()
        local tempKey = 'WAREHOUSES:' .. session.chestId
        local finalItems = decodeChest(vRP.getSData(tempKey))

        vRP.setSData(session.realChestKey, json.encode(finalItems))

        pcall(function()
            exports.oxmysql:execute('DELETE FROM vrp_srv_data WHERE dkey = ?', { tempKey })
        end)
    end)
end

local function removePoliceAlert(alertId)
    local alert = activeAlerts[alertId]
    if not alert then return end

    if alertBySource[alert.source] == alertId then
        alertBySource[alert.source] = nil
    end

    activeAlerts[alertId] = nil
    TriggerClientEvent('m_robbernpc:policeAlert:remove', -1, alertId)
end

local function ensurePoliceAlert(source, location)
    local previous = alertBySource[source]
    if previous and activeAlerts[previous] then
        local alert = activeAlerts[previous]
        TriggerClientEvent('m_robbernpc:trackAlert', source, previous, alert.coords, Config.AlertEndDistance)
        return previous
    end

    local alertId = ('%s:%s:%s'):format(source, os.time(), math.random(100000, 999999))
    local dataCoords = coordsTable(location)

    activeAlerts[alertId] = {
        source = source,
        coords = dataCoords
    }
    alertBySource[source] = alertId

    local police = vRP.getUsersByPermission(Config.PolicePermission) or {}
    for _, userId in pairs(police) do
        local policeSource = vRP.getUserSource(userId)
        if policeSource then
            notify(policeSource, 'aviso', Config.PoliceAlertText, 8)
            TriggerClientEvent('m_robbernpc:policeAlert:create', policeSource, alertId, dataCoords, Config.PoliceBlipRadius)
        end
    end

    TriggerClientEvent('m_robbernpc:trackAlert', source, alertId, dataCoords, Config.AlertEndDistance)
    return alertId
end


local function getPoliceSources()
    local sources = {}
    local police = vRP.getUsersByPermission(Config.PolicePermission) or {}

    for _, userId in pairs(police) do
        local policeSource = vRP.getUserSource(userId)
        if policeSource then
            sources[#sources + 1] = policeSource
        end
    end

    return sources
end

local function stopRadarTracking(alertId)
    local tracker = activeTrackers[alertId]
    if not tracker then return end

    if trackerBySource[tracker.source] == alertId then
        trackerBySource[tracker.source] = nil
    end

    activeTrackers[alertId] = nil
    TriggerClientEvent('m_robbernpc:policeTracker:remove', -1, alertId)
    TriggerClientEvent('m_robbernpc:robberTracker:stop', tracker.source)

    -- O rastreador recuperado volta a ser um item totalmente normal somente
    -- quando o período de rastreamento desse roubo termina.
    unlockRecoveredRadarItem(tracker.source, alertId)

    if Config.RobberTrackingEndedText and Config.RobberTrackingEndedText ~= '' then
        notify(tracker.source, 'sucesso', Config.RobberTrackingEndedText, 6)
    end
end

local function sendRadarPosition(alertId, tracker)
    if not tracker then return false end

    local ped = GetPlayerPed(tracker.source)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return false
    end

    local coords = coordsTable(GetEntityCoords(ped))
    local secondsLeft = math.max(0, tracker.expiresAt - os.time())

    for _, policeSource in ipairs(getPoliceSources()) do
        TriggerClientEvent('m_robbernpc:policeTracker:update', policeSource, alertId, coords, secondsLeft)
    end

    return true
end

local function startRadarTracking(alertId, robberSource)
    local previous = trackerBySource[robberSource]
    if previous and previous ~= alertId then
        stopRadarTracking(previous)
    end

    local duration = math.max(1, tonumber(Config.RadarTrackingTime) or 90)
    local tracker = {
        source = robberSource,
        expiresAt = os.time() + duration
    }

    activeTrackers[alertId] = tracker
    trackerBySource[robberSource] = alertId

    for _, policeSource in ipairs(getPoliceSources()) do
        notify(policeSource, 'aviso', Config.PoliceRadarActivatedText or 'O veículo roubado possui um radar oculto. O meliante será rastreado por 1 minuto e 30 segundos.', 8)
    end

    -- O ladrão descobre o rastreamento somente quando sai da área vermelha.
    -- A NUI mostra o aviso e a contagem regressiva do mesmo tempo usado pela polícia.
    TriggerClientEvent('m_robbernpc:robberTracker:start', robberSource, duration, Config.RobberTrackedText or 'VOCÊ ESTÁ SENDO RASTREADO,FUJA!')

    sendRadarPosition(alertId, tracker)
end

CreateThread(function()
    while true do
        Wait(math.max(500, tonumber(Config.RadarUpdateInterval) or 1000))

        local now = os.time()
        local toRemove = {}

        for alertId, tracker in pairs(activeTrackers) do
            if now >= tracker.expiresAt or not sendRadarPosition(alertId, tracker) then
                toRemove[#toRemove + 1] = alertId
            end
        end

        for _, alertId in ipairs(toRemove) do
            stopRadarTracking(alertId)
        end
    end
end)

local function drugConfig()
    return Config.NPCDrugSales or {}
end

local function drugClamp(value, minValue, maxValue)
    value = tonumber(value) or minValue
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function isDrugSaleBlocked(userId)
    for _, permission in ipairs(drugConfig().BlockedPermissions or {}) do
        if permission and permission ~= '' and vRP.hasPermission(userId, permission) then
            return true
        end
    end
    return false
end

local function isPlayerPedEntity(entity)
    if not entity or entity == 0 then return false end
    for _, playerSource in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(playerSource)
        if ped and ped ~= 0 and ped == entity then
            return true
        end
    end
    return false
end

local function getDrugPedFromNetId(netId, retries)
    netId = tonumber(netId)
    if not netId or netId <= 0 then return 0 end

    -- O client pode acabar de networkar um ped ambiental. Dá alguns frames para
    -- o OneSync registrar a entidade no servidor antes de negar a abordagem.
    local attempts = math.max(1, math.floor(tonumber(retries) or 1))
    for attempt = 1, attempts do
        local entity = NetworkGetEntityFromNetworkId(netId)
        if entity and entity ~= 0 and DoesEntityExist(entity) and GetEntityType(entity) == 1 then
            -- IsEntityDead não existe no runtime server-side do FiveM. A vida da
            -- entidade é suficiente aqui e funciona com OneSync no servidor.
            if not isPlayerPedEntity(entity) and GetEntityHealth(entity) > 0 then
                return entity
            end
            return 0
        end

        if attempt < attempts then
            Wait(50)
        end
    end

    return 0
end

local function validateDrugPedDistance(source, ped, maxDistance)
    if ped == 0 or not DoesEntityExist(ped) then return false end
    local playerPed = GetPlayerPed(source)
    if not playerPed or playerPed == 0 or not DoesEntityExist(playerPed) then return false end

    local playerCoords = GetEntityCoords(playerPed)
    local pedCoords = GetEntityCoords(ped)
    if not playerCoords or not pedCoords then return false end

    return #(playerCoords - pedCoords) <= (tonumber(maxDistance) or 4.0)
end

local function getPedDrugDealt(ped)
    if ped == 0 or not DoesEntityExist(ped) then return false end
    local ok, value = pcall(function()
        return Entity(ped).state.robbernpcDrugDealt
    end)
    return ok and value == true
end

local function markPedDrugDealt(ped)
    if ped == 0 or not DoesEntityExist(ped) then return end
    pcall(function()
        Entity(ped).state:set('robbernpcDrugDealt', true, true)
    end)
end

local function collectSellableDrugs(userId)
    local available = {}
    for key, drug in pairs(drugConfig().Drugs or {}) do
        if type(drug) == 'table' and drug.item and drug.item ~= '' then
            local stock = tonumber(vRP.getInventoryItemAmount(userId, drug.item)) or 0
            if stock > 0 then
                available[#available + 1] = {
                    key = key,
                    item = tostring(drug.item),
                    label = tostring(drug.label or drug.item),
                    stock = math.floor(stock),
                    minPricePerUnit = math.max(0, math.floor(tonumber(drug.minPricePerUnit) or 0)),
                    maxPricePerUnit = math.max(0, math.floor(tonumber(drug.maxPricePerUnit or drug.minPricePerUnit) or 0))
                }
            end
        end
    end
    return available
end


-- Mantém o client informado se o jogador possui pelo menos uma das drogas
-- configuradas. O prompt "NEGOCIAR DROGAS" só é permitido com estoque real.
RegisterNetEvent('m_robbernpc:drug:checkInventory', function()
    local source = source
    local cfg = drugConfig()
    local userId = vRP.getUserId(source)

    if not userId or cfg.Enabled == false then
        TriggerClientEvent('m_robbernpc:drug:inventoryState', source, false)
        return
    end

    local nowMs = GetGameTimer()
    if (drugInventoryCheckCooldown[source] or 0) > nowMs then
        return
    end
    drugInventoryCheckCooldown[source] = nowMs + 500

    if isDrugSaleBlocked(userId) then
        TriggerClientEvent('m_robbernpc:drug:inventoryState', source, false)
        return
    end

    local available = collectSellableDrugs(userId)
    TriggerClientEvent('m_robbernpc:drug:inventoryState', source, #available > 0)
end)

local function dispatchDrugSalePolice(source, userId, drug)
    local cfg = drugConfig().Dispatch or {}
    if cfg.Enabled == false then return end

    local resourceName = tostring(cfg.Resource or 'vrp_notifycall')
    if GetResourceState(resourceName) ~= 'started' then
        print(('[m_robbernpc] [WARNING] %s não está iniciado; alerta de venda de drogas não enviado.'):format(resourceName))
        return
    end

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return end
    local coords = GetEntityCoords(ped)
    if not coords then return end

    local permission = tostring(cfg.PolicePermission or Config.PolicePermission or 'perm.policia')
    local police = vRP.getUsersByPermission(permission) or {}
    local dispatchId = ('npc-drug-sale:%s:%s:%04d'):format(tostring(userId), tostring(os.time()), math.random(0, 9999))
    local text = tostring(cfg.Text or 'Um cidadão denunciou uma possível venda de drogas. Verifique a região.')

    if drug and drug.label then
        text = text .. ' Possível produto: ' .. tostring(drug.label) .. '.'
    end

    for _, policeUserId in pairs(police) do
        local policeSource = vRP.getUserSource(tonumber(policeUserId))
        if policeSource then
            TriggerClientEvent(tostring(cfg.Event or 'NotifyPush'), policeSource, {
                code = tostring(cfg.Code or '911'),
                title = tostring(cfg.Title or 'VENDA DE DROGAS'),
                text = text,
                x = coords.x,
                y = coords.y,
                z = coords.z,
                time = os.date('%H:%M'),
                rgba = cfg.Rgba or { 255, 55, 70, 255 },
                blipSprite = math.floor(tonumber(cfg.BlipSprite) or 161),
                blipColor = math.floor(tonumber(cfg.BlipColor) or 1),
                blipScale = tonumber(cfg.BlipScale) or 0.85,
                blipDuration = math.max(1000, math.floor(tonumber(cfg.BlipDuration) or 60000)),
                sound = cfg.Sound ~= false,
                dispatchId = dispatchId
            })
        end
    end
end

local function clearDrugDeal(source, token)
    local deal = activeDrugDeals[source]
    if not deal then return nil end
    if token and tostring(deal.token) ~= tostring(token) then return nil end
    activeDrugDeals[source] = nil
    return deal
end

RegisterNetEvent('m_robbernpc:drug:request', function(netId)
    local source = source
    local userId = vRP.getUserId(source)
    local cfg = drugConfig()

    if not userId or cfg.Enabled == false then return end

    local nowMs = GetGameTimer()
    if (drugRequestCooldown[source] or 0) > nowMs then
        TriggerClientEvent('m_robbernpc:drug:result', source, {
            outcome = 'denied',
            message = 'Aguarde um instante antes de abordar outra pessoa.'
        })
        return
    end
    drugRequestCooldown[source] = nowMs + 650

    local previous = activeDrugDeals[source]
    if previous and (tonumber(previous.expiresAt) or 0) > os.time() then
        TriggerClientEvent('m_robbernpc:drug:result', source, {
            outcome = 'denied',
            message = 'Finalize a negociação atual antes de tentar outra.'
        })
        return
    end
    activeDrugDeals[source] = nil

    if isDrugSaleBlocked(userId) then
        TriggerClientEvent('m_robbernpc:drug:result', source, {
            outcome = 'denied',
            message = 'Você não pode negociar drogas enquanto estiver neste serviço.'
        })
        return
    end

    local ped = getDrugPedFromNetId(netId, 10)
    if ped == 0 or not validateDrugPedDistance(source, ped, cfg.ServerMaxDistance or 4.0) then
        TriggerClientEvent('m_robbernpc:drug:result', source, {
            outcome = 'denied',
            message = 'O cidadão não está mais próximo o suficiente.'
        })
        return
    end

    if getPedDrugDealt(ped) then
        TriggerClientEvent('m_robbernpc:drug:result', source, {
            outcome = 'denied',
            message = 'Este cidadão não quer negociar agora.'
        })
        return
    end

    local available = collectSellableDrugs(userId)
    if #available <= 0 then
        TriggerClientEvent('m_robbernpc:drug:result', source, {
            outcome = 'denied',
            kind = 'aviso',
            message = 'Você não possui nenhuma droga disponível para vender.'
        })
        return
    end

    -- A partir daqui o NPC foi abordado: ninguém consegue farmar a mesma entidade.
    markPedDrugDealt(ped)

    -- Todo NPC que passou pela chance de elegibilidade demonstra interesse primeiro.
    -- O risco de ser um oficial disfarçado só é decidido quando o jogador confirma.
    local drug = available[math.random(1, #available)]

    local minQuantity = math.max(1, math.floor(tonumber(cfg.MinQuantity) or 1))
    local maxQuantity = math.max(minQuantity, math.floor(tonumber(cfg.MaxQuantity) or 5))
    local quantity = math.min(drug.stock, math.random(minQuantity, maxQuantity))
    if quantity <= 0 then
        TriggerClientEvent('m_robbernpc:drug:result', source, {
            outcome = 'denied',
            message = 'Seu inventário mudou antes da negociação.'
        })
        return
    end

    local minPrice = math.max(0, drug.minPricePerUnit)
    local maxPrice = math.max(minPrice, drug.maxPricePerUnit)
    local unitPrice = math.random(minPrice, maxPrice)
    local payment = unitPrice * quantity
    local timeout = math.max(5, math.floor(tonumber(cfg.OfferTimeout) or 18))
    local token = ('%s:%s:%06d'):format(tostring(source), tostring(os.time()), math.random(0, 999999))

    activeDrugDeals[source] = {
        token = token,
        userId = userId,
        netId = tonumber(netId),
        item = drug.item,
        label = drug.label,
        quantity = quantity,
        payment = payment,
        expiresAt = os.time() + timeout,
        confirmed = false
    }

    TriggerClientEvent('m_robbernpc:drug:result', source, {
        outcome = 'accepted',
        token = token,
        netId = tonumber(netId),
        item = drug.item,
        label = drug.label,
        quantity = quantity,
        timeout = timeout,
        dialogue = tostring(cfg.AcceptDialogue or 'Shh, fala baixo... que drogas você tem ai?'),
        dialogueDuration = math.max(5000, tonumber(cfg.DialogueDuration) or 5000)
    })

    SetTimeout((timeout + 2) * 1000, function()
        local deal = activeDrugDeals[source]
        if deal and tostring(deal.token) == token and os.time() >= (deal.expiresAt or 0) then
            activeDrugDeals[source] = nil
            TriggerClientEvent('m_robbernpc:drug:finished', source, {
                ok = false,
                message = 'A proposta expirou.'
            })
        end
    end)
end)

local function formatDrugMoney(value)
    local amount = math.max(0, math.floor(tonumber(value) or 0))
    local raw = tostring(amount)
    local formatted = raw:reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', '')
    return formatted
end

RegisterNetEvent('m_robbernpc:drug:confirm', function(token)
    local source = source
    local userId = vRP.getUserId(source)
    local deal = activeDrugDeals[source]
    local cfg = drugConfig()

    if not userId or not deal or tostring(deal.token) ~= tostring(token or '') then
        TriggerClientEvent('m_robbernpc:drug:finished', source, {
            ok = false,
            message = 'Esta proposta não é mais válida.'
        })
        return
    end

    if tonumber(deal.userId) ~= tonumber(userId) then
        activeDrugDeals[source] = nil
        return
    end

    if os.time() > (tonumber(deal.expiresAt) or 0) then
        activeDrugDeals[source] = nil
        TriggerClientEvent('m_robbernpc:drug:finished', source, {
            ok = false,
            message = 'A proposta expirou.'
        })
        return
    end

    if isDrugSaleBlocked(userId) then
        activeDrugDeals[source] = nil
        TriggerClientEvent('m_robbernpc:drug:finished', source, {
            ok = false,
            message = 'Você não pode concluir esta venda agora.'
        })
        return
    end

    local ped = getDrugPedFromNetId(deal.netId, 3)
    if ped == 0 or not validateDrugPedDistance(source, ped, cfg.ServerMaxDistance or 4.0) then
        activeDrugDeals[source] = nil
        TriggerClientEvent('m_robbernpc:drug:finished', source, {
            ok = false,
            message = 'Você se afastou do comprador.'
        })
        return
    end

    local stock = tonumber(vRP.getInventoryItemAmount(userId, deal.item)) or 0
    if stock < deal.quantity then
        activeDrugDeals[source] = nil
        TriggerClientEvent('m_robbernpc:drug:finished', source, {
            ok = false,
            message = 'Você não possui mais a quantidade combinada desta droga.'
        })
        return
    end

    -- A identidade do comprador é revelada SOMENTE depois de o jogador aceitar a proposta.
    -- Se for oficial disfarçado, nenhuma droga é removida e nenhuma animação de entrega ocorre.
    if deal.confirmed ~= true then
        local undercoverChance = drugClamp(cfg.UndercoverChance or 25, 0, 100)
        if math.random(1, 100) <= undercoverChance then
            activeDrugDeals[source] = nil
            dispatchDrugSalePolice(source, userId, deal)
            TriggerClientEvent('m_robbernpc:drug:undercover', source, {
                dialogue = tostring(cfg.UndercoverDialogue or cfg.UndercoverWarning or 'Alo?! Tem um meliante fazendo venda de drogas ilicitas! venham agora!'),
                dialogueDuration = math.max(5000, tonumber(cfg.UndercoverPhoneDuration) or 5000)
            })
            return
        end

        -- Comprador real. Reserva a negociação por tempo suficiente para a animação
        -- e aguarda o client avisar que a troca visual terminou.
        deal.confirmed = true
        deal.expiresAt = os.time() + 10
        activeDrugDeals[source] = deal
        TriggerClientEvent('m_robbernpc:drug:exchangeApproved', source, {
            token = deal.token
        })

        -- Fallback de limpeza caso o client interrompa/desconecte durante a animação.
        SetTimeout(12000, function()
            local pending = activeDrugDeals[source]
            if pending and tostring(pending.token) == tostring(deal.token)
                and pending.confirmed == true and os.time() >= (tonumber(pending.expiresAt) or 0) then
                activeDrugDeals[source] = nil
                TriggerClientEvent('m_robbernpc:drug:finished', source, {
                    ok = false,
                    message = 'A proposta expirou.'
                })
            end
        end)
        return
    end
end)

RegisterNetEvent('m_robbernpc:drug:complete', function(token)
    local source = source
    local userId = vRP.getUserId(source)
    local deal = activeDrugDeals[source]
    local cfg = drugConfig()

    if not userId or not deal or tostring(deal.token) ~= tostring(token or '') or deal.confirmed ~= true then
        TriggerClientEvent('m_robbernpc:drug:finished', source, {
            ok = false,
            message = 'Esta proposta não é mais válida.'
        })
        return
    end

    if tonumber(deal.userId) ~= tonumber(userId) then
        activeDrugDeals[source] = nil
        return
    end

    if os.time() > (tonumber(deal.expiresAt) or 0) then
        activeDrugDeals[source] = nil
        TriggerClientEvent('m_robbernpc:drug:finished', source, {
            ok = false,
            message = 'A proposta expirou.'
        })
        return
    end

    if isDrugSaleBlocked(userId) then
        activeDrugDeals[source] = nil
        TriggerClientEvent('m_robbernpc:drug:finished', source, {
            ok = false,
            message = 'Você não pode concluir esta venda agora.'
        })
        return
    end

    local ped = getDrugPedFromNetId(deal.netId, 3)
    if ped == 0 or not validateDrugPedDistance(source, ped, cfg.ServerMaxDistance or 4.0) then
        activeDrugDeals[source] = nil
        TriggerClientEvent('m_robbernpc:drug:finished', source, {
            ok = false,
            message = 'Você se afastou do comprador.'
        })
        return
    end

    local stock = tonumber(vRP.getInventoryItemAmount(userId, deal.item)) or 0
    if stock < deal.quantity then
        activeDrugDeals[source] = nil
        TriggerClientEvent('m_robbernpc:drug:finished', source, {
            ok = false,
            message = 'Você não possui mais a quantidade combinada desta droga.'
        })
        return
    end

    if not vRP.tryGetInventoryItem(userId, deal.item, deal.quantity, true) then
        activeDrugDeals[source] = nil
        TriggerClientEvent('m_robbernpc:drug:finished', source, {
            ok = false,
            message = 'Seu inventário mudou. A venda foi cancelada.'
        })
        return
    end

    local dirtyMoneyItem = tostring(cfg.DirtyMoneyItem or 'dirty_money')
    vRP.giveInventoryItem(userId, dirtyMoneyItem, deal.payment, true)
    activeDrugDeals[source] = nil

    local message = ('Você vendeu <b>%dx %s</b> e recebeu <b>$%s em dinheiro sujo</b>.')
        :format(deal.quantity, deal.label, formatDrugMoney(deal.payment))

    -- Log sem criar dependência obrigatória do vrp_admin.
    if GetResourceState('vrp_admin') == 'started' then
        pcall(function()
            exports['vrp_admin']:generateLog({
                category = 'inventario',
                room = 'venda-drogas-npc',
                user_id = userId,
                message = ('O USER_ID %s vendeu %sx %s para NPC e recebeu $%s em dinheiro sujo.')
                    :format(userId, deal.quantity, deal.item, deal.payment)
            })
        end)
    end

    local successDialogue = nil
    if type(cfg.SuccessDialogues) == 'table' and #cfg.SuccessDialogues > 0 then
        successDialogue = tostring(cfg.SuccessDialogues[math.random(1, #cfg.SuccessDialogues)])
    end

    TriggerClientEvent('m_robbernpc:drug:finished', source, {
        ok = true,
        message = message,
        quantity = deal.quantity,
        payment = deal.payment,
        item = deal.item,
        dialogue = successDialogue,
        dialogueDuration = math.max(5000, tonumber(cfg.DialogueDuration) or 5000)
    })
end)

RegisterNetEvent('m_robbernpc:drug:cancel', function(token)
    local source = source
    clearDrugDeal(source, token)
end)

local function clearVehicleBusy(netId, entity)
    if activeVehicles[netId] then
        activeVehicles[netId] = nil
    end
    setEntityState(entity, 'trunkrobberBusy', false)
end

local function getInventoryTotals(userId)
    local totals = {}
    local inventory = vRP.getInventory(userId) or {}

    for _, slotData in pairs(inventory) do
        if slotData and slotData.item then
            totals[slotData.item] = (totals[slotData.item] or 0) + (tonumber(slotData.amount) or 0)
        end
    end

    return totals
end

local function allLootWasTaken(session, userId)
    if not session or not session.loot or not session.initialTotals then return false end
    local current = getInventoryTotals(userId)

    for item, data in pairs(session.loot) do
        local before = session.initialTotals[item] or 0
        local expected = before + (tonumber(data.amount) or 0)
        if (current[item] or 0) < expected then
            return false
        end
    end

    return true
end

local function buildRandomLoot()
    local sourceList = {}

    for _, entry in ipairs(Config.Loot or {}) do
        -- getItemName retorna "Deleted" nessa vRP quando o item não existe.
        -- Evita transportar a tabela inteira de itens (que contém funções) pelo Proxy.
        local exists = entry.item and vRP.getItemName(entry.item) ~= 'Deleted'
        if exists then
            sourceList[#sourceList + 1] = entry
        else
            print(('^3[m_robbernpc]^7 Item ignorado na Config.Loot porque não existe na base: %s'):format(tostring(entry.item)))
        end
    end

    if #sourceList < Config.LootCount then
        return nil, ('Há apenas %s item(ns) válido(s) na Config.Loot; são necessários %s.'):format(#sourceList, Config.LootCount)
    end

    -- Fisher-Yates para garantir itens diferentes sem repetição.
    for i = #sourceList, 2, -1 do
        local j = math.random(i)
        sourceList[i], sourceList[j] = sourceList[j], sourceList[i]
    end

    local loot = {}
    for i = 1, Config.LootCount do
        local entry = sourceList[i]
        local min = tonumber(entry.min) or 1
        local max = tonumber(entry.max) or min
        if max < min then min, max = max, min end
        loot[entry.item] = { amount = math.random(min, max) }
    end

    return loot
end

local function denyStart(source, message, netId)
    if message then notify(source, 'negado', message) end
    TriggerClientEvent('m_robbernpc:requestDenied', source, netId)
end

local function radarUseFailure(source, cb, message)
    notify(source, 'negado', message, 5)
    if type(cb) == 'function' then
        cb({ error = message })
    end
    return false
end

-- Chamado diretamente pelo item rastreador_carro no shared.items.lua do inventory.
-- O próprio inventory consome 1x item antes de executar esta função e devolve
-- automaticamente em caso de cb({ error = ... }). Por isso NÃO use keep_item=true.
exports('useRadarItem', function(userId, source, item, slot, cb)
    userId = tonumber(userId)
    source = tonumber(source)

    if not userId or not source or tonumber(vRP.getUserId(source)) ~= userId then
        return radarUseFailure(source or 0, cb, 'Não foi possível validar o uso deste radar.')
    end

    if tostring(item or ''):lower() ~= tostring(Config.RadarItem or 'rastreador_carro'):lower() then
        return radarUseFailure(source, cb, 'Item de radar inválido.')
    end

    if isRecoveredRadarItemLocked(userId, source, item) then
        return radarUseFailure(source, cb, Config.RadarLockedUseText or 'Você não pode usar este rastreador enquanto estiver sendo rastreado.')
    end

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return radarUseFailure(source, cb, 'Não foi possível localizar seu personagem.')
    end

    local okVehicle, vehicle = pcall(GetVehiclePedIsIn, ped, false)
    if not okVehicle or not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return radarUseFailure(source, cb, 'Entre no seu veículo para instalar o radar.')
    end

    local okDriver, driver = pcall(GetPedInVehicleSeat, vehicle, -1)
    if not okDriver or driver ~= ped then
        return radarUseFailure(source, cb, 'Você precisa estar no banco do motorista para instalar o radar.')
    end

    if Config.RadarInstallRequireStopped ~= false and not isVehicleStationary(vehicle) then
        return radarUseFailure(source, cb, 'Pare o veículo antes de instalar o radar.')
    end

    local ownerId = getVehicleOwner(vehicle)
    if not ownerId or tonumber(ownerId) ~= userId then
        return radarUseFailure(source, cb, 'Você só pode instalar o radar em um veículo que pertença a você.')
    end

    if not getOwnedVehicleChest(vehicle) then
        return radarUseFailure(source, cb, 'Este veículo não possui um porta-malas cadastrado no m_garage.')
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    local key = getRadarStorageKey(ownerId, plate)
    if not key then
        return radarUseFailure(source, cb, 'Não foi possível identificar a placa deste veículo.')
    end

    if vehicleHasRadar(ownerId, vehicle) then
        return radarUseFailure(source, cb, Config.RadarAlreadyInstalledText or 'Este veículo já possui um radar oculto instalado.')
    end

    local saved = pcall(function()
        vRP.setSData(key, '1')
    end)

    if not saved then
        return radarUseFailure(source, cb, 'Não foi possível salvar o radar neste veículo.')
    end

    notify(source, 'sucesso', Config.RadarInstalledText or 'Radar oculto instalado neste veículo.', 6)

    if type(cb) == 'function' then
        cb(true)
    end

    return true
end)

-- Remove qualquer baú temporário deixado por crash/restart antigo.
CreateThread(function()
    Wait(1500)
    local pattern = 'WAREHOUSES:' .. Config.StoragePrefix .. '%'
    pcall(function()
        exports.oxmysql:execute('DELETE FROM vrp_srv_data WHERE dkey LIKE ?', { pattern })
    end)
end)

-- Compatibilidade com versões antigas: nelas um veículo de jogador também podia
-- receber trunkrobberRobbedNPC=true. Isso fazia o client bloqueá-lo para sempre.
-- Ao iniciar esta versão, removemos esse estado SOMENTE de veículos que possuem dono.
CreateThread(function()
    Wait(2500)

    local ok, vehicles = pcall(GetAllVehicles)
    if not ok or type(vehicles) ~= 'table' then return end

    for _, vehicle in ipairs(vehicles) do
        if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
            local ownerId = getVehicleOwner(vehicle)
            if ownerId then
                setEntityState(vehicle, 'trunkrobberRobbed', false)
                setEntityState(vehicle, 'trunkrobberRobbedNPC', false)

                -- Cooldowns válidos da versão atual continuam respeitados.
                -- Se não há cooldown em memória, remove eventual timestamp legado.
                local key = getPlayerVehicleCooldownKey(ownerId, vehicle)
                if not key or not playerVehicleCooldowns[key] then
                    setEntityState(vehicle, 'trunkrobberCooldownUntil', 0)
                end
            end
        end
    end
end)

-- /limparroubosportamalas
-- Limpa bloqueios definitivos de NPC, cooldowns de veículos de jogadores e
-- estados antigos deixados em entidades já spawnadas. NÃO remove rastreadores.
RegisterCommand(Config.ComandoLimparRoubos or 'limparroubosportamalas', function(source)
    source = tonumber(source) or 0

    if source > 0 then
        local userId = vRP.getUserId(source)
        local permission = Config.PermissaoLimparRoubos

        if not userId or (permission and permission ~= '' and not vRP.hasPermission(userId, permission)) then
            notify(source, 'negado', 'Você não possui permissão para limpar o histórico de roubos.', 5)
            return
        end
    end

    clearAllRobberyHistory()

    if source > 0 then
        notify(source, 'sucesso', 'Histórico e cooldowns de roubo de porta-malas foram limpos.', 6)
    else
        print('^2[m_robbernpc]^7 Histórico e cooldowns de roubo de porta-malas foram limpos.')
    end
end, false)

RegisterNetEvent('m_robbernpc:validateCandidate', function(netId, validationId)
    local source = source
    local userId = vRP.getUserId(source)
    local entity = getVehicleFromNetId(netId)
    local eligible = false

    if userId and entity ~= 0
        and validateDistance(source, entity, Config.ServerMaxDistance + 4.0)
        and isVehicleStationary(entity)
        and not hasBlockingOccupant(entity)
        and not activeVehicles[tonumber(netId)]
        and not getEntityState(entity, 'trunkrobberBusy') then

        local ownerId = getVehicleOwner(entity)

        -- NPC continua com bloqueio definitivo depois do primeiro roubo.
        if not ownerId then
            if not getEntityState(entity, 'trunkrobberRobbed') then
                eligible = true
            end

        -- Veículo de jogador usa cooldown por placa/dono em vez de bloqueio definitivo.
        elseif getOwnedVehicleChest(entity) then
            local ownerAllowed = tonumber(ownerId) ~= tonumber(userId) or Config.roubar_proprio_veiculo == true
            if ownerAllowed and getPlayerVehicleCooldownRemaining(ownerId, entity) <= 0 then
                -- Limpa eventual state antigo das versões onde player também ficava
                -- marcado como roubado para sempre.
                if getEntityState(entity, 'trunkrobberRobbed') then
                    setEntityState(entity, 'trunkrobberRobbed', false)
                end
                eligible = true
            end
        end
    end

    TriggerClientEvent('m_robbernpc:candidateResult', source, validationId, tonumber(netId), eligible)
end)

RegisterNetEvent('m_robbernpc:tryStart', function(netId, rearCoords)
    local source = source
    local userId = vRP.getUserId(source)
    if not userId then return end

    netId = tonumber(netId)
    if not netId then
        denyStart(source, 'Veículo inválido.', netId)
        return
    end

    if openSessions[source] then
        denyStart(source, 'Finalize o porta-malas que já está aberto antes de tentar outro.', netId)
        return
    end

    if activeVehicles[netId] == source then return end
    if activeVehicles[netId] then
        denyStart(source, 'Alguém já está arrombando este porta-malas.', netId)
        return
    end

    local now = os.time()
    if requestCooldown[source] and requestCooldown[source] >= now then
        denyStart(source, 'Aguarde um instante para tentar novamente.', netId)
        return
    end
    requestCooldown[source] = now + 1

    local entity = getVehicleFromNetId(netId)
    if entity == 0 then
        denyStart(source, 'Não foi possível localizar este veículo.', netId)
        return
    end

    if not validateDistance(source, entity, Config.ServerMaxDistance) then
        denyStart(source, 'Chegue mais perto do porta-malas.', netId)
        return
    end

    if not isVehicleStationary(entity) then
        denyStart(source, 'O veículo precisa estar completamente parado para arrombar o porta-malas.', netId)
        return
    end

    if hasBlockingOccupant(entity) then
        denyStart(source, 'Não é possível arrombar este veículo enquanto houver alguém vivo dentro.', netId)
        return
    end

    local vehicleOwnerId = getVehicleOwner(entity)
    if vehicleOwnerId and tonumber(vehicleOwnerId) == tonumber(userId) and Config.roubar_proprio_veiculo ~= true then
        denyStart(source, 'Você não pode arrombar o porta-malas do seu próprio veículo.', netId)
        return
    end

    local ownedChestMeta = nil
    if vehicleOwnerId then
        ownedChestMeta = getOwnedVehicleChest(entity)
        if not ownedChestMeta then
            denyStart(source, 'Este veículo não possui um porta-malas cadastrado no m_garage.', netId)
            return
        end
    end

    if vehicleOwnerId then
        local remaining = getPlayerVehicleCooldownRemaining(vehicleOwnerId, entity)
        if remaining > 0 then
            local minutes = math.ceil(remaining / 60)
            denyStart(source, ('Este veículo foi roubado recentemente. Aguarde %s minuto(s) para tentar novamente.'):format(minutes), netId)
            return
        end
    elseif getEntityState(entity, 'trunkrobberRobbed') then
        denyStart(source, 'Este veículo de NPC já foi roubado.', netId)
        return
    end

    if vRP.getInventoryItemAmount(userId, Config.LockpickItem) < 1 then
        denyStart(source, 'Você precisa de 1x Lock Pick para arrombar o porta-malas.', netId)
        return
    end

    local location = toVector3(rearCoords)
    local vehicleCoords = GetEntityCoords(entity)
    if not location or #(location - vehicleCoords) > (Config.ServerMaxDistance + 3.0) then
        location = vehicleCoords
    end

    activeVehicles[netId] = source
    setEntityState(entity, 'trunkrobberBusy', true)

    -- Verificamos o rastreador ANTES da taskbar. Se existir, o alarme original
    -- do GTA dispara imediatamente quando o arrombamento começa. O rastreador
    -- só é removido e recuperado pelo ladrão se a taskbar for concluída.
    local hadRadarAtStart = vehicleOwnerId and vehicleHasRadar(vehicleOwnerId, entity) or false

    -- O alerta é disparado ANTES do minigame, no exato início do arrombamento.
    -- O radar só será armado no chamado depois que o arrombamento for concluído
    -- com sucesso, evitando rastrear uma tentativa que falhou na taskbar.
    local alertId = ensurePoliceAlert(source, location)

    if hadRadarAtStart then
        TriggerClientEvent('m_robbernpc:vehicleAlarm', source, netId, tonumber(Config.RadarVehicleAlarmDuration) or 30000)
    end

    TriggerClientEvent('m_robbernpc:attemptStarted', source, netId)

    -- Mantida exatamente a chamada de taskbar solicitada pelo usuário.
    local finished = vRPclient.taskBar(source, 3000, math.random(7, 15))

    entity = getVehicleFromNetId(netId)

    if not finished then
        clearVehicleBusy(netId, entity)
        TriggerClientEvent('m_robbernpc:attemptEnded', source, false, netId)
        notify(source, 'negado', 'Você falhou ao arrombar o porta-malas.', 5)
        return
    end

    if entity == 0 or not validateDistance(source, entity, Config.ServerMaxDistance + 1.5) then
        clearVehicleBusy(netId, entity)
        TriggerClientEvent('m_robbernpc:attemptEnded', source, false, netId)
        notify(source, 'negado', 'O veículo ficou longe demais durante o arrombamento.', 5)
        return
    end

    -- Revalida no final: se alguém entrou no carro ou ele começou a se mover
    -- durante a taskbar, o porta-malas não é aberto.
    if not isVehicleStationary(entity) then
        clearVehicleBusy(netId, entity)
        TriggerClientEvent('m_robbernpc:attemptEnded', source, false, netId)
        notify(source, 'negado', 'O veículo começou a se mover durante o arrombamento.', 5)
        return
    end

    if hasBlockingOccupant(entity) then
        clearVehicleBusy(netId, entity)
        TriggerClientEvent('m_robbernpc:attemptEnded', source, false, netId)
        notify(source, 'negado', 'Alguém entrou no veículo durante o arrombamento.', 5)
        return
    end

    -- Se o veículo possuía rastreador no início e a taskbar foi concluída:
    -- 1) remove o rastreador do veículo de forma persistente;
    -- 2) entrega 1x rastreador_carro ao ladrão;
    -- 3) protege esse item contra descarte/transferência até o rastreamento acabar;
    -- 4) arma o rastreamento policial para começar quando ele sair da área vermelha.
    if hadRadarAtStart and vehicleOwnerId and alertId and activeAlerts[alertId] then
        if removeVehicleRadar(vehicleOwnerId, entity) then
            activeAlerts[alertId].radarEnabled = true
            activeAlerts[alertId].radarRecovered = true

            vRP.giveInventoryItem(userId, Config.RadarItem or 'rastreador_carro', 1, true)
            lockRecoveredRadarItem(source, userId, alertId)

            if Config.RadarRecoveredText and Config.RadarRecoveredText ~= '' then
                notify(source, 'aviso', Config.RadarRecoveredText, 6)
            end
        else
            print(('^1[m_robbernpc]^7 Falha ao remover o rastreador do veículo do user_id %s.'):format(tostring(vehicleOwnerId)))
        end
    end

    local sessionType = vehicleOwnerId and 'player' or 'npc'
    local chestItems = nil
    local maxWeight = tonumber(Config.TrunkWeight) or 50
    local realChestKey = nil
    local realOwnerId = nil

    if sessionType == 'player' then
        -- Para veículos de jogadores, NÃO gera loot.
        -- Espelhamos o conteúdo real do porta-malas no mesmo NUI do inventory
        -- e, ao fechar, sincronizamos todas as alterações de volta.
        local realChest = ownedChestMeta or getOwnedVehicleChest(entity)
        if not realChest then
            clearVehicleBusy(netId, entity)
            TriggerClientEvent('m_robbernpc:attemptEnded', source, false, netId)
            notify(source, 'negado', 'Não foi possível localizar o porta-malas cadastrado deste veículo.', 5)
            return
        end

        realChestKey = realChest.chestKey
        realOwnerId = realChest.ownerId
        maxWeight = realChest.maxWeight
        chestItems = decodeChest(vRP.getSData(realChestKey))
    else
        local loot, lootError = buildRandomLoot()
        if not loot then
            clearVehicleBusy(netId, entity)
            TriggerClientEvent('m_robbernpc:attemptEnded', source, false, netId)
            notify(source, 'negado', 'Não foi possível montar o loot deste porta-malas.', 5)
            print('^1[m_robbernpc]^7 ' .. tostring(lootError))
            return
        end

        chestItems = loot

        local lootWeight = vRP.computeChestWeight(loot) or 0
        maxWeight = math.max(maxWeight, math.ceil(lootWeight + 1))
    end

    if Config.ConsumeLockpick then
        vRP.tryGetInventoryItem(userId, Config.LockpickItem, 1, true)
    end

    -- NPC: continua bloqueado definitivamente depois do primeiro roubo.
    -- Player: pode ser roubado novamente depois do cooldown configurado.
    if sessionType == 'player' then
        startPlayerVehicleCooldown(vehicleOwnerId, entity)
    else
        setEntityState(entity, 'trunkrobberRobbed', true)
        setEntityState(entity, 'trunkrobberRobbedNPC', true)
        setEntityState(entity, 'trunkrobberCooldownUntil', 0)
    end

    setEntityState(entity, 'trunkrobberBusy', false)
    activeVehicles[netId] = nil
    TriggerClientEvent('m_robbernpc:vehicleRobbed', -1, netId)

    local chestId = ('%s%s_%s_%s'):format(Config.StoragePrefix, userId, os.time(), math.random(100000, 999999))
    local storageKey = 'WAREHOUSES:' .. chestId
    vRP.setSData(storageKey, json.encode(chestItems))

    openSessions[source] = {
        type = sessionType,
        chestId = chestId,
        netId = netId,
        maxWeight = maxWeight,
        opened = false,
        loot = sessionType == 'npc' and chestItems or nil,
        initialTotals = sessionType == 'npc' and getInventoryTotals(userId) or nil,
        realChestKey = realChestKey,
        realOwnerId = realOwnerId
    }

    TriggerClientEvent('m_robbernpc:attemptEnded', source, true, netId)
    TriggerClientEvent('m_robbernpc:prepareInventory', source, netId, chestId, maxWeight, sessionType)

    -- Se por qualquer motivo o client não pedir a abertura, remove o armazenamento temporário.
    SetTimeout(30000, function()
        local session = openSessions[source]
        if session and session.chestId == chestId and not session.opened then
            openSessions[source] = nil
            cleanupTempChest(chestId, 0)
            TriggerClientEvent('m_robbernpc:forceSessionEnd', source, chestId, netId)
        end
    end)
end)

RegisterNetEvent('m_robbernpc:readyOpenChest', function(chestId)
    local source = source
    local session = openSessions[source]
    if not session or session.chestId ~= chestId then return end
    if session.opened then return end

    if GetResourceState(Config.InventoryResource) ~= 'started' then
        notify(source, 'negado', 'O inventory não está iniciado.', 5)
        openSessions[source] = nil
        cleanupTempChest(chestId, 0)
        TriggerClientEvent('m_robbernpc:forceSessionEnd', source, chestId, session.netId)
        return
    end

    local entity = getVehicleFromNetId(session.netId)
    if entity == 0 or not validateDistance(source, entity, Config.ServerMaxDistance + 2.0) then
        notify(source, 'negado', 'Você se afastou do veículo.', 5)
        openSessions[source] = nil
        cleanupTempChest(chestId, 0)
        TriggerClientEvent('m_robbernpc:forceSessionEnd', source, chestId, session.netId)
        return
    end

    session.opened = true

    -- Usa o MESMO sistema/NUI do inventory enviado. O tipo WAREHOUSES é temporário,
    -- isolado por um ID aleatório e não precisa alterar nenhum arquivo do inventory.
    TriggerClientEvent('Warehouses:Chest', source, false, chestId, session.maxWeight)

    -- O fechamento automático continua existindo SOMENTE para o loot gerado de NPC.
    -- Porta-malas de jogador permanece aberto normalmente para mostrar/manipular
    -- o conteúdo real existente nele.
    if session.type == 'npc' then
        local userId = vRP.getUserId(source)
        if userId then
            CreateThread(function()
                while true do
                    local currentSession = openSessions[source]
                    if not currentSession or currentSession.chestId ~= chestId then return end

                    if allLootWasTaken(currentSession, userId) then
                        if not currentSession.autoCloseTriggered then
                            currentSession.autoCloseTriggered = true
                            inventoryClient._closeInventory(source)
                        end
                        return
                    end

                    Wait(350)
                end
            end)
        end
    end
end)

RegisterNetEvent('m_robbernpc:finishChest', function(chestId)
    local source = source
    local session = openSessions[source]
    if not session or session.chestId ~= chestId then return end

    openSessions[source] = nil

    if session.type == 'player' then
        -- Primeiro deixa o inventory salvar a cópia temporária; depois grava o
        -- resultado no chest:u<dono>veh_<modelo>, que é o porta-malas REAL.
        syncOwnedVehicleChest(session, 1600)
    else
        -- NPC continua descartando o armazenamento temporário depois de fechar.
        cleanupTempChest(chestId, 1500)
    end
end)

RegisterNetEvent('m_robbernpc:leftAlertArea', function(alertId)
    local source = source
    local alert = activeAlerts[alertId]
    if not alert or alert.source ~= source then return end

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return end

    local origin = vec3(alert.coords.x, alert.coords.y, alert.coords.z)
    local distance = #(GetEntityCoords(ped) - origin)

    -- Servidor valida a distância para o client não conseguir apagar o chamado manualmente.
    if distance >= (Config.AlertEndDistance - 5.0) then
        -- O comportamento antigo continua igual: a polícia é avisada e a área
        -- vermelha desaparece assim que o meliante sai dela.
        for _, policeSource in ipairs(getPoliceSources()) do
            notify(policeSource, 'aviso', Config.PoliceLeftAreaText or 'O meliante acaba de sair da area do roubo', 8)
        end

        local radarEnabled = alert.radarEnabled == true
        local robberSource = alert.source

        removePoliceAlert(alertId)

        -- Se o veículo roubado possuía radar oculto, substitui a área vermelha por
        -- um rastreamento de posição REAL do ladrão durante 90 segundos.
        if radarEnabled then
            startRadarTracking(alertId, robberSource)
        end
    end
end)

AddEventHandler('playerDropped', function()
    local source = source

    for netId, ownerSource in pairs(activeVehicles) do
        if ownerSource == source then
            local entity = getVehicleFromNetId(netId)
            clearVehicleBusy(netId, entity)
        end
    end

    local session = openSessions[source]
    if session then
        openSessions[source] = nil

        if session.type == 'player' then
            -- O inventory também salva no playerDropped. Esperamos mais tempo
            -- e sincronizamos a cópia final com o porta-malas verdadeiro.
            syncOwnedVehicleChest(session, 2600)
        else
            -- Delay maior para não disputar com o fechamento do inventory no playerDropped.
            cleanupTempChest(session.chestId, 2500)
        end
    end

    local alertId = alertBySource[source]
    if alertId then removePoliceAlert(alertId) end

    local trackerId = trackerBySource[source]
    if trackerId then stopRadarTracking(trackerId) end

    unlockRecoveredRadarItem(source)
    activeDrugDeals[source] = nil
    drugRequestCooldown[source] = nil
    drugInventoryCheckCooldown[source] = nil
    requestCooldown[source] = nil
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for alertId in pairs(activeAlerts) do
        TriggerClientEvent('m_robbernpc:policeAlert:remove', -1, alertId)
    end

    for trackerId in pairs(activeTrackers) do
        TriggerClientEvent('m_robbernpc:policeTracker:remove', -1, trackerId)
    end
end)
