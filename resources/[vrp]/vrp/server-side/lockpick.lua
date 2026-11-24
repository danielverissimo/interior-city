-- Desgaste compartilhado por personagem entre todas as atividades.
-- Salvo na datatable do vRP junto com os demais dados do personagem.
function vRP.useLockpick(user_id, slot)
    local data = vRP.getUserDataTable(user_id)
    if not data or vRP.getInventoryItemAmount(user_id, "lockpick") < 1 then
        return false
    end
    if slot then
        local entry = vRP.getSlotItem(user_id, tostring(slot))
        if not entry or entry.item ~= "lockpick" or vRP.isInventoryItemExpired(entry) then return false end
    end

    local uses = math.max(0, math.min(2, tonumber(data.lockpickUses) or 0))
    -- 1/3, depois 1/2, depois certeza: vida util de 1 a 3 usos.
    local broken = math.random(1, 3 - uses) == 1
    if broken then
        if not vRP.tryGetInventoryItem(user_id, "lockpick", 1, true, slot) then
            return false
        end
        data.lockpickUses = 0
        local player = vRP.getUserSource(user_id)
        if player then
            TriggerClientEvent("Notify", player, "aviso", "Sua lockpick quebrou durante o uso.", 5000)
        end
    else
        data.lockpickUses = uses + 1
    end
    -- Quebrar nao impede a tentativa que ja esta sendo realizada.
    return true
end
