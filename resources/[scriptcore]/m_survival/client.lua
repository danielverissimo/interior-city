local reasonDeath
local pedKiller
local Killer

local cooldown = 0
local morto = false
local deathtimer = LocalPlayer.state.NovatMode and 30 or cfg.deathtimer
local DisableMouse = 0
local mouseActived = false


local cooldownOnClick = GetGameTimer()
local calledStaff = false 
local medicCallRequested = false
local inReviving = false

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- M_EVENTOS / BATTLE ROYALE
-- O Battle Royale possui seu proprio fluxo de eliminacao/espectador.
-- Esta integracao limpa o estado da morte normal do m_survival e garante
-- que o jogador esteja vivo tanto ao entrar no espectador quanto ao sair.
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent('m_survival:forceAliveFromEvent', function(keepInvincible)
    local ped = PlayerPedId()
    if not ped or ped == 0 then return end

    morto = false
    inReviving = false
    mouseActived = false
    calledStaff = false
    deathtimer = cfg.deathtimer
    DisableMouse = 0

    -- Fecha imediatamente qualquer tela/estado visual do coma normal.
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close', deathtimer = deathtimer })
    StopScreenEffect('DeathFailMPIn')
    TriggerEvent('ragdoll:ChangeStatus', false)
    TriggerEvent('m_survival:updateComa', false)

    -- Restaura voz/HUD que o m_survival normalmente desabilita ao morrer.
    TriggerServerEvent('pma-voice:toggleMutePlayer', false)
    TriggerEvent('pma-voice:DesmutePlayer')
    MumbleSetVolumeOverride(PlayerId(), -1.0)
    MumbleSetActive(true)
    TriggerEvent('flaviin:toggleHud', true)

    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    if IsEntityDead(ped) or GetEntityHealth(ped) <= cfg.minHealth then
        NetworkResurrectLocalPlayer(coords.x + 0.0, coords.y + 0.0, coords.z + 0.25, heading + 0.0, true, false)
        ped = PlayerPedId()
    end

    ClearPedTasksImmediately(ped)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    SetEntityHealth(ped, cfg.maxHealth)
    SetPedDiesInWater(ped, true)
    SetPlayerHealthRechargeMultiplier(PlayerId(), 1.0)
    SetPlayerHealthRechargeLimit(PlayerId(), 1.0)

    if keepInvincible == true then
        SetPlayerInvincible(PlayerId(), true)
        SetEntityInvincible(ped, true)
        SetEntityCanBeDamaged(ped, false)
    else
        SetPlayerInvincible(PlayerId(), false)
        SetEntityInvincible(ped, false)
        SetEntityCanBeDamaged(ped, true)
    end
end)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- THREAD
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
        local time = 300
		local ped = PlayerPedId()
		local vida = GetEntityHealth(ped)
		local x,y,z = table.unpack(GetEntityCoords(ped,true))

        if cfg.dependencys() then
            if IsEntityDead(ped) then
                time = 0
                if GetPedCauseOfDeath(ped) ~= 0 and cooldown == 0 then
                    cooldown = cfg.cooldown

                    reasonDeath = GetPedCauseOfDeath(ped)
                    pedKiller = GetPedSourceOfDeath(ped)

                    if IsEntityAPed(pedKiller) and IsPedAPlayer(pedKiller) then
                        Killer = NetworkGetPlayerIndexFromPed(pedKiller)
                    elseif IsEntityAVehicle(pedKiller) and IsEntityAPed(GetPedInVehicleSeat(pedKiller, -1)) and IsPedAPlayer(GetPedInVehicleSeat(pedKiller, -1)) then
                        Killer = NetworkGetPlayerIndexFromPed(GetPedInVehicleSeat(pedKiller, -1))
                    end
                    
                    sendToLog(PlayerId(), reasonDeath, Killer)
                end 

                if not morto then
                    -- ############# ALTERAÇÃO AQUI #############
                    -- Lógica para definir o tempo de morte
                    local weaponDeathTime = cfg.deathTimesByWeapon[reasonDeath]

                    if weaponDeathTime then
                        -- Se houver um tempo customizado para a arma que matou, use-o
                        deathtimer = weaponDeathTime
                    else
                        -- Caso contrário, usa a lógica antiga (VIP/Padrão)
                        deathtimer = LocalPlayer.state.NovatMode and 30 or cfg.deathtimer
                        
                        local newSeconds = vSERVER.secoundsDeath()
                        if newSeconds then
                            deathtimer = newSeconds
                        end
                    end
                    -- ############# FIM DA ALTERAÇÃO #############
                end


                NetworkResurrectLocalPlayer(x,y,z,true,true, false)
                SetEntityInvincible(ped,true)
                SetPedDiesInWater(ped, false)
                SetEntityHealth(ped, cfg.minHealth)
            end

            if vida <= cfg.minHealth and not morto then
                if not LocalPlayer.state.isSpawnActived then
                    morto = true
                    medicCallRequested = false
                    mouseActived = false 
                    SetNuiFocus(true,true)
                    TriggerEvent('dynamic:closeSystem2',source)
                    TriggerEvent("ragdoll:ChangeStatus", morto)
                    print("Atualizou vida para: "..cfg.minHealth)
                    SetEntityHealth(ped, cfg.minHealth)
                    vRPserver.updateHealth(cfg.minHealth)
                    ExecuteCommand("e morrer")
                    TriggerEvent('m_survival:updateComa', morto)
                    TriggerServerEvent('pma-voice:toggleMutePlayer', true)
                    SetCurrentPedWeapon(ped,GetHashKey("WEAPON_UNARMED"),true)
                    TriggerEvent("pma-voice:MutePlayer")
                    MumbleSetVolumeOverride(PlayerId(),0.0)
                    MumbleSetActive(false)

                    exports["pma-voice"]:removePlayerFromRadio()
                    exports["pma-voice"]:setVoiceProperty('radioEnabled',false)
                    TriggerEvent("lotus-hud:leaveFrequency", 0)
                    TriggerEvent('flaviin:toggleHud', false)
                else
                    Wait(4000)
                end
            end

            if morto then
                if vida <= cfg.minHealth and not inReviving then
                    time = 5
                    cfg.animDeath()

                    DisableControlAction(0,199,true)
                    DisableControlAction(0,200,true)
                    SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
                    SetPlayerHealthRechargeLimit(PlayerId(), 0.0)
                    if cfg.versionNUI then
                        openNui()

                        -- A tela de coma agora possui botão clicável para chamar médico.
                        -- Mantém o foco da NUI durante todo o coma, respeitando o bloqueio
                        -- temporário já usado pelo próprio survival.
                        if DisableMouse <= 0 then
                            if not mouseActived then
                                SetNuiFocus(true, true)
                                mouseActived = true
                            end
                        elseif mouseActived then
                            mouseActived = false
                            SetNuiFocus(false, false)
                        end

                        if deathtimer <= 0 and not cfg.timedown then
                            -- Os botões de respawn continuam sendo controlados pela NUI.
                        end
                    else
                        cfg.drawtext(deathtimer)
                    end

                end

                if vida > cfg.minHealth then
                    vSERVER.cancelMedicCall()
                    medicCallRequested = false
                    morto = false
                    TriggerEvent("ragdoll:ChangeStatus", morto)
                    deathtimer =  cfg.deathtimer
                    SetEntityInvincible(ped,false)
                    SetPedDiesInWater(ped, true)
                    TriggerEvent('m_survival:updateComa', morto)
                    StopScreenEffect("DeathFailMPIn")
                    vRPserver.updateHealth(GetEntityHealth(ped))
                    TriggerServerEvent('pma-voice:toggleMutePlayer', false)
                    TriggerEvent("pma-voice:DesmutePlayer")
                    MumbleSetVolumeOverride(PlayerId(),-1.0)
                    MumbleSetActive(true)
                    ClearPedTasksImmediately(ped)
                    calledStaff = false
                    SetPlayerHealthRechargeMultiplier(PlayerId(), 1.0)
                    SetPlayerHealthRechargeLimit(PlayerId(), 1.0)
                    if cfg.versionNUI then  ---- AQUIKRLHO
                        closeNui()
                        TriggerEvent('flaviin:toggleHud', true)
                    end
                end

                if not IsEntityAttached(PlayerPedId()) then
                    if deathtimer <= 0 then
                        if cfg.timedown then
                            morrer()
                        end
                    end
                end
            end
        end

        Citizen.Wait(time)
	end
end)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FUNCTION
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sendToLog = function(idMorto, motivoMorto, quemMatou)
    local source = 0
    local ksource = 0
    local motivo = ""

    if idMorto ~= 0 then
        source = GetPlayerServerId(idMorto)
    end

    if quemMatou ~= 0 then
        ksource = GetPlayerServerId(quemMatou)
    end
    
    if cfg.reasons[motivoMorto] then
        motivo = cfg.reasons[motivoMorto]
    else
        motivo= cfg.reasons[0]
    end

    vSERVER.receberMorte(source, motivo, ksource)
end

src.getPosition = function()
    return GetEntityCoords(PlayerPedId(),true)
end

src.setFinalizado = function()  
    deathtimer = 0
end

morrer = function()
    Citizen.Wait(500)
    vSERVER.cancelMedicCall()
    medicCallRequested = false
    calledStaff = false
    morto = false
    TriggerEvent("ragdoll:ChangeStatus", morto)

    deathtimer = cfg.deathtimer

    StopScreenEffect("DeathFailMPIn")
    if cfg.versionNUI then
        closeNui()
    end

    TriggerEvent('m_survival:updateComa', morto)
    TriggerServerEvent('pma-voice:toggleMutePlayer', false)

    MumbleSetVolumeOverride(PlayerId(),-1.0)
    MumbleSetActive(true)

    DoScreenFadeOut(500)

    Citizen.Wait(2000)
    SetEntityInvincible(PlayerPedId(),false)
    SetPedDiesInWater(PlayerPedId(), true)
    ClearPedBloodDamage(PlayerPedId())

    Citizen.Wait(200)
    -- SetEntityCoords(PlayerPedId(), cfg.respawn)
    if not LocalPlayer.state.NovatMode then
        cfg.clearAccount()
    end

    Citizen.Wait(3000)
    SetEntityHealth(PlayerPedId(), cfg.maxHealth)
    ClearPedTasks(PlayerPedId())
    
    Citizen.Wait(4000)
    DoScreenFadeIn(1000)
    -- TriggerEvent('flaviin:toggleHud', true)
end

src.morrer2 = function()
    if IsEntityAttached(PlayerPedId()) then
        return false
    end
    vSERVER.cancelMedicCall()
    medicCallRequested = false
    calledStaff = false
    morto = false
    TriggerEvent("ragdoll:ChangeStatus", morto)

    deathtimer =  cfg.deathtimer

    StopScreenEffect("DeathFailMPIn")
    if cfg.versionNUI then
        closeNui()
    end

    TriggerEvent('m_survival:updateComa', morto)
    TriggerServerEvent('pma-voice:toggleMutePlayer', false)

    MumbleSetVolumeOverride(PlayerId(),-1.0)
    MumbleSetActive(true)
    DoScreenFadeOut(500)

    Citizen.Wait(2000)
    SetPedDiesInWater(PlayerPedId(), true)
    ClearPedBloodDamage(PlayerPedId())

    Citizen.Wait(3000)
    SetEntityCoords(PlayerPedId(), cfg.respawn)
    if not LocalPlayer.state.NovatMode then
        cfg.clearAccount()
    end

    Citizen.Wait(500)
    SetEntityHealth(PlayerPedId(), cfg.maxHealth)
    ClearPedTasks(PlayerPedId())
    
    TriggerServerEvent('pma-voice:toggleMutePlayer', false)
    
    Citizen.Wait(4000)
    DoScreenFadeIn(1000)
end

RegisterNetEvent("m_survival:updateComa")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- NUI
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
openNui = function()
    SendNUIMessage({ action = 'open', deathtimer = deathtimer, medicCalled = medicCallRequested })
end

closeNui = function()
    mouseActived = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close', deathtimer = deathtimer })
end

RegisterNuiCallback('spawn', function(data)
    if deathtimer <= 0 then
        
        if not cfg.timedown then
            if exports['vrp_policia']:getArrest() == true then 
                TriggerEvent("Notify",'negado','Você não pode reviver sendo arrestado.')
            elseif IsEntityAttached(PlayerPedId()) then
                TriggerEvent("Notify",'negado','Você não pode reviver enquanto está carregando.')
            else
                inReviving = true
                StopScreenEffect("DeathFailMPIn")
                if data.name == 'north' then
                    vRP.teleport(-234.11,6313.94,31.48)
                elseif data.name == 'south' then
                    vRP.teleport(-1676.82,-221.88,55.33)
                end
                morrer()
                inReviving = false
            end
        end
    end
end)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CHAMADO MÉDICO
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("callMedic", function(data, cb)
    if medicCallRequested then
        cb({ ok = false, message = "O chamado médico já foi enviado." })
        return
    end

    local response = vSERVER.requestMedicCall()
    if type(response) ~= "table" then
        response = { ok = false, message = "Não foi possível enviar o chamado médico." }
    end

    if response.ok then
        medicCallRequested = true
    end

    cb(response)
end) 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CALL STAFF
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("callStaff",function(data,cb)
    if calledStaff then return end 

    TriggerServerEvent("hub:sendCall2",true)

    calledStaff = true 

    cb(true)
end)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONTADOR
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        local time = 1000
        
        if cooldown > 0 then
            cooldown = cooldown - 1

            if cooldown <= 0 then
                cooldown = 0
            end
        end

        if DisableMouse >= 0 then 
            DisableMouse = DisableMouse - 1 
            if DisableMouse <= 0 then 
                DisableMouse = 0 
            end
        end

        if morto then
            deathtimer = deathtimer - 1

            if deathtimer <= 0 then
                deathtimer = 0
            end
        end

        Citizen.Wait(time)
    end
end)

RegisterNetEvent("Survival:DisableFocus",function()
    DisableMouse = 30
end)

local isNotifyActive = false
RegisterNetEvent('hub:notify', function(id, distance)
    isNotifyActive = true
    SendNUIMessage({ action = 'notify', id = id, distance = distance })

    CreateThread(function()
        local distanceString = vSERVER.getDistance(id)
        
        local distanceNumber = 0
        if distanceString then
            distanceString = distanceString:gsub('m', ''):gsub(',', '.')
            distanceNumber = tonumber(distanceString) or 0
        end
        
        while distanceNumber and distanceNumber > 5.0 and isNotifyActive do
            Wait(5000)
            distanceString = vSERVER.getDistance(id)

            if distanceString then
                distanceString = distanceString:gsub('m', ''):gsub(',', '.')
                distanceNumber = tonumber(distanceString) or 0
            else
                distanceNumber = 0
            end

            SendNUIMessage({ action = 'notify', id = id, distance = distanceString or '0m' })
        end
        isNotifyActive = false
        SendNUIMessage({ action = 'notify:close' })
    end)
end)

RegisterNetEvent('close:callhud', function()
    if isNotifyActive then
        isNotifyActive = false
    end
end)


RegisterCommand("vida", function(_, args, rawCommand)
    local ped = PlayerPedId()
	local vida = GetEntityHealth(ped)
    print('vida:'..vida)
end)