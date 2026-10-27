
--[[ Caso a mensagem tenha tipo não precisa enviar prefixColor ]]
SendNUIMessage({ action = 'create:message', data = {  messsage = 'Teste testado.', prefix = 'Anuncio', type = 'vip', title = 'COMPRA NA LOJA', time = '22:00' } })

SendNUIMessage({ action = 'create:message', data = {  messsage = 'Teste testado.', prefix = 'Anuncio', prefixColor = '#1c1c1c', title = 'COMPRA NA LOJA', time = '22:00' } })

--[[ Limpar as mensagens do chat ]]
SendNUIMessage({ action = 'clear:messages' })

--[[ Se data for true, vai mostar o campo de digitação e se for false vai ocultar o menu de digitação ]]
SendNUIMessage({ action = 'chat:show', data = true/false })

RegisterNUICallback('new:command', function(data, cb)
  --[[ recebe data.message ]]
  cb('new:command')
end)

RegisterNUICallback('closeChat', function(data, cb)
  cb('closeChat')
end)