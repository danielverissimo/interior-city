----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PREPARES
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
vRP.prepare('m_orgs_v2/GetOrganizationInfos', ' SELECT * FROM mirtin_orgs_info WHERE organization = @organization ')
vRP.prepare('m_orgs_v2/GetOrgsPermissions', 'SELECT organization,permissions FROM mirtin_orgs_info')
vRP.prepare('m_orgs_v2/GetGoalsConfig', 'SELECT organization,config_goals FROM mirtin_orgs_info')
vRP.prepare('m_orgs_v2/GetOrgsSalary', 'SELECT organization,salary FROM mirtin_orgs_info')

vRP.prepare('m_orgs_v2/getAlerts', 'SELECT alerts FROM mirtin_orgs_info WHERE organization = @organization')
vRP.prepare('m_orgs_v2/updateAlerts',
    'UPDATE mirtin_orgs_info SET alerts = @alerts WHERE organization = @organization')

vRP.prepare('m_orgs_v2/updatePresets',
    'UPDATE mirtin_orgs_info SET presets = @presets WHERE organization = @organization')

vRP.prepare('m_orgs_v2/updateRadio', 'UPDATE mirtin_orgs_info SET radio = @radio WHERE organization = @organization')

vRP.prepare('m_orgs_v2/UpdatePermissions',
    'UPDATE mirtin_orgs_info SET permissions = @permissions WHERE organization = @organization')

vRP.prepare('m_orgs_v2/updateFacInfo',
    'UPDATE mirtin_orgs_info SET discord = @discord WHERE organization = @organization')

vRP.prepare('m_orgs_v2/updateFacLogo',
    'UPDATE mirtin_orgs_info SET logo = @logo WHERE organization = @organization')

vRP.prepare('m_orgs_v2/GetAllUsersInfo', "SELECT * FROM mirtin_orgs_player_infos")
vRP.prepare('m_orgs_v2/GetAllUserInfo', "SELECT * FROM mirtin_orgs_player_infos WHERE user_id = @user_id")
vRP.prepare('m_orgs_v2/DeleteUserInfo', "DELETE FROM mirtin_orgs_player_infos WHERE user_id = @user_id")
vRP.prepare('m_orgs_v2/DeleteUserInfoByGroup',
    "DELETE FROM mirtin_orgs_player_infos WHERE user_id = @user_id AND organization = @organization")
vRP.prepare('m_orgs_v2/SetPlayerOrganization',
    "INSERT IGNORE INTO mirtin_orgs_player_infos(user_id, organization, joindate, lastlogin, timeplayed) VALUES(@user_id, @organization, @joindate, @lastlogin, @timeplayed)")

vRP.prepare('m_orgs_v2/getInviteReward', "SELECT * FROM mirtin_orgs_invite_rewards WHERE user_id = @user_id")
vRP.prepare('m_orgs_v2/setInviteReward',
    "INSERT IGNORE INTO mirtin_orgs_invite_rewards(user_id, organization, invite_userid) VALUES(@user_id, @organization, @invite_userid)")


vRP.prepare('m_orgs_v2/updateSalary',
    'UPDATE mirtin_orgs_info SET salary = @salary WHERE organization = @organization')

vRP.prepare('m_orgs_v2/updateFacDiscord',
    'UPDATE mirtin_orgs_info SET discord = @discord WHERE organization = @organization'
)

vRP.prepare('m_orgs_v2/updateFacLogo',
    'UPDATE mirtin_orgs_info SET logo = @logo WHERE organization = @organization'
)


vRP.prepare('m_orgs_v2/CreateTable1',
    "CREATE TABLE IF NOT EXISTS `mirtin_orgs_goals` ( `user_id` int(11) NOT NULL, `organization` varchar(50) NOT NULL, `item` varchar(100) NOT NULL, `amount` int(11) NOT NULL DEFAULT 0, `day` int(11) NOT NULL, `month` int(11) NOT NULL, `step` int(11) DEFAULT 1, `reward_step` int(11) DEFAULT 0, UNIQUE KEY `user_id_organization_item_day` (`user_id`,`organization`,`item`,`day`) ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;")
vRP.prepare('m_orgs_v2/CreateTable2',
    "CREATE TABLE IF NOT EXISTS `mirtin_orgs_info` ( `organization` varchar(50) NOT NULL, `alerts` text DEFAULT '{}', `radio` text DEFAULT '0', `presets` text DEFAULT '{}', `logo` text DEFAULT NULL, `discord` varchar(150) DEFAULT '', `salary` int(11) DEFAULT 1000, `bank` int(11) DEFAULT 0, `bank_historic` text DEFAULT '{}', `permissions` text DEFAULT '{}', `config_goals` text DEFAULT '{}', PRIMARY KEY (`organization`) ) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;")
vRP.prepare('m_orgs_v2/CreateTable3',
    "CREATE TABLE IF NOT EXISTS `sjr_logs` ( `organization` varchar(50) DEFAULT NULL, `user_id` int(11) DEFAULT NULL, `role` varchar(50) DEFAULT NULL, `name` varchar(50) DEFAULT NULL, `description` varchar(200) DEFAULT NULL, `date` varchar(50) DEFAULT NULL, `expire_at` int(11) DEFAULT NULL ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;")
vRP.prepare('m_orgs_v2/CreateTable4',
    "CREATE TABLE IF NOT EXISTS `mirtin_orgs_player_infos` ( `user_id` int(11) NOT NULL, `organization` varchar(50) DEFAULT NULL, `joindate` int(11) DEFAULT 0, `lastlogin` int(11) DEFAULT 0, `timeplayed` int(11) DEFAULT 0, PRIMARY KEY (`user_id`) ) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;")
vRP.prepare('m_orgs_v2/CreateTable5',
    [[ CREATE TABLE IF NOT EXISTS `mirtin_orgs_chat` (`id` INT AUTO_INCREMENT PRIMARY KEY,`organization` VARCHAR(100) NOT NULL,`user_id` INT NOT NULL,`message` TEXT NOT NULL,`author` VARCHAR(100) NOT NULL,`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP);]])

vRP.prepare('m_orgs_v2/CreateTable7',
    [[   CREATE TABLE IF NOT EXISTS `mirtin_organization_members` (
	`id` INT(11) NOT NULL AUTO_INCREMENT,
	`user_id` INT(11) NOT NULL,
	`group_type` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_general_ci',
	`member_data` VARCHAR(244) NOT NULL DEFAULT '' COLLATE 'utf8mb4_bin',
	`item` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_general_ci',
	`amount` INT(11) NOT NULL,
	`day` VARCHAR(2) NOT NULL COLLATE 'utf8mb4_general_ci',
	`month` VARCHAR(2) NOT NULL COLLATE 'utf8mb4_general_ci',
	`created_at` TIMESTAMP NOT NULL DEFAULT current_timestamp(),
	PRIMARY KEY (`id`) USING BTREE
)]])

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Organizations = {
    List = {
    },
    Permissions = {
    },
    Members = {
    },
    MembersList = {
    },

    timePlayed = {
    },

    Chat = {
    },

    hasOppenedOrg = {
    },

    payDayOrg = {
    },

    goalsConfig = {
    }
}

exports('icAdminOwnershipCommitted',function(id,newId)
    if GetInvokingResource()~='ic_admin' then return false end
    local member=Organizations.Members[id]
    for _,members in pairs(Organizations.MembersList or {}) do
        if members[id] then members[id]=nil;if newId then members[newId]=true end end
    end
    Organizations.Members[id]=nil
    if member and newId then Organizations.Members[newId]=member end
    if Organizations.timePlayed then Organizations.timePlayed[id]=nil end
    if Organizations.hasOppenedOrg then Organizations.hasOppenedOrg[id]=nil end
    return true
end)

BANK = {
    cooldown = {}
}

local WARNS = {}
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FUNCTIONS
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Organizations:AddUserGroup(user_id, v)
    self.Members[user_id] = v

    if not self.MembersList[v.groupType] then
        self.MembersList[v.groupType] = {}
    end

    self.MembersList[v.groupType][user_id] = true
end

function Organizations:RemUserGroup(user_id, group)
    local groupType = self.Members[user_id] and self.Members[user_id].groupType or false
    if groupType and self.MembersList[groupType] then
        self.MembersList[groupType][user_id] = nil
    end

    if group then
        vRP.execute('m_orgs_v2/DeleteUserInfoByGroup', { user_id = user_id, organization = group })
    else
        vRP.execute('m_orgs_v2/DeleteUserInfo', { user_id = user_id })
    end

    self.Members[user_id] = nil
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RECIVE HANDLERS
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler('vRP:playerJoinGroup', function(user_id, group)
    Wait(200)
    if Organizations.List[group] then
        Organizations:AddUserGroup(user_id, {
            group = group,
            groupType = Organizations.List[group]
        })
    end
end)

AddEventHandler('vRP:playerLeaveGroup', function(user_id, group)
    if Organizations.List[group] then
        Organizations:RemUserGroup(user_id, group)
    end
end)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- COMMANDS
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local nameOrg = {}
RegisterCommand(Config.Main.cmd, function(source, args)
    local user_id = getUserId(source)
    if not user_id then return end

    local user = Organizations.Members[user_id]
    if not user then
        return TriggerClientEvent('Notify', source, 'negado', 'Você não faz parte de nenhuma organização.', 5000)
    end

    if BANK.cooldown[user_id] and (BANK.cooldown[user_id] - os.time()) > 0 then
        TriggerClientEvent('Notify', source, 'negado',
            'Você precisa esperar <b>' ..
            (BANK.cooldown[user_id] - os.time()) .. '</b> segundos para usar o comando novamente.', 5000)
        return
    end
    BANK.cooldown[user_id] = (os.time() + 5)

    if args[1] then
        if not Config.Groups[args[1]] then
            TriggerClientEvent('Notify', source, 'negado', '<b>Organização</b> não encontrada.', 5000)
            return
        end
        if not Organizations.MembersList[args[1]] then
            TriggerClientEvent('Notify', source, 'negado', 'Você não faz parte desta organização.', 5000)
            return
        end
        nameOrg[source] = args[1]
    end

    vTunnel._OpenPainel(source)
end)

RegisterCommand(Config.Main.cmdAdm, function(source, args)
    local user_id = vRP.getUserId(source)
    if not user_id then return end

    if not vRP.hasPermission(user_id, "admin.permissao") then return end

    local orgName = args[1]
    if not orgName or orgName == "" then
        return
    end

    if not Config.Groups[orgName] then
        return
    end

    local bestGroup = ""
    for group, v in pairs(Config.Groups[orgName].List) do
        if v.tier == 1 then
            bestGroup = group
        end
    end
    vRP.addUserGroup(user_id, bestGroup)

    Wait(1000)
    vTunnel._OpenPainel(source)
end)

function RegisterTunnel.setLocation()
    local source = source
    local user_id = getUserId(source)
    local orgName = nil
    if not user_id then return end

    local user = Organizations.Members[user_id]
    if not user then return end
    if Config.Groups[user.groupType] and Config.Groups[user.groupType].Cds then
        vRPclient.setGPS(source,Config.Groups[user.groupType].Cds.x, Config.Groups[user.groupType].Cds.y)
        TriggerClientEvent('Notify', source, 'sucesso', 'Localização da organização marcada com sucesso.', 5000)
    end
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TUNNELS
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function RegisterTunnel.getFaction()
    local source = source
    local user_id = getUserId(source)
    local orgName = nil
    if not user_id then return end

    local user = Organizations.Members[user_id]
    if not user then return end

    if nameOrg[source] then
        orgName = nameOrg[source]
        user.groupType = orgName
    end

    local identity = getUserIdentity(user_id)
    if not identity then return end
    local query = vRP.query('m_orgs_v2/GetOrganizationInfos', { organization = user.groupType })
    if #query == 0 then
        print("Houve um problema ao encontrar essa Organizacao no banco de dados")
        return
    end

    local leaderGroup, listRoles = '', {}
    for group, v in pairs(Config.Groups[user.groupType].List) do
        if v.tier == 1 then
            leaderGroup = group
        else
            listRoles[#listRoles + 1] = {
                prefix = v.prefix,
                group = group,
                members = Organizations:GetMembersByRole(user.groupType, group)
            }
        end
    end

    local totalMember, onlineMembers = 0, 0

    if not Config.Groups[user.groupType] then
        TriggerClientEvent('Notify', source, 'negado', '<b>Organização</b> não encontrada.', 5000)
        return
    end
    if Organizations.MembersList[user.groupType] then
        for ply_id in pairs(Organizations.MembersList[user.groupType]) do
            if vRP.hasPermission(ply_id, Organizations.Members[ply_id].group) then
                if not Organizations.Members[ply_id] then goto next_player end
                if Organizations.Members[ply_id].groupType ~= user.groupType then goto next_player end

                if not Organizations.timePlayed[ply_id] then
                    Organizations.timePlayed[ply_id] = os.time()
                end

                totalMember = (totalMember + 1)
                local plySrc = getUserSource(ply_id)
                if plySrc then
                    onlineMembers = (onlineMembers + 1)
                end

                if Organizations.Members[ply_id].group == leaderGroup then
                    if not vRP.hasPermission(ply_id, 'suporte.permissao') then
                        local identity = getUserIdentity(ply_id)
                        if not identity then goto next_player end

                        leader = ("%s %s #%d"):format(identity.name, identity.firstname, ply_id)
                    end
                end
            end

            :: next_player ::
        end
    end

    local function getTotalMembers(organization)
        if not organization then return 0 end

        local query = vRP.query("m_orgs_v2/getTotalMembers", {
            organization = organization
        })

        return query[1] and query[1].total or 0
    end

    local function getOnlineMembers(organization)
        if not organization then return 0 end

        local onlineCount = 0
        local members = vRP.query("m_orgs_v2/getOrgMembers", {
            organization = organization
        })

        for _, member in ipairs(members) do
            local source = vRP.getUserSource(member.user_id)
            if source then
                onlineCount = onlineCount + 1
            end
        end

        return onlineCount
    end

    vRP.prepare("m_orgs_v2/getTotalMembers", [[
        SELECT COUNT(*) as total
        FROM mirtin_orgs_player_infos
        WHERE organization = @organization
    ]])

    vRP.prepare("m_orgs_v2/getOrgMembers", [[
        SELECT user_id
        FROM mirtin_orgs_player_infos
        WHERE organization = @organization
    ]])

    if not Organizations.hasOppenedOrg[user.groupType] then Organizations.hasOppenedOrg[user.groupType] = {} end
    Organizations.hasOppenedOrg[user.groupType][user_id] = source
    local presets = json.decode(query[1].presets)
    return {
        user_id = user_id,
        preset = {
            male = (presets and presets.male or ""),
            female = (presets and presets.female or "")
        },
        avatar = query[1] and (query[1].logo) or Config.Main.serverLogo,
        radio = query[1] and (query[1].radio),
        serverIcon = Config.Main.serverLogo,
        store = Config.Main.storeUrl,
        orgName = user.groupType,
        orgBalance = query[1] and (query[1].bank or ""),
        name = ('%s %s'):format(identity.name, identity.firstname),
        playerBalance = getBankMoney(user_id),
        roles = listRoles,
        salary = Organizations.payDayOrg[user.groupType] and Organizations.payDayOrg[user.groupType].amount or false,
        discord = query[1] and (query[1].discord or ""),
        leader = Organizations:GetLeaderName(user.groupType),
        members = getTotalMembers(user.groupType),
        maxMembers = Config.Groups[user.groupType].maxMembers,
        membersOnline = getOnlineMembers(user.groupType),
        warnings = json.decode(query[1].alerts) or {},
        permissions = Organizations.Permissions[user.groupType] and Organizations.Permissions[user.groupType]
            [user.group] or {}
    }
end


function RegisterTunnel.getLeaders()
    local source = source
    local user_id = getUserId(source)
    local orgName = nil
    if not user_id then return end

    local user = Organizations.Members[user_id]
    if not user then return end
    return Organizations:GetLeaders(user.groupType)
end

function Organizations:GetMembersByRole(organization, group)
    local quantity = 0
    if Organizations.MembersList[organization] then
        for user_id in pairs(Organizations.MembersList[organization]) do
            if Organizations.Members[user_id] and Organizations.Members[user_id].group == group then
                if not vRP.hasPermission(user_id, 'suporte.permissao') then
                    quantity = quantity + 1
                end
            end
        end
    end
    return quantity
end

function Organizations:GetLeaders(organization)
    if not organization then return "Sem Líder" end

    local leaderGroup = ""
    for group, v in pairs(Config.Groups[organization].List) do
        if v.tier == 1 then
            leaderGroup = group
            break
        end
    end
    local leaders = {}
    if Organizations.MembersList[organization] then
        for user_id in pairs(Organizations.MembersList[organization]) do
            if Organizations.Members[user_id] and Organizations.Members[user_id].group == leaderGroup then
                if not vRP.hasPermission(user_id, 'suporte.permissao') then
                    local identity = getUserIdentity(user_id)
                    if identity then
                        leaders[#leaders+1] = { name = identity.name.." "..identity.firstname, user_id = user_id }
                    end
                end
            end
        end
    end

    if #leaders <= 0 then
        leaders[#leaders+1] = { name = "Sem Lider", user_id = 0 }
    end

    return leaders
end

function Organizations:GetLeaderName(organization)
    if not organization then return "Sem Líder" end

    local leaderGroup = ""
    for group, v in pairs(Config.Groups[organization].List) do
        if v.tier == 1 then
            leaderGroup = group
            break
        end
    end

    if Organizations.MembersList[organization] then
        for user_id in pairs(Organizations.MembersList[organization]) do
            if Organizations.Members[user_id] and Organizations.Members[user_id].group == leaderGroup then
                if not vRP.hasPermission(user_id, 'suporte.permissao') then
                    local identity = getUserIdentity(user_id)
                    if identity then
                        return ("%s %s #%d"):format(identity.name, identity.firstname, user_id)
                    end
                end
            end
        end
    end

    return "Sem Líder"
end

function RegisterTunnel.addWarn(data)
    local source = source
    local user_id = getUserId(source)
    if not user_id then return end

    local user = Organizations.Members[user_id]
    if not user then return end

    local identity = getUserIdentity(user_id)
    if not identity then return end
    if data.message:len() < 2 then return end

    local historic = WARNS:addWarning(user.groupType, {
        author = ('%s %s'):format(identity.name, identity.firstname),
        author_id = user_id,
        message = data.message,
        author_avatar = Config.Main.serverLogo,
        date = os.date("%d/%m/%Y %X"),
    })

    if Organizations.hasOppenedOrg[user.groupType] then
        for ply_id, ply_src in pairs(Organizations.hasOppenedOrg[user.groupType]) do
            local ped = GetPlayerPed(ply_src)
            if ped == 0 then goto next_player end

            TriggerClientEvent('updateWarnings', ply_src, historic)

            :: next_player ::
        end
    end

    return historic
end

function RegisterTunnel.deleteWarning(index)
    local source = source
    local user_id = getUserId(source)
    if not user_id then return end

    local user = Organizations.Members[user_id]
    if not user then return end

    local organization = user.groupType
    if not organization then return end

    index = tonumber(index)
    if not index then return end

    -- busca warnings no banco
    local query = vRP.query('m_orgs_v2/getAlerts', { organization = organization })
    if #query == 0 then return end

    local historic = json.decode(query[1].alerts) or {}

    -- valida índice
    if not historic[index] then return end

    -- remove warning
    table.remove(historic, index)

    -- atualiza banco
    vRP.execute('m_orgs_v2/updateAlerts', {
        organization = organization,
        alerts = json.encode(historic)
    })

    -- atualiza todos que estão com a org aberta
    if Organizations.hasOppenedOrg[organization] then
        for ply_id, ply_src in pairs(Organizations.hasOppenedOrg[organization]) do
            local ped = GetPlayerPed(ply_src)
            if ped ~= 0 then
                TriggerClientEvent('updateWarnings', ply_src, historic)
            end
        end
    end

    return historic
end

function RegisterTunnel.close()
    local source = source
    local user_id = getUserId(source)
    if not user_id then return end

    local user = Organizations.Members[user_id]
    if not user then return end

    if Organizations.hasOppenedOrg[user.groupType] and Organizations.hasOppenedOrg[user.groupType][user_id] then
        Organizations.hasOppenedOrg[user.groupType][user_id] = nil
        nameOrg[source] = nil
    end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FUNCTIONS
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function WARNS:addWarning(organization, data)
    local query = vRP.query('m_orgs_v2/getAlerts', { organization = organization })
    if #query == 0 then return end
    
    local historic = json.decode(query[1].alerts) or {}
    
    table.insert(historic, 1, data)

    if #historic > 10 then
        table.remove(historic, 11)
    end

    vRP.execute('m_orgs_v2/updateAlerts', { organization = organization, alerts = json.encode(historic) })
    
    return historic
end



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CACHE FUNCTIONS
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Organizations:FormatConfig()
    local first = {}
    for orgName in pairs(Config.Groups) do
        for Group in pairs(Config.Groups[orgName].List) do
            self.List[Group] = orgName

            if (Config.Main.createAutomaticOrganizations) then
                if not first[orgName] then
                    first[orgName] = true
                    exports["oxmysql"]:executeSync([[INSERT IGNORE INTO mirtin_orgs_info(organization) VALUES(?)]],
                        { orgName })
                end
            end
        end
    end

    self:GenerateCache()
end

function Organizations:GenerateCache()
    local time = os.time()
    print(('^1[%s] ^0Iniciando Cache dos jogadores.'):format(GetCurrentResourceName():upper()))

    local query = vRP.query('m_orgs_v2/GetUsersGroup')
    local FormatUser = {}
    if not MIRTIN_MULTICHAR then
        for i = 1, #query do
            local ply = query[i]
            local plyData = json.decode(ply.dvalue) or {}

            FormatUser[ply.user_id] = (plyData.groups or {})
        end
    else
        for i = 1, #query do
            local ply = query[i]
            local plyData = json.decode(ply.groups) or {}

            FormatUser[ply.user_id] = plyData
        end
    end

    for user_id, groups in pairs(FormatUser) do
        for groupName in pairs(groups) do
            if self.List[groupName] then
                self:AddUserGroup(user_id, {
                    group = groupName,
                    groupType = self.List[groupName]
                })
            end
        end
    end

    print(('^2[%s] ^0Cache dos jogadores gerados com sucesso tempo %s segundo(s).'):format(
        GetCurrentResourceName():upper(), os.time() - time))
    FormatUser = {}

    self:VerifyPlayers()
    self:GenerateCachePermissions()
    self:GenerateCacheGoals()
end

function Organizations:GenerateCacheInfos()
    local query = vRP.query('m_orgs_v2/GetAllUsersInfo', {})
    for i = 1, #query do
        local ply = query[i]
        if self.Members[ply.user_id] then
            self.Members[ply.user_id].joindate = ply.joindate
            self.Members[ply.user_id].lastlogin = ply.lastlogin
            self.Members[ply.user_id].timeplayed = ply.timeplayed
        else
            -- REMOVENDO INFORMACOES CASO NÃO FOR MAIS DA ORGANIZAÇÃO
            vRP.execute('m_orgs_v2/DeleteUserInfo', { user_id = ply.user_id })
        end
    end
end

function Organizations:VerifyPlayers()
    local users = getUsers()
    for user_id, source in pairs(users) do
        local plyGroups = getUserMyGroups(user_id) or getUserGroups(user_id)
        for group in pairs(plyGroups) do
            if self.Members[user_id] then
                if self.List[self.Members[user_id].group] then
                    if not hasGroup(user_id, self.Members[user_id].group) then
                        self:RemUserGroup(user_id, self.Members[user_id].group)
                    end
                end
            end

            if self.List[group] then
                self:AddUserGroup(user_id, {
                    group = group,
                    groupType = self.List[group]
                })

                Organizations.timePlayed[user_id] = os.time()
            end
        end
    end

    self:GenerateCacheInfos()
end

function Organizations:GenerateCachePermissions()
    local query = vRP.query('m_orgs_v2/GetOrgsPermissions', {})
    for i = 1, #query do
        local v = query[i]
        if not v then goto next_org end

        local insert_permission = {}
        if Config.Groups[v.organization] then
            for Group in pairs(Config.Groups[v.organization].List) do
                if v.permissions == "{}" then
                    if not self.Permissions[v.organization] then self.Permissions[v.organization] = {} end
                    if not self.Permissions[v.organization][Group] then self.Permissions[v.organization][Group] = {} end
                    for permission in pairs(Config.defaultPermissions) do
                        local tier = Config.Groups[v.organization].List[Group].tier
                        if tier == 1 then
                            self.Permissions[v.organization][Group]['leader'] = true
                            self.Permissions[v.organization][Group][permission] = true
                        else
                            self.Permissions[v.organization][Group][permission] = false
                        end
                    end
                    local tier = Config.Groups[v.organization].List[Group].tier
                    if tier == 2 or tier == 3 then
                        self.Permissions[v.organization][Group]['withdraw'] = true
                        self.Permissions[v.organization][Group]['deposit'] = true
                    end

                    insert_permission[v.organization] = true
                else
                    self.Permissions[v.organization] = json.decode(v.permissions) or {}
                end
            end

            if insert_permission[v.organization] then
                vRP.execute('m_orgs_v2/UpdatePermissions',
                    { organization = v.organization, permissions = json.encode(self.Permissions[v.organization]) })
            end
        end

        :: next_org ::
    end

    insert_permission = {}
end

function Organizations:PayDay()
    local query = vRP.query('m_orgs_v2/GetOrgsSalary', {})
    local t = {}
    for i = 1, #query do
        t[query[i].organization] = json.decode(query[i].salary) or {}
    end

    for org, v in pairs(Config.Groups) do
        if v.Config and v.Config.Salary.active then
            self.payDayOrg[org] = {
                time = os.time() + (v.Config.Salary.time * 60),
                amount = v.Config.Salary.amount,
                salaryTime = v.Config.Salary.time
            }
        end

        local salary = t[org]

        if type(salary) == "table" and salary.expire_at and (salary.expire_at - os.time() > 0) then
            self.payDayOrg[org] = {
                salaryTime = salary.time,
                time = os.time() + (salary.salaryTime * 60),
                amount = salary.amount,
                salarySetTime = salary.salaryTime
            }
        else
            -- aqui está vazio, pode remover o else ou adicionar código
        end
    end
end





-- Inicia a thread de PayDay
function Organizations:startPayDayThread()
    local orgs = self -- mantém referência correta da classe

    CreateThread(function()
        while true do
            for org, v in pairs(orgs.payDayOrg) do
                if (v.time - os.time()) <= 0 then
                    -- garante que salarySetTime tenha valor padrão (5 min se não definido)
                    local salaryTime = v.salarySetTime or 5

                    orgs.payDayOrg[org].time = os.time() + (salaryTime * 60)

                    local query = vRP.query('m_orgs_v2/bank/getinfo', { organization = org })
                    if #query == 0 then
                        goto next_org
                    end

                    local bank_value = (query[1].bank + v.amount)
                    local generate_log = BANK:generateLog(json.decode(query[1].bank_historic), {
                        name = org,
                        type = "SALÁRIO FAC",
                        value = v.amount,
                        date = os.date('%d/%m/%Y %X'),
                    })

                    vRP.execute('m_orgs_v2/bank/updateBank', {
                        organization = org,
                        bank = bank_value,
                        historic = json.encode(generate_log)
                    })
                end

                ::next_org::
            end
            Wait(1000) -- 1 segundo de espera antes de rodar de novo
        end
    end)
end



function Organizations:addPayday(user_id, time, amount, expire)
    local user = Organizations.Members[user_id]
    if not user then
        return false
    end

    self.payDayOrg[user.groupType] = {
        salaryTime = time,
        time = os.time() + (time * 60),
        amount = amount,
        expire_at = os.time() + (expire * 60 * 60 * 24)
    }

    vRP.execute('m_orgs_v2/updateSalary', {
        organization = user.groupType,
        salary = json.encode(self.payDayOrg[user.groupType])
    })

    TriggerClientEvent('Notify', src, 'sucesso', 'Você renovou o seu <b>Salario de Facção</b>.', 5000)

    return true
end

exports('addOrganizationPayday', function(...)
    return Organizations:addPayday(...)
end)

function Organizations:GenerateCacheGoals()
    local query = vRP.query('m_orgs_v2/GetGoalsConfig', {})
    for i = 1, #query do
        local v = query[i]
        if not v then goto next_org end


        local insert_permission = {}
        if Config.Groups[v.organization] and Config.Groups[v.organization].Config.Goals then
            local data = json.decode(query[i].config_goals) or {}
            if not data.info then
                data.info = { itens = {} }
                data.info.defaultReward = Config.Groups[v.organization].Config.Goals.defaultReward
                for item, maxAmount in pairs(Config.Groups[v.organization].Config.Goals.itens) do
                    if not data.info.itens[item] then
                        data.info.itens[item] = { max = maxAmount, needed = true }
                    end
                end
            else
                for item in pairs(data.info.itens) do
                    if not Config.Groups[v.organization].Config.Goals.itens[item] then
                        data.info.itens[item] = nil
                    end
                end

                for item, values in pairs(Config.Groups[v.organization].Config.Goals.itens) do
                    if not data.info[item] then
                        data.info.itens[item] = { max = data.info.itens[item].max, needed = data.info.itens[item].needed }
                    end
                end
                data.info.defaultReward = parseInt(data.info.defaultReward)
            end
            self.goalsConfig[v.organization] = data
        end

        :: next_org ::
    end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- HANDLERS
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("m_orgs_v2:playerSpawn", function(user_id, source)
    if Organizations.Members[user_id] then
        Organizations.Members[user_id].lastlogin = os.time()
        Organizations.timePlayed[user_id] = os.time()

        exports["oxmysql"]:execute([[UPDATE mirtin_orgs_player_infos SET lastlogin = ? WHERE user_id = ?]],
            { Organizations.Members[user_id].lastlogin, user_id })
    end
end)

AddEventHandler("m_orgs_v2:playerLeave", function(user_id)
    if Organizations.timePlayed[user_id] then
        if Organizations.Members[user_id] and Organizations.Members[user_id].timeplayed then
            Organizations.Members[user_id].timeplayed = Organizations.Members[user_id].timeplayed +
                (os.time() - Organizations.timePlayed[user_id])

            exports["oxmysql"]:execute([[UPDATE mirtin_orgs_player_infos SET timeplayed = ? WHERE user_id = ?]],
                { Organizations.Members[user_id].timeplayed, user_id })
        end
    end
end)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- THREADS
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
    vRP.execute("m_orgs_v2/CreateTable1", {})
    vRP.execute("m_orgs_v2/CreateTable2", {})
    vRP.execute("m_orgs_v2/CreateTable3", {})
    vRP.execute("m_orgs_v2/CreateTable4", {})
    vRP.execute("m_orgs_v2/CreateTable5", {})
    vRP.execute("m_orgs_v2/CreateTable7", {})
    Wait(10)
    Organizations:FormatConfig()
    Organizations:PayDay()
end)
