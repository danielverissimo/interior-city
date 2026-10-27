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

local function requiredItemsAvailable(user_id,setup)
    for item,data in pairs(setup.itemsNecessarios or {}) do
        local amount = math.max(1,int(data.qtd or 1))
        if int(vRP.getInventoryItemAmount(user_id,item)) < amount then
            return false,item,amount
        end
    end
    return true
end

local function consumeRequiredItems(user_id,setup)
    local removed = {}
    for item,data in pairs(setup.itemsNecessarios or {}) do
        local amount = math.max(1,int(data.qtd or 1))
        if vRP.tryGetInventoryItem(user_id,item,amount,true) then
            removed[#removed + 1] = { item = item, amount = amount }
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

    if activeLocations[session.key] and activeLocations[session.key].user_id == user_id then
        activeLocations[session.key] = nil
    end
    playerSessions[user_id] = nil
    if session.source then sourceSessions[session.source] = nil end

    local source = vRP.getUserSource(user_id)
    if source and reason then
        TriggerClientEvent("m_roubos:forceStop",source,reason)
    end
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
    if activeLocations[key] or startLocks[key] then
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
    local finished = vRPclient.taskBar(source,1000,math.random(7,15))

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

    local stillHasItems,missingItem,missingAmount = requiredItemsAvailable(user_id,setup)
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

    vRPclient._playAnim(source,false,{{"anim@heists@ornate_bank@grab_cash_heels","grab"}},true)
    vCLIENT.iniciandoRoubo(source,location.x,location.y,location.z,duration,location.h)

    local robberyName = tostring(location.type or typeName)
    dispatchPolice(
        "Roubo em andamento",
        "Um roubo foi iniciado em "..robberyName..". Verifique a ocorrência.",
        location.x,location.y,location.z,robberyName
    )

    local identity = vRP.getUserIdentity(user_id) or {}
    -- Resolve private destinations here; Config is also sent to game clients.
    local hook = GetConvar("ic_secret_m_roubos_webhook", GetConvar("interior_city_webhook_logs", ""))
    sendWebhook(hook,"```prolog\n[ID]: "..user_id.." "..tostring(identity.nome or "").." "..tostring(identity.sobrenome or "")..
        "\n[ROUBO]: "..tostring(typeName)..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")

    -- Segurança contra sessão órfã caso o client deixe de responder.
    SetTimeout((duration + 30) * 1000,function()
        local current = playerSessions[user_id]
        if current == session then
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

    if os.time() < session.finishAt then
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

    if activeLocations[session.key] == session then activeLocations[session.key] = nil end
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
    requestCooldown[source] = nil
    local user_id = sourceSessions[source] or vRP.getUserId(source)
    if user_id then clearSession(user_id,nil) end

    for key,owner in pairs(startLocks) do
        if owner == source then startLocks[key] = nil end
    end
end)
