-- print('[DEBUG]: Server Pescador Init Sucess')

-- configpesca = module("emp_pescador","configpesca")

-----------------------------------------------------------------------------------------------------------------------------------------
-- FUNÇÕES
-----------------------------------------------------------------------------------------------------------------------------------------

local catchedFish = ""

configpesca = {}

configpesca.required = "isca"

configpesca.peixes = {
    [1] = { x = "dourado" },
    [2] = { x = "corvina" },
    [3] = { x = "salmao" }
}

configpesca.sell = {
	["dourado"] = {
            [1] = { 100,500 },
            [2] = { 600,900 },
            [3] = { 1000,1500 },
            [4] = { 1600,2300 },
            [5] = { 2400, 3000 }
        },
	["corvina"] = {
            [1] = { 100,500 },
            [2] = { 600,900 },
            [3] = { 1000,1500 },
            [4] = { 1600,2300 },
            [5] = { 2400, 3000 }
        },
	["salmao"] = {
            [1] = { 100,500 },
            [2] = { 600,900 },
            [3] = { 1000,1500 },
            [4] = { 1600,2300 },
            [5] = { 2400, 3000 }
        }
}

function src.checkItem()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return false end

    if not MageEmpregosHasJob(user_id, "Pescador") then
        MageEmpregosLogInvalid(source, "utilizar isca", "Tentativa de iniciar/continuar a pesca sem estar empregado como Pescador.")
        return false
    end

    if vRP.getInventoryItemAmount(user_id, configpesca.required) >= 1 then
        if vRP.tryGetInventoryItem(user_id, configpesca.required, 1) then
            TriggerClientEvent('Notify',source,'aviso','1x Isca utilizada',5000)
            MageEmpregosLog("job_pescador_bait_used", {
                actorId = user_id,
                details = ("Item consumido: %s\nQuantidade: 1\nMotivo: tentativa de pesca."):format(tostring(configpesca.required))
            })
            return true
        end
    end

    TriggerClientEvent('Notify',source,'negado','Você não possui isca!',5000)
    return false
end

function src.sellFish()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return false end

    if not MageEmpregosHasJob(user_id, "Pescador") then
        MageEmpregosLogInvalid(source, "vender peixes", "Tentativa de vender peixes sem estar empregado como Pescador.")
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
                TriggerClientEvent('Notify',source,'sucesso','[Pescador Nivel '..level..'] Você vendeu x'..amount..' '..fish..' e recebeu R$ '..payment..'',5000)
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

function src.catchFish()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return false end

    if not MageEmpregosHasJob(user_id, "Pescador") then
        MageEmpregosLogInvalid(source, "coletar peixe", "Tentativa de receber um peixe sem estar empregado como Pescador.")
        return false
    end

    if type(configpesca.peixes) ~= "table" or #configpesca.peixes < 1 then return false end
    local caughtFish = configpesca.peixes[math.random(#configpesca.peixes)].x
    if not caughtFish or caughtFish == "" then return false end

    if (vRP.computeInvWeight(user_id) + vRP.getItemWeight(caughtFish) <= vRP.getInventoryMaxWeight(user_id)) then
        vRP.giveInventoryItem(user_id,caughtFish,1,true)
        TriggerClientEvent('Notify',source,'sucesso','Você acaba de pescar um: '..caughtFish)
        MageEmpregosLog("job_pescador_caught", {
            actorId = user_id,
            details = ("Peixe pescado: %s\nQuantidade: 1\nNível do pescador: %s"):format(caughtFish, tostring(src.get_level() or 1))
        })
        return true
    else
        TriggerClientEvent('Notify',source,'aviso','Espaço insuficiente')
    end
    return false
end

function src.taskcheck()
	local finished = vRPclient.taskBar(source, 3000, math.random(7, 15))
    if finished then
		return true
	end
end



AddEventHandler("m_empregos:serverConfigUpdated",function()
    local e=cfg.extra and cfg.extra["Pescador"] or {}
    configpesca.required=e.item_necessario or configpesca.required
    if e.peixes then
        configpesca.peixes={}
        for i,item in ipairs(e.peixes) do configpesca.peixes[i]={x=item} end
    end
    configpesca.sell=e.valores_venda or configpesca.sell
end)
