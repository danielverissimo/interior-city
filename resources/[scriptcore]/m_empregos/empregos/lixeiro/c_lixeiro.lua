-- print('[DEBUG]: Client Lixeiro Init Sucess')

local oldTrashModel = nil
local l = 0
local area = 0
local onjob = false
local CanLeaveBox = false
local veh
local HashKeyBox = 600967813

modelTrash = {
	[1] = 1388308576,
	[2] = 1948359883,
	[3] = 897494494,
	[4] = 1098827230,
	[5] = -1681329307
}

local myCoords = {}
local coords = {}

Citizen.CreateThread(
	function()
		while true do
			local sleepemplx = 1000

			local myCoords = GetEntityCoords(PlayerPedId())

			if onjob then
				sleepemplx = 1
				for i = 1, #modelTrash do
					closestTrashMachine = GetClosestObjectOfType(myCoords.x, myCoords.y, myCoords.z, 2.0, modelTrash[i], false, false)
					if closestTrashMachine ~= nil and closestTrashMachine ~= 0 then
						coords = GetEntityCoords(closestTrashMachine)
						local distance = GetDistanceBetweenCoords(myCoords.x, myCoords.y, myCoords.z, coords.x, coords.y, coords.z, true)
						if distance < 1.50 and onjob then
							
							nearTrash = true
							openMenuTrash(nearTrash, closestTrashMachine)
						elseif distance >= 1.50 and onjob then
							nearTrash = false
							openMenuTrash(nearTrash)
						end
					end
				end
			end
			Citizen.Wait(sleepemplx)
		end
	end
)

Citizen.CreateThread(
	function()
		while true do
			local sleepemplx2 = 1000
			local myCoords = GetEntityCoords(GetPlayerPed(-1))
			veh = getNearVeh(10)
			local model = GetEntityModel(veh)

			if model == 1917016601 then
				coordsCar = GetOffsetFromEntityInWorldCoords(veh, 0.0, -3.75, 0.0)
				local distance =
					GetDistanceBetweenCoords(myCoords.x, myCoords.y, myCoords.z, coordsCar.x, coordsCar.y, coordsCar.z, true)
				if distance < 2.0 and onjob then
					sleepemplx2 = 1
					nearTrashCar = true
					openMenuTrashCar(nearTrashCar)
				elseif distance >= 2.25 and onjob then
					nearTrashCar = false
					openMenuTrashCar(nearTrashCar)
				end
			end
			Citizen.Wait(sleepemplx2)
		end
	end
)

Citizen.CreateThread(
	function()
		local ped = PlayerPedId()
		local vehicle = GetVehiclePedIsUsing(ped)
		while true do
			local sleepemplx3 = 1000

			if
				GetDistanceBetweenCoords(cfg.list["Lixeiro"]["inicio"][1],cfg.list["Lixeiro"]["inicio"][2],cfg.list["Lixeiro"]["inicio"][3], GetEntityCoords(GetPlayerPed(-1))) <
					10.0
			 then
				sleepemplx3 = 1
				
                DrawText3D(cfg.list["Lixeiro"]["inicio"][1],cfg.list["Lixeiro"]["inicio"][2],cfg.list["Lixeiro"]["inicio"][3], "Bem-Vindo a Central de Lixeiro\n")
				DrawMarker(27, cfg.list["Lixeiro"]["inicio"][1],cfg.list["Lixeiro"]["inicio"][2],cfg.list["Lixeiro"]["inicio"][3]-0.97 ,0,0,0,0,0,0,8.0,8.0,1.0,40, 34, 213,200,0,0,0,0)
				DrawMarker(39,cfg.list["Lixeiro"]["inicio"][1],cfg.list["Lixeiro"]["inicio"][2],cfg.list["Lixeiro"]["inicio"][3]-0.50,0,0,0,0.0,0,0,0.8,0.8,0.8,40,34,213,200,0,0,0,1)	
			end

			if
				GetDistanceBetweenCoords(cfg.list["Lixeiro"]["inicio"][1],cfg.list["Lixeiro"]["inicio"][2],cfg.list["Lixeiro"]["inicio"][3], GetEntityCoords(GetPlayerPed(-1))) <
					2.0
			 then
				if onjob == false then
					sleepemplx3 = 1
					-- drawTxtLX("PRESSIONE ~g~E~s~ PARA INICIAR O SERVIÇO", 1, 1, 0.5, 0.8, 0.6, 255, 255, 255, 255)
					if (IsControlJustReleased(1, 38)) and vSERVER.checkEmp('Lixeiro') then
						if IsVehicleModel(GetVehiclePedIsIn(GetPlayerPed(-1), true), GetHashKey("trash")) then
							TriggerEvent("Notify", "aviso", "Siga coletando o lixo pela cidade.")
							onjob = true
						else
							
							TriggerEvent("Notify", "negado", "Você precisa estar com o caminhão de lixo.")
						end
					end
				else
					drawTxtLX("PRESSIONE ~g~E~s~ PARA SAIR DE SERVIÇO", 1, 1, 0.5, 0.8, 0.6, 255, 255, 255, 255)
					if (IsControlJustReleased(1, 38)) then
						onjob = false
						local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), true), GetHashKey("trash")
						RemoveBlip(deliveryblip)
						-- TriggerServerEvent("nation:deleteVehicleSync",VehToNet(vehicle))  DELETAR VEICULO
						DeleteEntity(vehicle)
						TriggerEvent("Notify", "aviso", "Caminhão de lixo foi guardado na garagem.")
						SetWaypointOff()
					end
				end
			end
			Citizen.Wait(sleepemplx3)
		end
	end
)

function openMenuTrash(nearTrash, trashModel)
	if nearTrash then
		drawTxtLX("PRESSIONE ~g~E~s~ PARA COLETAR O LIXO", 1, 1, 0.5, 0.8, 0.6, 255, 255, 255, 255)
		if (IsControlJustPressed(1, 38)) and trashModel ~= oldTrashModel then
			while not HasAnimDictLoaded("missfbi4prepp1") do
				RequestAnimDict("missfbi4prepp1")
				Citizen.Wait(100)
			end
			TaskPlayAnim(GetPlayerPed(PlayerId()), "missfbi4prepp1", "_bag_pickup_garbage_man", 1.0, -1, -1, 50, 0, 0, 0, 0)
			Citizen.Wait(100)
			oldTrashModel = trashModel
			Wait(1000)
			SetEntityCoords(oldTrashModel, 0.0, 0.0, 0.0, false, false, false, true)
			CanLeaveBox = true
			ClearPedTasksImmediately(GetPlayerPed(-1))
		end
		if CanLeaveBox then
			local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1)))
			local prop = CreateObject(HashKeyBox, x + 5.5, y + 5.5, z + 0.2, true, true, true)
			AttachEntityToEntity(
				prop,
				GetPlayerPed(-1),
				GetPedBoneIndex(GetPlayerPed(-1), 0x6F06),
				0.00,
				0.0,
				-0.7,
				0.0,
				0.0,
				0.0,
				true,
				true,
				false,
				true,
				1,
				true
			)
			RequestAnimDict("missfbi4prepp1")
			while not HasAnimDictLoaded("missfbi4prepp1") do
				Wait(0)
			end
			TaskPlayAnim(GetPlayerPed(-1), "missfbi4prepp1", "_bag_walk_garbage_man", 8.0, -8, -1, 49, 0, 0, 0, 0)
			repeat
				Citizen.Wait(100)
				if CanLeaveBox == false then
					DeleteEntity(prop)
				end
			until (CanLeaveBox == false)
		end
	end
end

function openMenuTrashCar(nearTrashCar)
	if nearTrashCar and CanLeaveBox then
		drawTxtLX("PRESSIONE ~g~E~s~ PARA GUARDAR O LIXO", 1, 1, 0.5, 0.8, 0.6, 255, 255, 255, 255)
		if (IsControlJustPressed(1, 38)) then
			local pid = PlayerPedId()
			SetVehicleDoorOpen(veh, 5, false, true)
			DetachEntity(prop, true, false)
			SetEntityCoords(prop, 0.0, 0.0, 0.0, false, false, false, true)
			CanLeaveBox = false
			RequestAnimDict("missfbi4prepp1")
			while (not HasAnimDictLoaded("missfbi4prepp1")) do
				Citizen.Wait(1)
			end
			TaskPlayAnim(pid, "missfbi4prepp1", "_bag_throw_garbage_man", 100.0, 200.0, 0.3, 120, 0.2, 0, 0, 0)
			Wait(2000)
			StopAnimTask(pid, "missfbi4prepp1", "_bag_throw_garbage_man", 1.0)
			-- TriggerServerEvent("damn_lixeiro:rewardTrash") --- PAGAMENTO
			TriggerServerEvent('m_empregos:upgrade_level')
			TriggerServerEvent('m_empregos:payment')
			SetVehicleDoorsShut(veh, true)
		end
	end
end

function getNearVeh(radius)
	local playerPed = GetPlayerPed(-1)
	local coordA = GetEntityCoords(playerPed, 1)
	local coordB = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, radius + 0.00001, 0.0)
	local nearVehicle = getVehicleInDirection(coordA, coordB)

	if IsEntityAVehicle(nearVehicle) then
		return nearVehicle
	else
		local x, y, z = table.unpack(coordA)
		if IsPedSittingInAnyVehicle(playerPed) then
			local veh = GetVehiclePedIsIn(playerPed, true)
			return veh
		else
			local veh = GetClosestVehicle(x + 0.0001, y + 0.0001, z + 0.0001, radius + 0.0001, 0, 8192 + 4096 + 4 + 2 + 1) -- boats, helicos
			if not IsEntityAVehicle(veh) then
				veh = GetClosestVehicle(x + 0.0001, y + 0.0001, z + 0.0001, radius + 0.0001, 0, 4 + 2 + 1)
			end -- cars
			return veh
		end
	end
end

function getVehicleInDirection(coordFrom, coordTo)
	local rayHandle =
		CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, PlayerPedId(), 0)
	local a, b, c, d, vehicle = GetRaycastResult(rayHandle)
	return vehicle
end

function drawTxtLX(text, font, centre, x, y, scale, r, g, b, a)
	SetTextFont(6)
	SetTextProportional(0)
	SetTextScale(scale, scale)
	SetTextColour(r, g, b, a)
	SetTextDropShadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextCentre(centre)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x, y)
end

function drawTxtLXX(text,font,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(r,g,b,a)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end

Citizen.CreateThread(function()
	while true do
      local trava = 1000
      if onjob then
		trava = 1
			drawTxtLXX("~y~Siga coletando o~r~ LIXO ~w~ Espalhado Pela cidade ",4,0.270,0.905,0.45,255,255,255,200)
			drawTxtLXX("~w~Volte ao local de serviço para ~y~Finalizar ~w~ o trabalho",4,0.270,0.93,0.45,255,255,255,200)
      end
	  Citizen.Wait(trava)
	end
end)