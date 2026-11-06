-- Entregador - servidor
-- Fluxo autoritativo: iniciar -> entregar -> coletar -> entregar ... até encerrar o expediente.
-- Itens, quantidades e pontos são lidos de cfg.extra["Entregador"] e podem ser alterados pelo mg_config_panel.

local deliverySessions = {}

local DEFAULT_PROP = "prop_food_cb_bag_01"
local ACTION_COOLDOWN_MS = 650
local INTERACT_DISTANCE = 4.5

local function clone(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k,v in pairs(value) do out[k] = clone(v) end
    return out
end

local function deliveryExtra()
    return (cfg.extra and cfg.extra["Entregador"]) or {}
end

local function normalizePoint(point)
    if type(point) ~= "table" then return nil end
    local x = tonumber(point.x or point[1])
    local y = tonumber(point.y or point[2])
    local z = tonumber(point.z or point[3])
    if not x or not y or not z then return nil end
    return { x = x, y = y, z = z }
end

local function configuredPoints(key)
    local result = {}
    for _, point in pairs(deliveryExtra()[key] or {}) do
        local normalized = normalizePoint(point)
        if normalized then result[#result+1] = normalized end
    end
    return result
end

local function configuredItems()
    local extra = deliveryExtra()
    local result = {}

    for _, entry in pairs(extra.itens or {}) do
        if type(entry) == "string" then
            local item = tostring(entry)
            if item ~= "" then
                result[#result+1] = {
                    item = item,
                    min = 1,
                    max = 3,
                    prop = DEFAULT_PROP
                }
            end
        elseif type(entry) == "table" then
            local item = tostring(entry.item or entry.index or "")
            local minAmount = math.max(1, math.floor(tonumber(entry.min or entry.minimo) or 1))
            local maxAmount = math.max(minAmount, math.floor(tonumber(entry.max or entry.maximo) or 3))
            local prop = tostring(entry.prop or DEFAULT_PROP)
            if item ~= "" then
                result[#result+1] = {
                    item = item,
                    min = minAmount,
                    max = maxAmount,
                    prop = prop ~= "" and prop or DEFAULT_PROP
                }
            end
        end
    end

    -- Compatibilidade/fallback para servidores que ainda não salvaram a nova lista pelo painel.
    if #result == 0 then
        local fallbackProp = DEFAULT_PROP
        if type(extra.objetos) == "table" and extra.objetos[1] then
            fallbackProp = tostring(extra.objetos[1])
        end
        result[1] = {
            item = "lanches",
            min = 1,
            max = 3,
            prop = fallbackProp
        }
    end

    return result
end

local function serviceItemSet(userId)
    local set = {}
    for _, entry in ipairs(configuredItems()) do
        set[entry.item] = true
    end

    local session = userId and deliverySessions[tonumber(userId)] or nil
    if session and session.batch and session.batch.item then
        set[tostring(session.batch.item)] = true
    end

    return set
end

exports("isDeliveryServiceItem", function(item)
    item = tostring(item or "")
    if item == "" then return false end

    if serviceItemSet()[item] then return true end
    for _, session in pairs(deliverySessions) do
        if session and session.batch and tostring(session.batch.item or "") == item then
            return true
        end
    end
    return false
end)

exports("getDeliveryServiceItems", function()
    local set = serviceItemSet()
    for _, session in pairs(deliverySessions) do
        if session and session.batch and session.batch.item then
            set[tostring(session.batch.item)] = true
        end
    end

    local list = {}
    for item in pairs(set) do list[#list+1] = item end
    table.sort(list)
    return list
end)

local function isServiceActive(userId)
    return type(MageEmpregosIsServiceActive) == "function"
        and MageEmpregosIsServiceActive(userId, "Entregador")
end

local function playerDistanceTo(source, point)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 or not point then return math.huge end
    local coords = GetEntityCoords(ped)
    local dx = coords.x - point.x
    local dy = coords.y - point.y
    local dz = coords.z - point.z
    return math.sqrt((dx*dx) + (dy*dy) + (dz*dz))
end

local function choosePoint(points, previousIndex)
    if #points == 0 then return nil, nil end
    if #points == 1 then return clone(points[1]), 1 end

    local index = math.random(1, #points)
    local tries = 0
    while previousIndex and index == previousIndex and tries < 10 do
        index = math.random(1, #points)
        tries = tries + 1
    end
    return clone(points[index]), index
end

local function chooseItem()
    local items = configuredItems()
    if #items == 0 then return nil end
    local entry = clone(items[math.random(1, #items)])
    entry.amount = math.random(entry.min, entry.max)
    return entry
end

local function canCarry(userId, item, amount)
    local weight = tonumber(vRP.getItemWeight(item)) or 0
    local current = tonumber(vRP.computeInvWeight(userId)) or 0
    local maximum = tonumber(vRP.getInventoryMaxWeight(userId)) or 0
    return current + (weight * amount) <= maximum
end

local function cleanupItems(userId, notifySource)
    userId = tonumber(userId)
    if not userId then return 0 end

    local removed = 0
    for item in pairs(serviceItemSet(userId)) do
        local amount = tonumber(vRP.getInventoryItemAmount(userId, item)) or 0
        if amount > 0 and vRP.tryGetInventoryItem(userId, item, amount, false) then
            removed = removed + amount
        end
    end

    if notifySource and GetPlayerName(notifySource) then
        if removed > 0 then
            TriggerClientEvent(
                "Notify",
                notifySource,
                "aviso",
                "Você saiu de serviço! Todos lanches que carregava foram devolvidos para empresa.",
                8
            )
        else
            TriggerClientEvent("Notify", notifySource, "aviso", "Você saiu de serviço de Entregador.", 6)
        end
    end

    return removed
end

-- Chamado pelo controle geral de expediente em server.lua.
function MageEntregadorOnServiceEnd(userId, playerSource, notifyPlayer)
    userId = tonumber(userId)
    if not userId then return 0 end

    local removed = cleanupItems(userId, notifyPlayer and playerSource or nil)
    deliverySessions[userId] = nil
    return removed
end

local function ensureValidPlayer(source)
    local userId = vRP.getUserId(source)
    if not userId then return nil, "Jogador inválido." end
    if not MageEmpregosHasJob(userId, "Entregador") then
        return nil, "Você não está empregado como Entregador."
    end
    if not isServiceActive(userId) then
        return nil, "Inicie o expediente de Entregador primeiro."
    end
    return userId
end

local function stepPayload(session, message)
    if not session then return { ok = false } end
    return {
        ok = true,
        stage = session.stage,
        target = clone(session.target),
        batch = session.batch and clone(session.batch) or nil,
        message = message
    }
end

local function grantDeliveryPayment(source, userId)
    local query = mg.query('get_empdata', { user_id = userId })
    if not query[1] or not query[1].dvalue then return false end

    local jobs = json.decode(query[1].dvalue) or {}
    local progress = jobs["Entregador"] or {}
    local level = tonumber(progress.nivel) or 1
    local ranges = cfg.list["Entregador"] and cfg.list["Entregador"].payment_for_level or {}
    local range = ranges and ranges[level] or nil
    if not range or not range[1] or not range[2] then return false end

    local minPayment = tonumber(range[1]) or 0
    local maxPayment = tonumber(range[2]) or 0
    if maxPayment < minPayment then minPayment, maxPayment = maxPayment, minPayment end
    local payment = math.random(minPayment, maxPayment)

    mg.payment(userId, payment)
    TriggerClientEvent('Notify', source, 'sucesso', '[Entregador] Você recebeu seu pagamento de R$ '..payment..'', 8)

    if type(MageEmpregosLog) == "function" then
        MageEmpregosLog("job_entregador_payment", {
            actorId = userId,
            details = ("Emprego: Entregador\nNível: %d\nPagamento recebido: %s\nOrigem: entrega validada pelo servidor"):format(
                level,
                type(MageEmpregosMoney) == "function" and MageEmpregosMoney(payment) or tostring(payment)
            )
        })
    end

    return true
end

local function startBatch(userId)
    local batch = chooseItem()
    if not batch then return nil, "Nenhum item de entrega foi configurado." end
    if not canCarry(userId, batch.item, batch.amount) then
        return nil, "Sem espaço suficiente no inventário para carregar os lanches."
    end

    vRP.giveInventoryItem(userId, batch.item, batch.amount, true)
    return batch
end

function src.startDeliveryCycle()
    local source = source
    local userId, err = ensureValidPlayer(source)
    if not userId then return { ok = false, message = err } end

    local existing = deliverySessions[userId]
    if existing then
        return stepPayload(existing)
    end

    local deliveries = configuredPoints("locais_entrega")
    local pickups = configuredPoints("locais_retirada")
    if #deliveries == 0 then
        return { ok = false, message = "Nenhum ponto de entrega foi configurado no painel." }
    end
    if #pickups == 0 then
        return { ok = false, message = "Nenhum ponto de coleta foi configurado no painel." }
    end

    -- Remove resíduos de uma sessão anterior/restart antes de iniciar um novo ciclo.
    cleanupItems(userId, nil)

    local batch, batchErr = startBatch(userId)
    if not batch then
        return { ok = false, message = batchErr }
    end

    local target, targetIndex = choosePoint(deliveries)
    deliverySessions[userId] = {
        source = source,
        stage = "delivery",
        batch = batch,
        target = target,
        targetIndex = targetIndex,
        lastDeliveryIndex = targetIndex,
        lastPickupIndex = nil,
        lastActionAt = 0
    }

    if type(MageEmpregosLog) == "function" then
        MageEmpregosLog("job_entregador_route_started", {
            actorId = userId,
            details = ("Item: %s\nQuantidade: %d\nDestino: %.2f, %.2f, %.2f"):format(
                batch.item, batch.amount, target.x, target.y, target.z
            )
        })
    end

    return stepPayload(
        deliverySessions[userId],
        ("Você recebeu x%d %s. Faça a entrega no local marcado."):format(batch.amount, batch.item)
    )
end

function src.completeDeliveryStep()
    local source = source
    local userId, err = ensureValidPlayer(source)
    if not userId then return { ok = false, message = err } end

    local session = deliverySessions[userId]
    if not session or session.stage ~= "delivery" or not session.batch or not session.target then
        return { ok = false, message = "Nenhuma entrega válida está em andamento." }
    end

    local now = GetGameTimer()
    if now - (tonumber(session.lastActionAt) or 0) < ACTION_COOLDOWN_MS then
        return { ok = false, message = "Aguarde um instante." }
    end
    session.lastActionAt = now

    if playerDistanceTo(source, session.target) > INTERACT_DISTANCE then
        MageEmpregosLogInvalid(source, "finalizar entrega", "Tentativa de concluir entrega longe do destino definido pelo servidor.")
        return { ok = false, message = "Você não está no local correto da entrega." }
    end

    local item = tostring(session.batch.item or "")
    local amount = math.max(1, math.floor(tonumber(session.batch.amount) or 1))
    local owned = tonumber(vRP.getInventoryItemAmount(userId, item)) or 0
    if owned < amount then
        return { ok = false, message = "Os lanches desta entrega não estão mais no seu inventário." }
    end

    if not vRP.tryGetInventoryItem(userId, item, amount, true) then
        return { ok = false, message = "Não foi possível retirar os lanches da entrega." }
    end

    -- Muda de estágio ANTES de premiar para tornar a entrega idempotente.
    session.stage = "transition"
    session.batch = nil
    session.target = nil

    if type(MageEmpregosGrantXp) == "function" then
        MageEmpregosGrantXp(source, "Entregador")
    end
    grantDeliveryPayment(source, userId)

    local pickups = configuredPoints("locais_retirada")
    if #pickups == 0 then
        session.stage = "paused"
        return {
            ok = false,
            delivered = true,
            message = "Entrega concluída, mas não há pontos de coleta cadastrados no painel. Encerre o expediente e configure-os."
        }
    end

    local nextTarget, nextIndex = choosePoint(pickups, session.lastPickupIndex)
    session.stage = "pickup"
    session.target = nextTarget
    session.targetIndex = nextIndex
    session.lastPickupIndex = nextIndex

    if type(MageEmpregosLog) == "function" then
        MageEmpregosLog("job_entregador_delivery_completed", {
            actorId = userId,
            details = ("Item entregue: %s\nQuantidade: %d\nPróxima coleta: %.2f, %.2f, %.2f"):format(
                item, amount, nextTarget.x, nextTarget.y, nextTarget.z
            )
        })
    end

    return stepPayload(session, "Entrega concluída! Vá até o próximo ponto para retirar novos lanches.")
end

function src.collectDeliveryStep()
    local source = source
    local userId, err = ensureValidPlayer(source)
    if not userId then return { ok = false, message = err } end

    local session = deliverySessions[userId]
    if not session or session.stage ~= "pickup" or not session.target then
        return { ok = false, message = "Nenhuma coleta válida está em andamento." }
    end

    local now = GetGameTimer()
    if now - (tonumber(session.lastActionAt) or 0) < ACTION_COOLDOWN_MS then
        return { ok = false, message = "Aguarde um instante." }
    end
    session.lastActionAt = now

    if playerDistanceTo(source, session.target) > INTERACT_DISTANCE then
        MageEmpregosLogInvalid(source, "retirar lanches", "Tentativa de coletar lanches longe do ponto definido pelo servidor.")
        return { ok = false, message = "Você não está no local correto da coleta." }
    end

    local deliveries = configuredPoints("locais_entrega")
    if #deliveries == 0 then
        return { ok = false, message = "Nenhum ponto de entrega foi configurado no painel." }
    end

    local batch, batchErr = startBatch(userId)
    if not batch then
        return { ok = false, message = batchErr }
    end

    local nextTarget, nextIndex = choosePoint(deliveries, session.lastDeliveryIndex)
    session.stage = "delivery"
    session.batch = batch
    session.target = nextTarget
    session.targetIndex = nextIndex
    session.lastDeliveryIndex = nextIndex

    if type(MageEmpregosLog) == "function" then
        MageEmpregosLog("job_entregador_order_collected", {
            actorId = userId,
            details = ("Item: %s\nQuantidade: %d\nNovo destino: %.2f, %.2f, %.2f"):format(
                batch.item, batch.amount, nextTarget.x, nextTarget.y, nextTarget.z
            )
        })
    end

    return stepPayload(
        session,
        ("Você retirou x%d %s. Faça a entrega no local marcado."):format(batch.amount, batch.item)
    )
end

-- Compatibilidade: eventos antigos deixam de conceder prêmio diretamente.
RegisterServerEvent('vrp_ifood:receber')
AddEventHandler('vrp_ifood:receber', function(clientPayment)
    MageEmpregosLogInvalid(source, "pagamento legado do Entregador", ("Evento antigo bloqueado. Valor enviado: %s"):format(tostring(clientPayment or "-")))
end)

RegisterServerEvent('vrp_ifood:permissao')
AddEventHandler('vrp_ifood:permissao', function()
    local source = source
    local userId = vRP.getUserId(source)
    if userId and MageEmpregosHasJob(userId, "Entregador") then
        TriggerClientEvent('vrp_ifood:permissao', source)
    end
end)

-- Fallback adicional para desconexões e reinícios do resource.
AddEventHandler("playerDropped", function()
    local src = source
    for userId, session in pairs(deliverySessions) do
        if session and session.source == src then
            cleanupItems(userId, nil)
            deliverySessions[userId] = nil
            break
        end
    end
end)

CreateThread(function()
    Wait(2500)
    -- Após restart do resource não existe sessão válida; remove qualquer item de serviço residual.
    for _, player in ipairs(GetPlayers()) do
        local src = tonumber(player)
        local userId = src and vRP.getUserId(src) or nil
        if userId and not deliverySessions[userId] then
            cleanupItems(userId, nil)
        end
    end
end)
