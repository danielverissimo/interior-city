local Tunnel = module('vrp','lib/Tunnel')
local Proxy = module('vrp','lib/Proxy')
local vRP = Proxy.getInterface('vRP')
local vSERVER = Tunnel.getInterface('radio')

local GuiOpened = false
local currentChannel = 0
local radioVolume = 0.5

local function notify(kind, message)
    TriggerEvent('Notify', kind or 'aviso', message or '')
end

local function normalizeChannel(value)
    local number = tonumber(value)
    if not number then return 0 end
    number = math.floor(number)
    if number < 0 then return 0 end
    return number
end

local function canUseChannel(channel)
    channel = normalizeChannel(channel)
    if channel <= 0 then return true end
    local ok = vSERVER.canJoinChannel(channel)
    if ok ~= true then
        notify('negado', 'Você não tem permissão para entrar nessa frequência privada.')
        return false
    end
    return true
end

local function setRadio(channel)
    channel = normalizeChannel(channel)
    if channel <= 0 then
        currentChannel = 0
        exports['pma-voice']:removePlayerFromRadio()
        exports['pma-voice']:setVoiceProperty('radioEnabled', false)
        TriggerEvent('hud:RadioDisplay', 0)
        SendNUIMessage({ set = true, setChannel = 0 })
        return true
    end

    if not canUseChannel(channel) then return false end
    currentChannel = channel
    exports['pma-voice']:setRadioChannel(channel)
    exports['pma-voice']:setVoiceProperty('radioEnabled', true)
    exports['pma-voice']:setVoiceProperty('micClicks', true)
    TriggerEvent('hud:RadioDisplay', channel)
    SendNUIMessage({ set = true, setChannel = channel })
    return true
end

local function openGui()
    if not GuiOpened then
        GuiOpened = true
        SetNuiFocus(true, true)
        SendNUIMessage({ open = true })
    else
        GuiOpened = false
        SetNuiFocus(false, false)
        SendNUIMessage({ open = false })
    end
    TriggerEvent('animation:radio', GuiOpened)
end

RegisterCommand('radio', function()
    if vSERVER.hasRadio() then
        openGui()
    else
        notify('negado', 'Você não pode utilizar um rádio agora ou não possui um rádio.')
    end
end)

RegisterNetEvent('radioGui', function()
    if vSERVER.hasRadio() then openGui() else notify('negado', 'Você não pode utilizar um rádio agora ou não possui um rádio.') end
end)

RegisterNetEvent('ChannelSet', function(chan)
    currentChannel = normalizeChannel(chan)
    SendNUIMessage({ set = true, setChannel = currentChannel })
end)

-- Sincronização autoritativa do pma-voice. Se o servidor negar uma frequência
-- privada, o display do rádio volta imediatamente para a frequência realmente ativa.
RegisterNetEvent('pma-voice:clSetPlayerRadio', function(chan)
    currentChannel = normalizeChannel(chan)
    TriggerEvent('hud:RadioDisplay', currentChannel)
    SendNUIMessage({ set = true, setChannel = currentChannel })
end)

RegisterNetEvent('pma-voice:radioDenied', function()
    notify('negado', 'Você não tem permissão para entrar nessa frequência privada.')
end)

RegisterNetEvent('radio:accessRevoked', function(message)
    currentChannel = 0
    exports['pma-voice']:setVoiceProperty('radioEnabled', false)
    TriggerEvent('hud:RadioDisplay', 0)
    SendNUIMessage({ set = true, setChannel = 0 })
    notify('negado', message or 'Seu acesso a esta frequência privada foi removido.')
end)

RegisterNetEvent('radio:resetNuiCommand', function()
    SendNUIMessage({ reset = true })
end)

RegisterNUICallback('click', function(_, cb)
    PlaySound(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', 0, 0, 1)
    if cb then cb({ ok = true }) end
end)

-- O rádio antigo alterava MumbleSetVolumeOverride no próprio PED. Isso não controla
-- o volume do módulo de rádio do pma-voice. Agora o slider usa a API correta.
RegisterNUICallback('volumeRadio', function(data, cb)
    local normalized = tonumber(data and data.volume) or radioVolume
    normalized = math.max(0.0, math.min(1.0, normalized))
    radioVolume = normalized
    exports['pma-voice']:setRadioVolume(math.floor((normalized * 100.0) + 0.5))
    PlaySound(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', 0, 0, 1)
    if cb then cb({ ok = true }) end
end)

RegisterNUICallback('volumeUp', function(_, cb)
    radioVolume = math.min(1.0, radioVolume + 0.1)
    exports['pma-voice']:setRadioVolume(math.floor((radioVolume * 100.0) + 0.5))
    if cb then cb({ ok = true }) end
end)

RegisterNUICallback('volumeDown', function(_, cb)
    radioVolume = math.max(0.0, radioVolume - 0.1)
    exports['pma-voice']:setRadioVolume(math.floor((radioVolume * 100.0) + 0.5))
    if cb then cb({ ok = true }) end
end)

RegisterNUICallback('cleanClose', function(_, cb)
    TriggerEvent('InteractSound_CL:PlayOnOne','radioclick',0.6)
    GuiOpened = false
    SetNuiFocus(false,false)
    SendNUIMessage({open = false})
    TriggerEvent('animation:radio', GuiOpened)
    if cb then cb({ ok = true }) end
end)

RegisterNUICallback('poweredOn', function(data, cb)
    TriggerEvent('InteractSound_CL:PlayOnOne','radioclick',0.6)
    local ok = setRadio(data and data.channel or 0)
    if cb then cb({ ok = ok }) end
end)

RegisterNUICallback('poweredOff', function(_, cb)
    setRadio(0)
    if cb then cb({ ok = true }) end
end)

RegisterNUICallback('close', function(data, cb)
    local desired = normalizeChannel(data and data.channel or 0)
    if setRadio(desired) then
        TriggerEvent('InteractSound_CL:PlayOnOne','radioclick',0.6)
        GuiOpened = false
        SetNuiFocus(false,false)
        SendNUIMessage({open = false})
        TriggerEvent('animation:radio', GuiOpened)
    end
    if cb then cb({ ok = true }) end
end)

RegisterNetEvent('animation:radio', function(enable)
    local ped = PlayerPedId()
    local inPhone = enable == true
    RequestAnimDict('cellphone@')
    while not HasAnimDictLoaded('cellphone@') do Wait(0) end

    if inPhone then
        TaskPlayAnim(ped, 'cellphone@', 'cellphone_text_in', 2.0, 3.0, -1, 49, 0, false, false, false)
        Wait(300)
        while GuiOpened do
            if not IsEntityPlayingAnim(ped, 'cellphone@', 'cellphone_text_read_base', 3) then
                TaskPlayAnim(ped, 'cellphone@', 'cellphone_text_read_base', 2.0, 3.0, -1, 49, 0, false, false, false)
            end
            Wait(250)
        end
        ClearPedTasks(ped)
    else
        ClearPedTasks(ped)
        TaskPlayAnim(ped, 'cellphone@', 'cellphone_text_out', 2.0, 1.0, 450, 49, 0, false, false, false)
        Wait(450)
        ClearPedTasks(ped)
    end
end)

AddEventHandler('onClientResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if GuiOpened then SetNuiFocus(false, false) end
end)
