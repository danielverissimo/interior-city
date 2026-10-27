-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ENTRA AI BB: https://discord.gg/DQswMRDMVV  Toca do Mago FiveM
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

src = {}
Tunnel.bindInterface(GetCurrentResourceName(), src)
vCLIENT = Tunnel.getInterface(GetCurrentResourceName())

-----------------------------------------------------------------------------------------------------------------------------------------
-- /e
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand('e', function(source,args,rawCommand)
	TriggerClientEvent("m_anim:emotes",source,args[1])
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- /e2
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand('e2', function(source,args,rawCommand)
	local user_id = vRP.getUserId(source)
	if vRP.hasPermission(user_id,"administrador.permissao") then
		local nplayer = vRPclient.getNearestPlayer(source,2)
		if nplayer then
			TriggerClientEvent("m_anim:emotes",nplayer,args[1])
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- /e3
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand('e3', function(source,args,rawCommand)
    local source = source
    local user_id = vRP.getUserId(source)
    if vRP.hasPermission(user_id,"administrador.permissao") then
        if args[2] then
            local nplayer = vRP.getUserSource(parseInt(args[2]))
            if nplayer then
                TriggerClientEvent("m_anim:emotes",nplayer,args[1])
            end
        end
    end
end)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ENTRA AI BB: https://discord.gg/DQswMRDMVV  Toca do Mago FiveM
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
