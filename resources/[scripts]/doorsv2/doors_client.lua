local Tunnel = module("vrp","lib/Tunnel")
local srcDoors = {}
Tunnel.bindInterface(GetCurrentResourceName(),srcDoors)
local sprites = {
    [0] = { 'mpsafecracking', 'lock_open', 0, 0, 0.021, 0.021, 0, 65, 210, 125, 255 },
    [1] = { 'mpsafecracking', 'lock_closed', 0, 0, 0.021, 0.021, 0, 235, 70, 80, 255 },
}

local doors = {}
local receivedCatalog = false

local function modelHash(hash)
    return hash & 0xffffffff
end

local function physicalDoorEntity(door)
    local entity = door.physicalEntity
    if entity and DoesEntityExist(entity) and modelHash(GetEntityModel(entity)) == modelHash(door.hash) then
        return entity
    end

    entity = GetClosestObjectOfType(door.x, door.y, door.z, 0.35, door.hash, false, false, false)
    if entity ~= 0 and DoesEntityExist(entity) then return entity end
end

local function applyPhysicalState(door)
    local entity = physicalDoorEntity(door)
    if not entity then
        door.physicalEntity, door.appliedPhysicalLock = nil, nil
        return
    end

    local changed = door.physicalEntity ~= entity or door.appliedPhysicalLock ~= door.lock
    if door.lock then
        local headingError = math.abs((GetEntityHeading(entity) - door.closedHeading + 180.0) % 360.0 - 180.0)
        if changed or headingError > 0.5 or #(GetEntityCoords(entity) - door.position) > 0.05 then
            SetEntityCoordsNoOffset(entity, door.x, door.y, door.z, false, false, false)
            SetEntityHeading(entity, door.closedHeading)
        end
    end
    if changed or IsEntityPositionFrozen(entity) ~= door.lock then
        FreezeEntityPosition(entity, door.lock)
    end
    door.physicalEntity, door.appliedPhysicalLock = entity, door.lock
end

local function applyDoorState(door)
    if door.physicalLock and type(door.closedHeading) == 'number' then
        applyPhysicalState(door)
        return
    end

    if not door.identifier or not IsDoorRegisteredWithSystem(door.identifier) then
        local found, existing = DoorSystemFindExistingDoor(door.x, door.y, door.z, door.hash)
        door.identifier = found and existing or GetHashKey('doorsv2:' .. door.key)
        door.ownsIdentifier = not found
        door.originalDoorState = nil
        if door.ownsIdentifier then
            AddDoorToSystem(door.identifier, door.hash, door.x, door.y, door.z, false, false, true)
        end
    end

    local id = door.identifier
    if not DoorSystemGetIsPhysicsLoaded(id) then return end

    local currentState = DoorSystemGetDoorState(id)
    if not door.ownsIdentifier and door.originalDoorState == nil then
        door.originalDoorState = currentState
    end

    local desiredState = door.lock and 1 or 0
    if door.lock and math.abs(DoorSystemGetOpenRatio(id)) > 0.01 then
        if currentState ~= 0 then DoorSystemSetDoorState(id, 0, false, true) end
        DoorSystemSetOpenRatio(id, 0.0, false, true)
        DoorSystemSetDoorState(id, 1, false, true)
    elseif currentState ~= desiredState then
        DoorSystemSetDoorState(id, desiredState, false, true)
    end
end

local function releaseDoor(door)
    if door.physicalEntity and DoesEntityExist(door.physicalEntity)
        and modelHash(GetEntityModel(door.physicalEntity)) == modelHash(door.hash) then
        FreezeEntityPosition(door.physicalEntity, false)
    end
    if door.identifier and IsDoorRegisteredWithSystem(door.identifier) then
        if door.ownsIdentifier then
            RemoveDoorFromSystem(door.identifier)
        elseif door.originalDoorState ~= nil and DoorSystemGetIsPhysicsLoaded(door.identifier) then
            DoorSystemSetDoorState(door.identifier, door.originalDoorState, false, true)
        end
    end
end

RegisterNetEvent('doorsv2:state', function(snapshot)
    if source ~= 65535 or type(snapshot) ~= 'table' then return end
    local nextDoors = {}
    for id, data in pairs(snapshot) do
        local door = doors[id]
        if door and (door.physicalLock ~= data.physicalLock or door.closedHeading ~= data.closedHeading) then
            releaseDoor(door)
            door = nil
        end
        if not door then
            door = data
            door.key = id
            door.position = vec3(door.x, door.y, door.z)
        else
            door.lock, door.dist, door.text = data.lock, data.dist, data.text
            door.iconCoords = data.iconCoords
        end
        nextDoors[id] = door
    end
    for id, door in pairs(doors) do
        if not nextDoors[id] then releaseDoor(door) end
    end
    doors = nextDoors
    receivedCatalog = true

    local position = GetEntityCoords(PlayerPedId())
    for _, door in pairs(doors) do
        if #(position - door.position) < 80.0 then applyDoorState(door) end
    end
end)

RegisterNetEvent('doorsv2:lock', function(id, locked)
    if source ~= 65535 or type(locked) ~= 'boolean' then return end
    local door = doors[id]
    if door then
        door.lock = locked
        if #(GetEntityCoords(PlayerPedId()) - door.position) < 80.0 then applyDoorState(door) end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, door in pairs(doors) do releaseDoor(door) end
end)

CreateThread(function()
    while true do
        local position = GetEntityCoords(PlayerPedId())
        for _, door in pairs(doors) do
            if #(position - door.position) < 80.0 then applyDoorState(door) end
        end
        Wait(250)
    end
end)

CreateThread(function()
    Wait(1000)
    while not receivedCatalog do
        TriggerServerEvent('doors:requestState')
        Wait(2500)
    end
end)

local function getClosestLock(playerCoords)
    local candidates = {}
    for _, door in pairs(doors) do
        local distance = math.min(tonumber(door.dist) or 5.0, 10.0)
        if #(playerCoords - door.position) <= distance then
            candidates[#candidates+1] = door
        end
    end
    return candidates
end


local function drawSprite(lockCoords, sprite)
    SetDrawOrigin(lockCoords.x, lockCoords.y, lockCoords.z)
    DrawSprite(sprite[1], sprite[2], sprite[3], sprite[4], sprite[5], sprite[6] * GetAspectRatio(true), sprite[7], sprite[8], sprite[9], sprite[10], sprite[11])
    ClearDrawOrigin()
end

-- A origem de muitas portas fica na dobradica. Usa o centro do modelo
-- na altura da fechadura, acompanhando a porta quando ela gira.
local function getLockIconCoords(door)
    if type(door.iconCoords) == 'table' then
        return vec3(door.iconCoords.x, door.iconCoords.y, door.iconCoords.z)
    end
    local entity = door.iconEntity
    if not entity or not DoesEntityExist(entity) then
        if door.iconRetryAt and GetGameTimer() < door.iconRetryAt then
            return vec3(door.x, door.y, door.z)
        end
        entity = GetClosestObjectOfType(door.x, door.y, door.z, 2.0, tonumber(door.hash), false, false, false)
        door.iconEntity = entity ~= 0 and entity or nil
        door.iconRetryAt = GetGameTimer() + 2000
    end
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        local minimum, maximum = GetModelDimensions(tonumber(door.hash))
        return GetOffsetFromEntityInWorldCoords(entity,
            (minimum.x + maximum.x) * 0.5,
            (minimum.y + maximum.y) * 0.5,
            minimum.z + math.min(1.05, (maximum.z - minimum.z) * 0.5))
    end
    return vec3(door.x, door.y, door.z)
end

local isAddingDoorlock = false
local mansionCaptureActive = false
local toggleAimedLock

local function findAimedLock(candidates)
    local target, best = nil, 1.0
    local aspect = GetAspectRatio(true)
    for _, door in ipairs(candidates) do
        if door.text ~= false then
            local coords = getLockIconCoords(door)
            local visible, x, y = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
            if visible then
                local dx, dy = (x - 0.5) / 0.0105, (y - 0.5) / (0.0105 * aspect)
                local distance = dx * dx + dy * dy
                if distance < best then target, best = door, distance end
            end
        end
    end
    return target
end

local drawInteraction = function()
    RequestStreamedTextureDict(sprites[0][1], true)
    RequestStreamedTextureDict(sprites[1][1], true)

    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local closestLocks = getClosestLock(playerCoords)
        local delay = (#closestLocks > 0 and 0 or 500)

        if not mansionCaptureActive and not isAddingDoorlock then
            local target = findAimedLock(closestLocks)
            if target then
                DisableControlAction(0, 38, true)
                if IsDisabledControlJustPressed(0, 38) then toggleAimedLock(target) end
            end
        end

        if (closestLocks) then
            for key, lockable in pairs(closestLocks) do 
                local x,y,z = tonumber(lockable.x),tonumber(lockable.y),tonumber(lockable.z)
                local lock = lockable.lock == true
                if x and y and z then
                    local lockCoords = getLockIconCoords(lockable)
                    local lockState = (lock and 1 or 0)
                    local sprite = sprites[lockState]
                    if lockable.text ~= false then drawSprite(lockCoords, sprite) end
                end
            end
        end
        Wait(delay)
    end
end

srcDoors.rayCastDoor = function()
    if isAddingDoorlock or mansionCaptureActive then return end

    local function rayCastCam()
        local origin, direction = GetWorldCoordFromScreenCoord(0.5, 0.5)
        local destination = origin + direction * 20.0
        local handle = StartShapeTestLosProbe(origin.x, origin.y, origin.z,
            destination.x, destination.y, destination.z, 1 | 16, PlayerPedId(), 4)
        local started = GetGameTimer()
        repeat
            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            local status, hit, point, _, entity = GetShapeTestResult(handle)
            if status ~= 1 then return status == 2 and (hit == 1 or hit == true), entity, point end
            Wait(0)
        until GetGameTimer() - started >= 250 or IsDisabledControlJustPressed(0, 25)
    end

    isAddingDoorlock = true
    local outlined = 0
    while true do
        local hit, entity, point = rayCastCam()
        local valid = hit and entity and entity > 0 and DoesEntityExist(entity) and GetEntityType(entity) == 3
        local target = valid and entity or 0
        if target ~= outlined then
            if outlined ~= 0 and DoesEntityExist(outlined) then SetEntityDrawOutline(outlined, false) end
            if valid then SetEntityDrawOutline(target, true) end
            outlined = target
        end

        if IsDisabledControlJustPressed(0, 25) then break end
        if valid and IsDisabledControlJustPressed(0, 24) then
            local coords = GetEntityCoords(entity)
            SetEntityDrawOutline(entity, false)
            isAddingDoorlock = false
            return {
                coords = {x = coords.x, y = coords.y, z = coords.z},
                hash = GetEntityModel(entity),
                iconCoords = {x = point.x, y = point.y, z = point.z},
            }
        end
        if hit and point then
            DrawMarker(28, point.x, point.y, point.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.2, 0.2, 0.2, 255, 42, 24, 100, false, false, 0, true, false, false, false)
        end
        Wait(0)
    end
    if outlined ~= 0 and DoesEntityExist(outlined) then SetEntityDrawOutline(outlined, false) end
    isAddingDoorlock = false
end


RegisterKeyMapping("synclock1","Trancar / Destrancar","keyboard","e")
local selectingLock = false
local function canSeeLock(target)
    local origin = GetGameplayCamCoord()
    local destination = getLockIconCoords(target)
    local probe = StartShapeTestLosProbe(origin.x,origin.y,origin.z,
        destination.x,destination.y,destination.z,1|16,PlayerPedId(),4)
    local deadline = GetGameTimer()+250
    repeat
        Wait(0)
        local state, hit, point = GetShapeTestResult(probe)
        if state ~= 1 then
            return state == 2 and (not (hit == 1 or hit == true) or #(point - destination) <= 0.16)
        end
    until GetGameTimer() >= deadline
    return false
end

local lastToggleAt = -250
toggleAimedLock = function(target)
    if not target or mansionCaptureActive or isAddingDoorlock or selectingLock
        or GetGameTimer() - lastToggleAt < 250 then return end
    selectingLock = true
    CreateThread(function()
        local visible = canSeeLock(target)
        local current = findAimedLock(getClosestLock(GetEntityCoords(PlayerPedId())))
        if visible and current == target and not mansionCaptureActive and not isAddingDoorlock then
            lastToggleAt = GetGameTimer()
            TriggerServerEvent('tryLockDoor', target.key, not target.lock)
        end
        selectingLock = false
    end)
end

RegisterCommand('synclock1', function()
    toggleAimedLock(findAimedLock(getClosestLock(GetEntityCoords(PlayerPedId()))))
end, false)
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

    return hit == 1 or hit == true, entityHit or 0, endCoords
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

RegisterNetEvent('doorsv2:startMansionCapture',function()
    if mansionCaptureActive or isAddingDoorlock then
        TriggerEvent('mg_config_panel:mansionDoorCaptureCancelled','Já existe uma captura de porta em andamento.')
        return
    end

    mansionCaptureActive = true

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
            while mansionCaptureActive and raycastRunning do
                local hit,entity,coords = mansionRayCastDoor(25.0)
                if not mansionCaptureActive or not raycastRunning then break end

                rayHit = hit == true
                rayEntity = entity or 0
                rayCoords = coords
            end
        end)

        while mansionCaptureActive do
            Wait(0)

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
                clearOutline()
                TriggerEvent('mg_config_panel:mansionDoorsCaptured',captured)
                break
            end

            if cancelPressed then
                mansionCaptureActive = false
                clearOutline()
                TriggerEvent('mg_config_panel:mansionDoorCaptureCancelled','Captura de trancas cancelada.')
                break
            end
        end

        raycastRunning = false
        clearOutline()
    end)
end)
