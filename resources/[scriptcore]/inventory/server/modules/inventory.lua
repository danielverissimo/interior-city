local ts <const> = tostring
local tn <const> = tonumber


local imagesProfile = imagesProfile or {}

local function isEventWeaponAllowed(source)
    source = tonumber(source)
    if not source then return false end

    -- O m_eventos roda eventos em routing bucket próprio. Liberamos a troca
    -- de armas somente quando o próprio m_eventos marca explicitamente o
    -- jogador como autorizado. Isso não altera as demais regras do inventory.
    local player = Player(source)
    if player and player.state then
        if player.state.m_eventosAllowEventWeapons == true or player.state.m_eventosBattleRoyale == true then
            return true
        end
    end

    -- Fallback server-side para a pequena janela em que a state bag possa
    -- ainda estar sincronizando depois de teleporte/respawn/troca de bucket.
    if GetResourceState('m_eventos') == 'started' then
        local ok, allowed = pcall(function()
            return exports['m_eventos']:CanUseEventWeapons(source)
        end)
        if ok and allowed == true then
            return true
        end
    end

    return false
end

WeaponsTypes = {
    ["WEAPON_SNSPISTOL_MK2"] = "PISTOLAS",
    ["WEAPON_PISTOL_MK2"] = "PISTOLAS",
    ["WEAPON_PISTOL"] = "PISTOLAS",
    ["WEAPON_COMBATPISTOL"] = "PISTOLAS",
    ["WEAPON_DOUBLEACTION"] = "PISTOLAS",
	["WEAPON_HEAVYPISTOL"] = "PISTOLAS",
	["WEAPON_APPISTOL"] = "PISTOLAS",
    ["WEAPON_PISTOL50"] = "PISTOLAS",
    ["WEAPON_GUSENBERG"] = "SEMI-RIFLE",
    ["WEAPON_MACHINEPISTOL"] = "SEMI-RIFLE",
    ["WEAPON_SMG_MK2"] = "SEMI-RIFLE",
    ["WEAPON_SMG"] = "SEMI-RIFLE",
    ["WEAPON_MICROSMG"] = "SEMI-RIFLE",
    ["WEAPON_ASSAULTSMG"] = "SEMI-RIFLE",
	["WEAPON_COMBATPDW"] = "SEMI-RIFLE",
    ["WEAPON_SAWNOFFSHOTGUN"] = "SHOTGUN",
    ["WEAPON_PUMPSHOTGUN_MK2"] = "SHOTGUN",
    ["WEAPON_PUMPSHOTGUN"] = "SHOTGUN",
    ["WEAPON_MILITARYRIFLE"] = "RIFLE",
    ["WEAPON_ASSAULTRIFLE"] = "RIFLE",
    ["WEAPON_ASSAULTRIFLE_MK2"] = "RIFLE",
    ["WEAPON_PARAFAL"] = "RIFLE",


    ["WEAPON_TACTICALRIFLE"] = "RIFLE",
    ["WEAPON_BULLPUPRIFLE"] = "RIFLE",
    ["WEAPON_ADVANCEDRIFLE"] = "RIFLE",
    ["WEAPON_SPECIALCARBINE_MK2"] = "RIFLE",
    ["WEAPON_HEAVYRIFLE"] = "RIFLE",

    ["WEAPON_CARBINERIFLE"] = "RIFLE",
    ["WEAPON_CARBINERIFLE_MK2"] = "RIFLE",
    ["WEAPON_SPECIALCARBINE"] = "RIFLE",
    ["WEAPON_STUNGUN"] = "STUNGUN",
    ["WEAPON_HEAVYSNIPER"] = "SNIPER",

}

-- GTA_STANDARD_WEAPON_TYPES_BEGIN
-- Completa as categorias usadas pelos caminhos legados do inventário.
WeaponsTypes["WEAPON_PISTOL"] = WeaponsTypes["WEAPON_PISTOL"] or "PISTOLAS"
WeaponsTypes["WEAPON_PISTOL_MK2"] = WeaponsTypes["WEAPON_PISTOL_MK2"] or "PISTOLAS"
WeaponsTypes["WEAPON_COMBATPISTOL"] = WeaponsTypes["WEAPON_COMBATPISTOL"] or "PISTOLAS"
WeaponsTypes["WEAPON_APPISTOL"] = WeaponsTypes["WEAPON_APPISTOL"] or "PISTOLAS"
WeaponsTypes["WEAPON_PISTOL50"] = WeaponsTypes["WEAPON_PISTOL50"] or "PISTOLAS"
WeaponsTypes["WEAPON_SNSPISTOL"] = WeaponsTypes["WEAPON_SNSPISTOL"] or "PISTOLAS"
WeaponsTypes["WEAPON_SNSPISTOL_MK2"] = WeaponsTypes["WEAPON_SNSPISTOL_MK2"] or "PISTOLAS"
WeaponsTypes["WEAPON_HEAVYPISTOL"] = WeaponsTypes["WEAPON_HEAVYPISTOL"] or "PISTOLAS"
WeaponsTypes["WEAPON_VINTAGEPISTOL"] = WeaponsTypes["WEAPON_VINTAGEPISTOL"] or "PISTOLAS"
WeaponsTypes["WEAPON_FLAREGUN"] = WeaponsTypes["WEAPON_FLAREGUN"] or "PISTOLAS"
WeaponsTypes["WEAPON_MARKSMANPISTOL"] = WeaponsTypes["WEAPON_MARKSMANPISTOL"] or "PISTOLAS"
WeaponsTypes["WEAPON_REVOLVER"] = WeaponsTypes["WEAPON_REVOLVER"] or "PISTOLAS"
WeaponsTypes["WEAPON_REVOLVER_MK2"] = WeaponsTypes["WEAPON_REVOLVER_MK2"] or "PISTOLAS"
WeaponsTypes["WEAPON_DOUBLEACTION"] = WeaponsTypes["WEAPON_DOUBLEACTION"] or "PISTOLAS"
WeaponsTypes["WEAPON_RAYPISTOL"] = WeaponsTypes["WEAPON_RAYPISTOL"] or "PISTOLAS"
WeaponsTypes["WEAPON_CERAMICPISTOL"] = WeaponsTypes["WEAPON_CERAMICPISTOL"] or "PISTOLAS"
WeaponsTypes["WEAPON_NAVYREVOLVER"] = WeaponsTypes["WEAPON_NAVYREVOLVER"] or "PISTOLAS"
WeaponsTypes["WEAPON_GADGETPISTOL"] = WeaponsTypes["WEAPON_GADGETPISTOL"] or "PISTOLAS"
WeaponsTypes["WEAPON_PISTOLXM3"] = WeaponsTypes["WEAPON_PISTOLXM3"] or "PISTOLAS"
WeaponsTypes["WEAPON_STUNGUN"] = WeaponsTypes["WEAPON_STUNGUN"] or "STUNGUN"
WeaponsTypes["WEAPON_STUNGUN_MP"] = WeaponsTypes["WEAPON_STUNGUN_MP"] or "STUNGUN"
WeaponsTypes["WEAPON_MICROSMG"] = WeaponsTypes["WEAPON_MICROSMG"] or "SEMI-RIFLE"
WeaponsTypes["WEAPON_SMG"] = WeaponsTypes["WEAPON_SMG"] or "SEMI-RIFLE"
WeaponsTypes["WEAPON_SMG_MK2"] = WeaponsTypes["WEAPON_SMG_MK2"] or "SEMI-RIFLE"
WeaponsTypes["WEAPON_ASSAULTSMG"] = WeaponsTypes["WEAPON_ASSAULTSMG"] or "SEMI-RIFLE"
WeaponsTypes["WEAPON_COMBATPDW"] = WeaponsTypes["WEAPON_COMBATPDW"] or "SEMI-RIFLE"
WeaponsTypes["WEAPON_MACHINEPISTOL"] = WeaponsTypes["WEAPON_MACHINEPISTOL"] or "SEMI-RIFLE"
WeaponsTypes["WEAPON_MINISMG"] = WeaponsTypes["WEAPON_MINISMG"] or "SEMI-RIFLE"
WeaponsTypes["WEAPON_RAYCARBINE"] = WeaponsTypes["WEAPON_RAYCARBINE"] or "SEMI-RIFLE"
WeaponsTypes["WEAPON_TECPISTOL"] = WeaponsTypes["WEAPON_TECPISTOL"] or "SEMI-RIFLE"
WeaponsTypes["WEAPON_MG"] = WeaponsTypes["WEAPON_MG"] or "SEMI-RIFLE"
WeaponsTypes["WEAPON_COMBATMG"] = WeaponsTypes["WEAPON_COMBATMG"] or "SEMI-RIFLE"
WeaponsTypes["WEAPON_COMBATMG_MK2"] = WeaponsTypes["WEAPON_COMBATMG_MK2"] or "SEMI-RIFLE"
WeaponsTypes["WEAPON_GUSENBERG"] = WeaponsTypes["WEAPON_GUSENBERG"] or "SEMI-RIFLE"
WeaponsTypes["WEAPON_ASSAULTRIFLE"] = WeaponsTypes["WEAPON_ASSAULTRIFLE"] or "RIFLE"
WeaponsTypes["WEAPON_ASSAULTRIFLE_MK2"] = WeaponsTypes["WEAPON_ASSAULTRIFLE_MK2"] or "RIFLE"
WeaponsTypes["WEAPON_CARBINERIFLE"] = WeaponsTypes["WEAPON_CARBINERIFLE"] or "RIFLE"
WeaponsTypes["WEAPON_CARBINERIFLE_MK2"] = WeaponsTypes["WEAPON_CARBINERIFLE_MK2"] or "RIFLE"
WeaponsTypes["WEAPON_ADVANCEDRIFLE"] = WeaponsTypes["WEAPON_ADVANCEDRIFLE"] or "RIFLE"
WeaponsTypes["WEAPON_SPECIALCARBINE"] = WeaponsTypes["WEAPON_SPECIALCARBINE"] or "RIFLE"
WeaponsTypes["WEAPON_SPECIALCARBINE_MK2"] = WeaponsTypes["WEAPON_SPECIALCARBINE_MK2"] or "RIFLE"
WeaponsTypes["WEAPON_BULLPUPRIFLE"] = WeaponsTypes["WEAPON_BULLPUPRIFLE"] or "RIFLE"
WeaponsTypes["WEAPON_BULLPUPRIFLE_MK2"] = WeaponsTypes["WEAPON_BULLPUPRIFLE_MK2"] or "RIFLE"
WeaponsTypes["WEAPON_COMPACTRIFLE"] = WeaponsTypes["WEAPON_COMPACTRIFLE"] or "RIFLE"
WeaponsTypes["WEAPON_MILITARYRIFLE"] = WeaponsTypes["WEAPON_MILITARYRIFLE"] or "RIFLE"
WeaponsTypes["WEAPON_HEAVYRIFLE"] = WeaponsTypes["WEAPON_HEAVYRIFLE"] or "RIFLE"
WeaponsTypes["WEAPON_TACTICALRIFLE"] = WeaponsTypes["WEAPON_TACTICALRIFLE"] or "RIFLE"
WeaponsTypes["WEAPON_BATTLERIFLE"] = WeaponsTypes["WEAPON_BATTLERIFLE"] or "RIFLE"
WeaponsTypes["WEAPON_SNIPERRIFLE"] = WeaponsTypes["WEAPON_SNIPERRIFLE"] or "SNIPER"
WeaponsTypes["WEAPON_HEAVYSNIPER"] = WeaponsTypes["WEAPON_HEAVYSNIPER"] or "SNIPER"
WeaponsTypes["WEAPON_HEAVYSNIPER_MK2"] = WeaponsTypes["WEAPON_HEAVYSNIPER_MK2"] or "SNIPER"
WeaponsTypes["WEAPON_MARKSMANRIFLE"] = WeaponsTypes["WEAPON_MARKSMANRIFLE"] or "SNIPER"
WeaponsTypes["WEAPON_MARKSMANRIFLE_MK2"] = WeaponsTypes["WEAPON_MARKSMANRIFLE_MK2"] or "SNIPER"
WeaponsTypes["WEAPON_PRECISIONRIFLE"] = WeaponsTypes["WEAPON_PRECISIONRIFLE"] or "SNIPER"
WeaponsTypes["WEAPON_REMOTESNIPER"] = WeaponsTypes["WEAPON_REMOTESNIPER"] or "SNIPER"
WeaponsTypes["WEAPON_PUMPSHOTGUN"] = WeaponsTypes["WEAPON_PUMPSHOTGUN"] or "SHOTGUN"
WeaponsTypes["WEAPON_PUMPSHOTGUN_MK2"] = WeaponsTypes["WEAPON_PUMPSHOTGUN_MK2"] or "SHOTGUN"
WeaponsTypes["WEAPON_SAWNOFFSHOTGUN"] = WeaponsTypes["WEAPON_SAWNOFFSHOTGUN"] or "SHOTGUN"
WeaponsTypes["WEAPON_BULLPUPSHOTGUN"] = WeaponsTypes["WEAPON_BULLPUPSHOTGUN"] or "SHOTGUN"
WeaponsTypes["WEAPON_ASSAULTSHOTGUN"] = WeaponsTypes["WEAPON_ASSAULTSHOTGUN"] or "SHOTGUN"
WeaponsTypes["WEAPON_MUSKET"] = WeaponsTypes["WEAPON_MUSKET"] or "SHOTGUN"
WeaponsTypes["WEAPON_HEAVYSHOTGUN"] = WeaponsTypes["WEAPON_HEAVYSHOTGUN"] or "SHOTGUN"
WeaponsTypes["WEAPON_DBSHOTGUN"] = WeaponsTypes["WEAPON_DBSHOTGUN"] or "SHOTGUN"
WeaponsTypes["WEAPON_AUTOSHOTGUN"] = WeaponsTypes["WEAPON_AUTOSHOTGUN"] or "SHOTGUN"
WeaponsTypes["WEAPON_COMBATSHOTGUN"] = WeaponsTypes["WEAPON_COMBATSHOTGUN"] or "SHOTGUN"
WeaponsTypes["WEAPON_GRENADELAUNCHER"] = WeaponsTypes["WEAPON_GRENADELAUNCHER"] or "HEAVY"
WeaponsTypes["WEAPON_GRENADELAUNCHER_SMOKE"] = WeaponsTypes["WEAPON_GRENADELAUNCHER_SMOKE"] or "HEAVY"
WeaponsTypes["WEAPON_RPG"] = WeaponsTypes["WEAPON_RPG"] or "HEAVY"
WeaponsTypes["WEAPON_MINIGUN"] = WeaponsTypes["WEAPON_MINIGUN"] or "HEAVY"
WeaponsTypes["WEAPON_FIREWORK"] = WeaponsTypes["WEAPON_FIREWORK"] or "HEAVY"
WeaponsTypes["WEAPON_RAILGUN"] = WeaponsTypes["WEAPON_RAILGUN"] or "HEAVY"
WeaponsTypes["WEAPON_RAILGUNXM3"] = WeaponsTypes["WEAPON_RAILGUNXM3"] or "HEAVY"
WeaponsTypes["WEAPON_HOMINGLAUNCHER"] = WeaponsTypes["WEAPON_HOMINGLAUNCHER"] or "HEAVY"
WeaponsTypes["WEAPON_COMPACTLAUNCHER"] = WeaponsTypes["WEAPON_COMPACTLAUNCHER"] or "HEAVY"
WeaponsTypes["WEAPON_RAYMINIGUN"] = WeaponsTypes["WEAPON_RAYMINIGUN"] or "HEAVY"
WeaponsTypes["WEAPON_EMPLAUNCHER"] = WeaponsTypes["WEAPON_EMPLAUNCHER"] or "HEAVY"
WeaponsTypes["WEAPON_SNOWLAUNCHER"] = WeaponsTypes["WEAPON_SNOWLAUNCHER"] or "HEAVY"
WeaponsTypes["WEAPON_STINGER"] = WeaponsTypes["WEAPON_STINGER"] or "HEAVY"
-- GTA_STANDARD_WEAPON_TYPES_END

local function hasAmmoType(to_equip_weapon, weapon_list)
    local to_equip_type = WeaponsTypes[to_equip_weapon]
    if not to_equip_type then return false end
    for k, v in pairs(weapon_list) do
        if WeaponsTypes[k] and WeaponsTypes[k] == to_equip_type then
            return true
        end
    end
    return false
end

---@return table<string, table | number> | false
function API.getInventory()
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        return {
            weight = vRP.computeInvWeight(user_id),
            max_weight = vRP.getInventoryMaxWeight(user_id),
            inventory = vRP.getInventory(user_id),
        }
    end
    return false
end

AddEventHandler("vRP:playerSpawn", function(user_id, source, first_spawn)
	if (not user_id) then return end
	if (imagesProfile[tostring(user_id)]) then return end

	local query = exports["oxmysql"]:executeSync('SELECT avatarURL from smartphone_instagram WHERE user_id = ? ', { user_id })
	if (not query[1]) then return end

	imagesProfile[tostring(user_id)] = query[1].avatarURL
end)

local vipGroups = {
	'Inicial',
	'Bronze',
	'Prata',
	'Ouro',
	'Platina',
	'Diamante',
	'Safira',
	'Esmeralda',
	'Rubi',
	'RubiPlus',
	'Realidade',
	'Pascoa',
	'VipHalloween',
	'VipDeluxe',
	'VipInauguracao',
	'Ferias',
	'VipSaoJoao',
	'VipCrianca',
	'VipBlackfriday',
	'VipInicial',
	'VipSetembro',
	"VipNatal",
	"Vip2025",
	"VipAnoNovo",
	"VipCarnaval",
	"VipMaio",
	"VipReal",
	"Olimpiada",
	'Belarj',
	'Supremorj',
	'vipwipe',
	'VipVerao',
	'VipSaoJoao',
	'VipOutono',
}


local function getUserName(userId)
    local identity = vRP.getUserIdentity(userId)
    if identity then
        if identity.nome and identity.sobrenome then
            return identity.nome .. ' ' .. identity.sobrenome
        end
        return identity.nome
    end
    return ''
end

-- O campo "Emprego" do inventário representa a organização (org) atual do jogador.
-- A normalização abaixo mantém compatibilidade caso a base retorne somente o nome
-- da org ou uma estrutura com metadados.
local function getUserJob(userId)
    local ok, org = pcall(function()
        return vRP.getUserGroupOrg(userId)
    end)

    if not ok or org == nil then
        return 'Desempregado'
    end

    if type(org) == 'string' then
        if org ~= '' and org ~= 'nil' then
            return org
        end
        return 'Desempregado'
    end

    if type(org) == 'table' then
        local name = org.orgName or org.name or org.group or org.groupId or org.id
        if name ~= nil and tostring(name) ~= '' then
            return tostring(name)
        end
    end

    return 'Desempregado'
end

function API.getProfile()
    local source = source
    local user_id = vRP.getUserId(source)

    local currentVips = {}

    for k, v in pairs(vipGroups) do
        if (vRP.hasGroup(user_id, v)) then
            if v == 'VipWipe' then
                currentVips[#currentVips + 1] = 'VIP INAUGURAÇÃO'
            else
                currentVips[#currentVips + 1] = v
            end
        end
    end

    if user_id then
        if not imagesProfile[tostring(user_id)] then
            local query = exports["oxmysql"]:executeSync(
                'SELECT avatarURL FROM smartphone_instagram WHERE user_id = ?', 
                { user_id }
            )

            if query and query[1] and query[1].avatarURL then
                imagesProfile[tostring(user_id)] = query[1].avatarURL
            else
                imagesProfile[tostring(user_id)] = ""
            end
        end
        return {
            id = user_id,
            job = getUserJob(user_id),
            isVip = next(currentVips) and true or false,
            name = getUserName(user_id),
            image_url = imagesProfile[tostring(user_id)],
        }
    end
end

---@return table<string, number> | false
function API.getWeight()
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        return {
            weight = vRP.computeInvWeight(user_id),
        }
    end
    return false
end

---@param from_slot string
---@param from_amount number
---@param to_slot string
---@return boolean | nil
function API.swapSlot(from_slot, from_amount, to_slot)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then
        return error("Usuário não encontrado")
    end

    if from_amount < 0 then
        from_amount = 1
        return false
    end
    from_amount = parseInt(from_amount)

    local from_slot_data = vRP.getSlotItem(user_id, from_slot)
    if not from_slot_data then
        return false
    end

    local to_slot_data = vRP.getSlotItem(user_id, to_slot)
    from_amount = tn(from_amount) or from_slot_data.amount
    local fullAmount = ((from_slot_data.amount and from_slot_data.amount == from_amount) and true or false)

    local fromQuick = tonumber(from_slot) and tonumber(from_slot) >= 1 and tonumber(from_slot) <= 5
    local toQuick = tonumber(to_slot) and tonumber(to_slot) >= 1 and tonumber(to_slot) <= 5

    local fromDuty = HotbarWeapons and HotbarWeapons.IsDutyWeaponSlot(user_id, from_slot, from_slot_data.item) or false
    local toDuty = HotbarWeapons and to_slot_data and HotbarWeapons.IsDutyWeaponSlot(user_id, to_slot, to_slot_data.item) or false

    -- A temporary service weapon may be reorganized inside the quick bar, but
    -- it can never leave slots 1..5 (including through a reverse swap).
    if (fromDuty and not toQuick) or (toDuty and not fromQuick) then
        return { error = "Armas de serviço devem permanecer nos slots 1 a 5." }
    end

    -- Record which hotbar weapon will actually LEAVE slots 1..5 after the move.
    -- The ammo conversion is committed only after the inventory mutation works.
    local leavingSlot = nil
    local leavingItem = nil
    if fromQuick and not toQuick and fullAmount and Items[from_slot_data.item] and Items[from_slot_data.item].type == "equip" then
        leavingSlot = tostring(from_slot)
        leavingItem = from_slot_data.item
    elseif not fromQuick and toQuick and to_slot_data and Items[to_slot_data.item] and Items[to_slot_data.item].type == "equip" then
        leavingSlot = tostring(to_slot)
        leavingItem = to_slot_data.item
    end

    local moved = false
    if not to_slot_data then
        -- Alteração de slot, não há item no slot de destino.
        if from_slot_data.amount then
            if vRP.tryGetInventoryItem(user_id, from_slot_data.item, from_amount, false, from_slot) then
                vRP.giveInventoryItem(user_id, from_slot_data.item, from_amount, false, ts(to_slot))
                moved = true
            end
        end
    else
        local sameItems = from_slot_data.item == to_slot_data.item
        if sameItems then
            if fullAmount then
                if vRP.tryGetInventoryItem(user_id, from_slot_data.item, from_slot_data.amount, false, ts(from_slot)) then
                    vRP.giveInventoryItem(user_id, to_slot_data.item, from_amount, false, ts(to_slot))
                    moved = true
                end
            end
        else
            vRP.swapSlot(user_id, from_slot, to_slot)
            moved = true
        end
    end

    if not moved then
        return false
    end

    -- Keep the persistent temporary-weapon marker attached to the correct
    -- quick slot after a move/swap.
    if HotbarWeapons then
        if fromDuty then
            HotbarWeapons.UpdateDutyWeaponSlot(user_id, from_slot_data.item, to_slot)
        end
        if toDuty then
            HotbarWeapons.UpdateDutyWeaponSlot(user_id, to_slot_data.item, from_slot)
        end
    end

    -- Auditoria somente para armas que entram, saem ou mudam entre os slots 1..5.
    if InventoryAudit then
        local movements = {}
        local function addWeaponMovement(item, oldSlot, newSlot)
            if not item or not Items[item] or Items[item].type ~= "equip" then return end
            local oldN, newN = tonumber(oldSlot), tonumber(newSlot)
            local oldQuick = oldN and oldN >= 1 and oldN <= 5
            local newQuick = newN and newN >= 1 and newN <= 5
            if not oldQuick and not newQuick then return end

            local label = InventoryAudit.ItemLabel(item)
            if not oldQuick and newQuick then
                movements[#movements + 1] = ("**%s** (`%s`) entrou no slot de arma **%s** (origem: slot %s)."):format(label, item, tostring(newSlot), tostring(oldSlot))
            elseif oldQuick and not newQuick then
                movements[#movements + 1] = ("**%s** (`%s`) saiu do slot de arma **%s** para o slot %s."):format(label, item, tostring(oldSlot), tostring(newSlot))
            elseif tostring(oldSlot) ~= tostring(newSlot) then
                movements[#movements + 1] = ("**%s** (`%s`) mudou do slot de arma **%s** para o **%s**."):format(label, item, tostring(oldSlot), tostring(newSlot))
            end
        end

        addWeaponMovement(from_slot_data.item, from_slot, to_slot)
        if to_slot_data and to_slot_data.item ~= from_slot_data.item then
            addWeaponMovement(to_slot_data.item, to_slot, from_slot)
        end

        if #movements > 0 then
            InventoryAudit.Log("inventory_weapon_hotbar", {
                actorId = user_id,
                details = table.concat(movements, "\n")
            })
        end
    end

    local ammoRefunded = 0
    local ammoItem = nil

    if HotbarWeapons then
        if leavingSlot and leavingItem then
            local detached = HotbarWeapons.DetachQuickSlotAmmo(source, user_id, leavingSlot, leavingItem)
            if detached and detached.success == false then
                -- This should only happen with a malformed custom weapon config.
                -- The move already succeeded, so surface the problem explicitly
                -- and leave the weapon ammo state untouched rather than deleting it.
                return {
                    success = true,
                    warning = detached.error,
                    hotbar = HotbarWeapons.GetSnapshot(user_id),
                    refresh_inventory = true
                }
            end
            ammoRefunded = detached and detached.refunded or 0
            ammoItem = detached and detached.ammo_item or nil
        else
            -- Moving/switching an active weapon between quick slots should only
            -- holster it; ammo remains attached because the weapon never left 1..5.
            local active = HotbarWeapons.GetActive(user_id)
            if active and (tostring(active.slot) == tostring(from_slot) or tostring(active.slot) == tostring(to_slot)) then
                HotbarWeapons.ForceHolster(source, user_id)
            end
        end
    end

    return {
        success = true,
        hotbar = HotbarWeapons and HotbarWeapons.GetSnapshot(user_id) or nil,
        refresh_inventory = ammoRefunded > 0,
        ammo_refunded = ammoRefunded,
        ammo_item = ammoItem
    }
end

---@param slot string
---@param amount number
---@return boolean | table
function API.sendItem(slot, amount)
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        if HotbarWeapons then
            local active = HotbarWeapons.GetActive(user_id)
            if active and tostring(active.slot) == tostring(slot) then
                HotbarWeapons.ForceHolster(source, user_id)
            end
        end
        local slot_data = vRP.getSlotItem(user_id, slot)
        if slot_data then
            if HotbarWeapons and HotbarWeapons.IsDutyWeaponSlot(user_id, slot, slot_data.item) then
                return { error = "Você não pode enviar uma arma temporária de serviço." }
            end
            local tPlayer = vRPc.getNearestPlayer(source, 3.0)
            if tPlayer then
                local tUserId = vRP.getUserId(tPlayer)
                if tUserId then
                    if not (vRP.computeInvWeight(tUserId) + vRP.getItemWeight(slot_data.item) * amount <= vRP.getInventoryMaxWeight(tUserId)) then
                        return {
                            error = "Jogador sem espaço suficiente!"
                        }
                    end

                    if (slot_data.item):upper() == 'WEAPON_PISTOL' or (slot_data.item):upper() == 'AMMO_PISTOL' then
                        if not vRP.hasPermission(user_id, 'developer.permissao') and not vRP.hasPermission(user_id, 'perm.policiacivil') and not vRP.hasPermission(user_id, 'perm.pf') then
                            TriggerClientEvent("Notify",source,"negado","Você não pode pegar armas ou munições.")
                            return
                        end
                    end
                    if vRP.tryGetInventoryItem(user_id, slot_data.item, amount, ts(slot)) then
                        vRP.giveInventoryItem(tUserId, slot_data.item, amount, true)
                        if InventoryAudit then
                            local itemDetails = InventoryAudit.ItemDetails(slot_data.item, amount)
                            InventoryAudit.Log("inventory_item_sent", {
                                actorId = user_id,
                                targetId = tUserId,
                                details = itemDetails
                            })
                            InventoryAudit.Log("inventory_item_received", {
                                actorId = tUserId,
                                targetId = user_id,
                                details = itemDetails
                            })
                        end
                        vRPc._playAnim(source, true, { { "pickup_object", "putdown_low" } }, false)
                        vRPc._playAnim(tPlayer, true, { { "pickup_object", "putdown_low" } }, false)
                        Remote._sendNuiEvent(tPlayer, {
                            route = "FORCE_UPDATE_INVENTORY",
                        })

                        exports["vrp_admin"]:generateLog({
                            category = "inventario",
                            room = "enviar-item",
                            user_id = user_id,
                            target_id = tUserId,
                            message = ( [[O USER_ID %s ENVIOU O ITEM %s NA QUANTIDADE DE %s PARA O USER_ID %s]] ):format(user_id, slot_data.item, amount, tUserId)
                        })

                        return true
                    end
                end
            else
                return {
                    error = "Ninguém por perto!"
                }
            end
        end
    end
    return {
        error = "Erro desconhecido ao enviar item."
    }
end

function parseWeapons(valids, client)
    local response = {}
    for weapon, data in pairs(valids) do
        response[weapon] = data
        local compare = client[weapon]
        if compare and compare.ammo < data.ammo then
            data.ammo = compare.ammo
        end
    end
    return response
end

function mergeWeapons(user_id, source)
    local valids = vRP.getWeapons(user_id)
    local client = vRPc.getWeapons(source)
    if not client then
        print("Erro no getWeapons, source = " .. source)
    end
    return parseWeapons(valids, client)
end

---@param slot string
---@param amount number
---@return nil | table
function API.useItem(slot, amount)
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        local status, time = exports.vrp:getCooldown(user_id, "inventario")
        if not status then
            return { error = "Aguarde " .. time .. " segundos para usar um item novamente." }
        end
        local slot_data = vRP.getSlotItem(user_id, slot) or false
        if slot_data then
            if Items[slot_data.item] then
                -- Alimentos e bebidas ficam totalmente indisponíveis quando o
                -- sistema global de fome/sede é desligado no Painel ADM. A
                -- checagem acontece ANTES de remover o item do inventário.
                if Items[slot_data.item].needs then
                    local ok, enabled = pcall(function()
                        return exports["vrp"]:areNeedsEnabled()
                    end)
                    if (ok and enabled == false) or (not ok and GlobalState.needsEnabled == false) then
                        return { error = "O sistema de fome e sede está desligado." }
                    end
                end

                if (Items[slot_data.item].type == "equip" or Items[slot_data.item].type == "recharge") and HotbarWeapons then
                    local response = HotbarWeapons.UseSlot(source, user_id, slot, amount)
                    if response and (response.action == "equip" or response.action == "holster" or response.action == "recharge") then
                        pcall(function()
                            Remote._applyHotbarServerAction(source, response, false)
                        end)
                    end
                    return response
                end

                if Items[slot_data.item].func and (Items[slot_data.item].keep_item or vRP.tryGetInventoryItem(user_id, slot_data.item, 1, true, slot)) then
                    local p = promise.new()
                    local slot_data = slot_data
                    Items[slot_data.item].func(user_id, source, slot_data.item, slot, function(cb)
                        if type(cb) == "table" and cb.error then
                            if cb.error and not Items[slot_data.item].keep_item then
                                vRP.giveInventoryItem(user_id, slot_data.item, 1, true, slot)
                            end
                            return p:resolve(cb)
                        end
                        local _slot_data = vRP.getSlotItem(user_id, slot)
                        local usedAmount = 0
                        if Items[slot_data.item].keep_item then
                            usedAmount = 0
                        elseif not _slot_data then
                            usedAmount = tonumber(slot_data.amount) or 1
                        else
                            usedAmount = math.max(0, (tonumber(slot_data.amount) or 0) - (tonumber(_slot_data.amount) or 0))
                        end

                        if InventoryAudit then
                            local details = ("**Item:** %s\n**Spawn:** %s\n**Slot:** %s\n**Quantidade consumida:** %sx"):format(
                                InventoryAudit.ItemLabel(slot_data.item),
                                tostring(slot_data.item),
                                tostring(slot),
                                tostring(usedAmount)
                            )
                            if Items[slot_data.item].keep_item then
                                details = details .. "\n**Observação:** item configurado para permanecer no inventário após o uso."
                            end
                            InventoryAudit.Log("inventory_item_used", {
                                actorId = user_id,
                                details = details
                            })
                        end

                        p:resolve({ used_amount = usedAmount })
                    end)
                    return Citizen.Await(p)
                end
                if Items[slot_data.item].type then
                    if Items[slot_data.item].type == "recharge" then
                        if vRP.hasPermission(user_id, "crianca.permissao") then return end

                        local weapon_name = "WEAPON_" .. slot_data.item:gsub("ammo_", ""):upper();
                        local weapons = mergeWeapons(user_id, source)
                        if weapons[weapon_name] then
                            if weapons[weapon_name].ammo < 250 then
                                local checkamount = 250 - weapons[weapon_name].ammo
                                if amount > checkamount then
                                    amount = checkamount
                                end
                                if vRP.tryGetInventoryItem(user_id, slot_data.item, amount, slot) then
                                    weapons[weapon_name].ammo = weapons[weapon_name].ammo + amount
                                    vRP.setWeapons(user_id, weapons)
                                    vRPc.giveWeapons(source, weapons, true)
                                    exports["vrp_admin"]:generateLog({
                                        category = "inventario",
                                        room = "equipar",
                                        user_id = user_id,
                                        message = ( [[O USER_ID %s RECARREGOU A MUNICAO %s NA QUANTIDADE %s]] ):format(user_id, slot_data.item, amount)
                                    })
                                    return {
                                        used_amount = amount,
                                    }
                                end
                            else
                                return {
                                    error = "Você já está com a munição cheia."
                                }
                            end
                        else
                            return {
                                error = "Você não tem essa arma equipada."
                            }
                        end
                    end

                    if Items[slot_data.item].type == "equip" then
                        if GetPlayerRoutingBucket(source) ~= 0 and not isEventWeaponAllowed(source) then return { error = "Você não pode equipar arma agora." } end

                        if exports.vrp_admin:checkIfUserIsBlacklisted(user_id) then return { error = "Você não pode equipar arma agora." } end

                        local org = vRP.getUserGroupOrg(user_id)
                        if exports.vrp_admin:isOrganizationBlacklisted(org) then return { error = "Você não pode equipar arma agora." } end

                        local weapon_name = slot_data.item:upper()
                        local weapons = mergeWeapons(user_id, source)
                        if not weapons[weapon_name] then
                            if hasAmmoType(weapon_name, weapons) then
                                return {
                                    error = "Você já tem uma arma desse tipo equipada!"
                                }
                            end
                            if vRP.tryGetInventoryItem(user_id, slot_data.item, 1, slot) then
                                weapons[weapon_name] = { ammo = 0 }
                                vRP.setWeapons(user_id, weapons)
                                vRPc.giveWeapons(source, weapons, true)
                                exports["vrp_admin"]:generateLog({
                                    category = "inventario",
                                    room = "equipar",
                                    user_id = user_id,
                                    message = ( [[O USER_ID %s EQUIPOU A ARMA %s]] ):format(user_id, slot_data.item)
                                })
                                return {
                                    used_amount = 1,
                                }
                            end
                        else
                            return {
                                error = "Você já tem essa arma equipada!"
                            }
                        end
                    end
                end
            end
        end
    end
    return {
        error = "Item não utilizável."
    }
end

RegisterNetEvent("vrp_inventory:useItem", API.useItem)

---@param slot string
---@param amount number
---@return boolean | nil
function API.dropItem(slot, amount)
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        if HotbarWeapons then
            local active = HotbarWeapons.GetActive(user_id)
            if active and tostring(active.slot) == tostring(slot) then
                HotbarWeapons.ForceHolster(source, user_id)
            end
        end
        if amount <= 0 then
            return {error = 'Quantidade inválida.'}
        end
        if (GetPlayerRoutingBucket(source) ~= 0) then return { error = "Você não pode fazer isso aogra." } end
        if (GetEntityHealth(GetPlayerPed(source))) <= 101 then return { error = "Você está morto." } end
        local slot_data = vRP.getSlotItem(user_id, slot)
        if slot_data then
            if Items[slot_data.item] then
                if Items[slot_data.item].type == "equip" or Items[slot_data.item].type == "recharge" or slot_data.item == "dinheirosujo" then
                    return { error = "Você não pode dropar esse item." }
                end
            end

            if (slot_data.item):upper() == 'WEAPON_PISTOL' or (slot_data.item):upper() == 'AMMO_PISTOL' then
                TriggerClientEvent("Notify",source,"negado","Você não pode dropar armas ou munições.")
                return
            end
            if vRP.tryGetInventoryItem(user_id, slot_data.item, amount, slot) then
                vRPc._playAnim(source, true, { { "pickup_object", "pickup_low" } }, false)
                PickupSystem:Create({
                    src = source,
                    user_id = user_id
                }, slot_data.item, amount, GetEntityCoords(GetPlayerPed(source)))
                if InventoryAudit then
                    InventoryAudit.Log("inventory_item_dropped", {
                        actorId = user_id,
                        details = InventoryAudit.ItemDetails(slot_data.item, amount)
                    })
                end

                
				exports["vrp_admin"]:generateLog({
                    category = "inventario",
                    room = "dropar",
                    user_id = user_id,
                    message = ( [[O USER_ID %s DROPOU O ITEM %s NA QUANTIDADE DE x %s]] ):format(user_id, slot_data.item, amount)
                })

                return true
            end
        else
            return {error = 'Re-abra seu inventário. Você está realizando ações rápido demais.'}
        end
    end
end

---@param id number
---@param amount? number
---@param slot? string
---@return boolean
function API.getPickup(id, amount, slot)
    local source = source
    local user   = vRP.getUserId(source)
    if user then
        return PickupSystem:getPickup(id, user, source, amount, slot)
    end
    return false
end



RegisterCommand('garmas', function(source, args)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return end
    local ok = vRP.request(source, "Você deseja guardar suas armas?", 30)
    local status, time = exports['vrp']:getCooldown(user_id, "garmas")
    if not status then
        Notify(source, "negado", "Aguarde " .. time .. " segundos para guardar suas armas novamente.")
        return
    end
    if not ok then
        return Notify(source, "negado", "Você recusou a ação.")
    end
    if GetEntityHealth(GetPlayerPed(source)) <= 102 then
        return Notify(source, "negado", "Você não pode guardar armas estando morto.")
    end
    if vRP.hasPermission(user_id, "perm.disparo") and vRP.checkPatrulhamento(user_id) then
        TriggerClientEvent("Notify", source, "negado", "Você não pode guardar armas em patrulhamento.", 5)
        return
    end

    if vRP.hasPermission(user_id, "perm.bombeiro") or vRP.checkPatrulhamento(user_id) then
        TriggerClientEvent("Notify", source, "negado", "Você não pode guardar armas em patrulhamento.", 5)
        return
    end


    if vRP.hasPermission(user_id, "perm.tunar") and vRP.checkPatrulhamento(user_id) then
        TriggerClientEvent("Notify", source, "negado", "Você não pode guardar armas em patrulhamento.", 5)
        return
    end
    
    if vRP.hasPermission(user_id, "perm.customs") and vRP.checkPatrulhamento(user_id) then
        TriggerClientEvent("Notify", source, "negado", "Você não pode guardar armas em patrulhamento.", 5)
        return
    end

    if vRP.hasPermission(user_id, "perm.policia") and vRP.checkPatrulhamento(user_id) then
        TriggerClientEvent("Notify", source, "negado", "Você não pode guardar armas em patrulhamento.", 5)
        return
    end

    if GetPlayerRoutingBucket(source) ~= 0 then
        Notify(source, "negado", "Você não pode guardar armas agora.")
        return
    end
    -- TODO: Check if player is in a restricted area
    --[[
    if camp[user_id] then
            TriggerClientEvent("Notify",source,"negado","Você não pode dar /GARMAS estando com armas de campeonato!")
            return false
        end

        if arena.inArena(source) then
            TriggerClientEvent("Notify",source,"negado","Você não pode guardar armas aqui.", 3)
            return
    end
    ]]
    local hotbarHolstered = HotbarWeapons and HotbarWeapons.ForceHolster(source, user_id) or false
    local weapons = vRP.clearWeapons(user_id) or {}
    exports['vrp']:setCooldown(user_id, "garmas", 60)
    -- print(json.encode(weapons))
    if hotbarHolstered or next(weapons) then
        local weapon_list = ""
        for weapon, v in pairs(weapons) do
            if Items[(weapon):lower()] then
                vRP.giveInventoryItem(user_id, (weapon):lower(), 1)
                if v.ammo > 0 then
                    vRP.giveInventoryItem(user_id, "ammo_" .. (weapon:gsub("WEAPON_", "")):lower(),
                        v.ammo)
                    weapon_list = weapon_list .. "\n(ARMA: " .. weapon .. " MUNICAO: " .. v.ammo .. "x)"
                else
                    weapon_list = weapon_list .. "\n(ARMA: " .. weapon .. " MUNICAO: 0x)"
                end
            else
                print("Item não encontrado: " .. (weapon):lower())
            end
        end

        if InventoryAudit then
            InventoryAudit.Log("inventory_weapons_stored", {
                actorId = user_id,
                details = "**Armas devolvidas ao inventário:**" .. (weapon_list ~= "" and weapon_list or "\nSem munição registrada.")
            })
        end
        exports["vrp_admin"]:generateLog({
            category = "inventario",
            room = "garmas",
            user_id = user_id,
            message = ( [[O USER_ID %s GUARDOU %s]] ):format(user_id, weapon_list)
        })
        Notify(source, "sucesso", "Você guardou suas armas.")
    else
        Notify(source, "negado", "Você não tem armas para guardar.")
    end

end, false)

exports("storeWeapons",function(source,user_id)
    local status, time = exports['vrp']:getCooldown(user_id, "garmas")
    if not status then
        return
    end

    local hotbarHolstered = HotbarWeapons and HotbarWeapons.ForceHolster(source, user_id) or false
    local weapons = vRP.clearWeapons(user_id) or {}
    exports['vrp']:setCooldown(user_id, "garmas", 5)
    if hotbarHolstered or next(weapons) then
        local weapon_list = ""
        
        local inService = vRP.checkPatrulhamento(user_id) 
        if inService or GetPlayerRoutingBucket(source) ~= 0 then 
            return 
        end

        for weapon, v in pairs(weapons) do
            if Items[(weapon):lower()] then
                vRP.giveInventoryItem(user_id, (weapon):lower(), 1)
                if v.ammo > 0 then
                    vRP.giveInventoryItem(user_id, "ammo_" .. (weapon:gsub("WEAPON_", "")):lower(),v.ammo)
                    weapon_list = weapon_list .. "\n(ARMA: " .. weapon .. " MUNICAO: " .. v.ammo .. "x)"
                else
                    weapon_list = weapon_list .. "\n(ARMA: " .. weapon .. " MUNICAO: 0x)"
                end
            end
        end
        
        if InventoryAudit then
            InventoryAudit.Log("inventory_weapons_stored", {
                actorId = user_id,
                details = "**Armas devolvidas ao inventário (fluxo automático):**" .. (weapon_list ~= "" and weapon_list or "\nSem munição registrada.")
            })
        end
    end
end)

function Log(message)
    if webhook ~= "none" then
        PerformHttpRequest("", function(err, text, headers) end, 'POST', json.encode({ content = message }),
            { ['Content-Type'] = 'application/json' })
    end
end

local coldoownRepair = {}
RegisterServerEvent("tryreparar")
AddEventHandler("tryreparar",function(nveh)
	local source = source
	
	if coldoownRepair[source] and (coldoownRepair[source] - os.time()) > 0 then
		return
	end
	coldoownRepair[source] = os.time() + 30

	if type(nveh) ~= 'number' then
		return
	end

	nveh = tostring(nveh)
	if nveh:len() > 10 then
		return
	end

	nveh = tonumber(nveh)

	TriggerClientEvent("syncreparar",-1,nveh)
end)

local coldoownRepairPneus = {}
RegisterServerEvent("tryrepararpneus")
AddEventHandler("tryrepararpneus",function(nveh)
	local source = source
	
	if coldoownRepairPneus[source] and (coldoownRepairPneus[source] - os.time()) > 0 then
		return
	end
	coldoownRepairPneus[source] = os.time() + 30

	if type(nveh) ~= 'number' then
		return
	end

	nveh = tostring(nveh)
	if nveh:len() > 10 then
		return
	end

	nveh = tonumber(nveh)

	TriggerClientEvent("syncrepararpneus",-1,nveh)
end)

RegisterCommand('bauadm', function(source,args)
    local source = source
	local user_id = vRP.getUserId(source)
	if not user_id then return end
	if vRP.hasPermission(user_id, "developer.permissao") or vRP.hasPermission(user_id,"perm.resplog") or vRP.hasGroup(user_id,'respilegalrealidade') then
	
		
		local promptHouse = vRP.prompt(source, "Digite o Id da casa: ", t)
		if not promptHouse or promptHouse == "" then
			return
		end

		local rows = vRP.query("mirtin/ownerPropriedade", { houseID = promptHouse })
		if #rows == 0 then
			TriggerClientEvent("Notify",source,"negado","Propriedade não encontrada.", 3)
			return
		end

        if InventoryAudit then
            InventoryAudit.Log("inventory_staff_house_chest_open", {
                actorId = user_id,
                details = ("**Comando:** /bauadm\n**Casa/Propriedade:** %s\n**ID interno:** %s\n**Proprietário:** ID %s"):format(
                    tostring(promptHouse), tostring(rows[1].id or "-"), tostring(rows[1].proprietario or "-")
                )
            })
        end
		TriggerClientEvent('mirt1n:myHouseChest', source, rows[1].id, promptHouse, 1000,rows[1].proprietario)
	end
end, false)

RegisterCommand('baufacadm', function(source,args)
	local user_id = vRP.getUserId(source)
	if not user_id then return end
    if vRP.hasPermission(user_id, "developer.permissao") or vRP.hasPermission(user_id,"perm.resplog") or vRP.hasGroup(user_id,'respilegalrealidade') then
        local t = ""
        for i in pairs(Chests) do
            t = t.. i..", "
        end
    
        local promptOrg = vRP.prompt(source, "Escolha a Fac: ", t)
        if not promptOrg or promptOrg == "" then
            return
        end
    
        for i in pairs(Chests) do
            if i == promptOrg then
                staffRequests[source] = { user_id = user_id, org = promptOrg }
                TriggerClientEvent('openChestGroup', source, promptOrg)
                if InventoryAudit then
                    InventoryAudit.Log("inventory_staff_faction_chest_open", {
                        actorId = user_id,
                        details = ("**Comando:** /baufacadm\n**Facção/baú:** %s"):format(tostring(promptOrg))
                    })
                end
                return
            end
        end
    
        TriggerClientEvent( "Notify", source, "negado", "Bau de facção não encontrado...", 5 )
        return	
    end
end)