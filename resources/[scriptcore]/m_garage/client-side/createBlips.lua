local dynamicGarageBlips = {}

local function clearGarageBlips()
    for _,blip in ipairs(dynamicGarageBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    dynamicGarageBlips = {}
end

local function createBlipsInMap()
    clearGarageBlips()
    for i = 1, #garages do
        local garage = garages[i]
        local garageType = types[garage.type]
        if garageType and garageType.blip and garageType.blip.showBlip then
            local blip = AddBlipForCoord(garage.coords.x,garage.coords.y,garage.coords.z)
            SetBlipSprite(blip, tonumber(garageType.blip.blipId) or 357)
            SetBlipAsShortRange(blip,true)
            SetBlipColour(blip, tonumber(garageType.blip.blipColor) or 0)
            SetBlipScale(blip, tonumber(garageType.blip.blipScale) or 0.5)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(tostring(garageType.blip.name or "Garagem"))
            EndTextCommandSetBlipName(blip)
            dynamicGarageBlips[#dynamicGarageBlips+1] = blip
        end
    end
end

AddEventHandler("m_garage:configUpdated", function()
    CreateThread(function()
        Wait(100)
        createBlipsInMap()
    end)
end)

CreateThread(function()
    Wait(1200)
    createBlipsInMap()
end)
