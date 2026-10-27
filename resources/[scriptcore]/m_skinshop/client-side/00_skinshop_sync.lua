
locateShops = locateShops or {}
blipsInMap = blipsInMap or {}

local function clearSkinshopBlips()
    for _, blip in pairs(blipsInMap) do
        if blip and DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    blipsInMap = {}
end

local function rebuildSkinshopBlips()
    clearSkinshopBlips()
    for id, parameters in pairs(locateShops) do
        if parameters[4] then
            local blip = AddBlipForCoord(parameters[1], parameters[2], parameters[3])
            SetBlipSprite(blip, 73)
            SetBlipColour(blip, 3)
            SetBlipScale(blip, 0.5)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Loja de Roupas")
            EndTextCommandSetBlipName(blip)
            blipsInMap[id] = blip
        end
    end
end

RegisterNetEvent("m_skinshop:fullSync", function(locations)
    locateShops = {}
    for _, shop in ipairs(type(locations) == "table" and locations or {}) do
        local id = tostring(shop.id)
        locateShops[id] = {
            tonumber(shop.x) or 0.0,
            tonumber(shop.y) or 0.0,
            tonumber(shop.z) or 0.0,
            shop.blip == true,
            true
        }
    end
    rebuildSkinshopBlips()
end)

CreateThread(function()
    Wait(600)
    TriggerServerEvent("m_skinshop:requestSync")
end)
