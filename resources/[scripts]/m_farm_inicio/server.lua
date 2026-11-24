local Proxy=module('vrp','lib/Proxy')
local vRP=Proxy.getInterface('vRP')
local resource=GetCurrentResourceName()
local points, requestTimes, openTimes = {}, {}, {}

local function notify(src,message,kind)
    if src==0 then print('[m_farm_inicio] '..message)
    else TriggerClientEvent('Notify',src,kind or 'aviso',message,8) end
end
local function finite(value)
    value=tonumber(value)
    return value and value==value and math.abs(value)<=50000 and value or nil
end
local function coords(value)
    if type(value)~='table' and type(value)~='vector3' then return nil end
    local x,y,z=finite(value.x or value[1]),finite(value.y or value[2]),finite(value.z or value[3])
    if x and y and z then return {x=x,y=y,z=z} end
end
local function loadPoints()
    local ok,data=pcall(json.decode,LoadResourceFile(resource,'points.json') or '{}')
    if not ok or type(data)~='table' or type(data.points)~='table' then
        print('[m_farm_inicio] points.json invalido. Pontos nao foram carregados.')
        return false
    end
    local result, ids={},{}
    for _,point in ipairs(data.points) do
        if type(point)=='table' and type(point.id)=='string' and point.id:match('^[a-z0-9_]+$') and not ids[point.id]
            and type(point.rewardType)=='string' and type(point.permissions)=='table' then
            local position=coords(point.coords)
            result[#result+1]={id=point.id,label=tostring(point.label or point.id),rewardType=point.rewardType,
                permissions=point.permissions,coords=position,enabled=point.enabled==true and position~=nil}
            ids[point.id]=true
        end
    end
    points=result;return true
end
loadPoints()

local function allowed(userId,point)
    if not userId then return false end
    for _,permission in ipairs(point.permissions) do
        if type(permission)=='string' and vRP.hasPermission(userId,permission) then return true end
    end
    return false
end
local function sendPoints(src)
    local userId=vRP.getUserId(src)
    local isAdmin=userId and vRP.hasPermission(userId,FarmStart.AdminPermission)
    local result={}
    for _,point in ipairs(points) do
        if point.enabled and point.coords and (isAdmin or allowed(userId,point)) then
            result[#result+1]={id=point.id,label=point.label,coords=point.coords}
        end
    end
    TriggerClientEvent('m_farm_inicio:points',src,result)
end
local function broadcast()
    for _,src in ipairs(GetPlayers()) do sendPoints(tonumber(src)) end
end
local function save(updated)
    if not SaveResourceFile(resource,'points.json',json.encode({points=updated}),-1) then return false end
    points=updated;broadcast();return true
end
local function find(id)
    for index,point in ipairs(points) do if point.id==id then return point,index end end
end

RegisterNetEvent('m_farm_inicio:requestPoints',function()
    local src,now=source,GetGameTimer()
    if requestTimes[src] and now-requestTimes[src]<1500 then return end
    requestTimes[src]=now;sendPoints(src)
end)
RegisterNetEvent('m_farm_inicio:open',function(id)
    local src,now=source,GetGameTimer()
    if openTimes[src] and now-openTimes[src]<1000 then return end
    openTimes[src]=now
    local point=type(id)=='string' and find(id) or nil
    if not point or not point.enabled or not point.coords then return end
    local userId=vRP.getUserId(src)
    if not allowed(userId,point) then notify(src,'Voce nao possui acesso a este farm.','negado');return end
    local ped=GetPlayerPed(src)
    if not ped or ped==0 then return end
    local position=GetEntityCoords(ped)
    local dx,dy,dz=position.x-point.coords.x,position.y-point.coords.y,position.z-point.coords.z
    if dx*dx+dy*dy+dz*dz>FarmStart.ServerMaxDistance^2 then return end
    if GetResourceState(FarmStart.FarmResource)~='started' then notify(src,'O sistema de rotas esta indisponivel.','negado');return end
    local ok,result=pcall(function()
        return exports[FarmStart.FarmResource]:openFarmRoutesForPlayer(src,point.rewardType)
    end)
    if not ok then
        print('[m_farm_inicio] Falha ao abrir rota: '..tostring(result))
        notify(src,'Reinicie m_farm para carregar a integracao de rotas.','negado')
    end
end)
AddEventHandler('playerDropped',function()requestTimes[source]=nil;openTimes[source]=nil end)

RegisterCommand(FarmStart.Command,function(src,args)
    local userId=src~=0 and vRP.getUserId(src) or nil
    if not userId or not vRP.hasPermission(userId,FarmStart.AdminPermission) then
        notify(src,'Comando disponivel dentro do jogo para administradores.','negado');return
    end
    local id=tostring(args[1] or ''):lower()
    local aliases={roxo='roxos',verde='verdes'}
    id=aliases[id] or id
    if id=='recarregar' then
        if loadPoints() then broadcast();notify(src,'Pontos de inicio de farm recarregados.','sucesso')
        else notify(src,'points.json invalido. Confira o arquivo.','negado') end
        return
    end
    local point,index=find(id)
    if not point then
        local labels={}
        for _,entry in ipairs(points) do labels[#labels+1]=entry.id..(entry.enabled and ' [ativo]' or ' [sem local]') end
        notify(src,'Use /'..FarmStart.Command..' ID no local desejado. IDs: '..table.concat(labels,', '))
        return
    end
    local updated={};for i,p in ipairs(points) do updated[i]=p end
    local nextPoint={id=point.id,label=point.label,rewardType=point.rewardType,permissions=point.permissions}
    if args[2]=='remover' then nextPoint.enabled=false
    else
        local ped=GetPlayerPed(src)
        if not ped or ped==0 then return end
        nextPoint.coords=coords(GetEntityCoords(ped))
        if not nextPoint.coords then notify(src,'Nao foi possivel obter sua posicao.','negado');return end
        nextPoint.enabled=true
    end
    updated[index]=nextPoint
    if not save(updated) then notify(src,'Nao foi possivel salvar o ponto. Nenhuma mudanca foi aplicada.','negado');return end
    notify(src,nextPoint.enabled and ('Inicio do farm '..point.label..' salvo na sua posicao. Os pontos de coleta foram mantidos.')
        or ('Inicio do farm '..point.label..' desativado.'),'sucesso')
end,false)
