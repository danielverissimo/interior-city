local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

local vRP = Proxy.getInterface("vRP")
local vSERVER = Tunnel.getInterface("drogas_entregas")

local panelOpen = false
local service = false
local saleBusy = false
local selectedDrug = nil
local currentPoint = nil
local routeBlip = nil
local mapBlip = nil
local dealerPed = nil

-- Garante que um restart/ensure nunca deixe a NUI ou o cursor presos na tela.
CreateThread(function()
    Wait(0)
    panelOpen = false
    SetNuiFocus(false, false)
    if SetNuiFocusKeepInput then
        SetNuiFocusKeepInput(false)
    end
    SendNUIMessage({ action = "close" })
end)

AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    panelOpen = false
    SetNuiFocus(false, false)
    if SetNuiFocusKeepInput then
        SetNuiFocusKeepInput(false)
    end
    SendNUIMessage({ action = "close" })
end)

local function notify(kind, message, duration)
    TriggerEvent("Notify", kind, message, duration or 5000)
end

local function closePanel()
    panelOpen = false
    SetNuiFocus(false, false)
    if SetNuiFocusKeepInput then
        SetNuiFocusKeepInput(false)
    end
    SendNUIMessage({ action = "close" })
end

local function removeRouteBlip()
    if routeBlip and DoesBlipExist(routeBlip) then
        RemoveBlip(routeBlip)
    end
    routeBlip = nil
end

local function setRoutePoint(point)
    removeRouteBlip()

    if type(point) ~= "table" then
        currentPoint = nil
        return
    end

    local index = tonumber(point.index)
    local configured = index and Config.RoutePoints and Config.RoutePoints[index]
    if not configured then
        currentPoint = nil
        return
    end

    currentPoint = {
        index = index,
        x = tonumber(point.x) or configured.x,
        y = tonumber(point.y) or configured.y,
        z = tonumber(point.z) or configured.z
    }

    local cfg = (Config.Route and Config.Route.routeBlip) or {}
    routeBlip = AddBlipForCoord(currentPoint.x, currentPoint.y, currentPoint.z)
    SetBlipSprite(routeBlip, tonumber(cfg.sprite) or 207)
    SetBlipColour(routeBlip, tonumber(cfg.color) or 1)
    SetBlipScale(routeBlip, tonumber(cfg.scale) or 0.50)
    SetBlipAsShortRange(routeBlip, false)
    SetBlipRoute(routeBlip, true)
    SetBlipRouteColour(routeBlip, tonumber(cfg.color) or 1)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(tostring(cfg.text or "Venda de Drogas"))
    EndTextCommandSetBlipName(routeBlip)
end

local function stopRoute(showMessage)
    service = false
    saleBusy = false
    selectedDrug = nil
    currentPoint = nil
    removeRouteBlip()

    if showMessage then
        notify("aviso", "Você encerrou a rota de venda de drogas.")
    end
end

local function openPanel()
    if service then
        notify("aviso", "Você já está em uma rota. Pressione <b>F7</b> para encerrar.")
        return
    end

    local data = vSERVER.getMenuData()
    if type(data) ~= "table" or data.ok ~= true then return end

    panelOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "open",
        imageBaseUrl = data.imageBaseUrl or Config.ImageBaseUrl or "",
        reputation = data.reputation,
        drugs = data.drugs or {}
    })
end

RegisterNetEvent("drogasentregas")
AddEventHandler("drogasentregas", function()
    openPanel()
end)

RegisterNetEvent("drogas_entregas:reputationUpdated")
AddEventHandler("drogas_entregas:reputationUpdated", function(reputation)
    if panelOpen then
        SendNUIMessage({ action = "reputation", reputation = reputation })
    end
end)

RegisterNetEvent("drogas_entregas:forceStopRoute")
AddEventHandler("drogas_entregas:forceStopRoute", function()
    if panelOpen then
        closePanel()
    end

    if service then
        stopRoute(false)
    end
end)

RegisterNUICallback("close", function(_, cb)
    closePanel()
    if cb then cb({ ok = true }) end
end)

RegisterNUICallback("startRoute", function(data, cb)
    local key = data and data.key
    local result = vSERVER.startRoute(key)

    if type(result) == "table" and result.ok == true and result.point then
        service = true
        selectedDrug = result.drug
        saleBusy = false
        setRoutePoint(result.point)
        closePanel()

        notify("sucesso", "Rota de <b>" .. tostring((selectedDrug and selectedDrug.label) or "drogas") .. "</b> iniciada.")
        notify("aviso", "Siga o GPS. Em cada ponto você poderá vender a quantidade configurada.", 6000)
    elseif type(result) == "table" and result.message then
        notify("negado", tostring(result.message), 5000)
    end

    if cb then cb(result or { ok = false }) end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local start = Config.Start and Config.Start.coords

        if start then
            local distance = #(coords - vector3(start.x, start.y, start.z))
            if distance <= (tonumber(Config.Start.drawDistance) or 12.0) then
                sleep = 0

                local marker = Config.Start.marker or {}
                local scale = marker.scale or {}
                local color = marker.color or {}
                DrawMarker(
                    tonumber(marker.type) or 31,
                    start.x, start.y, start.z - 0.60,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    tonumber(scale.x) or 0.50, tonumber(scale.y) or 0.50, tonumber(scale.z) or 0.40,
                    tonumber(color.r) or 108, tonumber(color.g) or 54, tonumber(color.b) or 255, tonumber(color.a) or 115,
                    false, false, 2, false, nil, nil, false
                )

                DrawText3D(start.x, start.y, start.z + 0.25, service and "~p~ROTA CLANDESTINA~w~\nPressione ~r~F7~w~ para encerrar" or "~p~ROTAS CLANDESTINAS~w~\nPressione ~b~E~w~ para escolher a droga")

                if not panelOpen and not service and distance <= (tonumber(Config.Start.interactDistance) or 1.5) and IsControlJustPressed(0, 38) then
                    openPanel()
                end
            end
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000

        if service and currentPoint then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local target = vector3(currentPoint.x, currentPoint.y, currentPoint.z)
            local distance = #(coords - target)
            local drawDistance = tonumber((Config.Route and Config.Route.clientDrawDistance) or 15.0) or 15.0

            if distance <= drawDistance then
                sleep = 0
                local marker = (Config.Route and Config.Route.marker) or {}
                local scale = marker.scale or {}
                local color = marker.color or {}

                DrawMarker(
                    tonumber(marker.type) or 21,
                    currentPoint.x, currentPoint.y, currentPoint.z + 0.15,
                    0.0, 0.0, 0.0,
                    0.0, 180.0, 130.0,
                    tonumber(scale.x) or 1.25, tonumber(scale.y) or 1.25, tonumber(scale.z) or 0.85,
                    tonumber(color.r) or 139, tonumber(color.g) or 92, tonumber(color.b) or 246, tonumber(color.a) or 135,
                    true, false, 2, true, nil, nil, false
                )

                if distance <= (tonumber((Config.Route and Config.Route.interactDistance) or 2.5) or 2.5) then
                    drawTxt("PRESSIONE  ~y~E~w~  PARA REALIZAR A VENDA", 4, 0.5, 0.92, 0.35, 255, 255, 255, 200)

                    if not saleBusy and IsControlJustPressed(0, 38) then
                        saleBusy = true
                        local result = vSERVER.attemptSale()

                        if type(result) ~= "table" then
                            notify("negado", "Não foi possível processar esta venda.")
                        elseif result.ended == true then
                            stopRoute(false)
                            if result.message then notify("aviso", tostring(result.message)) end
                        elseif result.ok == true and result.nextPoint then
                            setRoutePoint(result.nextPoint)
                        elseif result.ok == false and result.message then
                            notify("negado", tostring(result.message))
                        end

                        SetTimeout(650, function()
                            saleBusy = false
                        end)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        if service then
            local label = selectedDrug and selectedDrug.label or "Drogas"
            drawTxt("ROTA: ~p~" .. tostring(label) .. "~w~  |  ~y~F7~w~ PARA FINALIZAR", 4, 0.5, 0.965, 0.31, 255, 255, 255, 190)
            Wait(0)
        else
            Wait(700)
        end
    end
end)

RegisterCommand("cancelardrogas", function()
    if panelOpen then
        closePanel()
        return
    end

    if not service then return end

    vSERVER.cancelRoute()
    stopRoute(true)
end, false)

RegisterKeyMapping("cancelardrogas", "Encerrar rota de venda de drogas", "keyboard", "F7")

CreateThread(function()
    local cfg = Config.MapBlip or {}
    if cfg.enabled == false then return end
    local c = cfg.coords
    if not c then return end

    mapBlip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(mapBlip, tonumber(cfg.sprite) or 310)
    SetBlipColour(mapBlip, tonumber(cfg.color) or 1)
    SetBlipScale(mapBlip, tonumber(cfg.scale) or 0.70)
    SetBlipAsShortRange(mapBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(tostring(cfg.text or "Zona Perigosa | Venda Drogas"))
    EndTextCommandSetBlipName(mapBlip)
end)

CreateThread(function()
    local cfg = Config.NPC or {}
    if cfg.enabled == false then return end
    if not cfg.coords or not cfg.model then return end

    local model = GetHashKey(tostring(cfg.model))
    RequestModel(model)

    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(20)
    end

    if not HasModelLoaded(model) then return end

    dealerPed = CreatePed(4, model, cfg.coords.x, cfg.coords.y, cfg.coords.z - 1.0, tonumber(cfg.heading) or 0.0, false, true)
    if DoesEntityExist(dealerPed) then
        FreezeEntityPosition(dealerPed, true)
        SetEntityInvincible(dealerPed, true)
        SetBlockingOfNonTemporaryEvents(dealerPed, true)
    end

    SetModelAsNoLongerNeeded(model)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    panelOpen = false
    SetNuiFocus(false, false)
    if SetNuiFocusKeepInput then
        SetNuiFocusKeepInput(false)
    end
    SendNUIMessage({ action = "close" })
    removeRouteBlip()

    if mapBlip and DoesBlipExist(mapBlip) then
        RemoveBlip(mapBlip)
    end

    if dealerPed and DoesEntityExist(dealerPed) then
        DeleteEntity(dealerPed)
    end
end)

function drawTxt(text, font, x, y, scale, r, g, b, a)
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

function DrawText3D(x, y, z, text)
    local onScreen, screenX, screenY = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 225)
    SetTextCentre(true)
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(screenX, screenY)
end
