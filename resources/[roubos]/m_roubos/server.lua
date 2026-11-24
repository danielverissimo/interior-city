local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

sRP = {}
Tunnel.bindInterface("m_roubos",sRP)
vCLIENT = Tunnel.getInterface("m_roubos")

local ultimoAssaltoHora = {}
local activeLocations = {}
local playerSessions = {}
local sourceSessions = {}
local startLocks = {}
local requestCooldown = {}
local atmCharges = {}
local atmSyncRequests = {}
local publishAtm

local function int(value)
    return math.floor(tonumber(value) or 0)
end

local function notify(source,kind,message)
    TriggerClientEvent("Notify",source,kind,message)
end

local function sendWebhook(url,message)
    if type(url) ~= "string" or url == "" then return end
    PerformHttpRequest(url,function() end,"POST",json.encode({ content = message }),{ ["Content-Type"] = "application/json" })
end

local function getLocation(typeName,id)
    for _,v in ipairs(Config.roubos or {}) do
        if tostring(v.type) == tostring(typeName) and tonumber(v.id) == tonumber(id) then
            return v
        end
    end
end

local function locationKey(typeName,id)
    return tostring(typeName)..":"..tostring(id)
end

local function remaining(typeName,id,waitMinutes)
    local last = ultimoAssaltoHora[locationKey(typeName,id)]
    if not last then return 0 end
    local wait = math.max(0,tonumber(waitMinutes) or 0) * 60
    return math.max(0,math.ceil(wait - (os.time() - last)))
end

local function hasBlockedPermission(user_id)
    for _,perm in ipairs((Config.settings and Config.settings.blockedPermissions) or {}) do
        if type(perm) == "string" and perm ~= "" and vRP.hasPermission(user_id,perm) then
            return true
        end
    end
    return false
end

local function policeUsers()
    local permission = (Config.settings and Config.settings.policePermission) or "perm.policia"
    return vRP.getUsersByPermission(permission) or {}
end

local function policeCount(users)
    local count = 0
    for _ in pairs(users or {}) do count = count + 1 end
    return count
end

local function isNear(source,x,y,z,maxDistance)
    local ped = GetPlayerPed(source)
    if not ped or ped <= 0 then return false end
    local coords = GetEntityCoords(ped)
    if not coords then return false end
    local dx,dy,dz = coords.x - x,coords.y - y,coords.z - z
    return (dx*dx + dy*dy + dz*dz) <= ((maxDistance or 3.0) ^ 2)
end

local function requiredItemsAvailable(user_id,setup,lockpickUsed)
    for item,data in pairs(setup.itemsNecessarios or {}) do
        local amount = math.max(1,int(data.qtd or 1))
        if not (lockpickUsed and item == "lockpick") and int(vRP.getInventoryItemAmount(user_id,item)) < amount then
            return false,item,amount
        end
    end
    return true
end

local function consumeRequiredItems(user_id,setup)
    local removed = {}
    for item,data in pairs(setup.itemsNecessarios or {}) do
        local amount = math.max(1,int(data.qtd or 1))
        local consumed
        if item == "lockpick" then
            consumed = true -- Desgaste aplicado no inicio da tentativa.
        else
            consumed = vRP.tryGetInventoryItem(user_id,item,amount,true)
        end
        if consumed then
            if item ~= "lockpick" then
                removed[#removed + 1] = { item = item, amount = amount }
            end
        else
            -- Rollback caso o inventário tenha mudado durante a taskbar.
            for _,entry in ipairs(removed) do
                vRP.giveInventoryItem(user_id,entry.item,entry.amount,true)
            end
            return false,item,amount
        end
    end
    return true
end

local function clearSession(user_id,reason)
    local session = playerSessions[user_id]
    if not session then return end

    if session.isAtm and atmCharges[session.key] == session then
        if session.phase == 'planting' then
            session.phase = 'cancelled'
            atmCharges[session.key] = nil
            activeLocations[session.key] = nil
            if publishAtm then publishAtm(session) end
        elseif session.phase == 'looting' then
            session.phase = 'exploded'
            session.finishAt = nil
            if publishAtm then publishAtm(session) end
        end
    elseif activeLocations[session.key] and activeLocations[session.key].user_id == user_id then
        activeLocations[session.key] = nil
    end
    playerSessions[user_id] = nil
    if session.source then sourceSessions[session.source] = nil end

    local source = vRP.getUserSource(user_id)
    if source and reason then
        TriggerClientEvent("m_roubos:forceStop",source,reason)
    end
end

publishAtm = function(session, target, explosionPlayer)
    TriggerClientEvent('m_roubos:atmState',target or -1,{
        key=session.key, phase=session.phase, location=session.location,
        seconds=session.phase=='armed' and math.max(0,math.ceil(((session.explodeAt or GetGameTimer())-GetGameTimer())/1000)) or 0,
        explosionPlayer=explosionPlayer
    })
end

RegisterNetEvent('m_roubos:requestAtmState',function()
    local now=GetGameTimer()
    if atmSyncRequests[source] and now-atmSyncRequests[source]<2000 then return end
    atmSyncRequests[source]=now
    for _,session in pairs(atmCharges) do publishAtm(session,source) end
end)

local function startAtmCharge(session, heading)
    session.isAtm, session.phase = true, 'planting'
    session.heading = tonumber(heading) or 0
    atmCharges[session.key] = session
    publishAtm(session)
    TriggerClientEvent('m_roubos:plantAtm',session.source,session.key,session.location,session.heading,Config.AtmC4.plantSeconds)
    SetTimeout(Config.AtmC4.plantSeconds*1000,function()
        if atmCharges[session.key] ~= session or session.phase ~= 'planting' then return end
        local ped = GetPlayerPed(session.source)
        if not ped or ped==0 or GetEntityHealth(ped)<=100 or
            not isNear(session.source,session.location.x,session.location.y,session.location.z,3.0) then
            clearSession(session.user_id,'Instalacao da C4 interrompida.')
            return
        end
        session.phase = 'armed'
        session.explodeAt=GetGameTimer()+Config.AtmC4.fuseSeconds*1000
        publishAtm(session)
        notify(session.source,'importante','C4 armada! Afaste-se: o caixa vai explodir em 10 segundos.')
        SetTimeout(Config.AtmC4.fuseSeconds*1000,function()
            if atmCharges[session.key] ~= session or session.phase ~= 'armed' then return end
            session.phase = 'exploded'
            session.lootExpiresAt=os.time()+Config.AtmC4.lootWindowSeconds
            if playerSessions[session.user_id]==session then clearSession(session.user_id,nil) end
            -- So um client cria a explosao de rede, evitando explosoes duplicadas.
            local executor, distance = nil, 200.0
            for _,player in ipairs(GetPlayers()) do
                player = tonumber(player)
                local entity = GetPlayerPed(player)
                if entity and entity~=0 then
                    local c=GetEntityCoords(entity)
                    local l=session.location
                    local d=math.sqrt((c.x-l.x)^2+(c.y-l.y)^2+(c.z-l.z)^2)
                    if d<distance then executor,distance=player,d end
                end
            end
            publishAtm(session,nil,executor)
            SetTimeout(Config.AtmC4.lootWindowSeconds*1000,function()
                if atmCharges[session.key]~=session or session.phase~='exploded' then return end
                if playerSessions[session.user_id]==session then clearSession(session.user_id,'O tempo de coleta deste caixa terminou.') end
                session.phase='empty'
                publishAtm(session)
            end)
        end)
    end)
    local restoreSeconds = math.max(60,tonumber(session.setup.tempoEspera or 5)*60,
        Config.AtmC4.plantSeconds+Config.AtmC4.fuseSeconds+Config.AtmC4.lootWindowSeconds+session.duration+5)
    SetTimeout(restoreSeconds*1000,function()
        if atmCharges[session.key]~=session then return end
        if playerSessions[session.user_id]==session then clearSession(session.user_id,'O caixa foi restaurado.') end
        atmCharges[session.key]=nil
        if activeLocations[session.key]==session then activeLocations[session.key]=nil end
        session.phase='restored'
        publishAtm(session)
    end)
end

function sRP.collectAtm(key)
    local player=source
    local userId=vRP.getUserId(player)
    local session=type(key)=='string' and atmCharges[key] or nil
    if not userId or not session or session.phase~='exploded' or os.time()>=(session.lootExpiresAt or 0) then return false end
    if playerSessions[userId] and playerSessions[userId]~=session then return false end
    local l=session.location
    local ped=GetPlayerPed(player)
    if not ped or ped==0 or GetEntityHealth(ped)<=100 or not isNear(player,l.x,l.y,l.z,2.5) then return false end
    local oldUser,oldSource=session.user_id,session.source
    if playerSessions[oldUser]==session then playerSessions[oldUser]=nil end
    if sourceSessions[oldSource]==oldUser then sourceSessions[oldSource]=nil end
    session.user_id,session.source,session.phase=userId,player,'looting'
    session.finishAt=os.time()+session.duration
    session.finishAtMs=GetGameTimer()+session.duration*1000
    playerSessions[userId],sourceSessions[player],activeLocations[key]=session,userId,session
    publishAtm(session)
    vRPclient._playAnim(player,false,{{'anim@heists@ornate_bank@grab_cash_heels','grab'}},true)
    vCLIENT.iniciandoRoubo(player,l.x,l.y,l.z,session.duration,session.heading)
    SetTimeout((session.duration+30)*1000,function()
        if atmCharges[key]==session and session.phase=='looting' and session.user_id==userId then
            clearSession(userId,'Coleta do caixa encerrada por tempo excedido.')
            if os.time()>=(session.lootExpiresAt or 0) then session.phase='empty';publishAtm(session) end
        end
    end)
    return true
end

-- Mensagens do vrp_notifycall por tipo, adaptadas dos módulos corrigidos
-- de mercados/Ammu-Nation/ATM. Não modifica o funcionamento do roubo.
local function qruForRobbery(typeName)
    local kind = tostring(typeName or ""):lower()
    if kind == "caixa" then
        return "ROUBO A CAIXA ELETRÔNICO", "Roubo em andamento em um caixa eletrônico. Verifique a ocorrência."
    elseif kind == "ammunition" or kind == "ammunation" then
        return "ROUBO À AMMU-NATION", "Assalto em andamento em uma Ammu-Nation. Verifique a ocorrência."
    elseif kind == "registradora" then
        return "ROUBO A MERCADO", "Assalto em andamento em um mercado. Verifique a ocorrência."
    elseif kind == "loja de departamento" then
        return "ROUBO A LOJA DE DEPARTAMENTO", "Roubo em andamento em uma loja de departamento. Verifique a ocorrência."
    elseif kind == "bebidas" then
        return "ROUBO A COMÉRCIO", "Roubo em andamento em um comércio. Verifique a ocorrência."
    end
    return "ROUBO EM ANDAMENTO", "Roubo em andamento: "..tostring(typeName or "Comércio")..". Verifique a ocorrência."
end

local function dispatchPolice(title,text,x,y,z,robberyName)
    local users = policeUsers()
    local notifyCfg = Config.NotifyCall or {}
    local callEnabled = notifyCfg.enabled ~= false and GetResourceState("vrp_notifycall") == "started"
    local blipSeconds = math.max(1,int((Config.settings and Config.settings.policeBlipSeconds) or 45))

    for _,uid in pairs(users) do
        local player = vRP.getUserSource(int(uid))
        if player then
            if callEnabled then
                TriggerClientEvent(notifyCfg.event or "NotifyPush",player,{
                    code = notifyCfg.code or "911",
                    title = title,
                    text = text,
                    x = x,
                    y = y,
                    z = z,
                    time = os.date("%H:%M"),
                    rgba = notifyCfg.rgba or { 255,48,66,255 },
                    blipSprite = notifyCfg.blipSprite or 161,
                    blipColor = notifyCfg.blipColor or 1,
                    blipScale = notifyCfg.blipScale or 0.85,
                    blipDuration = blipSeconds * 1000
                })
            else
                -- Fallback para não perder o chamado se notifycall estiver desligado.
                TriggerClientEvent("blip:criar:roubo",player,x,y,z)
                vRPclient.playSound(player,"Oneshot_Final","MP_MISSION_COUNTDOWN_SOUNDSET")
                TriggerClientEvent("chatMessage",player,"911",{255,64,64},text)
                SetTimeout(blipSeconds * 1000,function()
                    TriggerClientEvent("blip:remover:roubo",player)
                end)
            end
        end
    end
end

function sRP.startRobbery(typeName,id)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return false end

    local nowMs = GetGameTimer()
    if requestCooldown[source] and nowMs - requestCooldown[source] < 1200 then return false end
    requestCooldown[source] = nowMs

    if playerSessions[user_id] then
        notify(source,"negado","Você já possui um roubo em andamento.")
        return false
    end

    local location = getLocation(typeName,id)
    local setup = Config.setup and Config.setup[typeName]
    if not location or not setup then
        notify(source,"negado","Configuração deste roubo não foi encontrada.")
        return false
    end

    if not isNear(source,location.x,location.y,location.z,3.0) then
        return false
    end

    local key = locationKey(typeName,id)
    if activeLocations[key] or startLocks[key] or atmCharges[key] then
        notify(source,"negado","Este local já está sendo roubado por outra pessoa.")
        return false
    end

    local police = policeUsers()
    local requiredPolice = math.max(0,int(setup.lspd))
    if policeCount(police) < requiredPolice then
        notify(source,"negado","Necessários <b>"..requiredPolice.." policiais</b> para iniciar o roubo.")
        return false
    end

    if hasBlockedPermission(user_id) then
        notify(source,"importante","Você não pode iniciar este roubo.")
        return false
    end

    local wait = remaining(typeName,id,setup.tempoEspera)
    if wait > 0 then
        notify(source,"importante","Aguarde <b>"..wait.." segundos</b> para roubar este local novamente.")
        return false
    end

    local hasItems,item,amount = requiredItemsAvailable(user_id,setup)
    if not hasItems then
        notify(source,"negado","Você precisa de <b>"..amount.."x "..tostring(item).."</b> para prosseguir.")
        return false
    end

    startLocks[key] = source
    if (setup.itemsNecessarios or {}).lockpick and not vRP.useLockpick(user_id) then
        startLocks[key] = nil
        return false
    end
    local finished = typeName=='caixa' or vRPclient.taskBar(source,1000,math.random(7,15))

    if startLocks[key] == source then startLocks[key] = nil end
    if not finished then
        notify(source,"importante","Você errou, tente novamente!")
        return false
    end

    -- Revalida tudo que pode ter mudado enquanto a taskbar estava aberta.
    if not isNear(source,location.x,location.y,location.z,3.0) or activeLocations[key] or playerSessions[user_id] then
        notify(source,"negado","Não foi possível iniciar o roubo.")
        return false
    end

    local stillHasItems,missingItem,missingAmount = requiredItemsAvailable(user_id,setup,true)
    if not stillHasItems then
        notify(source,"negado","Você precisa de <b>"..missingAmount.."x "..tostring(missingItem).."</b> para prosseguir.")
        return false
    end

    local consumed,failedItem,failedAmount = consumeRequiredItems(user_id,setup)
    if not consumed then
        notify(source,"negado","Não foi possível consumir <b>"..failedAmount.."x "..tostring(failedItem).."</b>.")
        return false
    end

    local duration = math.max(1,int(setup.tempo))
    local session = {
        key = key,
        user_id = user_id,
        source = source,
        typeName = typeName,
        id = tonumber(id),
        startedAt = os.time(),
        finishAt = os.time() + math.max(0,duration - 1),
        duration = duration,
        location = { x = location.x, y = location.y, z = location.z },
        setup = setup
    }

    ultimoAssaltoHora[key] = os.time()
    activeLocations[key] = session
    playerSessions[user_id] = session
    sourceSessions[source] = user_id

    if typeName=='caixa' then
        startAtmCharge(session,location.h)
    else
        vRPclient._playAnim(source,false,{{"anim@heists@ornate_bank@grab_cash_heels","grab"}},true)
        vCLIENT.iniciandoRoubo(source,location.x,location.y,location.z,duration,location.h)
    end

    local robberyName = tostring(location.type or typeName)
    local qruTitle,qruText = qruForRobbery(robberyName)
    dispatchPolice(qruTitle,qruText,location.x,location.y,location.z,robberyName)

    local identity = vRP.getUserIdentity(user_id) or {}
    local hook = Config.webhooks and Config.webhooks[typeName] or ""
    sendWebhook(hook,"```prolog\n[ID]: "..user_id.." "..tostring(identity.nome or "").." "..tostring(identity.sobrenome or "")..
        "\n[ROUBO]: "..tostring(typeName)..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")

    -- Segurança contra sessão órfã caso o client deixe de responder.
    SetTimeout((duration + 30) * 1000,function()
        local current = playerSessions[user_id]
        if current == session and not session.isAtm then
            clearSession(user_id,"O roubo foi encerrado por tempo excedido.")
        end
    end)

    return true
end

function sRP.givePayment()
    local source = source
    local user_id = vRP.getUserId(source)
    local session = user_id and playerSessions[user_id]
    if not session or session.source ~= source then return false end

    if session.isAtm and session.phase~='looting' then return false end
    if session.isAtm and GetGameTimer()<(session.finishAtMs or math.huge) then return false end
    if not session.finishAt or os.time() < session.finishAt then
        return false
    end

    if not isNear(source,session.location.x,session.location.y,session.location.z,7.0) then
        clearSession(user_id,"Você se afastou demais e perdeu o roubo.")
        return false
    end

    local ped = GetPlayerPed(source)
    if ped <= 0 or GetEntityHealth(ped) <= 100 then
        clearSession(user_id,nil)
        return false
    end

    for item,data in pairs(session.setup.items or {}) do
        local min = math.max(0,int(data.min))
        local max = math.max(min,int(data.max))
        local amount = math.random(min,max)
        if amount > 0 then
            vRP.giveInventoryItem(user_id,item,amount,true)
        end
    end

    if session.isAtm then
        session.phase='empty'
        publishAtm(session)
    elseif activeLocations[session.key] == session then activeLocations[session.key] = nil end
    playerSessions[user_id] = nil
    sourceSessions[source] = nil
    return true
end

function sRP.cancelRobbery()
    local source = source
    local user_id = vRP.getUserId(source)
    local session = user_id and playerSessions[user_id]
    if not session or session.source ~= source then return false end

    -- Cancelar não gera recompensa parcial; evita farm/exploit de cancelamento.
    clearSession(user_id,nil)
    return true
end

AddEventHandler("playerDropped",function()
    local source = source
    atmSyncRequests[source]=nil
    requestCooldown[source] = nil
    local user_id = sourceSessions[source] or vRP.getUserId(source)
    if user_id then clearSession(user_id,nil) end

    for key,owner in pairs(startLocks) do
        if owner == source then startLocks[key] = nil end
    end
end)


-----------------------------------------------------------------------------------------------------------------------------------------
-- QRU DE DISPARO - VALIDACAO E DISPATCH EXCLUSIVAMENTE NO SERVIDOR
-----------------------------------------------------------------------------------------------------------------------------------------
local nextGunshotAlert = {}

RegisterNetEvent("m_roubos:reportGunshot")
AddEventHandler("m_roubos:reportGunshot",function()
    local source = source
    local cfg = Config.GunshotQRU or {}
    if cfg.enabled == false then return end

    local user_id = vRP.getUserId(source)
    if not user_id then return end

    -- Disparos de policiais nao geram QRU. Consulta no servidor, nunca no cliente.
    local policePermission = (Config.settings and Config.settings.policePermission) or "perm.policia"
    if vRP.hasPermission(user_id,policePermission) then return end

    local ped = GetPlayerPed(source)
    if not ped or ped <= 0 or GetEntityHealth(ped) <= 100 then return end

    local now = os.time()
    local cooldown = math.max(1,math.floor(tonumber(cfg.cooldownSeconds) or 25))
    if nextGunshotAlert[user_id] and now < nextGunshotAlert[user_id] then return end

    -- Posicao obtida no servidor para nao aceitar coordenadas arbitrarias enviadas por clientes.
    local coords = GetEntityCoords(ped)
    if not coords then return end
    local x,y,z = tonumber(coords.x),tonumber(coords.y),tonumber(coords.z)
    if not x or not y or not z then return end

    nextGunshotAlert[user_id] = now + cooldown
    dispatchPolice(
        cfg.title or "QRU de Disparo",
        cfg.text or "Disparos de arma de fogo foram registrados nesta localizacao. Verifique a ocorrencia.",
        x,y,z,"Disparo"
    )
end)
