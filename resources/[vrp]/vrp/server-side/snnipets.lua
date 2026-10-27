local pressetHooks = {
    ["ENTRADA"] = {""},
    ["SAIDA"] = {""},
    ["DROPAR"] = {""},
    ["ENVIAR"] = {""},
    ["EQUIPAR"] = {""},
    ["GARMAS"] = {""},
    ["SAQUEAR"] = {""},
    ["BAUCARRO"] = {""},
    ["BAUCASAS"] = {""},
    ["CRASHS"] = {""},
    ["MORTE"] = {""},
    ["ROUBOGERAIS"] = {""},
    ["ROUBOAMMU"] = {""},
    ["ROUBOCAIXA"] = {""},
    ["ROUBOREGISTRADORA"] = {""},
    ["BANCODEPOSITAR"] = {""},
    ["BANCOSACAR"] = {""},
    ["BANCOENVIAR"] = {""},
    ["COMPRARVEICULO"] = {""},
    ["WL"] = {""},
    ["IDS"] = {""},
    ["TPTO"] = {""},
    ["TPTOME"] = {""},
    ["GOD"] = {""},
    ["GOID"] = {""},
    ["KICK"] = {""},
    ["CAPUZ"] = {""},
    ["BAN"] = {""},
    ["PRENDERADM"] = {""},
    ["AADM"] = {""},
    ["KILL"] = {""},
    ["ITEM"] = {""},
    ["TPWAY"] = {""},
    ["ACEITARCHAMADOADMIN"] = {""},
    ["GROUPADD"] = {""},
    ["GROUPREM"] = {""},
    ["SPAWNCAR"] = {""},
    ["MONEY"] = {""},
    ["BATERPONTOBENNYS"] = {""},
    ["BATERPONTOPOLICIA"] = {""},
    ["BATERPONTOHOSPITAL"] = {""},
    ["BATERPONTOADMIN"] = {""},
    ["PRENDER"] = {""},
    ["DESMANCHE"] = {""},
    ["COPYPRESET"] = {""},
    ["SETPRESET"] = {""},
    ["REVISTARADM"] = {""},
    ["VAULTADM"] = {""},
    ["HOUSEADMCHEST"] = {""},
    ["FUEL"] = {""},
    ["LOCKPICK"] = {""},
    ["ADDCARRO"] = {""},
    ["RENOMEAR"] = {""},
    ["CRAFT"] = {""},
    ["KITMALOKERO"] = {""},
    ["ITEMP"] = {""},
    ["GETITEM"] = {""},
    ["REMCARRO"] = {""},
    ["REC"] = {""},
}
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DISCORD WEEBHOOK
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function vRP.sendLog(weebhook, mensagge)
    if weebhook and mensagge then
        if pressetHooks[weebhook] ~= nil then
            SendWebhookMessage(pressetHooks[weebhook][1],mensagge)
        else
            SendWebhookMessage(weebhook,mensagge)
        end
    end
end

-- local api = "http://api.c1-tiny-x86-sao-paulo-1.dacsistemas.com.br:15672/api/exchanges/%2F/fivem.lotusgroup.capitalrj/publish"
-- function exports["vrp_admin"]:generateLog(payload)
--     payload.time = os.time()

--     local content = {
-- 		properties = {
-- 			delivery_mode = 2,
-- 			content_type = "application/json"
-- 		},
-- 		routing_key = "",
--         payload = json.encode(payload),
-- 		payload_encoding = "string"
-- 	}

--     PerformHttpRequest(api, function(err, text, headers)
--     end, 'POST', json.encode(content), { ['Authorization'] = 'Basic bG90dXNncm91cDoxMjM0' })
-- end

function SendWebhookMessage(webhook,message)
    if webhook ~= "none" then
        PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({content = message}), { ['Content-Type'] = 'application/json' })
    end
end

function vRP.log(file,info)
    file = io.open(file, "a")
    
    if file then
        file:write("» "..info.."\r")

        file:close()
    end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- DESLOGAR DENTRO DA PROPRIEDADE
-----------------------------------------------------------------------------------------------------------------------------------------
function vRP.atualizarPosicao(user_id,x,y,z)
    local data = vRP.getUserDataTable(user_id)
    if user_id then
        if data then
            data.position = { x = x, y = y, z = z }
        end
    end
end

function vRP.limparArmas(user_id)
    local data = vRP.getUserDataTable(user_id)
    if user_id and data then
        local count = 0
        local rows = {}
        for weapon,weaponData in pairs(type(data.weapons) == "table" and data.weapons or {}) do
            count = count + 1
            if #rows < 20 then
                rows[#rows + 1] = ("%s (%d munições)"):format(tostring(weapon), tonumber(weaponData and weaponData.ammo) or 0)
            end
        end
        data.weapons = {}
        if count > 0 and type(vRP.mageAuditLog) == "function" then
            local origin = type(vRP.mageAuditOrigin) == "function" and vRP.mageAuditOrigin() or (GetInvokingResource() or GetCurrentResourceName() or "vrp")
            vRP.mageAuditLog("vrp_weapons_data_cleared", {
                actorId = tonumber(user_id),
                actorLabel = "JOGADOR AFETADO",
                details = ("**Resource:** %s\n**Função:** vRP.limparArmas\n**Armas removidas:** %d\n**Conteúdo:** %s"):format(
                    origin, count, #rows > 0 and table.concat(rows, ", ") or "Nenhuma"
                )
            })
        end
        return true
    end
    return false
end