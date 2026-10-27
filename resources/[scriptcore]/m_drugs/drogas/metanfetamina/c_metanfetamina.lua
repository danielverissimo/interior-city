local cfg = Config.Drugs.metanfetamina

-- ============================================================================
-- ESTADOS
-- ============================================================================
local carryingBenzoate = false
local benzoatePoured = false
local carryingToluene = false
local toluenePoured = false

local ephedrineState = "idle" -- idle | processing | ready
local ephedrineFinishAt = 0

local finalMixRunning = false
local finalProp1 = nil
local finalProp2 = nil
local metaCarryObject = nil

-- ============================================================================
-- HELPERS
-- ============================================================================
local function formatMetaTimer(ms)
    local total = math.max(0,math.ceil((tonumber(ms) or 0) / 1000))
    local minutes = math.floor(total / 60)
    local seconds = total % 60
    return string.format("%02d:%02d",minutes,seconds)
end

local function deleteMetaCarry()
    if metaCarryObject and DoesEntityExist(metaCarryObject) then
        DetachEntity(metaCarryObject,true,true)
        DeleteEntity(metaCarryObject)
    end
    metaCarryObject = nil
end

local function attachMetaCarry(data)
    deleteMetaCarry()
    if not data or not data.model then return end

    local ped = PlayerPedId()
    local hash = type(data.model) == "number" and data.model or GetHashKey(data.model)

    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Citizen.Wait(10)
    end

    metaCarryObject = CreateObjectNoOffset(hash,0.0,0.0,0.0,true,true,false)

    AttachEntityToEntity(
        metaCarryObject,
        ped,
        GetPedBoneIndex(ped,data.bone or 28422),
        data.x or 0.0,
        data.y or 0.0,
        data.z or 0.0,
        data.rx or 0.0,
        data.ry or 0.0,
        data.rz or 0.0,
        true,true,false,true,1,true
    )

    SetModelAsNoLongerNeeded(hash)
end

local methPackingScene = nil
local methPackingSceneObjects = {}

local function cleanupMethPackingScene()
    if methPackingScene then
        NetworkStopSynchronisedScene(methPackingScene)
        methPackingScene = nil
    end

    for _,object in ipairs(methPackingSceneObjects) do
        if object and DoesEntityExist(object) then
            DeleteEntity(object)
        end
    end

    methPackingSceneObjects = {}
end

local function loadMetaModel(model)
    local hash = type(model) == "number" and model or GetHashKey(model)

    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Citizen.Wait(10)
    end

    return hash
end

local function playMethPackingScene(requestedDuration)
    cleanupMethPackingScene()

    local ped = PlayerPedId()
    local sceneCfg = cfg.packingScene

    if not sceneCfg then
        return false,requestedDuration or 35000
    end

    local dict = sceneCfg.animDict
    local playerAnim = sceneCfg.playerAnim

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(10)
    end

    local pedCoords = GetEntityCoords(ped)
    local desiredHeading = GetEntityHeading(ped) + (sceneCfg.headingOffset or 0.0)

    -- Pequeno recuo do PERSONAGEM, não da origem da scene.
    -- Isso mantém o ped afastado da mesa sem quebrar o root-motion do clip.
    local backOffset = 0
    local headingRad = math.rad(desiredHeading)
    local forwardX = -math.sin(headingRad)
    local forwardY =  math.cos(headingRad)

    local targetX = pedCoords.x - (forwardX * backOffset)
    local targetY = pedCoords.y - (forwardY * backOffset)
    local targetZ = pedCoords.z

    -- =====================================================================
    -- CORREÇÃO DO "LIMBO"
    -- =====================================================================
    -- Essa animação possui root-motion/offset interno.
    -- Se usarmos diretamente a posição do ped como origem da scene, o GTA
    -- soma esse offset e desloca ped + props para fora do MLO.
    --
    -- Primeiro descobrimos a rotação inicial interna do clip e compensamos.
    local initialRot = GetAnimInitialOffsetRotation(
        dict,
        playerAnim,
        0.0,0.0,0.0,
        0.0,0.0,0.0,
        0.0,
        2
    )

    local sceneHeading = desiredHeading - initialRot.z

    -- Agora obtemos a posição inicial que o clip teria com origem 0,0,0
    -- usando a rotação já compensada.
    local initialPos = GetAnimInitialOffsetPosition(
        dict,
        playerAnim,
        0.0,0.0,0.0,
        0.0,0.0,sceneHeading,
        0.0,
        2
    )

    -- Calcula a origem da scene de modo que o PRIMEIRO FRAME do ped caia
    -- exatamente em targetX/Y/Z.
    local sceneX = targetX - initialPos.x
    local sceneY = targetY - initialPos.y
    local sceneZ = targetZ - initialPos.z

    -- Velocidade natural. Se o clip for maior que o tempo configurado,
    -- usamos a duração real do clip para não cortá-lo pela metade.
    local animSeconds = GetAnimDuration(dict,playerAnim)
    local configuredMs = requestedDuration or 35000
    local sceneDuration = configuredMs

    if animSeconds and animSeconds > 0.0 then
        local fullAnimMs = math.ceil(animSeconds * 1000.0) + 500
        if fullAnimMs > sceneDuration then
            sceneDuration = fullAnimMs
        end
    end

    methPackingScene = NetworkCreateSynchronisedScene(
        sceneX,
        sceneY,
        sceneZ,
        0.0,
        0.0,
        sceneHeading,
        2,
        false,
        false,
        -1,
        0,
        1.0
    )

    NetworkAddPedToSynchronisedScene(
        ped,
        methPackingScene,
        dict,
        playerAnim,
        1.5,
        -4.0,
        1,
        16,
        1148846080,
        0
    )

    for _,objectData in ipairs(sceneCfg.objects or {}) do
        local hash = loadMetaModel(objectData.model)

        local object = CreateObjectNoOffset(
            hash,
            sceneX,
            sceneY,
            sceneZ,
            true,
            true,
            false
        )

        methPackingSceneObjects[#methPackingSceneObjects + 1] = object

        NetworkAddEntityToSynchronisedScene(
            object,
            methPackingScene,
            dict,
            objectData.anim,
            1.0,
            1.0,
            1
        )

        SetModelAsNoLongerNeeded(hash)
    end

    NetworkStartSynchronisedScene(methPackingScene)

    return true,sceneDuration
end


local function playBoxCarry(data)
    vRP._playAnim(true,{{"anim@heists@box_carry@","idle"}},true)
    attachMetaCarry(data)
end

local function pourChemical(data,onFinish)
    local ped = PlayerPedId()
    local pourTime = 8000

    SetEntityHeading(ped,cfg.locations.tank.heading + 0.0)
    attachMetaCarry(data)

    local dict = "weapon@w_sp_jerrycan"
    local anim = "fire"

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(10)
    end

    -- A mesma animação de despejo usada na cocaína.
    TaskPlayAnim(ped,dict,anim,8.0,-8.0,-1,49,0.0,false,false,false)
    MDrugsLockAction(pourTime)

    SetTimeout(pourTime,function()
        deleteMetaCarry()
        ClearPedTasks(ped)
        if onFinish then onFinish() end
    end)
end

-- ============================================================================
-- FLUXO PRINCIPAL
-- ============================================================================
Citizen.CreateThread(function()
    while true do
        local sleep = 1000

        -- 1) PEGAR BENZOATO
        local c = cfg.locations.takeBenzoate
        if MDrugsDistance(c) <= 2.0 and not carryingBenzoate and not benzoatePoured then
            sleep = 1
            MDrugsDrawText3D(c.x,c.y,c.z,"[~g~E~w~] Para pegar o ~g~Benzoato~w~.")

            if IsControlJustPressed(0,Config.InteractionControl) and MDrugs.checkPermission("metanfetamina") then
                if MDrugs.takeMethIngredient("benzoate") then
                    carryingBenzoate = true
                    MDrugsSetPed(c)
                vRP._playAnim(false,{{"amb@prop_human_parking_meter@female@idle_a","idle_a_female"}},true)
                MDrugsLockAction(2500)

                SetTimeout(2500,function()
                    vRP._stopAnim(false)
                    playBoxCarry(cfg.carry.benzoate)
                    TriggerEvent("Notify","sucesso","Você separou <b>2x Benzoato</b>.")
                end)
                end
            end
        end

        -- 2) DESPEJAR BENZOATO NO TANQUE
        c = cfg.locations.tank
        if MDrugsDistance(c) <= 2.0 and carryingBenzoate and not benzoatePoured then
            sleep = 1
            MDrugsDrawText3D(c.x,c.y,c.z,"[~g~E~w~] Para colocar o ~g~Benzoato~w~ no tanque.")

            if IsControlJustPressed(0,Config.InteractionControl) then
                carryingBenzoate = false
                vRP._stopAnim(false)

                pourChemical(cfg.pour.benzoate,function()
                    benzoatePoured = true
                end)
            end
        end

        -- 3) PEGAR TOULENE
        c = cfg.locations.takeToluene
        if MDrugsDistance(c) <= 2.0 and benzoatePoured and not carryingToluene and not toluenePoured then
            sleep = 1
            MDrugsDrawText3D(c.x,c.y,c.z,"[~g~E~w~] Para pegar o ~g~Toulene~w~.")

            if IsControlJustPressed(0,Config.InteractionControl) then
                if MDrugs.takeMethIngredient("toluene") then
                    carryingToluene = true
                    MDrugsSetPed(c)
                vRP._playAnim(false,{{"amb@prop_human_parking_meter@female@idle_a","idle_a_female"}},true)
                MDrugsLockAction(2500)

                SetTimeout(2500,function()
                    vRP._stopAnim(false)
                    playBoxCarry(cfg.carry.toluene)
                    TriggerEvent("Notify","sucesso","Você separou <b>2x Toulene</b>.")
                end)
                end
            end
        end

        -- 4) DESPEJAR TOULENE NO MESMO TANQUE
        c = cfg.locations.tank
        if MDrugsDistance(c) <= 2.0 and carryingToluene and not toluenePoured then
            sleep = 1
            MDrugsDrawText3D(c.x,c.y,c.z,"[~g~E~w~] Para colocar o ~g~Toulene~w~ no tanque.")

            if IsControlJustPressed(0,Config.InteractionControl) then
                carryingToluene = false
                vRP._stopAnim(false)

                pourChemical(cfg.pour.toluene,function()
                    toluenePoured = true
                    ephedrineState = "idle"
                end)
            end
        end

        -- 5) PREPARAR / AGUARDAR / COLETAR EFEDRINA
        c = cfg.locations.tank
        if benzoatePoured and toluenePoured and MDrugsDistance(c) <= 2.0 then
            sleep = 1

            if ephedrineState == "processing" and GetGameTimer() >= ephedrineFinishAt then
                ephedrineState = "ready"
            end

            if ephedrineState == "idle" then
                MDrugsDrawText3D(c.x,c.y,c.z,"[~g~E~w~] Para preparar a Efedrina")

                if IsControlJustPressed(0,Config.InteractionControl) then
                    if MDrugs.startMethEphedrine() then
                        ephedrineState = "processing"
                        ephedrineFinishAt = GetGameTimer() + (cfg.ephedrine.duration or 60000)
                        MDrugsSetPed(c)
                        vRP._playAnim(false,{{"mini@repair","fixing_a_ped"}},true)
                        MDrugsLockAction(2500)
                        SetTimeout(2500,function()
                            vRP._stopAnim(false)
                        end)
                    end
                end

            elseif ephedrineState == "processing" then
                local remaining = math.max(0,ephedrineFinishAt - GetGameTimer())
                MDrugsDrawText3D(
                    c.x,c.y,c.z,
                    "Aguarde ~g~"..formatMetaTimer(remaining).."~w~ para Efedrina ficar pronta"
                )

            elseif ephedrineState == "ready" then
                MDrugsDrawText3D(c.x,c.y,c.z,"[~g~E~w~] Para coletar a Efedrina")

                if IsControlJustPressed(0,Config.InteractionControl) then
                    if MDrugs.finishMethEphedrine() then
                        ephedrineState = "idle"
                        ephedrineFinishAt = 0
                        benzoatePoured = false
                        toluenePoured = false
                    end
                end
            end
        end

        -- 6) MIXAR EFEDRINA + ANFETAMINA (SEMPRE VISÍVEL)
        c = cfg.locations.finalMix
        if MDrugsDistance(c) <= 2.0 and not finalMixRunning then
            sleep = 1
            MDrugsDrawText3D(c.x,c.y,c.z,"[~g~E~w~] Para mixar a Efedrina com Anfetamina")

            if IsControlJustPressed(0,Config.InteractionControl) then
                if MDrugs.startMethFinalMix() then
                    finalMixRunning = true
                    MDrugsSetPed(c)

                    -- Props aparecem lado a lado na mesa durante a mistura.
                    finalProp1 = MDrugsCreateObject(cfg.props.finalMixLeft)
                    finalProp2 = MDrugsCreateObject(cfg.props.finalMixRight)

                    local configuredDuration = cfg.finalMix.duration or 35000

                    -- Cena sincronizada com compensação de root-motion.
                    local sceneStarted,mixDuration = playMethPackingScene(configuredDuration)

                    if not sceneStarted then
                        finalMixRunning = false
                        return
                    end

                    MDrugsLockAction(mixDuration)
                    TriggerEvent("progress",math.ceil(mixDuration / 1000),"MIXANDO EFEDRINA E ANFETAMINA")

                    SetTimeout(mixDuration,function()
                        cleanupMethPackingScene()
                        ClearPedTasks(PlayerPedId())

                        MDrugsDeleteObjects({finalProp1,finalProp2})
                        finalProp1,finalProp2 = nil,nil

                        MDrugs.finishMethFinalMix()
                        finalMixRunning = false
                    end)
                end
            end
        end

        Citizen.Wait(sleep)
    end
end)

-- Enquanto estiver carregando Benzoato/Toulene, não corre nem pula.
Citizen.CreateThread(function()
    while true do
        if carryingBenzoate or carryingToluene then
            Citizen.Wait(0)
            DisableControlAction(0,21,true)
            DisableControlAction(0,22,true)
        else
            Citizen.Wait(250)
        end
    end
end)

AddEventHandler("onResourceStop",function(resource)
    if resource ~= GetCurrentResourceName() then return end
    deleteMetaCarry()
    cleanupMethPackingScene()
    MDrugsDeleteObjects({finalProp1,finalProp2})
end)
