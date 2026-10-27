local Proxy = module("vrp", "lib/Proxy")
local vRP = Proxy.getInterface("vRP")

local televisions = {}
local channels = {}
local defaultChannelCount = 0

local function notify(source, message, kind)
    TriggerClientEvent("m_television:notify", source, tostring(message or ""), kind or "info")
end

local function getPassport(source)
    if not source or source <= 0 then return nil end

    if vRP and vRP.Passport then
        local ok, value = pcall(vRP.Passport, source)
        if ok and value then return value end
    end

    if vRP and vRP.getUserId then
        local ok, value = pcall(vRP.getUserId, source)
        if ok and value then return value end
    end

    return nil
end

local function normalize(value)
    return tostring(value or ""):lower()
end

local function getUserGroups(passport)
    if not passport or not vRP then return {} end

    if vRP.GetUserGroups then
        local ok, groups = pcall(vRP.GetUserGroups, passport)
        if ok and type(groups) == "table" then return groups end
    end

    if vRP.getUserGroups then
        local ok, groups = pcall(vRP.getUserGroups, passport)
        if ok and type(groups) == "table" then return groups end
    end

    return {}
end

local function hasGroup(passport, group)
    if not passport or not group or group == "" or not vRP then return false end

    local checks = {
        { "HasGroup", passport, group },
        { "hasGroup", passport, group }
    }

    for _, check in ipairs(checks) do
        local fn = vRP[check[1]]
        if fn then
            local ok, result = pcall(fn, check[2], check[3])
            if ok and result then return true end
        end
    end

    local expected = normalize(group)
    for name, data in pairs(getUserGroups(passport)) do
        local candidate = type(name) == "string" and name or nil
        if not candidate and type(data) == "table" then
            candidate = data.group or data.groupId or data.name
        end
        if candidate and normalize(candidate) == expected then
            return true
        end
    end

    return false
end

local function hasPermission(passport, permission)
    if not passport or not permission or permission == "" or not vRP then return false end

    local checks = {
        { "HasPermission", passport, permission },
        { "hasPermission", passport, permission }
    }

    for _, check in ipairs(checks) do
        local fn = vRP[check[1]]
        if fn then
            local ok, result = pcall(fn, check[2], check[3])
            if ok and result then return true end
        end
    end

    return false
end

local function checkAccess(source, section)
    local rule = Config.Permissions and Config.Permissions[section]
    if not rule then return true end
    if rule.Everyone then return true end

    local passport = getPassport(source)
    if not passport then return false end

    for _, group in ipairs(rule.Groups or {}) do
        if hasGroup(passport, group) then return true end
    end

    for _, permission in ipairs(rule.Permissions or {}) do
        if hasPermission(passport, permission) then return true end
    end

    return false
end

local function configuredModel(model)
    model = tonumber(model)
    if not model then return nil end
    return Config.Models and Config.Models[model] or nil
end

local function playerNearScreen(source, screen)
    if type(screen) ~= "table" then return false end
    local coords = screen.coords
    local model = tonumber(screen.model)
    local modelData = configuredModel(model)
    if not coords or not modelData then return false end

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end

    local playerCoords = GetEntityCoords(ped)
    local tvCoords = MTelevisionVec3(coords)
    local maxDistance = (tonumber(modelData.Range) or 20.0) + ((Config.Security and Config.Security.InteractionDistanceBuffer) or 3.0)
    return #(playerCoords - tvCoords) <= maxDistance
end

local function normalizeUrl(url)
    url = MTelevisionTrim(url)
    if url == "" then return nil, "Informe uma URL válida." end

    local maxLength = (Config.Security and Config.Security.MaxUrlLength) or 700
    if #url > maxLength then
        return nil, "A URL informada é muito longa."
    end

    if not url:match("^https?://") then
        url = "https://" .. url
    end

    local lower = url:lower()
    local allowed = false
    for _, protocol in ipairs((Config.Security and Config.Security.AllowedProtocols) or { "http://", "https://" }) do
        if lower:sub(1, #protocol) == protocol:lower() then
            allowed = true
            break
        end
    end

    if not allowed then
        return nil, "Somente URLs HTTP/HTTPS são permitidas."
    end

    for _, word in ipairs(Config.BannedWords or {}) do
        local banned = normalize(word)
        if banned ~= "" and lower:find(banned, 1, true) then
            return nil, "Esta URL não é permitida."
        end
    end

    return url
end

local function sanitizeChannelName(name)
    name = MTelevisionTrim(name)
    name = name:gsub("[%c]", "")
    if #name > 40 then name = name:sub(1, 40) end
    return name
end

local function buildScreenKey(screen)
    if type(screen) ~= "table" then return nil end
    if not screen.coords or not configuredModel(screen.model) then return nil end
    return MTelevisionScreenKey(screen.coords, screen.model)
end

local function sendTelevisionState(key)
    local state = televisions[key]
    TriggerClientEvent("m_television:state", -1, key, state)
end

local function setTelevisionState(screen, status)
    local key = buildScreenKey(screen)
    if not key then return false end

    televisions[key] = {
        coords = {
            x = screen.coords.x + 0.0,
            y = screen.coords.y + 0.0,
            z = screen.coords.z + 0.0
        },
        model = tonumber(screen.model),
        ptv_status = status,
        update_time = os.time()
    }

    sendTelevisionState(key)
    return true
end

local function runApproval(callback, source, payload, onApproved)
    if type(callback) ~= "function" then
        onApproved()
        return
    end

    local completed = false
    local function done(approved)
        if completed then return end
        completed = true
        if approved ~= false then onApproved() end
    end

    local ok, err = pcall(callback, source, payload, done)
    if not ok then
        print(("[m_television] Erro em hook de aprovação: %s"):format(tostring(err)))
        return
    end
end

local function initializeChannels()
    channels = {}
    defaultChannelCount = 0

    for index, entry in ipairs(Config.Channels or {}) do
        local url = normalizeUrl(entry.url)
        if url then
            channels[index] = {
                name = sanitizeChannelName(entry.name or ("Canal " .. index)),
                url = url,
                source = nil,
                default = true
            }
            defaultChannelCount = index
        end
    end
end

local function findPlayerChannel(source)
    for index, channel in pairs(channels) do
        if channel.source == source and not channel.default then
            return index, channel
        end
    end
end

local function nextDynamicChannelIndex()
    local index = math.max(defaultChannelCount + 1, 1)
    while channels[index] do index = index + 1 end
    return index
end

local function syncChannels(changedIndex)
    TriggerClientEvent("m_television:channels", -1, channels, changedIndex)
end

local function clearChannelFromTelevisions(channelIndex)
    for key, state in pairs(televisions) do
        local status = state and state.ptv_status
        if status and tonumber(status.channel) == tonumber(channelIndex) then
            state.ptv_status = { type = "off" }
            state.update_time = os.time()
            TriggerClientEvent("m_television:state", -1, key, state)
        end
    end
end

local function removeDynamicChannel(index)
    if not index or not channels[index] or channels[index].default then return false end
    channels[index] = nil
    clearChannelFromTelevisions(index)
    syncChannels(index)
    return true
end

initializeChannels()

RegisterNetEvent("m_television:requestUpdate", function()
    TriggerClientEvent("m_television:update", source, {
        televisions = televisions,
        channels = channels,
        serverTime = os.time()
    })
end)

RegisterNetEvent("m_television:requestSync", function(screen)
    local key = buildScreenKey(screen)
    TriggerClientEvent("m_television:sync", source, key, key and televisions[key] or nil, os.time())
end)

RegisterNetEvent("m_television:requestMenu", function(screen)
    local source = source
    if not checkAccess(source, "Use") then
        notify(source, "Você não tem permissão para usar a televisão.", "error")
        TriggerClientEvent("m_television:menuPermission", source, false)
        return
    end

    if not playerNearScreen(source, screen) then
        notify(source, "Você precisa estar próximo da televisão.", "error")
        TriggerClientEvent("m_television:menuPermission", source, false)
        return
    end

    TriggerClientEvent("m_television:menuPermission", source, true, channels)
end)

RegisterNetEvent("m_television:setState", function(screen, status)
    local source = source
    if not checkAccess(source, "Use") then
        notify(source, "Você não tem permissão para controlar esta televisão.", "error")
        return
    end

    if not playerNearScreen(source, screen) then
        notify(source, "Você está longe demais desta televisão.", "error")
        return
    end

    if type(status) ~= "table" then return end
    local statusType = tostring(status.type or "")
    local payload = { screen = screen, status = MTelevisionCopy(status) }

    if statusType == "play" then
        if status.channel then
            local channelIndex = tonumber(status.channel)
            if not channelIndex or not channels[channelIndex] then
                notify(source, "Este canal não está disponível.", "error")
                return
            end
            status = { type = "play", channel = channelIndex }
            payload.status = status
        elseif status.url then
            local url, reason = normalizeUrl(status.url)
            if not url then
                notify(source, reason or "URL inválida.", "error")
                return
            end
            status = { type = "play", url = url }
            payload.status = status
        else
            return
        end
    elseif statusType == "browser" then
        local url, reason = normalizeUrl(status.url)
        if not url then
            notify(source, reason or "URL inválida.", "error")
            return
        end
        status = { type = "browser", url = url }
        payload.status = status
    elseif statusType == "off" then
        status = { type = "off" }
        payload.status = status
    else
        return
    end

    runApproval(Config.Events and Config.Events.ScreenInteract, source, payload, function()
        setTelevisionState(screen, status)
    end)
end)

RegisterNetEvent("m_television:requestBroadcastMenu", function()
    local source = source
    if not checkAccess(source, "Broadcast") then
        notify(source, "Você não tem permissão para transmitir um canal.", "error")
        TriggerClientEvent("m_television:broadcastMenu", source, false)
        return
    end

    local index, channel = findPlayerChannel(source)
    TriggerClientEvent("m_television:broadcastMenu", source, true, index, channel)
end)

RegisterNetEvent("m_television:startBroadcast", function(name, rawUrl)
    local source = source
    if not checkAccess(source, "Broadcast") then
        notify(source, "Você não tem permissão para transmitir um canal.", "error")
        return
    end

    if findPlayerChannel(source) then
        notify(source, "Você já possui uma transmissão ativa.", "error")
        return
    end

    name = sanitizeChannelName(name)
    if name == "" then
        notify(source, "Informe um nome para o canal.", "error")
        return
    end

    local url, reason = normalizeUrl(rawUrl)
    if not url then
        notify(source, reason or "URL inválida.", "error")
        return
    end

    local payload = { name = name, url = url }
    runApproval(Config.Events and Config.Events.Broadcast, source, payload, function()
        local index = nextDynamicChannelIndex()
        channels[index] = {
            name = name,
            url = url,
            source = source,
            default = false
        }
        syncChannels(index)
        notify(source, ("Transmissão iniciada no canal #%s."):format(index), "success")
    end)
end)

RegisterNetEvent("m_television:stopBroadcast", function()
    local source = source
    local index = findPlayerChannel(source)
    if not index then
        notify(source, "Você não possui uma transmissão ativa.", "error")
        return
    end

    removeDynamicChannel(index)
    notify(source, "Transmissão encerrada.", "success")
end)

RegisterNetEvent("m_television:requestAddTelevision", function()
    local source = source
    if not checkAccess(source, "AddTelevision") then
        notify(source, "Você não tem permissão para adicionar televisões.", "error")
        TriggerClientEvent("m_television:addTelevisionPermission", source, false)
        return
    end

    TriggerClientEvent("m_television:addTelevisionPermission", source, true)
end)

AddEventHandler("playerDropped", function()
    local source = source
    local index = findPlayerChannel(source)
    if index then
        removeDynamicChannel(index)
    end
end)

