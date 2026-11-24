local entity, camera, modelName = 0, nil, nil
local generation = 0
function StopLuxuryPreview()
    generation = generation + 1
    if camera then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(camera, false)
        camera = nil
        ClearFocus()
    end
    if entity ~= 0 and DoesEntityExist(entity) then DeleteEntity(entity) end
    entity, modelName = 0, nil
end
local function paint(hex)
    if entity == 0 or not DoesEntityExist(entity) then return false end
    local r,g,b=tonumber(hex:sub(2,3),16),tonumber(hex:sub(4,5),16),tonumber(hex:sub(6,7),16)
    SetVehicleCustomPrimaryColour(entity,r,g,b)
    SetVehicleCustomSecondaryColour(entity,r,g,b)
    return true
end
RegisterNUICallback('PREVIEW_VEHICLE',function(data,cb)
    local location=DealerShipIndexOpen and TestDrive.Locations[DealerShipIndexOpen]
    local spawn=type(data)=='table' and data.spawn
    if not location or location.panel~='deluxe' or InTestDrive or type(spawn)~='string' or #spawn>50 or not spawn:match('^[%w_-]+$') then
        cb({ok=false,message='Abra a Luxury Motors para visualizar o veiculo.'});return
    end
    local hex=data.color or '#eeeeeb'
    if type(hex)~='string' or not hex:match('^#%x%x%x%x%x%x$') then cb({ok=false,message='Cor invalida.'});return end
    if modelName==spawn and paint(hex) then cb({ok=true});return end
    StopLuxuryPreview()
    local current=generation
    local hash=GetHashKey(spawn)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then cb({ok=false,message='Modelo indisponivel.'});return end
    RequestModel(hash)
    local deadline=GetGameTimer()+8000
    while not HasModelLoaded(hash) and generation==current and GetGameTimer()<deadline do Wait(50);RequestModel(hash) end
    if generation~=current or not HasModelLoaded(hash) then
        SetModelAsNoLongerNeeded(hash);cb({ok=false,message='Nao foi possivel carregar a previa.'});return
    end
    -- Entidade local sem rede ou colisao, afastada do transito.
    local pos=location.coords
    local x,y,z=pos.x,pos.y,pos.z+100.0
    entity=CreateVehicle(hash,x,y,z,145.0,false,false)
    SetModelAsNoLongerNeeded(hash)
    if entity==0 or not DoesEntityExist(entity) then cb({ok=false,message='Nao foi possivel criar a previa.'});return end
    modelName=spawn
    SetEntityAsMissionEntity(entity,true,true)
    SetEntityCollision(entity,false,false)
    FreezeEntityPosition(entity,true)
    SetEntityInvincible(entity,true)
    SetVehicleDoorsLocked(entity,2)
    SetVehicleEngineOn(entity,false,true,true)
    SetVehicleDirtLevel(entity,0.0)
    SetVehRadioStation(entity,'OFF')
    paint(hex)
    local minimum,maximum=GetModelDimensions(hash)
    local size=math.max(maximum.x-minimum.x,maximum.y-minimum.y,maximum.z-minimum.z,2.5)
    local distance=size*1.25
    local center=z+(minimum.z+maximum.z)*0.5
    SetFocusPosAndVel(x,y,z,0.0,0.0,0.0)
    camera=CreateCam('DEFAULT_SCRIPTED_CAMERA',true)
    SetCamCoord(camera,x+distance,y+distance,center+size*0.35)
    PointCamAtCoord(camera,x,y,center)
    SetCamFov(camera,40.0)
    RenderScriptCams(true,false,0,true,true)
    CreateThread(function()
        while generation==current and camera do
            HideHudAndRadarThisFrame()
            DrawLightWithRange(x+distance,y+distance,center+size,255,245,230,size*5.0,5.0)
            DrawLightWithRange(x-distance,y,center+size,230,240,255,size*4.0,3.0)
            Wait(0)
        end
    end)
    cb({ok=true})
end)
RegisterNUICallback('STOP_PREVIEW',function(_,cb) StopLuxuryPreview();cb({ok=true}) end)
RegisterNUICallback('ROTATE_PREVIEW',function(data,cb)
    if entity~=0 and DoesEntityExist(entity) then
        SetEntityHeading(entity,GetEntityHeading(entity)+(tonumber(data.direction)==-1 and -30.0 or 30.0))
    end
    cb({ok=true})
end)
AddEventHandler('onResourceStop',function(resource)
    if resource==GetCurrentResourceName() then StopLuxuryPreview() end
end)
