local active = {}
local function modelHash(value)
    local hash = tonumber(value)
    if not hash or hash ~= hash or hash % 1 ~= 0 or hash < -2147483648 or hash > 4294967295.0 then
        return nil
    end
    -- Native hashes can arrive as signed int32 or unsigned uint32.
    return hash % 4294967296.0
end
local models = {}
for _, model in ipairs(WaterCoolerConfig.models) do models[modelHash(GetHashKey(model))] = true end

local function failure(message) return { error = message } end

local function position(value)
    if type(value) ~= "table" then return nil end
    local x, y, z = tonumber(value.x), tonumber(value.y), tonumber(value.z)
    if not x or not y or not z or x ~= x or y ~= y or z ~= z
        or math.abs(x) > 20000 or math.abs(y) > 20000 or math.abs(z) > 20000 then return nil end
    return vector3(x, y, z)
end

local function nearby(player, userId, waterSource)
    if vRP.getUserId(player) ~= userId then return false, "player" end
    local ped = GetPlayerPed(player)
    local coords = position(waterSource.coords)
    if ped == 0 then return false, "ped_missing" end
    if not coords then return false, "source_position" end
    local health = GetEntityHealth(ped)
    if health <= 101 then return false, "health=" .. tostring(health) end
    local distance = #(GetEntityCoords(ped) - coords)
    if distance > WaterCoolerConfig.distance then return false, "distance=" .. tostring(distance) end
    if waterSource.style == "fountain" then
        local model = modelHash(waterSource.model)
        if not model or not models[model] then return false, "model=" .. tostring(waterSource.model) end
        local networkId = tonumber(waterSource.networkId) or 0
        if networkId > 0 then
            local object = NetworkGetEntityFromNetworkId(networkId)
            local networkModel = object ~= 0 and modelHash(GetEntityModel(object)) or nil
            -- A map prop can have a network reference before its model is
            -- available on the server. Use the same validation as local props
            -- until OneSync supplies a nonzero model (and valid object data).
            if networkModel and networkModel ~= 0 then
                if networkModel ~= model then return false, "network_model=" .. tostring(networkModel) end
                if #(GetEntityCoords(object) - coords) > 0.5 then return false, "network_position" end
            end
        end
    elseif waterSource.style ~= "floor" then
        return false, "source_type"
    end
    return true
end

local function bottleError(userId, slot)
    if slot then
        local item = vRP.getSlotItem(userId, slot)
        if not item or item.item ~= "emptybottle" or (tonumber(item.amount) or 0) < 1 then
            return "Você precisa de uma garrafa vazia."
        end
    elseif vRP.getInventoryItemAmount(userId, "emptybottle") < 1 then
        return "Você precisa de uma garrafa vazia."
    end
    local weight = vRP.computeInvWeight(userId) + vRP.getItemWeight("water") - vRP.getItemWeight("emptybottle")
    if weight > vRP.getInventoryMaxWeight(userId) then return "Espaço insuficiente na mochila para a garrafa cheia." end
end

local function perform(player, userId, action, slot, coolerOnly)
    local waterSource = Remote.getWaterSource(player, coolerOnly)
    if type(waterSource) ~= "table" then
        print("[inventory:watercooler] Rejeitado: cliente nao confirmou a fonte; jogador=" .. tostring(userId))
        return failure("Aproxime-se de um bebedouro para usar.")
    end
    local valid, reason = nearby(player, userId, waterSource)
    if not valid or (coolerOnly and waterSource.style ~= "fountain") then
        print(("[inventory:watercooler] Rejeitado: %s; jogador=%s; modelo=%s; rede=%s"):format(
            tostring(reason or "cooler_required"), tostring(userId), tostring(waterSource.model), tostring(waterSource.networkId)))
        -- Include the failed check so a screenshot is enough to diagnose a live
        -- OneSync rejection when the server console is not available.
        return failure("Não foi possível confirmar o bebedouro. Código: " .. tostring(reason or "cooler_required") .. ".")
    end
    if action == "fill" then
        local message = bottleError(userId, slot)
        if message then return failure(message) end
    elseif not exports.vrp:areNeedsEnabled() then
        return failure("O sistema de fome e sede está desligado.")
    end

    local seconds = action == "fill" and WaterCoolerConfig.fillSeconds or WaterCoolerConfig.drinkSeconds
    Remote._closeInventory(player)
    exports.vrp:setCooldown(userId, "inventario", seconds)
    exports.vrp:setBlockCommand(userId, seconds)
    TriggerClientEvent("progress", player, seconds, action == "fill" and "Enchendo garrafinha" or "Bebendo água")
    local animation = waterSource.style == "floor"
        and { { "amb@world_human_bum_wash@male@high@base", "base" } }
        or { { "amb@prop_human_parking_meter@female@idle_a", "idle_a_female" } }
    if action == "drink" then
        active[userId].cup = true
        vRPc._CarregarObjeto(player, "amb@world_human_drinking@beer@male@idle_a", "idle_a",
            "prop_fib_coffee", 49, 28422)
    else
        vRPc._playAnim(player, false, animation, true)
    end

    for _ = 1, seconds * 2 do
        Wait(500)
        if not nearby(player, userId, waterSource) then
            return failure("Ação cancelada: permaneça perto do bebedouro.")
        end
    end
    local current = Remote.getWaterSource(player, coolerOnly)
    local currentPosition = type(current) == "table" and position(current.coords)
    if not currentPosition or current.style ~= waterSource.style
        or modelHash(current.model) ~= modelHash(waterSource.model) or #(currentPosition - position(waterSource.coords)) > 0.5
        or not nearby(player, userId, waterSource) then
        return failure("Ação cancelada: a fonte de água não está mais disponível.")
    end

    if action == "fill" then
        local message = bottleError(userId, slot)
        if message then return failure(message) end
        -- Exchange only after completion. Walking away or disconnecting consumes nothing.
        if not vRP.tryGetInventoryItem(userId, "emptybottle", 1, true, slot) then
            return failure("Você precisa de uma garrafa vazia.")
        end
        if not vRP.giveInventoryItem(userId, "water", 1, true) then
            vRP.giveInventoryItem(userId, "emptybottle", 1, true)
            return failure("Não foi possível encher a garrafa. Sua garrafa vazia foi devolvida.")
        end
        TriggerClientEvent("Notify", player, "sucesso", "Você encheu uma garrafinha de água.", 5)
    else
        if not exports.vrp:consumeNeeds(userId, 0, WaterCoolerConfig.thirstRestore) then
            return failure("Não foi possível beber água agora.")
        end
        TriggerClientEvent("Notify", player, "sucesso", "Você bebeu água no bebedouro.", 5)
    end
    return true
end

local function useWaterSource(player, userId, action, slot, coolerOnly)
    if not userId or (action ~= "fill" and action ~= "drink") then return failure("Ação inválida.") end
    if active[userId] then return failure("Aguarde terminar de usar o bebedouro.") end
    local allowed, remaining = exports.vrp:getCooldown(userId, "inventario")
    if not allowed then return failure("Aguarde " .. tostring(remaining) .. " segundos para usar novamente.") end
    local actionState = { cup = false }
    active[userId] = actionState
    local ok, result = xpcall(function() return perform(player, userId, action, slot, coolerOnly) end, debug.traceback)
    if vRP.getUserId(player) == userId then
        if actionState.cup then vRPc._DeletarObjeto(player) end
        vRPc._stopAnim(player, false)
    end
    active[userId] = nil
    if not ok then
        print("[inventory:watercooler] " .. tostring(result))
        return failure("Não foi possível usar o bebedouro agora.")
    end
    return result
end

function FillWaterBottle(player, userId, slot)
    return useWaterSource(player, userId, "fill", slot, false)
end

function API.useWaterCooler(action)
    local player = source
    return useWaterSource(player, vRP.getUserId(player), action, nil, true)
end
