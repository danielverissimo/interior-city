local Proxy = module("lib/Proxy")
local Tunnel = module("lib/Tunnel")

local config = module("cfg/base")

vRP = {}
Proxy.addInterface("vRP",vRP)

tvRP = {}
Tunnel.bindInterface("vRP",tvRP)
vRPclient = Tunnel.getInterface("vRP")
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TABELAS TEMPORÁRIAS
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
vRP.users = {}
vRP.rusers = {}
vRP.user_tables = {}
vRP.user_appareance = {}
vRP.user_tmp_tables = {}
vRP.user_sources = {}
vRP.user_through_src = {}
vRP.tempSource = {}
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PREPARE
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local prepared_queries = {}
local GeneratingCache = false 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PREPARE
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function vRP.prepare(name,query)
	prepared_queries[name] = query
end
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- QUERY
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function vRP.query(name,params,mode)
	return exports["oxmysql"]:query_async(prepared_queries[name],params)
end
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EXECUTE
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function vRP.execute(name,params)
	exports["oxmysql"]:query(prepared_queries[name],params)
end
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- BASE.LUA
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function vRP.setUData(user_id,key,value)
	exports["oxmysql"]:executeSync([[
		REPLACE INTO `vrp_user_data`(`user_id`,`dkey`,`dvalue`) VALUES(?,?,?)
	]],{ 
		user_id,key,value
	})
    if tostring(key or "") ~= "vRP:datatable" and type(vRP.mageAuditLog) == "function" then
        vRP.mageAuditLog("vrp_userdata_set", {
            actorId = tonumber(user_id),
            actorLabel = "JOGADOR AFETADO",
            details = ("**Resource:** %s\n**Função:** vRP.setUData\n**Chave:** %s\n**Tamanho do valor:** %d byte(s)"):format(
                vRP.mageAuditOrigin(), tostring(key or ""), #tostring(value or "")
            )
        })
    end
end

function vRP.getUData(user_id,key,cbr)
	local rows = exports["oxmysql"]:singleSync("SELECT `dvalue` FROM `vrp_user_data` WHERE `user_id` = ? AND `dkey` = ? ", { user_id,key })
	if rows then 
		return rows.dvalue
	end
	return ""
end

function vRP.remUData(user_id,key)
	vRP.execute("vRP/rem_u_data",{ user_id = parseInt(user_id), key = key })
    if type(vRP.mageAuditLog) == "function" then
        vRP.mageAuditLog("vrp_userdata_removed", {
            actorId = tonumber(user_id),
            actorLabel = "JOGADOR AFETADO",
            details = ("**Resource:** %s\n**Função:** vRP.remUData\n**Chave removida:** %s"):format(
                vRP.mageAuditOrigin(), tostring(key or "")
            )
        })
    end
end

function vRP.setSData(key,value)
	exports["oxmysql"]:executeSync([[
		REPLACE INTO `vrp_srv_data`(`dkey`,`dvalue`) VALUES(?,?)
	]],{ 
		key,value
	})
end

function vRP.getSData(key, cbr)
	local rows = exports["oxmysql"]:singleSync("SELECT `dvalue` FROM `vrp_srv_data` WHERE `dkey` = ?", { key })
	if rows then 
		return rows.dvalue
	end
	return ""
end

function vRP.getSDataKeys()
    local rows = exports["oxmysql"]:executeSync("SELECT `dkey` FROM `vrp_srv_data`", {})
    local keys = {}
    for _, row in ipairs(rows) do
        table.insert(keys, row.dkey)
    end
    return keys
end

function vRP.getUsers()
	local users = {}
	for k, v in pairs(vRP.user_sources) do
		users[k] = v
	end
	return users
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CAPTURAR IDENTIFIERS
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
vRP.prepare("vRP/getAllIdentifiers", "SELECT * FROM vrp_user_ids")

local identifier = {
	cache = {}
}

function identifier:createCache()
	local rows = vRP.query("vRP/getAllIdentifiers", {})
	for i = 1, #rows do
		if not self.cache[rows[i].user_id] then self.cache[rows[i].user_id] = {} end
		self.cache[rows[i].user_id][#self.cache[rows[i].user_id] + 1] = rows[i].identifier
	end

	GeneratingCache = true
end

function identifier:set(identifier, user_id)
	if not self.cache[user_id] then self.cache[user_id] = {} end

	self.cache[user_id][#self.cache[user_id] + 1] = identifier
end

function identifier:remove(identifier, user_id)
    if self.cache[user_id] then
        for i, id in ipairs(self.cache[user_id]) do
            if id == identifier then
                table.remove(self.cache[user_id], i)
                print(("Identificador %s removido do usuário %d."):format(identifier, user_id))
                return
            end
        end
    end
end

function identifier:Format(ids)
	local output = {}
	for i = 1, #ids do 
		local id = ids[i]
		if not id:find('ip:') then
			output[id] = true
		end
	end

	return output
end

function vRP.getUserIdByIdentifiers(ids)
	if ids and #ids then
		
		local identifiers = identifier:Format(ids) 
		local UserIdentifier = {}
		for user_id, identifier in pairs(identifier.cache) do
			for i = 1, #identifier do
				if identifiers[identifier[i]] then
					UserIdentifier[#UserIdentifier + 1] = user_id
				end
			end
		end

		if #UserIdentifier > 0 then		
			return math.min(table.unpack(UserIdentifier))
		end
		

		local rows = exports["oxmysql"]:executeSync([[INSERT INTO vrp_users(whitelist) VALUES(false)]])
		if rows then
			local user_id = rows.insertId

			for l,w in pairs(ids) do
				if (string.find(w,"ip:") == nil) then
					vRP.execute("vRP/add_identifier",{ user_id = user_id, identifier = w })
					identifier:set(w, user_id)
				end
			end

			vRP.execute("vRP/init_users_infos",{ user_id = user_id })
			TriggerEvent("vRP/new_user_created", user_id)
			return user_id
		end
	end
end

function vRP.getUserIdByIdentifier(ids) -- MQCU
	local rows = vRP.query("vRP/userid_byidentifier",{ identifier = ids})
	if #rows > 0 then
		return rows[1].user_id
	else
		return -1
	end
end

exports("updateIdentifier", function(...)
	identifier:set(...)
end)

exports("removeIdentifier", function(...)
    identifier:remove(...)
end)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SISTEMA DE WHITELIST
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function vRP.isWhitelisted(user_id)
	local rows = vRP.query("vRP/get_whitelisted",{ user_id = user_id })
	if #rows > 0 then
		return rows[1].whitelist
	else
		return false
	end
end

function vRP.setWhitelisted(user_id,whitelisted)
    local rawBefore = vRP.isWhitelisted(user_id)
    local before = rawBefore == true or tonumber(rawBefore) == 1
    local after = whitelisted == true or tonumber(whitelisted) == 1
    vRP.execute("vRP/set_whitelisted",{ user_id = user_id, whitelist = after })
    if type(vRP.mageAuditLog) == "function" and before ~= after then
        vRP.mageAuditLog("vrp_whitelist_set", {
            actorId = tonumber(user_id),
            actorLabel = "JOGADOR AFETADO",
            details = ("**Resource:** %s\n**Antes:** %s\n**Depois:** %s"):format(
                vRP.mageAuditOrigin(), before and "Liberada" or "Bloqueada", after and "Liberada" or "Bloqueada"
            )
        })
    end
end

function vRP.kick(source,reason)
    local user_id = vRP.getUserId(source)
    if type(vRP.mageAuditLog) == "function" then
        vRP.mageAuditLog("vrp_player_kick", {
            actorId = tonumber(user_id),
            actorName = GetPlayerName(source),
            actorLabel = "JOGADOR AFETADO",
            details = ("**Resource:** %s\n**Source:** %s\n**Motivo:** %s"):format(
                vRP.mageAuditOrigin(), tostring(source), tostring(reason or "Não informado")
            )
        })
    end
	DropPlayer(source,reason)
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FUNCTION GERAIS
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function vRP.getUserDataTable(user_id)
	return vRP.user_tables[user_id]
end

function vRP.getUserApparence(user_id)
	return vRP.user_appareance[user_id]
end

function vRP.getUserTmpTable(user_id)
	return vRP.user_tmp_tables[user_id]
end

function vRP.getUserId(source)
	if source ~= nil then
		if vRP.user_through_src[source] then 
			return vRP.user_through_src[source]
		end
		local ids = GetPlayerIdentifiers(source)
		if ids ~= nil and #ids > 0 then
			return vRP.users[ids[1]]
		end
	end
	return nil
end

function vRP.getUserSource(user_id)
	return vRP.user_sources[user_id]
end

function vRP.updateUserApparence(user_id, name, value)
	if vRP.user_appareance[user_id] then
		vRP.user_appareance[user_id][name] = value
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Sistema do Inventario
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function vRP.getInventory(user_id)
	local data = vRP.user_tables[user_id]
	if data then
		return data.inventory
	end
	return false
end

-- RegisterNetEvent('playerJoining')
AddEventHandler('playerJoining', function(tempId)
	local src = source
	SetPlayerRoutingBucket(src, src)
	local tempId = tonumber(tempId)
	if vRP.user_through_src[tempId] then 
		vRP.user_through_src[src] = vRP.user_through_src[tempId]
		vRP.user_through_src[tempId] = nil
	end
end)

AddEventHandler("playerJoining", function(old_source)
	old_source = parseInt(old_source)

	local source = source

	local plyId = vRP.tempSource[old_source]
	if not plyId then return end

	vRP.user_sources[plyId] = source
	vRP.tempSource[old_source] = nil
end)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- HWID SYSTEM
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
vRP.prepare("getAllTokens", "SELECT token,id FROM mirtin_bans_hwid")
vRP.prepare("mirtin_bans/getUserBans", "SELECT user_id,banimento,desbanimento,motivo FROM mirtin_bans WHERE user_id = @user_id")
vRP.prepare("mirtin_bans/addToken","INSERT IGNORE INTO mirtin_bans_hwid(id,token) VALUES(@user_id,@token)")

local geral = {
	logo = module("vrp", "lib/branding").logo(), -- LOGO do Servidor
    background = "https://cdn.discordapp.com/attachments/403296672748142595/875522538510368858/download_1.jpg", -- Fundo da Tela de banimento
    discord = "https://discord.gg/", -- Discord do Servidor (Colocar https://)

    color = 6356736, -- Cor da Lateral do WeebHook
    footer = "© CIDADE TocadoMagoDelux", -- RODAPE do WeebHook

    whookHWIDlogin = GetConvar("ic_secret_vrp_webhook", GetConvar("interior_city_webhook_logs", "")), -- WEEBHOOK para quando o estiver banido HWID e logar com outra conta.
}

local hwid = {
	list = {}
}

function hwid:createCache()
	local query = vRP.query("getAllTokens", {})

	if query then
		for i = 1, #query do
			self.list[query[i].token] = query[i].id
		end
	end
end

function hwid:getUserTokens(src)
	local numTokens = GetNumPlayerTokens(src)
	local tokens = {}
	for i = 0, numTokens - 1 do
		tokens[i] = GetPlayerToken(src, i)
	end

	return tokens
end

function getProxy()
	return Proxy
  end
  

function hwid:checkBanned(src, user_id)
	local tokens = hwid:getUserTokens(src)
	for i = 1, #tokens do
		if self.list[tokens[i]] then
			if self.list[tokens[i]] ~= user_id then
				local query = vRP.query("mirtin_bans/getUserBans", { user_id = self.list[tokens[i]] })
				if query and #query > 0 then
					vRP.execute("mirtin/insertBanned", { user_id = user_id, motivo = "Banido HWID! ID ANTIGO: "..self.list[tokens[i]], banimento = os.date("%d/%m/%Y as %H:%M"), desbanimento = "Nunca", time = 0, hwid = 0 })

					local card = '{ "type": "AdaptiveCard", "$schema": "http://adaptivecards.io/schemas/adaptive-card.json", "version": "1.3", "body": [ { "type": "Image", "url": "'..geral['logo']..'", "spacing": "Large", "size": "Large", "horizontalAlignment": "Center" }, { "type": "Container", "separator": true, "items": [ { "type": "TextBlock", "text": "Você está banido da cidade.", "wrap": true, "fontType": "Default", "weight": "Bolder", "color": "Attention", "size": "Large", "horizontalAlignment": "Center", "spacing": "None" } ] }, { "type": "TextBlock", "text": "Seu ID: '..user_id..'", "wrap": true, "size": "Medium", "color": "Warning", "fontType": "Default", "weight": "Bolder" }, { "type": "TextBlock", "text": "Motivo: Você foi banido no ID: '.. self.list[tokens[i]] ..'", "wrap": true, "size": "Medium", "color": "Warning", "weight": "Bolder" }, { "type": "TextBlock", "text": "Data do Banimento: '.. os.date("%d/%m/%Y") ..'", "wrap": true, "weight": "Bolder", "color": "Warning", "size": "Medium" }, { "type": "TextBlock", "text": "Data do Desbanimento: '.. query[1].desbanimento ..'", "wrap": true, "size": "Medium", "weight": "Bolder", "color": "Warning" }, { "type": "Container", "separator": true }, { "type": "ActionSet", "actions": [ { "type": "Action.OpenUrl", "title": "Acesse o Discord", "url": "'..geral['discord']..'", "iconUrl": "https://discord.com/assets/3437c10597c1526c3dbd98c737c2bcae.svg" } ] } ], "minHeight": "200px", "backgroundImage": { "url": "'..geral['background']..'" } }'
					local corpoBan = { { ["color"] = geral['color'], ["title"] = "**".. ":no_entry: BAN HWID | Tentativa de Login " .."**\n", ["thumbnail"] = geral['logo']:match("^https://") and { ["url"] = geral['logo'] } or nil, ["description"] = "**ID NOVO:**\n```cs\n"..user_id.."```\n**ID ANTIGO: **\n```cs\n"..self.list[tokens[i]].."```\n**Data:** ```cs\n "..os.date("%d/%m/%Y as %H:%M").."``` ", ["footer"] = { ["text"] = geral['footer'], }, } }
					if geral["whookHWIDlogin"] ~= "" then
					PerformHttpRequest(geral['whookHWIDlogin'], function(err, text, headers) end, 'POST', json.encode({embeds = corpoBan}), { ['Content-Type'] = 'application/json' })
					end

					return true, card
				end
			end
		else
			vRP.execute("mirtin_bans/addToken", { user_id = user_id, token = tokens[i] })
			self.list[tokens[i]] = user_id
		end
	end

	local query = vRP.query("mirtin_bans/getUserBans", { user_id = user_id })
	if query and #query > 0 then
		local card = '{ "type": "AdaptiveCard", "$schema": "http://adaptivecards.io/schemas/adaptive-card.json", "version": "1.3", "body": [ { "type": "Image", "url": "'..geral['logo']..'", "spacing": "Large", "size": "Large", "horizontalAlignment": "Center" }, { "type": "Container", "separator": true, "items": [ { "type": "TextBlock", "text": "Você está banido da cidade.", "wrap": true, "fontType": "Default", "weight": "Bolder", "color": "Attention", "size": "Large", "horizontalAlignment": "Center", "spacing": "None" } ] }, { "type": "TextBlock", "text": "Seu ID: '..user_id..'", "wrap": true, "size": "Medium", "color": "Warning", "fontType": "Default", "weight": "Bolder" }, { "type": "TextBlock", "text": "Motivo: '..query[1].motivo..'", "wrap": true, "size": "Medium", "color": "Warning", "weight": "Bolder" }, { "type": "TextBlock", "text": "Data do Banimento: '..query[1].banimento..'", "wrap": true, "weight": "Bolder", "color": "Warning", "size": "Medium" }, { "type": "TextBlock", "text": "Data do Desbanimento: '..query[1].desbanimento..'", "wrap": true, "size": "Medium", "weight": "Bolder", "color": "Warning" }, { "type": "Container", "separator": true }, { "type": "ActionSet", "actions": [ { "type": "Action.OpenUrl", "title": "Acesse o Discord", "url": "'..geral['discord']..'", "iconUrl": "https://discord.com/assets/3437c10597c1526c3dbd98c737c2bcae.svg" } ] } ], "minHeight": "200px", "backgroundImage": { "url": "'..geral['background']..'" } }'	
		return true, card
	end

	return false
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- IPS CACHE
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
vRP.prepare("getAllIps", "SELECT user_id,ip FROM mirtin_bans_ip")

local Ips = {
	list = {}
}

function Ips:CreateCache()
	local query = vRP.query("getAllIps", {})

	if query then
		for i = 1, #query do
			self.list[query[i].ip] = query[i].user_id
		end
	end
end

function Ips:GetIp(user_id, ip)
	if self.list[ip] then
		local card = '{ "type": "AdaptiveCard", "$schema": "http://adaptivecards.io/schemas/adaptive-card.json", "version": "1.3", "body": [ { "type": "Image", "url": "'..geral['logo']..'", "spacing": "Large", "size": "Large", "horizontalAlignment": "Center" }, { "type": "Container", "separator": true, "items": [ { "type": "TextBlock", "text": "Você está banido da cidade.", "wrap": true, "fontType": "Default", "weight": "Bolder", "color": "Attention", "size": "Large", "horizontalAlignment": "Center", "spacing": "None" } ] }, { "type": "TextBlock", "text": "Seu ID: '..user_id..'", "wrap": true, "size": "Medium", "color": "Warning", "fontType": "Default", "weight": "Bolder" }, { "type": "TextBlock", "text": "Motivo: Você foi banido no ID: '.. self.list[ip] ..'", "wrap": true, "size": "Medium", "color": "Warning", "weight": "Bolder" }, { "type": "TextBlock", "text": "Data do Banimento: Indefinido (2.0)", "wrap": true, "weight": "Bolder", "color": "Warning", "size": "Medium" }, { "type": "TextBlock", "text": "Data do Desbanimento: Nunca", "wrap": true, "size": "Medium", "weight": "Bolder", "color": "Warning" }, { "type": "Container", "separator": true }, { "type": "ActionSet", "actions": [ { "type": "Action.OpenUrl", "title": "Acesse o Discord", "url": "'..geral['discord']..'", "iconUrl": "https://discord.com/assets/3437c10597c1526c3dbd98c737c2bcae.svg" } ] } ], "minHeight": "200px", "backgroundImage": { "url": "'..geral['background']..'" } }'
		vRP.execute("mirtin/insertBanned", { user_id = user_id, motivo = "Banido HWID 2.0! ID ANTIGO: "..self.list[ip], banimento = os.date("%d/%m/%Y as %H:%M"), desbanimento = "Nunca", time = 0, hwid = 1 })
		return true, card
	end
end

function Ips:AddIp(user_id, ip)
	self.list[ip] = user_id
end

vRP.prepare("mirtin/insertBanned/base","INSERT IGNORE INTO mirtin_bans(user_id,motivo,desbanimento,banimento,time, hwid, owner,staff) VALUES(@user_id,@motivo,@desbanimento,@banimento,@time, @hwid, @owner,@staff)")
function vRP.setBanned(user_id,status, reason, time, verme,staffBan)
	if time and tostring(time) == "Likizao-AC" then
		reason = "Cheat"
		time = 0
	end
	if not time then
		time = 0
	end
	if user_id then
		vRP.execute("mirtin/insertBanned/base", { user_id = user_id, motivo = reason, banimento = os.date("%d/%m/%Y as %H:%M"), desbanimento = time > 0 and os.date("%d/%m/%Y as %H:%M", time) or "Nunca", time = time, hwid = 0, owner = verme and 1 or 0,  staff = staffBan and staffBan or 0 })
        if type(vRP.mageAuditLog) == "function" then
            local details = {
                ("**Resource:** %s"):format(vRP.mageAuditOrigin()),
                ("**Motivo:** %s"):format(tostring(reason or "Não informado")),
                ("**Status/IP:** %s"):format(tostring(status and true or false)),
                ("**Expiração:** %s"):format(tonumber(time) and tonumber(time) > 0 and os.date("%d/%m/%Y às %H:%M:%S", tonumber(time)) or "Nunca"),
                ("**Ban HWID/Owner:** %s"):format(tostring(verme and true or false)),
                ("**Staff informado:** %s"):format(tostring(staffBan or "-"))
            }
            vRP.mageAuditLog("vrp_player_banned", {
                actorId = tonumber(user_id),
                actorLabel = "JOGADOR AFETADO",
                details = table.concat(details, "\n")
            })
        end
	end

	if status then
		local query = vRP.query("mirtin_bans/GetBanIp", { user_id = user_id })
		if #query > 0 then
			local ip = (query[1].ip or "0.0.0.0")
			vRP.execute("mirtin_bans/SetBanIP", { user_id = user_id, ip = ip })
			Ips:AddIp(user_id, ip)
		end
	end
end 

function vRP.removeBanIp(user_id)
    local removed = {}
	for ip, ply_id in pairs(Ips.list) do
		if user_id == ply_id then
            removed[#removed + 1] = tostring(ip)
			Ips.list[ip] = nil
		end
	end
    if #removed > 0 and type(vRP.mageAuditLog) == "function" then
        vRP.mageAuditLog("vrp_ban_ip_removed", {
            actorId = tonumber(user_id),
            actorLabel = "JOGADOR AFETADO",
            details = ("**Resource:** %s\n**IP(s) removido(s):** %s"):format(
                vRP.mageAuditOrigin(), table.concat(removed, ", ")
            )
        })
    end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- IC Admin: operações server-side autenticadas atualizam caches após commit SQL.
exports('icAdminRefreshBanCaches', function()
    if GetInvokingResource() ~= 'ic_admin' then return false end
    hwid.list = {}
    Ips.list = {}
    hwid:createCache()
    Ips:CreateCache()
    return true
end)
exports('icAdminForgetUser', function(userId)
    if GetInvokingResource() ~= 'ic_admin' then return false end
    userId = tonumber(userId)
    if not userId or vRP.getUserSource(userId) then return false end
    vRP.user_tables[userId] = nil
    vRP.user_tmp_tables[userId] = nil
    vRP.user_appareance[userId] = nil
    identifier.cache[userId] = nil
    vRP.rusers[userId] = nil
    for key, id in pairs(vRP.users) do if tonumber(id) == userId then vRP.users[key] = nil end end
    for key, id in pairs(vRP.tempSource) do if tonumber(id) == userId then vRP.tempSource[key] = nil end end
    for key, id in pairs(vRP.user_through_src) do if tonumber(id) == userId then vRP.user_through_src[key] = nil end end
    local rows = vRP.query('vRP/getAllIdentifiers', {})
    for _, row in ipairs(rows or {}) do
        if tonumber(row.user_id) == userId then identifier:set(row.identifier, userId) end
    end
    if type(vRP.icAdminClearMoneyCache) == 'function' then vRP.icAdminClearMoneyCache(userId) end
    vRP.updateIdentity(userId)
    return true
end)

-- QUEUE
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local ConfigQUEUE = {
	active = false,
	delay = 1, -- DELAY PRA PROCESSAR A FILA
}

local QUEUE = {
	List = {},
	Ply = {},

	Priority = {
		--[1] = true,
	}
}

function QUEUE:addPlayer(source,ids)
	local POS = (#self.List + 1)

	self.List[POS] = source
	self.Ply[source] = POS
	
	print(("Adicionado Source: %s na posição %s pos"):format(source, POS))
end

function QUEUE:get(source)
	return self.Ply[source] or false
end

function QUEUE:start()
	print('Iniciando Sistema de FILA')
	CreateThread(function()
		while true do
			Wait( ConfigQUEUE.delay * 1000 )
			
			if ConfigQUEUE.active then
				-- PROCESSANDO O PRIMEIRO DA FILA
				local source = QUEUE.List[1]
				if QUEUE.Ply[source] then
					QUEUE.Ply[source] = nil
				end
				QUEUE.List[1] = nil

				-- ATUALIZANDO OS JOGAODRES DA FILA
				for pos,source in pairs(QUEUE.List) do
					if QUEUE.List[pos] then
						QUEUE.List[pos] = nil

						if GetPlayerEndpoint(source) ~= nil then
							local NEW_POS = (pos - 1)
							QUEUE.List[NEW_POS] = source
							QUEUE.Ply[source] = NEW_POS
						end
					end
				end

				if #QUEUE.List > 0 then
					print(("Total de Jogadores na Fila: %s"):format(#QUEUE.List))
				end
			end
		end

		QUEUE:start()
	end)
end

RegisterCommand('updateQueue', function(source,args)
	if source > 0 then return end

	ConfigQUEUE.active = not ConfigQUEUE.active

	if not ConfigQUEUE.active then
		QUEUE.List = {}
		QUEUE.Ply = {}
	end

	print(("Fila: %s"):format(ConfigQUEUE.active and "Ativada" or "Desativada"))
end)

RegisterCommand('addPriority', function(source,args)
	if source > 0 then return end
	if not args[1] or args[1] == "" then return end

	local ply_id = parseInt(args[1])
	QUEUE.Priority[ply_id] = true

	print(("Adicionado USER_ID: %s na fila"):format(ply_id))
end)

local earlyAccessActive = false
vRP.prepare("vRP/get_early_access","SELECT * FROM early_access WHERE identifier = @identifier")
RegisterCommand("desativaracess", function(source, args, rawCommand)
    if source == 0 then
        earlyAccessActive = not earlyAccessActive
        print("Acesso antecipado agora está " .. (earlyAccessActive and "ativado" or "desativado") .. ".")
    end
end)

async(function()
	if ConfigQUEUE.active then
		QUEUE:start()
	end
end)

RegisterCommand('dsakkdmas', function(source,args)
	QUEUE:start()
end)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LOGS CENTRALIZADAS DE CONEXÃO (MAGE ADMIN)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- A vRP não possui dependência obrigatória do painel para evitar ciclo entre resources.
-- Quando o Mage Admin ainda não iniciou/reiniciou, as logs ficam em uma fila curta em memória
-- e são reenviadas assim que o export server-side voltar a ficar disponível.
local MAGE_ADMIN_LOG_RESOURCE = GetConvar("ic_admin_service_resource", "ic_admin")
local MAGE_ADMIN_LOG_QUEUE_MAX = 250
local mageAdminLogQueue = {}
local mageConnectionAudit = {}
local mageConnectionAcceptedAt = {}

local function mageTrim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function mageFormatDuration(totalSeconds)
    totalSeconds = math.max(0, math.floor(tonumber(totalSeconds) or 0))
    local hours = math.floor(totalSeconds / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = totalSeconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

local function mageIdentityName(user_id, fallback)
    fallback = mageTrim(fallback)
    if user_id and type(vRP.getUserIdentity) == "function" then
        local ok, identity = pcall(vRP.getUserIdentity, user_id)
        if ok and type(identity) == "table" then
            local first = mageTrim(identity.nome or identity.name)
            local last = mageTrim(identity.sobrenome or identity.firstname or identity.name2)
            local full = mageTrim((first .. " " .. last):gsub("%s+", " "))
            if full ~= "" then return full end
        end
    end
    return fallback ~= "" and fallback or "Desconhecido"
end

local function mageTrySendLog(entry)
    if type(entry) ~= "table" then return true end
    if GetResourceState(MAGE_ADMIN_LOG_RESOURCE) ~= "started" then return false end

    local ok, sent, reason = pcall(function()
        return exports[MAGE_ADMIN_LOG_RESOURCE]:sendLog(entry.key, entry.data)
    end)
    if not ok then return false end

    -- Webhook vazia é uma escolha de configuração do administrador: a ocorrência
    -- pode ser descartada sem retry. Já uma chave ainda não cadastrada costuma
    -- indicar que o painel está em uma versão antiga durante um restart/atualização;
    -- nesse caso mantemos a ocorrência na fila para tentar novamente depois.
    if sent == false and tostring(reason or ""):find("não cadastrado", 1, true) then
        return false
    end

    return true
end

local function mageQueueLog(logKey, data)
    local entry = {
        key = tostring(logKey or ""),
        data = type(data) == "table" and data or {}
    }
    if entry.key == "" then return false end

    if mageTrySendLog(entry) then return true end

    if #mageAdminLogQueue >= MAGE_ADMIN_LOG_QUEUE_MAX then
        table.remove(mageAdminLogQueue, 1)
        print("^3[vRP/MageLogs]^7 Fila de logs cheia; a entrada mais antiga foi descartada.")
    end
    mageAdminLogQueue[#mageAdminLogQueue + 1] = entry
    return false
end

-- API de auditoria central utilizada pelos módulos internos da vRP.
-- Mantém o resource desacoplado do painel e preserva a fila/retry acima.
local mageAuditContexts = setmetatable({}, { __mode = "k" })
local mageAuditMainContext = {}

local function mageAuditContextStack(create)
    local running = coroutine.running()
    if not running then return mageAuditMainContext end
    local stack = mageAuditContexts[running]
    if not stack and create then
        stack = {}
        mageAuditContexts[running] = stack
    end
    return stack
end

local function mageAuditOrigin()
    -- Chamadas feitas através de Proxy carregam o nome do resource chamador
    -- em um contexto por coroutine (ver lib/Proxy.lua).
    local proxyOrigins = rawget(_G, "__mageProxyAuditOrigins")
    local running = coroutine.running()
    local proxyOrigin = proxyOrigins and running and mageTrim(proxyOrigins[running]) or ""
    if proxyOrigin ~= "" and proxyOrigin ~= GetCurrentResourceName() then return proxyOrigin end

    local invoking = type(GetInvokingResource) == "function" and GetInvokingResource() or nil
    invoking = mageTrim(invoking)
    if invoking ~= "" then return invoking end

    -- Quando a chamada chega por outros caminhos, GetInvokingResource pode ser nil.
    -- Nesse caso tentamos descobrir o resource pelo chunk Lua que chamou a função.
    if debug and type(debug.getinfo) == "function" then
        for level = 3, 12 do
            local info = debug.getinfo(level, "S")
            local src = info and tostring(info.source or "") or ""
            local resource = src:match("^@([^/\\]+)/")
            if resource and resource ~= "" and resource ~= GetCurrentResourceName() then
                return resource
            end
        end
    end

    return GetCurrentResourceName() or "vrp"
end

function vRP.mageAuditOrigin()
    return mageAuditOrigin()
end

function vRP.mageAuditPush(contextName)
    local stack = mageAuditContextStack(true)
    stack[#stack + 1] = tostring(contextName or "")
end

function vRP.mageAuditPop(contextName)
    local stack = mageAuditContextStack(false)
    if not stack then return end
    local wanted = tostring(contextName or "")
    for i = #stack, 1, -1 do
        if wanted == "" or stack[i] == wanted then
            table.remove(stack, i)
            return
        end
    end
end

function vRP.mageAuditIn(contextName)
    local stack = mageAuditContextStack(false)
    if not stack then return false end
    local wanted = tostring(contextName or "")
    for i = #stack, 1, -1 do
        if stack[i] == wanted then return true end
    end
    return false
end

function vRP.mageAuditLog(logKey, data)
    data = type(data) == "table" and data or {}
    if data.occurredAt == nil then data.occurredAt = os.time() end
    return mageQueueLog(logKey, data)
end

CreateThread(function()
    while true do
        Wait(5000)
        if #mageAdminLogQueue > 0 and GetResourceState(MAGE_ADMIN_LOG_RESOURCE) == "started" then
            local pending = mageAdminLogQueue
            mageAdminLogQueue = {}

            for _, entry in ipairs(pending) do
                if not mageTrySendLog(entry) then
                    if #mageAdminLogQueue < MAGE_ADMIN_LOG_QUEUE_MAX then
                        mageAdminLogQueue[#mageAdminLogQueue + 1] = entry
                    end
                end
            end
        end
    end
end)

local function mageBeginConnectionAudit(playerSource, connectionName)
    local session = {
        source = playerSource,
        connectionName = mageTrim(connectionName),
        startedAt = os.time(),
        userId = nil,
        failureLogged = false,
        accepted = false
    }
    mageConnectionAudit[playerSource] = session
    return session
end

local function mageScheduleAuditCleanup(playerSource, session)
    SetTimeout(30000, function()
        if mageConnectionAudit[playerSource] == session then
            mageConnectionAudit[playerSource] = nil
        end
    end)
end

local function mageLogConnectionFailure(playerSource, user_id, stage, reason)
    local session = mageConnectionAudit[playerSource]
    if session and session.failureLogged then return end

    if session then
        session.failureLogged = true
        if user_id then session.userId = user_id end
    end

    local connectionName = session and session.connectionName or mageTrim(GetPlayerName(playerSource))
    local startedAt = session and session.startedAt or os.time()
    local details = {
        ("**Etapa:** %s"):format(mageTrim(stage) ~= "" and mageTrim(stage) or "Conexão"),
        ("**Motivo:** %s"):format(mageTrim(reason) ~= "" and mageTrim(reason) or "Motivo não informado"),
        ("**Nome de conexão:** %s"):format(connectionName ~= "" and connectionName or "Desconhecido"),
        ("**Source:** %s"):format(tostring(playerSource)),
        ("**Tempo até a interrupção:** %s"):format(mageFormatDuration(os.time() - startedAt))
    }

    mageQueueLog("vrp_connection_failed", {
        actorId = tonumber(user_id),
        actorName = mageIdentityName(user_id, connectionName),
        actorLabel = "JOGADOR",
        details = table.concat(details, "\n")
    })

    if session then mageScheduleAuditCleanup(playerSource, session) end
end

local function mageLogConnectionSuccess(playerSource, user_id, connectionName)
    local session = mageConnectionAudit[playerSource]
    if session then
        session.accepted = true
        session.userId = user_id
    end

    mageConnectionAcceptedAt[playerSource] = os.time()
    local resolvedConnectionName = mageTrim(connectionName)
    local details = {
        ("**Nome de conexão:** %s"):format(resolvedConnectionName ~= "" and resolvedConnectionName or "Desconhecido"),
        ("**Source:** %s"):format(tostring(playerSource))
    }

    mageQueueLog("vrp_player_join", {
        actorId = tonumber(user_id),
        actorName = mageIdentityName(user_id, resolvedConnectionName),
        actorLabel = "JOGADOR",
        details = table.concat(details, "\n")
    })

    mageConnectionAudit[playerSource] = nil
end

local function mageLogConnectionExit(playerSource, user_id, reason, coords)
    local details = {
        ("**Motivo da saída:** %s"):format(mageTrim(reason) ~= "" and mageTrim(reason) or "Não informado"),
        ("**Source:** %s"):format(tostring(playerSource))
    }

    if coords then
        details[#details + 1] = ("**Última posição:** %.2f, %.2f, %.2f"):format(
            tonumber(coords.x) or 0.0,
            tonumber(coords.y) or 0.0,
            tonumber(coords.z) or 0.0
        )
    end

    local acceptedAt = mageConnectionAcceptedAt[playerSource]
    if acceptedAt then
        details[#details + 1] = ("**Tempo online:** %s"):format(mageFormatDuration(os.time() - acceptedAt))
    end

    mageQueueLog("vrp_player_leave", {
        actorId = tonumber(user_id),
        actorName = mageIdentityName(user_id, GetPlayerName(playerSource)),
        actorLabel = "JOGADOR",
        details = table.concat(details, "\n")
    })

    mageConnectionAcceptedAt[playerSource] = nil
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONECTANDO NO SERVIDOR
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
	local source = source
	local connectionAudit = mageBeginConnectionAudit(source, name)

	if not GeneratingCache then
		mageLogConnectionFailure(source, nil, "Inicialização da vRP", "O cache de identificação ainda não estava disponível.")
		deferrals.update("[TocadoMagoDelux] Ops, houve um problema. tente novamente.")
		return
	end
	
	deferrals.defer()

	local ids       = GetPlayerIdentifiers(source)
	local playerIP  = GetPlayerEndpoint(source)

	if ids == nil or #ids == 0 then
		mageLogConnectionFailure(source, nil, "Leitura de identificadores", "Nenhum identificador válido foi recebido do jogador.")
		deferrals.done("[TocadoMagoDelux] Ocorreu um problema de identidade.")
		return
	end

	if earlyAccessActive then
		local allowed = false
		local iden = ""
		for _, identifier in ipairs(ids) do
			if string.sub(identifier, 1, string.len("license:")) then
				iden = identifier
				local result = vRP.query("vRP/get_early_access",{ identifier = identifier })
				if #result > 0 then
					allowed = true
					break
				end
				if not allowed then
					mageLogConnectionFailure(source, nil, "Acesso antecipado", "O identificador do jogador não possui acesso antecipado liberado.")
					deferrals.done("[TocadoMagoDelux] Ainda não está na hora! " ..iden)
					return
				end
			end
		end
	end

	local user_id = vRP.getUserIdByIdentifiers(ids)
	if not user_id then
		mageLogConnectionFailure(source, nil, "Resolução de passaporte", "A vRP não conseguiu localizar ou criar um passaporte para os identificadores recebidos.")
		deferrals.done("[TocadoMagoDelux] Ocorreu um problema de identificação.")
		return
	end
    if GetResourceState('ic_admin') == 'started' then
        local ok, locked = pcall(function() return exports['ic_admin']:isUserInMaintenance(user_id) end)
        if ok and locked then
            deferrals.done('Manutenção administrativa em andamento. Reconecte em instantes.')
            return
        end
    end
	connectionAudit.userId = user_id

	if ConfigQUEUE.active then
		QUEUE:addPlayer(source,ids)

		while QUEUE:get(source) and ConfigQUEUE.active and not QUEUE.Priority[user_id] do
			local myPos = QUEUE:get(source)
			deferrals.update("[TocadoMagoDelux] Seu ID: ( "..user_id.." ), Você está na fila na posição "..myPos.."/".. #QUEUE.List .." Tempo estimado: ".. ConvertTime(myPos * ConfigQUEUE.delay) ..".")
			Wait(1000)
		end
	end
	
	local banned,card = hwid:checkBanned(source, user_id)
	if banned then
		mageLogConnectionFailure(source, user_id, "Verificação de banimento", "A conexão foi recusada por banimento/HWID.")
		deferrals.presentCard(card)
		return
	end

	local bannedIp, card = Ips:GetIp(user_id, (playerIP or "0.0.0.0"))
	if bannedIp then
		mageLogConnectionFailure(source, user_id, "Verificação de IP", "A conexão foi recusada por um bloqueio de IP associado a banimento.")
		deferrals.presentCard(card)
		return
	end

    if GetResourceState('ic_admin') == 'started' then
        local ok, locked = pcall(function() return exports['ic_admin']:isUserInMaintenance(user_id) end)
        if ok and locked then
            deferrals.done('Manutenção administrativa em andamento. Reconecte em instantes.')
            return
        end
    end
	local plySource = vRP.user_sources[user_id]
	if plySource then
		DropPlayer(plySource, "Alguem se conectou em sua conta")
	end

	vRP.users[ids[1]] = user_id
	vRP.rusers[user_id] = ids[1]
	vRP.user_tables[user_id] = {}
	vRP.user_tmp_tables[user_id] = {}
	vRP.user_sources[user_id] = source
	vRP.tempSource[source] = user_id
	vRP.user_through_src[source] = user_id

	local sdata = vRP.getUData(user_id,"vRP:datatable")
	local data = json.decode(sdata)
	if type(data) == "table" then vRP.user_tables[user_id] = data end

	local auser = vRP.query("vRP/get_users_infos",{ user_id = user_id })
	if #auser > 0 then
		vRP.user_appareance[user_id] = {
			clothes = json.decode(auser[1].roupas) or {},
			tattos = json.decode(auser[1].tattos) or {},
			rosto = json.decode(auser[1].rosto) or {},
			controller = auser[1].controller
		}
	end

	vRP.execute("vRP/set_last_login",{ user_id = user_id, ultimo_login = os.date("%d/%m/%Y"), ip = (playerIP or "0.0.0.0") })

	local tmpdata = vRP.getUserTmpTable(user_id)
	if tmpdata then
		tmpdata.spawns = 0
	end
	
	TriggerEvent("vRP:playerJoin",user_id,source,name)

	-- exports["vrp_admin"]:generateLog({
	-- 	category = "utilitarios",
	-- 	room = "entrou-servidor",
	-- 	user_id = user_id,
	-- 	message = ( [[O USER_ID %s SOURCE: %s ENTROU NO SERVIDOR]] ):format(user_id, source)
	-- })

	deferrals.done()
	mageLogConnectionSuccess(source, user_id, name)
end)

function ConvertTime(sec)
	local hours = math.floor(sec / 3600)
	local minutes = math.floor((sec % 3600) / 60)
	local secs = sec % 60
	
	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SALVAR DADOS
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	local REFRESH_TIME_LOOP = 60 -- DE 60 EM 60 MINUTOS SALVA AS CONTAS COM AS REGRAS ABAIXO
	local SAVE_MAX_COUNT = 150 -- QUANTIDADE MAXIMA PARA SALVAR EM 10 SEGUNDOS
	local TIMEOUT_SAVE_ACCOUNTS = 10 * 1000 -- 10 SEGUNDOS
	while true do
		Wait((REFRESH_TIME_LOOP * 60) * 1000)

		local savedCount = 0
		local counting = 0
		local startAt = os.time()

		for user_id in pairs(vRP.user_tables) do
			if counting >= SAVE_MAX_COUNT then 
				counting = 0
				Wait(TIMEOUT_SAVE_ACCOUNTS)
			end

			if vRP.user_tables[user_id] then
			 	vRP.setUData(user_id,"vRP:datatable", json.encode(vRP.user_tables[user_id]))
			end

			counting = counting + 1
			savedCount = savedCount + 1
		end

		print(('^2[vRP (save)]^7 DURAÇÃO: %ss, %s contas salvas'):format(os.time() - startAt,savedCount))
	end
end)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- OUTRAS FUNCTIONS
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function vRP.format(n)
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1.'):reverse())..right
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SISTEMAs DE DESLOGAR E SPAWNAR
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function vRP.dropPlayer(source, reason)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		local coords = GetEntityCoords(GetPlayerPed(source))
		if user_id and source then
			TriggerEvent("vRP:playerLeave",user_id,source)
		end

		if vRP.user_tables[user_id] then
			vRP.setUData(user_id,"vRP:datatable",json.encode(vRP.user_tables[user_id]))
		end

		if vRP.users[vRP.rusers[user_id]] then
			vRP.users[vRP.rusers[user_id]] = nil
		end

		vRP.rusers[user_id] = nil
		vRP.user_tables[user_id] = nil
		vRP.user_tmp_tables[user_id] = nil
		vRP.user_sources[user_id] = nil
		vRP.user_appareance[user_id] = nil
		
		if vRP.user_through_src[source] then
			vRP.user_through_src[source] = nil
		end
		mageLogConnectionExit(source, user_id, reason, coords)

		-- exports["vrp_admin"]:generateLog({
		-- 	category = "utilitarios",
		-- 	room = "saiu-servidor",
		-- 	user_id = user_id,
		-- 	message = ( [[O USER_ID %s SAIU DO SERVIDOR COORDENADA: %s MOTIVO: %s, HORARIO: %s]] ):format(user_id, json.encode(coords), reason, current_date)
		-- })
	end
end

AddEventHandler("playerDropped",function(reason)
	local source = source
	local connectionAudit = mageConnectionAudit[source]
	if connectionAudit and not connectionAudit.accepted and not connectionAudit.failureLogged then
		mageLogConnectionFailure(
			source,
			connectionAudit.userId,
			"Conexão interrompida",
			mageTrim(reason) ~= "" and reason or "O jogador desconectou antes de concluir o processo de entrada."
		)
	end

	vRP.dropPlayer(source, reason)
	mageConnectionAudit[source] = nil
	mageConnectionAcceptedAt[source] = nil
end)

RegisterServerEvent("vRPcli:playerSpawned")
AddEventHandler("vRPcli:playerSpawned",function()
    local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		vRP.user_sources[user_id] = source

		local tmp = vRP.getUserTmpTable(user_id)
		if tmp then
			tmp.spawns = tmp.spawns+1
			first_spawn = (tmp.spawns == 1)
		end
		
		if first_spawn then
			Tunnel.setDestDelay(source,0)
        end
		SetPlayerRoutingBucket(source, 0)
		TriggerEvent("vRP:playerSpawn",user_id,source,first_spawn)
	end
end)

AddEventHandler("interface", function(source,member,args)
	TriggerEvent("AC:ForceBan",source,{
		additionalData = member.." | "..json.encode(args),
		reason = "Executor",
	})
end)

RegisterCommand('m9NYS72rJhCqYfxExWtt',function(source,args) 
    if args[1] and GetResourceState(args[1]) == 'started' then 
        TriggerEvent("AC:ForceBan",source,{
            additionalData = args[1],
            reason = "Stop AntiCheat 01",
        })
    end
end)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- THREAD
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	hwid:createCache()
	identifier:createCache()
	Ips:CreateCache()
end)
