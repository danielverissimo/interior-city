local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

src = {}
Tunnel.bindInterface(GetCurrentResourceName(), src)
vCLIENT = Tunnel.getInterface(GetCurrentResourceName())

mg = {}

mg.getUserId = function(source)
    return vRP.getUserId(source)
end

mg.getUserGroupByType = function(user_id,prefix)
    return vRP.getUserGroupByType(user_id, prefix)
end

mg.prepare = function(prefix,prepare)
    return vRP.prepare(prefix,prepare)
end

mg.query = function(prefix,query)
    return vRP.query(prefix,query)
end

mg.execute = function(prefix,execute)
    vRP.execute(prefix,execute)
end

mg.addUserGroup = function(user_id,group)
    return vRP.addUserGroup(parseInt(user_id),group)
end

mg.removeUserGroup = function(user_id,group)
    return vRP.removeUserGroup(parseInt(user_id),group)
end

mg.payment = function(user_id,payment)
    return vRP.giveBankMoney(user_id,payment)
end