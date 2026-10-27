
Config = Config or {}
Config.RouteBlips = Config.RouteBlips or {}

local function farmVec3(c)
    if type(c) ~= 'table' then return vec3(0.0,0.0,0.0) end
    return vec3(tonumber(c.x or c[1]) or 0.0, tonumber(c.y or c[2]) or 0.0, tonumber(c.z or c[3]) or 0.0)
end

local function normalizeFarmClient(data)
    Config = data or {}
    Config.RouteBlips = Config.RouteBlips or {}
    for _,regions in pairs(Config.RouteBlips) do
        for _,points in pairs(regions) do
            for _,p in ipairs(points) do
                if p.coords then p.coords=farmVec3(p.coords) end
            end
        end
    end
end

RegisterNetEvent('m_farm:configSync', normalizeFarmClient)

CreateThread(function()
    Wait(500)
    TriggerServerEvent('m_farm:requestConfig')
end)

local Tunnel = module('vrp','lib/Tunnel')
local Proxy = module('vrp','lib/Proxy')
vRP = Proxy.getInterface('vRP')

ClientAPI = {}
Tunnel.bindInterface(GetCurrentResourceName(), ClientAPI)
ServerAPI = Tunnel.getInterface(GetCurrentResourceName())

local actualRoute = nil
local actualRegion = nil
local actualBlip = nil
local routeBlip = nil

--- @param x number
--- @param y number
--- @param z number
--- @param text string
--- @return void
local function DrawText3D(x, y, z, text)
	local onScreen,_x,_y = World3dToScreen2d(x,y,z)
	SetTextFont(4)
	SetTextScale(0.35,0.35)
	SetTextColour(255,255,255,100)
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(_x,_y)
	local factor = (string.len(text)) / 400
	DrawRect(_x,_y+0.0125,0.01+factor,0.03,0,0,0,140)
end

--- @return void
local function removeBlip()
    if routeBlip and DoesBlipExist(routeBlip) then
        RemoveBlip(routeBlip)
        routeBlip = nil
    end
end

--- @param coords vector3
--- @return void
local function createBlip(coords)
    removeBlip()
    routeBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
	SetBlipSprite(routeBlip,433)
	SetBlipColour(routeBlip,5)
	SetBlipScale(routeBlip,0.4)
	SetBlipAsShortRange(routeBlip,false)
	SetBlipRoute(routeBlip,true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Destino")
	EndTextCommandSetBlipName(routeBlip)
end

--- @return void
local function endRoute()
    actualRoute = nil
    actualRegion = nil
    actualBlip = nil
    removeBlip()
    ServerAPI.finishRoute()
end

--- @param routes table
--- @return void
function ClientAPI.openRoutes(routes)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        routes = routes
    })
end

--- @param route number
--- @param region string
--- @return void
function ClientAPI.startRoute(route, region)
    actualRoute = route
    actualRegion = region
    actualBlip = 1
    routeThread()
    local firstBlipCoords = Config.RouteBlips[actualRoute][actualRegion][actualBlip].coords
    createBlip(firstBlipCoords)
end

--- @param text string
--- @param x number
--- @param y number
--- @return void
function drawTxt(text, x, y)
    local res_x, res_y = GetActiveScreenResolution()

    SetTextFont(4)
    SetTextScale(0.3,0.3)
    SetTextColour(255,255,255,255)
    SetTextOutline()
    SetTextCentre(1)
    SetTextEntry("STRING")
    AddTextComponentString(text)

    if res_x >= 2000 then
        DrawText(x+0.076,y)
    else
        DrawText(x,y)
    end
end

RegisterNUICallback('boost', function(data, cb)
    ServerAPI.boostRoute()
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    cb(true)
end)

RegisterNUICallback('start', function(data, cb)
    local route = data.route.name
    local region = data.region
    if not route or not region then
        return
    end
    ServerAPI.startRoute(route, region)
    cb(true)
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
end)

RegisterNUICallback('close', function(data, cb)
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    cb(true)
end)

RegisterCommand('+cancelroute', function(source, args)
    if actualRoute then
        endRoute()
    end
end)

-- CreateThread(function()
--     while true do 
--         local timeDistance = 1000
--         local ped = PlayerPedId()
--         local coords = GetEntityCoords(ped)
--         for k, v in ipairs(Config.Routes) do
--             local distance = #(coords - v.coords)
--             if distance <= 2.0 then
--                 timeDistance = 0
--                 DrawText3D(v.coords.x, v.coords.y, v.coords.z, 'Pressione ~g~E~w~ para acessar as rotas.')
--                 DrawMarker(27, v.coords.x, v.coords.y, v.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 255, 255, 255, 0, 0, 0, 0)
--                 if IsControlJustPressed(0, 38) then
--                     ServerAPI.openRoutes(k)
--                 end
--             end
--         end
--         Wait(timeDistance)
--     end
-- end)

RegisterNetEvent('routes:initialize', function()
    ServerAPI.openRoutes()
end)

local function isPlayerInAirVehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 then
        local vehicleClass = GetVehicleClass(vehicle)
        return vehicleClass == 15 or vehicleClass == 16 -- 15: Helicópteros, 16: Aviões
    end
    return false
end

local function isPlayerInWaterVehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 then
        local vehicleClass = GetVehicleClass(vehicle)
        return vehicleClass == 14 -- 14: Barcos
    end
    return false
end

local function createCheckpointForBlip(blipIndex)

    local currentBlipData = Config.RouteBlips[actualRoute][actualRegion][blipIndex]
    local nextBlipData = Config.RouteBlips[actualRoute][actualRegion][blipIndex + 1]

    if not nextBlipData then 
        nextBlipData = Config.RouteBlips[actualRoute][actualRegion][1] -- Volta para o primeiro ponto se não houver próximo
    end


    if currentBlipData and nextBlipData then
        return CreateCheckpoint(
            actualRegion == "Water" and 35 or currentBlipData.blip, -- Tipo de checkpoint (47 é um tipo visual comum)
            currentBlipData.coords.x, currentBlipData.coords.y, currentBlipData.coords.z,
            nextBlipData.coords.x, nextBlipData.coords.y, nextBlipData.coords.z,
            50.0, 255, 0, 0, 70, 0
        )
    end
    return nil
end

local nextCheckpoint = nil
local hk_NetworkIsInTutorialSession = NetworkIsInTutorialSession
function routeThread()
    CreateThread(function()

        if actualRegion == "Air" then
            nextCheckpoint = createCheckpointForBlip(actualBlip)
        end

        while actualRoute do
            local timeDistance = 1000
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            if hk_NetworkIsInTutorialSession() then
                print("_")
                break
            end
            if actualBlip then
                local currentBlipData = Config.RouteBlips[actualRoute][actualRegion][actualBlip]
                local distance = #(currentBlipData.coords - coords)

                if actualRegion == "Air" and isPlayerInAirVehicle() then
                    timeDistance = 0
                    if distance <= 25.0 then
                        if ServerAPI.collectRoute(actualRoute, actualRegion, actualBlip) then
                            if nextCheckpoint then
                                DeleteCheckpoint(nextCheckpoint)
                                nextCheckpoint = nil
                            end
                            
                            actualBlip = actualBlip + 1
                
                            if actualBlip > #Config.RouteBlips[actualRoute][actualRegion] then
                                actualBlip = 1 -- Voltar para o primeiro ponto
                            end
                
                            createBlip(Config.RouteBlips[actualRoute][actualRegion][actualBlip].coords)
                            nextCheckpoint = createCheckpointForBlip(actualBlip) -- Certifique-se de recriar o checkpoint
                        end
                    end
                elseif actualRegion == "Water" and isPlayerInWaterVehicle() then
                    timeDistance = 0
                    DrawMarker(35, currentBlipData.coords.x, currentBlipData.coords.y, currentBlipData.coords.z + 15.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 20.0, 20.0, 20.0, 255, 0, 0, 255, 0, 0, 0, 0)
                    if distance <= 25.0 then
                        if ServerAPI.collectRoute(actualRoute, actualRegion, actualBlip) then
                            actualBlip = actualBlip + 1

                            if actualBlip > #Config.RouteBlips[actualRoute][actualRegion] then
                                actualBlip = 1 -- Voltar para o primeiro ponto
                            end

                            createBlip(Config.RouteBlips[actualRoute][actualRegion][actualBlip].coords)
                        end
                    end
                elseif actualRegion == "South" or actualRegion == "North" then
                    -- Rotas terrestres: interação com a tecla E
                    if distance <= 10.0 then
                        timeDistance = 0
                        DrawText3D(currentBlipData.coords.x, currentBlipData.coords.y, currentBlipData.coords.z, 'Pressione ~g~E~w~ para coletar.')
                        DrawMarker(27, currentBlipData.coords.x, currentBlipData.coords.y, currentBlipData.coords.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 255, 0, 255, 0, 0, 0, 0)
                        if IsControlJustPressed(0, 38) then
                            if ServerAPI.collectRoute(actualRoute, actualRegion, actualBlip) then
                                actualBlip = actualBlip + 1

                                if actualBlip > #Config.RouteBlips[actualRoute][actualRegion] then
                                    actualBlip = 1 -- Voltar para o primeiro ponto
                                end

                                createBlip(Config.RouteBlips[actualRoute][actualRegion][actualBlip].coords)

                            end
                        end
                    end
                end
            end
            Wait(timeDistance)
        end

        -- Certifique-se de deletar o checkpoint ao finalizar a rota
        if nextCheckpoint then
            DeleteCheckpoint(nextCheckpoint)
        end
    end)

    CreateThread(function()
        while actualRoute do
            local timeDistance = 1000
            if actualBlip then
                timeDistance = 0
                drawTxt("~w~Aperte ~r~F7~w~ se deseja finalizar o expediente.", 0.215, 0.94)
            end
            Wait(timeDistance)
        end
    end)
end




RegisterKeyMapping('+cancelroute', 'Cancelar rota', 'keyboard', 'F7')