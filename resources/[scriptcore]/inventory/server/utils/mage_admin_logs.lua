-- ============================================================================
-- INVENTORY -> MAGE ADMIN CENTRAL AUDIT LOGS
-- ============================================================================
-- Todas as ocorrências deste resource passam pelo sistema central do
-- m_paineladm_v2. Se o painel estiver reiniciando, a ocorrência fica em uma
-- pequena fila temporária e mantém o horário original da ação.
-- ============================================================================

InventoryAudit = InventoryAudit or {}

local PANEL_RESOURCE <const> = "m_paineladm_v2"
local MAX_PENDING <const> = 300
local FLUSH_INTERVAL <const> = 10000
local pendingLogs = {}

local function copyData(data)
    local out = {}
    if type(data) == "table" then
        for k, v in pairs(data) do out[k] = v end
    end
    out.occurredAt = tonumber(out.occurredAt) or os.time()
    return out
end

local function panelStarted()
    return GetResourceState(PANEL_RESOURCE) == "started"
end

local function trySend(entry)
    if not panelStarted() then
        return false, true
    end

    local ok, sent, reason = pcall(function()
        return exports[PANEL_RESOURCE]:sendLog(entry.key, entry.data)
    end)

    if not ok then
        return false, true
    end

    -- Se o painel respondeu normalmente, não há motivo para reter a ocorrência
    -- na fila. "false" aqui normalmente significa webhook ainda não configurada.
    return sent == true, false, reason
end

local function enqueue(key, data)
    if #pendingLogs >= MAX_PENDING then
        table.remove(pendingLogs, 1)
    end
    pendingLogs[#pendingLogs + 1] = {
        key = tostring(key or ""),
        data = copyData(data)
    }
end

function InventoryAudit.Log(key, data)
    key = tostring(key or "")
    if key == "" then return false end

    local entry = { key = key, data = copyData(data) }
    local sent, shouldRetry = trySend(entry)
    if shouldRetry then
        enqueue(key, entry.data)
    end
    return sent
end

function InventoryAudit.ItemLabel(item)
    item = tostring(item or "")
    local cfg = type(Items) == "table" and Items[item] or nil
    local name = cfg and tostring(cfg.name or "") or ""
    if name == "" then name = item end
    return name
end

function InventoryAudit.ItemDetails(item, amount)
    item = tostring(item or "")
    return ("**Item:** %s\n**Spawn:** %s\n**Quantidade:** %sx"):format(
        InventoryAudit.ItemLabel(item),
        item,
        tostring(math.max(0, math.floor(tonumber(amount) or 0)))
    )
end

local function flushPending()
    if not panelStarted() or #pendingLogs == 0 then return end

    local remaining = {}
    for i = 1, #pendingLogs do
        local entry = pendingLogs[i]
        local _, shouldRetry = trySend(entry)
        if shouldRetry then
            remaining[#remaining + 1] = entry
        end
    end
    pendingLogs = remaining
end

CreateThread(function()
    while true do
        Wait(FLUSH_INTERVAL)
        flushPending()
    end
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == PANEL_RESOURCE then
        SetTimeout(1500, flushPending)
    end
end)
