-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- VRP
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPserver = Tunnel.getInterface("vRP","m_snippets")

src = {}
Tunnel.bindInterface("m_snippets",src)
vSERVER = Tunnel.getInterface("m_snippets")


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- VARIAVEIS
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local segundos = 0
local trancas = config.doors

-----------------------------------------------------------------------------------------------------------------------------------------
-- SISTEMA DE TRANCAS
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	for k,v in pairs(trancas) do
		
		AddDoorToSystem(k, v.hash[1], v.coords)
	end
	while true do
		local time = 1000
		local pedCoords = GetEntityCoords(PlayerPedId())
		
		for k,v in pairs(trancas) do
			local inVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
			if inVehicle == nil or inVehicle == 0 then
				local distance = #(pedCoords - v.coords)
				if distance <= v.distance then
					time = 5
					if trancas[k].trancado[1] then
						DrawText3Ds(v.coords[1],v.coords[2],v.coords[3], "🔒")
					else
						DrawText3Ds(v.coords[1],v.coords[2],v.coords[3], "🔓")
					end

					if distance <= 2.5 then
						if IsControlJustPressed(0,38) and segundos <= 0 then
							segundos = 5
							if trancas[k].trancado[1] then
								vRP._playAnim(true,{{"veh@mower@base","start_engine"}},false)
								Citizen.Wait(2200)
								if vSERVER.syncLock(k, false, trancas[k].perm[1]) then
									TriggerEvent("Notify","negado","Porta destrancada.", 5)
									DoorSystemSetDoorState(k, 0)
								end
							else
								vRP._playAnim(true,{{"veh@mower@base","start_engine"}},false)
								Citizen.Wait(2200)
								if vSERVER.syncLock(k, true, trancas[k].perm[1]) then
									TriggerEvent("Notify","sucesso","Porta trancada.", 5)
									DoorSystemSetDoorState(k, 1)
								end
							end
						end
					end

				end
			else
				local distance = #(pedCoords - v.coords)
				if distance <= v.distance+3 then
					time = 5

					if trancas[k].trancado[1] then
						DrawText3Ds(v.coords[1],v.coords[2],v.coords[3], "[PORTA]: ~r~TRANCADA")
					else
						DrawText3Ds(v.coords[1],v.coords[2],v.coords[3], "[PORTA]: ~g~DESTRANCADA")
					end

					if IsControlJustPressed(0,38) and segundos <= 0 then
						segundos = 5
						if trancas[k].trancado[1] then
							vRP._playAnim(true,{{"veh@mower@base","start_engine"}},false)
							Citizen.Wait(2200)
							if vSERVER.syncLock(k, false, trancas[k].perm[1]) then
								TriggerEvent("Notify","negado","Porta destrancada.", 5)
								DoorSystemSetDoorState(k, 0)
							end
						else
							vRP._playAnim(true,{{"veh@mower@base","start_engine"}},false)
							Citizen.Wait(2200)
							if vSERVER.syncLock(k, true, trancas[k].perm[1]) then
								TriggerEvent("Notify","sucesso","Porta trancada.", 5)
								DoorSystemSetDoorState(k, 1)
							end
						end
					end
				end
			end
		end
	
		Citizen.Wait(time)
	end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- SYNCRONIZAR PORTAS
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
		local time = 500
		local pedCoords = GetEntityCoords(PlayerPedId())
		for k,v in pairs(trancas) do
			local distance = #(pedCoords - v.coords)
			if distance <= 20.0 then
				local door = GetClosestObjectOfType(v.coords[1],v.coords[2],v.coords[3],5.0,trancas[k].hash[1],false,false,false)
				SetEntityCanBeDamaged(door,false)
				if v.trancado[1] == false then
					NetworkRequestControlOfEntity(door)
					FreezeEntityPosition(door,false)
				else
					local lock,heading = GetStateOfClosestDoorOfType(v.hash[1],v.coords[1],v.coords[2],v.coords[3],lock,heading)
					if heading > -0.02 and heading < 0.02 then
						NetworkRequestControlOfEntity(door)
						FreezeEntityPosition(door,true)
					end
				end
			end
		end

		Citizen.Wait(time)
	end
end)


function src.setLock(id, status)
	if id then
		trancas[id].trancado[1] = status
	end
end

function src.syncAllLock(value)
	for k in pairs(value) do
		trancas[k].trancado[1] = value[k]
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SISTEMA DE ELEVADOR
-----------------------------------------------------------------------------------------------------------------------------------------
local elevatorRuntime = {}

local function rebuildElevators(list)
    config.elevador = {}
    config.locationElevador = {}
    elevatorRuntime = {}

    for _,elevator in ipairs(type(list) == "table" and list or {}) do
        local id = tostring(elevator.id or "")

        if id ~= "" then
            local runtime = {
                id = id,
                name = tostring(elevator.name or id),
                permission = tostring(elevator.permission or ""),
                drawDistance = tonumber(elevator.drawDistance) or (config.elevadorDefaults and config.elevadorDefaults.drawDistance) or 12.0,
                interactionDistance = tonumber(elevator.interactionDistance) or (config.elevadorDefaults and config.elevadorDefaults.interactionDistance) or 2.0,
                andares = {},
                floors = {}
            }

            for _,floor in ipairs(type(elevator.floors) == "table" and elevator.floors or {}) do
                local name = tostring(floor.name or "")
                local c = floor.coords or {}
                local x = tonumber(c.x or c[1])
                local y = tonumber(c.y or c[2])
                local z = tonumber(c.z or c[3])
                local w = tonumber(c.w or c[4]) or 0.0

                if name ~= "" and x and y and z then
                    runtime.andares[name] = { x, y, z, w }
                    runtime.floors[#runtime.floors + 1] = {
                        name = name,
                        coords = { x = x, y = y, z = z, w = w }
                    }

                    config.locationElevador[#config.locationElevador + 1] = {
                        type = id,
                        coords = vec3(x, y, z),
                        andar = name,
                        perm = runtime.permission,
                        drawDistance = runtime.drawDistance,
                        interactionDistance = runtime.interactionDistance
                    }
                end
            end

            config.elevador[id] = runtime
            elevatorRuntime[id] = runtime
        end
    end
end

RegisterNetEvent("m_snippets:syncElevators", function(list)
    rebuildElevators(list)
end)

CreateThread(function()
    Wait(800)
    TriggerServerEvent("m_snippets:requestElevators")
end)

Citizen.CreateThread(function()
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)
        local defaults = config.elevadorDefaults or {}
        local marker = defaults.marker or {}
        local markerColor = marker.color or { 236,72,153,190 }
        local markerScale = marker.scale or { 0.40,0.10,0.50 }

        for _,point in ipairs(config.locationElevador or {}) do
            local distance = #(playerCoords - point.coords)
            local drawDistance = tonumber(point.drawDistance) or tonumber(defaults.drawDistance) or 12.0
            local interactionDistance = tonumber(point.interactionDistance) or tonumber(defaults.interactionDistance) or 2.0

            if distance <= drawDistance then
                wait = 0

                DrawMarker(
                    tonumber(marker.type) or 20,
                    point.coords.x, point.coords.y, point.coords.z + (tonumber(marker.zOffset) or -0.70),
                    0.0,0.0,0.0, 0.0,0.0,130.0,
                    tonumber(markerScale[1]) or 0.40,
                    tonumber(markerScale[2]) or 0.10,
                    tonumber(markerScale[3]) or 0.50,
                    tonumber(markerColor[1]) or 236,
                    tonumber(markerColor[2]) or 72,
                    tonumber(markerColor[3]) or 153,
                    tonumber(markerColor[4]) or 190,
                    false,false,2,false,nil,nil,false
                )

                if distance <= interactionDistance then
                    DrawText3Ds(
                        point.coords.x,
                        point.coords.y,
                        point.coords.z + 0.20,
                        "~w~PRESSIONE ~p~[E]~w~ PARA USAR O ELEVADOR"
                    )

                    if IsControlJustReleased(0, 38) and segundos <= 0 then
                        local elevator = elevatorRuntime[point.type]

                        if elevator then
                            if point.perm and point.perm ~= "" and not vSERVER.checkPermission(point.perm) then
                                TriggerEvent("Notify","negado","Você não possui permissão para utilizar este elevador.",5000)
                            else
                                openElevador(point.type, point.andar, elevator.floors, point.perm)
                            end
                        end
                    end
                end
            end
        end

        Citizen.Wait(wait)
    end
end)

function openElevador(tipo, andar, floors, perm)
    if perm and perm ~= "" and not vSERVER.checkPermission(perm) then
        TriggerEvent("Notify","negado","Você não possui permissão para utilizar este elevador.",5000)
        return
    end

    SetNuiFocus(true,true)
    SendNUIMessage({
        showmenu = true,
        tipo = tipo,
        andar = andar,
        elevador = floors or {}
    })
end

function updateElevador(tipo, andar)
    local elevator = elevatorRuntime[tostring(tipo or "")]
    local destination = elevator and elevator.andares and elevator.andares[tostring(andar or "")]

    if not destination then
        TriggerEvent("Notify","negado","Andar do elevador não encontrado.",5000)
        return
    end

    local ped = PlayerPedId()

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    SetNuiFocus(false,false)
    SendNUIMessage({ hidemenu = true })

    RequestCollisionAtCoord(destination[1],destination[2],destination[3])
    SetEntityCoordsNoOffset(ped,destination[1],destination[2],destination[3],false,false,false)

    if destination[4] then
        SetEntityHeading(ped,tonumber(destination[4]) or GetEntityHeading(ped))
    end

    local timeout = GetGameTimer() + 2500
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < timeout do
        RequestCollisionAtCoord(destination[1],destination[2],destination[3])
        Wait(50)
    end

    Wait(250)
    DoScreenFadeIn(500)
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CALL BACKS
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("closeNui",function(data,cb)
	SetNuiFocus(false)
	SendNUIMessage({ hidemenu = true })
end)

RegisterNUICallback("elevadorInit",function(data,cb)
	if segundos <= 0 then
		segundos = 5
		updateElevador(data.elevador, data.andar)
	end
end)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SOUNDS
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent('vrp_sound:source')
AddEventHandler('vrp_sound:source',function(sound,volume)
	SendNUIMessage({ transactionType = 'playSound', transactionFile = sound, transactionVolume = volume })
end)

RegisterNetEvent('vrp_sound:distance')
AddEventHandler('vrp_sound:distance', function(playerNetId, maxDistance, soundFile, soundVolume)
    local lCoords = GetEntityCoords(GetPlayerPed(-1))
    local eCoords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(playerNetId)))
    local distIs = Vdist(lCoords.x, lCoords.y, lCoords.z, eCoords.x, eCoords.y, eCoords.z)
    if (distIs <= maxDistance) then
        SendNUIMessage({ transactionType = 'playSound', transactionFile = soundFile, transactionVolume = soundVolume })
    end
end)  

RegisterNetEvent('vrp_sound:fixed')
AddEventHandler('vrp_sound:fixed',function(playerid,x2,y2,z2,maxdistance,sound,volume)
	local ped = PlayerPedId()
	local x,y,z = table.unpack(GetEntityCoords(ped))
	local distance = GetDistanceBetweenCoords(x2,y2,z2,x,y,z,true)
	if distance <= maxdistance then
		SendNUIMessage({ transactionType = 'playSound', transactionFile = sound, transactionVolume = volume })
	end
end) 

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- BLIPS NO MAPA - SINCRONIZAÇÃO DINÂMICA
-----------------------------------------------------------------------------------------------------------------------------------------
local mapBlips = {}

local function clearMapBlips()
    for _,blip in pairs(mapBlips) do
        if blip and DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end

    mapBlips = {}
end

local function rebuildMapBlips(list)
    clearMapBlips()

    config.blips = {}

    for _,v in ipairs(type(list) == "table" and list or {}) do
        local c = v.coords or {}

        local x = tonumber(c.x) or 0.0
        local y = tonumber(c.y) or 0.0
        local z = tonumber(c.z) or 0.0
        local sprite = tonumber(v.sprite) or 1
        local color = tonumber(v.color) or 0
        local scale = tonumber(v.scale) or 0.5
        local name = tostring(v.name or "Marcação")

        config.blips[#config.blips + 1] = {
            x,
            y,
            z,
            sprite,
            color,
            name,
            scale
        }

        local blip = AddBlipForCoord(
            x + 0.001,
            y + 0.001,
            z + 0.001
        )

        SetBlipSprite(blip, sprite)
        SetBlipAsShortRange(
            blip,
            v.shortRange ~= false
        )
        SetBlipColour(blip, color)
        SetBlipScale(blip, scale)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(name)
        EndTextCommandSetBlipName(blip)

        mapBlips[tostring(v.id or #config.blips)] = blip
    end
end

RegisterNetEvent(
    "m_snippets:syncMapBlips",
    function(list)
        rebuildMapBlips(list)
    end
)

CreateThread(function()
    Wait(700)
    TriggerServerEvent(
        "m_snippets:requestMapBlips"
    )
end)

function DrawText3Ds(x,y,z,text)
	local onScreen,_x,_y = World3dToScreen2d(x,y,z)
	SetTextFont(4)
	SetTextScale(0.35,0.35)
	SetTextColour(255,255,255,150)
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(_x,_y)
	local factor = (string.len(text))/370
	DrawRect(_x,_y+0.0125,0.01+factor,0.03,0,0,0,80)
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONTADOR
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
		local time = 1000
		if segundos > 0 then
			segundos = segundos - 1
			
			if segundos <= 0 then
				segundos = 0
			end

		end
		Citizen.Wait(time)
	end
end)

--local inZoneAurora = false 
--local explosionAurora = false
--
--local ZoneAurora = PolyZone:Create({
--	vector2(669.16955566406, 3447.6110839844),
--	vector2(844.91400146484, 3452.6159667969),
--	vector2(856.39886474609, 3217.1520996094),
--	vector2(756.26599121094, 3210.0786132813)
--  }, {
--	name="Casa Aurora",
--	--minZ = 38.417961120605,
--	--maxZ = 58.228965759277
--  })
--
--local function CheckPlayerZone()
--	if trancas[364].trancado[1] == true and trancas[365].trancado[1] == true then
--		if inZoneAurora and not explosionAurora then 
--			explosionAurora = true 
--			TriggerEvent("Notify",'importante','Saia destá área em 10 segundos ou o alarme irá disparar.')
--			Wait(9000)
--			TriggerEvent("vrp_sound:source","alarm",0.5)
--			Wait(1000)
--			if inZoneAurora then 
--				local x,y,z = table.unpack(GetEntityCoords(PlayerPedId()))
--				AddExplosion(x,y,z, 'GRENADE', 2.0, true, false, 2.0)
--				StartEntityFire(PlayerPedId())
--				SetEntityHealth(PlayerPedId(), 101)
--			end
--			explosionAurora = false
--		end
--	end
--end
--  
--ZoneAurora:onPlayerInOut(function(naZona, _)
--	if not vSERVER.allowHouse() then
--		inZoneAurora = naZona
--		CheckPlayerZone()
--	end
--end)


RegisterNetEvent("doors:pending_coords", function(data)
	if data then
		trancas[#trancas + 1] = data
	end
end)