local blacklistGroups = {
    ["paulinho"] = true,
    ["TOP1"] = true,
    ["developer"] = true,
    ["developeroff"] = true,
    ["admin"] = true, 
    ["adminoff"] = true,
    ["moderador"] = true,
    ["moderadoroff"] = true,
    ["suporte"] = true,
    ["suporteoff"] = true,
    ["LiderCUPULA"] = true,
    ["respilegal"] = true,
    ["respilegaloff"] = true,
    ["resppolicia"] = true,
    ["resppoliciaoff"] = true,
    ["Inicial"] = true,
    ["Bronze"] = true,
    ["Prata"] = true,
    ["Black"] = true,
    ["Diamante"] = true,
    ["Brooklyn"] = true,
    ["Supremo"] = true,
    ["Supremobrooklyn"] = true,
    ["VipPolicia"] = true,
    ["VipCrianca"] = true,
    ["VipSetembro"] = true,
    ["Pascoa"] = true,
    ["Plastica"] = true,
    ["SalarioGerente"] = true,
    ["SalarioPatrao"] = true,
    ["SalarioVelhodalancha"] = true,
    ["SalarioCelebridade"] = true,
    ["SalarioMilionario"] = true,
    ["SalarioDosDeuses"] = true
}

local webhookGroup = ""

function src.checkPermission()
    local user_id = vRP.getUserId(source)
    return user_id and (vRP.hasPermission(user_id, "moderador.permissao") or vRP.hasPermission(user_id, "admin.permissao") or vRP.hasPermission(user_id, "developer.permissao")) or false
end

local function getBlacklistForJS()
    local result = {}
    for group, _ in pairs(blacklistGroups) do
        table.insert(result, group)
    end
    return result
end

function src.getGroups()
    -- Consulta sempre os grupos atuais carregados pela vRP.
    local groups = vRP.getGroups() or {}

    local groupNames = {}
    for name, _ in pairs(groups) do
        groupNames[name] = true
    end

    return groupNames, getBlacklistForJS()
end

function src.getUserDetails(userId)
    local user_id = tonumber(userId)
    
    if not user_id then return nil end
    
    local userGroups = {}
    local isOnline = false
    local userName = "Indivíduo Indigente"
    
    local nsource = vRP.getUserSource(user_id)
    if nsource then
        isOnline = true
        
        local identity = vRP.getUserIdentity(user_id)
        if identity then
            userName = identity.nome .. " " .. identity.sobrenome
        end
        
        local ugroups = vRP.getUserGroups(user_id)
        for group, _ in pairs(ugroups) do
            table.insert(userGroups, group)
        end
    else
        local rows = vRP.getUData(user_id, "vRP:datatable")
        if #rows > 0 then
            local data = json.decode(rows) or {}
            if data and data.groups then
                for group, _ in pairs(data.groups) do
                    table.insert(userGroups, group)
                end
            end
            
            local identity = vRP.getUserIdentity(user_id)
            if identity then
                userName = identity.nome .. " " .. identity.sobrenome
            end
        else
            return nil
        end
    end
    
    local userDetails = {
        id = user_id,
        name = userName,
        groups = userGroups,
        online = isOnline
    }

    return userDetails
end

function src.addGroup(userId, group, isOnline)
    local source = source
    local admin_id = vRP.getUserId(source)
    local target_id = tonumber(userId)
    
    if not vRP.hasPermission(admin_id, "admin.permissao") then
        TriggerClientEvent("Notify", source, "negado", "Você não tem permissão para adicionar grupos.", 5000)
        return
    end

    if blacklistGroups[group] and not vRP.hasPermission(admin_id, 'admin.permissao') then
        TriggerClientEvent("Notify", source, "negado", "Cargo em Blacklist.", 5000)
        return
    end
    
    if (group == 'developerCnxOff' or group == 'developerCnx') and not vRP.hasPermission(admin_id, "admin.permissao") then
        TriggerClientEvent("Notify", source, "negado", "Cargo em Blacklist.", 5000)
        return
    end
    
    local groups = vRP.getGroups() or {}

    if not groups[group] then 
        TriggerClientEvent("Notify", source, "negado", "Grupo não encontrado.", 5000)
        return
    end
    
    if isOnline then
        local nsource = vRP.getUserSource(target_id)
        if nsource then
            vRP.addUserGroup(target_id, group)
            TriggerClientEvent("Notify", source, "sucesso", "Você adicionou o (ID: " .. target_id .. ") no grupo: " .. group, 5000)
            -- vRP.sendLog(webhookGroup, "```prolog\n[GROUP] \n\n[STAFF]: " .. admin_id .. "  \n[SETOU]: " .. target_id .. "  \n[GRUPO]: " .. group .. " " .. os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S") .. " \r```")
        end
    else
        local rows = vRP.getUData(target_id, "vRP:datatable")
        if #rows > 0 then
            local data = json.decode(rows) or {}
            if data and data.groups then
                data.groups[group] = true
            end
            
            vRP.setUData(target_id, "vRP:datatable", json.encode(data))
            TriggerClientEvent("Notify", source, "sucesso", "** OFFLINE ** Você adicionou o (ID: " .. target_id .. ") no grupo: " .. group, 5000)
            -- vRP.sendLog(webhookGroup, "```prolog\n[GROUP] \n\n[STAFF]: " .. admin_id .. "  \n[SETOU]: " .. target_id .. "  \n[GRUPO]: " .. group .. " " .. os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S") .. " \r```")
        end
    end
    
    vCLIENT.setUserDetails(source,target_id)
end

function src.removeGroup(userId, group, isOnline)
    local source = source
    local admin_id = vRP.getUserId(source)
    local target_id = tonumber(userId)
    
    if not vRP.hasPermission(admin_id, "admin.permissao") then
        TriggerClientEvent("Notify", source, "negado", "Você não tem permissão para remover grupos.", 5000)
        return
    end

    if blacklistGroups[group] and not vRP.hasPermission(admin_id, 'admin.permissao') then
        TriggerClientEvent("Notify", source, "negado", "Cargo em Blacklist.", 5000)
        return
    end
    
    local groups = vRP.getGroups() or {}

    if not groups[group] then 
        TriggerClientEvent("Notify", source, "negado", "Grupo não encontrado.", 5000)
        return
    end
    
    if isOnline then
        local nsource = vRP.getUserSource(target_id)
        if nsource then
            vRP.removeUserGroup(target_id, group)
            TriggerClientEvent("Notify", source, "sucesso", "Você removeu o (ID: " .. target_id .. ") do grupo: " .. group, 5000)
            -- vRP.sendLog(webhookGroup, "```prolog\n[UNGROUP] \n\n[STAFF]: " .. admin_id .. "  \n[REMOVEU]: " .. target_id .. "  \n[GRUPO]: " .. group .. " " .. os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S") .. " \r```")
        end
    else
        local rows = vRP.getUData(target_id, "vRP:datatable")
        if #rows > 0 then
            local data = json.decode(rows) or {}
            if data and data.groups then
                data.groups[group] = nil
            end
            
            vRP.setUData(target_id, "vRP:datatable", json.encode(data))
            TriggerClientEvent("Notify", source, "sucesso", "** OFFLINE ** Você removeu o (ID: " .. target_id .. ") do grupo: " .. group, 5000)
            -- vRP.sendLog(webhookGroup, "```prolog\n[UNGROUP] \n\n[STAFF]: " .. admin_id .. "  \n[REMOVEU]: " .. target_id .. "  \n[GRUPO]: " .. group .. " " .. os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S") .. " \r```")
        end
    end
    
    vCLIENT.setUserDetails(source, target_id)
end