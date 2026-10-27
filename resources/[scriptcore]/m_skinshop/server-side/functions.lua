function serverFunctions.saveCloths(clothes)
    local source = source
    local user_id = vRP.getUserId(source)

    if user_id then
        vRP.execute("apparence/roupas",{ user_id = user_id, roupas = json.encode(clothes) })
		vRP.updateUserApparence(user_id, "clothes", clothes)
    end

    if vRP.getMoney(user_id) > 100 or vRP.getBankMoney(user_id) > 100 then 
        vRP.tryFullPayment(user_id,parseInt(100))
    end

end

function serverFunctions.checkPermission()
    local src = source
    local user_id = vRP.getUserId(src)

    return vRP.hasGroup(user_id,"developerrealidade") or vRP.hasGroup(user_id,"respilegalrealidade") 
    or vRP.hasGroup(user_id,"gestaorealidade") or vRP.hasGroup(user_id,"respeventosrealidade") or vRP.hasGroup(user_id,"supervisorrealidade")
end


local SKINSHOP_CONFIG_FILE = "shareds-side/localesSkinshop.json"

local function normalizeCoords(coords)
    if type(coords) ~= "table" then return nil end
    local x = tonumber(coords.x or coords[1])
    local y = tonumber(coords.y or coords[2])
    local z = tonumber(coords.z or coords[3])
    if not x or not y or not z then return nil end
    return { x = x, y = y, z = z }
end

local function loadSkinshopConfig()
    local raw = LoadResourceFile(GetCurrentResourceName(), SKINSHOP_CONFIG_FILE)
    local ok, data = pcall(json.decode, raw or "{}")
    if not ok or type(data) ~= "table" then data = {} end

    locateShops = {}
    local locations = type(data.locations) == "table" and data.locations or {}

    for _, shop in ipairs(locations) do
        local id = tonumber(shop.id)
        local coords = normalizeCoords(shop)
        if id and coords then
            locateShops[tostring(id)] = {
                coords.x, coords.y, coords.z,
                shop.blip == true
            }
        end
    end
end

local function serializeSkinshops()
    local locations = {}
    for id, data in pairs(locateShops or {}) do
        if data[1] and data[2] and data[3] then
            locations[#locations + 1] = {
                id = tonumber(id),
                x = tonumber(data[1]),
                y = tonumber(data[2]),
                z = tonumber(data[3]),
                blip = data[4] == true
            }
        end
    end
    table.sort(locations, function(a,b) return a.id < b.id end)
    return { locations = locations }
end

local function saveSkinshopConfig()
    local encoded = json.encode(serializeSkinshops())
    if not SaveResourceFile(GetCurrentResourceName(), SKINSHOP_CONFIG_FILE, encoded, -1) then
        return false, "Não foi possível salvar localesSkinshop.json."
    end
    TriggerClientEvent("m_skinshop:fullSync", -1, serializeSkinshops().locations)
    return true
end

local function nextSkinshopId()
    local highest = 0
    for id in pairs(locateShops or {}) do
        highest = math.max(highest, tonumber(id) or 0)
    end
    return highest + 1
end

loadSkinshopConfig()

RegisterNetEvent("m_skinshop:requestSync", function()
    TriggerClientEvent("m_skinshop:fullSync", source, serializeSkinshops().locations)
end)

AddEventHandler("vRP:playerSpawn", function(userId, source)
    TriggerClientEvent("m_skinshop:fullSync", source, serializeSkinshops().locations)
end)

exports("getSkinShops", function()
    local result = {}
    for _, shop in ipairs(serializeSkinshops().locations) do
        result[#result + 1] = {
            id = shop.id,
            coords = { x = shop.x, y = shop.y, z = shop.z }
        }
    end
    return result
end)

exports("addSkinshop", function(coords)
    coords = normalizeCoords(coords)
    if not coords then return false, "Coordenadas inválidas." end

    local id = nextSkinshopId()
    locateShops[tostring(id)] = { coords.x, coords.y, coords.z, false }

    local ok, msg = saveSkinshopConfig()
    if not ok then
        locateShops[tostring(id)] = nil
        return false, msg
    end

    return true, "Loja de roupa adicionada com sucesso.", id
end)

exports("updateSkinshop", function(id, coords)
    id = tonumber(id)
    coords = normalizeCoords(coords)
    if not id or not coords then return false, "Dados inválidos." end

    local old = locateShops[tostring(id)]
    if not old then return false, "Loja de roupa não encontrada." end

    local blip = old[4] == true
    locateShops[tostring(id)] = { coords.x, coords.y, coords.z, blip }

    local ok, msg = saveSkinshopConfig()
    if not ok then
        locateShops[tostring(id)] = old
        return false, msg
    end

    return true, "Local da loja de roupa atualizado."
end)

exports("removeSkinshop", function(id)
    id = tonumber(id)
    if not id or not locateShops[tostring(id)] then
        return false, "Loja de roupa não encontrada."
    end

    local old = locateShops[tostring(id)]
    locateShops[tostring(id)] = nil

    local ok, msg = saveSkinshopConfig()
    if not ok then
        locateShops[tostring(id)] = old
        return false, msg
    end

    return true, "Loja de roupa removida."
end)

exports("reloadSkinshops", function()
    loadSkinshopConfig()
    TriggerClientEvent("m_skinshop:fullSync", -1, serializeSkinshops().locations)
    return true
end)
