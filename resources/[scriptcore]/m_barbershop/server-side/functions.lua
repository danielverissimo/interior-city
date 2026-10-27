AddEventHandler("barbershop:init", function(user_id)
	local source = vRP.getUserSource(user_id)
	if source then
		local data = vRP.getUserApparence(user_id)
		if user_id then
			if data['rosto'] then
				clientFunctions.setCharacter(source, data['rosto'])
			end
		end
	end
end)

RegisterCommand('loja3', function(source, args)
    local userId = vRP.getUserId(source)
    local perms = {
        { permType = 'perm', perm = 'developer.permissao' },
    }

    local hasPermission = false
    for _, perm in pairs(perms) do
        if perm.permType == 'perm' then
            if vRP.hasPermission(userId, perm.perm) then
                hasPermission = true
                break
            end
        elseif perm.permType == 'group' then
            if vRP.hasGroup(userId, perm.perm) then
                hasPermission = true
                break
            end
        end
    end

    if not hasPermission then
        return
    end

    clientFunctions.openNuiShop(source)
end)

function serverFunctions.updateSkin(skinUpdate)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		vRP.updateUserApparence(user_id, "rosto", skinUpdate)
		vRP.execute("apparence/rosto",{ user_id = user_id, rosto = json.encode(skinUpdate) })
	end

    if vRP.getMoney(user_id) > 100 or vRP.getBankMoney(user_id) > 100 then 
        vRP.tryFullPayment(user_id,parseInt(100))
    end

end


local BARBER_CONFIG_FILE = "shared-side/shared.locations.json"

local function normalizeCoords(coords)
    if type(coords) ~= "table" then return nil end
    local x = tonumber(coords.x or coords[1])
    local y = tonumber(coords.y or coords[2])
    local z = tonumber(coords.z or coords[3])
    if not x or not y or not z then return nil end
    return { x = x, y = y, z = z }
end

local function loadBarberConfig()
    local raw = LoadResourceFile(GetCurrentResourceName(), BARBER_CONFIG_FILE)
    local ok, data = pcall(json.decode, raw or "{}")
    if not ok or type(data) ~= "table" then data = {} end

    locations = {}
    for _, shop in ipairs(type(data.locations) == "table" and data.locations or {}) do
        local id = tonumber(shop.id)
        local coords = normalizeCoords(shop)
        if id and coords then
            locations[tostring(id)] = {
                coords.x, coords.y, coords.z,
                shop.blip == true,
                shop.marker ~= false
            }
        end
    end
end

local function serializeBarbers()
    local out = {}
    for id, data in pairs(locations or {}) do
        if data[1] and data[2] and data[3] then
            out[#out+1] = {
                id = tonumber(id),
                x = tonumber(data[1]),
                y = tonumber(data[2]),
                z = tonumber(data[3]),
                blip = data[4] == true,
                marker = data[5] ~= false
            }
        end
    end
    table.sort(out, function(a,b) return a.id < b.id end)
    return { locations = out }
end

local function saveBarberConfig()
    local payload = serializeBarbers()
    if not SaveResourceFile(GetCurrentResourceName(), BARBER_CONFIG_FILE, json.encode(payload), -1) then
        return false, "Não foi possível salvar shared.locations.json."
    end
    TriggerClientEvent("m_barbershop:fullSync", -1, payload.locations)
    return true
end

local function nextBarberId()
    local highest = 0
    for id in pairs(locations or {}) do
        highest = math.max(highest, tonumber(id) or 0)
    end
    return highest + 1
end

loadBarberConfig()

RegisterNetEvent("m_barbershop:requestSync", function()
    TriggerClientEvent("m_barbershop:fullSync", source, serializeBarbers().locations)
end)

AddEventHandler("vRP:playerSpawn", function(userId, source)
    TriggerClientEvent("m_barbershop:fullSync", source, serializeBarbers().locations)
end)

exports("getBarberShops", function()
    local out = {}
    for _, shop in ipairs(serializeBarbers().locations) do
        out[#out+1] = {
            id = shop.id,
            coords = { x = shop.x, y = shop.y, z = shop.z }
        }
    end
    return out
end)

exports("addBarberShop", function(coords)
    coords = normalizeCoords(coords)
    if not coords then return false, "Coordenadas inválidas." end

    local id = nextBarberId()
    locations[tostring(id)] = { coords.x, coords.y, coords.z, false, true }

    local ok, msg = saveBarberConfig()
    if not ok then
        locations[tostring(id)] = nil
        return false, msg
    end
    return true, "Barbearia adicionada com sucesso.", id
end)

exports("updateBarberShop", function(id, coords)
    id = tonumber(id)
    coords = normalizeCoords(coords)
    if not id or not coords then return false, "Dados inválidos." end

    local key = tostring(id)
    local old = locations[key]
    if not old then return false, "Barbearia não encontrada." end

    locations[key] = { coords.x, coords.y, coords.z, old[4] == true, old[5] ~= false }
    local ok, msg = saveBarberConfig()
    if not ok then
        locations[key] = old
        return false, msg
    end
    return true, "Local da barbearia atualizado."
end)

exports("removeBarberShop", function(id)
    id = tonumber(id)
    local key = tostring(id or "")
    if not id or not locations[key] then return false, "Barbearia não encontrada." end

    local old = locations[key]
    locations[key] = nil
    local ok, msg = saveBarberConfig()
    if not ok then
        locations[key] = old
        return false, msg
    end
    return true, "Barbearia removida."
end)

exports("reloadBarberShops", function()
    loadBarberConfig()
    TriggerClientEvent("m_barbershop:fullSync", -1, serializeBarbers().locations)
    return true
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        for _, nSource in pairs(GetPlayers()) do
            local nuserId = vRP.getUserId(tonumber(nSource))
            if nuserId then
                TriggerEvent("barbershop:init", nuserId)
            end
        end
    end
end)
