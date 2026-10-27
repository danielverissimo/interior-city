local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

sun = {}
Tunnel.bindInterface(GetCurrentResourceName(), sun)
vCLIENT = Tunnel.getInterface(GetCurrentResourceName())

-- Mesmo cadastro e status utilizados pelo m_garage (1 = detido).
vRP.prepare("m_desmanche/getVehicle", "SELECT status FROM vrp_user_veiculos WHERE user_id = @user_id AND veiculo = @veiculo")
vRP.prepare("m_desmanche/setDetido", "UPDATE vrp_user_veiculos SET status = 1 WHERE user_id = @user_id AND veiculo = @veiculo AND status = @previousStatus")
vRP.prepare("m_desmanche/restoreStatus", "UPDATE vrp_user_veiculos SET status = @previousStatus WHERE user_id = @user_id AND veiculo = @veiculo AND status = 1")

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
local finalizando = {}

function sun.GerarPagamento(placa, nomeFeio, nomeBonito, pagamento, tipo)
    local src = source
    local user_id = vRP.getUserId(src)
    if not user_id then return false end
    local function negar(message)
        TriggerClientEvent('Notify', src, 'negado', message, 10000)
        return false
    end
    local config = cfg.table[tipo]
    if not config or tipo == 'none' or not vRP.hasPermission(user_id, config.permissao) then
        return negar('Sem permissão para finalizar este desmanche.')
    end
    if type(nomeFeio) ~= 'string' or nomeFeio == '' or tonumber(nomeFeio) then
        return negar('Modelo do veículo inválido. Reinicie o desmanche.')
    end
    placa = tostring(placa or ''):gsub(' ', '')
    local owner = vRP.getUserByRegistration(placa)
    if not owner then return negar('Não foi encontrado o proprietário desta placa.') end
    if not cfg.desmanchar_proprio_veiculo and owner == user_id then
        return negar('Você não pode desmanchar seu próprio veículo.')
    end

    -- Os exports da garagem recebem o spawn, não o hash numérico.
    local vehicleType = sun.getVehicleType(nomeFeio)
    if not cfg.desmanchar_veiculo_trabalho and (vehicleType == 'work' or vehicleType == 'service') then
        return negar('Este veículo de trabalho não pode ser desmanchado.')
    end
    local rate = tonumber((vehicleType == 'vip' or vehicleType == 'exclusive') and cfg.porcentagem_veiculovip or cfg.porcentagem_veiculocomum)
    local price = tonumber(sun.getVehiclePrice(nomeFeio))
    local amount = price and rate and price * rate
    if not amount or amount ~= amount or amount == math.huge or amount <= 0 then
        return negar('O preço ou percentual deste veículo é inválido.')
    end
    pagamento = math.floor(amount)
    if pagamento < 1 then return negar('O pagamento deve ser maior que zero.') end
    nomeBonito = tostring(sun.getVehicleName(nomeFeio) or nomeFeio)

    local key = tostring(owner)..':'..nomeFeio
    if finalizando[key] then return negar('Este veículo já está sendo finalizado.') end
    finalizando[key] = true
    local params = {user_id=owner, veiculo=nomeFeio}
    local ok, result = pcall(function()
        local rows = vRP.query('m_desmanche/getVehicle', params)
        local row = rows and rows[1]
        if not row then return negar('Veículo não encontrado no cadastro da garagem.') end
        params.previousStatus = tonumber(row.status) or 0
        if params.previousStatus == 1 then return negar('Este veículo já está detido.') end

        -- Aguarda o banco: vRP.execute desta base não retorna a conclusão do UPDATE.
        local update = vRP.query('m_desmanche/setDetido', params)
        if not update or tonumber(update.affectedRows) ~= 1 then
            return negar('Não foi possível marcar o veículo como detido. Tente novamente.')
        end
        if not vRP.giveInventoryItem(user_id, 'dirty_money', pagamento, true) then
            vRP.query('m_desmanche/restoreStatus', params)
            return negar('Não foi possível entregar o dinheiro sujo. Tente novamente.')
        end
        return true
    end)
    finalizando[key] = nil
    if not ok then
        print('[m_desmanche] Falha ao finalizar: '..tostring(result))
        return negar('Falha ao finalizar o desmanche. Consulte o console do servidor.')
    end
    if not result then return false end

    local nsource = vRP.getUserSource(owner)
    if nsource then
        TriggerClientEvent('Notify', nsource, 'aviso', 'Seu veículo <b>'..nomeBonito..' ('..nomeFeio..')</b> foi desmanchado e está detido na garagem.', 10000)
    end
    TriggerClientEvent('vrp_sound:source', src, 'coins', 0.3)
    TriggerClientEvent('Notify', src, 'sucesso', 'Você recebeu <b>R$'..vRP.format(pagamento)..'</b> em dinheiro sujo pelo desmanche de <b>'..nomeBonito..'</b>.', 10000)
    local identity = vRP.getUserIdentity(user_id) or {}
    SendWebhookMessage(config.log_webhook, '```prolog\n[DESMANCHE]: '..tostring(tipo)..'\n[PASSAPORTE]: '..user_id..'\n[NOME]: '..tostring(identity.nome or '')..' '..tostring(identity.sobrenome or '')..'\n[VEÍCULO]: '..nomeBonito..' ('..nomeFeio..')\n[PLACA]: '..placa..'\n[DIRTY_MONEY]: '..pagamento..os.date('\n[Data]: %d/%m/%y [Hora]: %H:%M:%S')..'\n```')
    return true
end

function sun.checkdono()
    local source = source
    local user_id = vRP.getUserId(source)
    local identity = user_id and vRP.getUserIdentity(user_id)
    local rg = identity and identity.registro

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