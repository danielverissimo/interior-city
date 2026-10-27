local function RegisterRoutes()
  local routes = {

    ["SELL_VEHICLE"] = function(vehicleData)
      serverFunctions.sellVehicle(vehicleData)
      return true
    end,

    ["LEND_VEHICLE"] = function(vehicleData)
      serverFunctions.addKeyCarForOtherUser(vehicleData)
      return true
    end,

    ["PULL_NEAREST"] = function(data)
      serverFunctions.storeProximityVehicle(20.0)
    end,

    ["GET_GARAGE"] = function()
      return requestVehiclesUserTable()
    end,
    ["TAKE_OUT"] = function(vehicleData) -- RETIRAR O VEÍCULO
      spawnVehicle(vehicleData)
      clientFunctions.closeNui()
      return true
    end,
    ["PULL"] = function(vehicleData) -- GUARDAR O VEÍCULO
      pullVehicle(vehicleData)
      clientFunctions.closeNui()
      return true
    end,

    ["CLOSE"] = function()
      clientFunctions.closeNui()
      return true
    end
  }

  for k, v in pairs(routes) do
    RegisterNUICallback(
      tostring(k),
      function(data, cb)
        cb(v(data))
      end
    )
  end
end
CreateThread(RegisterRoutes)

function clientFunctions.openNui(id, type)
  opennedGarageId = id
  opennedGarageType = type
  
  SetNuiFocus(true, true)
  SendNUIMessage({ action = "open" })
end

function clientFunctions.closeNui()
  SendNUIMessage({ action = "close" })
  SetNuiFocus(false, false)
end

exports('getVehicleName', function(vehicle)
  return serverFunctions.getVehicleName(vehicle)
end)

exports('getVehicleTrunk', function(vehicle)
  return serverFunctions.getVehicleTrunk(vehicle)
end)

exports("foundGarageByPermission", function (perm)
  for _, garage in pairs(garagesLocs) do
    if garage.permiss == perm then
      return garage
    end
  end
  return {}
end)