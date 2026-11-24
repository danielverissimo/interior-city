local active

local function notify(message)
    print('[m_skinshop] ' .. message)
    TriggerEvent('Notify', 'aviso', message, 6000)
end

RegisterNetEvent('skinshop:thumbnailStatus', function(message)
    if source == 65535 and type(message) == 'string' then notify(message) end
end)

RegisterCommand('fotografarroupas', function(_, args)
    if active then return notify('O catálogo já está sendo fotografado.') end
    if skinshopOpen then return notify('Feche o menu da loja antes de fotografar.') end
    print('[m_skinshop] Solicitando a geração automática das miniaturas ao servidor.')
    TriggerServerEvent('skinshop:requestThumbnailBatch', args)
end, false)

local function closeStage(batch)
    if batch.camera then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(batch.camera, false)
    end
    if batch.ped and DoesEntityExist(batch.ped) then DeleteEntity(batch.ped) end
    batch.camera, batch.ped = nil, nil
end

local function finish(batch)
    if active ~= batch then return end
    active = nil
    closeStage(batch)
    TriggerServerEvent('skinshop:finishThumbnailBatch', batch.id)
end

function skinshopIsCapturingThumbnails()
    return active ~= nil
end

RegisterNUICallback('THUMBNAIL_FRAME', function(data, cb)
    if active and data.id == active.id and data.group == active.group and data.model == active.model then
        active.frame = data.image or false
        active.failure = data.error
    end
    cb(true)
end)

RegisterNetEvent('skinshop:thumbnailSaved', function(id, group, model, saved, failure)
    if source == 65535 and active and id == active.id and group == active.group and model == active.model then
        active.saved = saved == true
        active.failure = not saved and failure or nil
    end
end)

local function waitFor(batch, key, timeout)
    local deadline = GetGameTimer() + timeout
    while active == batch and batch[key] == nil and GetGameTimer() < deadline do Wait(25) end
    return active == batch and batch[key]
end

local function drawBackdrop(position, category)
    local angle = category.angle or 0.0
    local back = position - vector3(math.sin(angle), math.cos(angle), 0.0) * 1.8
    local side = vector3(math.cos(angle), -math.sin(angle), 0.0) * 8.0
    local top, bottom = vector3(0, 0, 5.0), vector3(0, 0, -5.0)
    local a, b, c, d = back - side + bottom, back + side + bottom, back + side + top, back - side + top
    DrawPoly(a.x,a.y,a.z, b.x,b.y,b.z, c.x,c.y,c.z, 38,46,56,255)
    DrawPoly(a.x,a.y,a.z, c.x,c.y,c.z, d.x,d.y,d.z, 38,46,56,255)
    DrawPoly(c.x,c.y,c.z, b.x,b.y,b.z, a.x,a.y,a.z, 38,46,56,255)
    DrawPoly(d.x,d.y,d.z, c.x,c.y,c.z, a.x,a.y,a.z, 38,46,56,255)
end

local function capture(batch, range, completed)
    local category = SkinshopThumbnailCategories[range.category]
    local hash = GetHashKey(range.gender == 'female' and 'mp_f_freemode_01' or 'mp_m_freemode_01')
    RequestModel(hash)
    local deadline = GetGameTimer() + 5000
    while active == batch and not HasModelLoaded(hash) and GetGameTimer() < deadline do Wait(25) end
    if active ~= batch then
        SetModelAsNoLongerNeeded(hash)
        return
    end
    if not HasModelLoaded(hash) then
        SetModelAsNoLongerNeeded(hash)
        return 'Não foi possível carregar o avatar.'
    end

    local position = GetEntityCoords(PlayerPedId()) + vector3(0.0, 0.0, 55.0)
    local ped = CreatePed(4, hash, position.x, position.y, position.z, category.rear and 180.0 or 0.0, false, false)
    SetModelAsNoLongerNeeded(hash)
    if ped == 0 then return 'Não foi possível criar o avatar.' end
    batch.ped = ped
    SetEntityCollision(ped, false, false)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetPedDefaultComponentVariation(ped)
    ClearAllPedProps(ped)

    local count = category.prop and GetNumberOfPedPropDrawableVariations(ped, category.slot)
        or GetNumberOfPedDrawableVariations(ped, category.slot)
    local pending = {}
    for model = range.first, math.min(range.last, count - 1) do
        if not completed[model] then pending[#pending+1] = model end
    end
    if #pending == 0 then return end

    local angle = category.angle or 0.0
    local cameraPos = position + vector3(math.sin(angle) * category.distance,
        math.cos(angle) * category.distance, category.height)
    local camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    batch.camera = camera
    SetCamCoord(camera, cameraPos.x, cameraPos.y, cameraPos.z)
    PointCamAtCoord(camera, position.x, position.y, position.z + category.height)
    SetCamFov(camera, 35.0)
    RenderScriptCams(true, false, 0, true, true)

    CreateThread(function()
        while active == batch and batch.ped == ped do
            HideHudAndRadarThisFrame()
            DisableControlAction(0, 38, true)
            drawBackdrop(position, category)
            DrawLightWithRange(cameraPos.x, cameraPos.y, cameraPos.z + 0.65, 255, 244, 232, 6.0, 1.0)
            Wait(0)
        end
    end)

    for _, model in ipairs(pending) do
        if active ~= batch then return end
        if category.prop then
            SetPedPropIndex(ped, category.slot, model, 0, true)
        else
            SetPedComponentVariation(ped, category.slot, model, 0, 0)
        end
        Wait(450)
        if active ~= batch then return end
        batch.model, batch.frame, batch.saved, batch.failure = model, nil, nil, nil
        local group = batch.group
        exports.screencapture:requestScreenshot({encoding = 'jpg', maxWidth = 720, maxHeight = 540}, function(image)
            if active ~= batch or batch.group ~= group or batch.model ~= model then return end
            if type(image) ~= 'string' or image:sub(1, 11) ~= 'data:image/' then
                batch.frame, batch.failure = false, 'O ScreenCapture não retornou uma imagem.'
                return
            end
            SendNUIMessage({action = 'thumbnailCapture', id = batch.id, group = group, model = model, image = image})
        end)
        local image = waitFor(batch, 'frame', 12000)
        if not image then return batch.failure or 'A interface não devolveu o quadro do jogo.' end
        TriggerServerEvent('skinshop:saveThumbnail', batch.id, batch.group, model, image)
        if not waitFor(batch, 'saved', 6000) then return batch.failure or 'O servidor não confirmou a gravação.' end
        batch.savedCount = batch.savedCount + 1
        if batch.savedCount == 1 or batch.savedCount % 100 == 0 then
            print(('[m_skinshop] %d miniatura(s) gravada(s).'):format(batch.savedCount))
        end
    end
end

RegisterNetEvent('skinshop:takeThumbnailBatch', function(id, plan, done)
    if source ~= 65535 or active then return end
    print(('[m_skinshop] Estúdio iniciado. %d grupos de roupas recebidos.'):format(#plan))
    if skinshopOpen then
        TriggerServerEvent('skinshop:finishThumbnailBatch', id)
        return notify('Feche a loja de roupas antes de fotografar.')
    end
    if GetResourceState('screencapture') ~= 'started' then
        TriggerServerEvent('skinshop:finishThumbnailBatch', id)
        return notify('O recurso ScreenCapture precisa estar iniciado no servidor.')
    end
    local batch = {id = id, savedCount = 0}
    active = batch
    for group, range in ipairs(plan) do
        local completed = {}
        local name = range.gender .. '/' .. range.category
        for _, model in ipairs(done[name] or {}) do completed[model] = true end
        batch.group, batch.model = group, nil
        local ok, failure = xpcall(capture, debug.traceback, batch, range, completed)
        if active ~= batch then return end
        closeStage(batch)
        if not ok or failure then
            print(('[m_skinshop] %s/%s: %s'):format(name, tostring(batch.model or 'preparo'), tostring(failure)))
            finish(batch)
            return notify(('Captura interrompida em %s. %d fotos salvas. Veja o F8.'):format(name, batch.savedCount))
        end
    end
    finish(batch)
    notify(('Catálogo processado: %d novas fotos.'):format(batch.savedCount))
end)

RegisterCommand('pararfotosroupas', function()
    if not active then return end
    finish(active)
    notify('Captura de roupas cancelada.')
end, false)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and active then finish(active) end
end)
