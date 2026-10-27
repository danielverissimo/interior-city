local Tunnel=module("vrp","lib/Tunnel")
local Proxy=module("vrp","lib/Proxy")
vRP=Proxy.getInterface("vRP")

vRPG={}
Tunnel.bindInterface("PolySafeZone",vRPG)
Proxy.addInterface("PolySafeZone",vRPG)

-- Mantido apenas por compatibilidade com scripts externos antigos.
function vRPG.Identidade()
    return ""
end
