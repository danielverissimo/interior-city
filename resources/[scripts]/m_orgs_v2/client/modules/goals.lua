----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CALLBACKS
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback('NewGoal', function(data, cb)
  cb(vTunnel.newGoal(data))
end)

RegisterNUICallback('GetGoals', function(data, cb)
  local response = vTunnel.getGoals()
  cb(response)
end)
RegisterNUICallback('GetGoalsDetails', function(data, cb)
  cb(vTunnel.GetGoalsDetails())
end)

RegisterNUICallback('EditMyGoal', function(data, cb)
  cb(vTunnel.EditMyGoal(data))
end)

local LAST_RANKING_REQUEST = GetGameTimer()
local LAST_RANKING_RESPONSE = nil
RegisterNUICallback('getPersonalRanking', function(_, cb)
  if GetGameTimer() - LAST_RANKING_REQUEST > 10000 then
    LAST_RANKING_REQUEST = GetGameTimer()
    LAST_RANKING_RESPONSE = vTunnel.getPersonalRanking()
    cb(LAST_RANKING_RESPONSE)
  else
    cb(LAST_RANKING_RESPONSE)
  end
end)

RegisterNUICallback('ClaimRewards', function(data, cb)
  vTunnel._close()

  SetNuiFocus(false, false)
  SendNUIMessage({ action = 'close' })

  cb(vTunnel.ClaimRewards(data.rewards))
end)