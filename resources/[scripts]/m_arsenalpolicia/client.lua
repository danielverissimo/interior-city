local Tunnel=module('vrp','lib/Tunnel')
local Server=Tunnel.getInterface(GetCurrentResourceName())
local opened,allowed,canManage=false,false,false
local opening=false
local openToken=0
local location=Config.DefaultLocation
local arsenalBlip=nil
local blipKey=nil
local function refreshBlip()
    local key=allowed and type(location)=='table' and ('%s:%s:%s'):format(location.x,location.y,location.z) or false
    if key==blipKey and (not key or (arsenalBlip and DoesBlipExist(arsenalBlip))) then return end
    blipKey=key
    if arsenalBlip and DoesBlipExist(arsenalBlip) then RemoveBlip(arsenalBlip) end
    arsenalBlip=nil
    if not allowed or type(location)~='table' then return end
    arsenalBlip=AddBlipForCoord(location.x,location.y,location.z)
    SetBlipSprite(arsenalBlip,Config.Blip.sprite)
    SetBlipColour(arsenalBlip,Config.Blip.color)
    SetBlipScale(arsenalBlip,Config.Blip.scale)
    SetBlipAsShortRange(arsenalBlip,true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Blip.name)
    EndTextCommandSetBlipName(arsenalBlip)
end
local function updateLocation(point)
    location=point
    refreshBlip()
end
local function close()
    opened=false;canManage=false
    opening=false;openToken=openToken+1
    SetNuiFocus(false,false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({action='close'})
end
local function open()
    if opened or opening then close();return end
    opening=true
    openToken=openToken+1
    local token=openToken
    SetTimeout(8000,function()
        if token==openToken and opening then
            close()
            TriggerEvent('Notify','negado','O arsenal nao carregou. Seus controles foram liberados; tente abrir novamente.',6)
        end
    end)
    local ok,result=pcall(Server.open)
    if token~=openToken then return end
    if not ok or not result or not result.ok then
        close()
        TriggerEvent('Notify','negado',result and result.message or 'Nao foi possivel abrir o arsenal.',5)
        return
    end
    canManage=result.canManage==true
    allowed=true
    updateLocation(result.location)
    SendNUIMessage({action='open',data=result,token=token})
end
RegisterCommand(Config.Command,open,false)
RegisterCommand('fechararsenal',close,false)
RegisterNUICallback('visible',function(data,cb)
    if opening and data.token==openToken then
        opening=false;opened=true
        SetNuiFocus(true,true)
    end
    cb({ok=opened})
end)
RegisterNUICallback('close',function(_,cb) close();cb({ok=true}) end)
local function callback(route,fn)
    RegisterNUICallback(route,function(data,cb)
        if not opened then cb({ok=false,message='Abra o arsenal novamente.'});return end
        local ok,result=pcall(fn,type(data)=='table' and data or {})
        cb(ok and result or {ok=false,message='Falha de comunicacao. Tente atualizar o painel.'})
    end)
end
callback('refresh',function() return Server.open() end)
callback('purchase',function(data) return Server.purchase(data) end)
callback('setPrice',function(data) return Server.setPrice(data) end)
callback('relocate',function() return Server.relocate() end)
callback('clearLocation',function() return Server.clearLocation() end)
callback('management',function() return Server.management() end)
callback('setItemEnabled',function(data) return Server.setItemEnabled(data) end)
RegisterNetEvent(GetCurrentResourceName()..':location',function(point)
    if point~=false and type(point)~='table' then return end
    updateLocation(point)
    if opened then SendNUIMessage({action='location',data=point}) end
end)
RegisterNetEvent(GetCurrentResourceName()..':catalogChanged',function()
    if opened then SendNUIMessage({action='refresh'}) end
end)
CreateThread(function()
    Wait(1500)
    while true do
        local ok,result=pcall(Server.bootstrap)
        if ok and result and result.ok then
            allowed=result.allowed==true;updateLocation(result.location)
        end
        Wait(30000)
    end
end)
CreateThread(function()
    while true do
        local delay=750
        if allowed and type(location)=='table' then
            local ped=PlayerPedId()
            local p=GetEntityCoords(ped)
            local distance=#(p-vector3(location.x,location.y,location.z))
            if opened and not canManage and (distance>Config.ServerDistance or IsEntityDead(ped)) then close() end
            if not opened and distance<Config.DrawDistance then
                delay=0
                DrawMarker(27,location.x,location.y,location.z-0.95,0.0,0.0,0.0,0.0,0.0,0.0,0.85,0.85,0.85,192,171,124,150,false,false,2,false,nil,nil,false)
                if distance<=Config.InteractionDistance then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('Pressione ~INPUT_CONTEXT~ para acessar o arsenal policial.')
                    EndTextCommandDisplayHelp(0,false,true,-1)
                    if IsControlJustPressed(0,38) then open() end
                end
            end
        end
        Wait(delay)
    end
end)
AddEventHandler('onResourceStop',function(name)
    if name==GetCurrentResourceName() then
        close()
        if arsenalBlip and DoesBlipExist(arsenalBlip) then RemoveBlip(arsenalBlip) end
    end
end)
