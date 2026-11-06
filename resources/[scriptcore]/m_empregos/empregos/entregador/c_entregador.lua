-- Entregador - cliente
-- Ciclo contínuo: inicia com lanches -> entrega -> coleta -> entrega ... até F6.

local inService = false
local currentStage = nil
local currentTarget = nil
local currentBatch = nil
local packageObject = nil
local packageHidden = false
local routeBlip = nil
local startBlip = nil
local actionBusy = false

local function extraConfig()
    return (cfg.extra and cfg.extra["Entregador"]) or {}
end

local function serviceVehicleModel()
    return tostring(extraConfig().veiculo or "cg160")
end

local function removeRouteBlip()
    if routeBlip and DoesBlipExist(routeBlip) then
        RemoveBlip(routeBlip)
    end
    routeBlip = nil
end

local function createStartBlip()
    if startBlip and DoesBlipExist(startBlip) then RemoveBlip(startBlip) end
    startBlip = nil

    local start = cfg.list["Entregador"] and cfg.list["Entregador"].inicio
    if not start then return end

    startBlip = AddBlipForCoord(start[1] + 0.0, start[2] + 0.0, start[3] + 0.0)
    SetBlipSprite(startBlip, 494)
    SetBlipColour(startBlip, 1)
    SetBlipScale(startBlip, 0.6)
    SetBlipAsShortRange(startBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Central | Entregador")
    EndTextCommandSetBlipName(startBlip)
end

local function setRouteBlip(target, stage)
    removeRouteBlip()
    if not target then return end

    routeBlip = AddBlipForCoord(target.x + 0.0, target.y + 0.0, target.z + 0.0)
    SetBlipSprite(routeBlip, stage == "pickup" and 478 or 501)
    SetBlipColour(routeBlip, stage == "pickup" and 5 or 1)
    SetBlipScale(routeBlip, 0.72)
    SetBlipAsShortRange(routeBlip, false)
    SetBlipRoute(routeBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(stage == "pickup" and "Retirar Lanches" or "Entrega de Lanches")
    EndTextCommandSetBlipName(routeBlip)
end

local function deletePackageProp()
    if packageObject and DoesEntityExist(packageObject) then
        DeleteEntity(packageObject)
    end
    packageObject = nil
end

local function spawnPackageProp()
    if not inService or currentStage ~= "delivery" or not currentBatch or packageHidden then return end
    if packageObject and DoesEntityExist(packageObject) then return end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        packageHidden = true
        return
    end

    local propName = tostring(currentBatch.prop or "prop_food_cb_bag_01")
    local model = GetHashKey(propName)
    RequestModel(model)

    local deadline = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < deadline do
        Citizen.Wait(10)
    end
    if not HasModelLoaded(model) then return end

    local coords = GetEntityCoords(ped)
    packageObject = CreateObject(model, coords.x, coords.y, coords.z - 2.0, true, true, true)
    SetEntityCollision(packageObject, false, false)
    AttachEntityToEntity(
        packageObject,
        ped,
        GetPedBoneIndex(ped, 28422),
        0.25, 0.0, 0.06,
        65.0, -130.0, -65.0,
        true, true, false, true, 0, true
    )
    SetEntityAsMissionEntity(packageObject, true, true)
    SetModelAsNoLongerNeeded(model)
end

local function resetClientState()
    inService = false
    currentStage = nil
    currentTarget = nil
    currentBatch = nil
    actionBusy = false
    packageHidden = false
    deletePackageProp()
    removeRouteBlip()
    ClearPedTasks(PlayerPedId())
end

local function notify(message, kind)
    if message and message ~= "" then
        TriggerEvent("Notify", kind or "aviso", message, 7)
    end
end

local function applyServerStep(result)
    if not result or result.ok ~= true then
        notify(result and result.message or "Não foi possível atualizar a rota.", "negado")
        return false
    end

    currentStage = result.stage
    currentTarget = result.target
    currentBatch = result.batch
    packageHidden = false

    deletePackageProp()
    setRouteBlip(currentTarget, currentStage)

    if currentStage == "delivery" and currentBatch then
        spawnPackageProp()
    end

    notify(result.message, "aviso")
    return true
end

local function playTakeGiveAnimation()
    local ped = PlayerPedId()
    RequestAnimDict("mp_common")
    local deadline = GetGameTimer() + 3000
    while not HasAnimDictLoaded("mp_common") and GetGameTimer() < deadline do
        Citizen.Wait(10)
    end
    if HasAnimDictLoaded("mp_common") then
        TaskPlayAnim(ped, "mp_common", "givetake1_a", 2.0, -2.0, 900, 49, 0.0, false, false, false)
        Citizen.Wait(650)
        ClearPedTasks(ped)
    end
end

local function startDeliveryService()
    if inService or actionBusy then return end
    actionBusy = true

    if not vSERVER.checkEmp("Entregador") then
        actionBusy = false
        return
    end

    if not MageJobsBeginService("Entregador") then
        notify("Não foi possível iniciar o expediente.", "negado")
        actionBusy = false
        return
    end

    local result = vSERVER.startDeliveryCycle()
    if result and result.ok then
        inService = true
        applyServerStep(result)
    else
        notify(result and result.message or "Não foi possível iniciar a rota.", "negado")
        MageJobsEndService("Entregador")
        resetClientState()
    end

    actionBusy = false
end

local function finishCurrentAction()
    if not inService or actionBusy or not currentStage then return end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        notify("Desça do veículo para realizar esta ação.", "negado")
        return
    end

    actionBusy = true
    playTakeGiveAnimation()

    local result
    if currentStage == "delivery" then
        result = vSERVER.completeDeliveryStep()
    elseif currentStage == "pickup" then
        result = vSERVER.collectDeliveryStep()
    end

    if result and result.delivered then
        deletePackageProp()
        currentBatch = nil
    end

    if result and result.ok then
        applyServerStep(result)
    else
        notify(result and result.message or "Não foi possível concluir esta etapa.", "negado")
        if result and result.delivered then
            currentStage = "paused"
            currentTarget = nil
            removeRouteBlip()
        end
    end

    actionBusy = false
end

Citizen.CreateThread(function()
    Citizen.Wait(800)
    createStartBlip()
end)

-- Marker principal do emprego.
Citizen.CreateThread(function()
    while true do
        local idle = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local start = cfg.list["Entregador"] and cfg.list["Entregador"].inicio

        if start then
            local dist = #(coords - vector3(start[1] + 0.0, start[2] + 0.0, start[3] + 0.0))
            if dist <= 12.0 then
                idle = 0
                DrawMarker(27, start[1], start[2], start[3] - 0.95, 0,0,0, 0,0,0, 1.5,1.5,1.5, 132,102,226,180, false,false,2,false)

                if dist <= 3.0 and not inService then
                    DrawText3DIF(start[1], start[2], start[3], "~w~[ ~r~E ~w~] Iniciar expediente de entregas")
                    if dist <= 1.5 and IsControlJustPressed(0, 38) then
                        startDeliveryService()
                    end
                end
            end
        end

        Citizen.Wait(idle)
    end
end)

-- Ponto atual: entrega ou coleta.
Citizen.CreateThread(function()
    while true do
        local idle = 1000
        if inService and currentTarget and (currentStage == "delivery" or currentStage == "pickup") then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local target = vector3(currentTarget.x + 0.0, currentTarget.y + 0.0, currentTarget.z + 0.0)
            local dist = #(coords - target)

            if dist <= 35.0 then
                idle = 0
                local r,g,b = 255,80,80
                if currentStage == "pickup" then r,g,b = 255,200,70 end
                DrawMarker(27, target.x, target.y, target.z - 0.92, 0,0,0, 0,0,0, 1.25,1.25,1.0, r,g,b,120, false,false,2,false)

                if dist <= 3.0 then
                    local text = currentStage == "delivery"
                        and "~w~[ ~r~E ~w~] Entregar os lanches"
                        or "~w~[ ~y~E ~w~] Retirar novos lanches"
                    DrawText3DIF(target.x, target.y, target.z, text)

                    if dist <= 1.7 and IsControlJustPressed(0,38) then
                        finishCurrentAction()
                    end
                end
            end
        end
        Citizen.Wait(idle)
    end
end)

-- Prop automático: some ao entrar em veículo e volta ao sair.
Citizen.CreateThread(function()
    while true do
        local idle = 750
        if inService and currentStage == "delivery" and currentBatch then
            idle = 150
            local ped = PlayerPedId()
            local inVehicle = IsPedInAnyVehicle(ped, false)

            if inVehicle then
                if packageObject and DoesEntityExist(packageObject) then
                    deletePackageProp()
                end
                packageHidden = true
            else
                if packageHidden then packageHidden = false end
                if not packageObject or not DoesEntityExist(packageObject) then
                    spawnPackageProp()
                end
            end
        elseif packageObject and DoesEntityExist(packageObject) then
            deletePackageProp()
        end
        Citizen.Wait(idle)
    end
end)

-- F6 encerra o expediente em qualquer etapa.
Citizen.CreateThread(function()
    while true do
        local idle = 1000
        if inService then
            idle = 0
            drawTxtIF("~y~PRESSIONE ~r~F6 ~w~PARA ENCERRAR O EXPEDIENTE", 4, 0.270, 0.905, 0.45, 255,255,255,200)
            if IsControlJustPressed(0,167) and not actionBusy then
                actionBusy = true
                local ended = MageJobsEndService("Entregador")
                if ended then
                    vRP.playSound("Oneshot_Final", "MP_MISSION_COUNTDOWN_SOUNDSET")
                    resetClientState()
                else
                    notify("Não foi possível encerrar o expediente agora.", "negado")
                    actionBusy = false
                end
            end
        end
        Citizen.Wait(idle)
    end
end)

-- Sincroniza o estado local caso o expediente seja encerrado no servidor/restart.
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        if inService then
            local active = vSERVER.getActiveService()
            if active ~= "Entregador" then
                resetClientState()
            end
        end
    end
end)

RegisterNetEvent('vrp_ifood:permissao')
AddEventHandler('vrp_ifood:permissao', function()
    if not inService then startDeliveryService() end
end)

AddEventHandler("m_empregos:clientConfigUpdated", function()
    createStartBlip()
    -- Pontos/itens atualizados passam a valer no próximo passo do ciclo.
end)

-- Texto 3D local do entregador.
function DrawText3DIF(x,y,z,text)
    local onScreen,_x,_y = World3dToScreen2d(x,y,z)
    if not onScreen then return end
    SetTextFont(4)
    SetTextScale(0.35,0.35)
    SetTextColour(255,255,255,220)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = string.len(text) / 400
    DrawRect(_x,_y+0.0125,0.03+factor,0.04,0,0,0,110)
end

function drawTxtIF(text,font,x,y,scale,r,g,b,a)
    SetTextFont(font)
    SetTextScale(scale,scale)
    SetTextColour(r,g,b,a)
    SetTextOutline()
    SetTextCentre(1)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x,y)
end
