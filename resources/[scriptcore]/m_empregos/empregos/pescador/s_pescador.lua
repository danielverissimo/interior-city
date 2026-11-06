-- Pescador - servidor
-- Minigame de pesca inspirado em mecânicas de controle vertical, com sessão e prêmio validados no servidor.

configpesca = configpesca or {}

configpesca.required = "isca"
configpesca.locais = {
    { 1109.33, -637.33, 56.82, 105.18 },
    { 1108.88, -635.27, 56.82, 107.12 },
    { 1108.44, -633.04, 56.82, 103.16 },
    { 1107.97, -630.56, 56.82, 108.75 }
}

configpesca.peixes = {
    [1] = { x = "dourado" },
    [2] = { x = "corvina" },
    [3] = { x = "salmao" }
}

configpesca.sell = {
    ["dourado"] = {
        [1] = { 100,500 }, [2] = { 600,900 }, [3] = { 1000,1500 }, [4] = { 1600,2300 }, [5] = { 2400,3000 }
    },
    ["corvina"] = {
        [1] = { 100,500 }, [2] = { 600,900 }, [3] = { 1000,1500 }, [4] = { 1600,2300 }, [5] = { 2400,3000 }
    },
    ["salmao"] = {
        [1] = { 100,500 }, [2] = { 600,900 }, [3] = { 1000,1500 }, [4] = { 1600,2300 }, [5] = { 2400,3000 }
    }
}

-- Perfis do minigame. O item sorteado nunca é confiado ao client para a recompensa.
-- Valores desconhecidos/adicionados pelo painel usam o perfil padrão automaticamente.
-- progressGain controla a velocidade de subida da barra lateral de captura: menor = mais demorado/difícil.
-- progressLoss controla a velocidade de queda quando o peixe fica fora da área verde: maior = mais punitivo.
local fishingProfiles = {
    dourado = {
        behavior = "smooth", difficulty = 1,
        fishSpeed = 0.42, fishAccel = 1.90, changeMin = 0.75, changeMax = 1.45,
        barSize = 0.285, progressGain = 0.22, progressLoss = 0.18
    },
    corvina = {
        behavior = "mixed", difficulty = 2,
        fishSpeed = 0.56, fishAccel = 2.55, changeMin = 0.48, changeMax = 1.05,
        barSize = 0.245, progressGain = 0.20, progressLoss = 0.22
    },
    salmao = {
        behavior = "dart", difficulty = 3,
        fishSpeed = 0.64, fishAccel = 2.90, changeMin = 0.36, changeMax = 0.88,
        calmChance = 0.34, calmDurationMin = 0.95, calmDurationMax = 1.65,
        calmDistance = 0.16, calmSpeedMul = 0.55, calmAccelMul = 0.60,
        barSize = 0.225, progressGain = 0.18, progressLoss = 0.22
    }
}

local defaultProfiles = {
    {
        behavior = "smooth", difficulty = 1,
        fishSpeed = 0.43, fishAccel = 1.95, changeMin = 0.72, changeMax = 1.40,
        barSize = 0.28, progressGain = 0.22, progressLoss = 0.18
    },
    {
        behavior = "mixed", difficulty = 2,
        fishSpeed = 0.56, fishAccel = 2.55, changeMin = 0.48, changeMax = 1.05,
        barSize = 0.24, progressGain = 0.20, progressLoss = 0.22
    },
    {
        behavior = "dart", difficulty = 3,
        fishSpeed = 0.70, fishAccel = 3.10, changeMin = 0.34, changeMax = 0.86,
        calmChance = 0.32, calmDurationMin = 0.90, calmDurationMax = 1.55,
        calmDistance = 0.16, calmSpeedMul = 0.56, calmAccelMul = 0.62,
        barSize = 0.21, progressGain = 0.18, progressLoss = 0.26
    }
}

local fishingSessions = {}
local SESSION_TIMEOUT_MS = 60000
local MIN_VALID_WIN_MS = 1800

local function copyProfile(profile)
    local result = {}
    for k, v in pairs(profile or {}) do result[k] = v end
    return result
end

local function getProfile(item, index)
    local profile = fishingProfiles[tostring(item or ""):lower()]
    if profile then return copyProfile(profile) end

    local slot = ((tonumber(index) or 1) - 1) % #defaultProfiles + 1
    return copyProfile(defaultProfiles[slot])
end

local function isFishingServiceActive(user_id)
    return type(MageEmpregosIsServiceActive) == "function" and MageEmpregosIsServiceActive(user_id, "Pescador")
end

local function isNearFishingSpot(playerSource, maxDistance)
    local ped = GetPlayerPed(playerSource)
    if not ped or ped == 0 then return false end

    local coords = GetEntityCoords(ped)
    maxDistance = tonumber(maxDistance) or 5.0

    for _, spot in ipairs(configpesca.locais or {}) do
        local dx = coords.x - (tonumber(spot[1]) or 0.0)
        local dy = coords.y - (tonumber(spot[2]) or 0.0)
        local dz = coords.z - (tonumber(spot[3]) or 0.0)
        if math.sqrt((dx * dx) + (dy * dy) + (dz * dz)) <= maxDistance then
            return true
        end
    end

    return false
end

local function clearFishingSession(user_id)
    if user_id then fishingSessions[tonumber(user_id)] = nil end
end

local function buildClientChallenge(session)
    local p = session.profile
    return {
        token = session.token,
        seed = session.seed,
        behavior = p.behavior,
        difficulty = p.difficulty,
        fishSpeed = p.fishSpeed,
        fishAccel = p.fishAccel,
        changeMin = p.changeMin,
        changeMax = p.changeMax,
        barSize = p.barSize,
        progressGain = p.progressGain,
        progressLoss = p.progressLoss,
        startProgress = 0.28,
        gravity = 1.82,
        liftForce = 1.88,
        maxBarSpeed = 0.82,
        barBounce = 0.34,
        timeoutMs = 45000
    }
end

function src.hasFishingBait()
    local playerSource = source
    local user_id = vRP.getUserId(playerSource)
    if not user_id then return false end

    if not MageEmpregosHasJob(user_id, "Pescador") then
        MageEmpregosLogInvalid(playerSource, "verificar isca", "Tentativa de iniciar pesca sem estar empregado como Pescador.")
        return false
    end

    if (tonumber(vRP.getInventoryItemAmount(user_id, configpesca.required)) or 0) < 1 then
        TriggerClientEvent('Notify',playerSource,'negado','Você não possui isca!',5000)
        return false
    end

    return true
end

-- Compatibilidade com versões anteriores do client. Não é usado pelo fluxo novo.
function src.checkItem()
    return src.hasFishingBait()
end

function src.startFishingChallenge()
    local playerSource = source
    local user_id = vRP.getUserId(playerSource)
    if not user_id then return { ok = false, reason = "invalid_user" } end

    if not MageEmpregosHasJob(user_id, "Pescador") or not isFishingServiceActive(user_id) then
        MageEmpregosLogInvalid(playerSource, "iniciar minigame de pesca", "Tentativa sem expediente de Pescador ativo.")
        return { ok = false, reason = "not_in_service" }
    end

    if not isNearFishingSpot(playerSource, 6.0) then
        MageEmpregosLogInvalid(playerSource, "iniciar minigame de pesca", "Tentativa fora dos pontos configurados de pesca.")
        return { ok = false, reason = "too_far" }
    end

    local now = GetGameTimer()
    local existing = fishingSessions[user_id]
    if existing and (now - existing.startedAt) <= SESSION_TIMEOUT_MS then
        -- Nunca reabra uma sessão ainda ativa. Se o client pedir outra fisgada
        -- antes de concluir a atual, recusamos em vez de devolver o mesmo token.
        -- Isso elimina capturas duplicadas e sobreposição de minigames.
        return { ok = false, reason = "challenge_active" }
    end
    fishingSessions[user_id] = nil

    if (tonumber(vRP.getInventoryItemAmount(user_id, configpesca.required)) or 0) < 1 then
        TriggerClientEvent('Notify',playerSource,'aviso','Suas iscas acabaram.',5000)
        return { ok = false, reason = "no_bait" }
    end

    if not vRP.tryGetInventoryItem(user_id, configpesca.required, 1) then
        TriggerClientEvent('Notify',playerSource,'aviso','Suas iscas acabaram.',5000)
        return { ok = false, reason = "no_bait" }
    end

    if type(configpesca.peixes) ~= "table" or #configpesca.peixes < 1 then
        TriggerClientEvent('Notify',playerSource,'negado','Nenhum peixe está configurado para este emprego.',5000)
        return { ok = false, reason = "no_fish_config" }
    end

    local index = math.random(#configpesca.peixes)
    local caughtFish = configpesca.peixes[index] and configpesca.peixes[index].x
    if not caughtFish or caughtFish == "" then
        return { ok = false, reason = "invalid_fish" }
    end

    local profile = getProfile(caughtFish, index)
    local seed = math.random(100000, 999999999)
    local token = ("%s:%s:%s:%s"):format(user_id, now, seed, math.random(10000,99999))

    local session = {
        source = playerSource,
        token = token,
        fish = caughtFish,
        fishIndex = index,
        profile = profile,
        seed = seed,
        startedAt = now
    }
    fishingSessions[user_id] = session

    TriggerClientEvent('Notify',playerSource,'aviso','1x Isca utilizada',3500)
    MageEmpregosLog("job_pescador_bait_used", {
        actorId = user_id,
        details = ("Item consumido: %s\nQuantidade: 1\nMotivo: minigame de pesca iniciado."):format(tostring(configpesca.required))
    })

    return { ok = true, challenge = buildClientChallenge(session) }
end

function src.finishFishingChallenge(token, success, elapsedMs)
    local playerSource = source
    local user_id = vRP.getUserId(playerSource)
    if not user_id then return { ok = false, reason = "invalid_user" } end

    local session = fishingSessions[user_id]
    if not session or session.source ~= playerSource or tostring(session.token) ~= tostring(token or "") then
        MageEmpregosLogInvalid(playerSource, "finalizar minigame de pesca", "Sessão/token de pesca inválido ou inexistente.")
        return { ok = false, reason = "invalid_session" }
    end

    -- Invalida antes de qualquer recompensa para impedir reuso do mesmo resultado.
    fishingSessions[user_id] = nil

    if not MageEmpregosHasJob(user_id, "Pescador") or not isFishingServiceActive(user_id) then
        return { ok = false, reason = "not_in_service" }
    end

    if not isNearFishingSpot(playerSource, 8.0) then
        MageEmpregosLogInvalid(playerSource, "finalizar captura de peixe", "O jogador saiu da área de pesca durante o minigame.")
        return { ok = false, reason = "too_far" }
    end

    local serverElapsed = GetGameTimer() - session.startedAt
    local clientElapsed = math.floor(tonumber(elapsedMs) or 0)
    if serverElapsed > SESSION_TIMEOUT_MS or clientElapsed > SESSION_TIMEOUT_MS then
        return { ok = false, escaped = true, reason = "timeout" }
    end

    if success ~= true then
        MageEmpregosLog("job_pescador_escaped", {
            actorId = user_id,
            details = ("Peixe da tentativa: %s\nResultado: escapou/cancelado\nTempo: %d ms"):format(tostring(session.fish), math.max(clientElapsed, 0))
        })
        return { ok = true, escaped = true }
    end

    if serverElapsed < MIN_VALID_WIN_MS or clientElapsed < MIN_VALID_WIN_MS then
        MageEmpregosLogInvalid(playerSource, "captura de peixe", ("Resultado impossível/rápido demais. Server: %d ms | Client: %d ms"):format(serverElapsed, clientElapsed))
        return { ok = false, reason = "too_fast" }
    end

    local caughtFish = session.fish
    if (vRP.computeInvWeight(user_id) + vRP.getItemWeight(caughtFish)) > vRP.getInventoryMaxWeight(user_id) then
        TriggerClientEvent('Notify',playerSource,'aviso','Espaço insuficiente',5000)
        return { ok = true, inventoryFull = true }
    end

    vRP.giveInventoryItem(user_id,caughtFish,1,true)
    TriggerClientEvent('Notify',playerSource,'sucesso','Você acaba de pescar um: '..caughtFish,5000)

    MageEmpregosLog("job_pescador_caught", {
        actorId = user_id,
        details = ("Peixe pescado: %s\nQuantidade: 1\nNível do pescador: %s\nDificuldade: %s\nComportamento: %s\nTempo do minigame: %d ms"):format(
            caughtFish,
            tostring(src.get_level() or 1),
            tostring(session.profile.difficulty),
            tostring(session.profile.behavior),
            clientElapsed
        )
    })

    if type(MageEmpregosGrantXp) == "function" then
        MageEmpregosGrantXp(playerSource, "Pescador")
    end

    return { ok = true, caught = true, fish = caughtFish }
end

function src.cancelFishingChallenge(token)
    local playerSource = source
    local user_id = vRP.getUserId(playerSource)
    if not user_id then return false end

    local session = fishingSessions[user_id]
    if session and (not token or token == "" or tostring(session.token) == tostring(token)) then
        fishingSessions[user_id] = nil
        return true
    end
    return false
end

function src.sellFish()
    local playerSource = source
    local user_id = vRP.getUserId(playerSource)
    if not user_id then return false end

    if not MageEmpregosHasJob(user_id, "Pescador") then
        MageEmpregosLogInvalid(playerSource, "vender peixes", "Tentativa de vender peixes sem estar empregado como Pescador.")
        return false
    end

    local level = tonumber(src.get_level()) or 1
    local soldAny = false
    for fish, values in pairs(configpesca.sell or {}) do
        local amount = tonumber(vRP.getInventoryItemAmount(user_id, fish)) or 0
        local levelValues = type(values) == "table" and values[level] or nil
        if amount >= 1 and type(levelValues) == "table" and levelValues[1] and levelValues[2] then
            local minValue = tonumber(levelValues[1]) or 0
            local maxValue = tonumber(levelValues[2]) or 0
            if maxValue < minValue then minValue, maxValue = maxValue, minValue end
            local unitValue = math.random(minValue, maxValue)
            local payment = unitValue * amount

            if vRP.tryGetInventoryItem(user_id, fish, amount, true) then
                vRP.giveBankMoney(user_id,payment)
                TriggerClientEvent('Notify',playerSource,'sucesso','[Pescador Nivel '..level..'] Você vendeu x'..amount..' '..fish..' e recebeu R$ '..payment..'',5000)
                MageEmpregosLog("job_pescador_sold", {
                    actorId = user_id,
                    details = ("Peixe vendido: %s\nQuantidade: %d\nValor unitário: %s\nTotal recebido: %s\nNível: %d"):format(
                        fish, amount, MageEmpregosMoney(unitValue), MageEmpregosMoney(payment), level
                    )
                })
                soldAny = true
            end
        end
    end
    return soldAny
end

-- Funções legadas mantidas para não quebrar chamadas externas antigas.
function src.catchFish()
    MageEmpregosLogInvalid(source, "catchFish legado", "A recompensa direta foi bloqueada. Use o minigame de pesca.")
    return false
end

function src.taskcheck()
    MageEmpregosLogInvalid(source, "taskcheck legado", "O taskbar antigo foi substituído pelo minigame de pesca.")
    return false
end

AddEventHandler("m_empregos:serverConfigUpdated",function()
    local e = cfg.extra and cfg.extra["Pescador"] or {}
    configpesca.required = e.item_necessario or configpesca.required

    if type(e.locais_pesca) == "table" and #e.locais_pesca > 0 then
        configpesca.locais = e.locais_pesca
    end

    if type(e.peixes) == "table" and #e.peixes > 0 then
        configpesca.peixes = {}
        for i,item in ipairs(e.peixes) do
            configpesca.peixes[i] = { x = item }
        end
    end

    if type(e.valores_venda) == "table" then
        configpesca.sell = e.valores_venda
    end
end)

AddEventHandler("playerDropped", function()
    local playerSource = source
    local user_id = vRP.getUserId(playerSource)
    if user_id then
        clearFishingSession(user_id)
        return
    end

    for id, session in pairs(fishingSessions) do
        if session and session.source == playerSource then
            fishingSessions[id] = nil
            break
        end
    end
end)
