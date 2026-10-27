local Tunnel = module('vrp','lib/Tunnel')
local Server = Tunnel.getInterface(GetCurrentResourceName())

MG_MANSIONS_CLIENT_BRIDGE_READY = true

local mansions = {}
local blips = {}
local purchaseBusy = false
local deleteFurnitureObjects

local function money(value)
    local s=tostring(math.floor(tonumber(value) or 0))
    local rev=s:reverse():gsub('(%d%d%d)','%1.'):reverse()
    if rev:sub(1,1)=='.' then rev=rev:sub(2) end
    return rev
end

local function clearBlips()
    for _,b in pairs(blips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    blips={}
end

local function rebuildBlips()
    clearBlips()
    for _,m in ipairs(mansions) do
        local c=m.purchaseCoords
        if c then
            local b=AddBlipForCoord(c.x+0.0,c.y+0.0,c.z+0.0)
            SetBlipSprite(b,Config.BlipSprite)
            SetBlipColour(b,Config.BlipColor)
            SetBlipScale(b,Config.BlipScale)
            SetBlipAsShortRange(b,true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(tostring(m.name or 'Mansão'))
            EndTextCommandSetBlipName(b)
            blips[m.id]=b
        end
    end
end

RegisterNetEvent('m_mansions:sync',function(data)
    mansions=type(data)=='table' and data or {}
    rebuildBlips()
end)

local function drawText3D(x,y,z,text,scale,r,g,b)
    local onScreen,sx,sy=World3dToScreen2d(x,y,z)
    if not onScreen then return end
    SetTextScale(0.0,scale or 0.30)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(r or 255,g or 255,b or 255,235)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(sx,sy)
end

CreateThread(function()
    Wait(1200)
    TriggerServerEvent('m_mansions:requestSync')

    while true do
        local sleep=700
        local ped=PlayerPedId()
        local p=GetEntityCoords(ped)

        for _,m in ipairs(mansions) do
            if not m.occupied and m.purchaseCoords then
                local c=m.purchaseCoords
                local dist=#(p-vec3(c.x+0.0,c.y+0.0,c.z+0.0))
                if dist <= Config.MarkerDrawDistance then
                    sleep=0
                    DrawMarker(1,c.x,c.y,c.z-1.0,0.0,0.0,0.0,0.0,0.0,0.0,1.15,1.15,0.35,55,180,90,120,false,false,2,false,nil,nil,false)
                    drawText3D(c.x,c.y,c.z+0.65,('Pressione ~g~[E]~s~ para comprar a %s'):format(m.name),0.31,255,255,255)
                    drawText3D(c.x,c.y,c.z+0.48,('~g~R$ %s'):format(money(m.price)),0.30,90,220,130)
                    drawText3D(c.x,c.y,c.z+0.31,('x%d moradores'):format(tonumber(m.maxResidents) or 1),0.27,230,230,230)

                    if dist <= Config.PurchaseDistance and IsControlJustPressed(0,38) and not purchaseBusy then
                        purchaseBusy=true
                        local r=Server["requestPurchase"](m.id)
                        if not r or not r.ok then
                            TriggerEvent('Notify','negado',(r and r.message) or 'Não foi possível comprar esta mansão.',5000)
                            purchaseBusy=false
                        else
                            local bought=Server["confirmPurchase"](r.id)
                            if bought and not bought.ok and not bought.cancelled then
                                TriggerEvent('Notify','negado',bought.message or 'Não foi possível comprar esta mansão.',5000)
                            end
                            purchaseBusy=false
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('m_mansions:unlockPurchase',function()
    purchaseBusy=false
end)

AddEventHandler('onResourceStop',function(resource)
    if resource==GetCurrentResourceName() then clearBlips(); deleteFurnitureObjects(); SetNuiFocus(false,false) end
end)


-- ============================================================
-- MOBÍLIAS - NUI, PREVIEW 3D, EDIÇÃO E SINCRONIZAÇÃO
-- ============================================================
local furnitureObjects={}
local furnitureRecords={}
local furnitureUi=false
local furnitureContext=nil
local placement=nil
local editMode=false

local function requestModelSafe(model)
    local hash=joaat(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local timeout=GetGameTimer()+5000
    while not HasModelLoaded(hash) and GetGameTimer()<timeout do Wait(0) end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

deleteFurnitureObjects = function()
    for _,obj in pairs(furnitureObjects) do if DoesEntityExist(obj) then DeleteEntity(obj) end end
    furnitureObjects={}
end

local function spawnFurnitureRecord(f)
    if not f or not f.id or not f.model or not f.x then return end
    local hash=requestModelSafe(f.model)
    if not hash then return end
    local obj=CreateObjectNoOffset(hash,f.x+0.0,f.y+0.0,f.z+0.0,false,false,false)
    if obj and obj~=0 then
        SetEntityHeading(obj,(f.heading or 0.0)+0.0)
        FreezeEntityPosition(obj,true)
        SetEntityInvincible(obj,true)
        furnitureObjects[f.id]=obj
    end
    SetModelAsNoLongerNeeded(hash)
end

local function rebuildFurnitureObjects(data)
    deleteFurnitureObjects()
    furnitureRecords={}
    for _,f in ipairs(data or {}) do furnitureRecords[f.id]=f; spawnFurnitureRecord(f) end
end

RegisterNetEvent('m_mansions:furnitureSync',function(data) rebuildFurnitureObjects(data) end)

local function setUi(open)
    furnitureUi=open
    SetNuiFocus(open,open)
    SendNUIMessage({action=open and 'open' or 'close'})
end

local function openFurniture()
    if placement or editMode then return end
    local ctx=Server["getFurnitureContext"]()
    if not ctx or not ctx.ok then return TriggerEvent('Notify','negado',(ctx and ctx.message) or 'Não foi possível abrir o catálogo.',6000) end
    furnitureContext=ctx
    furnitureUi=true
    SetNuiFocus(true,true)
    SendNUIMessage({action='open',context=ctx})
end
RegisterNetEvent('m_mansions:openFurniture',openFurniture)

RegisterNUICallback('close',function(_,cb) setUi(false); cb({ok=true}) end)
RegisterNUICallback('refresh',function(_,cb) cb(Server["getFurnitureContext"]()) end)
RegisterNUICallback('savePrices',function(data,cb) cb(Server["saveFurniturePrices"](data and data.prices or {})) end)

local function rotationToDirection(rot)
    local z=math.rad(rot.z); local x=math.rad(rot.x); local num=math.abs(math.cos(x))
    return vec3(-math.sin(z)*num,math.cos(z)*num,math.sin(x))
end
local function cameraRay(distance)
    local cam=GetGameplayCamCoord(); local rot=GetGameplayCamRot(2); local dir=rotationToDirection(rot); local dest=cam+dir*distance
    local ray=StartShapeTestRay(cam.x,cam.y,cam.z,dest.x,dest.y,dest.z,-1,PlayerPedId(),7)
    local _,hit,endCoords=GetShapeTestResult(ray)
    if hit==1 then return endCoords end
    return dest
end

local function drawHelp(lines)
    local x,y=0.035,0.69
    local lineHeight=0.027
    local height=(#lines*lineHeight)+0.022
    DrawRect(0.175,y+(height/2)-0.006,0.300,height,12,12,14,205)
    DrawRect(0.026,y+(height/2)-0.006,0.004,height,190,151,92,235)
    for i,line in ipairs(lines) do
        SetTextFont(i==1 and 4 or 0)
        SetTextScale(0.0,i==1 and 0.37 or 0.32)
        SetTextColour(255,255,255,245)
        SetTextCentre(false)
        SetTextOutline()
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(line)
        EndTextCommandDisplayText(x,y+((i-1)*lineHeight))
    end
end

local function endPlacement(reopen)
    if placement and placement.object and DoesEntityExist(placement.object) then DeleteEntity(placement.object) end
    if placement and placement.originalObject and DoesEntityExist(placement.originalObject) then SetEntityVisible(placement.originalObject,true,false) end
    placement=nil
    if reopen then SetTimeout(150,function() openFurniture() end) end
end

RegisterNUICallback('buy',function(data,cb)
    local ctx=furnitureContext
    if not ctx then cb({ok=false,message='Contexto da mansão inválido.'}); return end
    local result=Server["beginFurniturePurchase"](ctx.mansionId,data.itemId)
    cb(result or {ok=false})
    if not result or not result.ok then return end
    local hash=requestModelSafe(result.item.model)
    if not hash then TriggerEvent('Notify','negado','Este prop não está disponível nesta build do GTA V.',6000); return end
    setUi(false)
    local p=GetEntityCoords(PlayerPedId())
    local obj=CreateObjectNoOffset(hash,p.x,p.y,p.z,false,false,false)
    SetEntityAlpha(obj,180,false); SetEntityCollision(obj,false,false); FreezeEntityPosition(obj,true)
    placement={mode='new',object=obj,item=result.item,mansionId=result.mansionId,heading=GetEntityHeading(PlayerPedId()),height=0.0}
    SetModelAsNoLongerNeeded(hash)
end)

CreateThread(function()
    while true do
        if placement then
            Wait(0)
            DisableControlAction(0,14,true); DisableControlAction(0,15,true)
            local hit=cameraRay(12.0)
            if hit then SetEntityCoordsNoOffset(placement.object,hit.x,hit.y,hit.z+placement.height,false,false,false) end
            if IsControlPressed(0,44) then placement.heading=placement.heading+0.7 end -- Q
            if IsControlPressed(0,38) then placement.heading=placement.heading-0.7 end -- E
            if IsControlJustPressed(0,10) or IsControlPressed(0,10) then placement.height=placement.height+0.015 end -- PGUP
            if IsControlJustPressed(0,11) or IsControlPressed(0,11) then placement.height=placement.height-0.015 end -- PGDN
            SetEntityHeading(placement.object,placement.heading)
            DrawMarker(28,GetEntityCoords(placement.object).x,GetEntityCoords(placement.object).y,GetEntityCoords(placement.object).z+0.1,0,0,0,0,0,0,0.16,0.16,0.16,60,160,255,120,false,false,2,false)
            drawHelp({'~y~POSICIONANDO MOBÍLIA','Mire para definir a posição','~y~[Q] / [E]~s~ Girar   ~y~[PAGE UP] / [PAGE DOWN]~s~ Altura','~g~[ENTER] CONFIRMAR~s~   |   ~r~[BACKSPACE] CANCELAR'})
            if IsControlJustPressed(0,191) then -- Enter
                local c=GetEntityCoords(placement.object)
                local result
                if placement.mode=='new' then result=Server["confirmFurniturePlacement"](placement.mansionId,placement.item.id,{x=c.x,y=c.y,z=c.z},placement.heading)
                else result=Server["updateFurniture"](placement.mansionId,placement.furnitureId,{x=c.x,y=c.y,z=c.z},placement.heading) end
                if result and result.ok then TriggerEvent('Notify','sucesso',result.message or 'Mobília salva.',5000); endPlacement(true)
                else TriggerEvent('Notify','negado',(result and result.message) or 'Não foi possível salvar a mobília.',6000) end
            elseif IsControlJustPressed(0,177) then endPlacement(true) end
        else Wait(250) end
    end
end)

local function closestOwnedFurniture(mansionId,maxDist)
    local p=GetEntityCoords(PlayerPedId()); local best,bestD
    for id,f in pairs(furnitureRecords) do
        if tostring(f.mansionId)==tostring(mansionId) then
            local d=#(p-vec3(f.x+0.0,f.y+0.0,f.z+0.0))
            if d<=(maxDist or 2.2) and (not bestD or d<bestD) then best,bestD=f,d end
        end
    end
    return best,bestD
end

RegisterNUICallback('editMode',function(_,cb)
    if not furnitureContext then cb({ok=false}); return end
    setUi(false); editMode=true; cb({ok=true})
end)

CreateThread(function()
    while true do
        if editMode and furnitureContext then
            Wait(0)
            local f=closestOwnedFurniture(furnitureContext.mansionId,tonumber(Config.FurnitureEditDistance) or 2.2)
            if f then
                local obj=furnitureObjects[f.id]
                if obj and DoesEntityExist(obj) then
                    DrawMarker(0,f.x,f.y,f.z+1.0,0,0,0,0,0,0,0.22,0.22,0.22,60,160,255,150,false,false,2,false)
                    drawHelp({('~b~%s'):format(f.name or f.model),'~g~[E]~s~ MOVER   ~y~[R]~s~ GIRAR   ~r~[G]~s~ VENDER','~r~[BACKSPACE]~s~ Sair da edição'})
                    if IsControlJustPressed(0,38) then
                        local hash=requestModelSafe(f.model)
                        if hash then
                            SetEntityVisible(obj,false,false)
                            local ghost=CreateObjectNoOffset(hash,f.x,f.y,f.z,false,false,false); SetEntityAlpha(ghost,180,false); SetEntityCollision(ghost,false,false); FreezeEntityPosition(ghost,true)
                            placement={mode='move',object=ghost,mansionId=furnitureContext.mansionId,furnitureId=f.id,heading=f.heading or 0.0,height=0.0,originalObject=obj}
                            editMode=false; SetModelAsNoLongerNeeded(hash)
                        end
                    elseif IsControlJustPressed(0,45) then -- R
                        local original=tonumber(f.heading) or 0.0
                        local heading=original
                        while true do
                            Wait(0); DisableControlAction(0,38,true)
                            if IsControlPressed(0,44) then heading=heading+0.8 end
                            if IsDisabledControlPressed(0,38) then heading=heading-0.8 end
                            SetEntityHeading(obj,heading)
                            drawHelp({'~y~GIRANDO MOBÍLIA','~y~Q / E~s~ Girar','~g~ENTER~s~ Salvar  |  ~r~BACKSPACE~s~ Cancelar'})
                            if IsControlJustPressed(0,191) then
                                local r=Server["updateFurniture"](furnitureContext.mansionId,f.id,{x=f.x,y=f.y,z=f.z},heading)
                                if r and r.ok then TriggerEvent('Notify','sucesso',r.message,4000) else SetEntityHeading(obj,original); TriggerEvent('Notify','negado',(r and r.message) or 'Falha ao girar.',5000) end
                                break
                            elseif IsControlJustPressed(0,177) then SetEntityHeading(obj,original); break end
                        end
                    elseif IsControlJustPressed(0,47) then -- G
                        local r=Server["sellFurniture"](furnitureContext.mansionId,f.id)
                        if r and r.ok then TriggerEvent('Notify','sucesso',r.message,5000) else TriggerEvent('Notify','negado',(r and r.message) or 'Não foi possível vender.',5000) end
                    end
                end
            else
                drawHelp({'~b~EDITAR MOBÍLIAS','Aproxime-se de uma mobília colocada nesta mansão.','~r~[BACKSPACE]~s~ Sair da edição'})
            end
            if IsControlJustPressed(0,177) then editMode=false; openFurniture() end
        else Wait(250) end
    end
end)

RegisterNUICallback('notify',function(data,cb) TriggerEvent('Notify',data.type or 'aviso',data.message or '',5000); cb({ok=true}) end)

CreateThread(function() Wait(1800); TriggerServerEvent('m_mansions:requestFurnitureSync') end)
