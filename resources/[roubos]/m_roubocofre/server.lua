local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

func = {}
Tunnel.bindInterface("m_roubocofre",func)

local webhookbankrobbery = ""
local timedown = 0
local moneyHeist = {}
local cardAuthorization = {}
local robberyAuthorization = {}
local activeRobbers = {}
local paymentCooldown = {}
local requestCooldown = {}

BankHeists = BankHeists or {}

local function int(value, fallback)
    local n = tonumber(value)
    if not n then return fallback or 0 end
    return math.floor(n)
end

local function sendWebhook(webhook,message)
    if type(webhook) ~= "string" or webhook == "" or webhook == "yourlink" then return end
    PerformHttpRequest(webhook,function() end,"POST",json.encode({content = message}),{["Content-Type"]="application/json"})
end

local function policePermission()
    local perm = tostring(RobConfig.policePermission or "perm.policia")
    if perm == "policia.permissao" then perm = "perm.policia" end
    return perm
end

local function policeUsers()
    return vRP.getUsersByPermission(policePermission()) or {}
end

local function countUsers(list)
    local amount = 0
    for _ in pairs(list or {}) do amount = amount + 1 end
    return amount
end

local function bankData(bankId)
    local banks = (RoubocofreData and RoubocofreData.banks) or {}
    return banks[tostring(bankId)]
end

local function isNear(source,x,y,z,maxDistance)
    local ped = GetPlayerPed(source)
    if not ped or ped <= 0 then return false end
    local coords = GetEntityCoords(ped)
    if not coords then return false end
    local dx,dy,dz = coords.x-x,coords.y-y,coords.z-z
    return (dx*dx + dy*dy + dz*dz) <= ((maxDistance or 3.0)^2)
end

local function isNearAnyStart(source,maxDistance)
    for _,bank in pairs((RoubocofreData and RoubocofreData.banks) or {}) do
        local pos = bank.startRobbing or {}
        if isNear(source,tonumber(pos.x) or 0.0,tonumber(pos.y) or 0.0,tonumber(pos.z) or 0.0,maxDistance or 3.0) then
            return true
        end
    end
    return false
end

local function dispatchPolice(bankId,x,y,z)
    local notifyAvailable = GetResourceState("vrp_notifycall") == "started"
    local duration = math.max(15000,int(RobConfig.policeBlipMilliseconds,200000))

    for _,uid in pairs(policeUsers()) do
        local player = vRP.getUserSource(int(uid))
        if player then
            if notifyAvailable then
                TriggerClientEvent("NotifyPush",player,{
                    code = "911",
                    title = "Roubo a Cofre Bancário",
                    text = "Um roubo foi iniciado em "..tostring(bankId)..". Suspeitos estão tentando acessar o cofre.",
                    x = x, y = y, z = z,
                    time = os.date("%H:%M"),
                    rgba = {255,48,66,255},
                    blipSprite = 161,
                    blipColor = 1,
                    blipScale = 0.85,
                    blipDuration = duration
                })
            else
                vRPclient._playSound(player,"CONFIRM_BEEP","HUD_MINI_GAME_SOUNDSET")
                TriggerClientEvent("chatMessage",player,"911",{255,64,64},"Roubo iniciado em "..tostring(bankId)..". Dirija-se ao local.")
                TriggerClientEvent("blip:criar:banco",player,x,y,z,bankId)
                SetTimeout(duration,function()
                    TriggerClientEvent("blip:remover:banco",player)
                end)
            end
        end
    end
end

function func.StartBankRobbery(bankId)
    local source = source
    local user_id = vRP.getUserId(source)
    local auth = robberyAuthorization[source]
    local bank = bankData(bankId)
    if not user_id or not bank or not auth or auth.bankId ~= tostring(bankId) or auth.expires < os.time() then return false end

    local start = bank.startRobbing or {}
    if not isNear(source,tonumber(start.x) or 0.0,tonumber(start.y) or 0.0,tonumber(start.z) or 0.0,8.0) then return false end

    robberyAuthorization[source] = nil
    activeRobbers[source] = tostring(bankId)

    TriggerClientEvent("bankrobbery:openDoor",-1,bankId)
    -- Somente o assaltante inicia a lógica de coleta; o código antigo iniciava em todos os clientes.
    TriggerClientEvent("bankrobbery:startRobbery",source,bankId)
    TriggerClientEvent("vrp_sound:source",source,"bankdoor",0.5)
    return true
end

function func.EndBankRobbery(bankId)
    local source = source
    if activeRobbers[source] == tostring(bankId) then
        activeRobbers[source] = nil
        TriggerClientEvent("bankrobbery:endRobbery",source,bankId)
        return true
    end
    return false
end

-- Mantido por compatibilidade com o client, mas não zera mais o total roubado do banco.
-- Isso impedia um exploit onde bastava se afastar para resetar o dinheiro disponível.
function func.ResetMoney(bankId)
    local source = source
    if activeRobbers[source] == tostring(bankId) then
        activeRobbers[source] = nil
        TriggerClientEvent("bankrobbery:endRobbery",source,bankId)
    end
    return true
end

function func.CheckPayment(bankId)
    local source = source
    local user_id = vRP.getUserId(source)
    bankId = tostring(bankId)
    local bank = bankData(bankId)
    if not user_id or not bank or activeRobbers[source] ~= bankId then return false end

    local cash = bank.cashPile or {}
    if not isNear(source,tonumber(cash.x) or 0.0,tonumber(cash.y) or 0.0,tonumber(cash.z) or 0.0,8.0) then return false end

    local now = GetGameTimer()
    if paymentCooldown[source] and now - paymentCooldown[source] < math.max(1000,int(RobConfig.cashAnimationMilliseconds,7500)-500) then
        return false
    end
    paymentCooldown[source] = now

    local limit = int(bank.money,0)
    local taken = int(moneyHeist[bankId],0)
    local remaining = math.max(0,limit-taken)
    if remaining <= 0 then
        TriggerClientEvent("bankrobbery:deleteEntity",source)
        activeRobbers[source] = nil
        return false
    end

    local minReward = math.max(1,int(RobConfig.rewardMin,10000))
    local maxReward = math.max(minReward,int(RobConfig.rewardMax,20000))
    local received = math.min(remaining,math.random(minReward,maxReward))

    moneyHeist[bankId] = taken + received
    vRP.giveInventoryItem(user_id,RobConfig.rewardItem or "dinheirosujo",received,true)
    TriggerClientEvent("Notify",source,"sucesso","Recebeu <b>$"..vRP.format(received).." dólares sujos</b>.")

    if moneyHeist[bankId] >= limit then
        TriggerClientEvent("bankrobbery:deleteEntity",source)
        activeRobbers[source] = nil
    end
    return true
end

function func.CheckPolice()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id or not isNearAnyStart(source,3.0) then return false end

    local nowMs = GetGameTimer()
    if requestCooldown[source] and nowMs-requestCooldown[source] < 750 then return false end
    requestCooldown[source] = nowMs

    local minimum = math.max(0,int(RobConfig.policeMinimum,0))
    if countUsers(policeUsers()) < minimum then
        TriggerClientEvent("Notify",source,"aviso","Número insuficiente de policiais no momento.",8000)
        return false
    end

    local cooldown = math.max(0,int(RobConfig.cooldownSeconds,1800))
    if timedown > 0 then
        local remaining = cooldown - (os.time()-timedown)
        if remaining > 0 then
            TriggerClientEvent("Notify",source,"aviso","Os cofres estão vazios. Aguarde <b>"..remaining.." segundos</b>.",8000)
            return false
        end
    end
    return true
end

function func.CheckRobbery(bankId)
    local source = source
    local user_id = vRP.getUserId(source)
    bankId = tostring(bankId)
    local bank = bankData(bankId)
    local auth = cardAuthorization[source]
    if not user_id or not bank or not auth or auth.expires < os.time() then return false end

    local start = bank.startRobbing or {}
    if not isNear(source,tonumber(start.x) or 0.0,tonumber(start.y) or 0.0,tonumber(start.z) or 0.0,3.0) then return false end

    local minimum = math.max(0,int(RobConfig.policeMinimum,0))
    if countUsers(policeUsers()) < minimum then return false end

    local cooldown = math.max(0,int(RobConfig.cooldownSeconds,1800))
    if timedown > 0 and (os.time()-timedown) < cooldown then return false end

    local item = tostring(auth.item or RobConfig.keycardItem or "keycard")
    local amount = math.max(1,int(auth.amount,RobConfig.keycardAmount or 1))
    if int(vRP.getInventoryItemAmount(user_id,item)) < amount or not vRP.tryGetInventoryItem(user_id,item,amount,true) then
        cardAuthorization[source] = nil
        TriggerClientEvent("Notify",source,"negado","Não foi possível consumir o cartão necessário.")
        return false
    end

    cardAuthorization[source] = nil
    timedown = os.time()
    moneyHeist[bankId] = 0
    robberyAuthorization[source] = {bankId=bankId,expires=os.time()+math.max(90,int(RobConfig.hackSeconds,60)+30)}

    local identity = vRP.getUserIdentity(user_id) or {}
    sendWebhook(RobConfig.webhook or webhookbankrobbery,"```prolog\n[ID]: "..user_id.." "..tostring(identity.nome or "").." "..tostring(identity.sobrenome or "").."\n[BANCO]: "..bankId..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")

    vRP.searchTimer(user_id,int(RobConfig.searchTimerSeconds,600))
    TriggerClientEvent("vrp_sound:source",source,"alarm",0.2)
    dispatchPolice(bankId,tonumber(start.x) or 0.0,tonumber(start.y) or 0.0,tonumber(start.z) or 0.0)
    return true
end

function func.KeyCard()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id or not isNearAnyStart(source,3.0) then return false end

    local item = tostring(RobConfig.keycardItem or "keycard")
    local amount = math.max(1,int(RobConfig.keycardAmount,1))
    if int(vRP.getInventoryItemAmount(user_id,item)) < amount then
        TriggerClientEvent("Notify",source,"negado","Você não possui <b>"..amount.."x "..item.."</b>.")
        return false
    end

    cardAuthorization[source] = {expires=os.time()+20,item=item,amount=amount}
    return true
end

CreateThread(function()
    local lastDropSecond = ""
    while true do
        Wait(1000)
        local now = os.date("%H:%M:%S")
        if now ~= lastDropSecond then
            for _,dropTime in ipairs(RobConfig.dropTimes or {}) do
                if now == dropTime and #(RobConfig.dropSpawns or {}) > 0 then
                    lastDropSecond = now
                    local pos = RobConfig.dropSpawns[math.random(#RobConfig.dropSpawns)]
                    TriggerEvent("DropSystem:create",RobConfig.dropItem or "keycard",int(RobConfig.dropAmount,1),pos[1],pos[2],pos[3],int(RobConfig.dropLifetimeSeconds,3600))
                    break
                end
            end
        end
    end
end)

AddEventHandler("playerDropped",function()
    local source = source
    cardAuthorization[source] = nil
    robberyAuthorization[source] = nil
    activeRobbers[source] = nil
    paymentCooldown[source] = nil
    requestCooldown[source] = nil
end)
