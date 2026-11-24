local cfg = Config.PedRobbery
local event = 'm_robbernpc:pedRobbery:'
local headDict = 'random@arrests@busted'
local giveDict = 'mp_common'
local active
local nextAttempt = 0

local function isCivilian(ped)
    if ped == 0 or not DoesEntityExist(ped) or not IsEntityAPed(ped) then return false end
    if IsPedAPlayer(ped) or not IsPedHuman(ped) or IsEntityDead(ped) then return false end
    if IsPedInAnyVehicle(ped, false) or IsEntityAMissionEntity(ped) then return false end
    local population = GetEntityPopulationType(ped)
    if population < 1 or population > 5 then return false end
    local excluded = Config.NPCDrugSales.ExcludedPedTypes
    return not excluded[GetPedType(ped)] and not Entity(ped).state.robbernpcPedRobbed
end

local function speak(ped, text, duration)
    PlayPedAmbientSpeechNative(ped, 'GENERIC_SHOCKED_HIGH', 'SPEECH_PARAMS_FORCE_SHOUTED')
    BeginTextCommandPrint('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandPrint(duration, true)
end

local function release(robbery, flee, report)
    if active ~= robbery then return end
    active = nil
    nextAttempt = GetGameTimer() + 1500
    local ped = robbery.ped
    if not robbery.controlling or not DoesEntityExist(ped) or not NetworkHasControlOfEntity(ped) then return end
    ClearPedTasks(ped)
    SetBlockingOfNonTemporaryEvents(ped, false)
    if flee and not IsEntityDead(ped) then
        if robbery.handedOver then
            speak(ped, report and 'Socorro! Chamem a polícia!' or 'Socorro! Alguém me ajuda!', 2500)
        end
        TaskSmartFleePed(ped, PlayerPedId(), 100.0, 12000, false, false)
    end
end

local function canContinue(robbery)
    local player = PlayerPedId()
    local ped = robbery.ped
    return active == robbery and DoesEntityExist(ped) and NetworkHasControlOfEntity(ped)
        and not IsEntityDead(player) and not IsEntityDead(ped)
        and IsPedArmed(player, 4) and not IsPedInAnyVehicle(player, false)
        and #(GetEntityCoords(player) - GetEntityCoords(ped)) <= cfg.Distance + 1
end

local function holdAim(robbery, duration)
    local remaining = duration
    local lastCheck = GetGameTimer()
    local lastAim = lastCheck
    while canContinue(robbery) do
        local now = GetGameTimer()
        local hit, target = GetEntityPlayerIsFreeAimingAt(PlayerId())
        if IsPlayerFreeAiming(PlayerId()) and hit and target == robbery.ped then
            remaining = remaining - (now - lastCheck)
            lastAim = now
            if remaining <= 0 then return true end
        elseif now - lastAim > cfg.AimGraceTime then
            return false
        end
        lastCheck = now
        Wait(50)
    end
    return false
end

local function playStage(robbery, dict, animation, flags, duration)
    if not canContinue(robbery) then return false end
    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(robbery.ped, dict, animation, 8.0, -8.0, -1, flags, 0.0, false, false, false)
    end
    return holdAim(robbery, duration)
end

RegisterNetEvent(event .. 'accepted', function(netId, id)
    local robbery = active
    if not robbery or robbery.netId ~= netId or robbery.id then
        TriggerServerEvent(event .. 'cancel', id)
        return
    end
    robbery.id = id
    local ped = robbery.ped
    local deadline = GetGameTimer() + 850
    while active == robbery and DoesEntityExist(ped) and not NetworkHasControlOfEntity(ped)
        and GetGameTimer() < deadline do
        NetworkRequestControlOfEntity(ped)
        Wait(0)
    end
    if not canContinue(robbery) then
        TriggerServerEvent(event .. 'cancel', id)
        release(robbery, false, false)
        return
    end

    robbery.controlling = true
    SetBlockingOfNonTemporaryEvents(ped, true)
    ClearPedTasksImmediately(ped)
    TaskHandsUp(ped, -1, PlayerPedId(), -1, false)
    RequestAnimDict(headDict)
    RequestAnimDict(giveDict)
    speak(ped, 'Não, por favor, não faça isso!', 2800)

    if holdAim(robbery, cfg.HandsUpTime) then
        local firstHalf = math.floor(cfg.HandsOnHeadTime / 2)
        if playStage(robbery, headDict, 'idle_a', 1, firstHalf) then
            speak(ped, 'Por favor, não faça isso...', 2200)
            if not holdAim(robbery, cfg.HandsOnHeadTime - firstHalf) then
                TriggerServerEvent(event .. 'cancel', id)
                release(robbery, true, false)
                return
            end
            StopAnimTask(ped, headDict, 'idle_a', 2.0)
            if holdAim(robbery, cfg.StandUpTime)
                and playStage(robbery, giveDict, 'givetake1_b', 48, cfg.HandOverTime) then
                TriggerServerEvent(event .. 'finish', id)
                return
            end
        end
    end
    TriggerServerEvent(event .. 'cancel', id)
    release(robbery, true, false)
end)

RegisterNetEvent(event .. 'denied', function(netId)
    if active and active.netId == netId and not active.id then release(active, false, false) end
end)

RegisterNetEvent(event .. 'result', function(id, received, report)
    if active and active.id == id then
        active.handedOver = received
        release(active, true, report)
        if not received then TriggerEvent('Notify', 'negado', 'Você não recebeu os pertences do pedestre.', 4000) end
    end
end)

CreateThread(function()
    while true do
        local player = PlayerPedId()
        local aiming = not active and GetGameTimer() >= nextAttempt and not IsEntityDead(player)
            and not IsPedInAnyVehicle(player, false) and IsPedArmed(player, 4)
            and IsPlayerFreeAiming(PlayerId())
        if aiming then
            local hit, ped = GetEntityPlayerIsFreeAimingAt(PlayerId())
            if hit and isCivilian(ped) and #(GetEntityCoords(player) - GetEntityCoords(ped)) <= cfg.Distance then
                if not NetworkGetEntityIsNetworked(ped) then NetworkRegisterEntityAsNetworked(ped) end
                local netId = NetworkGetEntityIsNetworked(ped) and NetworkGetNetworkIdFromEntity(ped)
                if netId and netId > 0 then
                    local robbery = {ped = ped, netId = netId}
                    active = robbery
                    TriggerServerEvent(event .. 'start', netId)
                    SetTimeout(cfg.SessionTimeout + 500, function()
                        if active == robbery then
                            if robbery.id then TriggerServerEvent(event .. 'cancel', robbery.id) end
                            release(robbery, true, false)
                        end
                    end)
                end
            end
        end
        Wait(aiming and 0 or 75)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and active then release(active, true, false) end
end)
