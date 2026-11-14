local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

src = {}
Tunnel.bindInterface("m_snippets",src)
Proxy.addInterface("m_snippets",src)

vCLIENT = Tunnel.getInterface("m_snippets")

-----------------------------------------------------------------------------------------------------------------------------------------
-- ELEVADORES DINÂMICOS
-----------------------------------------------------------------------------------------------------------------------------------------
local ELEVATORS_FILE = "config/elevators.json"
local ElevatorConfig = { elevators = {} }

local function elevTrim(value)
    return tostring(value or ""):gsub("^%s+",""):gsub("%s+$","")
end

local function elevClone(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k,v in pairs(value) do out[k] = elevClone(v) end
    return out
end

local function elevCoords(value)
    if type(value) ~= "table" then return nil end
    local x = tonumber(value.x or value[1])
    local y = tonumber(value.y or value[2])
    local z = tonumber(value.z or value[3])
    local w = tonumber(value.w or value[4]) or 0.0
    if not x or not y or not z then return nil end
    return { x = x, y = y, z = z, w = w }
end

local function normalizeElevator(data, keepId)
    if type(data) ~= "table" then
        return nil, "Dados do elevador inválidos."
    end

    local id = elevTrim(keepId or data.id)
    local name = elevTrim(data.name)
    local permission = elevTrim(data.permission)
    local drawDistance = tonumber(data.drawDistance) or 12.0
    local interactionDistance = tonumber(data.interactionDistance) or 2.0

    if id == "" then
        return nil, "Informe o identificador do elevador."
    end
    if name == "" then
        return nil, "Informe o nome do elevador."
    end
    if drawDistance < 2.0 then drawDistance = 2.0 end
    if drawDistance > 50.0 then drawDistance = 50.0 end
    if interactionDistance < 0.5 then interactionDistance = 0.5 end
    if interactionDistance > 5.0 then interactionDistance = 5.0 end

    local floors = {}
    local names = {}

    for _,floor in ipairs(type(data.floors) == "table" and data.floors or {}) do
        local floorName = elevTrim(floor.name)
        local coords = elevCoords(floor.coords)

        if floorName == "" then
            return nil, "Todos os andares precisam de um nome."
        end
        if names[floorName:lower()] then
            return nil, "Existem andares com o mesmo nome."
        end
        if not coords then
            return nil, ("Coordenadas inválidas no andar %s."):format(floorName)
        end

        names[floorName:lower()] = true
        floors[#floors + 1] = { name = floorName, coords = coords }
    end

    if #floors < 2 then
        return nil, "Cadastre pelo menos dois andares."
    end

    return {
        id = id,
        name = name,
        permission = permission,
        drawDistance = drawDistance,
        interactionDistance = interactionDistance,
        floors = floors
    }
end

local function loadElevators()
    local raw = LoadResourceFile(GetCurrentResourceName(), ELEVATORS_FILE)
    local ok, data = pcall(json.decode, raw or "{}")

    ElevatorConfig = ok and type(data) == "table" and data or { elevators = {} }
    if type(ElevatorConfig.elevators) ~= "table" then ElevatorConfig.elevators = {} end

    local clean = {}
    for _,entry in ipairs(ElevatorConfig.elevators) do
        local item = normalizeElevator(entry, entry.id)
        if item then clean[#clean + 1] = item end
    end
    ElevatorConfig.elevators = clean
end

local function findElevator(id)
    id = tostring(id or "")
    for index,item in ipairs(ElevatorConfig.elevators) do
        if tostring(item.id) == id then return index,item end
    end
end

local function syncElevators(target)
    TriggerClientEvent("m_snippets:syncElevators", target, ElevatorConfig.elevators)
end

local function saveElevators()
    local encoded = json.encode(ElevatorConfig)
    SaveResourceFile(GetCurrentResourceName(), ELEVATORS_FILE, encoded, -1)

    local verifyRaw = LoadResourceFile(GetCurrentResourceName(), ELEVATORS_FILE)
    local ok, verify = pcall(json.decode, verifyRaw or "")

    if not ok or type(verify) ~= "table" or type(verify.elevators) ~= "table" then
        return false, "Não foi possível salvar config/elevators.json."
    end

    syncElevators(-1)
    return true
end

loadElevators()

RegisterNetEvent("m_snippets:requestElevators", function()
    syncElevators(source)
end)

AddEventHandler("vRP:playerSpawn", function(userId, playerSource)
    if playerSource then syncElevators(playerSource) end
end)

function src.checkPermission(permission)
    permission = elevTrim(permission)
    if permission == "" then return true end

    local playerSource = source
    local userId = vRP.getUserId and vRP.getUserId(playerSource) or (vRP.Passport and vRP.Passport(playerSource))
    if not userId then return false end

    if vRP.hasPermission and vRP.hasPermission(userId, permission) then return true end
    if vRP.HasPermission and vRP.HasPermission(userId, permission) then return true end
    if vRP.hasGroup and vRP.hasGroup(userId, permission) then return true end
    if vRP.HasGroup and vRP.HasGroup(userId, permission) then return true end

    return false
end

exports("getElevators", function()
    return elevClone(ElevatorConfig.elevators)
end)

exports("upsertElevator", function(originalId, data)
    originalId = elevTrim(originalId)
    data = type(data) == "table" and data or {}

    local desiredId = elevTrim(data.id)
    if desiredId == "" then desiredId = originalId end

    local item, err = normalizeElevator(data, desiredId)
    if not item then return false, err end

    local existingIndex = originalId ~= "" and findElevator(originalId) or nil
    local collisionIndex = findElevator(item.id)

    if collisionIndex and collisionIndex ~= existingIndex then
        return false, "Já existe um elevador com este identificador."
    end

    local old
    if existingIndex then
        old = ElevatorConfig.elevators[existingIndex]
        ElevatorConfig.elevators[existingIndex] = item
    else
        ElevatorConfig.elevators[#ElevatorConfig.elevators + 1] = item
    end

    local ok, msg = saveElevators()
    if not ok then
        if existingIndex then
            ElevatorConfig.elevators[existingIndex] = old
        else
            table.remove(ElevatorConfig.elevators, #ElevatorConfig.elevators)
        end
        return false, msg
    end

    return true, existingIndex and "Elevador atualizado com sucesso." or "Elevador criado com sucesso."
end)

exports("removeElevator", function(id)
    local index = findElevator(id)
    if not index then return false, "Elevador não encontrado." end

    local old = table.remove(ElevatorConfig.elevators, index)
    local ok, msg = saveElevators()

    if not ok then
        table.insert(ElevatorConfig.elevators, index, old)
        return false, msg
    end

    return true, "Elevador removido."
end)

exports("reloadElevators", function()
    loadElevators()
    syncElevators(-1)
    return true
end)


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local trancas = {}

function src.syncLock(area, status, permissao)
    if type(area) ~= 'number' or type(status) ~= 'boolean' then
		return
	end

	area = tostring(area)
	if area:len() > 5 then
		return
	end
	area = tonumber(area)
    
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        if vRP.hasPermission(user_id, permissao) or vRP.hasPermission(user_id, "developer.permissao") or vRP.hasPermission(user_id, "perm.respilegal") then
            vCLIENT._setLock(-1, area, status)
            trancas[area] = status
            return true
        else
            TriggerClientEvent("Notify",source,"negado","Você não possui a chave dessa fechadura", 5)
        end
    end
end

AddEventHandler("vRP:playerSpawn",function(user_id,source,first_spawn)
	if first_spawn then
        if user_id then
            vCLIENT._syncAllLock(source, trancas)
        end
	end
end)

function src.allowHouse(area, status, permissao)
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        if vRP.hasPermission(user_id, "perm.aurorahouse") or vRP.hasPermission(user_id, "developer.permissao") then
            return true
        end
    end
    return false 
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- MARCAÇÕES DO MAPA - CONFIG JSON
-----------------------------------------------------------------------------------------------------------------------------------------
local MAP_BLIPS_FILE = "config/blips.json"
local MapBlips = { blips = {} }

local function mapTrim(value)
    return tostring(value or ""):gsub("^%s+",""):gsub("%s+$","")
end

local function mapClone(value)
    if type(value) ~= "table" then
        return value
    end

    local out = {}

    for k,v in pairs(value) do
        out[k] = mapClone(v)
    end

    return out
end

local function mapCoords(c)
    if type(c) ~= "table" then
        return nil
    end

    local x = tonumber(c.x or c[1])
    local y = tonumber(c.y or c[2])
    local z = tonumber(c.z or c[3])

    if not x or not y or not z then
        return nil
    end

    return {
        x = x,
        y = y,
        z = z
    }
end

local function normalizeMapBlip(data, keepId)
    if type(data) ~= "table" then
        return nil, "Dados da marcação inválidos."
    end

    local id = keepId or mapTrim(data.id)
    local name = mapTrim(data.name)
    local coords = mapCoords(data.coords)
    local sprite = tonumber(data.sprite)
    local color = tonumber(data.color)
    local scale = tonumber(data.scale)

    if id == "" then
        return nil, "Identificador inválido."
    end

    if name == "" then
        return nil, "Informe o nome da marcação."
    end

    if not coords then
        return nil, "Coordenadas inválidas."
    end

    if not sprite or sprite < 0 then
        return nil, "Sprite inválido."
    end

    if not color or color < 0 then
        return nil, "Cor inválida."
    end

    if not scale or scale <= 0 then
        return nil, "Escala inválida."
    end

    return {
        id = id,
        name = name,
        coords = coords,
        sprite = math.floor(sprite),
        color = math.floor(color),
        scale = scale,
        shortRange = data.shortRange ~= false
    }
end

local function loadMapBlips()
    local raw = LoadResourceFile(GetCurrentResourceName(), MAP_BLIPS_FILE)
    local ok, data = pcall(json.decode, raw or "{}")

    MapBlips = ok and type(data) == "table" and data or {
        blips = {}
    }

    if type(MapBlips.blips) ~= "table" then
        MapBlips.blips = {}
    end
end

local function findMapBlip(id)
    id = tostring(id or "")

    for i,b in ipairs(MapBlips.blips) do
        if tostring(b.id or "") == id then
            return i,b
        end
    end
end

local function nextMapBlipId()
    local highest = 0

    for _,b in ipairs(MapBlips.blips) do
        local number = tonumber(
            tostring(b.id or ""):match("^blip_(%d+)$")
        )

        if number and number > highest then
            highest = number
        end
    end

    return ("blip_%03d"):format(highest + 1)
end

local function syncMapBlips(target)
    TriggerClientEvent(
        "m_snippets:syncMapBlips",
        target,
        MapBlips.blips
    )
end

local function saveMapBlips()
    if not SaveResourceFile(
        GetCurrentResourceName(),
        MAP_BLIPS_FILE,
        json.encode(MapBlips),
        -1
    ) then
        return false, "Não foi possível salvar config/blips.json."
    end

    syncMapBlips(-1)
    return true
end

loadMapBlips()

RegisterNetEvent("m_snippets:requestMapBlips", function()
    syncMapBlips(source)
end)

AddEventHandler("vRP:playerSpawn", function(userId, nSource)
    syncMapBlips(nSource)
end)

exports("getMapBlips", function()
    return mapClone(MapBlips.blips)
end)

exports("addMapBlip", function(data)
    data = type(data) == "table" and data or {}
    data.id = nextMapBlipId()

    local item, err = normalizeMapBlip(data)

    if not item then
        return false, err
    end

    MapBlips.blips[#MapBlips.blips + 1] = item

    local ok, msg = saveMapBlips()

    if not ok then
        table.remove(MapBlips.blips, #MapBlips.blips)
        return false, msg
    end

    return true, "Marcação criada com sucesso."
end)

exports("updateMapBlip", function(id, data)
    local index = findMapBlip(id)

    if not index then
        return false, "Marcação não encontrada."
    end

    local item, err = normalizeMapBlip(
        data,
        tostring(id)
    )

    if not item then
        return false, err
    end

    local old = MapBlips.blips[index]
    MapBlips.blips[index] = item

    local ok, msg = saveMapBlips()

    if not ok then
        MapBlips.blips[index] = old
        return false, msg
    end

    return true, "Marcação atualizada com sucesso."
end)

exports("removeMapBlip", function(id)
    local index = findMapBlip(id)

    if not index then
        return false, "Marcação não encontrada."
    end

    local old = table.remove(
        MapBlips.blips,
        index
    )

    local ok, msg = saveMapBlips()

    if not ok then
        table.insert(MapBlips.blips, index, old)
        return false, msg
    end

    return true, "Marcação removida."
end)

exports("reloadMapBlips", function()
    loadMapBlips()
    syncMapBlips(-1)
    return true
end)
