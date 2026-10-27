local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
emP = Tunnel.getInterface("emp_hospital")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIAVEIS
-----------------------------------------------------------------------------------------------------------------------------------------
local macas = {

	{ ['blip'] = { 1125.55,-1547.35,34.96 }, ['maca'] = { 1126.94,-1547.34,35.89 }, ['h'] = 274.38  }, 
	{ ['blip'] = { 1125.53,-1544.08,34.96 }, ['maca'] = { 1126.94,-1543.97,35.89 }, ['h'] = 274.38  }, 
	{ ['blip'] = { 1125.51,-1541.16,34.96 }, ['maca'] = { 1127.07,-1541.09,35.89 }, ['h'] = 274.38  }, 
	{ ['blip'] = { 1125.51,-1538.36,34.96 }, ['maca'] = { 1127.12,-1538.4,35.89 }, ['h'] = 274.38  },

	{ ['blip'] = { 1124.48,-1555.16,34.96 }, ['maca'] = { 1124.51,-1553.67,35.89 }, ['h'] = 355.95  }, 
	{ ['blip'] = { 1127.41,-1555.13,34.96 }, ['maca'] = { 1127.36,-1553.64,35.89 }, ['h'] = 355.95  }, 

	{ ['blip'] = { 1126.4,-1560.79,34.96 }, ['maca'] = { 1126.42,-1562.25,35.89 }, ['h'] = 170.97  }, 
	{ ['blip'] = { 1123.63,-1560.83,34.96 }, ['maca'] = { 1123.61,-1562.63,35.89 }, ['h'] = 170.97  }, 
	{ ['blip'] = { 1120.92,-1560.8,34.96 }, ['maca'] = { 1120.87,-1562.42,35.89 }, ['h'] = 170.97  },
	{ ['blip'] = { 1118.58,-1560.81,34.96 }, ['maca'] = { 1118.56,-1562.38,35.89 }, ['h'] = 170.97  },
	{ ['blip'] = { 1116.23,-1560.88,34.96 }, ['maca'] = { 1116.2,-1562.42,35.89 }, ['h'] = 170.97  },

	{ ['blip'] = { 1132.16,-1579.99,35.38 }, ['maca'] = { 1133.03,-1579.81,36.29 }, ['h'] = 172.21  },
	{ ['blip'] = { 1127.91,-1580.66,35.38 }, ['maca'] = { 1126.42,-1580.58,36.29 }, ['h'] = 81.64  },
	{ ['blip'] = { 1126.46,-1585.33,35.38 }, ['maca'] = { 1126.45,-1584.44,36.29 }, ['h'] = 81.64  },
	{ ['blip'] = { 1127.89,-1588.18,35.38 }, ['maca'] = { 1126.34,-1588.16,36.29 }, ['h'] = 81.64  },
	{ ['blip'] = { 1126.46,-1592.99,35.38 }, ['maca'] = { 1126.36,-1591.97,36.29 }, ['h'] = 81.64  },



}

-----------------------------------------------------------------------------------------------------------------------------------------
-- DEITANDO
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
		local ms = 1000
		for k,v in pairs(macas) do
			local ped = PlayerPedId()
			local x,y,z = table.unpack(GetEntityCoords(ped))
			local bowz,cdz = GetGroundZFor_3dCoord(v['blip'][1],v['blip'][2],v['blip'][3])
			local distance = GetDistanceBetweenCoords(v['blip'][1],v['blip'][2],cdz,x,y,z,true)
			if distance <= 2.5 then
				ms = 1
				DrawText3D(v['blip'][1],v['blip'][2],v['blip'][3]-0, "~g~[E]~w~ para deitar ~g~[G] ~w~ para tratamento")
				if IsControlJustPressed(0,38) then
					SetEntityCoords(ped,v['maca'][1],v['maca'][2],v['maca'][3])
					SetEntityHeading(ped,v['h'])
					vRP._playAnim(false,{{"amb@world_human_sunbathe@female@back@idle_a","idle_a"}},true)
				end
				if IsControlJustPressed(0,47) then
					if emP.checkServices() then
						TriggerEvent('tratamento-macas')
						TriggerEvent('resetDiagnostic')
						TriggerEvent('resetWarfarina')
						SetEntityCoords(ped,v['maca'][1],v['maca'][2],v['maca'][3])
						SetEntityHeading(ped,v['h'])
						vRP._playAnim(false,{{"amb@world_human_sunbathe@female@back@idle_a","idle_a"}},true)
					else
						TriggerEvent("Notify","aviso","Existem paramédicos em serviço.")
					end
				end
			end
		end
		Wait(ms)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- FUNÇÕES
-----------------------------------------------------------------------------------------------------------------------------------------

RegisterNetEvent('event:deitarpaciente')
AddEventHandler('event:deitarpaciente',function()

	for k,v in pairs(macas) do
		local ped = PlayerPedId()
		local x,y,z = table.unpack(GetEntityCoords(ped))
		local bowz,cdz = GetGroundZFor_3dCoord(v.x,v.y,v.z)
		local distance = GetDistanceBetweenCoords(v.x,v.y,cdz,x,y,z,true)
		if distance <= 1.5 then
			SetEntityCoords(ped,v.x2,v.y2,v.z2)
			SetEntityHeading(ped,v.h)
			vRP._playAnim(false,{{"amb@world_human_sunbathe@female@back@idle_a","idle_a"}},true)
		end
	end

end)

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

RegisterNetEvent('tratamento-macas')
AddEventHandler('tratamento-macas',function()
	TriggerEvent("cancelando",true)
	repeat
		SetEntityHealth(PlayerPedId(),GetEntityHealth(PlayerPedId())+1)
		Citizen.Wait(60)
	until GetEntityHealth(PlayerPedId()) >= 400 or GetEntityHealth(PlayerPedId()) <= 100
	TriggerEvent("Notify","sucesso","Tratamento concluido.")
	TriggerEvent("cancelando",false)
end)

function DrawText3D(x,y,z,text)
	local onScreen,_x,_y = World3dToScreen2d(x,y,z)
	SetTextFont(4)
	SetTextScale(0.35,0.35)
	SetTextColour(255,255,255,150)
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(_x,_y)
end