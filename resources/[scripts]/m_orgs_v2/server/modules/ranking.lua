function RegisterTunnel.getFactionRanking()
    local source = source
    local user_id = getUserId(source)
    if not user_id then return end

    local user = Organizations.Members[user_id]
    if not user then return end

    if not Organizations.MembersList[user.groupType] then return end

    local users = {}
    for nuser in pairs(Organizations.MembersList[user.groupType]) do
        local identity = getUserIdentity(nuser)
        if not identity then goto next_player end
        local query = vRP.query('m_orgs_v2/someAll', { user_id = nuser, organization = user.groupType })
        users[#users+1] = {
            id = nuser,
            name = identity.name.. " "..identity.firstname,
            timePlayed = Organizations.Members[nuser] and Organizations.Members[nuser].timeplayed or 0,
            money = vRP.getBankMoney(nuser),
            farm = (query[1] and query[1].total_amount or 0),
        }
        :: next_player ::
    end
    return users
end


function RegisterTunnel.getRanking()
    local source = source
    local user_id = getUserId(source)
    if not user_id then return end

    local user = Organizations.Members[user_id]
    if not user then return end

    if not Organizations.MembersList[user.groupType] then return end

    local users = {}
    for nuser in pairs(Organizations.MembersList[user.groupType]) do
        local identity = getUserIdentity(nuser)
        if not identity then goto next_player end
        users[#users+1] = {
            name = identity.name.. " "..identity.firstname,
            user_id = nuser,
            time = Organizations.Members[nuser] and Organizations.Members[nuser].timeplayed or 0,
        }
        :: next_player ::
    end
    table.sort(users, function(a, b)
        return a.time > b.time
    end)
    for i = 1,#users do
        if users[i].user_id == user_id then
            users[i].player = true
            users[i].pos = i
        end
    end
    return users
end