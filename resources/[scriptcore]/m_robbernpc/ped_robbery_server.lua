local cfg = Config.PedRobbery
local vRP = module('vrp', 'lib/Proxy').getInterface('vRP')
local event = 'm_robbernpc:pedRobbery:'
local sessions, reserved, robbed, requestTime, untilReport = {}, {}, {}, {}, {}
local sequence = 0

local function resolvePed(src, netId)
    local player = GetPlayerPed(src)
    local ped = NetworkGetEntityFromNetworkId(netId)
    if player == 0 or ped == 0 or not DoesEntityExist(ped) or GetEntityType(ped) ~= 1 then return end
    if GetEntityHealth(player) <= 0 or GetEntityHealth(ped) <= 0 then return end
    local population = GetEntityPopulationType(ped)
    if population < 1 or population > 5 or GetVehiclePedIsIn(ped, false) ~= 0 then return end
    if GetEntityRoutingBucket(player) ~= GetEntityRoutingBucket(ped) then return end
    if #(GetEntityCoords(player) - GetEntityCoords(ped)) > cfg.Distance + 1 then return end
    local weapon = GetSelectedPedWeapon(player)
    if weapon == 0 or weapon == joaat('WEAPON_UNARMED') then return end
    return ped
end

local function release(src, session)
    if sessions[src] ~= session then return end
    sessions[src] = nil
    if reserved[session.ped] == session then reserved[session.ped] = nil end
end

local function reportRobbery(coords, id)
    for _, userId in pairs(vRP.getUsersByPermission(Config.PolicePermission) or {}) do
        local officer = vRP.getUserSource(tonumber(userId))
        if officer then
            TriggerClientEvent('NotifyPush', officer, {
                code = '911',
                title = 'ROUBO A PEDESTRE',
                text = 'Um cidadão pediu socorro após ser assaltado. Verifique o local marcado.',
                x = coords.x, y = coords.y, z = coords.z,
                time = os.date('%H:%M'),
                rgba = {255, 55, 70, 255},
                blipSprite = 161, blipColor = 1, blipScale = 0.85, blipDuration = 60000,
                sound = true,
                dispatchId = 'npc-robbery:' .. id
            })
        end
    end
end

RegisterNetEvent(event .. 'start', function(netId)
    local src = source
    local now = GetGameTimer()
    if type(netId) ~= 'number' or netId % 1 ~= 0 or netId < 1 or netId > 65535 then return end
    if sessions[src] or (requestTime[src] or 0) > now then return end
    requestTime[src] = now + 1500
    local userId = vRP.getUserId(src)
    if not userId then return end
    -- OneSync can take a few frames to register a newly networked ambient ped.
    for attempt = 1, 5 do
        if NetworkGetEntityFromNetworkId(netId) ~= 0 then break end
        Wait(50)
    end
    if sessions[src] or vRP.getUserId(src) ~= userId then return end
    local ped = resolvePed(src, netId)
    if not ped or reserved[ped] or robbed[ped] or Entity(ped).state.robbernpcPedRobbed then
        TriggerClientEvent(event .. 'denied', src, netId)
        return
    end

    sequence = sequence + 1
    local session = {id = sequence, ped = ped, netId = netId, userId = userId, started = GetGameTimer()}
    sessions[src], reserved[ped] = session, session
    TriggerClientEvent(event .. 'accepted', src, netId, session.id)
    SetTimeout(cfg.SessionTimeout, function() release(src, session) end)
end)

RegisterNetEvent(event .. 'cancel', function(id)
    local src = source
    local session = sessions[src]
    if session and session.id == id then release(src, session) end
end)

RegisterNetEvent(event .. 'finish', function(id)
    local src = source
    local session = sessions[src]
    if not session or session.id ~= id or session.finishing then return end
    local elapsed = GetGameTimer() - session.started
    local minimumDuration = cfg.HandsUpTime + cfg.HandsOnHeadTime + cfg.StandUpTime + cfg.HandOverTime
    if elapsed < minimumDuration or elapsed >= cfg.SessionTimeout then return end
    if resolvePed(src, session.netId) ~= session.ped or robbed[session.ped] then
        release(src, session)
        TriggerClientEvent(event .. 'result', src, id, false, false)
        return
    end

    session.finishing = true
    local coords = GetEntityCoords(session.ped)
    robbed[session.ped] = true
    Entity(session.ped).state:set('robbernpcPedRobbed', true, true)
    local loot = math.random(100) <= cfg.CashChance and {
        money = {amount = math.random(cfg.CashMin, cfg.CashMax)}
    } or BuildNPCTrunkLoot()
    local received = false
    for item, entry in pairs(loot or {}) do
        if vRP.giveInventoryItem(session.userId, item, entry.amount, true) then received = true end
    end
    release(src, session)

    local report = false
    if received then
        local remaining = untilReport[session.userId] or math.random(cfg.PoliceIntervalMin, cfg.PoliceIntervalMax)
        remaining = remaining - 1
        report = remaining == 0
        untilReport[session.userId] = report and math.random(cfg.PoliceIntervalMin, cfg.PoliceIntervalMax) or remaining
    end
    TriggerClientEvent(event .. 'result', src, id, received, report)
    if report then SetTimeout(1000, function() reportRobbery(coords, id) end) end
end)

AddEventHandler('entityRemoved', function(entity)
    robbed[entity] = nil
end)

AddEventHandler('playerDropped', function()
    local src = source
    if sessions[src] then release(src, sessions[src]) end
    requestTime[src] = nil
end)
