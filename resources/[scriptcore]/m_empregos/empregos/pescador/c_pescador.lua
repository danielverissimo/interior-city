-- Pescador - client
-- Fluxo: inicia expediente -> aguarda fisgada -> minigame -> recompensa validada no servidor.

local inpesca = false
local fishingMinigame = false
local requestingChallenge = false
local resolvingFishingChallenge = false
local segundos = 0
local nextFishAt = 0
local currentFishingToken = nil

configpesca = configpesca or {}
configpesca.fishDuration = 3
configpesca.locais = {
    { 1109.33, -637.33, 56.82, 105.18 },
    { 1108.88, -635.27, 56.82, 107.12 },
    { 1108.44, -633.04, 56.82, 103.16 },
    { 1107.97, -630.56, 56.82, 108.75 }
}
configpesca.venda = { 1112.09, -645.37, 56.85 }

local function applyFishingConfig()
    local e = cfg.extra and cfg.extra["Pescador"] or {}

    local duration = tonumber(e.duracao_pesca)
    if duration and duration >= 1 then
        configpesca.fishDuration = duration
    end

    if type(e.locais_pesca) == "table" and #e.locais_pesca > 0 then
        configpesca.locais = e.locais_pesca
    end

    if type(e.local_venda) == "table" and #e.local_venda >= 3 then
        configpesca.venda = e.local_venda
    end
end

local function cleanupFishingRod()
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    Wait(0)

    local coords = GetEntityCoords(ped)
    local obj = GetClosestObjectOfType(
        coords.x, coords.y, coords.z,
        2.5,
        GetHashKey("prop_fishing_rod_01"),
        false, false, false
    )

    if DoesEntityExist(obj) then
        NetworkRequestControlOfEntity(obj)
        local timeout = GetGameTimer() + 500
        while not NetworkHasControlOfEntity(obj) and GetGameTimer() < timeout do
            Wait(0)
            NetworkRequestControlOfEntity(obj)
        end
        SetEntityAsMissionEntity(obj, true, true)
        DeleteEntity(obj)
    end
end

local function scheduleNextFish()
    nextFishAt = GetGameTimer() + (math.floor(tonumber(configpesca.fishDuration) or 10) * 1000)
    segundos = math.max(1, math.ceil((nextFishAt - GetGameTimer()) / 1000))
end

local function closeFishingNui()
    fishingMinigame = false
    resolvingFishingChallenge = false
    currentFishingToken = nil
    SetNuiFocus(false,false)
    SendNUIMessage({ hideFishing = true })
end

local function stopFishingService(showNotify)
    if currentFishingToken then
        vSERVER.cancelFishingChallenge(currentFishingToken)
    end

    closeFishingNui()
    requestingChallenge = false
    resolvingFishingChallenge = false

    if inpesca then
        MageJobsEndService("Pescador")
    end

    inpesca = false
    segundos = 0
    nextFishAt = 0
    cleanupFishingRod()

    if showNotify then
        TriggerEvent("Notify", "aviso", "Você saiu de serviço! Venda seus peixes ao lado.", 5000)
    end
end

local function noIsca()
    closeFishingNui()
    requestingChallenge = false
    resolvingFishingChallenge = false
    inpesca = false
    segundos = 0
    nextFishAt = 0
    MageJobsEndService("Pescador")
    cleanupFishingRod()
end

local function startFishingMinigame()
    if not inpesca or fishingMinigame or requestingChallenge or resolvingFishingChallenge then return end
    requestingChallenge = true

    local result = vSERVER.startFishingChallenge()
    requestingChallenge = false

    if not inpesca then return end

    if not result or result.ok ~= true or type(result.challenge) ~= "table" then
        if result and result.reason == "no_bait" then
            noIsca()
        else
            TriggerEvent("Notify","negado","Não foi possível iniciar esta tentativa de pesca.",5000)
            scheduleNextFish()
        end
        return
    end

    currentFishingToken = result.challenge.token
    fishingMinigame = true
    SetNuiFocus(true,true)
    SendNUIMessage({
        showFishing = true,
        challenge = result.challenge
    })
end

local function beginFishingAtSpot(spot)
    if inpesca then return end
    if not vSERVER.hasFishingBait() then return end
    if not MageJobsBeginService("Pescador") then return end

    local ped = PlayerPedId()
    SetEntityCoords(ped, spot[1], spot[2], spot[3] - 1.0)
    SetEntityHeading(ped, spot[4] or GetEntityHeading(ped))
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_FISHING", 0, true)

    inpesca = true
    scheduleNextFish()
end

-- Venda dos peixes.
Citizen.CreateThread(function()
    while true do
        local idle = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local venda = configpesca.venda
        local distance = #(coords - vec3(venda[1],venda[2],venda[3]))

        if distance <= 10.0 and not inpesca then
            idle = 1
            DrawMarker(27,venda[1],venda[2],venda[3]-0.95,0,0,0,0,0,0,1.5,1.5,1.5,132,102,226,180,0,0,0,1)
            if distance <= 3.0 then
                DrawText3D(venda[1],venda[2],venda[3], "PRESSIONE  ~b~E~w~  PARA ~g~VENDER~w~ SEUS ~b~PEIXES")
                if distance <= 1.2 and IsControlJustPressed(0,38) and vSERVER.checkEmp('Pescador') then
                    vSERVER.sellFish()
                end
            end
        end

        Citizen.Wait(idle)
    end
end)

-- Pontos para iniciar o expediente.
Citizen.CreateThread(function()
    while true do
        local idle = 1000

        if not inpesca then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            for _,spot in ipairs(configpesca.locais) do
                local distance = #(coords - vec3(spot[1],spot[2],spot[3]))
                if distance <= 10.0 then
                    idle = 1
                    DrawMarker(27,spot[1],spot[2],spot[3]-0.95,0,0,0,0,0,0,1.5,1.5,1.5,132,102,226,180,0,0,0,1)
                    if distance <= 3.0 then
                        DrawText3D(spot[1],spot[2],spot[3], "PRESSIONE  ~b~E~w~  PARA ~y~PESCAR ~b~( REQ.: 1x ISCA )")
                        if IsControlJustPressed(0,38) and not IsPedInAnyVehicle(ped) and vSERVER.checkEmp('Pescador') then
                            beginFishingAtSpot(spot)
                        end
                    end
                end
            end
        end

        Citizen.Wait(idle)
    end
end)

-- Espera entre uma fisgada e outra. O minigame substitui o taskbar antigo.
Citizen.CreateThread(function()
    while true do
        local idle = 500

        if inpesca then
            idle = 0

            if not fishingMinigame and not requestingChallenge and not resolvingFishingChallenge then
                local remaining = nextFishAt - GetGameTimer()
                segundos = math.max(0, math.ceil(remaining / 1000))

                if remaining <= 0 then
                    startFishingMinigame()
                end
            end

            if not fishingMinigame then
                drawTxtPC("~y~Próximo peixe em: ~r~"..segundos.." ~w~ Fique atento!",4,0.251,0.865,0.45,255,255,255,200)
                drawTxtPC("~y~PRESSIONE ~r~F6 ~w~SE DESEJA FINALIZAR A PESCARIA",4,0.270,0.905,0.45,255,255,255,200)

                if IsControlJustPressed(0,167) then
                    stopFishingService(true)
                end
            end
        end

        Citizen.Wait(idle)
    end
end)

RegisterNUICallback("fishingResult", function(data, cb)
    -- Enquanto o servidor valida esta tentativa, mantemos o estado bloqueado.
    -- Isso impede a thread principal de iniciar/reabrir outra fisgada no mesmo frame.
    if not fishingMinigame or resolvingFishingChallenge then
        cb({ ok = false })
        return
    end

    resolvingFishingChallenge = true

    local token = currentFishingToken
    local success = data and data.success == true
    local elapsedMs = data and tonumber(data.elapsedMs) or 0

    -- O NUI já encerrou visualmente esta rodada, mas para a lógica Lua ela continua
    -- ativa até o servidor consumir o token e devolver o resultado definitivo.
    SetNuiFocus(false,false)
    SendNUIMessage({ hideFishing = true })

    local result = vSERVER.finishFishingChallenge(token, success, elapsedMs)

    -- Só agora liberamos uma nova tentativa.
    fishingMinigame = false
    currentFishingToken = nil

    if result and result.caught then
        PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    elseif result and result.escaped then
        PlaySoundFrontend(-1, "CHALLENGE_UNLOCKED", "HUD_AWARDS", true)
        TriggerEvent("Notify","negado","Você deixou o peixe escapar! Tente novamente.",5000)
    elseif result and result.inventoryFull then
        PlaySoundFrontend(-1, "ERROR", "HUD_AMMO_SHOP_SOUNDSET", true)
    elseif not result or result.ok ~= true then
        TriggerEvent("Notify","negado","Esta tentativa de pesca não pôde ser validada.",5000)
    end

    if inpesca then
        scheduleNextFish()
    end

    resolvingFishingChallenge = false
    cb({ ok = true })
end)

RegisterNUICallback("fishingQuitService", function(data, cb)
    stopFishingService(true)
    cb({ ok = true })
end)

RegisterNUICallback("fishingCancel", function(data, cb)
    if fishingMinigame and not resolvingFishingChallenge then
        resolvingFishingChallenge = true

        local token = currentFishingToken
        SetNuiFocus(false,false)
        SendNUIMessage({ hideFishing = true })

        -- Consome a sessão no servidor antes de permitir que a próxima tentativa comece.
        vSERVER.finishFishingChallenge(token, false, data and tonumber(data.elapsedMs) or 0)

        fishingMinigame = false
        currentFishingToken = nil
        TriggerEvent("Notify","negado","Você deixou o peixe escapar! Tente novamente.",5000)

        if inpesca then
            scheduleNextFish()
        end

        resolvingFishingChallenge = false
    end
    cb({ ok = true })
end)

AddEventHandler("m_empregos:clientConfigUpdated", function()
    applyFishingConfig()
end)

Citizen.CreateThread(function()
    Citizen.Wait(800)
    applyFishingConfig()
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if fishingMinigame then
        SetNuiFocus(false,false)
    end
end)

function drawTxtPC(text,font,x,y,scale,r,g,b,a)
    SetTextFont(font)
    SetTextScale(scale,scale)
    SetTextColour(r,g,b,a)
    SetTextOutline()
    SetTextCentre(1)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x,y)
end
