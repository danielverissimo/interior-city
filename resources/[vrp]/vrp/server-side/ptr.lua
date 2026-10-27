local patrulhamento = {}

function vRP.setPatrulhamento(user_id)
	patrulhamento[user_id] = true
end

function vRP.removePatrulhamento(user_id)
    patrulhamento[user_id] = nil
end

function vRP.checkPatrulhamento(user_id)
	return patrulhamento[user_id]
end

local function buildNotifyCallPayload(data)
    data = type(data) == "table" and data or {}

    local payload = {}
    for key, value in pairs(data) do
        payload[key] = value
    end

    -- Compatibilidade com o formato antigo usado pelos scripts da base.
    payload.blipSprite = payload.blipSprite or payload.blipID

    if payload.blipDuration == nil and tonumber(payload.time) then
        local legacyTime = tonumber(payload.time)
        payload.blipDuration = legacyTime <= 300 and (legacyTime * 1000) or legacyTime
    end

    -- No formato antigo, `name` era usado como descrição. No NotifyCall novo
    -- a descrição correta é `text`, enquanto `name` representa o solicitante.
    if payload.text == nil and payload.name ~= nil then
        payload.text = payload.name
        payload.name = nil
    end

    -- O NotifyCall exibe este campo no cabeçalho do chamado.
    payload.time = payload.displayTime or os.date("%H:%M")

    return payload
end

function alertPolice(data)
    local payload = buildNotifyCallPayload(data)
    if not payload.x or not payload.y or not payload.z then return end

    local policia = vRP.getUsersByPermission("perm.countpolicia")
    if #policia > 0 then
        for _, v in pairs(policia) do
            local passport = parseInt(v)
            local nsource = vRP.getUserSource(passport)
            if nsource and vRP.checkPatrulhamento(passport) then
                TriggerClientEvent("NotifyPush", nsource, payload)
            end
        end
    end
end

exports("alertPolice", function(...)
    alertPolice(...)
end)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CHECAGENS
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("vRP:playerLeave",function(user_id,source)
    local data = vRP.getUserDataTable(user_id)
    if patrulhamento[user_id] then
        if not vRP.hasPermission(user_id, "perm.tunar") or not vRP.hasPermission(user_id, "perm.unizk") then
            if data then
                data.weapons = {}
            end
        end

        patrulhamento[user_id] = nil
    end
end)