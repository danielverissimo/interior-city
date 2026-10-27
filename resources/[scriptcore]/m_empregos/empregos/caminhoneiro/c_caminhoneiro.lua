-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------

local nui = false
local inservice = false
local chk = nil
local chkattached = nil
local cooldown = 0

tempo_entrega = 15 --- Tempo que leva para descarregar o caminhão / Em segundos!

geral = {

    [1] = {
        
        ['type'] = 'madeiras', --- NAO ALTERAR / NAO MEXER

        ['valor_min'] = 1250,        -- Pode alterar / Valor minimo que recebe
        ['valor_max'] = 1500,        -- Pode alterar / Valor maximo que recebe

        ['rotas'] = {                -- Pode alterar / Rotas de entrega da carga, são escolhidas aleatoriamente ao iniciar / Sem limite de rotas

            [1] = { ['x'] = -827.13, ['y'] = 5414.54, ['z'] = 34.3 },
            [2] = { ['x'] = -574.51, ['y'] = 5336.35, ['z'] = 70.22 },
            [3] = { ['x'] = -552.43, ['y'] = 303.34, ['z'] = 83.21 },
            [4] = { ['x'] = -700.32, ['y'] = 5775.22, ['z'] = 17.33 }

        }
    },

    [2] = {
        
        ['type'] = 'carros', --- NAO ALTERAR / NAO MEXER

        ['valor_min'] = 1000, 
        ['valor_max'] = 1200, 

        ['rotas'] = {  

            [1] = { ['x'] = -75.57, ['y'] = -1102.08, ['z'] = 26.08 },
            [2] = { ['x'] = 921.36, ['y'] = -182.34, ['z'] = 74.1 },
            [3] = { ['x'] = -393.01, ['y'] = -135.02, ['z'] = 38.54 },
            [4] = { ['x'] = -810.56, ['y'] = -228.57, ['z'] = 37.21}

        }
    },

    [3] = {
        
        ['type'] = 'gas', --- NAO ALTERAR / NAO MEXER

        ['valor_min'] = 700, 
        ['valor_max'] = 950,

        ['rotas'] = {  

            [1] = { ['x'] = 617.2, ['y'] = 267.55, ['z'] = 103.09 },
            [2] = { ['x'] = -2092.35, ['y'] = -318.87, ['z'] = 13.03 },
            [3] = { ['x'] = -728.25, ['y'] = -933.51, ['z'] = 19.02 },
            [4] = { ['x'] = -1796.67, ['y'] = 806.76, ['z'] = 138.52 }

        }
    },

    [4] = {
        
        ['type'] = 'show', --- NAO ALTERAR / NAO MEXER

        ['valor_min'] = 950, 
        ['valor_max'] = 1300, 
        
        ['rotas'] = {  

            [1] = { ['x'] = -1407.11, ['y'] = -587.8, ['z'] = 30.39 },
            [2] = { ['x'] = -564.76, ['y'] = 268.13, ['z'] = 82.9 },
            [3] = { ['x'] = 301.42, ['y'] = 145.41, ['z'] = 103.76 },
            [4] = { ['x'] = -379.67, ['y'] = 230.13, ['z'] = 83.96 }

        }
    }

}


-- -----------------------------------------------------------------------------
-- ------ MAIN THREAD NUI
-- -----------------------------------------------------------------------------

localcarga = { 742.05, -1354.85, 26.34, 268.30 }

Citizen.CreateThread(function()
    while true do
        local idle = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local distance = #(vec3(coords[1],coords[2],coords[3]) - vec3(cfg.list["Caminhoneiro"]["inicio"][1],cfg.list["Caminhoneiro"]["inicio"][2],cfg.list["Caminhoneiro"]["inicio"][3]))
        if not servico then
            if distance <= 10.0 then
                idle = 1
                DrawMarker(27,cfg.list["Caminhoneiro"]["inicio"][1],cfg.list["Caminhoneiro"]["inicio"][2],cfg.list["Caminhoneiro"]["inicio"][3] - 0.95,0,0,0,0,0,0,1.5,1.5,1.5,132,102,226,180,0,0,0,1)
                if distance <= 3.0 then
                    DrawText3D(cfg.list["Caminhoneiro"]["inicio"][1],cfg.list["Caminhoneiro"]["inicio"][2],cfg.list["Caminhoneiro"]["inicio"][3], "Bem-Vindo a Central de Caminhoneiro\n")
                    
					if distance <= 1.2 and IsControlJustPressed(0, 38) and vSERVER.checkEmp('Caminhoneiro')  then
						
						if not nui then
				
						SetNuiFocus(true,true)
						-- TransitionToBlurred(1000)
						SendNUIMessage({ 
							showCENTRAL = "trucker",
							trucker = geral
						})
						nui = true
					
						end   

					end

                end
            end
        end
        Citizen.Wait(idle)
    end
end)

RegisterNUICallback("close_trucker", function(data, callback)
    SetNuiFocus(false,false)
    -- TransitionFromBlurred(1000)            
    nui = false 
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- MAIN
-----------------------------------------------------------------------------------------------------------------------------------------

RegisterNuiCallback('select_route', function(data, cb)
    if data == 'show' then
        if cooldown < 1 then
            chk = 4
            if not inservice then
                chkattached = "tvtrailer"
                spawnVehicle(chkattached,localcarga[1],localcarga[2],localcarga[3],localcarga[4])
                TriggerEvent("delivery_route")         
                vRP.playSound("Event_Message_Purple","GTAO_FM_Events_Soundset")
                cooldown = 60
                cdown()	
            else
                TriggerEvent('Notify','negado','Você já está em serviço!')
            end
        else
            TriggerEvent("Notify","aviso","Aguarde "..cooldown.." Segundos para puxar outra carga.")
        end	
    elseif data == 'gas' then
        if cooldown < 1 then
            chk = 3
            if not inservice then
                chkattached = "tanker"
                spawnVehicle(chkattached,localcarga[1],localcarga[2],localcarga[3],localcarga[4])
                TriggerEvent("delivery_route")
                vRP.playSound("Event_Message_Purple","GTAO_FM_Events_Soundset")
                cooldown = 60
                cdown()	
            else
                TriggerEvent('Notify','negado','Você já está em serviço!')
            end
        else
            TriggerEvent("Notify","aviso","Aguarde "..cooldown.." Segundos para puxar outra carga.")
        end	
    elseif data == 'madeiras' then
        if cooldown < 1 then
            chk = 1
            if not inservice then
                chkattached = "trailerlogs"
                spawnVehicle(chkattached,localcarga[1],localcarga[2],localcarga[3],localcarga[4])
                TriggerEvent("delivery_route")
                vRP.playSound("Event_Message_Purple","GTAO_FM_Events_Soundset")
                cooldown = 60
                cdown()	
            else
                TriggerEvent('Notify','negado','Você já está em serviço!')
            end
        else
            TriggerEvent("Notify","aviso","Aguarde "..cooldown.." Segundos para puxar outra carga.")
        end	
    elseif data == 'carros' then
        if cooldown < 1 then
            chk = 2
            if not inservice then
                chkattached = "tr4"
                spawnVehicle(chkattached,localcarga[1],localcarga[2],localcarga[3],localcarga[4])
                TriggerEvent("delivery_route")
                vRP.playSound("Event_Message_Purple","GTAO_FM_Events_Soundset")
                cooldown = 60
                cdown()	
            else
                TriggerEvent('Notify','negado','Você já está em serviço!')
            end
        else
            TriggerEvent("Notify","aviso","Aguarde "..cooldown.." Segundos para puxar outra carga.")
        end	
    end
end)

RegisterNetEvent("delivery_route",function()
	local ped = PlayerPedId()
   
    for k,v in pairs(geral[chk]['rotas']) do
        
        if not inservice then

            inservice = true
            
            random = math.random(k)
            
			CX = geral[chk]['rotas'][random].x
			CY = geral[chk]['rotas'][random].y
			CZ = geral[chk]['rotas'][random].z
			CriandoBlipCM(CX,CY,CZ)

            pagamento = math.random(geral[chk]['valor_min'],geral[chk]['valor_max'])

        end
    end
end)


Citizen.CreateThread(function()
	while true do
local idle = 1000
		if inservice then
			local ped = PlayerPedId()
			local x,y,z = table.unpack(GetEntityCoords(ped))
			local bowz,cdz = GetGroundZFor_3dCoord(CX,CY,CZ)
			local distance = GetDistanceBetweenCoords(CX,CY,cdz,x,y,z,true)
            local enttemp = tempo_entrega

			if distance <= 20.0 then
				idle = 1
                DrawMarker(27, CX,CY,CZ-0.97 ,0,0,0,0,0,0,8.0,8.0,1.0,40, 34, 213,200,0,0,0,1)
                DrawMarker(39,CX,CY,CZ-0.50,0,0,0,0.0,0,0,0.8,0.8,0.8,40,34,213,200,0,0,0,1)	
                if distance <= 5.0 and IsControlJustPressed(0,38) then
                    if not IsPedInAnyVehicle(ped) then	
                        local vehicle = vRP.getNearestVehicle(10)

                        if vehicle and GetEntityModel(vehicle) == GetHashKey(chkattached) then
                            
                            TriggerEvent('Notify','sucesso','Aguarde! Descarregando caminhão',10000)
                            TriggerEvent("cancelando",true)
                            vRP.playAnim(false,{{"anim@amb@business@coc@coc_packing_hi@","full_cycle_v1_pressoperator"}},true)
                            TriggerEvent("progress",enttemp)
                            SetTimeout(enttemp*1000, function()
                                vRP.playSound("Event_Message_Purple","GTAO_FM_Events_Soundset")
                                TriggerEvent("cancelando",false)
                                DeleteEntity(vehicle)
                                RemoveBlip(blips)
                               	TriggerServerEvent('m_empregos:upgrade_level')
								TriggerServerEvent('m_empregos:payment')
                              	vRP.stopAnim(false)
                                inservice = false
                                chkattached = nil
                            end)

                        else
                            TriggerEvent('Notify','importante','Posicione a carga corretamente no local marcado!')
                        end
                    else
                        TriggerEvent('Notify','importante','Posicione a carga no local marcado e pressione [E] ao lado fora do veículo!')
                    end    
                end
            end
		end
		Citizen.Wait(idle)
	end
end)

Citizen.CreateThread(function()
	while true do
      local idle = 1000
      if inservice then
		idle = 1
			drawTxtCM("~y~PRESSIONE ~r~F7 ~w~SE DESEJA CANCELAR A ROTA ",4,0.270,0.905,0.45,255,255,255,200)
			drawTxtCM("~w~VA ATÉ O DESTINO ~y~MARCADO ~w~NO GPS",4,0.270,0.93,0.45,255,255,255,200)
            if IsControlJustPressed(0,168) then             
                inservice = false
                chkattached = nil
                RemoveBlip(blips)
                TriggerEvent('Notify','importante','Você cancelou a rota de entrega!')
            end
        end
	  Citizen.Wait(idle)
	end
end)


function cdown()
    Citizen.CreateThread(function()
        while cooldown >= 1 do
            Citizen.Wait(1000)
            if cooldown > 0 then
                cooldown = cooldown - 1
            end
        end
    end)
    end

-----------------------------------------------------------------------------------------------------------------------------------------
-- FUNCTIONS
-----------------------------------------------------------------------------------------------------------------------------------------


function CriandoBlipCM(x,y,z)
	blips = AddBlipForCoord(x,y,z)
	SetBlipSprite(blips,1)
	SetBlipColour(blips,5)
	SetBlipScale(blips,0.4)
	SetBlipAsShortRange(blips,false)
	SetBlipRoute(blips,true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Entrega de Carga")
	EndTextCommandSetBlipName(blips)
end

function drawTxtCM(text,font,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(r,g,b,a)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end

function spawnVehicle(name,x,y,z,h)
	local mhash = GetHashKey(name)
	while not HasModelLoaded(mhash) do
		RequestModel(mhash)
		Citizen.Wait(10)
	end

	if HasModelLoaded(mhash) then
		local nveh = CreateVehicle(mhash,x,y,z+0.5,h,true,false)

		SetVehicleOnGroundProperly(nveh)
		SetVehicleNumberPlateText(nveh,vRP.getRegistrationNumber())
		SetEntityAsMissionEntity(nveh,true,true)

		SetModelAsNoLongerNeeded(mhash)
	end
end

function getVehicleInDirection(coordsfrom,coordsto)
	local handle = CastRayPointToPoint(coordsfrom.x,coordsfrom.y,coordsfrom.z,coordsto.x,coordsto.y,coordsto.z,10,PlayerPedId(),false)
	local a,b,c,d,vehicle = GetRaycastResult(handle)
	return vehicle
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------------------------------------------------------------





