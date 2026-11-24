-----------------------------------------------------------------------------------------------------------------------------------------
-- m_animacoes | Server-side favourites persistence + legacy emote commands
-----------------------------------------------------------------------------------------------------------------------------------------

local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

src = {}
Tunnel.bindInterface(GetCurrentResourceName(), src)
vCLIENT = Tunnel.getInterface(GetCurrentResourceName())

local DATA_KEY = cfg.chaveFavoritos or "m_animacoes:favoritos"
local MAX_FAVOURITES = tonumber(cfg.maxFavoritos) or 8

local validAnimations = {}
for _, emote in ipairs(cfg.animacoes or {}) do
    if emote.nome then
        validAnimations[tostring(emote.nome)] = true
    end
end

local function sanitiseFavourites(list)
    local clean = {}
    local used = {}

    if type(list) ~= "table" then
        return clean
    end

    for _, value in ipairs(list) do
        local name = tostring(value or "")
        if validAnimations[name] and not used[name] and #clean < MAX_FAVOURITES then
            used[name] = true
            clean[#clean + 1] = name
        end
    end

    return clean
end

local function getUserFavourites(user_id)
    if not user_id then return {} end

    local raw = vRP.getUData(user_id, DATA_KEY)
    if type(raw) ~= "string" or raw == "" then
        return {}
    end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= "table" then
        return {}
    end

    return sanitiseFavourites(decoded)
end

local function saveUserFavourites(user_id, list)
    local clean = sanitiseFavourites(list)
    vRP.setUData(user_id, DATA_KEY, json.encode(clean))
    return clean
end

function src.getFavourites()
    local source = source
    local user_id = vRP.getUserId(source)
    return getUserFavourites(user_id)
end

function src.toggleFavourite(name)
    local source = source
    local user_id = vRP.getUserId(source)
    name = tostring(name or "")

    if not user_id or not validAnimations[name] then
        return { ok = false, favourites = {}, message = "Animação inválida." }
    end

    local list = getUserFavourites(user_id)

    for index, value in ipairs(list) do
        if value == name then
            table.remove(list, index)
            list = saveUserFavourites(user_id, list)
            return { ok = true, favourites = list, message = "Removida dos favoritos." }
        end
    end

    if #list >= MAX_FAVOURITES then
        return {
            ok = false,
            favourites = list,
            message = ("Você pode salvar no máximo %d animações."):format(MAX_FAVOURITES)
        }
    end

    list[#list + 1] = name
    list = saveUserFavourites(user_id, list)
    return { ok = true, favourites = list, message = "Adicionada aos favoritos." }
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- LEGACY COMMANDS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("e", function(source, args)
    TriggerClientEvent("m_anim:emotes", source, args[1])
end)

RegisterCommand("e2", function(source, args)
    local user_id = vRP.getUserId(source)
    if user_id and vRP.hasPermission(user_id, "administrador.permissao") then
        local nplayer = vRPclient.getNearestPlayer(source, 2)
        if nplayer then
            TriggerClientEvent("m_anim:emotes", nplayer, args[1])
        end
    end
end)

RegisterCommand("e3", function(source, args)
    local user_id = vRP.getUserId(source)
    if user_id and vRP.hasPermission(user_id, "administrador.permissao") and args[2] then
        local nplayer = vRP.getUserSource(parseInt(args[2]))
        if nplayer then
            TriggerClientEvent("m_anim:emotes", nplayer, args[1])
        end
    end
end)
