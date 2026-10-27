local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
local vRP = Proxy.getInterface("vRP")
local vRPclient = Tunnel.getInterface("vRP")

local API = {}
Tunnel.bindInterface(GetCurrentResourceName(), API)
local vCLIENT = Tunnel.getInterface(GetCurrentResourceName())

vRP.prepare("aux:get_vehicle", "SELECT * FROM vrp_user_veiculos WHERE user_id = @user_id AND veiculo = @veiculo")
vRP.prepare("aux:set_detained", "UPDATE vrp_user_veiculos SET status = @status WHERE user_id = @user_id AND veiculo = @veiculo")
vRP.prepare("aux:get_vehicle_by_plate", "SELECT * FROM vrp_user_veiculos WHERE REPLACE(placa, ' ', '') = @placa LIMIT 1")

local placedObjects = {}
local objectSequence = 0
local officerObjectCount = {}
local actionCooldown = {}
local announcementCooldown = {}

local function response(ok, message, extra)
    local data = extra or {}
    data.ok = ok == true
    data.message = message
    return data
end

local function notify(source, kind, message, time)
    TriggerClientEvent("Notify", source, kind, message, time or 5000)
end

local function userId(source)
    return source and vRP.getUserId(source) or nil
end

local function hasRole(source, role)
    local uid = userId(source)
    local permission = cfg.permissions[role]
    return uid and permission and vRP.hasPermission(uid, permission), uid
end

local function allowedAction(source, role)
    local ok, uid = hasRole(source, role)
    if not ok then
        notify(source, "negado", "Você não possui permissão para esta função.")
        return nil
    end

    local now = os.time()
    if actionCooldown[source] and actionCooldown[source] > now then
        return nil
    end
    actionCooldown[source] = now + 1
    return uid
end

local function nearestPlayer(source, radius)
    local target = vRPclient.getNearestPlayer(source, radius or 4)
    if not target or target == source then return nil, nil end
    local uid = vRP.getUserId(target)
    if not uid then return nil, nil end
    return target, uid
end

local function getCoords(source)
    if not source then return nil end
    local x, y, z = vRPclient.getPosition(source)
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not x or not y or not z then return nil end
    return { x = x, y = y, z = z }
end

local function distance(a, b)
    if not a or not b then return math.huge end
    local x = (a.x or 0.0) - (b.x or 0.0)
    local y = (a.y or 0.0) - (b.y or 0.0)
    local z = (a.z or 0.0) - (b.z or 0.0)
    return math.sqrt(x*x + y*y + z*z)
end

local function cleanPlate(plate)
    if type(plate) ~= "string" then return nil end
    plate = plate:gsub("%s+", "")
    if plate == "" then return nil end
    return plate
end

local function identityPayload(uid)
    local identity = vRP.getUserIdentity(uid)
    if not identity then return nil end
    local rawFines = vRP.getUData(uid, "vRP:multas")
    local fines = 0
    if rawFines and rawFines ~= "" then
        local ok, decoded = pcall(json.decode, rawFines)
        if ok then fines = tonumber(decoded) or 0 end
    end

    return {
        id = tonumber(uid) or uid,
        nome = identity.nome or "Não informado",
        sobrenome = identity.sobrenome or "",
        registro = identity.registro or "Não informado",
        idade = identity.idade or "Não informado",
        telefone = identity.telefone or "Não informado",
        multas = math.floor(fines),
        carteira = tonumber(vRP.getMoney(uid)) or 0,
        banco = tonumber(vRP.getBankMoney(uid)) or 0
    }
end

function API.checkPerm()
    local source = source
    local uid = userId(source)
    if not uid then return false end

    -- Police first because this panel is commonly used operationally by officers
    -- who may also inherit another service permission.
    if vRP.hasPermission(uid, cfg.permissions.police) then return "police" end
    if vRP.hasPermission(uid, cfg.permissions.medic) then return "medic" end
    if vRP.hasPermission(uid, cfg.permissions.mecanic) then return "mecanic" end
    return false
end

local function trimText(value)
    local text = tostring(value or "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text
end

local function privilegedAnnouncementUser(uid)
    return vRP.hasGroup(uid, "developerrealidade") or vRP.hasGroup(uid, "dono")
end

local function sendDepartmentAnnouncement(source, uid, role)
    local data = cfg.announcements and cfg.announcements[role]
    if type(data) ~= "table" then
        return response(false, "Aviso deste setor não está configurado.")
    end

    local requiredPermission = trimText(data.permission)
    if requiredPermission ~= "" and not vRP.hasPermission(uid, requiredPermission) and not privilegedAnnouncementUser(uid) then
        return response(false, "Seu cargo não possui permissão para enviar este aviso.")
    end

    local now = os.time()
    local key = tostring(role) .. ":" .. tostring(uid)
    local availableAt = tonumber(announcementCooldown[key]) or 0
    if availableAt > now then
        return response(false, ("Aguarde %s segundos para anunciar novamente."):format(availableAt - now))
    end

    local message = trimText(vRP.prompt(source, data.prompt or "Mensagem do aviso:", ""))
    if message == "" then return response(false, "Aviso cancelado.") end

    local maxLength = math.max(1, math.min(1000, tonumber(data.maxLength) or 300))
    if #message > maxLength then
        return response(false, ("O aviso pode ter no máximo %s caracteres."):format(maxLength))
    end

    local cooldown = math.max(0, tonumber(data.cooldown) or 120)
    announcementCooldown[key] = now + cooldown

    TriggerClientEvent("m_aux:departmentAnnouncement", -1, {
        title = tostring(data.title or "AVISO"),
        message = message,
        accent = tostring(data.accent or "#4ea8ff"),
        duration = math.max(3, math.min(300, tonumber(data.duration) or 15))
    })

    return response(true, "Aviso enviado para toda a cidade.")
end

-- ==========================================================================
-- MEDIC
-- ==========================================================================
local function beginTreatment(source, medicId, target, targetId, kind, value)
    local amount = math.floor(tonumber(value) or 0)
    if amount < 0 or amount > cfg.maxBillingValue then
        return response(false, "Valor de tratamento inválido.", { close = false })
    end

    local accepted = true
    local paid = false

    if amount > 0 then
        accepted = vRP.request(target, ("Deseja aceitar o tratamento por R$ %s?"):format(vRP.format(amount)), 15)
        if not accepted then return response(false, "O paciente recusou o tratamento.") end

        if vRP.tryFullPayment(targetId, amount) then
            paid = true
            vRP.giveMoney(medicId, amount)
        else
            local free = vRP.request(source, "O paciente não possui saldo suficiente. Deseja aplicar o tratamento gratuitamente?", 15)
            if not free then return response(false, "Tratamento cancelado: pagamento não realizado.") end
        end
    end

    vRPclient._playAnim(source, true, {{ "amb@prop_human_parking_meter@female@idle_a", "idle_a_female" }}, true)
    TriggerClientEvent("progress", source, 5, "Diagnosticando")
    TriggerClientEvent("progress", target, 5, "Atendimento")
    notify(source, "aviso", "Diagnosticando paciente...", 5000)
    notify(target, "aviso", "Você está sendo atendido.", 5000)

    SetTimeout(5000, function()
        local currentSource = vRP.getUserSource(medicId)
        local currentTarget = vRP.getUserSource(targetId)
        if not currentSource or not currentTarget then return end

        -- Once the patient accepted (and paid, when applicable), the treatment
        -- is completed even if one of the players takes a small step away. This
        -- avoids unsafe refund races where the medic could spend the payment
        -- before an attempted rollback.
        vCLIENT.treatment(currentTarget, kind)
        vRPclient._stopAnim(currentSource, false)
        notify(currentSource, "sucesso", paid and ("Tratamento iniciado. Você recebeu R$ " .. vRP.format(amount) .. ".") or "Tratamento gratuito iniciado.")
        notify(currentTarget, "sucesso", "Tratamento iniciado.")
    end)

    return response(true, "Atendimento iniciado.")
end

function API.medic(action, value)
    local source = source
    local uid = allowedAction(source, "medic")
    if not uid then return response(false, "Aguarde um instante e tente novamente.") end

    local target, targetId = nearestPlayer(source, 3.5)

    if action == "quick_treatment" or action == "complete_treatment" then
        if not target then return response(false, "Não há nenhum cidadão próximo.") end
        return beginTreatment(source, uid, target, targetId, action == "quick_treatment" and "quick" or "complete", value)
    elseif action == "revive" then
        if not target then return response(false, "Não há nenhum cidadão próximo.") end
        local health = tonumber(vRPclient.getHealth(target)) or 400
        if health > 105 then return response(false, "A pessoa precisa estar em coma para ser reanimada.") end

        vRPclient._playAnim(source, false, {{ "amb@medic@standing@tendtodead@base", "base" }, { "mini@cpr@char_a@cpr_str", "cpr_pumpchest" }}, true)
        TriggerClientEvent("progress", source, 10, "Reanimando")
        notify(source, "aviso", "Reanimação iniciada.", 5000)

        SetTimeout(10000, function()
            local src = vRP.getUserSource(uid)
            local trg = vRP.getUserSource(targetId)
            if not src or not trg then return end
            if distance(getCoords(src), getCoords(trg)) > 5.0 then
                vRPclient._stopAnim(src, false)
                return notify(src, "negado", "Reanimação cancelada: cidadão se afastou.")
            end
            if (tonumber(vRPclient.getHealth(trg)) or 400) > 105 then
                vRPclient._stopAnim(src, false)
                return notify(src, "aviso", "O cidadão já não está em coma.")
            end
            vRPclient._setHealth(trg, 300)
            vRPclient._stopAnim(src, false)
            TriggerClientEvent("resetBleeding", trg)
            vRP.giveMoney(uid, cfg.reviveReward)
            notify(src, "sucesso", "Cidadão reanimado com sucesso.")
            notify(trg, "sucesso", "Você foi reanimado.")
        end)
        return response(true, "Reanimação iniciada.")
    elseif action == "m_cv" then
        if not target then return response(false, "Não há nenhum cidadão próximo.") end
        if not vRPclient.getNearestVehicle(source, 6) then return response(false, "Não há nenhum veículo próximo.") end
        vRPclient.putInNearestVehicleAsPassenger(target, 7)
        return response(true, "Cidadão colocado no veículo.")
    elseif action == "m_rv" then
        if not target then return response(false, "Não há nenhum cidadão próximo.") end
        vRPclient.ejectVehicle(target)
        return response(true, "Cidadão retirado do veículo.")
    elseif action == "m_aviso" then
        return sendDepartmentAnnouncement(source, uid, "medic")
    end

    return response(false, "Função médica inválida.")
end

-- ==========================================================================
-- POLICE OBJECTS
-- ==========================================================================
function API.canPlaceObject(kind)
    local source = source
    local ok = hasRole(source, "police")
    return ok and cfg.policeObjects[kind] ~= nil or false
end

function API.getObjects()
    return placedObjects
end

function API.placeObject(kind, coords, heading)
    local source = source
    local ok, uid = hasRole(source, "police")
    if not ok or not cfg.policeObjects[kind] or type(coords) ~= "table" then return false end

    local playerCoords = getCoords(source)
    local proposed = { x = tonumber(coords.x), y = tonumber(coords.y), z = tonumber(coords.z) }
    if not proposed.x or not proposed.y or not proposed.z then return false end
    if math.abs(proposed.x) > 10000 or math.abs(proposed.y) > 10000 or math.abs(proposed.z) > 2000 then return false end
    if distance(playerCoords, proposed) > 9.0 then return false end

    local count = 0
    for _ in pairs(placedObjects) do count = count + 1 end
    if count >= cfg.maxPlacedObjects then
        notify(source, "negado", "Limite global de objetos operacionais atingido.")
        return false
    end

    officerObjectCount[uid] = officerObjectCount[uid] or 0
    if officerObjectCount[uid] >= cfg.maxObjectsPerOfficer then
        notify(source, "negado", "Você atingiu o limite de objetos posicionados.")
        return false
    end

    objectSequence = objectSequence + 1
    local id = tostring(objectSequence)
    local def = cfg.policeObjects[kind]
    local data = {
        kind = kind,
        model = def.model,
        label = def.label,
        coords = proposed,
        heading = tonumber(heading) or 0.0,
        owner = uid,
        createdAt = os.time()
    }
    placedObjects[id] = data
    officerObjectCount[uid] = officerObjectCount[uid] + 1
    TriggerClientEvent("m_aux:object:add", -1, id, data)
    notify(source, "sucesso", (def.label or "Objeto") .. " posicionado com sucesso.")
    return true
end

local function removePlacedObject(id)
    id = tostring(id)
    local data = placedObjects[id]
    if not data then return false end
    placedObjects[id] = nil
    if data.owner and officerObjectCount[data.owner] then
        officerObjectCount[data.owner] = math.max(0, officerObjectCount[data.owner] - 1)
    end
    TriggerClientEvent("m_aux:object:remove", -1, id)
    return true
end

local function removeNearestPlacedObject(source, radius)
    local c = getCoords(source)
    local bestId, bestDist
    for id, data in pairs(placedObjects) do
        local d = distance(c, data.coords)
        if d <= radius and (not bestDist or d < bestDist) then bestId, bestDist = id, d end
    end
    return bestId and removePlacedObject(bestId) or false
end

local function clearPlacedArea(source, radius)
    local c = getCoords(source)
    local ids = {}
    for id, data in pairs(placedObjects) do
        if distance(c, data.coords) <= radius then ids[#ids + 1] = id end
    end
    for _, id in ipairs(ids) do removePlacedObject(id) end
    return #ids
end

-- ==========================================================================
-- POLICE
-- ==========================================================================
function API.police(action, _value)
    local source = source
    local uid = allowedAction(source, "police")
    if not uid then
        return response(false, "Aguarde um instante e tente novamente.", { close = (action == "p_rg" or action == "plate") and false or true })
    end

    if action == "p_aviso" then
        return sendDepartmentAnnouncement(source, uid, "police")
    elseif action == "p_removeobject" then
        local ok = removeNearestPlacedObject(source, 4.0)
        return response(ok, ok and "Objeto removido." or "Não há objeto operacional próximo.")
    elseif action == "p_cleararea" then
        local amount = clearPlacedArea(source, cfg.objectClearRadius)
        return response(true, amount > 0 and (amount .. " objeto(s) removido(s) da área.") or "Nenhum objeto operacional encontrado na área.")
    end

    local target, targetId = nearestPlayer(source, 5.0)

    if action == "apdr_itens" then
        if not target then return response(false, "Não há nenhum cidadão próximo.") end
        local removed = 0
        local removedWeapon = false
        for _, item in ipairs(cfg.illegalItems) do
            while true do
                local amount = tonumber(vRP.getInventoryItemAmount(targetId, item)) or 0
                if amount <= 0 then break end
                if not vRP.tryGetInventoryItem(targetId, item, amount, true) then break end
                removed = removed + amount
                if item:sub(1, 7) == "weapon_" then removedWeapon = true end
            end
        end
        if removedWeapon then vCLIENT.forceUnarmed(target) end
        if removed > 0 then
            notify(target, "negado", "Seus itens ilegais foram apreendidos.")
            notify(source, "sucesso", ("Apreensão concluída: %s item(ns) removido(s)."):format(removed))
            return response(true, "Itens ilegais apreendidos.")
        end
        return response(false, "Nenhum item ilegal configurado foi encontrado com o cidadão.")
    elseif action == "p_rg" then
        if not target then return response(false, "Não há nenhum cidadão próximo.", { close = false }) end
        local details = identityPayload(targetId)
        if not details then return response(false, "Não foi possível consultar a identidade.", { close = false }) end
        notify(target, "aviso", "Seu documento está sendo consultado por um policial.")
        return response(true, "Documento consultado.", { close = false, details = details, detailsType = "person" })
    elseif action == "p_cv" then
        if not target then return response(false, "Não há nenhum cidadão próximo.") end
        if not vRPclient.getNearestVehicle(source, 6) then return response(false, "Não há nenhum veículo próximo.") end
        vRPclient.putInNearestVehicleAsPassenger(target, 7)
        return response(true, "Cidadão colocado na viatura.")
    elseif action == "p_rv" then
        if not target then return response(false, "Não há nenhum cidadão próximo.") end
        vRPclient.ejectVehicle(target)
        return response(true, "Cidadão retirado da viatura.")
    elseif action == "p_rmsc" then
        if not target then return response(false, "Não há nenhum cidadão próximo.") end
        vCLIENT.removeMask(target)
        notify(source, "sucesso", "Máscara removida.")
        notify(target, "aviso", "Sua máscara foi removida por um policial.")
        return response(true, "Máscara removida.")
    elseif action == "detido" then
        local vehicleInfo = vCLIENT.nearestVehicleInfo(source, 6)
        if type(vehicleInfo) ~= "table" then return response(false, "Não há veículo próximo.") end
        local plate = cleanPlate(vehicleInfo.plate)
        local vehicle = tonumber(vehicleInfo.vehicle)
        if not plate or not vehicle then return response(false, "Não foi possível identificar o veículo próximo.") end

        local rows = vRP.query("aux:get_vehicle_by_plate", { placa = plate })
        local row = rows and rows[1] or nil
        local ownerId = row and tonumber(row.user_id) or tonumber(vRP.getUserByRegistration(plate))
        local model = row and row.veiculo or nil

        -- Compatibility fallback for bases where the vehicle plate mirrors the
        -- owner's registration and the `placa` column is still empty.
        if ownerId and not model then
            local _, legacyModel = vRPclient.ModelName(source, 6)
            model = legacyModel
            if model then
                local legacyRows = vRP.query("aux:get_vehicle", { user_id = ownerId, veiculo = model })
                row = legacyRows and legacyRows[1] or nil
            end
        end

        if not ownerId or not model or not row then
            return response(false, "Este veículo não foi encontrado na garagem de um proprietário.")
        end
        if tonumber(row.status) == 1 then return response(false, "Este veículo já está detido.") end

        local reason = vRP.prompt(source, "Motivo da apreensão:", "")
        if not reason or reason == "" then return response(false, "Apreensão cancelada.") end
        if #reason > 160 then reason = reason:sub(1, 160) end

        vRP.execute("aux:set_detained", { user_id = ownerId, veiculo = model, status = 1 })
        local bonus = math.random(90, 150)
        vRP.giveMoney(uid, bonus)
        vCLIENT.deleteVehicle(source, vehicle)

        local ownerSource = vRP.getUserSource(ownerId)
        if ownerSource then notify(ownerSource, "aviso", "Seu veículo foi detido. Motivo: " .. reason, 8000) end
        notify(source, "sucesso", ("Veículo detido. Bonificação: R$ %s."):format(vRP.format(bonus)))
        return response(true, "Veículo detido com sucesso.")
    elseif action == "plate" then
        local vehicleInfo = vCLIENT.nearestVehicleInfo(source, 7)
        if type(vehicleInfo) ~= "table" then return response(false, "Não há veículo próximo.", { close = false }) end
        local plate = cleanPlate(vehicleInfo.plate)
        if not plate then return response(false, "Não foi possível ler a placa do veículo.", { close = false }) end

        local rows = vRP.query("aux:get_vehicle_by_plate", { placa = plate })
        local row = rows and rows[1] or nil
        local ownerId = row and tonumber(row.user_id) or tonumber(vRP.getUserByRegistration(plate))
        if not ownerId then return response(false, "Placa inválida ou veículo sem proprietário identificado.", { close = false }) end
        local details = identityPayload(ownerId)
        if not details then return response(false, "Não foi possível consultar o proprietário.", { close = false }) end
        details.placa = plate
        details.veiculo = row and row.veiculo or vehicleInfo.displayName
        return response(true, "Placa consultada.", { close = false, details = details, detailsType = "vehicle" })
    end

    return response(false, "Função policial inválida.")
end

-- ==========================================================================
-- MECHANIC
-- ==========================================================================
local function startRepair(source, uid, mode, vehicle, consumeItem)
    if consumeItem and not vRP.tryGetInventoryItem(uid, consumeItem, 1, true) then
        return response(false, consumeItem == "pneus" and "Você precisa de 1 Pneu." or "Item necessário não encontrado.")
    end

    vRPclient._playAnim(source, false, {{ "mini@repair", "fixing_a_player" }}, true)
    TriggerClientEvent("progress", source, 10, "Reparando")
    notify(source, "aviso", "Reparo iniciado.")

    SetTimeout(10000, function()
        local currentSource = vRP.getUserSource(uid)
        if not currentSource then return end
        local repaired = vCLIENT.repairVehicle(currentSource, vehicle, mode)
        vRPclient._stopAnim(currentSource, false)
        if repaired then
            notify(currentSource, "sucesso", "Reparo concluído.")
        else
            if consumeItem then vRP.giveInventoryItem(uid, consumeItem, 1, true) end
            notify(currentSource, "negado", "Reparo cancelado: o veículo não está mais próximo.")
        end
    end)
    return response(true, "Reparo iniciado.")
end

function API.mecanic(action, value)
    local source = source
    local uid = allowedAction(source, "mecanic")
    if not uid then return response(false, "Aguarde um instante e tente novamente.") end

    if action == "r_motor" or action == "r_pneu" or action == "r_full" then
        if vRPclient.isInVehicle(source) then return response(false, "Saia do veículo para realizar o reparo.") end
        local vehicle = vRPclient.getNearestVehicle(source, action == "r_pneu" and 7 or 5)
        if not vehicle then return response(false, "Não há nenhum veículo próximo.") end
        if action == "r_motor" then return startRepair(source, uid, "engine", vehicle, nil) end
        if action == "r_pneu" then return startRepair(source, uid, "tires", vehicle, "pneus") end
        if vCLIENT.isFullRepairBlocked(source, vehicle) then
            return response(false, "Este veículo não pode receber reparo completo por este sistema.")
        end
        -- O inventário atual dá reparo completo gratuito para quem possui perm.mecanica.
        return startRepair(source, uid, "full", vehicle, nil)
    elseif action == "r_cobrar" then
        local target, targetId = nearestPlayer(source, 5.0)
        if not target then return response(false, "Não há nenhum cidadão próximo.") end
        local amount = math.floor(tonumber(value) or 0)
        if amount < 1 or amount > cfg.maxBillingValue then return response(false, "Valor de cobrança inválido.") end
        local accepted = vRP.request(target, ("Deseja pagar a cobrança de R$ %s?"):format(vRP.format(amount)), 20)
        if not accepted then return response(false, "Cobrança recusada.") end
        if not vRP.tryFullPayment(targetId, amount) then
            notify(target, "negado", "Você não possui saldo suficiente.")
            return response(false, "O cidadão não possui saldo suficiente.")
        end
        vRP.giveMoney(uid, amount)
        notify(target, "sucesso", ("Pagamento de R$ %s realizado."):format(vRP.format(amount)))
        notify(source, "sucesso", ("Você recebeu R$ %s."):format(vRP.format(amount)))
        return response(true, "Cobrança paga.")
    elseif action == "r_avisomec" then
        return sendDepartmentAnnouncement(source, uid, "mecanic")
    end

    return response(false, "Função da mecânica inválida.")
end

AddEventHandler("playerDropped", function()
    local droppedSource = source
    local uid = vRP.getUserId(droppedSource)
    actionCooldown[droppedSource] = nil
    if uid then
        announcementCooldown["medic:" .. uid] = nil
        announcementCooldown["mecanic:" .. uid] = nil
        announcementCooldown["police:" .. uid] = nil
    end
end)
