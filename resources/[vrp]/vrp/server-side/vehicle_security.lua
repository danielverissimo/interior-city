-----------------------------------------------------------------------------------------------------------------------------------------
-- NPC VEHICLE ACCESS - SERVER AUTHORITY
-- Somente os cargos EXATOS "developer" e "dono" podem entrar em veículos NPC.
-- Não usamos admin.permissao/developer.permissao para evitar qualquer outra
-- exceção indireta herdada por outros cargos.
-----------------------------------------------------------------------------------------------------------------------------------------
local function CanUseNpcVehicles(user_id)
    if not user_id then return false end

    return vRP.hasGroup(user_id, "developer") or vRP.hasGroup(user_id, "dono")
end

local function SyncNpcVehicleAccess(user_id, source)
    source = source or vRP.getUserSource(user_id)
    if not source then return end

    TriggerClientEvent("vrp:npcVehicleAccess", source, CanUseNpcVehicles(user_id))
end

RegisterNetEvent("vrp:requestNpcVehicleAccess")
AddEventHandler("vrp:requestNpcVehicleAccess", function()
    local source = source
    local user_id = vRP.getUserId(source)
    SyncNpcVehicleAccess(user_id, source)
end)

-- Sincroniza assim que o personagem entra.
AddEventHandler("vRP:playerSpawn", function(user_id, source)
    SetTimeout(1000, function()
        SyncNpcVehicleAccess(user_id, source)
    end)
end)

-- Atualiza imediatamente se o cargo for alterado com o jogador online.
AddEventHandler("vRP:playerJoinGroup", function(user_id)
    SyncNpcVehicleAccess(user_id)
end)

AddEventHandler("vRP:playerLeaveGroup", function(user_id)
    -- group.lua dispara este evento imediatamente antes de remover o cargo
    -- da tabela do usuário, então sincronizamos no próximo tick.
    SetTimeout(0, function()
        SyncNpcVehicleAccess(user_id)
    end)
end)
