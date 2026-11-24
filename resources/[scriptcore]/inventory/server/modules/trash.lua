-- Trash removes items from the authoritative inventory; it never creates pickups.
function API.deleteItem(slot, amount)
    local player = source
    local userId = vRP.getUserId(player)
    if not userId then return { error = "Jogador indisponível." } end
    amount = tonumber(amount)
    if not amount or amount ~= amount or amount == math.huge or amount <= 0 or amount % 1 ~= 0 then
        return { error = "Quantidade inválida." }
    end
    if type(slot) ~= "string" and type(slot) ~= "number" then
        return { error = "Slot inválido." }
    end
    slot = tostring(slot)
    if GetPlayerRoutingBucket(player) ~= 0 then return { error = "Você não pode jogar itens fora agora." } end
    local ped = GetPlayerPed(player)
    if ped == 0 or GetEntityHealth(ped) <= 101 then return { error = "Você está morto." } end
    local item = vRP.getSlotItem(userId, slot)
    if not item or amount > (tonumber(item.amount) or 0) then
        return { error = "O item ou a quantidade não está mais disponível. Reabra o inventário." }
    end
    if GetResourceState("m_robbernpc") == "started" then
        local ok, protected = pcall(function()
            return exports.m_robbernpc:isProtectedRadarItem(userId, player, item.item)
        end)
        if not ok or protected then
            return { error = "Você não pode jogar este item fora enquanto estiver sendo rastreado." }
        end
    end
    if HotbarWeapons then
        local active = HotbarWeapons.GetActive(userId)
        if active and tostring(active.slot) == slot then
            HotbarWeapons.ForceHolster(player, userId)
        end
    end
    -- The fifth argument selects the exact slot; the fourth controls notifications.
    if not vRP.tryGetInventoryItem(userId, item.item, amount, false, slot, true) then
        return { error = "Não foi possível jogar o item fora." }
    end
    if InventoryAudit then
        InventoryAudit.Log("inventory_item_deleted", {
            actorId = userId,
            details = InventoryAudit.ItemDetails(item.item, amount)
        })
    end
    return { used_amount = amount }
end
