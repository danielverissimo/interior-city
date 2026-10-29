local Tunnel = module('vrp','lib/Tunnel')
local Proxy = module('vrp','lib/Proxy')
vRP = Proxy.getInterface('vRP')
vRPclient = Tunnel.getInterface('vRP')

ServerAPI = {}
Tunnel.bindInterface(GetCurrentResourceName(), ServerAPI)
ClientAPI = Tunnel.getInterface(GetCurrentResourceName())

-- ============================================================================
-- INTEGRAÇÃO COM O SISTEMA CENTRAL DE LOGS DO MAGE ADMIN
-- ============================================================================
-- Não existe dependência obrigatória no fxmanifest: se o painel estiver reiniciando,
-- as ocorrências ficam em uma fila curta e são reenviadas quando o export voltar.
local MAGE_LOG_RESOURCE <const> = GetConvar("ic_admin_service_resource", "ic_admin")
local MAGE_LOG_QUEUE_LIMIT <const> = 250
local mageLogQueue = {}

local function mageLogSlug(value)
    value = tostring(value or 'desconhecido'):lower()
    value = value:gsub('%s+', '_'):gsub('[^%w_]', ''):gsub('_+', '_')
    value = value:gsub('^_+', ''):gsub('_+$', '')
    return value ~= '' and value or 'desconhecido'
end

local function trySendMageLog(logKey, payload)
    if GetResourceState(MAGE_LOG_RESOURCE) ~= 'started' then
        return false
    end

    local ok, sent, reason = pcall(function()
        return exports[MAGE_LOG_RESOURCE]:sendLog(logKey, payload)
    end)

    if not ok then
        return false
    end

    -- Export executado com sucesso. "Webhook não configurada" não é falha do
    -- resource integrado e não deve ficar sendo reenviada indefinidamente.
    if sent == true or reason == 'Webhook não configurada.' or reason == 'Log não cadastrado no catálogo.' then
        return true
    end

    -- Qualquer outra resposta do export foi processada pelo painel; não trava o script.
    return true
end

local function sendMageLog(logKey, payload)
    payload = type(payload) == 'table' and payload or {}
    payload.occurredAt = tonumber(payload.occurredAt) or os.time()
    if trySendMageLog(logKey, payload) then return end

    if #mageLogQueue >= MAGE_LOG_QUEUE_LIMIT then
        table.remove(mageLogQueue, 1)
    end
    mageLogQueue[#mageLogQueue + 1] = { key = logKey, payload = payload }
end

CreateThread(function()
    while true do
        Wait(5000)
        if #mageLogQueue > 0 and GetResourceState(MAGE_LOG_RESOURCE) == 'started' then
            local pending = mageLogQueue
            mageLogQueue = {}
            for _, entry in ipairs(pending) do
                if not trySendMageLog(entry.key, entry.payload) then
                    if #mageLogQueue < MAGE_LOG_QUEUE_LIMIT then
                        mageLogQueue[#mageLogQueue + 1] = entry
                    end
                end
            end
        end
    end
end)



local FARM_CONFIG_FILE = 'shared/config.json'

local function loadFarmConfig()
    local raw = LoadResourceFile(GetCurrentResourceName(), FARM_CONFIG_FILE)
    local ok,data = pcall(json.decode, raw or '{}')
    if not ok or type(data)~='table' then data={} end
    Config = data
    Config.Routes = type(Config.Routes)=='table' and Config.Routes or {}
    Config.Rewards = type(Config.Rewards)=='table' and Config.Rewards or {}
    Config.RouteBlips = type(Config.RouteBlips)=='table' and Config.RouteBlips or {}
    Config.coinAmount = tonumber(Config.coinAmount) or 1
    Config.coinMultiplier = tonumber(Config.coinMultiplier) or 1.0
    Config.coinTime = tonumber(Config.coinTime) or 3600
    Config.imageURL = tostring(Config.imageURL or 'http://127.0.0.1/images/')
    Config.routeCooldownTime = tonumber(Config.routeCooldownTime) or 5
    return Config
end

local function saveFarmConfig()
    if not SaveResourceFile(GetCurrentResourceName(), FARM_CONFIG_FILE, json.encode(Config), -1) then
        return false,'Não foi possível gravar shared/config.json.'
    end
    TriggerClientEvent('m_farm:configSync', -1, Config)
    return true
end

loadFarmConfig()

-- Coordenadas vindas de shared/config.json são tabelas { x, y, z }, enquanto
-- GetEntityCoords retorna um vector3 nativo do FiveM. Não fazemos operações
-- matemáticas diretamente entre os dois tipos para manter o config JSON
-- serializável e compatível com o painel de configuração.
local function readCoordComponent(coords, key, index)
    if coords == nil then return nil end

    local ok, value = pcall(function()
        return coords[key]
    end)
    if ok and value ~= nil then
        return tonumber(value)
    end

    if type(coords) == 'table' then
        return tonumber(coords[index])
    end

    return nil
end

local function distanceBetweenCoords(a, b)
    local ax = readCoordComponent(a, 'x', 1)
    local ay = readCoordComponent(a, 'y', 2)
    local az = readCoordComponent(a, 'z', 3)
    local bx = readCoordComponent(b, 'x', 1)
    local by = readCoordComponent(b, 'y', 2)
    local bz = readCoordComponent(b, 'z', 3)

    if not ax or not ay or not az or not bx or not by or not bz then
        return nil
    end

    local dx = ax - bx
    local dy = ay - by
    local dz = az - bz
    return math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
end

CreateThread(function()
    Wait(500)
    TriggerClientEvent('m_farm:configSync', -1, Config)
end)

RegisterNetEvent('m_farm:requestConfig', function()
    TriggerClientEvent('m_farm:configSync', source, Config)
end)

exports('getFarmConfig', function()
    return Config
end)

exports('upsertFarmLink', function(payload)
    if type(payload)~='table' or type(payload.rewardType)~='string' or payload.rewardType=='' then
        return false,'Farm inválido.'
    end
    local rewardType=payload.rewardType
    local routeType=tostring(payload.routeType or '')
    if routeType=='' or not Config.RouteBlips[routeType] then
        return false,'Tipo de rota inexistente no m_farm: '..routeType
    end

    local routeFound=nil
    for i,r in ipairs(Config.Routes) do
        if r.rewardType==rewardType then routeFound=i break end
    end
    local route={routeType=routeType,rewardType=rewardType,permissions=payload.permissions or {}}
    if routeFound then Config.Routes[routeFound]=route else table.insert(Config.Routes,route) end
    Config.Rewards[rewardType]=payload.rewards or {}
    return saveFarmConfig()
end)

exports('removeFarmLink', function(rewardType)
    rewardType=tostring(rewardType or '')
    for i=#Config.Routes,1,-1 do
        if Config.Routes[i].rewardType==rewardType then table.remove(Config.Routes,i) end
    end
    Config.Rewards[rewardType]=nil
    return saveFarmConfig()
end)

exports('reloadFarmConfig', function()
    loadFarmConfig()
    TriggerClientEvent('m_farm:configSync', -1, Config)
    return true
end)


local orgsMultiplier <const> = {}
local usersRoutes <const> = {}
local usersRoutesCooldown <const> = {}
local usersAttemptTracker <const> = {}

local ATTEMPT_LIMIT <const> = 3
local ATTEMPT_WINDOW <const> = 5

--- @param userId integer
--- @param permissions table
--- @return boolean
local function hasPermission(userId, permissions)
    for _, permission in ipairs(permissions) do
        if vRP.hasPermission(userId, permission) then
            return true
        end
    end
    return false
end

--- @param userId integer
--- @return number
local function calculateDominationMultiplier(userId)
    local multiplier = 1.0
    local _, orgName = exports['dm_module']:GetGroupType(userId)
    local domination = exports['dm_module']:GetUserDomination(userId)
    
    local hasDomination = domination and domination.zones and #domination.zones > 0
    local hasGlobalDomination = orgName and GlobalState.dominationOwner == orgName
    -- local hasPistolDomination = exports['brasil_dominacao_pistol']:isBoostDominationPistol(orgName)
    local hasPistolDomination = false

    if hasGlobalDomination then
        multiplier = 3.0
    elseif hasDomination or hasPistolDomination then
        multiplier = 2.0
    end

    return multiplier
end

--- @param userId integer
--- @return number
local function getUserMultiplier(userId)
    local multiplier = calculateDominationMultiplier(userId)
    local userOrg = vRP.getUserGroupOrg(userId)
    
    if userOrg and userOrg ~= '' and orgsMultiplier[userOrg] then
        if os.time() <= orgsMultiplier[userOrg].endTime then
            multiplier = (multiplier == 1.0) and 2.0 or (multiplier + Config.coinMultiplier)
        end
    end

    if multiplier > 4.0 then
        multiplier = 4.0
    end

    return multiplier
end

--- @param userId integer
--- @param routeType string
--- @return table
local function organizeRoutesToClient(userId, routeType)
    local routes = {}
    for _, route in ipairs(Config.Rewards[routeType]) do
        table.insert(routes, {
            name = route.name,
            icon = Config.imageURL .. '/' .. route.image .. '.png',
            coins = Config.coinAmount,
            multiplier = getUserMultiplier(userId),
        })
    end
    return routes
end

--- @param index integer
--- @return void
function ServerAPI.openRoutes(index)
    local source = source
    local userId = vRP.getUserId(source)

    -- If no index provided, pick the first route the user has permission for
    if not index then
        for i, route in ipairs(Config.Routes) do
            if hasPermission(userId, route.permissions) and Config.Rewards[route.rewardType] then
                index = i
                break
            end
        end
    end

    if not index or not Config.Routes[index] then
        TriggerClientEvent('Notify', source, 'negado', 'Nenhuma rota disponível para suas permissões.')
        return
    end
    if not hasPermission(userId, Config.Routes[index].permissions) then
        TriggerClientEvent('Notify', source, 'negado', 'Você não possui permissão para esta rota.')
        return
    end
    if not Config.Rewards[Config.Routes[index].rewardType] then
        TriggerClientEvent('Notify', source, 'negado', 'Recompensas não configuradas para esta rota.')
        return
    end

    ClientAPI.openRoutes(source, organizeRoutesToClient(userId, Config.Routes[index].rewardType))
    usersRoutes[userId] = { routeIndex = index, initialized = false }
end

--- @return boolean
function ServerAPI.boostRoute()
    local source = source
    local userId = vRP.getUserId(source)

    if not userId then return false end

    local userOrg = vRP.getUserGroupOrg(userId)
    if not userOrg or userOrg == '' or not vRP.tryGetInventoryItem(userId, 'coin', 1) then
        TriggerClientEvent('Notify', source, 'negado', 'Você não possui moedas suficientes.')
        return false
    end

    if orgsMultiplier[userOrg] then
        if os.time() <= orgsMultiplier[userOrg].endTime then
            orgsMultiplier[userOrg].endTime = orgsMultiplier[userOrg].endTime + Config.coinTime
        else
            orgsMultiplier[userOrg] = { endTime = os.time() + Config.coinTime }
        end
    else
        orgsMultiplier[userOrg] = { endTime = os.time() + Config.coinTime }
    end

    TriggerClientEvent('Notify', source, 'sucesso', 'Você aumentou o tempo de coleta dobrada da sua facção em ' .. Config.coinTime .. ' segundos.')

    return true
end

--- @param routeName string
--- @param region string
--- @return boolean
function ServerAPI.startRoute(routeName, region)
    local source = source
    local userId = vRP.getUserId(source)
    if not userId then return false end

    if usersRoutes[userId] and usersRoutes[userId].initialized then
        TriggerClientEvent('Notify', source, 'negado', 'Você já está em uma rota ativa.')
        return false
    end

    local routeIndex = usersRoutes[userId].routeIndex
    local rewardType = Config.Routes[routeIndex].rewardType
    local rewards = Config.Rewards[rewardType]

    local existsRoute = false
    if not rewards then return end
    for _, reward in ipairs(rewards) do
        if reward.name == routeName then
            existsRoute = true
            break
        end
    end

    if not existsRoute then return end

    local routeType = Config.Routes[routeIndex].routeType
    if not Config.RouteBlips[routeType] then return end

    local region = (region == 'north') and 'North' or 'South'
    local blips = Config.RouteBlips[routeType][region]
    if not blips then return end

    ClientAPI.startRoute(source, routeType, region)
    usersRoutes[userId] = { routeIndex = routeIndex, initialized = true, actualIndex = 1, routeRegion = region, routeName = routeName }
    TriggerClientEvent('Notify', source, 'sucesso', 'Você iniciou a rota. Para cancelar aperta F7')
end

local function handleRapidAttempts(userId)
    local currentTime = os.time()

    if not usersAttemptTracker[userId] then
        usersAttemptTracker[userId] = { count = 0, startTime = currentTime }
    end

    local attemptData = usersAttemptTracker[userId]

    if (currentTime - attemptData.startTime) <= ATTEMPT_WINDOW then
        attemptData.count = attemptData.count + 1
        if attemptData.count >= ATTEMPT_LIMIT then
            print('USUÁRIO TENTATIVAS RÁPIDAS => ' .. userId)
            -- DropPlayer(vRP.getSource(userId), 'Você foi banido por tentativas rápidas de coleta de rota.')
            -- vRP.setBanned(userId, true)
            usersAttemptTracker[userId] = nil
            return true
        end
    else
        usersAttemptTracker[userId] = { count = 1, startTime = currentTime }
    end

    return false
end


-- Os farms são separados por facção no painel. O vínculo principal usa o nome da
-- organização retornado pela vRP e possui fallback pelas permissões específicas
-- cadastradas no m_craft, evitando misturar, por exemplo, Mafia e Verdes na mesma
-- webhook apenas porque ambas utilizam a rota de Armas.
local farmOrgLinks = nil

local function loadFarmOrgLinks()
    local links = {}
    local raw = LoadResourceFile('m_craft', 'shared/config.json')
    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' and type(decoded.coords) == 'table' then
            for _, org in ipairs(decoded.coords) do
                if type(org) == 'table' and tostring(org.name or '') ~= '' and tostring(org.farmRewardType or '') ~= '' then
                    links[#links + 1] = org
                end
            end
        end
    end
    farmOrgLinks = links
    return links
end

local function resolveFarmOrgName(userId, rewardType)
    local links = farmOrgLinks or loadFarmOrgLinks()
    local directOrg = nil
    local ok, value = pcall(function() return vRP.getUserGroupOrg(userId) end)
    if ok and value and tostring(value) ~= '' then
        directOrg = tostring(value)
    end

    if directOrg then
        for _, org in ipairs(links) do
            if tostring(org.name):lower() == directOrg:lower() and tostring(org.farmRewardType or '') == tostring(rewardType or '') then
                return tostring(org.name)
            end
        end
    end

    -- Fallback seguro pelas permissões específicas da própria facção.
    for _, org in ipairs(links) do
        if tostring(org.farmRewardType or '') == tostring(rewardType or '') then
            local specificPermissions = { org.armazemPermission, org.craftPermission }
            for _, permission in ipairs(specificPermissions) do
                if permission and permission ~= '' and vRP.hasPermission(userId, permission) then
                    return tostring(org.name)
                end
            end
        end
    end

    return directOrg
end

local function farmLogKey(orgName)
    return ('farm_%s_collect'):format(mageLogSlug(orgName))
end

local function formatFarmCollectedItems(items)
    local rows = {}
    for _, item in ipairs(items or {}) do
        rows[#rows + 1] = ('• %s x%s'):format(tostring(item.item or 'item'), tostring(item.amount or 0))
    end
    return #rows > 0 and table.concat(rows, '\n') or 'Nenhum item recebido.'
end

--- @param route string
--- @param region string
--- @param index integer
--- @return boolean
function ServerAPI.collectRoute(route, region, index)
    local source = source
    local userId = vRP.getUserId(source)
    if not userId then return false end

    if handleRapidAttempts(userId) then return false end

    local routeState = usersRoutes[userId]
    if not routeState or not routeState.initialized then
        return false
    end

    local routeIndex = routeState.routeIndex
    local routeConfig = Config.Routes[routeIndex]
    if not routeConfig then
        print(('[m_farm] Rota ativa inválida para o passaporte %s (índice %s).'):format(
            tostring(userId), tostring(routeIndex)
        ))
        return false
    end

    local routeType = routeConfig.routeType
    local rewardType = routeConfig.rewardType
    local routeRegion = routeState.routeRegion
    local routeName = routeState.routeName
    local routeRegions = Config.RouteBlips[routeType]
    local routePoints = routeRegions and routeRegions[routeRegion]

    if index ~= routeState.actualIndex then 
        print('SUSPEITO HACK ROTAS => ' .. userId .. ' | INDEX ESPERADO: ' .. routeState.actualIndex .. ' | INDEX RECEBIDO: ' .. tostring(index))
        return false 
    end

    if not routePoints or not routePoints[index] then 
        print('SUSPEITO HACK ROTAS => ' .. userId)
        return false 
    end

    local currentTime = os.time()
    if usersRoutesCooldown[userId] and usersRoutesCooldown[userId].time and (currentTime - usersRoutesCooldown[userId].time < Config.routeCooldownTime) then
        -- print('COOLDOWN ROTAS => ' .. userId)
        TriggerClientEvent('Notify', source, 'negado', 'Espere '..(Config.routeCooldownTime - (currentTime - usersRoutesCooldown[userId].time))..' segundos para coletar.')
        return false
    end

    local playerPed = GetPlayerPed(source)
    if not playerPed or playerPed <= 0 then
        return false
    end

    local coords = GetEntityCoords(playerPed)
    local blipCoords = routePoints[index].coords
    local distance = distanceBetweenCoords(coords, blipCoords)

    if not distance then
        print(('[m_farm] Coordenada inválida na rota %s / %s / ponto %s.'):format(
            tostring(routeType), tostring(routeRegion), tostring(index)
        ))
        return false
    end

    if distance >= 10.0 then 
        print('SUSPEITO HACK ROTAS => ' .. userId)
        return false 
    end

    usersRoutesCooldown[userId] = { time = currentTime }

    local rewards = Config.Rewards[rewardType]
    if not rewards then return false end

    local collectedItems = {}
    for _, reward in ipairs(rewards) do
        if reward.name == routeName then
            for _, item in ipairs(reward.items) do
                local amount = math.random(item.min, item.max) * (getUserMultiplier(userId) + (routeRegion == 'North' and 1.0 or 0.0))
                if vRP.computeInvWeight(userId) + vRP.getItemWeight(item.item) * amount <= vRP.getInventoryMaxWeight(userId) then
                    vRP.giveInventoryItem(userId, item.item, amount, true)
                    collectedItems[#collectedItems + 1] = { item = item.item, amount = amount }
                else
                    TriggerClientEvent('Notify', source, 'negado', 'Mochila cheia.')
                    break
                end
            end
            break
        end
    end

    -- Gera uma ocorrência por PONTO somente quando ao menos um item foi realmente entregue.
    -- Assim uma tentativa com mochila cheia não produz uma log falsa de coleta.
    if #collectedItems > 0 then
        local orgName = resolveFarmOrgName(userId, rewardType)
        if orgName and tostring(orgName) ~= '' then
            local regionLabel = routeRegion == 'North' and 'Norte' or 'Sul'
            local pointTotal = #routePoints
            sendMageLog(farmLogKey(orgName), {
                actorId = userId,
                actorLabel = 'JOGADOR',
                details = (
                    'Facção: %s\nTipo de farm: %s\nRota: %s\nRegião: %s\nPonto coletado: %d/%d\nItens recebidos:\n%s'
                ):format(
                    tostring(orgName),
                    tostring(rewardType),
                    tostring(routeName),
                    regionLabel,
                    tonumber(index) or 0,
                    pointTotal,
                    formatFarmCollectedItems(collectedItems)
                )
            })
        end
    end

    routeState.actualIndex = (routeState.actualIndex + 1 <= #routePoints) and routeState.actualIndex + 1 or 1
    return true
end

--- @param userId integer
--- @return void
local function finishRoute(userId)
    if not userId or not usersRoutes[userId] then return end

    usersRoutes[userId] = nil
    usersAttemptTracker[userId] = nil
    usersRoutesCooldown[userId] = nil
end

--- @return void
function ServerAPI.finishRoute()
    local source = source
    local userId = vRP.getUserId(source)
    
    finishRoute(userId)
    TriggerClientEvent('Notify', source, 'sucesso', 'Você finalizou a rota.')
end

AddEventHandler('vRP:playerLeave',function(userId, source)
    if not userId then return end

    finishRoute(userId)
end)