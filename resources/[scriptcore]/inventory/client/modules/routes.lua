local ts = tostring
local tn = tonumber
local PENDING_CB <const> = {}
local COOLDOWN = GetGameTimer()

Routes = {
    ---@see UI

    ["CLOSE_INVENTORY"] = function(data)
        if data.right then 
            Remote._emitCloseListeners()
        end

        -- Garante que módulos que mantêm estado de abertura (como Shops)
        -- sejam avisados quando o fechamento veio da própria interface.
        TriggerEvent("inventory:shops:nuiClosed")
        SetNuiFocus(false, false)
    end,

    ["PLAY_SOUND"] = function(data)
        if data.sound == 'success' then
            PlaySound(-1, "CLICK_BACK", "WEB_NAVIGATION_SOUNDS_PHONE", 0, 0, 1)
        elseif data.sound == 'error' then
            PlaySound(-1, "Place_Prop_Fail", "DLC_Dmod_Prop_Editor_Sounds", 0, 0, 1)
        end
    end,

    ---@see Shop
    ["SHOP_ACTION"] = function(data)
        ---@return boolean | table
        return Remote.shopAction(data.store_name, data.item, data.amount, data.slot)
    end,
    ["TAKE_CHEST_ITEM"] = function(data)
        ---@return boolean | table
        return Remote.takeChestItem(data.item, data.amount,ts(data.slot))
    end,
    ["STORE_CHEST_ITEM"] = function(data)
        ---@return boolean
        return Remote.storeChestItem(ts(data.slot), data.amount)
    end,


    ---@see User Inventory
    ["GET_WEAPONS"] = function()
        ---@return table<string, number> | false
        return vRP.getWeapons()
    end,
    ["GET_HOTBAR_SNAPSHOT"] = function()
        local snapshot = Remote.getHotbarSnapshot() or { slots = {} }

        -- The server owns the persisted values for every weapon. For the one
        -- currently equipped, prefer the ped's live state so the inventory
        -- always opens with an exact clip/reserve count.
        if API.getHotbarWeaponState then
            local state = API.getHotbarWeaponState()
            local slot = state and tonumber(state.slot) or nil
            if state and slot and snapshot.slots and snapshot.slots[slot] then
                snapshot.active_slot = slot
                snapshot.active_weapon = state.weapon
                snapshot.slots[slot].equipped = true
                snapshot.slots[slot].weapon = state.weapon
                snapshot.slots[slot].ammo = {
                    clip = math.max(0, tonumber(state.clip) or 0),
                    reserve = math.max(0, tonumber(state.reserve) or 0),
                    total = math.max(0, tonumber(state.total) or 0)
                }
            end
        end

        return snapshot
    end,
    ["MANAGE_WEAPONS"] = function(data)
        ---@return table<string, string | boolean>
        if (COOLDOWN - GetGameTimer()) > 0 then return end
        COOLDOWN = (GetGameTimer() + 3000)

        return Remote.storeWeapons(data.weapons)
    end,
    ["GET_INVENTORY"] = function(data)
        ---@return table<string, table | number> | false
        
        local params = Remote.getInventory()

        params.profile = Remote.getProfile()

        print(json.encode(params, { indent = true }))

        return params
    end,
    ["GET_PICKUPS"] = function(data)
        ---@return table<string, table | number> | false
        --[[
            {
                weight: number, 
                max_weight: number,
                inventory: {
                    [slot: string]: {
                        item: string,
                        amount: number,
                    },
                }
            }
            ]]
        local ply = PlayerPedId()
        local plyCds = GetEntityCoords(ply)
        local pickupsFormatted = {}
        local count = 0
        for k,v in pairs(PICKUPS) do
            local distance = #(plyCds - v.coords)
            if distance < 7.0 then
                count += 1
                pickupsFormatted[tostring(count)] = {
                    item = v.item,
                    amount = v.amount,
                    id = k
                }
            end
        end
        return {
            weight = '-',
            max_weight = '-',
            inventory = pickupsFormatted
        }
    end,

    ["REQUEST_USER_WEIGHT"] = function(data)
        ---@return table<string, number> | false 
        --[[
            {
                weight: number,
            }
        ]]
        return Remote.getWeight()
    end,

    ["SWAP_SLOT"] = function(data)
        ---@return boolean | nil
        return Remote.swapSlot(
            ts(data.from_slot), -- slot inicial
            tn(data.from_amount), -- quantidade à ser movida
            ts(data.to_slot) -- slot alvo!
        )
    end,

    ["SEND_ITEM"] = function(data)
        ---@return boolean | table
        return Remote.sendItem(
            ts(data.slot), -- slot inicial
            tn(data.amount) -- quantidade à ser usada
        )
    end,
    
    ["USE_ITEM"] = function(data)
        ---@return boolean | nil

        return Remote.useItem(
            ts(data.slot), -- slot inicial
            tn(data.amount) -- quantidade à ser usada
        )
    end,

    ["HOTBAR_USE_SLOT"] = function(data)
        if not UseInventoryHotbarSlot then
            return { error = "Sistema de atalhos indisponível." }
        end

        return UseInventoryHotbarSlot(
            ts(data.slot),
            false,
            tn(data.amount) or 0
        )
    end,

    ["TAKE_PICKUP"] = function(data)
        ---@return boolean | nil
        return Remote.getPickup(
            tn(data.id), -- slot inicial
            tn(data.amount), -- quantidade à ser pega
            ts(data.slot) -- quantidade à ser pega
        )
    end,

    ["DROP_ITEM"] = function(data)
        ---@return boolean | nil
        return Remote.dropItem(
            ts(data.slot), -- slot inicial
            tn(data.amount) -- quantidade à ser usada
        )
    end,


    ["REQUEST_PICKUPS_NEAR"] = function()
        return API.getPickups()
    end,

    ---@see Inspect

    ["TAKE_INSPECT_ITEM"] = function(data)
        --[[ data.slot => Slot do item a ser roubado ]]
        ---@return boolean
        return Remote.takeInspectItem(ts(data.from_slot), ts(data.to_slot), tn(data.amount))
    end,

    ["PUT_INSPECT_ITEM"] = function(data)
        --[[ data.slot => Slot do item a ser roubado ]]
        ---@return boolean
        return Remote.putInspectItem(ts(data.from_slot), ts(data.to_slot), tn(data.amount))
    end,


    ---@see Config
    ["REQUEST_ITEMS_CONFIG"] = function(data)
        local config = Items 
        for k,v in pairs(config) do 
            if v.func then 
                config[k].func = nil
            end
        end
        ---@return table<string, table>
        return config
    end,


}


local NoWait = {
    ["USE_ITEM"] = true,
    ["HOTBAR_USE_SLOT"] = true,
    ["GET_HOTBAR_SNAPSHOT"] = true
}
CreateThread(function()
    for k,v in pairs(Routes) do
        RegisterNUICallback(k, function(data, cb)
            if not PENDING_CB[k] or NoWait[k] then 
                PENDING_CB[k] = true
                local result = v(data)
                PENDING_CB[k] = nil
                if cb then
                    cb(result)
                end
            else 
                error("Callback "..k.." is already pending!")
                cb(false)
            end
        end)
    end
end)