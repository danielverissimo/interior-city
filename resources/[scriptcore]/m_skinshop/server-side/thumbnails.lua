local resource = GetCurrentResourceName()
local directory = 'web-side/build/thumbnails/'
local indexFile = directory .. 'index.json'
local sessions = {}
local startRequests = {}
local sessionId = 0
local alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local digits = {}
for i = 1, #alphabet do digits[alphabet:byte(i)] = i - 1 end

local function decodeImage(encoded)
    if type(encoded) ~= 'string' or #encoded > 24000 or #encoded % 4 ~= 0
        or not encoded:match('^[%w+/]+=*%s*$') then return end
    local bytes = {}
    for i = 1, #encoded, 4 do
        local a, b, c, d = encoded:byte(i, i + 3)
        a, b = digits[a], digits[b]
        if not a or not b then return end
        bytes[#bytes + 1] = string.char((a << 2) | (b >> 4))
        if c == 61 and d == 61 and i + 3 == #encoded then break end
        c = digits[c]
        if not c then return end
        bytes[#bytes + 1] = string.char(((b & 15) << 4) | (c >> 2))
        if d == 61 and i + 3 == #encoded then break end
        d = digits[d]
        if not d then return end
        bytes[#bytes + 1] = string.char(((c & 3) << 6) | d)
    end
    local image = table.concat(bytes)
    if image:sub(1, 4) == 'RIFF' and image:sub(9, 12) == 'WEBP' then return image end
end

local function notify(player, message)
    TriggerClientEvent('skinshop:thumbnailStatus', player, message)
end

local function readIndex()
    local ok, index = pcall(json.decode, LoadResourceFile(resource, indexFile) or '{}')
    return ok and type(index) == 'table' and index or {}
end

RegisterNetEvent('skinshop:requestThumbnailBatch', function(args)
    local player = source
    if type(args) ~= 'table' then return end
    local now = GetGameTimer()
    if startRequests[player] and now - startRequests[player] < 1500 then return end
    startRequests[player] = now

    local user = vRP.getUserId(player)
    if not user or not (vRP.hasPermission(user, 'admin.permissao')
        or vRP.hasPermission(user, 'perm.admin')
        or IsPlayerAceAllowed(player, 'mgconfig.admin')) then
        return notify(player, 'Sua conta não tem permissão administrativa para gerar as miniaturas.')
    end
    if next(sessions) then return notify(player, 'Já existe uma captura em andamento.') end

    local plan = {}
    if not args[1] or args[1] == 'todas' then
        for _, category in ipairs(SkinshopThumbnailOrder) do
            for _, gender in ipairs({'male', 'female'}) do
                plan[#plan+1] = {category = category, gender = gender, first = 0, last = 2000}
            end
        end
    else
        local category = args[1]
        local first = math.tointeger(tonumber(args[2] or 0))
        local last = math.tointeger(tonumber(args[3] or (first and (first + 19))))
        if not SkinshopThumbnailCategories[category] or not first or not last or first < 0
            or last > 2000 or last < first then
            return notify(player, 'Use /fotografarroupas ou /fotografarroupas categoria início fim.')
        end
        local model = GetEntityModel(GetPlayerPed(player))
        local gender = model == GetHashKey('mp_f_freemode_01') and 'female' or 'male'
        plan[1] = {category = category, gender = gender, first = first, last = last}
    end

    local done = {}
    for key, path in pairs(readIndex()) do
        local gender, category, model = key:match('^(%a+)/(%a+)/(%d+)$')
        local name = gender and ('%s-%s-%d.webp'):format(gender, category, tonumber(model))
        if name and path == 'thumbnails/' .. name and LoadResourceFile(resource, directory .. name) then
            local group = gender .. '/' .. category
            done[group] = done[group] or {}
            done[group][#done[group] + 1] = tonumber(model)
        end
    end

    sessionId = sessionId + 1
    local session = {id = sessionId, plan = plan, expires = os.time() + 10800}
    sessions[player] = session
    SetTimeout(10800000, function()
        if sessions[player] == session then sessions[player] = nil end
    end)
    notify(player, 'Lote autorizado. Preparando o estúdio de fotos.')
    TriggerClientEvent('skinshop:takeThumbnailBatch', player, session.id, plan, done)
end)

RegisterNetEvent('skinshop:saveThumbnail', function(id, group, model, encoded)
    local player = source
    local session = sessions[player]
    local range = session and session.plan[group]
    if not range or id ~= session.id or os.time() > session.expires or type(model) ~= 'number'
        or model % 1 ~= 0 or model < range.first or model > range.last then return end
    local image = decodeImage(encoded)
    local name = ('%s-%s-%d.webp'):format(range.gender, range.category, model)
    local published = false
    local failure = 'WebP inválido ou acima do limite'
    if image and SaveResourceFile(resource, directory .. name, image, #image) then
        failure = 'não foi possível gravar o índice'
        local index = readIndex()
        index[('%s/%s/%d'):format(range.gender, range.category, model)] = 'thumbnails/' .. name
        published = SaveResourceFile(resource, indexFile, json.encode(index), -1)
    elseif image then
        failure = 'não foi possível gravar o arquivo'
    end
    if not published then print(('[m_skinshop] %s: %s.'):format(name, failure)) end
    TriggerClientEvent('skinshop:thumbnailSaved', player, id, group, model, published, failure)
end)

RegisterNetEvent('skinshop:finishThumbnailBatch', function(id)
    if sessions[source] and sessions[source].id == id then sessions[source] = nil end
end)
AddEventHandler('playerDropped', function()
    sessions[source], startRequests[source] = nil, nil
end)
