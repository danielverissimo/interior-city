local activeToken

local function finish(success)
    local token = activeToken
    if not token then return end
    activeToken = nil
    SendNUIMessage({action='lockpickClose', token=token})
    SetNuiFocus(false, false)
    TriggerEvent('m_robbernpc:releaseLockpick')
    TriggerServerEvent('m_robbernpc:lockpickResult', token, success == true)
end

RegisterNetEvent('m_robbernpc:lockpickStart', function(netId, token, speed)
    if activeToken then finish(false) end
    activeToken = token
    SetNuiFocus(true, false)
    SendNUIMessage({action='lockpickOpen', token=token, speed=speed})
    SetTimeout(26000, function() if activeToken == token then finish(false) end end)
    TriggerEvent('m_robbernpc:attemptStarted', netId)
end)

RegisterNUICallback('lockpickResult', function(data, cb)
    if type(data) == 'table' and data.token == activeToken then finish(data.success == true) end
    cb({ok=true})
end)

RegisterNetEvent('m_robbernpc:lockpickClose', function(token)
    if activeToken ~= token then return end
    activeToken = nil
    SendNUIMessage({action='lockpickClose', token=token})
    SetNuiFocus(false, false)
    TriggerEvent('m_robbernpc:releaseLockpick')
end)

AddEventHandler('m_robbernpc:attemptEnded', function()
    if activeToken then finish(false) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    activeToken = nil
    SetNuiFocus(false, false)
    FreezeEntityPosition(PlayerPedId(), false)
end)
