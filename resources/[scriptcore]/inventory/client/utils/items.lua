local oxygen = 0
local in_scuba = false
local attachedProp = 0
local scubaMask = 0
local scubaTank = 0
local inUseDrug = false
local countdownDrug = 0
local energySprintMultiplier = 1.15
local sprintBoosts = {}

local function setSprintBoost(effect, multiplier)
    sprintBoosts[effect] = multiplier

    local strongestBoost = 1.0
    for _, boost in pairs(sprintBoosts) do
        strongestBoost = math.max(strongestBoost, boost)
    end

    SetRunSprintMultiplierForPlayer(PlayerId(), strongestBoost)
    if strongestBoost == 1.0 then
        RestorePlayerStamina(PlayerId(), 1.0)
    end
end
local methArmourBonus = 5
local methArmourReinforcement

local function reinforceMethArmour(ped)
    local reinforcement = { ped = ped, remaining = methArmourBonus, armour = GetPedArmour(ped) }
    methArmourReinforcement = reinforcement

    CreateThread(function()
        while methArmourReinforcement == reinforcement do
            if PlayerPedId() ~= ped or IsEntityDead(ped) or GetPedArmour(ped) <= 0 then
                methArmourReinforcement = nil
                return
            end

            reinforcement.armour = GetPedArmour(ped)
            Wait(0)
        end
    end)
end

AddEventHandler("gameEventTriggered", function(eventName, args)
    local reinforcement = methArmourReinforcement
    if not reinforcement or eventName ~= "CEventNetworkEntityDamage" then return end

    local ped = reinforcement.ped
    if args[1] ~= ped or PlayerPedId() ~= ped or IsEntityDead(ped) then return end

    local armour = GetPedArmour(ped)
    local lost = reinforcement.armour - armour
    local weapon = args[7]
    if lost > 0 and weapon and GetWeaponDamageType(weapon) == 3 then
        local absorbed = math.min(lost, reinforcement.remaining)
        armour = armour + absorbed
        SetPedArmour(ped, armour)
        reinforcement.remaining = reinforcement.remaining - absorbed
    end

    reinforcement.armour = armour
    if reinforcement.remaining == 0 or armour == 0 then
        methArmourReinforcement = nil
    end
end)

RegisterNetEvent('inventory:useDrugs', function(drug)
	local ped = PlayerPedId()

	if not inUseDrug then
		inUseDrug = true
		if drug == "cocaina" then
			if GetEntityHealth(ped) <= 170 then
				TriggerEvent("Notify", "negado", "Você está com a vida muito baixa não pode utilizar.", 5)
				inUseDrug = false
				return
			end

            local health = GetEntityHealth(ped)
            SetEntityHealth(ped, math.floor(health * 0.95))
            setSprintBoost("cocaina", energySprintMultiplier)

            SetTimeout(15000, function()
                setSprintBoost("cocaina", nil)
                inUseDrug = false
            end)
            return
        elseif drug == "metanfetamina" then
            local currentArmor = GetPedArmour(ped)
            if currentArmor <= 0 or IsEntityDead(ped) then
                TriggerEvent("Notify", "negado", "O efeito exige que você ainda esteja com colete.", 5)
            else
                if currentArmor < 100 then
                    SetPedArmour(ped, math.min(100, currentArmor + methArmourBonus))
                    TriggerEvent("Notify", "sucesso", "Seu colete foi recuperado.", 5)
                elseif not API.hasMethArmourReinforcement() then
                    reinforceMethArmour(ped)
                    TriggerEvent("Notify", "sucesso", "Seu colete recebeu 5 pontos de proteção contra os próximos tiros.", 5)
                end
            end
            inUseDrug = false
            return
        elseif drug == "heroina" then
			countdownDrug = 15

			CreateThread(function()
				while inUseDrug do
					countdownDrug = countdownDrug - 1

					if countdownDrug <= 0 then
						inUseDrug = false
						break
					end

					Wait(1000)
				end
			end)
			return
		elseif drug == "cogumelo" then
			if GetPedArmour(ped) >= 75 then
				TriggerEvent("Notify", "negado", "Você está com o colete muito alto não pode utilizar.", 5)
				inUseDrug = false
				return
			end

			setSprintBoost("cogumelo", 1.3)

			local currentArmor = GetPedArmour(ped)
			local maxArmor = 100
			local armorToRestore = 0.25 * maxArmor
			local targetArmor = currentArmor + armorToRestore

			if targetArmor > 0.75 * maxArmor then
				targetArmor = 0.75 * maxArmor
			end

			local armorIncrement = 1

			calc_health = (GetEntityHealth(ped) * 0.05)
			SetEntityHealth(ped, parseInt(GetEntityHealth(ped) - calc_health))

			countdownDrug = 25

			local lastHealth = GetEntityHealth(ped)

			CreateThread(function()
				while inUseDrug do
					if GetEntityHealth(ped) < lastHealth then
						setSprintBoost("cogumelo", nil)
						TriggerEvent("Notify", "negado", "O efeito da droga foi cancelado porque você foi ferido.")
						inUseDrug = false
						break
					end

					lastHealth = GetEntityHealth(ped)

					currentArmor = parseInt(currentArmor) + parseInt(armorIncrement)
					if currentArmor > targetArmor then
						currentArmor = targetArmor
					end


					SetPedArmour(ped, parseInt(currentArmor))
					setSprintBoost("cogumelo", nil)

					countdownDrug = countdownDrug - 1

					if countdownDrug <= 0 then
						inUseDrug = false
						break
					end

					Wait(1000)
				end
			end)

			return
		else
			countdownDrug = 15

			CreateThread(function()
				while inUseDrug do
					countdownDrug = countdownDrug - 1

					if countdownDrug <= 0 then
						inUseDrug = false
						break;
					end
					Wait(1000)
				end
			end)

			return
		end
	end
end)

local overdoseEffect
local overdoseWalk = "move_m@drunk@moderatedrunk"
local overdoseAnim = "missfam5_blackout"
local overdoseScreen = "DrugsTrevorClownsFight"

local function stopOverdoseEffect()
    local effect = overdoseEffect
    if not effect then return end
    overdoseEffect = nil

    if effect.screenStarted then
        AnimpostfxStop(overdoseScreen)
    end
    if DoesEntityExist(effect.ped) then
        if effect.walkApplied then
            ResetPedMovementClipset(effect.ped, 0.25)
        end
        if effect.animStarted then
            StopAnimTask(effect.ped, overdoseAnim, "vomit", 1.0)
        end
    end
    RemoveAnimDict(overdoseAnim)
    RemoveAnimSet(overdoseWalk)
end

RegisterNetEvent("inventory:drugOverdose", function(duration)
    if overdoseEffect then return end
    local ped = PlayerPedId()
    if GetEntityHealth(ped) <= 101 then return end

    local effect = { ped = ped, screenStarted = not AnimpostfxIsRunning(overdoseScreen) }
    overdoseEffect = effect
    if effect.screenStarted then
        AnimpostfxPlay(overdoseScreen, 0, true)
    end
    RequestAnimDict(overdoseAnim)
    RequestAnimSet(overdoseWalk)

    CreateThread(function()
        local expires = GetGameTimer() + duration
        while overdoseEffect == effect and GetGameTimer() < expires
            and PlayerPedId() == ped and GetEntityHealth(ped) > 101 do
            if IsPedOnFoot(ped) and not IsPedRagdoll(ped) then
                if not effect.animStarted and HasAnimDictLoaded(overdoseAnim) then
                    TaskPlayAnim(ped, overdoseAnim, "vomit", 4.0, -4.0, 2000, 48, 0.0, false, false, false)
                    effect.animStarted = true
                end
                if not effect.walkApplied and HasAnimSetLoaded(overdoseWalk) then
                    SetPedMovementClipset(ped, overdoseWalk, 0.25)
                    effect.walkApplied = true
                end
            end
            Wait(100)
        end
        if overdoseEffect == effect then
            stopOverdoseEffect()
        end
    end)
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        stopOverdoseEffect()
        if next(sprintBoosts) then
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        end
    end
end)

function API.hasMethArmourReinforcement()
    local reinforcement = methArmourReinforcement
    return reinforcement ~= nil and reinforcement.ped == PlayerPedId()
        and not IsEntityDead(reinforcement.ped) and GetPedArmour(reinforcement.ped) > 0
end

function API.isInDrug()
	return inUseDrug
end


function API.setScuba(status)
	if status then
		attachProp("p_s_scuba_tank_s", 24818, -0.25, -0.25, 0.0, 180.0, 90.0, 0.0)
		attachProp("p_s_scuba_mask_s", 12844, 0.0, 0.0, 0.0, 180.0, 90.0, 0.0)
		in_scuba = true
		oxygen = 100
	else
		in_scuba = false
		DeleteEntity(scubaMask)
		DeleteEntity(scubaTank)
	end
end

function API.checkScuba()
	return in_scuba
end

function attachProp(attachModelSent, boneNumberSent, x, y, z, xR, yR, zR)
	local attachModel = GetHashKey(attachModelSent)
	local bone = GetPedBoneIndex(GetPlayerPed(-1), boneNumberSent)

	RequestModel(attachModel)
	while not HasModelLoaded(attachModel) do
		Citizen.Wait(100)
	end

	if tonumber(attachModel) == 1569945555 then
		attachedProp = CreateObject(attachModel, 1.0, 1.0, 1.0, 1, 1, 0)
		scubaTank = attachedProp
	elseif tonumber(attachModel) == 138065747 then
		attachedProp = CreateObject(attachModel, 1.0, 1.0, 1.0, 1, 1, 0)
		scubaMask = attachedProp
	end

	SetEntityCollision(attachedProp, false, 0)
	AttachEntityToEntity(attachedProp, GetPlayerPed(-1), bone, x, y, z, xR, yR, zR, 1, 1, 0, 0, 2, 1)
end

Citizen.CreateThread(function()
	while true do
		local time = 1000
		if IsPedSwimmingUnderWater(GetPlayerPed(-1)) and in_scuba then
			time = 5
			if oxygen > 50 then
				drawTxt("VOCÊ POSSUI ~g~" .. oxygen .. "% ~w~ DE OXIGÊNIO.", 4, 0.5, 0.96, 0.50, 255, 255, 255, 100)
				SetPedDiesInWater(GetPlayerPed(-1), false)
				SetPedMaxTimeUnderwater(GetPlayerPed(-1), 10.0)
			elseif oxygen > 30 then
				drawTxt("VOCÊ POSSUI ~b~" .. oxygen .. "% ~w~ DE OXIGÊNIO.", 4, 0.5, 0.96, 0.50, 255, 255, 255, 100)
				SetPedDiesInWater(GetPlayerPed(-1), false)
				SetPedMaxTimeUnderwater(GetPlayerPed(-1), 10.0)
			elseif oxygen > 0 then
				drawTxt("VOCÊ POSSUI ~r~" .. oxygen .. "% ~w~ DE OXIGÊNIO.", 4, 0.5, 0.96, 0.50, 255, 255, 255, 100)
				SetPedDiesInWater(GetPlayerPed(-1), false)
				SetPedMaxTimeUnderwater(GetPlayerPed(-1), 10.0)
			elseif oxygen <= 0 then
				drawTxt("~r~VOCÊ NÃO POSSUI MAIS OXIGÊNIO.", 4, 0.5, 0.96, 0.50, 255, 255, 255, 100)
				SetPedDiesInWater(GetPlayerPed(-1), true)
				SetPedMaxTimeUnderwater(GetPlayerPed(-1), 0.0)
				oxygen = 0
			end
		elseif IsPedSwimmingUnderWater(GetPlayerPed(-1)) and not in_scuba then
			SetPedMaxTimeUnderwater(GetPlayerPed(-1), 10.0)
			SetPedDiesInWater(GetPlayerPed(-1), true)
		end
		Citizen.Wait(time)
	end
end)

Citizen.CreateThread(function()
	while true do
		local time = 5000
		if IsPedSwimmingUnderWater(GetPlayerPed(-1)) and in_scuba then
			oxygen = oxygen - 1
		end
		Citizen.Wait(time)
	end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- SISTEMA DE ENERGETICO
-----------------------------------------------------------------------------------------------------------------------------------------
function API.setEnergetico(status)
    setSprintBoost("energetico", status and energySprintMultiplier or nil)
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- SISTEMA DE USAR BANDAGEM
-----------------------------------------------------------------------------------------------------------------------------------------
local bandagem = false
local pascoa = false
local remedio = false
local tempoBandagem = 0
local oldHealth = 0
local prefix = 'Bandagem'

function API.useBandagem(bool, pr)
	prefix = pr

	if bool then
		if GetEntityHealth(PlayerPedId()) < 110 then return end
		bandagem = true
		tempoBandagem = 60
		oldHealth = GetEntityHealth(PlayerPedId())
	else
		if GetEntityHealth(PlayerPedId()) < 110 then return end
		pascoa = true
		tempopascoa = 70
		oldHealth = GetEntityHealth(PlayerPedId())
	end
end

function API.useMedical(status)
	if remedio then
		return
	end

	if GetEntityHealth(PlayerPedId()) < 110 then return end

	if status then
		remedio = true
		oldHealth = GetEntityHealth(PlayerPedId())
	else
		remedio = false
		oldHealth = GetEntityHealth(PlayerPedId())
	end
end

Citizen.CreateThread(function()
	while true do
		local time = 1000
		if bandagem then
			if GetEntityHealth(PlayerPedId()) > 250 then
				tempoBandagem = 0
				bandagem = false
				TriggerEvent("Notify", "negado",
					"<b>[" .. prefix .. "]</b> Você não pode utilizer com esse quantidade de vida.", 5)
			end

			tempoBandagem = tempoBandagem - 1

			if tempoBandagem <= 0 then
				tempoBandagem = 0
				bandagem = false
				TriggerEvent("Notify", "negado", "<b>[" .. prefix .. "]</b> acabou a bandagem..", 5)
			end

			-- if oldHealth > GetEntityHealth(PlayerPedId()) and bandagem then
			-- 	tempoBandagem = 0
			-- 	bandagem = false
			-- 	TriggerEvent("Notify","negado","<b>["..prefix.."]</b> Você sofreu algum dano.", 5)
			-- end

			if GetEntityHealth(PlayerPedId()) <= 105 and bandagem then
				tempoBandagem = 0
				bandagem = false
				TriggerEvent("Notify", "negado", "<b>[" .. prefix .. "]</b> Você morreu.", 5)
			end

			if GetEntityHealth(PlayerPedId()) > 105 and bandagem and GetEntityHealth(PlayerPedId()) < 250 then
				SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId()) + 2)
				if prefix == "Cogumelo" then
					SetPedArmour(PlayerPedId(), GetPedArmour(PlayerPedId()) + 2)
				end
			end

			if GetEntityHealth(PlayerPedId()) >= 250 and bandagem then
				tempoBandagem = 0
				bandagem = false
				SetEntityHealth(PlayerPedId(), 250)
				TriggerEvent("Notify", "negado", "<b>[" .. prefix .. "]</b> Vida cheia.", 5)
			end
		elseif pascoa then
			if GetEntityHealth(PlayerPedId()) > 250 then
				tempopascoa = 0
				pascoa = false
				TriggerEvent("Notify", "negado", "<b>[PASCOA]</b> Você não pode utilizer com esse quantidade de vida.", 5)
			end

			tempopascoa = tempopascoa - 1

			if tempopascoa <= 0 then
				tempopascoa = 0
				pascoa = false
				TriggerEvent("Notify", "negado", "<b>[PASCOA]</b> acabou o efeito..", 5)
			end

			if oldHealth > GetEntityHealth(PlayerPedId()) and pascoa then
				tempopascoa = 0
				pascoa = false
				TriggerEvent("Notify", "negado", "<b>[PASCOA]</b> Você sofreu algum dano.", 5)
			end

			if GetEntityHealth(PlayerPedId()) <= 105 and pascoa then
				tempopascoa = 0
				pascoa = false
				TriggerEvent("Notify", "negado", "<b>[PASCOA]</b> Você morreu.", 5)
			end

			if GetEntityHealth(PlayerPedId()) > 105 and pascoa and GetEntityHealth(PlayerPedId()) < 275 then
				SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId()) + 2)
			end

			if GetEntityHealth(PlayerPedId()) >= 275 and pascoa then
				tempopascoa = 0
				pascoa = false
				SetEntityHealth(PlayerPedId(), 275)
				TriggerEvent("Notify", "negado", "<b>[PASCOA]</b> Vida cheia.", 5)
			end
		elseif remedio then
			if GetEntityHealth(PlayerPedId()) > 300 then
				remedio = false
				TriggerEvent("Notify", "negado",
					"<b>[" .. prefix .. "]</b> Você não pode utilizer com esse quantidade de vida.", 5)
			end

			if GetEntityHealth(PlayerPedId()) >= 300 then
				remedio = false
				TriggerEvent("Notify", "negado", "Remedio finalizado", 5)
			end

			if oldHealth > GetEntityHealth(PlayerPedId()) and remedio then
				remedio = false
				TriggerEvent("Notify","negado","Você sofreu algum dano.", 5)
			end

			if GetEntityHealth(PlayerPedId()) <= 105 and remedio then
				remedio = false
				TriggerEvent("Notify", "negado", "Você morreu.", 5)
			end

			if GetEntityHealth(PlayerPedId()) > 105 and remedio and GetEntityHealth(PlayerPedId()) < 300 then
				SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId()) + 4)
			end

			if GetEntityHealth(PlayerPedId()) >= 300 and remedio then
				remedio = false
				SetEntityHealth(PlayerPedId(), 300)
				TriggerEvent("Notify", "negado", "Vida cheia.", 5)
			end
		end
		Citizen.Wait(time)
	end
end)

Citizen.CreateThread(function()
	while true do
		local time = 5000
		if bandagem or pascoa then
			oldHealth = GetEntityHealth(PlayerPedId())
		end

		Citizen.Wait(time)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SISTEMA DE ENCHER A GARRAFA
-----------------------------------------------------------------------------------------------------------------------------------------
function API.checkFountain()
	local waterSource = API.getWaterSource(false)
	if waterSource then return true, waterSource.style end
	return false
end

function API.startAnimHotwired()
	while not HasAnimDictLoaded("anim@amb@clubhouse@tutorial@bkr_tut_ig3@") do
		RequestAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@")
		Citizen.Wait(10)
	end
	TaskPlayAnim(PlayerPedId(), "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 3.0, 3.0, -1,
		49, 5.0, 0, 0, 0)
end

function API.getNearestRepairVehicle()
	local vehicle = vRP.getNearestVehicle(3)
	if vehicle and NetworkGetEntityIsNetworked(vehicle) then
		return VehToNet(vehicle)
	end
end

RegisterNetEvent('reparar')
AddEventHandler('reparar', function(vehicle)
	TriggerServerEvent("tryreparar", VehToNet(vehicle))
end)

RegisterNetEvent('syncreparar')
AddEventHandler('syncreparar', function(index)
	if NetworkDoesNetworkIdExist(index) then
		local v = NetToVeh(index)
		local fuel = GetVehicleFuelLevel(v)
		if DoesEntityExist(v) then
			if IsEntityAVehicle(v) then
				SetVehicleFixed(v)
				SetVehicleDirtLevel(v, 0.0)
				SetVehicleUndriveable(v, false)
				SetEntityAsMissionEntity(v, true, true)
				SetVehicleOnGroundProperly(v)
				SetVehicleFuelLevel(v, fuel)
			end
		end
	end
end)


function PtfxThis(asset)
	while not HasNamedPtfxAssetLoaded(asset) do
		RequestNamedPtfxAsset(asset)
		Wait(10)
	end
	UseParticleFxAssetNextCall(asset)
end

local Fireworks = nil
local Fireworkscreate = false
RegisterNetEvent('fireworks:use')
AddEventHandler('fireworks:use', function()
	local ped = PlayerPedId()
	local times = 20

	if Fireworkscreate then
		return
	end
	Fireworkscreate = true

	local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.5, 0.0)
	Fireworks = CreateObject(GetHashKey("ind_prop_firework_03"), coords.x, coords.y, coords.z, true, false, false)
	PlaceObjectOnGroundProperly(Fireworks)
	FreezeEntityPosition(Fireworks, true)
	Wait(8000)
	repeat
		PtfxThis("scr_indep_fireworks")
		StartNetworkedParticleFxNonLoopedAtCoord("scr_indep_firework_trailburst", GetEntityCoords(Fireworks), 0.0, 0.0,
			0.0, 1.0, false, false, false, false)
		time = times - 1
		Wait(2000)
	until times == 0

	DeleteEntity(Fireworks)
	Fireworkscreate = false
	Fireworks = nil
end)


-----------------------------------------------------------------------------------------------------------------------------------------
-- REPARAR PNEUS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent('repararpneus')
AddEventHandler('repararpneus', function(vehicle)
	if IsEntityAVehicle(vehicle) then
		TriggerServerEvent("tryrepararpneus", VehToNet(vehicle))
	end
end)

RegisterNetEvent('syncrepararpneus')
AddEventHandler('syncrepararpneus', function(index)
	if NetworkDoesNetworkIdExist(index) then
		local v = NetToEnt(index)
		if DoesEntityExist(v) then
			for i = 0, 8 do
				SetVehicleTyreFixed(v, i)
			end
		end
	end
end)
