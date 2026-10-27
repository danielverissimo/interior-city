local LAST_HOURS_RANKING_REQUEST = GetGameTimer()
local LAST_HOURS_RANKING_RESPONSE = nil
RegisterNUICallback('GetRanking', function(_, cb) 
    -- cb({
    --   {
    --     id = 1337,
    --     name = 'João Sembraco',
    --     timePlayed = 1234,
    --     money = 5678,
    --     farm = 910
    --   },
    --   {
    --     id = 1337,
    --     name = 'João Sembraco',
    --     timePlayed = 1234,
    --     money = 5678,
    --     farm = 910
    --   },
    --   {
    --     id = 1337,
    --     name = 'João Sembraco',
    --     timePlayed = 1234,
    --     money = 5678,
    --     farm = 910
    --   },
    -- })
    local response = {}
    if GetGameTimer() - LAST_HOURS_RANKING_REQUEST > 20000 then
        response = vTunnel.getFactionRanking()
        if not next(response) or json.encode(response) == "[]" then 
            response = {}
        end
        LAST_HOURS_RANKING_REQUEST = GetGameTimer()
        LAST_HOURS_RANKING_RESPONSE = response
    else
        response = LAST_HOURS_RANKING_RESPONSE
    end

    cb(response)
end)