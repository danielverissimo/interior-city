local purchasePending = false
local routes = {

      ["PULL_NEAREST"] = function(data)
        serverFunctions.storeProximityVehicle(20.0)
      end,

      ['UPDATE_CUSTOM'] = function (res)
        if not skinshopOpen or type(res) ~= "table" or type(res.custom) ~= "table" then return false end
        local index = tonumber(res.index)
        if not index or index % 1 ~= 0 then return false end
        local item = getShopCloth(index)
        if not item or item.index_name ~= res.custom.index_name then return false end
        if type(res.custom.model) ~= "table" or type(res.custom.texture) ~= "table" then return false end
        res.custom.id = item.id
        res.custom.type = item.type
        if not changeCloth(res.custom) then return false end

        updateNuiLimitCloths(index, res.custom)

        return true
      end,

      ['HORIZONTAL'] = function(floatPos)
        moveCamPosition('HORIZONTAL', floatPos)
        return true
      end,

      ['VERTICAL'] = function(floatPos)
        moveCamPosition('VERTICAL', floatPos)
        return true
      end,

      ['ROTATE'] = function (rotation)
        userRotate(rotation)
        return true
      end,

      ['CAM'] = function(camPos)
        changeCamPosition(camPos)
        return true
      end,

      ['SAVE'] = function()
        if not skinshopOpen or purchasePending then return false end
        purchasePending = true
        local ok, message = clientFunctions.saveClothInServer()
        purchasePending = false
        if ok then
            TriggerEvent("Notify", "sucesso", ("Roupas salvas. Valor pago: R$ %d."):format(SkinshopPurchasePrice), 5)
        else
            TriggerEvent("Notify", "negado", message or "Não foi possível salvar as roupas.", 5)
        end
        return ok, message
      end,

      ['CLOSE'] = function(res)
        if purchasePending then return false end
        if skinshopOpen then clientFunctions.closeNuiShopAndReset() end
        return true
     end,
}

exports("handleShopUi", function(action, data)
    if GetInvokingResource() ~= "intc_lojaroupas" or not skinshopOpen or not routes[action] then return false end
    return routes[action](data)
end)

local function RegisterRoutes()
    for k, v in pairs(routes) do
      RegisterNuiCallback(k, function(data, cb)
        local response = v(data)
        cb(response)
      end)
    end
  end
CreateThread(RegisterRoutes)


