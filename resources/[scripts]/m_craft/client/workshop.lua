local Tunnel = module('vrp','lib/Tunnel')
local Server = Tunnel.getInterface(GetCurrentResourceName())
local Client = {}
Tunnel.bindInterface(GetCurrentResourceName(), Client)
Config = Config or {}; Config.Coords = Config.Coords or {}
local states, permissionCache, pending = {}, {}, {}
local opened, benchIndex, benchName, generation = false, nil, nil, 0
local animation, animationToken = nil, 0
local animDict, animClip = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer'
local function close()
    generation = generation + 1
    opened, benchIndex, benchName = false, nil, nil
    SetNuiFocus(false, false)
    SendNUIMessage({action='opened',data=false})
end

local function stopAnimation()
    animationToken = animationToken + 1
    if animation then StopAnimTask(animation.ped, animDict, animClip, 2.0) end
    animation = nil
end

local function stamp(job)
    if type(job) ~= 'table' then return nil end
    job.syncedAt = GetGameTimer()
    return job
end

local function remaining(job)
    return math.max(0, (tonumber(job.remaining) or 0) - math.floor((GetGameTimer() - (job.syncedAt or GetGameTimer())) / 1000))
end

local function near(index, maxDistance)
    local bench = Config.Coords[index]
    if not bench then return false end
    local position = GetEntityCoords(PlayerPedId())
    for _,coords in ipairs(bench.coords or {}) do
        if #(position - coords) <= maxDistance then return true end
    end
    return false
end

local function startAnimation(index, name, job)
    if type(job) ~= 'table' or job.status ~= 'crafting' then return end
    stopAnimation()
    local token, ped = animationToken, PlayerPedId()
    CreateThread(function()
        RequestAnimDict(animDict)
        local deadline = GetGameTimer() + 3000
        while not HasAnimDictLoaded(animDict) do
            if token ~= animationToken or GetGameTimer() > deadline then return end
            Wait(0)
        end
        if token ~= animationToken or IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) or not near(index, 3.5) then return end
        animation = {ped=ped,name=name,id=job.id}
        local duration = math.max(1,tonumber(job.remaining) or 1)*1000
        deadline = GetGameTimer() + duration
        TaskPlayAnim(ped, animDict, animClip, 3.0, -3.0, duration, 1, 0.0, false, false, false)
        Wait(250)
        while token == animationToken and animation do
            local current = states[name]
            if not current or current.id ~= job.id or current.status == 'ready' or remaining(current) <= 0
                or GetGameTimer() >= deadline or PlayerPedId() ~= ped or IsEntityDead(ped)
                or IsPedInAnyVehicle(ped,false) or not near(index,3.5)
                or not IsEntityPlayingAnim(ped,animDict,animClip,3)
                or (not opened and (IsControlPressed(0,30) or IsControlPressed(0,31))) then
                stopAnimation(); break
            end
            Wait(200)
        end
    end)
end

local function snapshot(index, name)
    local data = Server.getWorkshop(index)
    if type(data) ~= 'table' or data.name ~= name then return false end
    states[name] = stamp(data.job)
    return data
end

RegisterNetEvent('m_craft:configSync',function(payload)
    Config.Coords = type(payload)=='table' and type(payload.coords)=='table' and payload.coords or {}
    permissionCache = {}
    for _,bench in ipairs(Config.Coords) do
        for i,c in ipairs(bench.coords or {}) do
            bench.coords[i] = vector3(tonumber(c.x or c[1]) or 0,tonumber(c.y or c[2]) or 0,tonumber(c.z or c[3]) or 0)
        end
    end
    if opened and (not Config.Coords[benchIndex] or Config.Coords[benchIndex].name ~= benchName) then close() end
end)
RegisterNetEvent('m_craft:stateSync',function(payload)
    states = type(payload)=='table' and payload or {}
    for key,job in pairs(states) do states[key]=stamp(job) end
end)
RegisterNetEvent('m_craft:stateUpdate',function(name,job)
    states[name]=stamp(job)
    if animation and animation.name==name and (not states[name] or states[name].status=='ready') then stopAnimation() end
    if opened and benchName==name then SendNUIMessage({action='craftState',data=job or false}) end
end)

local function route(name, fn)
    RegisterNUICallback(name,function(data,cb)
        if pending[name] then cb({ok=false,message='Aguarde a operacao em andamento.'});return end
        if not opened then cb({ok=false,message='Abra a bancada novamente.'});return end
        local index, orgName, token = benchIndex, benchName, generation
        if type(data)=='table' and data.benchName and data.benchName~=orgName then cb({ok=false,message='A bancada mudou. Abra novamente.'});return end
        pending[name]=true
        local responded=false
        local function reply(result) if not responded then responded=true;cb(result) end end
        SetTimeout(10000,function() reply({ok=false,message='O servidor demorou a responder. Atualize a bancada antes de repetir.'}) end)
        CreateThread(function()
            local ok,result=xpcall(fn,debug.traceback,index,orgName,type(data)=='table' and data or {})
            pending[name]=nil
            if not ok then print('[m_craft] '..tostring(result));reply({ok=false,message='Nao foi possivel concluir. Tente novamente.'});return end
            if token~=generation then reply({ok=false,message='Esta janela ja foi fechada.'});return end
            reply(result)
        end)
    end)
end

RegisterNUICallback('Close',function(_,cb) close();cb({ok=true}) end)
RegisterNUICallback('Ready',function(_,cb)
    cb({ok=true})
    if opened then SendNUIMessage({action='opened',data=true}) end
end)
route('GetWorkshop',function(index,name)
    local data=snapshot(index,name)
    if not data then close();return {ok=false,message='Sem acesso a esta bancada.'} end
    return {ok=true,data=data}
end)
route('ProduceItem',function(index,name,data)
    local ok=Server.produceItem(index,{item={spawn=data.spawn},amount=data.amount})==true
    local state=snapshot(index,name)
    if ok and state then startAnimation(index,name,state.job) end
    return {ok=ok,data=state,message=ok and 'Fabricacao iniciada.' or 'Nao foi possivel fabricar. Confira os materiais, sua permissao e se a bancada esta livre.'}
end)
route('Collect',function(index,name,data)
    local ok=Server.removeItemFromQueue(index,{id=data.id})==true
    return {ok=ok,data=snapshot(index,name),message=ok and 'Producao coletada.' or 'A producao ainda nao esta pronta ou falta espaco na mochila.'}
end)
route('SaveAll',function(index,name)
    local ok=Server.saveAll(index)==true
    return {ok=ok,data=snapshot(index,name),message=ok and 'Materiais disponiveis depositados.' or 'Nao foi possivel depositar materiais.'}
end)
route('SaveItem',function(index,name,data)
    local ok=Server.saveItem(index,{spawn=data.spawn,amount=0})==true
    return {ok=ok,data=snapshot(index,name),message=ok and 'Item depositado no armazem.' or 'Voce nao possui esse material ou nao pode deposita-lo.'}
end)
route('GetRanking',function(index)
    local ranking=Server.getRanking(index)
    return {ok=type(ranking)=='table',ranking=type(ranking)=='table' and ranking or {}}
end)

RegisterCommand('fecharcraft',close,false)
AddEventHandler('onResourceStop',function(resource)
    if resource~=GetCurrentResourceName() then return end
    stopAnimation();SetNuiFocus(false,false)
end)

local function text3d(coords,text)
    local visible,x,y=World3dToScreen2d(coords.x,coords.y,coords.z)
    if not visible then return end
    SetTextScale(.32,.32);SetTextFont(4);SetTextColour(235,243,255,230)
    SetTextCentre(true);SetTextOutline();SetTextEntry('STRING');AddTextComponentString(text);DrawText(x,y)
end
CreateThread(function()
    Wait(500);TriggerServerEvent('m_craft:requestConfig')
    while true do
        local pause=700
        local ped=PlayerPedId();local position=GetEntityCoords(ped)
        if opened then
            pause=250
            if not near(benchIndex,4.0) or IsEntityDead(ped) or IsPedInAnyVehicle(ped,false) then close();stopAnimation() end
        else
            local nearest, distance=nil,3.01
            for index,bench in ipairs(Config.Coords) do
                for _,point in ipairs(bench.coords or {}) do
                    local d=#(position-point)
                    if d<20 then
                        pause=0
                        DrawMarker(27,point.x,point.y,point.z-.95,0,0,0,0,0,0,1.5,1.5,1.5,74,168,255,170,0,0,0,1)
                        if d<distance then nearest,distance=index,d end
                    end
                end
            end
            if nearest and not IsEntityDead(ped) and not IsPedInAnyVehicle(ped,false) then
                local bench=Config.Coords[nearest]
                local cached=permissionCache[nearest]
                if not cached or GetGameTimer()>cached.expires then
                    cached={allowed=Server.hasMinPermission(nearest)==true,expires=GetGameTimer()+4000};permissionCache[nearest]=cached
                end
                if cached.allowed then
                    local point=position+vector3(0,0,.7)
                    for _,p in ipairs(bench.coords) do if #(position-p)<=3 then point=p+vector3(0,0,.6);break end end
                    local job=states[bench.name]
                    local label = '[ E ] Abrir bancada'
                    if job then
                        local left = remaining(job)
                        label = left > 0 and ('Fabricando %sx %s - %ss | [ E ] Acompanhar'):format(job.resultAmount or job.amount,job.name,left) or '[ E ] Producao pronta para coletar'
                    end
                    text3d(point,label)
                    if IsControlJustPressed(0,38) then
                        local data=snapshot(nearest,bench.name)
                        if data then
                            generation=generation+1;benchIndex=nearest;benchName=bench.name;opened=true
                            SetNuiFocus(true,true)
                            SendNUIMessage({action='workshop',data=data})
                            SendNUIMessage({action='opened',data=true})
                        end
                    end
                end
            end
        end
        Wait(pause)
    end
end)

RegisterNetEvent('craft:showBlips',function(orgName)
    local point
    for _,bench in ipairs(Config.Coords) do if bench.name==orgName then point=bench.coords[1];break end end
    if not point then return end
    CreateThread(function()
        local deadline=GetGameTimer()+120000
        while GetGameTimer()<deadline do text3d(point+vector3(0,0,1),'Craft');Wait(0) end
    end)
end)
