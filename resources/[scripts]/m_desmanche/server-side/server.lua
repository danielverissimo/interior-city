local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

sun = {}
Tunnel.bindInterface(GetCurrentResourceName(), sun)
vCLIENT = Tunnel.getInterface(GetCurrentResourceName())

vRP._prepare("mb_setDetido","UPDATE vrp_user_vehicles SET detido = @detido, time = @time WHERE user_id = @user_id AND vehicle = @vehicle")

func = {}

function sun.getVehiclePrice(vehicle)
    local price = exports['m_garage']:getVehiclePrice(vehicle)
    return price
end

function sun.getVehicleModel(vehicle)
     local model = exports['m_garage']:getVehicleModel(vehicle)
     return model
end

function sun.getVehicleName(vehicle)
     local name = exports['m_garage']:getVehicleName(vehicle)
    return name
end

function sun.getVehicleType(vehicle)
     local tipo = exports['m_garage']:getVehicleType(vehicle)
     return tipo
end

-- FUNÇÃO VERIFICAR PERMISSÃO DO DESMANCHE
function sun.CheckPerm(perm)
    local source = source
    local user_id = vRP.getUserId(source)
        if vRP.hasPermission(user_id, perm) then
            return true
        end
        return false
end

-- FUNÇÃO PRA VERIFICAR SE POSSUI O ITEM
function sun.CheckItem(pditem,item,qtd)
    local source = source
    local user_id = vRP.getUserId(source)
    if pditem then
        if vRP.tryGetInventoryItem(user_id,item,qtd) then
            return true
        else
            TriggerClientEvent('Notify',source, 'negado', 'Você necessita de x'..qtd..' '..item..' para desmanchar o veiculo.')
        end
        return false
    end
    return true
end

-- FUNÇÃO PARA GERAR O PAGAMENTO E OS ITENS
function sun.GerarPagamento(placa, nomeFeio, nomeBonito, pagamento,tipo)
    local source = source
    local user_id = vRP.getUserId(source)
    local identity = vRP.getUserIdentity(user_id)
            local puser_id = vRP.getUserByRegistration(placa)
            if puser_id then
                vRP.giveInventoryItem(user_id,'dinheirosujo',pagamento) 
                vRP.execute("mb_setDetido",{ user_id = puser_id, vehicle = nomeFeio, detido = 1, time = parseInt(os.time()) })
                local nsource = vRP.getUserSource(puser_id)
                if nsource then
                    TriggerClientEvent('Notify', nsource, 'aviso','Você foi multado referente ao seguro do veículo <b>' .. nomeBonito .. ' (' .. nomeFeio .. ')</b>.', 10000)
                end
            end
            TriggerClientEvent("vrp_sound:source",source,'coins',0.3)
            TriggerClientEvent('Notify', source, 'sucesso','Você recebeu <b>R$'..vRP.format(pagamento)..'</b> pelo desmanche de um <b>'..nomeBonito..' ('.. nomeFeio..' - PLACA [' .. placa .. '])</b>.', 10000 )
            SendWebhookMessage(cfg.table[tipo]['log_webhook'],"```prolog\n[DESMANCHE]: "..tipo.."\n[PASSAPORTE]: "..user_id.." \n[NOME]: "..identity.nome.." "..identity.sobrenome.." \n[DESMANCHOU]: "..nomeBonito.."  \n[PLACA]: ".. placa .." \n[E RECEBEU]: ".. vRP.format(pagamento) .." "..os.date("\n[Data]: %d/%m/%y \n[Hora]: %H:%M:%S").." \r```")
end

function sun.checkdono()
    local source = source
    local user_id = vRP.getUserId(source)
    local identity = vRP.getUserIdentity(user_id)
    local rg = identity.registration

    if user_id then
        if not cfg.desmanchar_proprio_veiculo then
         return rg
        else
            return false
        end
    end

end



RegisterServerEvent("nation:deleteVehicleSync")
AddEventHandler("nation:deleteVehicleSync",function(nveh)
end)

function sun.chkdm()

    local source = source
    local user_id = vRP.getUserId(source)
    local nplayer = vRPclient.getNearestPlayer(source, 30)
    
    if nplayer then
        local resposta_dsmnc = vCLIENT.checkdesmancheut(nplayer)
        if resposta_dsmnc then
            return true
        else
            return false
        end
    else
        return true
    end

end

function SendWebhookMessage(webhook,message)
	if webhook ~= nil and webhook ~= "" then
		PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({content = message}), { ['Content-Type'] = 'application/json' })
	end
end