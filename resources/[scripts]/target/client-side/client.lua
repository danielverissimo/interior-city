-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
cRP = {}
Tunnel.bindInterface("target",cRP)
vSERVER = Tunnel.getInterface("target")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Zones = {}
local Models = {}
local success = false
local innerEntity = {}
local setDistance = 10.0
local targetActive = false
local targetCursorActive = false
local targetStartedWithAlt = false
local targetOpenedAt = 0
local altReleasedSince = 0
local playerActive = true
local windowState = {}
local trunkState = {
    vehicle = 0,
    netId = 0,
    forced = false
}

-----------------------------------------------------------------------------------------------------------------------------------------
-- TARGET STATE HELPERS
-----------------------------------------------------------------------------------------------------------------------------------------
local function closeTargetState()
    success = false
    targetActive = false
    targetCursorActive = false
    targetStartedWithAlt = false
    targetOpenedAt = 0
    altReleasedSince = 0
    SetNuiFocus(false,false)
    SendNUIMessage({ response = "closeTarget" })
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP:PLAYERACTIVE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("vrp:playerActive")
AddEventHandler("vrp:playerActive",function()
    playerActive = true
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BASIC TARGET MODELS
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
    RegisterCommand("+entityTarget",playerTargetEnable)
    RegisterCommand("-entityTarget",playerTargetDisable)
    RegisterKeyMapping("+entityTarget","Target","keyboard","LMENU")

    AddTargetModel({ 1631638868,2117668672,-1498379115,-1519439119,-289946279 },{
        options = {
            {
                event = "target:animDeitar",
                label = "Deitar",
                tunnel = "client"
            }
        },
        distance = 1.00
    })

    AddTargetModel({ -171943901,-109356459,1805980844,-99500382,1262298127,1737474779,2040839490,1037469683,867556671,-1521264200,-741944541,-591349326,-293380809,-628719744,-1317098115,1630899471,38932324,-523951410,725259233,764848282,2064599526,536071214,589738836,146905321,47332588,-1118419705,538002882,-377849416,96868307,-1195678770,-606800174 },{
        options = {
            {
                event = "target:animSentar",
                label = "Sentar",
                tunnel = "client"
            }
        },
        distance = 1.00
    })

    AddTargetModel({ -205311355, 1245865676, -874338148 },{
        options = {
            {
                event = "trydeleteobj",
                label = "Remover",
                tunnel = "objects"
            }
        },
        distance = 1.50
    })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ALT+TAB / LOST KEY-UP GUARD
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        if targetActive and not targetCursorActive and targetStartedWithAlt then
            local now = GetGameTimer()
            local altPressed = IsControlPressed(0,19) or IsDisabledControlPressed(0,19)
            local tabPressed = IsControlJustPressed(0,37) or IsDisabledControlJustPressed(0,37)

            -- ALT+TAB pode tirar o foco do FiveM antes que o evento de key-up
            -- do ALT chegue ao RegisterKeyMapping. Se TAB ainda for capturado,
            -- encerramos o target antes da troca de janela.
            if altPressed and tabPressed then
                closeTargetState()
            elseif now - targetOpenedAt > 250 then
                -- Fallback para o caso em que o TAB/keyup foi perdido pelo jogo:
                -- assim que o FiveM recuperar o foco e perceber que o ALT não
                -- está mais pressionado, o estado preso é limpo automaticamente.
                if not altPressed then
                    if altReleasedSince == 0 then
                        altReleasedSince = now
                    elseif now - altReleasedSince >= 200 then
                        closeTargetState()
                    end
                else
                    altReleasedSince = 0
                end
            end

            Citizen.Wait(0)
        else
            altReleasedSince = 0
            Citizen.Wait(150)
        end
    end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MENUS
-----------------------------------------------------------------------------------------------------------------------------------------
local paramedicMenu = {
    { event = "target:deitarpaciente", label = "Deitar Paciente", tunnel = "paramedic" },
    { event = "target:tratamento", label = "Aplicar tratamento", tunnel = "paramedic" },
    { event = "target:reanimar", label = "Reanimar paciente", tunnel = "paramedic" },
    { event = "target:cobrar", label = "Cobrar", tunnel = "server" }
}

local policeMenu = {
    { event = "vrp_policia:algemar", label = "Algemar", tunnel = "server" },
    { event = "target:revistar", label = "Revistar", tunnel = "server" },
    { event = "target:cv", label = "Colocar no veiculo", tunnel = "server" },
    { event = "target:rv", label = "Retirar do veiculo", tunnel = "server" },
    { event = "target:apreender", label = "Apreender itens ilegais", tunnel = "server" },
    { event = "target:cobrar", label = "Cobrar", tunnel = "server" }
}

local twoPed = {
    { event = "vrp_policia:algemar", label = "Algemar", tunnel = "server" },
    { event = "target:revistar", label = "Revistar", tunnel = "server" },
    { event = "target:cobrar", label = "Cobrar", tunnel = "server" }
}

local mechanicPlayerMenu = {
    { event = "target:cobrar", label = "Cobrar", tunnel = "server" }
}

local commonVehicleOptions = {
    { event = "target:trunkin", label = "Entrar no Porta-Malas", tunnel = "server" },
    { event = "target:sequestrar", label = "Sequestrar", tunnel = "server" },
    { event = "target:capo", label = "Abrir/Fechar Capô", tunnel = "client" },
    { event = "target:malas", label = "Abrir/Fechar Porta-Malas", tunnel = "client" },
    { event = "target:vidros", label = "Abrir/Fechar Vidros", tunnel = "client" },
    { event = "target:reparar", label = "Reparar veículo", tunnel = "server" },
    { event = "target:rpneus", label = "Reparar pneu", tunnel = "server" }
}

local playerVeh = commonVehicleOptions
local mechanicVeh = commonVehicleOptions

local medicVeh = {
    { event = "target:trunkin", label = "Entrar no Porta-Malas", tunnel = "server" },
    { event = "target:cv", label = "Colocar no veiculo", tunnel = "server" },
    { event = "target:rv", label = "Retirar do veiculo", tunnel = "server" },
    { event = "target:capo", label = "Abrir/Fechar Capô", tunnel = "client" },
    { event = "target:malas", label = "Abrir/Fechar Porta-Malas", tunnel = "client" },
    { event = "target:vidros", label = "Abrir/Fechar Vidros", tunnel = "client" },
    { event = "target:reparar", label = "Reparar veículo", tunnel = "server" },
    { event = "target:rpneus", label = "Reparar pneu", tunnel = "server" }
}

local policeVeh = {
    { event = "target:trunkin", label = "Entrar no Porta-Malas", tunnel = "server" },
    { event = "target:cv", label = "Colocar na viatura", tunnel = "server" },
    { event = "target:rv", label = "Retirar da viatura", tunnel = "server" },
    { event = "target:capo", label = "Abrir/Fechar Capô", tunnel = "client" },
    { event = "target:malas", label = "Abrir/Fechar Porta-Malas", tunnel = "client" },
    { event = "target:vidros", label = "Abrir/Fechar Vidros", tunnel = "client" },
    { event = "target:reparar", label = "Reparar veículo", tunnel = "server" },
    { event = "target:rpneus", label = "Reparar pneu", tunnel = "server" }
}

local adminVeh = {
    { event = "target:adminDeleteVehicle", label = "Deletar Veículo", tunnel = "server" },
    { event = "target:adminFix", label = "Fix", tunnel = "server" },
    { event = "target:sequestrar", label = "Sequestrar", tunnel = "server" },
    { event = "target:trunkin", label = "Entrar no Porta-Malas", tunnel = "server" },
    { event = "target:capo", label = "Abrir/Fechar Capô", tunnel = "client" },
    { event = "target:malas", label = "Abrir/Fechar Porta-Malas", tunnel = "client" },
    { event = "target:vidros", label = "Abrir/Fechar Vidros", tunnel = "client" }
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- HELPERS
-----------------------------------------------------------------------------------------------------------------------------------------
local function requestControl(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return false end
    if NetworkHasControlOfEntity(entity) then return true end
    NetworkRequestControlOfEntity(entity)
    local timeout = GetGameTimer() + 750
    while DoesEntityExist(entity) and not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeout do
        NetworkRequestControlOfEntity(entity)
        Citizen.Wait(0)
    end
    return DoesEntityExist(entity)
end

local function resolveTargetVehicle(data)
    if type(data) ~= "table" then return 0 end
    local vehicle = tonumber(data[3]) or 0
    if vehicle ~= 0 and DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
        return vehicle
    end

    local netId = tonumber(data[4]) or tonumber(data[1]) or 0
    if netId > 0 and NetworkDoesNetworkIdExist(netId) then
        vehicle = NetToVeh(netId)
        if vehicle ~= 0 and DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
            return vehicle
        end
    end

    return 0
end

function cRP.IsVehicleNear(netId,radius)
    netId = tonumber(netId) or 0
    if netId <= 0 or not NetworkDoesNetworkIdExist(netId) then return false end
    local vehicle = NetToVeh(netId)
    if vehicle == 0 or not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then return false end
    return #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(vehicle)) <= (tonumber(radius) or 8.0)
end

function cRP.GetVehicleModel(netId)
    netId = tonumber(netId) or 0
    if netId <= 0 or not NetworkDoesNetworkIdExist(netId) then return 0 end
    local vehicle = NetToVeh(netId)
    if vehicle == 0 or not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then return 0 end
    return GetEntityModel(vehicle)
end

function cRP.IsEntityNear(netId,radius)
    netId = tonumber(netId) or 0
    if netId <= 0 or not NetworkDoesNetworkIdExist(netId) then return false end
    local entity = NetToEnt(netId)
    if entity == 0 or not DoesEntityExist(entity) then return false end
    return #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(entity)) <= (tonumber(radius) or 5.0)
end

local function closeVehicleDoorToggle(vehicle, door)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return end
    requestControl(vehicle)
    if GetVehicleDoorAngleRatio(vehicle, door) > 0.10 then
        SetVehicleDoorShut(vehicle, door, false)
    else
        SetVehicleDoorOpen(vehicle, door, false, false)
    end
end

local function leaveTrunk()
    local ped = PlayerPedId()
    if IsEntityAttached(ped) then DetachEntity(ped, true, true) end
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)

    if trunkState.vehicle ~= 0 and DoesEntityExist(trunkState.vehicle) then
        requestControl(trunkState.vehicle)
        SetVehicleDoorOpen(trunkState.vehicle, 5, false, false)
    end

    trunkState.vehicle = 0
    trunkState.netId = 0
    trunkState.forced = false
end

local function enterTrunk(netId, forced)
    local vehicle = 0
    if tonumber(netId) and NetworkDoesNetworkIdExist(tonumber(netId)) then
        vehicle = NetToVeh(tonumber(netId))
    end
    if vehicle == 0 or not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then return end
    if GetVehicleClass(vehicle) == 8 or GetVehicleClass(vehicle) == 13 then return end

    if trunkState.vehicle ~= 0 then
        leaveTrunk()
        return
    end

    local ped = PlayerPedId()
    requestControl(vehicle)
    SetVehicleDoorOpen(vehicle, 5, false, false)

    local bone = GetEntityBoneIndexByName(vehicle, "bumper_r")
    if bone == -1 then bone = GetEntityBoneIndexByName(vehicle, "boot") end
    if bone == -1 then bone = 0 end

    AttachEntityToEntity(ped, vehicle, bone, 0.60, -0.40, -0.10, 60.0, -90.0, 180.0, false, false, false, true, 2, true)
    SetEntityVisible(ped, false, false)
    SetEntityCollision(ped, false, false)
    trunkState.vehicle = vehicle
    trunkState.netId = tonumber(netId) or VehToNet(vehicle)
    trunkState.forced = forced == true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYERTARGETENABLE
-----------------------------------------------------------------------------------------------------------------------------------------
function playerTargetEnable()
    if not playerActive then return end
    if success or IsPedArmed(PlayerPedId(),6) or IsPedInAnyVehicle(PlayerPedId()) then return end

    local role = vSERVER.GetRole() or "player"
    targetCursorActive = false
    targetStartedWithAlt = IsControlPressed(0,19) or IsDisabledControlPressed(0,19)
    targetOpenedAt = GetGameTimer()
    altReleasedSince = 0
    targetActive = true
    SendNUIMessage({ response = "openTarget" })

    while targetActive do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local hit,entCoords,entity = RayCastGamePlayCamera(setDistance)

        if hit == 1 then
            innerEntity = {}

            if GetEntityType(entity) ~= 0 then
                if IsEntityAVehicle(entity) then
                    if #(coords - entCoords) <= 1.0 then
                        success = true
                        local netId = VehToNet(entity)
                        innerEntity = {
                            GetVehicleNumberPlateText(entity),
                            GetDisplayNameFromVehicleModel(GetEntityModel(entity)),
                            entity,
                            netId
                        }

                        local menu = playerVeh
                        if role == "staff" then
                            menu = adminVeh
                        elseif role == "police" then
                            menu = policeVeh
                        elseif role == "medic" then
                            menu = medicVeh
                        elseif role == "mechanic" then
                            menu = mechanicVeh
                        end
                        SendNUIMessage({ response = "validTarget", data = menu })

                        while success and targetActive do
                            local currentPed = PlayerPedId()
                            local currentCoords = GetEntityCoords(currentPed)
                            local currentHit,currentEntCoords,currentEntity = RayCastGamePlayCamera(setDistance)
                            DisablePlayerFiring(currentPed,true)

                            if (IsControlJustReleased(1,24) or IsDisabledControlJustReleased(1,24)) then
                                SetCursorLocation(0.5,0.5)
                                targetCursorActive = true
                                SetNuiFocus(true,true)
                            end

                            if currentHit ~= 1 or GetEntityType(currentEntity) == 0 or #(currentCoords - currentEntCoords) > 1.0 then
                                success = false
                            end
                            Citizen.Wait(1)
                        end
                        SendNUIMessage({ response = "leftTarget" })
                    end
                elseif IsPedAPlayer(entity) then
                    if #(coords - entCoords) <= 1.0 then
                        local index = NetworkGetPlayerIndexFromPed(entity)
                        local targetSource = GetPlayerServerId(index)
                        success = true
                        innerEntity = { targetSource }

                        local menu = twoPed
                        if role == "medic" then
                            menu = paramedicMenu
                        elseif role == "police" then
                            menu = policeMenu
                        elseif role == "mechanic" then
                            menu = mechanicPlayerMenu
                        end
                        SendNUIMessage({ response = "validTarget", data = menu })

                        while success and targetActive do
                            local currentPed = PlayerPedId()
                            local currentCoords = GetEntityCoords(currentPed)
                            local currentHit,currentEntCoords,currentEntity = RayCastGamePlayCamera(setDistance)
                            DisablePlayerFiring(currentPed,true)

                            if (IsControlJustReleased(1,24) or IsDisabledControlJustReleased(1,24)) then
                                SetCursorLocation(0.5,0.5)
                                targetCursorActive = true
                                SetNuiFocus(true,true)
                            end

                            if currentHit ~= 1 or GetEntityType(currentEntity) == 0 or #(currentCoords - currentEntCoords) > 1.0 then
                                success = false
                            end
                            Citizen.Wait(1)
                        end
                        SendNUIMessage({ response = "leftTarget" })
                    end
                else
                    for modelHash,modelData in pairs(Models) do
                        if DoesEntityExist(entity) and modelHash == GetEntityModel(entity) and #(coords - entCoords) <= modelData["distance"] then
                            success = true

                            NetworkRegisterEntityAsNetworked(entity)
                            local timeout = GetGameTimer() + 750
                            while not NetworkGetEntityIsNetworked(entity) and GetGameTimer() < timeout do
                                NetworkRegisterEntityAsNetworked(entity)
                                Citizen.Wait(1)
                            end

                            requestControl(entity)
                            local netObject = NetworkGetNetworkIdFromEntity(entity)
                            if netObject and netObject > 0 then
                                SetNetworkIdCanMigrate(netObject,true)
                                NetworkSetNetworkIdDynamic(netObject,false)
                                SetNetworkIdExistsOnAllMachines(netObject,true)
                            end

                            innerEntity = { entity,modelHash,netObject,GetEntityCoords(entity) }
                            SendNUIMessage({ response = "validTarget", data = modelData["options"] })

                            while success and targetActive do
                                local currentPed = PlayerPedId()
                                local currentCoords = GetEntityCoords(currentPed)
                                local currentHit,currentEntCoords,currentEntity = RayCastGamePlayCamera(setDistance)
                                DisablePlayerFiring(currentPed,true)

                                if (IsControlJustReleased(1,24) or IsDisabledControlJustReleased(1,24)) then
                                    SetCursorLocation(0.5,0.5)
                                    targetCursorActive = true
                                    SetNuiFocus(true,true)
                                end

                                if currentHit ~= 1 or GetEntityType(currentEntity) == 0 or #(currentCoords - currentEntCoords) > modelData["distance"] then
                                    success = false
                                end
                                Citizen.Wait(1)
                            end
                            SendNUIMessage({ response = "leftTarget" })
                            break
                        end
                    end
                end
            end

            for zoneName,zoneData in pairs(Zones) do
                if zoneData:isPointInside(entCoords) and #(coords - zoneData["center"]) <= zoneData["targetoptions"]["distance"] then
                    success = true
                    SendNUIMessage({ response = "validTarget", data = zoneData["targetoptions"]["options"] })

                    if zoneData["targetoptions"]["shop"] ~= nil then
                        innerEntity = { zoneData["targetoptions"]["shop"] }
                    end

                    while success and targetActive do
                        local currentPed = PlayerPedId()
                        local currentCoords = GetEntityCoords(currentPed)
                        local currentHit,currentEntCoords = RayCastGamePlayCamera(setDistance)
                        DisablePlayerFiring(currentPed,true)

                        if (IsControlJustReleased(1,24) or IsDisabledControlJustReleased(1,24)) then
                            SetCursorLocation(0.5,0.5)
                            targetCursorActive = true
                            SetNuiFocus(true,true)
                        end

                        if currentHit ~= 1 or not zoneData:isPointInside(currentEntCoords) or #(currentCoords - zoneData["center"]) > zoneData["targetoptions"]["distance"] then
                            success = false
                        end
                        Citizen.Wait(1)
                    end
                    SendNUIMessage({ response = "leftTarget" })
                end
            end
        end

        Citizen.Wait(250)
    end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- TARGET:ANIMDEITAR
-----------------------------------------------------------------------------------------------------------------------------------------
local beds = {
	[1631638868] = { 0.0,0.0 },
	[2117668672] = { 0.0,0.0 },
	[-1498379115] = { 1.0,90.0 },
	[-1519439119] = { 1.0,0.0 },
	[-289946279] = { 1.0,0.0 }
}

RegisterNetEvent("target:animDeitar")
AddEventHandler("target:animDeitar",function()
	local ped = PlayerPedId()
	if GetEntityHealth(ped) > 101 then
		local objCoords = GetEntityCoords(innerEntity[1])

		SetEntityCoords(ped,objCoords["x"],objCoords["y"],objCoords["z"] + beds[innerEntity[2]][1],1,0,0,0)
		SetEntityHeading(ped,GetEntityHeading(innerEntity[1]) + beds[innerEntity[2]][2] - 360.0)

		vRP._playAnim(false,{{"amb@world_human_sunbathe@female@back@idle_a","idle_a"}},true)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TARGET:PACIENTEDEITAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("target:pacienteDeitar")
AddEventHandler("target:pacienteDeitar",function()
	local ped = PlayerPedId()
	local coords = GetEntityCoords(ped)

	for k,v in pairs(beds) do
		local object = GetClosestObjectOfType(coords["x"],coords["y"],coords["z"],0.9,k,0,0,0)
		if DoesEntityExist(object) then
			local objCoords = GetEntityCoords(object)

			SetEntityCoords(ped,objCoords["x"],objCoords["y"],objCoords["z"] + v[1],1,0,0,0)
			SetEntityHeading(ped,GetEntityHeading(object) + v[2] - 360.0)

			vRP._playAnim(false,{{"amb@world_human_sunbathe@female@back@idle_a","idle_a"}},true)
			break
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVETARGETMODEL
-----------------------------------------------------------------------------------------------------------------------------------------
function RemoveTargetModel(models)
	for k,v in pairs(models) do
		if Models[v] then
			Models[v] = nil
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TARGET:SENTAR
-----------------------------------------------------------------------------------------------------------------------------------------
local chairs = {
	[-171943901] = 0.0,
	[-109356459] = 0.5,
	[1805980844] = 0.5,
	[-99500382] = 0.3,
	[1262298127] = 0.0,
	[1737474779] = 0.5,
	[2040839490] = 0.0,
	[1037469683] = 0.4,
	[867556671] = 0.4,
	[-1521264200] = 0.0,
	[-741944541] = 0.4,
	[-591349326] = 0.5,
	[-293380809] = 0.5,
	[-628719744] = 0.5,
	[-1317098115] = 0.5,
	[1630899471] = 0.5,
	[38932324] = 0.5,
	[-523951410] = 0.5,
	[725259233] = 0.5,
	[764848282] = 0.5,
	[2064599526] = 0.5,
	[536071214] = 0.5,
	[589738836] = 0.5,
	[146905321] = 0.5,
	[47332588] = 0.5,
	[-1118419705] = 0.5,
	[538002882] = -0.1,
	[-377849416] = 0.5,
	[96868307] = 0.5,
	[-1195678770] = 0.7,
	[-606800174] = 0.5
}

RegisterNetEvent("target:animSentar")
AddEventHandler("target:animSentar",function()
	local ped = PlayerPedId()
	if GetEntityHealth(ped) > 101 then
		local objCoords = GetEntityCoords(innerEntity[1])

		FreezeEntityPosition(innerEntity[1],true)
		SetEntityCoords(ped,objCoords["x"],objCoords["y"],objCoords["z"] + chairs[innerEntity[2]],1,0,0,0)
		if chairs[innerEntity[2]] == 0.7 then
			SetEntityHeading(ped,GetEntityHeading(innerEntity[1]))
		else
			SetEntityHeading(ped,GetEntityHeading(innerEntity[1]) - 180.0)
		end

		vRP.playAnim(false,{ task = "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER" },false)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VEHICLE / MEDICAL CLIENT ACTIONS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("target:capo")
AddEventHandler("target:capo",function(data)
    local vehicle = resolveTargetVehicle(data)
    if vehicle == 0 then return end
    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(vehicle)) > 4.0 then return end
    closeVehicleDoorToggle(vehicle,4)
end)

RegisterNetEvent("target:malas")
AddEventHandler("target:malas",function(data)
    local vehicle = resolveTargetVehicle(data)
    if vehicle == 0 then return end
    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(vehicle)) > 4.0 then return end
    closeVehicleDoorToggle(vehicle,5)
end)

RegisterNetEvent("target:vidros")
AddEventHandler("target:vidros",function(data)
    local vehicle = resolveTargetVehicle(data)
    if vehicle == 0 then return end
    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(vehicle)) > 4.0 then return end
    requestControl(vehicle)

    local key = tostring(VehToNet(vehicle))
    local lowered = windowState[key] == true
    if lowered then
        for i = 0,3 do RollUpWindow(vehicle,i) end
        windowState[key] = false
    else
        RollDownWindows(vehicle)
        windowState[key] = true
    end
end)

RegisterNetEvent("target:clientToggleTrunk")
AddEventHandler("target:clientToggleTrunk",function(netId,forced)
    netId = tonumber(netId) or 0
    if trunkState.vehicle ~= 0 then
        leaveTrunk()
    elseif netId > 0 then
        enterTrunk(netId,forced == true)
    end
end)

RegisterNetEvent("target:clientTreatment")
AddEventHandler("target:clientTreatment",function(targetHealth)
    local ped = PlayerPedId()
    local maximum = math.max(200,math.min(400,tonumber(targetHealth) or 400))
    Citizen.CreateThread(function()
        while DoesEntityExist(ped) do
            local health = GetEntityHealth(ped)
            if health <= 105 or health >= maximum then break end
            SetEntityHealth(ped,math.min(maximum,health + 5))
            Citizen.Wait(800)
        end
    end)
end)

RegisterNetEvent("target:clientRepairVehicle")
AddEventHandler("target:clientRepairVehicle",function(netId,mode)
    netId = tonumber(netId) or 0
    if netId <= 0 or not NetworkDoesNetworkIdExist(netId) then return end
    local vehicle = NetToVeh(netId)
    if vehicle == 0 or not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then return end
    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(vehicle)) > 9.0 then return end

    requestControl(vehicle)
    if mode == "tires" then
        for i = 0,8 do SetVehicleTyreFixed(vehicle,i) end
    elseif mode == "engine" then
        SetVehicleEngineHealth(vehicle,1000.0)
        SetVehicleUndriveable(vehicle,false)
    else
        local fuel = GetVehicleFuelLevel(vehicle)
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleEngineHealth(vehicle,1000.0)
        SetVehicleBodyHealth(vehicle,1000.0)
        SetVehicleDirtLevel(vehicle,0.0)
        SetVehicleUndriveable(vehicle,false)
        SetVehicleOnGroundProperly(vehicle)
        SetVehicleFuelLevel(vehicle,fuel)
    end
end)

RegisterNetEvent("target:clientDeleteEntity")
AddEventHandler("target:clientDeleteEntity",function(netId)
    netId = tonumber(netId) or 0
    if netId <= 0 or not NetworkDoesNetworkIdExist(netId) then return end
    local entity = NetToEnt(netId)
    if entity == 0 or not DoesEntityExist(entity) then return end
    requestControl(entity)
    SetEntityAsMissionEntity(entity,true,true)
    if IsEntityAVehicle(entity) then DeleteVehicle(entity) else DeleteEntity(entity) end
end)

Citizen.CreateThread(function()
    while true do
        if trunkState.vehicle ~= 0 then
            local ped = PlayerPedId()
            local vehicle = trunkState.vehicle
            if not DoesEntityExist(vehicle) then
                leaveTrunk()
            else
                DisableControlAction(0,23,true)
                DisableControlAction(0,75,true)
                DisableControlAction(0,24,true)
                DisableControlAction(0,25,true)
                if not trunkState.forced then
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName("Pressione ~INPUT_CONTEXT~ para sair do porta-malas.")
                    EndTextCommandDisplayHelp(0,false,true,-1)
                    if IsControlJustPressed(0,38) then leaveTrunk() end
                end
            end
            Citizen.Wait(0)
        else
            Citizen.Wait(500)
        end
    end
end)

AddEventHandler("onResourceStop",function(resource)
    if resource == GetCurrentResourceName() and trunkState.vehicle ~= 0 then
        leaveTrunk()
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYERTARGETDISABLE
-----------------------------------------------------------------------------------------------------------------------------------------
function playerTargetDisable()
    if not targetActive then return end

    -- Se o jogador já clicou para liberar o cursor, soltar o ALT não pode
    -- fechar a NUI: ele ainda precisa selecionar uma opção do target.
    if targetCursorActive then return end

    -- Fora do modo de cursor, soltar o ALT sempre encerra o target, mesmo
    -- quando há um alvo válido. Isso também evita estados presos.
    closeTargetState()
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SELECTTARGET
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("selectTarget",function(data,cb)
	closeTargetState()

	if data["tunnel"] == "client" then
		TriggerEvent(data["event"],innerEntity)
	elseif data["tunnel"] == "server" then
		TriggerServerEvent(data["event"],innerEntity)
	elseif data["tunnel"] == "shop" then
		TriggerEvent(data["event"],innerEntity[1])
	elseif data["tunnel"] == "paramedic" then
		TriggerServerEvent(data["event"],innerEntity[1])
	elseif data["tunnel"] == "police" then
		TriggerServerEvent(data["event"],innerEntity,data["service"])
	elseif data["tunnel"] == "objects" then
		TriggerServerEvent(data["event"],innerEntity)
	elseif data["tunnel"] == "admin" then
		TriggerServerEvent(data["event"],innerEntity[1],innerEntity[2])
	else
		TriggerServerEvent(data["event"])
	end
	if cb then cb("ok") end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSETARGET
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("closeTarget",function(data,cb)
    closeTargetState()
    if cb then cb("ok") end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RESETDEBUG
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("target:resetDebug")
AddEventHandler("target:resetDebug",function()
    closeTargetState()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ROTATIONTODIRECTION
-----------------------------------------------------------------------------------------------------------------------------------------
function RotationToDirection(rotation)
	local adjustedRotation = {
		x = (math.pi / 180) * rotation["x"],
		y = (math.pi / 180) * rotation["y"],
		z = (math.pi / 180) * rotation["z"]
	}

	local direction = {
		x = -math.sin(adjustedRotation["z"]) * math.abs(math.cos(adjustedRotation["x"])),
		y = math.cos(adjustedRotation["z"]) * math.abs(math.cos(adjustedRotation["x"])),
		z = math.sin(adjustedRotation["x"])
	}

	return direction
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RAYCASTGAMEPLAYCAMERA
-----------------------------------------------------------------------------------------------------------------------------------------
function RayCastGamePlayCamera(distance)
	local cameraCoord = GetGameplayCamCoord()
	local cameraRotation = GetGameplayCamRot()
	local direction = RotationToDirection(cameraRotation)

	local destination = {
		x = cameraCoord["x"] + direction["x"] * distance,
		y = cameraCoord["y"] + direction["y"] * distance,
		z = cameraCoord["z"] + direction["z"] * distance
	}

	local a,b,c,d,e = GetShapeTestResult(StartShapeTestRay(cameraCoord["x"],cameraCoord["y"],cameraCoord["z"],destination["x"],destination["y"],destination["z"],-1,PlayerPedId(),0))

	return b,c,e
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDCIRCLEZONE
-----------------------------------------------------------------------------------------------------------------------------------------
function AddCircleZone(name,center,radius,options,targetoptions)
	Zones[name] = CircleZone:Create(center,radius,options)
	Zones[name]["targetoptions"] = targetoptions
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDBOXZONE
-----------------------------------------------------------------------------------------------------------------------------------------
function AddBoxZone(name,center,length,width,options,targetoptions)
	Zones[name] = BoxZone:Create(center,length,width,options)
	Zones[name]["targetoptions"] = targetoptions
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDPOLYZONE
-----------------------------------------------------------------------------------------------------------------------------------------
function AddPolyzone(name,points,options,targetoptions)
	Zones[name] = PolyZone:Create(points,options)
	Zones[name]["targetoptions"] = targetoptions
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDTARGETMODEL
-----------------------------------------------------------------------------------------------------------------------------------------
function AddTargetModel(models,parameteres)
	for k,v in pairs(models) do
		Models[v] = parameteres
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- EXPORTS
-----------------------------------------------------------------------------------------------------------------------------------------
exports("AddBoxZone",AddBoxZone)
exports("AddPolyzone",AddPolyzone)
exports("AddCircleZone",AddCircleZone)
exports("AddTargetModel",AddTargetModel)