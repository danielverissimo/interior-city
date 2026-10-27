-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP NOTIFYCALL - CLIENT
-----------------------------------------------------------------------------------------------------------------------------------------
local RESOURCE = GetCurrentResourceName()
local DEFAULT_BLIP_TIME = 60000
local quickFocus = false

CreateThread(function()
    SetNuiFocus(false,false)
end)

local function numberOr(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback end
    return n
end

local function getStreetName(x,y,z)
    local streetHash = GetStreetNameAtCoord(x + 0.0,y + 0.0,z + 0.0)
    if streetHash and streetHash ~= 0 then
        local street = GetStreetNameFromHashKey(streetHash)
        if street and street ~= "" then return street end
    end
    return "Localização não identificada"
end

local function normalizeColor(rgba)
    if type(rgba) ~= "table" then return { 255, 55, 70, 255 } end
    return {
        math.max(0,math.min(255,numberOr(rgba[1],255))),
        math.max(0,math.min(255,numberOr(rgba[2],55))),
        math.max(0,math.min(255,numberOr(rgba[3],70))),
        math.max(0,math.min(255,numberOr(rgba[4],255)))
    }
end

local function createDispatchBlip(data,preset)
    local x,y,z = tonumber(data.x),tonumber(data.y),tonumber(data.z)
    if not x or not y or not z then return end

    local blip = AddBlipForCoord(x,y,z)
    SetBlipSprite(blip,numberOr(data.blipSprite,preset.sprite))
    SetBlipAsShortRange(blip,data.blipShortRange == true)
    SetBlipColour(blip,numberOr(data.blipColor,preset.color))
    SetBlipScale(blip,numberOr(data.blipScale,preset.scale))

    if data.blipRoute == true then
        SetBlipRoute(blip,true)
        SetBlipRouteColour(blip,numberOr(data.blipColor,preset.color))
    end

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(tostring(data.title or "Chamado"))
    EndTextCommandSetBlipName(blip)

    local duration = math.max(1000,numberOr(data.blipDuration,DEFAULT_BLIP_TIME))
    SetTimeout(duration,function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
end

local function playDispatchSound(data)
    -- Som é sempre local: este evento já chega somente a quem deve receber o chamado.
    if data.sound == false then return end

    if data.soundName and data.soundSet then
        PlaySoundFrontend(-1,tostring(data.soundName),tostring(data.soundSet),false)
        return
    end

    -- Mantém compatibilidade com chamadas QRT antigas sem depender de uma global inexistente.
    if tostring(data.code or ""):upper() == "QRT" then
        TriggerEvent("vrp_sound:source","deathcop",0.7)
    else
        PlaySoundFrontend(-1,"Event_Message_Purple","GTAO_FM_Events_Soundset",false)
    end
end

local function pushNotification(raw,preset)
    if type(raw) ~= "table" then return end

    local data = {}
    for k,v in pairs(raw) do data[k] = v end

    local x,y,z = tonumber(data.x),tonumber(data.y),tonumber(data.z)
    if not x or not y or not z then return end

    data.x,data.y,data.z = x,y,z
    data.rgba = normalizeColor(data.rgba)
    data.street = data.street or getStreetName(x,y,z)
    data.title = tostring(data.title or "Novo chamado")

    SendNUIMessage({ action = "notify", data = data })
    createDispatchBlip(data,preset)
    playDispatchSound(data)
end

local PRESETS = {
    NotifyPush  = { sprite = 304, color = 5,  scale = 0.8 },
    NotifyPush2 = { sprite = 474, color = 1,  scale = 0.5 },
    NotifyPush3 = { sprite = 150, color = 48, scale = 0.5 },
    NotifyGod   = { sprite = 439, color = 1,  scale = 0.5 }
}

for eventName,preset in pairs(PRESETS) do
    RegisterNetEvent(eventName)
    AddEventHandler(eventName,function(data)
        pushNotification(data,preset)
    end)
end

RegisterCommand("chamados",function()
    SendNUIMessage({ action = "showAll" })
end,false)

RegisterKeyMapping("chamados","Abrir as notificações","keyboard","f12")

RegisterCommand("interagirchamado",function()
    -- F1 abre/fecha o histórico rápido das 3 últimas ocorrências recebidas.
    if quickFocus then
        quickFocus = false
        SetNuiFocus(false,false)
        SendNUIMessage({ action = "quickFocusOff" })
        return
    end

    quickFocus = true
    SetNuiFocus(true,true)
    SendNUIMessage({ action = "showQuickRecent" })
end,false)

RegisterKeyMapping("interagirchamado","Abrir as 3 últimas ocorrências","keyboard","f1")

RegisterNUICallback("focusOn",function(_,cb)
    SetNuiFocus(true,true)
    if cb then cb({ ok = true }) end
end)

RegisterNUICallback("focusOff",function(_,cb)
    quickFocus = false
    SetNuiFocus(false,false)
    SendNUIMessage({ action = "quickFocusOff" })
    if cb then cb({ ok = true }) end
end)

RegisterNUICallback("quickWay",function(data,cb)
    local x,y = tonumber(data and data.x),tonumber(data and data.y)
    if x and y then
        SetNewWaypoint(x + 0.0001,y + 0.0001)
    end

    quickFocus = false
    SetNuiFocus(false,false)
    SendNUIMessage({ action = "quickFocusOff" })

    if cb then cb({ ok = x ~= nil and y ~= nil }) end
end)

RegisterNUICallback("setWay",function(data,cb)
    local x,y = tonumber(data and data.x),tonumber(data and data.y)
    if x and y then
        SetNewWaypoint(x + 0.0001,y + 0.0001)
        SendNUIMessage({ action = "hideAll" })
    end
    if cb then cb({ ok = x ~= nil and y ~= nil }) end
end)

RegisterNUICallback("phoneCall",function(data,cb)
    local phone = data and data.phone
    if phone and tostring(phone) ~= "" then
        SendNUIMessage({ action = "hideAll" })
        TriggerEvent("gcPhone:callNotifyPush",phone)
    end
    if cb then cb({ ok = phone ~= nil }) end
end)

AddEventHandler("onResourceStop",function(resourceName)
    if resourceName ~= RESOURCE then return end
    quickFocus = false
    SetNuiFocus(false,false)
end)
