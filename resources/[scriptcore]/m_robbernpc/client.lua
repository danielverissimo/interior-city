local currentRawVehicle = 0
local currentVehicle = 0
local currentRearCoords = nil
local validationCounter = 0
local pendingValidation = nil
local requestPending = false
local robberyBusy = false
local activeRobberyVehicle = 0
local activeLootSession = nil
local activeCrimeAlert = nil
local policeBlips = {}
local policeTrackers = {}
local lastPromptUpdate = 0

-- Negociação de drogas com NPCs
local currentDrugPed = 0
local drugEligibility = {}
local drugEligibilityMeta = {}
local drugLocalCooldown = {}
local drugInteractionBusy = false
local drugInteractionStartedAt = 0
local activeDrugNpc = 0
local activeDrugOffer = nil
local npcDialogue = nil
local drugOfferAwaitingServer = false
local playerHasSellableDrugs = false
local drugInventoryStateKnown = false
local drugGlanceSeen = {}
local drugGlanceToken = {}
local drugGlanceActivePed = 0

local function notify(kind, text, time)
    TriggerEvent('Notify', kind, text, time or 5)
end

local function hidePrompt()
    SendNUIMessage({ action = 'hide' })
end

local function playRobberyAnimation(ped)
    local anim = Config.RobberyAnimation
    if not anim or not anim.dict or not anim.name then return end

    RequestAnimDict(anim.dict)
    local deadline = GetGameTimer() + 3000

    while not HasAnimDictLoaded(anim.dict) and GetGameTimer() < deadline do
        Wait(10)
        RequestAnimDict(anim.dict)
    end

    if robberyBusy and HasAnimDictLoaded(anim.dict) then
        TaskPlayAnim(ped, anim.dict, anim.name, 3.0, -3.0, -1, tonumber(anim.flag) or 1, 0.0, false, false, false)
    end
end

local function stopRobberyAnimation(ped)
    local anim = Config.RobberyAnimation
    if anim and anim.dict and anim.name then
        StopAnimTask(ped, anim.dict, anim.name, 2.0)
    end
end

local function playTrunkOpenAnimation(ped)
    local anim = Config.TrunkOpenAnimation
    if not anim or not anim.dict or not anim.name then return end

    RequestAnimDict(anim.dict)
    local deadline = GetGameTimer() + 3000

    while not HasAnimDictLoaded(anim.dict) and GetGameTimer() < deadline do
        Wait(10)
        RequestAnimDict(anim.dict)
    end

    if activeLootSession and HasAnimDictLoaded(anim.dict) then
        TaskPlayAnim(
            ped,
            anim.dict,
            anim.name,
            tonumber(anim.blendIn) or 3.0,
            tonumber(anim.blendOut) or -3.0,
            -1,
            tonumber(anim.flag) or 1,
            0.0,
            false,
            false,
            false
        )
    end
end

local function stopTrunkOpenAnimation(ped)
    local anim = Config.TrunkOpenAnimation
    if anim and anim.dict and anim.name then
        StopAnimTask(ped, anim.dict, anim.name, 2.0)
    end
end

local function ensureNetworked(vehicle)
    if not DoesEntityExist(vehicle) then return 0 end

    if not NetworkGetEntityIsNetworked(vehicle) then
        NetworkRegisterEntityAsNetworked(vehicle)
    end

    local netId = VehToNet(vehicle)
    if netId and netId > 0 then
        SetNetworkIdCanMigrate(netId, true)
        return netId
    end

    return 0
end

local function hasBlockingOccupant(vehicle)
    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)

    for seat = -1, maxPassengers - 1 do
        local occupant = GetPedInVehicleSeat(vehicle, seat)

        if occupant and occupant ~= 0 then
            -- Veículo de outro jogador nunca pode ser arrombado com alguém dentro.
            if IsPedAPlayer(occupant) then
                return true
            end

            -- NPC vivo dentro do carro também bloqueia a opção.
            -- NPC morto é permitido, conforme solicitado.
            if not IsEntityDead(occupant) and GetEntityHealth(occupant) > 0 then
                return true
            end
        end
    end

    return false
end

local function isVehicleStationary(vehicle)
    if not DoesEntityExist(vehicle) then return false end

    -- IsVehicleStopped evita exibir o prompt em carros realmente em movimento.
    -- O limite de velocidade funciona como uma segunda proteção para veículos
    -- customizados/físicas que reportem pequenas oscilações.
    if not IsVehicleStopped(vehicle) then return false end
    if GetEntitySpeed(vehicle) > (tonumber(Config.MaxVehicleSpeed) or 0.25) then return false end

    return true
end

local function getRearCoords(vehicle)
    if not DoesEntityExist(vehicle) then return nil end

    local minDim, maxDim = GetModelDimensions(GetEntityModel(vehicle))
    local vehicleHeight = math.max(0.01, maxDim.z - minDim.z)

    -- Alguns veículos customizados possuem aerofólio, para-choque extra ou
    -- colisão/model dimensions muito maiores do que a carroceria real. Quando
    -- usamos apenas minDim.y, o ponto pode ficar vários centímetros/metros atrás
    -- do porta-malas. Isso acontece tanto em carros de NPC quanto de jogadores;
    -- não existe mais uma lógica diferente entre os dois tipos.
    --
    -- Para achar a TRASEIRA VISUAL da carroceria, priorizamos bones que ficam
    -- fisicamente na traseira. Só usamos o bounding box como fallback final.
    local function getBoneLocal(name)
        local bone = GetEntityBoneIndexByName(vehicle, name)
        if not bone or bone == -1 then return nil end

        local world = GetWorldPositionOfEntityBone(vehicle, bone)
        if not world then return nil end

        return GetOffsetFromEntityGivenWorldCoords(vehicle, world.x, world.y, world.z)
    end

    local leftTail = getBoneLocal('taillight_l')
    local rightTail = getBoneLocal('taillight_r')
    local bumper = getBoneLocal('bumper_r')
    local plate = getBoneLocal('numberplate') or getBoneLocal('platelight')
    local boot = getBoneLocal('boot')

    local bodyRearSamples = {}

    -- As lanternas são a principal referência porque quase sempre acompanham
    -- exatamente o final da carroceria, sem considerar aerofólios grandes.
    if leftTail then bodyRearSamples[#bodyRearSamples + 1] = leftTail.y end
    if rightTail then bodyRearSamples[#bodyRearSamples + 1] = rightTail.y end

    -- Placa e para-choque traseiro são ótimos reforços para veículos custom.
    if plate then bodyRearSamples[#bodyRearSamples + 1] = plate.y end
    if bumper then bodyRearSamples[#bodyRearSamples + 1] = bumper.y end

    local rearY = nil

    if #bodyRearSamples > 0 then
        -- Usa a mediana em vez do ponto mais traseiro. Assim um único bone
        -- mal configurado não joga a interação para longe do carro.
        table.sort(bodyRearSamples)
        local count = #bodyRearSamples
        if count % 2 == 1 then
            rearY = bodyRearSamples[(count + 1) // 2]
        else
            rearY = (bodyRearSamples[count // 2] + bodyRearSamples[(count // 2) + 1]) * 0.5
        end
    end

    -- Se não houver nenhum bone traseiro confiável, o boot só é usado quando
    -- estiver realmente na metade traseira do veículo. Em vários add-ons o boot
    -- fica na dobradiça/vidro, então ele não deve ser nossa primeira opção.
    if not rearY and boot and boot.y < -0.15 then
        rearY = boot.y
    end

    -- Fallback para veículos extremamente simples/antigos sem bones úteis.
    if not rearY then
        rearY = minDim.y
    end

    -- Move o ponto um pouco para fora da chapa, mas sem depender da extremidade
    -- total do modelo (que pode incluir spoiler/extras).
    rearY = rearY - (Config.RearInteractionOffset or 0.18)

    local rearZ = nil

    -- Altura: lanternas costumam ficar muito bem posicionadas visualmente.
    if leftTail and rightTail then
        rearZ = (leftTail.z + rightTail.z) * 0.5
    elseif leftTail then
        rearZ = leftTail.z
    elseif rightTail then
        rearZ = rightTail.z
    elseif plate then
        rearZ = plate.z + math.min(0.18, vehicleHeight * 0.12)
    elseif boot then
        rearZ = boot.z - 0.08
    elseif bumper then
        rearZ = bumper.z + math.min(0.42, vehicleHeight * 0.28)
    end

    if not rearZ then
        rearZ = minDim.z + (vehicleHeight * 0.48)
    end

    -- Limita somente a altura. O eixo Y agora é definido pela carroceria real
    -- via bones, então não herdamos mais bounding boxes exagerados de spoilers.
    local minAllowedZ = minDim.z + (vehicleHeight * 0.28)
    local maxAllowedZ = minDim.z + (vehicleHeight * 0.68)
    rearZ = math.max(minAllowedZ, math.min(rearZ, maxAllowedZ))

    return GetOffsetFromEntityInWorldCoords(vehicle, 0.0, rearY, rearZ)
end

local function getEntityStateSafe(entity, key)
    if entity == 0 or not DoesEntityExist(entity) then return nil end
    local ok, value = pcall(function()
        return Entity(entity).state[key]
    end)
    if ok then return value end
    return nil
end

local function ensurePedNetworked(ped)
    if ped == 0 or not DoesEntityExist(ped) then return 0 end

    if not NetworkGetEntityIsNetworked(ped) then
        NetworkRegisterEntityAsNetworked(ped)
        local deadline = GetGameTimer() + 750
        while DoesEntityExist(ped) and not NetworkGetEntityIsNetworked(ped) and GetGameTimer() < deadline do
            Wait(0)
            NetworkRegisterEntityAsNetworked(ped)
        end
    end

    if not NetworkGetEntityIsNetworked(ped) then return 0 end

    local netId = PedToNet(ped)
    if netId and netId > 0 then
        SetNetworkIdCanMigrate(netId, true)
        return netId
    end

    return 0
end

local function isDrugPedAllowed(ped)
    local cfg = Config.NPCDrugSales
    if not cfg or cfg.Enabled == false then return false end
    if ped == 0 or not DoesEntityExist(ped) or not IsEntityAPed(ped) then return false end
    if IsPedAPlayer(ped) or not IsPedHuman(ped) then return false end
    if IsEntityDead(ped) or GetEntityHealth(ped) <= 0 then return false end
    if IsPedInAnyVehicle(ped, false) then return false end
    if cfg.IgnoreMissionPeds == true and IsEntityAMissionEntity(ped) then return false end

    local pedType = GetPedType(ped)
    if cfg.ExcludedPedTypes and cfg.ExcludedPedTypes[pedType] then return false end

    if getEntityStateSafe(ped, 'robbernpcDrugDealt') then return false end

    local cooldown = drugLocalCooldown[ped]
    if cooldown and cooldown > GetGameTimer() then return false end

    return true
end

local function setNpcDialogue(ped, text, duration)
    if ped == 0 or not DoesEntityExist(ped) then
        npcDialogue = nil
        return
    end

    npcDialogue = {
        ped = ped,
        text = tostring(text or ''),
        -- Diálogos de negociação precisam ficar legíveis tempo suficiente.
        expiresAt = GetGameTimer() + math.max(5000, tonumber(duration) or 5000)
    }
end

local function drawNpcDialogue(ped, text)
    if ped == 0 or not DoesEntityExist(ped) then return end

    local coords = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.38)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end

    local cam = GetGameplayCamCoords()
    local distance = #(cam - coords)
    local scale = math.max(0.28, math.min(0.40, 0.42 - (distance * 0.008)))

    SetTextScale(scale, scale)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextCentre(true)
    SetTextWrap(x - 0.13, x + 0.13)
    SetTextColour(255, 255, 255, 245)
    SetTextOutline()
    SetTextDropShadow(1, 0, 0, 0, 180)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

local function holdNpcForDeal(ped, timeoutSeconds)
    if ped == 0 or not DoesEntityExist(ped) then return end

    NetworkRequestControlOfEntity(ped)
    local deadline = GetGameTimer() + 800
    while not NetworkHasControlOfEntity(ped) and GetGameTimer() < deadline do
        Wait(0)
        NetworkRequestControlOfEntity(ped)
    end

    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedKeepTask(ped, true)
    ClearPedTasks(ped)
    TaskTurnPedToFaceEntity(ped, PlayerPedId(), 900)

    CreateThread(function()
        Wait(850)
        if activeDrugNpc == ped and DoesEntityExist(ped) then
            TaskStandStill(ped, (math.max(5, tonumber(timeoutSeconds) or 18) + 5) * 1000)
        end
    end)
end

local function releaseNpcAfterDeal(ped, shouldWander)
    if ped == 0 or not DoesEntityExist(ped) then return end

    NetworkRequestControlOfEntity(ped)
    local deadline = GetGameTimer() + 500
    while not NetworkHasControlOfEntity(ped) and GetGameTimer() < deadline do
        Wait(0)
        NetworkRequestControlOfEntity(ped)
    end

    SetBlockingOfNonTemporaryEvents(ped, false)
    SetPedKeepTask(ped, false)
    ClearPedTasks(ped)

    if shouldWander ~= false then
        TaskWanderStandard(ped, 10.0, 10)
    end
end

local function playDrugExchangeAnimation(playerPed, npcPed, onFinished)
    local cfg = (Config.NPCDrugSales and Config.NPCDrugSales.ExchangeAnimation) or {}
    local dict = tostring(cfg.Dict or 'mp_common')
    local playerAnim = tostring(cfg.PlayerAnim or 'givetake1_a')
    local npcAnim = tostring(cfg.NpcAnim or 'givetake1_b')
    local duration = math.max(900, math.floor(tonumber(cfg.Duration) or 1600))

    CreateThread(function()
        if playerPed == 0 or npcPed == 0 or not DoesEntityExist(playerPed) or not DoesEntityExist(npcPed) then
            if onFinished then onFinished(false) end
            return
        end

        NetworkRequestControlOfEntity(npcPed)
        local controlDeadline = GetGameTimer() + 700
        while DoesEntityExist(npcPed) and not NetworkHasControlOfEntity(npcPed) and GetGameTimer() < controlDeadline do
            Wait(0)
            NetworkRequestControlOfEntity(npcPed)
        end

        RequestAnimDict(dict)
        local animDeadline = GetGameTimer() + 3000
        while not HasAnimDictLoaded(dict) and GetGameTimer() < animDeadline do
            Wait(10)
            RequestAnimDict(dict)
        end

        -- Aproxima visualmente a troca: os dois se encaram antes de entregar/receber.
        TaskTurnPedToFaceEntity(playerPed, npcPed, 450)
        TaskTurnPedToFaceEntity(npcPed, playerPed, 450)
        Wait(420)

        if HasAnimDictLoaded(dict) and DoesEntityExist(playerPed) and DoesEntityExist(npcPed) then
            TaskPlayAnim(playerPed, dict, playerAnim, 3.0, -3.0, duration, 0, 0.0, false, false, false)
            TaskPlayAnim(npcPed, dict, npcAnim, 3.0, -3.0, duration, 0, 0.0, false, false, false)
            Wait(duration)

            if DoesEntityExist(playerPed) then
                StopAnimTask(playerPed, dict, playerAnim, 2.0)
            end
            if DoesEntityExist(npcPed) then
                StopAnimTask(npcPed, dict, npcAnim, 2.0)
            end
        else
            -- Se a animação não estiver disponível nessa build, a venda continua sem travar.
            Wait(250)
        end

        if onFinished then onFinished(true) end
    end)
end

local function hideDrugOffer()
    SendNUIMessage({ action = 'offerHide' })
end

local function clearActiveDrugOffer(sendCancel)
    local offer = activeDrugOffer
    activeDrugOffer = nil
    drugOfferAwaitingServer = false
    hideDrugOffer()

    if offer then
        if sendCancel and offer.token then
            TriggerServerEvent('m_robbernpc:drug:cancel', offer.token)
        end
        releaseNpcAfterDeal(offer.ped, true)
    elseif activeDrugNpc ~= 0 then
        releaseNpcAfterDeal(activeDrugNpc, true)
    end

    activeDrugNpc = 0
    drugInteractionBusy = false
    drugInteractionStartedAt = 0
end

local function clearDrugPedCache(ped)
    drugEligibility[ped] = nil
    drugEligibilityMeta[ped] = nil
    drugLocalCooldown[ped] = nil
    drugGlanceSeen[ped] = nil
    drugGlanceToken[ped] = nil
    if drugGlanceActivePed == ped then
        drugGlanceActivePed = 0
    end
end

local function findClosestDrugPed()
    local cfg = Config.NPCDrugSales
    if not cfg or cfg.Enabled == false then return 0 end

    -- Não mostra marcação alguma sem uma confirmação recente do servidor de que
    -- existe pelo menos uma droga vendável no inventário do jogador.
    if not drugInventoryStateKnown or not playerHasSellableDrugs then return 0 end

    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) or IsEntityDead(playerPed) then return 0 end

    local playerCoords = GetEntityCoords(playerPed)
    local searchDistance = tonumber(cfg.SearchDistance) or 10.0
    local interactionDistance = tonumber(cfg.InteractionDistance) or 1.65
    local rollDistance = math.max(interactionDistance, tonumber(cfg.EligibilityRollDistance) or 2.75)
    local chance = math.max(0, math.min(100, tonumber(cfg.EligibilityChance) or 30))
    local now = GetGameTimer()
    local bestPed = 0
    local bestDistance = interactionDistance + 0.001

    for _, ped in ipairs(GetGamePool('CPed')) do
        if ped ~= playerPed and DoesEntityExist(ped) then
            local distance = #(playerCoords - GetEntityCoords(ped))
            if distance <= searchDistance and isDrugPedAllowed(ped) then
                local model = GetEntityModel(ped)
                local meta = drugEligibilityMeta[ped]

                -- Handles de entidades podem ser reutilizados pelo GTA. Se isso acontecer,
                -- nunca reaproveitamos a chance do NPC antigo para o novo ped.
                if meta and meta.model ~= model then
                    clearDrugPedCache(ped)
                    meta = nil
                end

                -- O sorteio só acontece quando o NPC realmente chega perto. Antes, todos os
                -- peds em até 10m eram sorteados e ficavam guardados para sempre; com o tempo
                -- a área podia ficar inteira marcada como "não comprador".
                if drugEligibility[ped] == nil and distance <= rollDistance then
                    drugEligibility[ped] = math.random(1, 100) <= chance
                    drugEligibilityMeta[ped] = {
                        model = model,
                        lastNearAt = now,
                        farSince = nil
                    }
                elseif drugEligibilityMeta[ped] and distance <= rollDistance then
                    drugEligibilityMeta[ped].lastNearAt = now
                    drugEligibilityMeta[ped].farSince = nil
                end

                if drugEligibility[ped] and distance < bestDistance and distance <= interactionDistance then
                    if HasEntityClearLosToEntity(playerPed, ped, 17) then
                        bestPed = ped
                        bestDistance = distance
                    end
                end
            end
        end
    end

    return bestPed
end

RegisterNetEvent('m_robbernpc:drug:inventoryState', function(hasDrugs)
    local previousState = playerHasSellableDrugs
    drugInventoryStateKnown = true
    playerHasSellableDrugs = hasDrugs == true

    -- Ao voltar a ter drogas, começa uma nova rodada de encontros. Isso evita
    -- carregar indefinidamente resultados antigos de NPCs vistos antes.
    if playerHasSellableDrugs and not previousState then
        drugEligibility = {}
        drugEligibilityMeta = {}
        drugGlanceSeen = {}
        drugGlanceToken = {}
        drugGlanceActivePed = 0
    end

    -- Se as drogas acabaram/foram removidas enquanto um NPC estava marcado,
    -- esconde a opção imediatamente.
    if not playerHasSellableDrugs then
        if currentDrugPed ~= 0 then
            currentDrugPed = 0
            hidePrompt()
        end
    end
end)

-- Consulta leve e periódica ao servidor. Assim a marcação só existe quando o
-- inventário realmente contém ao menos uma das drogas configuradas, inclusive
-- se o jogador receber/remover itens por outros resources.
CreateThread(function()
    while true do
        local cfg = Config.NPCDrugSales or {}
        if cfg.Enabled ~= false then
            TriggerServerEvent('m_robbernpc:drug:checkInventory')
        else
            drugInventoryStateKnown = true
            playerHasSellableDrugs = false
        end

        Wait(math.max(750, tonumber(cfg.InventoryCheckInterval) or 1500))
    end
end)

-- Limpa e recicla a cache de encontros. A chance continua estável enquanto
-- o NPC está perto, mas um ped que foi embora por alguns segundos deixa de
-- ocupar a lista para sempre. Isso também protege contra reutilização de handles.
CreateThread(function()
    while true do
        Wait(2000)
        local cfg = Config.NPCDrugSales or {}
        local playerPed = PlayerPedId()
        local playerCoords = playerPed ~= 0 and DoesEntityExist(playerPed) and GetEntityCoords(playerPed) or nil
        local resetDistance = math.max(5.0, tonumber(cfg.EligibilityResetDistance) or 12.0)
        local resetDelay = math.max(1000, math.floor(tonumber(cfg.EligibilityResetDelay) or 6000))
        local now = GetGameTimer()

        for ped in pairs(drugEligibility) do
            local meta = drugEligibilityMeta[ped]
            local remove = not DoesEntityExist(ped)

            if not remove and meta and meta.model ~= GetEntityModel(ped) then
                remove = true
            end

            if not remove and playerCoords and meta then
                local distance = #(playerCoords - GetEntityCoords(ped))
                if distance > resetDistance then
                    meta.farSince = meta.farSince or now
                    if now - meta.farSince >= resetDelay then
                        remove = true
                    end
                else
                    meta.farSince = nil
                end
            end

            if remove then
                clearDrugPedCache(ped)
            end
        end

        -- Há peds que só passaram pela reação de olhar e nunca entraram na cache
        -- de 30%. Também limpamos esses handles quando deixam de existir.
        for ped in pairs(drugGlanceSeen) do
            if not DoesEntityExist(ped) then
                drugGlanceSeen[ped] = nil
                drugGlanceToken[ped] = nil
                if drugGlanceActivePed == ped then
                    drugGlanceActivePed = 0
                end
            end
        end
    end
end)

-- Quando o jogador carrega alguma droga, um pedestre que cruzar bem perto dele
-- para por 2 segundos e olha em sua direção. Isso acontece uma única vez por NPC
-- e em apenas um NPC por vez, evitando o efeito artificial de uma multidão inteira parar.
CreateThread(function()
    while true do
        local cfg = Config.NPCDrugSales or {}
        local canReact = cfg.Enabled ~= false
            and drugInventoryStateKnown and playerHasSellableDrugs
            and not drugInteractionBusy and activeDrugOffer == nil

        if canReact then
            local playerPed = PlayerPedId()
            if playerPed ~= 0 and DoesEntityExist(playerPed)
                and not IsPedInAnyVehicle(playerPed, false) and not IsEntityDead(playerPed)
                and drugGlanceActivePed == 0 then

                local playerCoords = GetEntityCoords(playerPed)
                local attentionDistance = math.max(1.25, tonumber(cfg.AttentionDistance) or 2.35)
                local closestPed = 0
                local closestDistance = attentionDistance + 0.001

                for _, ped in ipairs(GetGamePool('CPed')) do
                    if ped ~= playerPed and not drugGlanceSeen[ped] and isDrugPedAllowed(ped) then
                        local distance = #(playerCoords - GetEntityCoords(ped))
                        if distance <= attentionDistance and distance < closestDistance
                            and HasEntityClearLosToEntity(playerPed, ped, 17) then
                            closestPed = ped
                            closestDistance = distance
                        end
                    end
                end

                if closestPed ~= 0 then
                    local ped = closestPed
                    local lookTime = math.max(1000, math.floor(tonumber(cfg.AttentionDuration) or 2000))
                    local token = GetGameTimer() + math.random(1, 100000)

                    drugGlanceSeen[ped] = true
                    drugGlanceToken[ped] = token
                    drugGlanceActivePed = ped

                    NetworkRequestControlOfEntity(ped)
                    local deadline = GetGameTimer() + 600
                    while DoesEntityExist(ped) and not NetworkHasControlOfEntity(ped) and GetGameTimer() < deadline do
                        Wait(0)
                        NetworkRequestControlOfEntity(ped)
                    end

                    if DoesEntityExist(ped) then
                        SetBlockingOfNonTemporaryEvents(ped, true)
                        SetPedKeepTask(ped, true)
                        ClearPedTasks(ped)
                        TaskTurnPedToFaceEntity(ped, playerPed, lookTime)
                    end

                    CreateThread(function()
                        Wait(lookTime)
                        local stillThisReaction = drugGlanceToken[ped] == token
                        drugGlanceToken[ped] = nil
                        if drugGlanceActivePed == ped then
                            drugGlanceActivePed = 0
                        end

                        -- Se o jogador apertou N enquanto o NPC estava olhando, a negociação
                        -- assume o controle das tasks e este timer não interfere nela/fuga.
                        if stillThisReaction and activeDrugNpc ~= ped and DoesEntityExist(ped) then
                            releaseNpcAfterDeal(ped, true)
                        end
                    end)
                end
            end
        end

        Wait(180)
    end
end)

-- Localiza NPCs elegíveis. O sorteio de 30% é estável por ped.
CreateThread(function()
    while true do
        local blocked = requestPending or robberyBusy or activeLootSession or drugInteractionBusy or activeDrugOffer ~= nil
        if blocked then
            if currentDrugPed ~= 0 then
                currentDrugPed = 0
                hidePrompt()
            end
            Wait(250)
        else
            local ped = findClosestDrugPed()
            if ped ~= currentDrugPed then
                currentDrugPed = ped
                hidePrompt()
            end
            Wait(220)
        end
    end
end)

-- Desenha o mesmo prompt usado pelo porta-malas, agora sobre a cabeça do NPC.
CreateThread(function()
    while true do
        if currentDrugPed ~= 0 and DoesEntityExist(currentDrugPed)
            and not requestPending and not robberyBusy and not activeLootSession
            and not drugInteractionBusy and activeDrugOffer == nil then

            local coords = GetPedBoneCoords(currentDrugPed, 31086, 0.0, 0.0, 0.30)
            local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
            if onScreen then
                local now = GetGameTimer()
                if now - lastPromptUpdate >= 30 then
                    lastPromptUpdate = now
                    SendNUIMessage({
                        action = 'show',
                        x = x * 100.0,
                        y = y * 100.0,
                        key = Config.Key,
                        text = (Config.NPCDrugSales and Config.NPCDrugSales.PromptText) or 'NEGOCIAR DROGAS'
                    })
                end
            else
                hidePrompt()
            end
            Wait(0)
        else
            Wait(120)
        end
    end
end)

-- Balões de diálogo acima do NPC.
CreateThread(function()
    while true do
        if npcDialogue then
            if GetGameTimer() >= npcDialogue.expiresAt or not DoesEntityExist(npcDialogue.ped) then
                npcDialogue = nil
            else
                drawNpcDialogue(npcDialogue.ped, npcDialogue.text)
            end
            Wait(0)
        else
            Wait(150)
        end
    end
end)

-- Mantém o comprador olhando para o jogador enquanto a proposta está aberta.
CreateThread(function()
    while true do
        if activeDrugOffer and not drugOfferAwaitingServer
            and activeDrugOffer.ped ~= 0 and DoesEntityExist(activeDrugOffer.ped) then
            TaskTurnPedToFaceEntity(activeDrugOffer.ped, PlayerPedId(), 900)
            Wait(850)
        else
            Wait(300)
        end
    end
end)

local function startDrugInteraction(ped)
    if drugInteractionBusy or activeDrugOffer or ped == 0 or not DoesEntityExist(ped) then return end

    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) or IsEntityDead(playerPed) then return end

    local cfg = Config.NPCDrugSales or {}
    local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(ped))
    if distance > ((tonumber(cfg.InteractionDistance) or 1.65) + 0.35) then return end

    local netId = ensurePedNetworked(ped)
    if netId == 0 then
        drugLocalCooldown[ped] = GetGameTimer() + 5000
        notify('negado', 'Não foi possível sincronizar este cidadão.', 5)
        return
    end

    -- A negociação passa a comandar o NPC; impede o timer de 2s da reação
    -- ambiente de sobrescrever a proposta ou a fuga.
    drugGlanceToken[ped] = nil
    if drugGlanceActivePed == ped then
        drugGlanceActivePed = 0
    end

    drugInteractionBusy = true
    drugInteractionStartedAt = GetGameTimer()
    activeDrugNpc = ped
    currentDrugPed = 0
    hidePrompt()

    TriggerServerEvent('m_robbernpc:drug:request', netId)
end

local function confirmDrugOffer()
    local offer = activeDrugOffer
    if not offer or drugOfferAwaitingServer then return end
    if not offer.ped or offer.ped == 0 or not DoesEntityExist(offer.ped) then
        clearActiveDrugOffer(true)
        return
    end

    local maxDistance = tonumber((Config.NPCDrugSales or {}).ServerMaxDistance) or 4.0
    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(offer.ped)) > maxDistance then
        notify('negado', 'Você se afastou do comprador.', 5)
        clearActiveDrugOffer(true)
        return
    end

    -- O servidor decide PRIMEIRO se o comprador é legítimo ou um oficial disfarçado.
    -- Assim, quando for policial, nenhuma animação de entrega acontece e nenhuma droga
    -- sai do inventário. Se for comprador real, o servidor autoriza a animação.
    drugOfferAwaitingServer = true
    offer.expiresAt = GetGameTimer() + 8000
    hideDrugOffer()
    TriggerServerEvent('m_robbernpc:drug:confirm', offer.token)
end

RegisterNetEvent('m_robbernpc:drug:result', function(data)
    data = type(data) == 'table' and data or {}
    local ped = activeDrugNpc

    if data.outcome == 'accepted' and data.token then
        if ped == 0 or not DoesEntityExist(ped) then
            drugInteractionBusy = false
            drugInteractionStartedAt = 0
            TriggerServerEvent('m_robbernpc:drug:cancel', data.token)
            activeDrugNpc = 0
            return
        end

        drugEligibility[ped] = false
        holdNpcForDeal(ped, data.timeout)
        setNpcDialogue(ped, data.dialogue or (Config.NPCDrugSales and Config.NPCDrugSales.AcceptDialogue), data.dialogueDuration)

        activeDrugOffer = {
            token = tostring(data.token),
            ped = ped,
            netId = tonumber(data.netId) or 0,
            quantity = tonumber(data.quantity) or 1,
            label = tostring(data.label or 'Droga'),
            expiresAt = GetGameTimer() + (math.max(5, tonumber(data.timeout) or 18) * 1000)
        }

        SendNUIMessage({
            action = 'offerShow',
            text = ('Deseja vender %dx %s?'):format(activeDrugOffer.quantity, activeDrugOffer.label),
            confirmKey = tostring(Config.Key or 'N'):upper(),
            cancelKey = 'BACKSPACE'
        })
        return
    end

    drugInteractionBusy = false
    drugInteractionStartedAt = 0
    activeDrugOffer = nil
    drugOfferAwaitingServer = false
    hideDrugOffer()

    if ped ~= 0 and DoesEntityExist(ped) then
        drugLocalCooldown[ped] = GetGameTimer() + 8000
    end
    activeDrugNpc = 0

    if data.message and data.message ~= '' then
        notify(data.kind or 'negado', data.message, 5)
    end
end)

RegisterNetEvent('m_robbernpc:drug:exchangeApproved', function(data)
    data = type(data) == 'table' and data or {}
    local offer = activeDrugOffer
    if not offer or tostring(offer.token) ~= tostring(data.token or '') then return end

    local playerPed = PlayerPedId()
    local ped = offer.ped
    local token = offer.token

    if playerPed == 0 or IsEntityDead(playerPed) or ped == 0 or not DoesEntityExist(ped) then
        drugOfferAwaitingServer = false
        clearActiveDrugOffer(true)
        return
    end

    -- Comprador legítimo: só agora a troca visual acontece.
    offer.expiresAt = GetGameTimer() + 8000
    playDrugExchangeAnimation(playerPed, ped, function()
        if not activeDrugOffer or tostring(activeDrugOffer.token) ~= tostring(token) then
            return
        end

        if playerPed == 0 or IsEntityDead(playerPed) or ped == 0 or not DoesEntityExist(ped) then
            drugOfferAwaitingServer = false
            clearActiveDrugOffer(true)
            return
        end

        TriggerServerEvent('m_robbernpc:drug:complete', token)
    end)
end)

RegisterNetEvent('m_robbernpc:drug:undercover', function(data)
    data = type(data) == 'table' and data or {}
    local offer = activeDrugOffer
    local ped = offer and offer.ped or activeDrugNpc
    local cfg = Config.NPCDrugSales or {}

    activeDrugOffer = nil
    drugOfferAwaitingServer = false
    drugInteractionBusy = false
    drugInteractionStartedAt = 0
    hideDrugOffer()
    currentDrugPed = 0
    hidePrompt()

    -- O servidor já acionou a polícia. No client, o NPC encena a denúncia:
    -- fala no telefone por 5s, corre por 10s e depois volta a ser um NPC ambiente normal.
    if ped ~= 0 and DoesEntityExist(ped) then
        drugEligibility[ped] = false
        drugLocalCooldown[ped] = GetGameTimer() + 20000

        local dialogue = tostring(data.dialogue or cfg.UndercoverDialogue
            or 'Alo?! Tem um meliante fazendo venda de drogas ilicitas! venham agora!')
        local phoneDuration = math.max(5000, math.floor(tonumber(cfg.UndercoverPhoneDuration) or tonumber(data.dialogueDuration) or 5000))
        local fleeDuration = math.max(1000, math.floor(tonumber(cfg.UndercoverFleeDuration) or 10000))
        local fleeDistance = math.max(30.0, tonumber(cfg.UndercoverFleeDistance) or 120.0)
        local phoneScenario = tostring(cfg.UndercoverPhoneScenario or 'WORLD_HUMAN_STAND_MOBILE')

        setNpcDialogue(ped, dialogue, phoneDuration)

        CreateThread(function()
            if not DoesEntityExist(ped) then return end

            NetworkRequestControlOfEntity(ped)
            local controlDeadline = GetGameTimer() + 900
            while DoesEntityExist(ped) and not NetworkHasControlOfEntity(ped) and GetGameTimer() < controlDeadline do
                Wait(0)
                NetworkRequestControlOfEntity(ped)
            end

            if not DoesEntityExist(ped) then return end

            SetBlockingOfNonTemporaryEvents(ped, true)
            SetPedKeepTask(ped, true)
            ClearPedTasks(ped)
            TaskTurnPedToFaceEntity(ped, PlayerPedId(), 500)
            Wait(450)

            if DoesEntityExist(ped) then
                TaskStartScenarioInPlace(ped, phoneScenario, 0, true)
            end

            Wait(phoneDuration)
            if not DoesEntityExist(ped) then return end

            ClearPedTasks(ped)
            TaskSmartFleePed(ped, PlayerPedId(), fleeDistance, fleeDuration, false, false)

            Wait(fleeDuration)
            if not DoesEntityExist(ped) then return end

            -- Após os 10 segundos de fuga, desfaz tudo que o resource aplicou no ped.
            -- Ele volta a reagir ao mundo normalmente e pode ser limpo/despawnado pelo GTA.
            releaseNpcAfterDeal(ped, true)
            SetEntityAsNoLongerNeeded(ped)
        end)
    end

    activeDrugNpc = 0
    TriggerServerEvent('m_robbernpc:drug:checkInventory')
end)

RegisterNetEvent('m_robbernpc:drug:finished', function(data)
    data = type(data) == 'table' and data or {}

    -- Após uma venda bem-sucedida, desliga o prompt preventivamente até o
    -- servidor confirmar se ainda sobrou alguma droga. Isso evita uma marcação
    -- falsa por alguns frames quando a última unidade acabou de ser vendida.
    if data.ok == true then
        playerHasSellableDrugs = false
        currentDrugPed = 0
        hidePrompt()
    end

    -- Atualiza imediatamente o estado do inventário após concluir/cancelar uma
    -- negociação; o polling periódico continua como fallback.
    TriggerServerEvent('m_robbernpc:drug:checkInventory')
    local offer = activeDrugOffer
    local ped = offer and offer.ped or activeDrugNpc

    activeDrugOffer = nil
    drugOfferAwaitingServer = false
    drugInteractionBusy = false
    drugInteractionStartedAt = 0
    hideDrugOffer()

    if ped ~= 0 and DoesEntityExist(ped) then
        -- Venda concluída: o comprador solta uma resposta aleatória sobre a cabeça
        -- por pelo menos 5 segundos e, em seguida, volta à rotina normalmente.
        if data.ok == true and data.dialogue and tostring(data.dialogue) ~= '' then
            setNpcDialogue(ped, tostring(data.dialogue), math.max(5000, tonumber(data.dialogueDuration) or 5000))
        end
        releaseNpcAfterDeal(ped, true)
    end
    activeDrugNpc = 0

    if data.message and data.message ~= '' then
        notify(data.ok and 'sucesso' or 'negado', data.message, data.ok and 6 or 5)
    end
end)

-- Watchdog da abordagem: se por qualquer motivo o servidor/NPC perder a resposta
-- entre apertar N e abrir a proposta, o client não fica preso em "busy" para sempre.
CreateThread(function()
    while true do
        if drugInteractionBusy and activeDrugOffer == nil and activeDrugNpc ~= 0 and drugInteractionStartedAt > 0 then
            local watchdog = math.max(5000, math.floor(tonumber((Config.NPCDrugSales or {}).InteractionWatchdog) or 9000))
            if GetGameTimer() - drugInteractionStartedAt >= watchdog then
                local ped = activeDrugNpc
                if ped ~= 0 and DoesEntityExist(ped) then
                    releaseNpcAfterDeal(ped, true)
                    drugLocalCooldown[ped] = GetGameTimer() + 3000
                end
                activeDrugNpc = 0
                drugInteractionBusy = false
                drugInteractionStartedAt = 0
                currentDrugPed = 0
                hidePrompt()
                TriggerServerEvent('m_robbernpc:drug:checkInventory')
            end
        end
        Wait(500)
    end
end)

-- Timeout/movimento: fecha proposta sem permitir vender à distância.
CreateThread(function()
    while true do
        if activeDrugOffer then
            local offer = activeDrugOffer
            local cancel = GetGameTimer() >= offer.expiresAt
                or offer.ped == 0
                or not DoesEntityExist(offer.ped)

            if not cancel then
                local maxDistance = tonumber((Config.NPCDrugSales or {}).ServerMaxDistance) or 4.0
                cancel = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(offer.ped)) > maxDistance
            end

            if cancel then
                clearActiveDrugOffer(true)
            end
            Wait(250)
        else
            Wait(400)
        end
    end
end)

RegisterCommand('m_robbernpc:cancelDrugOffer', function()
    if activeDrugOffer then
        clearActiveDrugOffer(true)
    end
end, false)
RegisterKeyMapping('m_robbernpc:cancelDrugOffer', 'Recusar proposta de venda de drogas', 'keyboard', 'BACK')

local function faceTrunk(ped, vehicle)
    if not DoesEntityExist(ped) or not DoesEntityExist(vehicle) then return end

    -- Como a interação só pode começar na traseira do veículo, a forma mais
    -- confiável de deixar o personagem PERPENDICULAR à tampa é usar a mesma
    -- direção frontal do próprio veículo. Apontar para o centro do porta-malas
    -- fazia o ped ficar torto/diagonal quando ele estava um pouco para a esquerda
    -- ou direita da traseira.
    local vehicleHeading = GetEntityHeading(vehicle)
    SetEntityHeading(ped, vehicleHeading + 0.0)
end

-- Algumas animações possuem pequena rotação no root do ped. Enquanto o minigame
-- estiver ativo, mantemos o heading preso ao heading do veículo para garantir que
-- o personagem continue sempre de frente para o porta-malas.
CreateThread(function()
    while true do
        if robberyBusy and activeRobberyVehicle ~= 0 and DoesEntityExist(activeRobberyVehicle) then
            local ped = PlayerPedId()
            local desiredHeading = GetEntityHeading(activeRobberyVehicle)
            local currentHeading = GetEntityHeading(ped)
            local diff = math.abs(((desiredHeading - currentHeading + 180.0) % 360.0) - 180.0)

            if diff > 0.75 then
                SetEntityHeading(ped, desiredHeading + 0.0)
            end

            Wait(50)
        else
            Wait(250)
        end
    end
end)

local function localVehicleAllowed(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then return false end

    local model = GetEntityModel(vehicle)
    if not IsThisModelACar(model) then return false end

    -- O ARROMBAR só existe quando o veículo está realmente parado.
    if not isVehicleStationary(vehicle) then return false end

    -- Permitido somente vazio ou com NPC morto dentro.
    if hasBlockingOccupant(vehicle) then return false end

    local state = Entity(vehicle).state
    if state then
        if state.trunkrobberBusy then return false end

        -- Novo bloqueio definitivo é exclusivo de NPCs. Não usamos apenas
        -- trunkrobberRobbed aqui para não herdar o bloqueio permanente que
        -- versões antigas também aplicavam aos veículos de jogadores.
        if state.trunkrobberRobbedNPC then return false end

        -- Veículos de jogadores voltam a ficar disponíveis quando o cooldown
        -- termina. Se limite_de_tempo=false, esse bloqueio é ignorado na hora.
        if Config.limite_de_tempo == true then
            local cooldownUntil = tonumber(state.trunkrobberCooldownUntil) or 0

            -- O runtime CLIENT do FiveM não disponibiliza a biblioteca Lua `os`.
            -- GetCloudTimeAsInt() fornece um timestamp Unix no client. Caso essa
            -- native não esteja disponível por algum motivo, deixamos a validação
            -- definitiva para o servidor (que já valida o cooldown novamente).
            local currentTime = 0
            if type(GetCloudTimeAsInt) == 'function' then
                local ok, value = pcall(GetCloudTimeAsInt)
                if ok then currentTime = tonumber(value) or 0 end
            end

            if currentTime > 0 and cooldownUntil > currentTime then return false end
        end
    end

    return true
end

local function findClosestRearVehicle()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) or IsEntityDead(ped) then return 0, nil end

    local pedCoords = GetEntityCoords(ped)
    local bestVehicle = 0
    local bestRear = nil
    local bestDistance = Config.VehicleSearchDistance + 0.001

    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if vehicle ~= 0 and DoesEntityExist(vehicle) then
            -- Primeiro filtra por distância do centro para não consultar bancos/ocupantes
            -- de todos os veículos existentes no mapa a cada varredura.
            local vehCoords = GetEntityCoords(vehicle)
            if #(pedCoords - vehCoords) <= (Config.VehicleSearchDistance + 3.0) and localVehicleAllowed(vehicle) then
                local rear = getRearCoords(vehicle)
                if rear then
                    local distance = #(pedCoords - rear)
                    if distance < bestDistance
                        and distance <= Config.InteractionDistance
                        and HasEntityClearLosToEntity(ped, vehicle, 17) then
                        bestDistance = distance
                        bestVehicle = vehicle
                        bestRear = rear
                    end
                end
            end
        end
    end

    return bestVehicle, bestRear
end

local function requestVehicleValidation(vehicle)
    local netId = ensureNetworked(vehicle)
    if netId == 0 then
        currentVehicle = 0
        return
    end

    validationCounter = validationCounter + 1
    pendingValidation = {
        id = validationCounter,
        netId = netId,
        vehicle = vehicle
    }

    TriggerServerEvent('m_robbernpc:validateCandidate', netId, validationCounter)
end

RegisterNetEvent('m_robbernpc:candidateResult', function(validationId, netId, eligible)
    if not pendingValidation then return end
    if pendingValidation.id ~= validationId or pendingValidation.netId ~= netId then return end
    if currentRawVehicle ~= pendingValidation.vehicle then return end

    if eligible and DoesEntityExist(pendingValidation.vehicle) then
        currentVehicle = pendingValidation.vehicle
        currentRearCoords = getRearCoords(currentVehicle)
    else
        currentVehicle = 0
        currentRearCoords = nil
        hidePrompt()
    end

    pendingValidation = nil
end)

CreateThread(function()
    while true do
        if requestPending or robberyBusy or activeLootSession then
            currentRawVehicle = 0
            currentVehicle = 0
            currentRearCoords = nil
            pendingValidation = nil
            hidePrompt()
            Wait(250)
        else
            local vehicle, rear = findClosestRearVehicle()

            if vehicle ~= currentRawVehicle then
                currentRawVehicle = vehicle
                currentVehicle = 0
                currentRearCoords = rear
                pendingValidation = nil
                hidePrompt()

                if vehicle ~= 0 then
                    requestVehicleValidation(vehicle)
                end
            elseif currentVehicle ~= 0 then
                if not localVehicleAllowed(currentVehicle) then
                    currentRawVehicle = 0
                    currentVehicle = 0
                    currentRearCoords = nil
                    hidePrompt()
                else
                    currentRearCoords = getRearCoords(currentVehicle)
                end
            end

            Wait(175)
        end
    end
end)

CreateThread(function()
    while true do
        if currentVehicle ~= 0 and currentRearCoords and currentDrugPed == 0 and not drugInteractionBusy and activeDrugOffer == nil and not requestPending and not robberyBusy and not activeLootSession then
            local onScreen, x, y = World3dToScreen2d(currentRearCoords.x, currentRearCoords.y, currentRearCoords.z)
            if onScreen then
                local now = GetGameTimer()
                if now - lastPromptUpdate >= 30 then
                    lastPromptUpdate = now
                    SendNUIMessage({
                        action = 'show',
                        x = x * 100.0,
                        y = y * 100.0,
                        key = Config.Key,
                        text = Config.PromptText
                    })
                end
            else
                hidePrompt()
            end
            Wait(0)
        else
            Wait(150)
        end
    end
end)

RegisterCommand('m_robbernpc:interact', function()
    -- A mesma tecla serve para confirmar a proposta, negociar com NPC e arrombar.
    if activeDrugOffer then
        confirmDrugOffer()
        return
    end

    if currentDrugPed ~= 0 and DoesEntityExist(currentDrugPed) then
        startDrugInteraction(currentDrugPed)
        return
    end

    if requestPending or robberyBusy or activeLootSession or drugInteractionBusy then return end
    if currentVehicle == 0 or not DoesEntityExist(currentVehicle) or not currentRearCoords then return end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) or IsEntityDead(ped) then return end

    local rear = getRearCoords(currentVehicle)
    if not rear or #(GetEntityCoords(ped) - rear) > (Config.InteractionDistance + 0.35) then return end

    local netId = ensureNetworked(currentVehicle)
    if netId == 0 then
        notify('negado', 'Não foi possível sincronizar este veículo.', 5)
        return
    end

    requestPending = true
    hidePrompt()

    TriggerServerEvent('m_robbernpc:tryStart', netId, {
        x = rear.x,
        y = rear.y,
        z = rear.z
    })
end, false)

RegisterKeyMapping('m_robbernpc:interact', 'Interagir com roubo/negociação NPC', 'keyboard', Config.Key)

RegisterNetEvent('m_robbernpc:requestDenied', function()
    requestPending = false
end)

RegisterNetEvent('m_robbernpc:vehicleAlarm', function(netId, duration)
    local vehicle = NetToVeh(tonumber(netId) or 0)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return end

    NetworkRequestControlOfEntity(vehicle)
    local timeout = GetGameTimer() + 1000
    while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < timeout do
        Wait(0)
        NetworkRequestControlOfEntity(vehicle)
    end

    -- Alarme nativo do GTA V. O rastreador continua oculto; o ladrão apenas
    -- percebe que aquele veículo disparou o alarme ao iniciar o arrombamento.
    SetVehicleAlarm(vehicle, true)
    SetVehicleAlarmTimeLeft(vehicle, math.max(1000, tonumber(duration) or 30000))
    StartVehicleAlarm(vehicle)
end)

RegisterNetEvent('m_robbernpc:robberTracker:start', function(seconds, text)
    SendNUIMessage({
        action = 'trackerStart',
        seconds = tonumber(seconds) or 90,
        text = text or Config.RobberTrackedText or 'VOCÊ ESTÁ SENDO RASTREADO,FUJA!'
    })
end)

RegisterNetEvent('m_robbernpc:robberTracker:stop', function()
    SendNUIMessage({ action = 'trackerStop' })
end)

RegisterNetEvent('m_robbernpc:attemptStarted', function(netId)
    requestPending = false
    robberyBusy = true
    activeRobberyVehicle = 0
    hidePrompt()

    local ped = PlayerPedId()
    local vehicle = NetToVeh(tonumber(netId) or 0)

    -- Garante que o personagem sempre fique alinhado de frente para a tampa do
    -- porta-malas antes da animação. O heading é baseado no veículo, e não na
    -- posição lateral do jogador, evitando ficar diagonal em SUVs/sedans largos.
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        activeRobberyVehicle = vehicle
        faceTrunk(ped, vehicle)
    end

    -- Fica completamente imóvel durante todo o minigame/taskbar.
    FreezeEntityPosition(ped, true)

    -- Reaplica o heading já congelado para eliminar qualquer rotação residual.
    if activeRobberyVehicle ~= 0 then
        faceTrunk(ped, activeRobberyVehicle)
    end

    -- Mesmo dict/name do vRP.playAnim(false, {{...}}, true) solicitado.
    playRobberyAnimation(ped)

    -- Algumas animações tentam alterar o heading no primeiro frame.
    if activeRobberyVehicle ~= 0 then
        faceTrunk(ped, activeRobberyVehicle)
    end
end)

RegisterNetEvent('m_robbernpc:attemptEnded', function(success)
    requestPending = false
    robberyBusy = false
    activeRobberyVehicle = 0

    local ped = PlayerPedId()
    stopRobberyAnimation(ped)
    stopTrunkOpenAnimation(ped)
    FreezeEntityPosition(ped, false)
    hideDrugOffer()

    if activeDrugOffer and activeDrugOffer.token then
        TriggerServerEvent('m_robbernpc:drug:cancel', activeDrugOffer.token)
    end
    if activeDrugNpc ~= 0 then
        releaseNpcAfterDeal(activeDrugNpc, true)
    end
    activeDrugOffer = nil
    activeDrugNpc = 0
    drugInteractionBusy = false
    drugInteractionStartedAt = 0

    if not success then
        currentRawVehicle = 0
        currentVehicle = 0
        currentRearCoords = nil
        pendingValidation = nil
    end
end)

RegisterNetEvent('m_robbernpc:vehicleRobbed', function(netId)
    if currentVehicle ~= 0 and VehToNet(currentVehicle) == tonumber(netId) then
        currentRawVehicle = 0
        currentVehicle = 0
        currentRearCoords = nil
        pendingValidation = nil
        hidePrompt()
    end
end)

local function setTrunkDoor(vehicle, open)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return end

    NetworkRequestControlOfEntity(vehicle)
    local timeout = GetGameTimer() + 750
    while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < timeout do
        Wait(0)
        NetworkRequestControlOfEntity(vehicle)
    end

    if open then
        SetVehicleDoorOpen(vehicle, 5, false, false)
    else
        SetVehicleDoorShut(vehicle, 5, false)
    end
end

local function finishLootSession(sendServer)
    local session = activeLootSession
    if not session then return end

    activeLootSession = nil

    -- Assim que o inventário/porta-malas fecha, interrompe imediatamente
    -- a animação que fica ativa enquanto o jogador vasculha o porta-malas.
    stopTrunkOpenAnimation(PlayerPedId())

    local vehicle = NetToVeh(session.netId)
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        setTrunkDoor(vehicle, false)
    end

    if sendServer then
        TriggerServerEvent('m_robbernpc:finishChest', session.chestId)
    end
end

RegisterNetEvent('m_robbernpc:prepareInventory', function(netId, chestId, maxWeight, sessionType)
    local vehicle = NetToVeh(netId)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        TriggerServerEvent('m_robbernpc:finishChest', chestId)
        return
    end

    activeLootSession = {
        netId = netId,
        chestId = chestId,
        maxWeight = maxWeight,
        sessionType = sessionType or 'npc',
        requestedAt = GetGameTimer()
    }

    setTrunkDoor(vehicle, true)

    -- Enquanto o porta-malas estiver aberto, o personagem fica na animação
    -- configurada abaixo, olhando para a traseira do veículo. Ela permanece em
    -- loop até o inventário ser fechado ou a sessão ser encerrada pelo servidor.
    local ped = PlayerPedId()
    faceTrunk(ped, vehicle)
    playTrunkOpenAnimation(ped)

    Wait(350)

    if activeLootSession and activeLootSession.chestId == chestId then
        TriggerServerEvent('m_robbernpc:readyOpenChest', chestId)

        -- Fallback: caso o inventory não abra por algum erro, limpa a sessão.
        CreateThread(function()
            local deadline = GetGameTimer() + 8000
            local sawFocus = false

            while activeLootSession and activeLootSession.chestId == chestId and GetGameTimer() < deadline do
                if IsNuiFocused() then
                    sawFocus = true
                    break
                end
                Wait(100)
            end

            if not sawFocus and activeLootSession and activeLootSession.chestId == chestId then
                finishLootSession(true)
            end
        end)
    end
end)

-- Mantém a animação ativa durante toda a sessão do porta-malas. Alguns
-- eventos do inventory/FiveM podem cancelar tasks do ped; nesse caso ela é
-- restaurada automaticamente enquanto o porta-malas continuar aberto.
CreateThread(function()
    while true do
        if activeLootSession then
            local vehicle = NetToVeh(activeLootSession.netId)
            local ped = PlayerPedId()
            local anim = Config.TrunkOpenAnimation

            if vehicle ~= 0 and DoesEntityExist(vehicle) and anim and anim.dict and anim.name then
                if not IsEntityPlayingAnim(ped, anim.dict, anim.name, 3) then
                    faceTrunk(ped, vehicle)
                    playTrunkOpenAnimation(ped)
                end
            end

            Wait(500)
        else
            Wait(750)
        end
    end
end)

-- O inventory enviado dispara este evento sempre que a interface fecha.
-- Assim o baú temporário é apagado e a tampa fecha imediatamente.
AddEventHandler('inventory:shops:nuiClosed', function()
    if activeLootSession then
        finishLootSession(true)
    end
end)

RegisterNetEvent('m_robbernpc:forceSessionEnd', function(chestId, netId)
    if activeLootSession and activeLootSession.chestId == chestId then
        finishLootSession(false)
    else
        local vehicle = NetToVeh(netId)
        if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
            setTrunkDoor(vehicle, false)
        end
    end
end)

RegisterNetEvent('m_robbernpc:policeAlert:create', function(alertId, coords, radius)
    if policeBlips[alertId] then
        RemoveBlip(policeBlips[alertId])
        policeBlips[alertId] = nil
    end

    local blip = AddBlipForRadius(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0, tonumber(radius) or 85.0)
    SetBlipColour(blip, 1)
    SetBlipAlpha(blip, 115)
    SetBlipAsShortRange(blip, false)
    policeBlips[alertId] = blip

    -- Toca um alerta sonoro apenas quando a polícia recebe um NOVO chamado.
    -- O evento de criação é enviado pelo servidor somente aos policiais com
    -- Config.PolicePermission, então civis e o autor do roubo não escutam.
    if Config.PoliceAlertSound ~= false then
        PlaySoundFrontend(
            -1,
            Config.PoliceAlertSoundName or 'Event_Start_Text',
            Config.PoliceAlertSoundSet or 'GTAO_FM_Events_Soundset',
            true
        )
    end
end)

RegisterNetEvent('m_robbernpc:policeAlert:remove', function(alertId)
    local blip = policeBlips[alertId]
    if blip then
        RemoveBlip(blip)
        policeBlips[alertId] = nil
    end
end)

RegisterNetEvent('m_robbernpc:policeTracker:update', function(trackerId, coords, secondsLeft)
    if type(coords) ~= 'table' or not coords.x or not coords.y or not coords.z then return end

    local blip = policeTrackers[trackerId]
    if not blip or not DoesBlipExist(blip) then
        blip = AddBlipForCoord(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
        SetBlipSprite(blip, tonumber(Config.RadarTrackerBlipSprite) or 1)
        SetBlipColour(blip, tonumber(Config.RadarTrackerBlipColour) or 1)
        SetBlipScale(blip, tonumber(Config.RadarTrackerBlipScale) or 0.90)
        SetBlipDisplay(blip, 4)
        SetBlipAsShortRange(blip, false)
        SetBlipFlashes(blip, true)

        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(Config.RadarTrackerBlipName or 'Meliante rastreado')
        EndTextCommandSetBlipName(blip)

        PulseBlip(blip)
        policeTrackers[trackerId] = blip
    else
        SetBlipCoords(blip, coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    end
end)

RegisterNetEvent('m_robbernpc:policeTracker:remove', function(trackerId)
    local blip = policeTrackers[trackerId]
    if blip then
        if DoesBlipExist(blip) then RemoveBlip(blip) end
        policeTrackers[trackerId] = nil
    end
end)

RegisterNetEvent('m_robbernpc:trackAlert', function(alertId, coords, leaveDistance)
    activeCrimeAlert = {
        id = alertId,
        coords = vec3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0),
        distance = tonumber(leaveDistance) or Config.AlertEndDistance
    }

    CreateThread(function()
        local trackedId = alertId
        while activeCrimeAlert and activeCrimeAlert.id == trackedId do
            local ped = PlayerPedId()
            local distance = #(GetEntityCoords(ped) - activeCrimeAlert.coords)

            if distance >= activeCrimeAlert.distance then
                TriggerServerEvent('m_robbernpc:leftAlertArea', trackedId)
                activeCrimeAlert = nil
                break
            end

            Wait(500)
        end
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    hidePrompt()
    SendNUIMessage({ action = 'trackerStop' })

    local ped = PlayerPedId()
    stopRobberyAnimation(ped)
    stopTrunkOpenAnimation(ped)
    FreezeEntityPosition(ped, false)

    if activeLootSession then
        local vehicle = NetToVeh(activeLootSession.netId)
        if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
            setTrunkDoor(vehicle, false)
        end
    end

    for _, blip in pairs(policeBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end

    for _, blip in pairs(policeTrackers) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
end)
