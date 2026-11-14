-- ============================================================================
-- MAGE ADMIN - AUDITORIA CENTRAL DA CONCESSIONÁRIA
-- ============================================================================
-- Não cria dependência obrigatória no fxmanifest. Se o Mage Admin estiver
-- reiniciando, as ocorrências ficam em uma fila curta em memória e são
-- reenviadas preservando a data/hora original.

DealershipAudit = DealershipAudit or {}

local MAGE_LOG_RESOURCE = "m_paineladm_v2"
local MAGE_LOG_QUEUE_LIMIT = 250
local mageDealershipLogQueue = {}

local function trySendDealershipLog(logKey, payload)
    if GetResourceState(MAGE_LOG_RESOURCE) ~= "started" then
        return false
    end

    local ok, sent, reason = pcall(function()
        return exports[MAGE_LOG_RESOURCE]:sendLog(logKey, payload)
    end)

    if not ok then return false end

    -- Webhook vazia/chave ainda não cadastrada significa que o painel recebeu a
    -- ocorrência. Não mantemos isso preso em uma fila infinita.
    if sent == true or reason == "Webhook não configurada." or reason == "Log não cadastrado no catálogo." then
        return true
    end

    return true
end

function DealershipAudit.Log(logKey, payload)
    if type(logKey) ~= "string" or logKey == "" then return end

    payload = type(payload) == "table" and payload or {}
    payload.occurredAt = tonumber(payload.occurredAt) or os.time()
    if payload.actorId and not payload.actorLabel then
        payload.actorLabel = "JOGADOR"
    elseif not payload.actorId and not payload.actorName then
        payload.actorName = "Sistema"
        payload.actorLabel = "SISTEMA"
    end

    if trySendDealershipLog(logKey, payload) then return end

    if #mageDealershipLogQueue >= MAGE_LOG_QUEUE_LIMIT then
        table.remove(mageDealershipLogQueue, 1)
    end

    mageDealershipLogQueue[#mageDealershipLogQueue + 1] = {
        key = logKey,
        payload = payload
    }
end

function DealershipAudit.CoordsLine(src)
    src = tonumber(src)
    if not src or src <= 0 then return nil end
    local ped = GetPlayerPed(src)
    if not ped or ped <= 0 then return nil end
    local coords = GetEntityCoords(ped)
    if not coords then return nil end
    return ("Coordenadas: `%.2f, %.2f, %.2f`"):format(
        tonumber(coords.x or coords[1]) or 0.0,
        tonumber(coords.y or coords[2]) or 0.0,
        tonumber(coords.z or coords[3]) or 0.0
    )
end

function DealershipAudit.IsNearDealership(src, maxDistance)
    src = tonumber(src)
    if not src or src <= 0 then return false end
    local ped = GetPlayerPed(src)
    if not ped or ped <= 0 then return false end
    local coords = GetEntityCoords(ped)
    if not coords then return false end

    maxDistance = tonumber(maxDistance) or 8.0
    for index, location in pairs((TestDrive and TestDrive.Locations) or {}) do
        local target = location and location.coords
        if target then
            local dx = (tonumber(coords.x or coords[1]) or 0.0) - (tonumber(target.x or target[1]) or 0.0)
            local dy = (tonumber(coords.y or coords[2]) or 0.0) - (tonumber(target.y or target[2]) or 0.0)
            local dz = (tonumber(coords.z or coords[3]) or 0.0) - (tonumber(target.z or target[3]) or 0.0)
            if math.sqrt(dx * dx + dy * dy + dz * dz) <= maxDistance then
                return true, index
            end
        end
    end
    return false
end

function DealershipAudit.VehicleDetails(spawn, car, extra)
    spawn = tostring(spawn or "desconhecido")
    car = type(car) == "table" and car or {}
    local lines = {
        ("Veículo: **%s**"):format(tostring(car.name or spawn)),
        ("Spawn: `%s`"):format(spawn)
    }
    if type(extra) == "table" then
        for i = 1, #extra do
            local line = extra[i]
            if line ~= nil and tostring(line) ~= "" then
                lines[#lines + 1] = tostring(line)
            end
        end
    end
    return table.concat(lines, "\n")
end

function DealershipAudit.InvokingResourceLine(explicit)
    local resource = tostring(explicit or GetInvokingResource() or "desconhecido")
    return ("Resource responsável: `%s`"):format(resource)
end

CreateThread(function()
    while true do
        Wait(5000)
        if #mageDealershipLogQueue > 0 and GetResourceState(MAGE_LOG_RESOURCE) == "started" then
            local pending = mageDealershipLogQueue
            mageDealershipLogQueue = {}
            for _, entry in ipairs(pending) do
                if not trySendDealershipLog(entry.key, entry.payload) and #mageDealershipLogQueue < MAGE_LOG_QUEUE_LIMIT then
                    mageDealershipLogQueue[#mageDealershipLogQueue + 1] = entry
                end
            end
        end
    end
end)
