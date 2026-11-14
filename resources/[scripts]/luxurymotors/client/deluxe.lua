local mapBlip

function RefreshDeluxeBlip()
    if mapBlip then RemoveBlip(mapBlip); mapBlip = nil end
    if not DeluxeConfig.enabled or not DeluxeConfig.coords then return end
    local c = DeluxeConfig.coords
    mapBlip = AddBlipForCoord(c[1], c[2], c[3])
    SetBlipSprite(mapBlip, 326)
    SetBlipColour(mapBlip, 46)
    SetBlipScale(mapBlip, 0.75)
    SetBlipAsShortRange(mapBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('LuxuryMotors | Concessionária')
    EndTextCommandSetBlipName(mapBlip)
end

RegisterNetEvent('luxurymotors:syncDeluxe', function(config)
    ApplyDeluxeLocation(config)
    RefreshDeluxeBlip()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if mapBlip then RemoveBlip(mapBlip) end
    SetNuiFocus(false, false)
end)
