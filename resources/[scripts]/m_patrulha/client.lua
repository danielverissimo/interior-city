local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")

src = {}
Tunnel.bindInterface(GetCurrentResourceName(), src)
vSERVER = Tunnel.getInterface(GetCurrentResourceName())

local nui = false
local in_patrulha = false
local pos = 1
local blips = nil
local policia = nil
local patrolCheckpoint = nil

-----------------------------------------------------------------------------
------ MAIN THREAD NUI
-----------------------------------------------------------------------------

Citizen.CreateThread(function()
    while true do
        local idle = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for k,v in pairs(cfg.data) do
            local distance = #(vec3(coords[1],coords[2],coords[3]) - vec3(v.inicio[1],v.inicio[2],v.inicio[3]))

            if distance <= 10.0 then
                idle = 1
                DrawMarker(27,v.inicio[1],v.inicio[2],v.inicio[3] - 0.95,0,0,0,0,0,0,1.5,1.5,1.5,132,102,226,180,0,0,0,1)
                if distance <= 3.0 then
                    DrawText3D(v.inicio[1],v.inicio[2],v.inicio[3], "~b~[POLICIA "..k.."]~w~ Iniciar Patrulha\n")
                    if distance <= 5.0 and IsControlJustPressed(0, 38) and not nui then
                        if vSERVER.checkPerm(v.permissao) then
                            if not nui then
                                
                                SetNuiFocus(true,true)
                                -- TransitionToBlurred(1000)
                                SendNUIMessage({ 
                                    show = true,
                                    policia = k,
                                    ranking = vSERVER.checkRanking(k)
                                })
                                nui = true
                                
                            end                  
                        end
                    end
                end
            end
        end
        Citizen.Wait(idle)
    end
end)

RegisterNUICallback("confirm", function(data, callback)

    if not in_patrulha then

        policia = data.policia

        if data.tipo == 'sul' then
            src.iniciar_sul()
        elseif data.tipo == 'norte' then
            src.iniciar_norte()
        end
    else
        TriggerClientEvent('Notify','negado','Você ja está em patrulha!')
    end

end)

src.iniciar_sul = function()
    in_patrulha = true

    -- cria o primeiro ponto
    createPatrolTarget(
        cfg.data[policia].sul[pos][1],
        cfg.data[policia].sul[pos][2],
        cfg.data[policia].sul[pos][3]
    )

    Citizen.CreateThread(function()
        while in_patrulha do
            local idle = 1000
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            local x = cfg.data[policia].sul[pos][1]
            local y = cfg.data[policia].sul[pos][2]
            local z = cfg.data[policia].sul[pos][3]

            local distance = #(coords - vector3(x, y, z))

            if distance <= 30.0 then
                idle = 1
                if distance <= 1.0 then

                    if pos == #cfg.data[policia].sul then
                        pos = 1
                    else
                        pos = pos + 1
                    end

                    TriggerServerEvent('m_patrulha:upgrade_rank',policia)
                    PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)  
                    
                    createPatrolTarget(
                        cfg.data[policia].sul[pos][1],
                        cfg.data[policia].sul[pos][2],
                        cfg.data[policia].sul[pos][3]
                    )
                end
            end

            Citizen.Wait(idle)
        end

        -- ao sair da patrulha, limpa tudo
        removePatrolTarget()
    end)
end


src.iniciar_norte = function()
    in_patrulha = true

    -- cria o primeiro ponto
    createPatrolTarget(
        cfg.data[policia].norte[pos][1],
        cfg.data[policia].norte[pos][2],
        cfg.data[policia].norte[pos][3]
    )

    Citizen.CreateThread(function()
        while in_patrulha do
            local idle = 1000
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            local x = cfg.data[policia].norte[pos][1]
            local y = cfg.data[policia].norte[pos][2]
            local z = cfg.data[policia].norte[pos][3]

            local distance = #(coords - vector3(x, y, z))

            if distance <= 30.0 then
                idle = 1
                if distance <= 1.0 then

                    if pos == #cfg.data[policia].norte then
                        pos = 1
                    else
                        pos = pos + 1
                    end

                    TriggerServerEvent('m_patrulha:upgrade_rank',policia)
                    PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)  
                    
                    createPatrolTarget(
                        cfg.data[policia].norte[pos][1],
                        cfg.data[policia].norte[pos][2],
                        cfg.data[policia].norte[pos][3]
                    )
                end
            end

            Citizen.Wait(idle)
        end

        -- ao sair da patrulha, limpa tudo
        removePatrolTarget()
    end)
end

RegisterNUICallback("close", function(data, callback)
    SetNuiFocus(false,false)
    TransitionFromBlurred(1000)            
    nui = false 
end)

RegisterNUICallback("encerrar_ptr", function(data, callback)
    SetNuiFocus(false,false)
    TransitionFromBlurred(1000)    
    RemoveBlip(blips)   
    removePatrolTarget()     
    nui = false 
    in_patrulha = false
    pos = 1
end)


RegisterCommand("ptr", function(source, args)
    local ped = PlayerPedId()
    if not ped or ped == 0 then return end

    local veh = GetVehiclePedIsIn(ped, false)
    if not veh or veh == 0 then return end

    -- só o motorista pode usar
    if GetPedInVehicleSeat(veh, -1) ~= ped then return end

    local kmh = tonumber(60)
    if not kmh or kmh <= 0 then
        
        return
    end

    -- converte km/h para m/s
    local speed = kmh / 3.6

    SetVehicleMaxSpeed(veh, speed)

end)

RegisterCommand("rptr", function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if not veh or veh == 0 then return end

    SetVehicleMaxSpeed(veh, GetVehicleHandlingFloat(veh, "CHandlingData", "fInitialDriveMaxFlatVel"))
end)

-----------------------------------------------------------------------------
------ THREAD CANCEL
-----------------------------------------------------------------------------

Citizen.CreateThread(function()
    local ped = PlayerPedId()
	while true do
      local trava = 1000
      if in_patrulha then
		trava = 1

		drawTxt("~y~VOCÊ ESTÁ EM ~r~PATRULHAMENTO ~w~SIGA OS PONTOS NO MAPA",4,0.270,0.905,0.45,255,255,255,200)

      end
	  Citizen.Wait(trava)
	end
end)


-----------------------------------------------------------------------------
------ OTHER GERAL CLIENT FUNCTIONS
-----------------------------------------------------------------------------

function DrawText3D(x,y,z,text)
	local onScreen,_x,_y = World3dToScreen2d(x,y,z)
	SetTextFont(4)
	SetTextScale(0.35,0.35)
	SetTextColour(255,255,255,100)
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(_x,_y)
	local factor = (string.len(text)) / 400
	DrawRect(_x,_y+0.0125,0.03+factor,0.04,0,0,0,100)
end

function drawTxt(text,font,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(r,g,b,a)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end

function criandoblip(x,y,z)
	blips = AddBlipForCoord(x,y,z)
	SetBlipSprite(blips,1)
	SetBlipColour(blips,5)
	SetBlipScale(blips,0.4)
	SetBlipAsShortRange(blips,false)
	SetBlipRoute(blips,true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Destino")
	EndTextCommandSetBlipName(blips)
end

function createPatrolTarget(x, y, z)
    removePatrolTarget()

    -- ✅ CHECKPOINT estilo corrida (bem visível no mundo)
    -- Tipo 47 costuma lembrar bastante checkpoint de corrida (anel/coluna)
    patrolCheckpoint = CreateCheckpoint(
        47,             -- type
        x, y, z - 1.0,  -- pos
        0.0, 0.0, 0.0,  -- next pos (não usado)
        3.5,            -- radius/tamanho
        255, 60, 60, 180, -- RGBA (vermelho suave, bem visível)
        0               -- reserved
    )

    -- ✅ BLIP + ROTA (linha no mapa igual waypoint)
    patrolBlip = AddBlipForCoord(x, y, z)
    SetBlipSprite(patrolBlip, 1)          -- 1 = padrão (ponto)
    SetBlipScale(patrolBlip, 0.9)
    SetBlipColour(patrolBlip, 1)          -- 1 = vermelho
    SetBlipAsShortRange(patrolBlip, false)
    SetBlipFlashes(patrolBlip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Patrulha")
    EndTextCommandSetBlipName(patrolBlip)

    -- rota no minimapa
    SetBlipRoute(patrolBlip, true)
    SetBlipRouteColour(patrolBlip, 1)
end

function removePatrolTarget()
    if patrolBlip then
        RemoveBlip(patrolBlip)
        patrolBlip = nil
    end

    if patrolCheckpoint then
        DeleteCheckpoint(patrolCheckpoint)
        patrolCheckpoint = nil
    end
end