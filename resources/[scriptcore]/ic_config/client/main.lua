local resource = GetCurrentResourceName()
local pending, serial, opened, opening, generation = {}, 0, false, false, 0
local capture
local teleportRequest

local function failure(id, code, message)
    return {requestId=id, ok=false, message=message, error={code=code,message=message}}
end

local function closeUI()
    generation = generation + 1
    local previousCapture = capture
    capture = nil
    teleportRequest = nil
    if previousCapture and previousCapture.kind == 'doors' then
        TriggerEvent('doorsv2:cancelMansionCapture',resource)
    end
    opening, opened = false, false
    SetNuiFocus(false, false)
    SendNUIMessage({action='close'})
end

local function request(method, payload, callback, requestedId)
    serial = serial + 1
    local id = requestedId or ('%s:%s'):format(GetGameTimer(), serial)
    if type(id) ~= 'string' or #id < 1 or #id > 96 or
       type(method) ~= 'string' or #method < 1 or #method > 64 or type(payload) ~= 'table' then
        callback(failure('', 'INVALID_REQUEST', 'Solicitação inválida.')); return
    end
    if pending[id] then callback(failure(id, 'BUSY', 'Solicitação já enviada.')); return end
    local entry = {callback=callback}
    pending[id] = entry
    TriggerServerEvent('ic_config:request', {requestId=id,method=method,payload=payload})
    SetTimeout(15000, function()
        if pending[id] ~= entry then return end
        pending[id] = nil
        callback(failure(id, 'TIMEOUT', 'Sem resposta. Atualize os dados antes de repetir uma alteração.'))
    end)
end

RegisterNetEvent('ic_config:response', function(response)
    if source ~= 65535 or type(response) ~= 'table' then return end
    local entry = pending[response.requestId]
    if not entry then return end
    pending[response.requestId] = nil
    if response.error then response.message = response.error.message end
    entry.callback(response)
end)

local function authorized(callback)
    request('hasAccess', {}, function(response)
        if response.ok and response.data == true then callback()
        else callback(response.ok and failure(response.requestId,'FORBIDDEN','Sem permissão.') or response) end
    end)
end

local function openUI()
    if opening or opened then closeUI(); return end
    opening = true
    local token = generation
    authorized(function(denied)
        if token ~= generation then return end
        opening = false
        if denied then
            TriggerEvent('Notify', 'negado', denied.message or 'Painel indisponível.', 5000)
            return
        end
        opened = true
        SetNuiFocus(true, true)
        SendNUIMessage({action='open'})
    end)
end

RegisterCommand('icconfig', openUI, false)
RegisterCommand('+ic_config_open', openUI, false)
RegisterCommand('-ic_config_open', function() end, false)
RegisterKeyMapping('+ic_config_open', 'Abrir configurações Interior City', 'keyboard', 'F9')

-- Enable these aliases only at the approved cutover, after stopping the old panel.
if GetConvar('ic_config_legacy_aliases', 'false') == 'true' then
    RegisterCommand('painelconfig', openUI, false)
    RegisterCommand('+ic_config_home', openUI, false)
    RegisterCommand('-ic_config_home', function() end, false)
    RegisterKeyMapping('+ic_config_home', 'Abrir configurações Interior City (Home)', 'keyboard', 'HOME')
end

RegisterNUICallback('close', function(_, callback)
    closeUI()
    callback({ok=true})
end)

local function outfit()
    local ped = PlayerPedId()
    local model = GetEntityModel(ped)
    local gender
    if model == GetHashKey('mp_m_freemode_01') then gender = 'masculino'
    elseif model == GetHashKey('mp_f_freemode_01') then gender = 'feminino'
    else return nil end
    local value = {}
    for component=0,11 do
        if component ~= 2 then
            value[tostring(component)] = {GetPedDrawableVariation(ped,component),
                GetPedTextureVariation(ped,component),GetPedPaletteVariation(ped,component)}
        end
    end
    for prop=0,7 do
        value['p'..prop] = {GetPedPropIndex(ped,prop),GetPedPropTextureIndex(ped,prop)}
    end
    return {gender=gender,outfit=value}
end

local function finishCapture(cancelled, capturedData)
    local current = capture
    if not current or current.finishing then return end
    current.finishing = true
    local token = generation
    authorized(function(denied)
        if token ~= generation or capture ~= current then return end
        if denied then
            closeUI()
            TriggerEvent('Notify','negado',denied.message or 'Sem permissão.',5000)
            return
        end
        local value
        if not cancelled and current.kind == 'position' then
            local ped = PlayerPedId()
            local c, h = GetEntityCoords(ped), GetEntityHeading(ped)
            value = {x=c.x,y=c.y,z=c.z,w=h,h=h,heading=h}
        elseif not cancelled and current.kind == 'doors' then
            value = capturedData
        elseif not cancelled then
            value = {coords={}, minZ=current.minZ-1, maxZ=current.maxZ+2,
                minCapturedZ=current.minZ,maxCapturedZ=current.maxZ}
            for _,p in ipairs(current.points) do value.coords[#value.coords+1]={x=p.x,y=p.y} end
        end
        capture = nil
        SendNUIMessage({action='captureResult',kind=current.kind,target=current.target,
            cancelled=cancelled == true,data=value})
        SetNuiFocus(true,true)
        SendNUIMessage({action='resume'})
    end)
end

local function startCapture(data, callback)
    if capture or teleportRequest then callback(failure(data.requestId,'BUSY','Finalize a ação atual.')); return end
    local payload = data.payload
    if type(payload) ~= 'table' or type(payload.target) ~= 'string' or #payload.target > 512 then
        callback(failure(data.requestId,'INVALID_REQUEST','Destino de captura inválido.')); return
    end
    -- Reserve before the authorization roundtrip to prevent two simultaneous starts.
    local kind = data.method == 'startPositionCapture' and 'position'
        or data.method == 'startMansionDoorCapture' and 'doors' or 'polygon'
    local current = {kind=kind,
        target=payload.target,points={},finishing=true}
    capture = current
    local token = generation
    authorized(function(denied)
        if token ~= generation or capture ~= current or not opened then
            callback(failure(data.requestId,'CLOSED','A captura foi encerrada.')); return
        end
        if denied then
            capture = nil
            callback(failure(data.requestId,denied.error and denied.error.code or 'FORBIDDEN',
                denied.message or 'Sem permissão.')); return
        end
        if kind == 'doors' and GetResourceState(ICConfig.Resources.Doors) ~= 'started' then
            capture = nil
            callback(failure(data.requestId,'RESOURCE_UNAVAILABLE','O recurso de portas está indisponível.')); return
        end
        current.finishing = false
        SetNuiFocus(false,false)
        SendNUIMessage({action='suspend'})
        callback({requestId=data.requestId,ok=true,data={started=true}})
        if kind == 'doors' then TriggerEvent('doorsv2:startMansionCapture',resource) end
    end)
end

AddEventHandler('ic_config:mansionDoorsCaptured',function(doors)
    if not capture or capture.kind ~= 'doors' then return end
    if type(doors) ~= 'table' or #doors > 256 then finishCapture(true); return end
    finishCapture(false,{doors=doors})
end)
AddEventHandler('ic_config:mansionDoorCaptureCancelled',function()
    if capture and capture.kind == 'doors' then finishCapture(true) end
end)

CreateThread(function()
    while true do
        local current = capture
        if current and current.kind ~= 'doors' and not current.finishing then
            local c = GetEntityCoords(PlayerPedId())
            local help = current.kind == 'position' and '~INPUT_CONTEXT~ Confirmar posição  |  ~INPUT_CELLPHONE_CANCEL~ Cancelar'
                or ('Polígono: %d pontos  |  ~INPUT_CONTEXT~ Adicionar  |  ~INPUT_CELLPHONE_CANCEL~ Concluir  |  ~INPUT_VEH_DUCK~ Cancelar'):format(#current.points)
            SetTextFont(0);SetTextScale(0.0,0.32);SetTextCentre(true)
            SetTextColour(235,255,248,255);SetTextOutline()
            BeginTextCommandDisplayText('STRING');AddTextComponentSubstringPlayerName(help)
            EndTextCommandDisplayText(0.5,0.90)
            DisableControlAction(0,200,true)
            if current.kind == 'polygon' then
                for i,p in ipairs(current.points) do
                    local nextPoint = current.points[i+1] or c
                    DrawLine(p.x,p.y,p.z,nextPoint.x,nextPoint.y,nextPoint.z,100,230,190,220)
                end
            end
            if IsControlJustPressed(0,38) then
                if current.kind == 'position' then finishCapture(false)
                elseif #current.points < 256 then
                    current.points[#current.points+1] = {x=c.x,y=c.y,z=c.z}
                    current.minZ = math.min(current.minZ or c.z,c.z)
                    current.maxZ = math.max(current.maxZ or c.z,c.z)
                end
            elseif IsControlJustPressed(0,177) then
                if current.kind == 'position' then finishCapture(true)
                elseif #current.points >= 3 then finishCapture(false)
                else TriggerEvent('Notify','negado','Adicione pelo menos três pontos.',2500) end
            elseif IsControlJustPressed(0,73) then finishCapture(true) end
            Wait(0)
        else Wait(200) end
    end
end)

RegisterNUICallback('request', function(data, callback)
    if type(data) ~= 'table' or type(data.method) ~= 'string' then
        callback(failure('', 'INVALID_REQUEST', 'Solicitação inválida.')); return
    end
    if not opened then callback(failure(data.requestId,'CLOSED','Abra o painel novamente.')); return end
    if data.method == 'teleport' then
        if capture or teleportRequest then callback(failure(data.requestId,'BUSY','Finalize a ação atual.')); return end
        local current,token = {},generation
        teleportRequest = current
        request('teleport',data.payload or {},function(response)
            if teleportRequest == current then teleportRequest = nil end
            if token ~= generation or not opened then callback(failure(data.requestId,'CLOSED','O painel foi fechado.')); return end
            if not response.ok then callback(response); return end
            local coords = type(response.data)=='table' and response.data.coords
            for _,axis in ipairs({'x','y','z'}) do
                local value = type(coords)=='table' and coords[axis]
                if type(value)~='number' or value~=value or math.abs(value)>1000000 then
                    callback(failure(data.requestId,'INVALID_RESPONSE','Destino de teleporte inválido.')); return
                end
            end
            local ped = PlayerPedId()
            local entity = IsPedInAnyVehicle(ped,false) and GetVehiclePedIsIn(ped,false) or ped
            SetEntityCoords(entity,coords.x,coords.y,coords.z+0.25,false,false,false,false)
            closeUI()
            callback(response)
        end,data.requestId)
        return
    end
    if data.method == 'startPositionCapture' or data.method == 'startSafeZonePolygon'
        or data.method == 'startMansionDoorCapture' then
        startCapture(data,callback); return
    end
    if data.method == 'getPlayerPosition' or data.method == 'getCurrentOutfit' then
        local token = generation
        authorized(function(denied)
            if denied then
                callback(failure(data.requestId, denied.error and denied.error.code or 'FORBIDDEN',
                    denied.message or 'Sem permissão.')); return
            end
            if token ~= generation or not opened then
                callback(failure(data.requestId,'CLOSED','O painel foi fechado.')); return
            end
            local value
            if data.method == 'getCurrentOutfit' then
                value = outfit()
                if not value then callback(failure(data.requestId,'INVALID_MODEL','Use um personagem freemode para capturar o fardamento.')); return end
            else
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                value = {x=coords.x,y=coords.y,z=coords.z,heading=heading,w=heading}
            end
            callback({requestId=data.requestId,ok=true,data=value})
        end)
        return
    end
    request(data.method, data.payload or {}, callback, data.requestId)
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= resource then return end
    closeUI()
    local requests = pending
    pending = {}
    for id,entry in pairs(requests) do entry.callback(failure(id,'STOPPED','O painel foi reiniciado.')) end
end)
