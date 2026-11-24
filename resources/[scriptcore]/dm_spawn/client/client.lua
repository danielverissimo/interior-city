state = {
    isOpen = false,
    camera = nil
}

Citizen.CreateThread(function ()
    print('Script iniciado.')
end)

RegisterNUICallback('close', function(_, cb) cb(false) end)

RegisterNUICallback('ready', function(_, cb)
    cb(true)
    if state.isOpen then
        SendNUIMessage({ action = 'open' })
        SetNuiFocus(true, true)
    end
end)

RegisterNUICallback('getSpawns', function(_, cb)
    cb({ spawns = Config.Spawns })
end)

RegisterNUICallback('spawn', function(_, cb)
    local spawn = Config.Spawns[1]
    _G.Teleporting = true
    StartFade()
    -- vRP._teleport(spawn.coords[1], spawn.coords[2], spawn.coords[3])
    CloseUi()
    Citizen.Wait(1300)
    SetEntityCoords(PlayerPedId(), spawn.coords[1], spawn.coords[2], spawn.coords[3])

    Citizen.Wait(1000)
    EndFade()
    TriggerEvent("flaviin:toggleHud",true)

    SetTimeout(10*1000,function()
		local ped = PlayerPedId()
		SetEntityHealth(ped,300)
	end)
    cb(true)
end)


RegisterNUICallback('lastSpawn', function(data, cb)
    local data = Remote.GetUserData()
    if not data or not data.position then
        cb(false)
        return
    end
    _G.Teleporting = true

    print(data.position,'linha 51')

    local position = data and {data.position.x, data.position.y, data.position.z} or {x = -425.07, y = 1125.78, z = 325.86}
    StartFade()
    -- vRP._teleport(position[1],position[2],position[3])
    CloseUi()
    Citizen.Wait(1300)

    SetEntityCoords(PlayerPedId(), position[1], position[2], position[3])
    
    Citizen.Wait(1000)
    EndFade()
	TriggerEvent("flaviin:toggleHud",true)
    
    SetFocusEntity(PlayerPedId())
    -- CreateThread(function()
    --     Wait(3000)
    --     TriggerEvent('checkIsInDomination')
    -- end)

    SetTimeout(10*1000,function()
		local ped = PlayerPedId()
		SetEntityHealth(ped,300)
	end)

    cb(true)
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- TOGGLE LOGIN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent('vrp:ToogleLoginMenu')
AddEventHandler('vrp:ToogleLoginMenu', function()
    OpenUi()
end) 
