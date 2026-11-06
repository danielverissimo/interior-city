-- ==========================================================================
-- MAGE ADMIN - AUDITORIA DOS EMPREGOS
-- Integração server-side com m_paineladm_v2 sem expor webhooks aos clients.
-- ==========================================================================

local MAGE_PANEL_RESOURCE = "m_paineladm_v2"
local MAGE_LOG_QUEUE_LIMIT = 300
local mageEmpregosLogQueue = {}

local function mageNow()
    return os.time()
end

local function mageSafeString(value)
    value = tostring(value or "")
    if #value > 1800 then
        value = value:sub(1, 1797) .. "..."
    end
    return value
end

local function mageSendLogNow(logKey, payload)
    if GetResourceState(MAGE_PANEL_RESOURCE) ~= "started" then
        return false
    end

    local ok = pcall(function()
        exports[MAGE_PANEL_RESOURCE]:sendLog(logKey, payload)
    end)

    -- Se o painel respondeu sem erro, a ocorrência foi processada. Uma webhook
    -- vazia significa apenas que aquela log está desativada e não deve ficar
    -- presa na fila de retry.
    return ok
end

function MageEmpregosLog(logKey, payload)
    logKey = tostring(logKey or "")
    if logKey == "" then return false end

    payload = type(payload) == "table" and payload or {}
    payload.occurredAt = tonumber(payload.occurredAt) or mageNow()
    payload.actorLabel = payload.actorLabel or "JOGADOR"
    if payload.details then
        payload.details = mageSafeString(payload.details)
    end

    if mageSendLogNow(logKey, payload) then
        return true
    end

    if #mageEmpregosLogQueue >= MAGE_LOG_QUEUE_LIMIT then
        table.remove(mageEmpregosLogQueue, 1)
    end

    mageEmpregosLogQueue[#mageEmpregosLogQueue + 1] = {
        key = logKey,
        payload = payload
    }
    return false
end

function MageEmpregosCurrentJob(userId)
    userId = tonumber(userId)
    if not userId then return "" end
    local ok, job = pcall(function()
        return mg.getUserGroupByType(userId, "emp")
    end)
    if not ok then return "" end
    return tostring(job or "")
end

function MageEmpregosHasJob(userId, expectedJob)
    return MageEmpregosCurrentJob(userId) == tostring(expectedJob or "")
end

function MageEmpregosMoney(value)
    value = math.floor(tonumber(value) or 0)
    local formatted = tostring(math.abs(value))
    formatted = formatted:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
    if value < 0 then formatted = "-" .. formatted end
    return "R$ " .. formatted
end

function MageEmpregosLogInvalid(source, action, details)
    local userId = mg.getUserId(source)
    MageEmpregosLog("jobs_security_invalid_action", {
        actorId = userId,
        details = ("Ação: %s\nEmprego atual: %s\n%s"):format(
            tostring(action or "desconhecida"),
            MageEmpregosCurrentJob(userId),
            tostring(details or "Tentativa recusada pelo servidor.")
        )
    })
end

CreateThread(function()
    while true do
        Wait(5000)
        if #mageEmpregosLogQueue > 0 and GetResourceState(MAGE_PANEL_RESOURCE) == "started" then
            local pending = mageEmpregosLogQueue
            mageEmpregosLogQueue = {}
            for _, entry in ipairs(pending) do
                if not mageSendLogNow(entry.key, entry.payload) then
                    if #mageEmpregosLogQueue < MAGE_LOG_QUEUE_LIMIT then
                        mageEmpregosLogQueue[#mageEmpregosLogQueue + 1] = entry
                    end
                end
                Wait(25)
            end
        end
    end
end)
