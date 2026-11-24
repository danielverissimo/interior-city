-----------------------------------------------------------------------------------------------------------------------------------------
-- m_animacoes | Premium animation panel + favourites wheel
-----------------------------------------------------------------------------------------------------------------------------------------

local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")

src = {}
Tunnel.bindInterface(GetCurrentResourceName(), src)
vSERVER = Tunnel.getInterface(GetCurrentResourceName())

-----------------------------------------------------------------------------------------------------------------------------------------
-- STATE
-----------------------------------------------------------------------------------------------------------------------------------------
local fov_min = 5.0
local fov_max = 70.0
local binoculos = false
local camera = false
local fov = (fov_max + fov_min) * 0.5

local panelOpen = false
local wheelOpen = false
local favourites = {}
local catalogue = {}
local animationIndex = {}
local favouritesLoaded = false
local wheelActionGuard = false

-----------------------------------------------------------------------------------------------------------------------------------------
-- CATALOGUE
-----------------------------------------------------------------------------------------------------------------------------------------
local function categoryFor(emote)
    local name = string.lower(tostring(emote.nome or ""))

    if emote.carros then
        return "vehicle"
    elseif emote.prop then
        return "props"
    elseif string.sub(name, 1, 6) == "dancar" or string.sub(name, 1, 6) == "tiktok" or string.find(name, "dance", 1, true) then
        return "dance"
    elseif string.sub(name, 1, 4) == "foto" then
        return "photo"
    end

    return "general"
end

local function rebuildCatalogue()
    catalogue = {}
    animationIndex = {}

    for position, emote in ipairs(cfg.animacoes or {}) do
        if emote.nome then
            local entry = {
                id = position,
                nome = tostring(emote.nome),
                category = categoryFor(emote),
                prop = emote.prop ~= nil,
                vehicle = emote.carros == true,
                walk = emote.andar == true,
                loop = emote.loop == true
            }

            if not animationIndex[entry.nome] then
                catalogue[#catalogue + 1] = entry
            end
            animationIndex[entry.nome] = emote
        end
    end
end

rebuildCatalogue()

local function hasFavourite(name)
    for _, value in ipairs(favourites) do
        if value == name then
            return true
        end
    end
    return false
end

local function sanitiseFavourites(list)
    local clean = {}
    local used = {}
    local max = tonumber(cfg.maxFavoritos) or 8

    if type(list) ~= "table" then
        return clean
    end

    for _, name in ipairs(list) do
        name = tostring(name or "")
        if animationIndex[name] and not used[name] and #clean < max then
            used[name] = true
            clean[#clean + 1] = name
        end
    end

    return clean
end

local function loadFavourites(force)
    if favouritesLoaded and not force then
        return favourites
    end

    local result = vSERVER.getFavourites()
    favourites = sanitiseFavourites(result)
    favouritesLoaded = true
    return favourites
end

CreateThread(function()
    Wait(1200)
    loadFavourites(true)
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- ANIMATION EXECUTION
-----------------------------------------------------------------------------------------------------------------------------------------
local signAnimDict = "amb@world_human_bum_freeway@male@base"
local signModels = {
    [GetHashKey("prop_beggers_sign_01")] = true,
    [GetHashKey("prop_beggers_sign_03")] = true,
    [GetHashKey("prop_beggers_sign_04")] = true
}

local function deleteAttachedObject(object, ped)
    if not DoesEntityExist(object) or not IsEntityAttachedToEntity(object, ped) then
        return true
    end

    if NetworkGetEntityIsNetworked(object) and not NetworkHasControlOfEntity(object) then
        NetworkRequestControlOfEntity(object)
        return false
    end

    SetEntityAsMissionEntity(object, true, true)
    DeleteObject(object)
    return not DoesEntityExist(object)
end

local function clearAttachedSigns(ped)
    for _, object in ipairs(GetGamePool("CObject")) do
        if signModels[GetEntityModel(object)] then
            deleteAttachedObject(object, ped)
        end
    end
end

CreateThread(function()
    while true do
        Wait(1500)
        local ped = PlayerPedId()
        if DoesEntityExist(ped) and not IsEntityPlayingAnim(ped, signAnimDict, "base", 3) then
            clearAttachedSigns(ped)
        end
    end
end)

local function stopAnimation()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end

    vRP.DeletarObjeto()
    vRP._stopAnim(false)
end

local function executeAnimation(name)
    local ped = PlayerPedId()
    local emote = animationIndex[tostring(name or "")]

    if not emote or not DoesEntityExist(ped) or GetEntityHealth(ped) <= 100 then
        return false
    end

    vRP.DeletarObjeto()

    if not IsPedInAnyVehicle(ped, false) and not emote.carros then
        if emote.extra then
            emote.extra()
        end

        if emote.pos1 then
            vRP.CarregarObjeto("", "", emote.prop, emote.flag, emote.hand, emote.pos1, emote.pos2, emote.pos3, emote.pos4, emote.pos5, emote.pos6)
        elseif emote.prop then
            vRP.CarregarObjeto(emote.dict, emote.anim, emote.prop, emote.flag, emote.hand)
        elseif emote.dict then
            vRP._playAnim(emote.andar, {{ emote.dict, emote.anim }}, emote.loop)
        else
            vRP._playAnim(false, { task = emote.anim }, false)
        end

        return true
    end

    if IsPedInAnyVehicle(ped, false) and emote.carros then
        local vehicle = GetVehiclePedIsIn(ped, false)

        if (GetPedInVehicleSeat(vehicle, -1) == ped or GetPedInVehicleSeat(vehicle, 1) == ped) and emote.nome == "sexo4" then
            vRP._playAnim(emote.andar, {{ emote.dict, emote.anim }}, emote.loop)
            return true
        elseif (GetPedInVehicleSeat(vehicle, 0) == ped or GetPedInVehicleSeat(vehicle, 2) == ped) and (emote.nome == "sexo5" or emote.nome == "sexo6") then
            vRP._playAnim(emote.andar, {{ emote.dict, emote.anim }}, emote.loop)
            return true
        end
    end

    return false
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- PANEL
-----------------------------------------------------------------------------------------------------------------------------------------
local function closePanel()
    if not panelOpen then return end

    panelOpen = false
    SetNuiFocus(false, false)
    TriggerScreenblurFadeOut(180.0)
    SendNUIMessage({ action = "panel:close" })
end

local function openPanel()
    if panelOpen or wheelOpen then return end

    loadFavourites(false)
    panelOpen = true
    TriggerScreenblurFadeIn(180.0)
    SetNuiFocus(true, true)
    SetCursorLocation(0.5, 0.5)

    SendNUIMessage({
        action = "panel:open",
        animations = catalogue,
        favourites = favourites,
        maxFavourites = tonumber(cfg.maxFavoritos) or 8
    })
end

RegisterCommand(cfg.comandoPainel or "anim", function()
    openPanel()
end, false)

RegisterNUICallback("panelClose", function(_, cb)
    closePanel()
    cb({ ok = true })
end)

RegisterNUICallback("playAnimation", function(data, cb)
    local name = tostring(data and data.name or "")
    closePanel()
    cb({ ok = executeAnimation(name) })
end)

RegisterNUICallback("toggleFavourite", function(data, cb)
    local name = tostring(data and data.name or "")
    if not animationIndex[name] then
        cb({ ok = false, message = "Animação inválida." })
        return
    end

    local result = vSERVER.toggleFavourite(name)
    if type(result) == "table" then
        favourites = sanitiseFavourites(result.favourites)
        favouritesLoaded = true
        cb({
            ok = result.ok == true,
            favourites = favourites,
            message = result.message
        })
    else
        cb({ ok = false, favourites = favourites, message = "Não foi possível salvar os favoritos." })
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- FAVOURITES WHEEL
-- Press O once to open. The wheel remains open until the player clicks a favourite or presses ESC.
-----------------------------------------------------------------------------------------------------------------------------------------
local function closeWheel(execute, name)
    if not wheelOpen or wheelActionGuard then return end

    wheelActionGuard = true
    local selected = tostring(name or "")

    wheelOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "wheel:close" })

    if execute and selected ~= "" and hasFavourite(selected) then
        executeAnimation(selected)
    end

    SetTimeout(80, function()
        wheelActionGuard = false
    end)
end

local function openWheel()
    if panelOpen or wheelOpen or IsPauseMenuActive() then return end

    loadFavourites(false)

    local ped = PlayerPedId()
    if not DoesEntityExist(ped) or GetEntityHealth(ped) <= 100 then return end

    wheelOpen = true
    wheelActionGuard = false

    -- No GTA screen blur here. The NUI already has its own lightweight backdrop and
    -- avoiding screenblur fade in/out prevents flashing when focus changes.
    TriggerScreenblurFadeOut(0.0)
    SetNuiFocus(true, true)
    SetCursorLocation(0.5, 0.5)

    SendNUIMessage({
        action = "wheel:open",
        favourites = favourites,
        maxFavourites = tonumber(cfg.maxFavoritos) or 8
    })
end

RegisterCommand("+m_animacoes_wheel", function()
    openWheel()
end, false)

-- KeyMapping requires a release command for +commands. It intentionally does nothing:
-- releasing O must NOT close or execute the wheel anymore.
RegisterCommand("-m_animacoes_wheel", function()
end, false)

RegisterKeyMapping("+m_animacoes_wheel", "Abrir roleta de animações favoritas", "keyboard", cfg.teclaRoleta or "O")

-- Opens the same full panel used by /anim without releasing NUI focus in between.
-- This keeps the transition from the wheel to the full catalogue immediate and flicker-free.
RegisterNUICallback("wheelOpenPanel", function(_, cb)
    if not wheelOpen or wheelActionGuard then
        cb({ ok = false })
        return
    end

    wheelActionGuard = true
    loadFavourites(false)

    wheelOpen = false
    panelOpen = true

    TriggerScreenblurFadeIn(180.0)
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = "panel:open",
        animations = catalogue,
        favourites = favourites,
        maxFavourites = tonumber(cfg.maxFavoritos) or 8
    })

    cb({ ok = true })

    SetTimeout(80, function()
        wheelActionGuard = false
    end)
end)

RegisterNUICallback("wheelExecute", function(data, cb)
    local name = tostring(data and data.name or "")

    if not wheelOpen or not hasFavourite(name) then
        cb({ ok = false })
        return
    end

    closeWheel(true, name)
    cb({ ok = true })
end)

RegisterNUICallback("wheelCancel", function(_, cb)
    closeWheel(false)
    cb({ ok = true })
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- CANCEL ANIMATION
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("m_animacoes_cancel", function()
    if panelOpen then
        closePanel()
        return
    end

    if wheelOpen then
        closeWheel(false)
        return
    end

    stopAnimation()
end, false)

RegisterKeyMapping("m_animacoes_cancel", "Cancelar animação atual", "keyboard", cfg.teclaCancelar or "F6")

RegisterCommand("desbuga", function()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end

    closePanel()
    closeWheel(false)

    local pending = {}
    for _, object in ipairs(GetGamePool("CObject")) do
        if IsEntityAttachedToEntity(object, ped) then
            pending[#pending + 1] = object
        end
    end

    vRP._stopAnim(false)
    ClearPedSecondaryTask(ped)

    -- Dê tempo para a transferência de controle dos objetos de rede.
    for attempt = 1, 10 do
        if PlayerPedId() ~= ped then return end
        for i = #pending, 1, -1 do
            if deleteAttachedObject(pending[i], ped) then
                table.remove(pending, i)
            end
        end
        if #pending == 0 or attempt == 10 then return end
        Wait(50)
    end
end, false)

-----------------------------------------------------------------------------------------------------------------------------------------
-- /e, /e2, /e3 COMPATIBILITY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("m_anim:emotes")
AddEventHandler("m_anim:emotes", function(name)
    executeAnimation(name)
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- SAFETY / CLEANUP
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("onClientResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    panelOpen = false
    wheelOpen = false
    wheelActionGuard = false

    SetNuiFocus(false, false)
    TriggerScreenblurFadeOut(0.0)

    CreateThread(function()
        Wait(100)
        SendNUIMessage({ action = "ui:reset" })
        SetNuiFocus(false, false)
        TriggerScreenblurFadeOut(0.0)
    end)
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    TriggerScreenblurFadeOut(0.0)
end)

CreateThread(function()
    while true do
        if wheelOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- BINOCULARS / CAMERA (original functionality preserved)
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
    while true do
        local idle = 1000
        if binoculos then
            idle = 1
            local scaleform = RequestScaleformMovie("BINOCULARS")
            while not HasScaleformMovieLoaded(scaleform) do
                Wait(10)
            end

            local cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
            AttachCamToEntity(cam, PlayerPedId(), 0.0, 0.0, 1.0, true)
            SetCamRot(cam, 0.0, 0.0, GetEntityHeading(PlayerPedId()))
            SetCamFov(cam, fov)
            RenderScriptCams(true, false, 0, 1, 0)

            while binoculos do
                BlockWeaponWheelThisFrame()
                local zoomvalue = (1.0 / (fov_max - fov_min)) * (fov - fov_min)
                CheckInputRotation(cam, zoomvalue)
                HandleZoom(cam)
                DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
                Wait(0)
            end

            fov = (fov_max + fov_min) * 0.5
            RenderScriptCams(false, false, 0, 1, 0)
            SetScaleformMovieAsNoLongerNeeded(scaleform)
            DestroyCam(cam, false)
            SetNightvision(false)
            SetSeethrough(false)
        end

        if IsControlJustPressed(0, 38) then
            if IsEntityPlayingAnim(PlayerPedId(), "missfinale_c2mcs_1", "fin_c2_mcs_1_camman", 3) then
                camera = true
            end

            if camera then
                local scaleform = RequestScaleformMovie("breaking_news")
                local scaleform2 = RequestScaleformMovie("security_camera")

                while not HasScaleformMovieLoaded(scaleform) do
                    Wait(10)
                end

                while not HasScaleformMovieLoaded(scaleform2) do
                    Wait(10)
                end

                local cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
                AttachCamToEntity(cam, PlayerPedId(), 0.0, 0.0, 1.0, true)
                SetCamRot(cam, 0.0, 0.0, GetEntityHeading(PlayerPedId()))
                SetCamFov(cam, fov)
                RenderScriptCams(true, false, 0, 1, 0)

                while camera do
                    BlockWeaponWheelThisFrame()
                    local zoomvalue = (1.0 / (fov_max - fov_min)) * (fov - fov_min)
                    CheckInputRotation(cam, zoomvalue)
                    HandleZoom(cam)
                    DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
                    DrawScaleformMovieFullscreen(scaleform2, 255, 255, 255, 255)

                    if IsControlJustPressed(0, 38) then
                        camera = false
                    end
                    Wait(0)
                end

                fov = (fov_max + fov_min) * 0.5
                RenderScriptCams(false, false, 0, 1, 0)
                SetScaleformMovieAsNoLongerNeeded(scaleform)
                SetScaleformMovieAsNoLongerNeeded(scaleform2)
                DestroyCam(cam, false)
                SetNightvision(false)
                SetSeethrough(false)
            end
        end

        Wait(idle)
    end
end)

RegisterNetEvent("binoculos")
AddEventHandler("binoculos", function()
    if IsEntityPlayingAnim(PlayerPedId(), "amb@world_human_binoculars@male@enter", "enter", 3) then
        binoculos = true
        camera = true
    else
        binoculos = false
        camera = false
    end
end)

function CheckInputRotation(cam, zoomvalue)
    local rightAxisX = GetDisabledControlNormal(0, 220)
    local rightAxisY = GetDisabledControlNormal(0, 221)
    local rotation = GetCamRot(cam, 2)

    if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
        local new_z = rotation.z + rightAxisX * -1.0 * 8.0 * (zoomvalue + 0.1)
        local new_x = math.max(math.min(20.0, rotation.x + rightAxisY * -1.0 * 8.0 * (zoomvalue + 0.1)), -89.5)
        SetCamRot(cam, new_x, 0.0, new_z, 2)
    end
end

function HandleZoom(cam)
    if IsControlJustPressed(0, 241) then
        fov = math.max(fov - 10.0, fov_min)
    end

    if IsControlJustPressed(0, 242) then
        fov = math.min(fov + 10.0, fov_max)
    end

    local current_fov = GetCamFov(cam)
    if math.abs(fov - current_fov) < 0.1 then
        fov = current_fov
    end

    SetCamFov(cam, current_fov + (fov - current_fov) * 0.05)
end

function Breaking(text)
    SetTextColour(255, 255, 255, 255)
    SetTextFont(8)
    SetTextScale(1.2, 1.2)
    SetTextWrap(0.0, 1.0)
    SetTextCentre(false)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 205)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(0.2, 0.85)
end
