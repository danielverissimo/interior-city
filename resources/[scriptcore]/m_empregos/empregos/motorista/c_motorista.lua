-- print('[DEBUG]: Client Motorista Init Sucess')

-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIAVEIS
-----------------------------------------------------------------------------------------------------------------------------------------

local emservico = false

-----------------------------------------------------------------------------------------------------------------------------------------
-- GERANDO LOCAL DE ENTREGA
-----------------------------------------------------------------------------------------------------------------------------------------
local entregas = {
	[1] = { x=309.95,y=-760.52,z=30.09 },
	[2] = { x=69.59,y=-974.80,z=30.14 },
	[3] = { x=95.00,y=-634.89,z=45.02 },
	[4] = { x=58.27,y=-283.32,z=48.20 },
	[5] = { x=47.74,y=-160.44,z=56.03 },
	[6] = { x=323.93,y=-267.58,z=54.71 },
	[7] = { x=443.75,y=119.16,z=100.41 },
	[8] = { x=125.62,y=-4.42,z=68.48 },
	[9] = { x=-524.08,y=133.59,z=63.91 },
	[10] = { x=-586.64,y=268.39,z=83.24 },
	[11] = { x=-640.38,y=-163.16,z=38.49 },
	[12] = { x=-597.89,y=-361.27,z=35.77 },
	[13] = { x=-646.06,y=-804.09,z=25.78 },
	[14] = { x=-932.63,y=-1199.67,z=5.91 },
	[15] = { x=-1234.65,y=-1080.87,z=9.12 },
	[16] = { x=-1373.99,y=-793.23,z=20.09 },
	[17] = { x=-2011.25,y=-160.04,z=29.40 },
	[18] = { x=-2981.70,y=404.50,z=15.75 },
	[19] = { x=-3101.58,y=1112.65,z=21.28 },
	[20] = { x=-2556.10,y=2322.01,z=33.89 },
	[21] = { x=-1094.86,y=2675.87,z=20.08 },
	[22] = { x=-72.63,y=2813.83,z=54.60 },
	[23] = { x=540.55,y=2685.25,z=43.20 },
	[24] = { x=1119.93,y=2682.04,z=39.31 },
	[25] = { x=1470.51,y=2725.47,z=38.48 },
	[26] = { x=2002.62,y=2603.65,z=55.07 },
	[27] = { x=379.58,y=-599.20,z=29.58 }
}

-----------------------------------------------------------------------------
------ MAIN THREAD NUI
-----------------------------------------------------------------------------

Citizen.CreateThread(function()
    while true do
        local idle = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local distance = #(vec3(coords[1],coords[2],coords[3]) - vec3(cfg.list["Motorista"]["inicio"][1],cfg.list["Motorista"]["inicio"][2],cfg.list["Motorista"]["inicio"][3]))

        if distance <= 10.0 and not emservico then
            idle = 1
            DrawMarker(27,cfg.list["Motorista"]["inicio"][1],cfg.list["Motorista"]["inicio"][2],cfg.list["Motorista"]["inicio"][3] - 0.95,0,0,0,0,0,0,1.5,1.5,1.5,132,102,226,180,0,0,0,1)
            if distance <= 3.0 then
                DrawText3D(cfg.list["Motorista"]["inicio"][1],cfg.list["Motorista"]["inicio"][2],cfg.list["Motorista"]["inicio"][3], "Bem-Vindo a Central de Motorista\n")
                if distance <= 5.0 and IsControlJustPressed(0, 38) then
                    
                    
                    if distance <= 1.2 then
                        if IsControlJustPressed(0,38) and vSERVER.checkEmp('Motorista') then
                            TriggerEvent("Notify", "sucesso", "Você entrou em serviço! Pegue um ônibus ao lado")
                            emservico = true
                            destino = 1
                            CriandoBlipMT(entregas,destino)
                        end
 				    end
                                 
                end
            end
        end
        
        Citizen.Wait(idle)
    end
end)

---------------------------------------------------------------------------------------------------------------------------------------
--  GERANDO ENTREGA
---------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
		local sleep2 = 1000
		if emservico then
			local distance = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()),entregas[destino].x,entregas[destino].y,entregas[destino].z,true)
			if distance <= 20.0 then
				sleep2 = 1
				DrawMarker(21,entregas[destino].x,entregas[destino].y,entregas[destino].z-0.70,0,0,0,0,180.0,130.0,2.0,2.0,1.0,211,176,72,100,1,0,0,1)
				if distance <= 5.0 then
					drawTxtMT("PRESSIONE  ~b~E~w~  PARA CONTINUAR A ROTA",4,0.5,0.93,0.50,255,255,255,180)
					if IsControlJustPressed(0,38) then
						if IsVehicleModel(GetVehiclePedIsUsing(PlayerPedId()),GetHashKey("coach")) or IsVehicleModel(GetVehiclePedIsUsing(PlayerPedId()),GetHashKey("bus")) then
							RemoveBlip(blip)
							TriggerEvent("vrp_sound:source",'moeda',0.7)
							if destino == 27 then
								-- emP.checkPayment(600)    PAGAMENTO
								destino = 1
							else
								-- emP.checkPayment(0)
								TriggerServerEvent('m_empregos:upgrade_level')
								TriggerServerEvent('m_empregos:payment')

								destino = destino + 1
							end
							CriandoBlipMT(entregas,destino)
						end
					end
				end
			end
		end
		Citizen.Wait(sleep2)
	end
end)

Citizen.CreateThread(function()
	while true do
      local trava = 1000
      if emservico then
		trava = 1
			drawTxtMT("~y~PRESSIONE ~r~F7 ~w~SE DESEJA FINALIZAR A ROTA ",4,0.270,0.905,0.45,255,255,255,200)
			drawTxtMT("~w~VA ATÉ O DESTINO ~y~MARCADO ~w~NO GPS",4,0.270,0.93,0.45,255,255,255,200)
      end
	  Citizen.Wait(trava)
	end
end)
---------------------------------------------------------------------------------------------------------------------------------------
-- CANCELANDO ENTREGA
---------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
	local sleep3 = 1000
		if emservico then
			sleep3 = 1
			if IsControlJustPressed(0,168) then
				TriggerEvent("Notify", "negado", "Você saiu de serviço!")
				emservico = false
				RemoveBlip(blip)
			end
		end
		Citizen.Wait(sleep3)
	end
end)
---------------------------------------------------------------------------------------------------------------------------------------
-- FUNCOES
---------------------------------------------------------------------------------------------------------------------------------------
function drawTxtMT(text,font,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(r,g,b,a)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end

function CriandoBlipMT(entregas,destino)
	blip = AddBlipForCoord(entregas[destino].x,entregas[destino].y,entregas[destino].z)
	SetBlipSprite(blip,1)
	SetBlipColour(blip,5)
	SetBlipScale(blip,0.4)
	SetBlipAsShortRange(blip,false)
	SetBlipRoute(blip,true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Rota de Motorista")
	EndTextCommandSetBlipName(blip)
end

function DrawText3DMT(x, y, z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.50, 0.50)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370

end

