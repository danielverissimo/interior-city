local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

local vRP = Proxy.getInterface("vRP")
local vRPclient = Tunnel.getInterface("vRP")
local HospitalClient = Tunnel.getInterface("m_hospital")

-- Mantém a interface antiga do vrp_hospital para não quebrar integrações existentes.
local LegacyAPI = {}
Tunnel.bindInterface("emp_hospital", LegacyAPI)

-- Interface compartilhada pelos três painéis, com acesso controlado por organização.
local HospitalAPI = {}
Tunnel.bindInterface("m_hospital", HospitalAPI)

-- ============================================================================
-- Configuração/runtime dos painéis
-- ============================================================================
local Panels = {}
local sectorCallsReady = false

for key, cfg in pairs(HospitalConfig.Panels or {}) do
    local runtime = {
        key = tostring(key),
        cfg = cfg,
        hierarchyIndex = {},
        hierarchyLabel = {},
        hierarchyGroupByIndex = {},
    }

    for index, role in ipairs(cfg.hierarchy or {}) do
        runtime.hierarchyIndex[role.group] = index
        runtime.hierarchyLabel[role.group] = role.label or role.group
        runtime.hierarchyGroupByIndex[index] = role.group
    end

    Panels[key] = runtime
end

local function getPanel(panelKey)
    panelKey = tostring(panelKey or "Hospital")
    return Panels[panelKey]
end

local function panelName(panel)
    return panel and panel.cfg and (panel.cfg.displayName or panel.cfg.organization or panel.key) or "Organização"
end

local function notify(src, kind, message, time)
    if src and tonumber(src) and tonumber(src) > 0 then
        TriggerClientEvent("Notify", src, kind, message, time or 5000)
    end
end

local function fullIdentity(userId)
    local identity = vRP.getUserIdentity(tonumber(userId))
    if not identity then
        return {
            nome = "ID",
            sobrenome = tostring(userId),
            full = ("ID %s"):format(userId)
        }
    end

    local nome = tostring(identity.nome or identity.name or "")
    local sobrenome = tostring(identity.sobrenome or identity.name2 or "")
    local full = (nome .. " " .. sobrenome):gsub("^%s+", ""):gsub("%s+$", "")
    if full == "" then full = ("ID %s"):format(userId) end

    return { nome = nome, sobrenome = sobrenome, full = full }
end

local function getUsersSafe()
    local ok, users = pcall(vRP.getUsers)
    if ok and type(users) == "table" then return users end
    return {}
end

local function currentOperationalRole(userId, panel)
    if not panel then return nil end

    local ok, groups = pcall(vRP.getUserGroups, tonumber(userId))
    if not ok or type(groups) ~= "table" then return nil end

    for _, role in ipairs(panel.cfg.hierarchy or {}) do
        if groups[role.group] ~= nil then
            return role.group
        end
    end

    return nil
end

local function getPontoMembership(userId, panel)
    userId = tonumber(userId)
    if not userId or not panel then return nil end

    local org = panel.cfg.organization

    if GetResourceState("m_ponto") == "started" then
        local ok, data = pcall(function()
            return exports["m_ponto"]:getMembership(userId, org)
        end)

        if ok and type(data) == "table" and panel.hierarchyIndex[data.role] then
            return {
                role = data.role,
                onDuty = data.onDuty == true,
                source = vRP.getUserSource(userId)
            }
        end
    end

    -- Fallback apenas para membros atualmente em cargo operacional.
    local role = currentOperationalRole(userId, panel)
    if role then
        return {
            role = role,
            onDuty = true,
            source = vRP.getUserSource(userId)
        }
    end

    return nil
end

local function getServiceInfo(userId, panel)
    userId = tonumber(userId)
    if not userId or not panel then
        return { seconds = 0, formatted = "00:00:00" }
    end

    local org = panel.cfg.organization

    if GetResourceState("m_ponto") == "started" then
        local ok, data = pcall(function()
            return exports["m_ponto"]:getServiceInfo(userId, org)
        end)

        if ok and type(data) == "table" then
            return {
                seconds = math.max(0, math.floor(tonumber(data.seconds) or 0)),
                formatted = tostring(data.formatted or "00:00:00")
            }
        end
    end

    local row = exports.oxmysql:singleSync(
        "SELECT service_time FROM m_ponto_hours WHERE user_id = ? AND org = ? LIMIT 1",
        { userId, org }
    )

    local seconds = row and tonumber(row.service_time) or 0
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60

    return {
        seconds = seconds,
        formatted = ("%02d:%02d:%02d"):format(h, m, s)
    }
end

local function actorContext(src, panel)
    if not panel then return nil, "Painel inválido." end

    local userId = vRP.getUserId(src)
    if not userId then return nil, "Jogador não identificado." end

    local membership = getPontoMembership(userId, panel)
    if not membership then
        return nil, ("Você não faz parte da %s."):format(panelName(panel))
    end

    local role = membership.role

    return {
        source = src,
        userId = userId,
        role = role,
        roleLabel = panel.hierarchyLabel[role] or role,
        rank = panel.hierarchyIndex[role] or 999,
        canManage = panel.cfg.managementGroups and panel.cfg.managementGroups[role] == true or false,
        canHire = panel.cfg.hiringGroups and panel.cfg.hiringGroups[role] == true or false,
        onDuty = membership.onDuty == true,
    }
end

-- ============================================================================
-- Dados do painel
-- ============================================================================
local function hospitalCallCounts()
    local rows = exports.oxmysql:query_async([[
        SELECT medic_id, COUNT(*) AS total FROM (
            SELECT medic_id FROM m_hospital_calls
            UNION ALL
            SELECT c.actor_id AS medic_id FROM m_hospital_sector_calls c
            WHERE c.department = 'hospital'
              AND NOT EXISTS (SELECT 1 FROM m_hospital_calls old WHERE old.call_id = c.call_id)
        ) combined GROUP BY medic_id
    ]]) or {}

    local out = {}
    for _, row in ipairs(rows) do
        out[tonumber(row.medic_id)] = tonumber(row.total) or 0
    end

    return out
end

local function onlineRoster(panel)
    local roster = {}
    local seen = {}
    local users = getUsersSafe()

    for key, value in pairs(users) do
        local userId = tonumber(key)
        local src = tonumber(value)

        -- Compatibilidade defensiva caso alguma build retorne source => user_id.
        if userId and src and vRP.getUserSource(userId) ~= src then
            local maybeUserId = tonumber(value)
            local maybeSource = tonumber(key)

            if maybeUserId and maybeSource and vRP.getUserSource(maybeUserId) == maybeSource then
                userId, src = maybeUserId, maybeSource
            end
        end

        if userId and src and not seen[userId] and GetPlayerName(src) then
            local membership = getPontoMembership(userId, panel)

            if membership then
                seen[userId] = true
                local identity = fullIdentity(userId)

                roster[#roster + 1] = {
                    id = userId,
                    nome = identity.nome,
                    sobrenome = identity.sobrenome,
                    nomeCompleto = identity.full,
                    cargo = membership.role,
                    cargoLabel = panel.hierarchyLabel[membership.role] or membership.role,
                    rank = panel.hierarchyIndex[membership.role] or 999,
                    emServico = membership.onDuty == true,
                }
            end
        end
    end

    table.sort(roster, function(a, b)
        if a.rank ~= b.rank then return a.rank < b.rank end
        if a.nomeCompleto ~= b.nomeCompleto then return a.nomeCompleto < b.nomeCompleto end
        return a.id < b.id
    end)

    return roster
end

local function rankingData(panel, roster)
    local ids = {}
    local seen = {}
    local org = panel.cfg.organization
    local rows

    if panel.cfg.metric == "calls" then
        rows = exports.oxmysql:query_async([[
            SELECT user_id FROM m_ponto_hours WHERE org = ?
            UNION
            SELECT medic_id AS user_id FROM m_hospital_calls
            UNION
            SELECT actor_id AS user_id FROM m_hospital_sector_calls WHERE department = 'hospital'
            LIMIT 500
        ]], { org }) or {}
    else
        rows = exports.oxmysql:query_async([[
            SELECT user_id
            FROM m_ponto_hours
            WHERE org = ?
            LIMIT 500
        ]], { org }) or {}
    end

    for _, row in ipairs(rows) do
        local id = tonumber(row.user_id)
        if id and not seen[id] then
            seen[id] = true
            ids[#ids + 1] = id
        end
    end

    for _, member in ipairs(roster or {}) do
        if not seen[member.id] then
            seen[member.id] = true
            ids[#ids + 1] = member.id
        end
    end

    local counts = panel.cfg.metric == "calls" and hospitalCallCounts() or {}
    local ranking = {}

    for _, userId in ipairs(ids) do
        local membership = getPontoMembership(userId, panel)

        if membership then
            local identity = fullIdentity(userId)
            local service = getServiceInfo(userId, panel)

            ranking[#ranking + 1] = {
                id = userId,
                nome = identity.nome,
                sobrenome = identity.sobrenome,
                nomeCompleto = identity.full,
                cargo = membership.role,
                cargoLabel = panel.hierarchyLabel[membership.role] or membership.role,
                rank = panel.hierarchyIndex[membership.role] or 999,
                segundos = service.seconds,
                tempo = service.formatted,
                chamados = counts[userId] or 0,
                online = vRP.getUserSource(userId) ~= nil,
                emServico = membership.onDuty == true,
            }
        end
    end

    table.sort(ranking, function(a, b)
        if a.segundos ~= b.segundos then return a.segundos > b.segundos end

        if panel.cfg.metric == "calls" and a.chamados ~= b.chamados then
            return a.chamados > b.chamados
        end

        return a.id < b.id
    end)

    for i, row in ipairs(ranking) do
        row.posicao = i
    end

    return ranking
end

-- Contadores operacionais do m_aux, separados por setor e por ação.
local ProductivityColumns = {
    medic = {
        {key="quick_treatment", label="Trat. rápido"},
        {key="complete_treatment", label="Trat. completo"},
        {key="revive", label="Reanimações"},
        {key="calls_accepted", label="Chamados aceitos"},
        {key="m_aviso", label="Avisos"}
    },
    mecanic = {
        {key="r_motor", label="Motor"},
        {key="r_pneu", label="Pneus"},
        {key="r_full", label="Reparo completo"},
        {key="calls_accepted", label="Chamados aceitos"}
    }
}

local function productivityData(panel, roster, ranking)
    local role = panel.cfg.productivityRole
    local columns = ProductivityColumns[role] or {}
    local ok, records = pcall(function()
        return exports["m_aux"]:getServiceProductivity(role, role == "mecanic" and panel.cfg.organization or nil)
    end)
    if not ok or type(records) ~= "table" then
        return {available=false, columns=columns, rows={}, message="Produtividade indisponível. Verifique m_aux e o banco de dados."}
    end
    local callsOk, callCounts = pcall(function()
        if role == "medic" then return hospitalCallCounts() end
        local out = {}
        local rows = exports.oxmysql:query_async([[
            SELECT actor_id, COUNT(*) AS total FROM m_hospital_sector_calls
            WHERE department = 'mechanic' AND organization = ? GROUP BY actor_id
        ]], {panel.cfg.organization})
        if type(rows) ~= "table" then error("Consulta de chamados indisponível") end
        for _, row in ipairs(rows) do out[tonumber(row.actor_id)] = tonumber(row.total) or 0 end
        return out
    end)
    if not callsOk then
        return {available=false, columns=columns, rows={}, message="Não foi possível consultar os chamados aceitos."}
    end
    local ids, counts = {}, {}
    for _, member in ipairs(roster or {}) do ids[member.id] = true end
    for _, member in ipairs(ranking or {}) do ids[member.id] = true end
    for _, record in ipairs(records) do
        local id = tonumber(record.user_id)
        if id then
            ids[id] = true
            counts[id] = counts[id] or {}
            counts[id][record.action_type] = tonumber(record.total) or 0
        end
    end
    for id, total in pairs(callCounts) do
        ids[id] = true
        counts[id] = counts[id] or {}
        counts[id].calls_accepted = total
    end
    local rows, totals = {}, {}
    for id in pairs(ids) do
        -- A mesma regra de associação do painel também atende membros offline.
        local membership = getPontoMembership(id, panel)
        if membership then
            local values, total = {}, 0
            for _, column in ipairs(columns) do
                values[column.key] = (counts[id] or {})[column.key] or 0
                total = total + values[column.key]
                totals[column.key] = (totals[column.key] or 0) + values[column.key]
            end
            rows[#rows+1] = {
                id=id, name=fullIdentity(id).full,
                role=panel.hierarchyLabel[membership.role] or membership.role,
                counts=values, total=total,
                online=vRP.getUserSource(id) ~= nil
            }
        end
    end
    table.sort(rows, function(a,b)
        if a.total ~= b.total then return a.total > b.total end
        return a.id < b.id
    end)
    return {available=true, columns=columns, rows=rows, totals=totals}
end

local function panelPayload(panel)
    local cfg = panel.cfg
    local texts = cfg.texts or {}
    local initialRole = cfg.initialRole or panel.hierarchyGroupByIndex[#(cfg.hierarchy or {})]

    return {
        key = panel.key,
        organization = cfg.organization,
        displayName = cfg.displayName or cfg.organization,
        brand = cfg.brand or cfg.displayName or cfg.organization,
        brandSubtitle = cfg.brandSubtitle or "Gestão de equipe",
        theme = cfg.theme or "hospital",
        icon = cfg.icon or "medical",
        metric = cfg.metric or "hours",
        initialRole = initialRole,
        initialRoleLabel = panel.hierarchyLabel[initialRole] or initialRole or "",
        texts = {
            actorStatus = texts.actorStatus or "Equipe",
            teamTitle = texts.teamTitle or ("Equipe da " .. panelName(panel)),
            teamSubtitle = texts.teamSubtitle or "Membros online organizados por hierarquia.",
            teamHeading = texts.teamHeading or "Equipe online",
            teamDescription = texts.teamDescription or "ID, identificação, cargo e situação no bate-ponto.",
            rankingTitle = texts.rankingTitle or ("Ranking da " .. panelName(panel)),
            rankingSubtitle = texts.rankingSubtitle or "Tempo de serviço registrado pelo bate-ponto.",
            rankingHeading = texts.rankingHeading or "Ranking de horas",
            rankingDescription = texts.rankingDescription or "Horas acumuladas em serviço.",
            personColumn = texts.personColumn or "Membro",
            teamEmpty = texts.teamEmpty or "Nenhum membro está online agora.",
            rankingEmpty = texts.rankingEmpty or "Ainda não existem dados de serviço.",
            thirdStatLabel = texts.thirdStatLabel or "Horas acumuladas",
            thirdStatSmall = texts.thirdStatSmall or "horas em serviço",
            hireDescription = texts.hireDescription or "O novo funcionário deverá bater o ponto para entrar em serviço.",
        }
    }
end

local function dashboardFor(src, panelKey)
    local panel = getPanel(panelKey)
    if not panel then
        return { ok = false, message = "Painel de organização inválido." }
    end

    local actor, err = actorContext(src, panel)
    if not actor then
        return { ok = false, message = err }
    end

    if not sectorCallsReady then return {ok=false, message="Aguarde a inicialização do banco do painel."} end
    local roster = onlineRoster(panel)
    local ranking = rankingData(panel, roster)

    local totalSeconds, totalCalls, onDuty = 0, 0, 0

    for _, row in ipairs(ranking) do
        totalSeconds = totalSeconds + (tonumber(row.segundos) or 0)
        totalCalls = totalCalls + (tonumber(row.chamados) or 0)
    end

    for _, row in ipairs(roster) do
        if row.emServico then
            onDuty = onDuty + 1
        end
    end

    return {
        ok = true,
        panel = panelPayload(panel),
        actor = actor,
        roster = roster,
        ranking = ranking,
        productivity = productivityData(panel, roster, ranking),
        hierarchy = panel.cfg.hierarchy,
        stats = {
            online = #roster,
            onDuty = onDuty,
            totalHours = math.floor(totalSeconds / 3600),
            calls = totalCalls,
        }
    }
end

-- Resolve o /mec no servidor, sem confiar em dados recebidos do cliente.
-- Havendo dois vínculos, prioriza o único em serviço. Se ambos tiverem
-- a mesma situação, não expõe uma das organizações arbitrariamente.
local function mechanicPanelForUser(userId)
    local matches, onDuty = {}, {}
    for _, key in ipairs({"SportRacer", "LSCustoms"}) do
        local panel = getPanel(key)
        local membership = getPontoMembership(userId, panel)
        if membership then
            matches[#matches + 1] = panel
            if membership.onDuty then onDuty[#onDuty + 1] = panel end
        end
    end
    if #onDuty == 1 then return onDuty[1] end
    if #matches == 1 then return matches[1] end
    if #matches == 0 then return nil, "Você não pertence à Sport Racer nem à LS Customs." end
    return nil, "Você possui vínculo com duas oficinas. Ative o ponto em apenas uma delas para usar /mec."
end

function HospitalAPI.getMechanicPanelData()
    local src = source
    local userId = vRP.getUserId(src)
    if not userId then return {ok=false, message="Jogador não identificado."} end
    local panel, err = mechanicPanelForUser(userId)
    if not panel then return {ok=false, message=err} end
    return dashboardFor(src, panel.key)
end

-- ============================================================================
-- Gestão
-- ============================================================================
local function logAction(panel, actorId, targetId, action, fromRole, toRole)
    exports.oxmysql:executeSync([[
        INSERT INTO m_hospital_actions
            (org, actor_id, target_id, action_type, from_role, to_role, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        panel.cfg.organization,
        tonumber(actorId),
        tonumber(targetId),
        tostring(action),
        fromRole and tostring(fromRole) or nil,
        toRole and tostring(toRole) or nil,
        os.time()
    })
end

local function refreshPanels(panelKey)
    TriggerClientEvent("m_hospital:refreshPanel", -1, panelKey)
end

local function canManageTarget(actor, targetMembership, panel)
    if not actor.canManage then
        return false, "Seu cargo não pode gerenciar a equipe."
    end

    if not targetMembership then return true end

    local targetRank = panel.hierarchyIndex[targetMembership.role] or 999
    if targetRank <= actor.rank then
        return false, "Você não pode gerenciar um cargo igual ou superior ao seu."
    end

    return true
end

-- ============================================================================
-- Funções originais do vrp_hospital
-- ============================================================================
function LegacyAPI.checkServices()
    local source = source
    local userId = vRP.getUserId(source)
    if not userId then return false end

    local medics = vRP.getUsersByPermission("perm.unizk") or {}
    return #medics == 0
end

RegisterServerEvent("target:deitarpaciente")
AddEventHandler("target:deitarpaciente", function()
    local source = source
    local nearest = vRPclient.getNearestPlayer(source, 3)

    if nearest then
        TriggerClientEvent("event:deitarpaciente", nearest)
    end
end)


-- ============================================================================
-- DIAGNÓSTICO MÉDICO
-- ============================================================================
local diagnosisSequence = 0
local diagnosisSessions = {}
local diagnosisByMedic = {}
local diagnosisByPatient = {}
local validDiagnoses = {}

local function diagnosisKey(medicId, patientId)
    return ("%s:%s"):format(tostring(tonumber(medicId) or medicId), tostring(tonumber(patientId) or patientId))
end

local function diagnosisCoords(playerSource)
    if not playerSource then return nil end
    local x, y, z = vRPclient.getPosition(playerSource)
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not x or not y or not z then return nil end
    return { x = x, y = y, z = z }
end

local function diagnosisDistance(a, b)
    if not a or not b then return math.huge end
    local dx = (a.x or 0.0) - (b.x or 0.0)
    local dy = (a.y or 0.0) - (b.y or 0.0)
    local dz = (a.z or 0.0) - (b.z or 0.0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function cleanupDiagnosisSession(sessionId)
    sessionId = tonumber(sessionId)
    local session = sessionId and diagnosisSessions[sessionId] or nil
    if not session then return nil end

    diagnosisSessions[sessionId] = nil

    if diagnosisByMedic[session.medicId] == sessionId then
        diagnosisByMedic[session.medicId] = nil
    end

    if diagnosisByPatient[session.patientId] == sessionId then
        diagnosisByPatient[session.patientId] = nil
    end

    return session
end

local function diagnosisStatus(percent)
    percent = tonumber(percent) or 0.0

    if percent < 20.0 then
        return "CRÍTICO", "critical"
    elseif percent < 40.0 then
        return "GRAVE", "severe"
    elseif percent < 60.0 then
        return "MODERADO", "moderate"
    elseif percent < 80.0 then
        return "ESTÁVEL", "stable"
    end

    return "BOM", "good"
end

local function randomDiagnosis()
    local cfg = HospitalConfig.Diagnosis or {}
    local injuries = cfg.injuries or {}

    if #injuries <= 0 then
        return {
            part = "chest",
            partLabel = "Tórax",
            diagnosis = "Contusão torácica"
        }
    end

    local injury = injuries[math.random(1, #injuries)]
    local diagnoses = injury.diagnoses or {}
    local text = #diagnoses > 0 and diagnoses[math.random(1, #diagnoses)] or "Trauma localizado"

    return {
        part = tostring(injury.part or "chest"),
        partLabel = tostring(injury.label or "Região afetada"),
        diagnosis = tostring(text)
    }
end

local function getDiagnosisTreatmentPrice()
    if GetResourceState("m_aux") ~= "started" then
        return 0
    end

    local ok, value = pcall(function()
        return exports["m_aux"]:GetDiagnosticTreatmentPrice()
    end)

    return ok and math.max(0, math.floor(tonumber(value) or 0)) or 0
end

local function buildDiagnosisPayload(session, snapshot)
    snapshot = type(snapshot) == "table" and snapshot or {}
    local identity = fullIdentity(session.patientId)
    local percent = math.max(0.0, math.min(100.0, tonumber(snapshot.percent) or 0.0))
    local statusLabel, statusClass = diagnosisStatus(percent)

    return {
        sessionId = session.id,
        patientId = session.patientId,
        patientName = identity.full,
        health = {
            current = math.max(0, math.floor(tonumber(snapshot.current) or 0)),
            maximum = math.max(0, math.floor(tonumber(snapshot.maximum) or 0)),
            percent = math.floor(percent + 0.5)
        },
        status = statusLabel,
        statusClass = statusClass,
        injuredPart = session.injury.part,
        injuredPartLabel = session.injury.partLabel,
        diagnosis = session.injury.diagnosis,
        treatmentPrice = getDiagnosisTreatmentPrice(),
        validSeconds = math.max(30, math.floor(tonumber(HospitalConfig.Diagnosis and HospitalConfig.Diagnosis.validSeconds) or 600))
    }
end

function HospitalAPI.startDiagnosis()
    local source = source
    local cfg = HospitalConfig.Diagnosis or {}

    if cfg.enabled == false then
        return { ok = false, message = "O sistema de diagnóstico está desativado." }
    end

    local medicId = vRP.getUserId(source)
    if not medicId or not vRP.hasPermission(medicId, tostring(cfg.permission or "perm.unizk")) then
        return { ok = false, message = "Você não possui permissão médica para realizar diagnósticos." }
    end

    if diagnosisByMedic[medicId] then
        return { ok = false, message = "Você já possui um diagnóstico em andamento." }
    end

    local radius = math.max(1.0, tonumber(cfg.patientRadius) or 3.5)
    local targetSource = vRPclient.getNearestPlayer(source, radius)
    if not targetSource or targetSource == source then
        return { ok = false, message = "Não há nenhum paciente próximo." }
    end

    local patientId = vRP.getUserId(targetSource)
    if not patientId then
        return { ok = false, message = "Não foi possível identificar o paciente." }
    end

    if diagnosisByPatient[patientId] then
        return { ok = false, message = "Este paciente já está sendo diagnosticado por outro médico." }
    end

    local snapshot = HospitalClient.getHealthSnapshot(targetSource)
    if type(snapshot) ~= "table" then
        return { ok = false, message = "Não foi possível obter os sinais vitais do paciente." }
    end

    if (tonumber(snapshot.percent) or 0) <= 0 then
        return { ok = false, message = "O paciente está em coma. Utilize a opção Reanimar." }
    end

    diagnosisSequence = diagnosisSequence + 1
    local sessionId = diagnosisSequence

    local session = {
        id = sessionId,
        medicId = medicId,
        medicSource = source,
        patientId = patientId,
        patientSource = targetSource,
        startedAt = os.time(),
        completed = false,
        injury = randomDiagnosis()
    }

    diagnosisSessions[sessionId] = session
    diagnosisByMedic[medicId] = sessionId
    diagnosisByPatient[patientId] = sessionId

    notify(targetSource, "aviso", "O médico está realizando um diagnóstico clínico em você.", 6000)

    return {
        ok = true,
        sessionId = sessionId,
        targetServerId = targetSource,
        thinkSeconds = math.max(1, math.floor(tonumber(cfg.thinkSeconds) or 5))
    }
end

function HospitalAPI.completeDiagnosis(sessionId)
    local source = source
    sessionId = tonumber(sessionId)

    local session = sessionId and diagnosisSessions[sessionId] or nil
    if not session or session.medicSource ~= source then
        return { ok = false, message = "Este diagnóstico não é mais válido." }
    end

    local medicSource = vRP.getUserSource(session.medicId)
    local patientSource = vRP.getUserSource(session.patientId)
    if not medicSource or not patientSource then
        cleanupDiagnosisSession(sessionId)
        return { ok = false, message = "O diagnóstico foi cancelado porque um dos envolvidos desconectou." }
    end

    local radius = math.max(1.0, tonumber(HospitalConfig.Diagnosis and HospitalConfig.Diagnosis.patientRadius) or 3.5)
    if diagnosisDistance(diagnosisCoords(medicSource), diagnosisCoords(patientSource)) > (radius + 1.0) then
        cleanupDiagnosisSession(sessionId)
        return { ok = false, message = "O paciente se afastou durante o diagnóstico." }
    end

    local snapshot = HospitalClient.getHealthSnapshot(patientSource)
    if type(snapshot) ~= "table" or (tonumber(snapshot.percent) or 0) <= 0 then
        cleanupDiagnosisSession(sessionId)
        return { ok = false, message = "O paciente entrou em coma. Utilize a opção Reanimar." }
    end

    session.completed = true
    session.completedAt = os.time()
    session.patientSource = patientSource
    session.medicSource = medicSource

    local validSeconds = math.max(30, math.floor(tonumber(HospitalConfig.Diagnosis and HospitalConfig.Diagnosis.validSeconds) or 600))
    validDiagnoses[diagnosisKey(session.medicId, session.patientId)] = {
        expiresAt = os.time() + validSeconds,
        sessionId = sessionId
    }

    return {
        ok = true,
        data = buildDiagnosisPayload(session, snapshot)
    }
end

function HospitalAPI.closeDiagnosis(sessionId)
    local source = source
    sessionId = tonumber(sessionId)

    local session = sessionId and diagnosisSessions[sessionId] or nil
    if session and session.medicSource == source then
        cleanupDiagnosisSession(sessionId)
    end

    return { ok = true }
end

function HospitalAPI.medicateDiagnosis(sessionId)
    local source = source
    sessionId = tonumber(sessionId)

    local session = sessionId and diagnosisSessions[sessionId] or nil
    if not session or session.medicSource ~= source or session.completed ~= true then
        return { ok = false, message = "Realize o diagnóstico antes de medicar o paciente." }
    end

    local patientSource = vRP.getUserSource(session.patientId)
    if not patientSource then
        cleanupDiagnosisSession(sessionId)
        return { ok = false, message = "O paciente não está mais conectado." }
    end

    local radius = math.max(1.0, tonumber(HospitalConfig.Diagnosis and HospitalConfig.Diagnosis.patientRadius) or 3.5)
    if diagnosisDistance(diagnosisCoords(source), diagnosisCoords(patientSource)) > (radius + 1.0) then
        return { ok = false, message = "Aproxime-se novamente do paciente para medicá-lo." }
    end

    if not exports["m_hospital"]:HasValidDiagnosis(session.medicId, session.patientId) then
        return { ok = false, message = "O diagnóstico expirou. Realize uma nova avaliação." }
    end

    if GetResourceState("m_aux") ~= "started" then
        return { ok = false, message = "O sistema de tratamento médico não está disponível." }
    end

    local ok, result = pcall(function()
        return exports["m_aux"]:StartDiagnosedTreatment(source, patientSource)
    end)

    if not ok then
        return { ok = false, message = "Não foi possível iniciar o tratamento pós-diagnóstico." }
    end

    if type(result) ~= "table" then
        result = { ok = result == true }
    end

    if result.ok == true then
        cleanupDiagnosisSession(sessionId)
    end

    return result
end

exports("GetDiagnosisThresholdPercent", function()
    return math.max(1, math.min(100, tonumber(HospitalConfig.Diagnosis and HospitalConfig.Diagnosis.requiredBelowPercent) or 40))
end)

exports("HasValidDiagnosis", function(medicId, patientId)
    medicId = tonumber(medicId)
    patientId = tonumber(patientId)
    if not medicId or not patientId then return false end

    local key = diagnosisKey(medicId, patientId)
    local data = validDiagnoses[key]

    if not data then return false end
    if (tonumber(data.expiresAt) or 0) <= os.time() then
        validDiagnoses[key] = nil
        return false
    end

    return true
end)

exports("ConsumeDiagnosis", function(medicId, patientId)
    medicId = tonumber(medicId)
    patientId = tonumber(patientId)
    if not medicId or not patientId then return false end

    validDiagnoses[diagnosisKey(medicId, patientId)] = nil
    return true
end)

AddEventHandler("playerDropped", function()
    local droppedSource = source

    for sessionId, session in pairs(diagnosisSessions) do
        if session.medicSource == droppedSource or session.patientSource == droppedSource then
            cleanupDiagnosisSession(sessionId)
        end
    end

    for key, data in pairs(validDiagnoses) do
        if not data or (tonumber(data.expiresAt) or 0) <= os.time() then
            validDiagnoses[key] = nil
        end
    end
end)

-- ============================================================================
-- Painéis Hospital / Sport Racer / LS Customs
-- ============================================================================
function HospitalAPI.getPanelData(panelKey)
    return dashboardFor(source, panelKey)
end

function HospitalAPI.hire(panelKey, targetId)
    local source = source
    local panel = getPanel(panelKey)

    if not panel then
        return { ok = false, message = "Painel inválido." }
    end

    local actor, err = actorContext(source, panel)
    if not actor then return { ok = false, message = err } end

    if not actor.canHire then
        return { ok = false, message = "Seu cargo não possui permissão para contratar." }
    end

    targetId = tonumber(targetId)
    if not targetId then
        return { ok = false, message = "Informe um ID válido." }
    end

    if targetId == actor.userId then
        return { ok = false, message = "Você não pode contratar a si mesmo." }
    end

    local targetSource = vRP.getUserSource(targetId)
    if not targetSource then
        return { ok = false, message = "O jogador precisa estar online para ser contratado." }
    end

    if getPontoMembership(targetId, panel) then
        return { ok = false, message = ("Este jogador já faz parte da %s."):format(panelName(panel)) }
    end

    if GetResourceState("m_ponto") ~= "started" then
        return { ok = false, message = "O bate-ponto está indisponível. Tente novamente em instantes." }
    end

    local initialRole = panel.cfg.initialRole or panel.hierarchyGroupByIndex[#(panel.cfg.hierarchy or {})]
    if not initialRole then
        return { ok = false, message = "Cargo inicial não configurado." }
    end

    local ok, applied = pcall(function()
        return exports["m_ponto"]:setMembershipRole(
            targetId,
            panel.cfg.organization,
            initialRole
        )
    end)

    if not ok or applied ~= true then
        return { ok = false, message = ("Não foi possível registrar o novo funcionário na %s."):format(panelName(panel)) }
    end

    logAction(panel, actor.userId, targetId, "hire", nil, initialRole)

    local who = fullIdentity(targetId)
    local roleLabel = panel.hierarchyLabel[initialRole] or initialRole

    notify(
        targetSource,
        "sucesso",
        ("Você foi contratado na %s como %s."):format(panelName(panel), roleLabel),
        7000
    )

    notify(
        source,
        "sucesso",
        ("%s foi contratado com sucesso."):format(who.full),
        5000
    )

    refreshPanels(panel.key)

    return {
        ok = true,
        message = "Funcionário contratado com sucesso.",
        data = dashboardFor(source, panel.key)
    }
end

function HospitalAPI.promote(panelKey, targetId)
    local source = source
    local panel = getPanel(panelKey)

    if not panel then
        return { ok = false, message = "Painel inválido." }
    end

    local actor, err = actorContext(source, panel)
    if not actor then return { ok = false, message = err } end

    targetId = tonumber(targetId)
    if not targetId then
        return { ok = false, message = "ID inválido." }
    end

    if targetId == actor.userId then
        return { ok = false, message = "Você não pode promover a si mesmo." }
    end

    local membership = getPontoMembership(targetId, panel)
    if not membership then
        return { ok = false, message = ("Este jogador não faz parte da %s."):format(panelName(panel)) }
    end

    local allowed, reason = canManageTarget(actor, membership, panel)
    if not allowed then
        return { ok = false, message = reason }
    end

    local currentRank = panel.hierarchyIndex[membership.role]
    if not currentRank or currentRank <= 1 then
        return { ok = false, message = "Este funcionário já está no maior cargo disponível." }
    end

    local newRole = panel.hierarchyGroupByIndex[currentRank - 1]
    if not newRole then
        return { ok = false, message = "Próximo cargo não encontrado na hierarquia." }
    end

    -- Nunca permite que alguém promova outro jogador para um cargo acima
    -- da própria autoridade.
    local newRank = panel.hierarchyIndex[newRole] or 999
    if newRank < actor.rank then
        return { ok = false, message = "Você não pode promover alguém acima do seu próprio cargo." }
    end

    if GetResourceState("m_ponto") ~= "started" then
        return { ok = false, message = "O bate-ponto está indisponível." }
    end

    local ok, applied = pcall(function()
        return exports["m_ponto"]:setMembershipRole(
            targetId,
            panel.cfg.organization,
            newRole
        )
    end)

    if not ok or applied ~= true then
        return { ok = false, message = "Não foi possível aplicar a promoção." }
    end

    logAction(panel, actor.userId, targetId, "promote", membership.role, newRole)

    local targetSource = vRP.getUserSource(targetId)
    local who = fullIdentity(targetId)
    local roleLabel = panel.hierarchyLabel[newRole] or newRole

    notify(targetSource, "sucesso", ("Você foi promovido para %s."):format(roleLabel), 7000)
    notify(source, "sucesso", ("%s foi promovido para %s."):format(who.full, roleLabel), 5000)

    refreshPanels(panel.key)

    return {
        ok = true,
        message = "Promoção realizada com sucesso.",
        data = dashboardFor(source, panel.key)
    }
end

function HospitalAPI.dismiss(panelKey, targetId)
    local source = source
    local panel = getPanel(panelKey)

    if not panel then
        return { ok = false, message = "Painel inválido." }
    end

    local actor, err = actorContext(source, panel)
    if not actor then return { ok = false, message = err } end

    targetId = tonumber(targetId)
    if not targetId then
        return { ok = false, message = "ID inválido." }
    end

    if targetId == actor.userId then
        return { ok = false, message = "Você não pode exonerar a si mesmo." }
    end

    local membership = getPontoMembership(targetId, panel)
    if not membership then
        return { ok = false, message = ("Este jogador não faz parte da %s."):format(panelName(panel)) }
    end

    local allowed, reason = canManageTarget(actor, membership, panel)
    if not allowed then
        return { ok = false, message = reason }
    end

    if GetResourceState("m_ponto") ~= "started" then
        return { ok = false, message = "O bate-ponto está indisponível." }
    end

    local ok, removed = pcall(function()
        return exports["m_ponto"]:removeMembership(
            targetId,
            panel.cfg.organization
        )
    end)

    if not ok or removed ~= true then
        return { ok = false, message = "Não foi possível exonerar o funcionário." }
    end

    logAction(panel, actor.userId, targetId, "dismiss", membership.role, nil)

    local targetSource = vRP.getUserSource(targetId)
    local who = fullIdentity(targetId)

    notify(
        targetSource,
        "aviso",
        ("Você foi exonerado da %s."):format(panelName(panel)),
        7000
    )

    notify(
        source,
        "sucesso",
        ("%s foi exonerado da %s."):format(who.full, panelName(panel)),
        5000
    )

    refreshPanels(panel.key)

    return {
        ok = true,
        message = "Funcionário exonerado com sucesso.",
        data = dashboardFor(source, panel.key)
    }
end

-- ============================================================================
-- Integração: chamados aceitos no m_paineladm_v2
-- Evento legado usado apenas para chamados do Hospital.
-- ============================================================================
AddEventHandler("m_hospital:registerCallAccepted", function(medicId, callId, patientId, message)
    medicId = tonumber(medicId)
    callId = tonumber(callId)
    patientId = tonumber(patientId)

    if not medicId or not callId then return end

    local hospitalPanel = getPanel("Hospital")
    if not hospitalPanel then return end

    local membership = getPontoMembership(medicId, hospitalPanel)
    if not membership then return end

    exports.oxmysql:executeSync([[
        INSERT IGNORE INTO m_hospital_calls
            (call_id, medic_id, patient_id, message, accepted_at)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        callId,
        medicId,
        patientId,
        tostring(message or ""),
        os.time()
    })

    refreshPanels("Hospital")
end)

-- ============================================================================
-- Banco
-- ============================================================================
exports("RegisterSectorCallAccepted", function(data)
    if GetInvokingResource() ~= "m_paineladm_v2" or not sectorCallsReady or type(data) ~= "table" then return false end
    if data.department ~= "hospital" and data.department ~= "mechanic" then return false end
    local id, actor, created, accepted = tonumber(data.callId), tonumber(data.actorId), tonumber(data.createdAt), tonumber(data.acceptedAt)
    if not id or id < 1 or id % 1 ~= 0 or not actor or actor < 1 or actor % 1 ~= 0
        or not created or created < 1 or not accepted or accepted < 1 then return false end
    local organization = "Hospital"
    if data.department == "mechanic" then
        -- Chamados antigos sem organização permanecem como legacy/indefinidos;
        -- nunca atribuí-los a uma oficina apenas pelo cargo atual do jogador.
        organization = tostring(data.organization or "")
        if organization ~= "SportRacer" and organization ~= "LSCustoms"
            and organization ~= "RedLine" then
            organization = "" -- não contam em nenhuma das oficinas
        end
    end
    local ok, result = pcall(function()
        return exports.oxmysql:executeSync([[
            INSERT IGNORE INTO m_hospital_sector_calls
                (department, call_id, created_at, actor_id, patient_id, accepted_at, organization)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], {data.department, id, created, actor, tonumber(data.patientId) or 0, accepted, organization})
    end)
    if ok and result ~= nil and result ~= false then
        if data.department == "hospital" then
            refreshPanels("Hospital")
        elseif organization == "SportRacer" then
            refreshPanels("SportRacer")
        elseif organization == "LSCustoms" then
            refreshPanels("LSCustoms")
        end
        return true
    end
    return false
end)

CreateThread(function()
    exports.oxmysql:executeSync([[
        CREATE TABLE IF NOT EXISTS m_hospital_sector_calls (
            department VARCHAR(20) NOT NULL,
            call_id BIGINT NOT NULL,
            created_at BIGINT NOT NULL,
            actor_id INT NOT NULL,
            patient_id INT NOT NULL DEFAULT 0,
            accepted_at BIGINT NOT NULL,
            organization VARCHAR(40) NOT NULL DEFAULT '',
            PRIMARY KEY (department, call_id, created_at),
            INDEX idx_sector_actor (department, actor_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    -- Upgrade seguro: as linhas pré-existentes não identificavam a oficina.
    local orgColumns = exports.oxmysql:query_async([[
        SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'm_hospital_sector_calls'
          AND COLUMN_NAME = 'organization' LIMIT 1
    ]]) or {}
    if #orgColumns == 0 then
        exports.oxmysql:executeSync([[
            ALTER TABLE m_hospital_sector_calls
            ADD COLUMN organization VARCHAR(40) NOT NULL DEFAULT ''
        ]])
    end
    exports.oxmysql:executeSync([[
        CREATE TABLE IF NOT EXISTS m_hospital_calls (
            call_id INT NOT NULL PRIMARY KEY,
            medic_id INT NOT NULL,
            patient_id INT NULL,
            message VARCHAR(500) NULL,
            accepted_at BIGINT NOT NULL,
            INDEX idx_hospital_calls_medic (medic_id),
            INDEX idx_hospital_calls_time (accepted_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    exports.oxmysql:executeSync([[
        CREATE TABLE IF NOT EXISTS m_hospital_actions (
            id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
            org VARCHAR(100) NOT NULL DEFAULT 'Hospital',
            actor_id INT NOT NULL,
            target_id INT NOT NULL,
            action_type VARCHAR(30) NOT NULL,
            from_role VARCHAR(100) NULL,
            to_role VARCHAR(100) NULL,
            created_at BIGINT NOT NULL,
            INDEX idx_hospital_actions_org (org),
            INDEX idx_hospital_actions_actor (actor_id),
            INDEX idx_hospital_actions_target (target_id),
            INDEX idx_hospital_actions_time (created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Migração para instalações antigas onde a tabela ainda não possuía org.
    local columns = exports.oxmysql:query_async([[
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'm_hospital_actions'
          AND COLUMN_NAME = 'org'
        LIMIT 1
    ]]) or {}

    if #columns == 0 then
        exports.oxmysql:executeSync([[
            ALTER TABLE m_hospital_actions
            ADD COLUMN org VARCHAR(100) NOT NULL DEFAULT 'Hospital' AFTER id
        ]])

        pcall(function()
            exports.oxmysql:executeSync([[
                ALTER TABLE m_hospital_actions
                ADD INDEX idx_hospital_actions_org (org)
            ]])
        end)
    end
    sectorCallsReady = true
end)
