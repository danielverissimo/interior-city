local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
vRP = Proxy.getInterface("vRP")

local eventPrefix = '__PolyZone__:'

function triggerZoneEvent(eventName, ...)
  TriggerClientEvent(eventPrefix .. eventName, -1, ...)
end

RegisterNetEvent("PolyZone:TriggerZoneEvent")
AddEventHandler("PolyZone:TriggerZoneEvent", triggerZoneEvent)

exports("TriggerZoneEvent", triggerZoneEvent)

RegisterServerEvent("PolyZone:checkPermission")
AddEventHandler("PolyZone:checkPermission", function()
    local source = source
    local user_id = vRP.getUserId(source)
    
    if user_id then
        if vRP.hasPermission(user_id, "developer.permissao") or vRP.hasPermission(user_id, "perm.owner") then
            TriggerClientEvent("PolyZone:startCreation", source)
        else
            TriggerClientEvent("Notify", source, "negado", "Você não tem permissão para usar este comando.")
        end
    else
        TriggerClientEvent("Notify", source, "negado", "Erro ao verificar permissões.")
    end
end)

RegisterServerEvent("PolyZone:createSafeZone")
AddEventHandler("PolyZone:createSafeZone", function(points)
    local source = source
    local user_id = vRP.getUserId(source)
    
    if user_id and (vRP.hasPermission(user_id, "developer.permissao") or vRP.hasPermission(user_id, "perm.owner")) then
        local zoneName = "safezone_" .. os.time()
        
        local formattedPoints = {}
        for _, point in ipairs(points) do
            table.insert(formattedPoints, string.format("vector2(%.2f, %.2f)", point.x, point.y))
        end
        
        local zoneCode = string.format([[
          local zone%s = PolyZone:Create({
              %s
          }, {
              name = "%s",
              minZ = %.2f,
              maxZ = %.2f
          })
            ]], zoneName, table.concat(formattedPoints, ",\n    "), zoneName, points[1].z - 5.0, points[1].z + 5.0)
        
        TriggerClientEvent("PolyZone:receiveZoneCode", source, zoneCode)
        TriggerClientEvent("Notify", source, "sucesso", "Safezone criada com sucesso! Copie o código e adicione ao arquivo de configuração.")
    end
end)

RegisterServerEvent("PolyZone:getUserId")
AddEventHandler("PolyZone:getUserId", function(cb)
    local source = source
    local user_id = vRP.getUserId(source)
    cb(user_id)
end)