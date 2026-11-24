local soundWallSlots = {
    [joaat("chevys10")] = 5,
    [joaat("baller")] = 4,
    [joaat("vwsava")] = 5
}

local function applySoundWall(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return end
    local slot = soundWallSlots[GetEntityModel(vehicle)]
    if not slot then return end

    if GetVehicleModKit(vehicle) ~= 0 then SetVehicleModKit(vehicle, 0) end
    if GetNumVehicleMods(vehicle, slot) == 0 then return false end
    if GetVehicleMod(vehicle, slot) ~= 0 then SetVehicleMod(vehicle, slot, 0, false) end
    return GetVehicleMod(vehicle, slot) == 0
end

exports("applySoundWall", applySoundWall)

CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped and NetworkHasControlOfEntity(vehicle) then
            applySoundWall(vehicle)
        end
    end
end)
