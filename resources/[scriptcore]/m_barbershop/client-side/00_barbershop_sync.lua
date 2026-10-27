
locations = locations or {}
blipsInMap = blipsInMap or {}

local function clearBarberBlips()
    for _, blip in pairs(blipsInMap) do
        if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    blipsInMap = {}
end

local function rebuildBarberBlips()
    clearBarberBlips()
    for id, data in pairs(locations) do
        if data[4] then
            local blip = AddBlipForCoord(data[1],data[2],data[3])
            SetBlipSprite(blip,71)
            SetBlipColour(blip,3)
            SetBlipScale(blip,0.5)
            SetBlipAsShortRange(blip,true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Barbearia")
            EndTextCommandSetBlipName(blip)
            blipsInMap[id] = blip
        end
    end
end

RegisterNetEvent("m_barbershop:fullSync", function(list)
    locations = {}
    for _, shop in ipairs(type(list) == "table" and list or {}) do
        locations[tostring(shop.id)] = {
            tonumber(shop.x) or 0.0,
            tonumber(shop.y) or 0.0,
            tonumber(shop.z) or 0.0,
            shop.blip == true,
            shop.marker ~= false
        }
    end
    rebuildBarberBlips()
end)

CreateThread(function()
    Wait(600)
    TriggerServerEvent("m_barbershop:requestSync")
end)
