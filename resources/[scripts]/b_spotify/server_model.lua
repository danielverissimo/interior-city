-- Comando para alterar o modelo JBL em tempo real
RegisterCommand('sommodel', function(source, args, raw)
    local src = source
    local newModel = args[1]

    if not newModel or newModel == '' then
        if src ~= 0 then
            TriggerClientEvent('chat:addMessage', src, { args = { '⚠️ Uso', '/sommodel <nome_do_modelo>' } })
        else
            print('[foxzinlafy] Uso: /sommodel <nome_do_modelo>')
        end
        return
    end

    -- Envia para o cliente atualizar o modelo dinamicamente
    TriggerClientEvent('foxzinlafy:setPropModel', src, newModel)

    if src ~= 0 then
        TriggerClientEvent('chat:addMessage', src, { args = { '✅ Modelo JBL atualizado para', newModel } })
    else
        print('[foxzinlafy] Modelo JBL atualizado para: ' .. tostring(newModel))
    end
end, false)