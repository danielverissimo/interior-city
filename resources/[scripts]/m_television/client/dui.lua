function MTelevisionRequestTextureDictionary(dict)
    RequestStreamedTextureDict(dict, true)
    local timeout = GetGameTimer() + 5000
    while not HasStreamedTextureDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(0)
    end
    return HasStreamedTextureDictLoaded(dict)
end

function MTelevisionLoadModel(model)
    if not IsModelInCdimage(model) or not IsModelValid(model) then return false end
    RequestModel(model)
    local timeout = GetGameTimer() + 8000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(0)
    end
    return HasModelLoaded(model)
end

function MTelevisionCreateNamedRenderTarget(name, model)
    if not name or name == "" then return nil end

    if not IsNamedRendertargetRegistered(name) then
        RegisterNamedRendertarget(name, false)
    end
    if not IsNamedRendertargetLinked(model) then
        LinkNamedRendertarget(model)
    end
    if not IsNamedRendertargetRegistered(name) then return nil end

    local id = GetNamedRendertargetRenderId(name)
    if id == 0 or id == -1 then return nil end
    return id
end

function MTelevisionReleaseNamedRenderTarget(name)
    if name and name ~= "" and IsNamedRendertargetRegistered(name) then
        ReleaseNamedRendertarget(name)
    end
end

function MTelevisionRenderTarget(renderTarget, txdName, txnName)
    if not renderTarget then return end
    SetTextRenderId(renderTarget)
    Set_2dLayer(4)
    SetScriptGfxDrawBehindPausemenu(true)
    DrawSprite(txdName, txnName, 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
    SetTextRenderId(GetDefaultScriptRendertargetRenderId())
    SetScriptGfxDrawBehindPausemenu(false)
end

local function drawTriangle(a, b, c, txd, txn, ua, va, ub, vb, uc, vc)
    DrawSpritePoly(
        a.x, a.y, a.z,
        b.x, b.y, b.z,
        c.x, c.y, c.z,
        255, 255, 255, 255,
        txd, txn,
        ua, va, ub, vb, uc, vc
    )
end

function MTelevisionRenderWorldQuad(entity, modelData, txdName, txnName)
    if not DoesEntityExist(entity) then return end

    local _, right, up = GetEntityMatrix(entity)
    local offset = modelData.Offset or vector3(0.0, 0.0, 0.0)
    local center = GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z)
    local width = tonumber(modelData.Scale) or 1.0
    local height = width * (9.0 / 16.0)

    local halfRight = right * (width * 0.5)
    local halfUp = up * (height * 0.5)

    local topLeft = center - halfRight + halfUp
    local topRight = center + halfRight + halfUp
    local bottomLeft = center - halfRight - halfUp
    local bottomRight = center + halfRight - halfUp

    drawTriangle(topLeft, bottomLeft, topRight, txdName, txnName, 0.0, 0.0, 0.0, 1.0, 1.0, 0.0)
    drawTriangle(topRight, bottomLeft, bottomRight, txdName, txnName, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0)
end
