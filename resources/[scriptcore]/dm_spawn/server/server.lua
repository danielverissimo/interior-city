-- ============================================================================
-- dm_spawn - integração de spawn com m_mansions + IC Admin
--
-- A integração é intencionalmente somente-leitura: o spawn consulta os JSONs
-- persistidos pelos dois resources. Assim não precisamos alterar nem acoplar
-- o painel ADM ou o sistema de mansões ao dm_spawn.
-- ============================================================================

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalize(value)
    value = trim(value):lower()
    value = value
        :gsub("[áàâãä]", "a")
        :gsub("[éèêë]", "e")
        :gsub("[íìîï]", "i")
        :gsub("[óòôõö]", "o")
        :gsub("[úùûü]", "u")
        :gsub("ç", "c")
    return value:gsub("[^%w]", "")
end

local function validCoords(coords)
    return type(coords) == "table"
        and tonumber(coords.x or coords[1]) ~= nil
        and tonumber(coords.y or coords[2]) ~= nil
        and tonumber(coords.z or coords[3]) ~= nil
end

local function normalizeCoords(coords)
    if not validCoords(coords) then return nil end
    return {
        tonumber(coords.x or coords[1]) + 0.0,
        tonumber(coords.y or coords[2]) + 0.0,
        tonumber(coords.z or coords[3]) + 0.0
    }
end

local function readJsonResource(resourceName, fileName)
    resourceName = trim(resourceName)
    fileName = trim(fileName)
    if resourceName == "" or fileName == "" then return nil end

    local raw = LoadResourceFile(resourceName, fileName)
    if not raw or raw == "" then return nil end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= "table" then
        print(("^1[dm_spawn]^7 Não foi possível ler %s/%s."):format(resourceName, fileName))
        return nil
    end

    return decoded
end

local function userGroups(userId)
    if not userId then return {} end
    local groups = vRP.getUserGroups(userId)
    return type(groups) == "table" and groups or {}
end

local function groupDefinitions()
    if type(vRP.getGroups) == "function" then
        local ok, groups = pcall(function() return vRP.getGroups() end)
        if ok and type(groups) == "table" then return groups end
    end

    -- Compatibilidade com bases que não expõem vRP.getGroups().
    local ok, cfg = pcall(function()
        return module("vrp", "cfg/groups")
    end)
    if ok and type(cfg) == "table" then
        return cfg.groups or cfg
    end

    return {}
end

local function ignoredFactionCategory(category)
    local wanted = normalize(category)
    for _, value in ipairs(Config.FactionIgnoredCategories or {}) do
        if normalize(value) == wanted then return true end
    end
    return false
end

local function getPanelLocations()
    local provider = GetConvar("ic_admin_service_resource", "ic_admin")
    local data
    if GetResourceState(provider) == "started" then
        local ok, locations = pcall(function() return exports[provider]:getLocations() end)
        if ok and type(locations) == "table" then data = locations end
    end
    if not data and provider ~= "ic_admin" then
        -- Compatibilidade apenas durante a coexistência, selecionada pelo operador.
        data = readJsonResource(provider, Config.AdminPanelLocationsFile or "locations.json")
    end

    if type(data) ~= "table" then return {} end

    local out = {}
    for _, location in ipairs(data) do
        if type(location) == "table" then
            local name = trim(location.name or location.nome)
            local category = trim(location.category or location.categoria)
            local coords = normalizeCoords(location)
            if name ~= "" and category ~= "" and coords then
                out[#out + 1] = {
                    name = name,
                    category = category,
                    coords = coords
                }
            end
        end
    end

    return out
end

local function locationsByCategory(locations)
    local categories = {}
    for _, location in ipairs(locations or {}) do
        local key = normalize(location.category)
        if key ~= "" and not ignoredFactionCategory(location.category) then
            categories[key] = categories[key] or {
                name = location.category,
                locations = {}
            }
            categories[key].locations[#categories[key].locations + 1] = location
        end
    end
    return categories
end

local function definitionConfig(definition)
    if type(definition) ~= "table" then return nil end
    -- A base atual retorna _config; deixamos config como compatibilidade.
    return definition._config or definition.config
end

local function findFactionCategory(userId, categories)
    local ownedGroups = userGroups(userId)
    local definitions = groupDefinitions()
    local best, bestScore

    for groupName in pairs(ownedGroups) do
        local normalizedGroup = normalize(groupName)
        local definition = definitions[groupName]
        local cfg = definitionConfig(definition)
        local orgName = cfg and trim(cfg.orgName) or ""
        local normalizedOrg = normalize(orgName)

        for categoryKey, category in pairs(categories) do
            local score = nil

            -- Regra mais confiável: _config.orgName da própria vRP bate com a
            -- categoria cadastrada no painel ADM (Mafia, Cartel, Colombia...).
            if normalizedOrg ~= "" and normalizedOrg == categoryKey then
                score = 100000 + #categoryKey
            -- Fallback pedido pelo usuário: MembroMafia, LiderMafia,
            -- GerenteMafia etc. contêm a palavra-chave da categoria.
            elseif categoryKey ~= "" and normalizedGroup:find(categoryKey, 1, true) then
                score = 1000 + #categoryKey
            end

            if score and (not bestScore or score > bestScore) then
                best = category
                bestScore = score
            end
        end
    end

    return best
end

local function locationPreferenceScore(location)
    local name = normalize(location and location.name)
    if name == "fac" then return 100000 end
    if name == "localdafac" or name == "localfac" then return 95000 end
    if name:sub(1, 5) == "local" then return 90000 end
    if name == "interfone" then return 80000 end
    if name == "garagempublica" then return 70000 end

    -- Preferências adicionais configuráveis sem precisar alterar o código.
    for index, preferred in ipairs(Config.FactionSpawnLocationNames or {}) do
        if name == normalize(preferred) then
            return 60000 - index
        end
    end

    return 0
end

local function chooseFactionLocation(category)
    if not category or type(category.locations) ~= "table" then return nil end

    local best, bestScore = nil, -1
    for _, location in ipairs(category.locations) do
        if location.coords then
            local score = locationPreferenceScore(location)
            if score > bestScore then
                best, bestScore = location, score
            end
        end
    end

    return best
end

local function resolveFactionSpawn(userId)
    local locations = getPanelLocations()
    if #locations == 0 then return nil end

    local category = findFactionCategory(userId, locationsByCategory(locations))
    if not category then return nil end

    local location = chooseFactionLocation(category)
    if not location then return nil end

    return {
        coords = location.coords,
        category = category.name,
        location = location.name
    }
end

local function mansionBelongsToUser(mansion, userId)
    userId = tonumber(userId)
    if not userId or type(mansion) ~= "table" then return false, false end

    if tonumber(mansion.ownerId) == userId then
        return true, true
    end

    if Config.AllowMansionResidentsSpawn ~= false then
        for _, memberId in ipairs(mansion.members or {}) do
            if tonumber(memberId) == userId then
                return true, false
            end
        end
    end

    return false, false
end

local function resolveHomeSpawn(userId)
    local data = readJsonResource(
        Config.MansionsResource or "m_mansions",
        Config.MansionsDataFile or "mansions.json"
    )
    if not data then return nil end

    local mansions = data.mansions or data
    if type(mansions) ~= "table" then return nil end

    local candidates = {}
    for _, mansion in pairs(mansions) do
        local belongs, isOwner = mansionBelongsToUser(mansion, userId)
        local coords = belongs and normalizeCoords(mansion.purchaseCoords) or nil
        if coords then
            candidates[#candidates + 1] = {
                coords = coords,
                name = trim(mansion.name) ~= "" and trim(mansion.name) or "Mansão",
                id = tostring(mansion.id or ""),
                owner = isOwner,
                purchasedAt = tonumber(mansion.purchasedAt) or 0
            }
        end
    end

    if #candidates == 0 then return nil end

    -- A NUI atual possui apenas um botão "Sua Casa". Se o jogador estiver em
    -- mais de uma mansão, priorizamos primeiro uma mansão que ele realmente
    -- comprou e, entre elas, a compra mais recente.
    table.sort(candidates, function(a, b)
        if a.owner ~= b.owner then return a.owner == true end
        if a.purchasedAt ~= b.purchasedAt then return a.purchasedAt > b.purchasedAt end
        return tostring(a.name):lower() < tostring(b.name):lower()
    end)

    return candidates[1]
end

function API.GetUserData()
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        local rows = vRP.getUData(user_id, "vRP:datatable")
        if rows then
            local data = json.decode(rows) or {}
            if data then return data end
        end
    end
    return false
end

RegisterCommand("bucket", function(source)
    TriggerClientEvent("Notify", source, "Você está na bucket " .. GetPlayerRoutingBucket(source))
end, false)

function API.setBucket(status)
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        if status then
            SetPlayerRoutingBucket(source, source)
            if GetPlayerRoutingBucket(source) ~= source then
                SetPlayerRoutingBucket(source, source)
            end
        else
            SetPlayerRoutingBucket(source, 0)
        end
    end
end

-- Retorna as duas permissões de spawn já resolvidas pelo servidor. A NUI só
-- recebe booleanos; coordenadas nunca vêm do browser, evitando spoof.
function API.getSpawnContext()
    local source = source
    local userId = vRP.getUserId(source)
    if not userId then
        return { hasHome = false, hasOrg = false }
    end

    local home = resolveHomeSpawn(userId)
    local org = resolveFactionSpawn(userId)

    return {
        hasHome = home ~= nil,
        hasOrg = org ~= nil,
        homeName = home and home.name or nil,
        orgName = org and org.category or nil
    }
end

function API.getHomeSpawn()
    local source = source
    local userId = vRP.getUserId(source)
    if not userId then return false end

    local home = resolveHomeSpawn(userId)
    if not home then return false end

    return {
        coords = home.coords,
        name = home.name,
        id = home.id
    }
end

function API.getOrgSpawn()
    local source = source
    local userId = vRP.getUserId(source)
    if not userId then return false end

    local org = resolveFactionSpawn(userId)
    if not org then return false end

    return {
        coords = org.coords,
        category = org.category,
        location = org.location
    }
end

-- Compatibilidade com versões antigas do dm_spawn / integrações externas.
function API.HasHome()
    local source = source
    local userId = vRP.getUserId(source)
    return userId and resolveHomeSpawn(userId) ~= nil or false
end

function API.GetOrg()
    local source = source
    local userId = vRP.getUserId(source)
    if not userId then return false end
    local org = resolveFactionSpawn(userId)
    if not org then return false end
    return true, org.category
end

function API.getOrg()
    return API.GetOrg()
end
