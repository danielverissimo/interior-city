-- PREPARES
vRP.prepare("m_orgs_v2/getChestLogs", "SELECT * FROM sjr_logs WHERE organization = @organization ORDER BY expire_at DESC LIMIT 150")
vRP.prepare("m_orgs_v2/addChestLog", "INSERT INTO sjr_logs (organization, user_id, role, name, description, date, expire_at) VALUES(@organization, @id, @role, @name, @message, @time, @expire_at)")

-- CACHE LOGS
local chestLogCache = {}
local chestLogCacheAdd = {}

-- TUNNELS
function RegisterTunnel.getLogs(data)
    local source = source
    local user_id = getUserId(source)
    if not user_id then return {} end

    local user = Organizations.Members[user_id]
    if not user then return {} end

    local groupType = user.groupType
    local currentPage = data and tonumber(data.currentPage) or 1
    local selectedFilter = data and data.selectedFilter or 'chest'
    local pageSize = 10

    if not chestLogCache[groupType] then
        local t = {}
        local query = vRP.query('m_orgs_v2/getChestLogs', { organization = groupType })
        for i = 1, #query do
            t[#t + 1] = {
                id = query[i].user_id,
                name = query[i].name,
                role = query[i].role,
                description = query[i].description,
                message = query[i].description,
                date = query[i].date,
                time = query[i].date,
                type = 'chest',
                expire_at = query[i].expire_at
            }
        end
        chestLogCache[groupType] = t
    end

    local allLogs = chestLogCache[groupType] or {}
    local filteredLogs = {}

    for _, log in ipairs(allLogs) do
        if not selectedFilter or selectedFilter == "" or log.type == selectedFilter then
            table.insert(filteredLogs, log)
        end
    end

    -- Ordenar por data decrescente (mais recentes primeiro)
    table.sort(filteredLogs, function(a, b)
        return (a.expire_at or 0) > (b.expire_at or 0)
    end)

    local startIndex = (currentPage - 1) * pageSize + 1
    local endIndex = startIndex + pageSize - 1
    local paginatedLogs = {}

    for i = startIndex, endIndex do
        if filteredLogs[i] then
            table.insert(paginatedLogs, filteredLogs[i])
        end
    end

    return paginatedLogs
end

-- EXPORTS
exports('addLogChest', function(user_id, action, item, amount)
    user_id = parseInt(user_id)

    local user = Organizations.Members[user_id]
    if not user then return end

    local identity = getUserIdentity(user_id)
    if not identity then return end

    local description = ""
    local logType = action

    if action == 'withdraw' or action == 'deposit' then
        description = ('%s %dx %s'):format(action == 'withdraw' and 'Retirou' or 'Guardou', amount, item)
        logType = 'chest'
    elseif action == 'hired' then
        description = ('Contratou %s'):format(item)
    elseif action == 'fired' then
        description = ('Demitiu %s'):format(item)
    elseif action == 'craft' then
        description = ('Fabricou %dx %s'):format(amount, item)
    end

    local logEntry = {
        id = user_id,
        name = ('%s %s'):format(identity.name, identity.firstname),
        role = Config.Groups[user.groupType].List[user.group].prefix,
        description = description,
        message = description,
        date = os.date('%d/%m/%Y %X'),
        time = os.date('%d/%m/%Y %X'),
        type = logType,
        expire_at = os.time() + (Config.Main.clearChestLogs * 86400)
    }


    if not chestLogCache[user.groupType] then
        chestLogCache[user.groupType] = {}
    end

    if not chestLogCacheAdd[user.groupType] then
        chestLogCacheAdd[user.groupType] = {}
    end

    table.insert(chestLogCache[user.groupType], logEntry)
    table.insert(chestLogCacheAdd[user.groupType], logEntry)
end)

function RegisterTunnel.getLogsData()
    local source = source
    local user_id = getUserId(source)
    if not user_id then return end

    local user = Organizations.Members[user_id]
    if not user then return end

    local total = chestLogCache[user.groupType] and #chestLogCache[user.groupType] or 0
    local pageSize = 10
    local totalPages = math.max(1, math.ceil(total / pageSize))

    return {
        totalPages = totalPages,
        currentPage = 1,
        filters = {
            { label = "BAÚ", value = "chest" },
            { label = "CONTRATAÇÃO", value = "hired" },
            { label = "DEMISSÃO", value = "fired" },
            { label = "CRAFT", value = "craft" },
        }
    }
end
-- SYNC DATABASE
local function syncChestLogsWithDatabase()
    for groupType, logs in pairs(chestLogCacheAdd) do
        print(json.encode(logs))
        for _, log in ipairs(logs) do
            log.organization = groupType
            vRP.execute('m_orgs_v2/addChestLog', log)
        end
        chestLogCacheAdd[groupType] = {}
    end
end

-- CREATE CACHE
local function createCache()
    local processedOrgs = {}
    for _, user in pairs(Organizations.Members) do
        if not processedOrgs[user.groupType] then
            processedOrgs[user.groupType] = true
            local query = vRP.query('m_orgs_v2/getChestLogs', { organization = user.groupType })
            if query then
                local t = {}
                for i = 1, #query do
                    t[#t + 1] = {
                        id = query[i].user_id,
                        name = query[i].name,
                        role = query[i].role,
                        description = query[i].description,
                        message = query[i].description,
                        date = query[i].date,
                        time = query[i].date,
                        type = 'chest',
                        expire_at = query[i].expire_at
                    }
                end
                chestLogCache[user.groupType] = t
                print(('^2[%s] ^0Logs da org %s puxadas com sucesso.'):format(GetCurrentResourceName():upper(), user.groupType))
            end
        end
    end
end

-- MAIN THREAD
CreateThread(function()
    Wait(5000) -- Esperar o cache de membros ser gerado no main.lua
    print(('^2[%s] ^0Puxando logs no banco de dados!'):format(GetCurrentResourceName():upper()))
    createCache()
end)

-- SAVE CACHE ON STOP
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print(('^2[%s] ^0Salvando logs no banco de dados!'):format(GetCurrentResourceName():upper()))
        syncChestLogsWithDatabase()
    end
end)
