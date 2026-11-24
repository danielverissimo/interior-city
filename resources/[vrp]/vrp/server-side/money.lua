--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CACHE
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local cache = {}
cache['getBankMoney'] = {}
cache['getMakapoints'] = {}
cache['getMultas'] = {}

local function auditOrigin()
    return type(vRP.mageAuditOrigin) == "function" and vRP.mageAuditOrigin() or (GetInvokingResource() or GetCurrentResourceName() or "vrp")
end

local function audit(logKey, user_id, details, target_id, actorLabel)
    if type(vRP.mageAuditLog) ~= "function" then return end
    vRP.mageAuditLog(logKey, {
        actorId = tonumber(user_id),
        targetId = tonumber(target_id),
        actorLabel = actorLabel or "JOGADOR AFETADO",
        details = details
    })
end

local function pushContext(name)
    if type(vRP.mageAuditPush) == "function" then vRP.mageAuditPush(name) end
end

local function popContext(name)
    if type(vRP.mageAuditPop) == "function" then vRP.mageAuditPop(name) end
end

local function inContext(name)
    return type(vRP.mageAuditIn) == "function" and vRP.mageAuditIn(name) or false
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CARTEIRA
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function vRP.getMoney(user_id)
    if user_id then
        return parseInt(vRP.getInventoryItemAmount(user_id, "money")) or 0
    end
end

function vRP.giveMoney(user_id,amount)
    if user_id then
        amount = parseInt(amount)
        if amount > 0 then
            local before = parseInt(vRP.getMoney(user_id))
            pushContext("vrp_give_money")
            local given = vRP.giveInventoryItem(user_id, "money", amount, false)
            popContext("vrp_give_money")
            if not given then return false end

            local after = parseInt(vRP.getMoney(user_id))
            if not inContext("vrp_bank_withdraw") then
                audit("vrp_wallet_give_money", user_id,
                    ("**Resource:** %s\n**Função:** vRP.giveMoney\n**Valor adicionado:** R$ %d\n**Carteira antes:** R$ %d\n**Carteira depois:** R$ %d"):format(
                        auditOrigin(), amount, before, after
                    ))
            end
            return true
        end
    end
    return false
end

function vRP.tryPayment(user_id, amount)
    if user_id then
        amount = parseInt(amount)
        if amount > 0 then
            local walletBefore = parseInt(vRP.getMoney(user_id))
            local bankBefore = parseInt(vRP.getBankMoney(user_id))
            pushContext("vrp_try_payment")
            local ok = vRP.tryFullPayment(user_id, amount)
            popContext("vrp_try_payment")
            if ok then
                local walletAfter = parseInt(vRP.getMoney(user_id))
                local bankAfter = parseInt(vRP.getBankMoney(user_id))
                local sourceAccount = bankAfter < bankBefore and "Banco" or "Carteira"
                audit("vrp_try_payment", user_id,
                    ("**Resource:** %s\n**Função:** vRP.tryPayment\n**Valor pago:** R$ %d\n**Origem:** %s\n**Carteira:** R$ %d → R$ %d\n**Banco:** R$ %d → R$ %d"):format(
                        auditOrigin(), amount, sourceAccount, walletBefore, walletAfter, bankBefore, bankAfter
                    ))
            end
            return ok
        end
        return false
    end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MAKAPOINTS
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function vRP.giveMakapoints(user_id, amount)
    if user_id then
        amount = parseInt(amount)
        if amount > 0 then
            local before = parseInt(vRP.getMakapoints(user_id))
            local after = before + amount
            pushContext("vrp_give_makapoints")
            cache['getMakapoints'][user_id] = after
            vRP.setMakapoints(user_id, after)
            popContext("vrp_give_makapoints")
            audit("vrp_makapoints_give", user_id,
                ("**Resource:** %s\n**Função:** vRP.giveMakapoints\n**Pontos adicionados:** %d\n**Antes:** %d\n**Depois:** %d"):format(
                    auditOrigin(), amount, before, after
                ))
        end
    end
end
 
function vRP.getMakapoints(user_id)
    local source = vRP.getUserSource(user_id)
    if source then
        if user_id then
            if cache['getMakapoints'][user_id] == nil then
                local rows = vRP.query("vRP/get_user_identity",{ user_id = user_id })
                if rows[1] then
                    cache['getMakapoints'][user_id] = parseInt(rows[1].makapoints)
                end
            end
            
            return cache['getMakapoints'][user_id] or 0
        end
    else
        local rows = vRP.query("vRP/get_user_identity",{ user_id = user_id })
        if rows[1] then
            return parseInt(rows[1].makapoints)
        end
    end
end

function vRP.setMakapoints(user_id, amount)
    local source = vRP.getUserSource(user_id)
    amount = parseInt(amount)
    if amount < 0 then return end
    local before = parseInt(vRP.getMakapoints(user_id))
    if source then
        if user_id then
            cache['getMakapoints'][user_id] = amount
            vRP.execute("vRP/update_makapoints",{ user_id = user_id, makapoints = cache['getMakapoints'][user_id] })
        end
    else
        vRP.execute("vRP/update_makapoints",{ user_id = user_id, makapoints = amount })
        cache['getMakapoints'][user_id] = amount
    end

    if before ~= amount and not inContext("vrp_give_makapoints") then
        audit("vrp_makapoints_set", user_id,
            ("**Resource:** %s\n**Função:** vRP.setMakapoints\n**Antes:** %d\n**Depois:** %d\n**Diferença:** %+d"):format(
                auditOrigin(), before, amount, amount - before
            ))
    end
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- BANCO
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function vRP.giveBankMoney(user_id, amount)
    if user_id then
        amount = parseInt(amount)
        if amount > 0 then
            local before = parseInt(vRP.getBankMoney(user_id))
            local after = before + amount
            pushContext("vrp_give_bank_money")
            cache['getBankMoney'][user_id] = after
            vRP.setBankMoney(user_id, after)
            popContext("vrp_give_bank_money")
            audit("vrp_bank_give_money", user_id,
                ("**Resource:** %s\n**Função:** vRP.giveBankMoney\n**Valor adicionado:** R$ %d\n**Banco antes:** R$ %d\n**Banco depois:** R$ %d"):format(
                    auditOrigin(), amount, before, after
                ))
        end
    end
end
 
function vRP.getBankMoney(user_id)
    local source = vRP.getUserSource(user_id)
    if source then
        if user_id then
            if cache['getBankMoney'][user_id] == nil then
                local rows = vRP.query("vRP/get_user_identity",{ user_id = user_id })
                if rows[1] then
                    cache['getBankMoney'][user_id] = parseInt(rows[1].banco)
                end
            end
            
            return cache['getBankMoney'][user_id] or 0
        end
    else
        local rows = vRP.query("vRP/get_user_identity",{ user_id = user_id })
        if rows[1] then
            return parseInt(rows[1].banco)
        end
    end
end

function vRP.setBankMoney(user_id, amount)
    amount = parseInt(amount)
    if not user_id or amount < 0 then return end
    local before = parseInt(vRP.getBankMoney(user_id))
    local source = vRP.getUserSource(user_id)
    if source then
        cache['getBankMoney'][user_id] = amount
        vRP.execute("vRP/update_banco",{ user_id = user_id, banco = amount })
    else
        vRP.execute("vRP/update_banco",{ user_id = user_id, banco = amount })
        cache['getBankMoney'][user_id] = amount
    end

    local suppressed = inContext("vrp_give_bank_money") or inContext("vrp_bank_withdraw") or inContext("vrp_bank_deposit")
        or inContext("vrp_bank_transfer") or inContext("vrp_full_payment") or inContext("vrp_try_payment")
    if before ~= amount and not suppressed then
        audit("vrp_bank_set_balance", user_id,
            ("**Resource:** %s\n**Função:** vRP.setBankMoney\n**Banco antes:** R$ %d\n**Banco depois:** R$ %d\n**Diferença:** %+d"):format(
                auditOrigin(), before, amount, amount - before
            ))
    end
end

function vRP.tryWithdraw(user_id, amount)
    if user_id then
        amount = parseInt(amount)
        if amount > 0 then
            local bankBefore = parseInt(vRP.getBankMoney(user_id))
            local walletBefore = parseInt(vRP.getMoney(user_id))
            if bankBefore >= amount then
                pushContext("vrp_bank_withdraw")
                local credited = vRP.giveMoney(user_id, amount)
                if credited then
                    vRP.setBankMoney(user_id, bankBefore - amount)
                end
                popContext("vrp_bank_withdraw")
                if credited then
                    audit("vrp_bank_withdraw", user_id,
                        ("**Resource:** %s\n**Função:** vRP.tryWithdraw\n**Valor sacado:** R$ %d\n**Banco:** R$ %d → R$ %d\n**Carteira:** R$ %d → R$ %d"):format(
                            auditOrigin(), amount, bankBefore, bankBefore - amount, walletBefore, parseInt(vRP.getMoney(user_id))
                        ))
                    return true
                end
            end
        end
        return false
    end
end

function vRP.tryDeposit(user_id, amount)
    if user_id then
        amount = parseInt(amount)
        if amount > 0 then
            local walletBefore = parseInt(vRP.getMoney(user_id))
            local bankBefore = parseInt(vRP.getBankMoney(user_id))
            if walletBefore >= amount then
                pushContext("vrp_bank_deposit")
                local removed = vRP.tryGetInventoryItem(user_id, "money", amount)
                if removed then
                    vRP.setBankMoney(user_id, bankBefore + amount)
                end
                popContext("vrp_bank_deposit")
                if removed then
                    audit("vrp_bank_deposit", user_id,
                        ("**Resource:** %s\n**Função:** vRP.tryDeposit\n**Valor depositado:** R$ %d\n**Carteira:** R$ %d → R$ %d\n**Banco:** R$ %d → R$ %d"):format(
                            auditOrigin(), amount, walletBefore, parseInt(vRP.getMoney(user_id)), bankBefore, parseInt(vRP.getBankMoney(user_id))
                        ))
                    return true
                end
            end
        end
        return false
    end
end

function vRP.tryTransfer(user_id, target_id, amount)
    target_id = parseInt(target_id)
    if user_id then
        amount = parseInt(amount)
        if amount > 0 and target_id > 0 then
            local banco = parseInt(vRP.getBankMoney(user_id))
            local nbanco = vRP.getBankMoney(target_id)
            if nbanco ~= nil and banco >= amount then
                nbanco = parseInt(nbanco)
                pushContext("vrp_bank_transfer")
                vRP.setBankMoney(user_id, banco - amount)
                vRP.setBankMoney(target_id, nbanco + amount)
                popContext("vrp_bank_transfer")
                audit("vrp_bank_transfer", user_id,
                    ("**Resource:** %s\n**Função:** vRP.tryTransfer\n**Valor transferido:** R$ %d\n**Banco origem:** R$ %d → R$ %d\n**Banco destino:** R$ %d → R$ %d"):format(
                        auditOrigin(), amount, banco, banco - amount, nbanco, nbanco + amount
                    ), target_id, "JOGADOR ORIGEM")
                return true
            end
        end
        return false
    end
end

function vRP.tryFullPayment(user_id,amount)
    amount = parseInt(amount)
    if not user_id or amount < 0 then return false end
    if amount == 0 then return true end

    local bankBefore = parseInt(vRP.getBankMoney(user_id))
    local walletBefore = parseInt(vRP.getMoney(user_id))
    local paidFrom = nil

    pushContext("vrp_full_payment")
    if bankBefore >= amount then
        vRP.setBankMoney(user_id, bankBefore - amount)
        paidFrom = "Banco"
    elseif walletBefore >= amount then
        if vRP.tryGetInventoryItem(user_id,"money",amount,true) then
            paidFrom = "Carteira"
        end
    end
    popContext("vrp_full_payment")

    if paidFrom then
        if not inContext("vrp_try_payment") then
            audit("vrp_full_payment", user_id,
                ("**Resource:** %s\n**Função:** vRP.tryFullPayment\n**Valor pago:** R$ %d\n**Origem:** %s\n**Carteira:** R$ %d → R$ %d\n**Banco:** R$ %d → R$ %d"):format(
                    auditOrigin(), amount, paidFrom, walletBefore, parseInt(vRP.getMoney(user_id)), bankBefore, parseInt(vRP.getBankMoney(user_id))
                ))
        end
        return true
    end
    return false
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MULTAS
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function vRP.getMultas(user_id)
    if user_id then
        if cache['getMultas'][user_id] == nil then
            local rows = vRP.query("vRP/get_user_identity",{ user_id = user_id })
            if rows[1] then
                cache['getMultas'][user_id] = parseInt(rows[1].multas)
            end
        end

        return cache['getMultas'][user_id] or 0
    end
end

function vRP.updateMultas(user_id, amount)
    if user_id then
        local before = parseInt(vRP.getMultas(user_id))
        amount = parseInt(amount)
        cache['getMultas'][user_id] = amount
        vRP.execute("vRP/update_multas",{ user_id = user_id, multas = amount })
        if before ~= amount then
            audit("vrp_fines_update", user_id,
                ("**Resource:** %s\n**Função:** vRP.updateMultas\n**Multas antes:** R$ %d\n**Multas depois:** R$ %d\n**Diferença:** %+d"):format(
                    auditOrigin(), before, amount, amount - before
                ))
        end
        return
    end
end

AddEventHandler("playerDropped", function(reason)
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        cache['getBankMoney'][user_id] = nil
        cache['getMakapoints'][user_id] = nil
        cache['getMultas'][user_id] = nil
    end
end)
