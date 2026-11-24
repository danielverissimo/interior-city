-- Allow NPC carjacking, but block driving until a successful inventory lockpick.
local ambientTypes = {[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true}
local blockedVehicle = nil
local lastVehicle, lastRequest, notifiedVehicle = 0, 0, 0
local enteringVehicle, enteringRequest = 0, 0

local function ambientVehicle(vehicle)
    return vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) and
        ambientTypes[GetEntityPopulationType(vehicle)] == true
end

local function requiresHotwire(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end
    local required = Entity(vehicle).state.npcIgnitionRequired
    if required ~= nil then return required == true end
    return ambientVehicle(vehicle)
end

local function releaseBrake(startEngine)
    if blockedVehicle and DoesEntityExist(blockedVehicle) then
        SetVehicleHandbrake(blockedVehicle,false)
        if startEngine and GetVehicleEngineHealth(blockedVehicle) > 0 then SetVehicleEngineOn(blockedVehicle,true,true,false) end
    end
    blockedVehicle = nil
end

-- Clear the per-player entry locks left by the former NPC access restriction.
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for _,vehicle in ipairs(GetGamePool("CVehicle")) do
            if ambientVehicle(vehicle) and #(coords-GetEntityCoords(vehicle)) <= 140.0 then
                SetVehicleDoorsLockedForPlayer(vehicle,PlayerId(),false)
            end
        end
        Wait(1250)
    end
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local trying = GetVehiclePedIsTryingToEnter(ped)
        if ambientVehicle(trying) then
            local now = GetGameTimer()
            if NetworkGetEntityIsNetworked(trying) and (enteringVehicle ~= trying or now-enteringRequest >= 2000) then
                enteringVehicle,enteringRequest = trying,now
                TriggerServerEvent("vrp:requestNpcIgnitionState",VehToNet(trying))
            end
            SetVehicleDoorsLockedForPlayer(trying,PlayerId(),false)
            SetVehicleDoorsLocked(trying,1)
            local driver = GetPedInVehicleSeat(trying,-1)
            if driver ~= 0 and not IsPedAPlayer(driver) then SetPedCanBeDraggedOut(driver,true) end
        end
        Wait(100)
    end
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped,false)
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle,-1) == ped and requiresHotwire(vehicle) then
            local unlocked = Entity(vehicle).state.npcIgnitionUnlocked == true
            if not unlocked then
                if blockedVehicle and blockedVehicle ~= vehicle then releaseBrake() end
                blockedVehicle = vehicle
                SetVehicleEngineOn(vehicle,false,true,true)
                SetVehicleHandbrake(vehicle,true)
                DisableControlAction(0,71,true)
                DisableControlAction(0,72,true)
                DisableControlAction(0,87,true)
                DisableControlAction(0,88,true)
                if notifiedVehicle ~= vehicle then
                    notifiedVehicle = vehicle
                    TriggerEvent("Notify","aviso","Use uma lockpick dentro do veículo e vença o minigame para ligar o motor.",7000)
                end
                local now = GetGameTimer()
                if lastVehicle ~= vehicle or now-lastRequest >= 2000 then
                    lastVehicle,lastRequest = vehicle,now
                    if NetworkGetEntityIsNetworked(vehicle) then
                        TriggerServerEvent("vrp:requestNpcIgnitionState",VehToNet(vehicle))
                    end
                end
            elseif blockedVehicle == vehicle then
                releaseBrake(true)
            end
            Wait(0)
        else
            releaseBrake(vehicle ~= 0 and vehicle == blockedVehicle and GetPedInVehicleSeat(vehicle,-1) == ped and Entity(vehicle).state.npcIgnitionRequired == false)
            notifiedVehicle,lastVehicle = 0,0
            Wait(vehicle ~= 0 and 0 or 100)
        end
    end
end)

AddEventHandler("onResourceStop",function(name)
    if name == GetCurrentResourceName() then releaseBrake() end
end)
