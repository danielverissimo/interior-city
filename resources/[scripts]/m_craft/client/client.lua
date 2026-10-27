
Config = Config or {}
Config.Coords = Config.Coords or {}

local function craftVec3(c)
    if type(c) ~= 'table' then return vec3(0.0,0.0,0.0) end
    return vec3(tonumber(c.x or c[1]) or 0.0, tonumber(c.y or c[2]) or 0.0, tonumber(c.z or c[3]) or 0.0)
end

RegisterNetEvent('m_craft:configSync', function(payload)
    Config.Coords = (payload and payload.coords) or {}
    for _,bench in ipairs(Config.Coords) do
        for i,c in ipairs(bench.coords or {}) do bench.coords[i] = craftVec3(c) end
    end
end)

CreateThread(function()
    Wait(500)
    TriggerServerEvent('m_craft:requestConfig')
end)

local Tunnel = module('vrp','lib/Tunnel')
local Proxy = module('vrp','lib/Proxy')
local vRP = Proxy.getInterface('vRP')
vRP = Proxy.getInterface('vRP')

ClientAPI = {}
Tunnel.bindInterface(GetCurrentResourceName(), ClientAPI)
ServerAPI = Tunnel.getInterface(GetCurrentResourceName())

local craftStates = {}
local permissionCache = {}
local collectingBench = false

local isMenuOpen = false
local blipIdOpen = nil
local MIN_DISTANCE = 3.0

local pendingCallbacks = {}

-- Ensure we can return a true empty JSON array ([]) to NUI
local EMPTY_ARRAY = (json and json.decode('[]')) or {}

local function stampState(state)
    if type(state) ~= 'table' then return nil end
    state._syncedAt = GetGameTimer()
    state.remaining = math.max(0, tonumber(state.remaining) or 0)
    return state
end

RegisterNetEvent('m_craft:stateSync', function(states)
    craftStates = type(states) == 'table' and states or {}
    for key,state in pairs(craftStates) do
        craftStates[key] = stampState(state)
    end
end)

RegisterNetEvent('m_craft:stateUpdate', function(benchKey, state)
    if not benchKey then return end
    if type(state) == 'table' then
        craftStates[benchKey] = stampState(state)
    else
        craftStates[benchKey] = nil
        if isMenuOpen and blipIdOpen and Config.Coords[blipIdOpen] and Config.Coords[blipIdOpen].name == benchKey then
            SendNUIMessage({ action = 'updateQueue', data = EMPTY_ARRAY })
        end
    end
end)

RegisterNetEvent('m_craft:benchStarted', function(benchKey, starterSource)
    if not isMenuOpen or not blipIdOpen then return end
    local bench = Config.Coords[blipIdOpen]
    if not bench or tostring(bench.name) ~= tostring(benchKey) then return end
    if GetPlayerServerId(PlayerId()) ~= tonumber(starterSource) then
        isMenuOpen = false
        blipIdOpen = nil
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'opened', data = false })
    end
end)

local function getBenchState(blipIndex)
    local bench = Config.Coords[blipIndex]
    if not bench or not bench.name then return nil end
    return craftStates[tostring(bench.name)]
end

local function getStateRemaining(state)
    if type(state) ~= 'table' or state.status ~= 'crafting' then return 0 end
    local elapsed = math.floor(math.max(0, GetGameTimer() - (state._syncedAt or GetGameTimer())) / 1000)
    return math.max(0, (tonumber(state.remaining) or 0) - elapsed)
end

local function formatCraftTime(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return ('%02d:%02d:%02d'):format(hours, minutes, secs)
end

local function hasBenchAccess(blipIndex)
    local now = GetGameTimer()
    local cached = permissionCache[blipIndex]
    if cached and now < cached.expiresAt then
        return cached.allowed
    end
    local allowed = ServerAPI.hasMinPermission(blipIndex) == true
    permissionCache[blipIndex] = { allowed = allowed, expiresAt = now + 4000 }
    return allowed
end

local function openMenu(blipId)
    blipIdOpen = blipId
    isMenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'opened',
        data = true
    })
end

local function closeMenu()
    isMenuOpen = false
    blipIdOpen = nil
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'opened',
        data = false
    })
end

local function getNearestBlip(coords)
    local nearestBlip = nil
    local nearestDistance = 10.0
    for i=1, #Config.Coords do
        local blip = Config.Coords[i]
        for _, coord in ipairs(blip.coords) do
            local distance = #(coords - coord)
            if distance <= MIN_DISTANCE and (not nearestBlip or distance < nearestDistance) then
                nearestBlip = i
                nearestDistance = distance
            end
        end
    end
    return nearestBlip
end

RegisterNUICallback('Close', function(data, cb)
    closeMenu()
    cb(true)
end)

RegisterNUICallback('GetProductions', function(data, cb)
    if not isMenuOpen then
        cb({ items = EMPTY_ARRAY, inQueue = EMPTY_ARRAY })
        closeMenu()
        return
    end
    if pendingCallbacks["getProductions"] then
        return cb({ items = EMPTY_ARRAY, inQueue = EMPTY_ARRAY })
    end
    pendingCallbacks["getProductions"] = true
    Wait(math.random(50, 500))
    local productions = ServerAPI.getProductions(blipIdOpen)
    pendingCallbacks["getProductions"] = false
    if not productions then
        cb({ items = EMPTY_ARRAY, inQueue = EMPTY_ARRAY })
        closeMenu()
        return
    end

    local items = productions
    if type(items) ~= 'table' then items = EMPTY_ARRAY end
    cb({ items = items, inQueue = EMPTY_ARRAY })
end)

RegisterNUICallback('ProduceItem', function(data, cb)
    if not isMenuOpen then
        cb(false)
        closeMenu()
        return
    end
    if pendingCallbacks["produceItem"] then
        return cb(false)
    end
    pendingCallbacks["produceItem"] = true
    SetNuiFocus(false, false)
    Wait(math.random(50, 500))
    local status = ServerAPI.produceItem(blipIdOpen, data)
    SetNuiFocus(true, true)
    pendingCallbacks["produceItem"] = false
    if not status then
        cb(false)
        return
    end
    cb(true)
end)

RegisterNUICallback('RemoveItemFromQueue', function(data, cb)
    if not isMenuOpen then
        cb(false)
        closeMenu()
        return
    end

    if pendingCallbacks["removeItemFromQueue"] then
        return cb(false)
    end
    pendingCallbacks["removeItemFromQueue"] = true
    Wait(math.random(50, 500))
    local status = ServerAPI.removeItemFromQueue(blipIdOpen, data)
    pendingCallbacks["removeItemFromQueue"] = false
    
    if not status then
        cb(false)
        return
    end
    cb(true)
end)

RegisterNUICallback('GetStorage', function(data, cb)
    if not isMenuOpen then
        cb(EMPTY_ARRAY)
        return
    end

    local storage = ServerAPI.getStorage(blipIdOpen)
    if not storage then
        return cb(EMPTY_ARRAY)
    end

    cb(storage)
end)

RegisterNUICallback('SaveAll', function(data, cb)
    if not isMenuOpen then
        cb(false)
        closeMenu()
        return
    end
    if pendingCallbacks["saveAll"] then
        return cb(false)
    end
    pendingCallbacks["saveAll"] = true
    Wait(math.random(50, 500))
    local status = ServerAPI.saveAll(blipIdOpen)
    pendingCallbacks["saveAll"] = false
    if not status then
        cb(false)
        return
    end
    cb(true)
end)

RegisterNUICallback('SaveItem', function(data, cb)
    if not isMenuOpen then
        cb(false)
        closeMenu()
        return
    end
    if pendingCallbacks["saveItem"] then
        return cb(false)
    end
    pendingCallbacks["saveItem"] = true
    Wait(math.random(50, 500))
    local status = ServerAPI.saveItem(blipIdOpen, data)
    pendingCallbacks["saveItem"] = false
    if not status then
        cb(false)
        return
    end
    cb(true)
end)

RegisterNUICallback('GetRanking', function(data, cb)
    if not isMenuOpen then
        cb(EMPTY_ARRAY)
        return
    end

    local ranking = ServerAPI.getRanking(blipIdOpen)
    if not ranking then
        return cb(EMPTY_ARRAY)
    end

    cb(ranking)
end)

RegisterNUICallback('selectedFarm', function(data, cb)
    if not isMenuOpen then
        cb(false)
        closeMenu()
        return
    end
    
    cb(true)
    closeMenu()
    -- Open brasil_farm routes UI
    TriggerEvent('routes:initialize')
end)

RegisterNUICallback('selectedDrugs', function(data, cb)
    if not isMenuOpen then
        cb(false)
        closeMenu()
        return
    end
    
    cb(true)
    closeMenu()
    TriggerEvent('drugs:openRoutes')
end)

function DrawText3D(x,y,z,text)
	local onScreen,_x,_y = World3dToScreen2d(x,y,z)
	SetTextFont(4)
	SetTextScale(0.35,0.35)
	SetTextColour(255,255,255,100)
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(_x,_y)
	local factor = (string.len(text)) / 400
	DrawRect(_x,_y+0.0125,0.01+factor,0.03,0,0,0,140)
end

function DrawText3DAlways(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then
        return
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(playerCoords - vector3(x, y, z))
    local scale = 1.0 / math.max(distance, 1.0) * 2.0
    scale = math.min(scale, 0.35)
    scale = math.max(scale, 0.2)

    SetTextScale(scale, scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(_x, _y)
end


local function drawCraftStatus(coord, state)
    local amount = math.max(1, math.floor(tonumber(state.amount) or 1))
    local itemName = tostring(state.name or 'item')

    if state.status == 'ready' then
        DrawText3DAlways(coord.x, coord.y, coord.z + 0.72, ('%dx - %s prontos'):format(amount, itemName))
        DrawText3DAlways(coord.x, coord.y, coord.z + 0.54, '[ E ] para coletar')
    else
        DrawText3DAlways(coord.x, coord.y, coord.z + 0.72, ('Fabricando %dx %s, volte quando estiver terminado'):format(amount, itemName))
        DrawText3DAlways(coord.x, coord.y, coord.z + 0.54, formatCraftTime(getStateRemaining(state)))
    end
end

CreateThread(function()
    while true do
        local waitTime = 1500

        if not isMenuOpen then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local nearestBlip = getNearestBlip(coords)

            if nearestBlip then
                waitTime = 0
                local bench = Config.Coords[nearestBlip]
                local state = getBenchState(nearestBlip)
                local canAccess = nil

                -- A marcação no chão continua existindo, mas o texto de fabricação/coleta
                -- só é mostrado para quem realmente possui acesso àquela bancada.
                for _, coord in ipairs(bench.coords or {}) do
                    local distance = #(coords - coord)
                    if distance <= MIN_DISTANCE then
                        DrawMarker(27, coord.x, coord.y, coord.z - 0.95, 0,0,0,0,0,0,1.5,1.5,1.5,132,102,226,180,0,0,0,1)

                        if state then
                            if canAccess == nil then canAccess = hasBenchAccess(nearestBlip) end
                            if canAccess then
                                drawCraftStatus(coord, state)
                            end
                        end
                    end
                end

                if IsControlJustPressed(0, 38) then
                    if canAccess == nil then canAccess = hasBenchAccess(nearestBlip) end
                    if canAccess then
                        -- Confirma o estado diretamente no servidor no momento da interação.
                        -- Isso impede abrir a NUI por uma eventual perda/atraso de evento de sincronização.
                        local authoritativeState = ServerAPI.getBenchState(nearestBlip)
                        if type(authoritativeState) == 'table' then
                            authoritativeState = stampState(authoritativeState)
                            local key = bench and bench.name and tostring(bench.name)
                            if key then craftStates[key] = authoritativeState end
                            state = authoritativeState
                        elseif state then
                            -- Se o servidor não possui mais trabalho, remove estado local obsoleto.
                            local key = bench and bench.name and tostring(bench.name)
                            if key then craftStates[key] = nil end
                            state = nil
                        end

                        if state then
                            if state.status == 'ready' and not collectingBench then
                                collectingBench = true
                                local collected = ServerAPI.collectBench(nearestBlip)
                                collectingBench = false
                                if collected then
                                    local key = bench and bench.name and tostring(bench.name)
                                    if key then craftStates[key] = nil end
                                end
                            end
                            -- Durante a fabricação a bancada permanece bloqueada.
                        else
                            openMenu(nearestBlip)
                        end
                    end
                end
            end
        end

        Wait(waitTime)
    end
end)

RegisterNetEvent('craft:showBlips', function(org)
    CreateThread(function()
        local orgIndex
        for i=1, #Config.Coords do
            local table = Config.Coords[i]
            if table.name == org then
                orgIndex = i
                break
            end
        end

        if not orgIndex then return end

        local coords = Config.Coords[orgIndex].coords
        if not coords then return end
        coords = coords[1]
        local endTime = GetGameTimer() + (1000 * 60 * 2)
        while GetGameTimer() < endTime do
            Wait(0)
            DrawText3DAlways(coords.x, coords.y, coords.z + 1.0, "Craft")
        end
    end)
end)

-- Function to show organization storage menu
local function showOrgStorageMenu(orgName, items)
    if not lib or not lib.registerContext then
        print('[m_craft] ox_lib não está carregado, fallback simples de menu exibido no console.')
        for _, it in ipairs(items or {}) do
            print(('[%s] x%s'):format(it.name or it.spawn, it.amount))
        end
        return
    end
    if #items == 0 then
        lib.notify({
            title = 'Aviso',
            description = 'Armazém vazio ou organização não encontrada',
            type = 'inform'
        })
        return
    end

    local menuItems = {}
    for _, item in ipairs(items) do
        table.insert(menuItems, {
            title = item.name,
            description = 'Quantidade: ' .. item.amount,
            metadata = {
                {label = 'Quantidade', value = item.amount}
            },
            onSelect = function()
                local input = lib.inputDialog('Remover Item', {
                    {
                        type = 'number',
                        label = 'Quantidade',
                        description = 'Quantidade que deseja remover',
                        required = true,
                        min = 1,
                        max = item.amount
                    }
                })

                if not input then return end
                local removeAmount = input[1]

                if removeAmount > item.amount then
                    lib.notify({
                        title = 'Erro',
                        description = 'Quantidade inválida',
                        type = 'error'
                    })
                    return
                end

                -- Call server to remove items
                ServerAPI.removeOrgItem(orgName, item.name, removeAmount)
            end
        })
    end

    lib.registerContext({
        id = 'org_storage_menu',
        title = 'Armazém - ' .. orgName,
        options = menuItems
    })

    lib.showContext('org_storage_menu')
end

-- Command to open organization storage menu
RegisterCommand('orgstorage', function(source, args)
    if not args[1] then
        lib.notify({
            title = 'Erro',
            description = 'Uso: /orgstorage [nome da organização]',
            type = 'error'
        })
        return
    end

    local orgName = args[1]
    ServerAPI.getOrgStorage(orgName)
end)

-- Event handler for receiving storage data
RegisterNetEvent('m_craft:showStorageMenu')
AddEventHandler('m_craft:showStorageMenu', function(orgName, items)
    showOrgStorageMenu(orgName, items)
end)

-- Event handler for storage updates
RegisterNetEvent('m_craft:updateStorageMenu')
AddEventHandler('m_craft:updateStorageMenu', function(orgName, items)
    showOrgStorageMenu(orgName, items)
end)