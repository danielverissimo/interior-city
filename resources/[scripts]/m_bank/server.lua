local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
local Tools = module("vrp","lib/Tools")
local cFG = module("m_bank", "config")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

eG = {}
Tunnel.bindInterface("m_bank",eG)
--------------------------------------------------------------------------------------------------
-- WEBHOOK ---------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
function SendWebhookMessage(webhook,message)
	if webhook ~= nil and webhook ~= "" then
		PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({content = message}), { ['Content-Type'] = 'application/json' })
	end
end
--------------------------------------------------------------------------------------------------
-- SQL -------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
vRP.prepare("EG/selectPix","SELECT COUNT(chavePix) FROM vrp_user_identities WHERE chavePix = @chavePix")
vRP.prepare("EG/criarPix","UPDATE vrp_user_identities SET chavePix = @chavePix WHERE user_id = @user_id")
vRP.prepare("EG/editarPix","UPDATE vrp_user_identities SET chavePix = @chavePix WHERE user_id = @user_id")
vRP.prepare("EG/getPix","SELECT * FROM vrp_user_identities WHERE user_id = @user_id")
vRP.prepare('EG/getIdPix', "SELECT * FROM vrp_user_identities WHERE chavePix = @chavePix")
vRP.prepare("EG/getAll","SELECT tipo,store,valor FROM m_bank WHERE user_id = @user_id ORDER BY id DESC limit 4")
vRP.prepare("EG/transacoes","INSERT IGNORE INTO vrp_banco(user_id,extrato,data) VALUES(@user_id,@extrato,@data)")
vRP.prepare("EG/bankTransacoes","INSERT IGNORE INTO m_bank(user_id,para,tipo,store,valor) VALUES(@user_id,@para,@tipo,@store,@valor)")

vRP.prepare("EG/SomaGanhos", "SELECT valor from m_bank WHERE para = @user_id limit 10")
vRP.prepare("EG/SomaPerdas", "SELECT valor from m_bank WHERE user_id = @user_id and para != @user_id limit 10")

vRP.prepare("EG/createTable", "CREATE TABLE IF NOT EXISTS `m_bank` (`id` int(11) unsigned NOT NULL AUTO_INCREMENT,`user_id` int(11) unsigned DEFAULT NULL,`para` int(11) DEFAULT NULL,`valor` bigint(20) DEFAULT NULL,`tipo` varchar(50) DEFAULT NULL,`store` varchar(50) DEFAULT NULL,`data` timestamp NULL DEFAULT current_timestamp(),PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=latin1;")
vRP.prepare("EG/createTableTwo", "CREATE TABLE IF NOT EXISTS `vrp_banco` (`id` bigint(20) NOT NULL AUTO_INCREMENT,`user_id` bigint(20) NOT NULL DEFAULT 0,`extrato` varchar(255) NOT NULL,`data` varchar(255) NOT NULL,PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=latin1;")
--------------------------------------------------------------------------------------------------
-- VARIAVEIS -------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
local timers = 0
local recompensa = 0
local andamento = false
local tempoRoubo = {}
local webhookRoubo = cFG.webhookRoubo
local webhookSacar = cFG.webhookSacar
local webhookDepositar = cFG.webhookDepositar
local webhookTransferir = cFG.webhookTransferir
local cooldown = {}
--------------------------------------------------------------------------------------------------
--[ FUNÇÕES ]-------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
local store = "Banco"

Citizen.CreateThread( function()
    vRP.execute("EG/createTable")
    vRP.execute("EG/createTableTwo")
end)

function eG.getTransacoes()
	local source = source
	local user_id = vRP.getUserId(source)
	local bankMoney = vRP.getBankMoney(user_id)
	local transacoes = vRP.query("EG/getAll", {user_id = user_id}) or 0
	local carteira = vRP.getMoney(user_id)

	local tipo = {}
	local store = {}
	local value = {}

	i=1
	if transacoes[i] then
		for k,v in pairs(transacoes) do
			if v.store == 'Banco' or "Loja" then
				store[i] = v.store
			end
			if v.tipo == 'Depósito' or v.tipo == 'Transferência' or v.tipo == 'Saque' or v.tipo == 'Pix' then
				tipo[i] = v.tipo
			end
			if v.tipo then
				value[i] = v.valor
			end
			i = i + 1
		end
	end

	local value = vRP.getUData(parseInt(user_id),"vRP:multas")
	local multas = json.decode(value) or 0
	-- print(bankMoney)
	return bankMoney, transacoes, value, tipo, store, carteira, multas
end

function eG.getIdentity()
	local source = source
	local user_id = vRP.getUserId(source)
	local identity = vRP.query("EG/getPix", {user_id = user_id})
	local name = identity[1].nome.." "..identity[1].sobrenome
	local chavePix = identity[1].chavePix
	local id = identity[1].user_id
	return name, chavePix, id
end

function eG.getGraph()
	local source = source
	local user_id = vRP.getUserId(source)
	local multas = vRP.getUData(user_id,"vRP:multas") or 01
	local array = {}
	
	local ganhos = vRP.query("EG/SomaGanhos", {user_id = user_id})
	local somaGanhos = 1
	for k,v in pairs(ganhos) do
		somaGanhos = somaGanhos + parseInt(v.valor)
	end

	local percas = vRP.query("EG/SomaGanhos", {user_id = user_id})
	local somaPercas = 1
	for k,v in pairs(percas) do
		somaPercas = somaPercas + parseInt(v.valor)
	end

	array[1] = somaGanhos
	array[2] = somaPercas
	array[3] = parseInt(multas)
	
	return array
end

function eG.cadastrarPix(value)
	local source = source
    local user_id = vRP.getUserId(source)
	local identity = vRP.getUserIdentity(user_id)
	if value == "" then
		TriggerClientEvent("Notify",source,"negado","Valor <b>inválido</b>.")
		return
	end

	value = string.lower(value)
	local aux = vRP.query("EG/selectPix",{ chavePix = value })
	aux = json.encode(aux[1])
	aux = string.find(aux, "0")
	if aux then
		vRP.execute("EG/criarPix",{ chavePix = value, user_id = user_id })
		TriggerClientEvent("Notify",source,"sucesso","<b>Pix</b> Cadastrado, feche e abra o banco!.")
	else
		TriggerClientEvent("Notify",source,"negado","<b>Pix</b> já existente.")
	end
end

function eG.editarPix(value)
	local source = source
    local user_id = vRP.getUserId(source)
	local identity = vRP.getUserIdentity(user_id)
	if value == "" then
		TriggerClientEvent("Notify",source,"negado","Valor <b>inválido</b>.")
		return
	end

	value = string.lower(value)
	local aux = vRP.query("EG/selectPix",{ chavePix = value })
	aux = json.encode(aux[1])
	aux = string.find(aux, "0")
	if aux then
		vRP.query("EG/editarPix",{ user_id = user_id, chavePix = value })
		TriggerClientEvent("Notify",source,"sucesso","<b>Pix</b> editado, feche e abra o banco!.")
	else
		TriggerClientEvent("Notify",source,"negado","<b>Pix</b> já existente.")
	end
end
 
--[ DEPOSITAR ]-------------------------------------------------------------------------------
function eG.depositar(value)
	local source = source
	local user_id = vRP.getUserId(source)
	local identity = vRP.getUserIdentity(user_id)

	value = parseInt(value)
	if value == nil or value <= 0 or value > vRP.getMoney(user_id) then
		TriggerClientEvent("Notify",source,"negado","Valor <b>inválido</b>.")
	else
		antifloodEGBANK(source,"Flodando botão de realizar DEPOSITO",4)
		vRP.tryDeposit(user_id, tonumber(value))

		local extrato = "Depositou R$"..dot_string(tostring(value))
		local data = os.date("%d/%m/%Y %H:%M:%S")
		vRP.execute("EG/transacoes",{ user_id = user_id, extrato = extrato, data = data })

		local tipo = "Depósito"
		vRP.execute("EG/bankTransacoes",{ user_id = user_id, para = user_id, tipo = tipo, valor = value,store = store })

		TriggerClientEvent("Notify",source,"sucesso","Você depositou <b>$"..value.." dólares</b>.")
		SendWebhookMessage(webhookDepositar,"```prolog\n[ID]: "..user_id.." "..identity.nome.." "..identity.sobrenome.." \n[DEPOSITOU]: "..value.." "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```") 
	end
end

--[ SACAR ]-----------------------------------------------------------------------------------
function eG.sacar(value)
	local source = source
	local user_id = vRP.getUserId(source)
	local identity = vRP.getUserIdentity(user_id)

	value = parseInt(value)
	local getBankMoney = vRP.getBankMoney(user_id)

	if value == nil or value <= 0 or value > vRP.getBankMoney(user_id) then
		TriggerClientEvent("Notify",source,"negado","Valor inválido")
	else
		antifloodEGBANK(source,"Flodando botão de realizar SAQUE",4)
		vRP.tryWithdraw(user_id,value)

		local extrato = "Sacou R$"..dot_string(tostring(value))
		local data = os.date("%d/%m/%Y %H:%M:%S")
		vRP.execute("EG/transacoes",{ user_id = user_id, extrato = extrato, data = data })

		local tipo = "Saque"
		vRP.execute("EG/bankTransacoes",{ user_id = user_id, para = user_id, tipo = tipo, valor = value,store = store })

		TriggerClientEvent("Notify",source,"sucesso","Você sacou <b>$"..value.." dólares</b>.")
		SendWebhookMessage(webhookSacar,"```prolog\n[ID]: "..user_id.." "..identity.nome.." "..identity.sobrenome.." \n[SACOU]: "..value.." "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```") 
	end
end

--[ TRANSFERIR ]---------------------------------------------------------------------------------
function eG.transferir(para,value)
	local source = source
	local user_id = vRP.getUserId(source)
	local identity = vRP.getUserIdentity(user_id)

	local nplayer = vRP.getUserSource(parseInt(para))
	local nuser_id = para
	local identitynu = vRP.getUserIdentity(nuser_id)
	local banco = 0
	

	if nuser_id == nil then
		TriggerClientEvent("Notify",source,"negado","Passaporte inválido ou indisponível.")
	else
		if nuser_id == user_id then
			TriggerClientEvent("Notify",source,"negado","Você não pode transferir dinheiro para si mesmo.")
		elseif not nplayer then
			TriggerClientEvent("Notify",source,"negado","Pessoa fora da cidade.")
		else
			antifloodEGBANK(source,"Flodando botão de realizar TRANSFERENCIA",4)
			local banco = vRP.getBankMoney(user_id)
			local banconu = vRP.getBankMoney(nuser_id)
			if banco <= 0 or banco < tonumber(value) or tonumber(value) <= 0 then
				TriggerClientEvent("Notify",source,"negado","Dinheiro Insuficiente")
			else
				vRP.setBankMoney(user_id,banco-value)
				vRP.setBankMoney(nuser_id,banconu+value)
				
				local extrato = "Efetuou uma transferência de R$"..dot_string(tostring(value))
				local extrato2 = "Recebeu uma transferência de R$"..dot_string(tostring(value))
				local data = os.date("%d/%m/%Y %H:%M:%S")
				vRP.execute("EG/transacoes",{ user_id = user_id, extrato = extrato, data = data })
				vRP.execute("EG/transacoes",{ user_id = nuser_id, extrato = extrato2, data = data })
				
				local tipo = "Transferência"
				vRP.execute("EG/bankTransacoes",{ user_id = user_id, para = nuser_id, tipo = tipo, valor = value,store = store })
				
				TriggerClientEvent("Notify",nplayer,"sucesso","<b>"..identity.nome.." "..identity.sobrenome.."</b> depositou <b>$"..value.." dólares</b> na sua conta.")
				TriggerClientEvent("Notify",source,"sucesso","Você transferiu <b>$"..value.." dólares</b> para conta de <b>"..identitynu.nome.." "..identitynu.sobrenome.."</b>.")
				SendWebhookMessage(webhookTransferir,"```prolog\n[ID]: "..user_id.." \n[TRANSFERIU]: "..value.." \n[PARA O ID]: "..nuser_id.." "..identitynu.nome.." "..identitynu.sobrenome.." "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```") 
				
			end
		end
	end
end

--[ PIX ]---------------------------------------------------------------------------------
function eG.chavePix(para,value)
	local source = source
	local user_id = vRP.getUserId(source)
	local identity = vRP.getUserIdentity(user_id)
	
	local aux = vRP.query("EG/getIdPix",{ chavePix = para })

	if aux[1] == nil then
		TriggerClientEvent("Notify",source,"negado","PIX inválido ou indisponível.")
		return
	else
		local nplayer = vRP.getUserSource(parseInt(aux[1].user_id))
		local nuser_id = aux[1].user_id
		local identitynu = vRP.getUserIdentity(nuser_id)
		local banco = 0

		if nuser_id == nil then
			TriggerClientEvent("Notify",source,"negado","Passaporte inválido ou indisponível.")
		else
			antifloodEGBANK(source,"Flodando botão de realizar PIX",4)
			if nuser_id == user_id then
				TriggerClientEvent("Notify",source,"negado","Você não pode transferir dinheiro para si mesmo.")
			elseif not nplayer then
				TriggerClientEvent("Notify",source,"negado","Pessoa fora da cidade.")
			else
				local banco = vRP.getBankMoney(user_id)
				local banconu = vRP.getBankMoney(nuser_id)
				if banco <= 0 or banco < tonumber(value) or tonumber(value) <= 0 then
					TriggerClientEvent("Notify",source,"negado","Dinheiro Insuficiente")
				else
					vRP.setBankMoney(user_id,banco-value)
					vRP.setBankMoney(nuser_id,banconu+value)
					
					local extrato = "Efetuou uma transferência de R$"..dot_string(tostring(value))
					local extrato2 = "Recebeu uma transferência de R$"..dot_string(tostring(value))
					local data = os.date("%d/%m/%Y %H:%M:%S")
					vRP.execute("EG/transacoes",{ user_id = user_id, extrato = extrato, data = data })
					vRP.execute("EG/transacoes",{ user_id = nuser_id, extrato = extrato2, data = data })
					
					local tipo = "Transferência"
					vRP.execute("EG/bankTransacoes",{ user_id = user_id, para = nuser_id, tipo = tipo, valor = value,store = store })
					
					TriggerClientEvent("Notify",nplayer,"sucesso","<b>"..identity.nome.." "..identity.sobrenome.."</b> depositou <b>$"..value.." dólares</b> na sua conta.")
					TriggerClientEvent("Notify",source,"sucesso","Você transferiu <b>$"..value.." dólares</b> para conta de <b>"..identitynu.nome.." "..identitynu.sobrenome.."</b>.")
					SendWebhookMessage(webhookTransferir,"```prolog\n[ID]: "..user_id.." \n[TRANSFERIU]: "..value.." \n[PARA O ID]: "..nuser_id.." "..identitynu.nome.." "..identitynu.sobrenome.." "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```") 
					
				end
			end
		end
	end
end

function eG.pagarMultas(valor)
	local source = source
	local user_id = vRP.getUserId(source)

	local value = vRP.getUData(parseInt(user_id),"vRP:multas")
	local multas = json.decode(value) or 0
	local banco = vRP.getBankMoney(user_id)
	
	if user_id then
    	antifloodEGBANK(source,"Flodando botão de pagar MULTAS",4)
		if parseInt(valor) >  0 then
			if banco >= parseInt(valor) then
				if parseInt(valor) <= parseInt(multas) then
					vRP.setBankMoney(user_id,parseInt(banco-valor))
					vRP.setUData(user_id,"vRP:multas",json.encode(parseInt(multas)-parseInt(valor)))
					TriggerClientEvent("Notify",source,"sucesso","Você pagou <b>$"..valor.." dólares</b> em multas.",8000)

					local extrato = "Pagou Multa no valor de R$"..dot_string(tostring(valor))
					local data = os.date("%d/%m/%Y %H:%M:%S")
					vRP.execute("EG/transacoes",{ user_id = user_id, extrato = extrato, data = data })
			
					local tipo = "Pagou multa"
					vRP.execute("EG/bankTransacoes",{ user_id = user_id, para = user_id, tipo = tipo, valor = valor, store = store })
				else
					TriggerClientEvent("Notify",source,"negado","Você não pode pagar mais multas do que deve.",8000)
				end
			else
				TriggerClientEvent("Notify",source,"negado","Você não tem dinheiro em sua conta suficiente para isso.",8000)
			end
		end
	end
end


function dot_string(s)
    if s:len() <= 3 then
        return s
    end 
    return dot_string(s:sub(1, -4)) .. "." .. s:sub(-3)
end 

local delayflood = {}
local flood = {}
function antifloodEGBANK(source,key,limite)
	if cFG.antiFlood.status then
		if(flood[key]==nil or delayflood[key] == nil)then 
			flood[key]={}
			delayflood[key]={}
		end
		if(flood[key][source]==nil)then
			flood[key][source] = 1
			delayflood[key][source] = os.time()
		else
			if(os.time()-delayflood[key][source]<1)then
				flood[key][source]= flood[key][source] + 1
				if(flood[key][source]==limite)then
					local user_id = vRP.getUserId(source)
					if cFG.antiFlood.ban then
						vRP.setBanned(user_id,true)
					end
					DropPlayer(source, "PEGO PELO ANTI-FLOOD!")
					mensagem = "```prolog\n[ID]: "..user_id.." [PEGO PELO ANTI-FLOOD]: "..key..""..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").."```"
					PerformHttpRequest(cFG.antiFlood.webhook, function(err, text, headers) end, 'POST', json.encode({content = mensagem}), { ['Content-Type'] = 'application/json' })
				end
			else
				flood[key][source]=nil
				delayflood[key][source] = nil
			end
			delayflood[key][source] = os.time()
		end
	else
		return
	end
end

AddEventHandler("vRP:playerSpawn",function(user_id,source,first_spawn)
	if first_spawn then
		if cFG.bancoBlips.showBlip then
			for k,v in pairs(cFG.bancos) do
				vRPclient._addBlip(source,v.x,v.y,v.z,cFG.bancoBlips.bMapType,cFG.bancoBlips.bColor,cFG.bancoBlips.bText,cFG.bancoBlips.bScale,false)
			end
		end
		if cFG.atmBlips.showBlip then
			for k,v in pairs(cFG.atms) do
				vRPclient._addBlip(source,v.x,v.y,v.z,cFG.atmBlips.bMapType,cFG.atmBlips.bColor,cFG.atmBlips.bText,cFG.atmBlips.bScale,false)
			end
		end
	end
end)
---------------------------------------------------------------
-- AUTENTICADOR -----------------------------------------------
---------------------------------------------------------------
-- function eG.checkAuth()
--     return true
-- end