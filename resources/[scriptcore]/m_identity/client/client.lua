identity = {}
local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
vRP = Proxy.getInterface("vRP")
Tunnel.bindInterface(GetCurrentResourceName(), identity)
vSERVER = Tunnel.getInterface(GetCurrentResourceName())

RegisterKeyMapping("rg", "Identidade", "keyboard", "F11")

local function refreshIdentity()
	if not identity.hidden then return end

	local infos = vSERVER.getInfos()
	if infos then
		SendNUIMessage(infos)
	end
end

RegisterNetEvent('lotus_identity:hide', function()
	identity.hidden = false
	SendNUIMessage({ action = "close" })
end)

-- O Painel ADM v2.63 publica este evento assim que Nome, Sobrenome, Idade,
-- Telefone ou RG são alterados. Se a identidade estiver aberta, ela é
-- redesenhada imediatamente, sem precisar fechar/abrir e sem relogar.
RegisterNetEvent("m_paineladm_v2:identityLiveUpdated")
AddEventHandler("m_paineladm_v2:identityLiveUpdated", function(payload)
	refreshIdentity()
end)

RegisterCommand("rg", function()
	if GetEntityHealth(PlayerPedId()) > 101 then
		if not identity.hidden then
			identity.hidden = true
			refreshIdentity()
			TriggerEvent('lotus-hud:toggle', false)
		else
			identity.hidden = false
			SendNUIMessage({ action = "close" })
			TriggerEvent('lotus-hud:toggle', true)
		end
	end
end)
