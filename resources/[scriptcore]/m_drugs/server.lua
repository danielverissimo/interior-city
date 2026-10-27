local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")

local vRP = Proxy.getInterface("vRP")
local API = {}
Tunnel.bindInterface("m_drugs", API)

local function getDrugConfig(drugName)
    return Config and Config.Drugs and Config.Drugs[drugName]
end

local function hasAnyPermission(userId, permissions)
    if not permissions or #permissions == 0 then
        return true
    end

    for _, permission in pairs(permissions) do
        if vRP.hasPermission(userId, permission) then
            return true
        end
    end

    return false
end

local function getRewardAmount(drug)
    if drug.reward.amount then
        return drug.reward.amount
    end

    local min = drug.reward.min or 1
    local max = drug.reward.max or min
    return math.random(min, max)
end

local function hasInventorySpace(userId, item, amount)
    return vRP.computeInvWeight(parseInt(userId)) + (vRP.getItemWeight(item) * amount) <= vRP.getInventoryMaxWeight(parseInt(userId))
end

function API.checkPermission(drugName)
    local source = source
    local userId = vRP.getUserId(source)
    local drug = getDrugConfig(drugName)

    if not userId or not drug then
        return false
    end

    if not hasAnyPermission(userId, drug.permissions) then
        TriggerClientEvent("Notify", source, "negado", "Você não tem permissão para <b>produzir "..drugName.."</b>.", 5000)
        return false
    end

    local checkAmount = drug.reward.amount or drug.reward.max or 1
    if not hasInventorySpace(userId, drug.reward.item, checkAmount) then
        TriggerClientEvent("Notify", source, "negado", "Mochila cheia.", 5000)
        return false
    end

    return true
end

function API.finishProduction(drugName)
    local source = source
    local userId = vRP.getUserId(source)
    local drug = getDrugConfig(drugName)

    if not userId or not drug then
        return false
    end

    -- Revalida permissão no momento do pagamento para evitar recompensa
    -- indevida caso a produção seja acionada fora do fluxo normal do client.
    if not hasAnyPermission(userId, drug.permissions) then
        return false
    end

    local amount = getRewardAmount(drug)
    if not hasInventorySpace(userId, drug.reward.item, amount) then
        TriggerClientEvent("Notify", source, "negado", "Mochila cheia.", 5000)
        return false
    end

    vRP.giveInventoryItem(userId, drug.reward.item, amount,true)

    local names = {
        cocaina = "Cocaína",
        maconha = "Maconha",
        lsd = "LSD",
        metanfetamina = "Metanfetamina"
    }

    TriggerClientEvent("Notify", source, "sucesso", "Você produziu <b>"..amount.."x "..(names[drugName] or drugName).."</b>.", 5000)
    return true
end


-- Consome o adubo necessário antes de entregar o pote ao jogador.
function API.takeWeedFertilizer()
    local source = source
    local userId = vRP.getUserId(source)
    local drug = getDrugConfig("maconha")
    local planting = drug and drug.planting
    local requirement = planting and planting.fertilizerRequirement

    if not userId or not drug or not requirement then
        return false
    end

    if not hasAnyPermission(userId,drug.permissions) then
        TriggerClientEvent("Notify",source,"negado","Você não tem permissão para produzir maconha.",5000)
        return false
    end

    local item = requirement.item or "adubo"
    local amount = tonumber(requirement.amount) or 5
    local inventoryAmount = tonumber(vRP.getInventoryItemAmount(userId,item)) or 0

    if inventoryAmount < amount then
        TriggerClientEvent("Notify",source,"negado","Você precisa de <b>"..amount.."x "..item.."</b> para pegar o pote de adubo.",5000)
        return false
    end

    if not vRP.tryGetInventoryItem(userId,item,amount,true) then
        return false
    end

    return true
end

-- ============================================================================
-- PREPARO / EMBALAGEM DA MACONHA
-- ============================================================================
-- Guarda uma produção pendente por usuário para impedir que o client chame
-- diretamente a recompensa sem antes entregar a quantidade necessária.
local weedPreparation = {}

function API.startWeedPreparation()
    local source = source
    local userId = vRP.getUserId(source)
    local drug = getDrugConfig("maconha")
    local prep = drug and drug.preparation

    if not userId or not drug or not prep then
        return false
    end

    if weedPreparation[userId] then
        TriggerClientEvent("Notify",source,"negado","Você já está preparando maconha.",5000)
        return false
    end

    if not hasAnyPermission(userId,drug.permissions) then
        TriggerClientEvent("Notify",source,"negado","Você não tem permissão para <b>preparar maconha</b>.",5000)
        return false
    end

    local inventoryAmount = tonumber(vRP.getInventoryItemAmount(userId,prep.inputItem)) or 0
    local batchInput = tonumber(prep.inputAmount) or 10
    local batchOutput = tonumber(prep.outputAmount) or 2

    if inventoryAmount < batchInput then
        TriggerClientEvent(
            "Notify",
            source,
            "negado",
            "Você precisa de no mínimo <b>"..batchInput.."x Maconha</b> para preparar <b>"..batchOutput.."x malotes</b>.",
            5000
        )
        return false
    end

    -- Usa de uma vez todo múltiplo completo de 10 existente no inventário.
    -- Ex.: 10 -> 10, 20 -> 20, 25 -> 20 (sobram 5), 37 -> 30 (sobram 7).
    local batches = math.floor(inventoryAmount / batchInput)
    local inputAmount = batches * batchInput
    local outputAmount = batches * batchOutput

    if not hasInventorySpace(userId,prep.outputItem,outputAmount) then
        TriggerClientEvent("Notify",source,"negado","Mochila cheia para receber <b>"..outputAmount.."x malotes de maconha</b>.",5000)
        return false
    end

    if not vRP.tryGetInventoryItem(userId,prep.inputItem,inputAmount,true) then
        TriggerClientEvent("Notify",source,"negado","Você não possui maconha suficiente.",5000)
        return false
    end

    weedPreparation[userId] = {
        startedAt = os.time(),
        source = source,
        inputAmount = inputAmount,
        outputAmount = outputAmount
    }

    TriggerClientEvent(
        "Notify",
        source,
        "aviso",
        "Preparando <b>"..outputAmount.."x malotes</b> usando <b>"..inputAmount.."x maconhas</b>.",
        4000
    )

    return {
        inputAmount = inputAmount,
        outputAmount = outputAmount
    }
end

function API.finishWeedPreparation()
    local source = source
    local userId = vRP.getUserId(source)
    local drug = getDrugConfig("maconha")
    local prep = drug and drug.preparation
    local pending = userId and weedPreparation[userId]

    if not userId or not prep or not pending then
        return false
    end

    -- Não aceita finalizar instantaneamente pelo client.
    local minimumSeconds = math.max(1,math.floor((prep.duration or 15000) / 1000) - 1)
    if (os.time() - pending.startedAt) < minimumSeconds then
        return false
    end

    weedPreparation[userId] = nil

    local inputAmount = tonumber(pending.inputAmount) or (prep.inputAmount or 10)
    local outputAmount = tonumber(pending.outputAmount) or (prep.outputAmount or 2)

    if not hasInventorySpace(userId,prep.outputItem,outputAmount) then
        -- Se a mochila encheu durante a animação, devolve exatamente o que foi consumido.
        vRP.giveInventoryItem(userId,prep.inputItem,inputAmount,true)
        TriggerClientEvent("Notify",source,"negado","Sua mochila ficou cheia. A maconha foi devolvida.",5000)
        return false
    end

    vRP.giveInventoryItem(userId,prep.outputItem,outputAmount,true)
    TriggerClientEvent(
        "Notify",
        source,
        "sucesso",
        "Você preparou <b>"..outputAmount.."x malotes de maconha</b> usando <b>"..inputAmount.."x maconhas</b>.",
        5000
    )

    return true
end


-- ============================================================================
-- COCAÍNA - PASTA BASE / SEPARAÇÃO DO ÁCIDO
-- ============================================================================
local cocainePasteBase = {}

local function getMDrugsInventoryAmount(userId,item)
    return tonumber(vRP.getInventoryItemAmount(userId,item)) or 0
end

function API.startCocainePasteBase()
    local source = source
    local userId = vRP.getUserId(source)
    local drug = getDrugConfig("cocaina")
    local paste = drug and drug.pasteBase

    if not userId or not drug or not paste then
        return false
    end

    if cocainePasteBase[userId] then
        TriggerClientEvent("Notify",source,"negado","Você já está produzindo pasta base.",5000)
        return false
    end

    if not hasAnyPermission(userId,drug.permissions) then
        TriggerClientEvent("Notify",source,"negado","Você não tem permissão para produzir cocaína.",5000)
        return false
    end

    local item = paste.inputItem or "folhadecoca"
    local amount = tonumber(paste.inputAmount) or 10

    if getMDrugsInventoryAmount(userId,item) < amount then
        TriggerClientEvent(
            "Notify",source,"negado",
            "Você precisa de <b>"..amount.."x folhadecoca</b> para produzir pasta base.",
            5000
        )
        return false
    end

    if not vRP.tryGetInventoryItem(userId,item,amount,true) then
        return false
    end

    cocainePasteBase[userId] = {
        startedAt = os.time()
    }

    return true
end

function API.finishCocainePasteBase()
    local source = source
    local userId = vRP.getUserId(source)
    local drug = getDrugConfig("cocaina")
    local paste = drug and drug.pasteBase
    local pending = userId and cocainePasteBase[userId]

    if not userId or not paste or not pending then
        return false
    end

    local duration = tonumber(paste.duration) or 60000
    local minimumSeconds = math.max(1,math.floor(duration / 1000) - 1)

    if (os.time() - pending.startedAt) < minimumSeconds then
        return false
    end

    local outputItem = paste.outputItem or "pastabase"
    local outputAmount = tonumber(paste.outputAmount) or 5

    if not hasInventorySpace(userId,outputItem,outputAmount) then
        TriggerClientEvent("Notify",source,"negado","Mochila cheia.",5000)
        return false
    end

    cocainePasteBase[userId] = nil
    vRP.giveInventoryItem(userId,outputItem,outputAmount,true)

    TriggerClientEvent(
        "Notify",source,"sucesso",
        "Você coletou <b>"..outputAmount.."x pastabase</b>.",
        5000
    )

    return true
end

function API.separateCocaineAcid()
    local source = source
    local userId = vRP.getUserId(source)
    local drug = getDrugConfig("cocaina")
    local separation = drug and drug.acidSeparation

    if not userId or not drug or not separation then
        return false
    end

    if not hasAnyPermission(userId,drug.permissions) then
        return false
    end

    -- Para separar, ainda precisa POSSUIR os dois:
    -- 5x pastabase + 1x acido.
    for _,req in ipairs(separation.requirements or {}) do
        local amount = tonumber(req.amount) or 1
        if getMDrugsInventoryAmount(userId,req.item) < amount then
            TriggerClientEvent(
                "Notify",source,"negado",
                "Você precisa de <b>"..amount.."x "..req.item.."</b> para separar o ácido.",
                5000
            )
            return false
        end
    end

    -- Nesta etapa remove SOMENTE 1x acido.
    local consumeItem = separation.consumeItem or "acido"
    local consumeAmount = tonumber(separation.consumeAmount) or 1

    if not vRP.tryGetInventoryItem(userId,consumeItem,consumeAmount,true) then
        return false
    end

    return true
end


-- ============================================================================
-- COCAÍNA - PÓ DE COCAÍNA / PANELA
-- ============================================================================
local cocainePowderPreparation = {}

function API.startCocainePowderStage()
    local source = source
    local userId = vRP.getUserId(source)
    local drug = getDrugConfig("cocaina")
    local stage = drug and drug.cocainePowderStage

    if not userId or not stage then
        return false
    end

    if cocainePowderPreparation[userId] then
        TriggerClientEvent("Notify",source,"negado","Essa mistura já está sendo preparada.",5000)
        return false
    end

    local item = stage.inputItem or "pastabase"
    local amount = tonumber(stage.inputAmount) or 5

    if getMDrugsInventoryAmount(userId,item) < amount then
        TriggerClientEvent(
            "Notify",source,"negado",
            "Você precisa de <b>"..amount.."x "..item.."</b> para juntar com o ácido.",
            5000
        )
        return false
    end

    -- É AQUI que as 5x pastabase são removidas.
    if not vRP.tryGetInventoryItem(userId,item,amount,true) then
        return false
    end

    cocainePowderPreparation[userId] = {
        startedAt = os.time()
    }

    return true
end

function API.finishCocainePowderStage()
    local source = source
    local userId = vRP.getUserId(source)
    local drug = getDrugConfig("cocaina")
    local stage = drug and drug.cocainePowderStage
    local pending = userId and cocainePowderPreparation[userId]

    if not userId or not stage or not pending then
        return false
    end

    local duration = tonumber(stage.duration) or 30000
    local minimumSeconds = math.max(1,math.floor(duration / 1000) - 1)

    if (os.time() - pending.startedAt) < minimumSeconds then
        return false
    end

    local item = stage.outputItem or "podecocaina"
    local amount = tonumber(stage.outputAmount) or 10

    if not hasInventorySpace(userId,item,amount) then
        TriggerClientEvent("Notify",source,"negado","Mochila cheia.",5000)
        return false
    end

    cocainePowderPreparation[userId] = nil
    vRP.giveInventoryItem(userId,item,amount,true)

    TriggerClientEvent(
        "Notify",source,"sucesso",
        "Você coletou <b>"..amount.."x "..item.."</b>.",
        5000
    )

    return true
end

function API.consumeCocainePowderForPan()
    local source = source
    local userId = vRP.getUserId(source)
    local drug = getDrugConfig("cocaina")
    local req = drug and drug.panRequirement

    if not userId or not req then
        return false
    end

    local item = req.item or "podecocaina"
    local amount = tonumber(req.amount) or 10
    local have = tonumber(vRP.getInventoryItemAmount(userId,item)) or 0

    if have < amount then
        TriggerClientEvent(
            "Notify",source,"negado",
            "Você precisa de <b>"..amount.."x "..item.."</b> para pegar a panela.",
            5000
        )
        return false
    end

    if not vRP.tryGetInventoryItem(userId,item,amount,true) then
        return false
    end

    return true
end


function API.takeMethIngredient(ingredientName)
    local source = source
    local userId = vRP.getUserId(source)
    local drug = getDrugConfig("metanfetamina")
    local ingredients = drug and drug.ingredients
    local ingredient = ingredients and ingredients[ingredientName]

    if not userId or not drug or not ingredient then
        return false
    end

    if not hasAnyPermission(userId,drug.permissions) then
        return false
    end

    -- PRIMEIRA ETAPA:
    -- Para separar/pegar o Benzoato, o player precisa já possuir
    -- 2x Benzoato E 2x Toulene.
    -- Porém, neste momento, somente o Benzoato será removido.
    if ingredientName == "benzoate" then
        local benzoate = ingredients.benzoate
        local toluene = ingredients.toluene

        local benzoateAmount = tonumber(benzoate.amount) or 2
        local tolueneAmount = tonumber(toluene.amount) or 2

        local haveBenzoate = tonumber(vRP.getInventoryItemAmount(userId,benzoate.item)) or 0
        local haveToluene = tonumber(vRP.getInventoryItemAmount(userId,toluene.item)) or 0

        if haveBenzoate < benzoateAmount or haveToluene < tolueneAmount then
            TriggerClientEvent(
                "Notify",source,"negado",
                "Você precisa de <b>"..benzoateAmount.."x "..benzoate.item.."</b> e <b>"..
                tolueneAmount.."x "..toluene.item.."</b> para iniciar a produção.",
                5000
            )
            return false
        end

        -- Consome APENAS o Benzoato.
        return vRP.tryGetInventoryItem(userId,benzoate.item,benzoateAmount,true) and true or false
    end

    -- ETAPA DO TOULENE:
    -- Aqui sim os 2x Toulene são removidos.
    if ingredientName == "toluene" then
        local amount = tonumber(ingredient.amount) or 2
        local have = tonumber(vRP.getInventoryItemAmount(userId,ingredient.item)) or 0

        if have < amount then
            TriggerClientEvent(
                "Notify",source,"negado",
                "Você precisa de <b>"..amount.."x "..ingredient.item.."</b>.",
                5000
            )
            return false
        end

        return vRP.tryGetInventoryItem(userId,ingredient.item,amount,true) and true or false
    end

    return false
end

-- ============================================================================
-- METANFETAMINA - EFEDRINA / MISTURA FINAL
-- ============================================================================
local methEphedrinePreparation = {}
local methFinalMix = {}

function API.startMethEphedrine()
    local source = source
    local userId = vRP.getUserId(source)
    local drug = getDrugConfig("metanfetamina")

    if not userId or not drug or not drug.ephedrine then
        return false
    end

    if not hasAnyPermission(userId,drug.permissions) then
        TriggerClientEvent("Notify",source,"negado","Você não tem permissão para produzir metanfetamina.",5000)
        return false
    end

    if methEphedrinePreparation[userId] then
        TriggerClientEvent("Notify",source,"negado","A Efedrina já está sendo preparada.",5000)
        return false
    end

    methEphedrinePreparation[userId] = { startedAt = os.time() }
    return true
end

function API.finishMethEphedrine()
    local source = source
    local userId = vRP.getUserId(source)
    local drug = getDrugConfig("metanfetamina")
    local ephedrine = drug and drug.ephedrine
    local pending = userId and methEphedrinePreparation[userId]

    if not userId or not ephedrine or not pending then
        return false
    end

    local duration = tonumber(ephedrine.duration) or 60000
    local minimumSeconds = math.max(1,math.floor(duration / 1000) - 1)

    if (os.time() - pending.startedAt) < minimumSeconds then
        return false
    end

    local item = ephedrine.outputItem or "efedrina"
    local amount = tonumber(ephedrine.outputAmount) or 5

    if not hasInventorySpace(userId,item,amount) then
        TriggerClientEvent("Notify",source,"negado","Mochila cheia para receber a Efedrina.",5000)
        return false
    end

    methEphedrinePreparation[userId] = nil
    vRP.giveInventoryItem(userId,item,amount,true)
    TriggerClientEvent("Notify",source,"sucesso","Você coletou <b>"..amount.."x Efedrina</b>.",5000)
    return true
end

function API.startMethFinalMix()
    local source = source
    local userId = vRP.getUserId(source)
    local drug = getDrugConfig("metanfetamina")
    local mix = drug and drug.finalMix

    if not userId or not drug or not mix then
        return false
    end

    if not hasAnyPermission(userId,drug.permissions) then
        return false
    end

    if methFinalMix[userId] then
        TriggerClientEvent("Notify",source,"negado","Você já está fazendo essa mistura.",5000)
        return false
    end

    -- Valida TODOS os ingredientes primeiro.
    -- Se faltar qualquer um, informa a receita completa de uma vez.
    local missingIngredient = false

    for _,req in ipairs(mix.requirements or {}) do
        local amount = tonumber(req.amount) or 1
        local have = tonumber(vRP.getInventoryItemAmount(userId,req.item)) or 0

        if have < amount then
            missingIngredient = true
            break
        end
    end

    if missingIngredient then
        TriggerClientEvent(
            "Notify",source,"negado",
            "Você precisa de <b>5x efedrina</b> e <b>5x anfetamina</b>.",
            5000
        )
        return false
    end

    local consumed = {}
    for _,req in ipairs(mix.requirements or {}) do
        local amount = tonumber(req.amount) or 1
        if not vRP.tryGetInventoryItem(userId,req.item,amount,true) then
            for _,back in ipairs(consumed) do
                vRP.giveInventoryItem(userId,back.item,back.amount,true)
            end
            return false
        end
        consumed[#consumed+1] = { item=req.item, amount=amount }
    end

    methFinalMix[userId] = { startedAt=os.time() }
    return true
end

function API.finishMethFinalMix()
    local source = source
    local userId = vRP.getUserId(source)
    local drug = getDrugConfig("metanfetamina")
    local mix = drug and drug.finalMix
    local pending = userId and methFinalMix[userId]

    if not userId or not mix or not pending then
        return false
    end

    local duration = tonumber(mix.duration) or 20000
    local minimumSeconds = math.max(1,math.floor(duration / 1000) - 1)
    if (os.time() - pending.startedAt) < minimumSeconds then
        return false
    end

    local item = mix.outputItem or "metanfetamina"
    local amount = tonumber(mix.outputAmount) or 10

    if not hasInventorySpace(userId,item,amount) then
        TriggerClientEvent("Notify",source,"negado","Mochila cheia para receber a Metanfetamina.",5000)
        return false
    end

    methFinalMix[userId] = nil
    vRP.giveInventoryItem(userId,item,amount,true)
    TriggerClientEvent("Notify",source,"sucesso","Você produziu <b>"..amount.."x Metanfetamina</b>.",5000)
    return true
end

AddEventHandler("playerDropped",function()
    local userId = vRP.getUserId(source)
    if userId then
        weedPreparation[userId] = nil
        cocainePasteBase[userId] = nil
        methEphedrinePreparation[userId] = nil
        methFinalMix[userId] = nil
    end
end)
