local NeedsConfig = module("cfg/needs") or {}

local NEEDS_KVP = "vrp:needs:enabled"
local NEEDS_SETTINGS_KVP = "vrp:needs:settings"
local needsEnabled = NeedsConfig.enabledByDefault ~= false

local needsSettings = {
    hungerPerMinute = tonumber(NeedsConfig.hungerPerMinute or NeedsConfig.hungerPerTick) or 0.35,
    thirstPerMinute = tonumber(NeedsConfig.thirstPerMinute or NeedsConfig.thirstPerTick) or 0.50,
    hungerDamage = tonumber(NeedsConfig.hungerDamage or NeedsConfig.starvationDamage) or 5,
    thirstDamage = tonumber(NeedsConfig.thirstDamage or NeedsConfig.starvationDamage) or 5
}

local function clamp(value, minValue, maxValue)
    value = tonumber(value) or 0
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function round(value, decimals)
    local factor = 10 ^ (decimals or 0)
    return math.floor((tonumber(value) or 0) * factor + 0.5) / factor
end

local function normalizedSettings(input)
    input = type(input) == "table" and input or {}
    local maxLoss = math.max(0.01, tonumber(NeedsConfig.maxLossPerMinute) or 100.0)
    local maxDamage = math.max(1, math.floor(tonumber(NeedsConfig.maxDamage) or 100))

    return {
        hungerPerMinute = round(clamp(input.hungerPerMinute, 0, maxLoss), 3),
        thirstPerMinute = round(clamp(input.thirstPerMinute, 0, maxLoss), 3),
        hungerDamage = math.floor(clamp(input.hungerDamage, 0, maxDamage) + 0.5),
        thirstDamage = math.floor(clamp(input.thirstDamage, 0, maxDamage) + 0.5)
    }
end

local function publicNeedsSettings()
    return {
        hungerPerMinute = needsSettings.hungerPerMinute + 0.0,
        thirstPerMinute = needsSettings.thirstPerMinute + 0.0,
        hungerDamage = needsSettings.hungerDamage + 0,
        thirstDamage = needsSettings.thirstDamage + 0,
        starvationCheckMs = math.max(1000, math.floor(tonumber(NeedsConfig.starvationCheckMs) or 10000))
    }
end

local function saveNeedsSettings()
    if type(SetResourceKvp) ~= "function" then return end
    local ok, encoded = pcall(json.encode, publicNeedsSettings())
    if ok and encoded then
        SetResourceKvp(NEEDS_SETTINGS_KVP, encoded)
    end
end

local function loadNeedsSettings()
    local defaults = normalizedSettings(needsSettings)
    needsSettings = defaults

    if type(GetResourceKvpString) ~= "function" then return end
    local raw = GetResourceKvpString(NEEDS_SETTINGS_KVP)
    if not raw or raw == "" then
        saveNeedsSettings()
        return
    end

    local ok, decoded = pcall(json.decode, raw)
    if ok and type(decoded) == "table" then
        needsSettings = normalizedSettings({
            hungerPerMinute = decoded.hungerPerMinute ~= nil and decoded.hungerPerMinute or defaults.hungerPerMinute,
            thirstPerMinute = decoded.thirstPerMinute ~= nil and decoded.thirstPerMinute or defaults.thirstPerMinute,
            hungerDamage = decoded.hungerDamage ~= nil and decoded.hungerDamage or defaults.hungerDamage,
            thirstDamage = decoded.thirstDamage ~= nil and decoded.thirstDamage or defaults.thirstDamage
        })
    end

    saveNeedsSettings()
end

local function publishNeedsSettings()
    GlobalState.needsSettings = publicNeedsSettings()
end

local function loadNeedsState()
    if type(GetResourceKvpString) ~= "function" then
        needsEnabled = NeedsConfig.enabledByDefault ~= false
        return
    end

    local saved = GetResourceKvpString(NEEDS_KVP)
    if saved == "0" then
        needsEnabled = false
    elseif saved == "1" then
        needsEnabled = true
    else
        needsEnabled = NeedsConfig.enabledByDefault ~= false
        SetResourceKvp(NEEDS_KVP, needsEnabled and "1" or "0")
    end
end

local function saveNeedsState()
    if type(SetResourceKvp) == "function" then
        SetResourceKvp(NEEDS_KVP, needsEnabled and "1" or "0")
    end
end

local function ensureData(user_id)
    local data = vRP.getUserDataTable(user_id)
    if not data then return nil end

    data.hunger = clamp(data.hunger, 0, 100)
    data.thirst = clamp(data.thirst, 0, 100)
    return data
end

local function publicNeeds(data)
    data = data or {}
    local hungerNeed = clamp(data.hunger, 0, 100)
    local thirstNeed = clamp(data.thirst, 0, 100)

    return {
        enabled = needsEnabled,
        hunger = round(100 - hungerNeed, 1),
        thirst = round(100 - thirstNeed, 1),
        hungerNeed = round(hungerNeed, 1),
        thirstNeed = round(thirstNeed, 1)
    }
end

local function syncPlayer(user_id, source)
    user_id = tonumber(user_id)
    source = tonumber(source) or (user_id and vRP.getUserSource(user_id))
    if not user_id or not source then return end

    local data = ensureData(user_id)
    if not data then return end

    local payload = publicNeeds(data)
    local player = Player(source)
    if player and player.state then
        player.state:set("needsHunger", payload.hunger, true)
        player.state:set("needsThirst", payload.thirst, true)
        player.state:set("needsEnabled", payload.enabled, true)
    end

    TriggerClientEvent("vrp:needs:update", source, payload)
end

local function syncAllPlayers()
    GlobalState.needsEnabled = needsEnabled
    for user_id, source in pairs(vRP.getUsers() or {}) do
        syncPlayer(tonumber(user_id), tonumber(source))
    end
    TriggerClientEvent("vrp:needs:enabled", -1, needsEnabled)
end

function vRP.areNeedsEnabled()
    return needsEnabled
end

function vRP.getNeedsSettings()
    return publicNeedsSettings()
end

function vRP.setNeedsSettings(settings)
    settings = type(settings) == "table" and settings or {}
    needsSettings = normalizedSettings({
        hungerPerMinute = settings.hungerPerMinute ~= nil and settings.hungerPerMinute or needsSettings.hungerPerMinute,
        thirstPerMinute = settings.thirstPerMinute ~= nil and settings.thirstPerMinute or needsSettings.thirstPerMinute,
        hungerDamage = settings.hungerDamage ~= nil and settings.hungerDamage or needsSettings.hungerDamage,
        thirstDamage = settings.thirstDamage ~= nil and settings.thirstDamage or needsSettings.thirstDamage
    })
    saveNeedsSettings()
    publishNeedsSettings()
    return publicNeedsSettings()
end

function vRP.getHunger(user_id)
    local data = ensureData(user_id)
    return data and data.hunger or 0
end

function vRP.getThirst(user_id)
    local data = ensureData(user_id)
    return data and data.thirst or 0
end

function vRP.getNeeds(user_id)
    local data = ensureData(user_id)
    return publicNeeds(data)
end

function vRP.setHunger(user_id, value)
    local data = ensureData(user_id)
    if not data then return false end
    data.hunger = clamp(value, 0, 100)
    syncPlayer(user_id)
    return true
end

function vRP.setThirst(user_id, value)
    local data = ensureData(user_id)
    if not data then return false end
    data.thirst = clamp(value, 0, 100)
    syncPlayer(user_id)
    return true
end

-- Compatibilidade com bases vRP antigas: variação positiva aumenta a necessidade
-- (esvazia a barra), variação negativa reduz a necessidade (enche a barra).
function vRP.varyHunger(user_id, variation)
    local data = ensureData(user_id)
    if not data then return false end
    data.hunger = clamp(data.hunger + (tonumber(variation) or 0), 0, 100)
    syncPlayer(user_id)
    return true
end

function vRP.varyThirst(user_id, variation)
    local data = ensureData(user_id)
    if not data then return false end
    data.thirst = clamp(data.thirst + (tonumber(variation) or 0), 0, 100)
    syncPlayer(user_id)
    return true
end

-- API usada pelo inventário. hungerRestore/thirstRestore representam pontos da
-- barra. Valores positivos enchem a barra; negativos pioram a necessidade.
function vRP.consumeNeeds(user_id, hungerRestore, thirstRestore)
    if not needsEnabled then return false, "disabled" end

    local data = ensureData(user_id)
    if not data then return false, "invalid_user" end

    hungerRestore = tonumber(hungerRestore) or 0
    thirstRestore = tonumber(thirstRestore) or 0

    data.hunger = clamp(data.hunger - hungerRestore, 0, 100)
    data.thirst = clamp(data.thirst - thirstRestore, 0, 100)
    syncPlayer(user_id)

    return true, publicNeeds(data)
end

function vRP.setNeedsEnabled(enabled)
    needsEnabled = enabled == true
    saveNeedsState()
    syncAllPlayers()
    return needsEnabled
end

-- Tunnel de compatibilidade. O client atual não precisa chamar essas funções,
-- porém scripts antigos que usem vRPserver.varyHunger/varyThirst continuam válidos.
function tvRP.varyHunger(variation)
    local user_id = vRP.getUserId(source)
    if user_id and needsEnabled then
        return vRP.varyHunger(user_id, variation)
    end
    return false
end

function tvRP.varyThirst(variation)
    local user_id = vRP.getUserId(source)
    if user_id and needsEnabled then
        return vRP.varyThirst(user_id, variation)
    end
    return false
end

loadNeedsState()
loadNeedsSettings()
GlobalState.needsEnabled = needsEnabled
publishNeedsSettings()

AddEventHandler("vRP:playerJoin", function(user_id, source)
    local data = ensureData(user_id)
    if data then
        syncPlayer(user_id, source)
    end
end)

AddEventHandler("vRP:playerSpawn", function(user_id, source, first_spawn)
    if not first_spawn then
        syncPlayer(user_id, source)
        return
    end

    CreateThread(function()
        Wait(1000)
        syncPlayer(user_id, source)
    end)
end)

-- Desgaste autoritativo no servidor. Não depende do FPS, velocidade do player
-- ou de eventos client-side, evitando desync e manipulação local.
CreateThread(function()
    local waitMs = math.max(1000, math.floor(tonumber(NeedsConfig.tickMs) or 10000))
    local minuteFactor = waitMs / 60000.0

    while true do
        Wait(waitMs)
        if needsEnabled then
            -- Lê os valores atuais a cada ciclo; alterações feitas pelo Painel ADM
            -- passam a valer imediatamente, sem restart da vRP.
            local hungerIncrease = (tonumber(needsSettings.hungerPerMinute) or 0) * minuteFactor
            local thirstIncrease = (tonumber(needsSettings.thirstPerMinute) or 0) * minuteFactor

            for user_id, source in pairs(vRP.getUsers() or {}) do
                user_id = tonumber(user_id)
                source = tonumber(source)
                local data = user_id and ensureData(user_id)
                if data then
                    data.hunger = clamp(data.hunger + hungerIncrease, 0, 100)
                    data.thirst = clamp(data.thirst + thirstIncrease, 0, 100)
                    syncPlayer(user_id, source)
                end
            end
        end
    end
end)

-- Dano por fome/sede zerada. O limite mínimo evita atropelar o sistema de coma
-- da base; a partir dali o survival existente continua responsável pelo jogador.
CreateThread(function()
    local waitMs = math.max(1000, math.floor(tonumber(NeedsConfig.starvationCheckMs) or 10000))
    local minimumHealth = math.max(101, math.floor(tonumber(NeedsConfig.minimumHealth) or 105))

    while true do
        Wait(waitMs)
        if needsEnabled then
            for user_id, source in pairs(vRP.getUsers() or {}) do
                user_id = tonumber(user_id)
                source = tonumber(source)
                local data = user_id and ensureData(user_id)
                if data and source then
                    local damage = 0
                    if data.hunger >= 100 then
                        damage = damage + math.max(0, math.floor(tonumber(needsSettings.hungerDamage) or 0))
                    end
                    if data.thirst >= 100 then
                        damage = damage + math.max(0, math.floor(tonumber(needsSettings.thirstDamage) or 0))
                    end

                    if damage > 0 then
                        local ped = GetPlayerPed(source)
                        if ped and ped ~= 0 then
                            local health = GetEntityHealth(ped)
                            if health and health > minimumHealth then
                                local appliedDamage = math.min(damage, health - minimumHealth)
                                if appliedDamage > 0 then
                                    vRPclient._varyHealth(source, -appliedDamage)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Ressincronização de segurança para HUDs reiniciadas em runtime.
CreateThread(function()
    local waitMs = math.max(5000, math.floor(tonumber(NeedsConfig.syncEveryMs) or 30000))
    while true do
        Wait(waitMs)
        syncAllPlayers()
    end
end)

exports("areNeedsEnabled", function()
    return vRP.areNeedsEnabled()
end)

exports("setNeedsEnabled", function(enabled)
    return vRP.setNeedsEnabled(enabled)
end)

exports("getNeedsSettings", function()
    return vRP.getNeedsSettings()
end)

exports("setNeedsSettings", function(settings)
    return vRP.setNeedsSettings(settings)
end)

exports("getNeeds", function(user_id)
    return vRP.getNeeds(tonumber(user_id))
end)

exports("consumeNeeds", function(user_id, hungerRestore, thirstRestore)
    return vRP.consumeNeeds(tonumber(user_id), hungerRestore, thirstRestore)
end)
