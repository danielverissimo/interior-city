-- ============================================================================
-- INVENTORY HOTBAR / WEAPON CONTROLLER
-- Slots 1..5 are the only quick-access weapon slots.
-- The GTA weapon wheel is handled client-side and never used by this system.
-- Ammo state is persisted as clip + reserve so holstering/equipping never resets it.
-- ============================================================================

local MAX_HOTBAR_SLOT <const> = 5
local MAX_AMMO <const> = 250

local ActiveWeapons = {}
local AmmoCache = {}
local ActionCooldown = {}
local SourceToUser = {}
local DutyIssued = {}
local DutyLoaded = {}

HotbarWeapons = HotbarWeapons or {}

local function clampInt(value, minValue, maxValue)
    value = math.floor(tonumber(value) or 0)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function isHotbarSlot(slot)
    local n = tonumber(slot)
    return n and n >= 1 and n <= MAX_HOTBAR_SLOT
end

local function getUserCache(user_id)
    user_id = tonumber(user_id)
    AmmoCache[user_id] = AmmoCache[user_id] or {}
    return AmmoCache[user_id]
end

local function loadAmmoState(user_id, weapon)
    local cache = getUserCache(user_id)
    if cache[weapon] then
        return cache[weapon]
    end

    local rows = exports.oxmysql:executeSync([[SELECT clip, reserve, revision FROM inventory_weapon_ammo WHERE user_id = ? AND weapon = ? LIMIT 1]], {
        user_id,
        weapon
    }) or {}

    local clip = 0
    local reserve = 0
    local revision = 0
    if rows[1] then
        clip = clampInt(rows[1].clip, 0, MAX_AMMO)
        reserve = clampInt(rows[1].reserve, 0, MAX_AMMO)
        revision = math.max(0, math.floor(tonumber(rows[1].revision) or 0))
    end

    if clip + reserve > MAX_AMMO then
        reserve = math.max(0, MAX_AMMO - clip)
    end

    cache[weapon] = {
        clip = clip,
        reserve = reserve,
        dirty = false,
        revision = revision
    }

    return cache[weapon]
end

local function setAmmoState(user_id, weapon, total, clip)
    total = clampInt(total, 0, MAX_AMMO)
    clip = clampInt(clip, 0, total)

    local state = loadAmmoState(user_id, weapon)
    state.clip = clip
    state.reserve = math.max(0, total - clip)
    state.revision = (state.revision or 0) + 1
    state.dirty = true
    return state
end

local function saveAmmoState(user_id, weapon, state, sync)
    if not state then return end

    local query = [[
        INSERT INTO inventory_weapon_ammo (user_id, weapon, clip, reserve, revision)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            clip = IF(VALUES(revision) >= revision, VALUES(clip), clip),
            reserve = IF(VALUES(revision) >= revision, VALUES(reserve), reserve),
            revision = GREATEST(revision, VALUES(revision)),
            updated_at = IF(VALUES(revision) >= revision, CURRENT_TIMESTAMP, updated_at)
    ]]
    local params = { user_id, weapon, state.clip or 0, state.reserve or 0, state.revision or 0 }

    local revision = state.revision or 0
    if sync then
        exports.oxmysql:executeSync(query, params)
        if (state.revision or 0) == revision then
            state.dirty = false
        end
    else
        exports.oxmysql:execute(query, params, function()
            -- Do not mark a newer ammo change as clean when an older DB write
            -- finishes after it.
            if (state.revision or 0) == revision then
                state.dirty = false
            end
        end)
    end
end

local function flushUser(user_id, sync)
    local cache = AmmoCache[tonumber(user_id)]
    if not cache then return end
    for weapon, state in pairs(cache) do
        if state.dirty then
            saveAmmoState(user_id, weapon, state, sync)
        end
    end
end

local function snapshot(user_id)
    local response = {
        slots = {},
        active_slot = nil,
        active_weapon = nil
    }

    local active = ActiveWeapons[user_id]
    if active then
        response.active_slot = tonumber(active.slot)
        response.active_weapon = active.weapon
    end

    for i = 1, MAX_HOTBAR_SLOT do
        local slot = tostring(i)
        local data = vRP.getSlotItem(user_id, slot)
        if data and Items[data.item] then
            local itemConfig = Items[data.item]
            local slotData = {
                slot = i,
                item = data.item,
                amount = tonumber(data.amount) or 0,
                name = itemConfig.name or data.item,
                png = itemConfig.png or data.item,
                type = itemConfig.type or "use",
                equipped = active and tostring(active.slot) == slot or false
            }

            -- Every weapon kept in slots 1..5 carries its own persisted ammo
            -- snapshot. This lets the inventory show clip/reserve even when a
            -- different weapon is currently in the player's hands.
            if itemConfig.type == "equip" then
                local weapon = data.item:upper()
                local ammo = loadAmmoState(user_id, weapon)
                local clip = clampInt(ammo.clip or 0, 0, MAX_AMMO)
                local reserve = clampInt(ammo.reserve or 0, 0, MAX_AMMO)
                if clip + reserve > MAX_AMMO then
                    reserve = math.max(0, MAX_AMMO - clip)
                end

                slotData.weapon = weapon
                slotData.ammo = {
                    clip = clip,
                    reserve = reserve,
                    total = clip + reserve
                }
            end

            response.slots[i] = slotData
        else
            response.slots[i] = {
                slot = i,
                empty = true,
                equipped = false
            }
        end
    end

    return response
end

local function getClientWeaponState(source)
    local ok, state = pcall(function()
        return Remote.getHotbarWeaponState(source)
    end)

    if not ok or type(state) ~= "table" then
        return nil
    end
    return state
end

local function syncVrpWeapons(user_id, oldWeapon, newWeapon, total)
    local weapons = vRP.getWeapons(user_id) or {}
    if oldWeapon then
        weapons[oldWeapon] = nil
    end
    if newWeapon then
        weapons[newWeapon] = { ammo = clampInt(total or 0, 0, MAX_AMMO) }
    end
    vRP.setWeapons(user_id, weapons)
end

local function captureActive(user_id, source)
    local active = ActiveWeapons[user_id]
    if not active then return nil end

    local current = getClientWeaponState(source)
    if current and current.weapon == active.weapon then
        -- The client may report ammo decreases caused by shots/reloads, but it
        -- is never allowed to increase the server-authorized total. Ammo gains
        -- only happen through the server-side recharge path below.
        local reportedTotal = clampInt(current.total, 0, MAX_AMMO)
        local authorizedTotal = clampInt(active.total or reportedTotal, 0, MAX_AMMO)
        local safeTotal = math.min(reportedTotal, authorizedTotal)
        local safeClip = clampInt(current.clip, 0, safeTotal)
        active.total = safeTotal
        setAmmoState(user_id, active.weapon, safeTotal, safeClip)
    end

    return active
end

local function canEquip(user_id, source)
    if GetPlayerRoutingBucket(source) ~= 0 then
        return false, "Você não pode equipar arma agora."
    end

    local ped = GetPlayerPed(source)
    if ped and ped > 0 and GetEntityHealth(ped) <= 101 then
        return false, "Você não pode equipar arma estando morto."
    end

    local okBlacklist, blacklisted = pcall(function()
        return exports.vrp_admin:checkIfUserIsBlacklisted(user_id)
    end)
    if okBlacklist and blacklisted then
        return false, "Você não pode equipar arma agora."
    end

    local org = vRP.getUserGroupOrg(user_id)
    local okOrg, orgBlacklisted = pcall(function()
        return exports.vrp_admin:isOrganizationBlacklisted(org)
    end)
    if okOrg and orgBlacklisted then
        return false, "Você não pode equipar arma agora."
    end

    return true
end

function HotbarWeapons.GetSnapshot(user_id)
    return snapshot(user_id)
end

function HotbarWeapons.GetActive(user_id)
    return ActiveWeapons[user_id]
end

function HotbarWeapons.UpdateAmmo(user_id, source, slot, weapon, total, clip)
    local active = ActiveWeapons[user_id]
    if not active then return false end
    if tostring(active.slot) ~= tostring(slot) or active.weapon ~= weapon then return false end

    local reportedTotal = clampInt(total, 0, MAX_AMMO)
    local authorizedTotal = clampInt(active.total or reportedTotal, 0, MAX_AMMO)
    local safeTotal = math.min(reportedTotal, authorizedTotal)
    local safeClip = clampInt(clip, 0, safeTotal)

    active.total = safeTotal
    setAmmoState(user_id, weapon, safeTotal, safeClip)
    syncVrpWeapons(user_id, nil, weapon, safeTotal)
    return true
end

function HotbarWeapons.ForceHolster(source, user_id)
    local active = ActiveWeapons[user_id]
    if not active then return false end

    captureActive(user_id, source)

    local oldWeapon = active.weapon
    ActiveWeapons[user_id] = nil
    syncVrpWeapons(user_id, oldWeapon, nil, 0)

    if InventoryAudit then
        InventoryAudit.Log("inventory_weapon_holstered", {
            actorId = user_id,
            details = ("**Arma:** %s\n**Slot:** %s\n**Motivo:** coldre forçado por outra ação do inventário."):format(
                InventoryAudit.ItemLabel(active.item or tostring(oldWeapon):lower()),
                tostring(active.slot)
            )
        })
    end

    pcall(function()
        Remote._hotbarForceHolster(source, active.slot, active.weapon)
    end)

    return true
end

-- When a weapon LEAVES one of the quick slots (1..5), its remaining ammo is
-- detached from the weapon and returned to the player's inventory. The saved
-- clip/reserve is then reset to zero, so putting the weapon back in the hotbar
-- requires loading ammo again. This is deliberately different from simply
-- holstering a weapon with the same number key, which keeps its ammo attached.
function HotbarWeapons.DetachQuickSlotAmmo(source, user_id, slot, item)
    slot = tostring(slot)
    if not isHotbarSlot(slot) then
        return { success = true, refunded = 0 }
    end

    local slotData = item and { item = item } or vRP.getSlotItem(user_id, slot)
    if not slotData or not slotData.item or not Items[slotData.item] or Items[slotData.item].type ~= "equip" then
        return { success = true, refunded = 0 }
    end

    local weapon = slotData.item:upper()
    local active = ActiveWeapons[user_id]
    local isActiveSlot = active
        and tostring(active.slot) == slot
        and active.weapon == weapon

    -- Read the exact live amount before removing the physical weapon. This also
    -- captures shots fired immediately before the drag operation.
    if isActiveSlot then
        captureActive(user_id, source)
    end

    local ammo = loadAmmoState(user_id, weapon)
    local clip = clampInt(ammo.clip or 0, 0, MAX_AMMO)
    local reserve = clampInt(ammo.reserve or 0, 0, MAX_AMMO)
    if clip + reserve > MAX_AMMO then
        reserve = math.max(0, MAX_AMMO - clip)
    end
    local total = clip + reserve

    -- The ammo naming is the exact inverse of the recharge mapping used by
    -- hotbarUseSlot: WEAPON_PISTOL_MK2 <-> ammo_pistol_mk2.
    local ammoItem = "ammo_" .. weapon:gsub("^WEAPON_", ""):lower()

    if total > 0 then
        if not Items[ammoItem] or Items[ammoItem].type ~= "recharge" then
            -- Never destroy rounds if a custom weapon was configured without
            -- its matching ammo item. Keep the weapon state intact instead.
            return {
                success = false,
                error = "A munição correspondente desta arma não está configurada no inventário."
            }
        end

        -- Prefer the regular inventory area (slots 6+) so clearing a hotbar
        -- weapon does not immediately fill that same quick slot with ammo.
        local targetSlot = nil
        for i = MAX_HOTBAR_SLOT + 1, 58 do
            local data = vRP.getSlotItem(user_id, tostring(i))
            if data and data.item == ammoItem then
                targetSlot = tostring(i)
                break
            end
        end
        if not targetSlot then
            for i = MAX_HOTBAR_SLOT + 1, 58 do
                if not vRP.getSlotItem(user_id, tostring(i)) then
                    targetSlot = tostring(i)
                    break
                end
            end
        end

        -- Fallback lets vRP stack/place the ammo if the visible main inventory
        -- is full. The important rule here is that no remaining round is lost.
        if targetSlot then
            vRP.giveInventoryItem(user_id, ammoItem, total, false, targetSlot)
        else
            vRP.giveInventoryItem(user_id, ammoItem, total, false)
        end
    end

    if isActiveSlot then
        ActiveWeapons[user_id] = nil
        syncVrpWeapons(user_id, weapon, nil, 0)
        pcall(function()
            Remote._hotbarForceHolster(source, slot, weapon)
        end)
    end

    local state = setAmmoState(user_id, weapon, 0, 0)
    -- This transition moves ammo back into inventory, so persist immediately
    -- instead of waiting for the normal five-second batch flush.
    saveAmmoState(user_id, weapon, state, true)

    return {
        success = true,
        refunded = total,
        ammo_item = ammoItem,
        weapon = weapon
    }
end

function HotbarWeapons.UseSlot(source, user_id, slot, requestedAmount)
    slot = tostring(slot)
    local numericSlot = tonumber(slot)
    if not numericSlot or numericSlot < 1 or numericSlot % 1 ~= 0 then
        return { error = "Slot de inventário inválido." }
    end

    local slotData = vRP.getSlotItem(user_id, slot)
    if not slotData or not Items[slotData.item] then
        return {
            action = "empty",
            hotbar = snapshot(user_id)
        }
    end

    local config = Items[slotData.item]

    if config.type == "equip" then
        if not isHotbarSlot(slot) then
            return {
                error = "Mova a arma para um dos slots rápidos de 1 a 5 para equipá-la.",
                hotbar = snapshot(user_id)
            }
        end

        local allowed, reason = canEquip(user_id, source)
        if not allowed then
            return { error = reason, hotbar = snapshot(user_id) }
        end

        local weapon = slotData.item:upper()
        local active = ActiveWeapons[user_id]

        if active and tostring(active.slot) == slot and active.weapon == weapon then
            captureActive(user_id, source)
            ActiveWeapons[user_id] = nil
            syncVrpWeapons(user_id, weapon, nil, 0)

            if InventoryAudit then
                InventoryAudit.Log("inventory_weapon_holstered", {
                    actorId = user_id,
                    details = ("**Arma:** %s\n**Spawn:** %s\n**Slot:** %s\n**Motivo:** jogador guardou a arma pelo próprio slot."):format(
                        InventoryAudit.ItemLabel(slotData.item),
                        tostring(slotData.item),
                        tostring(slot)
                    )
                })
            end

            return {
                action = "holster",
                slot = tonumber(slot),
                weapon = weapon,
                hotbar = snapshot(user_id),
                used_amount = 0
            }
        end

        if active then
            captureActive(user_id, source)
        end

        local oldWeapon = active and active.weapon or nil
        local ammo = loadAmmoState(user_id, weapon)
        local total = clampInt((ammo.clip or 0) + (ammo.reserve or 0), 0, MAX_AMMO)
        local clip = clampInt(ammo.clip or 0, 0, total)

        ActiveWeapons[user_id] = {
            slot = slot,
            weapon = weapon,
            item = slotData.item,
            total = total
        }

        syncVrpWeapons(user_id, oldWeapon, weapon, total)

        if InventoryAudit then
            InventoryAudit.Log("inventory_weapon_equipped", {
                actorId = user_id,
                details = ("**Arma:** %s\n**Spawn:** %s\n**Slot:** %s\n**Munição total:** %sx\n**Pente:** %sx"):format(
                    InventoryAudit.ItemLabel(slotData.item),
                    tostring(slotData.item),
                    tostring(slot),
                    tostring(total),
                    tostring(clip)
                )
            })
        end

        pcall(function()
            exports.vrp_admin:generateLog({
                category = "inventario",
                room = "equipar",
                user_id = user_id,
                message = ("O USER_ID %s EQUIPOU A ARMA %s PELO SLOT %s"):format(user_id, slotData.item, slot)
            })
        end)

        return {
            action = "equip",
            slot = tonumber(slot),
            weapon = weapon,
            item = slotData.item,
            png = Items[slotData.item].png or slotData.item,
            total = total,
            clip = clip,
            reserve = math.max(0, total - clip),
            hotbar = snapshot(user_id),
            used_amount = 0
        }
    end

    if config.type == "recharge" then
        if vRP.hasPermission(user_id, "crianca.permissao") then
            return { error = "Você não pode utilizar munição agora.", hotbar = snapshot(user_id) }
        end

        local active = ActiveWeapons[user_id]
        if not active then
            return { error = "Você não tem uma arma equipada.", hotbar = snapshot(user_id) }
        end

        local expectedWeapon = "WEAPON_" .. slotData.item:gsub("ammo_", ""):upper()
        if active.weapon ~= expectedWeapon then
            return { error = "Esta munição não pertence à arma equipada.", hotbar = snapshot(user_id) }
        end

        local clientState = getClientWeaponState(source)
        local total = 0
        local clip = 0
        local maxClip = 0
        if clientState and clientState.weapon == active.weapon then
            local reportedTotal = clampInt(clientState.total, 0, MAX_AMMO)
            local authorizedTotal = clampInt(active.total or reportedTotal, 0, MAX_AMMO)
            total = math.min(reportedTotal, authorizedTotal)
            clip = clampInt(clientState.clip, 0, total)
            maxClip = clampInt(clientState.max_clip, 0, MAX_AMMO)
            active.total = total
            setAmmoState(user_id, active.weapon, total, clip)
        else
            local persisted = loadAmmoState(user_id, active.weapon)
            clip = persisted.clip or 0
            total = math.min(
                clampInt(clip + (persisted.reserve or 0), 0, MAX_AMMO),
                clampInt(active.total or MAX_AMMO, 0, MAX_AMMO)
            )
            clip = math.min(clip, total)
            active.total = total
        end

        if total >= MAX_AMMO then
            return { error = "Você já está com a munição cheia.", hotbar = snapshot(user_id) }
        end

        local available = tonumber(slotData.amount) or 0
        local requested = tonumber(requestedAmount) or available
        if requested <= 0 then requested = available end
        local amount = math.min(available, requested, MAX_AMMO - total)
        amount = math.floor(amount)
        if amount <= 0 then
            return { error = "Você não possui munição suficiente.", hotbar = snapshot(user_id) }
        end

        if not vRP.tryGetInventoryItem(user_id, slotData.item, amount, slot) then
            return { error = "Não foi possível utilizar esta munição.", hotbar = snapshot(user_id) }
        end

        local newTotal = total + amount
        local newClip = clip
        if maxClip > 0 then
            -- Using an ammo item acts like a real reload: fill the magazine
            -- first, then keep the remaining rounds as reserve.
            newClip = math.min(maxClip, newTotal)
        end
        newClip = math.min(newClip, newTotal)

        active.total = newTotal
        setAmmoState(user_id, active.weapon, newTotal, newClip)
        syncVrpWeapons(user_id, nil, active.weapon, newTotal)

        if InventoryAudit then
            InventoryAudit.Log("inventory_weapon_recharged", {
                actorId = user_id,
                details = ("**Arma:** %s\n**Munição usada:** %s (`%s`) x%s\n**Antes:** %sx\n**Depois:** %sx\n**Pente após recarga:** %sx"):format(
                    tostring(active.weapon),
                    InventoryAudit.ItemLabel(slotData.item),
                    tostring(slotData.item),
                    tostring(amount),
                    tostring(total),
                    tostring(newTotal),
                    tostring(newClip)
                )
            })
        end

        pcall(function()
            exports.vrp_admin:generateLog({
                category = "inventario",
                room = "equipar",
                user_id = user_id,
                message = ("O USER_ID %s RECARREGOU %s COM %sx DE %s"):format(user_id, active.weapon, amount, slotData.item)
            })
        end)

        return {
            action = "recharge",
            slot = tonumber(slot),
            weapon = active.weapon,
            total = newTotal,
            clip = newClip,
            reserve = math.max(0, newTotal - newClip),
            used_amount = amount,
            hotbar = snapshot(user_id)
        }
    end

    return {
        action = "regular",
        slot = tonumber(slot),
        hotbar = snapshot(user_id)
    }
end

function API.hotbarUseSlot(slot, amount)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return { error = "Usuário não encontrado." } end
    SourceToUser[source] = user_id

    local now = GetGameTimer()
    local last = ActionCooldown[user_id] or 0
    if now - last < 150 then
        return { error = "Aguarde um instante.", hotbar = snapshot(user_id) }
    end
    ActionCooldown[user_id] = now

    return HotbarWeapons.UseSlot(source, user_id, slot, amount)
end

function API.getHotbarSnapshot()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return { slots = {} } end
    return snapshot(user_id)
end

function API.updateHotbarAmmo(slot, weapon, total, clip)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return false end
    SourceToUser[source] = user_id
    return HotbarWeapons.UpdateAmmo(user_id, source, slot, weapon, total, clip)
end

function API.clientHolsterHotbar(slot, weapon, total, clip)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return false end
    SourceToUser[source] = user_id

    local active = ActiveWeapons[user_id]
    if not active or tostring(active.slot) ~= tostring(slot) or active.weapon ~= weapon then
        return false
    end

    local reportedTotal = clampInt(total, 0, MAX_AMMO)
    local authorizedTotal = clampInt(active.total or reportedTotal, 0, MAX_AMMO)
    local safeTotal = math.min(reportedTotal, authorizedTotal)
    local safeClip = clampInt(clip, 0, safeTotal)
    setAmmoState(user_id, weapon, safeTotal, safeClip)
    ActiveWeapons[user_id] = nil
    syncVrpWeapons(user_id, weapon, nil, 0)
    return true
end

-- Compatibility with the old "store equipped weapon" panel.
-- In the new system the weapon item never leaves slots 1..5; storing only holsters it.
function API.storeWeapons(_weapons)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return { error = "Usuário não encontrado." } end

    if HotbarWeapons.ForceHolster(source, user_id) then
        return { success = true }
    end
    return { error = "Você não tem nenhuma arma equipada." }
end


-- ============================================================================
-- TEMPORARY DUTY WEAPONS
-- Weapons issued by service resources are persisted as temporary inventory
-- entries. They stay in slots 1..5, cannot be transferred/stored and are
-- removed cleanly when duty ends or when stale state is detected on login.
-- ============================================================================

local function loadDutyIssued(user_id)
    user_id = tonumber(user_id)
    if not user_id then return {} end
    if DutyLoaded[user_id] then
        return DutyIssued[user_id] or {}
    end

    DutyIssued[user_id] = {}
    local rows = exports.oxmysql:executeSync([[
        SELECT item, slot
        FROM inventory_duty_weapons
        WHERE user_id = ?
    ]], { user_id }) or {}

    for _, row in ipairs(rows) do
        local item = tostring(row.item or ""):lower()
        local slot = tostring(tonumber(row.slot) or 0)
        if item ~= "" and isHotbarSlot(slot) then
            DutyIssued[user_id][item] = { slot = slot }
        end
    end

    DutyLoaded[user_id] = true
    return DutyIssued[user_id]
end

local function setDutyMarker(user_id, item, slot)
    user_id = tonumber(user_id)
    item = tostring(item or ""):lower()
    slot = tostring(slot or "")
    if not user_id or item == "" or not isHotbarSlot(slot) then return false end

    local issued = loadDutyIssued(user_id)
    issued[item] = { slot = slot }

    exports.oxmysql:executeSync([[
        INSERT INTO inventory_duty_weapons (user_id, item, slot, issued_at)
        VALUES (?, ?, ?, UNIX_TIMESTAMP())
        ON DUPLICATE KEY UPDATE slot = VALUES(slot), issued_at = VALUES(issued_at)
    ]], { user_id, item, tonumber(slot) })
    return true
end

local function clearDutyMarker(user_id, item)
    user_id = tonumber(user_id)
    item = tostring(item or ""):lower()
    if not user_id or item == "" then return end

    local issued = loadDutyIssued(user_id)
    issued[item] = nil
    exports.oxmysql:executeSync(
        "DELETE FROM inventory_duty_weapons WHERE user_id = ? AND item = ?",
        { user_id, item }
    )
end

local function findFreeHotbarSlot(user_id)
    for i = 1, MAX_HOTBAR_SLOT do
        if not vRP.getSlotItem(user_id, tostring(i)) then
            return tostring(i)
        end
    end
    return nil
end

local function findInventoryItemSlot(user_id, item)
    local inventory = vRP.getInventory(user_id) or {}
    for slot, data in pairs(inventory) do
        if data and data.item == item then
            return tostring(slot)
        end
    end
    return nil
end

function HotbarWeapons.GetDutyWeapon(user_id, item)
    local issued = loadDutyIssued(user_id)
    return issued[tostring(item or ""):lower()]
end

function HotbarWeapons.IsDutyWeapon(user_id, item)
    return HotbarWeapons.GetDutyWeapon(user_id, item) ~= nil
end

function HotbarWeapons.IsDutyWeaponSlot(user_id, slot, item)
    local marker = HotbarWeapons.GetDutyWeapon(user_id, item)
    return marker ~= nil and tostring(marker.slot) == tostring(slot)
end

function HotbarWeapons.UpdateDutyWeaponSlot(user_id, item, slot)
    if not HotbarWeapons.IsDutyWeapon(user_id, item) then return false end
    return setDutyMarker(user_id, item, slot)
end

exports("isDutyWeapon", function(user_id, item)
    return HotbarWeapons.IsDutyWeapon(user_id, item)
end)

exports("isDutyWeaponSlot", function(user_id, slot, item)
    return HotbarWeapons.IsDutyWeaponSlot(user_id, slot, item)
end)

exports("giveDutyWeapon", function(source, user_id, item, total, clip)
    user_id = tonumber(user_id)
    item = tostring(item or ""):lower()

    if not user_id or item == "" or not Items[item] or Items[item].type ~= "equip" then
        return { success = false, error = "Arma não cadastrada no inventário: " .. item }
    end
    if HotbarWeapons.IsDutyWeapon(user_id, item) then
        return { success = false, error = "Esta arma de serviço já foi retirada." }
    end
    -- Never transform an already-owned personal weapon into a temporary one.
    if findInventoryItemSlot(user_id, item) then
        return { success = false, error = "Você já possui esta arma no inventário." }
    end

    local slot = findFreeHotbarSlot(user_id)
    if not slot then
        return { success = false, error = "Seus slots de armas 1 a 5 estão cheios." }
    end

    vRP.giveInventoryItem(user_id, item, 1, false, slot)
    local inserted = vRP.getSlotItem(user_id, slot)
    if not inserted or inserted.item ~= item then
        return { success = false, error = "Não foi possível colocar a arma na hotbar." }
    end

    local weapon = item:upper()
    total = clampInt(total, 0, MAX_AMMO)
    clip = clampInt(clip, 0, total)

    local state = setAmmoState(user_id, weapon, total, clip)
    saveAmmoState(user_id, weapon, state, true)

    if not setDutyMarker(user_id, item, slot) then
        vRP.tryGetInventoryItem(user_id, item, 1, false, slot)
        setAmmoState(user_id, weapon, 0, 0)
        return { success = false, error = "Não foi possível registrar a arma temporária." }
    end

    if InventoryAudit then
        InventoryAudit.Log("inventory_duty_weapon_issued", {
            actorId = user_id,
            details = ("**Arma:** %s\n**Spawn:** %s\n**Slot rápido:** %s\n**Munição total:** %sx\n**Pente:** %sx"):format(
                InventoryAudit.ItemLabel(item),
                item,
                tostring(slot),
                tostring(total),
                tostring(clip)
            )
        })
    end

    return {
        success = true,
        slot = tonumber(slot),
        item = item,
        weapon = weapon,
        total = total,
        clip = clip
    }
end)

local function removeDutyWeaponInternal(source, user_id, item)
    user_id = tonumber(user_id)
    item = tostring(item or ""):lower()
    local marker = HotbarWeapons.GetDutyWeapon(user_id, item)
    if not user_id or not marker then
        return { success = false, error = "Arma não pertence ao loadout temporário." }
    end

    local weapon = item:upper()
    local active = ActiveWeapons[user_id]
    local src = tonumber(source) or 0
    local sourceOnline = src > 0 and GetPlayerName(src) ~= nil

    if active and active.weapon == weapon then
        if sourceOnline then
            HotbarWeapons.ForceHolster(src, user_id)
        else
            ActiveWeapons[user_id] = nil
            syncVrpWeapons(user_id, weapon, nil, 0)
        end
    else
        syncVrpWeapons(user_id, weapon, nil, 0)
    end

    local removeSlot = tostring(marker.slot)
    local slotData = vRP.getSlotItem(user_id, removeSlot)

    -- Marker normally follows quick-slot swaps. If another resource moved the
    -- item behind the inventory's back, recover it from another quick slot.
    if not slotData or slotData.item ~= item then
        removeSlot = nil
        for i = 1, MAX_HOTBAR_SLOT do
            local data = vRP.getSlotItem(user_id, tostring(i))
            if data and data.item == item then
                removeSlot = tostring(i)
                break
            end
        end
    end

    if removeSlot then
        vRP.tryGetInventoryItem(user_id, item, 1, false, removeSlot)
    end

    local state = setAmmoState(user_id, weapon, 0, 0)
    saveAmmoState(user_id, weapon, state, true)
    clearDutyMarker(user_id, item)

    if InventoryAudit then
        InventoryAudit.Log("inventory_duty_weapon_removed", {
            actorId = user_id,
            details = ("**Arma:** %s\n**Spawn:** %s\n**Slot removido:** %s"):format(
                InventoryAudit.ItemLabel(item),
                item,
                tostring(removeSlot or "-")
            )
        })
    end

    return { success = true, item = item, weapon = weapon, slot = tonumber(removeSlot) }
end

exports("clearDutyWeapon", function(source, user_id, item)
    return removeDutyWeaponInternal(source, user_id, item)
end)

exports("clearAllDutyWeapons", function(source, user_id)
    user_id = tonumber(user_id)
    if not user_id then return { success = false, removed = 0 } end

    local issued = loadDutyIssued(user_id)
    local items = {}
    for item in pairs(issued) do items[#items + 1] = item end

    local removed = 0
    for _, item in ipairs(items) do
        local result = removeDutyWeaponInternal(source, user_id, item)
        if result and result.success then removed = removed + 1 end
    end

    return { success = true, removed = removed }
end)

CreateThread(function()
    exports.oxmysql:executeSync([[
        CREATE TABLE IF NOT EXISTS inventory_weapon_ammo (
            user_id INT NOT NULL,
            weapon VARCHAR(100) NOT NULL,
            clip INT NOT NULL DEFAULT 0,
            reserve INT NOT NULL DEFAULT 0,
            revision BIGINT NOT NULL DEFAULT 0,
            updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (user_id, weapon)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    -- Upgrade installations that already created the table with an earlier
    -- version of this resource.
    exports.oxmysql:executeSync([[
        ALTER TABLE inventory_weapon_ammo
        ADD COLUMN IF NOT EXISTS revision BIGINT NOT NULL DEFAULT 0 AFTER reserve
    ]])

    exports.oxmysql:executeSync([[
        CREATE TABLE IF NOT EXISTS inventory_duty_weapons (
            user_id INT NOT NULL,
            item VARCHAR(100) NOT NULL,
            slot TINYINT UNSIGNED NOT NULL,
            issued_at BIGINT NOT NULL DEFAULT 0,
            PRIMARY KEY (user_id, item),
            INDEX idx_duty_user (user_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    while true do
        Wait(5000)
        for user_id in pairs(AmmoCache) do
            flushUser(user_id, false)
        end
    end
end)

-- Safety net for inventory mutations performed by other resources. If another
-- script removes or moves the weapon item without going through this inventory,
-- the physical weapon is holstered automatically instead of becoming orphaned.
CreateThread(function()
    while true do
        Wait(1000)
        for user_id, active in pairs(ActiveWeapons) do
            local source = vRP.getUserSource(user_id)
            if source then
                local slotData = vRP.getSlotItem(user_id, tostring(active.slot))
                if not slotData or slotData.item ~= active.item then
                    HotbarWeapons.ForceHolster(source, user_id)
                end
            end
        end
    end
end)

AddEventHandler("playerDropped", function()
    local src = source
    local user_id = vRP.getUserId(src) or SourceToUser[src]
    SourceToUser[src] = nil
    if not user_id then return end
    flushUser(user_id, true)
    local active = ActiveWeapons[user_id]
    if active then
        syncVrpWeapons(user_id, active.weapon, nil, 0)
    end
    ActiveWeapons[user_id] = nil
    AmmoCache[user_id] = nil
    ActionCooldown[user_id] = nil
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for user_id in pairs(AmmoCache) do
        flushUser(user_id, true)
    end
    for user_id, active in pairs(ActiveWeapons) do
        syncVrpWeapons(user_id, active.weapon, nil, 0)
    end
end)
