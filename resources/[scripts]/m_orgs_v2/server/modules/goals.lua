

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PREPARES
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
vRP.prepare('m_orgs_v2/bank/getinfo', 'SELECT bank,bank_historic FROM mirtin_orgs_info WHERE organization = @organization')
vRP.prepare('m_orgs_v2/bank/updateBank', 'UPDATE mirtin_orgs_info SET bank = @bank, bank_historic = @historic WHERE organization = @organization')
vRP.prepare('m_orgs_v2/updateConfigGoals', 'UPDATE mirtin_orgs_info SET config_goals = @config_goals WHERE organization = @organization')
vRP.prepare('m_orgs_v2/myGoals', ' SELECT * FROM mirtin_orgs_goals WHERE user_id = @user_id and organization = @organization and day = @day and month = @month ')
vRP.prepare('m_orgs_v2/someAll', ' SELECT SUM(amount) AS total_amount FROM mirtin_orgs_goals WHERE user_id = @user_id AND organization = @organization;')
vRP.prepare('m_orgs_v2/getRanking', ' SELECT ranking FROM (SELECT user_id, SUM(amount) AS total_amount, RANK() OVER (ORDER BY SUM(amount) DESC) AS ranking FROM mirtin_orgs_goals WHERE organization = @organization GROUP BY user_id) AS ranked_users WHERE user_id = @user_id;;')

vRP.prepare('m_orgs_v2/updateFarm', 'UPDATE mirtin_orgs_goals SET step = @step, reward_step = @reward_step WHERE user_id = @user_id AND organization = @organization AND month = @month AND day = @day')
vRP.prepare('m_orgs_v2/getDailyFarms', 'SELECT * FROM mirtin_orgs_goals WHERE organization = @organization and day = @day and month = @month ORDER BY amount DESC')

vRP.prepare('m_orgs_v2/getDailyFarmsByUser', 'SELECT * FROM mirtin_orgs_goals WHERE organization = @organization and day = @day and month = @month and user_id = @user_id ORDER BY amount DESC')

vRP.prepare('m_orgs_v2/addPlayerFarm', 'INSERT IGNORE INTO mirtin_orgs_goals(organization, user_id, item, amount, day, month) VALUES(@organization, @user_id, @item, @amount, @day, @month) ON DUPLICATE KEY UPDATE amount = amount + @amount;')

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local GOALS = {
    cooldown = {}
}

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TUNNELS
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function RegisterTunnel.getPersonalRanking()
    local source = source
    local user_id = getUserId(source)
    if not user_id then return end

    local user = Organizations.Members[user_id]
    if not user then return end

    if not Organizations.goalsConfig[user.groupType] then return end
    local function getWeekDays()
        local today = os.date("*t").wday
        local days = {}

        for i = 0, 6 do
            local offset = (i - (today - 1)) * 86400 
            local date = os.date("*t", os.time() + offset)
            days[i + 1] = { day = date.day, month = date.month }
        end
    
        return days
    end
    
    local weekDays = getWeekDays()

    local status = { 2, 2, 2, 2, 2, 2, 2 }
    local today = os.date("*t").wday

    for i, date in ipairs(weekDays) do
        local reward_data = vRP.query('m_orgs_v2/getDailyFarmsByUser', {
            user_id = user_id,
            day = date.day,
            month = date.month,
            organization = user.groupType
        })

        if #reward_data > 0 then
            local checked = 0
            local countitens = 0

            -- Contar os itens completados
            for _, values in pairs(reward_data) do
                local itemInfo = Organizations.goalsConfig[user.groupType].info.itens[values.item]
                if itemInfo and values.amount >= itemInfo.max and itemInfo.needed then
                    checked = checked + 1
                end
            end

            -- Contar todos os itens necessários
            for _, infos in pairs(Organizations.goalsConfig[user.groupType].info.itens) do
                if infos.needed then
                    countitens = countitens + 1
                end
            end
            if checked >= countitens then
                status[i] = 1
            else
                if i < today then
                    status[i] = 2
                elseif i >= today then
                    status[i] = 3
                end
            end
        else
            if i < today then
                status[i] = 2
            elseif i >= today then
                status[i] = 3 
            end
        end
    end


    if status[today] ~= 1 then
        status[today] = 3
    end


    local query = vRP.query('m_orgs_v2/getRanking', { user_id = user_id, organization = user.groupType })
    return { status = { status[2], status[3], status[4], status[5], status[6], status[7], status[1] }, rankingPosition = (query[1] and query[1].ranking or 999)  }
end


function RegisterTunnel.GetGoalsDetails()
    local source = source
    local user_id = getUserId(source)
    if not user_id then return end

    local user = Organizations.Members[user_id]
    if not user then return end

    if not Organizations.goalsConfig[user.groupType] then return end
    local myGoals = vRP.query('m_orgs_v2/myGoals', { user_id = user_id, organization = user.groupType, day = os.date('%d'), month = os.date('%m') }) or {}
    local myItems, concluded_items = {}, 0
    for i = 1, #myGoals do
        local goal = myGoals[i]
        
        local valid_goal = Organizations.goalsConfig[user.groupType].info.itens
        if valid_goal[goal.item] then
            local maxItem = valid_goal[goal.item].max

            myItems[goal.item] = {
                amount = goal.amount,
                step = goal.step
            }

        end
    end

    local goalsItens = {}
    local goalMax = Organizations.goalsConfig[user.groupType].info
    local goalsCurrent = 0
    local goalsMax = 0
    for item, maxItem in pairs(Organizations.goalsConfig[user.groupType].info.itens) do
        if goalMax.itens[item].needed then
           goalsItens[#goalsItens + 1] = {
            item = item, -- <<< NOME DO ITEM
            amount = myItems[item] and myItems[item].amount or 0,
            max = goalMax.itens[item].max * (myItems[item] and myItems[item].step or 1)
        }
            goalsCurrent = goalsCurrent + (myItems[item] and myItems[item].amount or 0)
            goalsMax = goalsMax + goalMax.itens[item].max
        end
    end
    local data = {
        rewards = goalsItens,
        reward = goalMax.defaultReward,
        goalsCurrent = goalsCurrent,
        goalsMax = goalsMax
    }
    return data
end


function RegisterTunnel.getGoals()
    local source = source
    local user_id = getUserId(source)
    if not user_id then return end

    local user = Organizations.Members[user_id]
    if not user then return end

    if not Organizations.goalsConfig[user.groupType] then return end

    local myGoals = vRP.query('m_orgs_v2/myGoals', { user_id = user_id, organization = user.groupType, day = os.date('%d'), month = os.date('%m') }) or {}
    local myItems, concluded_items = {}, 0
    for i = 1, #myGoals do
        local goal = myGoals[i]
        
        local valid_goal = Organizations.goalsConfig[user.groupType].info.itens
        if valid_goal[goal.item] then
            local maxItem = valid_goal[goal.item].max

            myItems[goal.item] = {
                amount = goal.amount,
                step = goal.step
            }

        end
    end

    local goalsItens = {}
    local goalMax = Organizations.goalsConfig[user.groupType].info
    for item, maxItem in pairs(Organizations.goalsConfig[user.groupType].info.itens) do
        goalsItens[#goalsItens + 1] = {
            name = getItemName(item),
            item = item,
            needed = goalMax.itens[item].needed,
            current = myItems[item] and myItems[item].amount or 0,
            max = goalMax.itens[item].max*(myItems[item] and myItems[item].step or 1)
        }
    end

    local function getWeekDays()
        local today = os.date("*t").wday
        local days = {}

        for i = 0, 6 do
            local offset = (i - (today - 1)) * 86400 
            local date = os.date("*t", os.time() + offset)
            days[i + 1] = { day = date.day, month = date.month }
        end
    
        return days
    end
    
    local weekDays = getWeekDays()
    local t = {}
    
    for nuserid in ipairs(Organizations.MembersList[user.groupType]) do
        local ply_identity = getUserIdentity(nuserid)
        if ply_identity then
            local nuser = Organizations.Members[nuserid]
            local status = { 2, 2, 2, 2, 2, 2, 2 }
    
            -- Obter o dia atual da semana (1 = domingo, 2 = segunda, ..., 7 = sábado)
            local today = os.date("*t").wday
    
            for i, date in ipairs(weekDays) do
                local reward_data = vRP.query('m_orgs_v2/getDailyFarmsByUser', {
                    user_id = nuserid,
                    day = date.day,
                    month = date.month,
                    organization = user.groupType
                })
    
                if #reward_data > 0 then
                    local checked = 0
                    local countitens = 0
    
                    -- Contar os itens completados
                    for _, values in pairs(reward_data) do
                        local itemInfo = Organizations.goalsConfig[user.groupType].info.itens[values.item]
                        if itemInfo and values.amount >= itemInfo.max and itemInfo.needed then
                            checked = checked + 1
                        end
                    end
    
                    -- Contar todos os itens necessários
                    for _, infos in pairs(Organizations.goalsConfig[user.groupType].info.itens) do
                        if infos.needed then
                            countitens = countitens + 1
                        end
                    end
                    if checked >= countitens then
                        status[i] = 1
                    else
                        if i < today then
                            status[i] = 2
                        elseif i >= today then
                            status[i] = 3
                        end
                    end
                else
                    if i < today then
                        status[i] = 2
                    elseif i >= today then
                        status[i] = 3 
                    end
                end
            end
    
  
            if status[today] ~= 1 then
                status[today] = 3
            end
            table.insert(t, {
                id = nuserid,
                name = ('%s %s'):format(ply_identity.name, ply_identity.firstname),
                role = Config.Groups[nuser.groupType] and Config.Groups[nuser.groupType].List[nuser.group].prefix or "Desconhecido",
                status = { status[2], status[3], status[4], status[5], status[6], status[7], status[1] }
            })
        end
    end
    return {
        prize = goalMax.defaultReward,
        my = goalsItens,
        members = t,
    }
end

function RegisterTunnel.rewardGoal(data)
    local source = source
    local user_id = getUserId(source)
    if not user_id then return end

    local identity = getUserIdentity(user_id)
    if not identity then return end

    local user = Organizations.Members[user_id]
    if not user then return end

    if not Organizations.goalsConfig[user.groupType] then return end

    if GOALS.cooldown[user_id] and (GOALS.cooldown[user_id] - os.time()) > 0 then
        return Config.Langs['waitCooldown'](source)
    end
    GOALS.cooldown[user_id] = (os.time() + 5)

    local myGoals = vRP.query('m_orgs_v2/myGoals', { user_id = user_id, organization = user.groupType, day = os.date('%d'), month = os.date('%m') }) or {}
    if #myGoals <= 0 or not myGoals[1] then
        return
    end
    local concluded_items = 0
    for i = 1, #myGoals do
        local goal = myGoals[i]
        
        local valid_goal = Organizations.goalsConfig[user.groupType].info.itens
        if valid_goal[goal.item] then
            local maxItem = valid_goal[goal.item].max

            if goal.amount >= (maxItem * goal.step) then
                concluded_items = (concluded_items + 1)
            end
        end
    end

    local totalItems = 0
    for item, values in pairs(Organizations.goalsConfig[user.groupType].info.itens) do
        if values.needed then
            totalItems = (totalItems + 1)
        end
    end

    if concluded_items < totalItems then
        TriggerClientEvent('Notify', source,'negado','Você deve concluir as metas para poder resgatar', 5000)
        return
    end

    local reward_step = myGoals[1].reward_step
    if myGoals[1].step >= 1 then
        reward_step = (reward_step + 1)
    end

    local query = vRP.query('m_orgs_v2/bank/getinfo', { organization = user.groupType })
    if #query == 0 then return end

    local amount = Organizations.goalsConfig[user.groupType].info.defaultReward or 0
    if not amount or not query[1].bank then
        return
    end
    if amount > query[1].bank then
        return Config.Langs['bankNotMoney'](source)
    end
    
    vRP.execute('m_orgs_v2/updateFarm', { user_id = user_id, organization = user.groupType, day = os.date('%d'), month = os.date('%m'), reward_step = reward_step, step = (myGoals[1].step + 1) })

    -- PAGAR META

    local bank_value = (query[1].bank - amount)
    local generate_log = BANK:generateLog(json.decode(query[1].bank_historic), {
        name = ('%s %s'):format(identity.name, identity.firstname),
        type = "META DIARIA",
        value = amount,
        date = os.date('%d/%m/%Y %X'),
    })

    vRP.execute('m_orgs_v2/bank/updateBank', { organization = user.groupType, bank = bank_value, historic = json.encode(generate_log) })
    vRP.giveBankMoney(user_id, amount)

    Config.Langs['rewardedGoal'](source, amount)
    return true
end


function RegisterTunnel.EditMyGoal(data)
    local source = source
    local user_id = getUserId(source)
    if not user_id then return end

    local user = Organizations.Members[user_id]
    if not user then return end
    local hasPermission = Organizations.Permissions[user.groupType] and Organizations.Permissions[user.groupType][user.group].leader or false
    if not hasPermission then
        return
    end
    local t = {}
    for index in pairs(data.items) do
        if not t.info then 
            t.info = {
                defaultReward = data.payment,
                itens = {}
            }
        end

        t.info.itens[data.items[index].item] = { max = data.items[index].max, needed = data.items[index].needed }
    end

    if Organizations.goalsConfig[user.groupType] then
        Organizations.goalsConfig[user.groupType] = t
    end

    vRP.execute('m_orgs_v2/updateConfigGoals', { organization = user.groupType, config_goals = json.encode(t) })
end


exports('addGoal', function(user_id, item, amount)
    user_id = parseInt(user_id)
    local source = getUserSource(user_id)
    if not source then return end

    local user = Organizations.Members[user_id]
    if not user then return end

    if not Organizations.goalsConfig[user.groupType] then return end
    if not Organizations.goalsConfig[user.groupType].info.itens[item] then return end

    vRP.execute('m_orgs_v2/addPlayerFarm', { organization = user.groupType, user_id = user_id, item = item, amount = amount, day = os.date('%d'), month = os.date('%m') })
end)