local ACTIVED_INSPECTS <const> = {}



AddEventHandler("playerDropped", function()
    local src = source
    if ACTIVED_INSPECTS[src] then
        local type = ACTIVED_INSPECTS[src].type
        if type == "thief" then
            local target = ACTIVED_INSPECTS[source].user
            local targetInfo = ACTIVED_INSPECTS[target]
            ClearPedTasksImmediately(GetPlayerPed(target))
            vRPc._playAnim(target, true, {{ "random@arrests@busted", "exit" }}, false)
            ACTIVED_INSPECTS[src] = nil
            ACTIVED_INSPECTS[target] = nil
        else
            local target = ACTIVED_INSPECTS[source].user
            ClearPedTasksImmediately(GetPlayerPed(target))
            ACTIVED_INSPECTS[src] = nil
            ACTIVED_INSPECTS[target] = nil
            Remote._sendNuiEvent(target, {
                route = "CLOSE_INVENTORY",
                ignoreRight = true
            })
        end
    end
end)

AddCloseListener(function(src, user_id)
    if ACTIVED_INSPECTS[src] then
        local type = ACTIVED_INSPECTS[src].type
        if type == "thief" then
            local target = ACTIVED_INSPECTS[source].user
            local targetInfo = ACTIVED_INSPECTS[target]
            ACTIVED_INSPECTS[src] = nil
            ACTIVED_INSPECTS[target] = nil
            ClearPedTasksImmediately(GetPlayerPed(target))
            ClearPedTasksImmediately(GetPlayerPed(src))
            vRPc._stopAnim(src)
            FreezeEntityPosition(GetPlayerPed(target), false)
            vRPc._playAnim(target, true, {{ "random@arrests@busted", "exit" }}, false)
        end
    end
end)

vPOLICIA = Tunnel.getInterface("vrp_policia")


---@param source number
RegisterCommand("revistar", function(source)
    local source = source
    local ped = GetPlayerPed(source)

    if (GetEntityHealth(ped) <= 101) then
        print('_a')
        return
    end
    if GetPlayerRoutingBucket(source) ~= 0 then
        print('_bucket')
        return
    end
    local user_id = vRP.getUserId(source)
    if user_id then
        local nplayer = vRPc.getNearestPlayer(source, 5)
        if not nplayer then
            TriggerClientEvent('Notify', source, 'negado', 'Ninguém por perto.')
            return
        end
       
        -- if vPOLICIA.inSafe(source) then
        --     TriggerClientEvent('Notify', source, 'negado', 'Você não pode revistar dentro de uma safe-zone.')
        --     return
        -- end
     
        if GetVehiclePedIsIn(ped) > 0 then
            TriggerClientEvent('Notify', source, 'negado', 'Você não pode revistar dentro do veiculo.')
            return
        end
        
        if vRPc.checkAnim(nplayer) then
            return TriggerClientEvent('Notify', source, 'negado', 'O jogador não está rendido.')
        end
      
        if ACTIVED_INSPECTS[source] then
            TriggerClientEvent('Notify', source, 'negado', 'Você já está revistando alguém.')
            return
        elseif ACTIVED_INSPECTS[nplayer] then
            TriggerClientEvent('Notify', source, 'negado', 'Este jogador já está revistando ou sendo revistado.')
            return
        end
       
        local targetPed = GetPlayerPed(nplayer)
        local plyPed = GetPlayerPed(source)
    
        if (GetEntityHealth(plyPed) <= 101) then
            TriggerClientEvent('Notify', source, 'negado', 'Voce nao pode fazer isto morto.')
            return
        end
        
        if #(GetEntityCoords(targetPed) - GetEntityCoords(plyPed)) > 5 then
            TriggerClientEvent('Notify', source, 'negado', 'Este jogador está muito longe.')
            return
        end
     
        local blockedTime = exports.vrp_admin:isUserBlocked(user_id)
     
        if blockedTime then
            TriggerClientEvent('Notify', source, 'negado', 'Você está em modo novato! Aguarde até '..blockedTime.." para poder lootear alguém.")
            return
        end
  
        Remote.sendNuiEvent(
            nplayer,
            {
                route = 'CLOSE_INVENTORY'
            }
        )
        
        local targetId = vRP.getUserId(nplayer)

        if vRP.hasPermission(targetId,"perm.disparo") and vRP.checkPatrulhamento(targetId) then 
            TriggerClientEvent('Notify', source, 'negado', 'Não é possível revistar oficiais em serviço.')
            return false 
        end

        local identity = vRP.getUserIdentity(user_id)
        if (GetEntityHealth(targetPed) <= 101 or 
            vRPc.isHandcuffed(nplayer) or 
            vRP.hasPermission(user_id, 'policia.permissao') or 
            vRP.hasPermission(user_id, 'perm.disparo') or 
            vRP.hasPermission(user_id, 'admin.permissao') or 
            vRP.request(nplayer, 'Você aceita ser revistado por ' .. identity.nome .. ' ' .. identity.sobrenome .. '?', 30)) then
            Remote.SetInventoryBlocked(nplayer, 5)

            if GetPlayerRoutingBucket(nplayer) ~= 0 then
                TriggerClientEvent('Notify', source, 'negado', 'Jogador no PVP.')
                TriggerClientEvent('Notify', nplayer, 'negado', 'Você não pode ser revistado na arena.')
                return false
            end

            -- if vRP.hasPermission(targetId, 'developer.permissao')  or vRP.hasGroup(targetId, 'respilegalrealidade') then
            --     Notify(source, 'negado', 'Esse jogador não pode ser revistado.')
            --     return false
            -- end

            if vRP.hasPermission(targetId, 'policia.permissao') or vRP.hasPermission(targetId, 'perm.judiciario') then
                 TriggerClientEvent('Notify', source, 'negado', 'Este jogador é um policial.')
                return false
            end
            
            if vRP.hasGroup(targetId, 'block') then
                TriggerClientEvent('Notify', source, 'negado', 'Este jogador não pode ser revistado.')
                return
            end

            if (vRP.hasPermission(targetId, 'perm.bombeiro') or vRP.hasPermission(targetId, 'perm.bombeirocivil') or vRP.hasPermission(targetId, 'perm.unizk') or vRP.hasPermission(targetId, 'perm.judiciario')) and vRP.checkPatrulhamento(targetId) then
                TriggerClientEvent('Notify', source, 'negado', 'Este jogador faz parte do Hospital.')
                return false
            end

            -- if vRP.hasPermission(targetId, 'admin.permissao') then
            --     Notify(source, 'negado', 'Este jogador faz parte da administração.')
            --     return false
            -- end

            ACTIVED_INSPECTS[nplayer] = {
                type = 'stolen',
                user = source,
                drag_and_drop = true
            }

            ACTIVED_INSPECTS[source] = {
                type = 'thief',
                user = nplayer,
                drag_and_drop = false
            }
            Remote.sendNuiEvent(
                nplayer,
                {
                    route = 'CLOSE_INVENTORY'
                }
            )
            local weapons = vRP.clearWeapons(targetId)
            for k, v in pairs(weapons) do
                local item = string.lower(k)
                vRP.giveInventoryItem(targetId, item, 1)
                if v.ammo > 0 then
                    vRP.giveInventoryItem(targetId, 'ammo_' .. (item:gsub("weapon_", "")), v.ammo)
                end
            end

            if (GetEntityHealth(targetPed) <= 101) then
                vRPc._playAnim(source, false, {{ 'amb@medic@standing@tendtodead@idle_a', 'idle_a' }}, true)
            else
                vRPc._playAnim(source, false, {{ 'misscarsteal4@director_grip', 'end_loop_grip' }}, true)
                FreezeEntityPosition(GetPlayerPed(nplayer), true)
                vRPc._playAnim(nplayer, true, {{ 'random@arrests@busted', 'idle_a' }}, true)
                Notify(nplayer, 'importante', 'Você está sendo revistado!')
            end

            local identity = vRP.getUserIdentity(targetId)
            
            Remote._openInspect(
                source,
                {
                    target = {
                        target_id = targetId,
                        target_name = identity.nome .. ' ' .. identity.sobrenome,
                        inventory = vRP.getInventory(targetId),
                        weight = vRP.computeInvWeight(targetId),
                        max_weight = vRP.getInventoryMaxWeight(targetId)
                    },
                    source = {
                        inventory = vRP.getInventory(user_id),
                        weight = vRP.computeInvWeight(user_id),
                        max_weight = vRP.getInventoryMaxWeight(user_id)
                    }
                }
            )

            if InventoryAudit then
                InventoryAudit.Log("inventory_inspect_started", {
                    actorId = user_id,
                    targetId = targetId,
                    details = "**Tipo:** revista de jogador\n**Distância máxima autorizada:** 5 metros"
                })
            end
        else
            Notify(source, 'negado', 'Este jogador não aceitou ser revistado.')
        end
    end
end, false)

RegisterServerEvent("target:revistar")
AddEventHandler("target:revistar",function()

    local source = source
    local ped = GetPlayerPed(source)

    if (GetEntityHealth(ped) <= 101) then
        print('_a')
        return
    end
    if GetPlayerRoutingBucket(source) ~= 0 then
        print('_bucket')
        return
    end
    local user_id = vRP.getUserId(source)
    if user_id then
        local nplayer = vRPc.getNearestPlayer(source, 5)
        if not nplayer then
            TriggerClientEvent('Notify', source, 'negado', 'Ninguém por perto.')
            return
        end
       
        -- if vPOLICIA.inSafe(source) then
        --     TriggerClientEvent('Notify', source, 'negado', 'Você não pode revistar dentro de uma safe-zone.')
        --     return
        -- end
     
        if GetVehiclePedIsIn(ped) > 0 then
            TriggerClientEvent('Notify', source, 'negado', 'Você não pode revistar dentro do veiculo.')
            return
        end
        
        if vRPc.checkAnim(nplayer) then
            return TriggerClientEvent('Notify', source, 'negado', 'O jogador não está rendido.')
        end
      
        if ACTIVED_INSPECTS[source] then
            TriggerClientEvent('Notify', source, 'negado', 'Você já está revistando alguém.')
            return
        elseif ACTIVED_INSPECTS[nplayer] then
            TriggerClientEvent('Notify', source, 'negado', 'Este jogador já está revistando ou sendo revistado.')
            return
        end
       
        local targetPed = GetPlayerPed(nplayer)
        local plyPed = GetPlayerPed(source)
    
        if (GetEntityHealth(plyPed) <= 101) then
            TriggerClientEvent('Notify', source, 'negado', 'Voce nao pode fazer isto morto.')
            return
        end
        
        if #(GetEntityCoords(targetPed) - GetEntityCoords(plyPed)) > 5 then
            TriggerClientEvent('Notify', source, 'negado', 'Este jogador está muito longe.')
            return
        end
     
        local blockedTime = exports.vrp_admin:isUserBlocked(user_id)
     
        if blockedTime then
            TriggerClientEvent('Notify', source, 'negado', 'Você está em modo novato! Aguarde até '..blockedTime.." para poder lootear alguém.")
            return
        end
  
        Remote.sendNuiEvent(
            nplayer,
            {
                route = 'CLOSE_INVENTORY'
            }
        )
        
        local targetId = vRP.getUserId(nplayer)

        if vRP.hasPermission(targetId,"perm.disparo") and vRP.checkPatrulhamento(targetId) then 
            TriggerClientEvent('Notify', source, 'negado', 'Não é possível revistar oficiais em serviço.')
            return false 
        end

        local identity = vRP.getUserIdentity(user_id)
        if (GetEntityHealth(targetPed) <= 101 or 
            vRPc.isHandcuffed(nplayer) or 
            vRP.hasPermission(user_id, 'policia.permissao') or 
            vRP.hasPermission(user_id, 'perm.disparo') or 
            vRP.hasPermission(user_id, 'admin.permissao') or 
            vRP.request(nplayer, 'Você aceita ser revistado por ' .. identity.nome .. ' ' .. identity.sobrenome .. '?', 30)) then
            Remote.SetInventoryBlocked(nplayer, 5)

            if GetPlayerRoutingBucket(nplayer) ~= 0 then
                TriggerClientEvent('Notify', source, 'negado', 'Jogador no PVP.')
                TriggerClientEvent('Notify', nplayer, 'negado', 'Você não pode ser revistado na arena.')
                return false
            end

            -- if vRP.hasPermission(targetId, 'developer.permissao')  or vRP.hasGroup(targetId, 'respilegalrealidade') then
            --     Notify(source, 'negado', 'Esse jogador não pode ser revistado.')
            --     return false
            -- end

            if vRP.hasPermission(targetId, 'policia.permissao') or vRP.hasPermission(targetId, 'perm.judiciario') then
                 TriggerClientEvent('Notify', source, 'negado', 'Este jogador é um policial.')
                return false
            end
            
            if vRP.hasGroup(targetId, 'block') then
                TriggerClientEvent('Notify', source, 'negado', 'Este jogador não pode ser revistado.')
                return
            end

            if (vRP.hasPermission(targetId, 'perm.bombeiro') or vRP.hasPermission(targetId, 'perm.bombeirocivil') or vRP.hasPermission(targetId, 'perm.unizk') or vRP.hasPermission(targetId, 'perm.judiciario')) and vRP.checkPatrulhamento(targetId) then
                TriggerClientEvent('Notify', source, 'negado', 'Este jogador faz parte do Hospital.')
                return false
            end

            -- if vRP.hasPermission(targetId, 'admin.permissao') then
            --     Notify(source, 'negado', 'Este jogador faz parte da administração.')
            --     return false
            -- end

            ACTIVED_INSPECTS[nplayer] = {
                type = 'stolen',
                user = source,
                drag_and_drop = true
            }

            ACTIVED_INSPECTS[source] = {
                type = 'thief',
                user = nplayer,
                drag_and_drop = false
            }
            Remote.sendNuiEvent(
                nplayer,
                {
                    route = 'CLOSE_INVENTORY'
                }
            )
            local weapons = vRP.clearWeapons(targetId)
            for k, v in pairs(weapons) do
                local item = string.lower(k)
                vRP.giveInventoryItem(targetId, item, 1)
                if v.ammo > 0 then
                    vRP.giveInventoryItem(targetId, 'ammo_' .. (item:gsub("weapon_", "")), v.ammo)
                end
            end

            if (GetEntityHealth(targetPed) <= 101) then
                vRPc._playAnim(source, false, {{ 'amb@medic@standing@tendtodead@idle_a', 'idle_a' }}, true)
            else
                vRPc._playAnim(source, false, {{ 'misscarsteal4@director_grip', 'end_loop_grip' }}, true)
                FreezeEntityPosition(GetPlayerPed(nplayer), true)
                vRPc._playAnim(nplayer, true, {{ 'random@arrests@busted', 'idle_a' }}, true)
                Notify(nplayer, 'importante', 'Você está sendo revistado!')
            end

            local identity = vRP.getUserIdentity(targetId)
            
            Remote._openInspect(
                source,
                {
                    target = {
                        target_id = targetId,
                        target_name = identity.nome .. ' ' .. identity.sobrenome,
                        inventory = vRP.getInventory(targetId),
                        weight = vRP.computeInvWeight(targetId),
                        max_weight = vRP.getInventoryMaxWeight(targetId)
                    },
                    source = {
                        inventory = vRP.getInventory(user_id),
                        weight = vRP.computeInvWeight(user_id),
                        max_weight = vRP.getInventoryMaxWeight(user_id)
                    }
                }
            )

            if InventoryAudit then
                InventoryAudit.Log("inventory_inspect_started", {
                    actorId = user_id,
                    targetId = targetId,
                    details = "**Tipo:** revista de jogador\n**Distância máxima autorizada:** 5 metros"
                })
            end
        else
            Notify(source, 'negado', 'Este jogador não aceitou ser revistado.')
        end
    end

end)

RegisterCommand("invsee", function(source, args)
    local user_id = vRP.getUserId(source)
    if not user_id then return end

    local targetId = tonumber(args[1])
    if not targetId or targetId <= 0 then 
        return 
    end

    local perms = {
        { permType = 'perm', perm = 'developer.permissao' },
        { permType = 'perm', perm = 'perm.respilegal' },
        { permType = 'group', perm = 'resplogrealidade' },
        { permType = 'group', perm = 'respstaffrealidade' },
    }

    local hasPermission = false
    for _, perm in ipairs(perms) do
        if perm.permType == 'perm' and vRP.hasPermission(user_id, perm.perm) then
            hasPermission = true
            break
        elseif perm.permType == 'group' and vRP.hasGroup(user_id, perm.perm) then
            hasPermission = true
            break
        end
    end

    if not hasPermission then 
        return 
    end

    local nplayer = vRP.getUserSource(targetId)
    if not nplayer then
        Notify(source, 'negado', 'Jogador não encontrado.')
        return
    end

    if vRP.hasGroup(targetId, 'block') then
        Notify(source, 'negado', 'Este jogador não pode ser revistado.')
        return
    end

    Remote.sendNuiEvent(
        nplayer,
        {
            route = 'CLOSE_INVENTORY'
        }
    )
    Remote.SetInventoryBlocked(nplayer, 5)

    ACTIVED_INSPECTS[nplayer] = {
        type = 'stolen',
        user = source,
        drag_and_drop = false
    }
    ACTIVED_INSPECTS[source] = {
        type = 'thief',
        user = nplayer,
        drag_and_drop = false
    }

    Remote.sendNuiEvent(
        nplayer,
        {
            route = 'CLOSE_INVENTORY'
        }
    )

    local weapons = vRP.clearWeapons(targetId)
    for k, v in pairs(weapons) do
        local item = string.lower(k)
        vRP.giveInventoryItem(targetId, item, 1)
        if v.ammo > 0 then
            vRP.giveInventoryItem(targetId, 'ammo_' .. (item:gsub("weapon_", "")), v.ammo)
        end
    end

    local identity = vRP.getUserIdentity(targetId)
    Remote._openInspect(
        source,
        {
            target = {
                target_id = targetId,
                target_name = identity.nome .. ' ' .. identity.sobrenome,
                inventory = vRP.getInventory(targetId),
                weight = vRP.computeInvWeight(targetId),
                max_weight = vRP.getInventoryMaxWeight(targetId)
            },
            source = {
                inventory = vRP.getInventory(user_id),
                weight = vRP.computeInvWeight(user_id),
                max_weight = vRP.getInventoryMaxWeight(user_id)
            }
        }
    )

    if InventoryAudit then
        InventoryAudit.Log("inventory_inspect_staff", {
            actorId = user_id,
            targetId = targetId,
            details = "**Método:** comando administrativo `invsee`"
        })
    end
end)

---@param from_slot string
---@param to_slot string
---@param amount number
---@return boolean | table
function API.takeInspectItem(from_slot, to_slot, amount)
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        if (ACTIVED_INSPECTS[source] and ACTIVED_INSPECTS[source].type == "thief") then
            local target_source = ACTIVED_INSPECTS[source].user
            local target_id     = vRP.getUserId(target_source)
            if not target_id then
                return { error = "Jogador revistado não encontrado." }
            end

            if vRP.checkPatrulhamento(user_id) or vRP.checkPatrulhamento(target_id) or vRP.hasPermission(user_id,"perm.disparo") or vRP.hasPermission(target_id,"perm.disparo") then 
                return false, TriggerClientEvent("Notify",source,"negado","Você não pode fazer isso.",5)
            end
            if HotbarWeapons then
                local active = HotbarWeapons.GetActive(target_id)
                if active and tostring(active.slot) == tostring(from_slot) then
                    HotbarWeapons.ForceHolster(target_source, target_id)
                end
            end
            local slot_data     = vRP.getSlotItem(target_id, from_slot)
            if slot_data then
                if HotbarWeapons and HotbarWeapons.IsDutyWeaponSlot(target_id, from_slot, slot_data.item) then
                    return { error = "Você não pode retirar uma arma temporária de serviço." }
                end
                if vRP.computeInvWeight(user_id) + (Items[slot_data.item].weight * amount) > vRP.getInventoryMaxWeight(user_id) then
                    Notify(source, "negado", "Espaço insuficiente na mochila.")
                    return {
                        error = "Espaço insuficiente na mochila."
                    }
                end

                if (slot_data.item):upper() == 'WEAPON_PISTOL' or (slot_data.item):upper() == 'AMMO_PISTOL' 
                or (slot_data.item):lower() == 'riopan' or (slot_data.item):lower() == 'coumadin' then
                    TriggerClientEvent("Notify",source,"negado","Você não pode pegar armas ou munições.")
                    return
                end
                amount = ((amount or 1) > slot_data.amount) and slot_data.amount or amount
                if vRP.tryGetInventoryItem(target_id, slot_data.item, amount, from_slot) then
                    vRP.giveInventoryItem(user_id, slot_data.item, amount, to_slot)
                    if InventoryAudit then
                        InventoryAudit.Log("inventory_inspect_item_taken", {
                            actorId = user_id,
                            targetId = target_id,
                            details = InventoryAudit.ItemDetails(slot_data.item, amount)
                        })
                    end
                    exports["vrp_admin"]:generateLog({
                        category = "inventario",
                        room = "saquear",
                        user_id = user_id,
                        target_id = target_id,
                        message = ( [[O USER_ID %s RETIROU %s %s DO INVENTARIO DO USER_ID %s]] ):format(user_id,amount, slot_data.item,target_id)
                    })

                    return true
                end
            end
        else
            return {
                error = "Reviste novamente!"
            }
        end
    end
    return {
        error = "Reviste novamente!"
    }
end

---@param from_slot string
---@param to_slot string
---@param amount number
---@return boolean | table
function API.putInspectItem(from_slot, to_slot, amount)
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        if (ACTIVED_INSPECTS[source] and ACTIVED_INSPECTS[source].type == "thief") then
            local target_source = ACTIVED_INSPECTS[source].user
            local target_source_ped = GetPlayerPed(target_source)
            local target_source_health = GetEntityHealth(target_source_ped)
            local target_source_ped_coords = GetEntityCoords(target_source_ped)
            local ped = GetPlayerPed(source)
            local ped_coords = GetEntityCoords(ped)
            local dist = #(target_source_ped_coords - ped_coords)
            if (dist >= 10.0) then
                return {
                    error = 'Você não pode enviar itens para um player distante.'
                }
            end
            if (target_source_health <= 101) then
                return {
                    error = 'Você não pode enviar itens para um morto.'
                }
            end
            local target_id = vRP.getUserId(target_source)
            if HotbarWeapons then
                local active = HotbarWeapons.GetActive(user_id)
                if active and tostring(active.slot) == tostring(from_slot) then
                    HotbarWeapons.ForceHolster(source, user_id)
                end
            end
            local slot_data = vRP.getSlotItem(user_id, from_slot)
            if slot_data then
                if HotbarWeapons and HotbarWeapons.IsDutyWeaponSlot(user_id, from_slot, slot_data.item) then
                    return { error = "Você não pode transferir uma arma temporária de serviço." }
                end
                if vRP.computeInvWeight(target_id) + (Items[slot_data.item].weight * amount) > vRP.getInventoryMaxWeight(target_id) then
                    return {
                        error = "Espaço insuficiente na mochila."
                    }
                end
                amount = ((amount or 1) > slot_data.amount) and slot_data.amount or amount
                if vRP.tryGetInventoryItem(user_id, slot_data.item, amount, from_slot) then
                    vRP.giveInventoryItem(target_id, slot_data.item, amount, to_slot)

                    if InventoryAudit then
                        InventoryAudit.Log("inventory_inspect_item_given", {
                            actorId = user_id,
                            targetId = target_id,
                            details = InventoryAudit.ItemDetails(slot_data.item, amount)
                        })
                    end

                    return true
                end
            end
        else
            return {
                error = "Reviste novamente!"
            }
        end
    end
    return {
        error = "Reviste novamente!"
    }
end

_G.isPlayerInspecting = function(src)
    return ACTIVED_INSPECTS[src] ~= nil
end
