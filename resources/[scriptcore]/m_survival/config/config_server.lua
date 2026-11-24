local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

src = {}
Tunnel.bindInterface("m_survival",src)
Proxy.addInterface("m_survival",src)

vCLIENT = Tunnel.getInterface("m_survival")
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
cfg = {}
config = {}

config.token = "" -- configure aqui seu token [ DEFINA-SEU-TOKEN-AQUI ]
cfg.weebhook = "" -- WEEBHOOK
cfg.logo = "" -- IMAGEM DO WEEBHOOK
cfg.color = 6356736 -- COR DO WEEBHOOK

src.limparConta = function() -- FUNÇÃO QUE VEM DO CONFIG.CLIENT PARA EXECUTAR FUNÇÕES DIRETAS
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        if not Player(source).state.NovatMode then
            vRP.clearAccount(user_id)
        end
    end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SISTEMA DE DISCONNECT
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("playerDropped", function(reason)
    local source = source
    local coords = GetEntityCoords(GetPlayerPed(source))
    local user_id = vRP.getUserId(source)
    if user_id then
        TriggerClientEvent("anticl", -1, user_id, coords, reason )
        vRP.sendLog('', 'ID '..user_id..' deslogou em '..json.encode(coords))
    end
end)