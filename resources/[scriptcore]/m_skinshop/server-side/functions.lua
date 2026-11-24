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

local function canOpenRemoteShop(user_id)
    return vRP.hasGroup(user_id,"developerrealidade") or vRP.hasGroup(user_id,"respilegalrealidade") 
    or vRP.hasGroup(user_id,"gestaorealidade") or vRP.hasGroup(user_id,"respeventosrealidade") or vRP.hasGroup(user_id,"supervisorrealidade")
end

function serverFunctions.checkPermission()
    local userId = vRP.getUserId(source)
    return userId ~= nil and canOpenRemoteShop(userId)
end

local buyingClothes = {}

local function canPurchaseClothes(player, userId)
    local ped = GetPlayerPed(player)
    if ped == 0 or GetEntityHealth(ped) <= 101 or GetVehiclePedIsIn(ped, false) ~= 0 then return false end
    if vRP.hasPermission(userId, "perm.ferias") or canOpenRemoteShop(userId) then return true end
    local position = GetEntityCoords(ped)
    for _, shop in pairs(locateShops or {}) do
        if #(position - vector3(shop[1], shop[2], shop[3])) <= 3.0 then return true end
    end
    return false
end

function serverFunctions.purchaseClothes(custom)
    local player = source
    local userId = vRP.getUserId(player)
    if not userId or not canPurchaseClothes(player, userId) or type(custom) ~= "table" then
        return false, "Você precisa estar em uma loja de roupas."
    end

    local pedModel = GetEntityModel(GetPlayerPed(player))
    if pedModel ~= `mp_m_freemode_01` and pedModel ~= `mp_f_freemode_01` then
        return false, "Este personagem não pode trocar de roupa."
    end
    local clean = { pedModel = pedModel }
    local function copySlot(slot, prop)
        local value = custom[slot] or custom[tostring(slot)]
        if type(value) ~= "table" then return false end
        local item, texture, palette = tonumber(value[1]), tonumber(value[2]), tonumber(value[3]) or 0
        if not item or item % 1 ~= 0 or item < (prop and -1 or 0) or item > 10000
            or not texture or texture % 1 ~= 0 or texture < 0 or texture > 1000
            or palette % 1 ~= 0 or palette < 0 or palette > 3 then return false end
        clean[slot] = prop and { item, texture } or { item, texture, palette }
        return true
    end
    for id = 0, 11 do
        if id ~= 2 and not copySlot(id, false) then return false, "Conjunto de roupas inválido." end
    end
    for id = 0, 7 do
        if not copySlot("p" .. id, true) then return false, "Conjunto de acessórios inválido." end
    end

    if buyingClothes[userId] then return false, "Aguarde a compra em andamento." end
    buyingClothes[userId] = true
    local paid = false
    local ok, saved = pcall(function()
        paid = vRP.tryFullPayment(userId, SkinshopPurchasePrice)
        if not paid then return false end
        local result = vRP.query("apparence/roupas", { user_id = userId, roupas = json.encode(clean) })
        return result ~= nil and result ~= false
    end)
    buyingClothes[userId] = nil
    if ok and not paid then return false, "Saldo insuficiente para comprar as roupas." end
    if not ok or not saved then
        if paid then vRP.giveBankMoney(userId, SkinshopPurchasePrice) end
        return false, "Não foi possível salvar as roupas. Tente novamente."
    end
    vRP.updateUserApparence(userId, "clothes", clean)
    return true
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
