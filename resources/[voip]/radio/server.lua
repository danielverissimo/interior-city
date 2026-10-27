local Tunnel = module('vrp', 'lib/Tunnel')
local Proxy = module('vrp', 'lib/Proxy')

local vRP = Proxy.getInterface('vRP')
local src = {}
Tunnel.bindInterface('radio', src)

local CONFIG_FILE = 'private_radios.json'
local radioStore = { nextId = 1, radios = {} }
local installedChecks = {}

local function trim(value)
    return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function int(value)
    local number = tonumber(value)
    if not number then return nil end
    number = math.floor(number)
    if number < 1 or number > 9999 then return nil end
    return number
end

local function sanitizePermissions(value)
    local output, seen = {}, {}
    if type(value) == 'string' then
        local list = {}
        for part in value:gmatch('[^,;\n]+') do list[#list + 1] = part end
        value = list
    end
    if type(value) ~= 'table' then return output end

    for _, permission in ipairs(value) do
        permission = trim(permission)
        if permission ~= '' then
            if #permission > 80 then permission = permission:sub(1, 80) end
            local key = permission:lower()
            if not seen[key] then
                seen[key] = true
                output[#output + 1] = permission
                if #output >= 16 then break end
            end
        end
    end
    return output
end

local function normalizeRadio(entry)
    if type(entry) ~= 'table' then return nil end
    local id = int(entry.id)
    local name = trim(entry.name or entry.nome)
    local channel = int(entry.channel or entry.frequency or entry.frequencia)
    local permissions = sanitizePermissions(entry.permissions or entry.permissoes or entry.permission or entry.perm)
    if name == '' or not channel or #permissions == 0 then return nil end
    if #name > 60 then name = name:sub(1, 60) end
    return {
        id = id,
        name = name,
        channel = channel,
        permissions = permissions,
        enabled = entry.enabled ~= false
    }
end

local function publicRadios()
    local list = {}
    for _, entry in ipairs(radioStore.radios) do
        list[#list + 1] = {
            id = entry.id,
            name = entry.name,
            channel = entry.channel,
            permissions = entry.permissions,
            enabled = entry.enabled ~= false
        }
    end
    table.sort(list, function(a, b)
        if a.channel == b.channel then return a.name:lower() < b.name:lower() end
        return a.channel < b.channel
    end)
    return list
end

local function saveRadios()
    local encoded = json.encode({ nextId = radioStore.nextId, radios = radioStore.radios })
    SaveResourceFile(GetCurrentResourceName(), CONFIG_FILE, encoded, -1)
end

local function loadRadios()
    local raw = LoadResourceFile(GetCurrentResourceName(), CONFIG_FILE)
    if not raw or raw == '' then
        saveRadios()
        return
    end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then
        print(('^1[%s] %s inválido. Mantendo configuração em memória.^7'):format(GetCurrentResourceName(), CONFIG_FILE))
        return
    end

    local sourceList = type(decoded.radios) == 'table' and decoded.radios or decoded
    local nextId = tonumber(decoded.nextId) or 1
    local normalized, usedIds, usedChannels = {}, {}, {}
    for _, entry in ipairs(sourceList) do
        local item = normalizeRadio(entry)
        if item and not usedChannels[item.channel] then
            if not item.id or usedIds[item.id] then
                while usedIds[nextId] do nextId = nextId + 1 end
                item.id = nextId
                nextId = nextId + 1
            end
            usedIds[item.id] = true
            usedChannels[item.channel] = true
            if item.id >= nextId then nextId = item.id + 1 end
            normalized[#normalized + 1] = item
        end
    end
    radioStore = { nextId = math.max(1, math.floor(nextId)), radios = normalized }
    saveRadios()
end

local function findById(id)
    id = int(id)
    if not id then return nil, nil end
    for index, entry in ipairs(radioStore.radios) do
        if entry.id == id then return entry, index end
    end
    return nil, nil
end

local function findByChannel(channel)
    channel = int(channel)
    if not channel then return nil end
    for _, entry in ipairs(radioStore.radios) do
        if entry.channel == channel and entry.enabled ~= false then return entry end
    end
    return nil
end

local function userHasAnyPermission(userId, permissions)
    if not userId then return false end
    for _, permission in ipairs(permissions or {}) do
        if vRP.hasPermission(userId, permission) then return true end
    end
    return false
end

local function canPlayerJoinPrivateChannel(playerSource, channel)
    local entry = findByChannel(channel)
    if not entry then return true end -- canais não cadastrados continuam públicos
    local userId = vRP.getUserId(tonumber(playerSource))
    return userHasAnyPermission(userId, entry.permissions)
end

local function disconnectFromChannel(channel, message)
    channel = int(channel)
    if not channel then return end
    if GetResourceState('pma-voice') ~= 'started' then return end
    for _, player in ipairs(GetPlayers()) do
        local playerSource = tonumber(player)
        local state = Player(playerSource).state
        if tonumber(state.radioChannel or 0) == channel then
            pcall(function() exports['pma-voice']:setPlayerRadio(playerSource, 0) end)
            TriggerClientEvent('radio:accessRevoked', playerSource, message or 'Esta frequência privada foi alterada. Você foi desconectado do rádio.')
        end
    end
end

local function enforcePrivateChannels()
    if GetResourceState('pma-voice') ~= 'started' then return end
    for _, player in ipairs(GetPlayers()) do
        local playerSource = tonumber(player)
        local channel = tonumber(Player(playerSource).state.radioChannel or 0)
        if channel and channel > 0 and findByChannel(channel) and not canPlayerJoinPrivateChannel(playerSource, channel) then
            pcall(function() exports['pma-voice']:setPlayerRadio(playerSource, 0) end)
            TriggerClientEvent('radio:accessRevoked', playerSource, 'Sua permissão para esta frequência privada foi removida.')
        end
    end
end

local function syncVoiceChecks()
    if GetResourceState('pma-voice') ~= 'started' then return false end

    for channel in pairs(installedChecks) do
        pcall(function() exports['pma-voice']:removeChannelCheck(channel) end)
    end
    installedChecks = {}

    for _, entry in ipairs(radioStore.radios) do
        if entry.enabled ~= false then
            local channel = entry.channel
            local ok = pcall(function()
                exports['pma-voice']:addChannelCheck(channel, function(playerSource)
                    return canPlayerJoinPrivateChannel(playerSource, channel)
                end)
            end)
            if ok then installedChecks[channel] = true end
        end
    end

    enforcePrivateChannels()
    return true
end

local function broadcastRadios()
    local list = publicRadios()
    TriggerClientEvent('radio:privateChannelsUpdated', -1, list)
    TriggerEvent('radio:privateChannelsUpdatedServer', list)
end

local function commitConfiguration(oldChannelToDisconnect)
    saveRadios()
    syncVoiceChecks()
    if oldChannelToDisconnect then
        disconnectFromChannel(oldChannelToDisconnect)
    end
    enforcePrivateChannels()
    broadcastRadios()
end

-- Tunnel usado pelo rádio do jogador ------------------------------------------------
function src.hasPermission(value)
    local userId = vRP.getUserId(source)
    return userId and vRP.hasPermission(userId, tostring(value or '')) or false
end

function src.hasRadio()
    local userId = vRP.getUserId(source)
    if not userId then return false end
    return (tonumber(vRP.getInventoryItemAmount(userId, 'radio')) or 0) >= 1
end

function src.canJoinChannel(channel)
    return canPlayerJoinPrivateChannel(source, channel)
end

function src.getPrivateChannels()
    return publicRadios()
end

-- API server-side para o Painel ADM ------------------------------------------------
exports('getPrivateRadios', function()
    return publicRadios()
end)

exports('upsertPrivateRadio', function(data)
    data = type(data) == 'table' and data or {}
    local name = trim(data.name)
    local channel = int(data.channel)
    local permissions = sanitizePermissions(data.permissions)
    local enabled = data.enabled ~= false
    local id = int(data.id)

    if name == '' then return { ok = false, message = 'Informe o nome da rádio.' } end
    if #name > 60 then name = name:sub(1, 60) end
    if not channel then return { ok = false, message = 'A frequência deve ser um número inteiro entre 1 e 9999.' } end
    if #permissions == 0 then return { ok = false, message = 'Informe ao menos uma permissão.' } end

    for _, entry in ipairs(radioStore.radios) do
        if entry.channel == channel and entry.id ~= id then
            return { ok = false, message = ('A frequência %d já pertence à rádio %s.'):format(channel, entry.name) }
        end
    end

    local oldChannel = nil
    local entry = id and findById(id) or nil
    if entry then
        oldChannel = entry.channel ~= channel and entry.channel or nil
        entry.name = name
        entry.channel = channel
        entry.permissions = permissions
        entry.enabled = enabled
    else
        id = radioStore.nextId
        radioStore.nextId = id + 1
        radioStore.radios[#radioStore.radios + 1] = {
            id = id, name = name, channel = channel, permissions = permissions, enabled = enabled
        }
    end

    commitConfiguration(oldChannel)
    return { ok = true, message = entry and 'Rádio privada atualizada em tempo real.' or 'Rádio privada criada em tempo real.', radios = publicRadios(), id = id }
end)

exports('deletePrivateRadio', function(id)
    local entry, index = findById(id)
    if not entry then return { ok = false, message = 'Rádio privada não encontrada.' } end
    local oldChannel = entry.channel
    table.remove(radioStore.radios, index)
    commitConfiguration(oldChannel)
    return { ok = true, message = 'Rádio privada removida. A frequência deixou de ser restrita.', radios = publicRadios() }
end)

exports('reloadPrivateRadios', function()
    loadRadios()
    syncVoiceChecks()
    broadcastRadios()
    return publicRadios()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        loadRadios()
        CreateThread(function()
            Wait(1000)
            syncVoiceChecks()
            broadcastRadios()
        end)
    elseif resource == 'pma-voice' then
        CreateThread(function()
            Wait(1000)
            syncVoiceChecks()
        end)
    end
end)

-- Em caso de hot reload onde o handler acima já ocorreu antes deste arquivo terminar.
CreateThread(function()
    Wait(0)
    if #radioStore.radios == 0 then loadRadios() end
    Wait(1000)
    syncVoiceChecks()
end)
