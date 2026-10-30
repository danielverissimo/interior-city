local resource=GetCurrentResourceName()
local pending,serial,opened,generation={},0,false,0
local opening,stopped=false,false
local properties,furniture,objects,blips={},{},{},{}
local placement
local function errorResult(id,code,message)
    return {requestId=id,ok=false,error={code=code,message=message}}
end
local function notify(message)
    TriggerEvent('Notify','aviso',message or 'Operação indisponível.',5000)
end
local function request(method,payload,callback,id)
    serial=serial+1
    id=id or ('game:%d:%d'):format(GetGameTimer(),serial)
    if type(id)~='string' or #id>96 or type(method)~='string' or type(payload)~='table' then
        callback(errorResult(id,'INVALID_REQUEST','Solicitação inválida.'));return
    end
    if pending[id] then callback(errorResult(id,'BUSY','Solicitação em andamento.'));return end
    local entry={callback=callback}
    pending[id]=entry
    TriggerServerEvent('ic_mansions:request',{requestId=id,method=method,payload=payload})
    SetTimeout(18000,function()
        if pending[id]~=entry then return end
        pending[id]=nil
        callback(errorResult(id,'TIMEOUT','Sem resposta. Consulte o estado antes de repetir uma operação.'))
    end)
end
RegisterNetEvent('ic_mansions:response',function(response)
    if source~=65535 or type(response)~='table' then return end
    local entry=pending[response.requestId]
    if not entry then return end
    pending[response.requestId]=nil
    entry.callback(response)
end)
local function deleteObject(entity)
    if entity and DoesEntityExist(entity) then DeleteEntity(entity) end
end
local function cancelPlacement()
    local current=placement
    placement=nil
    if current then deleteObject(current.entity) end
end
local function closeUI()
    generation=generation+1
    opened,opening=false,false
    cancelPlacement()
    SetNuiFocus(false,false)
    SendNUIMessage({action='close'})
end
local function openUI(id,section)
    generation=generation+1
    opening=true
    local token=generation
    request('getContext',id and {mansionId=id} or {},function(result)
        if token~=generation then return end
        opening=false
        if not result.ok then notify(result.error and result.error.message);return end
        opened=true
        SetNuiFocus(true,true)
        SendNUIMessage({action='open',context=result.data,view=section})
    end)
end
for _,command in ipairs({'mansao','mobilias','addmorador','tirarmorador','limparmansao'}) do
    RegisterCommand(command,function()
        if opened or opening then closeUI();return end
        openUI(nil,(command=='addmorador' or command=='tirarmorador') and 'residents'
            or command=='mobilias' and 'catalog' or 'overview')
    end,false)
end
local function serverEvent(name,callback)
    RegisterNetEvent('ic_mansions:'..name,function(value)
        if source==65535 then callback(value) end
    end)
end
serverEvent('taxDue',function(data)
    notify('O IPTU desta mansão está vencido. Use /mansao para pagar e liberar o acesso.')
end)
serverEvent('sync',function(rows)
    properties=type(rows)=='table' and rows or {}
    for _,blip in pairs(blips) do if DoesBlipExist(blip) then RemoveBlip(blip) end end
    blips={}
    for _,m in ipairs(properties) do
        local c=m.purchaseCoords
        if c and type(c.x)=='number' and type(c.y)=='number' and type(c.z)=='number' then
            local b=AddBlipForCoord(c.x,c.y,c.z)
            SetBlipSprite(b,ICMConfig.BlipSprite);SetBlipColour(b,ICMConfig.BlipColor)
            SetBlipScale(b,ICMConfig.BlipScale);SetBlipAsShortRange(b,true)
            BeginTextCommandSetBlipName('STRING');AddTextComponentSubstringPlayerName(m.name or 'Mansão')
            EndTextCommandSetBlipName(b);blips[m.id]=b
        end
    end
end)
serverEvent('furnitureSync',function(rows)
    furniture=type(rows)=='table' and rows or {}
    -- Recreate changed transforms; ownership/economy fields never arrive here.
    for _,entry in pairs(objects) do deleteObject(entry.entity) end
    objects={}
end)
local function distance(a,b)
    return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2)
end
local function loadModel(name)
    if type(name)~='string' or #name>100 then return nil end
    local hash=GetHashKey(name)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local deadline=GetGameTimer()+5000
    while not stopped and not HasModelLoaded(hash) and GetGameTimer()<deadline do Wait(0) end
    if stopped then SetModelAsNoLongerNeeded(hash);return nil end
    if not HasModelLoaded(hash) then return nil end
    return hash
end
local function beginPlacement(data,callback)
    if placement then callback(errorResult(data.requestId,'BUSY','Finalize o posicionamento atual.'));return end
    local payload=type(data.payload)=='table' and data.payload or {}
    local current={loading=true,mode=data.method=='startFurnitureMove' and 'move' or 'buy',mansionId=payload.mansionId}
    placement=current
    local token=generation
    local function ready(result)
        if placement~=current or generation~=token or not opened then
            callback(errorResult(data.requestId,'CLOSED','O painel foi fechado.'));return
        end
        if not result.ok then placement=nil;result.requestId=data.requestId;callback(result);return end
        local value=result.data
        if current.mode=='buy' then
            current.item=value.item;current.placementToken=value.placementToken
        else
            if not value.canFurniture then placement=nil;callback(errorResult(data.requestId,'FORBIDDEN','Somente o proprietário pode mover mobílias.'));return end
            for _,piece in ipairs(value.furniture or {}) do
                if tostring(piece.id)==tostring(payload.furnitureId) then current.item=piece;break end
            end
            current.furnitureId=payload.furnitureId
        end
        if not current.item then placement=nil;callback(errorResult(data.requestId,'NOT_FOUND','Mobília indisponível.'));return end
        local hash=loadModel(current.item.model)
        if placement~=current or token~=generation then if hash then SetModelAsNoLongerNeeded(hash) end;callback(errorResult(data.requestId,'CLOSED','O painel foi fechado.'));return end
        if not hash then placement=nil;callback(errorResult(data.requestId,'INVALID_MODEL','O modelo desta mobília não está disponível no jogo.'));return end
        local c=GetOffsetFromEntityInWorldCoords(PlayerPedId(),0.0,2.0,0.0)
        current.entity=CreateObjectNoOffset(hash,c.x,c.y,c.z,false,false,false)
        SetModelAsNoLongerNeeded(hash)
        if not current.entity or current.entity==0 then placement=nil;callback(errorResult(data.requestId,'INVALID_MODEL','Não foi possível criar a prévia.'));return end
        FreezeEntityPosition(current.entity,true);SetEntityCollision(current.entity,false,false)
        SetEntityAlpha(current.entity,160,false)
        current.heading=tonumber(current.item.heading) or GetEntityHeading(PlayerPedId())
        current.offsetZ=0.0;current.offsetY=2.0;current.loading=false
        SetNuiFocus(false,false);SendNUIMessage({action='suspend'})
        callback({requestId=data.requestId,ok=true,data={started=true}})
    end
    if current.mode=='buy' then request('beginFurniturePurchase',{mansionId=payload.mansionId,itemId=payload.itemId},ready)
    else request('getContext',{mansionId=payload.mansionId},ready) end
end
RegisterNUICallback('close',function(_,callback)closeUI();callback({ok=true})end)
RegisterNUICallback('request',function(data,callback)
    if not opened or type(data)~='table' then callback(errorResult('', 'CLOSED','Abra o painel novamente.'));return end
    if data.method=='startFurniturePlacement' or data.method=='startFurnitureMove' then
        beginPlacement(data,callback);return
    end
    request(data.method,data.payload or {},callback,data.requestId)
end)
local function help(text)
    SetTextFont(0);SetTextScale(0.0,0.32);SetTextCentre(true);SetTextColour(235,255,248,255)
    SetTextOutline();BeginTextCommandDisplayText('STRING');AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.5,0.9)
end
CreateThread(function()
    while true do
        local current=placement
        if current and not current.loading and not current.saving then
            Wait(0)
            if current~=placement or not opened or stopped then goto nextPlacementFrame end
            if IsControlPressed(0,174) then current.heading=current.heading-1 end
            if IsControlPressed(0,175) then current.heading=current.heading+1 end
            if IsControlPressed(0,10) then current.offsetZ=current.offsetZ+0.02 end
            if IsControlPressed(0,11) then current.offsetZ=current.offsetZ-0.02 end
            if IsControlJustPressed(0,14) then current.offsetY=math.min(8,current.offsetY+0.2) end
            if IsControlJustPressed(0,15) then current.offsetY=math.max(0.5,current.offsetY-0.2) end
            local c=GetOffsetFromEntityInWorldCoords(PlayerPedId(),0.0,current.offsetY,current.offsetZ)
            SetEntityCoordsNoOffset(current.entity,c.x,c.y,c.z,false,false,false)
            SetEntityHeading(current.entity,current.heading%360)
            local cost=current.mode=='buy' and (' | Compra R$ '..tostring(current.item.price or 0)) or ''
            help('E: confirmar | Backspace: cancelar | Setas: girar | PgUp/PgDn: altura'..cost)
            if IsControlJustPressed(0,177) then
                cancelPlacement();SetNuiFocus(true,true);SendNUIMessage({action='resume'})
            elseif IsControlJustPressed(0,38) then
                current.saving=true
                local payload={mansionId=current.mansionId,coords={x=c.x,y=c.y,z=c.z},heading=current.heading%360}
                local method
                if current.mode=='buy' then
                    method='confirmFurniturePlacement';payload.itemId=current.item.id;payload.placementToken=current.placementToken
                else method='updateFurniture';payload.furnitureId=current.furnitureId end
                local token=generation
                request(method,payload,function(result)
                    if placement==current then cancelPlacement() end
                    if token~=generation or not opened then return end
                    SendNUIMessage({action='operationResult',ok=result.ok==true,
                        message=result.ok and 'Posição salva.' or (result.error and result.error.message or 'Operação não confirmada.')})
                    SetNuiFocus(true,true);SendNUIMessage({action='resume'})
                end)
            end
        else Wait(200) end
        ::nextPlacementFrame::
    end
end)
CreateThread(function()
    while true do
        local c=GetEntityCoords(PlayerPedId())
        local delay=500
        if not placement and not opened then
            for _,m in ipairs(properties) do
                if not m.occupied and m.purchaseCoords and distance(c,m.purchaseCoords)<=20 then
                    delay=0
                    local p=m.purchaseCoords
                    DrawMarker(1,p.x,p.y,p.z-1,0,0,0,0,0,0,1.0,1.0,0.3,90,210,170,140,false,false,2,false,nil,nil,false)
                    if distance(c,p)<=ICMConfig.PurchaseDistance then
                        help('E: conhecer e comprar '..tostring(m.name or 'mansão'))
                        if IsControlJustPressed(0,38) then openUI(m.id,'overview') end
                    end
                end
            end
        end
        Wait(delay)
    end
end)
CreateThread(function()
    while true do
        local c=GetEntityCoords(PlayerPedId())
        local visible={}
        for _,piece in ipairs(furniture) do
            if piece.id and piece.model and type(piece.x)=='number' and type(piece.y)=='number' and type(piece.z)=='number'
                and distance(c,piece)<=ICMConfig.FurnitureDrawDistance then
                local key=tostring(piece.mansionId)..':'..tostring(piece.id);visible[key]=true
                if not objects[key] then
                    local snapshot=furniture
                    local hash=loadModel(piece.model)
                    if hash and not stopped and snapshot==furniture then
                        local object=CreateObjectNoOffset(hash,piece.x,piece.y,piece.z,false,false,false)
                        if object and object~=0 then
                            SetEntityHeading(object,tonumber(piece.heading) or 0);FreezeEntityPosition(object,true)
                            objects[key]={entity=object}
                        end
                    end
                    if hash then SetModelAsNoLongerNeeded(hash) end
                end
            end
        end
        for key,entry in pairs(objects) do if not visible[key] then deleteObject(entry.entity);objects[key]=nil end end
        Wait(1000)
    end
end)
CreateThread(function()
    Wait(1500)
    TriggerServerEvent('ic_mansions:requestSync')
    TriggerServerEvent('ic_mansions:requestFurnitureSync')
end)
AddEventHandler('onResourceStop',function(name)
    if name~=resource then return end
    stopped=true
    closeUI()
    for _,entry in pairs(objects) do deleteObject(entry.entity) end
    for _,b in pairs(blips) do if DoesBlipExist(b) then RemoveBlip(b) end end
    for id,entry in pairs(pending) do entry.callback(errorResult(id,'STOPPED','O sistema foi reiniciado.')) end
    pending={}
end)
