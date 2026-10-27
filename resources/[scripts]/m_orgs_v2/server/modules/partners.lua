local createPartnersTableQuery =
[[CREATE TABLE IF NOT EXISTS mirtin_partners ( id INT AUTO_INCREMENT PRIMARY KEY,cds TEXT,name VARCHAR(100),note INT DEFAULT 0,description TEXT,keyword TEXT,icon TEXT,groups TEXT,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP);]]
vRP.prepare("createPartnersTable", createPartnersTableQuery)
vRP.prepare("insertPartner",
    [[INSERT INTO mirtin_partners (cds, name, note, description, keyword, icon, groups) VALUES (@cds, @name, @note, @description, @keyword, @icon, @groups)]])
vRP.prepare("getPartners", [[SELECT * FROM mirtin_partners]])
vRP.prepare("getLastInsertedPartnerId", [[SELECT LAST_INSERT_ID() AS id]])
vRP.prepare("mirtin/delete_partner", "DELETE FROM mirtin_partners WHERE id = @id")
vRP.prepare("mirtin/get_partners", "SELECT * FROM mirtin_partners WHERE groups = @groups")
vRP.execute("createPartnersTable")

RegisterTunnel.GetPartners = function()
    local source = source
    local user_id = getUserId(source)
    if not user_id then return end

    local identity = getUserIdentity(user_id)
    if not identity then return end

    local user = Organizations.Members[user_id]
    if not user then return end

    local query = vRP.query("mirtin/get_partners", { groups = user.groupType })
    if #query > 0 then
        return query
    end
    return {}
end

RegisterTunnel.deletePartner = function(data)
    local source = source
    local user_id = getUserId(source)
    if not user_id then return end

    local identity = getUserIdentity(user_id)
    if not identity then return end

    local user = Organizations.Members[user_id]
    if not user then return end

    vRP.execute("mirtin/delete_partner", { id = data.id })
    Wait(1000)
    local query = vRP.query("mirtin/get_partners", { groups = user.groupType })
    if #query > 0 then
        return query
    end
    return {}
end

RegisterTunnel.addPartner = function(data)
    local source = source
    local user_id = getUserId(source)
    if not user_id then return end

    local identity = getUserIdentity(user_id)
    if not identity then return end

    local user = Organizations.Members[user_id]
    if not user then return end
    local hasPermission = Organizations.Permissions[user.groupType] and Organizations.Permissions[user.groupType][user.group].leader or false
    if not hasPermission then
        return
    end
    vRP.execute("insertPartner", { cds = data.cds, name = data.name, note = data.note, description = data.description, icon = data.icon, keyword = data.keyword, groups = user.groupType })
    Wait(1000)
    local query = vRP.query("mirtin/get_partners", { groups = user.groupType })
    if #query > 0 then
        return query
    end
    return {data}
end