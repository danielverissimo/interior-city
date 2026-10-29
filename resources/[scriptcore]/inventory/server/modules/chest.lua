Chests = Chests or {}
local isChestsLoaded = false
local sourcesLoadedChests = {}

local CHESTS_FILE <const> = "config/shared.chests.json"


local function mansionIptuAccess(source, permission)
    if not permission or permission == "" or GetResourceState("m_mansions") ~= "started" then
        return true
    end
    local ok,allowed = pcall(function()
        return exports["m_mansions"]:checkAccessByPermission(source,permission)
    end)
    if not ok then
        print(("^1[inventory]^7 Falha ao consultar IPTU da mansão: %s"):format(tostring(allowed)))
        return true
    end
    return allowed ~= false
end

local function normalizeChestCoords(coords)
    if not coords then return nil end

    local x = tonumber(coords.x or coords[1])
    local y = tonumber(coords.y or coords[2])
    local z = tonumber(coords.z or coords[3])

    if not x or not y or not z then
        return nil
    end

    return vec3(x, y, z)
end


local function chestForClient(chestData)
    if not chestData or not chestData.coords then return nil end

    return {
        max_weight = tonumber(chestData.max_weight) or 0,
        permission = chestData.permission or "",
        coords = {
            x = tonumber(chestData.coords.x or chestData.coords[1]) or 0.0,
            y = tonumber(chestData.coords.y or chestData.coords[2]) or 0.0,
            z = tonumber(chestData.coords.z or chestData.coords[3]) or 0.0
        }
    }
end

local function serializeChests()
    local data = {}

    for name, chest in pairs(Chests) do
        if chest and chest.coords then
            data[name] = {
                max_weight = tonumber(chest.max_weight) or 0,
                permission = chest.permission or "",
                coords = {
                    x = chest.coords.x,
                    y = chest.coords.y,
                    z = chest.coords.z
                }
            }
        end
    end

    return data
end

local function saveChestsJson()
    local encoded = json.encode(serializeChests(), { indent = true })
    local saved = SaveResourceFile(GetCurrentResourceName(), CHESTS_FILE, encoded, -1)

    if not saved then
        print("^1[ERRO]^7 Não foi possível salvar " .. CHESTS_FILE)
        return false
    end

    return true
end

local function loadChestsJson()
    local raw = LoadResourceFile(GetCurrentResourceName(), CHESTS_FILE)
    if not raw or raw == "" then
        print("^1[ERRO]^7 Arquivo " .. CHESTS_FILE .. " não encontrado ou vazio.")
        return false
    end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= "table" then
        print("^1[ERRO]^7 JSON inválido em " .. CHESTS_FILE)
        return false
    end

    Chests = {}

    for name, chest in pairs(decoded) do
        local coords = normalizeChestCoords(chest.coords)
        if type(name) == "string" and coords then
            Chests[name] = {
                max_weight = tonumber(chest.max_weight) or 0,
                permission = chest.permission or "",
                coords = coords
            }
        else
            print(("^3[AVISO]^7 Baú '%s' ignorado: configuração inválida."):format(tostring(name)))
        end
    end

    return true
end

---@class ChestUtils
ChestUtils = {
    chests = {
        --[[
            "chest_name":
                actived: boolean
                alias?: string | nil
        ]]
    },
    users  = {},
}

---@param src number
---@param chest string
---@param status boolean
---@param alias? string | nil
---@param max_weight? number | nil
---@param type? string | nil
function ChestUtils:SetStatus(src, chest, status, alias, max_weight, type)
    if not src then
        self.chests[chest] = false
        return
    end
    if not status then
        if not self.chests[chest] then
            return
        end
        SaveChest(chest, self.chests[chest])
        self.chests[chest] = nil
        self.users[src] = nil
        return
    end
    self.chests[chest] = {
        user = src,
        actived = status,
        alias = alias,
        type = type,
        max_weight = max_weight
    }
    self.users[src] = ((status) and chest or nil)
end

---@param chest string
---@return boolean
function ChestUtils:IsOpened(chest)
    return (self.chests[chest] and self.chests[chest].actived)
end

---@param chest string
---@return int
function ChestUtils:SourceOpened(chest)
    return (self.chests[chest] and self.chests[chest].user)
end

---@param name string
---@param toggle boolean
---@return boolean
function ChestUtils:ClearChestActive(name, toggle)
    if not self.chests[name] then
        return false
    end

    self.chests[name].actived = toggle
    return true
end

---@return table
function ChestUtils:AllChestsActive()
    local chestsActive = {}

    for k, v in pairs(self.chests) do
        if v.actived then
            chestsActive[k] = v
        end
    end

    return chestsActive
end

---@param src number | string
---@return string | nil
function ChestUtils:GetChestById(src)
    return (self.users[src])
end

---@param chest string | nil
---@return number | nil
function ChestUtils:GetWeight(chest)
    return ((self.chests[chest]) and self.chests[chest].max_weight or nil)
end

---@param chest string
---@return string | nil
function ChestUtils:GetType(chest)
    return ((self.chests[chest]) and self.chests[chest].type or nil)
end

---@param chest string
---@return string | nil
function ChestUtils:GetAlias(chest)
    return ((self.chests[chest]) and self.chests[chest].alias or nil)
end

---@param chest string
---@return number | nil
function ChestUtils:GetOwner(chest)
    return ((self.chests[chest]) and self.chests[chest].user or nil)
end

AddEventHandler("playerDropped", function(reason)
    if ChestUtils.users[source] then
        if reason:find("Server shutting down") then
            return
        end
        ChestUtils:SetStatus(source, ChestUtils.users[source], false)
    end
end)

local CACHED_HASHS = {}
local ITEMS_CACHE <const> = {}
-- IC Admin invokes these only while its global maintenance gate is held.
exports('icAdminOwnershipReady',function()
    if GetInvokingResource()~='ic_admin' then return false end
    return next(ChestUtils.chests or {})==nil and next(ChestUtils.users or {})==nil
end)
exports('icAdminOwnershipCommitted',function()
    if GetInvokingResource()~='ic_admin' then return false end
    if next(ChestUtils.chests or {}) or next(ChestUtils.users or {}) then return false end
    for key in pairs(ITEMS_CACHE) do ITEMS_CACHE[key]=nil end
    for key in pairs(CACHED_HASHS) do CACHED_HASHS[key]=nil end
    return true
end)

local USERS_BYPASS_VEHICLE = {}


local function auditChestTypeLabel(chestType)
    if chestType == "VEHICLE" then return "Porta-malas" end
    if chestType == "GROUP" then return "Baú de facção" end
    if chestType == "HOUSE" then return "Baú de casa" end
    if chestType == "WAREHOUSES" then return "Armazém" end
    return tostring(chestType or "Baú")
end

local function auditVehicleChestOwner(chestName)
    chestName = tostring(chestName or "")
    return tonumber(chestName:match("^chest:u(%d+)veh_"))
end

local function auditChestDetails(chestName, chestType, item, amount)
    local details = ("**Tipo:** %s\n**Identificador:** %s"):format(
        auditChestTypeLabel(chestType),
        tostring(chestName or "-")
    )
    if item then
        details = details .. "\n" .. InventoryAudit.ItemDetails(item, amount)
    end
    return details
end

function setBypassVehicle(user_id, vehicle)
    if not USERS_BYPASS_VEHICLE[vehicle] then
        USERS_BYPASS_VEHICLE[vehicle] = {}
    end
    USERS_BYPASS_VEHICLE[vehicle][user_id] = true
end

function isBypassVehicle(user_id, vehicle)
    return USERS_BYPASS_VEHICLE[vehicle] and USERS_BYPASS_VEHICLE[vehicle][user_id]
end

CreateThread(function()
    while GetResourceState("m_garage") ~= "started" do Wait(0) end
    local listCar = exports["m_garage"]:getListVehicles()
    for hash, data in pairs(listCar) do
        CACHED_HASHS[hash] = { spawn = data.model:lower(), name = data.name, trunk = data.trunk }
    end
    print("^2[INFO]^7 Carros carregados com sucesso!")
end)
vRP.prepare("updateBau","UPDATE mirtin_users_homes SET bau = @bau WHERE houseID = @id") 

---@param chest string
---@param data table
function SaveChest(chest, data)
    local identifier = chest
    if chest:find("HOME") then
        local houseId = tostring(chest:gsub('HOME_', ''))
        if not houseId:find(':') then
            vRP._execute("updateBau", { id = tonumber(houseId), bau = json.encode(ITEMS_CACHE[chest]) })
        else
            local newHouseId, ownerId = tonumber(houseId:split(':')[1]), tonumber(houseId:split(':')[2])
            exports.oxmysql:execute('UPDATE mirtin_users_homes SET bau = ? WHERE houseID = ? AND proprietario = ?', { json.encode(ITEMS_CACHE[chest]), newHouseId, ownerId })
        end
    elseif chest:find("WAREHOUSES:") then
        vRP.setSData(chest, json.encode(ITEMS_CACHE[chest]))
    else
        if data.type == "GROUP" then
            vRP.setSData(chest, json.encode(ITEMS_CACHE[chest]))
        else
            identifier = data.alias
            vRP.setSData(data.alias, json.encode(ITEMS_CACHE[identifier]))
        end
    end
    ITEMS_CACHE[identifier] = nil
end

local incomingRequests = {}

RegisterCommand('abrirpm', function(source, args)
    local user_id = vRP.getUserId(source)
    if not user_id then return end

    local perms = {
		{ permType = 'perm', perm = 'developer.permissao' },
		{ permType = 'perm', perm = 'perm.resplog' },
		{ permType = 'group', perm = 'respilegalrealidade' },
        { permType = 'group', perm = 'gestaorealidade' },
		{ permType = 'group', perm = 'resppoliciarealidade' },
		{ permType = 'group', perm = 'resplogrealidade' },
        { permType = 'group', perm = 'supervisorrealidade' },
	}

	local hasPermission = false
	for _, perm in ipairs(perms) do
		if perm.permType == 'perm' then
			if vRP.hasPermission(user_id, perm.perm) then
				hasPermission = true
				break
			end
		elseif perm.permType == 'group' then
			if vRP.hasGroup(user_id, perm.perm) then
				hasPermission = true
				break
			end
		end
	end

	if not hasPermission then 
		return
	end

    local TARGET_ID = vRP.prompt(source, "Digite o ID do cidadão: ", "")
    if not TARGET_ID or TARGET_ID == "" then
        return
    end
    TARGET_ID = parseInt(TARGET_ID)
    local TARGET_IDENTITY = vRP.getUserIdentity(TARGET_ID)

    if not TARGET_IDENTITY then
        TriggerClientEvent("Notify", source, "negado", "Id não encontrado.")
        return
    end

    local query = exports.oxmysql:executeSync('SELECT * FROM vrp_srv_data WHERE dkey LIKE ?', { 'chest:u'..TARGET_ID..'veh_%' })
    if #query == 0 then
        TriggerClientEvent("Notify", source, "negado", "Porta malas não encontrado.")
        return
    end

    local vehicleList = ""
    for i = 1, #query do
        vehicleList = vehicleList.. query[i].dkey:gsub("chest:u"..TARGET_ID.."veh_", "")..", "
    end

    local promptCar = vRP.prompt(source, "Escolha o veiculo do cidadão: ", vehicleList)
    if not promptCar or promptCar == "" then
        return
    end

    for i = 1, #query do
        if query[i].dkey == "chest:u"..TARGET_ID.."veh_"..promptCar then
            TriggerEvent('onSpawnVehicle', {
                name = promptCar,
                src = source
            })
            --staffRequests[source] = { user_id = TARGET_ID, vehicle = promptCar, entity = vehicle }
            if InventoryAudit then
                InventoryAudit.Log("inventory_staff_trunk_open", {
                    actorId = user_id,
                    targetId = TARGET_ID,
                    details = ("**Comando:** /abrirpm\n**Veículo:** %s\n**Dono do veículo:** ID %s"):format(tostring(promptCar), tostring(TARGET_ID))
                })
            end
            TriggerClientEvent("openChestVehicle", source, {promptCar, TARGET_IDENTITY.registro:gsub(" ", "")})
            break
        end
    end

    return
end)


---@param type "VEHICLE" | "GROUP" | "HOUSE"
---@param network_id number | nil
---@param chest_name string | nil
---@return table<string, table | number> | false
function API.requireChest(type, network_id, chest_name)
    if GetResourceState('ic_admin')=='started' and exports['ic_admin']:isUserInMaintenance(0) then
        TriggerClientEvent('Notify',source,'negado','Manutenção de patrimônio em andamento. Tente novamente em instantes.',5000)
        return
    end
    local source = source
    local user_id = vRP.getUserId(source)
    if incomingRequests[user_id] then
        Notify(source, "negado", "Voce ja tem uma abertura pendente, aguarde alguns instantes para tentar novamente!")
        return
    end


    if user_id then
        if type == "VEHICLE" then
            local entity = NetworkGetEntityFromNetworkId(network_id)
            local vehname, plate

            if entity > 0 then
                plate = GetVehicleNumberPlateText(entity)
                vehname = GetEntityModel(entity)
            else
                local platetext, model, netid, carname = vRPc.ModelName(source, 5.0)
                if netid then
                    entity = NetworkGetEntityFromNetworkId(network_id)
                    if entity > 0 then
                        plate = GetVehicleNumberPlateText(entity)
                        vehname = GetEntityModel(entity)
                    else
                        plate = platetext:gsub(" ", "")
                        vehname = GetHashKey(model)
                        entity = netid
                    end
                end
              
            end

            local vehicle_owner = vRP.getUserByRegistration(plate)
            if not vehicle_owner then
                Notify(source, "negado", "Veículo de americano.")
                return false
            end

            local hasPermission = false

            local perms = {
                { permType = 'perm', perm = 'developer.permissao' },
                { permType = 'perm', perm = 'perm.respilegal' },
                { permType = 'perm', perm = 'perm.resplog' },
                { permType = 'group', perm = 'supervisorrealidade' },
            }
            
            for _, perm in ipairs(perms) do
                if perm.permType == 'perm' then
                    if vRP.hasPermission(user_id, perm.perm) then
                        hasPermission = true
                        break
                    end
                elseif perm.permType == 'group' then
                    if vRP.hasGroup(user_id, perm.perm) then
                        hasPermission = true
                        break
                    end
                end
            end

            if vRP.hasPermission(user_id, 'perm.openchest') then
                local amount = vRP.getInventoryItemAmount(user_id, 'weapon_crowbar')
                if amount > 0 then
                    hasPermission = true
                end
            end

            if (not hasPermission) then
                if not ((vehicle_owner == user_id) or vRP.hasPermission(user_id, "policia.permissao") or isBypassVehicle(user_id, network_id)) then
                    local vehicle_owner_source = vRP.getUserSource(vehicle_owner)
                    if not vehicle_owner_source then
                        Notify(source, "negado", "Não foi possível encontrar o dono do veiculo!")
                        return false
                    end
                    local identity = vRP.getUserIdentity(user_id)
                    incomingRequests[user_id] = true
                    SetTimeout(15 * 1000, function()
                        incomingRequests[user_id] = nil
                    end)
                    Notify(source, "aviso", "Pedido de abertura enviada ao dono do veiculo!")
                    local request_owner = vRP.request(vehicle_owner_source,
                        string.format("%s [%s] deseja abrir seu porta malas, aceita?",
                            identity.nome .. " " .. identity.sobrenome, user_id), 15)
                    if request_owner then
                        incomingRequests[user_id] = nil
                    else
                        Notify(source, "negado", "O dono do veiculo recusou a abertura!")
                        return false
                    end
                end
            end

            local vehicle_data = CACHED_HASHS[vehname]
            if not vehicle_data then
                Notify(source, "negado", "Veículo não cadastrado.")
                return false
            end

            local max_weight = vehicle_data.trunk
            chest_name = "chest:u" .. vehicle_owner .. "veh_" .. string.lower(vehicle_data.spawn)
            if ChestUtils:IsOpened("VEHICLE_" .. entity) then
                Notify(source, "negado", "Baú em uso no momento.")
                return false
            end

            if not DoesEntityExist(entity) then
                Notify(source, "negado", "Veículo não encontrado.")
                return false
            end

            ---@diagnostic disable-next-line: param-type-mismatch
            ChestUtils:SetStatus(source, "VEHICLE_" .. entity, true, chest_name, max_weight, type)

            local chestItems = json.decode(vRP.getSData(chest_name)) or {}
            ITEMS_CACHE[chest_name] = chestItems

            if InventoryAudit then
                local accessMethod = "Autorização do proprietário/permissão válida"
                if vehicle_owner == user_id then
                    accessMethod = "Proprietário do veículo"
                elseif hasPermission then
                    accessMethod = "Permissão especial"
                elseif vRP.hasPermission(user_id, "policia.permissao") then
                    accessMethod = "Permissão policial"
                elseif isBypassVehicle(user_id, network_id) then
                    accessMethod = "Bypass autorizado"
                end

                InventoryAudit.Log("inventory_trunk_open", {
                    actorId = user_id,
                    targetId = vehicle_owner ~= user_id and vehicle_owner or nil,
                    details = ("**Veículo:** %s\n**Placa:** %s\n**Porta-malas:** %s\n**Capacidade:** %s kg\n**Acesso:** %s"):format(
                        tostring(vehicle_data.spawn or vehname),
                        tostring(plate or "-"),
                        tostring(chest_name),
                        tostring(max_weight),
                        accessMethod
                    )
                })
            end

            local formatedItems = {}
            local itemCount = 0
            if chestItems then
                for k, v in pairs(chestItems) do
                    itemCount += 1
                    formatedItems[tostring(itemCount)] = { amount = v["amount"], item = k }
                end
            end


            return {
                inventory = formatedItems,
                weight = vRP.computeChestWeight(chestItems),
                max_weight = max_weight,
            }
        elseif type == "GROUP" then
            local chest_config = Chests[chest_name]

            if not chest_config then
                error("invalid chest name " .. chest_name)
                return false
            end

            if chest_config.permission and vRP.hasPermission(user_id, chest_config.permission) then
                if not mansionIptuAccess(source,chest_config.permission) then
                    return false
                end
            end

            if chest_config.permission and not vRP.hasPermission(user_id, chest_config.permission) and not vRP.hasPermission(user_id, "developer.permissao") then
                Notify(source, "negado", "Você não tem permissão para acessar o baú " .. chest_name)
                return false
            end

            if ChestUtils:IsOpened("orgChest:" .. chest_name) then
                local plySource = ChestUtils:SourceOpened("orgChest:" .. chest_name)
                local plyPed = GetPlayerPed(plySource)

                if plyPed and #(GetEntityCoords(plyPed) - GetEntityCoords(GetPlayerPed(source))) <= 5 then
                    Notify(source, "negado", "Baú em uso no momento.")
                    return false
                end

                if plyPed > 0 then
                    Remote._sendNuiEvent(plySource, {
                        route = "CLOSE_INVENTORY",
                        ignoreRight = false
                    })
                end

                Wait(1000)
            end

            ---@diagnostic disable-next-line: param-type-mismatch
            ChestUtils:SetStatus(source, "orgChest:" .. chest_name, true, chest_name, chest_config.max_weight, type)
            local chestItems = json.decode(vRP.getSData("orgChest:" .. chest_name)) or {}
            local formatedItems = {}
            local itemCount = 0
            if chestItems then
                for k, v in pairs(chestItems) do
                    itemCount += 1
                    formatedItems[tostring(itemCount)] = { amount = v["amount"], item = k }
                end
            end
            ITEMS_CACHE["orgChest:" .. chest_name] = chestItems

            if InventoryAudit then
                InventoryAudit.Log("inventory_chest_open", {
                    actorId = user_id,
                    details = ("**Tipo:** Baú de facção\n**Baú:** %s\n**Capacidade:** %s kg"):format(
                        tostring(chest_name),
                        tostring(chest_config.max_weight)
                    )
                })
            end

            return ({
                title = chest_name,
                inventory = formatedItems,
                weight = vRP.computeChestWeight(chestItems),
                max_weight = chest_config.max_weight,
            })
        elseif type == "HOUSE" then
            local max_weight = network_id
            local houseId = tostring(chest_name)
            if ChestUtils:IsOpened("HOME_" .. houseId) then
                Notify(source, "negado", "Baú em uso no momento.")
                return false
            end
            ---@diagnostic disable-next-line: param-type-mismatch
            ChestUtils:SetStatus(source, "HOME_" .. houseId, true, nil, max_weight, type)
            local chestItems = {}
            if not houseId:find(':') then
                chestItems = json.decode(MySQL.single.await("SELECT bau FROM mirtin_users_homes WHERE houseID = ?",
                { houseId })?.bau) or {}
            else
                local newHouseId, ownerId = houseId:split(':')[1], houseId:split(':')[2]
                chestItems = json.decode(MySQL.single.await("SELECT bau FROM mirtin_users_homes WHERE houseID = ? AND proprietario = ?",
                { newHouseId, ownerId })?.bau) or {}
            end
            ITEMS_CACHE[chest_name] = chestItems
            local formatedItems = {}
            local itemCount = 0
            if chestItems then
                for k, v in pairs(chestItems) do
                    itemCount += 1
                    formatedItems[tostring(itemCount)] = { amount = v["amount"], item = k }
                end
            end
            ITEMS_CACHE["HOME_" .. houseId] = chestItems

            if InventoryAudit then
                InventoryAudit.Log("inventory_chest_open", {
                    actorId = user_id,
                    details = ("**Tipo:** Baú de casa\n**Casa:** %s\n**Capacidade:** %s kg"):format(
                        tostring(houseId),
                        tostring(max_weight)
                    )
                })
            end

            return ({
                inventory = formatedItems,
                weight = vRP.computeChestWeight(chestItems),
                max_weight = max_weight,
            })
        elseif type == "WAREHOUSES" then
            local max_weight = network_id
            if ChestUtils:IsOpened("WAREHOUSES:" .. chest_name) then
                Notify(source, "negado", "Baú em uso no momento.")
                return false
            end
            ---@diagnostic disable-next-line: param-type-mismatch
            ChestUtils:SetStatus(source, "WAREHOUSES:" .. chest_name, true, nil, max_weight, type)
            local chestItems = json.decode(vRP.getSData("WAREHOUSES:" .. chest_name)) or {}
            ITEMS_CACHE["WAREHOUSES:" .. chest_name] = chestItems
            local formatedItems = {}
            local itemCount = 0
            if chestItems then
                for k, v in pairs(chestItems) do
                    itemCount += 1
                    formatedItems[tostring(itemCount)] = { amount = v["amount"], item = k }
                end
            end
            ITEMS_CACHE["WAREHOUSES:" .. chest_name] = chestItems

            if InventoryAudit then
                InventoryAudit.Log("inventory_chest_open", {
                    actorId = user_id,
                    details = ("**Tipo:** Armazém\n**Armazém:** %s\n**Capacidade:** %s kg"):format(
                        tostring(chest_name),
                        tostring(max_weight)
                    )
                })
            end

            return ({
                inventory = formatedItems,
                weight = vRP.computeChestWeight(chestItems),
                max_weight = max_weight,
            })
        else
            error("invalid type " .. type)
            return false
        end
    end
    return false
end

---@param slot string
---@param amount number
---@return boolean | table
function API.storeChestItem(slot, amount)
    local source = source
    local user_id = vRP.getUserId(source)

    if user_id then
        if HotbarWeapons then
            local active = HotbarWeapons.GetActive(user_id)
            if active and tostring(active.slot) == tostring(slot) then
                HotbarWeapons.ForceHolster(source, user_id)
            end
        end

        local slot_data = vRP.getSlotItem(user_id, slot)
        if not slot_data then
            return {
                error = "Re-abra o baú."
            }
        end
        if HotbarWeapons and HotbarWeapons.IsDutyWeaponSlot(user_id, slot, slot_data.item) then
            return { error = "Você não pode guardar uma arma temporária de serviço." }
        end

        if slot_data.item == "money" then
            return {
                error = "Voce nao pode guardar isto aqui!"
            }
        end
        if amount <= 0 then
            return {
                error = "Atividade suspeita!"
            }
        end
        amount = ((amount > slot_data.amount) and slot_data.amount or amount)

        local identity = vRP.getUserIdentity(user_id)
        local chest_name = ChestUtils:GetChestById(source)
        local weight = ChestUtils:GetWeight(chest_name)
        local chest_type = ChestUtils:GetType(chest_name)
        if chest_name and chest_type ~= "GROUP" and ChestUtils:GetAlias(chest_name) then
            chest_name = ChestUtils:GetAlias(chest_name)
        end
        if chest_name then
            local chestItems = ITEMS_CACHE[chest_name]
            if not chestItems then
                print("ERRO GRAVE_INVENTARIO ", chest_name, chest_type)
            end
            if (tonumber(vRP.computeChestWeight(chestItems)) + tonumber((Items[slot_data.item].weight * amount))) > tonumber(weight) then
                return {
                    error = "Baú cheio."
                }
            else
                if not vRP.tryGetInventoryItem(user_id, slot_data.item, amount, slot) then
                    return {
                        error = "Item não disponível!"
                    }
                end
            end
            chestItems[slot_data.item] = chestItems[slot_data.item] or { amount = 0 }
            chestItems[slot_data.item].amount = chestItems[slot_data.item].amount + amount
            ITEMS_CACHE[chest_name] = chestItems

            if InventoryAudit then
                local isVehicle = chest_type == "VEHICLE"
                local ownerId = isVehicle and auditVehicleChestOwner(chest_name) or nil
                InventoryAudit.Log(isVehicle and "inventory_trunk_store" or "inventory_chest_store", {
                    actorId = user_id,
                    targetId = ownerId and ownerId ~= user_id and ownerId or nil,
                    details = auditChestDetails(chest_name, chest_type, slot_data.item, amount)
                })
            end

            if (chest_name):find('veh_') then 
                exports["vrp_admin"]:generateLog({
                    category = "inventario",
                    room = "bau-carros",
                    user_id = user_id,
                    message = ( [[O USER_ID %s VEICULO %s ACOES %s]] ):format(user_id, chest_name,  "Guardou "..amount.."x "..slot_data.item)
                })
            end

            if (chest_name):find('HOME_') then 
                exports["vrp_admin"]:generateLog({
                    category = "inventario",
                    room = "bau-casas",
                    user_id = user_id,
                    message = ( [[O USER_ID %s CASA %s ACOES %s]] ):format(user_id, chest_name,  "Guardou "..amount.."x "..slot_data.item)
                })
            end

            if (chest_name):find('orgChest:') then 
                exports["vrp_admin"]:generateLog({
                    category = "inventario",
                    room = "bau",
                    user_id = user_id,
                    message = ( [[O USER_ID %s BAU %s ACOES %s]] ):format(user_id, chest_name,  "Guardou "..amount.."x "..slot_data.item)
                })
            end

            return true
        end
    end
    return false
end


---@param item string
---@param amount number
---@return boolean | table
function API.takeChestItem(item, amount, slot)
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        if amount <= 0 then
            return {
                error = "Atividade suspeita!"
            }
        end
        local chest_name = ChestUtils:GetChestById(source)
        local chest_type = ChestUtils:GetType(chest_name)
        if chest_type == "VEHICLE" then
            local entity_str = chest_name:gsub("VEHICLE_", "")
            local entity = tonumber(entity_str)
            local ped = GetPlayerPed(source)
            if not IsEntityVisible(ped) then
                return false
            end
            if entity and entity > 0 and DoesEntityExist(entity) then
                local player_cds = GetEntityCoords(ped)
                local entity_cds = GetEntityCoords(entity)
                if #(player_cds - entity_cds) > 10.0 then
                    return false
                end
            end
        end
        if chest_name and chest_type ~= "GROUP" and ChestUtils:GetAlias(chest_name) then
            chest_name = ChestUtils:GetAlias(chest_name)
        end
        if chest_name then
            local identity = vRP.getUserIdentity(user_id)


            if vRP.computeInvWeight(user_id) + (Items[item].weight * amount) > vRP.getInventoryMaxWeight(user_id) then
                return {
                    error = "Espaço insuficiente na mochila."
                }
            end
            local chestItems = ITEMS_CACHE[chest_name]
            if not chestItems[item] then
                return false
            end
            amount = ((amount > chestItems[item].amount) and chestItems[item].amount or amount)
            if amount == chestItems[item].amount then
                chestItems[item] = nil
            else
                chestItems[item].amount -= amount
            end
            ITEMS_CACHE[chest_name] = chestItems
            vRP.giveInventoryItem(user_id, item, amount, slot)

            if InventoryAudit then
                local isVehicle = chest_type == "VEHICLE"
                local ownerId = isVehicle and auditVehicleChestOwner(chest_name) or nil
                InventoryAudit.Log(isVehicle and "inventory_trunk_take" or "inventory_chest_take", {
                    actorId = user_id,
                    targetId = ownerId and ownerId ~= user_id and ownerId or nil,
                    details = auditChestDetails(chest_name, chest_type, item, amount)
                })
            end

            if (chest_name):find('veh_') then 
                exports["vrp_admin"]:generateLog({
                    category = "inventario",
                    room = "bau-carros",
                    user_id = user_id,
                    message = ( [[O USER_ID %s VEICULO %s ACOES %s]] ):format(user_id, chest_name,  "Retirou "..amount.."x "..item)
                })
            end

            if (chest_name):find('HOME_') then 
                exports["vrp_admin"]:generateLog({
                    category = "inventario",
                    room = "bau-casas",
                    user_id = user_id,
                    message = ( [[O USER_ID %s CASA %s ACOES %s]] ):format(user_id, chest_name,  "Retirou "..amount.."x "..item)
                })
            end

            if (chest_name):find('orgChest:') then 
                exports["vrp_admin"]:generateLog({
                    category = "inventario",
                    room = "bau",
                    user_id = user_id,
                    message = ( [[O USER_ID %s BAU %s ACOES %s]] ):format(user_id, chest_name,  "Retirou "..amount.."x "..item)
                })
            end

            return true
        else
            return {
                error = "Baú não encontrado!"
            }
        end
    end
    return {
        error = "Erro desconhecido"
    }
end

AddCloseListener(function(src, user_id)
    local chest_name = ChestUtils:GetChestById(src)
    if chest_name then
        ChestUtils:SetStatus(src, chest_name, false)
        TriggerClientEvent("clearAnims", src)
    end
end)

AddEventHandler("entityRemoved", function(entity)
    if ChestUtils:IsOpened("VEHICLE_" .. entity) then
        local user = ChestUtils:GetOwner("VEHICLE_" .. entity)
        ChestUtils:SetStatus(user, "VEHICLE_" .. entity, false)
        TriggerClientEvent("clearAnims", user)
        Remote._sendNuiEvent(user, {
            route = "CLOSE_INVENTORY",
            ignoreRight = true
        })
    end
end)

RegisterCommand('baufacadm', function(source,args)
	local user_id = vRP.getUserId(source)
	if not user_id then return end
    if vRP.hasPermission(user_id, "developer.permissao") or vRP.hasPermission(user_id,"perm.resplog") or vRP.hasGroup(user_id,'respilegalrealidade') or vRP.hasGroup(user_id,'gestaorealidade') then
        local t = ""
        for i in pairs(Chests) do
            t = t.. i..", "
        end
    
        local promptOrg = vRP.prompt(source, "Escolha a Fac: ", t)
        if not promptOrg or promptOrg == "" then
            return
        end
    
        for i in pairs(Chests) do
            if i == promptOrg then
                staffRequests[source] = { user_id = user_id, org = promptOrg }
                TriggerClientEvent('openChestGroup', source, promptOrg)
                if InventoryAudit then
                    InventoryAudit.Log("inventory_staff_faction_chest_open", {
                        actorId = user_id,
                        details = ("**Comando:** /baufacadm\n**Facção/baú:** %s"):format(tostring(promptOrg))
                    })
                end
                return
            end
        end
    
        TriggerClientEvent( "Notify", source, "negado", "Bau de facção não encontrado...", 5 )
        return	
    end
end)

function addChest(chestName, chestData)
    Chests[chestName] = chestData

    local clientData = chestForClient(chestData)
    if clientData then
        TriggerClientEvent("inventory:chests:add", -1, chestName, clientData)
    end
end

function removeChest(chestName)
    Chests[chestName] = nil
    TriggerClientEvent("inventory:chests:remove", -1, chestName)
end

local function getAllChestsForClient()
    local payload = {}

    for chestName, chestData in pairs(Chests) do
        local clientData = chestForClient(chestData)
        if clientData then
            payload[chestName] = clientData
        end
    end

    return payload
end

function syncChestsWithPlayer(source)
    -- Sincronização completa em um único evento. Além de ser mais robusta,
    -- garante que baús removidos não permaneçam presos no cache do client.
    TriggerClientEvent("inventory:chests:fullSync", source, getAllChestsForClient())

    -- Mantemos a validação abaixo apenas para identificar configurações inválidas.
    for chestName, chestData in pairs(Chests) do
        if chestName and chestData then
            local clientData = chestForClient(chestData)
            -- clientData já foi enviado pelo fullSync acima.
        else
            local userId = vRP.getUserId(source)
            local mensagem = string.format(
                "**[Cidade Alta] Erro na Sincronização de Baú**\n🆔 **User ID:** %d\n📦 **Baú:** %s\n⚠️ **Status:** Não configurado corretamente!\n\n<@694665184815349821>",
                (userId and userId or source), chestName and chestName or "Não identificado"
            )
            print("[Cidade Alta] [ERRO] Baú não configurado:", chestName and chestName or "Não identificado")
            if InventoryAudit then
                InventoryAudit.Log("inventory_chest_sync_error", {
                    actorId = userId,
                    actorLabel = "JOGADOR AFETADO",
                    details = ("**Baú:** %s\n**Status:** configuração inválida/não carregada corretamente"):format(tostring(chestName or "Não identificado"))
                })
            end
        end
    end
end

RegisterNetEvent("inventory:chests:requestSync", function()
    local src = source

    while not isChestsLoaded do
        Wait(100)
    end

    if src and src > 0 then
        syncChestsWithPlayer(src)
    end
end)

exports('getChests', function()
    local chests = {}
    for k, v in pairs(Chests) do
        table.insert(chests, {
            name = k,
            weight = v.max_weight,
            permission = v.permission,
            coords = v.coords
        })
    end

    local function getRolePriority(name)
        if name:match("^Lider%-") then
            return 1
        elseif name:match("^Gerente%-") then
            return 2
        else
            return 3
        end
    end

    table.sort(chests, function(a, b)
        local priorityA = getRolePriority(a.name)
        local priorityB = getRolePriority(b.name)

        if priorityA == priorityB then
            return a.name < b.name
        else
            return priorityA < priorityB
        end
    end)

    return chests
end)


exports('addChest', function(name, weight, permission, coords)
    if type(name) ~= "string" or name == "" then
        return false, 'Nome do baú inválido'
    end

    if Chests[name] then
        return false, 'Baú já existe'
    end

    local chestCoords = normalizeChestCoords(coords)
    if not chestCoords then
        return false, 'Coordenadas inválidas'
    end

    local chestData = {
        max_weight = tonumber(weight) or 0,
        permission = permission or "",
        coords = chestCoords
    }

    addChest(name, chestData)

    if not saveChestsJson() then
        removeChest(name)
        return false, 'Erro ao salvar o arquivo de baús'
    end

    return true, 'Baú adicionado com sucesso'
end)

exports('removeChest', function(name)
    if not Chests[name] then
        return false, 'Baú não existe'
    end

    local oldData = Chests[name]
    removeChest(name)

    if not saveChestsJson() then
        addChest(name, oldData)
        return false, 'Erro ao salvar o arquivo de baús'
    end

    return true, 'Baú removido com sucesso'
end)

exports('updateChest', function(name, weight, coords, permission)
    if not Chests[name] then
        return false, 'Baú não existe'
    end

    local chestCoords = normalizeChestCoords(coords)
    if not chestCoords then
        return false, 'Coordenadas inválidas'
    end

    local oldData = {
        max_weight = Chests[name].max_weight,
        permission = Chests[name].permission,
        coords = Chests[name].coords
    }

    Chests[name].max_weight = tonumber(weight) or Chests[name].max_weight
    Chests[name].coords = chestCoords
    if permission ~= nil then
        Chests[name].permission = permission
    end

    addChest(name, Chests[name])

    if not saveChestsJson() then
        Chests[name] = oldData
        addChest(name, oldData)
        return false, 'Erro ao salvar o arquivo de baús'
    end

    return true, 'Baú atualizado com sucesso'
end)

exports('updateChestCoords', function(name, coords)
    if not Chests[name] then
        return false, 'Baú não existe'
    end

    local chestCoords = normalizeChestCoords(coords)
    if not chestCoords then
        return false, 'Coordenadas inválidas'
    end

    local oldCoords = Chests[name].coords
    Chests[name].coords = chestCoords
    addChest(name, Chests[name])

    if not saveChestsJson() then
        Chests[name].coords = oldCoords
        addChest(name, Chests[name])
        return false, 'Erro ao salvar o arquivo de baús'
    end

    return true, 'Coordenadas do baú atualizadas com sucesso'
end)

exports('updateChestWeight', function(name, weight)
    if not Chests[name] then
        return false, 'Baú não existe'
    end

    local oldWeight = Chests[name].max_weight
    Chests[name].max_weight = tonumber(weight) or oldWeight
    addChest(name, Chests[name])

    if not saveChestsJson() then
        Chests[name].max_weight = oldWeight
        addChest(name, Chests[name])
        return false, 'Erro ao salvar o arquivo de baús'
    end

    return true, 'Peso do baú atualizado com sucesso'
end)

exports('updateChestPermission', function(name, permission)
    if not Chests[name] then
        return false, 'Baú não existe'
    end

    local oldPermission = Chests[name].permission
    Chests[name].permission = permission or ""
    addChest(name, Chests[name])

    if not saveChestsJson() then
        Chests[name].permission = oldPermission
        addChest(name, Chests[name])
        return false, 'Erro ao salvar o arquivo de baús'
    end

    return true, 'Permissão do baú atualizada com sucesso'
end)

exports('reloadChests', function()
    if not loadChestsJson() then
        return false, 'Erro ao recarregar os baús'
    end

    for _, player in ipairs(GetPlayers()) do
        local playerSource = tonumber(player)
        TriggerClientEvent("inventory:chests:reset", playerSource)
        syncChestsWithPlayer(playerSource)
    end

    return true, 'Baús recarregados com sucesso'
end)

AddEventHandler('vRP:playerSpawn', function(userId, source)
    while not isChestsLoaded do
        Wait(1000)
    end
    sourcesLoadedChests[source] = true
    syncChestsWithPlayer(source)
end)

CreateThread(function()
    if not loadChestsJson() then
        print("^1[ERRO]^7 Falha ao carregar os baús do JSON.")
    end

    isChestsLoaded = true

    local total = 0
    for _ in pairs(Chests) do
        total = total + 1
    end

    print(("^2[INFO]^7 %d baús carregados do JSON com sucesso!"):format(total))
end)

local debugBauCooldown = {}

RegisterCommand('debugbau', function(source, args)
    if debugBauCooldown[source] and debugBauCooldown[source] > os.time() then
        TriggerClientEvent('Notify', source, 'aviso', 'Aguarde '..(debugBauCooldown[source] - os.time())..' segundos para utilizar esse comando novamente.', 5000)
        return
    end

    debugBauCooldown[source] = os.time() + 30

    while not isChestsLoaded do
        Wait(1000)
    end

    TriggerClientEvent('Notify', source, 'aviso', 'Aguarde, os báus estão sendo recarregados...', 5000)
    syncChestsWithPlayer(source)
    TriggerClientEvent('Notify', source, 'sucesso', 'Aguarde, Baus adicionados com sucesso!', 5000)
end)

function API.debugBau()
    local source = source
    local userId = vRP.getUserId(source)
    while not isChestsLoaded do
        Wait(1000)
    end

    if not sourcesLoadedChests[source] then
        if InventoryAudit then
            InventoryAudit.Log("inventory_chest_manual_sync", {
                actorId = userId,
                actorLabel = "JOGADOR AFETADO",
                details = "**Situação:** os baús NÃO haviam sido carregados pelo evento vRP:playerSpawn e precisaram ser recarregados manualmente."
            })
        end
    else
        if InventoryAudit then
            InventoryAudit.Log("inventory_chest_manual_sync", {
                actorId = userId,
                actorLabel = "JOGADOR AFETADO",
                details = "**Situação:** os baús haviam sido carregados pelo evento vRP:playerSpawn, mas foi solicitada uma recarga manual."
            })
        end
    end

    syncChestsWithPlayer(source)
end