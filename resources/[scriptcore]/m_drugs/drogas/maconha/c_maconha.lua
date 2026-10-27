local cfg = Config.Drugs.maconha

-- ============================================================================
-- PLANTIO MULTIPONTO DA MACONHA
-- ============================================================================
-- Cada ponto possui seu próprio estado e seu próprio cronômetro.
-- O jogador pode plantar em um ponto, sair, buscar outro adubo e plantar nos
-- demais enquanto os anteriores continuam crescendo normalmente.
local carryingFertilizer = false
local weedSlots = {}

local function createAt(model,pos,zOffset)
    return MDrugsCreateObject({
        model = model,
        x = pos.x,
        y = pos.y,
        z = pos.z + (zOffset or 0.0),
        heading = pos.heading
    })
end

local function deleteSlotObjects(slot)
    for _,object in ipairs(slot.objects or {}) do
        MDrugsDeleteObject(object)
    end
    slot.objects = {}
end

-- Cria os 3 pés nas posições definidas em slot.plants.
-- Todos os três avançam de estágio juntos, mas cada um possui coordenada própria.
local function setSlotObjects(slot,model,zOffset)
    deleteSlotObjects(slot)

    for _,plantPos in ipairs(slot.plants or {}) do
        slot.objects[#slot.objects + 1] = createAt(model,plantPos,zOffset)
    end
end

local function deleteSlotFertilizer(slot)
    if slot.fertilizerObject then
        MDrugsDeleteObject(slot.fertilizerObject)
        slot.fertilizerObject = nil
    end
end

local function createSlotFertilizer(slot)
    deleteSlotFertilizer(slot)

    local prop = cfg.props.fertilizerOpen
    local off = cfg.planting and cfg.planting.fertilizerOpenOffset or { x=-1.28, y=-0.37, z=-1.10 }

    slot.fertilizerObject = MDrugsCreateObject({
        model = prop.model,
        x = slot.action.x + (off.x or 0.0),
        y = slot.action.y + (off.y or 0.0),
        z = slot.action.z + (off.z or -1.10),
        heading = slot.action.heading
    })
end

local function deleteAllPlantObjects()
    for _,slot in ipairs(weedSlots) do
        deleteSlotObjects(slot)
        deleteSlotFertilizer(slot)
    end
end

local function getPlantingConfig()
    return cfg.planting or {}
end

local function secondsRemaining(slot)
    if not slot.dueAt then return 0 end
    return math.max(0,math.ceil((slot.dueAt - GetGameTimer()) / 1000))
end

local function formatPlantTimer(slot)
    local remaining = secondsRemaining(slot)
    if slot.stage == "waiting_water" then
        return ("PRECISA REGAR EM: ~g~%02ds~w~"):format(remaining)
    elseif slot.stage == "growing" then
        local minutes = math.floor(remaining / 60)
        local seconds = remaining % 60
        if minutes > 0 then
            return ("CRESCENDO: ~g~%02d:%02d~w~"):format(minutes,seconds)
        end
        return ("CRESCENDO: ~g~%02ds~w~"):format(seconds)
    end
    return nil
end

local function initializeWeedSlots()
    weedSlots = {}
    local planting = getPlantingConfig()
    for index,point in ipairs(planting.points or {}) do
        local action = point.action or point
        local plants = point.plants or { action, action, action }

        weedSlots[index] = {
            index = index,
            config = point,
            action = action,
            plants = plants,
            stage = "empty",
            dueAt = nil,
            objects = {},
            fertilizerObject = nil,
            busy = false
        }
    end
end

initializeWeedSlots()

-- ============================================================================
-- ESPAÇOS LIVRES NO MLO ORIGINAL
-- ============================================================================
local weedMapHidesApplied = false

local function setNativeWeedMapHides(enable)
    -- IMPORTANTE:
    -- CreateModelHideExcludingScriptObjects oculta somente os objetos do mapa/MLO.
    -- Os pés criados pelo próprio m_drugs com CreateObject continuam visíveis.
    local cleanup = cfg.mapCleanup
    local planting = getPlantingConfig()

    if not cleanup or cleanup.enabled == false then
        return
    end

    local radius = cleanup.radius or 1.05

    for _,point in ipairs(planting.points or {}) do
        local positions = {}
        positions[#positions + 1] = point.action or point

        for _,plantPos in ipairs(point.plants or {}) do
            positions[#positions + 1] = plantPos
        end

        for _,pos in ipairs(positions) do
            for _,model in ipairs(cleanup.models or {}) do
                local hash = type(model) == "number" and model or GetHashKey(model)

                if enable then
                    CreateModelHideExcludingScriptObjects(pos.x,pos.y,pos.z,radius,hash,true)
                else
                    RemoveModelHide(pos.x,pos.y,pos.z,radius,hash,true)
                end
            end
        end
    end

    weedMapHidesApplied = enable
end

Citizen.CreateThread(function()
    while true do
        local coords = GetEntityCoords(PlayerPedId())
        local center = cfg.locations.collectFertilizer
        local distance = #(coords - vector3(center.x,center.y,center.z))

        if distance <= 45.0 then
            if not weedMapHidesApplied then
                setNativeWeedMapHides(true)
            end
            Citizen.Wait(1500)
        else
            if weedMapHidesApplied then
                setNativeWeedMapHides(false)
            end
            Citizen.Wait(2000)
        end
    end
end)

AddEventHandler("onResourceStop",function(resource)
    if resource == GetCurrentResourceName() and weedMapHidesApplied then
        setNativeWeedMapHides(false)
    end
end)

local function finishPlanting(slot)
    deleteSlotFertilizer(slot)
    setSlotObjects(slot,"bkr_prop_weed_01_small_01c",getPlantingConfig().smallZOffset or -1.10)

    slot.stage = "waiting_water"
    slot.dueAt = GetGameTimer() + (getPlantingConfig().timeUntilWater or 30000)
    slot.busy = false

    TriggerEvent("Notify","sucesso","Você plantou um <b>pé de maconha</b>. Em breve ele precisará ser regado.")
end

local function plantAtSlot(slot)
    if not carryingFertilizer or slot.stage ~= "empty" or slot.busy or MDrugsIsActionLocked() then
        return
    end

    slot.busy = true
    carryingFertilizer = false

    vRP._DeletarObjeto()
    createSlotFertilizer(slot)
    setSlotObjects(slot,"bkr_prop_weed_plantpot_stack_01b",getPlantingConfig().potZOffset or -1.10)

    MDrugsSetPed({ heading = slot.action.heading or 30.22 })
    vRP._playAnim(false,{{"amb@world_human_gardener_plant@female@base","base_female"}},true)

    local duration = getPlantingConfig().plantAnimationTime or 5000
    MDrugsLockAction(duration)

    SetTimeout(duration,function()
        vRP._stopAnim(false)
        deleteSlotObjects(slot)
        finishPlanting(slot)
    end)
end

local function waterSlot(slot)
    if slot.stage ~= "needs_water" or slot.busy or MDrugsIsActionLocked() then
        return
    end

    slot.busy = true
    MDrugsSetPed({ heading = slot.action.heading or 30.22 })
    vRP._playAnim(true,{{"amb@prop_human_parking_meter@female@idle_a","idle_a_female"}},true)
    vRP._CarregarObjeto("","","prop_wateringcan",50,57005,0.45,0.0,0.05,0.0,260.0,140.0)

    local duration = getPlantingConfig().waterAnimationTime or 5000
    MDrugsLockAction(duration)

    SetTimeout(duration,function()
        vRP._stopAnim(false)
        vRP._DeletarObjeto()

        setSlotObjects(slot,"bkr_prop_weed_med_01a",getPlantingConfig().mediumZOffset or -3.50)
        slot.stage = "growing"
        slot.dueAt = GetGameTimer() + (getPlantingConfig().timeAfterWater or 60000)
        slot.busy = false

        TriggerEvent("Notify","sucesso","Você regou este <b>pé de maconha</b>. Aguarde ele crescer.")
    end)
end

local function harvestSlot(slot)
    if slot.stage ~= "ready" or slot.busy or MDrugsIsActionLocked() then
        return
    end

    slot.busy = true
    MDrugsSetPed({ heading = slot.action.heading or 30.22 })
    vRP._playAnim(false,{{"amb@prop_human_parking_meter@female@idle_a","idle_a_female"}},true)
    vRP._CarregarObjeto("amb@prop_human_parking_meter@female@idle_a","idle_a_female","p_cs_scissors_s",50,57005,0.055,0.05,0.0,240.0,0.0,0.0)

    local duration = getPlantingConfig().harvestAnimationTime or 10000
    MDrugsLockAction(duration)

    SetTimeout(duration,function()
        vRP._stopAnim(false)
        vRP._DeletarObjeto()
        deleteSlotObjects(slot)

        slot.stage = "empty"
        slot.dueAt = nil
        slot.busy = false

        MDrugs.finishProduction("maconha")
    end)
end

-- Atualiza individualmente o crescimento de cada plantação.
Citizen.CreateThread(function()
    while true do
        local now = GetGameTimer()

        for _,slot in ipairs(weedSlots) do
            if not slot.busy and slot.dueAt and now >= slot.dueAt then
                if slot.stage == "waiting_water" then
                    slot.stage = "needs_water"
                    slot.dueAt = nil
                    setSlotObjects(slot,"bkr_prop_weed_01_small_01a",getPlantingConfig().smallZOffset or -1.10)
                elseif slot.stage == "growing" then
                    slot.stage = "ready"
                    slot.dueAt = nil
                    setSlotObjects(slot,"bkr_prop_weed_lrg_01a",getPlantingConfig().largeZOffset or -3.50)
                end
            end
        end

        Citizen.Wait(200)
    end
end)

-- Ponto para pegar o pote de adubo. Agora são exigidos 5x "adubo" no inventário.
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local c = cfg.locations.collectFertilizer

        if not carryingFertilizer and MDrugsDistance(c) <= 1.0 then
            sleep = 1
            local requirement = getPlantingConfig().fertilizerRequirement or { item="adubo", amount=5 }
            MDrugsDrawText3D(
                c.x,c.y,c.z,
                ("[~r~E~w~] PEGAR ADUBO (~g~%dx %s~w~)"):format(requirement.amount or 5,requirement.item or "adubo"),
                {41,11,41,68}
            )

            if IsControlJustPressed(0,Config.InteractionControl) and not MDrugsIsActionLocked() then
                if MDrugs.checkPermission("maconha") and MDrugs.takeWeedFertilizer() then
                    MDrugsSetPed(c.action)
                    vRP._playAnim(true,{{"pickup_object","pickup_low"}},false)

                    local duration = getPlantingConfig().pickupAnimationTime or 2500
                    MDrugsLockAction(duration)

                    SetTimeout(duration,function()
                        carryingFertilizer = true
                        local carry = cfg.props.fertilizerCarry

                        -- Mantém o ped com os dois braços à frente, segurando o pote.
                        -- A animação precisa ser iniciada explicitamente em loop; apenas
                        -- passar dict/anim para _CarregarObjeto não garante que ela fique ativa.
                        vRP._playAnim(true,{{"anim@heists@box_carry@","idle"}},true)

                        vRP._CarregarObjeto(
                            "anim@heists@box_carry@","idle",carry.model,50,carry.bone,
                            carry.x,carry.y,carry.z,carry.rx,carry.ry,carry.rz
                        )
                        TriggerEvent("Notify","sucesso","Você pegou o <b>pote de adubo</b>.")
                    end)
                end
            end
        end

        Citizen.Wait(sleep)
    end
end)

-- Interação e timers dos 6 pontos independentes.
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local pedCoords = GetEntityCoords(PlayerPedId())

        for _,slot in ipairs(weedSlots) do
            local p = slot.action
            local distance = #(pedCoords - vector3(p.x,p.y,p.z))

            if distance <= 15.0 then
                sleep = 0

                local timerText = formatPlantTimer(slot)
                if timerText then
                    MDrugsDrawText3D(p.x,p.y,p.z + 1.05,timerText,{41,11,41,68})
                end

                if distance <= (getPlantingConfig().interactionDistance or 1.15) and not slot.busy then
                    if slot.stage == "empty" then
                        if carryingFertilizer then
                            MDrugsDrawText3D(p.x,p.y,p.z + 0.35,"[~r~E~w~] PARA PLANTAR A ~g~MACONHA~w~.",{41,11,41,68})
                            if IsControlJustPressed(0,Config.InteractionControl) and MDrugs.checkPermission("maconha") then
                                plantAtSlot(slot)
                            end
                        else
                            MDrugsDrawText3D(p.x,p.y,p.z + 0.35,"PEGUE UM ~g~ADUBO~w~ PARA PLANTAR.",{41,11,41,68})
                        end
                    elseif slot.stage == "needs_water" then
                        MDrugsDrawText3D(p.x,p.y,p.z + 0.35,"[~r~E~w~] PARA ~b~REGAR~w~ A PLANTA.",{41,11,41,68})
                        if IsControlJustPressed(0,Config.InteractionControl) then
                            waterSlot(slot)
                        end
                    elseif slot.stage == "ready" then
                        MDrugsDrawText3D(p.x,p.y,p.z + 0.35,"[~r~E~w~] PARA COLHER A ~g~MACONHA~w~.",{41,11,41,68})
                        if IsControlJustPressed(0,Config.InteractionControl) then
                            harvestSlot(slot)
                        end
                    end
                end
            end
        end

        Citizen.Wait(sleep)
    end
end)

-- Enquanto estiver carregando o pote de adubo até um ponto de plantio,
-- o jogador pode andar normalmente, mas não pode correr/sprintar nem pular.
-- Assim que o adubo é utilizado em plantAtSlot(), carryingFertilizer vira false
-- e os controles são liberados imediatamente.
Citizen.CreateThread(function()
    while true do
        if carryingFertilizer then
            Citizen.Wait(0)

            -- INPUT_SPRINT (SHIFT)
            DisableControlAction(0,21,true)

            -- INPUT_JUMP (ESPAÇO)
            DisableControlAction(0,22,true)

            if not MDrugsIsActionLocked() and IsControlJustPressed(0,Config.CancelControl) then
                carryingFertilizer = false
                vRP._DeletarObjeto()
                TriggerEvent("Notify","aviso","Você cancelou o transporte do adubo.")
            end
        else
            Citizen.Wait(500)
        end
    end
end)

-- ============================================================================
-- PREPARO DA MACONHA NAS CADEIRAS
-- ============================================================================
local preparingWeed = false
local preparationChairs = {}

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(10)
    end
end

local function getPreparationChairData(chair)
    local prep = cfg.preparation
    local seat = prep.seatOffset or { x=0.0, y=0.0, z=0.0 }
    local marker = prep.markerOffset or { x=0.75, y=0.0, z=0.10 }

    local seatCoords = GetOffsetFromEntityInWorldCoords(
        chair,
        seat.x or 0.0,
        seat.y or 0.0,
        seat.z or 0.0
    )

    local markerCoords = GetOffsetFromEntityInWorldCoords(
        chair,
        marker.x or 0.75,
        marker.y or 0.0,
        marker.z or 0.10
    )

    return seatCoords,markerCoords,(GetEntityHeading(chair) + (prep.seatHeadingOffset or 180.0)) % 360.0
end

local function refreshPreparationChairs()
    local prep = cfg.preparation
    if not prep then return end

    local center = vector3(prep.searchCenter.x,prep.searchCenter.y,prep.searchCenter.z)
    local model = tonumber(prep.chairModel)
    local found = {}

    for _,object in ipairs(GetGamePool("CObject")) do
        if DoesEntityExist(object) and GetEntityModel(object) == model then
            local coords = GetEntityCoords(object)
            if #(coords - center) <= (prep.searchRadius or 20.0) then
                found[#found+1] = object
            end
        end
    end

    preparationChairs = found
end

local preparationVisualBricks = {}
local preparationHandProp = nil

local function deletePreparationHandProp()
    if preparationHandProp and DoesEntityExist(preparationHandProp) then
        DetachEntity(preparationHandProp,true,true)
        DeleteEntity(preparationHandProp)
    end
    preparationHandProp = nil
end

local function createPreparationHandProp()
    deletePreparationHandProp()

    local prep = cfg.preparation
    local hand = prep and prep.handWeedProp
    if not hand then return end

    local model = tonumber(hand.model)
    if not model or not IsModelInCdimage(model) or not IsModelValid(model) then
        print("[m_drugs] Prop da mão inválido: "..tostring(hand.model))
        return
    end

    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Citizen.Wait(10)
    end

    if not HasModelLoaded(model) then
        print("[m_drugs] Não foi possível carregar o prop da mão: "..tostring(model))
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local obj = CreateObjectNoOffset(model,coords.x,coords.y,coords.z + 0.2,false,false,false)

    if obj and obj ~= 0 then
        SetEntityCollision(obj,false,false)
        AttachEntityToEntity(
            obj,
            ped,
            GetPedBoneIndex(ped,hand.bone or 18905),
            hand.x or 0.10,
            hand.y or 0.02,
            hand.z or 0.0,
            hand.rx or -80.0,
            hand.ry or 0.0,
            hand.rz or 10.0,
            true,true,false,true,1,true
        )
        preparationHandProp = obj
    end

    SetModelAsNoLongerNeeded(model)
end

local function deletePreparationVisualBricks()
    for i,obj in ipairs(preparationVisualBricks) do
        if obj and DoesEntityExist(obj) then
            DeleteEntity(obj)
        end
        preparationVisualBricks[i] = nil
    end
end

local function getClosestPreparationTable(chair)
    local prep = cfg.preparation
    if not prep or not DoesEntityExist(chair) then return nil end

    local chairCoords = GetEntityCoords(chair)
    local tableModel = tonumber(prep.tableModel)
    local closest = nil
    local closestDistance = prep.tableSearchRadius or 4.5

    for _,object in ipairs(GetGamePool("CObject")) do
        if DoesEntityExist(object) and GetEntityModel(object) == tableModel then
            local distance = #(GetEntityCoords(object) - chairCoords)
            if distance <= closestDistance then
                closest = object
                closestDistance = distance
            end
        end
    end

    return closest
end

local function createPreparationVisualBricks(chair,amount)
    deletePreparationVisualBricks()

    local prep = cfg.preparation
    local tableEntity = getClosestPreparationTable(chair)
    if not prep or not tableEntity or not DoesEntityExist(tableEntity) then
        return
    end

    local model = tonumber(prep.weedBrickModel)
    if not model or not IsModelInCdimage(model) or not IsModelValid(model) then
        print("[m_drugs] Weed Brick Open inválido: "..tostring(prep.weedBrickModel))
        return
    end

    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Citizen.Wait(10)
    end

    if not HasModelLoaded(model) then
        print("[m_drugs] Não foi possível carregar o Weed Brick Open: "..tostring(model))
        return
    end

    -- Descobre automaticamente a altura real do tampo deste model.
    local _,tableMax = GetModelDimensions(GetEntityModel(tableEntity))
    local tableTopZ = (tableMax and tableMax.z or 0.75) + (prep.weedBrickHeightOffset or 0.025)
    local offsets = prep.weedBrickOffsets or {}
    local visualAmount = math.min(tonumber(amount) or 2, prep.maxVisualBricks or #offsets, #offsets)
    local tableHeading = GetEntityHeading(tableEntity)

    for i=1,visualAmount do
        local offset = offsets[i]
        if offset then
            local pos = GetOffsetFromEntityInWorldCoords(
                tableEntity,
                offset.x or 0.0,
                offset.y or 0.0,
                tableTopZ + (offset.z or 0.0)
            )

            local obj = CreateObjectNoOffset(model,pos.x,pos.y,pos.z,false,false,false)
            if obj and obj ~= 0 then
                SetEntityHeading(obj,(tableHeading + (offset.heading or prep.weedBrickHeadingOffset or 0.0)) % 360.0)
                FreezeEntityPosition(obj,true)
                SetEntityCollision(obj,false,false)
                preparationVisualBricks[#preparationVisualBricks+1] = obj
            end
        end
    end

    SetModelAsNoLongerNeeded(model)
end

local function startWeedPreparation(chair)
    if preparingWeed or MDrugsIsActionLocked() or not DoesEntityExist(chair) then
        return
    end

    local production = MDrugs.startWeedPreparation()
    if not production then
        return
    end

    preparingWeed = true

    local prep = cfg.preparation
    local ped = PlayerPedId()
    local seatCoords,_,heading = getPreparationChairData(chair)

    -- O teleporte aqui é proposital: diferente das ações normais de produção,
    -- a cadeira exige encaixe exato do ped no assento.
    SetEntityCoordsNoOffset(ped,seatCoords.x,seatCoords.y,seatCoords.z,false,false,false)
    SetEntityHeading(ped,heading)

    ClearPedTasksImmediately(ped)
    TaskStartScenarioAtPosition(
        ped,
        prep.scenario or "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER",
        seatCoords.x,seatCoords.y,seatCoords.z,
        heading,
        0,
        true,
        true
    )

    -- Dá tempo para o scenario encaixar o personagem na cadeira.
    Citizen.Wait(1000)

    -- Exibe visualmente os malotes em cima da mesa mais próxima durante
    -- todo o preparo. A quantidade acompanha a produção, com limite visual
    -- para não encher a mesa de objetos.
    createPreparationVisualBricks(chair,production.outputAmount or 2)

    -- Mostra o pacote de maconha na mão durante o preparo.
    createPreparationHandProp()

    -- Animação de separação/embalagem de maconha com as duas mãos.
    -- Não utiliza mais tesoura ou qualquer outro prop preso à mão.
    local preparationAnim = prep.animation or {}
    local animDict = preparationAnim.dict or "anim@amb@business@weed@weed_sorting_seated@"
    local animName = preparationAnim.name or "sorter_right_sort_v3_sorter02"

    loadAnimDict(animDict)
    -- Mantém o scenario da cadeira como tarefa principal e executa apenas
    -- a parte superior da animação como tarefa secundária.
    -- Flag 49 = LOOPING (1) + UPPERBODY (16) + SECONDARY (32).
    -- Dessa forma as pernas/quadril continuam presos ao scenario sentado
    -- enquanto braços e mãos fazem o movimento de preparo.
    TaskPlayAnim(
        ped,
        animDict,
        animName,
        4.0,-4.0,
        prep.duration or 30000,
        preparationAnim.flags or 49,
        0.0,
        false,false,false
    )

    local preparationDuration = prep.duration or 30000
    MDrugsLockAction(preparationDuration)

    -- Timer visível durante todo o preparo.
    local finishAt = GetGameTimer() + preparationDuration
    while GetGameTimer() < finishAt do
        Citizen.Wait(0)

        local remaining = math.max(0, math.ceil((finishAt - GetGameTimer()) / 1000))
        local text = ("PREPARANDO O MALOTE DE MACONHA, AGUARDE!  %02ds"):format(remaining)

        SetTextFont(4)
        SetTextScale(0.42,0.42)
        SetTextColour(255,255,255,235)
        SetTextCentre(true)
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(0.5,0.88)
    end

    -- Terminou o preparo: os malotes visuais somem da mesa e o pacote sai da mão.
    deletePreparationVisualBricks()
    deletePreparationHandProp()

    ClearPedTasksImmediately(ped)

    -- Ao terminar, tira o ped do assento e coloca ele ao lado da própria cadeira.
    -- Isso evita o scenario escolher uma posição de saída em cima/na direção da mesa.
    local exit = prep.exitOffset or { x = 0.85, y = 0.0, z = 0.0 }
    local exitCoords = GetOffsetFromEntityInWorldCoords(
        chair,
        exit.x or 0.85,
        exit.y or 0.0,
        exit.z or 0.0
    )

    FreezeEntityPosition(ped,false)
    SetEntityCoordsNoOffset(ped,exitCoords.x,exitCoords.y,exitCoords.z,false,false,false)
    SetEntityHeading(ped,(GetEntityHeading(chair) + (prep.exitHeadingOffset or 90.0)) % 360.0)

    preparingWeed = false

    MDrugs.finishWeedPreparation()
end

-- Atualiza a lista das 5 cadeiras (ou qualquer quantidade encontrada) sem
-- precisar cadastrar uma coordenada manual para cada uma.
Citizen.CreateThread(function()
    while true do
        refreshPreparationChairs()
        Citizen.Wait(2000)
    end
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local prep = cfg.preparation

        if prep and not preparingWeed then
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)

            for _,chair in ipairs(preparationChairs) do
                if DoesEntityExist(chair) then
                    local _,markerCoords = getPreparationChairData(chair)
                    local distance = #(pedCoords - markerCoords)

                    if distance <= 8.0 then
                        sleep = 0

                        DrawMarker(
                            21,
                            markerCoords.x,markerCoords.y,markerCoords.z + 0.15,
                            0.0,0.0,0.0,
                            0.0,180.0,0.0,
                            0.18,0.18,0.18,
                            80,200,90,180,
                            false,true,2,false,nil,nil,false
                        )

                        if distance <= (prep.interactionDistance or 1.55) then
                            MDrugsDrawText3D(
                                markerCoords.x,markerCoords.y,markerCoords.z + 0.35,
                                "Pressione [~r~E~w~] para preparar a ~g~maconha~w~",
                                {41,11,41,68}
                            )

                            if IsControlJustPressed(0,Config.InteractionControl) then
                                startWeedPreparation(chair)
                                break
                            end
                        end
                    end
                end
            end
        end

        Citizen.Wait(sleep)
    end
end)


AddEventHandler("onResourceStop",function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    deletePreparationVisualBricks()
    deletePreparationHandProp()
end)
