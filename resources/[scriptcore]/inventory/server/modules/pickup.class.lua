---@class PickupSystem
PickupSystem = {
    pickups = {}
}

local pickupLocks, playerLocks = {}, {}
local storageKey = 'ground_items:v1'

function PickupSystem:Save()
    SetResourceKvp(storageKey, json.encode(self.pickups))
end

-- Persiste cada mudanca; sem prazo de desaparecimento automatico.
local stored = GetResourceKvpString(storageKey)
if stored and stored ~= '' then
    local ok, entries = pcall(json.decode, stored)
    if not ok or type(entries) ~= 'table' then error('Dados de itens no chao invalidos.') end
    for _, entry in pairs(entries) do
        if type(entry) == 'table' and Items[entry.item] and type(entry.coords) == 'table'
            and tonumber(entry.amount) and entry.amount > 0 then
            local id = IdGen:gen()
            entry.id = id
            entry.coords = vector3(entry.coords.x, entry.coords.y, entry.coords.z)
            PickupSystem.pickups[id] = entry
        end
    end
end

RegisterNetEvent('inventory:requestGroundItems', function()
    local player = source
    if not player or player <= 0 then return end
    local migrated = false
    for _, entry in pairs(PickupSystem.pickups) do
        local expiresAt = vRP.getItemExpiry(entry.item, entry.expiresAt)
        migrated = migrated or expiresAt ~= entry.expiresAt
        entry.expiresAt = expiresAt
    end
    if migrated then PickupSystem:Save() end
    TriggerClientEvent('inventory:syncGroundItems', player, PickupSystem.pickups)
end)

---@param ownerInfo table<string, number>
---@param idname string
---@param amount number
---@param coords vector3
function PickupSystem:Create(ownerInfo,idname,amount,coords,expiresAt)
    local id = IdGen:gen()
    local src, user_id = ownerInfo.src, ownerInfo.user_id
    self.pickups[id] = {id = id, item = idname, name = Items[idname].name , amount = amount,coords = coords, owner_id = user_id, expiresAt = expiresAt}
    self:Save()
    Remote._CreatePickup(-1, self.pickups[id], id)
end

---@param id number
---@param user number
---@param src number
---@return boolean
local function takePickup(self, id, user, src, amount, slot)
  

    local pickupInfo = self.pickups[id]
    if not pickupInfo then
        return false
    end

    local amount = tonumber(amount) or pickupInfo.amount
    if amount ~= amount or amount == math.huge or amount % 1 ~= 0 then return false end
    if amount > pickupInfo.amount then
        amount = pickupInfo.amount
    end
    if amount < 1 then
        return false
    end
    if vRP.computeInvWeight(user) + Items[pickupInfo.item].weight * amount > vRP.getInventoryMaxWeight(user) then 
        Notify(src, "negado", 'Espaço insuficiente na mochila!')
        return false
    end

    -- local coords = GetEntityCoords(GetPlayerPed(src))
    -- if #(coords - pickupInfo.coords) > 15.0 then
    --     print('SUSPEITO PEGANDO ITEM DE LONGE - ID: ' .. user)
    --     TriggerEvent("AC:ForceBan", src, {
    --         reason = "Hack (Pickup)",
    --         forceBan = false
    --     })
    --     return false
    -- end

    local ped = GetPlayerPed(src)
    if GetPlayerRoutingBucket(src) ~= 0 or ped == 0 or GetEntityHealth(ped) <= 101 then return false end
    local coords = GetEntityCoords(ped)
    local target = pickupInfo.coords
    local dx, dy, dz = coords.x - target.x, coords.y - target.y, coords.z - target.z
    if dx * dx + dy * dy + dz * dz > 7.0 * 7.0 then return false end

    if slot then
        local number = tonumber(slot)
        if not number or number < 1 or number % 1 ~= 0 then return false end
        slot = tostring(slot)
        local existing = vRP.getSlotItem(user, slot)
        if existing and existing.item ~= pickupInfo.item then return false end
    end
    if not vRP.giveInventoryItem(user, pickupInfo.item, amount, false, slot, pickupInfo.expiresAt) then return false end

    if amount < pickupInfo.amount then
        pickupInfo.amount = pickupInfo.amount - amount
        self.pickups[id] = pickupInfo
        Remote._UpdatePickup(-1, pickupInfo, id)
    else
        self.pickups[id] = nil
        IdGen:free(id)
        Remote._RemovePickup(-1, id)
    end
    self:Save()

    Notify(src, "sucesso", "Você pegou " .. pickupInfo.name .. " (" .. amount .. "x)")

    if InventoryAudit then
        local ownerId = tonumber(pickupInfo.owner_id)
        InventoryAudit.Log("inventory_item_pickup", {
            actorId = user,
            targetId = (ownerId and ownerId ~= tonumber(user)) and ownerId or nil,
            details = InventoryAudit.ItemDetails(pickupInfo.item, amount) .. ("\n**Pickup ID:** %s"):format(tostring(id))
        })
    end

    vRPc._playSound(src, "HUD_FRONTEND_DEFAULT_SOUNDSET", "PICK_UP")
    vRPc._playAnim(src, true, {{"pickup_object", "pickup_low"}}, false)

    exports["vrp_admin"]:generateLog({
        category = "inventario",
        room = "pegou",
        user_id = user,
        message = ( [[O USER_ID %s PEGOU O ITEM %s NA QUANTIDADE DE %s x]] ):format(user, pickupInfo.item, amount)
    })

    return true
end

function PickupSystem:getPickup(id, user, src, amount, slot)
    id = tonumber(id)
    if not id or pickupLocks[id] or playerLocks[user] then return false end
    pickupLocks[id], playerLocks[user] = true, true
    local ok, result = pcall(takePickup, self, id, user, src, amount, slot)
    pickupLocks[id], playerLocks[user] = nil, nil
    if not ok then
        print('[inventory] Erro ao recolher item: ' .. tostring(result))
        return false
    end
    return result
end
