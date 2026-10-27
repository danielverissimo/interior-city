
-----------------------------------------------------------------------------------------------------------------------------------------
-- ORGANIZAÇÕES DINÂMICAS - MG CONFIG PANEL
-----------------------------------------------------------------------------------------------------------------------------------------
local DYNAMIC_FILE = "dynamic_orgs.json"
local DynamicOrgs = { organizations = {}, deleted = {} }
local BaseOrganizationNames = {}

-- Guarda quais organizações vieram originalmente do config.lua.
for name in pairs(Config.Groups or {}) do
    BaseOrganizationNames[tostring(name)] = true
end

local function trim(value)
    return tostring(value or ""):gsub("^%s+",""):gsub("%s+$","")
end

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k,v in pairs(value) do out[k] = deepCopy(v) end
    return out
end

local function loadDynamicFile()
    local raw = LoadResourceFile(GetCurrentResourceName(),DYNAMIC_FILE)
    local ok,data = pcall(json.decode,raw or "{}")
    DynamicOrgs = ok and type(data) == "table" and data or {}
    if type(DynamicOrgs.organizations) ~= "table" then DynamicOrgs.organizations = {} end
    if type(DynamicOrgs.deleted) ~= "table" then DynamicOrgs.deleted = {} end
end

local function saveDynamicFile()
    return SaveResourceFile(
        GetCurrentResourceName(),
        DYNAMIC_FILE,
        json.encode(DynamicOrgs),
        -1
    )
end

local function isDeleted(name)
    for _,deletedName in ipairs(DynamicOrgs.deleted) do
        if tostring(deletedName) == tostring(name) then return true end
    end
    return false
end

local function removeDeleted(name)
    for i=#DynamicOrgs.deleted,1,-1 do
        if tostring(DynamicOrgs.deleted[i]) == tostring(name) then
            table.remove(DynamicOrgs.deleted,i)
        end
    end
end

local function buildOrganization(orgName,goalItem,goalAmount,defaultReward)
    local ranks = {
        { name="Lider", tier=1 },
        { name="SubLider", tier=2 },
        { name="Gerente", tier=3 },
        { name="Recrutador", tier=6 },
        { name="Membro", tier=7 },
        { name="Novato", tier=8 }
    }

    local list = {}
    for _,rank in ipairs(ranks) do
        local group = rank.name..orgName
        list[group] = {
            prefix = group,
            tier = rank.tier
        }
    end

    return {
        Config = {
            Salary = {
                active = false,
                amount = 2000,
                time = 30
            },
            Goals = {
                defaultReward = tonumber(defaultReward) or 300,
                itens = {
                    [goalItem] = tonumber(goalAmount) or 500
                }
            }
        },
        List = list
    }
end

local function applyOverlay()
    for _,name in ipairs(DynamicOrgs.deleted) do
        Config.Groups[tostring(name)] = nil
    end

    for name,data in pairs(DynamicOrgs.organizations) do
        if not isDeleted(name) then
            Config.Groups[tostring(name)] = deepCopy(data)
        end
    end
end

loadDynamicFile()
applyOverlay()

local function defaultPermissionsFor(orgName)
    local perms = {}
    local org = Config.Groups[orgName]
    if not org or not org.List then return perms end

    for group,data in pairs(org.List) do
        perms[group] = {}
        for permission in pairs(Config.defaultPermissions or {}) do
            perms[group][permission] = data.tier == 1
        end

        if data.tier == 1 then
            perms[group].leader = true
        end

        if data.tier == 2 or data.tier == 3 then
            perms[group].withdraw = true
            perms[group].deposit = true
        end
    end

    return perms
end

local function registerRuntimeOrganization(orgName)
    local org = Config.Groups[orgName]
    if not org or not Organizations then return end

    Organizations.MembersList[orgName] = Organizations.MembersList[orgName] or {}

    for group in pairs(org.List or {}) do
        Organizations.List[group] = orgName
    end

    local goalInfo = {
        info = {
            defaultReward = tonumber(org.Config and org.Config.Goals and org.Config.Goals.defaultReward) or 300,
            itens = {}
        }
    }

    for item,maxAmount in pairs(
        org.Config and org.Config.Goals and org.Config.Goals.itens or {}
    ) do
        goalInfo.info.itens[item] = {
            max = tonumber(maxAmount) or 0,
            needed = true
        }
    end

    Organizations.goalsConfig[orgName] = goalInfo
    Organizations.Permissions[orgName] = defaultPermissionsFor(orgName)

    exports["oxmysql"]:executeSync(
        "INSERT IGNORE INTO mirtin_orgs_info(organization) VALUES(?)",
        { orgName }
    )

    exports["oxmysql"]:executeSync(
        "UPDATE mirtin_orgs_info SET permissions = ?, config_goals = ? WHERE organization = ?",
        {
            json.encode(Organizations.Permissions[orgName]),
            json.encode(goalInfo),
            orgName
        }
    )
end

local function unregisterRuntimeOrganization(orgName)
    local org = Config.Groups[orgName]

    if Organizations then
        if org and org.List then
            for group in pairs(org.List) do
                Organizations.List[group] = nil
            end
        else
            -- Segurança para casos em que Config.Groups já foi removido.
            for group,groupType in pairs(Organizations.List or {}) do
                if tostring(groupType) == tostring(orgName) then
                    Organizations.List[group] = nil
                end
            end
        end

        Organizations.Permissions[orgName] = nil
        Organizations.goalsConfig[orgName] = nil
        Organizations.payDayOrg[orgName] = nil
        Organizations.MembersList[orgName] = nil

        for userId,user in pairs(Organizations.Members or {}) do
            if user and tostring(user.groupType) == tostring(orgName) then
                Organizations.Members[userId] = nil
            end
        end
    end
end

exports("canCreateManagedOrganization",function(orgName)
    orgName = trim(orgName)
    if orgName == "" then return false,"Informe o orgName da FAC." end
    if Config.Groups[orgName] then return false,"Esta organização já existe no m_orgs_v2." end
    return true
end)

exports("addManagedOrganization",function(orgName,goalItem,goalAmount,defaultReward)
    orgName = trim(orgName)
    goalItem = trim(goalItem)
    goalAmount = tonumber(goalAmount)
    defaultReward = tonumber(defaultReward)

    if orgName == "" then return false,"Informe o orgName da FAC." end
    if goalItem == "" then return false,"Informe o item da meta." end
    if not goalAmount or goalAmount <= 0 then return false,"Quantidade da meta inválida." end
    if not defaultReward or defaultReward < 0 then return false,"Recompensa padrão inválida." end
    if Config.Groups[orgName] then return false,"Esta organização já existe no m_orgs_v2." end

    local organization = buildOrganization(orgName,goalItem,goalAmount,defaultReward)

    DynamicOrgs.organizations[orgName] = deepCopy(organization)
    removeDeleted(orgName)

    if not saveDynamicFile() then
        DynamicOrgs.organizations[orgName] = nil
        return false,"Não foi possível salvar dynamic_orgs.json."
    end

    Config.Groups[orgName] = deepCopy(organization)
    registerRuntimeOrganization(orgName)

    return true,("Organização %s criada no m_orgs_v2."):format(orgName)
end)

exports("removeManagedOrganization",function(orgName)
    orgName = trim(orgName)
    if orgName == "" then return false,"Informe a FAC." end

    local existed = Config.Groups[orgName] ~= nil
    if not existed and not DynamicOrgs.organizations[orgName] then
        return false,"Organização não encontrada no m_orgs_v2."
    end

    unregisterRuntimeOrganization(orgName)

    DynamicOrgs.organizations[orgName] = nil

    if BaseOrganizationNames[orgName] and not isDeleted(orgName) then
        DynamicOrgs.deleted[#DynamicOrgs.deleted+1] = orgName
    end

    if not saveDynamicFile() then
        return false,"Não foi possível salvar a exclusão no dynamic_orgs.json."
    end

    Config.Groups[orgName] = nil

    -- Limpeza dos dados específicos desta FAC.
    exports["oxmysql"]:executeSync("DELETE FROM mirtin_orgs_goals WHERE organization = ?",{orgName})
    exports["oxmysql"]:executeSync("DELETE FROM mirtin_orgs_player_infos WHERE organization = ?",{orgName})
    exports["oxmysql"]:executeSync("DELETE FROM mirtin_orgs_chat WHERE organization = ?",{orgName})
    exports["oxmysql"]:executeSync("DELETE FROM sjr_logs WHERE organization = ?",{orgName})
    exports["oxmysql"]:executeSync("DELETE FROM mirtin_organization_members WHERE group_type = ?",{orgName})
    exports["oxmysql"]:executeSync("DELETE FROM mirtin_orgs_info WHERE organization = ?",{orgName})

    return true,("Organização %s excluída do m_orgs_v2."):format(orgName)
end)

exports("getManagedOrganizationNames",function()
    local result = {}
    for name in pairs(Config.Groups or {}) do
        result[#result+1] = tostring(name)
    end
    table.sort(result,function(a,b) return a:lower() < b:lower() end)
    return result
end)
