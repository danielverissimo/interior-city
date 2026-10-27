
RegisterNetEvent("m_roubos:syncConfig",function(data)
    if type(data)~="table" then return end
    Config.roubos=data.locations or {}
    Config.setup=data.setups or {}
    Config.webhooks=data.webhooks or {}
    Config.settings=data.settings or {}
end)

CreateThread(function()
    Wait(500)
    TriggerServerEvent("m_roubos:requestConfig")
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
sRP = {}
Tunnel.bindInterface("m_roubos",sRP)
vSERVER = Tunnel.getInterface("m_roubos")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local andamento = false
local segundos = 0
local robberyCoords = nil
local originalBag = nil
-----------------------------------------------------------------------------------------------------------------------------------------
-- CÓDIGO
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
		local oInfinity = 1000
		local ped = PlayerPedId()
		local coords = GetEntityCoords(ped)
		for k,v in pairs(Config.roubos) do
			local distance = #(coords - vector3(v.x,v.y,v.z))
			if distance <= 5 and not andamento then
				oInfinity = 4
				if distance <= 1.2 then
					drawTxt("PRESSIONE  ~b~G~w~  PARA INICIAR O ROUBO",4,0.5,0.93,0.50,255,255,255,180)
					if IsControlJustPressed(0,47) and not IsPedInAnyVehicle(ped) then
						if GetEntityModel(ped) == GetHashKey("mp_m_freemode_01") or GetEntityModel(ped) == GetHashKey("mp_f_freemode_01") then
							vSERVER.startRobbery(v.type, v.id)
						end
					end
				end
			end
		end
		Citizen.Wait(oInfinity)
	end
end)


local function restoreRobberyVisuals()
	local ped = PlayerPedId()
	ClearPedTasks(ped)
	if originalBag then
		SetPedComponentVariation(ped,5,originalBag.drawable,originalBag.texture,originalBag.palette)
		originalBag = nil
	end
	robberyCoords = nil
	TriggerEvent('cancelando',false)
end

local function stopRobberyLocal(callServer)
	if not andamento then return end
	andamento = false
	segundos = 0
	if callServer then vSERVER.cancelRobbery() end
	restoreRobberyVisuals()
end

Citizen.CreateThread(function()
	while true do
		local oInfinity = 500
		local ped = PlayerPedId()
		if andamento then
			oInfinity = 4
			if not IsPedInAnyVehicle(ped) then
				drawTxt("APERTE ~b~M~w~ PARA CANCELAR O ROUBO EM ANDAMENTO",4,0.5,0.91,0.36,255,255,255,30)
				drawTxt("RESTAM ~b~"..segundos.." SEGUNDOS ~w~PARA TERMINAR",4,0.5,0.93,0.50,255,255,255,180)
			end

			local shouldCancel = IsControlJustPressed(0,244) or GetEntityHealth(ped) <= 100 or IsPedInAnyVehicle(ped)
			if robberyCoords then
				local coords = GetEntityCoords(ped)
				if #(coords - robberyCoords) > 8.0 then shouldCancel = true end
			end

			if shouldCancel then stopRobberyLocal(true) end
		end
		Citizen.Wait(oInfinity)
	end
end)


function sRP.iniciandoRoubo(x,y,z,secs,head)
	local ped = PlayerPedId()
	segundos = tonumber(secs) or 0
	andamento = true
	robberyCoords = vector3(x + 0.0,y + 0.0,z + 0.0)
	originalBag = {
		drawable = GetPedDrawableVariation(ped,5),
		texture = GetPedTextureVariation(ped,5),
		palette = GetPedPaletteVariation(ped,5)
	}
	SetEntityHeading(ped,head + 0.0)
	SetEntityCoords(ped,x,y,z-1,false,false,false,false)
	SetPedComponentVariation(ped,5,45,0,2)
	SetCurrentPedWeapon(ped,GetHashKey("WEAPON_UNARMED"),true)
	TriggerEvent('cancelando',true)
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1000)
		if andamento then
			segundos = segundos - 1
			if segundos <= 0 then
				andamento = false
				segundos = 0
				vSERVER.givePayment()
				restoreRobberyVisuals()
			end
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



RegisterNetEvent("m_roubos:forceStop",function(message)
	if andamento then
		andamento = false
		segundos = 0
		restoreRobberyVisuals()
	end
	if message and message ~= "" then
		TriggerEvent("Notify","importante",message)
	end
end)

AddEventHandler("onResourceStop",function(resource)
	if resource == GetCurrentResourceName() and andamento then
		andamento = false
		restoreRobberyVisuals()
	end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- MARCAÇÃO
-----------------------------------------------------------------------------------------------------------------------------------------
local blip = nil
RegisterNetEvent('blip:criar:roubo')
AddEventHandler('blip:criar:roubo',function(x,y,z)
	if not DoesBlipExist(blip) then
		blip = AddBlipForCoord(x,y,z)
		SetBlipScale(blip,0.5)
		SetBlipSprite(blip,1)
		SetBlipColour(blip,59)
		BeginTextCommandSetBlipName("STRING")
		SetBlipAsShortRange(blip,false)
		SetBlipRoute(blip,true)
	end
end)

RegisterNetEvent('blip:remover:roubo')
AddEventHandler('blip:remover:roubo',function()
	if DoesBlipExist(blip) then
		RemoveBlip(blip)
		blip = nil
	end
end)