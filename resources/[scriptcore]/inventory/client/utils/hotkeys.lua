-- ============================================================================
-- INVENTORY QUICK SLOTS / WEAPON CONTROLLER
-- 1..5 = inventory quick slots. GTA's native weapon wheel and native weapon
-- number selection are completely blocked while this resource is running.
-- ============================================================================

local HOTKEY_COOLDOWN = 0
local ACTIVE = nil
local LAST_SYNC = { total = -1, clip = -1 }
local LAST_HUD = { weapon = nil, clip = -1, reserve = -1 }
-- While GTA is finishing the native weapon switch, GetAmmoInClip can briefly
-- report 0 even though the persisted hotbar state already has the correct clip.
-- Keep the authoritative values during that tiny transition so neither the HUD
-- nor the server ever sees the temporary/incorrect native value.
local AMMO_BOOTSTRAP = nil
local EQUIP_SERIAL = 0
local TAB_HOTBAR_HELD = false
local UNARMED_HASH <const> = joaat("WEAPON_UNARMED")

local function getAmmoInClipSafe(ped, weaponHash)
    local ok, clip = GetAmmoInClip(ped, weaponHash)
    if type(clip) == "number" then return math.max(0, clip) end
    if type(ok) == "number" then return math.max(0, ok) end
    return 0
end

local function getNativeState()
    if not ACTIVE then return nil end

    local ped = PlayerPedId()
    local hash = joaat(ACTIVE.weapon)
    local present = HasPedGotWeapon(ped, hash, false)
    local total
    local clip

    if present then
        total = math.max(0, GetAmmoInPedWeapon(ped, hash) or 0)
        clip = math.min(total, getAmmoInClipSafe(ped, hash))
    else
        -- If another resource disarms the ped, preserve the last authoritative
        -- local state instead of interpreting the missing weapon as 0 ammo.
        total = math.max(0, LAST_SYNC.total >= 0 and LAST_SYNC.total or 0)
        clip = math.max(0, math.min(total, LAST_SYNC.clip >= 0 and LAST_SYNC.clip or 0))
    end

    local maxClip = tonumber(GetMaxAmmoInClip(ped, hash, true)) or 0
    if maxClip < 0 then maxClip = 0 end

    return {
        slot = tostring(ACTIVE.slot),
        weapon = ACTIVE.weapon,
        total = total,
        clip = clip,
        reserve = math.max(0, total - clip),
        max_clip = maxClip,
        present = present
    }
end

local function getCurrentState()
    local state = getNativeState()
    if not state then return nil end

    local bootstrap = AMMO_BOOTSTRAP
    if bootstrap and ACTIVE and bootstrap.weapon == ACTIVE.weapon then
        -- Native state has caught up: from now on the live GTA values are the
        -- source of truth again.
        if state.present and state.total == bootstrap.total and state.clip == bootstrap.clip then
            AMMO_BOOTSTRAP = nil
            return state
        end

        -- If the total already dropped, a real shot/action happened after the
        -- equip. Never overwrite that live gameplay state with the bootstrap.
        if state.present and state.total < bootstrap.total then
            AMMO_BOOTSTRAP = nil
            return state
        end

        -- GTA commonly reports 0 / total for a few frames while switching
        -- weapons. During that window expose the persisted values instead.
        if GetGameTimer() < bootstrap.expires_at and state.present then
            state.total = bootstrap.total
            state.clip = bootstrap.clip
            state.reserve = math.max(0, bootstrap.total - bootstrap.clip)
            return state
        end

        AMMO_BOOTSTRAP = nil
    end

    return state
end

local function hideWeaponHud()
    LAST_HUD.weapon = nil
    LAST_HUD.clip = -1
    LAST_HUD.reserve = -1

    SendNUIMessage({
        route = "HIDE_WEAPON_HUD"
    })
end

local updateWeaponHud

local function sendWeaponHudValues(clip, reserve)
    if not ACTIVE then return end

    clip = math.max(0, tonumber(clip) or 0)
    reserve = math.max(0, tonumber(reserve) or 0)

    SendNUIMessage({
        route = "UPDATE_WEAPON_HUD",
        payload = {
            weapon = ACTIVE.weapon,
            item = ACTIVE.item,
            png = ACTIVE.png or ACTIVE.item,
            clip = clip,
            reserve = reserve
        }
    })

    LAST_HUD.weapon = ACTIVE.weapon
    LAST_HUD.clip = clip
    LAST_HUD.reserve = reserve
end

local function startAmmoBootstrap(total, clip)
    if not ACTIVE then return end

    EQUIP_SERIAL = EQUIP_SERIAL + 1
    local serial = EQUIP_SERIAL
    local weapon = ACTIVE.weapon
    local hash = joaat(weapon)
    local ped = PlayerPedId()

    AMMO_BOOTSTRAP = {
        weapon = weapon,
        total = total,
        clip = clip,
        expires_at = GetGameTimer() + 2000
    }

    -- Paint the authoritative server/persisted value immediately. We do not
    -- wait for GetAmmoInClip because GTA can briefly return 0 after a switch.
    sendWeaponHudValues(clip, math.max(0, total - clip))

    -- Also make the native weapon state converge immediately. SetAmmoInClip is
    -- more reliable after the weapon is already the current weapon, so retry
    -- for a few frames only while no real shot has changed the total ammo.
    CreateThread(function()
        for _ = 1, 12 do
            Wait(0)
            if serial ~= EQUIP_SERIAL or not ACTIVE or ACTIVE.weapon ~= weapon then return end

            local native = getNativeState()
            if not native or not native.present then return end

            if native.total == total and native.clip == clip then
                AMMO_BOOTSTRAP = nil
                updateWeaponHud(true)
                return
            end

            if native.total < total then
                AMMO_BOOTSTRAP = nil
                updateWeaponHud(true)
                return
            end

            if not IsPedShooting(ped) then
                SetCurrentPedWeapon(ped, hash, true)
                SetPedAmmo(ped, hash, total)
                if total > 0 then
                    SetAmmoInClip(ped, hash, clip)
                end
            end
        end
    end)
end

updateWeaponHud = function(force)
    if not ACTIVE then
        if LAST_HUD.weapon then hideWeaponHud() end
        return
    end

    local state = getCurrentState()
    if not state or not state.present then
        if LAST_HUD.weapon then hideWeaponHud() end
        return
    end

    local reserve = math.max(0, state.reserve or 0)
    local clip = math.max(0, state.clip or 0)
    if force or LAST_HUD.weapon ~= ACTIVE.weapon or LAST_HUD.clip ~= clip or LAST_HUD.reserve ~= reserve then
        sendWeaponHudValues(clip, reserve)
    end
end

local function pushAmmoState(force)
    local state = getCurrentState()
    if not state then return end

    if force or state.total ~= LAST_SYNC.total or state.clip ~= LAST_SYNC.clip then
        Remote._updateHotbarAmmo(state.slot, state.weapon, state.total, state.clip)
        LAST_SYNC.total = state.total
        LAST_SYNC.clip = state.clip
    end
end

local function removeActiveWeapon(saveState)
    if not ACTIVE then return end
    if saveState then pushAmmoState(true) end

    local ped = PlayerPedId()
    local hash = joaat(ACTIVE.weapon)
    SetCurrentPedWeapon(ped, UNARMED_HASH, true)
    RemoveWeaponFromPed(ped, hash)
    TriggerEvent("vrp:unregisterInventoryWeapon", ACTIVE.weapon)

    ACTIVE = nil
    AMMO_BOOTSTRAP = nil
    EQUIP_SERIAL = EQUIP_SERIAL + 1
    LAST_SYNC.total = -1
    LAST_SYNC.clip = -1
    hideWeaponHud()
end

local function equipWeapon(data)
    local ped = PlayerPedId()

    if ACTIVE and ACTIVE.weapon ~= data.weapon then
        local oldHash = joaat(ACTIVE.weapon)
        SetCurrentPedWeapon(ped, UNARMED_HASH, true)
        RemoveWeaponFromPed(ped, oldHash)
        TriggerEvent("vrp:unregisterInventoryWeapon", ACTIVE.weapon)
    end

    local hash = joaat(data.weapon)
    local total = math.max(0, tonumber(data.total) or 0)
    local clip = math.max(0, math.min(total, tonumber(data.clip) or 0))

    -- Registra a arma no controle legal da vRP antes de criar a entidade nativa.
    -- Isso evita o falso warning "weapon ... is not registered" do player_state.
    TriggerEvent("vrp:registerInventoryWeapon", data.weapon, total)

    -- Remove first to make the restored clip/reserve deterministic. GTA can
    -- return a temporary 0-in-clip value if SetAmmoInClip runs before the
    -- weapon becomes current, so select it first and then restore its ammo.
    RemoveWeaponFromPed(ped, hash)
    GiveWeaponToPed(ped, hash, total, false, false)
    SetCurrentPedWeapon(ped, hash, true)
    SetPedAmmo(ped, hash, total)
    if total > 0 then
        SetAmmoInClip(ped, hash, clip)
    end

    ACTIVE = {
        slot = tostring(data.slot),
        weapon = data.weapon,
        item = data.item,
        png = data.png or data.item
    }
    LAST_SYNC.total = total
    LAST_SYNC.clip = clip
    startAmmoBootstrap(total, clip)
end

local function applyRecharge(data)
    if not ACTIVE or ACTIVE.weapon ~= data.weapon then return end

    local ped = PlayerPedId()
    local hash = joaat(data.weapon)
    local total = math.max(0, tonumber(data.total) or 0)
    local clip = math.max(0, math.min(total, tonumber(data.clip) or 0))

    SetCurrentPedWeapon(ped, hash, true)
    SetPedAmmo(ped, hash, total)
    if total > 0 then
        SetAmmoInClip(ped, hash, clip)
    end

    LAST_SYNC.total = total
    LAST_SYNC.clip = clip
    startAmmoBootstrap(total, clip)
end

local function sendHotbarFeedback(hotbar)
    if not hotbar then return end

    local current = getCurrentState()
    if current then
        hotbar.active_ammo = {
            total = current.total,
            clip = current.clip,
            reserve = current.reserve
        }
    end

    SendNUIMessage({
        route = TAB_HOTBAR_HELD and "SHOW_QUICK_HOTBAR_HOLD" or "SHOW_QUICK_HOTBAR",
        payload = hotbar
    })
end

local function showHeldHotbar()
    local hotbar = Remote.getHotbarSnapshot()
    if not hotbar then return end

    local current = getCurrentState()
    if current then
        hotbar.active_slot = tonumber(current.slot) or hotbar.active_slot
        hotbar.active_weapon = current.weapon
        hotbar.active_ammo = {
            total = current.total,
            clip = current.clip,
            reserve = current.reserve
        }
    end

    SendNUIMessage({
        route = "SHOW_QUICK_HOTBAR_HOLD",
        payload = hotbar
    })
end

local function hideHeldHotbar()
    SendNUIMessage({
        route = "HIDE_QUICK_HOTBAR"
    })
end

local function applyResponse(response, showFeedback)
    if not response then return false end
    if response.error then
        TriggerEvent("Notify", "negado", response.error)
        if showFeedback and response.hotbar then sendHotbarFeedback(response.hotbar) end
        return response
    end

    if response.action == "equip" then
        equipWeapon(response)
    elseif response.action == "holster" then
        removeActiveWeapon(false)
    elseif response.action == "recharge" then
        applyRecharge(response)
    end

    if showFeedback and response.hotbar then
        sendHotbarFeedback(response.hotbar)
    end

    return response
end

function UseInventoryHotbarSlot(slot, showFeedback, requestedAmount)
    slot = tostring(slot)
    local response = Remote.hotbarUseSlot(slot, requestedAmount or 0)
    if not response then return false end

    if response.action == "regular" then
        local used = Remote.useItem(slot, 1)
        local hotbar = Remote.getHotbarSnapshot()
        if showFeedback then sendHotbarFeedback(hotbar) end
        return used
    end

    return applyResponse(response, showFeedback)
end

-- Called by server compatibility paths (e.g. old /garmas / weapon panel).
function API.hotbarForceHolster(slot, weapon)
    if not ACTIVE then return nil end
    if slot and tostring(ACTIVE.slot) ~= tostring(slot) then return nil end
    if weapon and ACTIVE.weapon ~= weapon then return nil end

    local state = getCurrentState()
    removeActiveWeapon(false)
    return state
end

function API.getHotbarWeaponState()
    return getCurrentState()
end

function API.applyHotbarServerAction(response, showFeedback)
    return applyResponse(response, showFeedback == true)
end

CreateThread(function()
    for i = 1, 5 do
        RegisterCommand("hotkey_" .. i, function()
            if IsNuiFocused() then return end
            if GetGameTimer() - HOTKEY_COOLDOWN < 250 then return end
            if LocalPlayer.state.pvp then return end
            if GetEntityHealth(PlayerPedId()) <= 101 then return end
            if vRP.isHandcuffed() then return end

            HOTKEY_COOLDOWN = GetGameTimer()
            UseInventoryHotbarSlot(i, true, 0)
        end, false)

        RegisterKeyMapping("hotkey_" .. i, "Usar slot rápido " .. i, "keyboard", tostring(i))
    end
end)

-- Completely suppress GTA's native weapon wheel and direct native weapon slots.
-- TAB is repurposed: while it is held, the custom inventory hotbar stays on
-- screen. Releasing TAB hides it using the NUI fade animation.
CreateThread(function()
    while true do
        DisableControlAction(0, 37, true)  -- TAB / weapon wheel
        DisableControlAction(1, 37, true)
        DisableControlAction(2, 37, true)
        DisableControlAction(0, 14, true)  -- wheel next
        DisableControlAction(0, 15, true)  -- wheel previous
        DisableControlAction(0, 16, true)  -- next weapon
        DisableControlAction(0, 17, true)  -- previous weapon

        -- GTA native weapon category keys 1..9.
        for control = 157, 165 do
            DisableControlAction(0, control, true)
            DisableControlAction(1, control, true)
            DisableControlAction(2, control, true)
        end

        -- Prevent the radial HUD itself from being rendered, even if another
        -- script briefly enables a selection control in the same frame.
        HideHudComponentThisFrame(19) -- native weapon wheel
        HideHudComponentThisFrame(20) -- native weapon wheel stats
        HideHudComponentThisFrame(2)  -- native weapon icon
        HideHudComponentThisFrame(22) -- native weapon/ammo HUD

        -- Because control 37 is disabled above, IsDisabledControlPressed is
        -- the correct native for detecting the physical TAB key.
        local tabPressed = IsDisabledControlPressed(0, 37)
            or IsDisabledControlPressed(1, 37)
            or IsDisabledControlPressed(2, 37)

        local canShow = not IsNuiFocused()
            and not LocalPlayer.state.pvp
            and GetEntityHealth(PlayerPedId()) > 101

        if tabPressed and canShow then
            if not TAB_HOTBAR_HELD then
                TAB_HOTBAR_HELD = true
                showHeldHotbar()
            end
        elseif TAB_HOTBAR_HELD then
            TAB_HOTBAR_HELD = false
            hideHeldHotbar()
        end

        Wait(0)
    end
end)

-- Keep the custom ammo HUD visually real-time without spamming the server.
-- NUI only receives a message when clip/reserve actually changes.
CreateThread(function()
    while true do
        if ACTIVE then
            updateWeaponHud(false)
            Wait(75)
        else
            Wait(400)
        end
    end
end)

-- Capture both clip and reserve while firing/reloading. This is intentionally
-- throttled; DB writes are additionally batched server-side.
CreateThread(function()
    while true do
        if ACTIVE then
            local state = getCurrentState()
            if state and not state.present then
                -- Respect disarm/death/model-reset systems from other resources.
                -- The ammo snapshot is preserved and the logical hotbar state is
                -- closed instead of silently recreating the weapon.
                Remote._clientHolsterHotbar(state.slot, state.weapon, state.total, state.clip)
                removeActiveWeapon(false)
            else
                pushAmmoState(false)
            end
        end
        Wait(1000)
    end
end)

-- Death must never leave a hotbar weapon logically active.
CreateThread(function()
    local wasDead = false
    while true do
        local dead = GetEntityHealth(PlayerPedId()) <= 101
        if dead and not wasDead and ACTIVE then
            local state = getCurrentState()
            if state then
                Remote._clientHolsterHotbar(state.slot, state.weapon, state.total, state.clip)
            end
            removeActiveWeapon(false)
        end
        wasDead = dead
        Wait(500)
    end
end)

AddEventHandler("onClientResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if ACTIVE then
        local state = getCurrentState()
        if state then
            Remote._clientHolsterHotbar(state.slot, state.weapon, state.total, state.clip)
        end
        removeActiveWeapon(false)
    end
end)
