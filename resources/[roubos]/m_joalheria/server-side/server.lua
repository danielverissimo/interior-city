local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")
func2 = Tunnel.getInterface("m_joalheria")

func = {}
Tunnel.bindInterface("m_joalheria",func)

local jewelryStatus = false
local robberyStartedAt = 0
local andamento = false
local roubando = false
local segundos = 0
local activeRobberSource = nil
local activeRobberUser = nil
local dispatchSent = false
local displayTimers = {}
local contagem = 0

local function int(value, fallback)
    local n = tonumber(value)
    if not n then return fallback or 0 end
    return math.floor(n)
end

local function settings()
    return (JConfig and JConfig.settings) or {}
end

local function policePermission()
    local perm = tostring(settings().policePermission or "perm.policia")
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

local function isNear(source,x,y,z,maxDistance)
    local ped = GetPlayerPed(source)
    if not ped or ped <= 0 then return false end
    local coords = GetEntityCoords(ped)
    if not coords then return false end
    local dx,dy,dz = coords.x-x,coords.y-y,coords.z-z
    return (dx*dx + dy*dy + dz*dz) <= ((maxDistance or 3.0)^2)
end

local function getDisplayById(id)
    id = tonumber(id)
    for _,display in ipairs((JConfig and JConfig.displays) or {}) do
        if tonumber(display.id) == id then return display end
    end
end

local function dispatchPolice(x,y,z)
    if dispatchSent then return end
    dispatchSent = true

    local notifyAvailable = GetResourceState("vrp_notifycall") == "started"
    local duration = math.max(15,int(settings().policeBlipSeconds,60)) * 1000

    for _,uid in pairs(policeUsers()) do
        local player = vRP.getUserSource(int(uid))
        if player then
            if notifyAvailable then
                TriggerClientEvent("NotifyPush",player,{
                    code = "911",
                    title = "Roubo à Joalheria",
                    text = "Denúncia de roubo em andamento na joalheria. Suspeitos possivelmente armados no local.",
                    x = x, y = y, z = z,
                    time = os.date("%H:%M"),
                    rgba = {255,48,66,255},
                    blipSprite = 161,
                    blipColor = 1,
                    blipScale = 0.85,
                    blipDuration = duration
                })
            else
                vRPclient.playSound(player,"Oneshot_Final","MP_MISSION_COUNTDOWN_SOUNDSET")
                TriggerClientEvent("chatMessage",player,"911",{255,64,64},"Roubo em andamento na Joalheria. Dirija-se até o local.")
                local blip = vRPclient.addBlip(player,x,y,z,161,1,"Roubo à Joalheria",0.85,false)
                SetTimeout(duration,function()
                    if blip then vRPclient.removeBlip(player,blip) end
                end)
            end
        end
    end
end

function func.jewelryUpdateStatus(status)
    jewelryStatus = status == true
    TriggerClientEvent("jewelry:jewelryFunctionStart",-1,jewelryStatus)
end

-- Apenas valida aqui. O item é consumido de forma atômica ao iniciar o hack,
-- evitando a cobrança duplicada que existia no fluxo original.
function func.jewelryCheckItens()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return false end

    local item = tostring(settings().keycardItem or "keycard")
    local amount = math.max(1,int(settings().keycardAmount,5))
    if int(vRP.getInventoryItemAmount(user_id,item)) >= amount then
        return true
    end

    TriggerClientEvent("Notify",source,"negado","Você precisa de <b>"..amount.."x "..item.."</b> para prosseguir.",5000)
    return false
end

function func.checkJewelry(_,_,_,h,sec,tipo)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return false end

    if roubando or andamento then
        TriggerClientEvent("Notify",source,"negado","A joalheria já possui um roubo em andamento.",5000)
        return false
    end

    local hack = settings().hackCoords or {-631.39,-230.25,38.05}
    local hx,hy,hz = tonumber(hack[1]) or -631.39,tonumber(hack[2]) or -230.25,tonumber(hack[3]) or 38.05
    if not isNear(source,hx,hy,hz,3.0) then return false end

    local minimum = math.max(0,int(settings().policeMinimum,0))
    if countUsers(policeUsers()) < minimum then
        TriggerClientEvent("Notify",source,"negado","Número insuficiente de <b>policiais</b> no momento.",5000)
        return false
    end

    local cooldown = math.max(0,int(settings().robberyCooldown,3600))
    if robberyStartedAt > 0 then
        local remaining = cooldown - (os.time() - robberyStartedAt)
        if remaining > 0 then
            TriggerClientEvent("Notify",source,"negado","A <b>joalheria</b> ainda está se recuperando. Aguarde <b>"..remaining.." segundos</b>.",5000)
            return false
        end
    end

    local item = tostring(settings().keycardItem or "keycard")
    local amount = math.max(1,int(settings().keycardAmount,5))
    if int(vRP.getInventoryItemAmount(user_id,item)) < amount then
        TriggerClientEvent("Notify",source,"negado","Você precisa de <b>"..amount.."x "..item.."</b> para hackear as câmeras.",5000)
        return false
    end

    if not vRP.tryGetInventoryItem(user_id,item,amount,true) then
        TriggerClientEvent("Notify",source,"negado","Não foi possível consumir os itens necessários.",5000)
        return false
    end

    activeRobberSource = source
    activeRobberUser = user_id
    roubando = true
    dispatchSent = false

    vRPclient._playAnim(source,false,{"missheist_jewel@hacking","hack_loop"},true)
    TriggerClientEvent("iniciandojewelry",source,hx,hy,hz,tonumber(h) or 213.52,tonumber(sec) or 10,tonumber(tipo) or 1,true)

    SetTimeout((math.max(1,int(sec,10))) * 1000,function()
        if activeRobberSource == source and roubando and not andamento then
            TriggerClientEvent("iniciandojewelrystart",source)
        end
    end)

    return true
end

RegisterNetEvent("jewelrystart")
AddEventHandler("jewelrystart",function()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id or source ~= activeRobberSource or user_id ~= activeRobberUser or not roubando then return end

    robberyStartedAt = os.time()
    andamento = true
    segundos = math.max(1,int(settings().robberyDuration,600))
    TriggerClientEvent("iniciandojewelry",source,0.0,0.0,0.0,0.0,0,0,false)
end)

function func.callPolice(x,y,z)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return false end

    local center = settings().centerCoords or {-622.18,-230.92,38.05}
    local cx,cy,cz = tonumber(center[1]) or -622.18,tonumber(center[2]) or -230.92,tonumber(center[3]) or 38.05

    if source ~= activeRobberSource and not isNear(source,cx,cy,cz,35.0) then return false end

    local px,py,pz = tonumber(x) or cx,tonumber(y) or cy,tonumber(z) or cz
    dispatchPolice(px,py,pz)
    TriggerClientEvent("sounds:fixed",-1,source,px,py,pz,100,"alarm",0.1)
    TriggerClientEvent("jewelry:bankNews",-1,15)

    -- Se a polícia foi acionada por falha antes de o roubo começar, encerra o estado pendente.
    if not andamento then
        roubando = false
        activeRobberSource = nil
        activeRobberUser = nil
    end
    return true
end

function func.returnJewelry()
    return andamento
end

function func.returnJewelry2()
    return roubando
end

RegisterNetEvent("jewelrysetmodel")
AddEventHandler("jewelrysetmodel",function(x,y,z,prop1,prop2)
    local source = source
    if not andamento then return end
    local ped = GetPlayerPed(source)
    if not ped or ped <= 0 then return end
    TriggerClientEvent("jewelrysetmodel",-1,x,y,z,prop1,prop2)
end)

function func.checkJewels(id,_,_,_,_,_,_,_,_,_,tipo)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id or not andamento then return false end

    local display = getDisplayById(id)
    if not display then return false end
    if not isNear(source,tonumber(display.x) or 0.0,tonumber(display.y) or 0.0,tonumber(display.z) or 0.0,2.2) then return false end

    id = tonumber(id)
    if (displayTimers[id] or 0) > 0 then
        TriggerClientEvent("Notify",source,"negado","O balcão está vazio, aguarde <b>"..int(displayTimers[id]).." segundos</b>.")
        return false
    end

    displayTimers[id] = math.max(1,int(settings().displayCooldown,600))
    TriggerClientEvent("jewelryroubo",source,6,tonumber(tipo) or 2,true,display.x,display.y,display.z,display.prop1,display.prop2,id)
    func2.setCoord(source,display.xplayer,display.yplayer,display.zplayer,display.heading)

    local rewards = (JConfig and JConfig.rewards) or {}
    if #rewards <= 0 then return true end
    local reward = rewards[math.random(#rewards)]
    if not reward or not reward.item then return true end

    local amount = math.random(math.max(1,int(reward.min,1)),math.max(math.max(1,int(reward.min,1)),int(reward.max,3)))
    local delay = (id == 4 or id == 13 or id == 14 or id == 17) and 2000 or 3100

    SetTimeout(delay,function()
        local currentSource = vRP.getUserSource(user_id)
        if currentSource and currentSource == source and andamento and isNear(currentSource,display.x,display.y,display.z,3.0) then
            vRPclient.setStandBY(currentSource,60)
            vRP.giveInventoryItem(user_id,reward.item,amount,true)
        end
    end)

    return true
end

function func.returnJewels(id,x,y,z,prop1,prop2)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return end

    id = tonumber(id)
    if (displayTimers[id] or 0) <= 0 and contagem <= 0 then
        func2.setModel(source,x,y,z,prop1,prop2)
        TriggerEvent("doors:doorsStatistics",tonumber(settings().doorId) or 17,true)
        contagem = math.max(1,int(settings().displayCooldown,600))
    end
end

CreateThread(function()
    while true do
        Wait(1000)

        for id,value in pairs(displayTimers) do
            value = value - 1
            if value <= 0 then displayTimers[id] = nil else displayTimers[id] = value end
        end

        if contagem > 0 then contagem = contagem - 1 end

        if andamento then
            segundos = segundos - 1
            if segundos <= 0 then
                andamento = false
                roubando = false
                jewelryStatus = false
                activeRobberSource = nil
                activeRobberUser = nil
                dispatchSent = false
                TriggerClientEvent("jewelry:jewelryFunctionStart",-1,false)
            end
        end
    end
end)

AddEventHandler("playerDropped",function()
    local source = source
    if source == activeRobberSource then
        if andamento then
            -- O cooldown continua válido se o roubo efetivamente iniciou.
            andamento = false
        end
        roubando = false
        jewelryStatus = false
        activeRobberSource = nil
        activeRobberUser = nil
        dispatchSent = false
        TriggerClientEvent("jewelry:jewelryFunctionStart",-1,false)
    end
end)
