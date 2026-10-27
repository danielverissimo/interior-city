local radioChecks = {}

local function getCheckEntry(channel)
    local entry = radioChecks[channel]
    if not entry then return nil end
    -- Compatibilidade com checks registrados antes desta versão.
    if entry.cb then return entry end
    return { cb = entry, resource = nil }
end

function canJoinChannel(source, radioChannel)
    local entry = getCheckEntry(radioChannel)
    if entry and entry.cb then
        local ok, allowed = pcall(function() return entry.cb(source) end)
        if not ok then
            logger.warn('[radio] Channel check for %s failed: %s', radioChannel, allowed)
            return false
        end
        return allowed == true
    end
    return true
end

function addChannelCheck(channel, cb)
    local channelType = type(channel)
    local cbType = type(cb)
    if channelType ~= 'number' then
        error(("'channel' expected 'number' got '%s'"):format(channelType))
    end
    if cbType ~= 'table' or not cb.__cfx_functionReference then
        error(("'cb' expected 'function' got '%s'"):format(cbType))
    end
    radioChecks[channel] = { cb = cb, resource = GetInvokingResource() }
    logger.info('%s added a check to channel %s', GetInvokingResource() or 'unknown', channel)
end
exports('addChannelCheck', addChannelCheck)

-- Permite que o resource que criou uma trava de frequência a remova em tempo real.
-- Isso é necessário para rádios privadas editáveis sem reiniciar pma-voice/radio.
function removeChannelCheck(channel)
    local channelType = type(channel)
    if channelType ~= 'number' then
        error(("'channel' expected 'number' got '%s'"):format(channelType))
    end
    local entry = getCheckEntry(channel)
    if not entry then return true end
    local invoking = GetInvokingResource()
    if entry.resource and invoking and entry.resource ~= invoking then
        logger.warn('%s tried to remove a radio check owned by %s on channel %s', invoking, entry.resource, channel)
        return false
    end
    radioChecks[channel] = nil
    logger.info('%s removed check from channel %s', invoking or 'internal', channel)
    return true
end
exports('removeChannelCheck', removeChannelCheck)

local function radioNameGetter_orig(source)
    return GetPlayerName(source)
end
local radioNameGetter = radioNameGetter_orig

function overrideRadioNameGetter(channel, cb)
    local cbType = type(cb)
    if cbType == 'table' and not cb.__cfx_functionReference then
        error(("'cb' expected 'function' got '%s'"):format(cbType))
    end
    radioNameGetter = cb
    logger.info('%s changed the radio name getter', GetInvokingResource() or 'unknown')
end
exports('overrideRadioNameGetter', overrideRadioNameGetter)

function addPlayerToRadio(source, radioChannel)
    if not canJoinChannel(source, radioChannel) then return false end
    logger.verbose('[radio] Added %s to radio %s', source, radioChannel)

    radioData[radioChannel] = radioData[radioChannel] or {}
    local plyName = radioNameGetter(source)
    for player, _ in pairs(radioData[radioChannel]) do
        TriggerClientEvent('pma-voice:addPlayerToRadio', player, source, plyName)
    end
    TriggerClientEvent('nation_hud:updateRadio', source, radioChannel)
    voiceData[source] = voiceData[source] or defaultTable(source)
    voiceData[source].radio = radioChannel
    radioData[radioChannel][source] = false
    TriggerClientEvent('pma-voice:syncRadioData', source, radioData[radioChannel], GetConvarInt('voice_syncPlayerNames', 0) == 1 and plyName)
    return true
end

function removePlayerFromRadio(source, radioChannel)
    radioChannel = tonumber(radioChannel) or 0
    logger.verbose('[radio] Removed %s from radio %s', source, radioChannel)
    if radioChannel > 0 then
        radioData[radioChannel] = radioData[radioChannel] or {}
        for player, _ in pairs(radioData[radioChannel]) do
            TriggerClientEvent('pma-voice:removePlayerFromRadio', player, source)
        end
        radioData[radioChannel][source] = nil
        if next(radioData[radioChannel]) == nil then radioData[radioChannel] = nil end
    end
    TriggerClientEvent('nation_hud:updateRadio', source, 0)
    voiceData[source] = voiceData[source] or defaultTable(source)
    voiceData[source].radio = 0
end

function setPlayerRadio(source, _radioChannel)
    if GetConvarInt('voice_enableRadios', 1) ~= 1 then return false end
    source = tonumber(source)
    if not source then return false end

    voiceData[source] = voiceData[source] or defaultTable(source)
    local plyVoice = voiceData[source]
    local radioChannel = tonumber(_radioChannel)
    if not radioChannel then
        if GetInvokingResource() then
            error(("'radioChannel' expected 'number', got: %s"):format(type(_radioChannel)))
        end
        logger.warn("%s sent an invalid radio channel", source)
        return false
    end

    radioChannel = math.floor(radioChannel)
    if radioChannel < 0 or radioChannel > 9999 then
        logger.warn('%s tried invalid radio channel %s', source, radioChannel)
        TriggerClientEvent('pma-voice:clSetPlayerRadio', source, plyVoice.radio or 0)
        return false
    end

    -- Valida ANTES de remover o jogador da frequência atual. O código antigo
    -- atualizava state.radioChannel primeiro e podia deixar o client acreditando
    -- que estava numa frequência em que o servidor nunca o adicionou.
    if radioChannel > 0 and not canJoinChannel(source, radioChannel) then
        local current = tonumber(plyVoice.radio) or 0
        Player(source).state:set('radioChannel', current, true)
        TriggerClientEvent('pma-voice:clSetPlayerRadio', source, current)
        TriggerClientEvent('pma-voice:radioDenied', source, radioChannel)
        return false
    end

    local current = tonumber(plyVoice.radio) or 0
    if current == radioChannel then
        Player(source).state:set('radioChannel', radioChannel, true)
        TriggerClientEvent('pma-voice:clSetPlayerRadio', source, radioChannel)
        return true
    end

    if current > 0 then removePlayerFromRadio(source, current) end
    if radioChannel > 0 then
        if not addPlayerToRadio(source, radioChannel) then
            Player(source).state:set('radioChannel', 0, true)
            TriggerClientEvent('pma-voice:clSetPlayerRadio', source, 0)
            return false
        end
    end

    Player(source).state:set('radioChannel', radioChannel, true)
    TriggerClientEvent('pma-voice:clSetPlayerRadio', source, radioChannel)
    return true
end
exports('setPlayerRadio', setPlayerRadio)

RegisterNetEvent('pma-voice:setPlayerRadio', function(radioChannel)
    setPlayerRadio(source, radioChannel)
end)

function setTalkingOnRadio(talking)
    if GetConvarInt('voice_enableRadios', 1) ~= 1 then return end
    voiceData[source] = voiceData[source] or defaultTable(source)
    local plyVoice = voiceData[source]
    if not plyVoice.radio or plyVoice.radio <= 0 then return end
    local radioTbl = radioData[plyVoice.radio]
    if radioTbl then
        radioTbl[source] = talking == true
        logger.verbose('[radio] Set %s to talking: %s on radio %s', source, talking, plyVoice.radio)
        for player, _ in pairs(radioTbl) do
            if player ~= source then
                TriggerClientEvent('pma-voice:setTalkingOnRadio', player, source, talking == true)
            end
        end
    end
end
RegisterNetEvent('pma-voice:setTalkingOnRadio', setTalkingOnRadio)

AddEventHandler('onResourceStop', function(resource)
    for channel, entry in pairs(radioChecks) do
        local normalized = getCheckEntry(channel)
        local owner = normalized and normalized.resource
        if owner == resource then
            radioChecks[channel] = nil
            logger.warn('Channel %s check removed because %s stopped', channel, resource)
        elseif not owner and normalized and normalized.cb and normalized.cb.__cfx_functionReference then
            local ref = normalized.cb.__cfx_functionReference
            if type(ref) == 'string' and ref:find(resource, 1, true) then radioChecks[channel] = nil end
        end
    end

    if type(radioNameGetter) == 'table' then
        local radioRef = radioNameGetter.__cfx_functionReference
        if radioRef and type(radioRef) == 'string' and radioRef:find(resource, 1, true) then
            radioNameGetter = radioNameGetter_orig
        end
    end
end)

RegisterServerEvent('pma-voice:toggleMutePlayer')
AddEventHandler('pma-voice:toggleMutePlayer', function(status)
    MumbleSetPlayerMuted(source, status or false)
    TriggerClientEvent('Notify', source, 'sucesso', status and 'Você foi mutado.' or 'Você foi desmutado.')
end)
