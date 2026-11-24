local points, nextOpen = {}, 0
RegisterNetEvent('m_farm_inicio:points',function(payload)
    points={}
    for _,point in ipairs(type(payload)=='table' and payload or {}) do
        if type(point)=='table' and type(point.coords)=='table' then
            points[#points+1]={id=point.id,label=point.label,coords=vector3(point.coords.x,point.coords.y,point.coords.z)}
        end
    end
end)
CreateThread(function()
    Wait(500)
    while true do TriggerServerEvent('m_farm_inicio:requestPoints');Wait(30000) end
end)
local function text3d(point,text)
    local visible,x,y=World3dToScreen2d(point.x,point.y,point.z+.4)
    if not visible then return end
    SetTextFont(4);SetTextScale(.33,.33);SetTextColour(235,243,255,235)
    SetTextCentre(true);SetTextOutline();SetTextEntry('STRING');AddTextComponentString(text);DrawText(x,y)
end
CreateThread(function()
    while true do
        local pause,nearest,distance=800,nil,FarmStart.InteractionDistance+.001
        local ped=PlayerPedId();local position=GetEntityCoords(ped)
        for _,point in ipairs(points) do
            local d=#(position-point.coords)
            if d<=FarmStart.DrawDistance then
                pause=0
                local m,c=FarmStart.Marker,point.coords
                DrawMarker(m.type,c.x,c.y,c.z+(m.zOffset or -0.95),0,0,0,0,0,0,m.size,m.size,m.height or m.size,m.r,m.g,m.b,m.alpha,false,false,2,false,nil,nil,false)
                if d<distance then nearest,distance=point,d end
            end
        end
        if nearest and not IsEntityDead(ped) and not IsPedInAnyVehicle(ped,false) then
            text3d(nearest.coords,'[ E ] Iniciar farm - '..nearest.label)
            if IsControlJustPressed(0,38) and GetGameTimer()>=nextOpen then
                nextOpen=GetGameTimer()+1500
                TriggerServerEvent('m_farm_inicio:open',nearest.id)
            end
        end
        Wait(pause)
    end
end)
