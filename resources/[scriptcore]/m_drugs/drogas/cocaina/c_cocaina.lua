local cfg = Config.Drugs.cocaina

local acido = false
local acidoobj = false
local panela = false
local panelaobj = false
local colocandoPanela = false
local misturar = false

local acidPlacedReady = false
local mixingAcid = false
local acidMixFinishAt = 0

local pasteBaseState = "idle"
local pasteBaseFinishAt = 0

local acidoobj1, panelacoca, espatula, balanca1, cocaina
local cocaineCarryObject = nil

-- Anexa diretamente ao ped para que rx/ry/rz da config sejam respeitados.
local function attachCocaineCarry(data)
    if not data or not data.model then return end

    if cocaineCarryObject and DoesEntityExist(cocaineCarryObject) then
        DeleteEntity(cocaineCarryObject)
        cocaineCarryObject = nil
    end

    local ped = PlayerPedId()
    local hash = type(data.model) == "number" and data.model or GetHashKey(data.model)

    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Citizen.Wait(10)
    end

    cocaineCarryObject = CreateObjectNoOffset(
        hash,
        GetEntityCoords(ped),
        true,
        true,
        false
    )

    SetEntityCollision(cocaineCarryObject,false,false)

    AttachEntityToEntity(
        cocaineCarryObject,
        ped,
        GetPedBoneIndex(ped,data.bone or 28422),
        data.x or 0.0,
        data.y or 0.0,
        data.z or 0.0,
        data.rx or 0.0,
        data.ry or 0.0,
        data.rz or 0.0,
        true,
        true,
        false,
        true,
        1,
        true
    )

    SetModelAsNoLongerNeeded(hash)
end

local function deleteCocaineCarry()
    if cocaineCarryObject and DoesEntityExist(cocaineCarryObject) then
        DetachEntity(cocaineCarryObject,true,true)
        DeleteEntity(cocaineCarryObject)
    end

    cocaineCarryObject = nil
end

local function formatCocaineTimer(ms)
    local total = math.max(0,math.ceil((tonumber(ms) or 0) / 1000))
    local minutes = math.floor(total / 60)
    local seconds = total % 60
    return string.format("%02d:%02d",minutes,seconds)
end

Citizen.CreateThread(function()
    while true do
        local sleep = 1000

        -- PASTA BASE
        local pastePoint = cfg.locations.producePasteBase
        if pastePoint and MDrugsDistance(pastePoint) <= 2.0 then
            sleep = 1

            if pasteBaseState == "processing" and GetGameTimer() >= pasteBaseFinishAt then
                pasteBaseState = "ready"
            end

            if pasteBaseState == "idle" then
                MDrugsDrawText3D(
                    pastePoint.x,pastePoint.y,pastePoint.z,
                    "Pressione [~g~E~w~] para produzir pasta base"
                )

                if IsControlJustPressed(0,Config.InteractionControl) then
                    if MDrugs.startCocainePasteBase() then
                        pasteBaseState = "processing"
                        pasteBaseFinishAt = GetGameTimer() + (cfg.pasteBase.duration or 60000)

                        SetEntityHeading(PlayerPedId(),pastePoint.heading or 0.0)
                        vRP._playAnim(false,{{"mp_common","givetake1_a"}},false)
                        MDrugsLockAction(1500)

                        SetTimeout(1500,function()
                            vRP._stopAnim(false)
                        end)
                    end
                end

            elseif pasteBaseState == "processing" then
                local remaining = math.max(0,pasteBaseFinishAt - GetGameTimer())

                MDrugsDrawText3D(
                    pastePoint.x,pastePoint.y,pastePoint.z,
                    "Aguarde ~g~"..formatCocaineTimer(remaining).."~w~ para que a pastabase fique pronta."
                )

            elseif pasteBaseState == "ready" then
                MDrugsDrawText3D(
                    pastePoint.x,pastePoint.y,pastePoint.z,
                    "Pressione [~g~E~w~] para coletar a pasta base"
                )

                if IsControlJustPressed(0,Config.InteractionControl) then
                    if MDrugs.finishCocainePasteBase() then
                        pasteBaseState = "idle"
                        pasteBaseFinishAt = 0
                    end
                end
            end
        end

        -- SEPARAÇÃO DO ÁCIDO
        if MDrugsDistance(cfg.locations.collectAcid) <= 2.0 and not acido then
            sleep = 1
            local c = cfg.locations.collectAcid
            MDrugsDrawText3D(c.x,c.y,c.z,"Pressione [~g~E~w~] para separar o acido")

            if IsControlJustPressed(0,Config.InteractionControl) and MDrugs.checkPermission("cocaina") then
                if MDrugs.separateCocaineAcid() then
                    acido = true
                    MDrugsSetPed(c.action)
                    vRP._playAnim(false,{{"amb@medic@standing@tendtodead@idle_a","idle_a"}},true)
                    MDrugsLockAction(2500)

                    SetTimeout(2500,function()
                        TriggerEvent("Notify","sucesso","Você separou o <b>Ácido</b>.")
                        vRP._stopAnim(false)

                        local carry = cfg.carry.acid
                        vRP._playAnim(true,{{"anim@heists@box_carry@","idle"}},true)
                        attachCocaineCarry(carry)
                    end)
                end
            end
        end

        -- COLOCAR ÁCIDO NA NOVA MESA
        if MDrugsDistance(cfg.locations.placeAcid) <= 2.0 and acido and not acidoobj then
            sleep = 1
            local c = cfg.locations.placeAcid
            MDrugsDrawText3D(c.x,c.y,c.z,"[~g~E~w~] Para colocar o ~g~Ácido~w~ na mesa.")

            if IsControlJustPressed(0,Config.InteractionControl) then
                acidoobj = true

                MDrugsSetPed(c.action)
                vRP._playAnim(false,{{"mp_common","givetake1_a"}},false)
                MDrugsLockAction(1500)
                deleteCocaineCarry()

                SetTimeout(1500,function()
                    if not (acidoobj1 and DoesEntityExist(acidoobj1)) then
                        acidoobj1 = MDrugsCreateObject(cfg.props.acidPlaced)
                    end
                    acidPlacedReady = true
                end)
            end
        end

        -- JUNTAR ÁCIDO COM A PASTA BASE
        -- IMPORTANTE:
        -- depois que a mistura começa, ela continua existindo mesmo que o frasco
        -- saia da mesa/mão. O timer depende de mixingAcid, não de acidPlacedReady.
        if cfg.locations.mixAcidPasteBase and MDrugsDistance(cfg.locations.mixAcidPasteBase) <= 2.0 then
            sleep = 1
            local c = cfg.locations.mixAcidPasteBase

            if not mixingAcid then
                if acidPlacedReady then
                    MDrugsDrawText3D(
                        c.x,c.y,c.z,
                        "Pressione [~g~E~w~] para juntar o acido com a pasta base"
                    )

                    if IsControlJustPressed(0,Config.InteractionControl) then
                        if MDrugs.startCocainePowderStage() then
                            mixingAcid = true
                            acidMixFinishAt = GetGameTimer() + ((cfg.cocainePowderStage and cfg.cocainePowderStage.duration) or 30000)

                            SetEntityHeading(PlayerPedId(),c.heading or 0.0)

                            -- O ácido sai da mesa e vai para a mão.
                            MDrugsDeleteObject(acidoobj1)
                            acidoobj1 = nil
                            acidPlacedReady = false

                            local carry = cfg.pour.acid
                            attachCocaineCarry(carry)

                            -- Mantém uma animação contínua de despejo durante todo pourTime.
                            local dict = "weapon@w_sp_jerrycan"
                            local anim = "fire"
                            local pourTime = (cfg.cocainePowderStage and cfg.cocainePowderStage.pourAnimationDuration) or 8000

                            RequestAnimDict(dict)
                            while not HasAnimDictLoaded(dict) do
                                Citizen.Wait(10)
                            end

                            TaskPlayAnim(
                                PlayerPedId(),
                                dict,
                                anim,
                                8.0,
                                -8.0,
                                -1,
                                49,
                                0.0,
                                false,
                                false,
                                false
                            )

                            -- Trava apenas enquanto está despejando.
                            MDrugsLockAction(pourTime)

                            SetTimeout(pourTime,function()
                                deleteCocaineCarry()
                                ClearPedTasks(PlayerPedId())

                                -- A mistura NÃO é resetada aqui.
                                -- mixingAcid continua true e o timer segue até os 30s.
                                acido = false
                                acidoobj = false
                            end)
                        end
                    end
                end
            else
                local remaining = math.max(0,acidMixFinishAt - GetGameTimer())

                if remaining > 0 then
                    MDrugsDrawText3D(
                        c.x,c.y,c.z,
                        "Aguarde ~g~"..formatCocaineTimer(remaining).."~w~ para que o pó de cocaina fique pronto."
                    )
                else
                    MDrugsDrawText3D(
                        c.x,c.y,c.z,
                        "Pressione [~g~E~w~] para coletar o pó de cocaina"
                    )

                    if IsControlJustPressed(0,Config.InteractionControl) then
                        if MDrugs.finishCocainePowderStage() then
                            mixingAcid = false
                            acidMixFinishAt = 0
                        end
                    end
                end
            end
        end

        -- PEGAR PANELA: APARECE DESDE O COMEÇO, MAS EXIGE 10x podecocaina
        if MDrugsDistance(cfg.locations.takePan) <= 2.0 and not panela then
            sleep = 1
            local c = cfg.locations.takePan
            MDrugsDrawText3D(c.x,c.y,c.z,"[~g~E~w~] Para pegar a ~g~Panela de Cocaína~w~.")
            if IsControlJustPressed(0,Config.InteractionControl) then
                if not MDrugs.consumeCocainePowderForPan() then
                    Citizen.Wait(250)
                else
                    panela = true
                    MDrugsSetPed(c.action)
                vRP._playAnim(false,{{"amb@medic@standing@tendtodead@idle_a","idle_a"}},true)
                MDrugsLockAction(5000)
                TriggerEvent("Notify","sucesso","Você pegou a <b>Panela de Cocaína</b>.")
                SetTimeout(5000,function()
                    local carry = cfg.carry.pan
                    vRP._stopAnim(false)
                    vRP._playAnim(true,{{"anim@heists@box_carry@","idle"}},true)
                    attachCocaineCarry(carry)
                end)
                end
            end
        end

        if MDrugsDistance(cfg.locations.placePan) <= 2.0 and panela and not panelaobj and not colocandoPanela then
            sleep = 1
            local c = cfg.locations.placePan
            MDrugsDrawText3D(c.x,c.y,c.z,"[~g~E~w~] Para colocar a ~g~Panela de Cocaína~w~.")

            if IsControlJustPressed(0,Config.InteractionControl) then
                -- Estado intermediário: bloqueia spam de E sem liberar ainda
                -- a próxima etapa (pesar).
                colocandoPanela = true

                SetEntityHeading(PlayerPedId(),c.heading)
                vRP._playAnim(false,{{"mp_common","givetake1_a"}},false)
                MDrugsLockAction(1500)
                deleteCocaineCarry()

                SetTimeout(1500,function()
                    if not (panelacoca and DoesEntityExist(panelacoca)) then
                        panelacoca = MDrugsCreateObject(cfg.props.panPlaced)
                    end

                    -- Só AGORA a etapa "pesar" é liberada.
                    panelaobj = true
                    colocandoPanela = false
                end)
            end
        end

        if MDrugsDistance(cfg.locations.weigh) <= 2.0 and panelaobj and not misturar then
            sleep = 1
            local c = cfg.locations.weigh
            MDrugsDrawText3D(c.x,c.y,c.z,"[~g~E~w~] Para pesar a ~g~Cocaína~w~.")
            if IsControlJustPressed(0,Config.InteractionControl) then
                misturar = true
                MDrugsSetPed(c)
                TriggerEvent("progress",20,"PESANDO A COCAÍNA")
                vRP._playAnim(false,{{"anim@amb@business@coc@coc_packing_hi@","full_cycle_v3_pressoperator"}},true)
                MDrugsLockAction(20300)
                espatula = MDrugsCreateObject(cfg.props.spatulaTemp)

                SetTimeout(2500,function()
                    vRP._CarregarObjeto("","","bkr_prop_coke_scale_01",50,28422,0.0,0.0,-0.1,0.0,0.0,0.0)
                end)
                SetTimeout(5000,function()
                    vRP._DeletarObjeto()
                    balanca1 = MDrugsCreateObject(cfg.props.scalePlaced)
                end)
                SetTimeout(7500,function()
                    MDrugsDeleteObject(espatula)

                    local carry = cfg.carry.spatula
                    attachCocaineCarry(carry)
                end)
                SetTimeout(15000,function()
                    cocaina = MDrugsCreateObject(cfg.props.powderPlaced)
                end)
                SetTimeout(20000,function()
                    deleteCocaineCarry()
                    vRP._DeletarObjeto()
                end)
                SetTimeout(20300,function()
                    vRP._stopAnim(false)
                    MDrugsDeleteObjects({balanca1,cocaina,panelacoca,acidoobj1})
                    MDrugs.finishProduction("cocaina")
                    acido,acidoobj,panela,panelaobj,colocandoPanela,misturar = false,false,false,false,false,false
                end)
            end
        end

        Citizen.Wait(sleep)
    end
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1000

        -- Enquanto estiver carregando o ácido OU a panela até o ponto de colocação:
        -- pode andar, mas não pode correr/sprintar nem pular.
        local carryingAcid = acido and not acidoobj
        local carryingPan = panela and not panelaobj and not colocandoPanela

        if carryingAcid or carryingPan then
            sleep = 5
            DisableControlAction(0,21,true) -- SHIFT / correr
            DisableControlAction(0,22,true) -- ESPAÇO / pular
        end

        Citizen.Wait(sleep)
    end
end)

AddEventHandler("onResourceStop",function(resource)
    if resource == GetCurrentResourceName() then
        deleteCocaineCarry()
    end
end)
