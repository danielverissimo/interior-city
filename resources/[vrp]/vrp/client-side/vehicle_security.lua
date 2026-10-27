-----------------------------------------------------------------------------------------------------------------------------------------
-- AMBIENT / NPC VEHICLE SECURITY
-- Veículos de população/NPC ficam bloqueados para todos os jogadores.
-- ÚNICA exceção: jogadores que estejam exatamente nos cargos "developer" ou "dono".
-- A autorização vem do servidor; nenhuma permissão genérica de staff concede bypass.
-----------------------------------------------------------------------------------------------------------------------------------------
local AMBIENT_POPULATION_TYPES = {
    [1] = true, -- RANDOM_PERMANENT
    [2] = true, -- RANDOM_PARKED
    [3] = true, -- RANDOM_PATROL
    [4] = true, -- RANDOM_SCENARIO
    [5] = true, -- RANDOM_AMBIENT
    [6] = true  -- PERMANENT (mundo/ambient)
}

local npcVehicleAccess = false

local function IsAmbientNpcVehicle(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then
        return false
    end

    return AMBIENT_POPULATION_TYPES[GetEntityPopulationType(vehicle)] == true
end

-- Bloqueio por jogador. Assim um developer/dono pode receber a exceção sem
-- destrancar o mesmo veículo para os demais jogadores do servidor.
local function LockAmbientVehicleForLocalPlayer(vehicle)
    if not IsAmbientNpcVehicle(vehicle) then return end

    SetVehicleDoorsLockedForPlayer(vehicle, PlayerId(), true)
end

local function UnlockAmbientVehicleForPrivilegedPlayer(vehicle)
    if not IsAmbientNpcVehicle(vehicle) then return end

    -- Remove qualquer trava específica que tenha sido aplicada anteriormente
    -- ao jogador local e libera a entrada. Os demais clientes continuam com
    -- o bloqueio individual aplicado pelo próprio vehicle_security.lua.
    SetVehicleDoorsLockedForPlayer(vehicle, PlayerId(), false)
    SetVehicleDoorsLocked(vehicle, 1)

    local driver = GetPedInVehicleSeat(vehicle, -1)
    if driver and driver ~= 0 and not IsPedAPlayer(driver) then
        SetPedCanBeDraggedOut(driver, true)
    end
end

RegisterNetEvent("vrp:npcVehicleAccess")
AddEventHandler("vrp:npcVehicleAccess", function(allowed)
    npcVehicleAccess = allowed == true
end)

-- Solicita ao servidor a autorização real do jogador. Repetimos após alguns
-- segundos para cobrir restart do resource/entrada do jogador durante o load.
CreateThread(function()
    Wait(1000)
    TriggerServerEvent("vrp:requestNpcVehicleAccess")
    Wait(4000)
    TriggerServerEvent("vrp:requestNpcVehicleAccess")
end)

-- Para jogadores comuns, qualquer veículo NPC/população próximo permanece
-- trancado para o jogador local. Developer/dono não recebe esse bloqueio.
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local vehicles = GetGamePool("CVehicle")

        for i = 1, #vehicles do
            local vehicle = vehicles[i]
            if IsAmbientNpcVehicle(vehicle) then
                local vehicleCoords = GetEntityCoords(vehicle)
                if #(coords - vehicleCoords) <= 140.0 then
                    if npcVehicleAccess then
                        SetVehicleDoorsLockedForPlayer(vehicle, PlayerId(), false)
                    else
                        LockAmbientVehicleForLocalPlayer(vehicle)
                    end
                end
            end
        end

        Wait(1250)
    end
end)

-- Entrada em veículo NPC.
-- Jogadores comuns têm a tarefa cancelada imediatamente.
-- Developer/dono tem o veículo liberado enquanto tenta entrar, inclusive
-- quando houver um ped NPC no banco do motorista.
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local tryingVehicle = GetVehiclePedIsTryingToEnter(ped)

        if tryingVehicle and tryingVehicle ~= 0 and IsAmbientNpcVehicle(tryingVehicle) then
            if npcVehicleAccess then
                UnlockAmbientVehicleForPrivilegedPlayer(tryingVehicle)
                Wait(0)
            else
                LockAmbientVehicleForLocalPlayer(tryingVehicle)
                ClearPedTasks(ped)
                Wait(0)
            end
        else
            Wait(200)
        end
    end
end)

-- Proteção final. Se algum script colocar um jogador comum dentro de um carro
-- NPC, ele é removido. Developer/dono permanece normalmente no veículo.
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle and vehicle ~= 0 and IsAmbientNpcVehicle(vehicle) then
            if npcVehicleAccess then
                UnlockAmbientVehicleForPrivilegedPlayer(vehicle)
                Wait(250)
            else
                LockAmbientVehicleForLocalPlayer(vehicle)
                TaskLeaveVehicle(ped, vehicle, 16)
                Wait(500)
            end
        else
            Wait(750)
        end
    end
end)
