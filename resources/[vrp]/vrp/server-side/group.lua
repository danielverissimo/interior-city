--- DYNAMIC GROUPS
local cfg = module("cfg/groups")
local users = cfg.users or {}
local selectors = cfg.selectors or {}

local GROUPS_FILE = "cfg/groups.json"
local groups = {}
local ManagedGroups = { groups = {} }
local INDEX

local function mageGroupOrigin()
    return type(vRP.mageAuditOrigin) == "function" and vRP.mageAuditOrigin() or (GetInvokingResource() or GetCurrentResourceName() or "vrp")
end

local function mageGroupLog(key, user_id, details, actorName, actorLabel)
    if type(vRP.mageAuditLog) ~= "function" then return end
    vRP.mageAuditLog(key, {
        actorId = tonumber(user_id),
        actorName = actorName,
        actorLabel = actorLabel or (user_id and "JOGADOR AFETADO" or "RESOURCE EXECUTOR"),
        details = details
    })
end

local function trimGroupValue(value)
    return tostring(value or ""):gsub("^%s+",""):gsub("%s+$","")
end

local function copyTable(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k,v in pairs(value) do out[k] = copyTable(v) end
    return out
end

local function defaultGroupPermission(name)
    local value = trimGroupValue(name):lower()
    value = value:gsub("[^%w]","")
    if value == "" then return nil end
    return "perm."..value
end

local function normalizePermissions(list)
    local out, seen = {}, {}
    for _,permission in ipairs(type(list) == "table" and list or {}) do
        local value = trimGroupValue(permission)
        if value ~= "" and not seen[value] then
            seen[value] = true
            out[#out+1] = value
        end
    end
    return out
end

local function normalizeGroupPayload(data, isNew)
    if type(data) ~= "table" then return nil,"Dados do cargo inválidos." end

    local name = trimGroupValue(data.name)
    if name == "" then return nil,"Informe o nome do cargo." end
    if name:find("[%[%]{}\"']") then return nil,"Nome do cargo contém caracteres inválidos." end

    local sourceConfig = type(data.config) == "table" and data.config or {}
    local config = {}

    local gtype = trimGroupValue(sourceConfig.gtype)
    if gtype ~= "" then config.gtype = gtype end

    local title = trimGroupValue(sourceConfig.title)
    if title ~= "" then config.title = title end

    local salario = tonumber(sourceConfig.salario)
    if salario ~= nil then config.salario = salario end

    if sourceConfig.ptr == true then
        config.ptr = true
    elseif sourceConfig.ptr == false then
        config.ptr = false
    end

    local orgName = trimGroupValue(sourceConfig.orgName)
    if orgName ~= "" then config.orgName = orgName end

    local orgType = trimGroupValue(sourceConfig.orgType)
    if orgType ~= "" then config.orgType = orgType end

    local permissions = normalizePermissions(data.permissions)
    if isNew and #permissions == 0 then
        local auto = defaultGroupPermission(name)
        if auto then permissions[1] = auto end
    end

    return {
        name = name,
        config = config,
        permissions = permissions
    }
end

local function rebuildRuntimeGroups()
    for key in pairs(groups) do
        groups[key] = nil
    end

    for _,entry in ipairs(ManagedGroups.groups or {}) do
        local name = tostring(entry.name or "")
        if name ~= "" then
            local runtime = {}
            local cfgData = type(entry.config) == "table" and entry.config or {}

            if next(cfgData) ~= nil then
                runtime._config = copyTable(cfgData)
            end

            for _,permission in ipairs(type(entry.permissions) == "table" and entry.permissions or {}) do
                runtime[#runtime+1] = tostring(permission)
            end

            groups[name] = runtime
        end
    end
end

local function loadManagedGroups()
    local raw = LoadResourceFile(GetCurrentResourceName(), GROUPS_FILE)
    local ok, data = pcall(json.decode, raw or "{}")

    if not ok or type(data) ~= "table" then
        print("^1[vRP Groups]^7 Falha ao carregar cfg/groups.json.")
        ManagedGroups = { groups = {} }
    else
        ManagedGroups = data
        if type(ManagedGroups.groups) ~= "table" then
            ManagedGroups.groups = {}
        end
    end

    rebuildRuntimeGroups()
end

local function saveManagedGroups()
    if not SaveResourceFile(GetCurrentResourceName(), GROUPS_FILE, json.encode(ManagedGroups), -1) then
        return false,"Não foi possível salvar cfg/groups.json."
    end
    return true
end

local function findManagedGroup(name)
    name = tostring(name or "")
    for index,entry in ipairs(ManagedGroups.groups or {}) do
        if tostring(entry.name or "") == name then
            return index,entry
        end
    end
end

local function invalidateAllPermissionCaches()
    if INDEX then
        for user_id in pairs(INDEX) do
            INDEX[user_id] = nil
        end
    end
end

local function migrateGroupInData(oldName, newName)
    local changed = 0

    for user_id,data in pairs(vRP.user_tables or {}) do
        if type(data) == "table" and type(data.groups) == "table" and data.groups[oldName] ~= nil then
            if newName and newName ~= "" then
                data.groups[newName] = data.groups[newName] or data.groups[oldName]
            end
            data.groups[oldName] = nil

            -- VIPs temporários guardam a expiração no mesmo datatable do usuário.
            -- Renomear/excluir um cargo no mg_config_panel precisa migrar/limpar
            -- este metadado junto do grupo para não deixar expirações órfãs.
            if type(data.vip_group_expirations) == "table" and data.vip_group_expirations[oldName] ~= nil then
                if newName and newName ~= "" then
                    data.vip_group_expirations[newName] = data.vip_group_expirations[oldName]
                end
                data.vip_group_expirations[oldName] = nil
            end

            changed = changed + 1
        end
    end

    local rows = exports["oxmysql"]:executeSync(
        "SELECT user_id,dvalue FROM vrp_user_data WHERE dkey = ?",
        { "vRP:datatable" }
    ) or {}

    for _,row in ipairs(rows) do
        local ok,data = pcall(json.decode,row.dvalue or "{}")
        if ok and type(data) == "table" and type(data.groups) == "table" and data.groups[oldName] ~= nil then
            if newName and newName ~= "" then
                data.groups[newName] = data.groups[newName] or data.groups[oldName]
            end
            data.groups[oldName] = nil

            if type(data.vip_group_expirations) == "table" and data.vip_group_expirations[oldName] ~= nil then
                if newName and newName ~= "" then
                    data.vip_group_expirations[newName] = data.vip_group_expirations[oldName]
                end
                data.vip_group_expirations[oldName] = nil
            end

            exports["oxmysql"]:executeSync(
                "UPDATE vrp_user_data SET dvalue = ? WHERE user_id = ? AND dkey = ?",
                { json.encode(data), row.user_id, "vRP:datatable" }
            )
        end
    end

    invalidateAllPermissionCaches()
    return changed
end

loadManagedGroups()

function vRP.getGroupTitle(group)
    local g = groups[group]
    if g and g._config and g._config.title then
        return g._config.title
    end
    return group
end

function vRP.getUserGroups(user_id)
    local data = vRP.getUserDataTable(user_id)
    if data then
        if data.groups == nil then
            data.groups = {}
        end
        return data.groups
    else
        return {}
    end
end

INDEX = setmetatable({}, {
    __index = function(self, user_id)
        if not user_id then
            return {}
        end

        local set = {}

        for group in pairs(vRP.getUserGroups(user_id)) do
            local config = groups[group] or {}

            for _, perm in ipairs(config) do
                set[perm] = true
            end
        end

        self[user_id] = set
        return set
    end,
})


function vRP.getGroups()
    return groups
end

exports("getManagedGroups", function()
    return copyTable(ManagedGroups.groups or {})
end)

exports("saveManagedGroup", function(originalName, payload)
    originalName = trimGroupValue(originalName)
    local isNew = originalName == ""
    local entry,err = normalizeGroupPayload(payload,isNew)
    if not entry then return false,err end

    if originalName == "user" and entry.name ~= "user" then
        return false,"O cargo 'user' é obrigatório e não pode ser renomeado."
    end

    local existingIndex = findManagedGroup(entry.name)
    local originalIndex = originalName ~= "" and findManagedGroup(originalName) or nil

    if existingIndex and existingIndex ~= originalIndex then
        return false,"Já existe um cargo com esse nome."
    end

    if originalIndex then
        local old = copyTable(ManagedGroups.groups[originalIndex])
        ManagedGroups.groups[originalIndex] = entry

        local ok,msg = saveManagedGroups()
        if not ok then
            ManagedGroups.groups[originalIndex] = old
            return false,msg
        end

        rebuildRuntimeGroups()

        if originalName ~= entry.name then
            migrateGroupInData(originalName,entry.name)
        else
            invalidateAllPermissionCaches()
        end

        local action = originalName ~= entry.name and "renomeado" or "atualizado"
        mageGroupLog("vrp_managed_group_saved", nil,
            ("**Resource:** %s\n**Ação:** Cargo %s\n**Nome anterior:** %s\n**Nome atual:** %s\n**gtype:** %s\n**Permissões:** %s"):format(
                mageGroupOrigin(), action, tostring(originalName), tostring(entry.name),
                tostring(entry.config and entry.config.gtype or "-"), table.concat(entry.permissions or {}, ", ")
            ), mageGroupOrigin(), "RESOURCE EXECUTOR")
        return true, originalName ~= entry.name
            and ("Cargo renomeado de %s para %s e usuários migrados."):format(originalName,entry.name)
            or "Cargo atualizado em tempo real."
    end

    ManagedGroups.groups[#ManagedGroups.groups+1] = entry
    local ok,msg = saveManagedGroups()

    if not ok then
        table.remove(ManagedGroups.groups,#ManagedGroups.groups)
        return false,msg
    end

    rebuildRuntimeGroups()
    invalidateAllPermissionCaches()
    mageGroupLog("vrp_managed_group_saved", nil,
        ("**Resource:** %s\n**Ação:** Cargo criado\n**Cargo:** %s\n**gtype:** %s\n**Permissões:** %s"):format(
            mageGroupOrigin(), tostring(entry.name), tostring(entry.config and entry.config.gtype or "-"), table.concat(entry.permissions or {}, ", ")
        ), mageGroupOrigin(), "RESOURCE EXECUTOR")
    return true,"Cargo criado e carregado em tempo real."
end)

-- Garante que um cargo gerenciado exista no runtime e no cfg/groups.json.
-- É idempotente e foi criado para integrações como m_mansions: se o cadastro
-- persistido da mansão existir mas o cargo tiver sido removido/ficado ausente,
-- o próprio sistema consegue reconstruí-lo antes de entregar a propriedade.
exports("ensureManagedGroup", function(name, permission, config)
    name = trimGroupValue(name)
    if name == "" then return false,"Informe o nome do cargo." end

    permission = trimGroupValue(permission)
    if permission == "" then
        permission = defaultGroupPermission(name) or ""
    end
    if permission == "" then return false,"Não foi possível gerar a permissão do cargo." end

    local index,existing = findManagedGroup(name)
    if index and existing then
        local changed = false
        local permissions = normalizePermissions(existing.permissions)
        local found = false
        for _,perm in ipairs(permissions) do
            if perm == permission then found = true break end
        end
        if not found then
            permissions[#permissions+1] = permission
            existing.permissions = permissions
            changed = true
        end

        if type(config) == "table" then
            existing.config = type(existing.config) == "table" and existing.config or {}
            for k,v in pairs(config) do
                if v ~= nil and existing.config[k] ~= v then
                    existing.config[k] = v
                    changed = true
                end
            end
        end

        if changed then
            local ok,msg = saveManagedGroups()
            if not ok then return false,msg end
        end
        rebuildRuntimeGroups()
        invalidateAllPermissionCaches()
        return true, changed and "Cargo reparado e carregado em tempo real." or "Cargo já existe e está carregado."
    end

    local entry,err = normalizeGroupPayload({
        name = name,
        permissions = { permission },
        config = type(config) == "table" and config or {}
    }, true)
    if not entry then return false,err end

    ManagedGroups.groups[#ManagedGroups.groups+1] = entry
    local ok,msg = saveManagedGroups()
    if not ok then
        table.remove(ManagedGroups.groups,#ManagedGroups.groups)
        return false,msg
    end

    rebuildRuntimeGroups()
    invalidateAllPermissionCaches()
    mageGroupLog("vrp_managed_group_saved", nil,
        ("**Resource:** %s\n**Ação:** Cargo garantido/criado por integração\n**Cargo:** %s\n**Permissão:** %s"):format(
            mageGroupOrigin(), tostring(name), tostring(permission)
        ), mageGroupOrigin(), "RESOURCE EXECUTOR")
    return true,"Cargo criado e carregado em tempo real."
end)

exports("managedGroupExists", function(name)
    name = trimGroupValue(name)
    if name == "" then return false end
    return groups[name] ~= nil
end)

exports("removeManagedGroup", function(name)
    name = trimGroupValue(name)

    if name == "user" then
        return false,"O cargo 'user' é obrigatório e não pode ser excluído."
    end

    local index = findManagedGroup(name)
    if not index then return false,"Cargo não encontrado." end

    local old = table.remove(ManagedGroups.groups,index)
    local ok,msg = saveManagedGroups()

    if not ok then
        table.insert(ManagedGroups.groups,index,old)
        return false,msg
    end

    rebuildRuntimeGroups()
    migrateGroupInData(name,nil)
    mageGroupLog("vrp_managed_group_removed", nil,
        ("**Resource:** %s\n**Cargo removido:** %s"):format(mageGroupOrigin(), tostring(name)),
        mageGroupOrigin(), "RESOURCE EXECUTOR")
    return true,"Cargo excluído e removido dos usuários que o possuíam."
end)



local FAC_DEFAULT_RANKS = {
    "Recrutador",
    "Novato",
    "Membro",
    "Gerente",
    "SubLider",
    "Lider"
}

local function facPermissionSlug(value)
    local s = tostring(value or "")
    local replacements = {
        ["Á"]="A",["À"]="A",["Â"]="A",["Ã"]="A",["á"]="a",["à"]="a",["â"]="a",["ã"]="a",
        ["É"]="E",["Ê"]="E",["é"]="e",["ê"]="e",
        ["Í"]="I",["í"]="i",
        ["Ó"]="O",["Ô"]="O",["Õ"]="O",["ó"]="o",["ô"]="o",["õ"]="o",
        ["Ú"]="U",["ú"]="u",
        ["Ç"]="C",["ç"]="c"
    }
    for from,to in pairs(replacements) do
        s = s:gsub(from,to)
    end
    return s:lower():gsub("[^a-z0-9]","")
end

exports("createFacGroups", function(orgName, orgType)
    orgName = trimGroupValue(orgName)
    orgType = trimGroupValue(orgType)

    if orgName == "" then
        return false,"Informe o orgName da FAC."
    end

    if orgType == "" then
        return false,"Selecione o tipo da organização."
    end

    local pending = {}

    -- Valida TODOS os cargos antes de salvar qualquer coisa.
    for _,rank in ipairs(FAC_DEFAULT_RANKS) do
        local name = rank..orgName
        if findManagedGroup(name) then
            return false,("Já existe o cargo %s. Nenhum cargo da FAC foi criado."):format(name)
        end

        pending[#pending+1] = {
            name = name,
            config = {
                gtype = "org",
                orgName = orgName,
                orgType = orgType
            },
            permissions = {
                "perm."..facPermissionSlug(name)
            }
        }
    end

    -- Snapshot completo para garantir operação atômica.
    local backup = copyTable(ManagedGroups.groups)

    for _,entry in ipairs(pending) do
        local normalized,err = normalizeGroupPayload(entry,true)
        if not normalized then
            ManagedGroups.groups = backup
            rebuildRuntimeGroups()
            return false,err
        end
        ManagedGroups.groups[#ManagedGroups.groups+1] = normalized
    end

    table.sort(ManagedGroups.groups,function(a,b)
        return tostring(a.name):lower() < tostring(b.name):lower()
    end)

    local ok,msg = saveManagedGroups()
    if not ok then
        ManagedGroups.groups = backup
        rebuildRuntimeGroups()
        return false,msg
    end

    rebuildRuntimeGroups()
    invalidateAllPermissionCaches()

    mageGroupLog("vrp_fac_groups_created", nil,
        ("**Resource:** %s\n**Organização:** %s\n**Tipo:** %s\n**Cargos criados:** %d"):format(
            mageGroupOrigin(), tostring(orgName), tostring(orgType), #pending
        ), mageGroupOrigin(), "RESOURCE EXECUTOR")
    return true,("FAC %s criada com %d cargos."):format(orgName,#pending)
end)


exports("removeFacGroups", function(orgName)
    orgName = trimGroupValue(orgName)
    if orgName == "" then return false,"Informe o orgName da FAC." end

    local indexes = {}
    local names = {}

    for i,entry in ipairs(ManagedGroups.groups) do
        if entry.config
            and tostring(entry.config.gtype or "") == "org"
            and tostring(entry.config.orgName or "") == orgName
        then
            indexes[#indexes+1] = i
            names[#names+1] = entry.name
        end
    end

    if #indexes == 0 then
        return false,"Nenhum cargo desta FAC foi encontrado."
    end

    local backup = copyTable(ManagedGroups.groups)

    -- Remove de trás para frente para preservar os índices.
    table.sort(indexes,function(a,b) return a>b end)
    for _,index in ipairs(indexes) do
        table.remove(ManagedGroups.groups,index)
    end

    local ok,msg = saveManagedGroups()
    if not ok then
        ManagedGroups.groups = backup
        rebuildRuntimeGroups()
        return false,msg
    end

    rebuildRuntimeGroups()

    -- Remove os cargos da FAC dos usuários online/offline.
    for _,name in ipairs(names) do
        migrateGroupInData(name,nil)
    end

    invalidateAllPermissionCaches()

    mageGroupLog("vrp_fac_groups_removed", nil,
        ("**Resource:** %s\n**Organização:** %s\n**Cargos removidos:** %d\n**Cargos:** %s"):format(
            mageGroupOrigin(), tostring(orgName), #names, table.concat(names, ", ")
        ), mageGroupOrigin(), "RESOURCE EXECUTOR")
    return true,("FAC %s removida (%d cargos excluídos)."):format(orgName,#names)
end)

exports("reloadManagedGroups", function()
    loadManagedGroups()
    invalidateAllPermissionCaches()
    mageGroupLog("vrp_managed_groups_reloaded", nil,
        ("**Resource:** %s\n**Total de cargos gerenciados:** %d"):format(mageGroupOrigin(), #(ManagedGroups.groups or {})),
        mageGroupOrigin(), "RESOURCE EXECUTOR")
    return true,"Cargos recarregados."
end)

AddEventHandler('vRP:playerLeave', function(user_id)
    INDEX[user_id] = nil
end)

-- ==========================================================================
-- VIP TEMPORÁRIO NATIVO DA vRP
-- Todo cargo com gtype = "vip" recebe 30 dias por padrão ao ser setado.
-- A expiração fica persistida no vRP:datatable do próprio usuário, portanto
-- continua funcionando após restart e também quando o VIP é aplicado por
-- qualquer outro script que utilize vRP.addUserGroup.
-- ==========================================================================
local VIP_DEFAULT_DURATION = 30 * 24 * 60 * 60

local function vipExpirationTable(user_id)
    local data = vRP.getUserDataTable(user_id)
    if not data then return nil end
    if type(data.vip_group_expirations) ~= "table" then
        data.vip_group_expirations = {}
    end
    return data.vip_group_expirations
end

local function isVipGroup(group)
    local definition = groups[tostring(group or "")]
    return definition and definition._config and tostring(definition._config.gtype or ""):lower() == "vip"
end

local function setVipExpiration(user_id, group, duration)
    if not isVipGroup(group) then return nil end
    local expirations = vipExpirationTable(user_id)
    if not expirations then return nil end
    local seconds = math.max(60, math.floor(tonumber(duration) or VIP_DEFAULT_DURATION))
    local expiresAt = os.time() + seconds
    expirations[group] = expiresAt
    return expiresAt
end

local function cleanupExpiredVipGroups(user_id)
    local data = vRP.getUserDataTable(user_id)
    if not data or type(data.vip_group_expirations) ~= "table" then return false end

    local expired = {}
    local now = os.time()
    for group,expiresAt in pairs(data.vip_group_expirations) do
        if tonumber(expiresAt) and tonumber(expiresAt) <= now then
            expired[#expired+1] = tostring(group)
        end
    end

    local changed = false
    for _,group in ipairs(expired) do
        data.vip_group_expirations[group] = nil
        if type(data.groups) == "table" and data.groups[group] ~= nil then
            -- removeUserGroup também invalida o cache de permissões e dispara
            -- os eventos normais de saída do grupo.
            vRP.removeUserGroup(user_id, group)
        end
        changed = true
    end
    return changed
end

function vRP.getUserGroupExpiration(user_id, group)
    local expirations = vipExpirationTable(user_id)
    if not expirations then return 0 end
    return tonumber(expirations[tostring(group or "")]) or 0
end

function vRP.setUserGroupExpiration(user_id, group, duration)
    if not vRP.hasGroup(user_id, group) or not isVipGroup(group) then return false,0 end
    local oldExpiration = vRP.getUserGroupExpiration(user_id, group)
    local expiresAt = setVipExpiration(user_id, group, duration)
    if expiresAt then
        mageGroupLog("vrp_group_expiration_set", user_id,
            ("**Resource:** %s\n**Função:** vRP.setUserGroupExpiration\n**Cargo:** %s\n**Expiração anterior:** %s\n**Nova expiração:** %s\n**Duração solicitada:** %s segundo(s)"):format(
                mageGroupOrigin(), tostring(group),
                tonumber(oldExpiration) and tonumber(oldExpiration) > 0 and os.date("%d/%m/%Y às %H:%M:%S", tonumber(oldExpiration)) or "Sem expiração",
                os.date("%d/%m/%Y às %H:%M:%S", expiresAt), tostring(duration or "padrão")
            ))
    end
    return expiresAt ~= nil, expiresAt or 0
end

function vRP.addUserGroup(user_id,group)
    local ngroup = groups[group]
    if not ngroup then return false end

    local addedNow = false
    if not vRP.hasGroup(user_id,group) then
        local user_groups = vRP.getUserGroups(user_id)
        if ngroup._config and ngroup._config.gtype ~= nil then
            -- Cargos VIP são cumulativos: o jogador pode possuir Bronze, Prata,
            -- Ouro etc. ao mesmo tempo. A exclusividade por gtype continua valendo
            -- para os demais tipos (org, staff, emp...), preservando o comportamento
            -- original da base fora do sistema de VIPs.
            local incomingType = tostring(ngroup._config.gtype or ""):lower()
            if incomingType ~= "vip" then
                local _user_groups = {}
                for k,v in pairs(user_groups) do
                    _user_groups[k] = v
                end

                for k,v in pairs(_user_groups) do
                    local kgroup = groups[k]
                    local existingType = kgroup and kgroup._config and tostring(kgroup._config.gtype or ""):lower() or ""
                    if existingType ~= "" and existingType == incomingType then
                        vRP.removeUserGroup(user_id,k)
                    end
                end
            end
        end

        user_groups[group] = true
        addedNow = true
        INDEX[user_id] = nil
        local player = vRP.getUserSource(user_id)
        if ngroup._config and ngroup._config.onjoin and player ~= nil then
            ngroup._config.onjoin(player)
        end

        local gtype = nil
        if ngroup._config then
            gtype = ngroup._config.gtype
        end
        TriggerEvent("vRP:playerJoinGroup",user_id,group,gtype)
    end

    -- Um VIP recém-setado recebe 30 dias. Se algum script chamar addUserGroup
    -- repetidamente para um VIP que o jogador já possui, o prazo NÃO é
    -- renovado silenciosamente. Renovações explícitas usam setUserGroupExpiration.
    if isVipGroup(group) then
        local expirations = vipExpirationTable(user_id)
        local currentExpiration = expirations and tonumber(expirations[group]) or nil
        if addedNow or not currentExpiration or currentExpiration <= 0 then
            setVipExpiration(user_id, group, VIP_DEFAULT_DURATION)
        end
    end

    if addedNow and tostring(group) ~= "user" then
        local gtype = ngroup._config and tostring(ngroup._config.gtype or "") or ""
        mageGroupLog("vrp_group_added", user_id,
            ("**Resource:** %s\n**Função:** vRP.addUserGroup\n**Cargo:** %s\n**Tipo:** %s"):format(
                mageGroupOrigin(), tostring(group), gtype ~= "" and gtype or "sem gtype"
            ))
    end

    return true
end

function vRP.getUsersByPermission(perm)
    local users = {}
    for k,v in pairs(vRP.rusers) do
        if vRP.hasPermission(tonumber(k),perm) then
            table.insert(users,tonumber(k))
        end
    end
    return users
end

function vRP.removeUserGroup(user_id,group)
    local user_groups = vRP.getUserGroups(user_id)
    local existed = user_groups[group] ~= nil
    local groupdef = groups[group]
    if groupdef and groupdef._config and groupdef._config.onleave then
        local source = vRP.getUserSource(user_id)
        if source then groupdef._config.onleave(source) end
    end

    local gtype = groupdef and groupdef._config and groupdef._config.gtype or nil
    TriggerEvent("vRP:playerLeaveGroup",user_id,group,gtype)
    user_groups[group] = nil
    local expirations = vipExpirationTable(user_id)
    if expirations then expirations[group] = nil end
    INDEX[user_id] = nil

    if existed and tostring(group) ~= "user" then
        mageGroupLog("vrp_group_removed", user_id,
            ("**Resource:** %s\n**Função:** vRP.removeUserGroup\n**Cargo:** %s\n**Tipo:** %s"):format(
                mageGroupOrigin(), tostring(group), tostring(gtype or "sem gtype")
            ))
    end
    return existed
end

function vRP.hasGroup(user_id,group)
    local user_groups = vRP.getUserGroups(user_id)
    if user_groups[group] == nil then return false end

    local data = vRP.getUserDataTable(user_id)
    local expiresAt = data and type(data.vip_group_expirations) == "table" and tonumber(data.vip_group_expirations[group]) or nil
    if expiresAt and expiresAt <= os.time() then
        vRP.removeUserGroup(user_id,group)
        return false
    end

    return true
end

local func_perms = {}

function vRP.registerPermissionFunction(name,callback)
    func_perms[name] = callback
end

vRP.registerPermissionFunction("not",function(user_id,parts)
    return not vRP.hasPermission(user_id,"!"..table.concat(parts,".",2))
end)

vRP.registerPermissionFunction("is",function(user_id,parts)
    local param = parts[2]
    if param == "inside" then
        local player = vRP.getUserSource(user_id)
        if player then
            return vRPclient.isInside(player)
        end
    elseif param == "invehicle" then
        local player = vRP.getUserSource(user_id)
        if player then
            return vRPclient.isInVehicle(player)
        end
    end
end)

function vRP.hasPermission(user_id,perm)
    return INDEX[user_id][perm] ~= nil
end

function vRP.hasPermissions(user_id, perms)
    for k,v in ipairs(perms) do
        if vRP.hasPermission(user_id, v) then
            return true
        end
    end
    return false
end

function vRP.getUserGroupByType(user_id,gtype)
    local user_groups = vRP.getUserGroups(user_id)
    if gtype == 'job' and GetInvokingResource() == 'likizao_ac' then
        gtype = 'org'
    end
    for k,v in pairs(user_groups) do
        local kgroup = groups[k]
        if kgroup then
            if kgroup._config and kgroup._config.gtype and kgroup._config.gtype == gtype then
                return k
            end
        end
    end
    return ""
end

function vRP.getUserGroupOrg(user_id)
    local getGroup = vRP.getUserGroupByType(user_id, "org") or 0
    for k,v in pairs(groups) do
        if groups[k] and groups[k]._config ~= nil and k then
            local getOrg = groups[k]._config.orgName
            if k == getGroup then
                return getOrg
            end
        end
    end

    return false
end

function vRP.getUserGroupOrgType(user_id)
    local getGroup = vRP.getUserGroupByType(user_id, "org") or 0
    for k,v in pairs(groups) do
        if groups[k] and groups[k]._config ~= nil and k then
            local getOrgType = groups[k]._config.orgType
            if k == getGroup then
                return getOrgType
            end
        end
    end

    return false
end
-- Limpeza persistente também para jogadores offline. Isso mantém o próprio
-- vrp_user_data correto depois dos 30 dias, sem depender do jogador reconectar.
-- Jogadores online são ignorados aqui para nunca disputar gravação com a tabela
-- viva em memória; eles são tratados pelo loop logo abaixo.
local function cleanupExpiredVipGroupsOffline()
    local rows = exports["oxmysql"]:executeSync(
        "SELECT user_id,dvalue FROM vrp_user_data WHERE dkey = ? AND dvalue LIKE ?",
        { "vRP:datatable", "%vip_group_expirations%" }
    ) or {}
    local now = os.time()

    for _,row in ipairs(rows) do
        local user_id = tonumber(row.user_id)
        if user_id and not vRP.getUserSource(user_id) then
            local ok,data = pcall(json.decode,row.dvalue or "{}")
            if ok and type(data) == "table" and type(data.vip_group_expirations) == "table" then
                local changed = false
                for group,expiresAt in pairs(data.vip_group_expirations) do
                    if tonumber(expiresAt) and tonumber(expiresAt) <= now then
                        data.vip_group_expirations[group] = nil
                        if type(data.groups) == "table" and data.groups[group] ~= nil then
                            data.groups[group] = nil
                        end
                        changed = true
                    end
                end

                if changed then
                    exports["oxmysql"]:executeSync(
                        "UPDATE vrp_user_data SET dvalue = ? WHERE user_id = ? AND dkey = ?",
                        { json.encode(data), user_id, "vRP:datatable" }
                    )
                end
            end
        end
    end
end

CreateThread(function()
    Wait(10000)
    while true do
        local ok,err = pcall(cleanupExpiredVipGroupsOffline)
        if not ok then
            print(("^1[vRP VIP]^7 Falha ao limpar VIPs offline: %s"):format(tostring(err)))
        end
        Wait(600000) -- 10 minutos
    end
end)

-- Expiração em tempo real para jogadores online. Para jogadores offline, o
-- cleaner acima mantém o datatable persistido igualmente correto.
CreateThread(function()
    while true do
        Wait(30000)
        for user_id in pairs(vRP.rusers or {}) do
            cleanupExpiredVipGroups(tonumber(user_id))
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- SPAWN
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("vRP:playerSpawn",function(user_id,source,first_spawn)
    -- Remove VIP expirado antes de qualquer onspawn/permissão ser processado.
    cleanupExpiredVipGroups(user_id)

    if first_spawn then
        local user = users[user_id]
        if user then
            for k,v in pairs(user) do
                vRP.addUserGroup(user_id,v)
            end
        end
    end

    local user_groups = vRP.getUserGroups(user_id)
    for k,v in pairs(user_groups) do
        local group = groups[k]
        if group and group._config and group._config.onspawn then
            group._config.onspawn(source)
        end
    end

    vRP.addUserGroup(user_id, "user")
end)
-- ============================================================================
-- MANAGED GROUP USER HELPERS
-- Permite recursos confiaveis (ex.: m_mansions) adicionar/remover um cargo
-- tambem de jogadores offline, mantendo o mesmo vRP:datatable da base.
-- ============================================================================
local function mutateManagedUserGroup(user_id, group, add)
    user_id = tonumber(user_id)
    group = trimGroupValue(group)
    if not user_id or group == '' then return false,'Usuario ou cargo invalido.' end
    if not groups[group] then return false,'Cargo nao encontrado na vRP.' end

    local source = vRP.getUserSource(user_id)
    if source then
        local ok = add and vRP.addUserGroup(user_id,group) or vRP.removeUserGroup(user_id,group)
        if add then
            return ok == true, ok == true and 'Cargo adicionado.' or 'Nao foi possivel adicionar o cargo.'
        end
        -- Remover um cargo que o usuario ja nao possui e uma operacao idempotente.
        return true, ok and 'Cargo removido.' or 'O usuario ja nao possuia este cargo.'
    end

    local rows = exports['oxmysql']:executeSync(
        'SELECT dvalue FROM vrp_user_data WHERE user_id = ? AND dkey = ? LIMIT 1',
        { user_id, 'vRP:datatable' }
    ) or {}

    if not rows[1] then return false,'Nao foi encontrado o datatable deste ID.' end

    local ok,data = pcall(json.decode,rows[1].dvalue or '{}')
    if not ok or type(data) ~= 'table' then return false,'Datatable do usuario esta invalido.' end
    data.groups = type(data.groups) == 'table' and data.groups or {}

    local existed = data.groups[group] ~= nil
    if add then
        data.groups[group] = true
    else
        data.groups[group] = nil
        if type(data.vip_group_expirations) == 'table' then data.vip_group_expirations[group] = nil end
    end

    exports['oxmysql']:executeSync(
        'UPDATE vrp_user_data SET dvalue = ? WHERE user_id = ? AND dkey = ?',
        { json.encode(data), user_id, 'vRP:datatable' }
    )

    INDEX[user_id] = nil
    mageGroupLog(add and 'vrp_managed_group_offline_added' or 'vrp_managed_group_offline_removed', user_id,
        ('**Resource:** %s\n**Cargo:** %s\n**Operacao offline:** %s\n**Ja possuia:** %s'):format(
            mageGroupOrigin(), tostring(group), add and 'adicionar' or 'remover', existed and 'sim' or 'nao'
        ))

    return true, add and 'Cargo adicionado ao jogador offline.' or 'Cargo removido do jogador offline.'
end

exports('addManagedUserGroup',function(user_id,group)
    return mutateManagedUserGroup(user_id,group,true)
end)

exports('removeManagedUserGroup',function(user_id,group)
    return mutateManagedUserGroup(user_id,group,false)
end)
