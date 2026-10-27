local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")

vRP = Proxy.getInterface("vRP")
MDrugs = Tunnel.getInterface("m_drugs")

function MDrugsDistance(coords)
    local pedCoords = GetEntityCoords(PlayerPedId())
    return GetDistanceBetweenCoords(pedCoords, coords.x, coords.y, coords.z, true)
end

function MDrugsDrawText3D(x, y, z, text, rectColor)
    local onScreen, screenX, screenY = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    SetTextScale(0.28, 0.28)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(screenX, screenY)

    local factor = string.len(text) / 370
    local color = rectColor or { 0, 255, 0, 10 }
    DrawRect(screenX, screenY + 0.0125, 0.005 + factor, 0.03, color[1], color[2], color[3], color[4])
end

function MDrugsSetPed(coords)
    if not coords then return end

    local ped = PlayerPedId()

    -- Mantém o jogador exatamente onde ele apertou E.
    -- A função agora altera somente a direção do ped, sem teletransportá-lo.
    if coords.heading then
        SetEntityHeading(ped, coords.heading + 0.0)
    end
end

function MDrugsCreateObject(data)
    if not data or not data.model then return nil end

    local hash = type(data.model) == "number" and data.model or GetHashKey(data.model)

    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Citizen.Wait(10)
    end

    local spawnZ = (data.z or 0.0) + 0.0
    local object = CreateObjectNoOffset(hash,data.x + 0.0,data.y + 0.0,spawnZ,true,true,false)

    if data.heading then
        SetEntityHeading(object,data.heading + 0.0)
    end

    -- Apoia o fundo do objeto exatamente na primeira superfície sólida abaixo
    -- da coordenada informada. Ideal para bancadas/mesas.
    if data.snapToSurface then
        local rayStartZ = spawnZ + (data.raycastAbove or 2.0)
        local rayEndZ = spawnZ - (data.raycastBelow or 3.0)

        local ray = StartShapeTestRay(
            data.x + 0.0,data.y + 0.0,rayStartZ,
            data.x + 0.0,data.y + 0.0,rayEndZ,
            1,
            object,
            7
        )

        local _,hit,hitCoords = GetShapeTestResult(ray)

        if hit == 1 then
            local minDim,maxDim = GetModelDimensions(hash)

            -- minDim.z normalmente é negativo; subtrair esse valor posiciona
            -- a base geométrica do prop exatamente sobre a superfície.
            local finalZ = hitCoords.z - minDim.z + (data.surfaceOffset or 0.0)

            SetEntityCoordsNoOffset(
                object,
                data.x + 0.0,
                data.y + 0.0,
                finalZ,
                false,false,false
            )
        end
    end

    FreezeEntityPosition(object,true)
    SetModelAsNoLongerNeeded(hash)
    return object
end

function MDrugsDeleteObject(object)
    if object and DoesEntityExist(object) then
        DeleteEntity(object)
    end
end

function MDrugsDeleteObjects(objects)
    for _, object in pairs(objects or {}) do
        MDrugsDeleteObject(object)
    end
end


local mDrugsActionLocked = false
local mDrugsActionToken = 0

function MDrugsIsActionLocked()
    return mDrugsActionLocked
end

function MDrugsLockAction(duration)
    duration = tonumber(duration) or 0
    if duration <= 0 then return end

    local ped = PlayerPedId()
    mDrugsActionToken = mDrugsActionToken + 1
    local token = mDrugsActionToken

    mDrugsActionLocked = true
    FreezeEntityPosition(ped,true)

    SetTimeout(duration,function()
        if token ~= mDrugsActionToken then return end
        mDrugsActionLocked = false

        local currentPed = PlayerPedId()
        if DoesEntityExist(currentPed) then
            FreezeEntityPosition(currentPed,false)
        end
    end)
end

Citizen.CreateThread(function()
    while true do
        if mDrugsActionLocked then
            Citizen.Wait(0)

            -- Movimento / corrida / pulo / agachar.
            DisableControlAction(0,30,true)
            DisableControlAction(0,31,true)
            DisableControlAction(0,21,true)
            DisableControlAction(0,22,true)
            DisableControlAction(0,36,true)

            -- Impede entrar/sair de veículos e ações que possam quebrar a animação.
            DisableControlAction(0,23,true)
            DisableControlAction(0,75,true)
            DisableControlAction(0,73,true)

            -- F6 e F7. Algumas bases usam essas teclas para cancelar animações/ações.
            DisableControlAction(0,167,true)
            DisableControlAction(0,168,true)

            -- Combate/armas durante a produção.
            DisableControlAction(0,24,true)
            DisableControlAction(0,25,true)
            DisableControlAction(0,37,true)
            DisableControlAction(0,44,true)
            DisablePlayerFiring(PlayerId(),true)
        else
            Citizen.Wait(250)
        end
    end
end)
