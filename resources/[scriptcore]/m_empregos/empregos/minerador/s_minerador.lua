-----------------------------------------------------------------------------
------ VARIABLES
-----------------------------------------------------------------------------

local minerios = {
    [1] = { x = "bronze" },
    [2] = { x = "ferro" },
    [3] = { x = "ouro" },
    [4] = { x = "diamante" },
    [5] = { x = "rubi" },
    [6] = { x = "safira" }
}

local sell_miner = {
	["bronze"] = {
            [1] = { 100,500 },
            [2] = { 600,900 },
            [3] = { 1000,1500 },
            [4] = { 1600,2300 },
            [5] = { 2400, 3000 }
    },
	["ferro"] = {
            [1] = { 100,500 },
            [2] = { 600,900 },
            [3] = { 1000,1500 },
            [4] = { 1600,2300 },
            [5] = { 2400, 3000 }
    },
	["ouro"] = {
            [1] = { 100,500 },
            [2] = { 600,900 },
            [3] = { 1000,1500 },
            [4] = { 1600,2300 },
            [5] = { 2400, 3000 }
    },
    ["diamante"] = {
            [1] = { 100,500 },
            [2] = { 600,900 },
            [3] = { 1000,1500 },
            [4] = { 1600,2300 },
            [5] = { 2400, 3000 }
    },
	["rubi"] = {
            [1] = { 100,500 },
            [2] = { 600,900 },
            [3] = { 1000,1500 },
            [4] = { 1600,2300 },
            [5] = { 2400, 3000 }
    },
	["safira"] = {
            [1] = { 100,500 },
            [2] = { 600,900 },
            [3] = { 1000,1500 },
            [4] = { 1600,2300 },
            [5] = { 2400, 3000 }
    }
}

-----------------------------------------------------------------------------
------ FUNCTIONS
-----------------------------------------------------------------------------

function src.pickMinerio()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return false end

    if not MageEmpregosHasJob(user_id, "Minerador") then
        MageEmpregosLogInvalid(source, "coletar minério", "Tentativa de coletar minério sem estar empregado como Minerador.")
        return false
    end

    if type(minerios) ~= "table" or #minerios < 1 then return false end
    local randomMiner = minerios[math.random(#minerios)].x
    if not randomMiner or randomMiner == "" then return false end

    if (vRP.computeInvWeight(user_id) + vRP.getItemWeight(randomMiner) <= vRP.getInventoryMaxWeight(user_id)) then
        vRP.giveInventoryItem(user_id,randomMiner,1,true)
        TriggerClientEvent('Notify',source,'sucesso','Você acaba de pegar um: '..randomMiner)
        MageEmpregosLog("job_minerador_collected", {
            actorId = user_id,
            details = ("Item coletado: %s\nQuantidade: 1\nNível do minerador: %s"):format(randomMiner, tostring(src.get_level() or 1))
        })
        return true
    else
        TriggerClientEvent('Notify',source,'aviso','Espaço insuficiente')
    end
    return false
end

function src.sellMiner()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return false end

    if not MageEmpregosHasJob(user_id, "Minerador") then
        MageEmpregosLogInvalid(source, "vender minérios", "Tentativa de vender minérios sem estar empregado como Minerador.")
        return false
    end

    local level = tonumber(src.get_level()) or 1
    local soldAny = false

    for mineral, values in pairs(sell_miner or {}) do
        local amount = tonumber(vRP.getInventoryItemAmount(user_id, mineral)) or 0
        local levelValues = type(values) == "table" and values[level] or nil
        if amount >= 1 and type(levelValues) == "table" and levelValues[1] and levelValues[2] then
            local minValue = tonumber(levelValues[1]) or 0
            local maxValue = tonumber(levelValues[2]) or 0
            if maxValue < minValue then minValue, maxValue = maxValue, minValue end
            local unitValue = math.random(minValue, maxValue)
            local payment = unitValue * amount

            if vRP.tryGetInventoryItem(user_id, mineral, amount, true) then
                vRP.giveBankMoney(user_id,payment)
                TriggerClientEvent('Notify',source,'sucesso','[Minerador Nivel '..level..'] Você vendeu x'..amount..' '..mineral..' e recebeu R$ '..payment..'',5000)
                MageEmpregosLog("job_minerador_sold", {
                    actorId = user_id,
                    details = ("Minério vendido: %s\nQuantidade: %d\nValor unitário: %s\nTotal recebido: %s\nNível: %d"):format(
                        mineral, amount, MageEmpregosMoney(unitValue), MageEmpregosMoney(payment), level
                    )
                })
                soldAny = true
            end
        end
    end

    return soldAny
end

AddEventHandler("m_empregos:serverConfigUpdated",function()
    local e=cfg.extra and cfg.extra["Minerador"] or {}
    if e.minerios then
        minerios={}
        for i,item in ipairs(e.minerios) do minerios[i]={x=item} end
    end
    sell_miner=e.valores_venda or sell_miner
end)
