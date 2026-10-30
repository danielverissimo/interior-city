local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
srcDoors = {}
Tunnel.bindInterface(GetCurrentResourceName(),srcDoors)
vSERVERdoors = Tunnel.getInterface(GetCurrentResourceName())
local sprites = {
    [0] = { 'mpsafecracking', 'lock_open', 0, 0, 0.018, 0.018, 0, 0, 255, 0, 255 },
    [1] = { 'mpsafecracking', 'lock_closed', 0, 0, 0.018, 0.018, 0, 255, 0, 0, 255 },
}

local nearestLocks = {}
local closestLocks = {}
local doorData = {}
local tempData = {}
local delay = false
local doors = {}

local loadDoors = function()
    for key,lockable in pairs(doors) do
        local isGate = lockable.isGate == true
        local dist = tonumber(lockable.dist) or 5.0
        local text = lockable.text ~= false
        local lock = lockable.lock == true
        local hash = tonumber(lockable.hash)
        local x,y,z = tonumber(lockable.x),tonumber(lockable.y),tonumber(lockable.z)
        local perm = tostring(lockable.perm or '')
        if not hash or not x or not y or not z then goto continue end
        local identifier = ([[%s_%s]]):format(key, perm)
        local state = (lock and 4 or 0)
        lockable.identifier = identifier
        AddDoorToSystem(identifier, hash, x, y, z, false, false, false)
        DoorSystemSetDoorState(identifier, state, false, false)
        ::continue::
    end
end

RegisterNetEvent('doors:load', function(lockList)
    for k, lock in pairs(lockList) do
        print("Key:", k, "Lock status:", lock)
        if doors[k] then
            doors[k].lock = lock
        else
            print("Porta não encontrada para o ID:", k)
        end
    end
    loadDoors()
end)


RegisterNetEvent('door', function(id, unk)
    local door = doors[id]
    if door then
        local status = (unk and 2 or 0)
        DoorSystemSetDoorState(door.identifier, status, false, false)
        door.lock = unk or false
    end
end)

RegisterNetEvent('doors:loadall')
AddEventHandler('doors:loadall', function(listdoors)
    for _,door in pairs(doors or {}) do
        if door.identifier then
            RemoveDoorFromSystem(door.identifier)
        end
    end
    doors = listdoors or {}
end)

local function getClosestLock(playerCoords)
    local closestLocks = {}
    for key, lockable in pairs(doors) do
        local dist = tonumber(lockable.dist) or 5.0
        local x,y,z = tonumber(lockable.x),tonumber(lockable.y),tonumber(lockable.z)
        if x and y and z then
            local playerDistance = #(playerCoords - vec3(x, y, z))
            if playerDistance <= dist then
                lockable.key = key
                closestLocks[#closestLocks+1] = lockable
            end
        end
    end
    return closestLocks
end

local function drawSprite(lockCoords, sprite)
    SetDrawOrigin(lockCoords.x, lockCoords.y, lockCoords.z)
    DrawSprite(sprite[1], sprite[2], sprite[3], sprite[4], sprite[5], sprite[6] * GetAspectRatio(true), sprite[7], sprite[8], sprite[9], sprite[10], sprite[11])
    ClearDrawOrigin()
end

local drawInteraction = function()
    RequestStreamedTextureDict(sprites[0][1], true)
    RequestStreamedTextureDict(sprites[1][1], true)

    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local closestLocks = getClosestLock(playerCoords)
        local delay = (#closestLocks > 0 and 0 or 500)

        if (closestLocks) then
            for key, lockable in pairs(closestLocks) do 
                local x,y,z = tonumber(lockable.x),tonumber(lockable.y),tonumber(lockable.z)
                local lock = lockable.lock == true
                if x and y and z then
                    local lockCoords = vec3(x, y, z)
                    local lockState = (lock and 1 or 0)
                    local sprite = sprites[lockState]
                    drawSprite(lockCoords, sprite)
                end
            end
        end
        Wait(delay)
    end
end
local isAddingDoorlock = false
local mansionCaptureActive = false
local mansionCaptureOwner = nil
local mansionCaptureGeneration = 0

srcDoors.rayCastDoor = function()
    local rayCastCam = function(flags, ignore, distance)
        local coords, normal = GetWorldCoordFromScreenCoord(0.5, 0.5)
        local destination = coords + normal * (distance or 20)
        local handle = StartShapeTestLosProbe(coords.x, coords.y, coords.z, destination.x, destination.y, destination.z, flags or 511, PlayerPedId(), ignore or 4)
    
        while true do
            Wait(0)
    
            local retval, hit, endCoords, surfaceNormal, materialHash, entityHit = GetShapeTestResultIncludingMaterial(handle)
    
            if retval ~= 1 then
                return hit, entityHit, endCoords, surfaceNormal, materialHash
            end
        end
    end
    isAddingDoorlock = true
    repeat
        DisablePlayerFiring(PlayerId(), true)
        DisableControlAction(0, 25, true)

        local hit, entity, coords = rayCastCam(1|16)
        local changedEntity = lastEntity ~= entity
        local doorA = tempData[1] and tempData[1].entity or nil

        if changedEntity and lastEntity ~= doorA then
            SetEntityDrawOutline(lastEntity, false)
        end

        lastEntity = entity

        if hit then
            DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 255, 42, 24, 100, false, false, 0, true, false, false, false)
        end

        if hit and entity > 0 and GetEntityType(entity) == 3 and (doorA ~= entity) then
            if changedEntity then
                SetEntityDrawOutline(entity, true)
            end

            if IsDisabledControlJustPressed(0, 24) then
                isAddingDoorlock = false
                local doorCoords = GetEntityCoords(entity)
                local data = {
                    coords = {
                        x = doorCoords.x,
                        y = doorCoords.y,
                        z = doorCoords.z,
                    },
                    hash = GetEntityModel(entity)
                }
                SetEntityDrawOutline(entity, false)
                return data
            end
        end

        if IsDisabledControlJustPressed(0, 25) then
            SetEntityDrawOutline(entity, false)

            if not doorA then
                isAddingDoorlock = false
                return
            end

            SetEntityDrawOutline(doorA, false)
            table.wipe(tempData)
        end
    until not isAddingDoorlock
end

RegisterKeyMapping("synclock1","Trancar / Destrancar","keyboard","e")
local syncLock1 = function(source,args)
    if mansionCaptureActive then return end
    local playerCoords = GetEntityCoords(PlayerPedId())
    local closestLocks = getClosestLock(playerCoords)
    if (#closestLocks == 0) then return end
    
    for key, lockable in pairs(closestLocks) do 
        TriggerServerEvent('tryLockDoor', lockable.key)
    end
end

RegisterCommand('synclock1', syncLock1)
CreateThread(drawInteraction)

-----------------------------------------------------------------------------------------------------------------------------------------
-- MANSION DOOR CAPTURE
-- Captura robusta reutilizando a mesma lógica do raycast do doorsv2.
-- Mouse 1 OU E adicionam uma porta. F finaliza. Backspace cancela.
-----------------------------------------------------------------------------------------------------------------------------------------
local function mansionRayCastDoor(distance)
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)

    local function rotationToDirection(rot)
        local z = math.rad(rot.z)
        local x = math.rad(rot.x)
        local cosX = math.abs(math.cos(x))
        return vector3(-math.sin(z) * cosX, math.cos(z) * cosX, math.sin(x))
    end

    local direction = rotationToDirection(camRot)
    local destination = camCoords + direction * (distance or 20.0)
    local handle = StartShapeTestLosProbe(
        camCoords.x, camCoords.y, camCoords.z,
        destination.x, destination.y, destination.z,
        1 | 16,
        PlayerPedId(),
        7
    )

    local retval, hit, endCoords, surfaceNormal, entityHit
    repeat
        Wait(0)
        retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(handle)
    until retval ~= 1

    return hit == 1, entityHit or 0, endCoords
end

local function drawMansionCaptureText(x,y,text,scale,r,g,b,a)
    SetTextFont(4)
    SetTextScale(0.0,scale)
    SetTextColour(r or 255,g or 255,b or 255,a or 255)
    SetTextCentre(true)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x,y)
end

local function drawMansionCaptureHelp(count,hasDoor)
    -- Mantido totalmente em DrawText/DrawRect por frame. Não usa HelpText/Notify,
    -- evitando a mensagem que piscava durante a captura.
    DrawRect(0.5,0.885,0.72,0.105,10,14,22,235)
    drawMansionCaptureText(0.5,0.842,('Trancas da mansao: ~g~%d~s~ adicionada(s)'):format(count),0.36,255,255,255,255)
    if hasDoor then
        drawMansionCaptureText(0.5,0.878,'~g~[MOUSE 1 / E]~s~ Adicionar porta   ~b~[F]~s~ Finalizar   ~r~[BACKSPACE]~s~ Cancelar',0.30,215,225,240,255)
    else
        drawMansionCaptureText(0.5,0.878,'Aponte o centro da tela para uma porta   ~b~[F]~s~ Finalizar sem tranca   ~r~[BACKSPACE]~s~ Cancelar',0.30,215,225,240,255)
    end

    -- Mira discreta para deixar claro qual ponto do raycast está sendo usado.
    DrawRect(0.5,0.5,0.0015,0.014,255,255,255,210)
    DrawRect(0.5,0.5,0.008,0.0015,255,255,255,210)
end

local function sameCapturedDoor(a,hash,coords)
    return a.hash == hash
        and math.abs((a.x or 0.0)-coords.x) < 0.08
        and math.abs((a.y or 0.0)-coords.y) < 0.08
        and math.abs((a.z or 0.0)-coords.z) < 0.08
end

RegisterNetEvent('doorsv2:startMansionCapture',function(requestedOwner)
    -- Route only to the two known configuration panels; no arbitrary event names.
    local owner = requestedOwner == 'ic_config' and 'ic_config' or 'mg_config_panel'
    if mansionCaptureActive or isAddingDoorlock then
        TriggerEvent(owner..':mansionDoorCaptureCancelled','Já existe uma captura de porta em andamento.')
        return
    end

    mansionCaptureActive = true
    mansionCaptureOwner = owner
    mansionCaptureGeneration = mansionCaptureGeneration + 1
    local captureGeneration = mansionCaptureGeneration

    CreateThread(function()
        local captured = {}
        local outlinedEntity = 0
        local stableEntity = 0
        local stableCoords = nil
        local lastValidAt = 0
        local TARGET_GRACE_MS = 450
        local addWasDown = false
        local finishWasDown = false
        local cancelWasDown = false

        local function clearOutline()
            if outlinedEntity ~= 0 and DoesEntityExist(outlinedEntity) then
                SetEntityDrawOutline(outlinedEntity,false)
            end
            outlinedEntity = 0
        end

        -- O raycast usa um shape-test assíncrono e pode precisar esperar 1+ frames
        -- até o GTA devolver o resultado. Se fizermos essa espera dentro do mesmo
        -- loop que desenha a HUD/marker, o DrawText/DrawRect/DrawMarker deixa de ser
        -- executado em todos os frames e visualmente tudo fica piscando.
        --
        -- Por isso a leitura do raycast roda em uma thread separada e este loop fica
        -- 100% dedicado ao desenho por frame. Assim a mensagem inferior, a mira e o
        -- marcador permanecem contínuos mesmo quando o shape-test demora para responder.
        local rayHit = false
        local rayEntity = 0
        local rayCoords = nil
        local raycastRunning = true

        CreateThread(function()
            while mansionCaptureActive and captureGeneration == mansionCaptureGeneration and raycastRunning do
                local hit,entity,coords = mansionRayCastDoor(25.0)
                if not mansionCaptureActive or captureGeneration ~= mansionCaptureGeneration or not raycastRunning then break end

                rayHit = hit == true
                rayEntity = entity or 0
                rayCoords = coords
            end
        end)

        while mansionCaptureActive and captureGeneration == mansionCaptureGeneration do
            Wait(0)
            if not mansionCaptureActive or captureGeneration ~= mansionCaptureGeneration then break end

            DisablePlayerFiring(PlayerId(),true)
            DisableControlAction(0,24,true)  -- Mouse 1
            DisableControlAction(0,25,true)  -- Mouse 2
            DisableControlAction(0,38,true)  -- E
            DisableControlAction(0,23,true)  -- F
            DisableControlAction(0,177,true) -- Backspace

            local hit,entity,coords = rayHit,rayEntity,rayCoords
            local rawValid = hit and entity and entity > 0 and coords and DoesEntityExist(entity) and GetEntityType(entity) == 3
            local now = GetGameTimer()

            -- O shape-test do GTA pode falhar por 1 ou 2 frames mesmo mirando na mesma porta.
            -- Mantemos o último alvo válido por alguns milissegundos para impedir o outline/texto
            -- de piscar e para não perder o clique do jogador nesses frames intermediários.
            if rawValid then
                stableEntity = entity
                stableCoords = coords
                lastValidAt = now
            elseif stableEntity ~= 0 then
                if not DoesEntityExist(stableEntity) or (now - lastValidAt) > TARGET_GRACE_MS then
                    stableEntity = 0
                    stableCoords = nil
                end
            end

            local valid = stableEntity ~= 0 and DoesEntityExist(stableEntity) and GetEntityType(stableEntity) == 3

            if valid then
                if outlinedEntity ~= stableEntity then
                    clearOutline()
                    SetEntityDrawOutline(stableEntity,true)
                    outlinedEntity = stableEntity
                end

                local markerCoords = stableCoords
                if not markerCoords then markerCoords = GetEntityCoords(stableEntity) end
                DrawMarker(28,markerCoords.x,markerCoords.y,markerCoords.z,0.0,0.0,0.0,0.0,0.0,0.0,0.18,0.18,0.18,74,168,255,165,false,false,0,true,false,false,false)
            else
                clearOutline()
            end

            drawMansionCaptureHelp(#captured,valid)

            -- Leitura por borda manual. É mais estável que depender apenas de
            -- IsDisabledControlJustPressed quando o controle também está bloqueado.
            local addDown = IsDisabledControlPressed(0,24) or IsDisabledControlPressed(0,38)
            local finishDown = IsDisabledControlPressed(0,23)
            local cancelDown = IsDisabledControlPressed(0,177)

            local addPressed = addDown and not addWasDown
            local finishPressed = finishDown and not finishWasDown
            local cancelPressed = cancelDown and not cancelWasDown

            addWasDown = addDown
            finishWasDown = finishDown
            cancelWasDown = cancelDown

            if valid and addPressed then
                local dc = GetEntityCoords(stableEntity)
                local hash = GetEntityModel(stableEntity)
                local duplicate = false

                for _,door in ipairs(captured) do
                    if sameCapturedDoor(door,hash,dc) then
                        duplicate = true
                        break
                    end
                end

                if not duplicate then
                    captured[#captured+1] = {
                        hash = hash,
                        x = dc.x,
                        y = dc.y,
                        z = dc.z,
                        dist = 5.0,
                        text = true,
                        isGate = false,
                        lock = true
                    }
                    -- Feedback imediato: evita dúvida se o clique foi reconhecido.
                    PlaySoundFrontend(-1,'SELECT','HUD_FRONTEND_DEFAULT_SOUNDSET',true)
                    lastValidAt = now
                else
                    PlaySoundFrontend(-1,'ERROR','HUD_AMMO_SHOP_SOUNDSET',true)
                end
            end

            if finishPressed then
                mansionCaptureActive = false
                mansionCaptureOwner = nil
                clearOutline()
                TriggerEvent(owner..':mansionDoorsCaptured',captured)
                break
            end

            if cancelPressed then
                mansionCaptureActive = false
                mansionCaptureOwner = nil
                clearOutline()
                TriggerEvent(owner..':mansionDoorCaptureCancelled','Captura de trancas cancelada.')
                break
            end
        end

        raycastRunning = false
        clearOutline()
    end)
end)

AddEventHandler('doorsv2:cancelMansionCapture',function(owner)
    if mansionCaptureActive and mansionCaptureOwner == owner then
        mansionCaptureActive = false
        mansionCaptureOwner = nil
        mansionCaptureGeneration = mansionCaptureGeneration + 1
        TriggerEvent(owner..':mansionDoorCaptureCancelled','Captura de trancas cancelada.')
    end
end)

AddEventHandler('onResourceStop',function(name)
    if name == GetCurrentResourceName() or name == mansionCaptureOwner then
        mansionCaptureActive = false
        mansionCaptureOwner = nil
        mansionCaptureGeneration = mansionCaptureGeneration + 1
    end
end)
