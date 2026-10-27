identidade = {}
Tunnel = module("vrp", "lib/Tunnel")
Proxy = module("vrp", "lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPC = Tunnel.getInterface("vRP")
Tunnel.bindInterface(GetCurrentResourceName(), identidade)
vCLIENT = Tunnel.getInterface(GetCurrentResourceName())

local function getUserVips(user_id)
	local currentVips = {}
	local userGroups = vRP.getUserGroups(user_id) or {}
	local groupDefinitions = vRP.getGroups() or {}

	for groupName in pairs(userGroups) do
		local groupDef = groupDefinitions[groupName]
		local groupConfig = groupDef and groupDef._config

		if groupConfig and tostring(groupConfig.gtype or ""):lower() == "vip" then
			local displayName = groupName

			if vRP.getGroupTitle then
				local title = vRP.getGroupTitle(groupName)
				if title and tostring(title) ~= "" then
					displayName = tostring(title)
				end
			elseif groupConfig.title and tostring(groupConfig.title) ~= "" then
				displayName = tostring(groupConfig.title)
			end

			currentVips[#currentVips + 1] = displayName
		end
	end

	table.sort(currentVips, function(a, b)
		return tostring(a):lower() < tostring(b):lower()
	end)

	return currentVips
end

--[[
    IMPORTANTE:
    vRP.getUserIdentity() nesta base mantém os dados da identidade em memória
    durante a sessão. Quando o Painel ADM altera nome/idade/telefone/RG direto
    no banco, esse cache pode continuar devolvendo os valores antigos até o
    jogador reconectar.

    Por isso o m_identity consulta vrp_user_identities diretamente sempre que
    a identidade é aberta/atualizada. Assim o banco passa a ser a fonte de
    verdade para os campos editáveis e a atualização aparece sem relog.
]]
local function getFreshIdentity(user_id)
	local cachedIdentity = {}
	local okCached, cached = pcall(vRP.getUserIdentity, user_id)
	if okCached and type(cached) == "table" then
		cachedIdentity = cached
	end

	local okDb, rows = pcall(function()
		return exports["oxmysql"]:executeSync([[
			SELECT nome, sobrenome, idade, telefone, registro, relacionamento
			FROM vrp_user_identities
			WHERE user_id = ?
			LIMIT 1
		]], { user_id })
	end)

	if okDb and type(rows) == "table" and rows[1] then
		local row = rows[1]
		return {
			nome = row.nome or cachedIdentity.nome or "",
			sobrenome = row.sobrenome or cachedIdentity.sobrenome or "",
			idade = row.idade or cachedIdentity.idade or "",
			telefone = row.telefone or cachedIdentity.telefone or "",
			registro = row.registro or cachedIdentity.registro or "",
			relacionamento = row.relacionamento or cachedIdentity.relacionamento or "{}"
		}
	end

	-- Fallback para não quebrar a identidade caso o banco esteja indisponível.
	return cachedIdentity
end

local function decodeRelationship(value)
	if type(value) == "table" then return value end
	if type(value) ~= "string" or value == "" then return nil end

	local ok, decoded = pcall(json.decode, value)
	if ok and type(decoded) == "table" then
		return decoded
	end

	return nil
end

AddEventHandler("vRP:playerSpawn", function(user_id, source, first_spawn)
	if (not user_id) then return end
	if (identidade[tostring(user_id)]) then return end

	local query = exports["oxmysql"]:executeSync('SELECT avatarURL from smartphone_instagram WHERE user_id = ? ', { user_id })
	if (not query[1]) then return end

	identidade[tostring(user_id)] = {}
	identidade[tostring(user_id)].avatarURL = query[1].avatarURL
end)

identidade.getInfos = function()
	local src = source
	local user_id = vRP.getUserId(src)
	local porte
	local isStaff
	local avatarURL

	if (not user_id) then return end

	-- NÃO usa mais somente vRP.getUserIdentity aqui, pois ela pode estar cacheada.
	local identity = getFreshIdentity(user_id)
	if type(identity) ~= "table" then return end

	if (vRP.hasGroup(user_id, "Porte de Armas")) then porte = 'Possui' else porte = nil end

	isStaff = vRP.getUserGroupByType(user_id, "staff")

	if (isStaff == nil or isStaff == "") then
		isStaff = 'Não'
	end

	local currentVips = getUserVips(user_id)

	if (identidade[tostring(user_id)]) then
		avatarURL = identidade[tostring(user_id)].avatarURL
	end

	local org = vRP.getUserGroupByType(user_id, "org")
	if (org == nil or org == "") then
		org = "Não possui"
	end

	local at_emprego = vRP.getUserGroupByType(user_id, "emp")
	if at_emprego == nil or at_emprego == "" then at_emprego = "Nenhum" end

	local spouse = decodeRelationship(identity.relacionamento)

	local status_spouse = 'Solteiro(a)'
	if spouse and spouse.tipo then
		status_spouse = spouse.tipo
	end
	if (not spouse or identity.relacionamento == '{}') then
		spouse = 'Ninguém'
	elseif spouse and spouse.tipo then
		spouse = spouse.tipo..' '..(spouse.name and spouse.name or 'Não encontrado')
	end

	local infos = {
		action = "open",
		image = avatarURL,
		id = user_id,
		name = tostring(identity.nome or "") .. " " .. tostring(identity.sobrenome or ""),
		rg = identity.registro,
		birth = identity.idade,
		org = org,
		spouse = spouse,
		status_spouse = status_spouse,
		telephone = identity.telefone,
		wallet = vRP.getMoney(user_id),
		bank = vRP.getBankMoney(user_id),
		carry = porte,
		staff = isStaff,
		vips = currentVips,
		emprego = at_emprego
	}
	return infos
end
