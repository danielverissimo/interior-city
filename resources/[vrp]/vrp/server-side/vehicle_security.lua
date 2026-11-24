-- NPC vehicles can be entered, but their ignition is unlocked only by a server
-- inventory attempt. There is deliberately no network event accepting success.
local ambientTypes = {[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true}
local attempts = {}
local Tunnel = module("lib/Tunnel")
local inventoryClient = Tunnel.getInterface("inventory")

local function npcVehicle(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then return false end
    local state = Entity(vehicle).state
    if state.npcIgnitionRequired ~= nil then return state.npcIgnitionRequired == true end
    if not ambientTypes[GetEntityPopulationType(vehicle)] then return false end
    local plate = GetVehicleNumberPlateText(vehicle):gsub("^%s+",""):gsub("%s+$","")
    local required = not vRP.getUserByRegistration(plate)
    state:set("npcIgnitionRequired",required,true)
    return required
end

local function driverStillInVehicle(player, ped, vehicle, netId, userId)
    return vRP.getUserId(player) == userId and GetPlayerPed(player) == ped and
        DoesEntityExist(vehicle) and NetworkGetNetworkIdFromEntity(vehicle) == netId and
        GetVehiclePedIsIn(ped,false) == vehicle and GetPedInVehicleSeat(vehicle,-1) == ped and
        GetEntityHealth(ped) > 101
end

RegisterNetEvent("vrp:requestNpcIgnitionState",function(netId)
    local player = source
    local ped = GetPlayerPed(player)
    if not vRP.getUserId(player) or not tonumber(netId) then return end
    local vehicle = NetworkGetEntityFromNetworkId(tonumber(netId))
    if vehicle == 0 or not DoesEntityExist(vehicle) then return end
    -- Mark traffic before the player takes over: another script may promote
    -- the entity to a mission vehicle during the carjacking animation.
    if GetVehiclePedIsIn(ped,false) ~= vehicle and #(GetEntityCoords(ped)-GetEntityCoords(vehicle)) > 6.0 then return end
    npcVehicle(vehicle)
end)

exports("useNpcVehicleLockpick",function(player,slot)
    local userId = vRP.getUserId(player)
    local ped = GetPlayerPed(player)
    local vehicle = GetVehiclePedIsIn(ped,false)
    -- Returning false leaves the existing player-vehicle lockpick flow intact.
    if not userId or not npcVehicle(vehicle) then return false,false end
    if GetPedInVehicleSeat(vehicle,-1) ~= ped then
        TriggerClientEvent("Notify",player,"negado","Use a lockpick no banco do motorista.",5000)
        return true,false
    end
    if GetEntityHealth(ped) <= 101 then return true,false end
    if Entity(vehicle).state.npcIgnitionUnlocked == true then
        TriggerClientEvent("Notify",player,"aviso","Este veículo já está com a ignição liberada.",5000)
        return true,false
    end
    if attempts[player] then
        TriggerClientEvent("Notify",player,"aviso","Você já está tentando fazer a ligação direta.",5000)
        return true,false
    end
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId == 0 then return true,false end
    if not driverStillInVehicle(player,ped,vehicle,netId,userId) then return true,false end
    local attempt = {vehicle=vehicle,netId=netId}
    attempts[player] = attempt
    local ok,result = pcall(function()
        if not vRP.useLockpick(userId,slot) then
            TriggerClientEvent("Notify",player,"negado","Você precisa de uma lockpick para ligar este carro.",5000)
            return false
        end
        inventoryClient._closeInventory(player)
        local coords = GetEntityCoords(ped)
        exports["vrp"]:alertPolice({
            x=coords.x,y=coords.y,z=coords.z,code="911",
            title="Roubo de veículo",text="Tentativa de ligação direta em veículo de NPC.",
            vehicle=GetVehicleNumberPlateText(vehicle),
            rgba={255,55,70,255},blipSprite=161,blipColor=1,blipScale=0.75,blipDuration=60000
        })
        local speed = tonumber(GetConvar('vehicle_lockpick_speed', '1.5')) or 1.5
        local finished = vRPclient.taskBar(player, nil, nil, speed)
        if attempts[player] ~= attempt or not driverStillInVehicle(player,ped,vehicle,netId,userId) then return false end
        if finished ~= true then
            TriggerClientEvent("Notify",player,"negado","A ligação direta falhou. O motor continua bloqueado.",5000)
            return false
        end
        Entity(vehicle).state:set("npcIgnitionUnlocked",true,true)
        TriggerClientEvent("Notify",player,"sucesso","Ligação direta concluída. Motor liberado.",5000)
        return true
    end)
    if attempts[player] == attempt then attempts[player] = nil end
    if not ok then
        print("[npc-lockpick] Falha na tentativa: "..tostring(result))
        TriggerClientEvent("Notify",player,"negado","Não foi possível concluir a ligação direta. Tente novamente.",5000)
        return true,false
    end
    return true,result == true
end)

AddEventHandler("playerDropped",function() attempts[source]=nil end)
