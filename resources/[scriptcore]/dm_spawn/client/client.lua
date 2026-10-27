state = {
    isOpen = false,
    camera = nil
}

Citizen.CreateThread(function ()
    print('Script iniciado.')
end)

local function teleportToResolvedSpawn(coords)
    if type(coords) ~= "table" or not coords[1] or not coords[2] or not coords[3] then
        return false
    end

    local ped = PlayerPedId()
    local x, y, z = coords[1] + 0.0, coords[2] + 0.0, coords[3] + 0.0

    FreezeEntityPosition(ped, true)
    RequestCollisionAtCoord(x, y, z)
    SetFocusPosAndVel(x, y, z, 0.0, 0.0, 0.0)
    SetEntityCoords(ped, x, y, z, false, false, false, false)

    local timeout = GetGameTimer() + 4000
    while GetGameTimer() < timeout and not HasCollisionLoadedAroundEntity(ped) do
        RequestCollisionAtCoord(x, y, z)
        Citizen.Wait(50)
    end

    SetEntityCoords(ped, x, y, z, false, false, false, false)
    FreezeEntityPosition(ped, false)
    ClearFocus()
    SetFocusEntity(ped)
    return true
end

RegisterNUICallback('close', function(_, cb) cb(false) end)

RegisterNUICallback('getSpawns', function(data, cb)
    local context = Remote.getSpawnContext() or {}
    cb({
        hasOrg = context.hasOrg == true,
        hasHome = context.hasHome == true,
        spawns = Config.Spawns
    })
end)
RegisterNUICallback("home", function(data, cb)
    local home = Remote.getHomeSpawn()
    local coords = home and home.coords or nil
    if not coords or not coords[1] or not coords[2] or not coords[3] then
        TriggerEvent("Notify", "negado", "Você não possui uma mansão disponível para nascer.", 5000)
        cb(false)
        return
    end

    _G.Teleporting = true
    StartFade()
    CloseUi()
    Citizen.Wait(1300)

    teleportToResolvedSpawn(coords)

    Citizen.Wait(1000)
    EndFade()
    TriggerEvent("flaviin:toggleHud", true)

    SetFocusEntity(PlayerPedId())
    CreateThread(function()
        Wait(3000)
        TriggerEvent('checkIsInDomination')
    end)

    SetTimeout(10 * 1000, function()
        local ped = PlayerPedId()
        SetEntityHealth(ped, 300)
    end)

    cb(true)
end)

RegisterNUICallback('spawn', function(data, cb)
    local spawn = data.spawn
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
    CreateThread(function()
        Wait(3000)
        TriggerEvent('checkIsInDomination')
    end)

    SetTimeout(10*1000,function()
		local ped = PlayerPedId()
		SetEntityHealth(ped,300)
	end)

    cb(true)
end)

RegisterNUICallback('org', function(data, cb)
    local org = Remote.getOrgSpawn()
    local coords = org and org.coords or nil
    if not coords or not coords[1] or not coords[2] or not coords[3] then
        TriggerEvent("Notify", "negado", "Não foi possível localizar o ponto da sua facção.", 5000)
        cb(false)
        return
    end

    _G.Teleporting = true
    StartFade()
    CloseUi()
    Citizen.Wait(1300)

    teleportToResolvedSpawn(coords)

    Citizen.Wait(1000)
    EndFade()
    TriggerEvent("flaviin:toggleHud", true)

    SetFocusEntity(PlayerPedId())
    CreateThread(function()
        Wait(3000)
        TriggerEvent('checkIsInDomination')
    end)

    SetTimeout(10 * 1000, function()
        local ped = PlayerPedId()
        SetEntityHealth(ped, 300)
    end)

    cb(true)
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- TOGGLE LOGIN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent('vrp:ToogleLoginMenu')
AddEventHandler('vrp:ToogleLoginMenu', function()
    if not state.isOpen then
        OpenUi()
    else
        CloseUi()
    end
end) 