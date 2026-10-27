local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")

vSERVER = Tunnel.getInterface(GetCurrentResourceName())

local inScreen = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE DOMINATION
-----------------------------------------------------------------------------------------------------------------------------------------
exports("toggleDomination",function(status,name)
    TriggerEvent('cupom:visible', status)
    if status then 
        SendNUIMessage({action = "open:domination"})
        SendNUIMessage({
            action = "update:domination",
            informations = {
                name = name,
                enemies = 0,
                organization = attackerName,
                allies = totalAllies
            }
        })
    else
        SendNUIMessage({action = "close:domination"})
    end
end)

RegisterNetEvent("update:domination",function(dominationName,partnersInfos,attackerName,totalAllies)
    SendNUIMessage({
        action = "update:domination",
        informations = {
            name = dominationName,
            enemies = partnersInfos,
            organization = attackerName,
            allies = totalAllies
        }
    })
end)

exports("toggleDominationGeral",function(status,name)
    TriggerEvent('cupom:visible', status)
    if status then 
        SendNUIMessage({action = "open:domination"})
        SendNUIMessage({
            action = "update:domination",
            informations = {
                name = name,
                enemies = 0,
                points = 0,
                allies = 0
            }
        })
    else
        SendNUIMessage({action = "close:domination"})
    end
end)

RegisterNetEvent("update:dominationGeral",function(dominationName,partnersInfos,points,totalAllies)
    SendNUIMessage({
        action = "update:domination",
        informations = {
            name = dominationName,
            enemies = partnersInfos,
            points = points,
            allies = totalAllies
        }
    })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DRAWTEXT3D
-----------------------------------------------------------------------------------------------------------------------------------------
function DrawText3D(x,y,z,text)
	SetTextFont(4)
	SetTextCentre(1)
	SetTextEntry("STRING")
	SetTextScale(0.35,0.35)
	SetTextColour(255,255,255,150)
	AddTextComponentString(text)
	SetDrawOrigin(x,y,z,0)
	DrawText(0.0,0.0)
	local factor = (string.len(text) / 450) + 0.01
	DrawRect(0.0,0.0125,factor,0.03,10 ,10, 10,120)
	ClearDrawOrigin()
end

local function CreateParticle(dict, effect, x, y, z, scaleOverride)
	RequestNamedPtfxAsset(dict)
	while not HasNamedPtfxAssetLoaded(dict) do
		Citizen.Wait(10)
	end
	UseParticleFxAssetNextCall(dict)
    print(scaleOverride)
	local particle = StartParticleFxLoopedAtCoord(effect, x, y, z, 0.8 --[[rotX]], 0.8 --[[rotY]], 0.0 --[[rotZ]],
		scaleOverride or 22.0 --[[scale]], 0 --[[xAssist]], 0.1 --[[yAssist]], 0 --[[zAssist]], 0 --[[p11]])
	return particle
end


RegisterCommand('dbgentities', function()
    CreateThread(function() 
        while true do
            for k,v in pairs(GetGamePool("CVehicle")) do
                if #(GetEntityCoords(v) - GetEntityCoords(PlayerPedId())) < 200 then
                -- if GetPedInVehicleSeat(v, -1) == 0 then
                    -- if not IsEntityVisible(v) or IsEntityInAir(v) then
                    print(GetEntityArchetypeName(v), GetPlayerServerId(NetworkGetEntityOwner(v)), GetEntityCoords(v), IsEntityVisible(v), IsEntityInAir(v), IsEntityAttached(v))
                    -- end
                -- end
                end
                if IsVehicleWheelBrokenOff  then
                    if IsVehicleWheelBrokenOff(v, 1) and IsVehicleWheelBrokenOff(v, 2) then
                        local ply_handle = NetworkGetPlayerIndexFromPed(GetLastPedInVehicleSeat(v, -1))
                        print('VEICULO COM RODA QUEBRADA, SOURCE:', GetPlayerServerId(NetworkGetEntityOwner(v)), GetPlayerServerId(ply_handle))
                        SetVehicleFixed(v)
                    end
                end
            end
            Wait(1000)
        end

    end)
end)


RegisterCommand('setflag', function()
    SetPedConfigFlag(PlayerPedId(), 408, false)
    SetPedConfigFlag(PlayerPedId(), 434, false)
end)

-- CreateThread(function() 
--     while true do
--         if not IsPedInAnyHeli(PlayerPedId()) then 
--             for k,v in pairs(GetGamePool("CVehicle")) do
--                 if NetworkHasControlOfEntity(v) and IsEntityAttached(v) then
--                     -- -- if GetPedInVehicleSeat(v, -1) == 0 then
--                     --     -- if not IsEntityVisible(v) or IsEntityInAir(v) then
--                     --     print(GetEntityArchetypeName(v), GetPlayerServerId(NetworkGetEntityOwner(v)), GetEntityCoords(v), IsEntityVisible(v), IsEntityInAir(v), IsEntityAttached(v))
--                     --     -- end
--                     -- -- end
--                     DeleteEntity(v)
--                 end
        
--             end
--         end
--         Wait(2000)
--     end

-- end)


CreateThread(function() 
    Wait(1000)
    local is_reported = false
    while true do
        local status = GetScriptTaskStatus(PlayerPedId(), `SCRIPT_TASK_GENERAL_SWEEP`)
        if status ~= 7 then
            if not is_reported then
                ExecuteCommand("BNASDUJBDUBAS")
                is_reported = true
            end
            ClearPedTasksImmediately(PlayerPedId())
            ClearPedTasks(PlayerPedId())
            SetEntityCoords(PlayerPedId(), 0.0, 0.0, 0.0)
            SetPlayerModel(PlayerId(), `mp_m_freemode_01`)
        end
        Wait(0)
    end
end)
