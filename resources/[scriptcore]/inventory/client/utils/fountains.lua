local coolerModels = {}
for _, model in ipairs(WaterCoolerConfig.models) do
    coolerModels[#coolerModels + 1] = GetHashKey(model)
end

-- Map props may not be networked. Never require a network ID to find a dispenser.
function API.getWaterSource(coolerOnly)
    local ped = PlayerPedId()
    if IsEntityDead(ped) or GetEntityHealth(ped) <= 101 or IsPedInAnyVehicle(ped, false)
        or vRP.isHandcuffed() or LocalPlayer.state.pvp or LocalPlayer.state.defuse_mode then
        return false
    end

    local coords = GetEntityCoords(ped)
    local closest, closestDistance
    for _, model in ipairs(coolerModels) do
        local object = GetClosestObjectOfType(coords.x, coords.y, coords.z,
            WaterCoolerConfig.distance, model, false, false, false)
        if object ~= 0 and DoesEntityExist(object) then
            local position = GetEntityCoords(object)
            local distance = #(coords - position)
            if distance <= WaterCoolerConfig.distance and (not closestDistance or distance < closestDistance) then
                closestDistance = distance
                closest = {
                    style = "fountain", model = model,
                    coords = { x = position.x, y = position.y, z = position.z },
                    networkId = NetworkGetEntityIsNetworked(object) and NetworkGetNetworkIdFromEntity(object) or 0
                }
            end
        end
    end
    if closest then return closest end

    -- Preserve the existing ability to refill a bottle while standing in water.
    if not coolerOnly and IsEntityInWater(ped) then
        return { style = "floor", coords = { x = coords.x, y = coords.y, z = coords.z } }
    end
    return false
end

local function useCooler(action)
    if not API.getWaterSource(true) then
        TriggerEvent("Notify", "negado", "Aproxime-se do bebedouro para usar.", 5)
        return
    end
    local result = Remote.useWaterCooler(action)
    if type(result) == "table" and result.error then
        TriggerEvent("Notify", "negado", result.error, 5)
    end
end

AddEventHandler("inventory:coolerDrink", function() useCooler("drink") end)
AddEventHandler("inventory:coolerFill", function() useCooler("fill") end)

local function registerCoolers()
    if GetResourceState("target") ~= "started" then return end
    exports.target:AddTargetModel(coolerModels, {
        options = {
            { event = "inventory:coolerDrink", label = "Beber água", tunnel = "client" },
            { event = "inventory:coolerFill", label = "Encher garrafinha", tunnel = "client" }
        },
        distance = WaterCoolerConfig.distance
    })
end

CreateThread(function()
    Wait(1000)
    registerCoolers()
end)
AddEventHandler("onClientResourceStart", function(resource)
    if resource == "target" then registerCoolers() end
end)
