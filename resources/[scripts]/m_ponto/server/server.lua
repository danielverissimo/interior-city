-- m_ponto - controle de serviço, ranking e equipamentos
-- Integração refinada com vRP + inventory.

local Duty = {}
local ActionLock = {}
local RankingCache = {}

local HEARTBEAT_SECONDS <const> = 60
local MAX_RANKING <const> = 10

local function notify(src, kind, message, time)
    if src and src > 0 then
        TriggerClientEvent("Notify", src, kind, message, time or 5)
    end
end

local function identityName(user_id)
    local identity = vRP.getUserIdentity(user_id)
    if not identity then return ("ID %s"):format(user_id) end
    return (("%s %s"):format(identity.nome or "", identity.sobrenome or "")):gsub("^%s+", ""):gsub("%s+$", "")
end

local function formatDuration(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return ("%02dh %02dm %02ds"):format(hours, minutes, secs)
end

local function formatClock(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return ("%02d:%02d:%02d"):format(hours, minutes, secs)
end

local function validDutyRole(org, role)
    return type(org) == "string"
        and type(role) == "string"
        and Config.Orgs[org] ~= nil
        and Config.Orgs[org].groups ~= nil
        and Config.Orgs[org].groups[role] ~= nil
end

local function getStoredDutyRole(user_id, org)
    if not user_id or not Config.Orgs[org] then return nil end
    local row = exports.oxmysql:singleSync(
        "SELECT duty_group FROM m_ponto_roles WHERE user_id = ? AND org = ? LIMIT 1",
        { user_id, org }
    )
    local role = row and tostring(row.duty_group or "") or ""
    if role ~= "" and validDutyRole(org, role) then
        return role
    end
    return nil
end

local function saveDutyRole(user_id, org, role)
    if not user_id or not validDutyRole(org, role) then return false end
    exports.oxmysql:executeSync([[
        INSERT INTO m_ponto_roles (user_id, org, duty_group)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE duty_group = VALUES(duty_group), updated_at = CURRENT_TIMESTAMP
    ]], { user_id, org, role })
    return true
end

local function getCurrentDutyRole(user_id, org)
    if not user_id or not Config.Orgs[org] then return nil end
    local userGroups = vRP.getUserGroups(user_id) or {}
    for group in pairs(userGroups) do
        if validDutyRole(org, group) then
            return group
        end
    end
    return nil
end

local function readOfflineGroups(user_id)
    local row = exports.oxmysql:singleSync(
        "SELECT dvalue FROM vrp_user_data WHERE user_id = ? AND dkey = ? LIMIT 1",
        { user_id, "vRP:datatable" }
    )
    if not row or type(row.dvalue) ~= "string" then return {} end

    local ok, data = pcall(json.decode, row.dvalue)
    if not ok or type(data) ~= "table" then return {} end
    if type(data.groups) ~= "table" then data.groups = {} end
    return data.groups
end

local function hasGroupSafe(user_id, group)
    if not user_id or not group or group == "" then return false end
    if vRP.getUserSource(user_id) then
        return vRP.hasGroup(user_id, group) == true
    end
    return readOfflineGroups(user_id)[group] ~= nil
end

local function setGroupSafe(user_id, group, enabled)
    if not user_id or not group or group == "" then return false end

    if vRP.getUserSource(user_id) then
        if enabled then
            vRP.addUserGroup(user_id, group)
            return vRP.hasGroup(user_id, group) == true
        end
        if vRP.hasGroup(user_id, group) then
            vRP.removeUserGroup(user_id, group)
        end
        return vRP.hasGroup(user_id, group) ~= true
    end

    local row = exports.oxmysql:singleSync(
        "SELECT dvalue FROM vrp_user_data WHERE user_id = ? AND dkey = ? LIMIT 1",
        { user_id, "vRP:datatable" }
    )
    if not row or type(row.dvalue) ~= "string" then return false end

    local ok, data = pcall(json.decode, row.dvalue)
    if not ok or type(data) ~= "table" then return false end
    data.groups = type(data.groups) == "table" and data.groups or {}

    if enabled then
        data.groups[group] = true
    else
        data.groups[group] = nil
    end

    exports.oxmysql:executeSync(
        "UPDATE vrp_user_data SET dvalue = ? WHERE user_id = ? AND dkey = ?",
        { json.encode(data), user_id, "vRP:datatable" }
    )
    return true
end

local function isOffDuty(user_id, org)
    local orgConfig = Config.Orgs[org]
    if not orgConfig or not orgConfig.offDutyGroup then return false end
    return hasGroupSafe(user_id, orgConfig.offDutyGroup)
end

local function ensureOffDutyGroups()
    local groups = vRP.getGroups() or {}
    local created = false

    for org, orgConfig in pairs(Config.Orgs or {}) do
        local groupName = orgConfig.offDutyGroup
        if orgConfig.autoCreateOffDuty == true and type(groupName) == "string" and groupName ~= "" and not groups[groupName] then
            local ok = false
            pcall(function()
                ok = select(1, exports["vrp"]:saveManagedGroup("", {
                    name = groupName,
                    config = {
                        gtype = "org",
                        orgName = org,
                        salario = 0,
                        title = orgConfig.offDutyTitle or "Paisana"
                    },
                    permissions = { "off." .. org:lower() }
                })) == true
            end)
            if ok then
                created = true
                print(("^2[m_ponto]^7 Cargo de paisana criado automaticamente: %s (%s)"):format(groupName, org))
            else
                print(("^3[m_ponto]^7 Não foi possível criar automaticamente o cargo %s. Verifique a vRP."):format(groupName))
            end
        end
    end

    if created then
        pcall(function() exports["vrp"]:reloadManagedGroups() end)
    end
end

local function switchToDutyRole(user_id, org, role)
    if not validDutyRole(org, role) then return false end
    saveDutyRole(user_id, org, role)
    vRP.addUserGroup(user_id, role)
    return vRP.hasGroup(user_id, role) == true
end

local function switchToOffDuty(user_id, org, role)
    local orgConfig = Config.Orgs[org]
    if not orgConfig or not orgConfig.offDutyGroup or orgConfig.offDutyGroup == "" then
        return true
    end

    if validDutyRole(org, role) then
        saveDutyRole(user_id, org, role)
    end

    vRP.addUserGroup(user_id, orgConfig.offDutyGroup)
    return vRP.hasGroup(user_id, orgConfig.offDutyGroup) == true
end

local function webhookUrl(kind)
    if type(PontoWebhooks) ~= "table" then return nil end
    return PontoWebhooks[kind]
end

local function sendWebhook(kind, title, description, color, fields)
    local url = webhookUrl(kind)
    if type(url) ~= "string" or url == "" or url == "none" then return end

    PerformHttpRequest(url, function() end, "POST", json.encode({
        username = "Bate-ponto",
        embeds = {{
            title = title,
            description = description,
            color = color or 16711680,
            fields = fields or {},
            footer = { text = os.date("%d/%m/%Y %H:%M:%S") }
        }}
    }), { ["Content-Type"] = "application/json" })
end

local function invalidateRanking(org)
    if org then RankingCache[org] = nil end
end

local function addServiceTime(user_id, org, name, seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    if seconds <= 0 then return end

    exports.oxmysql:executeSync([[
        INSERT INTO m_ponto_hours (user_id, org, identity, service_time)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            identity = VALUES(identity),
            service_time = m_ponto_hours.service_time + VALUES(service_time),
            updated_at = CURRENT_TIMESTAMP
    ]], { user_id, org, name, seconds })

    invalidateRanking(org)
end

local function updateSessionHeartbeat(session, now)
    exports.oxmysql:execute(
        "UPDATE m_ponto_sessions SET last_heartbeat = ? WHERE session_key = ? AND ended_at IS NULL",
        { now, session.key }
    )
end

local function flushSession(user_id, now)
    local session = Duty[user_id]
    if not session then return 0 end

    now = now or os.time()
    local delta = math.max(0, now - (session.last_saved_at or session.started_at))
    if delta > 0 then
        addServiceTime(user_id, session.org, session.name, delta)
        session.last_saved_at = now
    end

    updateSessionHeartbeat(session, now)
    return delta
end

local function resolveOrg(source, user_id, org)
    local orgConfig = Config.Orgs[org]
    if not orgConfig then
        return false, "Organização inválida."
    end

    -- Em serviço: usa o cargo real que o jogador possui agora.
    local currentRole = getCurrentDutyRole(user_id, org)
    if currentRole then
        return true, currentRole, "duty"
    end

    -- Fora de serviço: o jogador possui o cargo Paisana e o último cargo
    -- operacional fica persistido para que ele volte exatamente ao mesmo posto.
    if isOffDuty(user_id, org) then
        local storedRole = getStoredDutyRole(user_id, org)
        if storedRole then
            return true, storedRole, "offduty"
        end
        return false, "Seu cargo anterior não foi encontrado. Contate um administrador."
    end

    return false, "Você não faz parte desta organização."
end

local function getKitInfo(key)
    local data = Config.WeaponsKit[key]
    if not data then return nil end
    return {
        key = key,
        weapon = data.name,
        item = data.item or string.lower(data.name),
        ammo = math.max(0, tonumber(data.ammo) or 0),
        clip = math.max(0, tonumber(data.clip) or 0)
    }
end

local function issueWeapon(source, user_id, weaponKey)
    local session = Duty[user_id]
    if not session then
        return { success = false, error = "Você precisa estar em serviço." }
    end

    if session.issued[weaponKey] then
        return { success = false, error = "Você já retirou esta arma neste serviço." }
    end

    local allowed = false
    for _, key in ipairs(session.allowedWeapons) do
        if key == weaponKey then
            allowed = true
            break
        end
    end
    if not allowed then
        return { success = false, error = "Esta arma não está liberada para o seu cargo." }
    end

    local kit = getKitInfo(weaponKey)
    if not kit then
        return { success = false, error = "Arma não configurada." }
    end

    if GetResourceState("inventory") ~= "started" then
        return { success = false, error = "Inventário indisponível no momento." }
    end

    local ok, result = pcall(function()
        return exports["inventory"]:giveDutyWeapon(source, user_id, kit.item, kit.ammo, kit.clip)
    end)

    if not ok or type(result) ~= "table" or not result.success then
        local message = type(result) == "table" and result.error or "Não foi possível retirar a arma."
        return { success = false, error = message }
    end

    session.issued[weaponKey] = {
        item = kit.item,
        slot = result.slot,
        weapon = kit.weapon
    }

    sendWebhook("weapon", "Arma retirada", ("%s retirou um equipamento de serviço."):format(session.name), 16744272, {
        { name = "ID", value = tostring(user_id), inline = true },
        { name = "Organização", value = session.org, inline = true },
        { name = "Cargo", value = session.group, inline = true },
        { name = "Arma", value = ("%s (`%s`)"):format(weaponKey, kit.weapon), inline = false },
        { name = "Slot", value = tostring(result.slot or "-"), inline = true }
    })

    return {
        success = true,
        slot = result.slot,
        weapon = weaponKey
    }
end

local function clearIssuedWeapons(user_id, source, session)
    if GetResourceState("inventory") ~= "started" then return end

    -- The inventory persists temporary-duty markers. Clearing all markers for
    -- this user is safer than trusting only this runtime session table (which
    -- can be lost after a resource/server restart).
    pcall(function()
        exports["inventory"]:clearAllDutyWeapons(source or 0, user_id)
    end)
end

local function cleanupStaleDutyWeapons(user_id, source)
    if GetResourceState("inventory") ~= "started" then return end
    pcall(function()
        exports["inventory"]:clearAllDutyWeapons(source or 0, user_id)
    end)
end

local function finishService(user_id, reason, sourceOverride)
    local session = Duty[user_id]
    if not session then return false end

    -- Retira primeiro da tabela para impedir encerramento duplicado por
    -- playerDropped + vRP:playerLeave no mesmo tick.
    Duty[user_id] = nil

    local now = os.time()
    local source = sourceOverride or vRP.getUserSource(user_id) or session.source
    local delta = math.max(0, now - (session.last_saved_at or session.started_at))
    if delta > 0 then
        addServiceTime(user_id, session.org, session.name, delta)
    end

    exports.oxmysql:executeSync([[
        UPDATE m_ponto_sessions
        SET last_heartbeat = ?, ended_at = ?, duration_seconds = ?, exit_reason = ?
        WHERE session_key = ? AND ended_at IS NULL
    ]], {
        now,
        now,
        math.max(0, now - session.started_at),
        reason,
        session.key
    })

    vRP.removePatrulhamento(user_id)
    clearIssuedWeapons(user_id, source, session)
    invalidateRanking(session.org)

    -- Qualquer encerramento real da sessão remove as permissões operacionais e
    -- devolve o jogador ao cargo paisana. Assim não existe serviço "fantasma"
    -- após disconnect/restart do resource.
    switchToOffDuty(user_id, session.org, session.group)

    local reasonLabel = ({
        manual = "Saiu de serviço pelo painel",
        disconnect = "Desconectou do servidor",
        resource_restart = "Reinício do bate-ponto"
    })[reason] or reason

    sendWebhook("service_exit", "Saída de serviço", ("%s encerrou o serviço."):format(session.name), 15158332, {
        { name = "ID", value = tostring(user_id), inline = true },
        { name = "Organização", value = session.org, inline = true },
        { name = "Cargo", value = session.group, inline = true },
        { name = "Tempo da sessão", value = formatDuration(now - session.started_at), inline = false },
        { name = "Motivo", value = reasonLabel, inline = false }
    })

    return true, now - session.started_at
end

-- ============================================================================
-- Banco / recuperação
-- ============================================================================

CreateThread(function()
    exports.oxmysql:executeSync([[
        CREATE TABLE IF NOT EXISTS m_ponto_hours (
            user_id INT NOT NULL,
            org VARCHAR(100) NOT NULL,
            identity VARCHAR(150) NOT NULL,
            service_time BIGINT NOT NULL DEFAULT 0,
            updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (user_id, org),
            INDEX idx_org_time (org, service_time)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    exports.oxmysql:executeSync([[
        CREATE TABLE IF NOT EXISTS m_ponto_roles (
            user_id INT NOT NULL,
            org VARCHAR(100) NOT NULL,
            duty_group VARCHAR(150) NOT NULL,
            updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (user_id, org),
            INDEX idx_org_role (org, duty_group)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    ensureOffDutyGroups()

    exports.oxmysql:executeSync([[
        CREATE TABLE IF NOT EXISTS m_ponto_sessions (
            session_key VARCHAR(80) NOT NULL,
            user_id INT NOT NULL,
            org VARCHAR(100) NOT NULL,
            group_name VARCHAR(150) NOT NULL,
            identity VARCHAR(150) NOT NULL,
            started_at BIGINT NOT NULL,
            last_heartbeat BIGINT NOT NULL,
            ended_at BIGINT NULL,
            duration_seconds BIGINT NOT NULL DEFAULT 0,
            exit_reason VARCHAR(50) NULL,
            PRIMARY KEY (session_key),
            INDEX idx_user (user_id),
            INDEX idx_org (org),
            INDEX idx_open (ended_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Migração do nome antigo usado pela configuração anterior. Mantém todas
    -- as horas já acumuladas da RedLine em vez de começar um ranking do zero.
    exports.oxmysql:executeSync([[
        INSERT INTO m_ponto_hours (user_id, org, identity, service_time)
        SELECT legacy.user_id, 'RedLine', legacy.identity, legacy.service_time
        FROM m_ponto_hours AS legacy
        WHERE legacy.org = 'Redline'
        ON DUPLICATE KEY UPDATE
            identity = VALUES(identity),
            service_time = m_ponto_hours.service_time + VALUES(service_time)
    ]])
    exports.oxmysql:executeSync("DELETE FROM m_ponto_hours WHERE org = 'Redline'")
    exports.oxmysql:executeSync("UPDATE m_ponto_sessions SET org = 'RedLine' WHERE org = 'Redline'")

    -- Sessões que ficaram abertas por crash já tiveram suas horas salvas pelo
    -- heartbeat. Fechamos no último heartbeat, sem contar tempo de servidor off.
    exports.oxmysql:executeSync([[
        UPDATE m_ponto_sessions
        SET ended_at = last_heartbeat,
            duration_seconds = GREATEST(0, last_heartbeat - started_at),
            exit_reason = 'server_interruption'
        WHERE ended_at IS NULL
    ]])

    -- Mantém compatibilidade com instalações antigas apenas como histórico.
    exports.oxmysql:executeSync([[
        CREATE TABLE IF NOT EXISTS ponto_presets (
            org VARCHAR(100) NOT NULL,
            `group` VARCHAR(100) NOT NULL,
            preset TEXT NOT NULL,
            PRIMARY KEY (org, `group`)
        )
    ]])

    -- If this resource is ensured while players are online, all runtime Duty
    -- sessions start empty. Therefore any persisted temporary weapon is stale.
    SetTimeout(1500, function()
        for user_id, src in pairs(vRP.getUsers() or {}) do
            if not Duty[user_id] then
                cleanupStaleDutyWeapons(user_id, src)
                vRP.removePatrulhamento(user_id)

                -- Migração segura da versão antiga: quem estiver online com
                -- cargo operacional de uma org que usa paisana é colocado fora
                -- de serviço até bater o ponto novamente.
                for org, orgConfig in pairs(Config.Orgs or {}) do
                    if orgConfig.offDutyGroup then
                        local currentRole = getCurrentDutyRole(user_id, org)
                        if currentRole then
                            switchToOffDuty(user_id, org, currentRole)
                            break
                        end
                    end
                end
            end
        end
    end)
end)

-- ============================================================================
-- Uniformes
-- ============================================================================

local Clothes = { cache = {} }

function Clothes:Mount()
    local rows = exports.oxmysql:query_async("SELECT `org`, `group`, `preset` FROM ponto_presets", {}) or {}
    self.cache = {}
    for i = 1, #rows do
        local row = rows[i]
        self.cache[row.org] = self.cache[row.org] or {}
        self.cache[row.org][row.group] = json.decode(row.preset) or {}
    end
    return self.cache
end

function Clothes:Get(org, group)
    return self.cache[org] and self.cache[org][group] or nil
end

function Clothes:Update(org, group, preset)
    local decoded = type(preset) == "string" and json.decode(preset) or preset
    if type(decoded) ~= "table" then return false end
    self.cache[org] = self.cache[org] or {}
    self.cache[org][group] = decoded

    exports.oxmysql:executeSync([[
        INSERT INTO ponto_presets (`org`, `group`, preset)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE preset = VALUES(preset)
    ]], { org, group, json.encode(decoded) })
    return true
end

CreateThread(function()
    Wait(250)
    Clothes:Mount()
    for group, preset in pairs(Config.Clothes or {}) do
        if not Clothes:Get(preset.org, group) then
            Clothes:Update(preset.org, group, {
                male = preset.male or {},
                female = preset.female or {}
            })
        end
    end
end)

-- ============================================================================
-- Ranking
-- ============================================================================

local function buildRanking(org)
    local rows = exports.oxmysql:query_async([[
        SELECT user_id, identity AS name, service_time
        FROM m_ponto_hours
        WHERE org = ?
        ORDER BY service_time DESC
        LIMIT 25
    ]], { org }) or {}

    local byUser = {}
    for _, row in ipairs(rows) do
        row.user_id = tonumber(row.user_id)
        row.service_time = tonumber(row.service_time) or 0
        byUser[row.user_id] = row
    end

    local now = os.time()
    for user_id, session in pairs(Duty) do
        if session.org == org then
            local row = byUser[user_id]
            if not row then
                row = {
                    user_id = user_id,
                    name = session.name,
                    service_time = 0
                }
                rows[#rows + 1] = row
                byUser[user_id] = row
            end
            row.service_time = row.service_time + math.max(0, now - (session.last_saved_at or now))
        end
    end

    table.sort(rows, function(a, b)
        if a.service_time == b.service_time then
            return (a.user_id or 0) < (b.user_id or 0)
        end
        return a.service_time > b.service_time
    end)

    local result = {}
    for i = 1, math.min(MAX_RANKING, #rows) do
        result[#result + 1] = {
            user_id = rows[i].user_id,
            name = rows[i].name,
            seconds = rows[i].service_time,
            formatted = formatDuration(rows[i].service_time)
        }
    end

    RankingCache[org] = {
        generated_at = os.time(),
        rows = result
    }
    return result
end

function API.getRanking(org)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id or not Config.Orgs[org] then return {} end

    local cache = RankingCache[org]
    if cache and os.time() - cache.generated_at < (RANKING_UPDATE_INTERVAL or 30) then
        return cache.rows
    end
    return buildRanking(org)
end

-- ============================================================================
-- Integração externa (MDT / outros recursos)
-- ============================================================================

local function getServiceSeconds(user_id, org)
    user_id = tonumber(user_id)
    if not user_id or not Config.Orgs[org] then return 0 end

    local row = exports.oxmysql:singleSync(
        "SELECT service_time FROM m_ponto_hours WHERE user_id = ? AND org = ? LIMIT 1",
        { user_id, org }
    )
    local total = row and tonumber(row.service_time) or 0

    local session = Duty[user_id]
    if session and session.org == org then
        total = total + math.max(0, os.time() - (session.last_saved_at or session.started_at))
    end

    return math.max(0, math.floor(total))
end

local function getMembershipInfo(user_id, org)
    user_id = tonumber(user_id)
    if not user_id or not Config.Orgs[org] then return nil end

    local currentRole = getCurrentDutyRole(user_id, org)
    local session = Duty[user_id]
    if currentRole then
        return {
            org = org,
            role = currentRole,
            onDuty = session ~= nil and session.org == org,
            offDutyGroup = Config.Orgs[org].offDutyGroup
        }
    end

    local storedRole = getStoredDutyRole(user_id, org)
    if storedRole then
        -- Para jogadores online exigimos o cargo paisana real. Para jogadores
        -- offline, o estado é conferido diretamente no datatable persistido.
        -- Isso permite ao MDT promover/rebaixar membros paisana mesmo offline
        -- sem devolver permissões operacionais por acidente.
        local offDuty = isOffDuty(user_id, org)
        if offDuty then
            return {
                org = org,
                role = storedRole,
                onDuty = false,
                offDutyGroup = Config.Orgs[org].offDutyGroup
            }
        end
    end

    return nil
end

exports("getServiceInfo", function(user_id, org)
    local membership = getMembershipInfo(user_id, org)
    local seconds = getServiceSeconds(user_id, org)
    return {
        org = org,
        role = membership and membership.role or nil,
        onDuty = membership and membership.onDuty or false,
        seconds = seconds,
        formatted = formatClock(seconds)
    }
end)

exports("getMembership", function(user_id, org)
    return getMembershipInfo(user_id, org)
end)

exports("setStoredDutyRole", function(user_id, org, role)
    user_id = tonumber(user_id)
    if not user_id then return false end
    return saveDutyRole(user_id, org, role)
end)

exports("removeMembership", function(user_id, org)
    user_id = tonumber(user_id)
    if not user_id or not Config.Orgs[org] then return false end

    local orgConfig = Config.Orgs[org]
    local storedRole = getStoredDutyRole(user_id, org)

    -- Remove tanto o paisana quanto um eventual cargo operacional residual.
    -- setGroupSafe funciona com membro online e offline.
    if orgConfig.offDutyGroup and orgConfig.offDutyGroup ~= "" then
        setGroupSafe(user_id, orgConfig.offDutyGroup, false)
    end
    if storedRole and validDutyRole(org, storedRole) then
        setGroupSafe(user_id, storedRole, false)
    end

    exports.oxmysql:executeSync("DELETE FROM m_ponto_roles WHERE user_id = ? AND org = ?", { user_id, org })
    invalidateRanking(org)
    return true
end)

-- ============================================================================
-- APIs NUI / serviço
-- ============================================================================

function API.checkOrgData(org)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return false end

    local ok, groupOrError, membershipState = resolveOrg(source, user_id, org)
    if not ok then return false end

    local identity = vRP.getUserIdentity(user_id)
    if not identity then return false end

    local session = Duty[user_id]
    return true, groupOrError, session and session.started_at or nil, {
        isDeveloper = vRP.hasPermission(user_id, ADMIN_PERMISSION),
        name = identityName(user_id),
        group = groupOrError,
        org = org,
        onDuty = session ~= nil,
        membershipState = membershipState,
    }
end

function API.startService(org)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return { success = false, error = "Usuário não encontrado." } end
    if ActionLock[user_id] then return { success = false, error = "Aguarde um instante." } end
    ActionLock[user_id] = true

    local ok, groupOrError, membershipState = resolveOrg(source, user_id, org)
    if not ok then
        ActionLock[user_id] = nil
        notify(source, "negado", groupOrError)
        return { success = false, error = groupOrError }
    end

    if Duty[user_id] then
        ActionLock[user_id] = nil
        return { success = false, error = "Você já está em serviço.", startedAt = Duty[user_id].started_at }
    end

    if membershipState == "offduty" then
        if not switchToDutyRole(user_id, org, groupOrError) then
            ActionLock[user_id] = nil
            notify(source, "negado", "Não foi possível restaurar seu cargo de serviço.")
            return { success = false, error = "Falha ao restaurar o cargo de serviço." }
        end
    else
        -- Mantém a referência atualizada mesmo para quem está usando o ponto
        -- pela primeira vez antes de existir um registro em m_ponto_roles.
        saveDutyRole(user_id, org, groupOrError)
    end

    local blocked = false
    pcall(function()
        blocked = exports.vrp_admin:isOrganizationBlacklisted(org) == true
    end)
    if blocked then
        if membershipState == "offduty" then
            switchToOffDuty(user_id, org, groupOrError)
        end
        ActionLock[user_id] = nil
        notify(source, "negado", "Você não pode entrar em serviço nesta organização.")
        return { success = false, error = "Organização bloqueada." }
    end

    -- Any temporary weapon left by an interrupted previous session is removed
    -- before a new duty session starts. Personal weapons are untouched.
    cleanupStaleDutyWeapons(user_id, source)

    local now = os.time()
    local name = identityName(user_id)
    local key = ("%s:%s:%s"):format(user_id, now, math.random(100000, 999999))
    local allowedWeapons = {}
    for _, weaponKey in ipairs(Config.Orgs[org].groups[groupOrError].WeaponsKit or {}) do
        allowedWeapons[#allowedWeapons + 1] = weaponKey
    end

    Duty[user_id] = {
        source = source,
        org = org,
        group = groupOrError,
        name = name,
        started_at = now,
        last_saved_at = now,
        key = key,
        allowedWeapons = allowedWeapons,
        issued = {}
    }

    exports.oxmysql:executeSync([[
        INSERT INTO m_ponto_sessions
            (session_key, user_id, org, group_name, identity, started_at, last_heartbeat)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], { key, user_id, org, groupOrError, name, now, now })

    vRP.setPatrulhamento(user_id, true)
    invalidateRanking(org)

    sendWebhook("service_enter", "Entrada em serviço", ("%s entrou em serviço."):format(name), 5763719, {
        { name = "ID", value = tostring(user_id), inline = true },
        { name = "Organização", value = org, inline = true },
        { name = "Cargo", value = groupOrError, inline = true }
    })

    ActionLock[user_id] = nil
    notify(source, "sucesso", "Você entrou em serviço.")
    return { success = true, startedAt = now }
end

function API.stopService(org)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return { success = false, error = "Usuário não encontrado." } end
    if ActionLock[user_id] then return { success = false, error = "Aguarde um instante." } end

    local session = Duty[user_id]
    if not session then
        return { success = false, error = "Você não está em serviço." }
    end
    if session.org ~= org then
        return { success = false, error = "Organização do serviço inválida." }
    end

    ActionLock[user_id] = true
    local success, elapsed = finishService(user_id, "manual", source)
    ActionLock[user_id] = nil

    if success then
        notify(source, "sucesso", ("Serviço encerrado. Tempo: %s"):format(formatDuration(elapsed)))
        return { success = true, elapsed = elapsed }
    end
    return { success = false, error = "Não foi possível encerrar o serviço." }
end

function API.getClothes(org)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id or not vRP.hasPermission(user_id, ADMIN_PERMISSION) or not Config.Orgs[org] then
        return { radio = 0, uniforms = {} }
    end

    local response = {}
    for group in pairs(Config.Orgs[org].groups) do
        response[#response + 1] = {
            name = "Uniforme - " .. group,
            group = group,
            preset = Clothes:Get(org, group)
        }
    end
    table.sort(response, function(a, b) return a.name < b.name end)

    return {
        radio = Config.Orgs[org].radioChannel,
        uniforms = response
    }
end

function API.updateUniform(org, group, new_preset)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id or not vRP.hasPermission(user_id, ADMIN_PERMISSION) then return false end
    if not Config.Orgs[org] or not Config.Orgs[org].groups[group] then return false end
    return Clothes:Update(org, group, new_preset)
end

function API.takeWeapon(org, weaponKey)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return { success = false, error = "Usuário não encontrado." } end

    local session = Duty[user_id]
    if not session or session.org ~= org then
        notify(source, "negado", "Entre em serviço antes de retirar armamento.")
        return { success = false, error = "Você não está em serviço." }
    end

    if ActionLock[user_id] then return { success = false, error = "Aguarde um instante." } end
    ActionLock[user_id] = true
    local result = issueWeapon(source, user_id, tostring(weaponKey or ""))
    ActionLock[user_id] = nil

    if result.success then
        notify(source, "sucesso", ("%s retirado para o slot %s."):format(result.weapon, result.slot or "-"))
    else
        notify(source, "negado", result.error or "Não foi possível retirar a arma.")
    end
    return result
end

function API.equip(org)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return { success = false, error = "Usuário não encontrado." } end

    local session = Duty[user_id]
    if not session or session.org ~= org then
        notify(source, "negado", "Você precisa estar em serviço.")
        return { success = false, error = "Você não está em serviço." }
    end
    if ActionLock[user_id] then return { success = false, error = "Aguarde um instante." } end
    ActionLock[user_id] = true

    local clothes = Clothes:Get(session.org, session.group) or { male = {}, female = {} }
    local ped = GetPlayerPed(source)
    local isMale = ped and ped > 0 and GetEntityModel(ped) == GetHashKey("mp_m_freemode_01")
    local preset = isMale and (clothes.male or {}) or (clothes.female or {})

    if next(preset) then
        vRPC._setCustomization(source, preset)
    end

    if vRP.getInventoryItemAmount(user_id, "radio") <= 0 then
        vRP.giveInventoryItem(user_id, "radio", 1, true)
    end

    local orgConfig = Config.Orgs[session.org] or {}
    local armour = tonumber(orgConfig.armour)
    if armour == nil then
        -- Por padrão, somente organizações com armamento operacional recebem
        -- colete. Hospital e oficinas não ganham 100 de colete ao equipar.
        armour = #session.allowedWeapons > 0 and 100 or 0
    end
    if armour > 0 then
        vRPC._setArmour(source, math.min(100, math.max(0, armour)))
    end
    TriggerClientEvent("vrp_sound:source", source, "ziper", 0.5)

    local issued = 0
    local failures = {}
    for _, weaponKey in ipairs(session.allowedWeapons) do
        if not session.issued[weaponKey] then
            local result = issueWeapon(source, user_id, weaponKey)
            if result.success then
                issued = issued + 1
            else
                failures[#failures + 1] = ("%s: %s"):format(weaponKey, result.error or "erro")
                if result.error and result.error:lower():find("slot") then
                    break
                end
            end
        end
    end

    ActionLock[user_id] = nil

    if #failures > 0 then
        notify(source, "aviso", ("Uniforme equipado. %s arma(s) retirada(s). Libere slots 1 a 5 para retirar as restantes."):format(issued), 7)
    else
        notify(source, "sucesso", ("Equipamento aplicado e %s arma(s) retirada(s)."):format(issued))
    end

    return {
        success = true,
        issued = issued,
        partial = #failures > 0,
        errors = failures
    }
end

-- Se algum outro recurso/admin entregar um cargo operacional enquanto o
-- jogador não está em serviço, convertemos imediatamente para paisana. Isso
-- impede permissões de polícia/médico/mecânico fora do bate-ponto.
AddEventHandler("vRP:playerJoinGroup", function(user_id, group)
    if not user_id or not group or Duty[user_id] or ActionLock[user_id] then return end

    for org, orgConfig in pairs(Config.Orgs or {}) do
        if orgConfig.offDutyGroup and validDutyRole(org, group) then
            SetTimeout(250, function()
                if not Duty[user_id] and not ActionLock[user_id] and vRP.hasGroup(user_id, group) then
                    switchToOffDuty(user_id, org, group)
                end
            end)
            break
        end
    end
end)

-- Remove temporary equipment that survived a previous server interruption.
-- A player that is currently in Duty is intentionally ignored.
AddEventHandler("vRP:playerSpawn", function(user_id, source)
    if user_id and not Duty[user_id] then
        SetTimeout(1500, function()
            if Duty[user_id] or not vRP.getUserSource(user_id) then return end

            cleanupStaleDutyWeapons(user_id, source)
            vRP.removePatrulhamento(user_id)

            -- Depois de reconnect/restart ninguém permanece com permissões de
            -- serviço sem ter batido o ponto novamente.
            for org, orgConfig in pairs(Config.Orgs or {}) do
                if orgConfig.offDutyGroup then
                    local currentRole = getCurrentDutyRole(user_id, org)
                    if currentRole then
                        switchToOffDuty(user_id, org, currentRole)
                        break
                    end
                end
            end
        end)
    end
end)

-- Heartbeat: mantém ranking persistido e limita perda em crash a no máximo ~60s.
CreateThread(function()
    while true do
        Wait(HEARTBEAT_SECONDS * 1000)
        local now = os.time()
        for user_id in pairs(Duty) do
            flushSession(user_id, now)
        end
    end
end)

AddEventHandler("vRP:playerLeave", function(user_id)
    if Duty[user_id] then
        finishService(user_id, "disconnect")
    end
end)

AddEventHandler("playerDropped", function()
    local user_id = vRP.getUserId(source)
    if user_id and Duty[user_id] then
        finishService(user_id, "disconnect", source)
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    local ids = {}
    for user_id in pairs(Duty) do ids[#ids + 1] = user_id end
    for _, user_id in ipairs(ids) do
        finishService(user_id, "resource_restart")
    end
end)
