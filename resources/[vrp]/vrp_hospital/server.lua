local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")
emP = {}
Tunnel.bindInterface("emp_hospital",emP)
vDIAGNOSTIC = Tunnel.getInterface("vrp_diagnostic")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIAVEIS
-----------------------------------------------------------------------------------------------------------------------------------------
function emP.checkServices()
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		local paramedicos = vRP.getUsersByPermission("perm.unizk")
		print(paramedicos)
		if parseInt(#paramedicos) == 0 then
			return true
		end
	end
end

RegisterServerEvent("target:deitarpaciente")
AddEventHandler("target:deitarpaciente",function()

	local source = source
	local user_id = vRP.getUserId(source)
	local nplayer = vRPclient.getNearestPlayer(source, 3)
	local nsource = vRP.getUserSource(nplayer)

	TriggerClientEvent("event:deitarpaciente", nplayer)
	
end)
