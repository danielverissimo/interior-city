-- print('[DEBUG]: Server Caminhoneiro Init Sucess')

-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIAVEIS
-----------------------------------------------------------------------------------------------------------------------------------------

local caminhao = 1

-----------------------------------------------------------------------------------------------------------------------------------------
-- GETTRUCKPOINT
-----------------------------------------------------------------------------------------------------------------------------------------
function src.getTruckpoint(point)
	if point == "caminhao" then
		return parseInt(caminhao)
	end
end

-- local reward = {configcaminhao.pagamento[1],configcaminhao.pagamento[2]}
-- local rndResult = math.random(1,1)

-- RegisterServerEvent('caminhao:rewardbruxo')
-- AddEventHandler('caminhao:rewardbruxo', function(farm)
-- 	local source = source
-- 	local user_id = vRP.getUserId(source)
-- 	local player = vRP.getUserSource(user_id)
-- 	local x,y = table.unpack(reward)
-- 	local rewardValue = math.random(x, y)
-- 	vRP.giveBankMoney(user_id,rewardValue)
-- 	TriggerClientEvent("Notify",source,"sucess","Você recebeu R$"..rewardValue.."")
-- end)

function src.request()
	local source = source
	local user_id = vRP.getUserId(source)
	if vRP.request(source,"Deseja iniciar a rota de caminhoneiro?",30) then
		return true
	else
		TriggerClientEvent('Notify',source,'negado','Volte quando tiver mudado de ideia!',5)
		return false
	end
end