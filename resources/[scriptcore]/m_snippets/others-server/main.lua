local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

src = {}
Tunnel.bindInterface("m_snippets",src)
Proxy.addInterface("m_snippets",src)

vCLIENT = Tunnel.getInterface("m_snippets")
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
