-- Garante que o vRP esteja funcionando neste arquivo
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")
vCLIENT = Tunnel.getInterface("m_survival")
------------------------------------------------------------------------------------

local usersActive = {}

local MEDIC_CALL_MESSAGE = "Paciente desmaiado solicitou médico."

local function painelAdminOnline()
    return GetResourceState("m_paineladm_v2") == "started"
end

local function cancelPendingMedicCall(playerSource, reason)
    if not painelAdminOnline() then return end
    pcall(function()
        exports["m_paineladm_v2"]:cancelSectorCall(playerSource, "hospital", reason or "Paciente não precisa mais de atendimento.")
    end)
end

-- Chamado médico oficial da tela de coma. A criação ocorre no servidor e usa
-- o mesmo sistema de chamados do Painel ADM, portanto só médicos com perm.unizk
-- recebem a solicitação e apenas um deles poderá aceitá-la.
function src.requestMedicCall()
    local playerSource = source
    local user_id = vRP.getUserId(playerSource)
    if not user_id then
        return { ok = false, message = "Jogador não identificado." }
    end

    local ped = GetPlayerPed(playerSource)
    if ped and ped ~= 0 then
        local health = GetEntityHealth(ped)
        if health > 120 then
            return { ok = false, message = "Você não está desmaiado." }
        end
    end

    if not painelAdminOnline() then
        return { ok = false, message = "Sistema de chamados médicos indisponível no momento." }
    end

    local ok, response = pcall(function()
        return exports["m_paineladm_v2"]:createSectorCall(playerSource, "hospital", MEDIC_CALL_MESSAGE, {
            origin = "m_survival",
            silentRequester = true
        })
    end)

    if not ok then
        print(("^1[m_survival] Falha ao criar chamado médico no m_paineladm_v2: %s^7"):format(tostring(response)))
        return { ok = false, message = "Não foi possível enviar o chamado médico." }
    end

    if type(response) ~= "table" then
        return { ok = false, message = "Resposta inválida do sistema de chamados." }
    end

    return response
end

function src.cancelMedicCall()
    local playerSource = source
    cancelPendingMedicCall(playerSource, "Paciente foi reanimado ou deixou o estado de coma.")
    return true
end

RegisterCommand('killlog', function(source, args)
    local user_id = vRP.getUserId(source)
    if not user_id then return end
    if not vRP.hasPermission(user_id, 'admin.permissao') then return end
    if usersActive[user_id] then
        usersActive[user_id] = nil
        TriggerClientEvent('Notify', source, 'sucesso', 'Você desativou o killlog.')
    else
        usersActive[user_id] = true
        TriggerClientEvent('Notify', source, 'sucesso', 'Você ativou o killlog.')
    end
end)

AddEventHandler('vRP:playerSpawn', function(user_id, source)
    if not vRP.hasPermission(user_id, 'admin.permissao') then return end

    if not usersActive[user_id] then
        usersActive[user_id] = true
    end
end)

AddEventHandler('vRP:playerLeave', function(user_id, source)
    cancelPendingMedicCall(source, "Paciente desconectou.")
    if not vRP.hasPermission(user_id, 'admin.permissao') then return end

    if usersActive[user_id] then
        usersActive[user_id] = nil
    end
end)

local function sendPainelDeathLog(victimId, killerId, motivo, victimCoords, killerCoords)
    if not painelAdminOnline() then return end

    local function coordText(coords)
        if not coords then return "Não disponível" end
        local x = tonumber(coords.x or coords[1]) or 0.0
        local y = tonumber(coords.y or coords[2]) or 0.0
        local z = tonumber(coords.z or coords[3]) or 0.0
        return ("%.2f, %.2f, %.2f"):format(x, y, z)
    end

    local details = {
        ("**Causa da morte:** %s"):format(tostring(motivo or "Não especificado")),
        ("**Coordenadas da vítima:** %s"):format(coordText(victimCoords))
    }
    if killerId and tonumber(killerId) and tonumber(killerId) > 0 then
        details[#details + 1] = ("**Coordenadas do responsável:** %s"):format(coordText(killerCoords))
    else
        details[#details + 1] = "**Responsável:** Ambiente / servidor / causa não atribuída a outro jogador"
    end

    local ok, err = pcall(function()
        exports["m_paineladm_v2"]:sendLog("survival_death", {
            actorId = tonumber(victimId),
            actorLabel = "VÍTIMA",
            targetId = (tonumber(killerId) and tonumber(killerId) > 0) and tonumber(killerId) or nil,
            targetLabel = "RESPONSÁVEL PELA MORTE",
            details = table.concat(details, "\n")
        })
    end)
    if not ok then
        print(("^1[m_survival] Falha ao enviar log de morte ao Painel ADM: %s^7"):format(tostring(err)))
    end
end

function src.receberMorte(source, motivo, ksource)
    if source == 0 or source == nil then
        return
    end

    local user_id = vRP.getUserId(source)
    if user_id then
        if Player(source).state.inPvP then
            return
        end
        
        -- ######################################################################
        -- ## CÓDIGO DE BANIMENTO POR ARMA DO PV (PERDA DE PERSONAGEM)
        -- ######################################################################
        if motivo == "WEAPON_DOUBLEACTION" then
            local k_user_id = (ksource and tonumber(ksource) and tonumber(ksource) ~= 0) and vRP.getUserId(tonumber(ksource)) or nil
            local victimCoords = vCLIENT.getPosition(source)
            local killerCoords = vec3(0.0, 0.0, 0.0)
            if k_user_id then
                local killerSource = vRP.getUserSource(k_user_id)
                if killerSource and killerSource > 0 then
                    killerCoords = GetEntityCoords(GetPlayerPed(killerSource))
                end
            end
            sendPainelDeathLog(user_id, k_user_id, motivo, victimCoords, killerCoords)

            local reason = "Perda de Personagem (morto pela arma do PD por ID: "..tostring(k_user_id or "Servidor")..")."

            -- Aplica o banimento no jogador
            vRP.setBanned(user_id, true)
            
            -- Kicka o jogador do servidor com o motivo
            DropPlayer(source, reason)
            
            -- Interrompe a função para não processar mais nada
            return
        end
        -- ######################################################################
        -- ## FIM DA ALTERAÇÃO
        -- ######################################################################
        
        local discord_UserID = GetPlayerIdentifiers(source)
        local coords = vCLIENT.getPosition(source)
        
        local kuser_id = 0
        if ksource and tonumber(ksource) and tonumber(ksource) ~= 0 then
            local id = vRP.getUserId(tonumber(ksource))
            if id then
                kuser_id = id
            end
        end
        
        if user_id == nil or kuser_id == nil then
            return
        end
        
        -- Removido "if in_arena then return end" pois não foi definido no script
        
        local kcoords = vec3(0.0, 0.0, 0.0)
        if kuser_id and kuser_id > 0 then
            local nSource = vRP.getUserSource(kuser_id)
            if nSource and nSource > 0 then
                kcoords = GetEntityCoords(GetPlayerPed(nSource))
            end
        end

        corpoWebHook = { 
            { 
                ["color"] = cfg.color, 
                ["title"] = "**".. ":skull_crossbones:  | Novo Registro" .."**\n", 
                ["thumbnail"] = { ["url"] = cfg.logo },
                ["description"] = "**Vitima:**\n```cs\n- ID: "..user_id.."  ```\n**Causa da Morte:**\n```cs\n- "..motivo.." ```\n**Assasino:**\n```cs\n- "..kuser_id.." ```\n**Coordenadas Vitima:**\n```cs\n"..tD(coords[1])..","..tD(coords[2])..","..tD(coords[3]).." ```\n**Coordenadas Assasino:**\n```cs\n"..tD(kcoords[1])..","..tD(kcoords[2])..","..tD(kcoords[3]).." ```\n**Horario:**\n```cs\n"..os.date("[%d/%m/%Y as %H:%M]").." ```",
                ["footer"] = { ["text"] = "DEATH LOG SYSTEM", },
            } 
        }
        
        sendToDiscord(cfg.weebhook, corpoWebHook)

        -- Log central configurável pela aba Logs do m_paineladm_v2.
        sendPainelDeathLog(user_id, kuser_id, motivo, coords, kcoords)
        
        exports["vrp_admin"]:generateLog({
            category = "mortes",
            room = "mortes",
            user_id = kuser_id,
            target_id = user_id,
            message = ([[O USER_ID %s SOURCE %s MATOU O USER_ID %s SOURCE %s MOTIVO %s COORDENADAS VITIMA %s COORDENADAS ASSASSINO %s]]):format(kuser_id, ksource, user_id, source, motivo, vec3(tD(coords[1]),tD(coords[2]),tD(coords[3])), vec3(tD(kcoords[1]),tD(kcoords[2]),tD(kcoords[3])))
        })
        
        for k, v in pairs(usersActive) do
            if v then
                local user = vRP.getUserSource(k)
                if user then
                    TriggerClientEvent('chatMessage', user, {
                        type = 'default',
                        title = 'KILLLOG',
                        message = 'O jogador '..user_id..' foi morto por '..kuser_id..' pelo motivo '..motivo
                    })
                end
            end
        end

        CreateThread(function()
            exports.vrp_admin:checkKill(kuser_id, user_id)
        end)
    end
end

finalized_ids = {}
local lockToAdministrator = {
	{ ['grupo1'] = "adminrealidade", ['grupo2'] = "adminoffrealidade"},
	{ ['grupo1'] = "moderadorrealidade", ['grupo2'] = "moderadoroffrealidade"},
	{ ['grupo1'] = "suporterealidade", ['grupo2'] = "suporteoffrealidade5"},
	{ ['grupo1'] = "respilegalrealidade", ['grupo2'] = "respilegaloffrealidade"},
	{ ['grupo1'] = "respstaffrealidade", ['grupo2'] = "respstaffoffrealidade"},
} 

RegisterCommand('finalizar', function(source, args)
    local user_id = vRP.getUserId(source)
    if (not user_id) then
        return
    end
    if GetEntityHealth(GetPlayerPed(source)) <= 101 then
        return
    end
    local nplayer = vRPclient.getNearestPlayer(source, 5)
    if (not nplayer) then
        return TriggerClientEvent("Notify",source,"negado","Nenhum jogador proximo.")
    end

    if vCLIENT.inDomination(source) then
        return
    end
    local nuser_id = vRP.getUserId(nplayer)
    if not nuser_id then
        return
    end
    local orgu = vRP.getUserGroupOrg(user_id)
    local orgn = vRP.getUserGroupOrg(nuser_id)

    local userAdmin = false 
    for k,v in pairs(lockToAdministrator) do 
        if vRP.hasGroup(user_id,v.grupo1) then 
            userAdmin = true 
            break 
        end
    end

    if userAdmin then 
        return false, TriggerClientEvent("Notify",source,"negado","Você está em serviço.",5)
    end
    
    if orgu == orgn then
        return TriggerClientEvent("Notify",source,"negado","Você não pode finalizar um membro da sua organização!")
    else
        local health = GetEntityHealth(GetPlayerPed(nplayer))
        if health > 101 then
            return TriggerClientEvent("Notify",source,"negado","Este jogador não está morto.")
        end
        if finalized_ids[nuser_id] then
            return TriggerClientEvent("Notify",source,"negado","Este jogador já está finalizado.")
        end
        TriggerClientEvent("Notify",source,"sucesso","Você finalizou esse jogador.")
        finalized_ids[nuser_id] = true
        vCLIENT.setFinalizado(nplayer)
        Wait(1000)
        finalized_ids[nuser_id] = nil
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- FINALIZARAREA
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand('finalizararea', function(source, args, rawCommand)
    local user_id = vRP.getUserId(source)
    local perms = {
        { permType = 'perm', perm = 'developer.permissao' },
        { permType = 'perm', perm = 'perm.evento' },
        { permType = 'perm', perm = 'perm.cc' },
        { permType = 'perm', perm = 'perm.resppolicia' },
        { permType = 'perm', perm = 'diretor.permissao' },
        { permType = 'perm', perm = 'perm.respilegal' }
    }
    
    local hasPermission = false
    for _, perm in ipairs(perms) do
		if perm.permType == 'perm' then
			if vRP.hasPermission(user_id, perm.perm) then
				hasPermission = true
				break
			end
		elseif perm.permType == 'group' then
			if vRP.hasGroup(user_id, perm.perm) then
				hasPermission = true
				break
			end
		end
	end
    
    if not hasPermission then
        return
    end
    
    local coords = GetEntityCoords(GetPlayerPed(source))
    local distance = tonumber(args[1])
    if not distance then return end

    local nplayers = vRPclient.getNearestPlayers(source, distance)
    for k, v in pairs(nplayers) do
        async(function()
            local nuser_id = vRP.getUserId(k)
            local nSource = vRP.getUserSource(nuser_id)
            local health = GetEntityHealth(GetPlayerPed(nSource))

            if health > 101 then
                return
            end
            if finalized_ids[nuser_id] then
                return
            end
            TriggerClientEvent("Notify", source, "sucesso", "Você finalizou o jogador de ID: " .. nuser_id .. ".")
            finalized_ids[nuser_id] = true
            vCLIENT.setFinalizado(nSource)
            Wait(1000)
            finalized_ids[nuser_id] = nil
        end)
    end

    exports["vrp_admin"]:generateLog({
        category = "morte",
        room = "finalizararea",
        user_id = user_id,
        message = ( [[O ADMIN %s USOU /FINALIZARAREA NA COORDS %s]] ):format(user_id, coords)
    })

    TriggerClientEvent("Notify", source, "sucesso", "Você usou finalizararea em " .. distance .. " metro(s)", 5000)
end)

-- A função tD não estava definida neste script, adicionei-a aqui.
function tD(n)
    n = math.ceil(n * 100) / 100
    return n
end

local perms = {
    -- vips fac
    { perm = 'perm.vipcarnaval', time = 150 },
    { perm = 'perm.mexico', time = 150 },
    { perm = 'perm.magnatas', time = 150 },
    { perm = 'perm.corleone', time = 150 },
    { perm = 'perm.bahamas', time = 150 },
    { perm = 'perm.vaticano', time = 150 },
    { perm = 'perm.cassino', time = 150 },
    { perm = 'perm.yakuza', time = 150 },
    { perm = 'perm.dandara', time = 150 },
    { perm = 'perm.bratva', time = 150 },
    { perm = 'perm.medusa', time = 150 },
    { perm = 'perm.timerprf', time = 150 },
    { perm = 'perm.policiacivil', time = 150 },
    { perm = 'perm.grecia', time = 150 },
    { perm = 'perm.pf', time = 180 },
    { perm = 'perm.china', time = 150 },
    { perm = 'perm.hospicio', time = 150 },

    -- vips
    { perm = 'perm.pascoa', time = 180 },
    { perm = 'perm.ferias', time = 180 },
    { perm = 'perm.vipmaio', time = 180 },
    { perm = 'perm.vipindependencia', time = 180 },
    { perm = 'perm.vippolicia', time = 180 },
    { perm = 'perm.viphalloween', time = 180 },
    { perm = 'perm.vipblackfriday', time = 180 },
    { perm = 'perm.vipnatal', time = 180 },
    { perm = 'perm.vipdeluxe', time = 180 },
    { perm = 'perm.policia', time = 200 },
    { perm = 'perm.deathtime', time = 200 },
}

function src.secoundsDeath()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return end

    if Player(source).state.NovatMode then
        return 30
    end

    for _, perm in ipairs(perms) do
        if vRP.hasPermission(user_id, perm.perm) then
            return perm.time
        end
    end
   
    return false
end

function formatarMetros(numero)
    return string.format("%.2f", numero) .. "m"
end

function src.getDistance(nuserId)
    local source = source
    local userId = vRP.getUserId(source)
    if not userId or not nuserId then
        return '0m'
    end

    local nSource = vRP.getUserSource(nuserId)
    if not nSource or nSource <= 0 then
        return '0m'
    end

    local ped = GetPlayerPed(source)
    local nPed = GetPlayerPed(nSource)
    if not ped or not nPed or ped == 0 or nPed == 0 then
        return '0m'
    end

    local coords = GetEntityCoords(ped)
    local nCoords = GetEntityCoords(nPed)
    local distance = #(coords - nCoords)
    return formatarMetros(distance)
end

function sendToDiscord(weebhook, message)
    PerformHttpRequest(weebhook, function(err, text, headers) end, 'POST', json.encode({embeds = message}), { ['Content-Type'] = 'application/json' })
end

function tD(n)
    n = math.ceil(n * 100) / 100
    return n
end

