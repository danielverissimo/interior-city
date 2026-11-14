local placed, spawned = {}, {}
local opened, editing, ghost, selected = false,false,nil,nil
local requestId=0
local function notice(t) SendNUIMessage({type='notice',text=t}) end
local function removeGhost()
    if ghost and DoesEntityExist(ghost) then DeleteEntity(ghost) end
    ghost=nil
end
local function restore(msg)
    editing=false;removeGhost();opened=true;SetNuiFocus(true,true)
    SendNUIMessage({type='restore',message=msg})
end
local function loadModel(name)
    local hash=GetHashKey(name)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local deadline=GetGameTimer()+5000
    while not HasModelLoaded(hash) and GetGameTimer()<deadline do Wait(0) end
    if not HasModelLoaded(hash) then return nil end
    return hash
end
local function spawnLocal(p)
    local hash=loadModel(p.model)
    if not hash then return nil end
    local obj=CreateObjectNoOffset(hash,p.x,p.y,p.z,false,false,false)
    SetEntityHeading(obj,p.heading or 0.0)
    FreezeEntityPosition(obj,true)
    SetEntityCollision(obj,true,true)
    SetModelAsNoLongerNeeded(hash)
    return obj
end
RegisterNetEvent('m_propadmin:sync',function(data)
    placed=data or {}
    local valid={}
    for _,p in ipairs(placed) do valid[tostring(p.id)]=true end
    for id,obj in pairs(spawned) do
        if not valid[id] then if DoesEntityExist(obj) then DeleteEntity(obj) end spawned[id]=nil end
    end
    if opened then SendNUIMessage({type='placed',items=placed}) end
end)
RegisterNetEvent('m_propadmin:notice',notice)
RegisterNetEvent('m_propadmin:open',function()
    if editing then return end
    opened=true;SetNuiFocus(true,true)
    SendNUIMessage({type='open',items=placed})
    TriggerServerEvent('m_propadmin:request')
end)
RegisterNUICallback('close',function(_,cb)
    opened=false;SetNuiFocus(false,false);SendNUIMessage({type='close'});cb({ok=true})
end)
RegisterNUICallback('delete',function(data,cb)
    TriggerServerEvent('m_propadmin:delete',tonumber(data.id));cb({ok=true})
end)
RegisterNUICallback('start',function(data,cb)
    if editing then cb({ok=false});return end
    local name=tostring(data.model or '')
    if #name>Config.MaxModelLength or not name:match('^[%w_]+$') then cb({ok=false,error='Nome invalido'});return end
    local hash=loadModel(name)
    if not hash then cb({ok=false,error='Modelo nao disponivel neste build'});return end
    local ped=PlayerPedId()
    local c=GetOffsetFromEntityInWorldCoords(ped,0.0,2.0,0.0)
    ghost=CreateObjectNoOffset(hash,c.x,c.y,c.z,false,false,false)
    SetEntityAlpha(ghost,170,false)
    SetEntityCollision(ghost,false,false)
    FreezeEntityPosition(ghost,true)
    SetModelAsNoLongerNeeded(hash)
    selected=name;editing=true;opened=false;SetNuiFocus(false,false)
    SendNUIMessage({type='editing'})
    cb({ok=true})
    CreateThread(function()
        local pos=vector3(c.x,c.y,c.z)
        local heading=GetEntityHeading(ped)
        local saving=false
        while editing and ghost and DoesEntityExist(ghost) do
            Wait(0)
            DisableControlAction(0,30,true);DisableControlAction(0,31,true)
            DisableControlAction(0,32,true);DisableControlAction(0,33,true)
            DisableControlAction(0,34,true);DisableControlAction(0,35,true)
            DisableControlAction(0,44,true);DisableControlAction(0,38,true)
            local step=IsControlPressed(0,21) and 0.09 or 0.025
            local cam=GetGameplayCamRot(2).z
            local rad=math.rad(cam)
            local forward=vector3(-math.sin(rad),math.cos(rad),0)
            local right=vector3(math.cos(rad),math.sin(rad),0)
            if IsDisabledControlPressed(0,32) then pos=pos+forward*step end
            if IsDisabledControlPressed(0,33) then pos=pos-forward*step end
            if IsDisabledControlPressed(0,35) then pos=pos+right*step end
            if IsDisabledControlPressed(0,34) then pos=pos-right*step end
            if IsDisabledControlPressed(0,44) then heading=heading-1.0 end
            if IsDisabledControlPressed(0,38) then heading=heading+1.0 end
            if IsControlPressed(0,10) then pos=pos+vector3(0,0,step) end
            if IsControlPressed(0,11) then pos=pos-vector3(0,0,step) end
            SetEntityCoordsNoOffset(ghost,pos.x,pos.y,pos.z,false,false,false)
            SetEntityHeading(ghost,heading)
            DrawRect(0.5,0.915,0.58,0.115,10,20,25,195)
            SetTextFont(4);SetTextScale(0.0,0.32);SetTextColour(255,255,255,255);SetTextCentre(true)
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName('W A S D: Mover   |   Q / E: Girar   |   PgUp / PgDn: Altura~n~ENTER: Confirmar   |   ESC: Cancelar')
            EndTextCommandDisplayText(0.5,0.88)
            if IsControlJustPressed(0,200) or IsControlJustPressed(0,177) then restore('Posicionamento cancelado.');break end
            if not saving and IsControlJustPressed(0,201) then
                saving=true;requestId=requestId+1
                local id=requestId
                TriggerServerEvent('m_propadmin:save',id,{model=selected,x=pos.x,y=pos.y,z=pos.z,heading=heading})
                CreateThread(function()
                    Wait(7000)
                    if editing and saving and requestId==id then saving=false;notice('Sem resposta do servidor. Tente novamente.') end
                end)
            end
        end
    end)
end)
RegisterNetEvent('m_propadmin:result',function(id,ok,message)
    if id~=requestId or not editing then return end
    if ok then restore(message) else notice(message);SendNUIMessage({type='error',message=message}) end
end)
CreateThread(function()
    while true do
        Wait(Config.RefreshMs)
        local pos=GetEntityCoords(PlayerPedId())
        for _,p in ipairs(placed) do
            local id=tostring(p.id)
            local d=#(pos-vector3(p.x,p.y,p.z))
            if d<Config.StreamDistance then
                if not spawned[id] or not DoesEntityExist(spawned[id]) then spawned[id]=spawnLocal(p) end
            elseif spawned[id] then
                if DoesEntityExist(spawned[id]) then DeleteEntity(spawned[id]) end
                spawned[id]=nil
            end
        end
    end
end)
CreateThread(function() Wait(2000);TriggerServerEvent('m_propadmin:request') end)
AddEventHandler('onResourceStop',function(res)
    if res~=GetCurrentResourceName() then return end
    removeGhost();SetNuiFocus(false,false)
    for _,obj in pairs(spawned) do if DoesEntityExist(obj) then DeleteEntity(obj) end end
end)
