-- ============================================================================
-- MAGE ADMIN - AUDITORIA CENTRAL DA GARAGEM
-- ============================================================================
-- Esta integração não cria dependência obrigatória no fxmanifest. Se o Mage
-- Admin estiver reiniciando no instante da ocorrência, mantemos uma fila curta
-- em memória e reenviamos quando o export voltar. A data/hora original é
-- preservada em occurredAt.

GarageAudit = GarageAudit or {}

local MAGE_LOG_RESOURCE = GetConvar("ic_admin_service_resource", "ic_admin")
local MAGE_LOG_QUEUE_LIMIT = 250
local mageGarageLogQueue = {}

local function trySendGarageLog(logKey, payload)
    if GetResourceState(MAGE_LOG_RESOURCE) ~= "started" then
        return false
    end

    local ok, sent, reason = pcall(function()
        return exports[MAGE_LOG_RESOURCE]:sendLog(logKey, payload)
    end)

    if not ok then
        return false
    end

    -- Webhook vazia ou chave ainda não cadastrada não deve prender a garagem em
    -- uma fila infinita. O painel processou a chamada; apenas não havia destino.
    if sent == true or reason == "Webhook não configurada." or reason == "Log não cadastrado no catálogo." then
        return true
    end

    return true
end

function GarageAudit.Log(logKey, payload)
    if type(logKey) ~= "string" or logKey == "" then return end

    payload = type(payload) == "table" and payload or {}
    payload.occurredAt = tonumber(payload.occurredAt) or os.time()

    if trySendGarageLog(logKey, payload) then return end

    if #mageGarageLogQueue >= MAGE_LOG_QUEUE_LIMIT then
        table.remove(mageGarageLogQueue, 1)
    end

    mageGarageLogQueue[#mageGarageLogQueue + 1] = {
        key = logKey,
        payload = payload
    }
end

function GarageAudit.VehicleDetails(vehicleSpawn, extra)
    vehicleSpawn = tostring(vehicleSpawn or "desconhecido")

    local vehicleName = vehicleSpawn
    if type(getVehicleName) == "function" then
        local ok, resolved = pcall(getVehicleName, vehicleSpawn)
        if ok and resolved and tostring(resolved) ~= "" then
            vehicleName = tostring(resolved)
        end
    end

    local lines = {
        ("Veículo: **%s**"):format(vehicleName),
        ("Spawn: `%s`"):format(vehicleSpawn)
    }

    if type(extra) == "table" then
        -- Tabelas montadas com helpers opcionais (placa/garagem/coordenadas)
        -- podem possuir "buracos" numéricos. ipairs() pararia no primeiro nil e
        -- esconderia as informações seguintes da log, por isso preservamos a
        -- ordem descobrindo o maior índice numérico existente.
        local maxIndex = 0
        for key in pairs(extra) do
            if type(key) == "number" and key > maxIndex then
                maxIndex = key
            end
        end

        for i = 1, maxIndex do
            local line = extra[i]
            if line ~= nil and tostring(line) ~= "" then
                lines[#lines + 1] = tostring(line)
            end
        end
    end

    return table.concat(lines, "\n")
end

function GarageAudit.GarageLine(garageId, garageType)
    local id = tostring(garageId or "")
    local kind = tostring(garageType or "")
    if id == "" and kind == "" then return nil end
    if id == "" then return ("Tipo de garagem: **%s**"):format(kind) end
    if kind == "" then return ("Garagem: **%s**"):format(id) end
    return ("Garagem: **%s** | Tipo: **%s**"):format(id, kind)
end

function GarageAudit.PlateLine(plate)
    plate = tostring(plate or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if plate == "" then return nil end
    return ("Placa: `%s`"):format(plate)
end

function GarageAudit.CoordsLine(src)
    src = tonumber(src)
    if not src or src <= 0 then return nil end

    local ped = GetPlayerPed(src)
    if not ped or ped <= 0 then return nil end

    local coords = GetEntityCoords(ped)
    if not coords then return nil end

    return ("Coordenadas: `%.2f, %.2f, %.2f`"):format(coords.x or coords[1] or 0.0, coords.y or coords[2] or 0.0, coords.z or coords[3] or 0.0)
end

CreateThread(function()
    while true do
        Wait(5000)

        if #mageGarageLogQueue > 0 and GetResourceState(MAGE_LOG_RESOURCE) == "started" then
            local pending = mageGarageLogQueue
            mageGarageLogQueue = {}

            for _, entry in ipairs(pending) do
                if not trySendGarageLog(entry.key, entry.payload) then
                    if #mageGarageLogQueue < MAGE_LOG_QUEUE_LIMIT then
                        mageGarageLogQueue[#mageGarageLogQueue + 1] = entry
                    end
                end
            end
        end
    end
end)
