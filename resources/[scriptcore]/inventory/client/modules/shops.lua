local ShopBlips = {}
local shopOpen = false
local activeShopName = nil

local function clearShopBlips()
    for _,blip in ipairs(ShopBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    ShopBlips = {}
end

local function convertPoint(point)
    if type(point) ~= "table" then return nil end
    local c = point.coords or point
    local x,y,z = tonumber(c.x or c[1]),tonumber(c.y or c[2]),tonumber(c.z or c[3])
    if not x or not y or not z then return nil end

    return { coords = vec3(x,y,z), blip = point.blip == true }
end

local function normalizeClientShops(raw)
    local out = {}

    for name,data in pairs(raw or {}) do
        local shop = { items = {}, mode = data.mode or "buy", coords = {} }

        for item,price in pairs(data.items or {}) do
            shop.items[item] = tonumber(price) or 0
        end

        if data.perm and data.perm ~= "" then shop.perm = data.perm end
        if data.onlyWalletPayment == true then shop.onlyWalletPayment = true end

        if type(data.blip) == "table" then
            shop.blip = {
                text = data.blip.text or "Loja",
                index = tonumber(data.blip.index) or 52,
                color = tonumber(data.blip.color) or 0,
                scale = tonumber(data.blip.scale) or 0.5
            }
        end

        for _,point in pairs(data.coords or {}) do
            local p = convertPoint(point)
            if p then shop.coords[#shop.coords+1] = p end
        end

        out[name] = shop
    end

    return out
end

local function createSystemBlips()
    clearShopBlips()

    for _,shop in pairs(Shops or {}) do
        if shop.blip then
            for _,point in ipairs(shop.coords or {}) do
                if point.blip then
                    local b = AddBlipForCoord(point.coords.x,point.coords.y,point.coords.z)
                    SetBlipSprite(b,shop.blip.index)
                    SetBlipColour(b,shop.blip.color)
                    SetBlipScale(b,shop.blip.scale or 0.5)
                    SetBlipAsShortRange(b,true)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString(shop.blip.text)
                    EndTextCommandSetBlipName(b)
                    ShopBlips[#ShopBlips+1] = b
                end
            end
        end
    end
end

local function parseItems(items)
    local response = {}
    local keys = {}

    for item in pairs(items or {}) do keys[#keys+1] = item end
    table.sort(keys)

    for i,item in ipairs(keys) do
        response[tostring(i)] = { price = items[item], item = item, slot = tostring(i) }
    end

    return response
end

local function resetShopState()
    shopOpen = false
    activeShopName = nil
end

local function closeShop()
    if not shopOpen then return end
    resetShopState()
    SendNUIMessage({ route = "CLOSE_INVENTORY", payload = false })
    SetNuiFocus(false,false)
end

-- Quando a própria NUI é fechada por ESC/botão, o callback genérico do
-- inventário precisa também limpar o estado local da loja. Sem isso,
-- shopOpen permanecia true e impedia uma segunda abertura.
AddEventHandler("inventory:shops:nuiClosed", function()
    resetShopState()
end)

RegisterNetEvent("inventory:shops:fullSync",function(raw)
    closeShop()
    Shops = normalizeClientShops(raw)
    createSystemBlips()

    local count = 0
    for _ in pairs(Shops) do count = count + 1 end
    print(("^2[inventory]^7 %s loja(s) sincronizada(s) no client."):format(count))
end)

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(500) end
    Wait(1200)
    TriggerServerEvent("inventory:shops:requestSync")
end)

CreateThread(function()
    while true do
        local sleep = 750
        local ped = PlayerPedId()

        if GetEntityHealth(ped) > 101 then
            local pcoords = GetEntityCoords(ped)
            local nearestShop,nearestDistance = nil,99999.0

            for name,shop in pairs(Shops or {}) do
                for _,point in ipairs(shop.coords or {}) do
                    local distance = #(pcoords - point.coords)

                    if distance < 7.0 then
                        sleep = 0
                        DrawMarker(29,point.coords.x,point.coords.y,point.coords.z-0.4,0,0,0,0,180.0,0,0.7,0.7,0.7,0,0,255,75,1,0,0,1)

                        if distance < nearestDistance then
                            nearestShop = name
                            nearestDistance = distance
                        end
                    end
                end
            end

            if nearestShop and nearestDistance <= 1.3 and IsControlJustPressed(0,38) and not shopOpen then
                local shop = Shops[nearestShop]

                if not shop.perm or Remote.checkPermission(shop.perm) then
                    shopOpen = true
                    activeShopName = nearestShop

                    SendNUIMessage({
                        route = "OPEN_SHOP",
                        payload = {
                            mode = shop.mode,
                            store_name = nearestShop,
                            inventory = parseItems(shop.items)
                        }
                    })

                    SetNuiFocus(true,true)
                end
            end

            if shopOpen and activeShopName then
                local active = Shops[activeShopName]
                local stillNear = false

                if active then
                    for _,point in ipairs(active.coords or {}) do
                        if #(pcoords - point.coords) <= 7.0 then
                            stillNear = true
                            break
                        end
                    end
                end

                if not stillNear then closeShop() end
            end
        elseif shopOpen then
            closeShop()
        end

        Wait(sleep)
    end
end)

AddEventHandler("onResourceStop",function(resource)
    if resource == GetCurrentResourceName() then clearShopBlips() end
end)
