local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPserver = Tunnel.getInterface("vRP","vrp_player")

src = {}
Tunnel.bindInterface("vrp_player",src)
vSERVER = Tunnel.getInterface("vrp_player")
local user_id = nil
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DISCORD API
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
        local players,id = vSERVER.CheckPlayers()
        SetDiscordAppId(1457016081515413729)
        SetDiscordRichPresenceAssetText('TocaDoMago DELUX')
		SetDiscordRichPresenceAsset("logo")
		SetDiscordRichPresenceAssetSmall('logo')
		SetDiscordRichPresenceAssetSmallText('O Servidor mais otimizado do BRASIL')
        SetRichPresence("Jogadores Conectados: "..players)
        SetDiscordRichPresenceAction(0, "JOGAR", "https://discord.gg/DQswMRDMVV")
        SetDiscordRichPresenceAction(1, "DISCORD", "https://discord.gg/DQswMRDMVV")
        Citizen.Wait(60000)
	end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- DESABILITAR X NA MOTO
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        local timeDistance = 3000
        local ped = PlayerPedId()
		if IsPedInAnyVehicle(ped) then
            local vehicle = GetVehiclePedIsIn(ped)
			if (GetPedInVehicleSeat(vehicle, -1) == ped or GetPedInVehicleSeat(vehicle, 0) == ped) and GetVehicleClass(vehicle) == 8 then
				timeDistance = 4
                DisableControlAction(0, 345, true)
            end
		end
		Citizen.Wait(timeDistance)
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- DESABILITAR CAPACETE AUTOMATICO
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        local timeDistance = 3000
        local ped = PlayerPedId()
		if IsPedInAnyVehicle(ped) then
            local vehicle = GetVehiclePedIsIn(ped)
			if (GetPedInVehicleSeat(vehicle, -1) == ped or GetPedInVehicleSeat(vehicle, 0) == ped) and GetVehicleClass(vehicle) == 8 then
				timeDistance = 4
                SetPedConfigFlag(PlayerPedId(), 35, false)
            end
		end
		Citizen.Wait(timeDistance)
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
--[ DESABILITAR A CORONHADA ]------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------

Citizen.CreateThread(function()
    while true do
       	local idle = 1000
        local ped = PlayerPedId()
		if IsPedArmed(ped,6) then
			idle = 5
            DisableControlAction(0,140,true)
            DisableControlAction(0,141,true)
            DisableControlAction(0,142,true)
		end
		Citizen.Wait(idle)
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
--[ CAR DRIFT  ]------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(PlayerPedId())
        if IsPedInAnyVehicle(ped) then
            local speed = GetEntitySpeed(vehicle)*2.236936
            if GetPedInVehicleSeat(vehicle,-1) == ped 
                and (GetEntityModel(vehicle) ~= GetHashKey("coach") 
                    and GetEntityModel(vehicle) ~= GetHashKey("bus") 
                    and GetEntityModel(vehicle) ~= GetHashKey("youga2") 
                    and GetEntityModel(vehicle) ~= GetHashKey("ratloader") 
                    and GetEntityModel(vehicle) ~= GetHashKey("taxi") 
                    and GetEntityModel(vehicle) ~= GetHashKey("boxville4") 
                    and GetEntityModel(vehicle) ~= GetHashKey("trash2") 
                    and GetEntityModel(vehicle) ~= GetHashKey("tiptruck") 
                    and GetEntityModel(vehicle) ~= GetHashKey("rebel") 
                    and GetEntityModel(vehicle) ~= GetHashKey("speedo") 
                    and GetEntityModel(vehicle) ~= GetHashKey("phantom") 
                    and GetEntityModel(vehicle) ~= GetHashKey("packer") 
                    and GetEntityModel(vehicle) ~= GetHashKey("paramedicoambu")) then
                    if speed <= 100.0 then
                    if IsControlPressed(1,21) then
                        SetVehicleReduceGrip(vehicle,true)
                    else
                        SetVehicleReduceGrip(vehicle,false)
                    end
                end    
            end
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
--[ DISABLE AFK CAMERA  ]------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------

Citizen.CreateThread(function()
    while true do 
        Citizen.Wait(100)
        DisableIdleCamera(true)
    end
end) 

-----------------------------------------------------------------------------------------------------------------------------------------
-- FIX TRUNKIN
-----------------------------------------------------------------------------------------------------------------------------------------
local isInTrunkIn = false

src.updateTrunkIn = function(vehicle, status)
	if status then
		isInTrunkIn = status
		isTrunkVehID = vehicle
	else
		isTrunkVehID = nil
		isInTrunkIn = false
	end

	CreateThread(function()
		while isInTrunkIn do
			if isTrunkVehID ~= nil then
				if not IsEntityAVehicle(isTrunkVehID) then
					isTrunkVehID = nil
					isInTrunkIn = false
					DetachEntity(PlayerPedId(), true, true)
					SetEntityVisible(PlayerPedId(), true)
					SetEntityInvincible(PlayerPedId(), false)
					vRP.setMalas(false)
				end
			end
			Wait(300)
		end
	end)
end
-- soco

-- Citizen.CreateThread(function()
--     while true do
--         Citizen.Wait(0)
--         local ped = PlayerPedId()

--         -- Se o jogador estiver desarmado e em combate corpo a corpo
--         if IsPedInMeleeCombat(ped) and GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_UNARMED") then
--             for _, player in ipairs(GetActivePlayers()) do
--                 if player ~= PlayerId() then
--                     local targetPed = GetPlayerPed(player)
--                     local distance = #(GetEntityCoords(ped) - GetEntityCoords(targetPed))

--                     -- Se o alvo estiver perto e dentro do ângulo do soco
--                     if distance < 2.0 and IsPedFacingPed(ped, targetPed, 60.0) then
--                         TriggerServerEvent("melee:hitPlayer", GetPlayerServerId(player))
--                         Citizen.Wait(600) -- cooldown
--                     end
--                 end
--             end
--         end
--     end
-- end)

-- -- Recebe o dano e animações
-- RegisterNetEvent("melee:applyDamage")
-- AddEventHandler("melee:applyDamage", function(damage, attackerId)
--     local ped = PlayerPedId()
--     local attackerPed = GetPlayerPed(GetPlayerFromServerId(attackerId))

--     -- Aplica dano real
--     -- ApplyDamageToPed(ped, damage, false)

--     -- Efeito de câmera
--     -- ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.1)

--     -- Animação de impacto na vítima
--     RequestAnimDict("melee@unarmed@streamed_core")
--     while not HasAnimDictLoaded("melee@unarmed@streamed_core") do
--         Citizen.Wait(0)
--     end
--     TaskPlayAnim(ped, "melee@unarmed@streamed_core", "victim_impact", 2.0, -2.0, 500, 0, 0, false, false, false)

--     -- Animação de soco para o atacante
--     if attackerPed and attackerPed ~= -1 then
--         RequestAnimDict("melee@unarmed@streamed_core")
--         while not HasAnimDictLoaded("melee@unarmed@streamed_core") do
--             Citizen.Wait(0)
--         end
--         TaskPlayAnim(attackerPed, "melee@unarmed@streamed_core", "light_right", 2.0, -2.0, 500, 0, 0, false, false, false)
--     end
-- end)


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONTADOR DE SALARIO
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	local SLEEP = 300*1000
	while true do
		vSERVER.rCountSalario()
		Citizen.Wait(SLEEP)
	end
end)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EMPURRAR E CAIR
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        local time = 500
        
        if IsPedJumping(PlayerPedId()) then
            time = 5
            if IsControlJustReleased(0, 51) then
                if not IsPedInAnyVehicle(PlayerPedId()) then
                    local ForwardVector = GetEntityForwardVector(PlayerPedId())
                    local Tackled = {}
                    
                    local playerHealth = GetEntityHealth(PlayerPedId())
                    if playerHealth <= 0 then
                        Citizen.Wait(1000)  -- Aguardar um pouco para evitar mortes múltiplas
                    else
                        ApplyDamageToPed(PlayerPedId(), 10, false)  
                        TriggerEvent("ragdoll:ChangeStatus", true)
                        
                        SetPedToRagdollWithFall(PlayerPedId(), 1500, 2000, 0, ForwardVector, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
                        
                        while IsPedRagdoll(PlayerPedId()) do
                            Citizen.Wait(1)
                            for Key, Value in ipairs(GetTouchedPlayers()) do
                                if not Tackled[Value] then
                                    Tackled[Value] = true
                                    vSERVER.TackleServerPlayer(GetPlayerServerId(Value), ForwardVector.x, ForwardVector.y, ForwardVector.z, GetPlayerName(PlayerId()))
                                end
                            end
                        end
                        
                        TriggerEvent("ragdoll:ChangeStatus", false)
                    end
                end
            end
        end
        
        Citizen.Wait(time)
    end
end)

function src.TackleClientPlayer(ForwardVectorX,ForwardVectorY,ForwardVectorZ,Tackler)
	print("Você foi derrubado pelo script Tackle.")
	TriggerEvent("ragdoll:ChangeStatus", true)
    SetPedToRagdollWithFall(PlayerPedId(),1500,1500,0,ForwardVectorX,ForwardVectorY,ForwardVectorZ,10.0,0.0,0.0,0.0,0.0,0.0,0.0)
	Wait(6000)
	TriggerEvent("ragdoll:ChangeStatus", false)
end

function GetPlayers()
    local Players = {}
    for i = 0,256 do
        if NetworkIsPlayerActive(i) then
            table.insert(Players,i)
        end
    end
    return Players
end

function GetTouchedPlayers()
    local TouchedPlayer = {}
    for Key,Value in ipairs(GetPlayers()) do
		if IsEntityTouchingEntity(PlayerPedId(),GetPlayerPed(Value)) then
			table.insert(TouchedPlayer,Value)
		end
    end
    return TouchedPlayer
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TROCAR DE BANCO
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function src.seatPlayer(index)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(ped)

    if IsEntityAVehicle(vehicle) and IsPedInAnyVehicle(ped) then
        if parseInt(index) <= 1 or index == nil then
            seat = -1
        elseif parseInt(index) == 2 then
            seat = 0
        elseif parseInt(index) == 3 then
            seat = 1
        elseif parseInt(index) == 4 then
            seat = 2
        elseif parseInt(index) == 5 then
            seat = 3
        elseif parseInt(index) == 6 then
            seat = 4
        elseif parseInt(index) == 7 then
            seat = 5
        elseif parseInt(index) >= 8 then
            seat = 6
        end

        if IsVehicleSeatFree(vehicle,seat) then
            SetPedIntoVehicle(ped,vehicle,seat)
        end
    end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- [ ATTACHS ]---------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("attachs",function(source,args)
	local ped = PlayerPedId()
    if vSERVER.checkAttachs() then
        if GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_COMBATPISTOL") then
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_COMBATPISTOL"),GetHashKey("COMPONENT_AT_PI_FLSH"))
        elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_SMG") then
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SMG"),GetHashKey("COMPONENT_AT_AR_FLSH"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SMG"),GetHashKey("COMPONENT_AT_SCOPE_MACRO_02"))
        elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_COMBATPDW") then
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_COMBATPDW"),GetHashKey("COMPONENT_AT_AR_FLSH"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_COMBATPDW"),GetHashKey("COMPONENT_AT_SCOPE_SMALL"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_COMBATPDW"),GetHashKey("COMPONENT_AT_AR_AFGRIP"))
        elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_PUMPSHOTGUN_MK2") then
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_PUMPSHOTGUN_MK2"),GetHashKey("COMPONENT_AT_SIGHTS"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_PUMPSHOTGUN_MK2"),GetHashKey("COMPONENT_AT_SCOPE_SMALL_MK2"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_PUMPSHOTGUN_MK2"),GetHashKey("COMPONENT_AT_AR_FLSH"))
        elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_CARBINERIFLE") then
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE"),GetHashKey("COMPONENT_AT_AR_FLSH"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE"),GetHashKey("COMPONENT_AT_AR_AFGRIP"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE"),GetHashKey("COMPONENT_AT_SCOPE_MEDIUM"))
        elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_MICROSMG") then
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_MICROSMG"),GetHashKey("COMPONENT_AT_PI_FLSH"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_MICROSMG"),GetHashKey("COMPONENT_AT_SCOPE_MACRO"))
        elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_ASSAULTRIFLE") then
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTRIFLE"),GetHashKey("COMPONENT_AT_AR_FLSH"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTRIFLE"),GetHashKey("COMPONENT_AT_SCOPE_MACRO"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTRIFLE"),GetHashKey("COMPONENT_AT_AR_AFGRIP"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTRIFLE"),GetHashKey("COMPONENT_ASSAULTRIFLE_VARMOD_LUXE"))
        elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_PISTOL_MK2") then
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_PISTOL_MK2"),GetHashKey("COMPONENT_AT_PI_RAIL"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_PISTOL_MK2"),GetHashKey("COMPONENT_AT_PI_FLSH_02"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_PISTOL_MK2"),GetHashKey("COMPONENT_AT_PI_COMP"))
        elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_REVOLVER_MK2") then
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_REVOLVER_MK2"),GetHashKey("COMPONENT_AT_PI_FLSH"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_REVOLVER_MK2"),GetHashKey("COMPONENT_AT_SIGHTS"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_REVOLVER_MK2"),GetHashKey("COMPONENT_REVOLVER_MK2_CAMO_IND_01"))	
        elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_ASSAULTSMG") then
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTSMG"),GetHashKey("COMPONENT_AT_AR_FLSH"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTSMG"),GetHashKey("COMPONENT_AT_SCOPE_MACRO"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTSMG"),GetHashKey("COMPONENT_ASSAULTSMG_VARMOD_LOWRIDER"))
        elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_PISTOL") then
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_PISTOL"),GetHashKey("COMPONENT_AT_PI_FLSH"))
        elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_CARBINERIFLE_MK2") then
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE_MK2"),GetHashKey("COMPONENT_SPECIALCARBINE_MK2_CLIP_02"))	
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE_MK2"),GetHashKey("COMPONENT_AT_MUZZLE_06"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE_MK2"),GetHashKey("COMPONENT_AT_SIGHTS"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE_MK2"),GetHashKey("COMPONENT_AT_SCOPE_MEDIUM_MK2"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE_MK2"),GetHashKey("COMPONENT_AT_AR_FLSH"))
            
        elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_SPECIALCARBINE") then
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SPECIALCARBINE"),GetHashKey("COMPONENT_AT_AR_FLSH"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SPECIALCARBINE"),GetHashKey("COMPONENT_AT_SCOPE_MEDIUM"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SPECIALCARBINE"),GetHashKey("COMPONENT_AT_AR_AFGRIP"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SPECIALCARBINE"),GetHashKey("COMPONENT_SPECIALCARBINE_CLIP_01"))
        elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_CARBINERIFLE_MK2") then
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE_MK2"),GetHashKey("COMPONENT_AT_SIGHTS"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE_MK2"),GetHashKey("COMPONENT_AT_MUZZLE_04"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE_MK2"),GetHashKey("COMPONENT_AT_AR_AFGRIP_02"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE_MK2"),GetHashKey("COMPONENT_AT_AR_FLSH"))
        elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_ASSAULTRIFLE_MK2") then
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTRIFLE_MK2"),GetHashKey("COMPONENT_AT_AR_FLSH"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTRIFLE_MK2"),GetHashKey("COMPONENT_AT_SCOPE_MEDIUM_MK2"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTRIFLE_MK2"),GetHashKey("COMPONENT_AT_AR_AFGRIP_02"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTRIFLE_MK2"),GetHashKey("COMPONENT_AT_MUZZLE_01"))
        elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_BULLPUPRIFLE_MK2") then
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_BULLPUPRIFLE_MK2"),GetHashKey("COMPONENT_BULLPUPRIFLE_MK2_CLIP_01"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_BULLPUPRIFLE_MK2"),GetHashKey("COMPONENT_AT_AR_FLSH"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_BULLPUPRIFLE_MK2"),GetHashKey("COMPONENT_AT_SIGHTS"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_BULLPUPRIFLE_MK2"),GetHashKey("COMPONENT_AT_MUZZLE_04"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_BULLPUPRIFLE_MK2"),GetHashKey("COMPONENT_AT_BP_BARREL_01"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_BULLPUPRIFLE_MK2"),GetHashKey("COMPONENT_AT_AR_AFGRIP_02"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_BULLPUPRIFLE_MK2"),GetHashKey("COMPONENT_BULLPUPRIFLE_MK2_CAMO_09"))
        elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_SPECIALCARBINE_MK2") then	
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SPECIALCARBINE_MK2"),GetHashKey("COMPONENT_AT_AR_FLSH"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SPECIALCARBINE_MK2"),GetHashKey("COMPONENT_AT_AR_AFGRIP_02"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SPECIALCARBINE_MK2"),GetHashKey("COMPONENT_AT_SCOPE_MEDIUM_MK2"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SPECIALCARBINE_MK2"),GetHashKey("COMPONENT_SPECIALCARBINE_MK2_CLIP_01"))
            GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SPECIALCARBINE_MK2"),GetHashKey("COMPONENT_AT_MUZZLE_04"))
		elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_GRAJADA") then
			GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_GRAJADA"),GetHashKey("GLOCKRAJADA_CARREGADOR_3"))
		elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_BARRET") then
			GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_BARRET"),GetHashKey("COMPONENT_BARRET_CARREGADOR"))
			GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_BARRET"),GetHashKey("COMPONENT_BARRET_LUNETA"))
		elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_AKDEFERRO_RELIKIASHOP") then
			GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_AKDEFERRO_RELIKIASHOP"),GetHashKey("TAMBOR_AKDERERRO_RELIKIASHOP"))
		elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_AR10PRETO_RELIKIASHOP") then
			GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_AR10PRETO_RELIKIASHOP"),GetHashKey("PENTEAR10_EXTENDIDO"))
		elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_AR15BEGE_RELIKIASHOP") then
			GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_AR15BEGE_RELIKIASHOP"),GetHashKey("TAMBOR_AR15BEGE"))
		elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_ARPENTEACRILICO_RELIKIASHOP") then
			GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ARPENTEACRILICO_RELIKIASHOP"),GetHashKey("TABORAR_RELIKIASHOP"))
		elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_ARDELUNETA_RELIKIASHOP") then
			GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ARDELUNETA_RELIKIASHOP"),GetHashKey("COMPONENT_AT_SCOPE1_LARGE"))
			GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ARDELUNETA_RELIKIASHOP"),GetHashKey("COMPONENT_AT_AR_SUPP1_02"))
			GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ARDELUNETA_RELIKIASHOP"),GetHashKey("COMPONENT_HEAVYSNIPER1_CLIP_01"))
		elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_HKG3A3") then
			GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_HKG3A3"),GetHashKey("COMPONENT_AT_AR_FLSH"))
			GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_HKG3A3"),GetHashKey("COMPONENT_AT_AR_VGRIP"))
			GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_HKG3A3"),GetHashKey("COMPONENT_AT_AR_M203"))
			GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_HKG3A3"),GetHashKey("COMPONENT_G3A3_CLIP_02"))
			GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_HKG3A3"),GetHashKey("COMPONENT_AT_SCOPE_AOG"))
			GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_HKG3A3"),GetHashKey("COMPONENT_AT_CR_BARREL_02"))
		elseif GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_HK_RELIKIASHOP") then
			GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_HK_RELIKIASHOP"),GetHashKey("PENTE_EXTENDIDOHK"))
        end
    end
end)


RegisterNetEvent('Weapon:Attachs')
AddEventHandler('Weapon:Attachs', function() 
	local ped = PlayerPedId()
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_COMBATPISTOL"),GetHashKey("COMPONENT_AT_PI_FLSH"))

	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SMG"),GetHashKey("COMPONENT_AT_AR_FLSH"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SMG"),GetHashKey("COMPONENT_AT_SCOPE_MACRO_02"))


	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_COMBATPDW"),GetHashKey("COMPONENT_AT_AR_FLSH"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_COMBATPDW"),GetHashKey("COMPONENT_AT_SCOPE_SMALL"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_COMBATPDW"),GetHashKey("COMPONENT_AT_AR_AFGRIP"))

	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_PUMPSHOTGUN_MK2"),GetHashKey("COMPONENT_AT_SIGHTS"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_PUMPSHOTGUN_MK2"),GetHashKey("COMPONENT_AT_SCOPE_SMALL_MK2"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_PUMPSHOTGUN_MK2"),GetHashKey("COMPONENT_AT_AR_FLSH"))

	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE"),GetHashKey("COMPONENT_AT_AR_FLSH"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE"),GetHashKey("COMPONENT_AT_AR_AFGRIP"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE"),GetHashKey("COMPONENT_AT_SCOPE_MEDIUM"))

	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_MICROSMG"),GetHashKey("COMPONENT_AT_PI_FLSH"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_MICROSMG"),GetHashKey("COMPONENT_AT_SCOPE_MACRO"))

	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTRIFLE"),GetHashKey("COMPONENT_AT_AR_FLSH"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTRIFLE"),GetHashKey("COMPONENT_AT_SCOPE_MACRO"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTRIFLE"),GetHashKey("COMPONENT_AT_AR_AFGRIP"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTRIFLE"),GetHashKey("COMPONENT_ASSAULTRIFLE_VARMOD_LUXE"))

	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_PISTOL_MK2"),GetHashKey("COMPONENT_AT_PI_RAIL"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_PISTOL_MK2"),GetHashKey("COMPONENT_AT_PI_FLSH_02"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_PISTOL_MK2"),GetHashKey("COMPONENT_AT_PI_COMP"))

	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_REVOLVER_MK2"),GetHashKey("COMPONENT_AT_PI_FLSH"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_REVOLVER_MK2"),GetHashKey("COMPONENT_AT_SIGHTS"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_REVOLVER_MK2"),GetHashKey("COMPONENT_REVOLVER_MK2_CAMO_IND_01"))	

	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTSMG"),GetHashKey("COMPONENT_AT_AR_FLSH"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTSMG"),GetHashKey("COMPONENT_AT_SCOPE_MACRO"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTSMG"),GetHashKey("COMPONENT_ASSAULTSMG_VARMOD_LOWRIDER"))

	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_PISTOL"),GetHashKey("COMPONENT_AT_PI_FLSH"))

	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE_MK2"),GetHashKey("COMPONENT_SPECIALCARBINE_MK2_CLIP_02"))	
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE_MK2"),GetHashKey("COMPONENT_AT_MUZZLE_06"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE_MK2"),GetHashKey("COMPONENT_AT_SIGHTS"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE_MK2"),GetHashKey("COMPONENT_AT_SCOPE_MEDIUM_MK2"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE_MK2"),GetHashKey("COMPONENT_AT_AR_FLSH"))

	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SPECIALCARBINE"),GetHashKey("COMPONENT_AT_AR_FLSH"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SPECIALCARBINE"),GetHashKey("COMPONENT_AT_SCOPE_MEDIUM"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SPECIALCARBINE"),GetHashKey("COMPONENT_AT_AR_AFGRIP"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SPECIALCARBINE"),GetHashKey("COMPONENT_SPECIALCARBINE_CLIP_01"))

	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE_MK2"),GetHashKey("COMPONENT_AT_SIGHTS"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE_MK2"),GetHashKey("COMPONENT_AT_MUZZLE_04"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE_MK2"),GetHashKey("COMPONENT_AT_AR_AFGRIP_02"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_CARBINERIFLE_MK2"),GetHashKey("COMPONENT_AT_AR_FLSH"))

	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTRIFLE_MK2"),GetHashKey("COMPONENT_AT_AR_FLSH"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTRIFLE_MK2"),GetHashKey("COMPONENT_AT_SCOPE_MEDIUM_MK2"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTRIFLE_MK2"),GetHashKey("COMPONENT_AT_AR_AFGRIP_02"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_ASSAULTRIFLE_MK2"),GetHashKey("COMPONENT_AT_MUZZLE_01"))

	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_BULLPUPRIFLE_MK2"),GetHashKey("COMPONENT_BULLPUPRIFLE_MK2_CLIP_01"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_BULLPUPRIFLE_MK2"),GetHashKey("COMPONENT_AT_AR_FLSH"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_BULLPUPRIFLE_MK2"),GetHashKey("COMPONENT_AT_SIGHTS"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_BULLPUPRIFLE_MK2"),GetHashKey("COMPONENT_AT_MUZZLE_04"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_BULLPUPRIFLE_MK2"),GetHashKey("COMPONENT_AT_BP_BARREL_01"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_BULLPUPRIFLE_MK2"),GetHashKey("COMPONENT_AT_AR_AFGRIP_02"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_BULLPUPRIFLE_MK2"),GetHashKey("COMPONENT_BULLPUPRIFLE_MK2_CAMO_09"))

	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SPECIALCARBINE_MK2"),GetHashKey("COMPONENT_AT_AR_FLSH"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SPECIALCARBINE_MK2"),GetHashKey("COMPONENT_AT_AR_AFGRIP_02"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SPECIALCARBINE_MK2"),GetHashKey("COMPONENT_AT_SCOPE_MEDIUM_MK2"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SPECIALCARBINE_MK2"),GetHashKey("COMPONENT_SPECIALCARBINE_MK2_CLIP_01"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_SPECIALCARBINE_MK2"),GetHashKey("COMPONENT_AT_MUZZLE_04"))

	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_GRAJADA"),GetHashKey("GLOCKRAJADA_CARREGADOR_3"))

	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_BARRET"),GetHashKey("COMPONENT_BARRET_CARREGADOR"))
	GiveWeaponComponentToPed(ped,GetHashKey("WEAPON_BARRET"),GetHashKey("COMPONENT_BARRET_LUNETA"))

	TriggerEvent("Notify","sucesso","Você usou o item <b>ATTACHS</b> em todas suas armas equipadas.",5)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- [ COR ]---------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("cor",function(source,args)
    if vSERVER.checkAttachs() then
        local tinta = parseInt(args[1])
        if tinta >= 0 then
            SetPedWeaponTintIndex(PlayerPedId(),GetSelectedPedWeapon(PlayerPedId()),tinta)
        else
            TriggerEvent("Notify","negado","Você precisa especificar uma pintura válida.",5)
        end
    end
end)

RegisterNetEvent('changeWeaponColor')
AddEventHandler('changeWeaponColor', function(cor) 
    local tinta = tonumber(cor)
    local ped = PlayerPedId()
    local arma = GetSelectedPedWeapon(ped)
    if tinta >= 0 then
        SetPedWeaponTintIndex(ped,arma,tinta)
    end
 
end)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- /FPS
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("fps",function(source,args)
	print('fps args '..args[1])
    if args[1] == "on" then
        SetTimecycleModifier("cinema")
        TriggerEvent("Notify","sucesso","Boost de fps ligado!", 5)
    elseif args[1] == "off" then
        SetTimecycleModifier("default")
        TriggerEvent("Notify","sucesso","Boost de fps desligado!", 5)
    end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- /VTUNING
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("vtuning",function(source,args)
	local vehicle = vRP.getNearestVehicle(3)
	if IsEntityAVehicle(vehicle) then
		local motor = GetVehicleMod(vehicle,11)
		local freio = GetVehicleMod(vehicle,12)
		local transmissao = GetVehicleMod(vehicle,13)
		local suspensao = GetVehicleMod(vehicle,15)
		local blindagem = GetVehicleMod(vehicle,16)
		local body = GetVehicleBodyHealth(vehicle)
		local engine = GetVehicleEngineHealth(vehicle)
		local fuel = GetVehicleFuelLevel(vehicle)

		if motor == -1 then
			motor = "Desativado"
		elseif motor == 0 then
			motor = "Nível 1 / "..GetNumVehicleMods(vehicle,11)
		elseif motor == 1 then
			motor = "Nível 2 / "..GetNumVehicleMods(vehicle,11)
		elseif motor == 2 then
			motor = "Nível 3 / "..GetNumVehicleMods(vehicle,11)
		elseif motor == 3 then
			motor = "Nível 4 / "..GetNumVehicleMods(vehicle,11)
		elseif motor == 4 then
			motor = "Nível 5 / "..GetNumVehicleMods(vehicle,11)
		end

		if freio == -1 then
			freio = "Desativado"
		elseif freio == 0 then
			freio = "Nível 1 / "..GetNumVehicleMods(vehicle,12)
		elseif freio == 1 then
			freio = "Nível 2 / "..GetNumVehicleMods(vehicle,12)
		elseif freio == 2 then
			freio = "Nível 3 / "..GetNumVehicleMods(vehicle,12)
		end

		if transmissao == -1 then
			transmissao = "Desativado"
		elseif transmissao == 0 then
			transmissao = "Nível 1 / "..GetNumVehicleMods(vehicle,13)
		elseif transmissao == 1 then
			transmissao = "Nível 2 / "..GetNumVehicleMods(vehicle,13)
		elseif transmissao == 2 then
			transmissao = "Nível 3 / "..GetNumVehicleMods(vehicle,13)
		elseif transmissao == 3 then
			transmissao = "Nível 4 / "..GetNumVehicleMods(vehicle,13)
		end

		if suspensao == -1 then
			suspensao = "Desativado"
		elseif suspensao == 0 then
			suspensao = "Nível 1 / "..GetNumVehicleMods(vehicle,15)
		elseif suspensao == 1 then
			suspensao = "Nível 2 / "..GetNumVehicleMods(vehicle,15)
		elseif suspensao == 2 then
			suspensao = "Nível 3 / "..GetNumVehicleMods(vehicle,15)
		elseif suspensao == 3 then
			suspensao = "Nível 4 / "..GetNumVehicleMods(vehicle,15)
		end

		if blindagem == -1 then
			blindagem = "Desativado"
		elseif blindagem == 0 then
			blindagem = "Nível 1 / "..GetNumVehicleMods(vehicle,16)
		elseif blindagem == 1 then
			blindagem = "Nível 2 / "..GetNumVehicleMods(vehicle,16)
		elseif blindagem == 2 then
			blindagem = "Nível 3 / "..GetNumVehicleMods(vehicle,16)
		elseif blindagem == 3 then
			blindagem = "Nível 4 / "..GetNumVehicleMods(vehicle,16)
		elseif blindagem == 4 then
			blindagem = "Nível 5 / "..GetNumVehicleMods(vehicle,16)
		end

		TriggerEvent("Notify","importante","<b>Motor:</b> "..motor.."<br><b>Freio:</b> "..freio.."<br><b>Transmissão:</b> "..transmissao.."<br><b>Suspensão:</b> "..suspensao.."<br><b>Blindagem:</b> "..blindagem.."<br><b>Chassi:</b> "..parseInt(body/10).."%<br><b>Engine:</b> "..parseInt(engine/10).."%<br><b>Gasolina:</b> "..parseInt(fuel).."%", 15)
	end
end)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SISTEMA DE PUXAR A ARMA
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local data = {		
	["peds"] = {
	  ["mp_m_freemode_01"] = { ["components"] = { [7] = { [1] = 3, [6] = 5, [8] = 2, [42] = 43, [110] = 111, [119] = 120 }, [8] = { [16] = 18 } } },
	  ["mp_f_freemode_01"] = { ["components"] = { [7] = { [1] = 3, [6] = 5, [8] = 2, [29] = 30, [81] = 82 }, [8] = { [9] = 10 } } },
	}
}

local skins = {
	"mp_m_freemode_01",
	"mp_f_freemode_01",
}

local weapons = { 
	"WEAPON_SNSPISTOL_MK2",
	"WEAPON_PISTOL_MK2",
	"WEAPON_PISTOL",
	"WEAPON_HATCHET",
	"WEAPON_KNIFE",
	"WEAPON_FLARE",
	"WEAPON_POOLCUE",
	"WEAPON_BATTLEAXE",
	"WEAPON_BAT",
	"WEAPON_BOTTLE",
	"WEAPON_FLASHLIGHT",
	"WEAPON_CROWBAR",
	"WEAPON_GOLFCLUB",
	"WEAPON_DAGGER",
	"WEAPON_HAMMER",
	"WEAPON_WRENCH",
	"WEAPON_SWITCHBLADE",
	"WEAPON_KNUCKLE",
	"WEAPON_MILITARYRIFLE",
	
	"WEAPON_MACHINEPISTOL",
	"WEAPON_SMG_MK2",
	"WEAPON_SMG",
	"WEAPON_ASSAULTSMG",
	"WEAPON_SAWNOFFSHOTGUN",
	"AMMO_PUMPSHOTGUN_MK2",
	"WEAPON_ASSAULTRIFLE_MK2",
	"WEAPON_HEAVYSNIPER",
	"WEAPON_ASSAULTRIFLE",
	"WEAPON_SPECIALCARBINE_MK2",
	"WEAPON_AKPENTEDE90_RELIKIASHOP",
	"WEAPON_TEMPERED",
	"WEAPON_FNSCAR", 
	"WEAPON_AR15",
	"WEAPON_AR15BEGE_RELIKIASHOP",
	"WEAPON_ARPENTEACRILICO_RELIKIASHOP",
	"WEAPON_ARDELUNETA_RELIKIASHOP",
	"WEAPON_ARLUNETAPRATA",
	"WEAPON_AK472",
	"WEAPON_AR10PRETO_RELIKIASHOP",
	"WEAPON_ARTAMBOR",
	"WEAPON_G3LUNETA_RELIKIASHOP",
	"WEAPON_GLOCKDEROUPA_RELIKIASHOP",
	"WEAPON_HKG3A3",
	"WEAPON_HK_RELIKIASHOP",
	"WEAPON_PENTEDUPLO1",
	"WEAPON_50_RELIKIASHOP",
	"WEAPON_HEAVYSNIPER_MK2",
	"WEAPON_CARBINERIFLE",
	"WEAPON_CARBINERIFLE_MK2",
	"WEAPON_SPECIALCARBINE",
	"WEAPON_STUNGUN",
	"WEAPON_FIREWORK",
	"WEAPON_SNOWBALL",
	"WEAPON_BZGAS"
}

 
local default_weapon = GetHashKey(data.weapon)
local active = false
local ped = nil
local currentPedData = nil
local holstered = true
local in_arena = false

local weapon
local disabled

RegisterNetEvent("mirtin_survival:updateArena", function(boolean)
	in_arena = boolean
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(4)
		local ped = PlayerPedId()
		local sex = GetEntityModel(ped)
		if not in_arena and DoesEntityExist( ped ) and not IsEntityDead( ped ) and not IsPedInAnyVehicle(PlayerPedId(), true) and CheckSkin(ped) then
			loadAnimDict( "reaction@intimidation@1h" )
			loadAnimDict( "rcmjosh4" )
			loadAnimDict( "anim@weapons@pistol@doubleaction_holster" )
			local holster = GetPedDrawableVariation(GetPlayerPed(-1), 8)
			local holster2 = GetPedDrawableVariation(GetPlayerPed(-1), 7)
			if holster ~= 122 and holster ~= 130 and holster2 ~= 8 and holster2 ~= 1 and holster2 ~= 110 and sex == 1885233650 then
				if CheckWeapon(ped) then
					if holstered then
						disabled = true	
						SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
						TaskPlayAnim(ped, "reaction@intimidation@1h", "intro", 8.0, 2.0, -1, 48, 0, 0, 0, 0 )
						Citizen.Wait(1800)
						SetCurrentPedWeapon(ped, GetHashKey(weapon), true)
						StopAnimTask(ped, "reaction@intimidation@1h", "intro", 1.0)
						Citizen.Wait(1000)
						disabled = false
						holstered = false
					end
				elseif not CheckWeapon(ped) then
					if not holstered then
						SetCurrentPedWeapon(ped, GetHashKey(weapon), true)
						disabled = true			
						TaskPlayAnim(ped, "reaction@intimidation@1h", "outro", 8.0, 2.0, -1, 48, 10, 0, 0, 0 )		
						Citizen.Wait(1800)
						StopAnimTask(ped, "reaction@intimidation@1h", "outro", 1.0)
						SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
						disabled = false
						holstered = true
					end
				end
			elseif holster ~= 160 and holster ~= 152 and holster2 ~= 81 and holster2 ~= 8 and holster2 ~= 1 and sex == -1667301416 then
				if CheckWeapon(ped) then
					if holstered then
						disabled = true	
						SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
						TaskPlayAnim(ped, "reaction@intimidation@1h", "intro", 8.0, 2.0, -1, 48, 0, 0, 0, 0 )
						Citizen.Wait(1400)
						SetCurrentPedWeapon(ped, GetHashKey(weapon), true)
						StopAnimTask(ped, "reaction@intimidation@1h", "intro", 1.0)
						Citizen.Wait(1000)
						disabled = false
						holstered = false
					end
				elseif not CheckWeapon(ped) then
					if not holstered then
						SetCurrentPedWeapon(ped, GetHashKey(weapon), true)
						disabled = true
						TaskPlayAnim(ped, "reaction@intimidation@1h", "outro", 8.0, 2.0, -1, 48, 10, 0, 0, 0 )
						Citizen.Wait(1600)
						StopAnimTask(ped, "reaction@intimidation@1h", "intro", 1.0)
						SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
						disabled = false
						holstered = true
					end
				end
			elseif holster ~= 160 or holster == 152 or holster2 == 81 or holster2 == 8 or holster2 == 1 and sex == -1667301416 then
				if CheckWeapon(ped) then
					if holstered then
						disabled = true	
						TaskPlayAnim(ped, "rcmjosh4", "josh_leadout_cop2", 8.0, 2.0, -1, 48, 10, 0, 0, 0 )
						Citizen.Wait(800)
						StopAnimTask(ped, "rcmjosh4", "josh_leadout_cop2", 1.0)
						Citizen.Wait(100)
						disabled = false
						holstered = false
					end
				elseif not CheckWeapon(ped) then
					if not holstered then
						SetCurrentPedWeapon(ped, GetHashKey(weapon), true)
						disabled = true
						TaskPlayAnim(ped, "weapons@pistol@", "aim_2_holster", 8.0, 2.0, -1, 48, 10, 0, 0, 0 )
						Citizen.Wait(800)
						StopAnimTask(ped, "weapons@pistol@", "aim_2_holster", 1.0)
						SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
						disabled = false
						holstered = true
					end
				end			
			elseif holster == 160 or holster == 152 and sex == -1667301416 then
				if CheckWeapon(ped) then
					if holstered then
						disabled = true	
						TaskPlayAnim(ped, "rcmjosh4", "josh_leadout_cop2", 8.0, 2.0, -1, 48, 10, 0, 0, 0 )
						Citizen.Wait(800)
						StopAnimTask(ped, "rcmjosh4", "josh_leadout_cop2", 1.0)
						Citizen.Wait(100)
						disabled = false
						holstered = false
					end
				elseif not CheckWeapon(ped) then
					if not holstered then
						SetCurrentPedWeapon(ped, GetHashKey(weapon), true)
						disabled = true
						TaskPlayAnim(ped, "weapons@pistol@", "aim_2_holster", 8.0, 2.0, -1, 48, 10, 0, 0, 0 )
						Citizen.Wait(800)
						StopAnimTask(ped, "weapons@pistol@", "aim_2_holster", 1.0)
						SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
						disabled = false
						holstered = true
					end
				end			
			end
		end
	end
end)

function table_invert(t)
  local s={}
  for k,v in pairs(t) do
    s[v]=k
  end
  return s
end

function CheckSkin(ped)
	for i = 1, #skins do
		if GetHashKey(skins[i]) == GetEntityModel(ped) then
			return true
		end
	end
	return false
end

function CheckWeapon(ped)
	for i = 1, #weapons do
		if GetHashKey(weapons[i]) == GetSelectedPedWeapon(ped) then
			weapon = weapons[i]
			return true
		end
	end
	return false
end

function DisableActions(ped)
	DisableControlAction(1, 37, true)
	DisablePlayerFiring(ped, true)
end

function loadAnimDict( dict )
	while ( not HasAnimDictLoaded( dict ) ) do
		RequestAnimDict( dict )
		Citizen.Wait( 0 )
	end
end

Citizen.CreateThread(function()
  while true do
    ped = GetPlayerPed(-1)
    local ped_hash = GetEntityModel(ped)
    local enable = false 
    for ped, data in pairs(data.peds) do
      if GetHashKey(ped) == ped_hash then 
        enable = true
        if data.enabled ~= nil then
          enable = data.enabled
        end
        currentPedData = data
        break
      end
    end
    active = enable
    Citizen.Wait(5000)
  end
end)

local last_weapon = nil
Citizen.CreateThread(function()
  while true do
    if not in_arena and active then
      current_weapon = GetSelectedPedWeapon(ped)
      if current_weapon ~= last_weapon then
        
        for component, holsters in pairs(currentPedData.components) do
          local holsterDrawable = GetPedDrawableVariation(ped, component)
          local holsterTexture = GetPedTextureVariation(ped, component)

          local emptyHolster = holsters[holsterDrawable]
          if emptyHolster and current_weapon == default_weapon then
            SetPedComponentVariation(ped, component, emptyHolster, holsterTexture, 0)
            break
          end

          local filledHolster = table_invert(holsters)[holsterDrawable]
          if filledHolster and current_weapon ~= default_weapon and last_weapon == default_weapon then
            SetPedComponentVariation(ped, component, filledHolster, holsterTexture, 0)
            break
          end
        end
      end
      last_weapon = current_weapon
    end
    Citizen.Wait(1000)
  end
end)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FIX LIMBO
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local garagens = {
	{ 213.90,-809.08,31.01},
	{ 596.69,91.42,93.12},
	{ 275.41,-345.24,45.17},
	{ 56.08,-876.53,30.65},
	{ -348.95,-874.39,31.31},
	{ -340.64,266.31,85.67},
	{ -773.59,5597.57,33.60},
	{ 317.17,2622.99,44.45},
	{ 459.6,-986.55,25.7},
	{ -1184.93,-1509.98,4.64},
	{ -73.32,-2004.20,18.27}
}

Citizen.CreateThread(function()
	while true do
		local ped = PlayerPedId()
		local x,y,z = table.unpack(GetEntityCoords(ped))
		if z < -110 then
			if IsPedInAnyVehicle(ped) then
				vSERVER._deleteVeh(VehToNet(GetVehiclePedIsIn(ped)))
				teleportPlayerProxmityCoords(x,y,z)
				TriggerEvent('Notify', 'negado', 'Você caiu no limbo com seu veiculo e foi teleportado para a garagem mais proxima.', 5)
			end
		end

		Citizen.Wait(3000)
	end
end)

--NPC DAS LOJAS--
local pedlist = {
	-- { ['coords'] = vec4(-169.31,927.7,235.64,316.43), ['hash2'] = "s_m_y_swat_01"}, -- Pcc
	-- { ['coords'] = vec4(-3030.13,1626.99,31.14,118.11), ['hash2'] = "s_m_y_swat_01"}, -- Inglaterra
	-- { ['coords'] = vec4(-2981.23,65.25,11.61,327.01), ['hash2'] = "s_m_y_swat_01"}, -- Mercenarios
	-- { ['coords'] = vec4(2485.88,4953.12,44.84,139.78), ['hash2'] = "s_m_y_swat_01"}, -- Mafia
	-- { ['coords'] = vec4(-1512.23,851.87,181.59,27.52), ['hash2'] = "s_m_y_swat_01"}, -- Anonymous
	-- { ['coords'] = vec4(1369.5,-755.85,67.18,336.63), ['hash2'] = "s_m_y_swat_01"}, -- Cv
	-- { ['coords'] = vec4(701.33,-975.77,24.16,186.49), ['hash2'] = "s_m_y_swat_01"}, -- Espanha
	-- { ['coords'] = vec4(155.03,6629.6,31.83,138.43), ['hash2'] = "s_m_y_swat_01"}, -- Hospicio
	-- { ['coords'] = vec4(1279.09,-264.3,97.83,12.42), ['hash2'] = "s_m_y_swat_01"}, -- Bronks
	-- { ['coords'] = vec4(-2664.1,1327.31,147.37,179.12), ['hash2'] = "s_m_y_swat_01"}, -- Korea
	-- { ['coords'] = vec4(-711.66,5768.39,17.32,0.0), ['hash2'] = "s_m_y_swat_01"}, -- Magnatas
	-- { ['coords'] = vec4(-2041.56,-139.79,27.09,200.66), ['hash2'] = "s_m_y_swat_01"}, -- Franca
	-- { ['coords'] = vec4(-1816.57,449.37,128.41,356.57), ['hash2'] = "s_m_y_swat_01"}, -- Turquia
	-- { ['coords'] = vec4(-1536.96,83.17,56.77,320.41), ['hash2'] = "s_m_y_swat_01"}, -- Central
	-- { ['coords'] = vec4(1441.19,1137.88,114.33,93.4), ['hash2'] = "s_m_y_swat_01"}, -- Russia
	-- { ['coords'] = vec4(1418.33,-2508.89,55.03,188.89), ['hash2'] = "s_m_y_swat_01"}, -- Bratva
	-- { ['coords'] = vec4(-598.37,-1593.87,26.74,358.79), ['hash2'] = "s_m_y_swat_01"}, -- Cartel
	-- { ['coords'] = vec4(-543.9,338.73,84.37,171.8), ['hash2'] = "s_m_y_swat_01"}, -- Tequila
	-- { ['coords'] = vec4(-3171.44,798.19,11.76,32.58), ['hash2'] = "s_m_y_swat_01"}, -- Furia
	-- { ['coords'] = vec4(-295.06,184.01,87.92,184.9), ['hash2'] = "s_m_y_swat_01"}, -- Lux
	-- { ['coords'] = vec4(1013.54,-111.65,73.89,129.59), ['hash2'] = "s_m_y_swat_01"}, -- Motoclube
	-- { ['coords'] = vec4(-1085.32,-1642.62,4.48,127.54), ['hash2'] = "s_m_y_swat_01"}, -- Baixada
	-- { ['coords'] = vec4(501.09,-1340.5,29.3,359.54), ['hash2'] = "s_m_y_swat_01"}, -- Cohab
	-- { ['coords'] = vec4(-2205.53,4242.72,48.34,40.62), ['hash2'] = "s_m_y_swat_01"}, -- Lacoste
	-- { ['coords'] = vec4(-229.97,-1295.18,31.29,270.15), ['hash2'] = "s_m_y_swat_01"}, -- Bennys
	-- { ['coords'] = vec4(2526.61,4109.95,38.59,56.64), ['hash2'] = "s_m_y_swat_01"}, -- Cdd
	-- { ['coords'] = vec4(2358.98,3084.35,48.16,24.85), ['hash2'] = "s_m_y_swat_01"}, -- Roxos
	-- { ['coords'] = vec4(-810.72,166.42,72.22,115.44), ['hash2'] = "s_m_y_swat_01"}, -- Belgica
	-- { ['coords'] = vec4(-1897.39,2078.76,141.0,317.93), ['hash2'] = "s_m_y_swat_01"}, -- Italia
	-- { ['coords'] = vec4(180.02,2793.22,45.65,281.69), ['hash2'] = "s_m_y_swat_01"}, -- Colombia
	-- { ['coords'] = vec4(-543.9,338.73,84.37,171.8), ['hash2'] = "s_m_y_swat_01"}, -- Vanilla
	-- { ['coords'] = vec4(730.95,3395.45,62.68,300.98), ['hash2'] = "s_m_y_swat_01"}, -- Cosanostra

	{ ['coords'] = vec4(178.83,-947.74,29.79,219.7), ['hash2'] = "s_m_y_swat_01"}, -- Arena
	{ ['coords'] = vec4(-1631.89,-1015.31,13.13,316.74), ['hash2'] = "s_m_y_swat_01"}, -- Arena

	{ ['coords'] = vec4(-1584.63,-870.81,10.18,137.29), ['hash2'] = "s_m_y_valet_01"}, -- Vallet

	{ ['coords'] = vec4(1372.45,4379.79,44.42,189.68), ['hash2'] = "cs_hunter"}, -- Elevador
	-- { ['coords'] = vec4(176.84,-919.38,29.5,248.41), ['hash2'] = "cs_hunter"}, -- Elevador
	-- { ['coords'] = vec4(170.35,-928.98,29.81,252.95), ['hash2'] = "cs_hunter"}, -- Elevador
	{ ['coords'] = vec4(-601.46,2088.97,132.56,4.83), ['hash2'] = "cs_hunter"}, -- Elevador
	{ ['coords'] = vec4(1532.46,3587.73,38.77,276.58), ['hash2'] = "cs_hunter"}, -- Ilegal
}

CreateThread(function()
	for k,v in pairs(pedlist) do
		RequestModel(GetHashKey(v.hash2))
		while not HasModelLoaded(GetHashKey(v.hash2)) 
			do Wait(100) 
		end

		ped = CreatePed(4,GetHashKey(v.hash2),v.coords.x,v.coords.y,v.coords.z-1,v.coords.w,false,true)
		peds = ped
		FreezeEntityPosition(ped,true)
		SetEntityInvincible(ped,true)
		SetBlockingOfNonTemporaryEvents(ped,true)
	end
end)

function teleportPlayerProxmityCoords(x,y,z)
	local array = {}
	local coordenadas = {}

	for k,v in pairs(garagens) do
		local distanceAtual = parseInt(Vdist2(v[1],v[2],v[3], td(x),td(y),td(z)))
		table.insert(array, distanceAtual)
		coordenadas[distanceAtual] = { x = v[1], y = v[2], z = v[3] }
	end

	if coordenadas[math.min(table.unpack(array))] then
		SetEntityCoords(PlayerPedId(),coordenadas[math.min(table.unpack(array))].x,coordenadas[math.min(table.unpack(array))].y,coordenadas[math.min(table.unpack(array))].z)
	end

end

function td(n)
	n = math.ceil(n * 100) / 100
	return n
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EMPURRAR VEICULO
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local First = vector3(0.0, 0.0, 0.0)
local Second = vector3(5.0, 5.0, 5.0)
local Vehicle = {Coords = nil, Vehicle = nil, Dimension = nil, IsInFront = false, Distance = nil}
local empurrando = false

Citizen.CreateThread(function()
    while true do

        local time = 1000
        local ped = PlayerPedId()
        local posped = GetEntityCoords(GetPlayerPed(-1))
        local entityWorld = GetOffsetFromEntityInWorldCoords(ped, 0.0, 20.0, 0.0)
        local rayHandle = CastRayPointToPoint(posped.x, posped.y, posped.z, entityWorld.x, entityWorld.y, entityWorld.z, 10, ped, 0)
        local a, b, c, d, closestVehicle = GetRaycastResult(rayHandle)
        local Distance = GetDistanceBetweenCoords(c.x, c.y, c.z, posped.x, posped.y, posped.z, false);
        local vehicleCoords = GetEntityCoords(closestVehicle)
        local dimension = GetModelDimensions(GetEntityModel(closestVehicle), First, Second)
        if Distance < 6.0  and not IsPedInAnyVehicle(ped, false) then
            Vehicle.Coords = vehicleCoords
            Vehicle.Dimensions = dimension
            Vehicle.Vehicle = closestVehicle
            Vehicle.Distance = Distance
            if GetDistanceBetweenCoords(GetEntityCoords(closestVehicle) + GetEntityForwardVector(closestVehicle), GetEntityCoords(ped), true) > GetDistanceBetweenCoords(GetEntityCoords(closestVehicle) + GetEntityForwardVector(closestVehicle) * -1, GetEntityCoords(ped), true) then
                Vehicle.IsInFront = false
            else
                Vehicle.IsInFront = true
            end
        else
            Vehicle = {Coords = nil, Vehicle = nil, Dimensions = nil, IsInFront = false, Distance = nil}
        end
        Citizen.Wait(time)
    end
end)

Citizen.CreateThread(function()
    local lerpCurrentAngle = 0.0
    while true do 
    local ped = PlayerPedId()
    local time = 3000
    if Vehicle.Vehicle ~= nil then
        time = 5
            if IsControlPressed(0, 244) and IsVehicleSeatFree(Vehicle.Vehicle, -1) and not IsEntityAttachedToEntity(ped, Vehicle.Vehicle) then
                NetworkRequestControlOfEntity(Vehicle.Vehicle)

                if Vehicle.IsInFront then    
                    AttachEntityToEntity(PlayerPedId(), Vehicle.Vehicle, GetPedBoneIndex(6286), 0.0, Vehicle.Dimensions.y * -1 + 0.1 , Vehicle.Dimensions.z + 1.0, 0.0, 0.0, 180.0, 0.0, false, false, true, false, true)
                else
                    AttachEntityToEntity(PlayerPedId(), Vehicle.Vehicle, GetPedBoneIndex(6286), 0.0, Vehicle.Dimensions.y - 0.3, Vehicle.Dimensions.z  + 1.0, 0.0, 0.0, 0.0, 0.0, false, false, true, false, true)
                end
                if not empurrando then
                    empurrando = true
                    RequestAnimDict('missfinale_c2ig_11')
                    TaskPlayAnim(ped, 'missfinale_c2ig_11', 'pushcar_offcliff_m', 2.0, -8.0, -1, 35, 0, 0, 0, 0)
                end
                Citizen.Wait(200)
                    while true do
                    Citizen.Wait(5)

                    local speed = GetFrameTime() * 50
                    if IsDisabledControlPressed(0, 34) then
                        SetVehicleSteeringAngle(Vehicle.Vehicle, lerpCurrentAngle)
                        lerpCurrentAngle = lerpCurrentAngle + speed
                    elseif IsDisabledControlPressed(0, 9) then
                        SetVehicleSteeringAngle(Vehicle.Vehicle, lerpCurrentAngle)
                        lerpCurrentAngle = lerpCurrentAngle - speed
                    else
                        SetVehicleSteeringAngle(Vehicle.Vehicle, lerpCurrentAngle)
    
                        if lerpCurrentAngle < -0.02 then    
                            lerpCurrentAngle = lerpCurrentAngle + speed
                        elseif lerpCurrentAngle > 0.02 then
                            lerpCurrentAngle = lerpCurrentAngle - speed
                        else
                            lerpCurrentAngle = 0.0
                        end
                    end

                    if lerpCurrentAngle > 15.0 then
                        lerpCurrentAngle = 15.0
                    elseif lerpCurrentAngle < -15.0 then
                        lerpCurrentAngle = -15.0
                    end

                    if Vehicle.IsInFront then
                        SetVehicleForwardSpeed(Vehicle.Vehicle, -1.0)
                    else
                        SetVehicleForwardSpeed(Vehicle.Vehicle, 1.0)
                    end

                    if HasEntityCollidedWithAnything(Vehicle.Vehicle) then
                        SetVehicleOnGroundProperly(Vehicle.Vehicle)
                    end

                    if not IsDisabledControlPressed(0, 244) then
                        empurrando = false
                        DetachEntity(ped, false, false)
                        StopAnimTask(ped, 'missfinale_c2ig_11', 'pushcar_offcliff_m', 2.0)
                        FreezeEntityPosition(ped, false)
                        break
                    end
                end
            end
        end

        Citizen.Wait(time)
    end  
end)

function DrawText3D(x,y,z, text)
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
-----------------------------------------------------------------------------------------------------------------------------------------
-- PRESSME
-----------------------------------------------------------------------------------------------------------------------------------------
-- local showMe = {}
-- local flagged = false

-- RegisterNetEvent("vrp_player:pressMe")
-- AddEventHandler("vrp_player:pressMe", function(source, text, v)
--     local pedSource = GetPlayerFromServerId(source)
--     if pedSource ~= -1 then
--         local flagged = false
--         local blocks = {
--             "font size=", "font size =", "<font", "size=", "<font size=", 
--             "<font size =", "width", "zoom", "transform: scale(", "transform:"
--         }
        
--         for i = 1, #blocks do
--             if string.match(string.lower(text), blocks[i]) then
--                 flagged = true
--                 break
--             end
--         end

--         if flagged then
--             return
--         else
--             showMe[GetPlayerPed(pedSource)] = {text, v[1], v[2], v[3], v[4], v[5], GetGameTimer() + 10000}
--         end
--     end
-- end)

local showMe = {}
RegisterNetEvent("vrp_showme:pressMe")
AddEventHandler("vrp_showme:pressMe",function(source,text,v)
	local pedSource = GetPlayerFromServerId(source)
	if pedSource ~= -1 then
		showMe[GetPlayerPed(pedSource)] = { text,v[1],v[2],v[3],v[4],v[5] }
		SetTimeout(10000,function()
			showMe[GetPlayerPed(pedSource)] = nil
		end)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSHOWMEDISPLAY
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
		local timeDistance = 1000
		local ped = PlayerPedId()
		local coords = GetEntityCoords(ped)
		for k,v in pairs(showMe) do
			local coordsMe = GetEntityCoords(k)
			local distance = #(coords - coordsMe)
			if distance <= 5 then
				timeDistance = 0
				if HasEntityClearLosToEntity(ped,k,17) then
					showMe3D(coordsMe.x,coordsMe.y,coordsMe.z+0.3,string.upper(v[1]),v[3],v[4],v[5],v[6])
				end
			end
		end

		Citizen.Wait(timeDistance)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SHOWME3D
-----------------------------------------------------------------------------------------------------------------------------------------
function showMe3D(x, y, z, text, h, back, color, opacity)
    SetTextFont(4)
    SetTextCentre(1)
    SetTextEntry("STRING")
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 255, 255, 150)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text) / 375) + 0.01
    DrawRect(0.0, 0.0125, factor, 0.03, 38, 42, 56, 200)
    ClearDrawOrigin()
end
-----------------------------------------------------------------------------------------------------------------------------------------
--[ ABRIR PORTAS DO VEICULO ]------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("portas",function(source,args)
	local v = vRP.getNearestVehicle(7)
	local locked = GetVehicleDoorLockStatus(vehicle)
	if locked == 2 then
		TriggerEvent("Notify","negado","Veículo trancado!")
		return
	elseif IsEntityAVehicle(v) then
		if args[1] then
			openDoors(v, 'doors', tostring(args[1]))
		else
			openDoors(v, 'allDoors')
		end
	end
end)

function openDoors(veh, type, status)
	if not DoesEntityExist(veh) then return end
	NetworkRequestControlOfEntity(veh)

	if (type == 'allDoors') then
		local isopen = GetVehicleDoorAngleRatio(veh,0) and GetVehicleDoorAngleRatio(veh,1)
		if isopen == 0 then
			SetVehicleDoorOpen(veh,0,0,0)
			SetVehicleDoorOpen(veh,1,0,0)
			SetVehicleDoorOpen(veh,2,0,0)
			SetVehicleDoorOpen(veh,3,0,0)
		else
			SetVehicleDoorShut(veh,0,0)
			SetVehicleDoorShut(veh,1,0)
			SetVehicleDoorShut(veh,2,0)
			SetVehicleDoorShut(veh,3,0)
		end
	end

	if (type == 'doors') then
		if status == "1" then
			if GetVehicleDoorAngleRatio(veh,0) == 0 then
				SetVehicleDoorOpen(veh,0,0,0)
			else
				SetVehicleDoorShut(veh,0,0)
			end
		elseif status == "2" then
			if GetVehicleDoorAngleRatio(veh,1) == 0 then
				SetVehicleDoorOpen(veh,1,0,0)
			else
				SetVehicleDoorShut(veh,1,0)
			end
		elseif status == "3" then
			if GetVehicleDoorAngleRatio(veh,2) == 0 then
				SetVehicleDoorOpen(veh,2,0,0)
			else
				SetVehicleDoorShut(veh,2,0)
			end
		elseif status == "4" then
			if GetVehicleDoorAngleRatio(veh,3) == 0 then
				SetVehicleDoorOpen(veh,3,0,0)
			else
				SetVehicleDoorShut(veh,3,0)
			end
		elseif status == "5" then
			local isopen = GetVehicleDoorAngleRatio(veh,5)
			if DoesEntityExist(veh) then
				if IsEntityAVehicle(veh) then
					if isopen == 0 then
						SetVehicleDoorOpen(veh,5,0,0)
					else
						SetVehicleDoorShut(veh,5,0)
					end
				end
			end
		end
	end

	if (type == 'capo') then
		local isopen = GetVehicleDoorAngleRatio(veh,4)
		if DoesEntityExist(veh) then
			if IsEntityAVehicle(veh) then
				if isopen == 0 then
					SetVehicleDoorOpen(veh,4,0,0)
				else
					SetVehicleDoorShut(veh,4,0)
				end
			end
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
--[ ABRE E FECHA OS VIDROS ]-------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------
local vidros = false
RegisterCommand("vidros",function(source,args)
	local vehicle = vRP.getNearestVehicle(7)
	if IsEntityAVehicle(vehicle) then
		TriggerServerEvent("trywins",VehToNet(vehicle), GetClosestPlayers(50.0))
	end
end)

RegisterNetEvent("target:vidros")
AddEventHandler("target:vidros",function(index)
	local vehicle = vRP.getNearestVehicle(7)
	if IsEntityAVehicle(vehicle) then
		TriggerServerEvent("trywins",VehToNet(vehicle), GetClosestPlayers(50.0))
	end
end)


RegisterNetEvent("syncwins")
AddEventHandler("syncwins",function(index)
	if NetworkDoesNetworkIdExist(index) then
		local v = NetToVeh(index)
		if DoesEntityExist(v) then
			if IsEntityAVehicle(v) then
				if vidros then
					vidros = false
					RollUpWindow(v,0)
					RollUpWindow(v,1)
					RollUpWindow(v,2)
					RollUpWindow(v,3)
				else
					vidros = true
					RollDownWindow(v,0)
					RollDownWindow(v,1)
					RollDownWindow(v,2)
					RollDownWindow(v,3)
				end
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
--[ ABRIR CAPO DO VEICULO ]--------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("capo",function(source,args)
	local vehicle = vRP.getNearestVehicle(7)
	if IsEntityAVehicle(vehicle) then
		openDoors(vehicle, 'capo')
	end
end)

RegisterNetEvent("target:capo")
AddEventHandler("target:capo",function(index)
	local vehicle = vRP.getNearestVehicle(7)
	if IsEntityAVehicle(vehicle) then
		openDoors(vehicle, 'capo')
	end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- ABRIR PORTA-MALAS DO VEICULO
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("malas",function(source,args)
	local vehicle = vRP.getNearestVehicle(7)
	if IsEntityAVehicle(vehicle) then
		TriggerServerEvent("trytrunkVisual",VehToNet(vehicle))
	end
end)

RegisterNetEvent("target:malas")
AddEventHandler("target:malas",function(index)
	local vehicle = vRP.getNearestVehicle(7)
	if IsEntityAVehicle(vehicle) then
		TriggerServerEvent("trytrunkVisual",VehToNet(vehicle))
	end
end)

RegisterNetEvent("synctrunkVisual")
AddEventHandler("synctrunkVisual",function(index)
	if NetworkDoesNetworkIdExist(index) then
		local v = NetToVeh(index)
		local isopen = GetVehicleDoorAngleRatio(v,5)
		if DoesEntityExist(v) then
			if IsEntityAVehicle(v) then
				if isopen == 0 then
					SetVehicleDoorOpen(v,5,0,0)
				else
					SetVehicleDoorShut(v,5,0)
				end
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- /SKIN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("skinmenu")
AddEventHandler("skinmenu",function(mhash, check)
	--if vSERVER.checkskin() or check then
		if GetInvokingResource() then
			return
		end
		while not HasModelLoaded(mhash) do
			RequestModel(mhash)
			Citizen.Wait(10)
		end

		if HasModelLoaded(mhash) then
			SetPlayerModel(PlayerId(),mhash)
			SetModelAsNoLongerNeeded(mhash)
			
			-- SetPedCanRagdoll(PlayerPedId(), false)
		end
	--end
end)



-- local enableMessages = true
-- local timeout = 10 * 1000 * 60 -- from ms, to sec, to min

-- Citizen.CreateThread(function()
--     while true do
--     	if enableMessages then
--     	    TriggerEvent('chat:addMessage',{template='<div style="display:flex;align-items:center;justify-content:center;padding:10px;margin:5px 0;background-image: linear-gradient(to right, rgba(89, 48, 192,0.8) 3%, rgba(89, 48, 192,0) 95%);border-radius: 5px;"><b>DIGITE /ONLINE PARA RECEBER PRÊMIOS E ITENS EXCLUSIVOS</b></div>'})
--     	end
--     	Citizen.Wait(timeout)
--     end
-- end)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SISTEMA DE GRAU
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local comecar = false
local dict = "rcmextreme2atv"
local anims = {
	"idle_b",
	"idle_c",
	"idle_d",
	"idle_e"
}

RegisterCommand("manobras",function(raw,args)
	if comecar == false then
		if vSERVER.checkPermVip() then
			comecar = true
			
			Citizen.CreateThread(function()
				while comecar do 
					local idle = 1000
					if comecar == true then
						local ped = PlayerPedId()
						local bike = GetVehiclePedIsIn(ped)
						local speed = GetEntitySpeed(bike)*3.6
						idle = 1000
						if IsPedOnAnyBike(ped) then
							if speed >= 5 then
								idle = 5
								while not HasAnimDictLoaded(dict) do 
									Wait(0)
									RequestAnimDict(dict)
								end
				
								if IsControlJustPressed(0,174) or IsControlJustPressed(0,108) then -- Seta Esquerda ou NumPad 4 = Manobra esquerda
									TaskPlayAnim(ped,dict,anims[1], 8.0, -8.0, -1, 32, 0, false, false, false)
									
								elseif IsControlJustPressed(0,175) or IsControlJustPressed(0,107) then -- Seta Direita ou NumPad 6 = Manobra direita
									TaskPlayAnim(ped,dict,anims[2], 8.0, -8.0, -1, 32, 0, false, false, false)
				
								elseif IsControlJustPressed(0,173) or IsControlJustPressed(0,110) then -- Seta para Baixo ou NumPad 5 = Manobra lados
									TaskPlayAnim(ped,dict,anims[3], 8.0, -8.0, -1, 32, 0, false, false, false)
				
								elseif IsControlJustPressed(0,27) or IsControlJustPressed(0,111) then -- Seta para Cima ou NumPad 8 = Manobra cima
									TaskPlayAnim(ped,dict,anims[4], 8.0, -8.0, -1, 32, 0, false, false, false)
								end
							end
						end
					end
					Citizen.Wait(idle)
				end
			end)

			TriggerEvent("Notify","sucesso","Você está preparado para fazer as manobras")
		else
			TriggerEvent("Notify","negado","Você não tem permissão")
			return false
		end
	else
		comecar = false
		TriggerEvent("Notify","importante","Você está parou de fazer manobras")
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

function GetClosestPlayers(range)
    local peds = GetGamePool("CPed")
    local ped = PlayerPedId()
    local plys = {}
    for i=1, #peds do
        local ply = peds[i]
        local distance = #(GetEntityCoords(ped) - GetEntityCoords(ply))
        if IsPedAPlayer(ply) and distance < range then
            plys[#plys + 1] = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ply))
        end
    end
    return plys
end

local rainbowColors = {
    {255, 0, 0},       -- Vermelho
    {255, 63, 0},
    {255, 127, 0},
    {255, 191, 0},
    {255, 255, 0},
    {191, 255, 0},
    {127, 255, 0},
    {63, 255, 0},
    {0, 255, 0},       -- Verde
    {0, 255, 63},
    {0, 255, 127},
    {0, 255, 191},
    {0, 255, 255},     -- Ciano
    {0, 191, 255},
    {0, 127, 255},
    {0, 63, 255},
    {0, 0, 255},       -- Azul
    {63, 0, 255},
    {127, 0, 255},
    {191, 0, 255},
    {255, 0, 255},     -- Magenta
    {255, 0, 191},
    {255, 0, 127},
    {255, 0, 63},
}

local currentColorIndex = 1

function setVehicleColor(vehicle, color)
    local r, g, b = color[1], color[2], color[3]
    SetVehicleCustomPrimaryColour(vehicle, r, g, b)
end

function getVehicleColor(vehicle)
    local r, g, b = GetVehicleCustomPrimaryColour(vehicle)
    return {r, g, b}
end

local function getNextRainbowColor()
    return rainbowColors[currentColorIndex]
end

local function goToNextColor()
    currentColorIndex = currentColorIndex + 1
    if currentColorIndex > #rainbowColors then
        currentColorIndex = 1
    end
end

function changeVehicleColor()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if DoesEntityExist(vehicle) then
        local startColor = getVehicleColor(vehicle)
        local nextColor = getNextRainbowColor(vehicle)
        local r,g,b = startColor[1], startColor[2], startColor[3]
        local rd,gd,bd = nextColor[1], nextColor[2], nextColor[3]
        local startTime = GetGameTimer()
        while true do
            if rd ~= r or gd ~= g or bd ~= b then
                if rd ~= r then
                    if r > rd then
                        rd = rd + 1
                    else
                        rd = rd - 1
                    end
                end
                if gd ~= g then
                    if g > gd then
                        gd = gd + 1
                    else
                        gd = gd - 1
                    end
                end
                if bd ~= b then
                    if b > bd then
                        bd = bd + 1
                    else
                        bd = bd - 1
                    end
                end
                SetVehicleCustomPrimaryColour(vehicle,rd,gd,bd)
            end

            if rd == r and gd == g and bd == b then
                goToNextColor()
                local nextColor = getNextRainbowColor(vehicle)
                r,g,b = nextColor[1], nextColor[2], nextColor[3]
            end
            Citizen.Wait(1)
        end
    end
end

-- RegisterCommand("mudarcor", function()
-- 	if vSERVER.checkPermCor() then
--     	changeVehicleColor()
-- 	end
-- end) 


local inSafeZone = false

Citizen.CreateThread(function()
    while true do 
        local timeIdle = 1000
        if inSafeZone then 
            timeIdle = 0 
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped) then
             --   SetNetworkVehicleAsGhost(GetVehiclePedIsUsing(player),true)
                if not IsEntityGhostedToLocalPlayer(ped) then
                    SetLocalPlayerAsGhost(true)
                    SetGhostedEntityAlpha(254)
                end
            else
				SetGhostedEntityAlpha(254)
                if IsEntityGhostedToLocalPlayer(ped) then
                    SetLocalPlayerAsGhost(false)
					ResetGhostedEntityAlpha()
                end
            end
        else 
			SetGhostedEntityAlpha(254)
            if IsEntityGhostedToLocalPlayer(ped) then
                SetLocalPlayerAsGhost(false)
				ResetGhostedEntityAlpha()
            end
        end
        Citizen.Wait(timeIdle)
    end
end)


exports("setinsafe", function(status)
	inSafeZone = status
    if not status then 
        if IsEntityGhostedToLocalPlayer(PlayerPedId()) then
            SetLocalPlayerAsGhost(false)
        end
    end
end)

function src.isInDomination()
	return exports.dominacao:inDomination() or exports.dm_module:inDomination() or exports['fusion_dominacao_pistol']:inDomination()
end

RegisterNetEvent("novak:markerYouOrganization", function(permission, orgName)
	local coordsInMap = exports["m_garage"]:foundGarageByPermission(permission)
	if coordsInMap and next(coordsInMap) then
		if coordsInMap.coords then
			local blip = AddBlipForCoord(coordsInMap.coords.x + 2.5, coordsInMap.coords.y + 1.5, coordsInMap.coords.z)
			SetBlipSprite(blip, 630)
			SetBlipColour(blip, 46)
			SetBlipScale(blip, 1.0)
			SetBlipAsShortRange(blip, true)
			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString("[SUA FACÇÃO]")
			EndTextCommandSetBlipName(blip)
		end
	end
end)

function src.checkEnteringVehicle()
	local ped = PlayerPedId()
	return IsPedTryingToEnterALockedVehicle(ped) or IsPedInAnyVehicle(ped)
end

CreateThread(function() 
  StartAudioScene("CHARACTER_CHANGE_IN_SKY_SCENE");
  SetAudioFlag("PoliceScannerDisabled",true); 
  SetPlayerCanUseCover(PlayerId(),false)
end)

-----------------------------------------------------------------------------------------------------------------------------------------

other = nil
drag = false
carregado = false

RegisterNetEvent("carregar")
AddEventHandler("carregar",function(p1)
    other = p1
    drag = not drag
end)

Citizen.CreateThread(function()
    while true do
    	local idle = 1000
		if drag and other then
			idle = 5
			local ped = GetPlayerPed(GetPlayerFromServerId(other))
--			Citizen.InvokeNative(0x6B9BBD38AB0796DF,PlayerPedId(),ped,4103,11816,0.48,0.0,0.0,0.0,0.0,0.0,false,false,false,false,2,true)
			Citizen.InvokeNative(0x6B9BBD38AB0796DF,PlayerPedId(),ped,4103,0.56,0.0,0.0,0.0,0.0,0.0,0.0,false,false,false,false,2,true)
			carregado = true
		else
			idle = 5
        	if carregado then
				DetachEntity(PlayerPedId(),true,false)
				carregado = false
			end
		end
		Citizen.Wait(idle)
	end
end)

Citizen.CreateThread(function()
	while true do
		local idle = 1000
		if not IsPedInAnyVehicle(PlayerPedId()) then
			idle = 5
			if IsControlJustPressed(0,74) then
				TriggerServerEvent("mg:carregar")
			end
		end
		Citizen.Wait(idle)
	end
end)








------------------------------------------------------------------------------
-- CARREGAR NO OMBRO
--------------------------------------------------------------------------------
local carryingBackInProgress = false

RegisterCommand("carregar",function(source, args)
	
		if not carryingBackInProgress then
			if vSERVER.checkpermcarregar() then
				carryingBackInProgress = true
				local player = PlayerPedId()	
				lib = 'missfinale_c2mcs_1'
				anim1 = 'fin_c2_mcs_1_camman'
				lib2 = 'nm'
				anim2 = 'firemans_carry'
				distans = 0.15
				distans2 = 0.27
				height = 0.63
				spin = 0.0		
				length = 100000
				controlFlagMe = 49
				controlFlagTarget = 33
				animFlagTarget = 1
				local closestPlayer = GetClosestPlayer(3)
				target = GetPlayerServerId(closestPlayer)
				if closestPlayer ~= nil then
				--	print("triggering cmg2_animations:sync")
					TriggerServerEvent('cmg2_animations:sync', closestPlayer, lib,lib2, anim1, anim2, distans, distans2, height,target,length,spin,controlFlagMe,controlFlagTarget,animFlagTarget)
				else
				--	print("[Aviso] Nenhum jogador por perto")
				end
			end
		else
			carryingBackInProgress = false
			ClearPedSecondaryTask(GetPlayerPed(-1))
			DetachEntity(GetPlayerPed(-1), true, false)
			local closestPlayer = GetClosestPlayer(3)
			target = GetPlayerServerId(closestPlayer)
			TriggerServerEvent("cmg2_animations:stop",target)
		end
	
end,false)

RegisterNetEvent('cmg2_animations:syncTarget')
AddEventHandler('cmg2_animations:syncTarget', function(target, animationLib, animation2, distans, distans2, height, length,spin,controlFlag)
	local playerPed = GetPlayerPed(-1)
	local targetPed = GetPlayerPed(GetPlayerFromServerId(target))
	carryingBackInProgress = true
	print("triggered cmg2_animations:syncTarget")
	RequestAnimDict(animationLib)

	while not HasAnimDictLoaded(animationLib) do
		Citizen.Wait(10)
	end
	if spin == nil then spin = 180.0 end
	AttachEntityToEntity(GetPlayerPed(-1), targetPed, 0, distans2, distans, height, 0.5, 0.5, spin, false, false, false, false, 2, false)
	if controlFlag == nil then controlFlag = 0 end
	TaskPlayAnim(playerPed, animationLib, animation2, 8.0, -8.0, length, controlFlag, 0, false, false, false)
end)

RegisterNetEvent('cmg2_animations:syncMe')
AddEventHandler('cmg2_animations:syncMe', function(animationLib, animation,length,controlFlag,animFlag)
	local playerPed = GetPlayerPed(-1)
	print("triggered cmg2_animations:syncMe")
	RequestAnimDict(animationLib)

	while not HasAnimDictLoaded(animationLib) do
		Citizen.Wait(10)
	end
	Wait(500)
	if controlFlag == nil then controlFlag = 0 end
	TaskPlayAnim(playerPed, animationLib, animation, 8.0, -8.0, length, controlFlag, 0, false, false, false)

	Citizen.Wait(length)
end)

RegisterNetEvent('cmg2_animations:cl_stop')
AddEventHandler('cmg2_animations:cl_stop', function()
	carryingBackInProgress = false
	ClearPedSecondaryTask(GetPlayerPed(-1))
	DetachEntity(GetPlayerPed(-1), true, false)
end)

function GetPlayers()
    local players = {}

    for i = 0, 255 do
        if NetworkIsPlayerActive(i) then
            table.insert(players, i)
        end
    end

    return players
end

function GetClosestPlayer(radius)
    local players = GetPlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local ply = GetPlayerPed(-1)
    local plyCoords = GetEntityCoords(ply, 0)

    for index,value in ipairs(players) do
        local target = GetPlayerPed(value)
        if(target ~= ply) then
            local targetCoords = GetEntityCoords(GetPlayerPed(value), 0)
            local distance = GetDistanceBetweenCoords(targetCoords['x'], targetCoords['y'], targetCoords['z'], plyCoords['x'], plyCoords['y'], plyCoords['z'], true)
            if(closestDistance == -1 or closestDistance > distance) then
                closestPlayer = value
                closestDistance = distance
            end
        end
    end
--	print("jogador mais próximo é dist: " .. tostring(closestDistance))
	if closestDistance <= radius then
		return closestPlayer
	else
		return nil
	end
end





otheralg = nil
dragalg = false
carregadoalg = false

RegisterNetEvent("carregar:alg")
AddEventHandler("carregar:alg",function(p1)
    otheralg = p1
    dragalg = not dragalg
end)

Citizen.CreateThread(function()
    while true do
    	local idle = 1000
		if dragalg and otheralg then
			idle = 5
			local ped = GetPlayerPed(GetPlayerFromServerId(otheralg))
			-- Citizen.InvokeNative(0x6B9BBD38AB0796DF,PlayerPedId(),ped,4103,11816,0.48,0.0,0.0,0.0,0.0,0.0,false,false,false,false,2,true)
			-- Citizen.InvokeNative(0x6B9BBD38AB0796DF,PlayerPedId(),ped,4103,0.56,0.0,0.0,0.0,0.0,0.0,0.0,false,false,false,false,2,true)
			carregadoalg = true
		else
			idle = 5
        	if carregadoalg then
				DetachEntity(PlayerPedId(),true,false)
				carregadoalg = false
			end
		end
		Citizen.Wait(idle)
	end
end)
 
Citizen.CreateThread(function()
	while true do
		local idle = 1000
		if not IsPedInAnyVehicle(PlayerPedId()) then
			idle = 5
			if IsControlJustPressed(0,47) then
				TriggerServerEvent("vrp_policia:algemar")
			end
			if IsControlJustPressed(0,74) then
				TriggerServerEvent("vrp_policia:carregar")
			end
		end
		Citizen.Wait(idle)
	end
end)