Televisions = Televisions or {}
Channels = Channels or {}
TelevisionsLocal = TelevisionsLocal or {}

local function currentScreenKey()
    if not CURRENT_SCREEN then return nil end
    return MTelevisionScreenKey(CURRENT_SCREEN.coords, CURRENT_SCREEN.model)
end

function GetTelevision(coords, model)
    local key = MTelevisionScreenKey(coords, model)
    return key, Televisions[key]
end

function GetTelevisionLocal(coords, model)
    local key = MTelevisionScreenKey(coords, model)
    return key, TelevisionsLocal[key]
end

function SetTelevisionLocal(coords, model, key, value)
    local screenKey = MTelevisionScreenKey(coords, model)
    TelevisionsLocal[screenKey] = TelevisionsLocal[screenKey] or {}
    TelevisionsLocal[screenKey][key] = value
    return screenKey
end

function SetChannel(index)
    if not CURRENT_SCREEN then return end
    TriggerServerEvent("m_television:setState", {
        coords = CURRENT_SCREEN.coords,
        model = CURRENT_SCREEN.model
    }, {
        type = "play",
        channel = tonumber(index)
    })
end

function GetChannelList()
    local list = {}
    local currentKey = currentScreenKey()
    local status = currentKey and Televisions[currentKey] or nil
    local activeChannel = status and status.ptv_status and tonumber(status.ptv_status.channel) or nil

    local indices = {}
    for index in pairs(Channels or {}) do
        indices[#indices + 1] = tonumber(index) or index
    end
    table.sort(indices, function(a, b) return tonumber(a) < tonumber(b) end)

    for _, index in ipairs(indices) do
        local channel = Channels[index] or Channels[tostring(index)]
        if channel then
            list[#list + 1] = {
                index = tonumber(index),
                name = channel.name or ("Canal " .. tostring(index)),
                url = channel.url,
                active = activeChannel == tonumber(index),
                default = channel.default == true
            }
        end
    end

    return list
end

function OpenTVMenu()
    if not CURRENT_SCREEN then
        MTelevisionNotify("Nenhuma televisão ativa próxima.", "error")
        return
    end

    TriggerServerEvent("m_television:requestMenu", {
        coords = CURRENT_SCREEN.coords,
        model = CURRENT_SCREEN.model
    })
end

function PlayBrowser(data)
    if not duiObj or not data or not data.url then return end
    while duiObj and not IsDuiAvailable(duiObj) do Wait(10) end
    if not duiObj then return end
    setDuiURL(data.url)
end

function PlayVideo(data)
    if not duiObj or not data or not data.url then return end
    while duiObj and not IsDuiAvailable(duiObj) do Wait(10) end
    if not duiObj then return end

    if getDuiURL() ~= DEFAULT_URL then
        waitForLoad = true
        setDuiURL(DEFAULT_URL)

        local timeout = GetGameTimer() + 3500
        while duiObj and waitForLoad and GetGameTimer() < timeout do Wait(10) end
        if duiObj and waitForLoad then
            -- Fallback for DUI pages where the readiness callback is delayed or
            -- unavailable. Do not wait six seconds or drop the requested video.
            Wait(350)
            waitForLoad = false
        end
    end

    if not duiObj then return end
    SendDuiMessage(duiObj, json.encode({
        action = "setVideo",
        data = data
    }))
end

function ResetDisplay()
    if not duiObj then return end
    waitForLoad = true
    setDuiURL(DEFAULT_URL)
end

local function applyState(state, serverTime)
    if not state or not state.ptv_status then
        ResetDisplay()
        return
    end

    local status = state.ptv_status
    if status.type == "off" then
        ResetDisplay()
    elseif status.type == "browser" and status.url then
        PlayBrowser({ url = status.url })
    elseif status.type == "play" then
        if status.channel then
            local channel = Channels[status.channel] or Channels[tostring(status.channel)]
            if channel and channel.url then
                PlayVideo({ url = channel.url, channel = tonumber(status.channel), time = 0 })
            else
                ResetDisplay()
            end
        elseif status.url then
            local elapsed = 0
            if serverTime and state.update_time then
                elapsed = math.max(0, math.floor(serverTime - state.update_time))
            end
            PlayVideo({ url = status.url, time = elapsed })
        end
    end
end

RegisterNetEvent("m_television:update", function(data)
    Televisions = type(data) == "table" and (data.televisions or {}) or {}
    Channels = type(data) == "table" and (data.channels or {}) or {}
end)

RegisterNetEvent("m_television:sync", function(key, state, serverTime)
    if key then
        if state then Televisions[key] = state else Televisions[key] = nil end
    end

    if CURRENT_SCREEN and key == currentScreenKey() then
        applyState(state, serverTime)
    end
end)

RegisterNetEvent("m_television:state", function(key, state)
    if not key then return end
    if state then Televisions[key] = state else Televisions[key] = nil end

    if CURRENT_SCREEN and key == currentScreenKey() then
        applyState(state, nil)
    end
end)

RegisterNetEvent("m_television:channels", function(data, changedIndex)
    Channels = data or {}

    if not CURRENT_SCREEN or not changedIndex then return end
    local key = currentScreenKey()
    local state = key and Televisions[key] or nil
    local status = state and state.ptv_status or nil
    if status and tonumber(status.channel) == tonumber(changedIndex) then
        local stillExists = Channels[changedIndex] or Channels[tostring(changedIndex)]
        if not stillExists then ResetDisplay() end
    end

    if duiObj and getDuiURL() == DEFAULT_URL then
        SendDuiMessage(duiObj, json.encode({
            action = "channelNotification",
            channel = changedIndex,
            data = Channels[changedIndex] or Channels[tostring(changedIndex)]
        }))
    end
end)
