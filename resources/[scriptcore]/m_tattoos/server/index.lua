-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
cRP = {}
Tunnel.bindInterface("vrp_tattos",cRP)
vCLIENT = Tunnel.getInterface("vrp_tattos")

-----------------------------------------------------------------------------------------------------------------------------------------
-- GETPLAYERS
-----------------------------------------------------------------------------------------------------------------------------------------
function cRP.updateTattoo(status)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		vRP.updateUserApparence(user_id, "tattos", status)
		vRP.execute("apparence/tattos",{ user_id = user_id, tattos = json.encode(status) })
		vCLIENT._setTattos(source, status)

        if vRP.getMoney(user_id) > 100 or vRP.getBankMoney(user_id) > 100 then 
            vRP.tryFullPayment(user_id,parseInt(100))
        end

        TriggerClientEvent("Notify",source,"sucesso","Você pagou R$ 100,00 Nas tatuagens.",5)

	end
end

function cRP.sgetCustomization()
	local source = source
	local user_id = vRP.getUserId(source)
    local old_custom = vRPclient.getCustomization(source)

	if user_id then
         idle_copy = vRP.save_idle_custom(source,old_custom)
	end
end

function cRP.setClothes(clothes)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
        vRP.removeCloak(source)
	end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- SETINSTANCE
-----------------------------------------------------------------------------------------------------------------------------------------
-- function cRP.setInstance(status)
--     local source = source 
--     local user_id = vRP.getUserId(source)
--     if user_id then 
-- 		if status then
-- 			SetPlayerRoutingBucket(source, user_id)
-- 		else
-- 			SetPlayerRoutingBucket(source, 0)
-- 		end
--     end
-- end

-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYERSPAWN
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("tattos:init", function(user_id)
	local source = vRP.getUserSource(user_id)
	if source and user_id then
		local data = vRP.getUserApparence(user_id)       
		vCLIENT._setTattos(source, data.tattos)
	end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
		for _, player in pairs(GetPlayers()) do
			local userId = vRP.getUserId(tonumber(player))
			if userId then
				TriggerEvent("tattos:init", userId)
			end
		end
    end
end)


local TATTOO_CONFIG_FILE = "shared/locations.json"

local function normalizeCoords(coords)
    if type(coords) ~= "table" then return nil end

    local x = tonumber(coords.x or coords[1])
    local y = tonumber(coords.y or coords[2])
    local z = tonumber(coords.z or coords[3])

    if not x or not y or not z then return nil end
    return { x = x, y = y, z = z }
end

local function loadTattooConfig()
    local raw = LoadResourceFile(GetCurrentResourceName(), TATTOO_CONFIG_FILE)
    local ok, data = pcall(json.decode, raw or "{}")

    if not ok or type(data) ~= "table" then
        data = {}
    end

    locateTattoos = {}

    for _, shop in ipairs(type(data.locations) == "table" and data.locations or {}) do
        local id = tonumber(shop.id)
        local coords = normalizeCoords(shop)

        if id and coords then
            locateTattoos[tostring(id)] = {
                coords.x,
                coords.y,
                coords.z,
                shop.blip == true,
                shop.marker ~= false
            }
        end
    end
end

local function serializeTattooShops()
    local locations = {}

    for id, data in pairs(locateTattoos or {}) do
        if data[1] and data[2] and data[3] then
            locations[#locations + 1] = {
                id = tonumber(id),
                x = tonumber(data[1]),
                y = tonumber(data[2]),
                z = tonumber(data[3]),
                blip = data[4] == true,
                marker = data[5] ~= false
            }
        end
    end

    table.sort(locations, function(a,b)
        return a.id < b.id
    end)

    return { locations = locations }
end

local function syncTattooShops(target)
    TriggerClientEvent("m_tattoos:fullSync", target, serializeTattooShops().locations)
end

local function saveTattooConfig()
    local payload = serializeTattooShops()

    if not SaveResourceFile(
        GetCurrentResourceName(),
        TATTOO_CONFIG_FILE,
        json.encode(payload),
        -1
    ) then
        return false, "Não foi possível salvar shared/locations.json."
    end

    syncTattooShops(-1)
    return true
end

local function nextTattooId()
    local highest = 0

    for id in pairs(locateTattoos or {}) do
        highest = math.max(highest, tonumber(id) or 0)
    end

    return highest + 1
end

loadTattooConfig()

RegisterNetEvent("m_tattoos:requestSync", function()
    syncTattooShops(source)
end)

AddEventHandler("vRP:playerSpawn", function(userId, source)
    syncTattooShops(source)
end)

exports("getTattooShops", function()
    local out = {}

    for _, shop in ipairs(serializeTattooShops().locations) do
        out[#out + 1] = {
            id = shop.id,
            coords = {
                x = shop.x,
                y = shop.y,
                z = shop.z
            }
        }
    end

    return out
end)

exports("addTattooShop", function(coords)
    coords = normalizeCoords(coords)

    if not coords then
        return false, "Coordenadas inválidas."
    end

    local id = nextTattooId()

    -- Novo local: sem blip por padrão, marker ativo.
    locateTattoos[tostring(id)] = {
        coords.x,
        coords.y,
        coords.z,
        false,
        true
    }

    local ok, msg = saveTattooConfig()

    if not ok then
        locateTattoos[tostring(id)] = nil
        return false, msg
    end

    return true, "Estúdio Tattoo adicionado com sucesso.", id
end)

exports("updateTattooShop", function(id, coords)
    id = tonumber(id)
    coords = normalizeCoords(coords)

    if not id or not coords then
        return false, "Dados inválidos."
    end

    local key = tostring(id)
    local old = locateTattoos[key]

    if not old then
        return false, "Estúdio Tattoo não encontrado."
    end

    -- Preserva blip e marker existentes ao mover o ponto.
    locateTattoos[key] = {
        coords.x,
        coords.y,
        coords.z,
        old[4] == true,
        old[5] ~= false
    }

    local ok, msg = saveTattooConfig()

    if not ok then
        locateTattoos[key] = old
        return false, msg
    end

    return true, "Local do Estúdio Tattoo atualizado."
end)

exports("removeTattooShop", function(id)
    id = tonumber(id)
    local key = tostring(id or "")

    if not id or not locateTattoos[key] then
        return false, "Estúdio Tattoo não encontrado."
    end

    local old = locateTattoos[key]
    locateTattoos[key] = nil

    local ok, msg = saveTattooConfig()

    if not ok then
        locateTattoos[key] = old
        return false, msg
    end

    return true, "Estúdio Tattoo removido."
end)

exports("reloadTattooShops", function()
    loadTattooConfig()
    syncTattooShops(-1)
    return true
end)

exports("setTattos", function(nSource, data)
    vCLIENT._setTattos(nSource, data)
end)
