local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

local vRP = Proxy.getInterface("vRP")

local API = {}
Tunnel.bindInterface("drogas_entregas", API)

local sessions = {}
local sourceUsers = {}
local requestCooldown = {}
local clearSession

local reputationCache = {}
local reputationDbReady = false

local function ensureReputationTable()
    if reputationDbReady then return true end

    local ok, err = pcall(function()
        exports.oxmysql:executeSync([[
            CREATE TABLE IF NOT EXISTS drogas_reputation (
                user_id INT NOT NULL PRIMARY KEY,
                level VARCHAR(24) NOT NULL DEFAULT 'intacta',
                arrest_progress INT NOT NULL DEFAULT 0,
                clean_sales INT NOT NULL DEFAULT 0,
                total_sales INT NOT NULL DEFAULT 0,
                total_drug_arrests INT NOT NULL DEFAULT 0,
                last_arrest_at BIGINT NOT NULL DEFAULT 0,
                updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
        ]])
    end)

    if not ok then
        print(('[drogas_entregas] [ERROR] Não foi possível criar drogas_reputation: %s'):format(tostring(err)))
        return false
    end

    reputationDbReady = true
    return true
end

CreateThread(function()
    ensureReputationTable()
end)

local function reputationConfig()
    return Config.Reputation or {}
end

local function reputationLevels()
    return reputationConfig().levels or {}
end

local function normalizeReputationLevel(level)
    local levels = reputationLevels()
    level = tostring(level or '')
    if levels[level] then return level end

    local fallback = tostring(reputationConfig().defaultLevel or 'intacta')
    if levels[fallback] then return fallback end
    if levels.intacta then return 'intacta' end

    for key in pairs(levels) do
        return key
    end

    return 'intacta'
end

local function getReputationLevelConfig(level)
    local levels = reputationLevels()
    local normalized = normalizeReputationLevel(level)
    return levels[normalized] or {}, normalized
end

local function saveReputation(data)
    if not data or not data.user_id or not ensureReputationTable() then return false end

    exports.oxmysql:execute([[
        INSERT INTO drogas_reputation
            (user_id, level, arrest_progress, clean_sales, total_sales, total_drug_arrests, last_arrest_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            level = VALUES(level),
            arrest_progress = VALUES(arrest_progress),
            clean_sales = VALUES(clean_sales),
            total_sales = VALUES(total_sales),
            total_drug_arrests = VALUES(total_drug_arrests),
            last_arrest_at = VALUES(last_arrest_at)
    ]], {
        data.user_id,
        normalizeReputationLevel(data.level),
        math.max(0, math.floor(tonumber(data.arrest_progress) or 0)),
        math.max(0, math.floor(tonumber(data.clean_sales) or 0)),
        math.max(0, math.floor(tonumber(data.total_sales) or 0)),
        math.max(0, math.floor(tonumber(data.total_drug_arrests) or 0)),
        math.max(0, math.floor(tonumber(data.last_arrest_at) or 0))
    })

    return true
end

local function getReputation(user_id)
    user_id = math.floor(tonumber(user_id) or 0)
    if user_id <= 0 then return nil end

    if reputationCache[user_id] then
        return reputationCache[user_id]
    end

    if not ensureReputationTable() then return nil end

    local rows = exports.oxmysql:executeSync([[
        SELECT level, arrest_progress, clean_sales, total_sales, total_drug_arrests, last_arrest_at
        FROM drogas_reputation
        WHERE user_id = ?
        LIMIT 1
    ]], { user_id }) or {}

    local row = rows[1]
    local data = {
        user_id = user_id,
        level = normalizeReputationLevel(row and row.level or nil),
        arrest_progress = math.max(0, math.floor(tonumber(row and row.arrest_progress) or 0)),
        clean_sales = math.max(0, math.floor(tonumber(row and row.clean_sales) or 0)),
        total_sales = math.max(0, math.floor(tonumber(row and row.total_sales) or 0)),
        total_drug_arrests = math.max(0, math.floor(tonumber(row and row.total_drug_arrests) or 0)),
        last_arrest_at = math.max(0, math.floor(tonumber(row and row.last_arrest_at) or 0))
    }

    reputationCache[user_id] = data

    if not row then
        saveReputation(data)
    end

    return data
end

local function reputationPayload(data)
    if not data then return nil end

    local levelCfg, level = getReputationLevelConfig(data.level)
    local levels = reputationLevels()
    local recoverTo = levelCfg.recoverTo and normalizeReputationLevel(levelCfg.recoverTo) or nil
    local dropTo = levelCfg.dropTo and normalizeReputationLevel(levelCfg.dropTo) or nil
    local recoverCfg = recoverTo and levels[recoverTo] or nil
    local dropCfg = dropTo and levels[dropTo] or nil

    local paymentPercent = tonumber(levelCfg.paymentPercent) or 100
    if paymentPercent < 0 then paymentPercent = 0 end
    if paymentPercent > 500 then paymentPercent = 500 end

    return {
        key = level,
        label = tostring(levelCfg.label or string.upper(level)),
        color = tostring(levelCfg.color or '#d7d7d7'),
        paymentPercent = paymentPercent,
        arrestProgress = math.max(0, math.floor(tonumber(data.arrest_progress) or 0)),
        arrestsRequired = math.max(0, math.floor(tonumber(levelCfg.arrestsToDrop) or 0)),
        cleanSales = math.max(0, math.floor(tonumber(data.clean_sales) or 0)),
        cleanSalesRequired = math.max(0, math.floor(tonumber(levelCfg.salesToRecover) or 0)),
        recoverTo = recoverTo,
        recoverLabel = recoverCfg and tostring(recoverCfg.label or string.upper(recoverTo)) or nil,
        dropTo = dropTo,
        dropLabel = dropCfg and tostring(dropCfg.label or string.upper(dropTo)) or nil,
        totalSales = math.max(0, math.floor(tonumber(data.total_sales) or 0)),
        totalDrugArrests = math.max(0, math.floor(tonumber(data.total_drug_arrests) or 0))
    }
end

local function applyReputationPrice(value, data)
    value = math.max(0, math.floor(tonumber(value) or 0))
    if reputationConfig().enabled == false then return value end

    local levelCfg = getReputationLevelConfig(data and data.level)
    local percentage = tonumber(levelCfg.paymentPercent) or 100
    if percentage < 0 then percentage = 0 end
    if percentage > 500 then percentage = 500 end

    return math.max(0, math.floor((value * percentage) / 100))
end

local function pushReputationUpdate(user_id)
    local data = getReputation(user_id)
    if not data then return end

    local target = vRP.getUserSource(user_id)
    if target then
        TriggerClientEvent('drogas_entregas:reputationUpdated', target, reputationPayload(data))
    end
end

local function registerCleanSale(user_id)
    if reputationConfig().enabled == false then return nil, false end

    local data = getReputation(user_id)
    if not data then return nil, false end

    data.total_sales = (data.total_sales or 0) + 1

    local levelCfg, oldLevel = getReputationLevelConfig(data.level)
    local changed = false

    if levelCfg.recoverTo and (tonumber(levelCfg.salesToRecover) or 0) > 0 then
        data.clean_sales = (data.clean_sales or 0) + 1
        local required = math.max(1, math.floor(tonumber(levelCfg.salesToRecover) or 1))

        if data.clean_sales >= required then
            data.level = normalizeReputationLevel(levelCfg.recoverTo)
            data.clean_sales = 0
            data.arrest_progress = 0
            changed = true
        end
    else
        data.clean_sales = 0
    end

    saveReputation(data)
    pushReputationUpdate(user_id)

    if changed then
        local target = vRP.getUserSource(user_id)
        local newCfg = getReputationLevelConfig(data.level)
        if target then
            TriggerClientEvent('Notify', target, 'sucesso',
                'Sua reputação melhorou para <b>' .. tostring(newCfg.label or string.upper(data.level)) .. '</b> após realizar vendas sem ser pego.', 7000)
        end
    end

    return reputationPayload(data), changed, oldLevel
end

local function isDrugSaleCrime(crimeName)
    crimeName = tostring(crimeName or '')
    if crimeName == '' then return false end

    local lowered = string.lower(crimeName)
    for _, configuredName in ipairs(reputationConfig().mdtCrimeNames or {}) do
        if lowered == string.lower(tostring(configuredName or '')) then
            return true
        end
    end

    return false
end

local function registerDrugArrest(user_id, officer_id, crimeName)
    if reputationConfig().enabled == false then return false end
    if not isDrugSaleCrime(crimeName) then return false end

    user_id = math.floor(tonumber(user_id) or 0)
    if user_id <= 0 then return false end

    local data = getReputation(user_id)
    if not data then return false end

    local now = os.time()
    local protection = math.max(0, math.floor(tonumber(reputationConfig().duplicateArrestProtectionSeconds) or 15))
    if protection > 0 and (data.last_arrest_at or 0) > 0 and (now - data.last_arrest_at) < protection then
        return false
    end

    data.last_arrest_at = now
    data.total_drug_arrests = (data.total_drug_arrests or 0) + 1
    data.clean_sales = 0

    local levelCfg, oldLevel = getReputationLevelConfig(data.level)
    local required = math.max(0, math.floor(tonumber(levelCfg.arrestsToDrop) or 0))
    local changed = false

    if levelCfg.dropTo and required > 0 then
        data.arrest_progress = (data.arrest_progress or 0) + 1
        if data.arrest_progress >= required then
            data.level = normalizeReputationLevel(levelCfg.dropTo)
            data.arrest_progress = 0
            data.clean_sales = 0
            changed = true
        end
    else
        -- HORRÍVEL é o piso: continua registrando o total de prisões,
        -- mas não acumula um contador sem utilidade.
        data.arrest_progress = 0
    end

    saveReputation(data)

    -- Ser preso encerra imediatamente qualquer rota clandestina ainda aberta.
    if sessions and sessions[user_id] then
        clearSession(user_id)
    end

    local target = vRP.getUserSource(user_id)
    if target then
        TriggerClientEvent('drogas_entregas:forceStopRoute', target)

        if changed then
            local newCfg = getReputationLevelConfig(data.level)
            TriggerClientEvent('Notify', target, 'negado',
                'Você foi preso por venda de drogas. Sua reputação caiu para <b>' ..
                tostring(newCfg.label or string.upper(data.level)) .. '</b>.', 8000)
        else
            local currentCfg = getReputationLevelConfig(data.level)
            local need = math.max(0, math.floor(tonumber(currentCfg.arrestsToDrop) or 0))
            local progress = math.max(0, math.floor(tonumber(data.arrest_progress) or 0))
            if need > 0 then
                TriggerClientEvent('Notify', target, 'aviso',
                    ('Prisão por venda de drogas registrada. Risco de queda de reputação: <b>%d/%d</b>.'):format(progress, need), 7000)
            end
        end
    end

    pushReputationUpdate(user_id)

    print(('[drogas_entregas] Reputação do ID %d atualizada pelo MDT (%s). Oficial: %s | %s -> %s'):format(
        user_id, tostring(crimeName), tostring(officer_id or 'N/A'), tostring(oldLevel), tostring(data.level)
    ))

    return true
end

-- Evento somente server-side. Não é RegisterNetEvent, portanto clientes não conseguem
-- forjar uma prisão para alterar reputação.
AddEventHandler('drogas_entregas:mdtDrugArrest', function(user_id, officer_id, crimeName)
    registerDrugArrest(user_id, officer_id, crimeName)
end)

exports('registerDrugArrest', registerDrugArrest)
exports('getReputation', function(user_id)
    return reputationPayload(getReputation(user_id))
end)


local function int(value)
    return math.floor(tonumber(value) or 0)
end

local function clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function notify(source, kind, message, duration)
    TriggerClientEvent("Notify", source, kind, message, duration or 5000)
end

local function formatMoney(value)
    if vRP.format then
        return vRP.format(int(value))
    end
    return tostring(int(value))
end

local function coordsDistanceSquared(a, b)
    local dx = (a.x or 0.0) - (b.x or 0.0)
    local dy = (a.y or 0.0) - (b.y or 0.0)
    local dz = (a.z or 0.0) - (b.z or 0.0)
    return dx * dx + dy * dy + dz * dz
end

local function isNear(source, target, maxDistance)
    local ped = GetPlayerPed(source)
    if not ped or ped <= 0 then return false end

    local coords = GetEntityCoords(ped)
    if not coords then return false end

    return coordsDistanceSquared(coords, target) <= ((tonumber(maxDistance) or 3.0) ^ 2)
end

local function isBlocked(user_id)
    for _, permission in ipairs((Config.Route and Config.Route.blockedPermissions) or {}) do
        if permission and permission ~= "" and vRP.hasPermission(user_id, permission) then
            return true
        end
    end
    return false
end

local function getDrug(key)
    key = tostring(key or "")
    local drug = Config.Drugs and Config.Drugs[key]
    if type(drug) ~= "table" then return nil end
    if type(drug.item) ~= "string" or drug.item == "" then return nil end
    return drug, key
end

local function getPoint(index)
    index = int(index)
    local point = Config.RoutePoints and Config.RoutePoints[index]
    if type(point) ~= "table" then return nil end
    return point
end

local function randomPoint(exclude)
    local total = #(Config.RoutePoints or {})
    if total <= 0 then return nil end
    if total == 1 then return 1 end

    local selected = math.random(total)
    local tries = 0
    while selected == exclude and tries < 12 do
        selected = math.random(total)
        tries = tries + 1
    end

    if selected == exclude then
        selected = (exclude % total) + 1
    end

    return selected
end

local function pointPayload(index)
    local point = getPoint(index)
    if not point then return nil end
    return {
        index = index,
        x = tonumber(point.x) or 0.0,
        y = tonumber(point.y) or 0.0,
        z = tonumber(point.z) or 0.0
    }
end

clearSession = function(user_id)
    local session = sessions[user_id]
    if not session then return end
    if session.source then
        sourceUsers[session.source] = nil
        requestCooldown[session.source] = nil
    end
    sessions[user_id] = nil
end

local function nextPoint(session)
    session.point = randomPoint(session.point)
    return pointPayload(session.point)
end

local function dispatchPolice(source, user_id, drug)
    local cfg = Config.Dispatch or {}
    if cfg.enabled == false then return end

    -- Não existe fallback para chat/blip antigo: este resource usa exclusivamente vrp_notifycall.
    local resourceName = tostring(cfg.resource or "vrp_notifycall")
    if GetResourceState(resourceName) ~= "started" then
        print(("[drogas_entregas] [WARNING] %s não está iniciado; alerta policial não enviado."):format(resourceName))
        return
    end

    local ped = GetPlayerPed(source)
    if not ped or ped <= 0 then return end
    local coords = GetEntityCoords(ped)
    if not coords then return end

    local permission = tostring(cfg.policePermission or "perm.policia")
    local police = vRP.getUsersByPermission(permission) or {}
    local dispatchId = ("drug-sale:%s:%s:%04d"):format(tostring(user_id), tostring(os.time()), math.random(0, 9999))
    local text = tostring(cfg.text or "Um cidadão denunciou uma possível venda de drogas. Verifique a região.")

    if drug and drug.label then
        text = text .. " Possível produto: " .. tostring(drug.label) .. "."
    end

    for _, policeUserId in pairs(police) do
        local player = vRP.getUserSource(int(policeUserId))
        if player then
            TriggerClientEvent(tostring(cfg.event or "NotifyPush"), player, {
                code = tostring(cfg.code or "911"),
                title = tostring(cfg.title or "VENDA DE DROGAS"),
                text = text,
                x = coords.x,
                y = coords.y,
                z = coords.z,
                time = os.date("%H:%M"),
                rgba = cfg.rgba or { 255, 55, 70, 255 },
                blipSprite = int(cfg.blipSprite or 161),
                blipColor = int(cfg.blipColor or 1),
                blipScale = tonumber(cfg.blipScale) or 0.85,
                blipDuration = math.max(1000, int(cfg.blipDuration or 60000)),
                sound = cfg.sound ~= false,
                dispatchId = dispatchId
            })
        end
    end
end

function API.getMenuData()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return { ok = false } end

    if sessions[user_id] then
        notify(source, "aviso", "Você já possui uma rota de venda em andamento. Pressione <b>F7</b> para encerrar.")
        return { ok = false, active = true }
    end

    if isBlocked(user_id) then
        notify(source, "negado", "Você não pode iniciar uma rota de venda de drogas.")
        return { ok = false }
    end

    local start = Config.Start and Config.Start.coords
    if not start or not isNear(source, start, 4.0) then
        return { ok = false }
    end

    local reputation = getReputation(user_id)
    local entries = {}
    local order = Config.DrugOrder or {}
    local added = {}

    local function addDrug(key, drug)
        if added[key] or type(drug) ~= "table" or not drug.item then return end
        added[key] = true
        entries[#entries + 1] = {
            key = key,
            item = drug.item,
            label = drug.label or drug.item,
            description = drug.description or "",
            image = drug.image or drug.item,
            stock = int(vRP.getInventoryItemAmount(user_id, drug.item)),
            minQuantity = math.max(1, int(drug.minQuantity or 1)),
            maxQuantity = math.max(1, int(drug.maxQuantity or 3)),
            minPricePerUnit = applyReputationPrice(math.max(0, int(drug.minPricePerUnit or 0)), reputation),
            maxPricePerUnit = applyReputationPrice(math.max(0, int(drug.maxPricePerUnit or drug.minPricePerUnit or 0)), reputation),
            refusalChance = clamp(drug.refusalChance or 0, 0, 100)
        }
    end

    for _, key in ipairs(order) do
        addDrug(key, Config.Drugs and Config.Drugs[key])
    end

    -- Se adicionar uma nova droga e esquecer de colocá-la no DrugOrder,
    -- ela ainda aparecerá no painel.
    for key, drug in pairs(Config.Drugs or {}) do
        addDrug(key, drug)
    end

    return {
        ok = true,
        imageBaseUrl = tostring(Config.ImageBaseUrl or ""),
        reputation = reputationPayload(reputation),
        drugs = entries
    }
end

function API.startRoute(drugKey)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return { ok = false } end

    if sessions[user_id] then
        return { ok = false, message = "Você já possui uma rota em andamento." }
    end

    if isBlocked(user_id) then
        return { ok = false, message = "Você não pode iniciar esta rota." }
    end

    local start = Config.Start and Config.Start.coords
    if not start or not isNear(source, start, 4.0) then
        return { ok = false, message = "Você se afastou do ponto de início." }
    end

    local drug, key = getDrug(drugKey)
    if not drug then
        return { ok = false, message = "Droga inválida." }
    end

    local stock = int(vRP.getInventoryItemAmount(user_id, drug.item))
    if stock <= 0 then
        return { ok = false, message = "Você não possui " .. tostring(drug.label or drug.item) .. " para vender." }
    end

    local point = randomPoint(nil)
    if not point then
        return { ok = false, message = "Nenhum ponto de venda foi configurado." }
    end

    sessions[user_id] = {
        user_id = user_id,
        source = source,
        drugKey = key,
        point = point,
        busy = false,
        startedAt = os.time()
    }
    sourceUsers[source] = user_id

    return {
        ok = true,
        drug = {
            key = key,
            item = drug.item,
            label = drug.label or drug.item
        },
        point = pointPayload(point)
    }
end

function API.attemptSale()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return { ok = false } end

    local session = sessions[user_id]
    if not session or session.source ~= source then
        return { ok = false, ended = true, message = "Sua rota não está mais ativa." }
    end

    local now = GetGameTimer()
    local cooldown = math.max(500, int((Config.Route and Config.Route.interactionCooldownMs) or 1200))
    if requestCooldown[source] and (now - requestCooldown[source]) < cooldown then
        return { ok = false, busy = true }
    end
    requestCooldown[source] = now

    if session.busy then
        return { ok = false, busy = true }
    end
    session.busy = true

    local function done(data)
        session.busy = false
        return data
    end

    local point = getPoint(session.point)
    if not point then
        clearSession(user_id)
        return { ok = false, ended = true, message = "O ponto da rota ficou inválido." }
    end

    local maxDistance = tonumber((Config.Route and Config.Route.serverValidationDistance) or 5.0) or 5.0
    if not isNear(source, point, maxDistance) then
        return done({ ok = false, message = "Aproxime-se do local da venda." })
    end

    local drug = Config.Drugs and Config.Drugs[session.drugKey]
    if not drug then
        clearSession(user_id)
        return { ok = false, ended = true, message = "A droga desta rota não está mais configurada." }
    end

    local stock = int(vRP.getInventoryItemAmount(user_id, drug.item))
    if stock <= 0 then
        clearSession(user_id)
        notify(source, "aviso", "Você ficou sem <b>" .. tostring(drug.label or drug.item) .. "</b>. A rota foi encerrada.")
        return { ok = true, ended = true, outcome = "no_items" }
    end

    local refusalChance = clamp(drug.refusalChance or 0, 0, 100)
    local refused = math.random(1, 100) <= refusalChance

    if refused then
        -- O item não é removido quando o comprador recusa.
        dispatchPolice(source, user_id, drug)
        local nextRoutePoint = nextPoint(session)
        notify(source, "negado", "O comprador <b>recusou a venda</b> e chamou a polícia!", 6000)
        return done({
            ok = true,
            outcome = "refused",
            nextPoint = nextRoutePoint
        })
    end

    local minQuantity = math.max(1, int(drug.minQuantity or 1))
    local maxQuantity = math.max(minQuantity, int(drug.maxQuantity or minQuantity))
    local quantity = math.random(minQuantity, maxQuantity)
    quantity = math.min(quantity, stock)

    if quantity <= 0 then
        clearSession(user_id)
        return { ok = true, ended = true, outcome = "no_items" }
    end

    if not vRP.tryGetInventoryItem(user_id, drug.item, quantity, true) then
        return done({ ok = false, message = "Seu inventário mudou. Tente novamente." })
    end

    local minPrice = math.max(0, int(drug.minPricePerUnit or 0))
    local maxPrice = math.max(minPrice, int(drug.maxPricePerUnit or minPrice))
    local baseUnitPrice = math.random(minPrice, maxPrice)
    local reputation = getReputation(user_id)
    local unitPrice = applyReputationPrice(baseUnitPrice, reputation)
    local payment = unitPrice * quantity
    local dirtyMoneyItem = tostring((Config.Route and Config.Route.dirtyMoneyItem) or "dirty_money")

    vRP.giveInventoryItem(user_id, dirtyMoneyItem, payment, true)

    -- Só uma venda realmente concluída conta para recuperação de reputação.
    local updatedReputation = registerCleanSale(user_id)

    local remaining = int(vRP.getInventoryItemAmount(user_id, drug.item))
    local nextRoutePoint = nil
    local ended = remaining <= 0

    if ended then
        clearSession(user_id)
    else
        nextRoutePoint = nextPoint(session)
    end

    notify(source, "sucesso",
        "Você vendeu <b>" .. quantity .. "x " .. tostring(drug.label or drug.item) ..
        "</b> e recebeu <b>$" .. formatMoney(payment) .. " em dinheiro sujo</b>.", 6000)

    return done({
        ok = true,
        outcome = "sold",
        quantity = quantity,
        payment = payment,
        remaining = remaining,
        reputation = updatedReputation,
        ended = ended,
        nextPoint = nextRoutePoint
    })
end

function API.cancelRoute()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return false end

    if sessions[user_id] then
        clearSession(user_id)
        return true
    end

    return false
end

AddEventHandler("playerDropped", function()
    local source = source
    local user_id = sourceUsers[source] or vRP.getUserId(source)
    if user_id then
        clearSession(user_id)
    end
    requestCooldown[source] = nil
    sourceUsers[source] = nil
    if user_id then
        reputationCache[user_id] = nil
    end
end)
