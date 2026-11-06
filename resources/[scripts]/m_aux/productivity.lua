-- Exclusivamente server-side: não há evento de rede para incrementar contadores.
AuxProductivity = {}
local ready, initializing = false, false
local validActions = {
    medic = { quick_treatment=true, complete_treatment=true, revive=true, m_cv=true, m_rv=true, m_aviso=true },
    mecanic = { r_motor=true, r_pneu=true, r_full=true, r_cobrar=true, r_avisomec=true }
}

local function ensureTable()
    while initializing do Wait(50) end
    if ready then return true end
    initializing = true
    local ok, result = pcall(function()
        return exports.oxmysql:executeSync([[
            CREATE TABLE IF NOT EXISTS m_aux_productivity (
                service_role VARCHAR(20) NOT NULL,
                user_id INT NOT NULL,
                action_type VARCHAR(40) NOT NULL,
                total BIGINT UNSIGNED NOT NULL DEFAULT 0,
                last_at BIGINT NOT NULL,
                PRIMARY KEY (service_role, user_id, action_type)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
    end)
    ready = ok and result ~= nil and result ~= false
    initializing = false
    if not ready then print('[m_aux] Não foi possível inicializar produtividade: '..tostring(result)) end
    return ready
end

-- Mapeia as oficinas pelos cargos REAIS do groups.json. Não utiliza somente
-- perm.mecanica (compartilhada por Sport Racer, LS Customs e RedLine).
local mechanicGroups = {
    SportRacer = { "LiderSPORTRACER", "SubLiderSPORTRACER", "GerenteSPORTRACER",
                   "RecrutadorSPORTRACER", "MembroSPORTRACER", "NovatoSPORTRACER" },
    LSCustoms = { "LiderLSCustoms", "SubLiderLSCustoms", "GerenteGeralLSCustoms",
                  "GerenteLSCustoms", "SupervisorLSCustoms", "MecanicoLSCustoms", "EstagiarioLSCustoms" },
    RedLine = { "LiderRedLine", "SubLiderRedLine", "GerenteRedLine",
                "RecrutadorRedLine", "MembroRedLine", "NovatoRedLine" },
}
local function mechanicOrg(uid)
    local groups = nil
    local ok, result = pcall(function()
        local Proxy = module("vrp", "lib/Proxy")
        local vRP = Proxy.getInterface("vRP")
        return vRP.getUserGroups(uid)
    end)
    if ok and type(result) == "table" then groups = result end
    local found, duty = {}, {}
    for org, names in pairs(mechanicGroups) do
        local isActive = false
        for _, name in ipairs(names) do
            if groups and groups[name] ~= nil then isActive = true; break end
        end
        if isActive then found[#found+1] = org end
        if GetResourceState("m_ponto") == "started" then
            local success, member = pcall(function() return exports["m_ponto"]:getMembership(uid, org) end)
            if success and type(member) == "table" and member.onDuty == true then
                duty[#duty+1] = org
                if not isActive then found[#found+1] = org end
            end
        end
    end
    if #duty == 1 then return duty[1] end
    if #found == 1 then return found[1] end
    return nil -- Não inventar atribuição quando não há oficina única.
end

local orgTableReady = false
local function ensureOrgTable()
    if orgTableReady then return true end
    local ok, result = pcall(function()
        return exports.oxmysql:executeSync([[
            CREATE TABLE IF NOT EXISTS m_aux_productivity_org (
                service_role VARCHAR(20) NOT NULL,
                organization VARCHAR(40) NOT NULL,
                user_id INT NOT NULL,
                action_type VARCHAR(40) NOT NULL,
                total BIGINT UNSIGNED NOT NULL DEFAULT 0,
                last_at BIGINT NOT NULL,
                PRIMARY KEY (service_role, organization, user_id, action_type)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
    end)
    orgTableReady = ok and result ~= nil and result ~= false
    return orgTableReady
end

function AuxProductivity.record(role, uid, action)
    uid = tonumber(uid)
    if not uid or uid < 1 or not validActions[role] or not validActions[role][action] then return false end
    if not ensureTable() then return false end
    local org = role == "mecanic" and mechanicOrg(uid) or nil
    local ok, result = pcall(function()
        return exports.oxmysql:executeSync([[
            INSERT INTO m_aux_productivity (service_role, user_id, action_type, total, last_at)
            VALUES (?, ?, ?, 1, ?)
            ON DUPLICATE KEY UPDATE total = total + 1, last_at = VALUES(last_at)
        ]], {role, uid, action, os.time()})
    end)
    if not ok or result == nil or result == false then
        print(('[m_aux] Falha ao registrar produtividade %s/%s/%s: %s'):format(role, uid, action, tostring(result)))
        return false
    end
    -- Registro por organização é independente da tabela legada global.
    -- Apenas novos serviços podem ser classificados com segurança.
    if role == "mecanic" and org then
        if not ensureOrgTable() then
            print('[m_aux] Falha ao criar tabela de produtividade por oficina.')
            return false
        end
        local saved, response = pcall(function()
            return exports.oxmysql:executeSync([[
                INSERT INTO m_aux_productivity_org
                    (service_role, organization, user_id, action_type, total, last_at)
                VALUES (?, ?, ?, ?, 1, ?)
                ON DUPLICATE KEY UPDATE total = total + 1, last_at = VALUES(last_at)
            ]], {role, org, uid, action, os.time()})
        end)
        if not saved or response == nil or response == false then
            print(('[m_aux] Erro ao registrar serviço da %s: %s'):format(org, tostring(response)))
            return false
        end
    end
    return true
end

exports('getServiceProductivity', function(role, organization)
    if GetInvokingResource() ~= 'm_hospital' or not validActions[role] then return nil end
    if not ensureTable() then return nil end
    local ok, rows = pcall(function()
        if role == "mecanic" then
            if organization ~= "SportRacer" and organization ~= "LSCustoms"
                and organization ~= "RedLine" then return nil end
            if not ensureOrgTable() then return nil end
            return exports.oxmysql:query_async([[
                SELECT user_id, action_type, total, last_at
                FROM m_aux_productivity_org
                WHERE service_role = ? AND organization = ?
            ]], {role, organization})
        end
        return exports.oxmysql:query_async([[
            SELECT user_id, action_type, total, last_at
            FROM m_aux_productivity WHERE service_role = ?
        ]], {role})
    end)
    if not ok or type(rows) ~= 'table' then return nil end
    return rows
end)

CreateThread(ensureTable)
