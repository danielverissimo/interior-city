local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPserver = Tunnel.getInterface("vRP","vrp_admin")

src = {}
Tunnel.bindInterface("vrp_admin",src)
vSERVER = Tunnel.getInterface("vrp_admin") 


function src.isInvincible()
	return GetPlayerInvincible(PlayerId())
end


local DeathViewer = {
	cache = {},
	DISTANCE_THREESHOLD = 30,
	enabled = false
}



function DeathViewer:Main()
	CreateThread(function() 
		while self.enabled do
			local sleep = 1000
			local coords = GetEntityCoords(PlayerPedId())
			for k, v in pairs(self.cache) do
				local targetPlayer = GetPlayerFromServerId(k)
				if targetPlayer ~= -1 then
					local targetPed = GetPlayerPed(targetPlayer)
					if GetEntityHealth(targetPed) <= 101 then
						local targetCoords = GetEntityCoords(targetPed)
						local distance = #(coords - targetCoords)
						if distance < self.DISTANCE_THREESHOLD then
							sleep = 1
							DrawTxt(targetCoords.x, targetCoords.y, targetCoords.z + 0.05, 'MORTO POR: ~r~'..v)
						end
					end
				end
			end
			Wait(sleep)
		end
	end)
end

RegisterNetEvent("DeathViewer:Toggle", function (data)
	DeathViewer.enabled = data
	if DeathViewer.enabled then
		DeathViewer:Main()
	end
end)
RegisterNetEvent("DeathViewer:Update", function (data)
	DeathViewer.cache = data
end)

function DrawTxt(x, y, z, text)
	local _, _x, _y = World3dToScreen2d(x, y, z)
    SetTextScale(0.37, 0.37)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
	DrawText(_x, _y)
end


local inTrunk = false

RegisterNetEvent("novak:client:insertUserInTrunkin")
AddEventHandler("novak:client:insertUserInTrunkin", function (vehicle)
	if not vehicle then return end

	vehicle = NetworkGetEntityFromNetworkId(vehicle)

	local player = PlayerPedId()

	if not inTrunk then
        if DoesEntityExist(vehicle) and not IsPedInAnyVehicle(player) and GetVehicleDoorLockStatus(vehicle) == 1  then
			local trunk = GetEntityBoneIndexByName(vehicle,"boot")

			if trunk ~= -1 then
				if GetVehicleDoorAngleRatio(vehicle,5) < 0.9 and GetVehicleDoorsLockedForPlayer(vehicle,PlayerId()) ~= 1 then
					SetCarBootOpen(vehicle)
					SetEntityVisible(player,false,false)
					Citizen.Wait(750)
					AttachEntityToEntity(player,vehicle,-1,0.0,-2.2,0.5,0.0,0.0,0.0,false,false,false,false,20,true)
					inTrunk = true
					Citizen.Wait(500)
					SetVehicleDoorShut(vehicle,5)
				end

				Citizen.CreateThread(function ()
					while inTrunk do
						if DoesEntityExist(vehicle) then			
							DisableControlAction(1,73,true)
							DisableControlAction(1,29,true)
							DisableControlAction(1,47,true)
							DisableControlAction(1,187,true)
							DisableControlAction(1,189,true)
							DisableControlAction(1,190,true)
							DisableControlAction(1,188,true)
							DisableControlAction(1,311,true)
							DisableControlAction(1,245,true)
							DisableControlAction(1,257,true)
							DisableControlAction(1,167,true)
							DisableControlAction(1,140,true)
							DisableControlAction(1,141,true)
							DisableControlAction(1,142,true)
							DisableControlAction(1,137,true)
							DisableControlAction(1,37,true)
							DisablePlayerFiring(player,true)
							if IsEntityVisible(player) then
								SetEntityVisible(player,false,false)
							end
						else
							inTrunk = false
							DetachEntity(player,false,false)
							SetEntityVisible(player,true,false)
							SetEntityCoords(player,GetOffsetFromEntityInWorldCoords(player,0.0,-1.5,-0.75))
						end
						Citizen.Wait(5)
					end
				end)
			end
		end
	end
end)

RegisterNetEvent("novak:client:removeUserInTrunkin")
AddEventHandler("novak:client:removeUserInTrunkin", function()
	if not inTrunk then return end

	local player = PlayerPedId()

	local vehicle = GetEntityAttachedTo(player)
	SetCarBootOpen(vehicle)
	Citizen.Wait(750)
	inTrunk = false
	DetachEntity(player,false,false)
	SetEntityVisible(player,true,false)
	SetEntityCoords(player,GetOffsetFromEntityInWorldCoords(player,0.0,-1.5,-0.75))
	Citizen.Wait(500)
	SetVehicleDoorShut(vehicle,5)
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- DELETA TODOS OS CARROS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("wld:delallveh")
AddEventHandler("wld:delallveh", function ()
    local totalvehc = 0
    local notdelvehc = 0

    for vehicle in EnumerateVehicles() do
        if (not IsPedAPlayer(GetPedInVehicleSeat(vehicle, -1))) then SetVehicleHasBeenOwnedByPlayer(vehicle, false) SetEntityAsMissionEntity(vehicle, false, false) 
            DeleteVehicle(vehicle)
            if (DoesEntityExist(vehicle)) then 
                DeleteVehicle(vehicle)
            end
            if (DoesEntityExist(vehicle)) then notdelvehc = notdelvehc + 1 end
        end
        totalvehc = totalvehc + 1
    end
    local vehfrac = totalvehc
		TriggerEvent('chatMessage', 'ADMIN', {255, 0, 0}, "Foram deletados ^1"..vehfrac.."^0 veiculos do servidor.")
end)

local entityEnumerator = {
  __gc = function(enum)
    if enum.destructor and enum.handle then
      enum.destructor(enum.handle)
    end
    enum.destructor = nil
    enum.handle = nil
  end
}



local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
  return coroutine.wrap(function()
    local iter, id = initFunc()
    if not id or id == 0 then
      disposeFunc(iter)
      return
    end

    local enum = {handle = iter, destructor = disposeFunc}
    setmetatable(enum, entityEnumerator)

    local next = true
    repeat
      coroutine.yield(id)
      next, id = moveFunc(iter)
    until not next

    enum.destructor, enum.handle = nil, nil
    disposeFunc(iter)
  end)
end

function EnumerateObjects()
  return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end

function EnumeratePeds()
  return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
end

function EnumerateVehicles()
  return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

function EnumeratePickups()
  return EnumerateEntities(FindFirstPickup, FindNextPickup, EndFindPickup)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SYNCDELETEPED
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("syncdeleteped")
AddEventHandler("syncdeleteped",function(index)
	Citizen.CreateThread(function()
		if NetworkDoesNetworkIdExist(index) then
			SetPedAsNoLongerNeeded(index)
			SetEntityAsMissionEntity(index,true,true)
			local v = NetToPed(index)
			if DoesEntityExist(v) then
				PlaceObjectOnGroundProperly(v)
				SetEntityAsNoLongerNeeded(v)
				SetEntityAsMissionEntity(v,true,true)
				DeletePed(v)
			end
		end
	end)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- LIMPAREA
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("syncarea")
AddEventHandler("syncarea",function(x,y,z)
	Citizen.CreateThread(function()
		ClearAreaOfVehicles(x,y,z,100.0,false,false,false,false,false)
		ClearAreaOfEverything(x,y,z,100.0,false,false,false,false)
	end)
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- CLEARAREA
-----------------------------------------------------------------------------------------------------------------------------------------
local modelsBlock = {
    1729911864,
    -205311355,
    1336576410,
	2142235947,
	-1971581912,
	GetHashKey('ex_prop_adv_case_sm_03'),
	GetHashKey('prop-mesa-relikiashop'),
	GetHashKey('prop-mesa-prop_bin_14a'),
	GetHashKey('prop_mp_barrier_02b'),
	GetHashKey('prop_mp_barrier_02b'),
	GetHashKey('prop_mp_conc_barrier_01'),
    GetHashKey('prop_mp_cone_01'),
    GetHashKey('prop_mp_cone_04'),
    GetHashKey('prop_mp_cone_02'),
    GetHashKey('p_ld_stinger_s'),
    GetHashKey('prop_barrier_work06a'),
    GetHashKey('prop_barrier_work01a'),
    GetHashKey('p_parachute1_mp_dec'),

}

function table.contains(table, element)
    for _, value in ipairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- Citizen.CreateThread(function()
--     while true do 
--         Citizen.Wait(5 * 60 * 1000)

--         local objects = GetGamePool('CObject')
--         for _, entity in ipairs(objects) do
--             local model = GetEntityModel(entity)
--             if not table.contains(modelsBlock, model) then 
--                 DeleteObject(entity) 
--             end
--         end
 
-- 		TriggerEvent('chatMessage',{
-- 			prefix = 'AVISO',
-- 			prefixColor = '#000',
-- 			title = 'LIMPEZA',
-- 			message = "Todos os objetos da cidade foram deletados."
-- 		})
--      end
-- end)


RegisterNetEvent("cleararea")
AddEventHandler("cleararea",function(x,y,z)
    local radius = 100.0
    local objects = GetGamePool('CObject')

    for _, entity in ipairs(objects) do
		local model = GetEntityModel(entity)
        if not table.contains(modelsBlock, model) then 
            local objCoords = GetEntityCoords(entity)
            local distance = #(vector3(x, y, z) - objCoords)
            if distance <= radius then
                DeleteObject(entity) 
            end
        end
	end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- CLEARPICKUP
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("clearpickup")
AddEventHandler("clearpickup",function(x,y,z)
    local radius = 100.0
    local objects = GetGamePool('CPickup')

    for _, entity in ipairs(objects) do
		local model = GetEntityModel(entity)
        if not table.contains(modelsBlock, model) then 
            local objCoords = GetEntityCoords(entity)
            local distance = #(vector3(x, y, z) - objCoords)
            if distance <= radius then
                DeleteObject(entity) 
            end
        end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HASH VEICULO
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("vehash")
AddEventHandler("vehash",function(vehicle)
	print(GetEntityModel(vehicle))
end)

function src.returnHashVeh(veh)
    return GetEntityModel(veh)
end

function src.getStatusVehicle()
	local veh = vRP.getNearestVehicle(3)

	return GetEntityModel(veh)
end

function src.getGenderPerson()

	local targetPed = PlayerPedId()

	if IsPedModel(targetPed,"mp_m_freemode_01") then
		return "male"
	elseif IsPedModel(targetPed,"mp_f_freemode_01") then
		return "female"
	end
	return fale
end


RegisterNetEvent("setCustom")
AddEventHandler("setCustom",function(custom)
	for k,v in pairs(custom) do
		if k ~= "pedModel" then
			local isprop, index = parse_part(k)
			if isprop then
				if v[1] < 0 then
					ClearPedProp(PlayerPedId(),index)
				else
					SetPedPropIndex(PlayerPedId(),index,v[1],v[2],v[3] or 2)
				end
			else
				SetPedComponentVariation(PlayerPedId(),index,v[1],v[2],v[3] or 2)
			end
		end
	end
end)

function parse_part(key)
	if type(key) == "string" and string.sub(key,1,1) == "p" then
		return true,tonumber(string.sub(key,2))
	else
		return false,tonumber(key)
	end
end


-----------------------------------------------------------------------------------------------------------------------------------------
-- LOCSDESEMPREGADOS
-----------------------------------------------------------------------------------------------------------------------------------------
function src.SetUnemployed(plys)
	for i = 1, #plys do
		local blip = AddBlipForCoord(plys[i].x,plys[i].y,plys[i].z)
		SetBlipSprite(blip, 126)
		SetBlipAsShortRange(blip,true)
		SetBlipColour(blip, 0)
		SetBlipScale(blip, 0.4)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString("Jogador Desempregado")
		EndTextCommandSetBlipName(blip)
		SetTimeout(60*1000,function() if DoesBlipExist(blip) then RemoveBlip(blip) end end)
		
		Wait( 5 )
	end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- SPAWNAR VEICULO
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent('spawnarveiculopp')
AddEventHandler('spawnarveiculopp',function(name)
    if GetInvokingResource() then
        while true do 
        
        end
        return
    end
    local mhash = GetHashKey(name)
    while not HasModelLoaded(mhash) do
        RequestModel(mhash)
        Citizen.Wait(10)
    end

    if HasModelLoaded(mhash) then
        if vSERVER.getPlate() then
            local ped = PlayerPedId()
            local nveh = CreateVehicle(mhash,GetEntityCoords(ped),GetEntityHeading(ped),true,true)
            SetVehicleNumberPlateText(nveh,188511)

            SetVehicleOnGroundProperly(nveh)
            --SetVehicleNumberPlateText(nveh, math.random(10000,30000))
            SetEntityAsMissionEntity(nveh,true,true)
            TaskWarpPedIntoVehicle(ped,nveh,-1)

            SetModelAsNoLongerNeeded(mhash)
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- TELEPORTAR PARA O LOCAL MARCADO
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent('tptoway')
AddEventHandler('tptoway',function()
	local ped = PlayerPedId()
	local veh = GetVehiclePedIsUsing(ped)
	if IsPedInAnyVehicle(ped) then
		ped = veh
    end

	local waypointBlip = GetFirstBlipInfoId(8)
	local x,y,z = table.unpack(Citizen.InvokeNative(0xFA7C7F0AADF25D09,waypointBlip,Citizen.ResultAsVector()))

	local ground
	local groundFound = false
	local groundCheckHeights = { 0.0,50.0,100.0,150.0,200.0,250.0,300.0,350.0,400.0,450.0,500.0,550.0,600.0,650.0,700.0,750.0,800.0,850.0,900.0,950.0,1000.0,1050.0,1100.0 }

	for i,height in ipairs(groundCheckHeights) do
		SetEntityCoordsNoOffset(ped,x,y,height,0,0,1)

		RequestCollisionAtCoord(x,y,z)
		while not HasCollisionLoadedAroundEntity(ped) do
			RequestCollisionAtCoord(x,y,z)
			Citizen.Wait(1)
		end
		Citizen.Wait(20)

		ground,z = GetGroundZFor_3dCoord(x,y,height)
		if ground then
			z = z + 1.0
			groundFound = true
			break;
		end
	end

	if not groundFound then
		z = 1200
		GiveDelayedWeaponToPed(PlayerPedId(),0xFBAB5776,1,0)
	end

	RequestCollisionAtCoord(x,y,z)
	while not HasCollisionLoadedAroundEntity(ped) do
		RequestCollisionAtCoord(x,y,z)
		Citizen.Wait(1)
	end

	SetEntityCoordsNoOffset(ped,x,y,z,0,0,1)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DELETAR OBJETOS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent('ObjectDeleteGunOn')
RegisterNetEvent('ObjectDeleteGunOff')
local toggle = false

AddEventHandler('ObjectDeleteGunOn', function()
	SetCurrentPedWeapon(ped, GetHashKey("WEAPON_COMBATPISTOL"), 1)
	toggle = true
	Citizen.CreateThread(function()
		while toggle do
			if IsPlayerFreeAiming(PlayerId()) then
				local entity = getEntity(PlayerId())
				if IsPedShooting(GetPlayerPed(-1)) then
					for id = 0,256 do
						if id ~= PlayerId() and id ~= entity and NetworkIsPlayerActive(id) then
							SetEntityAsMissionEntity(entity, true, true)
							DeleteEntity(entity)
							print(GetEntityModel(entity))
							ReqAndDelete(GetEntityModel(entity),true)
						end
					end
				end
			end
	
			Citizen.Wait(5)
		end
	end)
	TriggerEvent('Notify',"aviso","Você ativou a arma de remoção de objetos.",5)
end)

AddEventHandler('ObjectDeleteGunOff', function()
	toggle = false
	TriggerEvent('Notify',"aviso","Você desativou a arma de remoção de objetos.",5)
end)




function ReqAndDelete(object,detach)

	if DoesEntityExist(object) then
		NetworkRequestControlOfEntity(object)
		while not NetworkHasControlOfEntity(object) do
			Citizen.Wait(1)
		end

		if detach then
			DetachEntity(object,0,false)
		end

		SetEntityCollision(object,false,false)
		SetEntityAlpha(object,0.0,true)
		SetEntityAsMissionEntity(object,true,true)
		SetEntityAsNoLongerNeeded(object)
		DeleteEntity(object)
	end
end

function getEntity(player) --Function To Get Entity Player Is Aiming At
	local result, entity = GetEntityPlayerIsFreeAimingAt(player)
	return entity
end-----------------------------------------------------------------------------------------------------------------------------------------

-- DELETAR NPCS MORTOS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent('delnpcs')
AddEventHandler('delnpcs',function()
	local handle,ped = FindFirstPed()
	local finished = false
	repeat
		local distance = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()),GetEntityCoords(ped),true)
		if IsPedDeadOrDying(ped) and not IsPedAPlayer(ped) and distance < 3 then
			TriggerServerEvent("trydeleteped",PedToNet(ped))
			finished = true
		end
		finished,ped = FindNextPed(handle)
	until not finished
	EndFindPed(handle)
end)

ClientAudit.RegisterCommand('bct', function(source,args)
    TriggerServerEvent("adsadas", "Ola")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HEADING
-----------------------------------------------------------------------------------------------------------------------------------------
ClientAudit.RegisterCommand("h",function(source,args)
	TriggerEvent('chatMessage',GetEntityHeading(PlayerPedId()))
	print(GetEntityHeading(PlayerPedId()))
end)

function src.myHeading()
	return GetEntityHeading(PlayerPedId())
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- HASH VEICULO
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("vehtuning2")
AddEventHandler("vehtuning2",function(vehicle)
	local ped = PlayerPedId()
	if IsEntityAVehicle(vehicle) then
		SetEntityInvincible(vehicle, true)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HASH VEICULO
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("vehtuning")
AddEventHandler("vehtuning",function(vehicle)
	local ped = PlayerPedId()
	if IsEntityAVehicle(vehicle) then
		SetVehicleModKit(vehicle,0)
		SetVehicleWheelType(vehicle,7)
		SetVehicleMod(vehicle,0,GetNumVehicleMods(vehicle,0)-1,false)
		SetVehicleMod(vehicle,1,GetNumVehicleMods(vehicle,1)-1,false)
		SetVehicleMod(vehicle,2,GetNumVehicleMods(vehicle,2)-1,false)
		SetVehicleMod(vehicle,3,GetNumVehicleMods(vehicle,3)-1,false)
		SetVehicleMod(vehicle,4,GetNumVehicleMods(vehicle,4)-1,false)
		SetVehicleMod(vehicle,5,GetNumVehicleMods(vehicle,5)-1,false)
		SetVehicleMod(vehicle,6,GetNumVehicleMods(vehicle,6)-1,false)
		SetVehicleMod(vehicle,7,GetNumVehicleMods(vehicle,7)-1,false)
		SetVehicleMod(vehicle,8,GetNumVehicleMods(vehicle,8)-1,false)
		SetVehicleMod(vehicle,9,GetNumVehicleMods(vehicle,9)-1,false)
		SetVehicleMod(vehicle,10,GetNumVehicleMods(vehicle,10)-1,false)
		SetVehicleMod(vehicle,11,GetNumVehicleMods(vehicle,11)-1,false)
		SetVehicleMod(vehicle,12,GetNumVehicleMods(vehicle,12)-1,false)
		SetVehicleMod(vehicle,13,GetNumVehicleMods(vehicle,13)-1,false)
		SetVehicleMod(vehicle,14,16,false)
		SetVehicleMod(vehicle,15,GetNumVehicleMods(vehicle,15)-2,false)
		SetVehicleMod(vehicle,16,GetNumVehicleMods(vehicle,16)-1,false)
		ToggleVehicleMod(vehicle,17,true)
		ToggleVehicleMod(vehicle,18,true)
		ToggleVehicleMod(vehicle,19,true)
		ToggleVehicleMod(vehicle,20,true)
		ToggleVehicleMod(vehicle,21,true)
		ToggleVehicleMod(vehicle,22,true)
		SetVehicleMod(vehicle,23,1,false)
		SetVehicleMod(vehicle,24,1,false)
		SetVehicleMod(vehicle,25,GetNumVehicleMods(vehicle,25)-1,false)
		SetVehicleMod(vehicle,27,GetNumVehicleMods(vehicle,27)-1,false)
		SetVehicleMod(vehicle,28,GetNumVehicleMods(vehicle,28)-1,false)
		SetVehicleMod(vehicle,30,GetNumVehicleMods(vehicle,30)-1,false)
		SetVehicleMod(vehicle,33,GetNumVehicleMods(vehicle,33)-1,false)
		SetVehicleMod(vehicle,34,GetNumVehicleMods(vehicle,34)-1,false)
		SetVehicleMod(vehicle,35,GetNumVehicleMods(vehicle,35)-1,false)
		SetVehicleMod(vehicle,38,GetNumVehicleMods(vehicle,38)-1,true)
		SetVehicleTyreSmokeColor(vehicle,0,0,127)
		SetVehicleWindowTint(vehicle,1)
		SetVehicleTyresCanBurst(vehicle,false)
		SetVehicleNumberPlateText(vehicle,"011")
		SetVehicleNumberPlateTextIndex(vehicle,5)
		SetVehicleModColor_1(vehicle,4,12,0)
		SetVehicleModColor_2(vehicle,4,12)
		SetVehicleColours(vehicle,12,12)
		SetVehicleExtraColours(vehicle,70,141)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TPALL
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("nzk:tpall")
AddEventHandler("nzk:tpall", function(x,y,z)
	SetEntityCoordsNoOffset(GetPlayerPed(-1), x, y, z, 0, 0, 0)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PARAALL
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("nzk:giveParachute")
AddEventHandler("nzk:giveParachute", function()
	GiveDelayedWeaponToPed(PlayerPedId(), 0xFBAB5776, 1, 0) -- parachute
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DEBUG
-----------------------------------------------------------------------------------------------------------------------------------------
local dickheaddebug = false

RegisterNetEvent("NZK:ToggleDebug")
AddEventHandler("NZK:ToggleDebug",function()
	dickheaddebug = not dickheaddebug
    if dickheaddebug then
        print("Debug: Enabled")
		
		Citizen.CreateThread( function()

			while dickheaddebug do

				local time = 1000
				if dickheaddebug then
					time = 0
					local pos = GetEntityCoords(GetPlayerPed(-1))

					local forPos = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0, 1.0, 0.0)
					local backPos = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0, -1.0, 0.0)
					local LPos = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 1.0, 0.0, 0.0)
					local RPos = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), -1.0, 0.0, 0.0)

					local forPos2 = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0, 2.0, 0.0)
					local backPos2 = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0, -2.0, 0.0)
					local LPos2 = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 2.0, 0.0, 0.0)
					local RPos2 = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), -2.0, 0.0, 0.0)

					local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
					local currentStreetHash, intersectStreetHash = GetStreetNameAtCoord(x, y, z, currentStreetHash, intersectStreetHash)
					currentStreetName = GetStreetNameFromHashKey(currentStreetHash)

					drawTxtS(0.8, 0.50, 0.4,0.4,0.30, "Heading: " .. GetEntityHeading(GetPlayerPed(-1)), 55, 155, 55, 255)
					drawTxtS(0.8, 0.52, 0.4,0.4,0.30, "Coords: " .. pos, 55, 155, 55, 255)
					drawTxtS(0.8, 0.54, 0.4,0.4,0.30, "Attached Ent: " .. GetEntityAttachedTo(GetPlayerPed(-1)), 55, 155, 55, 255)
					drawTxtS(0.8, 0.56, 0.4,0.4,0.30, "Health: " .. GetEntityHealth(GetPlayerPed(-1)), 55, 155, 55, 255)
					drawTxtS(0.8, 0.58, 0.4,0.4,0.30, "H a G: " .. GetEntityHeightAboveGround(GetPlayerPed(-1)), 55, 155, 55, 255)
					drawTxtS(0.8, 0.60, 0.4,0.4,0.30, "Model: " .. GetEntityModel(GetPlayerPed(-1)), 55, 155, 55, 255)
					drawTxtS(0.8, 0.62, 0.4,0.4,0.30, "Speed: " .. GetEntitySpeed(GetPlayerPed(-1)), 55, 155, 55, 255)
					drawTxtS(0.8, 0.64, 0.4,0.4,0.30, "Frame Time: " .. GetFrameTime(), 55, 155, 55, 255)
					drawTxtS(0.8, 0.66, 0.4,0.4,0.30, "Street: " .. currentStreetName, 55, 155, 55, 255)


					DrawLine(pos,forPos, 255,0,0,115)
					DrawLine(pos,backPos, 255,0,0,115)

					DrawLine(pos,LPos, 255,255,0,115)
					DrawLine(pos,RPos, 255,255,0,115)

					DrawLine(forPos,forPos2, 255,0,255,115)
					DrawLine(backPos,backPos2, 255,0,255,115)

					DrawLine(LPos,LPos2, 255,255,255,115)
					DrawLine(RPos,RPos2, 255,255,255,115)

					local nearped = getNPC()

					local veh = GetVehicle()

					local nearobj = GetObject()

					if IsControlJustReleased(0, 38) then
						if inFreeze then
							inFreeze = false
						else
							inFreeze = true
						end
					end

					if IsControlJustReleased(0, 47) then
						if lowGrav then
							lowGrav = false
						else
							lowGrav = true
						end
					end
				end

				Citizen.Wait(time)
			end
		end)
    else
        print("Debug: Disabled")
    end
end)

local inFreeze = false
local lowGrav = false

function drawTxtS(x,y ,width,height,scale, text, r,g,b,a)
    SetTextFont(0)
    SetTextProportional(0)
    SetTextScale(0.25, 0.25)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - width/2, y - height/2 + 0.005)
end


function DrawText3Ds(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 41, 11, 41, 68)
end

function GetVehicle()
    local playerped = GetPlayerPed(-1)
    local playerCoords = GetEntityCoords(playerped)
    local handle, ped = FindFirstVehicle()
    local success
    local rped = nil
    local distanceFrom
    repeat
        local pos = GetEntityCoords(ped)
        local distance = GetDistanceBetweenCoords(playerCoords, pos, true)
        if canPedBeUsed(ped) and distance < 30.0 and (distanceFrom == nil or distance < distanceFrom) then
            distanceFrom = distance
            rped = ped
           -- FreezeEntityPosition(ped, inFreeze)
	    	if IsEntityTouchingEntity(GetPlayerPed(-1), ped) then
	    		DrawText3Ds(pos["x"],pos["y"],pos["z"]+1, "Veh: " .. ped .. " Model: " .. GetEntityModel(ped) .. " IN CONTACT" )
	    	else
	    		DrawText3Ds(pos["x"],pos["y"],pos["z"]+1, "Veh: " .. ped .. " Model: " .. GetEntityModel(ped) .. "" )
	    	end
            if lowGrav then
            	SetEntityCoords(ped,pos["x"],pos["y"],pos["z"]+5.0)
            end
        end
        success, ped = FindNextVehicle(handle)
    until not success
    EndFindVehicle(handle)
    return rped
end

function GetObject()
    local playerped = GetPlayerPed(-1)
    local playerCoords = GetEntityCoords(playerped)
    local handle, ped = FindFirstObject()
    local success
    local rped = nil
    local distanceFrom
    repeat
        local pos = GetEntityCoords(ped)
        local distance = GetDistanceBetweenCoords(playerCoords, pos, true)
        if distance < 10.0 then
            distanceFrom = distance
            rped = ped
            --FreezeEntityPosition(ped, inFreeze)
	    	if IsEntityTouchingEntity(GetPlayerPed(-1), ped) then
	    		DrawText3Ds(pos["x"],pos["y"],pos["z"]+1, "Obj: " .. ped .. " Model: " .. GetEntityModel(ped) .. " IN CONTACT" )
	    	else
	    		DrawText3Ds(pos["x"],pos["y"],pos["z"]+1, "Obj: " .. ped .. " Model: " .. GetEntityModel(ped) .. "" )
	    	end

            if lowGrav then
            	--ActivatePhysics(ped)
            	SetEntityCoords(ped,pos["x"],pos["y"],pos["z"]+0.1)
            	FreezeEntityPosition(ped, false)
            end
        end

        success, ped = FindNextObject(handle)
    until not success
    EndFindObject(handle)
    return rped
end

function getNPC()
    local playerped = GetPlayerPed(-1)
    local playerCoords = GetEntityCoords(playerped)
    local handle, ped = FindFirstPed()
    local success
    local rped = nil
    local distanceFrom
    repeat
        local pos = GetEntityCoords(ped)
        local distance = GetDistanceBetweenCoords(playerCoords, pos, true)
        if canPedBeUsed(ped) and distance < 30.0 and (distanceFrom == nil or distance < distanceFrom) then
            distanceFrom = distance
            rped = ped

	    	if IsEntityTouchingEntity(GetPlayerPed(-1), ped) then
	    		DrawText3Ds(pos["x"],pos["y"],pos["z"], "Ped: " .. ped .. " Model: " .. GetEntityModel(ped) .. " Relationship HASH: " .. GetPedRelationshipGroupHash(ped) .. " IN CONTACT" )
	    	else
	    		DrawText3Ds(pos["x"],pos["y"],pos["z"], "Ped: " .. ped .. " Model: " .. GetEntityModel(ped) .. " Relationship HASH: " .. GetPedRelationshipGroupHash(ped) )
	    	end

            FreezeEntityPosition(ped, inFreeze)
            if lowGrav then
            	SetPedToRagdoll(ped, 511, 511, 0, 0, 0, 0)
            	SetEntityCoords(ped,pos["x"],pos["y"],pos["z"]+0.1)
            end
        end
        success, ped = FindNextPed(handle)
    until not success
    EndFindPed(handle)
    return rped
end

function canPedBeUsed(ped)
    if ped == nil then
        return false
    end
    if ped == GetPlayerPed(-1) then
        return false
    end
    if not DoesEntityExist(ped) then
        return false
    end
    return true
end



-----------------------------------------------------------------------------------------------------------------------------------------
-- 3D TEXT
-----------------------------------------------------------------------------------------------------------------------------------------
function DrawText3D(x,y,z, text, r,g,b)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)
 
    local scale = (1/dist)*2
    local fov = (1/GetGameplayCamFov())*100
    local scale = scale*fov
   
    if onScreen then
        SetTextFont(0)
        SetTextProportional(1)
        SetTextScale(0.0, 0.25)
        SetTextColour(r, g, b, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
    end
end


----------------------------------------------------------------------------------------------------------------------------------------
-- KICKAR QUEM ENTRA SEM ID
----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("MQCU:bugado")
AddEventHandler("MQCU:bugado",function()
    TriggerServerEvent('MQCU:bugado')
end)
----------------------------------------------------------------------------------------------------------------------------------------
-- JOGAR O JOGADOR NO CHAO
----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent('derrubarwebjogador')
AddEventHandler('derrubarwebjogador',function(ForwardVectorX,ForwardVectorY,ForwardVectorZ,Tackler)
	TriggerEvent("ragdoll:ChangeStatus", true)
    SetPedToRagdollWithFall(PlayerPedId(),1500,2000,0,ForwardVector,1.0,0.0,0.0,0.0,0.0,0.0,0.0)
	Wait(5000)
	TriggerEvent("ragdoll:ChangeStatus", false)
end)

AddEventHandler("ragdoll:ChangeStatus", function(status)
    -- SetPedCanRagdoll(PlayerPedId(), status)
end)

----------------------------------------------------------------------------------------------------------------------------------------
-- CAR SEAT
----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent('SetarDentroDocarro')
AddEventHandler('SetarDentroDocarro', function()
    local ped = PlayerPedId()
    local ncarro = vRP.getNearestVehicle(15)
    if IsVehicleSeatFree(ncarro, -1) then
        SetPedIntoVehicle(ped, ncarro, -1)
    else
        SetPedIntoVehicle(ped, ncarro, -2)
    end
end)


-----------------------------------------------------------------------------------------------------------------------------------------
-- CONE
-----------------------------------------------------------------------------------------------------------------------------------------
local cone = nil
RegisterNetEvent('cone')
AddEventHandler('cone',function(nome)
	local coord = GetOffsetFromEntityInWorldCoords(PlayerPedId(),0.0,1.0,-0.94)
	local prop = "prop_mp_cone_02"
	local h = GetEntityHeading(PlayerPedId())
	if nome ~= "d" then
		cone = CreateObject(GetHashKey(prop),coord.x,coord.y-0.5,coord.z,true,true,true)
		PlaceObjectOnGroundProperly(cone)
		SetModelAsNoLongerNeeded(cone)
		SetEntityAsMissionEntity(cone,true,true)
		SetEntityHeading(cone,h)
		FreezeEntityPosition(cone,true)
		SetEntityAsNoLongerNeeded(cone)
	else
		if DoesObjectOfTypeExistAtCoords(coord.x,coord.y,coord.z,0.9,GetHashKey(prop),true) then
			cone = GetClosestObjectOfType(coord.x,coord.y,coord.z,0.9,GetHashKey(prop),false,false,false)
			TriggerServerEvent("trydeleteobj",ObjToNet(cone))
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BARREIRA
-----------------------------------------------------------------------------------------------------------------------------------------
local barreira = nil
RegisterNetEvent('barreira')
AddEventHandler('barreira',function(nome)
	local coord = GetOffsetFromEntityInWorldCoords(PlayerPedId(),0.0,1.5,-0.94)
	local prop = "prop_mp_barrier_02b"
	local h = GetEntityHeading(PlayerPedId())
	if nome ~= "d" then
		barreira = CreateObject(GetHashKey(prop),coord.x,coord.y-0.95,coord.z,true,true,true)
		PlaceObjectOnGroundProperly(barreira)
		SetModelAsNoLongerNeeded(barreira)
		SetEntityAsMissionEntity(barreira,true,true)
		SetEntityHeading(barreira,h-180)
		FreezeEntityPosition(barreira,true)
		SetEntityAsNoLongerNeeded(barreira)
	else
		if DoesObjectOfTypeExistAtCoords(coord.x,coord.y,coord.z,0.9,GetHashKey(prop),true) then
			barreira = GetClosestObjectOfType(coord.x,coord.y,coord.z,0.9,GetHashKey(prop),false,false,false)
			TriggerServerEvent("trydeleteobj",ObjToNet(barreira))
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPIKE
-----------------------------------------------------------------------------------------------------------------------------------------
local spike = nil
RegisterNetEvent('spike')
AddEventHandler('spike',function(nome)
	local coord = GetOffsetFromEntityInWorldCoords(PlayerPedId(),0.0,2.5,0.0)
	local prop = "p_ld_stinger_s"
	local h = GetEntityHeading(PlayerPedId())
	if nome ~= "d" then
		spike = CreateObject(GetHashKey(prop),coord.x,coord.y,coord.z,true,true,true)
		PlaceObjectOnGroundProperly(spike)
		SetModelAsNoLongerNeeded(spike)
		SetEntityAsMissionEntity(spike,true,true)
		SetEntityHeading(spike,h-180)
		FreezeEntityPosition(spike,true)
		SetEntityAsNoLongerNeeded(spike)
	else
		if DoesObjectOfTypeExistAtCoords(coord.x,coord.y,coord.z,0.9,GetHashKey(prop),true) then
			spike = GetClosestObjectOfType(coord.x,coord.y,coord.z,0.9,GetHashKey(prop),false,false,false)
			TriggerServerEvent("trydeleteobj",ObjToNet(spike))
		end
	end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- SAFE MODE
-----------------------------------------------------------------------------------------------------------------------------------------
local SafeMode = false
RegisterNetEvent('SetSafeMode', function(status)
	SafeMode = status

	if SafeMode then
		CreateThread(function()
			while SafeMode do
				local ped = PlayerPedId()
				DisableControlAction(2, 37, true) -- desabilitar roda de arma (Tab)
				DisablePlayerFiring(ped,true) -- Desativa o disparo todos juntos se, de alguma forma, ignorarem inzone Mouse Disable
				DisableControlAction(0, 106, true) -- Desative os controles do mouse no jogo
				if IsDisabledControlJustPressed(2, 37) then --se Tab for pressionado, enviar mensagem de erro
					SetCurrentPedWeapon(ped,GetHashKey("WEAPON_UNARMED"),true) -- se a guia for pressionada, eles serão desarmados (isso é para cobrir a falha do veículo até que eu resolva tudo)
					-- exports["mirtin_inventory"]:setinsafe(true)
					exports["vrp_policia"]:setinsafe(true)
					exports["vrp_carry"]:setcarregar2(true)
				end

				if IsDisabledControlJustPressed(0, 106) then --se o botão esquerdo for pressionado, enviar mensagem de erro
					SetCurrentPedWeapon(ped,GetHashKey("WEAPON_UNARMED"),true) -- Se eles clicarem, serão desarmados
					-- exports["mirtin_inventory"]:setinsafe(true)
					exports["vrp_policia"]:setinsafe(true)
					exports["vrp_carry"]:setcarregar2(true)
				end
				Wait(0)
			end
		end)
	end
end)


local in_arena = false

RegisterNetEvent("mirtin_survival:updateArena", function(boolean)
	in_arena = boolean
end)

AddEventHandler("gameEventTriggered", function(eventName, args)


    if eventName == "CEventNetworkEntityDamage" then
		if not IsPedAPlayer(args[2]) then return end
        local victim = args[1]
        if IsPedAPlayer(args[1]) and victim == PlayerPedId() then
			if in_arena then return end
			if LocalPlayer.state.inPvP then
				return
			end
            local plyHealth = GetEntityHealth(victim)
            if plyHealth <= 0 then
				local x,y,z = table.unpack(GetEntityCoords(PlayerPedId()))
                vSERVER._SendLogKillFeed({
                    cds = vec3(x,y,z),
                    attacker = GetPlayerServerId(NetworkGetPlayerIndexFromPed(args[2])),
                    weapon = args[7],
					victim = GetPlayerServerId(NetworkGetPlayerIndexFromPed(args[1])),
                })
			else
				local weapon = args[7]
            end
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- ADMIN:INITSPECTATE
-----------------------------------------------------------------------------------------------------------------------------------------
local spectate = false
RegisterNetEvent("admin:initSpectate")
AddEventHandler("admin:initSpectate",function(source)
	if not NetworkIsInSpectatorMode() then
		local Pid = GetPlayerFromServerId(source)
		local Ped = GetPlayerPed(Pid)
		spectate = true
		NetworkSetInSpectatorMode(true,Ped)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADMIN:RESETSPECTATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("admin:resetSpectate")
AddEventHandler("admin:resetSpectate",function()
	if NetworkIsInSpectatorMode() then
		NetworkSetInSpectatorMode(false)
		spectate = false
	end
end)


src.requestfesta = function(coords, time)
    AddBlipFesta(coords, time)
end

function AddBlipFesta(coords, time)
	if type(coords) ~= 'table' or #coords < 3 then return end
    local x, y, z = coords[1], coords[2], coords[3]
    local blip = AddBlipForCoord(x + 0.001, y + 0.001, z + 0.001)
    SetBlipSprite(blip, 540)
    SetBlipAsShortRange(blip, false)
    SetBlipColour(blip, 48)
    SetBlipScale(blip, 1.0)
    SetBlipPriority(blip, 5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("FESTA")
    EndTextCommandSetBlipName(blip)

    Citizen.SetTimeout((time * 1000) or 18000, function()
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end

local canEnterParty = false
local partyCoords = vec3(0.0, 0.0, 0.0)

function src.checkTeleportFesta(coords, time)
    local x, y, z = tonumber(coords[1]), tonumber(coords[2]), tonumber(coords[3])
    if not x or not y or not z then return end

    canEnterParty = true
    partyCoords = vec3(x, y, z)

    local startTime = GetGameTimer()
    local endTime = startTime + (time * 1000)
    CreateThread(function()
        while GetGameTimer() < endTime do
            Wait(1000)
        end
        canEnterParty = false
    end)
end

ClientAudit.RegisterCommand('+enterparty', function(source, args)
    local playerPed = PlayerPedId()
    if GetEntityHealth(playerPed) <= 101 then
        TriggerEvent('Notify', 'aviso', 'Você não pode fazer isso morto.')
        return
    end

    if canEnterParty then
        SetEntityCoords(playerPed, partyCoords)
    else
        TriggerEvent('Notify', 'erro', 'O evento já acabou ou está indisponível.')
    end
end)

RegisterKeyMapping('+enterparty', 'Entrar na festa', 'keyboard', 'F4')
------------------------------------------------------------------------------------------------------------------------------------------------
-- PPRESET
------------------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("ppreset:requestClothingInfo")
AddEventHandler("ppreset:requestClothingInfo", function(requester_source)
    local ped = PlayerPedId()

    local clothes = {
        jaqueta = GetPedDrawableVariation(ped, 11),
        jaqueta_texture = GetPedTextureVariation(ped, 11),
        calca = GetPedDrawableVariation(ped, 4),
        calca_texture = GetPedTextureVariation(ped, 4),
        blusa = GetPedDrawableVariation(ped, 8),
        blusa_texture = GetPedTextureVariation(ped, 8),
        sapatos = GetPedDrawableVariation(ped, 6),
        sapatos_texture = GetPedTextureVariation(ped, 6),
        oculos = GetPedPropIndex(ped, 1),
        oculos_texture = GetPedPropTextureIndex(ped, 1),
        acessorios = GetPedDrawableVariation(ped, 7),
        acessorios_texture = GetPedTextureVariation(ped, 7),
        chapeu = GetPedPropIndex(ped, 0),
        chapeu_texture = GetPedPropTextureIndex(ped, 0),
        colete = GetPedDrawableVariation(ped, 9),
        colete_texture = GetPedTextureVariation(ped, 9),
        mascara = GetPedDrawableVariation(ped, 1),
        mascara_texture = GetPedTextureVariation(ped, 1),
        maos = GetPedDrawableVariation(ped, 3),
        maos_texture = GetPedTextureVariation(ped, 3)
    }

    local clothingData = string.format("jaqueta %d %d; calca %d %d; blusa %d %d; sapatos %d %d; oculos %d %d; acessorios %d %d; chapeu %d %d; colete %d %d; mascara %d %d; maos %d %d;"
    , clothes.jaqueta, clothes.jaqueta_texture, clothes.calca, clothes.calca_texture, clothes.blusa, clothes.blusa_texture,clothes.sapatos, clothes.sapatos_texture, clothes.oculos, clothes.oculos_texture, clothes.acessorios, clothes.acessorios_texture, clothes.chapeu, clothes.chapeu_texture, clothes.colete, clothes.colete_texture, clothes.mascara, clothes.mascara_texture, clothes.maos, clothes.maos_texture)

    TriggerServerEvent("ppreset:receiveClothingInfo", requester_source, clothingData)
end)

RegisterNetEvent("ppreset:displayClothingInfo")
AddEventHandler("ppreset:displayClothingInfo", function(clothingData)
    TriggerServerEvent('roupasinfo:sendInfo', clothingData)
end)
------------------------------------------------------------------------------------------------------------------------------------------------

CreateThread(function() 
    local pickupList = {`PICKUP_AMMO_BULLET_MP`,`PICKUP_AMMO_FIREWORK`,`PICKUP_AMMO_FLAREGUN`,`PICKUP_AMMO_GRENADELAUNCHER`,`PICKUP_AMMO_GRENADELAUNCHER_MP`,`PICKUP_AMMO_HOMINGLAUNCHER`,`PICKUP_AMMO_MG`,`PICKUP_AMMO_MINIGUN`,`PICKUP_AMMO_MISSILE_MP`,`PICKUP_AMMO_PISTOL`,`PICKUP_AMMO_RIFLE`,`PICKUP_AMMO_RPG`,`PICKUP_AMMO_SHOTGUN`,`PICKUP_AMMO_SMG`,`PICKUP_AMMO_SNIPER`,`PICKUP_ARMOUR_STANDARD`,`PICKUP_CAMERA`,`PICKUP_CUSTOM_SCRIPT`,`PICKUP_GANG_ATTACK_MONEY`,`PICKUP_HEALTH_SNACK`,`PICKUP_HEALTH_STANDARD`,`PICKUP_MONEY_CASE`,`PICKUP_MONEY_DEP_BAG`,`PICKUP_MONEY_MED_BAG`,`PICKUP_MONEY_PAPER_BAG`,`PICKUP_MONEY_PURSE`,`PICKUP_MONEY_SECURITY_CASE`,`PICKUP_MONEY_VARIABLE`,`PICKUP_MONEY_WALLET`,`PICKUP_PARACHUTE`,`PICKUP_PORTABLE_CRATE_FIXED_INCAR`,`PICKUP_PORTABLE_CRATE_UNFIXED`,`PICKUP_PORTABLE_CRATE_UNFIXED_INCAR`,`PICKUP_PORTABLE_CRATE_UNFIXED_INCAR_SMALL`,`PICKUP_PORTABLE_CRATE_UNFIXED_LOW_GLOW`,`PICKUP_PORTABLE_DLC_VEHICLE_PACKAGE`,`PICKUP_PORTABLE_PACKAGE`,`PICKUP_SUBMARINE`,`PICKUP_VEHICLE_ARMOUR_STANDARD`,`PICKUP_VEHICLE_CUSTOM_SCRIPT`,`PICKUP_VEHICLE_CUSTOM_SCRIPT_LOW_GLOW`,`PICKUP_VEHICLE_HEALTH_STANDARD`,`PICKUP_VEHICLE_HEALTH_STANDARD_LOW_GLOW`,`PICKUP_VEHICLE_MONEY_VARIABLE`,`PICKUP_VEHICLE_WEAPON_APPISTOL`,`PICKUP_VEHICLE_WEAPON_ASSAULTSMG`,`PICKUP_VEHICLE_WEAPON_COMBATPISTOL`,`PICKUP_VEHICLE_WEAPON_GRENADE`,`PICKUP_VEHICLE_WEAPON_MICROSMG`,`PICKUP_VEHICLE_WEAPON_MOLOTOV`,`PICKUP_VEHICLE_WEAPON_PISTOL`,`PICKUP_VEHICLE_WEAPON_PISTOL50`,`PICKUP_VEHICLE_WEAPON_SAWNOFF`,`PICKUP_VEHICLE_WEAPON_SMG`,`PICKUP_VEHICLE_WEAPON_SMOKEGRENADE`,`PICKUP_VEHICLE_WEAPON_STICKYBOMB`,`PICKUP_WEAPON_ADVANCEDRIFLE`,`PICKUP_WEAPON_APPISTOL`,`PICKUP_WEAPON_ASSAULTRIFLE`,`PICKUP_WEAPON_ASSAULTSHOTGUN`,`PICKUP_WEAPON_ASSAULTSMG`,`PICKUP_WEAPON_AUTOSHOTGUN`,`PICKUP_WEAPON_BAT`,`PICKUP_WEAPON_BATTLEAXE`,`PICKUP_WEAPON_BOTTLE`,`PICKUP_WEAPON_BULLPUPRIFLE`,`PICKUP_WEAPON_BULLPUPSHOTGUN`,`PICKUP_WEAPON_CARBINERIFLE`,`PICKUP_WEAPON_COMBATMG`,`PICKUP_WEAPON_COMBATPDW`,`PICKUP_WEAPON_COMBATPISTOL`,`PICKUP_WEAPON_COMPACTLAUNCHER`,`PICKUP_WEAPON_COMPACTRIFLE`,`PICKUP_WEAPON_CROWBAR`,`PICKUP_WEAPON_DAGGER`,`PICKUP_WEAPON_DBSHOTGUN`,`PICKUP_WEAPON_FIREWORK`,`PICKUP_WEAPON_FLAREGUN`,`PICKUP_WEAPON_FLASHLIGHT`,`PICKUP_WEAPON_GRENADE`,`PICKUP_WEAPON_GRENADELAUNCHER`,`PICKUP_WEAPON_GUSENBERG`,`PICKUP_WEAPON_GOLFCLUB`,`PICKUP_WEAPON_HAMMER`,`PICKUP_WEAPON_HATCHET`,`PICKUP_WEAPON_HEAVYPISTOL`,`PICKUP_WEAPON_HEAVYSHOTGUN`,`PICKUP_WEAPON_HEAVYSNIPER`,`PICKUP_WEAPON_HOMINGLAUNCHER`,`PICKUP_WEAPON_KNIFE`,`PICKUP_WEAPON_KNUCKLE`,`PICKUP_WEAPON_MACHETE`,`PICKUP_WEAPON_MACHINEPISTOL`,`PICKUP_WEAPON_MARKSMANPISTOL`,`PICKUP_WEAPON_MARKSMANRIFLE`,`PICKUP_WEAPON_MG`,`PICKUP_WEAPON_MICROSMG`,`PICKUP_WEAPON_MINIGUN`,`PICKUP_WEAPON_MINISMG`,`PICKUP_WEAPON_MOLOTOV`,`PICKUP_WEAPON_MUSKET`,`PICKUP_WEAPON_NIGHTSTICK`,`PICKUP_WEAPON_PETROLCAN`,`PICKUP_WEAPON_PIPEBOMB`,`PICKUP_WEAPON_PISTOL`,`PICKUP_WEAPON_PISTOL50`,`PICKUP_WEAPON_POOLCUE`,`PICKUP_WEAPON_PROXMINE`,`PICKUP_WEAPON_PUMPSHOTGUN`,`PICKUP_WEAPON_RAILGUN`,`PICKUP_WEAPON_REVOLVER`,`PICKUP_WEAPON_RPG`,`PICKUP_WEAPON_SAWNOFFSHOTGUN`,`PICKUP_WEAPON_SMG`,`PICKUP_WEAPON_SMOKEGRENADE`,`PICKUP_WEAPON_SNIPERRIFLE`,`PICKUP_WEAPON_SNSPISTOL`,`PICKUP_WEAPON_SPECIALCARBINE`,`PICKUP_WEAPON_STICKYBOMB`,`PICKUP_WEAPON_STUNGUN`,`PICKUP_WEAPON_SWITCHBLADE`,`PICKUP_WEAPON_VINTAGEPISTOL`,`PICKUP_WEAPON_WRENCH`, `PICKUP_WEAPON_RAYCARBINE`}
    local Playerid = PlayerId()
    for a = 1, #pickupList do
		ToggleUsePickupsForPlayer(Playerid, pickupList[a], false)
    end
    while true do
		local pickupPool = GetGamePool('CPickup') 
		for i = 1, #pickupPool do
			if NetworkHasControlOfPickup(pickupPool[i]) then
				print("[pickup-manager] Pickup detectada & deletada")
			end
			RemovePickup(pickupPool[i])
		end
		Wait(10000)
    end
end)

ClientAudit.RegisterCommand('record',function(source, args) 
    if tostring(args[1]) == 'start' then
        StartRecording(1)
    elseif tostring(args[1]) == 'save' then
        StopRecordingAndSaveClip()
    elseif tostring(args[1]) == 'discard' then
        StopRecordingAndDiscardClip()
    elseif tostring(args[1]) == 'open' then
        NetworkSessionLeaveSinglePlayer()

        ActivateRockstarEditor()
    end
end)

RegisterNetEvent("drawnotification2")
AddEventHandler("drawnotification2",function(string)
    if aimlock then
        SetNotificationTextEntry("STRING")
        AddTextComponentString(string)
        DrawNotification(true, false)
    end
end)
function drawNotification(string)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(string)
	DrawNotification(true, false)
end




local delay = false
ClientAudit.RegisterCommand("guardarroupas",function(source,args,rawCommand)
	if not menuOpen and not delay then
		delay = true

		local ped = PlayerPedId()
	    local clothes = vSERVER.getClothes()

		if GetEntityHealth(ped) > 101 then
			local myOutfits = {}

            if clothes then
                for _,v in pairs(clothes) do
					table.insert(myOutfits, {
						["name"] = v.name,
						["image"] = "clothe",
						["delete"] = true,
						["trigger"] = {
							["name"] = "player:setClothes",
							["delete"] = true,
							["isServer"] = true,
							["args"] = {v.name, "roupas"}
						}
					})
                end
            end

			local createMenu = {
				{
					["name"] = "Carregar Ombros",
					["image"] = "carry",
					["description"] = "Carregar Jogador Próximo",
					["trigger"] = {
						["type"] = "command",
						["name"] = "carregar",
					}
				},

				["Outifits"] = {
					["description"] = "Gerencie suas roupas.",
					["image"] = "clothe",
					["options"] = {
						["Ver Outfits"] = {
							["image"] = "clothe",
							["description"] = "Deletar uma roupa salva.",
							["options"] = myOutfits
						},
						{
							["name"] = "Salvar",
							["image"] = "save",
							["description"] = "Guardar as roupas do corpo.",
							["modal"] = true,
							["trigger"] = {
								["name"] = "player:outfitFunctions",
								["args"] = { "salvar" },
								["isServer"] = true,
							}
						},
						{
							["name"] = "Retirar Roupa",
							["image"] = "clothe",
							["description"] = "Retirar sua roupa.",
							["trigger"] = {
								["name"] = "player:outfitFunctions",
								["args"] = { "remover" },
								["isServer"] = true,
							}
						}
					}
				},
				{
					["name"] = "Colocar",
					["image"] = "vehicle",
					["description"] = "Colocar proximo ao porta-malas",
					["trigger"] = {
						["name"] = "novak:server:insertUserInTrunkin",
						["isServer"] = true,
					},
				},

				{
					["name"] = "Desbugar",
					["image"] = "debug",
					["description"] = "Desbugar",
					["trigger"] = {
						["isServer"] = true,
						["name"] = "desbugplayer",
					}
				},

				{
					["name"] = "Retirar",
					["image"] = "vehicle",
					["description"] = "Remover proximo do porta-malas",
					["trigger"] = {
						["name"] = "novak:server:removerUserInTrunkin",
						["isServer"] = true,
					},
				},
			}
			exports['m_dynamic']:createMenu(createMenu)
			SetTimeout(5000, function() delay = false end)
		end
	end
end, false)
RegisterKeyMapping("guardarroupas","Abrir menu principal.","keyboard","F9")


-- local delay = false
-- ClientAudit.RegisterCommand("guardarroupas",function(source,args,rawCommand)
-- 	if not menuOpen and not delay then
-- 		delay = true

-- 		local ped = PlayerPedId()
-- 	    local clothes = vSERVER.getClothes()

-- 		if GetEntityHealth(ped) > 101 then
-- 			exports["dynamic"]:AddButton("Salvar","Guardar as roupas do corpo.","player:outfitFunctions","salvar","outfit",true)
-- 			exports["dynamic"]:AddButton("Retirar","Retirar sua roupa.","player:outfitFunctions","remover","outfit",true)
-- 			exports["dynamic"]:AddButton("Deletar","Deletar uma roupa salva.","player:outfitFunctions","deletar","outfit",true)

--             exports["dynamic"]:SubMenu("Outfits","Listar roupas salvas.","roupas",true)
--             exports["dynamic"]:SubMenu("Vestuário","Mudança de roupas rápidas.","outfit")

--             if clothes then
--                 for k,v in pairs(clothes) do 
--                     exports["dynamic"]:AddButton(v.name,"Clique para colocar a sua roupa.","player:setClothes",v.name,"roupas",true)
--                 end
--             end

-- 			SetTimeout(5000, function() delay = false end)
-- 		end
-- 	end
-- end)
-- RegisterKeyMapping("guardarroupas","Abrir menu principal.","keyboard","F9")





local BlockedModels = {}
local REPORTADO = false
local REPORTADO_2 = false
local REPORTADO_3 = false
local founded_sizes = {}

function src.parseSize(model)
	local size = founded_sizes[model]
	if not size then
		local min, max = GetModelDimensions(model) 
		local size_vec = max - min
		size = size_vec.x + size_vec.y + size_vec.z
		founded_sizes[model] = size
	end
	return size
end


local flash = false 
ClientAudit.RegisterCommand("flash", function(source, args)
    if not vSERVER.getPermissao() then
        return
    end

    --flash = not flash 
    if not flash then
		SetRunSprintMultiplierForPlayer(PlayerId(),1.49)
		flash = true
        TriggerEvent('Notify','sucesso','Flash Ligado.')
	else
		SetRunSprintMultiplierForPlayer(PlayerId(),1.0)
		RestorePlayerStamina(PlayerId(),1.0)
		flash = false
        TriggerEvent('Notify','sucesso','Flash Desligado.')
	end
end)

local freeze = false

function src.setFreeze()
    freeze = not freeze 
    FreezeEntityPosition(PlayerPedId(),freeze)
	LocalPlayer.state:set("Freeze",freeze,false)
    return freeze
end


exports("freezeAdmin", function()
	return freeze
end)




local inAnyZone = false 
local inZonePCC = false

local function CheckPlayerZone()
    inAnyZone = inZonePCC 
end

--[[ EXEMPLO
    zonaPCC:onPlayerInOut(function(naZona, _)
    inZonePCC = naZona
    CheckPlayerZone()
    if naZona then 
        if not vSERVER.getPermFac("perm.baupcc") then
            TriggerEvent("Notify",'aviso','Você não é do PCC e não pode atirar neste local.')
            SetCurrentPedWeapon(PlayerPedId(),GetHashKey("WEAPON_UNARMED"),true)
            disableWeaponFac()
        end
    end
end)
]]

function disableWeaponFac()
    Citizen.CreateThread(function()
		exports["vrp_policia"]:setinsafe(true)
        while inAnyZone do
            Wait(4)
            SetCurrentPedWeapon(PlayerPedId(), GetHashKey("WEAPON_UNARMED"), true)
            DisableControlAction(2, 37, true) -- desabilitar roda de arma (Tab)
        end
		exports["vrp_policia"]:setinsafe(false)
    end)
end



CreateThread(function()
	local limboCDS = vec3(-270.0,-1793.89,4.03)
	while true do 
		local pedCoords = GetEntityCoords(PlayerPedId())

		if #(pedCoords - limboCDS) <= 10.0 then
			SetEntityCoords(PlayerPedId(), -262.61,-1897.04,27.73)
		end

		Wait(3000)
	end
end)




local voiceState = false
ClientAudit.RegisterCommand("vozes", function()
	voiceState = not voiceState
	if voiceState then
		CreateThread(function() 
			local _Wait = Wait
			local _MumbleGetTalkerProximity = MumbleGetTalkerProximity
			while voiceState do
				local myCoords = GetEntityCoords(PlayerPedId())
				for k,v in pairs(GetActivePlayers()) do
					if MumbleIsPlayerTalking(v) then
						local ped = GetPlayerPed(v)
						print(GetPlayerName(v), "| src: "..GetPlayerServerId(v).." | dist: "..#(myCoords - GetEntityCoords(ped)), MumbleGetVoiceChannelFromServerId(GetPlayerServerId(v)))
					end
				end
				_Wait(1000)
			end
		end)
	end
end)




local function pretty_dbg(tbl)
	tbl.func = nil
	return json.encode(tbl)
end


CreateThread(function()
	while true do
		local dicas = {
			{ title = 'DICA', message = 'Para saber quantos cidadãos estão acordados, digite /status', type = 'tip' },
			{ title = 'DICA', message = 'Para ganhar premiação gratuitamente, digite /box', type = 'tip' },
			{ title = 'DICA', message = 'Para melhorar seu FPS, digite /fps on', type = 'tip' },
			{ title = 'DICA', message = 'Para mudar a altura do VOIP, use o botão Home', type = 'tip' },
			{ title = 'DICA', message = 'Para trocar o HUD, digite /trocarhud', type = 'tip' },
			{ title = 'DICA', message = 'Para desligar notificações, digite /notoff', type = 'tip' },
			{ title = 'DICA', message = 'Para guardar suas armas digite o comando /garmas', type = 'tip' },
			{ title = 'DICA', message = 'VOCÊ PODE RESGATAR PREMIAÇÕES DIARIAS NO DAILY EM SEU ESC', type = 'tip' },
			-- { title = 'DICA', message = 'QUER TER BENEFÍCIOS VIPS E EXCLUSIVOS DENTRO DO SERVIDOR? DIGITE /LOJA E ACESSE JÁ!', type = 'store' },
		}

		local randomDicas = dicas[math.random(1, #dicas)]
		TriggerEvent('chatMessage', {
			type = randomDicas.type,
			title = randomDicas.title,
			message = randomDicas.message
		})
		Wait(60000 * math.random(2, 10))
	end
end)

CreateThread(function()
	local SLEEP = 5 * 60 * 1000
	while true do
		TriggerEvent('chatMessage', {
			type = 'store',
			title = 'ACESSE NOSSA LOJA',
			message = 'QUER TER BENEFÍCIOS VIPS E EXCLUSIVOS DENTRO DO SERVIDOR? DIGITE /LOJA E ACESSE JÁ!'
		})
		Wait(SLEEP)
	end
end)

ClientAudit.RegisterCommand("checkdriver", function() 
	

	local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
	CreateThread(function() 
		while true do
			if DoesEntityExist(vehicle) then
				for k,v in pairs(GetActivePlayers()) do
					local ped = GetPlayerPed(v)
					if IsPedExclusiveDriverOfVehicle(vehicle, ped, -1) or IsPedExclusiveDriverOfVehicle(vehicle, ped, 0) then
						print(GetPlayerName(v), '| src =>',  GetPlayerServerId(v))
					end
				end
			else 
				break
			end
			Wait(1)
		end

	end)
end)
local function get_all_entities()
	local entities = {}
	for k,v in pairs(GetGamePool('CObject')) do
		table.insert(entities, v)
	end
	for k,v in pairs(GetGamePool('CPed')) do
		if not IsPedAPlayer(v) then
			table.insert(entities, v)
		else
			print("Ignorando ped player -> ", GetEntityModel(v))
		end
	end
	return entities
end

ClientAudit.RegisterCommand("verentidades", function(source, args, rawCommand)
	local res = ""
	local radius = tonumber(args[1]) or 10.0
	for k,v in pairs(get_all_entities()) do
		local coords = GetEntityCoords(v)
		if #(coords - GetEntityCoords(PlayerPedId())) <= radius then
			local archetype = GetEntityArchetypeName(v) or "none"
			local message = string.format("Type: %s | Model: %s | Archetype: %s | Distance: %s", GetEntityType(v), GetEntityModel(v), archetype, #(coords - GetEntityCoords(PlayerPedId())))
			res = res..message.."\n"
		end
	end
	print(res)
	vRP.prompt("Resultado", res)
end)


local flash2 = false 
ClientAudit.RegisterCommand("flash2", function(source, args)
    if not vSERVER.getPermissao() then
        return
    end

    --flash = not flash 
    if not flash2 then
		SetRunSprintMultiplierForPlayer(PlayerId(),1.49)
		SetPedMoveRateOverride(PlayerPedId(), 10.0)
		flash2 = true
        TriggerEvent('Notify','sucesso','Flash Ligado.')
	else
		SetRunSprintMultiplierForPlayer(PlayerId(),1.0)
		SetPedMoveRateOverride(PlayerPedId(), 1.0)
		RestorePlayerStamina(PlayerId(),1.0)
		flash2 = false
        TriggerEvent('Notify','sucesso','Flash Desligado.')
	end
end)

local jump = false
ClientAudit.RegisterCommand('jump', function()
	if not vSERVER.getPermissao() then
        return
    end

	local playerPed = PlayerPedId()

	if not jump then
		jump = true
		Citizen.CreateThread(function()
			while jump do
				SetSuperJumpThisFrame(PlayerId())
				SetPlayerInvincible(PlayerId(), true)
				SetPedCanRagdoll(PlayerPedId(), false)
				Citizen.Wait(0)
			end
		end)
	else
		jump = false
	end
end)

exports('checkPerm', function()
	return vSERVER.getPermissao()
end)
exports('checkStaffPerm', function()
	return vSERVER.checkStaffPerm()
end)

CreateThread(function()
	while true do
		local ped = PlayerPedId()
		local timeDistance = 3000
		if IsPedInAnyVehicle(ped, false) then
			local vehicle = GetVehiclePedIsIn(ped, false)
			local vehicleCoords = GetEntityCoords(vehicle)
			if vehicleCoords.z < -60.14 then
				vSERVER.limbo()
			end
		end
		Wait(timeDistance)
	end
end)

local block_limbo = false
ClientAudit.RegisterCommand("limbo",function(source,args,rawCommand) 
    if block_limbo then
        return TriggerEvent("Notify","negado","Voce ja usou esse comando ou ja passou o tempo para usar, caso queira usar novamente. Relogue!")
    end
    block_limbo = true

    local ped = PlayerPedId()
    local x,y,z = table.unpack(GetEntityCoords(PlayerPedId()))
    if #(vec3(x,y,z) - vec(-0.01, -0.01, -0.32)) <= 20.0 then
        SetEntityCoordsNoOffset(ped,362.37, 298.25, 103.88,0,0,1)
        return
    end

    local groundCheckHeights = { 0.0,50.0,100.0,150.0,200.0,250.0,300.0,350.0,400.0,450.0,500.0,550.0,600.0,650.0,700.0,750.0,800.0,850.0,900.0,950.0,1000.0,1050.0,1100.0,1150.0,1200.0,1250.0,1300.0,1350.0,1400.0,1450.0,1500.0,1850.0,1900.0 }
    for i,height in ipairs(groundCheckHeights) do
        SetEntityCoordsNoOffset(ped,x,y,height,0,0,1)
        RequestCollisionAtCoord(x,y,z)
        while not HasCollisionLoadedAroundEntity(ped) do
            RequestCollisionAtCoord(x,y,z)
            Citizen.Wait(1)
        end
        Citizen.Wait(20)
        ground,z = GetGroundZFor_3dCoord(x,y,height)
        if ground then
            z = z + 1.0
            groundFound = true
            break;
        end
    end

    if not groundFound then
        z = 1200
    end
    RequestCollisionAtCoord(x,y,z)
    while not HasCollisionLoadedAroundEntity(ped) do
        RequestCollisionAtCoord(x,y,z)
        Citizen.Wait(1)
    end
    SetEntityCoordsNoOffset(ped,x,y,z,0,0,1)
end)

CreateThread(function()
    Wait(10000)
    TriggerEvent("Notify","importante","Caso esteja no limbo digite o comando /limbo, para sair dele.", 60000)

    SetTimeout(60000, function()
        block_limbo = true
    end)
end)


RegisterNetEvent("Admin:ChoseColor",function(Data)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped)
    if IsEntityAVehicle(vehicle) then  
        SetVehicleModColor_1(vehicle,tonumber(Data[1]),tonumber(Data[2]),tonumber(Data[3]))
        SetVehicleModColor_2(vehicle,tonumber(Data[1]),tonumber(Data[2]),tonumber(Data[3]))
        SetVehicleCustomPrimaryColour(vehicle,tonumber(Data[1]),tonumber(Data[2]),tonumber(Data[3]))
        SetVehicleCustomSecondaryColour(vehicle,tonumber(Data[1]),tonumber(Data[2]),tonumber(Data[3]))
    end
end)

function src.getVehicleName(vehicle)
	local vehicleEntity = NetworkGetEntityFromNetworkId(vehicle)
	local vehicleName = GetDisplayNameFromVehicleModel(GetEntityModel(vehicleEntity))
	return vehicleName
end

function src.inDomination()
	return exports.dominacao:inDomination() or exports.dm_module:inDomination() or exports['01_dominacao_pistol']:inDomination()
end

local hudStatus = true
CreateThread(function()
	while true do
		if IsPauseMenuActive() and hudStatus then
			TriggerEvent('flaviin:toggleHud', false)
			hudStatus = false
		elseif not IsPauseMenuActive() and not hudStatus then
			TriggerEvent('flaviin:toggleHud', true)
			hudStatus = true
		end
		Wait(1000)
	end
end)

RegisterNetEvent('abrircapo', function()
	ExecuteCommand("capo")
end)

ClientAudit.RegisterCommand('SDAIASDIJ', function()
	TriggerEvent("CHECK_DBG_STR", 'TriggerServerEvent')
end)

-- local inZoneDisableCollision = false

-- local zoneRuaBC = PolyZone:Create({
-- 	vector2(564.57458496094, 258.25140380859),
-- 	vector2(497.45977783203, 67.277191162109),
-- 	vector2(179.71324157715, 180.58432006836),
-- 	vector2(8.6768102645874, 243.06973266602),
-- 	vector2(-102.66213226318, 237.72259521484),
-- 	vector2(-169.20422363281, 238.68383789063),
-- 	vector2(-284.31921386719, 245.04922485352),
-- 	vector2(-362.89935302734, 224.51037597656),
-- 	vector2(-428.63482666016, 224.8994140625),
-- 	vector2(-559.69586181641, 240.73362731934),
-- 	vector2(-547.54467773438, 272.59317016602),
-- 	vector2(-550.89190673828, 451.46319580078),
-- 	vector2(-148.34674072266, 449.80572509766),
-- 	vector2(208.78303527832, 396.91311645508)
-- }, {
-- 	name="ruabc",
-- 	--minZ = 82.765808105469,
-- 	--maxZ = 114.41422271729
-- })

-- zoneRuaBC:onPlayerInOut(function(naZona, _)
--     inZoneDisableCollision = naZona
-- end)

-- local zoneVermelho = PolyZone:Create({
-- 	vector2(60.500499725342, -1004.2694702148),
-- 	vector2(135.00151062012, -783.62432861328),
-- 	vector2(12.016539573669, -739.15893554688),
-- 	vector2(-236.79264831543, -648.15704345703),
-- 	vector2(-321.68807983398, -640.85168457031),
-- 	vector2(-653.86474609375, -643.04235839844),
-- 	vector2(-654.05932617188, -855.76800537109),
-- 	vector2(-483.07437133789, -848.48480224609),
-- 	vector2(-366.1242980957, -856.03430175781),
-- 	vector2(-282.55139160156, -874.34149169922)
-- }, {
-- 	name="vermelho",
-- 	--minZ = 24.836532592773,
-- 	--maxZ = 34.606246948242
-- })
  
-- zoneVermelho:onPlayerInOut(function(naZona, _)
--     inZoneDisableCollision = naZona
-- end)

-- CreateThread(function()
--     while true do
--         local timeDistance = 2000
--         if inZoneDisableCollision then
--             timeDistance = 0
--             local ped = PlayerPedId()
--             local vehList = GetGamePool('CVehicle')
--             for k,v in pairs(vehList) do
--                 SetEntityNoCollisionEntity(v, ped, true)
--                 if IsPedInAnyVehicle(ped) then
--                     local veh = GetVehiclePedIsIn(ped)
--                     if veh ~= v then
--                         SetEntityNoCollisionEntity(v, veh, true)
--                     end
--                 end
--             end
--         end
--         Wait(timeDistance)
--     end
-- end)

local zonesInPerimeter = {}
local perimeterBlips = {}
local centerBlips = {}
local inPerimeter = nil

function src.createPerimeter(userId, coords)
    zonesInPerimeter[tostring(userId)] = { coords = coords }
	
	perimeterBlips[tostring(userId)] = AddBlipForRadius(coords[1], coords[2], coords[3], 250.0)
	SetBlipSprite(perimeterBlips[tostring(userId)], 9)
	SetBlipColour(perimeterBlips[tostring(userId)], 1)
	SetBlipAlpha(perimeterBlips[tostring(userId)], 100)
	
	centerBlips[tostring(userId)] = AddBlipForCoord(coords[1], coords[2], coords[3])
	SetBlipSprite(centerBlips[tostring(userId)], 161)
	SetBlipColour(centerBlips[tostring(userId)], 1)
	SetBlipScale(centerBlips[tostring(userId)], 0.8)
	BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Perímetro")
    EndTextCommandSetBlipName(centerBlips[tostring(userId)])
end

function src.removePerimeter(userId)
    zonesInPerimeter[tostring(userId)] = nil
	
	if DoesBlipExist(perimeterBlips[tostring(userId)]) then
		RemoveBlip(perimeterBlips[tostring(userId)])
		perimeterBlips[tostring(userId)] = nil
	end
	
	if DoesBlipExist(centerBlips[tostring(userId)]) then
		RemoveBlip(centerBlips[tostring(userId)])
		centerBlips[tostring(userId)] = nil
	end
end

CreateThread(function()
	while true do
		local ped = PlayerPedId()
		local coords = GetEntityCoords(ped)
		for k,v in pairs(zonesInPerimeter) do
			if #(coords - v.coords) < 250.0 then
				if inPerimeter ~= k then
					TriggerEvent('Notify', 'aviso', 'Você entrou em uma área de código 10, por favor, saia da área para evitar problemas.')
					inPerimeter = k
				end
			else
				if inPerimeter == k then
					inPerimeter = nil
				end
			end
		end
		Wait(1000)
	end
end)

local vtrs = {
    "wrdusterpol", "wrspinpol", "wrtrailpol", "wrcorollapol", "wras350pol",
    "wrsw4pol", "wrxt660pol", "WRstorm", "caveiraopmerj", "wr5ton",
    "wrranger23eb", "wrranger23ebc", "uh1exercito", "wrhaitun", "WRtrailblazer22",
    "WRranger23", "wrr1200pm", "WRas350", "wrblindadoramfed", "fbi",
    "wrcb500fed", "wrcorollafed", "wrl200fed", "wrtrailfed", "wras350fed",
    "WRtrailblazerprf", "WRranger21", "WR21hiluxprf", "WRcruzeprf", "WRl200prf",
    "WRprfcamaro19", "WRas350prf", "WRbell407prf", "WRCorolla", "WRl200",
    "WRpajero", "WRstorm","pdfocus","pd_i8","tigerpolicia","amarokpolicia"
}

function isVehicleVtr(vehicle)
    if not vehicle or vehicle == 0 then return false end
    
    for _, vtr in ipairs(vtrs) do
        if GetEntityModel(vehicle) == GetHashKey(vtr) then
            return true
        end
    end

    return false
end

CreateThread(function()
    local lastVehicleCheck = nil
    
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle and vehicle > 0 and vehicle ~= lastVehicleCheck and isVehicleVtr(vehicle) and GetPedInVehicleSeat(vehicle, -1) == ped then
            if not vSERVER.checkUserIsCop() then
                TaskLeaveVehicle(ped, vehicle, 4160)
                TriggerEvent('Notify', 'aviso', 'Você precisa ser um policial em serviço para entrar em uma viatura')
			else
				lastVehicleCheck = vehicle
			end
        end
        
        Wait(1000)
    end
end)

RegisterNetEvent('checkIsInDomination', function()
	print('status dominacao', (exports.dm_module:inDomination() or exports.dominacao:inDomination()))
	if exports.dm_module:inDomination() or exports.dominacao:inDomination() then
		SetEntityCoords(PlayerPedId(), 218.87,-808.39,30.7)
	end
end)

local cooldownMecanico = 0

function DrawText3DVeh(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)

    if onScreen then
        local width = 0.12
        local height = 0.03
        local boxX = _x
        local boxY = _y + 0.012

        DrawRect(boxX, boxY, width, height, 0, 0, 0, 150)

        SetTextScale(0.4, 0.4)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextCentre(1)
        SetTextEntry("STRING")
        AddTextComponentString("[~g~E~w~] - CHAMAR MECÂNICO")
        DrawText(_x, _y)
    end
end

CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local vehicles = GetGamePool("CVehicle")
        local closestVehicle = nil
        local closestDistance = 10.0
        local sleepTime = 4000

        for _, vehicle in ipairs(vehicles) do
            local vehicleCoords = GetEntityCoords(vehicle)
            local distance = #(playerCoords - vehicleCoords)

            if distance < 10.0 then
                local engineHealth = GetVehicleEngineHealth(vehicle)
                local bodyHealth = GetVehicleBodyHealth(vehicle)

                if engineHealth <= 0 or bodyHealth < 100 or IsEntityOnFire(vehicle) then
                    if distance < closestDistance then
                        closestVehicle = vehicle
                        closestDistance = distance
                    end
                end
            end
        end

        if closestVehicle then
            local vehicleCoords = GetEntityCoords(closestVehicle)
            DrawText3DVeh(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + 1.2, "[E] - CHAMAR MECÂNICO")
            sleepTime = 0

            if IsControlJustReleased(0, 38) and GetGameTimer() > cooldownMecanico then
                cooldownMecanico = GetGameTimer() + (1000 * 60)
                TriggerServerEvent("hub:sendCallType", nil, "mecanico", "Meu veículo está danificado, preciso de um mecânico.")
            end
        end

        Wait(sleepTime)
    end
end)

local inAutoPilot = false

function startAutoPilot()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        TriggerEvent('Notify', 'aviso', 'Você não está em um veículo')
        return false
    end

    local blip = GetFirstBlipInfoId(8)
    if not DoesBlipExist(blip) then
        TriggerEvent('Notify', 'aviso', 'Não há um destino definido')
        return false
    end

    local veh = GetVehiclePedIsIn(ped, false)
    if not veh or veh == 0 then
        TriggerEvent('Notify', 'erro', 'Erro ao detectar o veículo')
        return false
    end

    local bCoords = GetBlipCoords(blip)
    ClearPedTasks(ped)

    TaskVehicleDriveToCoord(ped, veh, bCoords.x, bCoords.y, bCoords.z, 500.0, 0, veh, 1074528293, 0, true)
    SetDriveTaskDrivingStyle(ped, 1074528293)
    inAutoPilot = true

    CreateThread(function()
        while inAutoPilot do
            Wait(250)
            
            if not IsPedInAnyVehicle(ped, false) then
                stopAutoPilot()
                return
            end

            local pedCoords = GetEntityCoords(ped)
            if #(pedCoords - bCoords) <= 35.0 then
                TriggerEvent('Notify', 'sucesso', 'Piloto automático chegou ao destino')
                stopAutoPilot()
            end
        end
    end)

    return true
end

function stopAutoPilot()
    if not inAutoPilot then return false end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh and veh ~= 0 then
            ClearPedTasks(ped)
            SetVehicleHandbrake(veh, true)
			Wait(1000)
            SetVehicleHandbrake(veh, false)
        end
    end

    inAutoPilot = false
    return true
end

local allowedVehicles = {
	[GetHashKey('xplaid24c')] = true,
	[GetHashKey('cybciv')] = true,
}

ClientAudit.RegisterCommand('pilotoautomatico', function()
	local ped = PlayerPedId()
	local vehicle = GetVehiclePedIsIn(ped, false)
	if not vehicle or vehicle == 0 then
		return
	end

    if not vSERVER.checkAutoPilotPermission() then
        TriggerEvent('Notify', 'aviso', 'Você não tem permissão para usar o piloto automático')
        return
    end

    if inAutoPilot then
        if stopAutoPilot() then
            TriggerEvent('Notify', 'sucesso', 'Piloto automático desativado com sucesso')
        end
    else
        if startAutoPilot() then
            TriggerEvent('Notify', 'sucesso', 'Piloto automático ativado com sucesso')
        end
    end
end)

local rgbAtivo = false

ClientAudit.RegisterCommand('rgb', function(source, args, rawCommand)
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)

    if vehicle == 0 then
        return
    end

    if not vSERVER.checkRGBPermission() then
        return
    end

    rgbAtivo = not rgbAtivo

    if rgbAtivo then
        TriggerEvent('Notify', 'sucesso', 'RGB ativado!')

        CreateThread(function()
            local hue = 0 

            while rgbAtivo do
                if GetVehiclePedIsIn(player, false) ~= vehicle then
                    rgbAtivo = false
                    break
                end

                local r, g, b = HSVtoRGB(hue, 1, 1)
                
                SetVehicleCustomPrimaryColour(vehicle, r, g, b)
                SetVehicleCustomSecondaryColour(vehicle, r, g, b)

                hue = (hue + 1) % 360 

                Wait(20)
            end
        end)
    else
        TriggerEvent('Notify', 'aviso', 'RGB desativado!')
    end
end)

function HSVtoRGB(h, s, v)
    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c
    local r, g, b = 0, 0, 0

    if h < 60 then
        r, g, b = c, x, 0
    elseif h < 120 then
        r, g, b = x, c, 0
    elseif h < 180 then
        r, g, b = 0, c, x
    elseif h < 240 then
        r, g, b = 0, x, c
    elseif h < 300 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end

    return math.floor((r + m) * 255), math.floor((g + m) * 255), math.floor((b + m) * 255)
end

RegisterNetEvent('activateNitro')
AddEventHandler('activateNitro', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        local boostDuration = 15000
        local startTime = GetGameTimer()
        CreateThread(function()
			TriggerEvent('Notify', 'sucesso', 'Nitro ativado!')
            while (GetGameTimer() - startTime) < boostDuration do
                Wait(0)
                local forwardVector = GetEntityForwardVector(veh)
                local boostForce = 1.0
                ApplyForceToEntity(
                    veh,
                    15, 
                    forwardVector.x * boostForce, 
                    forwardVector.y * boostForce, 
                    forwardVector.z * boostForce, 
                    0.0, 0.0, 0.0,
                    true, false, true, false, true
                )
            end
			TriggerEvent('Notify', 'aviso', 'Nitro desativado!')
        end)
    end
end)

RegisterNetEvent("vehash")
AddEventHandler("vehash",function()
	local vehicle = vRP.getNearestVehicle(7)
    if IsEntityAVehicle(vehicle) then
        vRP.prompt(source,""..GetEntityModel(vehicle),GetEntityModel(vehicle))
	end
end)

RegisterNetEvent("vehtuning")
AddEventHandler("vehtuning",function()
	local ped = PlayerPedId()
	local vehicle = GetVehiclePedIsIn(ped)
	if IsEntityAVehicle(vehicle) then
		SetVehicleModKit(vehicle,0)
		SetVehicleWheelType(vehicle,7)
		SetVehicleMod(vehicle,0,GetNumVehicleMods(vehicle,0)-1,false)
		SetVehicleMod(vehicle,1,GetNumVehicleMods(vehicle,1)-1,false)
		SetVehicleMod(vehicle,2,GetNumVehicleMods(vehicle,2)-1,false)
		SetVehicleMod(vehicle,3,GetNumVehicleMods(vehicle,3)-1,false)
		SetVehicleMod(vehicle,4,GetNumVehicleMods(vehicle,4)-1,false)
		SetVehicleMod(vehicle,5,GetNumVehicleMods(vehicle,5)-1,false)
		SetVehicleMod(vehicle,6,GetNumVehicleMods(vehicle,6)-1,false)
		SetVehicleMod(vehicle,7,GetNumVehicleMods(vehicle,7)-1,false)
		SetVehicleMod(vehicle,8,GetNumVehicleMods(vehicle,8)-1,false)
		SetVehicleMod(vehicle,9,GetNumVehicleMods(vehicle,9)-1,false)
		SetVehicleMod(vehicle,10,GetNumVehicleMods(vehicle,10)-1,false)
		SetVehicleMod(vehicle,11,GetNumVehicleMods(vehicle,11)-1,false)
		SetVehicleMod(vehicle,12,GetNumVehicleMods(vehicle,12)-1,false)
		SetVehicleMod(vehicle,13,GetNumVehicleMods(vehicle,13)-1,false)
		SetVehicleMod(vehicle,14,16,false)
		SetVehicleMod(vehicle,15,GetNumVehicleMods(vehicle,15)-2,false)
		SetVehicleMod(vehicle,16,GetNumVehicleMods(vehicle,16)-1,false)
		ToggleVehicleMod(vehicle,17,true)
		ToggleVehicleMod(vehicle,18,true)
		ToggleVehicleMod(vehicle,19,true)
		ToggleVehicleMod(vehicle,20,true)
		ToggleVehicleMod(vehicle,21,true)
		ToggleVehicleMod(vehicle,22,true)
		SetVehicleMod(vehicle,23,1,false)
		SetVehicleMod(vehicle,24,1,false)
		SetVehicleMod(vehicle,25,GetNumVehicleMods(vehicle,25)-1,false)
		SetVehicleMod(vehicle,27,GetNumVehicleMods(vehicle,27)-1,false)
		SetVehicleMod(vehicle,28,GetNumVehicleMods(vehicle,28)-1,false)
		SetVehicleMod(vehicle,30,GetNumVehicleMods(vehicle,30)-1,false)
		SetVehicleMod(vehicle,33,GetNumVehicleMods(vehicle,33)-1,false)
		SetVehicleMod(vehicle,34,GetNumVehicleMods(vehicle,34)-1,false)
		SetVehicleMod(vehicle,35,GetNumVehicleMods(vehicle,35)-1,false)
		SetVehicleMod(vehicle,38,GetNumVehicleMods(vehicle,38)-1,true)
		SetVehicleTyreSmokeColor(vehicle,0,0,0)
        SetVehicleWindowTint(vehicle,1)
        SetVehicleTyresCanBurst(vehicle,false)
        -- SetVehicleNumberPlateText(vehicle,"STAFF")
        SetVehicleNumberPlateTextIndex(vehicle,5)
        SetVehicleModColor_1(vehicle,0,0,0)
        SetVehicleModColor_2(vehicle,0,0)
        SetVehicleColours(vehicle,0,0)
        SetVehicleExtraColours(vehicle,0,0)
        SetVehicleNeonLightEnabled(vehicle,0,true)
        SetVehicleNeonLightEnabled(vehicle,1,true)
        SetVehicleNeonLightEnabled(vehicle,2,true)
        SetVehicleNeonLightEnabled(vehicle,3,true)
        SetVehicleNeonLightsColour(vehicle,0,0,0)
	end
end)
