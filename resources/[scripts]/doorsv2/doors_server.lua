local resource = GetCurrentResourceName()
local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
local vRP = Proxy.getInterface("vRP")
local client = Tunnel.getInterface(resource)

local doors, byId, locks = {}, {}, {}
local syncRequests, lockRequests = {}, {}

local function notify(player, kind, message)
    TriggerClientEvent('Notify', player, kind, message, 5000)
end

local function modelHash(hash)
    hash = math.tointeger(tonumber(hash))
    return hash and (hash & 0xffffffff)
end

local function doorId(door)
    return ('%d:%.4f:%.4f:%.4f'):format(modelHash(door.hash), door.x, door.y, door.z)
end

local function setCatalog(catalog)
    local nextIndex, nextLocks = {}, {}
    for _, door in ipairs(catalog) do
        local id = doorId(door)
        nextIndex[id] = door
        local state = locks[id]
        if state == nil then state = door.lock ~= false end
        nextLocks[id] = state
    end
    doors, byId, locks = catalog, nextIndex, nextLocks
end

local function sendCatalog(player)
    local snapshot = {}
    for id, door in pairs(byId) do
        local data = {}
        for key, value in pairs(door) do data[key] = value end
        data.lock = locks[id]
        snapshot[id] = data
    end
    TriggerClientEvent('doorsv2:state', player, snapshot)
end

local function saveCatalog(catalog, forceLockedId)
    if not SaveResourceFile(resource, 'doors.json', json.encode(catalog, {indent = true}), -1) then
        return false, 'Não foi possível salvar doors.json.'
    end
    if forceLockedId then locks[forceLockedId] = true end
    setCatalog(catalog)
    sendCatalog(-1)
    return true
end

local function findDoor(hash, coords)
    if not hash or type(coords) ~= 'table' then return end
    local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
    if not x or not y or not z then return end
    local nearest, best = nil, 0.25 * 0.25
    for index, door in ipairs(doors) do
        if modelHash(door.hash) == modelHash(hash) then
            local dx, dy, dz = door.x - x, door.y - y, door.z - z
            local distance = dx*dx + dy*dy + dz*dz
            if distance < best then nearest, best = index, distance end
        end
    end
    return nearest
end

local function isAdmin(player)
    local userId = player ~= 0 and vRP.getUserId(player)
    return userId and vRP.hasPermission(userId, 'admin.permissao')
end

local function isOwner(userId)
    return userId and vRP.hasGroup(userId, 'dono')
end

local raw = LoadResourceFile(resource, 'doors.json')
local ok, decoded = pcall(json.decode, raw or '')
if ok and type(decoded) == 'table' then
    local ordered = {}
    for key, door in pairs(decoded) do
        local index = math.tointeger(tonumber(key))
        if index and type(door) == 'table' and modelHash(door.hash)
            and tonumber(door.x) and tonumber(door.y) and tonumber(door.z) then
            door.hash = tonumber(door.hash)
            door.x, door.y, door.z = tonumber(door.x), tonumber(door.y), tonumber(door.z)
            ordered[#ordered+1] = {index = index, door = door}
        end
    end
    table.sort(ordered, function(a,b) return a.index < b.index end)
    local catalog = {}
    for _, row in ipairs(ordered) do catalog[#catalog+1] = row.door end
    setCatalog(catalog)
else
    print('[doorsv2] Não foi possível carregar doors.json.')
end

RegisterNetEvent('doors:requestState', function()
    local player, now = source, GetGameTimer()
    if syncRequests[player] and now - syncRequests[player] < 1500 then return end
    syncRequests[player] = now
    sendCatalog(player)
end)

AddEventHandler('playerDropped', function()
    syncRequests[source], lockRequests[source] = nil, nil
end)

RegisterNetEvent('tryLockDoor', function(id, desired)
    local player = source
    if type(id) ~= 'string' or type(desired) ~= 'boolean' then return end
    local door = byId[id]
    if not door then return end
    local now = GetGameTimer()
    if lockRequests[player] and now - lockRequests[player] < 250 then return end
    lockRequests[player] = now

    local userId = vRP.getUserId(player)
    if not userId then return end
    local permission = type(door.perm) == 'string' and door.perm:match('^%s*(.-)%s*$') or ''
    local allowed
    if door.ownerOnly then
        allowed = isOwner(userId)
    else
        allowed = vRP.hasPermission(userId, 'admin.permissao')
            or (permission ~= '' and vRP.hasPermission(userId, permission))
    end
    if not allowed then
        notify(player, 'negado', 'Você não possui a chave desta porta.')
        return
    end
    if byId[id] ~= door then return end

    local ped = GetPlayerPed(player)
    if not ped or ped == 0 then return end
    local position = GetEntityCoords(ped)
    local dx, dy, dz = position.x-door.x, position.y-door.y, position.z-door.z
    local maxDistance = math.min(tonumber(door.dist) or 5.0, 10.0) + 0.75
    if dx*dx + dy*dy + dz*dz > maxDistance*maxDistance then return end

    if locks[id] == desired then
        TriggerClientEvent('doorsv2:lock', player, id, desired)
        return
    end
    locks[id] = desired
    TriggerClientEvent('doorsv2:lock', -1, id, desired)
end)

AddEventHandler('vRP:playerSpawn', function(_, player)
    sendCatalog(player)
end)

RegisterCommand('reloaddoors', function(player)
    if not isAdmin(player) then return end
    sendCatalog(-1)
    notify(player, 'sucesso', 'Estados das portas sincronizados.')
end, false)

RegisterCommand('debugport', function(player)
    if not isAdmin(player) then return end
    local data = client.rayCastDoor(player)
    local index = data and findDoor(data.hash, data.coords)
    if not index then return notify(player, 'negado', 'Nenhuma porta cadastrada encontrada.') end
    notify(player, 'sucesso', 'ID da porta: ' .. index)
end, false)

RegisterCommand('travarporta', function(player)
    local userId = player ~= 0 and vRP.getUserId(player)
    if not isOwner(userId) then return end

    notify(player, 'importante', 'Aponte para a porta e clique com o botão esquerdo. Botão direito cancela.')
    local data = client.rayCastDoor(player)
    if not data or vRP.getUserId(player) ~= userId or not isOwner(userId) then return end
    local hash, coords = modelHash(data.hash), data.coords
    local ped = GetPlayerPed(player)
    if not hash or type(coords) ~= 'table' or ped == 0 then return end
    local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
    if not x or not y or not z then return end
    local pos = GetEntityCoords(ped)
    local dx, dy, dz = pos.x - x, pos.y - y, pos.z - z
    if not (dx * dx + dy * dy + dz * dz <= 64) then
        return notify(player, 'negado', 'Aproxime-se da porta e tente novamente.')
    end

    local catalog = {table.unpack(doors)}
    local index = findDoor(hash, {x = x, y = y, z = z})
    local updated = {hash = hash, x = x, y = y, z = z, dist = 5.0, text = true, iconCoords = data.iconCoords}
    if index then
        for key, value in pairs(doors[index]) do updated[key] = value end
    end
    updated.ownerOnly, updated.lock = true, true
    catalog[index or (#catalog + 1)] = updated
    local saved, err = saveCatalog(catalog, doorId(updated))
    notify(player, saved and 'sucesso' or 'negado', err or 'Porta trancada. Somente donos podem abrir e fechar.')
end, false)

RegisterCommand('ajustarcadeado', function(player)
    if not isAdmin(player) then return end
    local data = client.rayCastDoor(player)
    local index = data and data.iconCoords and findDoor(data.hash, data.coords)
    if not index then return notify(player, 'negado', 'Esta porta não possui tranca cadastrada.') end

    local catalog = {table.unpack(doors)}
    local updated = {}
    for key, value in pairs(doors[index]) do updated[key] = value end
    updated.iconCoords = data.iconCoords
    catalog[index] = updated
    local saved, err = saveCatalog(catalog)
    notify(player, saved and 'sucesso' or 'negado', err or 'Cadeado posicionado no ponto selecionado.')
end, false)

RegisterCommand('delport', function(player)
    local userId = player ~= 0 and vRP.getUserId(player)
    if not isOwner(userId) and not isAdmin(player) then return end
    local data = client.rayCastDoor(player)
    local index = data and findDoor(data.hash, data.coords)
    if not index then return notify(player, 'negado', 'Nenhuma porta cadastrada encontrada.') end
    if doors[index].ownerOnly and not isOwner(userId) then
        return notify(player, 'negado', 'Somente donos podem remover esta tranca.')
    end
    if not doors[index].ownerOnly and not isAdmin(player) then return end

    local catalog = {table.unpack(doors)}
    table.remove(catalog, index)
    local saved, err = saveCatalog(catalog)
    notify(player, saved and 'sucesso' or 'negado', err or 'Porta removida com sucesso.')
end, false)

RegisterCommand('addport', function(player)
    if not isAdmin(player) then return end
    local data = client.rayCastDoor(player)
    if not data or not data.hash or not data.coords then
        return notify(player, 'negado', 'Nenhuma porta detectada no local.')
    end
    local permission = vRP.prompt(player, 'Digite a permissão para a porta:', '')
    if type(permission) ~= 'string' or not permission:find('%S') then return end
    if findDoor(data.hash, data.coords) then
        return notify(player, 'negado', 'Esta porta já possui uma tranca.')
    end
    local catalog = {table.unpack(doors)}
    catalog[#catalog+1] = {
        hash = data.hash, x = data.coords.x, y = data.coords.y, z = data.coords.z,
        perm = permission:match('^%s*(.-)%s*$'), lock = true, isGate = false, dist = 5.0, text = true,
    }
    local saved, err = saveCatalog(catalog)
    notify(player, saved and 'sucesso' or 'negado', err or 'Porta adicionada com sucesso.')
end, false)

exports('replaceMansionDoors', function(mansionId, permission, newDoors)
    mansionId, permission = tostring(mansionId or ''), tostring(permission or '')
    if mansionId == '' then return false, 'Identificador da mansão inválido.' end
    if permission == '' then return false, 'Permissão da mansão inválida.' end

    local catalog, ids = {}, {}
    local function append(door)
        local id = doorId(door)
        if ids[id] then return false end
        ids[id] = true
        catalog[#catalog+1] = door
        return true
    end
    for _, door in ipairs(doors) do
        if door.ownerOnly or tostring(door.mansionId or '') ~= mansionId then append(door) end
    end
    for _, data in ipairs(type(newDoors) == 'table' and newDoors or {}) do
        local hash = tonumber(data.hash)
        local x, y, z = tonumber(data.x), tonumber(data.y), tonumber(data.z)
        if modelHash(hash) and x and y and z then
            if not append({
                hash = hash, x = x, y = y, z = z, perm = permission, lock = true,
                isGate = data.isGate == true, dist = tonumber(data.dist) or 5.0,
                text = data.text ~= false, mansionId = mansionId,
            }) then
                return false, 'Uma das portas já possui uma tranca.'
            end
        end
    end
    return saveCatalog(catalog)
end)

exports('removeMansionDoors', function(mansionId)
    mansionId = tostring(mansionId or '')
    if mansionId == '' then return false, 'Identificador da mansão inválido.' end
    local catalog = {}
    for _, door in ipairs(doors) do
        if door.ownerOnly or tostring(door.mansionId or '') ~= mansionId then catalog[#catalog+1] = door end
    end
    local removed = #doors - #catalog
    local saved, err = saveCatalog(catalog)
    if not saved then return false, err end
    return true, ('%d tranca(s) da mansão removida(s).'):format(removed)
end)

exports('getMansionDoors', function(mansionId)
    mansionId = tostring(mansionId or '')
    if mansionId == '' then return {} end
    local result = {}
    for _, door in ipairs(doors) do
        if tostring(door.mansionId or '') == mansionId then
            result[#result+1] = {
                hash = door.hash, x = door.x, y = door.y, z = door.z,
                isGate = door.isGate == true, dist = tonumber(door.dist) or 5.0,
                text = door.text ~= false, lock = true,
            }
        end
    end
    return result
end)

