local pending, serial, sessionId = {}, 0, nil
local opened, publicOpen = false, false
local resource = GetCurrentResourceName()

local function closeUI()
    opened, publicOpen = false, false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'close' })
end

local function failure(id, code, message)
    return { requestId = id, ok = false, error = { code = code, message = message } }
end

local function request(method, payload, cb, requestedId)
    serial = serial + 1
    local id = requestedId or ('%s:%s'):format(GetGameTimer(), serial)
    if type(method) ~= 'string' or #method > 64 or type(payload) ~= 'table' or type(id) ~= 'string' or #id > 96 then
        cb(failure(id, 'INVALID_REQUEST', 'Solicitação inválida.')); return
    end
    if pending[id] then cb(failure(id, 'BUSY', 'Solicitação já enviada.')); return end
    pending[id] = cb
    TriggerServerEvent('ic_admin:request', { requestId = id, method = method, payload = payload, sessionId = sessionId })
    SetTimeout(20000, function()
        local callback = pending[id]
        if callback then
            pending[id] = nil
            callback(failure(id, 'TIMEOUT', 'Sem resposta. Consulte os dados antes de repetir a operação.'))
        end
    end)
end

RegisterNetEvent('ic_admin:response', function(response)
    if source ~= 65535 or type(response) ~= 'table' then return end
    local callback = pending[response.requestId]
    if not callback then return end
    pending[response.requestId] = nil
    if response.ok and type(response.data) == 'table' and response.data.sessionId then
        sessionId = response.data.sessionId
    elseif not response.ok and response.error and (response.error.code == 'SESSION_EXPIRED' or response.error.code == 'UNAUTHENTICATED') then
        sessionId = nil
        closeUI()
    end
    callback(response)
end)

local function openUI()
    if opened or publicOpen then closeUI(); return end
    request('bootstrap', {}, function(result)
        if not result.ok then
            TriggerEvent('Notify', 'negado', result.error and result.error.message or 'Acesso indisponível.', 5000)
            return
        end
        opened = true
        SetNuiFocus(true, true)
        SendNUIMessage({ type = 'open', payload = result.data })
    end)
end

local function publicSession(callback)
    if sessionId then callback(true); return end
    request('player.bootstrap', {}, function(result)
        if not result.ok then
            TriggerEvent('Notify', 'negado', result.error and result.error.message or 'Serviço indisponível.', 5000)
        end
        callback(result.ok == true)
    end)
end

RegisterCommand('icadmin', openUI, false)
RegisterCommand('+ic_admin_open', openUI, false)
RegisterCommand('-ic_admin_open', function() end, false)
RegisterKeyMapping('+ic_admin_open', 'Abrir IC Admin', 'keyboard', 'F10')
if GetConvar('ic_admin_mode', 'preview') == 'active' then
    RegisterCommand('padm', openUI, false)
    RegisterCommand('+ic_admin_legacy_open', openUI, false)
    RegisterCommand('-ic_admin_legacy_open', function() end, false)
    RegisterKeyMapping('+ic_admin_legacy_open', 'Abrir IC Admin (Insert)', 'keyboard', 'INSERT')
end

RegisterCommand('icchamado', function()
    publicSession(function(ok)
        if not ok then return end
        publicOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ type = 'publicCalls' })
    end)
end, false)
if GetConvar('ic_admin_mode', 'preview') == 'active' then
    RegisterCommand('+ic_admin_call', function() ExecuteCommand('icchamado') end, false)
    RegisterCommand('-ic_admin_call', function() end, false)
    RegisterKeyMapping('+ic_admin_call', 'Chamar atendimento da cidade', 'keyboard', 'F5')
end
RegisterCommand('icchamados', function()
    publicSession(function(ok)
        if not ok then return end
        publicOpen = true; SetNuiFocus(true, true)
        SendNUIMessage({ type = 'publicCallsList' })
    end)
end, false)
RegisterCommand('icvip', function()
    publicSession(function(ok)
        if not ok then return end
        request('vip.mine', {}, function(result)
            if not result.ok then return end
            for _, entry in ipairs(result.data.assignments or {}) do
                if tonumber(entry.remaining) and entry.remaining > 0 then
                    publicOpen = true; SetNuiFocus(true, true)
                    SendNUIMessage({ type = 'vipChoice', payload = entry }); return
                end
            end
            TriggerEvent('Notify', 'aviso', 'Você não possui escolhas VIP pendentes.', 5000)
        end)
    end)
end, false)

RegisterNUICallback('rpc', function(data, cb)
    if type(data) ~= 'table' then cb(failure('', 'INVALID_REQUEST', 'Solicitação inválida.')); return end
    if data.method == 'ui.close' then closeUI(); cb({ ok = true, data = {} }); return end
    if data.method == 'position.capture' then
        local coords = GetEntityCoords(PlayerPedId())
        cb({ ok = true, data = { x = coords.x, y = coords.y, z = coords.z, heading = GetEntityHeading(PlayerPedId()) } }); return
    end
    request(data.method, data.payload or {}, cb, data.requestId)
end)

RegisterNUICallback('monitorSignal', function(data, cb)
    if type(data) == 'table' and type(data.token) == 'string' and type(data.kind) == 'string' then
        TriggerServerEvent('ic_admin:monitorSignal', data.token, data.kind, data.payload or {})
    end
    cb({ ok = true })
end)
RegisterNUICallback('monitorFrame', function(data, cb)
    if type(data) == 'table' and type(data.token) == 'string' and type(data.frame) == 'string' and #data.frame <= 900000 then
        TriggerLatentServerEvent('ic_admin:monitorFrame', 2500000, data.token, tonumber(data.sequence) or 0, data.frame)
    end
    cb({ ok = true })
end)

local function serverEvent(event, callback)
    RegisterNetEvent(event, function(...)
        if source ~= 65535 then return end
        callback(...)
    end)
end

serverEvent('ic_admin:sessionClosed', function()
    sessionId = nil
    closeUI()
    for id, cb in pairs(pending) do
        pending[id] = nil
        cb(failure(id, 'SESSION_CLOSED', 'A sessão administrativa foi encerrada.'))
    end
end)
for _, event in ipairs({ 'notice', 'callNotice', 'vipChoice', 'punishment', 'monitorMessage' }) do
    serverEvent('ic_admin:' .. event, function(data)
        if event == 'vipChoice' and data and data.assignmentId then
            publicSession(function(ok)
                if not ok then return end
                publicOpen = true; SetNuiFocus(true, true)
                SendNUIMessage({ type = event, payload = data })
            end)
        else SendNUIMessage({ type = event, payload = data }) end
    end)
end

local function vehicleNearPlayer()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        local c = GetEntityCoords(ped)
        vehicle = GetClosestVehicle(c.x, c.y, c.z, 8.0, 0, 70)
    end
    return vehicle
end

local vipTest = nil
local function stopVipTest()
    if not vipTest then return end
    local previous = vipTest; vipTest = nil
    if DoesEntityExist(previous.vehicle) then DeleteEntity(previous.vehicle) end
    if previous.returnCoords then
        local p = previous.returnCoords
        SetEntityCoordsNoOffset(PlayerPedId(), p.x or p[1], p.y or p[2], p.z or p[3], false, false, false)
    end
    SendNUIMessage({ type = 'vipTestEnded' })
end

serverEvent('ic_admin:clientAction', function(action, data)
    data = type(data) == 'table' and data or {}
    local ped = PlayerPedId()
    if action == 'teleport' then
        local p = data.coords or data
        if tonumber(p.x or p[1]) and tonumber(p.y or p[2]) and tonumber(p.z or p[3]) then
            SetEntityCoordsNoOffset(ped, p.x or p[1], p.y or p[2], p.z or p[3], false, false, false)
            if p.heading then SetEntityHeading(ped, p.heading) end
        end
    elseif action == 'revive' or action == 'god' then
        TriggerEvent('m_survival:forceAliveFromEvent', false)
        local c = GetEntityCoords(ped)
        NetworkResurrectLocalPlayer(c.x, c.y, c.z, GetEntityHeading(ped), true, false)
        SetEntityHealth(ped, 400); ClearPedBloodDamage(ped); ClearPedTasksImmediately(ped)
    elseif action == 'kill' then SetEntityHealth(ped, 0)
    elseif action == 'freeze' or action == 'unfreeze' then FreezeEntityPosition(ped, action == 'freeze')
    elseif action == 'clear_weapons' then RemoveAllPedWeapons(ped, true)
    elseif action == 'tpway' then
        local waypoint = GetFirstBlipInfoId(8)
        if DoesBlipExist(waypoint) then
            local c = GetBlipInfoIdCoord(waypoint)
            local vehicle = GetVehiclePedIsIn(ped, false)
            local entity = vehicle ~= 0 and vehicle or ped
            FreezeEntityPosition(entity, true)
            local found, ground = false, 1000.0
            for h = 1000, 0, -50 do
                RequestCollisionAtCoord(c.x, c.y, h + 0.0)
                SetEntityCoordsNoOffset(entity, c.x, c.y, h + 0.0, false, false, false)
                Wait(20)
                found, ground = GetGroundZFor_3dCoord(c.x, c.y, h + 0.0, false)
                if found then break end
            end
            SetEntityCoordsNoOffset(entity, c.x, c.y, found and ground + 1.0 or 100.0, false, false, false)
            FreezeEntityPosition(entity, false)
        end
    elseif action == 'spawnVehicle' or action == 'spawn_veh' or action == 'vipTest' then
        closeUI()
        local name = data.vehicle or data.spawn
        if type(name) ~= 'string' or #name > 80 then return end
        local model = GetHashKey(name)
        if not IsModelInCdimage(model) or not IsModelAVehicle(model) then return end
        RequestModel(model)
        local timeout = GetGameTimer() + 10000
        while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(20) end
        if not HasModelLoaded(model) then return end
        local c = GetOffsetFromEntityInWorldCoords(ped, 0.0, 3.0, 0.0)
        local vehicle = CreateVehicle(model, c.x, c.y, c.z, GetEntityHeading(ped), true, false)
        SetModelAsNoLongerNeeded(model)
        if vehicle ~= 0 then
            SetPedIntoVehicle(ped, vehicle, -1)
            SetVehicleOnGroundProperly(vehicle)
            if action == 'vipTest' then
                stopVipTest()
                vipTest = { vehicle = vehicle, token = data.token, returnCoords = data.returnCoords }
                local identity = vipTest
                SetTimeout(math.min(300, tonumber(data.seconds) or 60) * 1000, function()
                    if vipTest == identity then
                        request('vip.test', { mode = 'finish', token = data.token }, function() end)
                        stopVipTest()
                    end
                end)
            end
        end
    elseif action == 'vipTestStop' then stopVipTest()
    elseif action == 'fix' or action == 'tuning' or action == 'dv' or action == 'hash' then
        local vehicle = vehicleNearPlayer()
        if vehicle == 0 then return end
        NetworkRequestControlOfEntity(vehicle)
        local untilAt = GetGameTimer() + 1500
        while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < untilAt do Wait(0) end
        if not NetworkHasControlOfEntity(vehicle) then return end
        if action == 'fix' then SetVehicleFixed(vehicle); SetVehicleDirtLevel(vehicle, 0.0)
        elseif action == 'dv' then SetEntityAsMissionEntity(vehicle, true, true); DeleteEntity(vehicle)
        elseif action == 'tuning' then
            SetVehicleModKit(vehicle, 0)
            for _, index in ipairs({ 11, 12, 13, 15, 16 }) do SetVehicleMod(vehicle, index, GetNumVehicleMods(vehicle, index) - 1, false) end
            ToggleVehicleMod(vehicle, 18, true)
        elseif action == 'hash' then
            SendNUIMessage({ type = 'notice', payload = { message = ('Veículo: %s · hash %s'):format(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)), GetEntityModel(vehicle)), seconds = 10 } })
        end
    end
end)

local environment = nil
serverEvent('ic_admin:environment', function(data) environment = data; SendNUIMessage({ type = 'environment', payload = data }) end)
CreateThread(function()
    while true do
        if environment and GetConvar('ic_admin_mode', 'preview') == 'active' then
            local e = environment
            local hour = tonumber(e.hour) or math.floor((tonumber(e.minuteOfDay) or 720) / 60)
            local minute = tonumber(e.minute) or ((tonumber(e.minuteOfDay) or 720) % 60)
            NetworkOverrideClockTime(hour, minute, 0)
            if type(e.weather) == 'string' then SetWeatherTypeNowPersist(e.weather) end
        end
        Wait(1000)
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= resource then return end
    closeUI(); stopVipTest()
    FreezeEntityPosition(PlayerPedId(), false)
    for id, cb in pairs(pending) do cb(failure(id, 'STOPPED', 'O painel foi reiniciado.')) end
    pending = {}
end)
