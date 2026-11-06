local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

local vRP = Proxy.getInterface("vRP")
local vRPclient = Tunnel.getInterface("vRP")

local API = {}
Tunnel.bindInterface(GetCurrentResourceName(), API)

local groupModule = module("vrp", "cfg/groups")

-- Catálogo da aba Itens.
-- Itens comuns continuam vindo do cadastro legado vrp/cfg/items.lua, porém
-- armas e munições (WEAPON_* / AMMO_*) também precisam aparecer mesmo quando
-- existirem somente no catálogo ativo retornado por vRP.getAllItens().
local itemsConfigModule = module("vrp", "cfg/items")
local configuredItems = (type(itemsConfigModule) == "table" and type(itemsConfigModule.items) == "table") and itemsConfigModule.items or {}

local function isWeaponOrAmmoItem(item)
    local key = tostring(item or ""):upper()
    return key:sub(1, 7) == "WEAPON_" or key:sub(1, 5) == "AMMO_"
end

local function isAllowedPanelItem(item, activeItems)
    item = tostring(item or "")
    if item == "" then return false end

    if configuredItems[item] ~= nil then
        return true
    end

    activeItems = activeItems or (vRP.getAllItens() or {})
    return isWeaponOrAmmoItem(item) and activeItems[item] ~= nil
end

local cleanupRunning = false
-- Armazena nomes de arquivos/KVPs em uma única estrutura para manter o chunk
-- principal abaixo do limite de 200 variáveis locais do Lua/FiveM.
local STORAGE = {
    locationsFile = "locations.json",
    locationCategoriesFile = "location_categories.json",
    environmentFile = "environment_state.json",
    environmentKvp = "mage_admin_environment_state",
    panelPermissionsFile = "panel_permissions.json",
    panelPermissionsKvp = "mage_admin_panel_permissions",
    banHistoryFile = "ban_history.json",
    vehiclesFile = "vehicles.json",
    warningsFile = "warnings_data.json",
    callsFile = "calls_data.json",
    callsKvp = "mage_admin_calls_data",
    logsFile = "logs_config.json",
    logsKvp = "mage_admin_logs_config"
}
local VIP = {
    packagesFile = "vip_packages.json",
    assignmentsFile = "vip_assignments.json",
    packagesStore = { packages = {} },
    assignmentsStore = { nextId = 1, active = {} },
    tests = {},
    durationSeconds = 30 * 24 * 60 * 60,
    testCenter = { x = -1291.34, y = -2980.99, z = 13.93, h = 330.0 },
    testRadius = 150.0,
    testSeconds = 60
}
local savedLocations = {}
local savedLocationCategories = {}
local savedVehicles = { game = {}, addon = {} }
local panelPermissions = {}
local banHistoryStore = { nextId = 1, entries = {} }
local warningStore = { nextId = 1, counts = {}, active = {}, history = {} }
local punishmentAppliedSources = {}

-- Cache local das identidades realmente persistidas no banco. Diferente do cache
-- interno de algumas bases vRP, este cache é alimentado pela vrp_user_identities e
-- é atualizado pelo editor do painel. Assim, mesmo após reiniciar SOMENTE este
-- resource, a primeira leitura volta ao banco e não reaproveita nome/idade antigos
-- que ainda possam estar presos em vRP.getUserIdentity durante a sessão do player.
local liveIdentityOverrides = {}

-- Forward declarations: getIdentity/publishIdentityLiveUpdate ficam antes das
-- rotinas SQL/listagem. Declarar aqui evita que Lua resolva getPlayers como global
-- quando a identidade é alterada em tempo real.
local identityRow
local getPlayers
local getItems

local callStore = { nextId = 1, history = {}, evaluations = {} }
local activeCalls = {}
local lastCallCreatedAt = {}

-- Sessões de monitoramento de tela. Apenas uma sessão por administrador.
local liveScreenSessions = {}
local liveScreenByAdmin = {}
local liveScreenByTarget = {}

-- Cache de coordenadas reportadas pelos próprios clients. O fallback por native
-- server-side continua existindo, mas o cache evita marcadores em 0,0 quando
-- a entidade do player ainda não está resolvida pelo OneSync.
local liveMapPositionCache = {}


local function normalizeCategoryName(value)
    local name = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return "" end
    if #name > 60 then name = name:sub(1, 60) end
    return name
end

local function parseCoordinateString(value)
    if type(value) ~= "string" then return nil end

    local raw = value:gsub("^%s+", ""):gsub("%s+$", "")
    if raw == "" then return nil end

    local parts = {}
    for part in (raw .. ","):gmatch("(.-),") do
        parts[#parts + 1] = part:gsub("^%s+", ""):gsub("%s+$", "")
    end

    if #parts ~= 3 then return nil end
    local x, y, z = tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3])
    if not x or not y or not z then return nil end

    return x + 0.0, y + 0.0, z + 0.0
end

local function resolveCoordinates(data)
    if type(data) ~= "table" then return nil end

    -- Quando a NUI envia o campo unificado, ele é validado de forma estrita:
    -- exatamente três valores numéricos separados por vírgula.
    if data.coords ~= nil then
        return parseCoordinateString(data.coords)
    end

    -- Compatibilidade com captura direta no jogo e versões anteriores.
    local x, y, z = tonumber(data.x), tonumber(data.y), tonumber(data.z)
    if not x or not y or not z then return nil end
    return x + 0.0, y + 0.0, z + 0.0
end

local function findLocationCategory(value)
    local wanted = normalizeCategoryName(value):lower()
    if wanted == "" then return nil end
    for _, category in ipairs(savedLocationCategories) do
        if tostring(category):lower() == wanted then return category end
    end
    return nil
end

local function ensureLocationCategory(value)
    local name = normalizeCategoryName(value)
    if name == "" then name = "Geral" end
    local existing = findLocationCategory(name)
    if existing then return existing, false end
    savedLocationCategories[#savedLocationCategories + 1] = name
    table.sort(savedLocationCategories, function(a, b) return tostring(a):lower() < tostring(b):lower() end)
    return name, true
end

local function saveLocationCategories()
    SaveResourceFile(GetCurrentResourceName(), STORAGE.locationCategoriesFile, json.encode(savedLocationCategories), -1)
end

local function loadLocationCategories()
    savedLocationCategories = {}
    local raw = LoadResourceFile(GetCurrentResourceName(), STORAGE.locationCategoriesFile)
    if raw and raw ~= "" then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == "table" then
            for _, entry in ipairs(decoded) do
                local name = normalizeCategoryName(type(entry) == "table" and (entry.name or entry.nome) or entry)
                if name ~= "" and not findLocationCategory(name) then
                    savedLocationCategories[#savedLocationCategories + 1] = name
                end
            end
        end
    end
    ensureLocationCategory("Geral")
end

local function normalizeLocation(entry)
    if type(entry) ~= "table" then return nil end
    local name = tostring(entry.name or entry.nome or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local x = tonumber(entry.x)
    local y = tonumber(entry.y)
    local z = tonumber(entry.z)
    if name == "" or not x or not y or not z then return nil end
    local category = normalizeCategoryName(entry.category or entry.categoria or "Geral")
    if category == "" then category = "Geral" end
    category = ensureLocationCategory(category)
    return { name = name, category = category, x = x + 0.0, y = y + 0.0, z = z + 0.0 }
end

local function loadSavedLocations()
    savedLocations = {}
    local raw = LoadResourceFile(GetCurrentResourceName(), STORAGE.locationsFile)
    if not raw or raw == "" then return end
    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= "table" then
        print(("^1[%s] locations.json inválido; iniciando lista vazia.^7"):format(GetCurrentResourceName()))
        return
    end
    for _, entry in ipairs(decoded) do
        local location = normalizeLocation(entry)
        if location then savedLocations[#savedLocations + 1] = location end
    end
end

local function saveSavedLocations()
    SaveResourceFile(GetCurrentResourceName(), STORAGE.locationsFile, json.encode(savedLocations), -1)
end

local function publicLocations()
    local list = {}
    for index, location in ipairs(savedLocations) do
        list[#list + 1] = {
            index = index,
            name = location.name,
            category = location.category or "Geral",
            type = "normal",
            x = location.x,
            y = location.y,
            z = location.z
        }
    end
    return list
end

local function publicLocationCategories()
    local list = {}
    for _, category in ipairs(savedLocationCategories) do
        list[#list + 1] = tostring(category)
    end
    table.sort(list, function(a, b) return a:lower() < b:lower() end)
    return list
end

loadLocationCategories()
loadSavedLocations()
saveLocationCategories() -- persiste Geral e categorias migradas de locations.json antigo

-- ============================================================================
-- CATÁLOGO DE VEÍCULOS (JOGO / ADDON)
-- ============================================================================
local function normalizeVehicleCategory(value)
    value = tostring(value or "game"):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if value == "addon" then return "addon" end
    return "game"
end

local function normalizeVehicleCatalogEntry(entry)
    if type(entry) ~= "table" then return nil end
    local spawn = tostring(entry.spawn or entry.vehicle or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local name = tostring(entry.name or entry.nome or spawn):gsub("^%s+", ""):gsub("%s+$", "")
    if spawn == "" then return nil end
    if #spawn > 80 then spawn = spawn:sub(1, 80) end
    if name == "" then name = spawn end
    if #name > 80 then name = name:sub(1, 80) end
    return { spawn = spawn, name = name }
end

local function seedGameVehicles()
    savedVehicles.game = {}
    for _, vehicle in ipairs(Config.Vehicles or {}) do
        local normalized = normalizeVehicleCatalogEntry(vehicle)
        if normalized then
            savedVehicles.game[#savedVehicles.game + 1] = normalized
        end
    end
end

local function saveVehicleCatalog()
    SaveResourceFile(GetCurrentResourceName(), STORAGE.vehiclesFile, json.encode(savedVehicles), -1)
end

local function loadVehicleCatalog()
    savedVehicles = { game = {}, addon = {} }
    local raw = LoadResourceFile(GetCurrentResourceName(), STORAGE.vehiclesFile)
    if raw and raw ~= "" then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == "table" then
            for _, category in ipairs({ "game", "addon" }) do
                local sourceList = type(decoded[category]) == "table" and decoded[category] or {}
                for _, entry in ipairs(sourceList) do
                    local normalized = normalizeVehicleCatalogEntry(entry)
                    if normalized then
                        savedVehicles[category][#savedVehicles[category] + 1] = normalized
                    end
                end
            end
        else
            print(("^1[%s] vehicles.json inválido; recriando catálogo padrão.^7"):format(GetCurrentResourceName()))
        end
    end

    -- Em instalação antiga sem vehicles.json, preserva a lista GTA já existente.
    if #savedVehicles.game == 0 then
        seedGameVehicles()
    end

    table.sort(savedVehicles.game, function(a, b) return a.name:lower() < b.name:lower() end)
    table.sort(savedVehicles.addon, function(a, b) return a.name:lower() < b.name:lower() end)
    saveVehicleCatalog()
end

local function publicVehicles()
    local list = {}
    for _, category in ipairs({ "game", "addon" }) do
        for index, vehicle in ipairs(savedVehicles[category] or {}) do
            list[#list + 1] = {
                index = index,
                spawn = vehicle.spawn,
                name = vehicle.name or vehicle.spawn,
                category = category
            }
        end
    end
    return list
end

loadVehicleCatalog()

-- ============================================================================
-- VIPS / PACOTES / ESCOLHA DE VEÍCULOS
-- ============================================================================
function VIP.trim(value, maxLen)
    local out = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if maxLen and #out > maxLen then out = out:sub(1, maxLen) end
    return out
end

function VIP.defaultPermission(groupName)
    local slug = VIP.trim(groupName):lower():gsub("[^%w]", "")
    if slug == "" then return nil end
    return "perm." .. slug
end

function VIP.loadStores()
    local raw = LoadResourceFile(GetCurrentResourceName(), VIP.packagesFile)
    local ok, decoded = pcall(json.decode, raw or "{}")
    if ok and type(decoded) == "table" then VIP.packagesStore = decoded end
    if type(VIP.packagesStore.packages) ~= "table" then VIP.packagesStore.packages = {} end

    local rawAssignments = LoadResourceFile(GetCurrentResourceName(), VIP.assignmentsFile)
    local okAssignments, decodedAssignments = pcall(json.decode, rawAssignments or "{}")
    if okAssignments and type(decodedAssignments) == "table" then VIP.assignmentsStore = decodedAssignments end
    if type(VIP.assignmentsStore.active) ~= "table" then VIP.assignmentsStore.active = {} end
    VIP.assignmentsStore.nextId = math.max(1, math.floor(tonumber(VIP.assignmentsStore.nextId) or 1))

    -- v2.90+: cada jogador pode possuir várias escolhas VIP pendentes ao mesmo
    -- tempo. Migra automaticamente o formato antigo active[userId] = record para
    -- active[userId][assignmentId] = record sem perder escolhas já existentes.
    local normalizedActive = {}
    local highestId = VIP.assignmentsStore.nextId - 1
    local migrated = false

    for userKey,value in pairs(VIP.assignmentsStore.active) do
        local userId = tonumber(userKey)
        if type(value) == "table" and value.group ~= nil then
            userId = tonumber(value.userId) or userId
            if userId then
                local assignmentId = math.max(1, math.floor(tonumber(value.id) or VIP.assignmentsStore.nextId))
                value.id = assignmentId
                value.userId = userId
                normalizedActive[tostring(userId)] = normalizedActive[tostring(userId)] or {}
                normalizedActive[tostring(userId)][tostring(assignmentId)] = value
                highestId = math.max(highestId, assignmentId)
                migrated = true
            end
        elseif userId and type(value) == "table" then
            normalizedActive[tostring(userId)] = normalizedActive[tostring(userId)] or {}
            for assignmentKey,record in pairs(value) do
                if type(record) == "table" and record.group ~= nil then
                    local assignmentId = math.max(1, math.floor(tonumber(record.id) or tonumber(assignmentKey) or VIP.assignmentsStore.nextId))
                    record.id = assignmentId
                    record.userId = userId
                    normalizedActive[tostring(userId)][tostring(assignmentId)] = record
                    highestId = math.max(highestId, assignmentId)
                end
            end
        end
    end

    VIP.assignmentsStore.active = normalizedActive
    VIP.assignmentsStore.nextId = math.max(VIP.assignmentsStore.nextId, highestId + 1)
    if migrated then
        SaveResourceFile(GetCurrentResourceName(), VIP.assignmentsFile, json.encode(VIP.assignmentsStore), -1)
    end
end

function VIP.savePackages()
    return SaveResourceFile(GetCurrentResourceName(), VIP.packagesFile, json.encode(VIP.packagesStore), -1)
end

function VIP.saveAssignments()
    return SaveResourceFile(GetCurrentResourceName(), VIP.assignmentsFile, json.encode(VIP.assignmentsStore), -1)
end

function VIP.assignmentBucket(userId, create)
    local key = tostring(tonumber(userId) or userId or "")
    if key == "" then return nil end
    local bucket = VIP.assignmentsStore.active[key]
    if type(bucket) ~= "table" then
        if not create then return nil end
        bucket = {}
        VIP.assignmentsStore.active[key] = bucket
    end
    return bucket
end

function VIP.removeAssignment(userId, assignmentId)
    local userKey = tostring(tonumber(userId) or userId or "")
    local bucket = VIP.assignmentBucket(userId, false)
    if not bucket then return end
    bucket[tostring(assignmentId or "")] = nil
    if next(bucket) == nil then VIP.assignmentsStore.active[userKey] = nil end
end

function VIP.currentAssignment(userId, preferredAssignmentId)
    userId = tonumber(userId)
    local bucket = userId and VIP.assignmentBucket(userId, false) or nil
    if not bucket then return nil,nil end

    local function valid(record)
        return type(record) == "table"
            and (tonumber(record.remainingChoices) or 0) > 0
            and vRP.hasGroup(userId, tostring(record.group or ""))
    end

    if preferredAssignmentId ~= nil then
        local preferred = bucket[tostring(preferredAssignmentId)]
        if valid(preferred) then return preferred,tostring(preferredAssignmentId) end
    end

    local selectedKey,selectedRecord,selectedId = nil,nil,nil
    for assignmentKey,record in pairs(bucket) do
        if valid(record) then
            local id = tonumber(record.id) or tonumber(assignmentKey) or math.huge
            if not selectedRecord or id < selectedId then
                selectedKey,selectedRecord,selectedId = tostring(assignmentKey),record,id
            end
        end
    end
    return selectedRecord,selectedKey
end

function VIP.managedGroupsRaw()
    if GetResourceState("vrp") ~= "started" then return {} end
    local ok, groupsList = pcall(function() return exports["vrp"]:getManagedGroups() end)
    if not ok or type(groupsList) ~= "table" then return {} end
    return groupsList
end

function VIP.managedGroups()
    local list = {}
    for _,entry in ipairs(VIP.managedGroupsRaw()) do
        local cfgData = type(entry.config) == "table" and entry.config or {}
        if tostring(cfgData.gtype or ""):lower() == "vip" then
            list[#list+1] = entry
        end
    end
    table.sort(list, function(a,b)
        local at = tostring((a.config or {}).title or a.name or ""):lower()
        local bt = tostring((b.config or {}).title or b.name or ""):lower()
        return at < bt
    end)
    return list
end

function VIP.findManaged(groupName)
    groupName = tostring(groupName or "")
    for _,entry in ipairs(VIP.managedGroups()) do
        if tostring(entry.name or "") == groupName then return entry end
    end
end

function VIP.normalizeItems(sourceItems)
    local activeItems = vRP.getAllItens() or {}
    local out, seen = {}, {}
    for _,entry in ipairs(type(sourceItems) == "table" and sourceItems or {}) do
        local item = VIP.trim(type(entry) == "table" and (entry.item or entry.index) or entry, 100)
        local amount = math.floor(tonumber(type(entry) == "table" and entry.amount or 1) or 0)
        if item ~= "" and amount > 0 and amount <= 100000 and activeItems[item] and not seen[item] then
            seen[item] = true
            out[#out+1] = { item = item, amount = amount }
        end
    end
    return out
end

function VIP.vehicleCatalogLookup()
    local lookup = {}
    for _,vehicle in ipairs(publicVehicles()) do
        lookup[tostring(vehicle.spawn or ""):lower()] = vehicle
    end
    return lookup
end

function VIP.normalizeVehicles(sourceVehicles)
    local catalog = VIP.vehicleCatalogLookup()
    local out, seen = {}, {}
    for _,entry in ipairs(type(sourceVehicles) == "table" and sourceVehicles or {}) do
        local spawn = VIP.trim(type(entry) == "table" and (entry.spawn or entry.vehicle) or entry, 100):lower()
        local vehicle = catalog[spawn]
        if spawn ~= "" and vehicle and not seen[spawn] then
            seen[spawn] = true
            out[#out+1] = {
                spawn = spawn,
                name = tostring(vehicle.name or spawn),
                category = tostring(vehicle.category or "game")
            }
        end
    end
    return out
end

function VIP.packageFor(group)
    local stored = type(VIP.packagesStore.packages[group]) == "table" and VIP.packagesStore.packages[group] or {}
    return {
        group = group,
        items = VIP.normalizeItems(stored.items),
        vehicles = VIP.normalizeVehicles(stored.vehicles),
        vehicleChoices = math.max(0, math.floor(tonumber(stored.vehicleChoices) or 0)),
        -- Quantidade de vagas ADICIONAIS que este VIP libera na garagem.
        -- O limite base pertence à concessionária (5 por padrão) e cada VIP
        -- ativo soma seu próprio bônus de forma cumulativa.
        garageSlots = math.max(0, math.min(1000, math.floor(tonumber(stored.garageSlots) or 0))),
        updatedAt = tonumber(stored.updatedAt) or 0
    }
end

function VIP.publicAdminData()
    local vips = {}
    for _,entry in ipairs(VIP.managedGroups()) do
        local cfgData = type(entry.config) == "table" and entry.config or {}
        local package = VIP.packageFor(tostring(entry.name or ""))
        package.vehicleChoices = math.min(package.vehicleChoices, #package.vehicles)
        vips[#vips+1] = {
            group = tostring(entry.name or ""),
            title = tostring(cfgData.title or entry.name or "VIP"),
            salary = math.max(0, math.floor(tonumber(cfgData.salario) or 0)),
            permissions = type(entry.permissions) == "table" and entry.permissions or {},
            items = package.items,
            vehicles = package.vehicles,
            vehicleChoices = package.vehicleChoices,
            garageSlots = package.garageSlots,
            durationDays = 30
        }
    end
    return {
        vips = vips,
        items = getItems(),
        vehicles = publicVehicles(),
        images = Config.Images or {},
        durationDays = 30,
        test = { seconds = VIP.testSeconds, radius = VIP.testRadius }
    }
end

function VIP.choicePayload(userId, notice, preferredAssignmentId)
    local record = select(1, VIP.currentAssignment(userId, preferredAssignmentId))
    if type(record) ~= "table" then return nil end
    local remaining = math.max(0, math.floor(tonumber(record.remainingChoices) or 0))
    if remaining <= 0 then return nil end
    return {
        assignmentId = tonumber(record.id) or 0,
        group = tostring(record.group or ""),
        title = tostring(record.title or record.group or "VIP"),
        remainingChoices = remaining,
        totalChoices = math.max(0, math.floor(tonumber(record.totalChoices) or remaining)),
        vehicles = type(record.vehicles) == "table" and record.vehicles or {},
        selectedVehicles = type(record.selectedVehicles) == "table" and record.selectedVehicles or {},
        images = Config.Images or {},
        notice = notice or ""
    }
end

function VIP.endVehicleTest(playerSource, reopen)
    playerSource = tonumber(playerSource)
    local session = playerSource and VIP.tests[playerSource] or nil
    if not session then return nil end
    VIP.tests[playerSource] = nil
    if GetPlayerName(playerSource) then
        SetPlayerRoutingBucket(playerSource, tonumber(session.previousBucket) or 0)
    end
    local userId = tonumber(session.userId)
    return {
        returnPosition = session.returnPosition,
        choice = reopen and userId and VIP.choicePayload(userId, nil, session.assignmentId) or nil
    }
end

function VIP.pushChoice(userId, notice, preferredAssignmentId)
    userId = tonumber(userId)
    if not userId then return false end

    local targetSource = vRP.getUserSource(userId)
    if not targetSource then return false end

    local payload = VIP.choicePayload(userId, notice, preferredAssignmentId)
    if not payload then return false end

    TriggerClientEvent("m_paineladm_v2:vipChoiceOpen", targetSource, payload)
    return true
end

-- O primeiro evento pode ser disparado enquanto o client ainda está concluindo
-- o callback NUI usado para setar o VIP (principalmente quando a staff seta o
-- VIP nela mesma). Reenviamos a escolha em pequenos intervalos, sempre lendo
-- novamente a pendência atual. Se ela já tiver sido concluída, nada é aberto.
function VIP.ensureChoiceVisible(userId, notice, preferredAssignmentId)
    userId = tonumber(userId)
    if not userId then return end

    CreateThread(function()
        local delays = { 0, 450, 1400 }
        for _,delay in ipairs(delays) do
            if delay > 0 then Wait(delay) end

            local targetSource = vRP.getUserSource(userId)
            if not targetSource then return end

            local payload = VIP.choicePayload(userId, notice, preferredAssignmentId)
            if not payload then return end

            -- Durante teste o client ignora abertura de escolha. Fora do teste,
            -- este reenvio garante que a NUI receba o modal mesmo em caso de race.
            TriggerClientEvent("m_paineladm_v2:vipChoiceOpen", targetSource, payload)
        end
    end)
end

function VIP.testBucketFor(playerSource)
    -- Source é único entre jogadores conectados, portanto cada teste simultâneo
    -- recebe uma dimensão própria. O offset alto reduz chance de colisão com
    -- buckets utilizados por outros sistemas da base.
    return 1800000 + math.max(1, math.floor(tonumber(playerSource) or 1))
end

-- Retorna somente o bônus de vagas dos VIPs ativos do jogador. A concessionária
-- continua dona do limite base (5 por padrão) e soma este valor no momento da
-- compra. A checagem é feita por GRUPO VIP exato, evitando somar permissões
-- compartilhadas e permitindo acumular Bronze + Prata + Rubi etc.
function VIP.garageSlotsForUser(userId)
    userId = tonumber(userId)
    if not userId then return 0, {} end

    local total = 0
    local breakdown = {}

    for _,entry in ipairs(VIP.managedGroups()) do
        local groupName = tostring(entry.name or "")
        if groupName ~= "" and vRP.hasGroup(userId, groupName) then
            local package = VIP.packageFor(groupName)
            local slots = math.max(0, math.floor(tonumber(package.garageSlots) or 0))
            if slots > 0 then
                total = total + slots
                breakdown[#breakdown + 1] = {
                    group = groupName,
                    title = tostring((entry.config or {}).title or groupName),
                    slots = slots
                }
            end
        end
    end

    return total, breakdown
end

exports("getVipGarageSlotsForUser", function(userId)
    return VIP.garageSlotsForUser(userId)
end)

exports("getVipGarageSlotsForGroup", function(groupName)
    groupName = VIP.trim(groupName, 80)
    if groupName == "" then return 0 end
    return math.max(0, math.floor(tonumber(VIP.packageFor(groupName).garageSlots) or 0))
end)

VIP.loadStores()

-- Mantém a store do painel sincronizada com a expiração nativa da vRP e fecha
-- qualquer seletor/teste caso o VIP seja removido por outro sistema.
CreateThread(function()
    while true do
        Wait(30000)
        local changed = false
        local affectedUsers = {}

        for userIdKey,bucket in pairs(VIP.assignmentsStore.active) do
            local userId = tonumber(userIdKey)
            if userId and type(bucket) == "table" then
                -- getUserDataTable da vRP só existe para jogadores carregados.
                -- Portanto nunca descartamos escolhas de quem está offline; elas
                -- permanecem persistidas e são validadas assim que o player voltar.
                local targetSource = vRP.getUserSource(userId)
                if targetSource then
                    for assignmentKey,record in pairs(bucket) do
                        local stillHasVip = vRP.hasGroup(userId, tostring(record.group or ""))
                        if not stillHasVip then
                            if VIP.tests[targetSource] and tonumber(VIP.tests[targetSource].assignmentId) == tonumber(record.id) then
                                local ended = VIP.endVehicleTest(targetSource, false)
                                if ended and ended.returnPosition then
                                    TriggerClientEvent("m_paineladm_v2:vipTestForceStop", targetSource, ended.returnPosition)
                                end
                            end
                            bucket[assignmentKey] = nil
                            affectedUsers[userId] = true
                            changed = true
                        end
                    end
                    if next(bucket) == nil then VIP.assignmentsStore.active[userIdKey] = nil end
                end
            end
        end

        if changed then
            VIP.saveAssignments()
            for userId in pairs(affectedUsers) do
                local targetSource = vRP.getUserSource(userId)
                if targetSource then
                    local payload = VIP.choicePayload(userId, "Um dos seus VIPs expirou ou foi removido.")
                    if payload then
                        TriggerClientEvent("m_paineladm_v2:vipChoiceOpen", targetSource, payload)
                    else
                        TriggerClientEvent("m_paineladm_v2:vipChoiceClose", targetSource, "Seu VIP expirou ou foi removido.")
                    end
                end
            end
        end
    end
end)

-- ============================================================================
-- CLIMA / HORÁRIO GLOBAL
-- ============================================================================
local weatherConfig = Config.Weather or {}
local environmentState = {
    weather = tostring(weatherConfig.default or "CLEAR"):upper(),
    weatherFrozen = weatherConfig.defaultWeatherFrozen ~= false,
    rotating = false,
    hour = math.max(0, math.min(23, math.floor(tonumber(weatherConfig.defaultHour) or 12))),
    minute = math.max(0, math.min(59, math.floor(tonumber(weatherConfig.defaultMinute) or 0))),
    timeFrozen = weatherConfig.defaultTimeFrozen == true,
    weatherRevision = 1,
    stateRevision = 1,
    transition = false,
    transitionSeconds = tonumber(weatherConfig.transitionSeconds) or 30.0
}

local validWeather = {}
for _, entry in ipairs(weatherConfig.types or {}) do
    if type(entry) == "table" and entry.name then
        validWeather[tostring(entry.name):upper()] = true
    end
end

local rotationList = weatherConfig.rotation or { "CLEAR", "CLOUDS", "OVERCAST", "RAIN", "CLEARING", "EXTRASUNNY" }
local rotationIndex = 1

local function encodeEnvironmentState()
    local payload = {
        weather = environmentState.weather,
        weatherFrozen = environmentState.weatherFrozen,
        rotating = environmentState.rotating,
        hour = environmentState.hour,
        minute = environmentState.minute,
        timeFrozen = environmentState.timeFrozen
    }

    local ok, encoded = pcall(json.encode, payload)
    if not ok or not encoded then
        return nil
    end
    return encoded
end

local function saveEnvironmentState()
    local encoded = encodeEnvironmentState()
    if not encoded then
        print(("^1[%s] Não foi possível codificar o estado de clima/horário.^7"):format(GetCurrentResourceName()))
        return false
    end

    -- KVP é a persistência principal: sobrevive a restart do resource e não depende
    -- de manter um arquivo específico ao atualizar a pasta do script.
    if type(SetResourceKvp) == "function" then
        SetResourceKvp(STORAGE.environmentKvp, encoded)
    end

    -- JSON é mantido como backup legível dentro do resource.
    SaveResourceFile(GetCurrentResourceName(), STORAGE.environmentFile, encoded, -1)
    return true
end

local function applyEnvironmentState(decoded)
    if type(decoded) ~= "table" then return false end

    local weather = tostring(decoded.weather or environmentState.weather):upper()
    if validWeather[weather] then
        environmentState.weather = weather
    end

    local hour = tonumber(decoded.hour)
    local minute = tonumber(decoded.minute)
    if hour then
        environmentState.hour = math.max(0, math.min(23, math.floor(hour)))
    end
    if minute then
        environmentState.minute = math.max(0, math.min(59, math.floor(minute)))
    end

    if type(decoded.weatherFrozen) == "boolean" then
        environmentState.weatherFrozen = decoded.weatherFrozen
    end
    if type(decoded.rotating) == "boolean" then
        environmentState.rotating = decoded.rotating
    end
    if type(decoded.timeFrozen) == "boolean" then
        environmentState.timeFrozen = decoded.timeFrozen
    end

    -- O modo rotativo e o clima congelado são mutuamente exclusivos.
    if environmentState.rotating then
        environmentState.weatherFrozen = false
    end

    for index, weatherName in ipairs(rotationList) do
        if tostring(weatherName):upper() == environmentState.weather then
            rotationIndex = index
            break
        end
    end

    return true
end

local function decodeEnvironment(raw)
    if not raw or raw == "" then return nil end
    local ok, decoded = pcall(json.decode, raw)
    if ok and type(decoded) == "table" then
        return decoded
    end
    return nil
end

local function loadEnvironmentState()
    -- 1) KVP: fonte principal e resistente a substituição de arquivos do resource.
    if type(GetResourceKvpString) == "function" then
        local decoded = decodeEnvironment(GetResourceKvpString(STORAGE.environmentKvp))
        if decoded and applyEnvironmentState(decoded) then
            return true, "KVP"
        end
    end

    -- 2) JSON: fallback/backup local.
    local raw = LoadResourceFile(GetCurrentResourceName(), STORAGE.environmentFile)
    local decoded = decodeEnvironment(raw)
    if decoded and applyEnvironmentState(decoded) then
        return true, "JSON"
    end

    if raw and raw ~= "" then
        print(("^1[%s] environment_state.json inválido; ignorando backup.^7"):format(GetCurrentResourceName()))
    end

    -- 3) Migração da V2.23: durante um `restart`, o GlobalState anterior pode ainda
    -- estar disponível. Isso evita até o primeiro restart após instalar esta versão.
    local previous = GlobalState.mageAdminEnvironment
    if type(previous) == "table" and applyEnvironmentState(previous) then
        return true, "GlobalState"
    end

    return false, "Config"
end

local restoredEnvironment, restoreSource = loadEnvironmentState()
if restoredEnvironment then
    print(("^2[%s] Clima/horário restaurados (%s): %s | %02d:%02d.^7"):format(
        GetCurrentResourceName(),
        restoreSource or "persistência",
        environmentState.weather,
        environmentState.hour,
        environmentState.minute
    ))
    -- Garante que qualquer fallback/migração já fique salvo nas duas persistências.
    saveEnvironmentState()
end

local function publicEnvironment()
    return {
        weather = environmentState.weather,
        weatherFrozen = environmentState.weatherFrozen,
        rotating = environmentState.rotating,
        hour = environmentState.hour,
        minute = environmentState.minute,
        timeFrozen = environmentState.timeFrozen,
        weatherRevision = environmentState.weatherRevision,
        stateRevision = environmentState.stateRevision,
        transition = environmentState.transition,
        transitionSeconds = environmentState.transitionSeconds
    }
end

local function publishEnvironment(weatherChanged, transition)
    environmentState.stateRevision = environmentState.stateRevision + 1
    environmentState.transition = transition == true
    if weatherChanged then
        environmentState.weatherRevision = environmentState.weatherRevision + 1
    end

    local public = publicEnvironment()
    GlobalState.mageAdminEnvironment = public
    -- Compatibilidade com a m_hud: ela ainda usa GlobalState.time para regras visuais.
    GlobalState.time = { environmentState.hour, environmentState.minute }
    TriggerClientEvent("m_paineladm_v2:environmentSync", -1, public)
end

-- Publica o estado restaurado; na primeira execução usa os padrões de Config.Weather.
publishEnvironment(true, false)

-- O client solicita explicitamente o estado ao terminar de entrar no servidor.
-- Não dependemos apenas do momento em que o GlobalState replica, porque isso podia
-- deixar um jogador com o clima local do GTA até a próxima alteração manual.
RegisterNetEvent("m_paineladm_v2:requestEnvironmentSync")
AddEventHandler("m_paineladm_v2:requestEnvironmentSync", function()
    local playerSource = source
    if not playerSource or playerSource <= 0 then return end
    TriggerClientEvent("m_paineladm_v2:environmentSync", playerSource, publicEnvironment())
end)

-- Reenvio periódico do estado oficial. Não altera revision nem grava em disco; é
-- apenas uma redundância de sincronização para joins, respawns e clients que tenham
-- sofrido interferência local de outro estado de clima.
CreateThread(function()
    local interval = math.max(5000, math.floor(tonumber(weatherConfig.serverResyncEveryMs) or 15000))
    while true do
        Wait(interval)
        TriggerClientEvent("m_paineladm_v2:environmentSync", -1, publicEnvironment())
    end
end)

CreateThread(function()
    local waitMs = math.max(1000, math.floor(tonumber(weatherConfig.timeAdvanceEveryMs) or 10000))
    local advance = math.max(1, math.floor(tonumber(weatherConfig.timeAdvanceMinutes) or 2))

    while true do
        Wait(waitMs)
        if not environmentState.timeFrozen then
            local total = ((environmentState.hour * 60) + environmentState.minute + advance) % 1440
            environmentState.hour = math.floor(total / 60)
            environmentState.minute = total % 60
            publishEnvironment(false, false)
        end
    end
end)

CreateThread(function()
    local interval = math.max(1, tonumber(weatherConfig.rotationIntervalMinutes) or 5) * 60 * 1000
    while true do
        Wait(interval)
        if environmentState.rotating and #rotationList > 0 then
            rotationIndex = rotationIndex + 1
            if rotationIndex > #rotationList then rotationIndex = 1 end
            local nextWeather = tostring(rotationList[rotationIndex] or "CLEAR"):upper()
            if validWeather[nextWeather] then
                environmentState.weather = nextWeather
                publishEnvironment(true, true)
                saveEnvironmentState()
            end
        end
    end
end)

-- Persistência adicional: mantém o relógio recente mesmo em encerramentos inesperados.
CreateThread(function()
    local persistEveryMs = math.max(10000, math.floor(tonumber(weatherConfig.persistEveryMs) or 60000))
    while true do
        Wait(persistEveryMs)
        saveEnvironmentState()
    end
end)

-- Em `restart m_paineladm_v2`, salva o estado exato antes do resource parar.
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        saveEnvironmentState()
    end
end)

local ACTION_LABELS = {
    wladd = "Liberar whitelist",
    wlrem = "Remover whitelist",
    god = "Reviver jogador",
    godall = "Reviver todos",
    kill = "Matar jogador",
    ban = "Banir jogador",
    unban = "Desbanir jogador",
    kick = "Expulsar jogador",
    give_veh = "Adicionar veículo",
    rem_veh = "Remover veículo",
    freeze = "Congelar jogador",
    unfreeze = "Descongelar jogador",
    send_dm = "Mensagem privada",
    send_adm = "Aviso geral",
    warning = "Advertência",
    needs_manage = "Gerenciar fome e sede",
    delete_warning = "Excluir advertência",
    wipe_user_data = "Limpar Dados ID",
    catch_rg = "Consultar RG",
    givemoney = "Adicionar dinheiro",
    remove_money = "Remover dinheiro",
    give_item = "Adicionar item",
    spawn_self_item = "Spawnar item para si",
    spawn_weapon = "Puxar arma + munição",
    remove_item = "Remover item",
    clear_inv = "Limpar inventário",
    clear_weapons = "Limpar armas",
    spawn_veh = "Spawnar veículo",
    add_vehicle_catalog = "Adicionar veículo ao catálogo",
    fix = "Reparar veículo",
    tuning = "Tunar veículo",
    tptome = "Puxar jogador",
    tpto = "Ir até jogador",
    tpway = "Teleportar ao waypoint",
    tpcds = "Teleportar para coordenadas",
    hash = "Consultar hash do veículo",
    dv = "Deletar veículo",
    clear_allveh = "Limpar veículos",
    clear_props = "Limpar props",
    set_group = "Adicionar cargo",
    remove_group = "Remover cargo",
    add_location = "Cadastrar teleporte",
    weather_manage = "Alterar clima",
    time_manage = "Alterar horário",
    panel_permissions = "Editar permissões do painel",
    edit_identity = "Editar identidade",
    edit_identity_balance = "Editar carteira e banco",
    change_user_id = "Alterar Passaporte / ID",
    map_screen = "Ver tela do jogador",
    calls_accept = "Aceitar chamado Staff",
    calls_finish = "Finalizar chamado Staff"
}

local function trim(value)
    if value == nil then return "" end
    return tostring(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function clampString(value, maxLen)
    value = trim(value)
    maxLen = tonumber(maxLen) or 80
    if #value > maxLen then
        value = value:sub(1, maxLen)
    end
    return value
end

local function toInt(value)
    local number = tonumber(value)
    if not number then return nil end
    number = math.floor(number)
    if number < 1 then return nil end
    return number
end

local function hasAnyPermission(userId, permissions)
    if not userId or type(permissions) ~= "table" then return false end
    for _, permission in ipairs(permissions) do
        if vRP.hasPermission(userId, permission) then
            return true
        end
    end
    return false
end

local panelPermissionDefinitions = {}
for _, definition in ipairs(ServerConfig.PanelPermissionDefinitions or {}) do
    if type(definition) == "table" and definition.key then
        panelPermissionDefinitions[tostring(definition.key)] = definition
    end
end

local function getPanelRole(userId)
    if not userId then return nil end

    local groups = vRP.getUserGroups(userId) or {}
    local ordered = { "dono", "developer", "admin", "moderador", "suporte" }
    for _, role in ipairs(ordered) do
        if groups[role] then
            return role
        end
    end

    -- Compatibilidade com bases em que o grupo administrativo possui outro nome,
    -- mas mantém as permissões antigas já usadas pelo painel.
    if vRP.hasPermission(userId, "developer.permissao") then
        return "developer"
    end
    if vRP.hasPermission(userId, "admin.permissao") then
        return "admin"
    end

    return nil
end

local function isPermissionManager(userId)
    if not userId then return false end
    local groups = vRP.getUserGroups(userId) or {}
    return groups.dono ~= nil or groups.developer ~= nil
end

local function defaultRoleValue(role)
    if role == "dono" or role == "developer" then return true end
    return ServerConfig.DefaultPanelRoleAccess and ServerConfig.DefaultPanelRoleAccess[role] == true or false
end

local function normalizePanelPermissions(input)
    local output = {}
    input = type(input) == "table" and input or {}

    for key in pairs(panelPermissionDefinitions) do
        local saved = type(input[key]) == "table" and input[key] or {}
        local function savedRole(role)
            if type(saved[role]) == "boolean" then
                return saved[role]
            end
            return defaultRoleValue(role)
        end

        output[key] = {
            dono = true,
            developer = true,
            admin = savedRole("admin"),
            moderador = savedRole("moderador"),
            suporte = savedRole("suporte")
        }
    end

    return output
end

local function encodePanelPermissions()
    local ok, encoded = pcall(json.encode, panelPermissions)
    if not ok then return nil end
    return encoded
end

local function savePanelPermissions()
    local encoded = encodePanelPermissions()
    if not encoded then return false end

    if type(SetResourceKvp) == "function" then
        SetResourceKvp(STORAGE.panelPermissionsKvp, encoded)
    end
    SaveResourceFile(GetCurrentResourceName(), STORAGE.panelPermissionsFile, encoded, -1)
    return true
end

local function decodePanelPermissions(raw)
    if not raw or raw == "" then return nil end
    local ok, decoded = pcall(json.decode, raw)
    if ok and type(decoded) == "table" then return decoded end
    return nil
end

local function loadPanelPermissions()
    local decoded = nil
    if type(GetResourceKvpString) == "function" then
        decoded = decodePanelPermissions(GetResourceKvpString(STORAGE.panelPermissionsKvp))
    end
    if not decoded then
        decoded = decodePanelPermissions(LoadResourceFile(GetCurrentResourceName(), STORAGE.panelPermissionsFile))
    end

    panelPermissions = normalizePanelPermissions(decoded)
    savePanelPermissions()
end

loadPanelPermissions()

local function canOpen(userId)
    return getPanelRole(userId) ~= nil or hasAnyPermission(userId, ServerConfig.OpenPermissions)
end

local panelActionParents = {
    wladd = { "view_server" }, wlrem = { "view_server" }, unban = { "view_server" }, ban_history = { "view_server" },
    send_adm = { "view_server" }, tpway = { "view_server" }, tpcds = { "view_server" },
    warning = { "view_server", "view_players" },
    needs_manage = { "view_server" },
    radio_manage = { "view_radio" },
    delete_warning = { "view_warnings" },
    wipe_user_data = { "view_server" },
    godall = { "view_server" }, clear_allveh = { "view_server" }, clear_props = { "view_server" },

    tpto = { "view_players", "view_map" }, tptome = { "view_players", "view_map" }, god = { "view_players" },
    kill = { "view_players" }, freeze = { "view_players", "view_map" }, unfreeze = { "view_players" },
    kick = { "view_players" }, ban = { "view_players", "view_server" }, clear_weapons = { "view_players" },
    inspect_inventory = { "view_players" }, give_item = { "view_players" },
    remove_item = { "view_players" }, clear_inv = { "view_players" },

    set_group = { "view_groups" }, remove_group = { "view_groups" },
    edit_identity = { "view_identity_editor" }, edit_identity_balance = { "view_identity_editor" }, change_user_id = { "view_identity_editor" },
    spawn_self_item = { "view_items" },
    spawn_weapon = { "view_weapons" },

    spawn_veh = { "view_vehicles" }, add_vehicle_catalog = { "view_vehicles" },
    give_veh = { "view_vehicles" }, rem_veh = { "view_vehicles" },
    tuning = { "view_vehicles" },

    add_location = { "view_locations" }, teleport_location = { "view_locations" },
    weather_manage = { "view_climate" }, time_manage = { "view_climate" },
    map_screen = { "view_map" },

    calls_accept = { "view_calls" }, calls_finish = { "view_calls" },
    calls_history = { "view_calls" }, calls_ranking = { "view_calls" },
    calls_evaluations = { "view_calls" }, calls_staff_notes = { "view_calls" },

    -- Ações reutilizadas em mais de uma aba: basta uma das abas estar liberada.
    catch_rg = { "view_server", "view_players" }, send_dm = { "view_server", "view_players" },
    givemoney = { "view_server", "view_players" }, remove_money = { "view_server", "view_players" },
    fix = { "view_server", "view_vehicles" }, hash = { "view_server", "view_vehicles" },
    dv = { "view_server", "view_vehicles" }
}

local function rawRolePermission(role, key)
    if role == "dono" or role == "developer" then return true end
    local permissions = panelPermissions[tostring(key)]
    return permissions and permissions[role] == true or false
end

local function canUseAction(userId, action)
    local role = getPanelRole(userId)
    if not role then return false end
    if role == "dono" or role == "developer" then return true end

    action = tostring(action)
    if not rawRolePermission(role, action) then return false end

    local parents = panelActionParents[action]
    if not parents or #parents == 0 or action:sub(1, 5) == "view_" then
        return true
    end

    for _, parent in ipairs(parents) do
        if rawRolePermission(role, parent) then return true end
    end
    return false
end

local function buildPermissionPayload(userId)
    local role = getPanelRole(userId)
    local canManage = isPermissionManager(userId)
    local allowedActions = {}

    for key in pairs(panelPermissionDefinitions) do
        allowedActions[key] = canUseAction(userId, key)
    end

    -- Webhooks são credenciais sensíveis. A aba Logs só é exposta para Dono e
    -- Developer, mesmo que uma configuração antiga de permissões tente liberá-la.
    allowedActions.view_logs = isPermissionManager(userId)

    -- Operação crítica não configurável: só Dono e Developer enxergam e usam.
    -- Ela não entra no gerenciador de permissões para evitar liberação acidental
    -- para Admin/Moderador/Suporte. A validação é repetida no servidor.
    allowedActions.wipe_user_data = role == "dono" or role == "developer"

    local definitions = {}
    if canManage then
        for _, definition in ipairs(ServerConfig.PanelPermissionDefinitions or {}) do
            local key = tostring(definition.key)
            definitions[#definitions + 1] = {
                key = key,
                label = tostring(definition.label or key),
                category = tostring(definition.category or "Outros"),
                roles = {
                    dono = true,
                    developer = true,
                    admin = panelPermissions[key] and panelPermissions[key].admin == true or false,
                    moderador = panelPermissions[key] and panelPermissions[key].moderador == true or false,
                    suporte = panelPermissions[key] and panelPermissions[key].suporte == true or false
                }
            }
        end
    end

    return {
        role = role,
        canManage = canManage,
        allowedActions = allowedActions,
        definitions = definitions,
        roleLabels = ServerConfig.PanelRoleLabels or {}
    }
end

local function pushPermissionStateToStaff()
    for userId, playerSource in pairs(vRP.getUsers() or {}) do
        userId = tonumber(userId)
        if userId and canOpen(userId) then
            TriggerClientEvent("m_paineladm_v2:permissionsUpdated", playerSource, buildPermissionPayload(userId))
        end
    end
end

local function notify(playerSource, kind, message, duration)
    if playerSource then
        TriggerClientEvent("Notify", playerSource, kind or "aviso", message or "", duration or 7000)
    end
end

local function result(ok, message, data)
    return {
        ok = ok == true,
        message = message or "",
        data = data
    }
end

local function getIdentity(userId)
    userId = tonumber(userId)

    -- v2.65: o banco é SEMPRE a fonte principal para a aba Jogadores.
    -- Isso impede que qualquer cache antigo (do próprio painel ou de
    -- vRP.getUserIdentity) faça o jogador continuar aparecendo com nome antigo.
    local identity = nil

    if userId and type(identityRow) == "function" then
        local ok, fresh = pcall(identityRow, userId)
        if ok and type(fresh) == "table" then
            identity = {
                nome = fresh.nome or "",
                sobrenome = fresh.sobrenome or "",
                idade = fresh.idade or "",
                telefone = fresh.telefone or "",
                registro = fresh.registro or ""
            }
            liveIdentityOverrides[userId] = identity
        end
    end

    -- Fallback somente se a consulta direta ao banco estiver indisponível.
    if not identity and userId then
        identity = liveIdentityOverrides[userId]
    end

    if not identity and userId then
        identity = vRP.getUserIdentity(userId)
    end

    if not identity then
        return {
            nome = "Sem",
            sobrenome = "Identidade",
            idade = "-",
            telefone = "-",
            registro = "-"
        }
    end

    return {
        nome = identity.nome or identity.name or "Sem",
        sobrenome = identity.sobrenome or identity.firstname or identity.name2 or "Identidade",
        idade = identity.idade or identity.age or "-",
        telefone = identity.telefone or identity.phone or "-",
        registro = identity.registro or identity.registration or "-"
    }
end

local function getFullName(userId)
    local identity = getIdentity(userId)
    return (tostring(identity.nome) .. " " .. tostring(identity.sobrenome)):gsub("%s+", " ")
end

local function normalizeBanHistoryStore(raw)
    local store = type(raw) == "table" and raw or {}
    local entries = type(store.entries) == "table" and store.entries or {}
    local nextId = math.max(1, math.floor(tonumber(store.nextId) or 1))
    local maxId = 0

    for _, entry in ipairs(entries) do
        maxId = math.max(maxId, tonumber(entry.id) or 0)
    end
    if nextId <= maxId then nextId = maxId + 1 end

    return { nextId = nextId, entries = entries }
end

local function loadBanHistoryStore()
    local raw = LoadResourceFile(GetCurrentResourceName(), STORAGE.banHistoryFile)
    if raw and raw ~= "" then
        local ok, decoded = pcall(json.decode, raw)
        if ok then banHistoryStore = normalizeBanHistoryStore(decoded) end
    end
end

local function saveBanHistoryStore()
    local ok, encoded = pcall(json.encode, banHistoryStore)
    if ok and encoded then
        SaveResourceFile(GetCurrentResourceName(), STORAGE.banHistoryFile, encoded, -1)
    end
end

local function addBanHistoryEntry(action, actorId, targetId, reason)
    local entryId = banHistoryStore.nextId
    banHistoryStore.nextId = entryId + 1

    banHistoryStore.entries[#banHistoryStore.entries + 1] = {
        id = entryId,
        action = action == "unban" and "unban" or "ban",
        actor = {
            id = tonumber(actorId) or 0,
            name = getFullName(actorId)
        },
        target = {
            id = tonumber(targetId) or 0,
            name = getFullName(targetId)
        },
        reason = tostring(reason or ""),
        timestamp = os.time(),
        date = os.date("%d/%m/%Y"),
        time = os.date("%H:%M:%S")
    }

    saveBanHistoryStore()
end

loadBanHistoryStore()

-- ============================================================================
-- SISTEMA DE ADVERTÊNCIAS / CASTIGO
-- ============================================================================
-- As advertências ficam persistidas em JSON. O castigo ativo também é salvo,
-- portanto sair/reentrar ou reiniciar apenas este resource não remove o tempo.
local PUNISHMENT_CENTER = { x = 4501.22, y = -4546.93, z = 4.03 }
local PUNISHMENT_RELEASE = { x = 82.82, y = -854.72, z = 30.77 }
local PUNISHMENT_RADIUS = 10.0

local function normalizeWarningStore(raw)
    raw = type(raw) == "table" and raw or {}
    local output = { nextId = math.max(1, math.floor(tonumber(raw.nextId) or 1)), counts = {}, active = {}, history = {} }
    local usedIds = {}
    local maxId = 0

    if type(raw.history) == "table" then
        for _, rawEntry in ipairs(raw.history) do
            if type(rawEntry) == "table" then
                local targetId = tonumber(rawEntry.targetId or rawEntry.userId)
                if targetId and targetId > 0 then
                    local entryId = math.floor(tonumber(rawEntry.id) or 0)
                    if entryId <= 0 or usedIds[entryId] then
                        entryId = maxId + 1
                        while usedIds[entryId] do entryId = entryId + 1 end
                    end
                    usedIds[entryId] = true
                    maxId = math.max(maxId, entryId)

                    local startedAt = math.floor(tonumber(rawEntry.startedAt or rawEntry.timestamp) or os.time())
                    local minutes = math.max(1, math.floor(tonumber(rawEntry.minutes) or 1))
                    local endsAt = math.floor(tonumber(rawEntry.endsAt) or (startedAt + minutes * 60))
                    local reason = trim(rawEntry.reason)
                    if reason == "" then reason = "Sem motivo registrado (advertência antiga)." end

                    output.history[#output.history + 1] = {
                        id = entryId,
                        targetId = math.floor(targetId),
                        targetName = tostring(rawEntry.targetName or ""),
                        targetSurname = tostring(rawEntry.targetSurname or ""),
                        actorId = math.floor(tonumber(rawEntry.actorId) or 0),
                        actorName = tostring(rawEntry.actorName or ""),
                        reason = reason,
                        minutes = minutes,
                        startedAt = startedAt,
                        endsAt = endsAt,
                        date = tostring(rawEntry.date or os.date("%d/%m/%Y", startedAt)),
                        time = tostring(rawEntry.time or os.date("%H:%M:%S", startedAt))
                    }
                end
            end
        end
    end

    -- A contagem passa a ser derivada do histórico. Assim, ao excluir uma
    -- advertência, o número exibido nunca fica divergente do que existe na aba.
    for _, entry in ipairs(output.history) do
        local key = tostring(entry.targetId)
        output.counts[key] = (output.counts[key] or 0) + 1
    end

    if type(raw.active) == "table" then
        for userId, record in pairs(raw.active) do
            local id = tonumber(userId)
            if id and id > 0 and type(record) == "table" then
                local endsAt = math.floor(tonumber(record.endsAt) or 0)
                if endsAt > 0 then
                    local warningId = math.floor(tonumber(record.warningId) or 0)
                    if warningId <= 0 then
                        -- Migração das advertências criadas na v2.72: associa o
                        -- castigo ativo ao registro histórico correspondente.
                        for i = #output.history, 1, -1 do
                            local entry = output.history[i]
                            if tonumber(entry.targetId) == id and math.abs((tonumber(entry.startedAt) or 0) - (tonumber(record.startedAt) or 0)) <= 2 then
                                warningId = tonumber(entry.id) or 0
                                break
                            end
                        end
                    end
                    output.active[tostring(id)] = {
                        warningId = warningId > 0 and warningId or nil,
                        endsAt = endsAt,
                        startedAt = math.floor(tonumber(record.startedAt) or os.time()),
                        minutes = math.max(1, math.floor(tonumber(record.minutes) or 1)),
                        actorId = math.floor(tonumber(record.actorId) or 0),
                        reason = trim(record.reason),
                        bucket = math.floor(tonumber(record.bucket) or (50000 + id))
                    }
                end
            end
        end
    end

    output.nextId = math.max(output.nextId, maxId + 1)
    return output
end

local function saveWarningStore()
    local ok, encoded = pcall(json.encode, warningStore)
    if ok and encoded then
        SaveResourceFile(GetCurrentResourceName(), STORAGE.warningsFile, encoded, -1)
        return true
    end
    return false
end

local function loadWarningStore()
    local raw = LoadResourceFile(GetCurrentResourceName(), STORAGE.warningsFile)
    if raw and raw ~= "" then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == "table" then
            warningStore = normalizeWarningStore(decoded)
        end
    end
    saveWarningStore()
end

local function getWarningCount(userId)
    userId = tonumber(userId)
    if not userId then return 0 end
    return math.max(0, math.floor(tonumber(warningStore.counts[tostring(userId)]) or 0))
end


local function warningIdentity(userId)
    local identity = getIdentity(tonumber(userId))
    return {
        nome = tostring(identity and identity.nome or "Sem"),
        sobrenome = tostring(identity and identity.sobrenome or "Identidade")
    }
end

local function warningSummaryPayload()
    local byPlayer = {}

    for _, entry in ipairs(warningStore.history or {}) do
        local targetId = tonumber(entry.targetId)
        if targetId then
            local key = tostring(targetId)
            if not byPlayer[key] then
                local identity = warningIdentity(targetId)
                byPlayer[key] = {
                    id = targetId,
                    nome = identity.nome,
                    sobrenome = identity.sobrenome,
                    count = 0,
                    latestAt = 0,
                    active = warningStore.active[key] ~= nil
                }
            end
            local row = byPlayer[key]
            row.count = row.count + 1
            row.latestAt = math.max(row.latestAt or 0, tonumber(entry.startedAt) or 0)
            row.active = warningStore.active[key] ~= nil
        end
    end

    local players = {}
    local totalWarnings = 0
    for _, row in pairs(byPlayer) do
        totalWarnings = totalWarnings + (tonumber(row.count) or 0)
        players[#players + 1] = row
    end

    table.sort(players, function(a, b)
        if (a.latestAt or 0) ~= (b.latestAt or 0) then return (a.latestAt or 0) > (b.latestAt or 0) end
        return (a.id or 0) < (b.id or 0)
    end)

    return {
        players = players,
        totalWarnings = totalWarnings,
        totalPlayers = #players
    }
end

local function warningDetailPayload(userId)
    userId = tonumber(userId)
    if not userId then return nil end

    local identity = warningIdentity(userId)
    local entries = {}
    for i = #(warningStore.history or {}), 1, -1 do
        local entry = warningStore.history[i]
        if tonumber(entry.targetId) == userId then
            entries[#entries + 1] = {
                id = tonumber(entry.id) or 0,
                targetId = userId,
                actorId = tonumber(entry.actorId) or 0,
                actorName = tostring(entry.actorName or ""),
                reason = tostring(entry.reason or "Sem motivo registrado."),
                minutes = tonumber(entry.minutes) or 0,
                startedAt = tonumber(entry.startedAt) or 0,
                endsAt = tonumber(entry.endsAt) or 0,
                date = tostring(entry.date or ""),
                time = tostring(entry.time or ""),
                active = warningStore.active[tostring(userId)] ~= nil
                    and tonumber(warningStore.active[tostring(userId)].warningId) == tonumber(entry.id)
            }
        end
    end

    return {
        id = userId,
        nome = identity.nome,
        sobrenome = identity.sobrenome,
        count = #entries,
        active = warningStore.active[tostring(userId)] ~= nil,
        entries = entries
    }
end

local function pushWarningStateToStaff()
    local payload = warningSummaryPayload()
    for userId, playerSource in pairs(vRP.getUsers() or {}) do
        userId = tonumber(userId)
        playerSource = tonumber(playerSource)
        if userId and playerSource and canOpen(userId) and canUseAction(userId, "view_warnings") then
            TriggerClientEvent("m_paineladm_v2:warningsLiveUpdated", playerSource, payload)
        end
    end
end

local function punishmentBucketFor(userId)
    userId = math.max(1, math.floor(tonumber(userId) or 1))
    return 50000 + userId
end

local function applyPunishmentToSource(userId, targetSource, record)
    userId = tonumber(userId)
    targetSource = tonumber(targetSource)
    record = type(record) == "table" and record or warningStore.active[tostring(userId)]

    if not userId or not targetSource or not record then return false end

    local remaining = math.max(0, math.floor((tonumber(record.endsAt) or 0) - os.time()))
    if remaining <= 0 then return false end

    local bucket = math.floor(tonumber(record.bucket) or punishmentBucketFor(userId))
    record.bucket = bucket

    SetPlayerRoutingBucket(targetSource, bucket)
    vRPclient._teleport(targetSource, PUNISHMENT_CENTER.x, PUNISHMENT_CENTER.y, PUNISHMENT_CENTER.z)

    TriggerClientEvent("m_paineladm_v2:punishmentStart", targetSource, {
        remainingSeconds = remaining,
        endsAt = tonumber(record.endsAt) or (os.time() + remaining),
        center = PUNISHMENT_CENTER,
        radius = PUNISHMENT_RADIUS
    })

    punishmentAppliedSources[tostring(userId)] = targetSource
    return true
end

local function finishPunishment(userId, teleportOut)
    userId = tonumber(userId)
    if not userId then return end

    local key = tostring(userId)
    warningStore.active[key] = nil
    punishmentAppliedSources[key] = nil
    saveWarningStore()

    local targetSource = vRP.getUserSource(userId)
    if targetSource then
        SetPlayerRoutingBucket(targetSource, 0)
        TriggerClientEvent("m_paineladm_v2:punishmentStop", targetSource)
        if teleportOut ~= false then
            vRPclient._teleport(targetSource, PUNISHMENT_RELEASE.x, PUNISHMENT_RELEASE.y, PUNISHMENT_RELEASE.z)
        end
    end
end

loadWarningStore()

-- Mantém dimensão, raio e expiração sob controle do servidor. O client também
-- verifica o raio com intervalo menor para a correção visual ser imediata.
CreateThread(function()
    while true do
        Wait(1000)
        local now = os.time()

        for userIdKey, record in pairs(warningStore.active) do
            local userId = tonumber(userIdKey)
            if not userId or type(record) ~= "table" or (tonumber(record.endsAt) or 0) <= now then
                if userId then
                    finishPunishment(userId, true)
                else
                    warningStore.active[userIdKey] = nil
                    saveWarningStore()
                end
            else
                local targetSource = vRP.getUserSource(userId)
                if targetSource then
                    local expectedBucket = math.floor(tonumber(record.bucket) or punishmentBucketFor(userId))
                    if GetPlayerRoutingBucket(targetSource) ~= expectedBucket then
                        SetPlayerRoutingBucket(targetSource, expectedBucket)
                    end

                    if tonumber(punishmentAppliedSources[userIdKey]) ~= tonumber(targetSource) then
                        applyPunishmentToSource(userId, targetSource, record)
                    end

                    local ped = GetPlayerPed(targetSource)
                    if ped and ped > 0 then
                        local coords = GetEntityCoords(ped)
                        if coords then
                            local dx = (tonumber(coords.x or coords[1]) or 0.0) - PUNISHMENT_CENTER.x
                            local dy = (tonumber(coords.y or coords[2]) or 0.0) - PUNISHMENT_CENTER.y
                            local dz = (tonumber(coords.z or coords[3]) or 0.0) - PUNISHMENT_CENTER.z
                            if (dx * dx + dy * dy + dz * dz) > (PUNISHMENT_RADIUS * PUNISHMENT_RADIUS) then
                                vRPclient._teleport(targetSource, PUNISHMENT_CENTER.x, PUNISHMENT_CENTER.y, PUNISHMENT_CENTER.z)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Reaplica um castigo persistido quando o personagem entra novamente.
AddEventHandler("vRP:playerSpawn", function(userId, playerSource)
    userId = tonumber(userId)
    playerSource = tonumber(playerSource)
    if not userId or not playerSource then return end

    local record = warningStore.active[tostring(userId)]
    if record then
        CreateThread(function()
            Wait(1500)
            if (tonumber(record.endsAt) or 0) > os.time() then
                applyPunishmentToSource(userId, playerSource, record)
            else
                finishPunishment(userId, true)
            end
        end)
    end
end)


-- Se o jogador saiu antes de terminar as escolhas do VIP, o modal volta
-- automaticamente no próximo spawn sem duplicar itens ou veículos.
AddEventHandler("vRP:playerSpawn", function(userId, playerSource)
    userId = tonumber(userId)
    playerSource = tonumber(playerSource)
    if not userId or not playerSource then return end
    CreateThread(function()
        Wait(3000)
        local payload = VIP.choicePayload(userId)
        if payload and vRP.hasGroup(userId, tostring(payload.group or "")) then
            TriggerClientEvent("m_paineladm_v2:vipChoiceOpen", playerSource, payload)
        end
    end)
end)

-- Se apenas o painel for reiniciado, jogadores que ainda possuem escolha
-- pendente recebem o modal novamente sem precisar relogar.
AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(4000)
        for userId,playerSource in pairs(vRP.getUsers() or {}) do
            userId = tonumber(userId)
            playerSource = tonumber(playerSource)
            if userId and playerSource then
                local payload = VIP.choicePayload(userId)
                if payload and vRP.hasGroup(userId, tostring(payload.group or "")) then
                    TriggerClientEvent("m_paineladm_v2:vipChoiceOpen", playerSource, payload)
                end
            end
        end
    end)
end)

-- Libera temporariamente os routing buckets ao parar o resource. Os registros
-- continuam persistidos e serão reaplicados se o resource voltar antes do fim.
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for playerSource,session in pairs(VIP.tests) do
        if GetPlayerName(playerSource) then
            SetPlayerRoutingBucket(playerSource, tonumber(session.previousBucket) or 0)
            TriggerClientEvent("m_paineladm_v2:vipTestForceStop", playerSource, session.returnPosition)
        end
    end
    VIP.tests = {}

    for userIdKey in pairs(warningStore.active) do
        local userId = tonumber(userIdKey)
        local targetSource = userId and vRP.getUserSource(userId) or nil
        if targetSource then
            SetPlayerRoutingBucket(targetSource, 0)
            TriggerClientEvent("m_paineladm_v2:punishmentStop", targetSource)
        end
    end
end)


-- ============================================================================
-- SISTEMA CENTRAL DE LOGS / WEBHOOKS
-- ============================================================================
-- As webhooks são persistidas somente no servidor. O client recebe as URLs
-- apenas quando um Dono/Developer abre a aba Logs para editá-las.
local logWebhookStore = { webhooks = {} }
local logDefinitionsByKey = {}

local function buildLogDefinitionIndex()
    logDefinitionsByKey = {}
    for _, category in ipairs(ServerConfig.LogCatalog or {}) do
        local categoryLabel = tostring(category.label or category.id or "Logs")
        local function addLogs(logs, subcategoryLabel)
            for _, definition in ipairs(type(logs) == "table" and logs or {}) do
                local key = tostring(definition.key or "")
                if key ~= "" then
                    logDefinitionsByKey[key] = {
                        key = key,
                        name = tostring(definition.name or key),
                        description = tostring(definition.description or "Ação registrada pelo sistema."),
                        category = categoryLabel,
                        subcategory = tostring(subcategoryLabel or categoryLabel)
                    }
                end
            end
        end

        if type(category.subcategories) == "table" and #category.subcategories > 0 then
            for _, subcategory in ipairs(category.subcategories) do
                addLogs(subcategory.logs, subcategory.label or subcategory.id)
            end
        else
            addLogs(category.logs, categoryLabel)
        end
    end
end

local function decodeLogWebhookStore(raw)
    if not raw or raw == "" then return nil end
    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= "table" then return nil end
    local webhooks = type(decoded.webhooks) == "table" and decoded.webhooks or decoded
    local normalized = { webhooks = {} }
    for key, value in pairs(webhooks) do
        key = tostring(key or "")
        value = trim(value)
        if key ~= "" and value ~= "" and logDefinitionsByKey[key] then
            normalized.webhooks[key] = value
        end
    end
    return normalized
end

local function saveLogWebhookStore()
    local ok, encoded = pcall(json.encode, logWebhookStore)
    if not ok or not encoded then return false end
    if type(SetResourceKvp) == "function" then
        SetResourceKvp(STORAGE.logsKvp, encoded)
    end
    return SaveResourceFile(GetCurrentResourceName(), STORAGE.logsFile, encoded, -1) ~= false
end

local function loadLogWebhookStore()
    buildLogDefinitionIndex()
    local decoded = nil
    if type(GetResourceKvpString) == "function" then
        decoded = decodeLogWebhookStore(GetResourceKvpString(STORAGE.logsKvp))
    end
    if not decoded then
        decoded = decodeLogWebhookStore(LoadResourceFile(GetCurrentResourceName(), STORAGE.logsFile))
    end
    logWebhookStore = decoded or { webhooks = {} }
    saveLogWebhookStore()
end

local function normalizeDiscordWebhook(value)
    value = trim(value)
    if value == "" or value:lower() == "none" then return "" end
    if #value > 600 then return nil end

    -- Discord, Canary e PTB usam o mesmo endpoint /api/webhooks/{id}/{token}.
    local valid = value:match("^https://[%w%.%-]*discord%.com/api/webhooks/%d+/[^%s]+$")
        or value:match("^https://[%w%.%-]*discordapp%.com/api/webhooks/%d+/[^%s]+$")
    if not valid then return nil end
    return value
end

local function publicLogCatalog()
    local categories = {}
    local configured = 0
    local total = 0

    for _, category in ipairs(ServerConfig.LogCatalog or {}) do
        local publicCategory = {
            id = tostring(category.id or "category"),
            label = tostring(category.label or category.id or "Logs"),
            description = tostring(category.description or ""),
            logs = {},
            subcategories = {}
        }

        local function publicLogs(logs)
            local rows = {}
            for _, definition in ipairs(type(logs) == "table" and logs or {}) do
                local key = tostring(definition.key or "")
                if key ~= "" then
                    local webhook = tostring(logWebhookStore.webhooks[key] or "")
                    total = total + 1
                    if webhook ~= "" then configured = configured + 1 end
                    rows[#rows + 1] = {
                        key = key,
                        name = tostring(definition.name or key),
                        description = tostring(definition.description or ""),
                        webhook = webhook,
                        configured = webhook ~= ""
                    }
                end
            end
            return rows
        end

        if type(category.subcategories) == "table" and #category.subcategories > 0 then
            for _, subcategory in ipairs(category.subcategories) do
                publicCategory.subcategories[#publicCategory.subcategories + 1] = {
                    id = tostring(subcategory.id or "subcategory"),
                    label = tostring(subcategory.label or subcategory.id or "Logs"),
                    description = tostring(subcategory.description or ""),
                    logs = publicLogs(subcategory.logs)
                }
            end
        else
            publicCategory.logs = publicLogs(category.logs)
        end
        categories[#categories + 1] = publicCategory
    end

    return { categories = categories, configured = configured, total = total }
end

local function safeLogName(userId, explicitName)
    explicitName = trim(explicitName)
    if explicitName ~= "" then return explicitName end
    userId = tonumber(userId)
    if not userId then return "Sistema" end
    local ok, name = pcall(getFullName, userId)
    name = ok and trim(name) or ""
    if name == "" then return "Desconhecido" end
    return name
end

local function truncateDiscord(value, maxLen)
    value = tostring(value or "")
    maxLen = tonumber(maxLen) or 1000
    if #value <= maxLen then return value end
    return value:sub(1, math.max(1, maxLen - 3)) .. "..."
end

local function sendConfiguredLog(logKey, data)
    logKey = tostring(logKey or "")
    data = type(data) == "table" and data or {}
    local definition = logDefinitionsByKey[logKey]
    if not definition then return false, "Log não cadastrado no catálogo." end

    local webhook = tostring(logWebhookStore.webhooks[logKey] or "")
    if webhook == "" then return false, "Webhook não configurada." end

    local actorId = tonumber(data.actorId or data.userId or data.id)
    local actorName = safeLogName(actorId, data.actorName or data.userName or data.name)
    local targetId = tonumber(data.targetId)
    local targetName = targetId and safeLogName(targetId, data.targetName) or nil
    local details = trim(data.details or data.detail or "")
    local occurredAt = tonumber(data.occurredAt) or os.time()
    if occurredAt < 1 then occurredAt = os.time() end

    local description = definition.description
    if details ~= "" then
        description = description .. "\n\n**Detalhes:** " .. details
    end

    -- Cada bloco ocupa uma linha inteira no embed.
    -- Isso evita que o Discord compacte NOME/ID e jogador envolvido lado a lado.
    local actorBlock = ("**Nome:** %s\n**ID:** %s"):format(
        truncateDiscord(actorName, 900),
        actorId and tostring(actorId) or "-"
    )

    local actorFieldName = trim(data.actorLabel or "")
    if actorFieldName == "" then actorFieldName = "QUEM EXECUTOU A AÇÃO" end

    local fields = {
        { name = truncateDiscord(actorFieldName:upper(), 250), value = actorBlock, inline = false }
    }

    if targetId then
        local targetBlock = ("**Nome:** %s\n**ID:** %s"):format(
            truncateDiscord(targetName or "Desconhecido", 900),
            tostring(targetId)
        )
        local targetFieldName = trim(data.targetLabel or "")
        if targetFieldName == "" then targetFieldName = "JOGADOR ENVOLVIDO" end
        fields[#fields + 1] = { name = truncateDiscord(targetFieldName:upper(), 250), value = targetBlock, inline = false }
    end

    fields[#fields + 1] = { name = "DESCRIÇÃO", value = truncateDiscord(description, 1000), inline = false }
    fields[#fields + 1] = { name = "DATA E HORA", value = os.date("%d/%m/%Y às %H:%M:%S", occurredAt), inline = false }

    local payload = {
        username = "Mage Admin • Logs",
        allowed_mentions = { parse = {} },
        embeds = {
            {
                title = truncateDiscord(definition.name:upper(), 250),
                description = ("**%s**  ›  %s"):format(definition.category, definition.subcategory),
                color = 4893183,
                fields = fields,
                footer = { text = "MAGE ADMIN • Sistema padronizado de logs" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", occurredAt)
            }
        }
    }

    PerformHttpRequest(webhook, function(statusCode, responseBody)
        statusCode = tonumber(statusCode) or 0
        if statusCode < 200 or statusCode >= 300 then
            print(("[m_paineladm_v2] Falha ao enviar log '%s' ao Discord. HTTP %s | %s"):format(
                logKey, tostring(statusCode), truncateDiscord(responseBody or "sem resposta", 300)
            ))
        end
    end, "POST", json.encode(payload), { ["Content-Type"] = "application/json" })

    return true
end

-- Compatibilidade interna: todos os pontos antigos continuam chamando webhookLog,
-- mas agora cada chave usa sua própria webhook cadastrada na aba Logs.
local function webhookLog(actorId, action, detail, targetId, options)
    options = type(options) == "table" and options or {}
    options.actorId = actorId
    options.targetId = targetId or options.targetId
    options.details = detail or options.details
    return sendConfiguredLog(action, options)
end

-- Fundação para os próximos scripts que serão ligados ao painel. Use apenas no
-- SERVER do resource integrado: exports["m_paineladm_v2"]:sendLog("chave", {...})
exports("sendLog", function(logKey, data)
    return sendConfiguredLog(logKey, data)
end)

loadLogWebhookStore()

function API.logsAdmin(data)
    local playerSource = source
    local actorId = vRP.getUserId(playerSource)
    if not actorId or not canOpen(actorId) then return result(false, "Sem permissão.") end
    if not isPermissionManager(actorId) then
        return result(false, "Apenas Dono e Developer podem visualizar ou alterar webhooks de logs.")
    end

    data = type(data) == "table" and data or {}
    local mode = tostring(data.mode or "list")

    if mode == "list" then
        return result(true, "Logs carregados.", publicLogCatalog())
    end

    if mode == "save" then
        local incoming = type(data.webhooks) == "table" and data.webhooks or {}
        local changed = 0
        local invalid = {}
        local pending = {}

        -- Primeiro valida o formulário inteiro. Nenhuma URL é aplicada em memória
        -- se existir um campo inválido, evitando salvamento parcial da mesma aba.
        for key, value in pairs(incoming) do
            key = tostring(key or "")
            if logDefinitionsByKey[key] then
                local normalized = normalizeDiscordWebhook(value)
                if normalized == nil then
                    invalid[#invalid + 1] = key
                else
                    pending[key] = normalized
                end
            end
        end

        if #invalid > 0 then
            return result(false, "Uma ou mais webhooks são inválidas. Use uma URL de webhook oficial do Discord.", { invalid = invalid })
        end

        for key, normalized in pairs(pending) do
            if tostring(logWebhookStore.webhooks[key] or "") ~= normalized then changed = changed + 1 end
            if normalized == "" then
                logWebhookStore.webhooks[key] = nil
            else
                logWebhookStore.webhooks[key] = normalized
            end
        end

        if not saveLogWebhookStore() then
            return result(false, "Não foi possível salvar logs_config.json.")
        end

        webhookLog(actorId, "logs_manage", ("%d webhook(s) alterada(s) neste salvamento."):format(changed))
        return result(true, changed == 1 and "1 webhook atualizada." or ("%d webhooks atualizadas."):format(changed), publicLogCatalog())
    end

    return result(false, "Operação de logs inválida.")
end

local function requirePanelAccess(playerSource)
    local userId = vRP.getUserId(playerSource)
    if not userId or not canOpen(userId) then
        notify(playerSource, "negado", "Você não possui permissão para acessar o painel.")
        return nil
    end
    return userId
end

local function requireAction(playerSource, action)
    local userId = vRP.getUserId(playerSource)
    if not userId or not canOpen(userId) or not canUseAction(userId, action) then
        notify(playerSource, "negado", "Você não possui permissão para usar esta opção.")
        return nil
    end
    return userId
end

getPlayers = function()
    local list = {}
    local users = vRP.getUsers()

    for userId, playerSource in pairs(users) do
        local identity = getIdentity(tonumber(userId))
        list[#list + 1] = {
            id = tonumber(userId),
            source = tonumber(playerSource),
            name = (tostring(identity.nome) .. " " .. tostring(identity.sobrenome)):gsub("%s+", " "),
            ping = GetPlayerPing(playerSource) or 0,
            bucket = GetPlayerRoutingBucket(playerSource) or 0,
            warnings = getWarningCount(tonumber(userId))
        }
    end

    table.sort(list, function(a, b)
        return (a.id or 0) < (b.id or 0)
    end)

    return list
end

local function getUserSourceSafe(userId)
    userId = tonumber(userId)
    if not userId then return nil end

    if type(vRP.getUserSource) == "function" then
        local playerSource = vRP.getUserSource(userId)
        if playerSource then return tonumber(playerSource) end
    end

    for id, playerSource in pairs(vRP.getUsers() or {}) do
        if tonumber(id) == userId then
            return tonumber(playerSource)
        end
    end
    return nil
end



-- ============================================================================
-- SISTEMA DE CHAMADOS
-- ============================================================================
local function normalizeCallStore(raw)
    local store = type(raw) == "table" and raw or {}
    local history = type(store.history) == "table" and store.history or {}
    local evaluations = type(store.evaluations) == "table" and store.evaluations or {}
    local nextId = math.max(1, math.floor(tonumber(store.nextId) or 1))
    local maxId = 0
    for _, item in ipairs(history) do maxId = math.max(maxId, tonumber(item.id) or 0) end
    for _, item in ipairs(evaluations) do maxId = math.max(maxId, tonumber(item.callId) or 0) end
    if nextId <= maxId then nextId = maxId + 1 end
    return { nextId = nextId, history = history, evaluations = evaluations }
end

local function loadCallStore()
    local raw = nil
    if type(GetResourceKvpString) == "function" then raw = GetResourceKvpString(STORAGE.callsKvp) end
    if not raw or raw == "" then raw = LoadResourceFile(GetCurrentResourceName(), STORAGE.callsFile) end
    if raw and raw ~= "" then
        local ok, decoded = pcall(json.decode, raw)
        if ok then callStore = normalizeCallStore(decoded) end
    end
end

local function saveCallStore()
    local ok, encoded = pcall(json.encode, callStore)
    if ok and encoded then
        if type(SetResourceKvp) == "function" then SetResourceKvp(STORAGE.callsKvp, encoded) end
        SaveResourceFile(GetCurrentResourceName(), STORAGE.callsFile, encoded, -1)
    end
end

loadCallStore()

local function departmentConfig(department)
    return (ServerConfig.CallDepartments or {})[tostring(department or "")]
end

local function isDepartmentMember(userId, department)
    local config = departmentConfig(department)
    if not userId or not config then return false end
    if department == "staff" then
        return canOpen(userId) and canUseAction(userId, "view_calls")
    end
    return hasAnyPermission(userId, config.permissions or {})
end

local function publicCall(call)
    if type(call) ~= "table" then return nil end
    return {
        id = tonumber(call.id),
        department = tostring(call.department or "staff"),
        departmentLabel = tostring(call.departmentLabel or "Chamado"),
        playerId = tonumber(call.playerId),
        playerName = tostring(call.playerName or "Jogador"),
        message = tostring(call.message or ""),
        status = tostring(call.status or "open"),
        acceptedById = tonumber(call.acceptedById),
        acceptedByName = call.acceptedByName and tostring(call.acceptedByName) or nil,
        createdAt = tonumber(call.createdAt) or os.time(),
        createdAtText = tostring(call.createdAtText or "-")
    }
end

local function pushCallsPanelUpdate()
    for userId, playerSource in pairs(vRP.getUsers() or {}) do
        userId = tonumber(userId)
        if userId and canOpen(userId) and canUseAction(userId, "view_calls") then
            TriggerClientEvent("m_paineladm_v2:callsUpdated", playerSource)
        end
    end
end

local function getDepartmentOnlineCount(department)
    local total = 0
    for userId, playerSource in pairs(vRP.getUsers() or {}) do
        userId = tonumber(userId)
        playerSource = tonumber(playerSource)
        if userId and playerSource and isDepartmentMember(userId, department) then
            -- Confirma que a source ainda existe no servidor antes de considerá-la
            -- como atendente disponível para receber um novo chamado.
            if GetPlayerName(playerSource) ~= nil then
                total = total + 1
            end
        end
    end
    return total
end

local function getDepartmentUnavailableMessage(department)
    local config = departmentConfig(department) or {}
    if config.unavailableMessage and config.unavailableMessage ~= "" then
        return tostring(config.unavailableMessage)
    end

    local fallbacks = {
        staff = "Não há nenhum Staff online no momento.",
        police = "Não há nenhum policial online no momento.",
        mechanic = "Não há nenhum mecânico online no momento.",
        hospital = "Não há nenhum médico online no momento."
    }
    return fallbacks[tostring(department or "")] or "Não há ninguém deste setor online no momento."
end

local function removeOrphanOpenCall(playerId, department)
    local changed = false
    for callId, existing in pairs(activeCalls) do
        if tonumber(existing.playerId) == tonumber(playerId)
            and existing.department == department
            and existing.status == "open" then
            activeCalls[callId] = nil
            changed = true
        end
    end

    if changed and department == "staff" then
        pushCallsPanelUpdate()
    end
    return changed
end

local function sendToDepartment(department, eventName, payload)
    local sent = 0
    for userId, playerSource in pairs(vRP.getUsers() or {}) do
        userId = tonumber(userId)
        playerSource = tonumber(playerSource)
        if userId and playerSource and isDepartmentMember(userId, department) and GetPlayerName(playerSource) ~= nil then
            TriggerClientEvent(eventName, playerSource, payload)
            sent = sent + 1
        end
    end
    return sent
end

-- Criação centralizada de chamados. Além da NUI do painel, outros resources
-- server-side podem usar o export createSectorCall sem duplicar a regra de
-- permissões, disponibilidade, cooldown e concorrência dos atendimentos.
local function createCallForPlayer(playerSource, department, message, options)
    options = type(options) == "table" and options or {}
    playerSource = tonumber(playerSource)
    if not playerSource or GetPlayerName(playerSource) == nil then
        return result(false, "Jogador não está online.")
    end

    local userId = vRP.getUserId(playerSource)
    if not userId then return result(false, "Jogador não identificado.") end

    department = tostring(department or "")
    local dept = departmentConfig(department)
    if not dept then return result(false, "Tipo de chamado inválido.") end

    message = clampString(message, (Config.Calls and Config.Calls.maxMessage) or ServerConfig.Limits.maxMessage or 500)
    if message == "" then return result(false, "Explique em que você precisa de ajuda.") end

    if getDepartmentOnlineCount(department) <= 0 then
        removeOrphanOpenCall(userId, department)
        return result(false, getDepartmentUnavailableMessage(department))
    end

    local cooldown = math.max(0, tonumber(Config.Calls and Config.Calls.createCooldownSeconds) or 12)
    local last = tonumber(lastCallCreatedAt[userId]) or 0
    if not options.ignoreCooldown and cooldown > 0 and os.time() - last < cooldown then
        return result(false, ("Aguarde %d segundo(s) antes de abrir outro chamado."):format(cooldown - (os.time() - last)))
    end

    for _, existing in pairs(activeCalls) do
        if tonumber(existing.playerId) == tonumber(userId)
            and existing.department == department
            and (existing.status == "open" or existing.status == "accepted") then
            return result(false, "Você já possui um chamado deste setor em andamento.", publicCall(existing))
        end
    end

    local identity = getIdentity(userId)
    local callId = callStore.nextId
    callStore.nextId = callId + 1
    saveCallStore()
    lastCallCreatedAt[userId] = os.time()

    local call = {
        id = callId,
        department = department,
        departmentLabel = tostring(dept.label or department),
        playerId = userId,
        playerSource = playerSource,
        playerName = (tostring(identity.nome) .. " " .. tostring(identity.sobrenome)):gsub("%s+", " "),
        message = message,
        status = "open",
        createdAt = os.time(),
        createdAtText = os.date("%d/%m/%Y %H:%M:%S"),
        origin = tostring(options.origin or "panel")
    }
    activeCalls[callId] = call

    if department == "staff" then
        sendToDepartment("staff", "m_paineladm_v2:staffCallNotice", publicCall(call))
        pushCallsPanelUpdate()
    else
        sendToDepartment(department, "m_paineladm_v2:sectorCallNew", publicCall(call))
    end

    if options.silentRequester ~= true then
        notify(playerSource, "sucesso", ("Chamado %s enviado com sucesso."):format(call.departmentLabel), 7000)
    end
    webhookLog(userId, "calls_create", ("Chamado #%d | Setor: %s | Mensagem: %s | Origem: %s"):format(
        callId, call.departmentLabel, message, call.origin
    ))

    return result(true, "Chamado enviado com sucesso.", publicCall(call))
end

-- Cancela chamados ainda pendentes do jogador. Usado, por exemplo, pelo
-- m_survival quando o paciente é revivido antes de um médico aceitar.
local function cancelCallsForPlayer(playerSource, department, reason)
    playerSource = tonumber(playerSource)
    local userId = playerSource and vRP.getUserId(playerSource) or nil
    if not userId then return result(false, "Jogador não identificado.") end

    department = tostring(department or "")
    local removed = 0
    for callId, call in pairs(activeCalls) do
        if tonumber(call.playerId) == tonumber(userId)
            and (department == "" or call.department == department)
            and call.status == "open" then
            local payload = publicCall(call) or {}
            payload.cancelled = true
            payload.cancelReason = tostring(reason or "Solicitação cancelada.")
            if call.department == "staff" then
                activeCalls[callId] = nil
                pushCallsPanelUpdate()
            else
                activeCalls[callId] = nil
                sendToDepartment(call.department, "m_paineladm_v2:sectorCallTaken", payload)
            end
            removed = removed + 1
        end
    end

    return result(true, removed > 0 and "Chamado cancelado." or "Nenhum chamado pendente.", { removed = removed })
end

exports("createSectorCall", function(playerSource, department, message, options)
    return createCallForPlayer(playerSource, department, message, options)
end)

exports("cancelSectorCall", function(playerSource, department, reason)
    return cancelCallsForPlayer(playerSource, department, reason)
end)

local function buildRatingMaps()
    local aggregate = {}
    for _, evaluation in ipairs(callStore.evaluations or {}) do
        local staffId = tonumber(evaluation.staffId)
        local stars = tonumber(evaluation.stars)
        if staffId and stars then
            local row = aggregate[staffId] or { sum = 0, count = 0 }
            row.sum = row.sum + stars
            row.count = row.count + 1
            aggregate[staffId] = row
        end
    end
    return aggregate
end

local function buildRanking()
    local rows = {}
    local byId = {}
    local ratings = buildRatingMaps()
    for _, item in ipairs(callStore.history or {}) do
        local staffId = tonumber(item.staffId)
        if staffId then
            local row = byId[staffId]
            if not row then
                row = { id = staffId, name = tostring(item.staffName or ("Staff #" .. staffId)), points = 0, averageRating = 0, ratingCount = 0 }
                byId[staffId] = row
                rows[#rows + 1] = row
            end
            row.points = row.points + 1
            if item.staffName and item.staffName ~= "" then row.name = tostring(item.staffName) end
        end
    end
    for _, row in ipairs(rows) do
        local rating = ratings[row.id]
        if rating and rating.count > 0 then
            row.ratingCount = rating.count
            row.averageRating = rating.sum / rating.count
        end
    end
    table.sort(rows, function(a,b)
        if a.points ~= b.points then return a.points > b.points end
        if a.averageRating ~= b.averageRating then return a.averageRating > b.averageRating end
        return a.name:lower() < b.name:lower()
    end)
    return rows
end

local function buildStaffNotes()
    local ranking = buildRanking()
    local rows = {}
    for _, row in ipairs(ranking) do
        rows[#rows + 1] = {
            id = row.id, name = row.name, completed = row.points,
            ratingCount = row.ratingCount, averageRating = row.averageRating
        }
    end
    table.sort(rows, function(a,b)
        if a.averageRating ~= b.averageRating then return a.averageRating > b.averageRating end
        if a.ratingCount ~= b.ratingCount then return a.ratingCount > b.ratingCount end
        return a.completed > b.completed
    end)
    return rows
end

local function buildCallsDashboard(actorId)
    local open = {}
    for _, call in pairs(activeCalls) do
        if call.department == "staff" and (call.status == "open" or call.status == "accepted") then
            open[#open + 1] = publicCall(call)
        end
    end
    table.sort(open, function(a,b) return (a.createdAt or 0) > (b.createdAt or 0) end)

    local history = {}
    if canUseAction(actorId, "calls_history") then
        for i = #callStore.history, 1, -1 do
            history[#history + 1] = callStore.history[i]
            if #history >= 500 then break end
        end
    end
    local evaluations = {}
    if canUseAction(actorId, "calls_evaluations") then
        for i = #callStore.evaluations, 1, -1 do
            evaluations[#evaluations + 1] = callStore.evaluations[i]
            if #evaluations >= 500 then break end
        end
    end

    return {
        viewerId = actorId,
        openCalls = open,
        history = history,
        ranking = canUseAction(actorId, "calls_ranking") and buildRanking() or {},
        evaluations = evaluations,
        staffNotes = canUseAction(actorId, "calls_staff_notes") and buildStaffNotes() or {}
    }
end

local function getCallTargetCoords(call)
    if not call then return nil end
    local targetSource = getUserSourceSafe(call.playerId)
    if not targetSource then return nil end
    local cached = liveMapPositionCache[targetSource]
    if cached and (os.time() - (cached.updatedAt or 0)) <= 12 then
        return cached.x, cached.y, cached.z, targetSource
    end
    local x, y, z = vRPclient.getPosition(targetSource)
    if x and y and z then return x, y, z, targetSource end
    return nil
end

function API.calls(data)
    data = type(data) == "table" and data or {}
    local mode = tostring(data.mode or "")
    local playerSource = source
    local userId = vRP.getUserId(playerSource)
    if not userId then return result(false, "Jogador não identificado.") end

    if mode == "panelData" then
        local actorId = requireAction(playerSource, "view_calls")
        if not actorId then return result(false, "Sem permissão para visualizar chamados.") end
        local auditView = tostring(data.auditView or "")
        local auditPermissions = {
            history = { key = "calls_history_view", permission = "calls_history", detail = "Histórico de chamados finalizados" },
            ranking = { key = "calls_ranking_view", permission = "calls_ranking", detail = "Ranking de atendimentos Staff" },
            evaluations = { key = "calls_evaluations_view", permission = "calls_evaluations", detail = "Avaliações dos atendimentos Staff" },
            notes = { key = "calls_staff_notes_view", permission = "calls_staff_notes", detail = "Notas consolidadas da Staff" }
        }
        local audit = auditPermissions[auditView]
        if audit and canUseAction(actorId, audit.permission) then
            webhookLog(actorId, audit.key, audit.detail)
        end
        return result(true, "Chamados carregados.", buildCallsDashboard(actorId))
    end

    if mode == "create" then
        return createCallForPlayer(playerSource, data.department, data.message, { origin = "painel" })
    end

    if mode == "acceptStaff" then
        local actorId = requireAction(playerSource, "calls_accept")
        if not actorId then return result(false, "Sem permissão para aceitar chamados.") end
        local callId = tonumber(data.callId)
        local call = callId and activeCalls[callId] or nil
        if not call or call.department ~= "staff" then return result(false, "Chamado não encontrado.") end
        if call.status ~= "open" then return result(false, "Outro Staff já aceitou este chamado.", buildCallsDashboard(actorId)) end

        for _, existing in pairs(activeCalls) do
            if existing.department == "staff" and existing.status == "accepted" and tonumber(existing.acceptedById) == tonumber(actorId) then
                return result(false, "Finalize seu chamado atual antes de aceitar outro.")
            end
        end

        local x, y, z, targetSource = getCallTargetCoords(call)
        if not targetSource or not x then return result(false, "O jogador do chamado não está mais online.") end

        call.status = "accepted"
        call.acceptedById = actorId
        call.acceptedBySource = playerSource
        call.acceptedByName = getFullName(actorId)
        call.acceptedAt = os.time()
        call.acceptedAtText = os.date("%d/%m/%Y %H:%M:%S")

        -- Usa exatamente o noclip nativo já existente na vRP da base.
        -- O painel não mantém mais nenhuma implementação própria de noclip.
        vRPclient._teleport(playerSource, x, y, z + 0.65)
        vRPclient._toggleNoclip(playerSource)
        TriggerClientEvent("m_paineladm_v2:staffCallAccepted", playerSource, { callId = callId })

        notify(targetSource, "aviso", ("Seu chamado Staff foi aceito por %s."):format(call.acceptedByName), 8000)
        webhookLog(actorId, "calls_accept", ("Chamado #%d | %s"):format(callId, tostring(call.message or "-")), call.playerId, { targetName = call.playerName })
        pushCallsPanelUpdate()
        return result(true, "Chamado aceito. Você foi enviado até o jogador.", buildCallsDashboard(actorId))
    end

    if mode == "finishStaff" then
        local actorId = requireAction(playerSource, "calls_finish")
        if not actorId then return result(false, "Sem permissão para finalizar chamados.") end
        local callId = tonumber(data.callId)
        local call = callId and activeCalls[callId] or nil
        if not call or call.department ~= "staff" then return result(false, "Chamado não encontrado.") end
        if call.status ~= "accepted" or tonumber(call.acceptedById) ~= tonumber(actorId) then
            return result(false, "Somente o Staff que aceitou pode finalizar este chamado.")
        end

        call.status = "completed"
        call.completedAt = os.time()
        call.completedAtText = os.date("%d/%m/%Y %H:%M:%S")
        local historyEntry = {
            id = call.id, playerId = call.playerId, playerName = call.playerName,
            message = call.message, staffId = actorId, staffName = call.acceptedByName,
            createdAt = call.createdAt, createdAtText = call.createdAtText,
            acceptedAt = call.acceptedAt, acceptedAtText = call.acceptedAtText,
            completedAt = call.completedAt, completedAtText = call.completedAtText,
            rating = nil, feedback = nil
        }
        callStore.history[#callStore.history + 1] = historyEntry
        if #callStore.history > 3000 then table.remove(callStore.history, 1) end
        activeCalls[callId] = nil
        saveCallStore()

        -- Finalizar o chamado desativa o mesmo noclip da vRP ativado no aceite.
        vRPclient._toggleNoclip(playerSource)
        TriggerClientEvent("m_paineladm_v2:staffCallFinished", playerSource, callId)

        local targetSource = getUserSourceSafe(call.playerId)
        if targetSource then
            TriggerClientEvent("m_paineladm_v2:callEvaluation", targetSource, {
                callId = callId,
                staffId = actorId,
                staffName = call.acceptedByName
            })
        end
        webhookLog(actorId, "calls_finish", ("Chamado #%d finalizado | Solicitação: %s"):format(callId, tostring(call.message or "-")), call.playerId, { targetName = call.playerName })
        pushCallsPanelUpdate()
        return result(true, "Chamado finalizado e arquivado. +1 ponto no ranking.", buildCallsDashboard(actorId))
    end

    if mode == "rate" then
        local callId = tonumber(data.callId)
        local stars = math.floor(tonumber(data.stars) or 0)
        if not callId or stars < 1 or stars > 5 then return result(false, "Selecione de 1 a 5 estrelas.") end
        local historyEntry = nil
        for _, item in ipairs(callStore.history or {}) do
            if tonumber(item.id) == callId then historyEntry = item break end
        end
        if not historyEntry or tonumber(historyEntry.playerId) ~= tonumber(userId) then
            return result(false, "Esta avaliação não pertence a você.")
        end
        if historyEntry.rating then return result(false, "Este atendimento já foi avaliado.") end

        local feedback = clampString(data.message, 500)
        if feedback == "" then feedback = "sem-mensagem" end
        historyEntry.rating = stars
        historyEntry.feedback = feedback
        local evaluation = {
            callId = callId,
            playerId = historyEntry.playerId, playerName = historyEntry.playerName,
            staffId = historyEntry.staffId, staffName = historyEntry.staffName,
            stars = stars, message = feedback,
            createdAt = os.time(), createdAtText = os.date("%d/%m/%Y %H:%M:%S")
        }
        callStore.evaluations[#callStore.evaluations + 1] = evaluation
        if #callStore.evaluations > 3000 then table.remove(callStore.evaluations, 1) end
        saveCallStore()
        pushCallsPanelUpdate()
        notify(playerSource, "sucesso", "Obrigado pela avaliação do atendimento.", 6000)
        webhookLog(userId, "calls_rate", ("Chamado #%d | %d estrela(s) | Comentário: %s"):format(callId, stars, feedback), historyEntry.staffId, { targetName = historyEntry.staffName })
        return result(true, "Avaliação registrada.")
    end

    if mode == "sectorAccept" then
        local callId = tonumber(data.callId)
        local call = callId and activeCalls[callId] or nil
        if not call or call.department == "staff" then return result(false, "Chamado não encontrado.") end
        if not isDepartmentMember(userId, call.department) then return result(false, "Você não pertence ao setor deste chamado.") end
        if call.status ~= "open" then return result(false, "Este chamado já foi aceito.") end

        -- Confirma que o solicitante continua online e captura a posição mais
        -- recente antes de reservar o chamado. Assim o atendente já recebe o
        -- ponto correto no GPS ao clicar em Aceitar.
        local x, y, z, targetSource = getCallTargetCoords(call)
        if not targetSource or not x or not y then
            activeCalls[callId] = nil
            local cancelled = publicCall(call) or {}
            cancelled.id = callId
            cancelled.cancelled = true
            sendToDepartment(call.department, "m_paineladm_v2:sectorCallTaken", cancelled)
            return result(false, "O jogador do chamado não está mais online.")
        end

        if activeCalls[callId] ~= call or call.status ~= "open" then
            return result(false, "Este chamado já foi aceito ou cancelado.")
        end
        call.status = "accepted"
        call.acceptedById = userId
        QueueSectorProductivity(call, userId)
        call.acceptedByName = getFullName(userId)
        local payload = publicCall(call)
        payload.acceptedById = userId
        payload.acceptedByName = call.acceptedByName
        sendToDepartment(call.department, "m_paineladm_v2:sectorCallTaken", payload)

        -- Evento exclusivo para quem aceitou: fecha qualquer interface de
        -- chamados ainda aberta e marca a localização do solicitante no mapa.
        TriggerClientEvent("m_paineladm_v2:sectorCallAccepted", playerSource, {
            callId = callId,
            department = call.department,
            departmentLabel = call.departmentLabel,
            playerId = call.playerId,
            playerName = call.playerName,
            x = x, y = y, z = z
        })

        notify(targetSource, "sucesso", ("Seu chamado %s foi aceito por %s."):format(call.departmentLabel, call.acceptedByName), 8000)

        -- Para Polícia/Mecânica/Hospital, aceitar encerra a fila. Não entram no
        -- histórico do painel administrativo, conforme solicitado.
        webhookLog(userId, "calls_sector_accept", ("Chamado #%d | Setor: %s | Mensagem: %s"):format(callId, call.departmentLabel, tostring(call.message or "-")), call.playerId, { targetName = call.playerName })
        activeCalls[callId] = nil
        return result(true, "Chamado aceito. Localização marcada no GPS.", { x = x, y = y, z = z })
    end

    return result(false, "Operação de chamados inválida.")
end

AddEventHandler("playerDropped", function()
    local droppedSource = tonumber(source)
    local droppedUserId = vRP.getUserId(droppedSource)
    local removeIds = {}
    local callsChanged = false
    for callId, call in pairs(activeCalls) do
        if tonumber(call.playerSource) == droppedSource or (droppedUserId and tonumber(call.playerId) == tonumber(droppedUserId)) then
            removeIds[#removeIds + 1] = callId
            callsChanged = true
            if call.department == "staff" and call.acceptedById then
                local staffSource = getUserSourceSafe(call.acceptedById)
                if staffSource then
                    -- O solicitante saiu: encerra também o noclip da vRP do Staff.
                    vRPclient._toggleNoclip(staffSource)
                    TriggerClientEvent("m_paineladm_v2:staffCallFinished", staffSource, callId)
                    notify(staffSource, "aviso", "O jogador do chamado desconectou. Atendimento encerrado.", 7000)
                end
            elseif call.department ~= "staff" then
                local cancelled = publicCall(call)
                cancelled.cancelled = true
                sendToDepartment(call.department, "m_paineladm_v2:sectorCallTaken", cancelled)
            end
        elseif call.department == "staff" and call.status == "accepted" and tonumber(call.acceptedBySource) == droppedSource then
            -- Se a Staff que aceitou desconectar, o chamado volta automaticamente
            -- para a fila em vez de ficar preso como "Outro staff aceitou".
            call.status = "open"
            call.acceptedById = nil
            call.acceptedBySource = nil
            call.acceptedByName = nil
            call.acceptedAt = nil
            call.acceptedAtText = nil
            callsChanged = true
            local targetSource = getUserSourceSafe(call.playerId)
            if targetSource then notify(targetSource, "aviso", "O Staff desconectou. Seu chamado voltou para a fila.", 7000) end
        end
    end
    for _, callId in ipairs(removeIds) do activeCalls[callId] = nil end
    if callsChanged then pushCallsPanelUpdate() end
end)


local function getMapPlayers()
    local list = {}
    local now = os.time()
    for userId, playerSource in pairs(vRP.getUsers() or {}) do
        userId = tonumber(userId)
        playerSource = tonumber(playerSource)
        if userId and playerSource then
            local identity = getIdentity(userId)
            local x, y, z, heading = 0.0, 0.0, 0.0, 0.0
            local hasPosition = false

            -- Preferimos a posição enviada pelo client porque ela é estável mesmo
            -- quando o ped server-side ainda não foi criado/resolvido pelo OneSync.
            local cached = liveMapPositionCache[playerSource]
            if cached and (now - (cached.updatedAt or 0)) <= 12 then
                x = tonumber(cached.x) or 0.0
                y = tonumber(cached.y) or 0.0
                z = tonumber(cached.z) or 0.0
                heading = tonumber(cached.heading) or 0.0
                hasPosition = true
            end

            -- Fallback para o native server-side.
            if not hasPosition then
                local ped = GetPlayerPed(playerSource)
                if ped and ped > 0 then
                    local coords = GetEntityCoords(ped)
                    if coords then
                        x = tonumber(coords.x or coords[1]) or 0.0
                        y = tonumber(coords.y or coords[2]) or 0.0
                        z = tonumber(coords.z or coords[3]) or 0.0
                        hasPosition = true
                    end
                    heading = tonumber(GetEntityHeading(ped)) or 0.0
                end
            end

            list[#list + 1] = {
                id = userId,
                source = playerSource,
                name = (tostring(identity.nome) .. " " .. tostring(identity.sobrenome)):gsub("%s+", " "),
                ping = GetPlayerPing(playerSource) or 0,
                bucket = GetPlayerRoutingBucket(playerSource) or 0,
                x = x, y = y, z = z, heading = heading,
                hasPosition = hasPosition
            }
        end
    end

    table.sort(list, function(a, b)
        return (a.id or 0) < (b.id or 0)
    end)
    return list
end

RegisterNetEvent("m_paineladm_v2:reportMapPosition")
AddEventHandler("m_paineladm_v2:reportMapPosition", function(x, y, z, heading)
    local playerSource = tonumber(source)
    x, y, z, heading = tonumber(x), tonumber(y), tonumber(z), tonumber(heading)
    if not playerSource or not x or not y or not z then return end
    -- Valores absurdos são ignorados em vez de poluir a projeção do mapa.
    if math.abs(x) > 15000 or math.abs(y) > 15000 or math.abs(z) > 10000 then return end
    liveMapPositionCache[playerSource] = {
        x = x + 0.0, y = y + 0.0, z = z + 0.0,
        heading = (heading or 0.0) + 0.0,
        updatedAt = os.time()
    }
end)

AddEventHandler("playerDropped", function()
    liveMapPositionCache[tonumber(source)] = nil
end)

local function closeLiveScreenSession(token, notifyAdmin, message)
    token = tostring(token or "")
    if token == "" then return end

    local session = liveScreenSessions[token]
    if not session then return end

    session.active = false
    liveScreenSessions[token] = nil

    local adminSource = tonumber(session.adminSource)
    local targetSource = tonumber(session.targetSource)
    local targetId = tonumber(session.targetId)

    if adminSource and liveScreenByAdmin[adminSource] == token then
        liveScreenByAdmin[adminSource] = nil
    end
    if targetId and liveScreenByTarget[targetId] == token then
        liveScreenByTarget[targetId] = nil
    end

    if targetSource then
        TriggerClientEvent("m_paineladm_v2:liveScreenPublisherStop", targetSource, token)
        TriggerClientEvent("m_paineladm_v2:liveScreenRelayStop", targetSource, token)
    end

    if notifyAdmin and adminSource then
        TriggerClientEvent(
            "m_paineladm_v2:liveScreenError",
            adminSource,
            token,
            tostring(message or "Monitoramento encerrado.")
        )
    end
end

local function stopLiveScreenForAdmin(adminSource)
    adminSource = tonumber(adminSource)
    if not adminSource then return end
    local token = liveScreenByAdmin[adminSource]
    if token then closeLiveScreenSession(token, false) end
end

local function newLiveScreenToken(adminSource, targetId)
    return ("%s:%s:%s:%s"):format(
        tostring(adminSource), tostring(targetId), tostring(GetGameTimer()), tostring(math.random(100000, 999999))
    )
end

local function sanitizeLiveScreenSignal(kind, payload)
    kind = tostring(kind or "")
    payload = type(payload) == "table" and payload or {}

    if kind == "offer" or kind == "answer" then
        local signalType = tostring(payload.type or "")
        local sdp = tostring(payload.sdp or "")
        if (signalType ~= "offer" and signalType ~= "answer") or sdp == "" or #sdp > 120000 then
            return nil
        end
        return { type = signalType, sdp = sdp }
    end

    if kind == "candidate" then
        local candidate = tostring(payload.candidate or "")
        if candidate == "" or #candidate > 12000 then return nil end
        local sdpMid = tostring(payload.sdpMid or "")
        if #sdpMid > 128 then sdpMid = sdpMid:sub(1, 128) end
        return {
            candidate = candidate,
            sdpMid = sdpMid ~= "" and sdpMid or nil,
            sdpMLineIndex = tonumber(payload.sdpMLineIndex)
        }
    end

    if kind == "status" then
        local state = tostring(payload.state or "")
        local text = tostring(payload.message or "")
        if #state > 40 then state = state:sub(1, 40) end
        if #text > 240 then text = text:sub(1, 240) end
        return { state = state, message = text }
    end

    return nil
end

-- Signaling WebRTC. O FXServer só troca SDP/ICE entre os dois clients; nenhum
-- frame de vídeo passa por evento de rede do servidor. O `senderRole` é
-- obrigatório no protocolo atual para também permitir teste em loopback quando
-- administrador e jogador monitorado são o mesmo client.
RegisterNetEvent("m_paineladm_v2:liveScreenSignal")
AddEventHandler("m_paineladm_v2:liveScreenSignal", function(token, kind, payload, senderRole)
    local playerSource = tonumber(source)
    token = tostring(token or "")
    kind = tostring(kind or "")
    senderRole = tostring(senderRole or "")
    if not playerSource or token == "" then return end

    local session = liveScreenSessions[token]
    if not session or not session.active then return end

    local clean = sanitizeLiveScreenSignal(kind, payload)
    if not clean then return end

    local adminSource = tonumber(session.adminSource)
    local targetSource = tonumber(session.targetSource)
    if not adminSource or not targetSource then return end

    local destination
    local destinationRole

    if senderRole == "receiver" then
        -- ADM/receptor -> jogador/publicador.
        if playerSource ~= adminSource then return end
        if kind ~= "answer" and kind ~= "candidate" then return end
        destination = targetSource
        destinationRole = "publisher"
    elseif senderRole == "publisher" then
        -- Jogador/publicador -> ADM/receptor.
        if playerSource ~= targetSource then return end
        if kind ~= "offer" and kind ~= "candidate" and kind ~= "status" then return end
        destination = adminSource
        destinationRole = "receiver"
    else
        -- Compatibilidade com sinalização da v2.53 para conexões entre clients
        -- diferentes. Em loopback o papel precisa vir explicitamente.
        if adminSource == targetSource then return end
        if playerSource == adminSource then
            if kind ~= "answer" and kind ~= "candidate" then return end
            destination = targetSource
            destinationRole = "publisher"
        elseif playerSource == targetSource then
            if kind ~= "offer" and kind ~= "candidate" and kind ~= "status" then return end
            destination = adminSource
            destinationRole = "receiver"
        else
            return
        end
    end

    TriggerClientEvent("m_paineladm_v2:liveScreenSignal", destination, token, kind, clean, destinationRole)

    if senderRole == "publisher" and kind == "status" and tostring(clean.state or "") == "error" then
        closeLiveScreenSession(token, false)
    elseif senderRole == "" and playerSource == targetSource and kind == "status" and tostring(clean.state or "") == "error" then
        closeLiveScreenSession(token, false)
    end
end)


RegisterNetEvent("m_paineladm_v2:liveScreenRelayFrame")
AddEventHandler("m_paineladm_v2:liveScreenRelayFrame", function(token, seq, frame)
    local playerSource = tonumber(source)
    token = tostring(token or "")
    frame = tostring(frame or "")
    seq = math.floor(tonumber(seq) or 0)
    if not playerSource or token == "" or frame == "" then return end

    local session = liveScreenSessions[token]
    if not session or not session.active or session.relayEnabled ~= true then return end
    if playerSource ~= tonumber(session.targetSource) then return end

    -- Aceita somente JPEG data URL gerado pelo próprio canvas do CEF.
    if frame:sub(1, 23) ~= "data:image/jpeg;base64," then return end

    local mapConfig = Config.LiveMap or {}
    local maxBytes = math.max(120000, math.min(1200000, math.floor(tonumber(mapConfig.screenRelayMaxFrameBytes) or 900000)))
    if #frame > maxBytes then return end

    -- Descarta frames antigos/duplicados; evita backlog em conexão lenta.
    if seq <= (tonumber(session.lastRelaySeq) or 0) then return end
    session.lastRelaySeq = seq
    session.lastRelayAt = os.time()

    local adminSource = tonumber(session.adminSource)
    if not adminSource or GetPlayerName(adminSource) == nil then
        closeLiveScreenSession(token, false)
        return
    end

    local bandwidth = math.max(128000, math.min(3500000, math.floor(tonumber(mapConfig.screenRelayBandwidth) or 2500000)))
    TriggerLatentClientEvent("m_paineladm_v2:liveScreenRelayFrame", adminSource, bandwidth, token, seq, frame)
end)

local function getOnlineStats(players)
    local permissions = ServerConfig.OnlineCounterPermissions or {}

    local function countByPermission(permission)
        if not permission or permission == "" or type(vRP.getUsersByPermission) ~= "function" then
            return 0
        end
        local users = vRP.getUsersByPermission(permission) or {}
        local total = 0
        for _ in pairs(users) do
            total = total + 1
        end
        return total
    end

    return {
        players = #(players or getPlayers()),
        staff = countByPermission(permissions.staff or ServerConfig.StaffPermission),
        mechanics = countByPermission(permissions.mechanics),
        police = countByPermission(permissions.police),
        medics = countByPermission(permissions.medics),
        illegal = countByPermission(permissions.illegal)
    }
end

local function getServerGroups()
    local groups = {}
    local sourceGroups = nil

    if type(vRP.getGroups) == "function" then
        sourceGroups = vRP.getGroups()
    elseif groupModule and groupModule.groups then
        sourceGroups = groupModule.groups
    else
        sourceGroups = {}
    end

    for name, definition in pairs(sourceGroups or {}) do
        local hidden = false
        for _, pattern in ipairs(ServerConfig.HiddenGroupPatterns or {}) do
            if tostring(name):find(pattern) then
                hidden = true
                break
            end
        end

        if not hidden then
            local config = type(definition) == "table" and definition._config or nil
            groups[#groups + 1] = {
                name = tostring(name),
                type = config and config.gtype or "outro",
                org = config and config.orgName or nil,
                rank = ServerConfig.GroupHierarchy[tostring(name)] or 0
            }
        end
    end

    table.sort(groups, function(a, b)
        return a.name:lower() < b.name:lower()
    end)

    return groups
end

getItems = function()
    local items = {}
    local added = {}
    local activeItems = vRP.getAllItens() or {}

    local function appendItem(index, sourceItem)
        index = tostring(index or "")
        if index == "" or added[index] or not activeItems[index] then return end

        local display = nil
        if type(sourceItem) == "table" then
            -- Compatível tanto com cfg/items.lua quanto com shared.items.lua.
            display = sourceItem[1] or sourceItem.name or sourceItem.label or sourceItem.Name
        elseif type(sourceItem) == "string" then
            display = sourceItem
        end

        if not display or display == "" then
            display = vRP.getItemName(index)
        end

        items[#items + 1] = {
            index = index,
            name = tostring(display or index)
        }
        added[index] = true
    end

    -- Itens comuns cadastrados no cfg/items.lua e efetivamente carregados.
    for index, cfgItem in pairs(configuredItems) do
        appendItem(index, cfgItem)
    end

    -- Armas e munições também entram no catálogo mesmo quando não existem no
    -- cfg/items.lua, desde que estejam no catálogo ativo do inventário.
    for index, activeItem in pairs(activeItems) do
        if isWeaponOrAmmoItem(index) then
            appendItem(index, activeItem)
        end
    end

    table.sort(items, function(a, b)
        local an = a.name:lower()
        local bn = b.name:lower()
        if an == bn then return a.index:lower() < b.index:lower() end
        return an < bn
    end)

    return items
end


-- Armas que funcionam sem um item de munição carregável no inventário.
-- Esta lista é intencionalmente independente da existência de AMMO_* porque
-- versões antigas da base podiam criar automaticamente itens de munição falsos
-- (ex.: AMMO_RAYPISTOL). Mesmo que um desses itens ainda exista em cache ou em
-- configuração legada, o painel nunca irá oferecê-lo nem entregá-lo.
local WEAPONS_WITHOUT_INVENTORY_AMMO = {
    ["WEAPON_UNARMED"] = true,
    ["WEAPON_BAT"] = true,
    ["WEAPON_BATTLEAXE"] = true,
    ["WEAPON_BOTTLE"] = true,
    ["WEAPON_CANDYCANE"] = true,
    ["WEAPON_CROWBAR"] = true,
    ["WEAPON_DAGGER"] = true,
    ["WEAPON_DIGISCANNER"] = true,
    ["WEAPON_FLASHLIGHT"] = true,
    ["WEAPON_GOLFCLUB"] = true,
    ["WEAPON_HACKINGDEVICE"] = true,
    ["WEAPON_HAMMER"] = true,
    ["WEAPON_HATCHET"] = true,
    ["WEAPON_KNIFE"] = true,
    ["WEAPON_KNUCKLE"] = true,
    ["WEAPON_MACHETE"] = true,
    ["WEAPON_NIGHTSTICK"] = true,
    ["WEAPON_POOLCUE"] = true,
    ["WEAPON_RAYPISTOL"] = true, -- Up-n-Atomizer: recarga própria, sem munição de inventário.
    ["WEAPON_STONE_HATCHET"] = true,
    ["WEAPON_STUNGUN"] = true,
    ["WEAPON_STUNGUN_MP"] = true,
    ["WEAPON_STUNROD"] = true,
    ["WEAPON_SWITCHBLADE"] = true,
    ["WEAPON_WRENCH"] = true
}

local function weaponUsesInventoryAmmo(index)
    return not WEAPONS_WITHOUT_INVENTORY_AMMO[tostring(index or ""):upper()]
end

local function weaponCategory(index, ammoItem)
    local key = tostring(index or ""):upper()
    if key:find("SHOTGUN", 1, true) or key:find("MUSKET", 1, true) then return "Escopetas" end
    if key:find("SNIPER", 1, true) or key:find("MARKSMANRIFLE", 1, true) or key:find("PRECISIONRIFLE", 1, true) then return "Snipers" end
    if key:find("SMG", 1, true) or key:find("PDW", 1, true) or key:find("MACHINEPISTOL", 1, true) or key:find("GUSENBERG", 1, true) then return "Submetralhadoras" end
    if key:find("RIFLE", 1, true) or key:find("CARBINE", 1, true) then return "Rifles" end
    if key:find("PISTOL", 1, true) or key:find("REVOLVER", 1, true) or key:find("FLAREGUN", 1, true) or key:find("STUNGUN", 1, true) then return "Pistolas" end
    if key:find("RPG", 1, true) or key:find("LAUNCHER", 1, true) or key:find("MINIGUN", 1, true) or key:find("RAILGUN", 1, true) then return "Pesadas" end
    if key:find("GRENADE", 1, true) or key:find("MOLOTOV", 1, true) or key:find("STICKYBOMB", 1, true) or key:find("PROXMINE", 1, true) or key:find("PIPEBOMB", 1, true) or key:find("SNOWBALL", 1, true) or key:find("BALL", 1, true) or key:find("FLARE", 1, true) or key:find("BZGAS", 1, true) then return "Explosivos" end
    if key:find("PETROLCAN", 1, true) or key:find("FIREEXTINGUISHER", 1, true) or key:find("HAZARDCAN", 1, true) or key:find("FERTILIZERCAN", 1, true) or key:find("HACKINGDEVICE", 1, true) or key:find("DIGISCANNER", 1, true) then return "Utilitários" end
    if not ammoItem then return "Corpo a corpo" end
    return "Outras"
end

local function getWeapons()
    local activeItems = vRP.getAllItens() or {}
    local byUpper = {}

    -- O inventário atual trabalha majoritariamente com índices em minúsculo,
    -- enquanto algumas configurações legadas usam WEAPON_/AMMO_ em maiúsculo.
    -- Este índice torna o vínculo arma -> munição totalmente case-insensitive.
    for index in pairs(activeItems) do
        byUpper[tostring(index):upper()] = tostring(index)
    end

    local weapons = {}
    for index, item in pairs(activeItems) do
        local upper = tostring(index):upper()
        if upper:sub(1, 7) == "WEAPON_" then
            local ammoUpper = "AMMO_" .. upper:sub(8)
            local ammoItem = weaponUsesInventoryAmmo(upper) and byUpper[ammoUpper] or nil
            local display = nil
            if type(item) == "table" then
                display = item.name or item.label or item.Name or item[1]
            elseif type(item) == "string" then
                display = item
            end
            if not display or display == "" then
                display = vRP.getItemName(index)
            end

            weapons[#weapons + 1] = {
                index = tostring(index),
                name = tostring(display or index),
                ammo = ammoItem,
                ammoName = ammoItem and tostring(vRP.getItemName(ammoItem) or ammoItem) or nil,
                category = weaponCategory(index, ammoItem)
            }
        end
    end

    table.sort(weapons, function(a, b)
        if a.category == b.category then
            local an, bn = a.name:lower(), b.name:lower()
            if an == bn then return a.index:lower() < b.index:lower() end
            return an < bn
        end
        return a.category < b.category
    end)

    return weapons
end

local function getInventory(userId)
    local data = vRP.getUserDataTable(userId)
    local inventory = {}

    if not data or type(data.inventory) ~= "table" then
        return inventory
    end

    for slot, entry in pairs(data.inventory) do
        if type(entry) == "table" and entry.item then
            inventory[#inventory + 1] = {
                slot = tostring(slot),
                index = tostring(entry.item),
                name = tostring(vRP.getItemName(entry.item) or entry.item),
                amount = tonumber(entry.amount) or 0
            }
        end
    end

    table.sort(inventory, function(a, b)
        return a.name:lower() < b.name:lower()
    end)

    return inventory
end

local function getUserGroups(userId)
    local output = {}
    local groups = vRP.getUserGroups(userId) or {}

    for groupName in pairs(groups) do
        output[#output + 1] = tostring(groupName)
    end

    table.sort(output, function(a, b)
        return a:lower() < b:lower()
    end)

    return output
end

local function highestHierarchy(userId)
    local highest = 0
    local groups = vRP.getUserGroups(userId) or {}

    for groupName in pairs(groups) do
        local rank = ServerConfig.GroupHierarchy[tostring(groupName)] or 0
        if rank > highest then highest = rank end
    end

    return highest
end

local function canManageGroup(actorId, groupName)
    local targetRank = ServerConfig.GroupHierarchy[tostring(groupName)] or 0
    if targetRank <= 0 then return true end

    local actorRank = highestHierarchy(actorId)
    return actorRank > targetRank
end

local function isOnline(userId)
    local targetSource = userId and vRP.getUserSource(userId) or nil
    return targetSource ~= nil, targetSource
end

local function playerSnapshot(userId, actorId)
    local identity = getIdentity(userId)
    local online, playerSource = isOnline(userId)
    local bank = 0
    local wallet = 0
    local fines = 0

    if type(vRP.getBankMoney) == "function" then
        bank = tonumber(vRP.getBankMoney(userId)) or 0
    end
    if type(vRP.getMoney) == "function" then
        wallet = tonumber(vRP.getMoney(userId)) or 0
    end
    if type(vRP.getMultas) == "function" then
        fines = tonumber(vRP.getMultas(userId)) or 0
    end

    return {
        id = userId,
        online = online,
        source = playerSource,
        name = (tostring(identity.nome) .. " " .. tostring(identity.sobrenome)):gsub("%s+", " "),
        identity = identity,
        bank = bank,
        wallet = wallet,
        fines = fines,
        warnings = getWarningCount(userId),
        groups = getUserGroups(userId),
        inventory = online and (not actorId or canUseAction(actorId, "inspect_inventory")) and getInventory(userId) or {},
        ping = online and (GetPlayerPing(playerSource) or 0) or 0,
        bucket = online and (GetPlayerRoutingBucket(playerSource) or 0) or 0
    }
end


-- ============================================================================
-- ALTERAÇÃO DE RG / PASSAPORTE
-- ============================================================================
-- Usa o próprio driver de banco da vRP (prepare/query/execute), portanto não
-- depende de uma global MySQL/oxmysql existir dentro deste resource.
-- Isso mantém compatibilidade com a mesma base que já é usada pelo restante
-- do painel e pelos demais scripts do servidor.
local identityEditableFields = {
    nome = { column = "nome", label = "Nome", max = 60 },
    sobrenome = { column = "sobrenome", label = "Sobrenome", max = 60 },
    idade = { column = "idade", label = "Idade", numeric = true, min = 1, maxNumber = 150 },
    telefone = { column = "telefone", label = "Telefone", max = 40 },
    registro = { column = "registro", label = "RG", max = 80 }
}

local identityDbPrepared = false
local cachedDatabaseName = nil
local cachedUserIdTables = nil
local dynamicDbStatements = {}

local function vrpPrepareStatement(name, sql)
    local fn = vRP.prepare or vRP.Prepare
    if type(fn) ~= "function" then
        return false, "O driver de banco da vRP não possui prepare/Prepare."
    end
    local ok, err = pcall(fn, name, sql)
    if not ok then
        print(("^1[%s] Erro preparando SQL (%s): %s^7"):format(GetCurrentResourceName(), tostring(name), tostring(err)))
        return false, tostring(err)
    end
    return true
end

local function vrpQueryStatement(name, params)
    local fn = vRP.query or vRP.Query
    if type(fn) ~= "function" then
        return nil, "O driver de banco da vRP não possui query/Query."
    end
    local ok, rows = pcall(fn, name, params or {})
    if not ok then
        print(("^1[%s] Erro consultando SQL (%s): %s^7"):format(GetCurrentResourceName(), tostring(name), tostring(rows)))
        return nil, tostring(rows)
    end
    return type(rows) == "table" and rows or {}
end

local function vrpExecuteStatement(name, params)
    local fn = vRP.execute or vRP.Execute or vRP.Query or vRP.query
    if type(fn) ~= "function" then
        return false, "O driver de banco da vRP não possui execute/Execute."
    end
    local ok, resultValue = pcall(fn, name, params or {})
    if not ok then
        print(("^1[%s] Erro executando SQL (%s): %s^7"):format(GetCurrentResourceName(), tostring(name), tostring(resultValue)))
        return false, tostring(resultValue)
    end
    return true, resultValue
end

local function ensureIdentityDbPrepared()
    if identityDbPrepared then return true end

    local statements = {
        { "m_paineladm_v2/identity_db_name", "SELECT DATABASE() AS db" },
        { "m_paineladm_v2/identity_user_tables", [[
            SELECT TABLE_NAME
            FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = @database
              AND COLUMN_NAME = 'user_id'
        ]] },
        { "m_paineladm_v2/identity_user_reference_columns", [[
            SELECT c.TABLE_NAME, c.COLUMN_NAME
            FROM information_schema.COLUMNS c
            INNER JOIN information_schema.TABLES t
                ON t.TABLE_SCHEMA = c.TABLE_SCHEMA
               AND t.TABLE_NAME = c.TABLE_NAME
            WHERE c.TABLE_SCHEMA = @database
              AND t.TABLE_TYPE = 'BASE TABLE'
              AND LOWER(c.COLUMN_NAME) IN ('user_id', 'passport')
            ORDER BY c.TABLE_NAME, c.COLUMN_NAME
        ]] },
        { "m_paineladm_v2/identity_user_exists", "SELECT id FROM vrp_users WHERE id = @id LIMIT 1" },
        { "m_paineladm_v2/identity_row", [[
            SELECT user_id, nome, sobrenome, idade, telefone, registro
            FROM vrp_user_identities
            WHERE user_id = @id
            LIMIT 1
        ]] },
        { "m_paineladm_v2/identity_update_nome", "UPDATE vrp_user_identities SET nome = @value WHERE user_id = @id" },
        { "m_paineladm_v2/identity_update_sobrenome", "UPDATE vrp_user_identities SET sobrenome = @value WHERE user_id = @id" },
        { "m_paineladm_v2/identity_update_idade", "UPDATE vrp_user_identities SET idade = @value WHERE user_id = @id" },
        { "m_paineladm_v2/identity_update_telefone", "UPDATE vrp_user_identities SET telefone = @value WHERE user_id = @id" },
        { "m_paineladm_v2/identity_update_registro", "UPDATE vrp_user_identities SET registro = @value WHERE user_id = @id" },
        { "m_paineladm_v2/identity_change_master_id", "UPDATE vrp_users SET id = @to WHERE id = @from" },
        { "m_paineladm_v2/identity_delete_master_id", "DELETE FROM vrp_users WHERE id = @id" }
    }

    for _, statement in ipairs(statements) do
        local ok = vrpPrepareStatement(statement[1], statement[2])
        if not ok then return false end
    end

    identityDbPrepared = true
    return true
end

local function quoteSqlIdentifier(name)
    return "`" .. tostring(name or ""):gsub("`", "``") .. "`"
end

local function safeTableName(name)
    name = tostring(name or "")
    if name:match("^[%w_]+$") then return name end
    return nil
end

local function prepareDynamicTableStatement(kind, tableName)
    tableName = safeTableName(tableName)
    if not tableName then return nil, "Nome de tabela inválido." end

    local cacheKey = kind .. ":" .. tableName
    if dynamicDbStatements[cacheKey] then return dynamicDbStatements[cacheKey] end

    local statementName = ("m_paineladm_v2/identity_%s_%s"):format(kind, tableName)
    local sql
    if kind == "exists" then
        sql = ("SELECT user_id FROM %s WHERE user_id = @id LIMIT 1"):format(quoteSqlIdentifier(tableName))
    elseif kind == "move" then
        sql = ("UPDATE %s SET user_id = @to WHERE user_id = @from"):format(quoteSqlIdentifier(tableName))
    else
        return nil, "Operação SQL dinâmica inválida."
    end

    local ok, err = vrpPrepareStatement(statementName, sql)
    if not ok then return nil, err end
    dynamicDbStatements[cacheKey] = statementName
    return statementName
end

local function databaseName()
    if cachedDatabaseName and cachedDatabaseName ~= "" then return cachedDatabaseName end
    if not ensureIdentityDbPrepared() then return nil, "Não foi possível iniciar o acesso ao banco pela vRP." end

    local rows, err = vrpQueryStatement("m_paineladm_v2/identity_db_name", {})
    if not rows then return nil, err end
    local row = rows[1]
    local name = row and tostring(row.db or "") or ""
    if name == "" then return nil, "Não foi possível identificar o banco de dados atual." end

    cachedDatabaseName = name
    return name
end

local function getUserIdTablesForIdentityChange(refresh)
    if cachedUserIdTables and not refresh then return cachedUserIdTables end

    local dbName, dbErr = databaseName()
    if not dbName then return nil, dbErr end

    local rows, err = vrpQueryStatement("m_paineladm_v2/identity_user_tables", { database = dbName })
    if not rows then return nil, err end

    local seen, tables = {}, {}
    for _, row in ipairs(rows) do
        local tableName = safeTableName(row.TABLE_NAME or row.table_name)
        if tableName and not seen[tableName] then
            seen[tableName] = true
            tables[#tables + 1] = tableName
        end
    end

    table.sort(tables)
    cachedUserIdTables = tables
    return tables
end

local function userIdExistsAnywhere(userId, tables)
    if not ensureIdentityDbPrepared() then return nil, "Não foi possível iniciar o banco pela vRP." end

    local rows, err = vrpQueryStatement("m_paineladm_v2/identity_user_exists", { id = userId })
    if not rows then return nil, err end
    if rows[1] then return true end

    for _, tableName in ipairs(tables or {}) do
        local statement, prepErr = prepareDynamicTableStatement("exists", tableName)
        if not statement then return nil, prepErr end
        local foundRows, queryErr = vrpQueryStatement(statement, { id = userId })
        if not foundRows then return nil, queryErr end
        if foundRows[1] then return true end
    end

    return false
end

identityRow = function(userId)
    userId = tonumber(userId)
    if not userId then return nil, "Passaporte inválido." end

    -- Aqui o banco é a fonte de verdade. Na v2.62 a função consultava
    -- vRP.getUserIdentity primeiro; em bases que cacheiam a identidade durante a
    -- sessão isso fazia o painel mostrar o valor antigo mesmo após o UPDATE.
    if ensureIdentityDbPrepared() then
        local rows, err = vrpQueryStatement("m_paineladm_v2/identity_row", { id = userId })
        if rows and rows[1] then
            local row = rows[1]
            return {
                nome = row.nome or "",
                sobrenome = row.sobrenome or "",
                idade = row.idade or "",
                telefone = row.telefone or "",
                registro = row.registro or ""
            }
        elseif err then
            return nil, err
        end
    end

    -- Compatibilidade de emergência se o driver SQL da vRP estiver indisponível.
    local okIdentity, identity = pcall(vRP.getUserIdentity, userId)
    if okIdentity and type(identity) == "table" then
        return {
            nome = identity.nome or identity.name or "",
            sobrenome = identity.sobrenome or identity.firstname or identity.name2 or "",
            idade = identity.idade or identity.age or "",
            telefone = identity.telefone or identity.phone or "",
            registro = identity.registro or identity.registration or ""
        }
    end

    return nil, "Passaporte não encontrado."
end

local function copyIdentity(identity)
    identity = type(identity) == "table" and identity or {}
    return {
        nome = tostring(identity.nome or ""),
        sobrenome = tostring(identity.sobrenome or ""),
        idade = tonumber(identity.idade) or identity.idade or "",
        telefone = tostring(identity.telefone or ""),
        registro = tostring(identity.registro or "")
    }
end

local function publishIdentityLiveUpdate(targetId, identity)
    targetId = tonumber(targetId)
    if not targetId or type(identity) ~= "table" then return end

    local fresh = copyIdentity(identity)

    -- A identity.lua da base mantém vRP.getUserIdentity em cache. Depois que o
    -- UPDATE já foi persistido, invalidamos esse cache imediatamente para que
    -- TODOS os outros resources que chamarem getUserIdentity recebam o dado novo.
    if type(vRP.updateIdentity) == "function" then
        pcall(vRP.updateIdentity, targetId)
    end

    liveIdentityOverrides[targetId] = fresh

    local payload = {
        id = targetId,
        identity = fresh,
        name = (tostring(fresh.nome) .. " " .. tostring(fresh.sobrenome)):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    }

    local targetSource = vRP.getUserSource(targetId)
    local sent = {}

    -- O número de registro/placa pessoal é mantido no client pela vRP clássica.
    -- Atualizá-lo evita que o RG antigo continue em memória até o próximo spawn.
    if targetSource then
        targetSource = tonumber(targetSource)
        pcall(function()
            vRPclient._setRegistrationNumber(targetSource, fresh.registro ~= "" and fresh.registro or "000AAA")
        end)

        -- State bag namespaced: deixa os dados novos disponíveis imediatamente para
        -- HUDs/identidades que queiram consumir o evento/estado sem relogar.
        pcall(function()
            local player = Player(targetSource)
            if player and player.state then
                player.state:set("m_paineladm_identity", payload.identity, true)
            end
        end)

        TriggerClientEvent("m_paineladm_v2:identityLiveUpdated", targetSource, payload)
        sent[targetSource] = true
    end

    -- Atualiza simultaneamente qualquer staff que esteja com o Painel ADM aberto.
    for userId, playerSource in pairs(vRP.getUsers() or {}) do
        userId = tonumber(userId)
        playerSource = tonumber(playerSource)
        if userId and playerSource and canOpen(userId) and not sent[playerSource] then
            TriggerClientEvent("m_paineladm_v2:identityLiveUpdated", playerSource, payload)
            sent[playerSource] = true
        end
    end

    -- Atualiza também qualquer chamado ATIVO que ainda carregue o nome antigo.
    -- Histórico concluído não é reescrito, porque deve preservar o nome usado na
    -- época da ação; somente informações vivas são sincronizadas.
    local callsChanged = false
    for _, call in pairs(activeCalls or {}) do
        if tonumber(call.playerId) == targetId then
            call.playerName = payload.name
            callsChanged = true
        end
        if tonumber(call.acceptedById) == targetId then
            call.acceptedByName = payload.name
            callsChanged = true
        end
    end
    if callsChanged then pushCallsPanelUpdate() end

    -- Além do patch pontual acima, envia a lista ONLINE completa novamente para
    -- todas as staffs. Isso sincroniza lista da aba Jogadores, card selecionado,
    -- nome do próprio administrador e qualquer painel aberto mesmo se algum frame
    -- da mensagem identityLiveUpdated tiver sido perdido pela NUI.
    local playersNow = getPlayers()
    local statsNow = getOnlineStats(playersNow)
    for userId, playerSource in pairs(vRP.getUsers() or {}) do
        userId = tonumber(userId)
        playerSource = tonumber(playerSource)
        if userId and playerSource and canOpen(userId) then
            TriggerClientEvent("m_paineladm_v2:playersLiveUpdated", playerSource, {
                players = playersNow,
                stats = statsNow,
                changedId = targetId
            })
        end
    end

    -- Compatibilidade com bases vRP/vrpex que mantêm a identidade em cache.
    -- Diversos resources de identidade dessa família usam este hook para
    -- invalidar/recarregar os dados do jogador sem exigir relog.
    TriggerEvent("identity:atualizar", targetId)

    -- Hook namespaced do próprio painel para integrações adicionais da cidade.
    TriggerEvent("m_paineladm_v2:identityUpdated", targetId, fresh, targetSource)
end

local function identityEditorSnapshot(userId)
    local identity, err = identityRow(userId)
    if not identity then return nil, err end

    local online, playerSource = isOnline(userId)
    local wallet = 0
    local bank = 0

    -- A carteira desta base é o item configurado em ServerConfig.MoneyItem
    -- (por padrão "money"). getMoney lê exatamente esse saldo do inventário.
    if type(vRP.getMoney) == "function" then
        local okWallet, value = pcall(vRP.getMoney, userId)
        if okWallet then wallet = tonumber(value) or 0 end
    end

    -- O banco continua usando as próprias funções da vRP, garantindo que a
    -- alteração siga o mesmo caminho utilizado pelo restante da base.
    if type(vRP.getBankMoney) == "function" then
        local okBank, value = pcall(vRP.getBankMoney, userId)
        if okBank then bank = tonumber(value) or 0 end
    end

    return {
        id = userId,
        online = online,
        source = playerSource,
        name = (tostring(identity.nome) .. " " .. tostring(identity.sobrenome)):gsub("%s+", " "),
        identity = identity,
        wallet = math.max(0, math.floor(wallet)),
        bank = math.max(0, math.floor(bank))
    }
end

local function updateIdentityBalance(targetId, account, value)
    targetId = tonumber(targetId)
    account = tostring(account or "")
    local newAmount = tonumber(value)

    if not targetId or (account ~= "wallet" and account ~= "bank") then
        return false, "Saldo inválido."
    end
    if not newAmount or newAmount < 0 then
        return false, "Informe um valor válido maior ou igual a zero."
    end

    newAmount = math.floor(newAmount)
    local maxAmount = tonumber(ServerConfig.Limits and ServerConfig.Limits.maxAmount) or 1000000000
    if newAmount > maxAmount then
        return false, ("O valor máximo permitido é R$ %d."):format(maxAmount)
    end

    if account == "wallet" then
        local online = isOnline(targetId)
        if not online then
            return false, "O jogador precisa estar online para alterar a carteira, pois o dinheiro fica no inventário."
        end
        if type(vRP.getMoney) ~= "function" then
            return false, "A função de consultar a carteira não está disponível na vRP."
        end
        if type(vRP.tryGetInventoryItem) ~= "function" or type(vRP.giveInventoryItem) ~= "function" then
            return false, "As funções de inventário necessárias para alterar a carteira não estão disponíveis na vRP."
        end

        local current = math.max(0, math.floor(tonumber(vRP.getMoney(targetId)) or 0))
        if current == newAmount then return true, newAmount end

        -- Faz uma substituição real do saldo do inventário: remove o valor
        -- atual e entrega exatamente o novo valor solicitado.
        if current > 0 then
            local removed = vRP.tryGetInventoryItem(targetId, ServerConfig.MoneyItem, current, true)
            if removed == false then
                return false, "Não foi possível remover o saldo atual da carteira."
            end
        end

        if newAmount > 0 then
            vRP.giveInventoryItem(targetId, ServerConfig.MoneyItem, newAmount, true)
        end

        return true, newAmount
    end

    if type(vRP.getBankMoney) ~= "function" or type(vRP.setBankMoney) ~= "function" then
        return false, "As funções bancárias não estão disponíveis na vRP."
    end

    vRP.setBankMoney(targetId, newAmount)
    return true, newAmount
end

local function updateIdentityValue(targetId, fieldName, value)
    local definition = identityEditableFields[fieldName]
    if not definition then return false, "Campo de identidade inválido." end

    local normalized
    if definition.numeric then
        local number = tonumber(value)
        if not number then return false, "Informe uma idade válida." end
        number = math.floor(number)
        if number < (definition.min or 1) or number > (definition.maxNumber or 150) then
            return false, "Informe uma idade válida."
        end
        normalized = number
    else
        normalized = trim(value)
        if normalized == "" then
            return false, ("Informe um valor válido para %s."):format(definition.label)
        end
        local maxLen = tonumber(definition.max) or 80
        if #normalized > maxLen then normalized = normalized:sub(1, maxLen) end
    end

    if not ensureIdentityDbPrepared() then
        return false, "Não foi possível iniciar o acesso ao banco pela vRP."
    end

    local statementName = "m_paineladm_v2/identity_update_" .. fieldName
    local ok, err = vrpExecuteStatement(statementName, { value = normalized, id = targetId })
    if not ok then
        local msg = tostring(err or "")
        if msg:lower():find("duplicate", 1, true) then
            return false, ("Este %s já está em uso."):format(definition.label)
        end
        return false, "Não foi possível salvar esta informação."
    end

    return true, normalized
end

local function moveUserIdInTable(tableName, fromId, toId)
    local statement, err = prepareDynamicTableStatement("move", tableName)
    if not statement then return false, err end
    return vrpExecuteStatement(statement, { from = fromId, to = toId })
end

local function changeUserIdAcrossDatabase(oldId, newId)
    if oldId == newId then
        return false, "O novo ID precisa ser diferente do atual."
    end

    local tables, err = getUserIdTablesForIdentityChange(true)
    if not tables then return false, err or "Não foi possível mapear as tabelas do banco." end

    local oldExists, oldErr = userIdExistsAnywhere(oldId, tables)
    if oldExists == nil then return false, oldErr end
    if not oldExists then return false, ("ID atual %d não encontrado."):format(oldId) end

    local newExists, newErr = userIdExistsAnywhere(newId, tables)
    if newExists == nil then return false, newErr end
    if newExists then return false, "ID JÁ EM USO" end

    -- A base disponibiliza o banco através da própria vRP. Atualizamos todas as
    -- tabelas com user_id e, se algo falhar, tentamos desfazer o que já foi
    -- alterado antes de retornar erro. vrp_users.id é alterado por último.
    local movedTables = {}

    for _, tableName in ipairs(tables) do
        local ok, moveErr = moveUserIdInTable(tableName, oldId, newId)
        if not ok then
            for i = #movedTables, 1, -1 do
                pcall(moveUserIdInTable, movedTables[i], newId, oldId)
            end
            return false, ("Falha ao atualizar a tabela %s: %s"):format(tableName, tostring(moveErr or "erro SQL"))
        end
        movedTables[#movedTables + 1] = tableName
    end

    if not ensureIdentityDbPrepared() then
        for i = #movedTables, 1, -1 do pcall(moveUserIdInTable, movedTables[i], newId, oldId) end
        return false, "Não foi possível preparar a alteração do Passaporte."
    end

    local masterOk, masterErr = vrpExecuteStatement("m_paineladm_v2/identity_change_master_id", { from = oldId, to = newId })
    if not masterOk then
        for i = #movedTables, 1, -1 do
            pcall(moveUserIdInTable, movedTables[i], newId, oldId)
        end
        return false, "Não foi possível alterar o ID principal: " .. tostring(masterErr or "erro SQL")
    end

    return true
end

-- ============================================================================
-- LIMPAR DADOS ID
-- ============================================================================
-- Mapeia referências diretas de personagem usadas pelas bases vRP/VRPex e
-- Creative: `user_id` e `passport`. Não apagamos colunas genéricas chamadas
-- apenas `id`, pois normalmente são chaves primárias de registros sem relação
-- direta com o jogador. O registro mestre vrp_users.id é removido por último.
local cachedUserReferenceColumns = nil
local wipeDynamicStatements = {}

local function getUserReferenceColumnsForWipe(refresh)
    if cachedUserReferenceColumns and not refresh then return cachedUserReferenceColumns end

    local dbName, dbErr = databaseName()
    if not dbName then return nil, dbErr end
    if not ensureIdentityDbPrepared() then return nil, "Não foi possível iniciar o acesso ao banco pela vRP." end

    local rows, err = vrpQueryStatement("m_paineladm_v2/identity_user_reference_columns", { database = dbName })
    if not rows then return nil, err end

    local output, seen = {}, {}
    for _, row in ipairs(rows) do
        local tableName = safeTableName(row.TABLE_NAME or row.table_name)
        local columnName = safeTableName(row.COLUMN_NAME or row.column_name)
        if tableName and columnName and tableName ~= "vrp_users" then
            local key = tableName .. ":" .. columnName
            if not seen[key] then
                seen[key] = true
                output[#output + 1] = { tableName = tableName, columnName = columnName }
            end
        end
    end

    cachedUserReferenceColumns = output
    return output
end

local function prepareWipeDeleteStatement(tableName, columnName)
    tableName = safeTableName(tableName)
    columnName = safeTableName(columnName)
    if not tableName or not columnName then return nil, "Tabela/coluna inválida." end

    local cacheKey = tableName .. ":" .. columnName
    if wipeDynamicStatements[cacheKey] then return wipeDynamicStatements[cacheKey] end

    local statementName = ("m_paineladm_v2/wipe_%s_%s"):format(tableName, columnName)
    local sql = ("DELETE FROM %s WHERE %s = @id"):format(quoteSqlIdentifier(tableName), quoteSqlIdentifier(columnName))
    local ok, err = vrpPrepareStatement(statementName, sql)
    if not ok then return nil, err end

    wipeDynamicStatements[cacheKey] = statementName
    return statementName
end

local function purgePanelDataForUser(userId)
    userId = tonumber(userId)
    if not userId then return end
    local key = tostring(userId)

    -- Não deixa uma pessoa futura que reutilize o ID herdar advertências/castigo.
    warningStore.active[key] = nil
    warningStore.counts[key] = nil
    punishmentAppliedSources[key] = nil
    for i = #(warningStore.history or {}), 1, -1 do
        if tonumber(warningStore.history[i].targetId) == userId then
            table.remove(warningStore.history, i)
        end
    end
    saveWarningStore()

    -- Remove sobrescritas de identidade em memória do próprio painel e invalida
    -- também o cache central da vRP/identity.lua, evitando que consultas feitas
    -- depois da limpeza ainda recebam nome/idade antigos deste Passaporte.
    liveIdentityOverrides[userId] = nil
    if type(vRP.updateIdentity) == "function" then
        pcall(vRP.updateIdentity, userId)
    end
    TriggerEvent("identity:atualizar", userId)

    -- Chamados ainda abertos do jogador não podem sobreviver à exclusão do ID.
    local callsChanged = false
    for callId, call in pairs(activeCalls or {}) do
        if tonumber(call.playerId) == userId then
            activeCalls[callId] = nil
            callsChanged = true
        end
    end
    lastCallCreatedAt[userId] = nil

    if callsChanged then pushCallsPanelUpdate() end
    pushWarningStateToStaff()
end

local function wipeUserDataAcrossDatabase(userId)
    userId = tonumber(userId)
    if not userId then return false, "Informe um Passaporte / ID válido." end
    if not ensureIdentityDbPrepared() then
        return false, "Não foi possível iniciar o acesso ao banco pela vRP."
    end

    local masterRows, masterErr = vrpQueryStatement("m_paineladm_v2/identity_user_exists", { id = userId })
    if not masterRows then return false, masterErr or "Não foi possível consultar o ID." end
    if not masterRows[1] then return false, ("ID %d não encontrado."):format(userId) end

    local refs, refsErr = getUserReferenceColumnsForWipe(true)
    if not refs then return false, refsErr or "Não foi possível mapear os dados vinculados ao ID." end

    -- Prepara todos os comandos ANTES de apagar qualquer linha. Assim um nome de
    -- tabela/coluna incompatível não deixa uma limpeza pela metade.
    local prepared = {}
    for _, ref in ipairs(refs) do
        local statement, prepErr = prepareWipeDeleteStatement(ref.tableName, ref.columnName)
        if not statement then
            return false, ("Não foi possível preparar a limpeza de %s.%s: %s"):format(
                tostring(ref.tableName), tostring(ref.columnName), tostring(prepErr or "erro SQL")
            )
        end
        prepared[#prepared + 1] = {
            statement = statement,
            tableName = ref.tableName,
            columnName = ref.columnName
        }
    end

    local cleaned = {}
    for _, item in ipairs(prepared) do
        local ok, execErr = vrpExecuteStatement(item.statement, { id = userId })
        if not ok then
            return false, ("Falha ao limpar %s.%s: %s. A limpeza foi interrompida."):format(
                tostring(item.tableName), tostring(item.columnName), tostring(execErr or "erro SQL")
            )
        end
        cleaned[item.tableName] = true
    end

    -- vrp_users por último: enquanto este registro existir o ID ainda pertence
    -- ao jogador. Depois deste DELETE ele fica livre para ser setado em outro.
    local masterOk, deleteErr = vrpExecuteStatement("m_paineladm_v2/identity_delete_master_id", { id = userId })
    if not masterOk then
        return false, "Os dados relacionados foram limpos, mas não foi possível liberar o ID principal: " .. tostring(deleteErr or "erro SQL")
    end

    local tableCount = 0
    for _ in pairs(cleaned) do tableCount = tableCount + 1 end
    return true, tableCount
end

function API.getIdentityEditor(data)
    local playerSource = source
    local actorId = requireAction(playerSource, "view_identity_editor")
    if not actorId then return result(false, "Sem permissão.") end

    local targetId = toInt(type(data) == "table" and (data.targetId or data.id) or data)
    if not targetId then return result(false, "Informe um passaporte válido.") end

    local snapshot, err = identityEditorSnapshot(targetId)
    if not snapshot then return result(false, err or "Passaporte não encontrado.") end
    return result(true, "Dados carregados.", snapshot)
end

function API.updateIdentity(data)
    local playerSource = source
    data = type(data) == "table" and data or {}

    local targetId = toInt(data.targetId)
    if not targetId then return result(false, "Informe um passaporte válido.") end

    local operation = tostring(data.operation or data.mode or "field")

    if operation == "balance" then
        local actorId = requireAction(playerSource, "edit_identity_balance")
        if not actorId then return result(false, "Sem permissão.") end

        local account = tostring(data.field or data.account or "")
        if account ~= "wallet" and account ~= "bank" then
            return result(false, "Saldo inválido.")
        end

        local before, beforeErr = identityEditorSnapshot(targetId)
        if not before then return result(false, beforeErr or "Passaporte não encontrado.") end

        local ok, savedOrErr = updateIdentityBalance(targetId, account, data.value)
        if not ok then return result(false, savedOrErr or "Não foi possível alterar o saldo.") end

        local label = account == "wallet" and "Carteira" or "Banco"
        local oldValue = tonumber(before[account]) or 0
        webhookLog(actorId, "edit_identity_balance",
            ("%s: R$ %d -> R$ %d"):format(label, oldValue, tonumber(savedOrErr) or 0), targetId)

        local updated, snapshotErr = identityEditorSnapshot(targetId)
        if not updated then
            return result(false, snapshotErr or "Saldo alterado, mas não foi possível recarregar os dados.")
        end

        return result(true, ("%s atualizado para R$ %d."):format(label, tonumber(savedOrErr) or 0), updated)
    end

    if operation == "id" then
        local actorId = requireAction(playerSource, "change_user_id")
        if not actorId then return result(false, "Sem permissão.") end

        local newId = toInt(data.value or data.newId)
        if not newId then return result(false, "Informe um novo ID válido.") end

        local before, beforeErr = identityEditorSnapshot(targetId)
        if not before then return result(false, beforeErr or "Passaporte não encontrado.") end

        local targetOnline, targetSource = isOnline(targetId)
        if targetOnline then
            if targetSource == playerSource then
                return result(false, "Para alterar o seu próprio ID, faça a alteração com este personagem offline usando outro staff.")
            end

            notify(targetSource, "aviso", "Seu Passaporte / ID será alterado pela administração. Reconecte ao servidor após a alteração.", 8000)
            Wait(350)
            vRP.kick(targetSource, "Seu Passaporte / ID está sendo alterado pela administração. Reconecte ao servidor em alguns segundos.")

            local attempts = 0
            while vRP.getUserSource(targetId) and attempts < 30 do
                Wait(100)
                attempts = attempts + 1
            end

            if vRP.getUserSource(targetId) then
                return result(false, "O jogador ainda está conectado. Aguarde alguns segundos e tente novamente.")
            end
        end

        local success, changeErr = changeUserIdAcrossDatabase(targetId, newId)
        if not success then return result(false, changeErr or "Não foi possível alterar o ID.") end

        webhookLog(actorId, "change_user_id",
            ("Passaporte %d -> %d"):format(targetId, newId), targetId, { targetName = tostring(before.name or "-") })

        local updated = identityEditorSnapshot(newId)
        if not updated then
            return result(true, ("ID alterado com sucesso: %d -> %d."):format(targetId, newId), {
                id = newId,
                online = false,
                source = nil,
                name = before.name,
                identity = before.identity
            })
        end

        return result(true, ("ID alterado com sucesso: %d -> %d. O ID %d ficou livre."):format(targetId, newId, targetId), updated)
    end

    local actorId = requireAction(playerSource, "edit_identity")
    if not actorId then return result(false, "Sem permissão.") end

    local fieldName = tostring(data.field or "")
    local definition = identityEditableFields[fieldName]
    if not definition then return result(false, "Campo de identidade inválido.") end

    local exists, existsErr = identityEditorSnapshot(targetId)
    if not exists then return result(false, existsErr or "Passaporte não encontrado.") end

    local ok, savedOrErr = updateIdentityValue(targetId, fieldName, data.value)
    if not ok then return result(false, savedOrErr or "Não foi possível salvar.") end

    -- O UPDATE já terminou. Invalida imediatamente o cache central da identity.lua
    -- antes de qualquer outro resource consultar novamente o jogador.
    if type(vRP.updateIdentity) == "function" then
        pcall(vRP.updateIdentity, targetId)
    end

    -- Reconsulta o registro direto do banco e publica a identidade nova para o
    -- jogador + todos os painéis abertos, sem exigir reconnect (exceto mudança de ID).
    local freshIdentity = identityRow(targetId)
    if freshIdentity then
        publishIdentityLiveUpdate(targetId, freshIdentity)
    end

    webhookLog(actorId, "edit_identity",
        ("Campo %s alterado"):format(tostring(definition.label or fieldName)), targetId)

    local updated, snapshotErr = identityEditorSnapshot(targetId)
    if not updated then return result(false, snapshotErr or "Alteração salva, mas não foi possível recarregar os dados.") end

    return result(true, ("%s atualizado com sucesso."):format(definition.label), updated)
end


function API.warnings(data)
    local playerSource = source
    data = type(data) == "table" and data or {}
    local mode = tostring(data.mode or "list")

    if mode == "delete" then
        local actorId = requireAction(playerSource, "delete_warning")
        if not actorId then return result(false, "Sem permissão para excluir advertências.") end

        local warningId = toInt(data.warningId)
        local targetId = toInt(data.targetId)
        if not warningId or not targetId then return result(false, "Advertência inválida.") end

        local removed = nil
        for index = #(warningStore.history or {}), 1, -1 do
            local entry = warningStore.history[index]
            if tonumber(entry.id) == warningId and tonumber(entry.targetId) == targetId then
                removed = table.remove(warningStore.history, index)
                break
            end
        end
        if not removed then return result(false, "Advertência não encontrada.") end

        local key = tostring(targetId)
        local count = 0
        for _, entry in ipairs(warningStore.history or {}) do
            if tonumber(entry.targetId) == targetId then count = count + 1 end
        end
        warningStore.counts[key] = count
        if count <= 0 then warningStore.counts[key] = nil end

        local active = warningStore.active[key]
        if active and tonumber(active.warningId) == warningId then
            finishPunishment(targetId, true)
        else
            saveWarningStore()
        end

        webhookLog(actorId, "delete_warning", ("Advertência #%d | Motivo: %s"):format(
            warningId, tostring(removed.reason or "-")
        ), targetId)

        pushWarningStateToStaff()
        return result(true, "Advertência excluída com sucesso.", {
            summary = warningSummaryPayload(),
            player = warningDetailPayload(targetId),
            targetId = targetId,
            warningId = warningId
        })
    end

    local actorId = requireAction(playerSource, "view_warnings")
    if not actorId then return result(false, "Sem permissão para visualizar advertências.") end

    if mode == "detail" then
        local targetId = toInt(data.targetId)
        if not targetId then return result(false, "Jogador inválido.") end
        return result(true, "Advertências carregadas.", warningDetailPayload(targetId))
    end

    return result(true, "Advertências carregadas.", warningSummaryPayload())
end


function API.getBanHistory()
    local playerSource = source
    local actorId = requireAction(playerSource, "ban_history")
    if not actorId then return result(false, "Sem permissão para visualizar os registros de ban e unban.") end

    local entries = {}
    for i = #(banHistoryStore.entries or {}), 1, -1 do
        entries[#entries + 1] = banHistoryStore.entries[i]
    end

    webhookLog(actorId, "ban_history_view", ("%d registro(s) carregado(s)"):format(#entries))
    return result(true, "Registros carregados.", { entries = entries })
end


local function getNeedsEnabledState()
    local ok, enabled = pcall(function()
        return exports["vrp"]:areNeedsEnabled()
    end)

    if ok then return enabled == true end
    return GlobalState.needsEnabled ~= false
end

local function getNeedsSettingsState()
    local ok, settings = pcall(function()
        return exports["vrp"]:getNeedsSettings()
    end)

    if ok and type(settings) == "table" then
        return settings
    end

    local fallback = GlobalState.needsSettings
    if type(fallback) == "table" then return fallback end

    return {
        hungerPerMinute = 0.35,
        thirstPerMinute = 0.50,
        hungerDamage = 5,
        thirstDamage = 5,
        starvationCheckMs = 10000
    }
end

function API.updateNeedsSettings(data)
    local playerSource = source
    local actorId = requireAction(playerSource, "needs_manage")
    if not actorId then return result(false, "Sem permissão para configurar fome e sede.") end
    if not getNeedsEnabledState() then
        return result(false, "Ative a fome e sede antes de alterar as configurações.")
    end

    data = type(data) == "table" and data or {}
    local hungerPerMinute = tonumber(data.hungerPerMinute)
    local thirstPerMinute = tonumber(data.thirstPerMinute)
    local hungerDamage = tonumber(data.hungerDamage)
    local thirstDamage = tonumber(data.thirstDamage)

    if not hungerPerMinute or hungerPerMinute < 0 or hungerPerMinute > 100
        or not thirstPerMinute or thirstPerMinute < 0 or thirstPerMinute > 100 then
        return result(false, "A velocidade deve ficar entre 0 e 100% por minuto.")
    end

    if not hungerDamage or hungerDamage < 0 or hungerDamage > 100 or hungerDamage ~= math.floor(hungerDamage)
        or not thirstDamage or thirstDamage < 0 or thirstDamage > 100 or thirstDamage ~= math.floor(thirstDamage) then
        return result(false, "O dano deve ser um número inteiro entre 0 e 100.")
    end

    local ok, settingsOrError = pcall(function()
        return exports["vrp"]:setNeedsSettings({
            hungerPerMinute = hungerPerMinute,
            thirstPerMinute = thirstPerMinute,
            hungerDamage = hungerDamage,
            thirstDamage = thirstDamage
        })
    end)

    if not ok or type(settingsOrError) ~= "table" then
        return result(false, "Não foi possível comunicar com as configurações de fome e sede da vRP.")
    end

    local settings = settingsOrError
    TriggerClientEvent("m_paineladm_v2:needsSettingsSync", -1, settings)
    webhookLog(actorId, "needs_settings", ("Fome %.3f%%/min, dano %d | Sede %.3f%%/min, dano %d"):format(
        tonumber(settings.hungerPerMinute) or hungerPerMinute, tonumber(settings.hungerDamage) or hungerDamage,
        tonumber(settings.thirstPerMinute) or thirstPerMinute, tonumber(settings.thirstDamage) or thirstDamage
    ))

    return result(true, "Velocidade e dano de fome/sede atualizados em tempo real.", {
        needsEnabled = true,
        needsSettings = settings
    })
end


local function getRadioAdminData()
    local state = GetResourceState('radio')
    if state ~= 'started' then
        return { available = false, radios = {}, resourceState = state, message = 'O resource radio não está iniciado.' }
    end
    local ok, radios = pcall(function() return exports['radio']:getPrivateRadios() end)
    if not ok or type(radios) ~= 'table' then
        return { available = false, radios = {}, resourceState = state, message = 'O resource radio não expôs a configuração esperada.' }
    end
    return { available = true, radios = radios, resourceState = state }
end

function API.radioAdmin(data)
    local playerSource = source
    data = type(data) == 'table' and data or {}
    local mode = tostring(data.mode or 'list')

    if mode == 'list' then
        local actorId = requireAction(playerSource, 'view_radio')
        if not actorId then return result(false, 'Sem permissão para acessar as rádios privadas.') end
        local payload = getRadioAdminData()
        return result(payload.available, payload.message or 'Rádios privadas atualizadas.', payload)
    end

    local actorId = requireAction(playerSource, 'radio_manage')
    if not actorId then return result(false, 'Sem permissão para alterar rádios privadas.') end
    if GetResourceState('radio') ~= 'started' then return result(false, 'O resource radio não está iniciado.') end

    if mode == 'save' then
        local name = clampString(data.name, 60)
        local channel = toInt(data.channel)
        local permissions = data.permissions
        if name == '' then return result(false, 'Informe o nome da rádio.') end
        if not channel or channel > 9999 then return result(false, 'Informe uma frequência inteira entre 1 e 9999.') end
        if type(permissions) == 'string' then
            local list = {}
            for part in permissions:gmatch('[^,;\n]+') do
                local permission = clampString(part, 80):gsub('^%s+', ''):gsub('%s+$', '')
                if permission ~= '' then list[#list + 1] = permission end
            end
            permissions = list
        end
        if type(permissions) ~= 'table' or #permissions == 0 then return result(false, 'Informe ao menos uma permissão.') end

        local ok, response = pcall(function()
            return exports['radio']:upsertPrivateRadio({
                id = data.id,
                name = name,
                channel = channel,
                permissions = permissions,
                enabled = data.enabled ~= false
            })
        end)
        if not ok or type(response) ~= 'table' then return result(false, 'Falha ao salvar a rádio no resource radio.') end
        if response.ok ~= true then return result(false, response.message or 'Não foi possível salvar a rádio.') end
        webhookLog(actorId, 'radio_save', ('%s | Frequência %d | Permissões: %s'):format(name, channel, table.concat(permissions, ', ')))
        local payload = { available = true, radios = response.radios or {}, resourceState = 'started' }
        TriggerClientEvent('m_paineladm_v2:radioUpdated', -1, payload)
        return result(true, response.message or 'Rádio salva.', payload)
    end

    if mode == 'delete' then
        local id = toInt(data.id)
        if not id then return result(false, 'Rádio inválida.') end
        local ok, response = pcall(function() return exports['radio']:deletePrivateRadio(id) end)
        if not ok or type(response) ~= 'table' then return result(false, 'Falha ao remover a rádio no resource radio.') end
        if response.ok ~= true then return result(false, response.message or 'Não foi possível remover a rádio.') end
        webhookLog(actorId, 'radio_delete', ('ID interno %d'):format(id))
        local payload = { available = true, radios = response.radios or {}, resourceState = 'started' }
        TriggerClientEvent('m_paineladm_v2:radioUpdated', -1, payload)
        return result(true, response.message or 'Rádio removida.', payload)
    end

    return result(false, 'Operação de rádio inválida.')
end

function API.vipAdmin(data)
    local playerSource = source
    data = type(data) == "table" and data or {}
    local mode = tostring(data.mode or "list")

    if mode == "list" then
        local actorId = requireAction(playerSource, "view_vips")
        if not actorId then return result(false, "Sem permissão.") end
        return result(true, "VIPs atualizados.", VIP.publicAdminData())
    end

    if mode == "save" then
        local permission = VIP.trim(data.originalGroup) == "" and "create_vip" or "edit_vip"
        local actorId = requireAction(playerSource, permission)
        if not actorId then return result(false, "Sem permissão.") end

        local originalGroup = VIP.trim(data.originalGroup, 80)
        local groupName = VIP.trim(data.group, 80)
        local title = VIP.trim(data.title, 80)
        local salary = math.max(0, math.floor(tonumber(data.salary) or 0))
        if groupName == "" or title == "" then return result(false, "Informe o nome do VIP e o cargo da vRP.") end
        if groupName:find("[%[%]{}\"']") then return result(false, "O nome do cargo contém caracteres inválidos.") end

        local existing = originalGroup ~= "" and VIP.findManaged(originalGroup) or nil
        local permissions = existing and type(existing.permissions) == "table" and existing.permissions or {}
        if #permissions == 0 then
            local auto = VIP.defaultPermission(groupName)
            if auto then permissions = { auto } end
        end

        local items = VIP.normalizeItems(data.items)
        local vehicles = VIP.normalizeVehicles(data.vehicles)
        local choices = math.max(0, math.floor(tonumber(data.vehicleChoices) or 0))
        local garageSlots = math.max(0, math.min(1000, math.floor(tonumber(data.garageSlots) or 0)))
        if #vehicles > 0 then
            choices = math.max(1, math.min(choices > 0 and choices or 1, #vehicles))
        else
            choices = 0
        end

        local ok, saved, message = pcall(function()
            local success, msg = exports["vrp"]:saveManagedGroup(originalGroup, {
                name = groupName,
                config = { gtype = "vip", title = title, salario = salary },
                permissions = permissions
            })
            return success, msg
        end)
        if not ok or saved ~= true then
            return result(false, message or "Não foi possível salvar o cargo VIP na vRP.")
        end

        if originalGroup ~= "" and originalGroup ~= groupName then
            VIP.packagesStore.packages[groupName] = VIP.packagesStore.packages[originalGroup]
            VIP.packagesStore.packages[originalGroup] = nil
            for _,bucket in pairs(VIP.assignmentsStore.active) do
                if type(bucket) == "table" then
                    for _,record in pairs(bucket) do
                        if type(record) == "table" and tostring(record.group or "") == originalGroup then
                            record.group = groupName
                        end
                    end
                end
            end
            VIP.saveAssignments()
        end

        VIP.packagesStore.packages[groupName] = {
            items = items,
            vehicles = vehicles,
            vehicleChoices = choices,
            garageSlots = garageSlots,
            updatedAt = os.time()
        }
        if not VIP.savePackages() then return result(false, "Cargo salvo na vRP, mas não foi possível salvar os benefícios do VIP.") end

        webhookLog(actorId, permission, ("VIP %s | Cargo %s | Salário R$ %d | +%d vagas na garagem | %d itens | %d veículos | escolhe %d"):format(title, groupName, salary, garageSlots, #items, #vehicles, choices))
        return result(true, originalGroup == "" and "VIP criado e carregado em tempo real." or "VIP atualizado em tempo real.", VIP.publicAdminData())
    end

    if mode == "delete" then
        local actorId = requireAction(playerSource, "delete_vip")
        if not actorId then return result(false, "Sem permissão.") end
        local groupName = VIP.trim(data.group, 80)
        if groupName == "" or not VIP.findManaged(groupName) then return result(false, "VIP não encontrado.") end

        local ok, removed, message = pcall(function()
            local success, msg = exports["vrp"]:removeManagedGroup(groupName)
            return success, msg
        end)
        if not ok or removed ~= true then return result(false, message or "Não foi possível excluir o VIP da vRP.") end

        VIP.packagesStore.packages[groupName] = nil
        VIP.savePackages()
        local affectedUsers = {}
        for userIdKey,bucket in pairs(VIP.assignmentsStore.active) do
            local userId = tonumber(userIdKey)
            if userId and type(bucket) == "table" then
                for assignmentKey,record in pairs(bucket) do
                    if type(record) == "table" and tostring(record.group or "") == groupName then
                        local targetSource = vRP.getUserSource(userId)
                        if targetSource and VIP.tests[targetSource] and tonumber(VIP.tests[targetSource].assignmentId) == tonumber(record.id) then
                            local ended = VIP.endVehicleTest(targetSource, false)
                            if ended and ended.returnPosition then
                                TriggerClientEvent("m_paineladm_v2:vipTestForceStop", targetSource, ended.returnPosition)
                            end
                        end
                        bucket[assignmentKey] = nil
                        affectedUsers[userId] = true
                    end
                end
                if next(bucket) == nil then VIP.assignmentsStore.active[userIdKey] = nil end
            end
        end
        for userId in pairs(affectedUsers) do
            local targetSource = vRP.getUserSource(userId)
            if targetSource then
                local payload = VIP.choicePayload(userId, "Um VIP foi removido pela administração.")
                if payload then
                    TriggerClientEvent("m_paineladm_v2:vipChoiceOpen", targetSource, payload)
                else
                    TriggerClientEvent("m_paineladm_v2:vipChoiceClose", targetSource, "Este VIP foi removido pela administração.")
                end
            end
        end
        VIP.saveAssignments()
        webhookLog(actorId, "delete_vip", "VIP: " .. groupName)
        return result(true, "VIP excluído da vRP e removido dos jogadores que o possuíam.", VIP.publicAdminData())
    end

    if mode == "assign" then
        local actorId = requireAction(playerSource, "assign_vip")
        if not actorId then return result(false, "Sem permissão.") end
        local targetId = toInt(data.targetId)
        local groupName = VIP.trim(data.group, 80)
        local vip = VIP.findManaged(groupName)
        if not targetId or not vip then return result(false, "ID ou VIP inválido.") end

        local targetSource = vRP.getUserSource(targetId)
        if not targetSource then
            return result(false, "O jogador precisa estar online para escolher o veiculo do vip!")
        end

        local cfgData = type(vip.config) == "table" and vip.config or {}
        local package = VIP.packageFor(groupName)
        local choices = math.min(math.max(0, package.vehicleChoices), #package.vehicles)

        -- VIPs são cumulativos. Setar um novo VIP nunca remove Bronze, Prata,
        -- Ouro ou qualquer outro VIP que o jogador já possua. Cada cargo mantém
        -- sua própria validade, salário, permissões e benefícios.

        local added = vRP.addUserGroup(targetId, groupName)
        if added == false or not vRP.hasGroup(targetId, groupName) then
            return result(false, "Não foi possível setar o VIP no jogador.")
        end

        -- Atribuição explícita pelo painel sempre inicia/renova os 30 dias.
        local expiryOk, expiresAt = vRP.setUserGroupExpiration(targetId, groupName, VIP.durationSeconds)
        expiresAt = tonumber(expiresAt) or tonumber(vRP.getUserGroupExpiration(targetId, groupName)) or (os.time() + VIP.durationSeconds)
        if expiryOk == false then
            return result(false, "O VIP foi setado, mas não foi possível registrar a validade de 30 dias.")
        end

        for _,reward in ipairs(package.items) do
            vRP.giveInventoryItem(targetId, reward.item, reward.amount, true)
        end

        if choices > 0 then
            local assignmentId = VIP.assignmentsStore.nextId
            VIP.assignmentsStore.nextId = assignmentId + 1
            local bucket = VIP.assignmentBucket(targetId, true)
            bucket[tostring(assignmentId)] = {
                id = assignmentId,
                userId = targetId,
                group = groupName,
                title = tostring(cfgData.title or groupName),
                assignedAt = os.time(),
                expiresAt = expiresAt,
                remainingChoices = choices,
                totalChoices = choices,
                vehicles = package.vehicles,
                selectedVehicles = {}
            }
            VIP.saveAssignments()
        end

        notify(targetSource, "sucesso", ("Você recebeu o VIP %s por 30 dias."):format(tostring(cfgData.title or groupName)), 8000)
        if choices > 0 then
            -- Abre imediatamente e reforça a entrega do modal em seguida. Isso
            -- elimina a corrida que ocorria ao setar VIP no próprio administrador.
            VIP.ensureChoiceVisible(targetId)
        end

        webhookLog(actorId, "assign_vip", ("VIP %s | Expira %s | Itens %d | Veículos a escolher %d"):format(groupName, os.date("%d/%m/%Y %H:%M", expiresAt), #package.items, choices), targetId)
        return result(true, choices > 0 and "VIP setado. O jogador recebeu os itens e já pode escolher os veículos." or "VIP setado e benefícios entregues.", VIP.publicAdminData())
    end

    return result(false, "Operação de VIP inválida.")
end

function API.vipPlayer(data)
    local playerSource = tonumber(source)
    local userId = playerSource and vRP.getUserId(playerSource) or nil
    data = type(data) == "table" and data or {}
    if not userId then return result(false, "Jogador inválido.") end

    local mode = tostring(data.mode or "status")

    if mode == "finishTest" then
        local ended = VIP.endVehicleTest(playerSource, true)
        if not ended then return result(false, "Nenhum teste ativo.") end
        return result(true, "Teste encerrado.", ended)
    end

    -- Sempre que a NUI informar o assignmentId, trabalha exatamente sobre o
    -- VIP que está sendo exibido na tela. Isso é importante porque um jogador
    -- pode acumular vários VIPs e várias escolhas pendentes simultaneamente.
    local requestedAssignmentId = tonumber(data.assignmentId)
    local record,recordKey

    if requestedAssignmentId then
        local bucket = VIP.assignmentBucket(userId, false)
        local preferred = bucket and bucket[tostring(requestedAssignmentId)] or nil
        local preferredValid = type(preferred) == "table"
            and (tonumber(preferred.remainingChoices) or 0) > 0
            and vRP.hasGroup(userId, tostring(preferred.group or ""))

        if preferredValid then
            record,recordKey = preferred,tostring(requestedAssignmentId)
        else
            -- Nunca troca silenciosamente para outro VIP enquanto o jogador está
            -- clicando em um seletor já aberto. Retorna a pendência atual para a
            -- NUI se recuperar sem consumir uma escolha no pacote errado.
            local refreshed = VIP.choicePayload(userId)
            return result(false, "Esta escolha de VIP foi atualizada. O seletor foi recarregado.", refreshed or { completed = true })
        end
    else
        record,recordKey = VIP.currentAssignment(userId)
    end

    if type(record) ~= "table" then
        return result(false, "Você não possui uma escolha de veículo VIP pendente.", { completed = true })
    end

    if mode == "status" then
        local payload = VIP.choicePayload(userId)
        return result(payload ~= nil, payload and "Escolha pendente." or "Nenhuma escolha pendente.", payload)
    end

    local spawn = VIP.trim(data.vehicle, 100):lower()
    local allowedVehicle = nil
    for _,vehicle in ipairs(type(record.vehicles) == "table" and record.vehicles or {}) do
        if tostring(vehicle.spawn or ""):lower() == spawn then allowedVehicle = vehicle break end
    end
    if (mode == "choose" or mode == "startTest") and not allowedVehicle then
        return result(false, "Este veículo não faz parte do seu VIP.")
    end

    if mode == "choose" then
        if VIP.tests[playerSource] then return result(false, "Encerre o teste do veículo antes de confirmar sua escolha.") end
        if (tonumber(record.remainingChoices) or 0) <= 0 then return result(false, "Você já utilizou todas as escolhas deste VIP.", { completed = true }) end
        for _,selected in ipairs(type(record.selectedVehicles) == "table" and record.selectedVehicles or {}) do
            if tostring(selected):lower() == spawn then return result(false, "Você já escolheu este veículo. Escolha outro.") end
        end

        local owned = vRP.query("vRP/get_veiculos_status", { user_id = userId, veiculo = spawn }) or {}
        if owned[1] then
            return result(false, "Você já possui este veículo na garagem. Escolha outro para não perder sua escolha.")
        end

        vRP.execute("vRP/inserir_veh", { user_id = userId, veiculo = spawn, ipva = os.time(), expired = "{}" })
        record.selectedVehicles = type(record.selectedVehicles) == "table" and record.selectedVehicles or {}
        record.selectedVehicles[#record.selectedVehicles+1] = spawn
        record.remainingChoices = math.max(0, math.floor(tonumber(record.remainingChoices) or 0) - 1)
        VIP.saveAssignments()
        webhookLog(userId, "vip_vehicle_choose", ("VIP %s | Veículo: %s | Restantes: %d"):format(
            tostring(record.title or record.group or "VIP"), tostring(allowedVehicle.name or spawn), tonumber(record.remainingChoices) or 0
        ))

        if record.remainingChoices > 0 then
            local notice = record.remainingChoices == 1 and "Você pode escolher mais um veículo!" or ("Você ainda pode escolher mais %d veículos!"):format(record.remainingChoices)
            notify(playerSource, "sucesso", ("%s foi adicionado à sua garagem. %s"):format(tostring(allowedVehicle.name or spawn), notice), 8000)
            return result(true, notice, VIP.choicePayload(userId, notice, record.id or recordKey))
        end

        VIP.removeAssignment(userId, record.id or recordKey)
        VIP.saveAssignments()

        local nextPayload = VIP.choicePayload(userId, "As escolhas deste VIP foram concluídas. Você ainda possui outro VIP pendente!")
        if nextPayload then
            notify(playerSource, "sucesso", ("%s foi adicionado à sua garagem. Agora escolha o benefício do seu próximo VIP."):format(tostring(allowedVehicle.name or spawn)), 9000)
            return result(true, "Escolhas deste VIP concluídas. Próximo VIP disponível.", nextPayload)
        end

        notify(playerSource, "sucesso", ("%s foi adicionado à sua garagem. Todas as escolhas de VIP foram concluídas!"):format(tostring(allowedVehicle.name or spawn)), 9000)
        return result(true, "Veículo adicionado à garagem. Todas as escolhas concluídas.", { completed = true })
    end

    if mode == "startTest" then
        if VIP.tests[playerSource] then return result(false, "Você já está testando um veículo.") end
        if (tonumber(record.remainingChoices) or 0) <= 0 then return result(false, "Você já utilizou todas as escolhas deste VIP.", { completed = true }) end
        for _,selected in ipairs(type(record.selectedVehicles) == "table" and record.selectedVehicles or {}) do
            if tostring(selected):lower() == spawn then return result(false, "Este veículo já foi escolhido. Teste outra opção.") end
        end

        -- A posição de retorno é capturada pelo servidor. Não confiamos em
        -- coordenadas enviadas pela NUI/client para impedir teleport arbitrário.
        local ped = GetPlayerPed(playerSource)
        local coords = ped and ped > 0 and GetEntityCoords(ped) or nil
        if not coords then return result(false, "Não foi possível obter sua posição atual.") end
        local returnPosition = {
            x = tonumber(coords.x) or 0.0,
            y = tonumber(coords.y) or 0.0,
            z = tonumber(coords.z) or 0.0,
            h = (ped and ped > 0 and GetEntityHeading(ped)) or 0.0
        }
        local previousBucket = GetPlayerRoutingBucket(playerSource)
        local bucket = VIP.testBucketFor(playerSource)
        VIP.tests[playerSource] = {
            userId = userId,
            assignmentId = record.id,
            vehicle = spawn,
            previousBucket = previousBucket,
            returnPosition = returnPosition,
            startedAt = os.time()
        }
        SetPlayerRoutingBucket(playerSource, bucket)
        TriggerClientEvent("m_paineladm_v2:vipTestStart", playerSource, {
            vehicle = spawn,
            vehicleName = tostring(allowedVehicle.name or spawn),
            center = VIP.testCenter,
            radius = VIP.testRadius,
            seconds = VIP.testSeconds,
            returnPosition = returnPosition
        })
        webhookLog(userId, "vip_vehicle_test", ("VIP %s | Veículo: %s | Teste de %ds"):format(
            tostring(record.title or record.group or "VIP"), tostring(allowedVehicle.name or spawn), tonumber(VIP.testSeconds) or 60
        ))
        return result(true, "Teste iniciado.")
    end

    return result(false, "Operação de escolha VIP inválida.")
end

function API.auditPanelAction(data)
    local playerSource = source
    data = type(data) == "table" and data or {}
    local key = tostring(data.key or "")
    local rules = {
        inspect_inventory = { permission = "inspect_inventory", target = true }
    }
    local rule = rules[key]
    if not rule then return result(false, "Auditoria inválida.") end

    local actorId = requireAction(playerSource, rule.permission)
    if not actorId then return result(false, "Sem permissão.") end
    local targetId = rule.target and toInt(data.targetId) or nil
    if rule.target and not targetId then return result(false, "Jogador inválido.") end

    webhookLog(actorId, key, trim(data.details), targetId)
    return result(true, "Ação auditada.")
end

function API.bootstrap()
    local playerSource = source
    local actorId = requirePanelAccess(playerSource)
    if not actorId then
        return { allowed = false }
    end

    local players = getPlayers()
    local identity = getIdentity(actorId)
    local onlineStats = getOnlineStats(players)

    return {
        allowed = true,
        admin = {
            id = actorId,
            name = (tostring(identity.nome) .. " " .. tostring(identity.sobrenome)):gsub("%s+", " ")
        },
        stats = onlineStats,
        players = players,
        groups = getServerGroups(),
        items = getItems(),
        weapons = getWeapons(),
        vehicles = publicVehicles(),
        locations = publicLocations(),
        locationCategories = publicLocationCategories(),
        environment = publicEnvironment(),
        needsEnabled = getNeedsEnabledState(),
        needsSettings = getNeedsSettingsState(),
        radioAdmin = canUseAction(actorId, "view_radio") and getRadioAdminData() or nil,
        vipAdmin = canUseAction(actorId, "view_vips") and VIP.publicAdminData() or nil,
        permissions = buildPermissionPayload(actorId)
    }
end


function API.getMapPlayers()
    local playerSource = source
    local actorId = requireAction(playerSource, "view_map")
    if not actorId then return result(false, "Sem permissão para acessar o mapa.") end

    return result(true, "Mapa atualizado.", {
        players = getMapPlayers(),
        updatedAt = os.time()
    })
end

function API.stopLiveScreen()
    stopLiveScreenForAdmin(source)
    return result(true, "Monitoramento encerrado.")
end

function API.startLiveScreen(data)
    local adminSource = tonumber(source)
    local actorId = requireAction(adminSource, "map_screen")
    if not actorId then return result(false, "Sem permissão para visualizar a tela.") end

    data = type(data) == "table" and data or {}
    local targetId = toInt(data.targetId)
    if not targetId then return result(false, "Jogador inválido.") end

    local targetSource = getUserSourceSafe(targetId)
    if not targetSource then return result(false, "O jogador não está online.") end
    targetSource = tonumber(targetSource)

    -- A própria staff também pode selecionar o próprio ID. Nesse caso o painel
    -- usa um autoteste local (CfxTexture -> canvas.captureStream -> <video>) sem
    -- ICE/STUN/WebRTC de rede, evitando falso erro de P2P no mesmo CEF.

    -- Uma única transmissão por jogador e uma única visualização por ADM. Isso
    -- impede múltiplos encoders WebRTC consumindo GPU/CPU do mesmo client.
    stopLiveScreenForAdmin(adminSource)
    local targetToken = liveScreenByTarget[targetId]
    if targetToken and liveScreenSessions[targetToken] then
        return result(false, "Este jogador já está sendo monitorado por outra staff.")
    end

    local token = newLiveScreenToken(adminSource, targetId)
    local session = {
        active = true,
        token = token,
        adminSource = adminSource,
        actorId = actorId,
        targetId = targetId,
        targetSource = targetSource,
        adminReady = false,
        publisherStarted = false,
        createdAt = os.time()
    }

    liveScreenSessions[token] = session
    liveScreenByAdmin[adminSource] = token
    liveScreenByTarget[targetId] = token

    webhookLog(actorId, "map_screen", "Transmissão WebRTC iniciada", targetId)

    local identity = getIdentity(targetId)
    local targetName = (tostring(identity.nome) .. " " .. tostring(identity.sobrenome)):gsub("%s+", " ")
    return result(true, "Conexão WebRTC preparada.", {
        token = token,
        targetId = targetId,
        name = targetName
    })
end

function API.readyLiveScreen(data)
    local adminSource = tonumber(source)
    local actorId = requireAction(adminSource, "map_screen")
    if not actorId then return result(false, "Sem permissão para visualizar a tela.") end

    data = type(data) == "table" and data or {}
    local token = tostring(data.token or "")
    local session = liveScreenSessions[token]
    if not session or not session.active or tonumber(session.adminSource) ~= adminSource then
        return result(false, "Sessão de monitoramento inválida ou encerrada.")
    end

    local currentTarget = getUserSourceSafe(session.targetId)
    if not currentTarget or tonumber(currentTarget) ~= tonumber(session.targetSource) then
        closeLiveScreenSession(token, false)
        return result(false, "O jogador não está mais online.")
    end

    local mapConfig = Config.LiveMap or {}
    local width = math.max(480, math.min(1280, math.floor(tonumber(mapConfig.screenWidth) or 960)))
    local height = math.max(270, math.min(720, math.floor(tonumber(mapConfig.screenHeight) or 540)))
    local fps = math.max(6, math.min(20, math.floor(tonumber(mapConfig.screenFps) or 12)))
    local bitrate = math.max(350000, math.min(3000000, math.floor(tonumber(mapConfig.screenBitrate) or 1200000)))
    local timeoutMs = math.max(8000, math.min(30000, math.floor(tonumber(mapConfig.screenConnectTimeoutMs) or 15000)))
    local iceServers = type(mapConfig.screenIceServers) == "table" and mapConfig.screenIceServers or {}
    local selfTest = tonumber(session.adminSource) == tonumber(session.targetSource)

    local responseData = {
        width = width,
        height = height,
        fps = fps,
        bitrate = bitrate,
        timeoutMs = timeoutMs,
        iceServers = iceServers,
        selfTest = selfTest
    }

    if session.publisherStarted then
        return result(true, selfTest and "Teste local já iniciado." or "Transmissão já iniciada.", responseData)
    end

    session.adminReady = true
    session.publisherStarted = true
    session.selfTest = selfTest

    -- Quando a staff tela o próprio ID não faz sentido forçar uma conexão ICE
    -- entre dois RTCPeerConnection dentro do mesmo CEF. Alguns builds do FiveM
    -- falham nesse loopback mesmo com o render funcionando. Para o autoteste,
    -- entregamos o MediaStream do canvas diretamente ao <video>. Assim o teste
    -- valida exatamente CfxTexture -> WebGL -> canvas.captureStream, sem NAT/STUN.
    if selfTest then
        return result(true, "Teste local de captura preparado.", responseData)
    end

    TriggerClientEvent("m_paineladm_v2:liveScreenPublisherStart", session.targetSource, token, responseData)

    return result(true, "Transmissão solicitada ao jogador.", responseData)
end


function API.startLiveScreenRelay(data)
    local adminSource = tonumber(source)
    local actorId = requireAction(adminSource, "map_screen")
    if not actorId then return result(false, "Sem permissão para visualizar a tela.") end

    data = type(data) == "table" and data or {}
    local token = tostring(data.token or "")
    local session = liveScreenSessions[token]
    if not session or not session.active or tonumber(session.adminSource) ~= adminSource then
        return result(false, "Sessão de monitoramento inválida ou encerrada.")
    end

    local currentTarget = getUserSourceSafe(session.targetId)
    if not currentTarget or tonumber(currentTarget) ~= tonumber(session.targetSource) then
        closeLiveScreenSession(token, false)
        return result(false, "O jogador não está mais online.")
    end

    local mapConfig = Config.LiveMap or {}
    if mapConfig.screenRelayFallback == false then
        return result(false, "O modo compatibilidade está desativado na configuração.")
    end

    local relayWidth = math.max(480, math.min(1280, math.floor(tonumber(mapConfig.screenRelayWidth) or 960)))
    local relayHeight = math.max(270, math.min(720, math.floor(tonumber(mapConfig.screenRelayHeight) or 540)))
    local relayFps = math.max(1, math.min(10, math.floor(tonumber(mapConfig.screenRelayFps) or 8)))
    local relayQuality = math.max(0.25, math.min(0.85, tonumber(mapConfig.screenRelayQuality) or 0.65))
    local relayBandwidth = math.max(128000, math.min(3500000, math.floor(tonumber(mapConfig.screenRelayBandwidth) or 2500000)))

    session.relayEnabled = true
    session.lastRelaySeq = 0
    session.lastRelayAt = os.time()

    local relayOptions = {
        relayWidth = relayWidth,
        relayHeight = relayHeight,
        relayFps = relayFps,
        relayQuality = relayQuality,
        relayBandwidth = relayBandwidth
    }

    TriggerClientEvent("m_paineladm_v2:liveScreenRelayStart", tonumber(session.targetSource), token, relayOptions)

    webhookLog(actorId, "map_screen", "Fallback relay FXServer ativado", tonumber(session.targetId))
    return result(true, "Modo compatibilidade iniciado.", relayOptions)
end

function API.updatePanelPermission(data)
    local playerSource = source
    local actorId = requirePanelAccess(playerSource)
    if not actorId or not isPermissionManager(actorId) then
        return result(false, "Apenas dono e developer podem editar as permissões do painel.")
    end

    data = type(data) == "table" and data or {}
    local key = clampString(data.key, 80)
    if key == "" or not panelPermissionDefinitions[key] or not panelPermissions[key] then
        return result(false, "Função inválida.")
    end

    local roles = type(data.roles) == "table" and data.roles or {}
    panelPermissions[key].dono = true
    panelPermissions[key].developer = true
    panelPermissions[key].admin = roles.admin == true
    panelPermissions[key].moderador = roles.moderador == true
    panelPermissions[key].suporte = roles.suporte == true

    savePanelPermissions()
    webhookLog(actorId, "panel_permissions", ("Função: %s | admin=%s | moderador=%s | suporte=%s")
        :format(key, tostring(panelPermissions[key].admin), tostring(panelPermissions[key].moderador), tostring(panelPermissions[key].suporte)))
    pushPermissionStateToStaff()

    return result(true, "Permissões atualizadas.", buildPermissionPayload(actorId))
end

function API.getPanelPermissions()
    local playerSource = source
    local actorId = requirePanelAccess(playerSource)
    if not actorId or not isPermissionManager(actorId) then
        return result(false, "Apenas dono e developer podem gerenciar as permissões do painel.")
    end
    return result(true, "Permissões carregadas.", buildPermissionPayload(actorId))
end

function API.updateEnvironment(data)
    local playerSource = source
    data = type(data) == "table" and data or {}
    local mode = tostring(data.action or "")

    if mode == "setWeather" or mode == "freezeWeather" or mode == "rotating" then
        local actorId = requireAction(playerSource, "weather_manage")
        if not actorId then return result(false, "Sem permissão.") end

        if mode == "setWeather" then
            local weather = clampString(data.weather, 32):upper()
            if not validWeather[weather] then
                return result(false, "Clima inválido.")
            end

            environmentState.weather = weather
            environmentState.rotating = false
            -- Seleção manual volta ao modo fixo por padrão.
            environmentState.weatherFrozen = true
            publishEnvironment(true, true)
            saveEnvironmentState()
            webhookLog(actorId, "weather_set", ("Clima definido como %s"):format(weather))
            return result(true, ("Clima alterado para %s."):format(weather), publicEnvironment())
        end

        if mode == "freezeWeather" then
            environmentState.weatherFrozen = data.enabled == true
            if environmentState.weatherFrozen then
                environmentState.rotating = false
            end
            publishEnvironment(true, false)
            saveEnvironmentState()
            webhookLog(actorId, "weather_freeze", environmentState.weatherFrozen and "Clima congelado" or "Clima descongelado")
            return result(true, environmentState.weatherFrozen and "Clima congelado." or "Clima descongelado.", publicEnvironment())
        end

        local enabled = data.enabled == true
        environmentState.rotating = enabled
        environmentState.weather = "CLEAR"
        environmentState.weatherFrozen = not enabled
        rotationIndex = 1
        publishEnvironment(true, enabled)
        saveEnvironmentState()
        webhookLog(actorId, "weather_rotation", enabled and "Clima rotativo ativado" or "Clima rotativo desativado; CLEAR restaurado")
        return result(true, enabled and "Clima rotativo ativado." or "Clima rotativo desativado. Clima restaurado para CLEAR.", publicEnvironment())
    end

    if mode == "setTime" or mode == "freezeTime" then
        local actorId = requireAction(playerSource, "time_manage")
        if not actorId then return result(false, "Sem permissão.") end

        if mode == "setTime" then
            local minuteOfDay = tonumber(data.minuteOfDay)
            if not minuteOfDay then return result(false, "Horário inválido.") end
            minuteOfDay = math.floor(minuteOfDay)
            if minuteOfDay < 0 or minuteOfDay > 1439 then
                return result(false, "Horário fora do intervalo permitido.")
            end

            environmentState.hour = math.floor(minuteOfDay / 60)
            environmentState.minute = minuteOfDay % 60
            publishEnvironment(false, false)
            -- Durante o arraste, evita gravação em disco a cada pixel. O valor final é persistido.
            if data.live ~= true then
                saveEnvironmentState()
            end
            -- Durante o arraste do slider recebemos vários updates curtos.
            -- Só registra no webhook quando o valor final é confirmado.
            if data.live ~= true then
                webhookLog(actorId, "time_set", ("Horário definido para %02d:%02d"):format(environmentState.hour, environmentState.minute))
            end
            return result(true, ("Horário definido para %02d:%02d."):format(environmentState.hour, environmentState.minute), publicEnvironment())
        end

        environmentState.timeFrozen = data.enabled == true
        publishEnvironment(false, false)
        saveEnvironmentState()
        webhookLog(actorId, "time_freeze", environmentState.timeFrozen and "Horário congelado" or "Horário descongelado")
        return result(true, environmentState.timeFrozen and "Horário congelado." or "Horário descongelado.", publicEnvironment())
    end

    return result(false, "Ação de clima/horário inválida.")
end

function API.refreshPlayers()
    local playerSource = source
    if not requireAction(playerSource, "view_players") then
        return result(false, "Sem permissão.")
    end

    local players = getPlayers()
    return result(true, "Lista atualizada.", {
        players = players,
        stats = getOnlineStats(players)
    })
end

function API.getPlayerSnapshot(target)
    local playerSource = source
    local actorId = vRP.getUserId(playerSource)
    if not actorId or not canOpen(actorId) or not (canUseAction(actorId, "view_players") or canUseAction(actorId, "view_groups") or canUseAction(actorId, "view_identity_editor")) then
        notify(playerSource, "negado", "Você não possui permissão para consultar jogadores nesta área.")
        return result(false, "Sem permissão.")
    end

    local targetId = toInt(type(target) == "table" and (target.targetId or target.id) or target)
    if not targetId then
        return result(false, "Informe um passaporte válido.")
    end

    local identity = identityRow(targetId)
    if not identity then
        return result(false, "Passaporte não encontrado.")
    end

    -- Se este usuário foi alterado pelo editor, playerSnapshot já usa o espelho
    -- liveIdentityOverrides e portanto reflete o dado novo instantaneamente.
    return result(true, "Dados carregados.", playerSnapshot(targetId, actorId))
end

function API.changeGroup(data)
    local playerSource = source
    data = type(data) == "table" and data or {}

    local mode = data.mode == "remove" and "remove_group" or "set_group"
    local actorId = requireAction(playerSource, mode)
    if not actorId then
        return result(false, "Sem permissão.")
    end

    local targetId = toInt(data.targetId)
    local groupName = clampString(data.group, ServerConfig.Limits.maxString)

    if not targetId or groupName == "" then
        return result(false, "Passaporte ou cargo inválido.")
    end

    local online = isOnline(targetId)
    if not online then
        return result(false, "O jogador precisa estar online para alterar cargos nesta vRP.")
    end

    local available = false
    for _, group in ipairs(getServerGroups()) do
        if group.name == groupName then
            available = true
            break
        end
    end

    if not available then
        return result(false, "Cargo inválido ou oculto no painel.")
    end

    if not canManageGroup(actorId, groupName) then
        return result(false, "Sua hierarquia não permite alterar este cargo.")
    end

    if mode == "set_group" then
        vRP.addUserGroup(targetId, groupName)
        notify(playerSource, "sucesso", ("Cargo %s adicionado ao ID %d."):format(groupName, targetId))
        webhookLog(actorId, mode, ("Cargo: %s"):format(groupName), targetId)
    else
        vRP.removeUserGroup(targetId, groupName)
        notify(playerSource, "sucesso", ("Cargo %s removido do ID %d."):format(groupName, targetId))
        webhookLog(actorId, mode, ("Cargo: %s"):format(groupName), targetId)
    end

    return result(true, "Cargo atualizado.", playerSnapshot(targetId, actorId))
end

local function changeItemForSource(playerSource, data)
    data = type(data) == "table" and data or {}

    local action = data.mode == "remove" and "remove_item" or "give_item"
    local actorId = requireAction(playerSource, action)
    if not actorId then
        return result(false, "Sem permissão.")
    end

    local targetId = toInt(data.targetId)
    local item = clampString(data.item, ServerConfig.Limits.maxString)
    local amount = toInt(data.amount)

    if not targetId or item == "" or not amount then
        return result(false, "Preencha ID, item e quantidade corretamente.")
    end

    amount = math.min(amount, ServerConfig.Limits.maxAmount)

    local online = isOnline(targetId)
    if not online then
        return result(false, "O jogador precisa estar online para alterar o inventário.")
    end

    local allItems = vRP.getAllItens() or {}
    if not isAllowedPanelItem(item, allItems) then
        return result(false, "Este item não está disponível no catálogo do servidor.")
    end

    if not allItems[item] then
        return result(false, "Este item não está carregado no inventário do servidor.")
    end

    if action == "give_item" then
        vRP.giveInventoryItem(targetId, item, amount, true)
        webhookLog(actorId, action, ("%s x%d"):format(item, amount), targetId)
        return result(true, ("Adicionado %dx %s ao ID %d."):format(amount, item, targetId), playerSnapshot(targetId, actorId))
    end

    local current = tonumber(vRP.getInventoryItemAmount(targetId, item)) or 0
    if current < amount then
        return result(false, ("O jogador possui apenas %d deste item."):format(current))
    end

    local removed = vRP.tryGetInventoryItem(targetId, item, amount, true)
    if removed == false then
        return result(false, "Não foi possível remover o item.")
    end

    webhookLog(actorId, action, ("%s x%d"):format(item, amount), targetId)
    return result(true, ("Removido %dx %s do ID %d."):format(amount, item, targetId), playerSnapshot(targetId, actorId))
end


function API.changeItem(data)
    return changeItemForSource(source, data)
end

function API.addVehicleCatalog(data)
    local playerSource = source
    local actorId = requireAction(playerSource, "add_vehicle_catalog")
    if not actorId then
        return result(false, "Sem permissão.")
    end

    data = type(data) == "table" and data or {}
    local spawn = clampString(data.spawn or data.vehicle, ServerConfig.Limits.maxString)
    spawn = spawn:gsub("^%s+", ""):gsub("%s+$", "")
    local category = normalizeVehicleCategory(data.category)

    if spawn == "" then
        return result(false, "Informe o spawn do veículo.")
    end

    -- Spawns FiveM usuais aceitam letras, números, _, - e ponto.
    if not spawn:match("^[%w_%.%-]+$") then
        return result(false, "Spawn inválido. Use apenas letras, números, ponto, hífen ou underline.")
    end

    for _, vehicle in ipairs(savedVehicles[category] or {}) do
        if tostring(vehicle.spawn or ""):lower() == spawn:lower() then
            return result(false, "Este veículo já está cadastrado nesta categoria.")
        end
    end

    savedVehicles[category][#savedVehicles[category] + 1] = {
        spawn = spawn,
        name = spawn
    }
    table.sort(savedVehicles[category], function(a, b)
        return tostring(a.name or a.spawn):lower() < tostring(b.name or b.spawn):lower()
    end)
    saveVehicleCatalog()

    local categoryLabel = category == "addon" and "Veículos addon" or "Veículos do jogo"
    webhookLog(actorId, "add_vehicle_catalog", ("%s | %s"):format(spawn, categoryLabel))
    return result(true, ("Veículo %s adicionado em %s."):format(spawn, categoryLabel), {
        vehicles = publicVehicles(),
        category = category
    })
end

function API.addLocationCategory(data)
    local playerSource = source
    local actorId = requireAction(playerSource, "add_location")
    if not actorId then return result(false, "Sem permissão.") end

    data = type(data) == "table" and data or {}
    local name = normalizeCategoryName(clampString(data.name, 60))
    if name == "" then return result(false, "Informe um nome para a categoria.") end
    if findLocationCategory(name) then
        return result(false, "Já existe uma categoria com este nome.", { categories = publicLocationCategories() })
    end

    local category = ensureLocationCategory(name)
    saveLocationCategories()
    webhookLog(actorId, "add_location_category", ("Categoria: %s"):format(category))
    return result(true, ("Categoria %s criada."):format(category), { categories = publicLocationCategories() })
end

function API.addLocation(data)
    local playerSource = source
    local actorId = requireAction(playerSource, "add_location")
    if not actorId then
        return result(false, "Sem permissão.")
    end

    data = type(data) == "table" and data or {}
    local name = clampString(data.name, ServerConfig.Limits.maxString)
    local category = normalizeCategoryName(data.category or "Geral")
    local x, y, z = resolveCoordinates(data)

    if name == "" then
        return result(false, "Informe um nome para o local.")
    end
    if category == "" then
        return result(false, "Informe uma categoria para o local.")
    end
    if not x or not y or not z then
        return result(false, "Digite uma coordenada correta!")
    end

    local resolvedCategory, categoryCreated = ensureLocationCategory(category)
    if categoryCreated then saveLocationCategories() end

    savedLocations[#savedLocations + 1] = {
        name = name,
        category = resolvedCategory,
        x = x + 0.0,
        y = y + 0.0,
        z = z + 0.0
    }
    saveSavedLocations()

    webhookLog(actorId, "add_location", ("%s | Categoria: %s | %.2f, %.2f, %.2f"):format(name, resolvedCategory, x, y, z))
    return result(true, ("Local %s cadastrado em %s."):format(name, resolvedCategory), {
        locations = publicLocations(),
        categories = publicLocationCategories()
    })
end

function API.removeLocation(data)
    local playerSource = source
    local actorId = requireAction(playerSource, "remove_location")
    if not actorId then
        return result(false, "Sem permissão.")
    end

    local index = toInt(type(data) == "table" and data.index or data)
    local location = index and savedLocations[index] or nil
    if not location then
        return result(false, "Local inválido.")
    end

    local removedName = tostring(location.name or ("#" .. tostring(index)))
    local removedCategory = tostring(location.category or "Geral")
    local removedX, removedY, removedZ = location.x, location.y, location.z

    table.remove(savedLocations, index)
    saveSavedLocations()

    webhookLog(actorId, "remove_location", ("%s | Categoria: %s | %.2f, %.2f, %.2f"):format(
        removedName, removedCategory, removedX or 0.0, removedY or 0.0, removedZ or 0.0
    ))

    return result(true, ("Local %s removido de %s."):format(removedName, removedCategory), {
        locations = publicLocations(),
        categories = publicLocationCategories()
    })
end

function API.teleportLocation(data)
    local playerSource = source
    local actorId = requireAction(playerSource, "teleport_location")
    if not actorId then
        return result(false, "Sem permissão.")
    end

    local index = toInt(type(data) == "table" and data.index or data)
    local location = index and savedLocations[index] or nil
    if not location then
        return result(false, "Local inválido.")
    end

    vRPclient._teleport(playerSource, location.x + 0.0, location.y + 0.0, location.z + 0.0)
    webhookLog(actorId, "teleport_location", ("%s | %.2f, %.2f, %.2f"):format(location.name or index, location.x, location.y, location.z))
    return result(true, ("Teleportado para %s."):format(location.name or "local"))
end

local function getTargetId(payload)
    return toInt(payload.targetId or payload.id)
end

local function targetOnlineOrError(targetId)
    if not targetId then return nil, "Informe um passaporte válido." end
    local targetSource = vRP.getUserSource(targetId)
    if not targetSource then return nil, "Este jogador não está online." end
    return targetSource
end

function API.execute(action, payload)
    local playerSource = source
    action = clampString(action, 40)
    payload = type(payload) == "table" and payload or {}

    local actorId = requireAction(playerSource, action)
    if not actorId then
        return result(false, "Você não possui permissão para esta ação.")
    end

    local targetId = getTargetId(payload)

    if action == "wipe_user_data" then
        -- Esta operação é propositalmente hard-locked em Dono/Developer. Ela não
        -- aparece no gerenciador de permissões e não pode ser liberada para outros cargos.
        local actorRole = getPanelRole(actorId)
        if actorRole ~= "dono" and actorRole ~= "developer" then
            return result(false, "Apenas Dono e Developer podem limpar completamente um ID.")
        end
        if not targetId then return result(false, "Informe um Passaporte / ID válido.") end
        if tonumber(targetId) == tonumber(actorId) then
            return result(false, "Você não pode limpar o ID que está usando. Faça esta operação com outro Dono/Developer.")
        end

        -- Captura o nome antes de remover a identidade para deixar o log legível.
        local beforeIdentity = identityRow(targetId)
        local beforeName = beforeIdentity and ((tostring(beforeIdentity.nome or "") .. " " .. tostring(beforeIdentity.sobrenome or "")):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")) or "Sem identidade"

        -- Se estiver online, desconecta PRIMEIRO e espera a vRP terminar o logout.
        -- Caso apagássemos antes, handlers de saída poderiam salvar novamente inventário,
        -- grupos ou posição e recriar dados que acabamos de remover.
        local targetSource = getUserSourceSafe(targetId)
        if targetSource then
            notify(targetSource, "aviso", "Seus dados estão sendo redefinidos pela administração. Você será desconectado.", 7000)
            Wait(350)
            if type(vRP.kick) == "function" then
                vRP.kick(targetSource, "Seus dados foram redefinidos pela administração. Entre novamente para criar um novo personagem/ID.")
            else
                DropPlayer(targetSource, "Seus dados foram redefinidos pela administração. Entre novamente.")
            end

            local attempts = 0
            while getUserSourceSafe(targetId) and attempts < 50 do
                Wait(100)
                attempts = attempts + 1
            end
            if getUserSourceSafe(targetId) then
                return result(false, "O jogador ainda está conectado. Aguarde alguns segundos e tente novamente.")
            end
            -- Margem para eventos de playerDropped/vRP logout concluírem gravações pendentes.
            Wait(750)
        end

        local success, countOrErr = wipeUserDataAcrossDatabase(targetId)
        if not success then
            return result(false, countOrErr or "Não foi possível limpar os dados deste ID.")
        end

        purgePanelDataForUser(targetId)
        webhookLog(actorId, "wipe_user_data", ("%d tabela(s) mapeada(s) limpas | ID liberado"):format(
            tonumber(countOrErr) or 0
        ), targetId, { targetName = beforeName ~= "" and beforeName or "Sem identidade" })

        -- Sincroniza imediatamente a lista de jogadores de qualquer painel aberto.
        local playersNow = getPlayers()
        local statsNow = getOnlineStats(playersNow)
        for staffId, staffSource in pairs(vRP.getUsers() or {}) do
            staffId = tonumber(staffId)
            staffSource = tonumber(staffSource)
            if staffId and staffSource and canOpen(staffId) then
                TriggerClientEvent("m_paineladm_v2:playersLiveUpdated", staffSource, {
                    players = playersNow,
                    stats = statsNow,
                    removedId = targetId
                })
            end
        end

        return result(true, ("Dados do ID %d apagados completamente. O ID está livre para ser usado por outra pessoa."):format(targetId), {
            wipedId = targetId,
            tables = tonumber(countOrErr) or 0
        })
    end


    if action == "needs_manage" then
        local requested = payload.enabled == true
        local ok, enabledOrError = pcall(function()
            return exports["vrp"]:setNeedsEnabled(requested)
        end)

        if not ok then
            return result(false, "Não foi possível comunicar com o sistema de fome e sede da vRP.")
        end

        local enabled = enabledOrError == true
        TriggerClientEvent("m_paineladm_v2:needsSync", -1, enabled)
        webhookLog(actorId, "needs_toggle", enabled and "Fome e sede ativadas" or "Fome e sede desativadas")

        return result(true, enabled and "Fome e sede ativadas no servidor." or "Fome e sede desativadas no servidor.", {
            needsEnabled = enabled
        })
    end

    if action == "wladd" or action == "wlrem" then
        if not targetId then return result(false, "Informe um passaporte válido.") end
        local status = action == "wladd"
        vRP.setWhitelisted(targetId, status)
        webhookLog(actorId, action, nil, targetId)
        return result(true, status and "Whitelist liberada." or "Whitelist removida.")
    end

    if action == "god" then
        local targetSource, err = targetOnlineOrError(targetId)
        if not targetSource then return result(false, err) end

        local data = vRP.getUserDataTable(targetId)
        if data then data.health = 400 end
        vRPclient._setHealth(targetSource, 400)
        TriggerClientEvent("m_paineladm_v2:revive", targetSource)
        webhookLog(actorId, action, nil, targetId)
        return result(true, ("ID %d revivido."):format(targetId))
    end

    if action == "godall" then
        local count = 0
        for userId, targetSource in pairs(vRP.getUsers()) do
            local data = vRP.getUserDataTable(tonumber(userId))
            if data then data.health = 400 end
            vRPclient._setHealth(targetSource, 400)
            TriggerClientEvent("m_paineladm_v2:revive", targetSource)
            count = count + 1
        end
        webhookLog(actorId, action, ("%d jogadores"):format(count))
        return result(true, ("%d jogadores foram revividos."):format(count))
    end

    if action == "kill" then
        local targetSource, err = targetOnlineOrError(targetId)
        if not targetSource then return result(false, err) end

        local data = vRP.getUserDataTable(targetId)
        if data then data.health = 0 end
        vRPclient._setHealth(targetSource, 0)
        webhookLog(actorId, action, nil, targetId)
        return result(true, ("ID %d abatido."):format(targetId))
    end

    if action == "tptome" then
        local targetSource, err = targetOnlineOrError(targetId)
        if not targetSource then return result(false, err) end

        local x, y, z = vRPclient.getPosition(playerSource)
        vRPclient._teleport(targetSource, x, y, z)
        webhookLog(actorId, action, nil, targetId)
        return result(true, ("ID %d puxado até você."):format(targetId))
    end

    if action == "tpto" then
        local targetSource, err = targetOnlineOrError(targetId)
        if not targetSource then return result(false, err) end

        local x, y, z = vRPclient.getPosition(targetSource)
        vRPclient._teleport(playerSource, x, y, z)
        if Config.ToggleNoclipAfterTeleport then
            vRPclient._toggleNoclip(playerSource)
        end
        webhookLog(actorId, action, nil, targetId)
        return result(true, ("Teleportado até o ID %d."):format(targetId))
    end

    if action == "freeze" or action == "unfreeze" then
        local targetSource, err = targetOnlineOrError(targetId)
        if not targetSource then return result(false, err) end

        local state = action == "freeze"
        TriggerClientEvent("m_paineladm_v2:freeze", targetSource, state)
        webhookLog(actorId, action, nil, targetId)
        return result(true, state and "Jogador congelado." or "Jogador descongelado.")
    end

    if action == "send_dm" then
        local targetSource, err = targetOnlineOrError(targetId)
        if not targetSource then return result(false, err) end

        local message = clampString(payload.message, ServerConfig.Limits.maxMessage)
        if message == "" then return result(false, "Digite a mensagem.") end

        local maxSeconds = tonumber(ServerConfig.Limits.maxAlertSeconds) or 300
        local durationSeconds = math.floor(tonumber(payload.durationSeconds) or 8)
        durationSeconds = math.max(1, math.min(maxSeconds, durationSeconds))

        TriggerClientEvent("m_paineladm_v2:screenAlert", targetSource, message, durationSeconds, "private")
        webhookLog(actorId, action, ("Duração %ds | Mensagem: %s"):format(durationSeconds, message), targetId)
        return result(true, ("Mensagem exibida por %d segundos."):format(durationSeconds))
    end

    if action == "send_adm" then
        local message = clampString(payload.message, ServerConfig.Limits.maxMessage)
        if message == "" then return result(false, "Digite a mensagem.") end

        local maxSeconds = tonumber(ServerConfig.Limits.maxAlertSeconds) or 300
        local durationSeconds = math.floor(tonumber(payload.durationSeconds) or 8)
        durationSeconds = math.max(1, math.min(maxSeconds, durationSeconds))

        TriggerClientEvent("m_paineladm_v2:screenAlert", -1, message, durationSeconds, "general")
        webhookLog(actorId, action, ("%ds | %s"):format(durationSeconds, message))
        return result(true, ("Aviso exibido para todos por %d segundos."):format(durationSeconds))
    end

    if action == "catch_rg" then
        if not targetId then return result(false, "Informe um passaporte válido.") end
        local identity = getIdentity(targetId)
        if not identity then return result(false, "Passaporte não encontrado.") end

        local snapshot = playerSnapshot(targetId, actorId)
        webhookLog(actorId, action, nil, targetId)
        return result(true, "RG carregado.", {
            kind = "identity",
            player = snapshot
        })
    end

    if action == "warning" then
        if not targetId then return result(false, "Informe um passaporte válido.") end

        local targetSource, err = targetOnlineOrError(targetId)
        if not targetSource then return result(false, err) end

        local minutes = toInt(payload.minutes)
        if not minutes then
            return result(false, "Informe quantos minutos o jogador ficará de castigo.")
        end

        local reason = clampString(payload.reason, ServerConfig.Limits.maxReason)
        if reason == "" then
            return result(false, "Informe o motivo da advertência.")
        end

        local maxMinutes = math.max(1, math.floor(tonumber(ServerConfig.Limits.maxPunishmentMinutes) or 10080))
        minutes = math.max(1, math.min(minutes, maxMinutes))

        local key = tostring(targetId)
        local identity = warningIdentity(targetId)
        local actorIdentity = warningIdentity(actorId)
        local warningId = math.max(1, math.floor(tonumber(warningStore.nextId) or 1))
        warningStore.nextId = warningId + 1

        local startedAt = os.time()
        local record = {
            warningId = warningId,
            startedAt = startedAt,
            endsAt = startedAt + (minutes * 60),
            minutes = minutes,
            actorId = actorId,
            reason = reason,
            bucket = punishmentBucketFor(targetId)
        }
        warningStore.active[key] = record

        warningStore.history[#warningStore.history + 1] = {
            id = warningId,
            targetId = targetId,
            targetName = identity.nome,
            targetSurname = identity.sobrenome,
            actorId = actorId,
            actorName = (actorIdentity.nome .. " " .. actorIdentity.sobrenome):gsub("%s+", " "),
            reason = reason,
            minutes = minutes,
            startedAt = record.startedAt,
            endsAt = record.endsAt,
            date = os.date("%d/%m/%Y", startedAt),
            time = os.date("%H:%M:%S", startedAt)
        }
        local count = 0
        for _, entry in ipairs(warningStore.history) do
            if tonumber(entry.targetId) == targetId then count = count + 1 end
        end
        warningStore.counts[key] = count

        saveWarningStore()
        applyPunishmentToSource(targetId, targetSource, record)
        pushWarningStateToStaff()

        webhookLog(actorId, action, ("%d minuto(s) | Advertência #%d | Motivo: %s"):format(
            minutes, getWarningCount(targetId), reason
        ), targetId)

        local snapshot = playerSnapshot(targetId, actorId)
        snapshot.warningSummary = warningSummaryPayload()
        return result(true,
            ("Advertência aplicada ao ID %d por %d minuto(s)."):format(targetId, minutes),
            snapshot
        )
    end

    if action == "ban" then
        if not targetId then return result(false, "Informe um passaporte válido.") end

        local reason = clampString(payload.reason, ServerConfig.Limits.maxReason)
        if reason == "" then return result(false, "Informe o motivo do banimento.") end

        vRP.setBanned(targetId, true, reason, 0, false, actorId)
        addBanHistoryEntry("ban", actorId, targetId, reason)

        local targetSource = vRP.getUserSource(targetId)
        if targetSource then
            vRP.kick(targetSource, "Você foi banido. Motivo: " .. reason)
        end

        webhookLog(actorId, action, ("Motivo: %s"):format(reason), targetId)
        return result(true, ("ID %d banido."):format(targetId))
    end

    if action == "unban" then
        if not targetId then return result(false, "Informe um passaporte válido.") end

        local reason = clampString(payload.reason, ServerConfig.Limits.maxReason)
        if reason == "" then return result(false, "Informe o motivo do desbanimento.") end

        vRP.execute("mirtin/removeBanned", { user_id = targetId })
        if type(vRP.removeBanIp) == "function" then
            vRP.removeBanIp(targetId)
        end

        addBanHistoryEntry("unban", actorId, targetId, reason)
        webhookLog(actorId, action, ("Motivo: %s"):format(reason), targetId)
        return result(true, ("ID %d desbanido."):format(targetId))
    end

    if action == "kick" then
        local targetSource, err = targetOnlineOrError(targetId)
        if not targetSource then return result(false, err) end

        local reason = clampString(payload.reason, ServerConfig.Limits.maxReason)
        if reason == "" then return result(false, "Informe o motivo da expulsão.") end

        webhookLog(actorId, action, ("Motivo: %s"):format(reason), targetId)
        vRP.kick(targetSource, "Você foi expulso da cidade. Motivo: " .. reason)
        return result(true, ("ID %d expulso."):format(targetId))
    end

    if action == "spawn_weapon" then
        local requestedWeapon = clampString(payload.weapon, ServerConfig.Limits.maxString)
        local requestedAmmo = tonumber(payload.ammoAmount)
        if requestedWeapon == "" then
            return result(false, "Selecione uma arma válida.")
        end

        requestedAmmo = requestedAmmo and math.floor(requestedAmmo) or 0
        if requestedAmmo < 0 then
            return result(false, "A quantidade de munição não pode ser negativa.")
        end
        requestedAmmo = math.min(requestedAmmo, ServerConfig.Limits.maxAmount)

        local activeItems = vRP.getAllItens() or {}
        local byUpper = {}
        for itemIndex in pairs(activeItems) do
            byUpper[tostring(itemIndex):upper()] = tostring(itemIndex)
        end

        local weaponItem = byUpper[requestedWeapon:upper()]
        if not weaponItem or weaponItem:upper():sub(1, 7) ~= "WEAPON_" then
            return result(false, "Esta arma não existe no inventário atual do servidor.")
        end

        local weaponUpper = weaponItem:upper()
        local ammoItem = weaponUsesInventoryAmmo(weaponUpper) and byUpper["AMMO_" .. weaponUpper:sub(8)] or nil

        -- Entrega como ITEM, e nunca com giveWeapons nativo. Isso mantém a arma
        -- 100% compatível com o hotbar/inventory atual, serialização e sistema de munição.
        vRP.giveInventoryItem(actorId, weaponItem, 1, true)
        if ammoItem and requestedAmmo > 0 then
            vRP.giveInventoryItem(actorId, ammoItem, requestedAmmo, true)
        end

        local weaponName = tostring(vRP.getItemName(weaponItem) or weaponItem)
        if ammoItem then
            webhookLog(actorId, action, ("Próprio inventário | %s + %s x%d"):format(weaponItem, ammoItem, requestedAmmo))
            return result(true, ("Você recebeu %s + %d munição(ões)."):format(weaponName, requestedAmmo))
        end

        webhookLog(actorId, action, ("Próprio inventário | %s | sem item de munição"):format(weaponItem))
        return result(true, ("Você recebeu %s. Esta arma não utiliza item de munição."):format(weaponName))
    end

    if action == "spawn_self_item" then
        local item = clampString(payload.item, ServerConfig.Limits.maxString)
        local amount = toInt(payload.amount)

        if item == "" or not amount then
            return result(false, "Informe um item e uma quantidade válidos.")
        end

        amount = math.min(amount, ServerConfig.Limits.maxAmount)

        local allItems = vRP.getAllItens() or {}
        if not isAllowedPanelItem(item, allItems) then
            return result(false, "Este item não está disponível no catálogo do servidor.")
        end

        if not allItems[item] then
            return result(false, "Este item não está carregado no inventário do servidor.")
        end

        vRP.giveInventoryItem(actorId, item, amount, true)
        webhookLog(actorId, action, ("Próprio inventário | %s x%d"):format(item, amount))
        return result(true, ("Você recebeu %dx %s."):format(amount, tostring(vRP.getItemName(item) or item)))
    end

    if action == "givemoney" or action == "remove_money" then
        if not targetId then return result(false, "Informe um passaporte válido.") end

        local amount = toInt(payload.amount)
        if not amount then return result(false, "Informe uma quantia válida.") end
        amount = math.min(amount, ServerConfig.Limits.maxAmount)

        local account = payload.account == "bank" and "bank" or "wallet"

        if account == "wallet" then
            local targetSource, err = targetOnlineOrError(targetId)
            if not targetSource then return result(false, err) end

            if action == "givemoney" then
                -- Na sua vRP, vRP.giveMoney() chama giveInventoryItem(..., false),
                -- o que adiciona o dinheiro sem exibir o itensNotify.
                -- Para a carteira, entregamos o item money diretamente com notify = true.
                if type(vRP.giveInventoryItem) == "function" then
                    vRP.giveInventoryItem(targetId, ServerConfig.MoneyItem, amount, true)
                elseif type(vRP.giveMoney) == "function" then
                    vRP.giveMoney(targetId, amount)
                else
                    return result(false, "A função de adicionar dinheiro não está disponível na vRP.")
                end
            else
                local current = tonumber(vRP.getMoney(targetId)) or 0
                if current < amount then return result(false, "Saldo insuficiente na carteira.") end
                local removed = vRP.tryGetInventoryItem(targetId, ServerConfig.MoneyItem, amount, true)
                if removed == false then return result(false, "Não foi possível remover o dinheiro.") end
            end
        else
            local current = tonumber(vRP.getBankMoney(targetId)) or 0
            if action == "givemoney" then
                vRP.setBankMoney(targetId, current + amount)
            else
                if current < amount then return result(false, "Saldo insuficiente no banco.") end
                vRP.setBankMoney(targetId, current - amount)
            end
        end

        webhookLog(actorId, action, ("%s | R$ %d"):format(account, amount), targetId)
        return result(true, action == "givemoney" and "Dinheiro adicionado." or "Dinheiro removido.", playerSnapshot(targetId, actorId))
    end

    if action == "give_item" or action == "remove_item" then
        return changeItemForSource(playerSource, {
            targetId = targetId,
            item = payload.item,
            amount = payload.amount,
            mode = action == "remove_item" and "remove" or "give"
        })
    end

    if action == "clear_inv" then
        local targetSource, err = targetOnlineOrError(targetId)
        if not targetSource then return result(false, err) end

        vRP.clearInventory(targetId)
        webhookLog(actorId, action, nil, targetId)
        return result(true, ("Inventário do ID %d limpo."):format(targetId), playerSnapshot(targetId, actorId))
    end

    if action == "clear_weapons" then
        local targetSource, err = targetOnlineOrError(targetId)
        if not targetSource then return result(false, err) end

        local data = vRP.getUserDataTable(targetId)
        if data then data.weapons = {} end
        TriggerClientEvent("m_paineladm_v2:clearWeapons", targetSource)
        webhookLog(actorId, action, nil, targetId)
        return result(true, ("Armas do ID %d removidas."):format(targetId))
    end

    if action == "give_veh" or action == "rem_veh" then
        if not targetId then return result(false, "Informe um passaporte válido.") end

        local vehicle = clampString(payload.vehicle, ServerConfig.Limits.maxString):lower()
        if vehicle == "" then return result(false, "Informe o spawn do veículo.") end

        if action == "give_veh" then
            vRP.execute("vRP/inserir_veh", {
                user_id = targetId,
                veiculo = vehicle,
                ipva = os.time(),
                expired = "{}"
            })
        else
            vRP.execute("vRP/delete_vehicle", {
                user_id = targetId,
                veiculo = vehicle
            })
        end

        webhookLog(actorId, action, ("Veículo: %s"):format(vehicle), targetId)
        return result(true, action == "give_veh" and "Veículo adicionado à garagem." or "Veículo removido da garagem.")
    end

    if action == "spawn_veh" then
        local vehicle = clampString(payload.vehicle, ServerConfig.Limits.maxString):lower()
        if vehicle == "" then return result(false, "Informe o spawn do veículo.") end

        TriggerClientEvent("m_paineladm_v2:spawnVehicle", playerSource, vehicle)
        webhookLog(actorId, action, vehicle)
        return result(true, ("Solicitado spawn de %s."):format(vehicle))
    end

    if action == "fix" then
        TriggerClientEvent("m_paineladm_v2:fixVehicle", playerSource)
        webhookLog(actorId, action, "Veículo próximo/atual")
        return result(true, "Reparo solicitado.")
    end

    if action == "tuning" then
        TriggerClientEvent("m_paineladm_v2:tuneVehicle", playerSource)
        webhookLog(actorId, action, "Veículo atual")
        return result(true, "Tuning solicitado.")
    end

    if action == "hash" then
        TriggerClientEvent("m_paineladm_v2:vehicleHash", playerSource)
        webhookLog(actorId, action, "Veículo atual")
        return result(true, "Consultando hash do veículo.")
    end

    if action == "dv" then
        TriggerClientEvent("m_paineladm_v2:deleteVehicle", playerSource)
        webhookLog(actorId, action, "Veículo próximo/atual")
        return result(true, "Remoção do veículo solicitada.")
    end

    if action == "tpway" then
        TriggerClientEvent("m_paineladm_v2:teleportWaypoint", playerSource)
        webhookLog(actorId, action, "Waypoint")
        return result(true, "Teleportando para o waypoint.")
    end

    if action == "tpcds" then
        local x, y, z = resolveCoordinates(payload)
        if not x or not y or not z then
            return result(false, "Digite uma coordenada correta!")
        end

        vRPclient._teleport(playerSource, x + 0.0, y + 0.0, z + 0.0)
        webhookLog(actorId, action, ("%.2f, %.2f, %.2f"):format(x, y, z))
        return result(true, "Teleportado para as coordenadas.")
    end

    if action == "clear_props" then
        local x, y, z = vRPclient.getPosition(playerSource)
        TriggerClientEvent("m_paineladm_v2:clearProps", -1, x, y, z, Config.PropCleanupRadius or 2000.0)
        webhookLog(actorId, action, ("Centro: %.2f, %.2f, %.2f"):format(x, y, z))
        return result(true, "Limpeza de props enviada aos clientes.")
    end

    if action == "clear_allveh" then
        if cleanupRunning then
            return result(false, "Já existe uma limpeza de veículos em andamento.")
        end

        cleanupRunning = true
        local delay = math.max(0, tonumber(Config.VehicleCleanupDelay) or 60)

        TriggerClientEvent("chatMessage", -1,
            ("^1ADMIN: ^0Limpeza de veículos em ^2%ds^0. Entre no veículo para preservá-lo."):format(delay)
        )
        TriggerClientEvent("Notify", -1, "importante",
            ("ADMIN: limpeza de veículos em %d segundos. Entre no veículo para preservá-lo."):format(delay),
            15000
        )

        webhookLog(actorId, action, ("Iniciada | Delay %ds"):format(delay))

        CreateThread(function()
            Wait(delay * 1000)

            local deleted = 0
            for _, vehicle in ipairs(GetAllVehicles()) do
                if DoesEntityExist(vehicle) then
                    local driver = GetPedInVehicleSeat(vehicle, -1)
                    if not driver or driver == 0 then
                        DeleteEntity(vehicle)
                        deleted = deleted + 1
                    end
                end
            end

            TriggerClientEvent("chatMessage", -1, ("^1ADMIN: ^0%d veículos removidos."):format(deleted))
            TriggerClientEvent("Notify", -1, "sucesso", ("ADMIN: %d veículos removidos."):format(deleted), 8000)
            cleanupRunning = false
        end)

        return result(true, ("Limpeza iniciada. Execução em %d segundos."):format(delay))
    end

    return result(false, "Ação administrativa desconhecida.")
end


-- Encerra monitoramentos quando administrador/alvo desconecta.
AddEventHandler("playerDropped", function()
    local droppedSource = tonumber(source)
    if not droppedSource then return end

    for userIdKey, appliedSource in pairs(punishmentAppliedSources) do
        if tonumber(appliedSource) == droppedSource then
            punishmentAppliedSources[userIdKey] = nil
        end
    end

    if VIP.tests[droppedSource] then
        VIP.tests[droppedSource] = nil
    end

    local adminToken = liveScreenByAdmin[droppedSource]
    if adminToken then
        closeLiveScreenSession(adminToken, false)
    end

    local tokens = {}
    for token, session in pairs(liveScreenSessions) do
        if session and session.active and tonumber(session.targetSource) == droppedSource then
            tokens[#tokens + 1] = token
        end
    end
    for _, token in ipairs(tokens) do
        closeLiveScreenSession(token, true, "O jogador ficou offline.")
    end
end)
