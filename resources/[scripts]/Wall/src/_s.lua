GlobalState["pedrin_wall"] = math.random(213444500,213445500)
GlobalState["svpedrin"] = math.random(113444500,113445500)

pedrin = {}
module("vrp","lib/Tunnel").bindInterface(GlobalState["svpedrin"],pedrin)
local chain = GlobalState["pedrin_wall"]
vRP = module("vrp","lib/Proxy").getInterface("vRP")

-- Carrega a configuração de grupos da própria base quando disponível.
-- Isso permite identificar o cargo de STAFF pelo gtype/permissão, sem confundir com a ORG.
local groupDefinitions = {}
do
    local ok,cfg = pcall(module,"vrp","cfg/groups")
    if ok and type(cfg) == "table" then
        if type(cfg.groups) == "table" then
            groupDefinitions = cfg.groups
        else
            groupDefinitions = cfg
        end
    end
end

local wall_infos = {}

local function safeCall(fn,...)
    if type(fn) ~= "function" then
        return nil
    end

    local ok,result = pcall(fn,...)
    if ok then
        return result
    end

    return nil
end

local function trim(value)
    if value == nil then
        return ""
    end

    value = tostring(value)
    return value:match("^%s*(.-)%s*$") or value
end

local function getIdentityName(user_id,source)
    -- Creative: esta é a função padrão da própria identidade para nome completo.
    -- Ela é priorizada para nunca usar o nickname da Steam/FiveM como nome do personagem.
    local fullName = nil

    if vRP.FullName then
        fullName = safeCall(vRP.FullName,user_id)
        if type(fullName) ~= "string" or trim(fullName) == "" then
            fullName = safeCall(vRP.FullName,tostring(user_id))
        end
    end

    if type(fullName) == "string" and trim(fullName) ~= "" then
        return trim(fullName)
    end

    -- Fallback para a tabela de identidade da Creative/vRP.
    local identity = nil

    if vRP.Identity then
        identity = safeCall(vRP.Identity,user_id)
    end

    if (type(identity) ~= "table") and vRP.getUserIdentity then
        identity = safeCall(vRP.getUserIdentity,user_id)
    end

    if (type(identity) ~= "table") and vRP.GetUserIdentity then
        identity = safeCall(vRP.GetUserIdentity,user_id)
    end

    -- Algumas bridges retornam a consulta dentro da posição [1].
    if type(identity) == "table" and type(identity[1]) == "table" then
        identity = identity[1]
    end

    if type(identity) == "table" then
        -- Creative: name + name2
        local firstName = trim(identity.name or identity.nome)
        local lastName = trim(identity.name2 or identity.sobrenome)
        if firstName ~= "" and lastName ~= "" then
            return trim(firstName.." "..lastName)
        end

        -- vRPex: name + firstname
        local vrpexName = trim(identity.name)
        local vrpexSurname = trim(identity.firstname)
        if vrpexName ~= "" and vrpexSurname ~= "" then
            return trim(vrpexName.." "..vrpexSurname)
        end

        -- Outros formatos comuns de identidade.
        local givenName = trim(identity.firstname or identity.first_name or identity.nome)
        local surname = trim(identity.lastname or identity.Lastname or identity.last_name or identity.surname or identity.sobrenome)
        if givenName ~= "" and surname ~= "" then
            return trim(givenName.." "..surname)
        end

        -- Caso a identidade tenha apenas um campo de nome, ainda usamos o dado da identidade,
        -- nunca o nickname gerado pelo FiveM/Steam.
        local singleName = trim(identity.name or identity.nome or identity.firstname or identity.first_name)
        if singleName ~= "" then
            return singleName
        end
    end

    return "N/A"
end

local function getOrgGroup(user_id)
    local org = nil

    -- Função usada em várias bases vrpex/Creative adaptadas.
    if vRP.getUserGroupOrg then
        org = safeCall(vRP.getUserGroupOrg,user_id)
    end

    -- Fallback padrão vRP: grupo cujo gtype é "org".
    if (org == nil or org == "") and vRP.getUserGroupByType then
        org = safeCall(vRP.getUserGroupByType,user_id,"org")
    end

    if type(org) == "table" then
        org = org.orgName or org.orgname or org.groupId or org.group or org.name or org.id or org[1]
    end

    org = trim(org)
    if org == "" then
        return "N/A"
    end

    return org
end

local function addUnique(list,lookup,value)
    value = trim(value)
    if value == "" or value == "_config" or lookup[value] then
        return
    end

    lookup[value] = true
    list[#list + 1] = value
end

local function normalizeGroups(groups)
    local list = {}
    local lookup = {}

    if type(groups) ~= "table" then
        return list
    end

    for key,value in pairs(groups) do
        if type(key) == "string" and key ~= "_config" then
            -- Formato mais comum: { ["Admin"] = true, ["Mafia"] = true }
            if value ~= false and value ~= nil then
                addUnique(list,lookup,key)
            end
        elseif type(value) == "string" or type(value) == "number" then
            addUnique(list,lookup,value)
        elseif type(value) == "table" then
            addUnique(list,lookup,value.groupId or value.group_id or value.group or value.name or value.id)
        end
    end

    table.sort(list,function(a,b)
        return string.lower(a) < string.lower(b)
    end)

    return list
end

local STAFF_PRIORITY = {
    ["dono"] = 1000,
    ["owner"] = 990,
    ["fundador"] = 980,
    ["developer"] = 900,
    ["desenvolvedor"] = 900,
    ["diretor"] = 850,
    ["administrador"] = 800,
    ["admin"] = 800,
    ["gerente"] = 700,
    ["moderador"] = 600,
    ["mod"] = 600,
    ["suporte"] = 500,
    ["staff"] = 400
}

local function extractGroupName(group)
    if type(group) == "table" then
        group = group.groupId or group.group_id or group.group or group.name or group.id or group[1]
    end

    group = trim(group)
    if group == "" then
        return nil
    end

    return group
end

local function groupHasStaffFlag(groupName)
    local definition = groupDefinitions[groupName]
    if type(definition) ~= "table" then
        return false
    end

    local config = definition._config
    if type(config) == "table" then
        local gtype = string.lower(trim(config.gtype or config.type))
        if gtype == "staff" or gtype == "admin" or gtype == "administracao" or gtype == "administracao_staff" then
            return true
        end
    end

    -- Muitas bases colocam perm.ptr.staff diretamente na lista de permissões do grupo.
    local function scan(tbl)
        if type(tbl) ~= "table" then
            return false
        end

        for key,value in pairs(tbl) do
            if type(value) == "string" and string.lower(trim(value)) == "perm.ptr.staff" then
                return true
            end

            if type(key) == "string" and string.lower(trim(key)) == "perm.ptr.staff" and value ~= false then
                return true
            end
        end

        return false
    end

    if scan(definition) then
        return true
    end

    if type(definition.permissions) == "table" and scan(definition.permissions) then
        return true
    end

    return false
end

local function getStaffGroup(user_id)
    -- Primeiro tenta o tipo oficial configurado na própria vRP.
    if vRP.getUserGroupByType then
        local byType = extractGroupName(safeCall(vRP.getUserGroupByType,user_id,"staff"))
        if byType then
            return byType
        end
    end

    local rawGroups = nil
    if vRP.getUserGroups then
        rawGroups = safeCall(vRP.getUserGroups,user_id)
    end
    if type(rawGroups) ~= "table" and vRP.GetUserGroups then
        rawGroups = safeCall(vRP.GetUserGroups,user_id)
    end

    local groups = normalizeGroups(rawGroups)
    local bestGroup = nil
    local bestScore = -1

    for _,groupName in ipairs(groups) do
        local lower = string.lower(trim(groupName))
        local priority = STAFF_PRIORITY[lower]
        local configuredAsStaff = groupHasStaffFlag(groupName)

        if configuredAsStaff or priority then
            local score = priority or 100
            if configuredAsStaff then
                score = score + 10000
            end

            if score > bestScore then
                bestScore = score
                bestGroup = groupName
            end
        end
    end

    -- Se a pessoa possui a permissão geral de staff, os nomes conhecidos acima
    -- funcionam como fallback mesmo em bases sem gtype configurado.
    if bestGroup and vRP.hasPermission then
        local isStaff = safeCall(vRP.hasPermission,user_id,"perm.ptr.staff")
        if isStaff == false and not groupHasStaffFlag(bestGroup) then
            return "N/A"
        end
    end

    return bestGroup or "N/A"
end

local function getAllGroups(user_id)
    local groups = nil

    if vRP.getUserGroups then
        groups = safeCall(vRP.getUserGroups,user_id)
    end

    if type(groups) ~= "table" and vRP.GetUserGroups then
        groups = safeCall(vRP.GetUserGroups,user_id)
    end

    local list = normalizeGroups(groups)
    if #list == 0 then
        local org = getOrgGroup(user_id)
        if org ~= "N/A" then
            list[1] = org
        end
    end

    return list
end

local function refreshWallInfo(source)
    source = tonumber(source)
    if not source then
        return nil
    end

    local user_id = vRP.getUserId(source)
    if not user_id then
        wall_infos[source] = nil
        return nil
    end

    local old = wall_infos[source] or {}
    local info = {
        user_id = user_id,
        name = getIdentityName(user_id,source),
        staff = getStaffGroup(user_id),
        org = getOrgGroup(user_id),
        groups = getAllGroups(user_id),
        wallstats = old.wallstats == true
    }

    wall_infos[source] = info
    return info
end

function pedrin.setWallInfos()
    refreshWallInfo(source)
end

function pedrin.getWallInfos()
    -- Atualiza nome/cargos para o wall refletir alterações feitas com o jogador online.
    local online = {}
    for _,playerSource in ipairs(GetPlayers()) do
        local src = tonumber(playerSource)
        if src then
            online[src] = true
            refreshWallInfo(src)
        end
    end

    for src,_ in pairs(wall_infos) do
        if not online[tonumber(src)] then
            wall_infos[src] = nil
        end
    end

    return wall_infos
end

RegisterCommand("wall",function(source,args)
    local user_id = vRP.getUserId(source)
    if not user_id then
        return
    end

    if vRP.hasPermission(user_id,"perm.ptr.staff") then
        local info = refreshWallInfo(source)
        if not info then
            return
        end

        info.wallstats = not info.wallstats
        wall_infos[source].wallstats = info.wallstats
        TriggerClientEvent(chain..":wall",source,info.wallstats)
    else
        TriggerClientEvent("Notify",source,"negado","Você não possui permissão!.",5)
    end
end)

AddEventHandler("playerDropped",function()
    wall_infos[source] = nil
end)
