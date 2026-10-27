-- print('[DEBUG]: Server Entregador Init Sucess')
-- Compatibilidade com os eventos legados do antigo vrp_ifood.
-- O pagamento nunca mais confia em um valor informado pelo client.

local legacyDeliveryCooldown = {}

RegisterServerEvent('vrp_ifood:permissao')
AddEventHandler('vrp_ifood:permissao', function()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return end

    if not MageEmpregosHasJob(user_id, "Entregador") then
        MageEmpregosLogInvalid(source, "solicitar permissão do entregador", "Evento legado chamado sem estar empregado como Entregador.")
        return
    end

    TriggerClientEvent('vrp_ifood:permissao', source)
end)

RegisterServerEvent('vrp_ifood:receber')
AddEventHandler('vrp_ifood:receber', function(clientPayment)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return end

    if not MageEmpregosHasJob(user_id, "Entregador") then
        MageEmpregosLogInvalid(source, "receber pagamento legado do entregador", ("Valor enviado pelo client: %s"):format(tostring(clientPayment or "-")))
        return
    end

    local now = os.time()
    if now - (legacyDeliveryCooldown[user_id] or 0) < 2 then
        MageEmpregosLog("jobs_security_payment_spam", {
            actorId = user_id,
            details = ("Emprego: Entregador\nEvento legado vrp_ifood:receber repetido em menos de 2 segundos.\nValor enviado pelo client e ignorado: %s"):format(tostring(clientPayment or "-"))
        })
        return
    end
    legacyDeliveryCooldown[user_id] = now

    local query = mg.query('get_empdata', { user_id = user_id })
    if not query[1] or not query[1].dvalue then return end
    local jobs = json.decode(query[1].dvalue) or {}
    local progress = jobs["Entregador"] or {}
    local level = tonumber(progress.nivel) or 1
    local range = cfg.list["Entregador"] and cfg.list["Entregador"].payment_for_level and cfg.list["Entregador"].payment_for_level[level] or nil
    if not range or not range[1] or not range[2] then
        MageEmpregosLog("jobs_security_invalid_payment", {
            actorId = user_id,
            details = ("Emprego: Entregador\nNível: %d\nEvento legado tentou pagar, mas não existe faixa de pagamento configurada."):format(level)
        })
        return
    end

    local minPayment = tonumber(range[1]) or 0
    local maxPayment = tonumber(range[2]) or 0
    if maxPayment < minPayment then minPayment, maxPayment = maxPayment, minPayment end
    local payment = math.random(minPayment, maxPayment)

    mg.payment(user_id, payment)
    TriggerClientEvent("vrp_sound:source", source, 'dinheiro', 0.3)
    TriggerClientEvent('Notify', source, 'sucesso', '[Entregador] Você recebeu seu pagamento de R$ '..payment..'', 10)

    MageEmpregosLog("job_entregador_payment", {
        actorId = user_id,
        details = ("Emprego: Entregador\nNível: %d\nPagamento recebido: %s\nOrigem: evento legado compatível vrp_ifood:receber\nValor enviado pelo client (IGNORADO): %s"):format(
            level, MageEmpregosMoney(payment), tostring(clientPayment or "-")
        )
    })
end)
