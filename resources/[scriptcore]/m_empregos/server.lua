-- print('[DEBUG]: Server Init Sucess')

local all_info = {}

local MageJobLogKey = {
    Caminhoneiro = "job_caminhoneiro",
    Motorista = "job_motorista",
    Taxista = "job_taxista",
    Entregador = "job_entregador",
    Pescador = "job_pescador",
    Lixeiro = "job_lixeiro",
    Minerador = "job_minerador",
    Eletricista = "job_eletricista"
}

local mageJobActionCooldown = {}

local mageJobActiveServices = {}

-- Tipos de garagem vinculados a cada emprego. O m_garage usa esta informação
-- para devolver somente os veículos realmente retirados na garagem daquele serviço.
local MageJobGarageTypes = {
    Caminhoneiro = { "Caminhoneiro" },
    Motorista = { "Motorista" },
    Taxista = { "Taxista" },
    Entregador = { "Entregador" },
    Lixeiro = { "Lixeiro" },
    Minerador = { "Mineracao" },
    Eletricista = { "Eletricista" }
}

-- Mapeamento inverso usado pela garagem para validar se o jogador realmente
-- iniciou o expediente antes de retirar um veículo do serviço.
local MageGarageTypeToJob = {
    Caminhoneiro = "Caminhoneiro",
    Motorista = "Motorista",
    Taxista = "Taxista",
    Entregador = "Entregador",
    Lixeiro = "Lixeiro",
    Mineracao = "Minerador",
    Eletricista = "Eletricista"
}

local MageJobReturnToStartToEnd = {
    Lixeiro = true,
    Eletricista = true
}

local function mageJobIsNearJobStart(playerSource, jobName, maxDistance)
    local jobConfig = cfg.list[jobName]
    local start = jobConfig and jobConfig.inicio
    if type(start) ~= "table" then return false end

    local ped = GetPlayerPed(playerSource)
    if not ped or ped == 0 then return false end

    local coords = GetEntityCoords(ped)
    local dx = coords.x - (tonumber(start[1]) or 0.0)
    local dy = coords.y - (tonumber(start[2]) or 0.0)
    local dz = coords.z - (tonumber(start[3]) or 0.0)
    return math.sqrt((dx * dx) + (dy * dy) + (dz * dz)) <= (tonumber(maxDistance) or 5.0)
end

local function mageJobGetActiveService(userId)
    return mageJobActiveServices[tonumber(userId)]
end

-- API interna compartilhada pelos módulos deste resource.
-- Permite que um emprego valide o expediente real sem expor a tabela de sessões.
function MageEmpregosIsServiceActive(userId, jobName)
    userId = tonumber(userId)
    jobName = tostring(jobName or "")
    if not userId or jobName == "" then return false end

    local active = mageJobGetActiveService(userId)
    return active ~= nil and active.job == jobName
end

-- Export consultado pelo m_garage. Retorna nil para garagens que não pertencem
-- à Central de Empregos; para as garagens protegidas, retorna true somente se
-- o expediente correspondente estiver realmente ativo.
exports("canUseCentralJobGarage", function(userId, garageType)
    userId = tonumber(userId)
    garageType = tostring(garageType or "")

    local requiredJob = MageGarageTypeToJob[garageType]
    if not requiredJob then
        return nil
    end

    if not userId then
        return false
    end

    local active = mageJobGetActiveService(userId)
    if not active or active.job ~= requiredJob then
        return false
    end

    -- Validação adicional: além do expediente ativo, o emprego atual do player
    -- ainda precisa ser o mesmo que originou aquele serviço.
    local currentJob = mg.getUserGroupByType(userId, "emp") or ""
    return currentJob == requiredJob
end)

local function mageJobGetServiceVehicles(userId, jobName)
    if GetResourceState("m_garage") ~= "started" then
        return {}
    end

    local garageTypes = MageJobGarageTypes[jobName]
    if not garageTypes then
        return {}
    end

    local ok, vehicles = pcall(function()
        return exports["m_garage"]:getUserJobVehicles(tonumber(userId), garageTypes)
    end)

    if not ok or type(vehicles) ~= "table" then
        return {}
    end

    return vehicles
end

local function mageJobReturnServiceVehicle(userId, netId)
    if GetResourceState("m_garage") ~= "started" then
        return false
    end

    local ok, returned = pcall(function()
        return exports["m_garage"]:returnUserJobVehicle(tonumber(userId), tonumber(netId))
    end)

    return ok and returned == true
end

local function mageJobScheduleVehicleReturn(userId, playerSource, jobName)
    local vehicles = mageJobGetServiceVehicles(userId, jobName)
    if #vehicles <= 0 then
        return
    end

    if playerSource and GetPlayerName(playerSource) then
        TriggerClientEvent("m_empregos:serviceVehicleCountdown", playerSource, 30)
    end

    SetTimeout(30000, function()
        for _, vehicle in ipairs(vehicles) do
            if type(vehicle) == "table" and vehicle.netId then
                mageJobReturnServiceVehicle(userId, vehicle.netId)
            elseif tonumber(vehicle) then
                mageJobReturnServiceVehicle(userId, vehicle)
            end
        end
    end)
end

local function mageJobBlockCentralIfWorking(playerSource, userId)
    local active = mageJobGetActiveService(userId)
    if not active then
        return false
    end

    TriggerClientEvent(
        "Notify",
        playerSource,
        "negado",
        "Encerre o expediente do emprego atual antes de voltar aqui!",
        8
    )
    return true
end


local function mageJobRoundXp(value)
    value = tonumber(value) or 0
    return math.floor((value * 10000) + 0.5) / 10000
end

local function mageJobFormatXp(value)
    value = mageJobRoundXp(value)
    if value == math.floor(value) then
        return tostring(math.floor(value))
    end
    local text = string.format("%.4f", value)
    text = text:gsub("0+$", ""):gsub("%.$", "")
    return text
end

local function mageJobRateAllowed(userId, action, seconds)
    userId = tonumber(userId)
    if not userId then return false end
    action = tostring(action or "action")
    seconds = tonumber(seconds) or 2
    local key = tostring(userId) .. ":" .. action
    local now = os.time()
    local previous = tonumber(mageJobActionCooldown[key]) or 0
    if now - previous < seconds then
        return false, previous, now
    end
    mageJobActionCooldown[key] = now
    return true, previous, now
end

local function mageJobProgress(userId, jobName)
    local query = mg.query('get_empdata', { user_id = userId })
    if not query[1] or not query[1].dvalue then return nil, nil, nil end
    local jobs = json.decode(query[1].dvalue) or {}
    local job = jobs[jobName]
    if not job then return jobs, nil, nil end
    return jobs, job, query
end

local function mageJobPaymentLogKey(jobName)
    local base = MageJobLogKey[jobName]
    return base and (base .. "_payment") or nil
end

local function mageJobLevelLogKey(jobName)
    local base = MageJobLogKey[jobName]
    return base and (base .. "_levelup") or nil
end


mg.prepare("get_empdata","SELECT * FROM m_empregos WHERE user_id = @user_id")
mg.prepare("set_empdata","INSERT INTO m_empregos(user_id,dvalue) VALUES(@user_id,@dvalue)")

src.checkEmp = function(emp)

    local source = source
    local user_id = mg.getUserId(source)
    local at_emprego = mg.getUserGroupByType(user_id, "emp")

    if at_emprego == "" then at_emprego = "Nenhum" end 

    if emp == at_emprego then
        return true
    else
        vCLIENT.setRoute(source,cfg.central[1],cfg.central[2])
        TriggerClientEvent('Notify', source, 'negado', 'Vá até a Central de Empregos e assine sua carteira como '..emp..'! Foi marcado em seu GPS.',10)
        return false
    end

end

src.getInitCache = function()

    local source = source
    local user_id = mg.getUserId(source)
    local at_emprego = mg.getUserGroupByType(user_id, "emp")

    if at_emprego == "" then at_emprego = "Nenhum" end 
    
    local emp_data = {}

    local query = mg.query('get_empdata', { user_id = user_id })

    empregos = json.decode(query[1].dvalue) or {}
     
    for k, v in pairs(empregos) do
        table.insert(emp_data, {
            at_emprego = 'at_emprego',
            emprego = k,
            nivel = v.nivel,
            xp = v.xp
        })
        -- print('[DEBUG ALL INFO]: [Empregos]:'..k..'[NIVEL]:'..v.nivel..'[XP]:'..v.xp..'')
    end



    -- print('[DEBUG]: [Emprego Setado]:'..at_emprego)
    
    return emp_data
end

mg.prepare("att_empdata","REPLACE INTO m_empregos(user_id,dvalue) VALUES(@user_id,@dvalue)")

mg.prepare(
  "update_level",
  "INSERT INTO m_empregos (user_id, dvalue) VALUES (@user_id, @dvalue) \
   ON DUPLICATE KEY UPDATE dvalue = @dvalue"
)

src.upgrade_level = function()
    -- Interface Tunnel legada. O client atual não usa esta função; manter o
    -- incremento aqui permitiria contornar o controle do evento oficial.
    MageEmpregosLogInvalid(source, "upgrade_level direto", "Chamada direta da interface legada de experiência foi bloqueada. O progresso só pode ocorrer pelo evento controlado m_empregos:upgrade_level.")
    return false
end

local function mageJobGrantXp(playerSource, expectedJob)
    playerSource = tonumber(playerSource)
    if not playerSource then return false end

    local user_id = mg.getUserId(playerSource)
    if not user_id then return false end

    local at_emprego = mg.getUserGroupByType(user_id, "emp")
    if at_emprego == "" or not at_emprego then
        MageEmpregosLogInvalid(playerSource, "ganhar experiência", "Tentativa de receber XP sem possuir um emprego ativo.")
        return false
    end

    expectedJob = tostring(expectedJob or "")
    if expectedJob ~= "" and at_emprego ~= expectedJob then
        MageEmpregosLogInvalid(playerSource, "ganhar experiência", ("Emprego esperado: %s\nEmprego atual: %s"):format(expectedJob, tostring(at_emprego)))
        return false
    end

    local allowed = mageJobRateAllowed(user_id, "xp:" .. at_emprego, 2)
    if not allowed then
        MageEmpregosLog("jobs_security_progress_spam", {
            actorId = user_id,
            details = ("Emprego: %s\nUma tentativa de experiência em intervalo inferior a 2 segundos foi bloqueada."):format(at_emprego)
        })
        return false
    end

    local query = mg.query('get_empdata', { user_id = user_id })
    if not query[1] or not query[1].dvalue then return false end

    local empregos = json.decode(query[1].dvalue) or {}
    if not empregos[at_emprego] or not cfg.list[at_emprego] then return false end

    local emp = empregos[at_emprego]
    local oldLevel = tonumber(emp.nivel) or 1
    local nivel = oldLevel
    local xp = tonumber(emp.xp) or 0

    if nivel >= cfg.list[at_emprego]["total_nivel"] then
        emp.nivel = cfg.list[at_emprego]["total_nivel"]
        emp.xp = 0
    else
        local xpGain = tonumber(cfg.list[at_emprego]["xp_per_action"])
        if xpGain == nil then xpGain = 1 end
        if xpGain < 0 then xpGain = 0 end

        xp = mageJobRoundXp(xp + xpGain)
        local xp_max = tonumber(cfg.list[at_emprego]["xp_for_level"][nivel]) or 0
        if (xp + 0.0000001) >= xp_max then
            xp = 0
            nivel = nivel + 1
            TriggerClientEvent('Notify', playerSource, 'sucesso', '['..at_emprego..'] Parabéns! Você alcançou o Nivel '..nivel..'',10)
        else
            TriggerClientEvent('Notify', playerSource, 'sucesso', '['..at_emprego..'] Experiência: '..mageJobFormatXp(xp)..' de '..mageJobFormatXp(xp_max)..'',10)
        end
        emp.nivel = nivel
        emp.xp = xp
    end

    empregos[at_emprego] = emp
    mg.execute("update_level", {
        user_id = user_id,
        dvalue = json.encode(empregos)
    })

    if tonumber(emp.nivel) and tonumber(emp.nivel) > oldLevel then
        local logKey = mageJobLevelLogKey(at_emprego)
        if logKey then
            MageEmpregosLog(logKey, {
                actorId = user_id,
                details = ("Emprego: %s\nNível anterior: %d\nNovo nível: %d"):format(at_emprego, oldLevel, tonumber(emp.nivel))
            })
        end
    end

    return true
end

-- API interna para módulos do próprio m_empregos. Não é registrada como evento de rede.
function MageEmpregosGrantXp(playerSource, expectedJob)
    return mageJobGrantXp(playerSource, expectedJob)
end

RegisterServerEvent('m_empregos:upgrade_level')
AddEventHandler('m_empregos:upgrade_level',function()
    local playerSource = source
    local userId = mg.getUserId(playerSource)
    local currentJob = userId and mg.getUserGroupByType(userId, "emp") or ""
    if currentJob == "Lixeiro" then
        MageEmpregosLogInvalid(playerSource, "XP de Lixeiro pela rota legada", "O XP do Lixeiro só é concedido após uma coleta validada no caminhão.")
        return
    end
    mageJobGrantXp(playerSource, nil)
end)

RegisterServerEvent('m_empregos:payment')
AddEventHandler('m_empregos:payment',function()

    local source = source
    local user_id = mg.getUserId(source)
    if not user_id then return end

    local at_emprego = mg.getUserGroupByType(user_id, "emp")
    if at_emprego == "Lixeiro" then
        MageEmpregosLogInvalid(source, "pagamento de Lixeiro pela rota legada", "O pagamento do Lixeiro só é concedido após uma coleta validada no caminhão.")
        return
    end
    if at_emprego == "" or not at_emprego then
        MageEmpregosLogInvalid(source, "receber pagamento", "Evento de pagamento chamado sem possuir um emprego ativo.")
        return
    end

    local allowed = mageJobRateAllowed(user_id, "payment:" .. at_emprego, 2)
    if not allowed then
        MageEmpregosLog("jobs_security_payment_spam", {
            actorId = user_id,
            details = ("Emprego: %s\nUma segunda solicitação de pagamento em menos de 2 segundos foi bloqueada."):format(at_emprego)
        })
        return
    end

    local query = mg.query('get_empdata', { user_id = user_id })
    if not query[1] or not query[1].dvalue then return end

    local empregos = json.decode(query[1].dvalue) or {}
    if not empregos[at_emprego] then return end

    local emp = empregos[at_emprego]
    local nivel = tonumber(emp.nivel) or 1

    local paymentTable = cfg.list[at_emprego] and cfg.list[at_emprego]["payment_for_level"] or {}
    local payment_level = paymentTable and paymentTable[nivel]
    if not payment_level or not payment_level[1] or not payment_level[2] then
        MageEmpregosLog("jobs_security_invalid_payment", {
            actorId = user_id,
            details = ("Emprego: %s\nNível: %d\nO emprego não possui pagamento comum configurado para este nível."):format(at_emprego, nivel)
        })
        return
    end

    local minPayment = tonumber(payment_level[1]) or 0
    local maxPayment = tonumber(payment_level[2]) or 0
    if maxPayment < minPayment then minPayment, maxPayment = maxPayment, minPayment end
    local payment = math.random(minPayment,maxPayment)

    mg.payment(user_id,payment)
    TriggerClientEvent('Notify', source, 'sucesso', '['..at_emprego..'] Você recebeu seu pagamento de R$ '..payment..'',10)

    local logKey = mageJobPaymentLogKey(at_emprego)
    if logKey then
        MageEmpregosLog(logKey, {
            actorId = user_id,
            details = ("Emprego: %s\nNível: %d\nPagamento recebido: %s\nFaixa configurada do nível: %s até %s"):format(
                at_emprego, nivel, MageEmpregosMoney(payment), MageEmpregosMoney(minPayment), MageEmpregosMoney(maxPayment)
            )
        })
    end
end)

-- RegisterCommand("emp", function(source, args, rawCommand)

--     local source = source
--     local user_id = mg.getUserId(source)
--     if not user_id then return end

--     local at_emprego = mg.getUserGroupByType(user_id, "emp")
--     if at_emprego == "" or not at_emprego then return end

--     local query = mg.query('get_empdata', { user_id = user_id })
--     if not query[1] or not query[1].dvalue then return end

--     local empregos = json.decode(query[1].dvalue) or {}
--     if not empregos[at_emprego] then return end

--     local emp = empregos[at_emprego]

--     -- dados atuais
--     local nivel = emp.nivel or 1
--     local xp = emp.xp or 0
        
--     local xp_max = cfg.list[at_emprego]["xp_for_level"][nivel] or 0

--     if nivel >= cfg.list[at_emprego]["total_nivel"] then
--         TriggerClientEvent('Notify', source, 'sucesso', '[Atual Emprego]: '..at_emprego..' <br> [Nivel]: '..nivel..' <br> [Experiência]: Nivel Máximo',10)
--     else
--         TriggerClientEvent('Notify', source, 'sucesso', '[Atual Emprego]: '..at_emprego..' <br> [Nivel]: '..nivel..' <br> [Experiência]: '..xp..' de '..xp_max..'',10)
--     end
-- end)

src.get_level = function()
    local source = source
    local user_id = mg.getUserId(source)
    if not user_id then return end

    local at_emprego = mg.getUserGroupByType(user_id, "emp")
    if at_emprego == "" or not at_emprego then return end

    local query = mg.query('get_empdata', { user_id = user_id })
    if not query[1] or not query[1].dvalue then return end

    local empregos = json.decode(query[1].dvalue) or {}
    if not empregos[at_emprego] then return end

    local emp = empregos[at_emprego]
    -- dados atuais
    local nivel = emp.nivel or 1
        
    return nivel
end

src.get_at_emprego = function()

    local source = source
    local user_id = mg.getUserId(source)
    local at_emprego = mg.getUserGroupByType(user_id, "emp")

    if at_emprego == "" then at_emprego = "Nenhum" end 
    
    return at_emprego
end


-- Controle server-side do expediente. A Central consulta este estado antes de
-- qualquer troca de emprego, inclusive se alguém tentar chamar a NUI/evento direto.
src.startService = function(jobName)
    local playerSource = source
    local user_id = mg.getUserId(playerSource)
    if not user_id then return false end

    jobName = tostring(jobName or "")
    if jobName == "" or not cfg.list[jobName] then
        return false
    end

    local currentJob = mg.getUserGroupByType(user_id, "emp") or ""
    if currentJob ~= jobName then
        return false
    end

    local active = mageJobGetActiveService(user_id)
    if active then
        return active.job == jobName
    end

    mageJobActiveServices[user_id] = {
        job = jobName,
        source = playerSource,
        startedAt = os.time()
    }

    return true
end

src.endService = function(jobName)
    local playerSource = source
    local user_id = mg.getUserId(playerSource)
    if not user_id then return false end

    jobName = tostring(jobName or "")
    local active = mageJobGetActiveService(user_id)
    if not active or active.job ~= jobName then
        return false
    end

    if MageJobReturnToStartToEnd[jobName] and not mageJobIsNearJobStart(playerSource, jobName, 5.0) then
        return false
    end

    if jobName == "Entregador" and type(MageEntregadorOnServiceEnd) == "function" then
        MageEntregadorOnServiceEnd(user_id, playerSource, true)
    end

    if jobName == "Lixeiro" and type(MageLixeiroOnServiceEnd) == "function" then
        MageLixeiroOnServiceEnd(user_id, playerSource)
    end

    mageJobActiveServices[user_id] = nil
    mageJobScheduleVehicleReturn(user_id, playerSource, jobName)
    return true
end

src.canOpenCentral = function()
    local playerSource = source
    local user_id = mg.getUserId(playerSource)
    if not user_id then return false end

    return not mageJobBlockCentralIfWorking(playerSource, user_id)
end

src.getActiveService = function()
    local playerSource = source
    local user_id = mg.getUserId(playerSource)
    if not user_id then return nil end

    local active = mageJobGetActiveService(user_id)
    return active and active.job or nil
end

src.set_at_emprego = function(at_emprego,set_emprego,loc)

    local source = source
    local user_id = mg.getUserId(source)
    if not user_id then return false end

    if mageJobBlockCentralIfWorking(source, user_id) then
        return false
    end

    set_emprego = tostring(set_emprego or "")
    local emprego = mg.getUserGroupByType(user_id, "emp") or ""

    -- Nunca confia no nome do grupo enviado pelo client. Somente empregos
    -- realmente cadastrados no jobs.json/cfg.list podem ser aplicados aqui.
    if set_emprego == "" or not cfg.list[set_emprego] then
        MageEmpregosLogInvalid(source, "alterar emprego", ("Cargo solicitado e bloqueado: %s"):format(set_emprego ~= "" and set_emprego or "<vazio>"))
        TriggerClientEvent('Notify', source, 'negado', 'Emprego inválido.', 5)
        return false
    end

    if emprego == set_emprego then
        TriggerClientEvent('Notify', source, 'negado', 'Você já está trabalhando de: ' ..set_emprego..'')
        return false
    end

    local previousJob = emprego ~= "" and emprego or "Nenhum"
    if emprego ~= "" then
        mg.removeUserGroup(parseInt(user_id), emprego)
    end
    mg.addUserGroup(parseInt(user_id), set_emprego)

    TriggerClientEvent('Notify', source, 'sucesso', 'Você saiu de '..previousJob..'\nPara o emprego de: ' ..set_emprego..'')

    MageEmpregosLog("jobs_job_changed", {
        actorId = user_id,
        details = ("Emprego anterior: %s\nNovo emprego: %s"):format(previousJob, set_emprego)
    })

    local jobLocation = cfg.list[set_emprego] and cfg.list[set_emprego].inicio or nil
    if type(jobLocation) == "table" and tonumber(jobLocation[1]) and tonumber(jobLocation[2]) then
        vCLIENT.setRoute(source,tonumber(jobLocation[1]),tonumber(jobLocation[2]))
        TriggerClientEvent('Notify', source, 'importante', 'Foi marcado em seu GPS a localização do emprego!',15)
    end

    return true
end

src.demissao = function(at_emprego)
    local source = source
    local user_id = mg.getUserId(source)
    if not user_id then return false end

    if mageJobBlockCentralIfWorking(source, user_id) then
        return false
    end

    local emprego = mg.getUserGroupByType(user_id, "emp") or ""
    if emprego == "" then
        TriggerClientEvent('Notify', source, 'negado', 'Você não está em nenhum emprego!')
        return false
    end

    mg.removeUserGroup(parseInt(user_id), emprego)
    MageEmpregosLog("jobs_job_resigned", {
        actorId = user_id,
        details = ("Emprego encerrado: %s"):format(emprego)
    })
    TriggerClientEvent('Notify', source, 'sucesso', 'Você acaba de pedir demissão do emprego: ['..emprego..']\n',10)
    return true
end

src.give_un = function(emprego)

    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return false end

    emprego = tostring(emprego or "")
    if emprego == "" or not cfg.list[emprego] or not MageEmpregosHasJob(user_id, emprego) then
        MageEmpregosLogInvalid(source, "vestir uniforme de emprego", ("Uniforme solicitado: %s"):format(emprego ~= "" and emprego or "<vazio>"))
        return false
    end

    local custom = cfg.list[emprego]["uniforme"]

    if custom then

        local old_custom = vRPclient.getCustomization(source)
        local idle_copy = {}
        
        local masc = 1885233650
        local fem = -1667301416

        ped = GetPlayerPed(source)
        local getmd = GetEntityModel(ped)
       
        idle_copy = vRP.save_idle_custom(source,old_custom)
        idle_copy.modelhash = nil

        if getmd == masc then
            for k,v in pairs(custom['masculino']) do
                idle_copy[k] = v
            end
        elseif getmd == fem then
            for k,v in pairs(custom['feminino']) do
                idle_copy[k] = v
            end
        end

        vRPclient._setCustomization(source,idle_copy)
    end

end

src.remove_un = function()
    local source = source
    local user_id = vRP.getUserId(source)
    vRP.removeCloak(source)
end


local function resetEmpregoForSource(playerSource)
    local user_id = mg.getUserId(playerSource)
    if not user_id then return end

    local at_emprego = mg.getUserGroupByType(user_id, "emp")
    if at_emprego == "" or not at_emprego then return end

    local query = mg.query('get_empdata', { user_id = user_id })
    if not query[1] or not query[1].dvalue then return end

    local empregos = json.decode(query[1].dvalue) or {}
    if not empregos[at_emprego] then return end

    -- reset do emprego atual
    empregos[at_emprego].nivel = 1
    empregos[at_emprego].xp = 0

    -- salva
    mg.execute("update_level", {
        user_id = user_id,
        dvalue = json.encode(empregos)
    })

    MageEmpregosLog("jobs_level_reset", {
        actorId = user_id,
        details = ("Emprego: %s\nNível redefinido para 1 e experiência redefinida para 0."):format(at_emprego)
    })
end

src.reset_emprego = function()
    return resetEmpregoForSource(source)
end

RegisterCommand("empreset", function(source, args, rawCommand)
    resetEmpregoForSource(source)
end)

AddEventHandler('vRP:playerSpawn', function(user_id, source)
    if user_id then
        local query = mg.query('get_empdata', { user_id = user_id })

        -- SÓ cria se NÃO existir registro no banco
        if not query[1] then

            local empregos = {}

            for k, v in pairs(cfg.list) do
                empregos[k] = {
                    nivel = 1,
                    xp = 0
                }
            end

            mg.execute("set_empdata", {
                user_id = user_id,
                dvalue = json.encode(empregos)
            })

            -- print('[DEBUG EMPREGOS]: Dados CRIADOS para ID '..user_id)
        else
            -- print('[DEBUG EMPREGOS]: Dados JÁ EXISTEM para ID '..user_id)
        end
    end
end)



AddEventHandler("playerDropped", function()
    local playerSource = source
    local user_id = mg.getUserId(playerSource)

    if not user_id then
        for id, service in pairs(mageJobActiveServices) do
            if service and service.source == playerSource then
                user_id = id
                break
            end
        end
    end

    if not user_id then return end

    local active = mageJobActiveServices[user_id]

    if active and active.job == "Entregador" and type(MageEntregadorOnServiceEnd) == "function" then
        MageEntregadorOnServiceEnd(user_id, nil, false)
    end

    mageJobActiveServices[user_id] = nil

    -- Ao desconectar, não mantém veículo de serviço abandonado no mapa.
    if active and active.job then
        local vehicles = mageJobGetServiceVehicles(user_id, active.job)
        for _, vehicle in ipairs(vehicles) do
            local netId = type(vehicle) == "table" and vehicle.netId or vehicle
            if netId then
                mageJobReturnServiceVehicle(user_id, netId)
            end
        end
    end
end)

