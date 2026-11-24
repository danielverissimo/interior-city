local attempts, serial = {}, 0

RegisterNetEvent('m_robbernpc:lockpickResult', function(token, success)
    local attempt = attempts[source]
    if not attempt or attempt.token ~= token or attempt.done then return end
    attempt.done = true
    attempt.success = success == true and GetGameTimer() - attempt.started >= 400
end)

function RunTrunkLockpick(player, netId, speed)
    if attempts[player] then return false end
    serial = serial + 1
    local attempt = { token=tostring(serial) .. ':' .. tostring(GetGameTimer()), started=GetGameTimer() }
    attempts[player] = attempt
    TriggerClientEvent('m_robbernpc:lockpickStart', player, netId, attempt.token, speed)
    while not attempt.done and GetPlayerName(player) and GetGameTimer() - attempt.started < 25000 do Wait(25) end
    attempts[player] = nil
    TriggerClientEvent('m_robbernpc:lockpickClose', player, attempt.token)
    return attempt.done == true and attempt.success == true
end

AddEventHandler('playerDropped', function() attempts[source] = nil end)
