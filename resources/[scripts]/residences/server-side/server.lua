local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
cO = {}
Tunnel.bindInterface("residences",cO)
vCLIENT = Tunnel.getInterface("residences")

-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local homeLock = {}
local homeEnter = {}
local homesInterior = {}
local homes = {}
local chestOpen = {}
----------------------------
local webhookbaucasas = GetConvar("ic_secret_residences_webhook", GetConvar("interior_city_webhook_logs", ""))

function SendWebhookMessage(webhook,message)
	if webhook ~= nil and webhook ~= "" then
		PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({content = message}), { ['Content-Type'] = 'application/json' })
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- NEW INTERIOR -- TRADE
-----------------------------------------------------------------------------------------------------------------------------------------
local newInterior = ResidencesInteriors or {}

-----------------------------------------------------------------------------------------------------------------------------------------
-- START
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
    Wait(800)
    homes = ResidenceHomes or homes
    newInterior = ResidencesInteriors or newInterior
    vCLIENT.updateHomes(-1,homes)
end)

AddEventHandler("residences:panelConfigUpdated",function(updatedHomes,updatedInteriors,updatedTypes,settings)
    homes = updatedHomes or {}
    newInterior = updatedInteriors or {}
    -- Keep the private Docker/convar destination independent of shared panel JSON.
    webhookbaucasas = GetConvar("ic_secret_residences_webhook", GetConvar("interior_city_webhook_logs", ""))
    vCLIENT.updateHomes(-1,homes)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ENTER INTERIOR
-----------------------------------------------------------------------------------------------------------------------------------------
function cO.myInterior(interiorType,homeName,homeNumber)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then 
		if newInterior[interiorType] then 
			if newInterior[interiorType] then 
				if homeNumber == 0 then 
					if GetPlayerRoutingBucket(source) == 0 then
						SetPlayerRoutingBucket(source, parseInt(user_id))
						return newInterior[interiorType]
					end
				end
			end

			if (ResidenceTypes[homeName] == "Apartamento" or (homeName):find "Apartamento") then 
				local ownerConsult = vRP.query("vRP/selectOwner",{ name = homeName, number = homeNumber })
				if ownerConsult[1] then
					local interiorCasa = newInterior[interiorType]
					if ownerConsult[1]["interior"] ~= interiorType then
						interiorCasa = newInterior[ownerConsult[1]["interior"]]
					end
					if GetPlayerRoutingBucket(source) == 0 then
						SetPlayerRoutingBucket(source, parseInt(ownerConsult[1]["user_id"]))
					end
					return interiorCasa
				end
				return newInterior[interiorType]
			end

			local checkExist = vRP.query("homes/userOwnermissions",{ name = homeName })
			if checkExist[1] then 
				if GetPlayerRoutingBucket(source) == 0 then
					SetPlayerRoutingBucket(source, parseInt(checkExist[1]["user_id"]))
					local myInterior = newInterior[interiorType]
					if checkExist[1]["interior"] ~= interiorType then
						myInterior = newInterior[checkExist[1]["interior"]]
					end
					return myInterior
				end
			end
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- NEARESTHOMES
-----------------------------------------------------------------------------------------------------------------------------------------
function nearestHomes(source)
	local ped = GetPlayerPed(source)
	local coords = GetEntityCoords(ped)

	for k,v in pairs(homes) do
		local distance = #(coords - vector3(v[1],v[2],v[3]))
		if distance <= 1.5 then
			return k
		end
	end

	return false
end

RegisterCommand("rsolo",function(source,args,rawCommand)
	local source = source
	local user_id = vRP.getUserId(source)
	local nplayer = vRP.getUserSource(parseInt(args[1]))
	if vRP.hasPermission(user_id,"suporte.permissao") then 
		if args[1] then 
			--if homeEnter[nplayer] then
			--vCLIENT.teleport(nplayer,278.88,-337.13,44.92)
			SetPlayerRoutingBucket(nplayer, 0)
			homeEnter[nplayer] = nil
			TriggerClientEvent("Notify",source,"sucesso","Você retitou o player da sessao solo")
			--end
		else
			SetPlayerRoutingBucket(user_id, 0)
			homeEnter[user_id] = nil
			TriggerClientEvent("Notify",source,"sucesso","Você saiu da sessao solo")
		end
	end	
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONSULT APARTAMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function getFreeAppartment(homeName,number)
	local rows = vRP.query("vRP/selectAppartment",{ name = homeName, number = number })
	if rows[1] then 
		return rows[1].user_id
	end
	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FIND INTERFONE
-----------------------------------------------------------------------------------------------------------------------------------------
function findFreeNumber(homeName,max)
	local i = 1
	while i <= max do
		if not getFreeAppartment(homeName,i) then
			return i
		end
		i = i+1
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- APARTAMENTO
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("casas",function(source,args,rawCommand)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then 
		local homesList = vRP.query("homes/userList",{ user_id = user_id })
		if parseInt(#homesList) >= 1 then
			for k,v in pairs(homesList) do
				if string.find(v["name"],"Apartamento") then 
					if parseInt(os.time()) >= parseInt(v["tax"] + 24 * 15 * 60 * 60) then
						TriggerClientEvent("Notify",source,"sucesso","<b>Apartamento:</b> "..v["name"].."<br> <b>Interfone:</b> " ..v["number"].."<br> <b>Taxa:</b> Vencida",20000)
					else
						TriggerClientEvent("Notify",source,"sucesso","<b>Apartamento:</b> "..v["name"].."<br> <b>Interfone:</b> " ..v["number"].."<br> <b>Taxa:</b> "..vRP.getDayHours(86400 * 15 - (os.time() - v["tax"])).." ",20000)
					end
				else
					TriggerClientEvent("Notify",source,"sucesso","<b>Residência:</b> "..v["name"].. "<br> <b>Taxa:</b> "..vRP.getDayHours(86400 * 15 - (os.time() - v["tax"])).." ",20000)
				end
			end
		else
			TriggerClientEvent("Notify",source,"negado","Você não possuí residências",6000)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CRIAÇÃO DE NOVAS CASAS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("homeadm",function(source,args,rawCommand)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id and vRP.hasPermission(user_id, "developer.permissao") or vRP.hasPermission(user_id, "perm.administrador") then 
		if args[1] == "deletar" then 
			local homeName = nearestHomes(source)
			if homeName then 
				local choice = vRP.request(source, "Deseja deletar a residência e remover todos moradores ? ", 60)
				if choice then 
					vRP.execute("vRP/deleteHouse",{ name = homeName })
					vRP.execute("homes/selling",{ name = homeName })
					vRP.remSrvdata("wardrobe:"..homeName)
					vRP.remSrvdata("fridge:"..homeName)
					vRP.remSrvdata("vault:"..homeName)
					homes[homeName] = nil
					vCLIENT.updateHomes(-1,homes)
				end
			end
		else
			vCLIENT.showOptions(source,1)
		end
	end	
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INTERAÇÃO CRIAÇÃO
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("homes:createSystem")
AddEventHandler("homes:createSystem",function(actionType)
	local source = source 
	local user_id = vRP.getUserId(source)
	if user_id and vRP.hasPermission(user_id,"developer.permissao") then
		local coords = GetEntityCoords(GetPlayerPed(source))
		TriggerClientEvent("dynamic:closeSystem2", source)
		if actionType == "Apartamento" then 
			local number = vRP.prompt(source, "Insira o número do condominio", "0")
			if parseInt(number) > 0 then 
				local checkExist = vRP.query("vRP/selectcHouse", { name = "Apartamento"..number })
				if not checkExist[1] then 
					local price = vRP.prompt(source, "Insira o valor do apartamento", "0")
					if parseInt(price) > 0 then 
						local slot = vRP.prompt(source, "Insira o máximo de moradores do condomínio", "10")
						if parseInt(slot) > 0 then 
							local trade = vRP.prompt(source, "Deseja que o apartamento valorize ? , se sim insira o valor que vai aumentar a cada venda", "0")
							if parseInt(trade) > 0 then 
								vCLIENT.showOptions(source,2,newInterior)
							end
						end
					end		
					local actived = {}

					RegisterServerEvent("homes:interiorCheck")
					AddEventHandler("homes:interiorCheck",function(interiorType)
						if actived[user_id] then return end 
						actived[user_id] = true 
						if newInterior[interiorType] and not homes["Apartamento"..number] then 
							TriggerClientEvent("dynamic:closeSystem2", source)
							homes["Apartamento"..number] = { coords.x,coords.y,coords.z,interiorType,parseInt(price),parseInt(slot),parseInt(trade) }
							vRP.execute("vRP/insertHouses",{ name = "Apartamento"..number, x = coords.x, y = coords.y, z = coords.z, interiorType = interiorType, intPrice = parseInt(price), slot = parseInt(slot), trade = parseInt(trade)   })
							vCLIENT.updateHomes(-1,homes)
							return
						end
					end)

				else
					TriggerClientEvent("Notify",source,"negado","Esse condominio já existe",5000) 
				end 
			end
		elseif actionType == "Casa" then 
			local number = vRP.prompt(source, "Insira o número da casa", "0")
			local checkExist = vRP.query("vRP/selectcHouse", { name = "Homes"..number })
			if not checkExist[1] then 
				local price = vRP.prompt(source, "Insira o valor da casa", "0")
				if parseInt(price) > 0 then 
					vCLIENT.showOptions(source,2,newInterior)
				end

				local actived = {}

				RegisterServerEvent("homes:interiorCheck")
				AddEventHandler("homes:interiorCheck",function(interiorType)
					if actived[user_id] then return end 
					actived[user_id] = true 
					if newInterior[interiorType] and not homes["Homes"..number]  then 
						TriggerClientEvent("dynamic:closeSystem2", source)
						homes["Homes"..number] = { coords.x,coords.y,coords.z,interiorType,parseInt(price),0,0 }
						vRP.execute("vRP/insertHouses",{ name = "Homes"..number, x = coords.x, y = coords.y, z = coords.z, interiorType = interiorType, intPrice = parseInt(price), slot = 0, trade = 0  })
						vCLIENT.updateHomes(-1,homes)
						return
					end
				end)

			else
				TriggerClientEvent("Notify",source,"negado","Essa casa já existe",5000) 
			end 
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SISTEMA
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("homes:invokeSystem")
AddEventHandler("homes:invokeSystem",function(action)
	local source = source
	local user_id = vRP.getUserId(source)
	
	if user_id then 
		local homeName = nearestHomes(source) --[[or tostring(args[1])]]
		if homes[tostring(homeName)] then 
			TriggerClientEvent("dynamic:closeSystem2", source)
			if action == "visitar" then 
				homesInterior[homeName] = homes[homeName][4]
				vCLIENT.entranceHomes(source,homeName,homesInterior[homeName],false,0,true)
			elseif action == "buyHouse" then 
				--if not vRP.hasPermission(user_id, "manager.permissao") then return end

				local checkExist = vRP.query("homes/permissions",{ name = homeName })
				if checkExist[1] == nil then
					local value = vRP.getUData(parseInt(user_id),"vRP:multas")
					local multas = json.decode(value) or 0
					if multas > 0 then
						TriggerClientEvent("Notify",source,"negado","Você tem multas pendentes.",10000)
						return
					end

					local interiorSelect = homes[homeName][4]
					local homesPrice = homes[homeName][5]
					--local plyInfos = vRP.query("creative/get_users", { user_id = user_id })
					--[[print(json.encode(plyInfos))
					if plyInfos[1] and plyInfos[1]["ticketCasa"] > 0 then 
						if vRP.request(source,"Deseja comprar a residência <b>"..interiorSelect.."</b> utilizando seu ticket vip ?",30) then
							vRP.execute("vRP/updateTicket",{ user_id = user_id })
							vRP.execute("homes/buying",{ name = homeName, user_id = user_id, interior = homes[homeName][4], tax = os.time(), price = homesPrice, residents = newInterior[interiorSelect]["residents"], vault = newInterior[interiorSelect]["vault"], fridge = newInterior[interiorSelect]["fridge"] })
							TriggerClientEvent("Notify",source,"sucesso","Compra concluída.",5000)
							return
						end
					end
]]
				local maxHomes = vRP.query("homes/countUsers",{ user_id = user_id })
					local myHomes = 10
					if parseInt(maxHomes[1]["qtd"]) >= myHomes then
						TriggerClientEvent("Notify",source,"negado","Atingiu o máximo de residências.",3000)
						return
					end

					 local interiorSelect = homes[homeName][4]
					 local homesPrice = homes[homeName][5]

					if vRP.request(source,"Deseja comprar a residência <b>"..interiorSelect.."</b> por <b>$"..vRP.format(homesPrice).."</b> dólares?",30) then
						if vRP.tryPayment(user_id,homesPrice) then
							vRP.execute("homes/buying",{ name = homeName, user_id = user_id, interior = homes[homeName][4], tax = os.time(), price = homesPrice, residents = newInterior[interiorSelect]["residents"], vault = newInterior[interiorSelect]["vault"], fridge = newInterior[interiorSelect]["fridge"] })
							TriggerClientEvent("Notify",source,"sucesso","Compra concluída.",5000)
						else
							TriggerClientEvent("Notify",source,"negado","Dólares insuficientes.",5000)
						end
					end
				end
			elseif action == "buyAp" then 
--if not vRP.hasPermission(user_id, "manager.permissao") then return end

				local checkHouse = 0
				local ownerConsult = vRP.query("homes/userOwnermissions",{ name = homeName })
							
				if ownerConsult[1] == nil then checkHouse = 0 else checkHouse = ownerConsult[1]["user_id"] end 
				if checkHouse == 0 or checkHouse ~= user_id then 
					local slot = findFreeNumber(homeName,homes[homeName][6])
					if slot then 
						local interiorSelect = homes[homeName][4]
						local homesPrice = homes[homeName][5]
						if #ownerConsult > 1  then 
							if homes[homeName][7] then 
								local trading = homes[homeName][7] * #ownerConsult
								homesPrice = homesPrice + trading
							end
						end

						local value = vRP.getUData(parseInt(user_id),"vRP:multas")
                        local multas = json.decode(value) or 0
                        if multas > 0 then
                            TriggerClientEvent("Notify",source,"negado","Você tem multas pendentes.",10000)
                            return
                        end
--[[
						local plyInfos = vRP.query("creative/get_users", { user_id = user_id })
						if plyInfos[1] and plyInfos[1]["ticketCasa"] > 0 then 
							if vRP.request(source,"Deseja comprar a residência <b>"..interiorSelect.."</b> utilizando seu ticket vip ?",30) then
								vRP.execute("vRP/updateTicket",{ user_id = user_id })
								vRP.execute("vRP/buyAppartment",{ name = homeName, user_id = user_id, interior = homes[homeName][4], tax = os.time(), price = homesPrice, number = parseInt(slot), residents = newInterior[interiorSelect]["residents"], vault = newInterior[interiorSelect]["vault"], fridge = newInterior[interiorSelect]["fridge"] })
								TriggerClientEvent("Notify",source,"sucesso","Compra concluída.",5000)
								return
							end
						end
						]]
    
					local maxHomes = vRP.query("homes/countUsers",{ user_id = user_id })
						local myHomes = 10
						if parseInt(maxHomes[1]["qtd"]) >= myHomes then
							TriggerClientEvent("Notify",source,"negado","Atingiu o máximo de residências.",3000)
							return
						end
	
						if vRP.request(source,"Deseja comprar a residência <b>"..interiorSelect.."</b> por <b>$"..vRP.format(homesPrice).."</b> dólares?",30) then
							if vRP.tryPayment(user_id,homesPrice) then
								vRP.execute("vRP/buyAppartment",{ name = homeName, user_id = user_id, interior = homes[homeName][4], tax = os.time(), price = homesPrice, number = parseInt(slot), residents = newInterior[interiorSelect]["residents"], vault = newInterior[interiorSelect]["vault"], fridge = newInterior[interiorSelect]["fridge"] })
								TriggerClientEvent("Notify",source,"sucesso","Compra concluída.",5000)
							else
								TriggerClientEvent("Notify",source,"negado","Dólares insuficientes.",5000)
							end
						end
					else
						TriggerClientEvent("Notify",source,"negado","Todos apartamentos já foram vendidos.",6000)
					end
				else
					TriggerClientEvent("Notify",source,"negado","Você já possuí um apartamento neste condomínio",6000)
				end
			elseif action == "interfone" then 
				if homes[homeName][6] >= 1 then
					local consult = vRP.query("homes/userPermissions",{ name = homeName, user_id = user_id })
					if consult[1] and consult[1].number then 
						local myInterfone = consult[1].number
						local interfone = vRP.prompt(source, "Insira o número do apartamento", myInterfone)
						if interfone ~= "" and parseInt(interfone) > 0 then 
							
							local myAppartment = getFreeAppartment(homeName,parseInt(interfone))
							if myAppartment then
								homesInterior[homeName] = homes[homeName][4]
								if parseInt(myInterfone) ~= parseInt(interfone) then
	
									local playerOne = vRP.getUserSource(parseInt(myAppartment))
									if playerOne then 
										local identity = vRP.getUserIdentity(user_id)
										local onChoice = vRP.request(playerOne, identity["name"].." "..identity["firstname"].." Está tocando sua campainha, deseja aceitar ?" , 60)
										if onChoice then 
											vCLIENT.entranceHomes(source,homeName,homesInterior[homeName],false,parseInt(interfone))
											return 
										else
											TriggerClientEvent("Notify",source,"importante","Sua solicitação foi recusada.",10000)
											return false
										end
									else
										TriggerClientEvent("Notify",source,"negado","O morador está fora da cidade.",10000)
										return false
									end
								end
								
								local ownerConsult = vRP.query("vRP/selectOwner",{ name = homeName, number = consult[1].number })
								if parseInt(os.time()) >= parseInt(ownerConsult[1]["tax"] + 24 * 15 * 60 * 60) then
									TriggerClientEvent("Notify",source,"amarelo","As taxas da propriedade estão atrasadas.",10000)
									return false
								end

								vCLIENT.entranceHomes(source,homeName,homesInterior[homeName],false,parseInt(interfone))
								if parseInt(consult[1]["owner"]) >= 1 then 
									TriggerClientEvent("Notify",source,"amarelo","Taxa em : "..vRP.getDayHours(86400 * 15 - (os.time() - consult[1]["tax"])),10000)
								end
								return
							end
						end
					else
						local interfone = vRP.prompt(source, "Insira o número do apartamento","0")
						if interfone ~= "" and parseInt(interfone) > 0 then 
							local myAppartment = getFreeAppartment(homeName,parseInt(interfone))
							if myAppartment then
								homesInterior[homeName] = homes[homeName][4]
								if user_id ~= myAppartment then
									local playerOne = vRP.getUserSource(parseInt(myAppartment))
									if playerOne then 
										local identity = vRP.getUserIdentity(user_id)
										local onChoice = vRP.request(playerOne, identity["name"].." "..identity["firstname"].." Está tocando sua campainha, deseja aceitar ?" , 60)
										if onChoice then 
											vCLIENT.entranceHomes(source,homeName,homesInterior[homeName],false,parseInt(interfone))
											return 
										else
											TriggerClientEvent("Notify",source,"amarelo","Sua solicitação foi recusada.",10000)
											return false
										end
									else
										TriggerClientEvent("Notify",source,"negado","O morador está fora da cidade.",10000)
										return false
									end
								end
							end
						end
					end
					return
				end
			elseif action == "list" then 
                if (ResidenceTypes[homeName] == "Apartamento" or (homeName):find "Apartamento") then 
					local permList = ""
					local query = vRP.query("homes/userPermissions",{ name = homeName, user_id = user_id })
                    if query[1] then 
						local checkExist = vRP.query("vRP/selectAppartment",{ name = homeName, number = query[1].number })
						if checkExist[1] then 
							for k,v in pairs(checkExist) do
								local identity = vRP.getUserIdentity(v["user_id"])
								if identity then
									permList = permList.."<b>Nome:</b> "..identity["name"].." "..identity["firstname"].."   -   <b>Passaporte:</b> "..v["user_id"]
									if k ~= #checkExist then
										permList = permList.."<br>"
									end
								end
							end
							TriggerClientEvent("Notify",source,"importante","Lista de permissões da residência: <br>"..permList,20000)
						end
                    end
                else
					local permList = ""
                    local checkExist = vRP.query("homes/permissions",{ name = homeName })
					if checkExist[1] then 
						for k,v in pairs(checkExist) do
							local identity = vRP.getUserIdentity(v["user_id"])
							if identity then
								permList = permList.."<b>Nome:</b> "..identity["name"].." "..identity["firstname"].."   -   <b>Passaporte:</b> "..v["user_id"]
								if k ~= #checkExist then
									permList = permList.."<br>"
								end
							end
						end
						TriggerClientEvent("Notify",source,"importante","Lista de permissões da residência: <br>"..permList,20000)
					end
                end
            
			elseif action == "enterHouse" then 
				local checkExist = vRP.query("homes/permissions",{ name = homeName })
				if checkExist[1] then
					local ownerConsult = vRP.query("homes/userOwnermissions",{ name = homeName })
					if ownerConsult[1] then
						if parseInt(os.time()) >= parseInt(ownerConsult[1]["tax"] + 24 * 15 * 60 * 60) then
							TriggerClientEvent("Notify",source,"amarelo","As taxas da propriedade estão atrasadas.",10000)
							return false
						end
						TriggerClientEvent("Notify",source,"amarelo","Taxa em : "..cO.getDayHours(86400 * 15 - (os.time() - ownerConsult[1]["tax"])),1000)
					end
	
					homesInterior[homeName] = checkExist[1]["interior"]
	
					local consult = vRP.query("homes/userPermissions",{ name = homeName, user_id = user_id })
					if consult[1] then
						vCLIENT.entranceHomes(source,homeName,homesInterior[homeName],false)
					else
						if not homeLock[homeName] then
							TriggerClientEvent("Notify",source,"negado","Trancada.",3000)
						else
							local ownerConsult = vRP.query("homes/userOwnermissions",{ name = homeName })
							if ownerConsult[1] then
								if parseInt(os.time()) >= parseInt(ownerConsult[1]["tax"] + 24 * 15 * 60 * 60) then
									TriggerClientEvent("Notify",source,"amarelo","As taxas da propriedade estão atrasadas.",10000)
									return false
								end
							end
							vCLIENT.entranceHomes(source,homeName,homesInterior[homeName],false)
						end
					end
				end
			end


			-- PARTE DO DONO
			local consult = vRP.query("homes/userPermissions",{ name = homeName, user_id = user_id })
			if consult[1] and consult[1]["owner"] >= 1 then
				if action == "baú" then 
					if vRP.request(source,"Deseja aumentar o baú por <b>$100.000</b> dólares?",30) then
						if consult[1]["vault"] <= 1000 then 
							if vRP.tryPayment(user_id,100000) then
								vRP.execute("homes/updateVault",{ name = homeName, vault = 50 })
								TriggerClientEvent("Notify",source,"sucesso","Compra efetuada.",5000)
							else
								TriggerClientEvent("Notify",source,"negado","Dólares insuficientes.",5000)
							end
						else
							TriggerClientEvent("Notify",source,"negado","Atingiu o peso máximo do baú",5000)
						end
					end
				elseif action == "vender" then 
					local homesPrice = parseInt(consult[1]["price"] * 0.07)
					if vRP.request(source,"Deseja concluir a venda por <b>$"..vRP.format(homesPrice).."</b> dólares?",30) then
						local checkOwned 
						if (ResidenceTypes[homeName] == "Apartamento" or (homeName):find "Apartamento") then 
							checkOwned = vRP.query("vRP/selectOwner",{ name = homeName, number = consult[1]["number"] })
							if checkOwned[1] then
								vRP.execute("vRP/deleteAP",{ name = homeName, number = consult[1]["number"] })
								vRP.remSrvdata("vault:"..homeName..consult[1].number)
								vRP.giveBankMoney(user_id,homesPrice)
								TriggerClientEvent("Notify",source,"sucesso","Venda concluída.",5000)
							end
						else
							checkOwned = vRP.query("homes/userPermissions",{ name = homeName, user_id = user_id })
							if checkOwned[1] then
								TriggerEvent("vrp_garages:removeGarages",homeName)
								vRP.execute("homes/selling",{ name = homeName })
								vRP.remSrvdata("wardrobe:"..homeName)
								vRP.remSrvdata("vault:"..homeName)
								vRP.giveBankMoney(user_id,homesPrice)
								TriggerClientEvent("Notify",source,"sucesso","Venda concluída.",5000)
							end
						end
					end
				elseif action == "tax" then 
				--	if parseInt(os.time()) >= parseInt(consult[1]["tax"] + 24 * 15 * 60 * 60) then
						local homesPrice = parseInt(consult[1]["price"] * 0.27)
						if parseInt(consult[1]["price"])> 8000000 then 
						homesPrice = parseInt(consult[1]["price"] * 0.03)
						end
						if homesPrice > 350000 then
						homesPrice = 350000
						end
						if vRP.hasPermission(user_id, "casa.permissao") then  -- permissão que não paga taxa da casa
							vRP.execute("homes/updateTax",{ name = homeName, tax = os.time() })
							TriggerClientEvent("Notify",source,"sucesso","Pagamento efetuado.",10000)
							return 
						end
	
						if vRP.request(source,"Deseja pagar as taxas por <b>$"..vRP.format(homesPrice).."</b> dólares?",30) then
							if vRP.tryPayment(user_id,homesPrice) then
								vRP.execute("homes/updateTax",{ name = homeName, tax = os.time() })
								TriggerClientEvent("Notify",source,"sucesso","Pagamento efetuado.",10000)
							else
								TriggerClientEvent("Notify",source,"negado","Dólares insuficientes.",10000)
							end
						end
					--else
					--	TriggerClientEvent("Notify",source,"negado","Suas taxas não venceram, restam  <b>"..vRP.getDayHours(86400 * 15 - (os.time() - consult[1]["tax"])),10000)
					--end
				elseif action == "garagem" then 
					if (ResidenceTypes[homeName] == "Apartamento" or (homeName):find "Apartamento") then return end
					local homesGarage = 50000
					if vRP.request(source,"Deseja adicionar a garagem pagando <b>$"..vRP.format(homesGarage).."</b> dólares?",30) then
						if vRP.getBankMoney(user_id) + vRP.getMoney(user_id) >= homesGarage then
							TriggerClientEvent("Notify",source,"amarelo","Fique no local onde vai abrir a garagem e pressione a tecla <b>E</b>.",10000)
							vCLIENT.homeGarage(source,homeName,homes[homeName][1],homes[homeName][2],homes[homeName][3])
						else
							TriggerClientEvent("Notify",source,"negado","Dólares insuficientes.",5000)
						end
					end
				elseif action == "trans" then 
					local nplayer = vRP.prompt(source, "Insira o passaporte que deseja transferir a residência")
					if nplayer and nplayer ~= "" and parseInt(nplayer) > 0 and vRP.getUserSource(parseInt(nplayer)) then 
						local nuser_id = parseInt(nplayer)
						local identity = vRP.getUserIdentity(nuser_id)
						if identity then
						--[[local maxHomes = vRP.query("homes/countUsers",{ user_id = user_id })
							local myHomes = vRP.query("homes/countHouses",{ user_id = user_id })[1]["houses"]
							if parseInt(maxHomes[1]["qtd"]) >= myHomes then
								TriggerClientEvent("Notify",source,"negado","Atingiu o máximo de residências.",3000)
								return
							end]]
					
							local userConsult = vRP.query("homes/userPermissions",{ user_id = nuser_id, name = homeName })
							if userConsult[1] then
								vRP.execute("homes/removePermissions",{ name = homeName, user_id = nuser_id })
							end
					
							vRP.execute("homes/updateOwner",{ name = homeName, user_id = user_id, nuser_id = nuser_id })
							TriggerClientEvent("Notify",source,"sucesso","Transferencia da residência para <b>"..identity["name"].." "..identity["firstname"].."</b> concluída.",5000)
						else
							TriggerClientEvent("Notify",source,"negado","Passaporte inválido.",5000)
						end
					end
				elseif action == "addchave" then 
					local nplayer = vRP.prompt(source, "Insira o passaporte que deseja adicionar em sua residência")
					if nplayer and nplayer ~= "" and parseInt(nplayer) > 0 and vRP.getUserSource(parseInt(nplayer)) then 
						local nuser_id = parseInt(nplayer)
						local identity = vRP.getUserIdentity(nuser_id)
						if identity then
						--[[local maxHomes = vRP.query("homes/countUsers",{ user_id = user_id })
							local myHomes = vRP.query("homes/countHouses",{ user_id = user_id })[1]["houses"]
							if parseInt(maxHomes[1]["qtd"]) >= myHomes then
								TriggerClientEvent("Notify",source,"negado","Atingiu o máximo de residências.",3000)
								return
							end]]
					
							
							local homesCount = vRP.query("homes/countPermissions",{ name = homeName })
							if homesCount[1]["qtd"] >= consult[1]["residents"] then
								TriggerClientEvent("Notify",source,"negado","Atingiu o máximo de moradores.",5000)
								return
							end
				
							local newConsult = vRP.query("homes/userPermissions",{ user_id = nuser_id, name = homeName })
							if newConsult[1] then
								TriggerClientEvent("Notify",source,"importante","<b>"..identity["name"].." "..identity["firstname"].."</b> já pertence a residência.",5000)
							else
								if (ResidenceTypes[homeName] == "Apartamento" or (homeName):find "Apartamento") then 
									vRP.execute("vRP/secondOwnerAP",{ user_id = nuser_id, name = homeName, interior = consult[1]["interior"], owner = 0, number = consult[1]["number"] })
									TriggerClientEvent("Notify",source,"sucesso","Adicionado o(a) <b>"..identity["name"].." "..identity["firstname"].."</b> a residência.",5000)
								else
									vRP.execute("homes/newPermissions",{ user_id = nuser_id, name = homeName, interior = consult[1]["interior"], owner = 0 })
									TriggerClientEvent("Notify",source,"sucesso","Adicionado o(a) <b>"..identity["name"].." "..identity["firstname"].."</b> a residência.",5000)
								end
							end
						else
							TriggerClientEvent("Notify",source,"negado","Passaporte inválido.",5000)
						end 
					end
				elseif action == "rchave" then 
					local nplayer = vRP.prompt(source, "Insira o passaporte que deseja remover de sua residência","0")
					if nplayer and nplayer ~= "" and parseInt(nplayer) > 0 then 
						local nuser_id = parseInt(nplayer)
						local identity = vRP.getUserIdentity(nuser_id)
						if identity then
							local userConsult
							if (ResidenceTypes[homeName] == "Apartamento" or (homeName):find "Apartamento") then
								userConsult = vRP.query("vRP/selectAP2",{ name = homeName, user_id = nuser_id, number = consult[1]["number"] })
							else
								userConsult = vRP.query("homes/userPermissions",{ user_id = nuser_id, name = homeName })
							end

							if userConsult[1] then
								vRP.execute("homes/removePermissions",{ name = homeName, user_id = nuser_id })
								TriggerClientEvent("Notify",source,"sucesso","Removido o(a) <b>"..identity["name"].." "..identity["firstname"].."</b> da residência.",5000)
							else
								TriggerClientEvent("Notify",source,"negado","Não foi possível encontrar o passaporte <b>"..vRP.format(nuser_id).."</b> na residência.",5000)
							end
						else
							TriggerClientEvent("Notify",source,"negado","Passaporte inválido.",5000)
						end
					end
				elseif action == "upgrade" then 
					local oldType = consult[1]["interior"]
					TriggerClientEvent("dynamic:closeSystem2", source)
					
					vCLIENT.showOptions(source,2,newInterior)
					
					local actived = {}
					RegisterServerEvent("homes:interiorCheck")
					AddEventHandler("homes:interiorCheck",function(interiorType)
						local user_id = user_id
						if not actived[user_id] then 
							actived[user_id] = true
							TriggerClientEvent("dynamic:closeSystem2", source)
							if interiorType ~= oldType then 
								if vRP.request(source, "Você deseja visitar o novo interior antes de fazer a alteração ?, recuse para prosseguir com a compra e alteração.", 6000) then 
									vCLIENT.entranceHomes(source,homeName,interiorType,false,0,true)
								else
									--[[local plyInfos = vRP.query("creative/get_users", { user_id = user_id })
									
									if plyInfos[1] and plyInfos[1]["ticketCasa"] > 0 then 
										if vRP.request(source,"Deseja atualizar o interior <b>"..interiorType.."</b> utilizando seu ticket vip ?",30) then
											if (ResidenceTypes[homeName] == "Apartamento" or (homeName):find "Apartamento") then 
												vRP.execute("vRP/updateInterior2",{ interior = interiorType, name = homeName, number = consult[1]["number"], user_id = user_id })
												TriggerClientEvent("Notify",source,"sucesso","Interior atualizado com sucesso.",6000)
												return
											else
												vRP.execute("vRP/updateInterior",{ interior = interiorType, name = homeName, user_id = user_id })
												TriggerClientEvent("Notify",source,"sucesso","Interior atualizado com sucesso.",6000)
												return
											end
										end
									end
									]]--
									if vRP.request(source, "O valor do novo interior é de <b>$"..vRP.format(newInterior[interiorType]["valor"]).."</b>, deseja comprar ?", 6000) then 
										if vRP.tryPayment(user_id,newInterior[interiorType]["valor"]) then 
											if (ResidenceTypes[homeName] == "Apartamento" or (homeName):find "Apartamento") then 
												vRP.execute("vRP/updateInterior2",{ interior = interiorType, name = homeName, number = consult[1]["number"], user_id = user_id })
												TriggerClientEvent("Notify",source,"sucesso","Interior atualizado com sucesso.",6000)
											else
												vRP.execute("vRP/updateInterior",{ interior = interiorType, name = homeName, user_id = user_id })
												TriggerClientEvent("Notify",source,"sucesso","Interior atualizado com sucesso.",6000)
											end
										else
											TriggerClientEvent("Notify",source,"negado","Dinheiro Insuficiente.",6000)
										end
									end
								end
							else
								TriggerClientEvent("Notify",source,"negado","Escolha um interior diferente do seu atual",5000)
							end
						end 		
					end)
				end
			end
			
			if action == "trancar" then 
				if consult[1] then 
					if (ResidenceTypes[homeName] == "Apartamento" or (homeName):find "Apartamento") then
						return 
					end

					if homeLock[homeName] then
						homeLock[homeName] = nil
						TriggerClientEvent("Notify",source,"amarelo","Trancada.",3000)
					else
						homeLock[homeName] = true
						TriggerClientEvent("Notify",source,"amarelo","Destrancada.",3000)
					end
				end
			end


		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYERSPAWN
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("vRP:playerSpawn",function(user_id,source)
	local query = vRP.query("homes/get_casas",{})
	for k,v in pairs(query) do 
		homes[v["name"]]["green"] = true
	end

	vCLIENT.updateHomes(source,homes)
	if user_id then
		local myHomes = vRP.query("homes/userList",{ user_id = parseInt(user_id) })
		if parseInt(#myHomes) >= 1 then
			for k,v in pairs(myHomes) do		
				vCLIENT.setBlipsOwner(source,v["name"],homes[v["name"]][1],homes[v["name"]][2],homes[v["name"]][3])
				Citizen.Wait(10)
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKPERMISSIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function cO.checkPermissions(homeName,houseInterfone)
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        local vault = 0
        local oldname = homeName
        if (ResidenceTypes[oldname or homeName] == "Apartamento" or string.find(homeName,"Apartamento")) then 
            homeName = homeName..houseInterfone
        end

        local checkExist = vRP.query("homes/permissions",{ name = oldname })
        if checkExist[1] then
            local consult = vRP.query("homes/userPermissions",{ name = oldname, user_id = user_id })
            if consult[1] or vRP.hasPermission(user_id,"policia.permissao") then
				vault = consult[1].vault
                if consult[1].vault == 1 then vault = newInterior[tostring(consult[1].interior)]["vault"] end
                
                return true
            else
                if not homeLock[homeName] then
                    TriggerClientEvent("Notify",source,"negado","Trancada.",3000)
                else
                    return true
                end
            end
        end
        return false
    end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- ROUPAS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("homes:clotheSystem")
AddEventHandler("homes:clotheSystem",function(action)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id and homeEnter[user_id] then
		local basic = vRP.getSData("wardrobe:"..user_id)
		local consult = json.decode(basic) or {}
		if action == "save" then
			TriggerClientEvent("dynamic:closeSystem2", source)
			local custom = vRPC.getCustomPlayer(source)
			local nameFit = vRP.prompt(source, "Insira o nome do outfit.", "")
			if nameFit ~= "" then 
				if consult[nameFit] == nil and string.len(nameFit) > 0 then
					consult[nameFit] = custom
					vRP.setSData("wardrobe:"..user_id,json.encode(consult))

					TriggerClientEvent("Notify",source,"sucesso","Outfit <b>"..nameFit.."</b> adicionado.",5000)
				else
					TriggerClientEvent("Notify",source,"amarelo","Outfit escolhido já existe em seu armário de roupas.",5000)
				end
			end
		elseif action == "delete" then 
			TriggerClientEvent("dynamic:closeSystem2", source)
			local nameFit = vRP.prompt(source, "Insira o nome do outfit.", "")
			if nameFit ~= "" then 
				if consult[nameFit] ~= nil and string.len(nameFit) > 0 then
					consult[nameFit] = nil
					vRP.setSData("wardrobe:"..user_id,json.encode(consult))
					TriggerClientEvent("Notify",source,"sucesso","Outfit <b>"..nameFit.."</b> removido.",5000)
				else
					TriggerClientEvent("Notify",source,"negado","Outfit escolhido não existe em seu armário de roupas.",5000)
				end
			end
		else
			if consult[action] ~= nil and string.len(action) > 0 then
				TriggerClientEvent("updateRoupas",source,consult[action])
				TriggerClientEvent("Notify",source,"sucesso","Outfit <b>"..action.."</b> aplicado.",5000)
			else
				TriggerClientEvent("Notify",source,"negado","Outfit escolhido não existe em seu armário de roupas.",5000)
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RETURN CLOTHES
-----------------------------------------------------------------------------------------------------------------------------------------
cO.myClothes = function()
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id and homeEnter[user_id] then
		local basic = vRP.getSData("wardrobe:"..user_id)
		local consult = json.decode(basic) or {}
		return consult
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVADIR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("invadir",function(source,args,rawCommand)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		if vRP.hasPermission(user_id,"policia.permissao") then
			local homeName = nearestHomes(source)
			if homeName then
				if args[1] then 
					enterHomes(source,homeName,false,args[1])
				else
					enterHomes(source,homeName,false)
				end
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- APPLYHOUSEOPEN
-----------------------------------------------------------------------------------------------------------------------------------------
function cO.applyHouseOpen(homeName)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		homeEnter[user_id] = homeName
		vRPclient.playerHomeReady(source,true)
		vCLIENT.saveEnterExit(source,homes[homeEnter[user_id]][1],homes[homeEnter[user_id]][2],homes[homeEnter[user_id]][3])
	end
end


-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEHOUSEOPEN
-----------------------------------------------------------------------------------------------------------------------------------------
function cO.removeHouseOpen()
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		if homeEnter[user_id] then
			SetPlayerRoutingBucket(source, 0)
			homeEnter[user_id] = nil
			vRPclient.playerHomeReady(source,false)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ENTER HOMES
-----------------------------------------------------------------------------------------------------------------------------------------
function enterHomes(source,homeName,status,user)
	if (ResidenceTypes[homeName] == "Apartamento" or (homeName):find "Apartamento") then 
		local checkExist = vRP.query("homes/userPermissions",{ name = homeName, user_id = parseInt(user) })
		if checkExist[1] then
			homesInterior[homeName] = checkExist[1]["interior"]
			vCLIENT.entranceHomes(source,homeName,homesInterior[homeName],status,checkExist[1]["number"])
			return
		end
	end
	
	local checkExist = vRP.query("homes/permissions",{ name = homeName })
	if checkExist[1] then
		homesInterior[homeName] = checkExist[1]["interior"]
	else
		if homesInterior[homeName] == nil then
			homesInterior[homeName] = newInterior[math.random(#newInterior)]["interior"]
		end
	end

	vCLIENT.entranceHomes(source,homeName,homesInterior[homeName],status)
end

function cO.openVault(homeName,houseInterfone)
	local source = source 
	local user_id = vRP.getUserId(source)
	if user_id then 
		local checkInfos = vRP.query("homes/permissions",{ name = homeName })
		local vault = 0
		if (ResidenceTypes[oldname or homeName] == "Apartamento" or string.find(homeName,"Apartamento")) then 
			homeName = homeName..houseInterfone
		end

		if checkInfos[1] then
			vault = parseInt(checkInfos[1].vault)
			if vault == 1 then 
				vault = newInterior[tostring(checkInfos[1].interior)]["vault"]
			end
		--	inv.openHomeChest(source,user_id,homeName,vault)
			-- comunicação com inventário. a fazer.
			TriggerClientEvent("dz:chesthomes", source, homeName,vault)--housename, housename, parseInt(Config.homesList[housename].vault_weight))
		end
	end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- THREAD UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	Citizen.Wait(10000)
	vCLIENT.updateHomes(-1,homes)
end)


-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYERLEAVE
-----------------------------------------------------------------------------------------------------------------------------------------

AddEventHandler("vRP:playerLeave",function(user_id,source)
	if homeEnter[user_id] then
		vRP.updateHomes(user_id,homes[homeEnter[user_id]][1],homes[homeEnter[user_id]][2],homes[homeEnter[user_id]][3])
		Wait(500)		
		homeEnter[user_id] = nil
		vRPclient.playerHomeReady(source,false)
	end
end)
local actived = {}
local blipHomes = {}

-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKINTPERMISSIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function cO.checkIntPermissions(homeName)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		if not vRP.searchReturn(source,user_id) then
			local myResult = vRP.query("homes/get_homeuser",{ user_id = parseInt(user_id), home = tostring(homeName) })
			if myResult[1] or vRP.hasPermission(user_id,"policia.permissao") then
				return true
			end
		end
	end
	return false
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- ACTIVEDOWNTIME
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(2000)
		for k,v in pairs(actived) do
			if v > 0 then
				actived[k] = v - 2
				if v == 0 then
					actived[k] = nil
				end
			end
		end
	end
end)
----------------------------------------------------------------------------------------------------------------------------------------
-- OPENCHEST
-----------------------------------------------------------------------------------------------------------------------------------------
function cO.openChest(homeName)
	local source = source
	local user_id = vRP.getUserId(source)
	 local vault = 0
        local oldname = homeName
		 local checkExist = vRP.query("homes/permissions",{ name = oldname })
		  local consult = vRP.query("homes/userPermissions",{ name = oldname, user_id = user_id })
		--  TriggerClientEvent("dz:chesthomes", source, homeName, homeName, parseInt(consult[1].vault))
		  TriggerClientEvent('mirt1n:myHouseChest', source, homeName, homeName, parseInt(consult[1].vault))

	return false
end

function cO.getDayHours(seconds)
    local days = math.floor(seconds/86400)
    seconds = seconds - days * 86400
    local hours = math.floor(seconds/3600)

    if days > 0 then
        return string.format("<b>%d Dias</b> e <b>%d Horas</b>",days,hours)
    else
        return string.format("<b>%d Horas</b>",hours)
    end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- STOREITEM
-----------------------------------------------------------------------------------------------------------------------------------------
function cO.storeItem(homeName,itemName,amount)
	local source = source
	if itemName then
		local user_id = vRP.getUserId(source)
		local identity = vRP.getUserIdentity(user_id)
		 local vault = 0
        local oldname = homeName
		 local checkExist = vRP.query("homes/permissions",{ name = oldname })
		  local consult = vRP.query("homes/userPermissions",{ name = oldname, user_id = user_id })
		if user_id and actived[parseInt(user_id)] == 0 or not actived[parseInt(user_id)] then
			if string.match(itemName,"identidade") then
				TriggerClientEvent("Notify",source,"importante","Não pode guardar este item.",8000)
				return
			end

			local data = vRP.getSData("chest:"..tostring(homeName))
			local items = json.decode(data) or {}
			if items then
				if parseInt(amount) > 0 then
					local new_weight = vRP.computeItemsWeight(items)+vRP.getItemWeight(itemName)*parseInt(amount)
					if new_weight <= consult[1].vault then
						if vRP.tryGetInventoryItem(parseInt(user_id),itemName,parseInt(amount)) then
							SendWebhookMessage(webhookbaucasas,"```prolog\n[ID]: "..user_id.." "..identity.name.." "..identity.firstname.." \n[GUARDOU]: "..vRP.format(parseInt(amount)).." "..vRP.itemNameList(itemName).." \n[BAU]: "..(tostring(homeName)).." "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")
							if items[itemName] ~= nil then
								items[itemName].amount = parseInt(items[itemName].amount) + parseInt(amount)
							else
								items[itemName] = { amount = parseInt(amount) }
							end
							actived[parseInt(user_id)] = 2
						end
					else
						TriggerClientEvent("Notify",source,"negado","<b>bau</b> cheio.",8000)
					end
				else
					local inv = vRP.getInventory(parseInt(user_id))
					for k,v in pairs(inv) do
						if itemName == k then
							local new_weight = vRP.computeItemsWeight(items)+vRP.getItemWeight(itemName)*parseInt(v.amount)
							if new_weight <= consult[1].vault then
								if vRP.tryGetInventoryItem(parseInt(user_id),itemName,parseInt(v.amount)) then
									if items[itemName] ~= nil then
										items[itemName].amount = parseInt(items[itemName].amount) + parseInt(v.amount)
									else
										items[itemName] = { amount = parseInt(v.amount) }
									end
									SendWebhookMessage(webhookbaucasas,"```prolog\n[ID]: "..user_id.." "..identity.name.." "..identity.firstname.." \n[GUARDOU]: "..vRP.format(parseInt(v.amount)).." "..vRP.itemNameList(itemName).." \n[BAU]: "..(tostring(homeName)).." "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")
									actived[parseInt(user_id)] = 2
								end
							else
								TriggerClientEvent("Notify",source,"negado","<b>bau</b> cheio.",8000)
							end
						end
					end
				end
				vRP.setSData("chest:"..tostring(homeName),json.encode(items))
				TriggerClientEvent('Creative:Updatebau',source,'updatebau')
			end
		end
	end
	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAKEITEM
-----------------------------------------------------------------------------------------------------------------------------------------
local bau = false
function cO.takeItem(homeName,itemName,amount)
	local source = source
	if itemName then
		local user_id = vRP.getUserId(source)
		local identity = vRP.getUserIdentity(user_id)
		if user_id and actived[parseInt(user_id)] == 0 or not actived[parseInt(user_id)] then
			local data = vRP.getSData("chest:"..tostring(homeName))
			local items = json.decode(data) or {}
			if items then
			
			
				if parseInt(amount) > 0 then
					if items[itemName] ~= nil and parseInt(items[itemName].amount) >= parseInt(amount) then
						if vRP.getInventoryWeight(parseInt(user_id))+vRP.getItemWeight(itemName)*parseInt(amount) <= vRP.getInventoryMaxWeight(parseInt(user_id)) then
						TriggerClientEvent("bau:fechar",source)
							pedidos = false
							local pedido = vRP.request(source, "Deseja pegar este item?", 6)
						
						if pedido  and pedidos == false then
							pedidos = true
							SendWebhookMessage(webhookbaucasas,"```prolog\n[ID]: "..user_id.." "..identity.name.." "..identity.firstname.." \n[RETIROU]: "..vRP.format(parseInt(amount)).." "..vRP.itemNameList(itemName).." \n[BAU]: "..(tostring(homeName)).." "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")
							items[itemName].amount = parseInt(items[itemName].amount) - parseInt(amount)
							vRP.giveInventoryItem(parseInt(user_id),itemName,parseInt(amount))
						TriggerClientEvent('Creative:UpdateVault',source,'updateVault')
				       vRP.setSData("chest:"..tostring(homeName),json.encode(items))
							
							if parseInt(items[itemName].amount) <= 0 then
								items[itemName] = nil
							end
							
							actived[parseInt(user_id)] = 2
							Wait(6000) -- pausa de 5 segundos
							pedidos = false
	
						else
						TriggerClientEvent("Notify",source,"negado","<b>Espere 6 segundos.",8000)
						end
						else
							TriggerClientEvent("Notify",source,"negado","<b>Mochila</b> cheia.",8000)
						end
					end
				else
				
					TriggerClientEvent("bau:fechar",source)
					TriggerClientEvent("Notify",source,"negado","<b>Insira a quantidades",8000)
				end
				TriggerClientEvent('Creative:UpdateVault',source,'updateVault')
				vRP.setSData("chest:"..tostring(homeName),json.encode(items))
				
			end
		end
	end
	return false
end


	
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKPOLICE
-----------------------------------------------------------------------------------------------------------------------------------------
function cO.checkPolice()
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		if vRP.hasPermission(user_id,"policia.permissao") then
			return true
		end
		return false
	end
end

RegisterNetEvent("dPN:inventario:RequestVault")
AddEventHandler("dPN:inventario:RequestVault",function(user_id,house)
	if house then
		if homes[house] then
			TriggerEvent('dPN:inventario:returAmountVault',user_id,homes[house])
		end
	end
end)

