local display = false

local function RefreshGroupsList()
    local groupNames, blacklistGroups = vSERVER.getGroups()

    SendNUIMessage({
        type = "setGroups",
        groups = groupNames,
        blacklistedGroups = blacklistGroups
    })
end

function ToggleGroupPanel()
    display = not display

    -- Sempre busca a lista atual antes de abrir.
    if display then
        RefreshGroupsList()
    end

    SetNuiFocus(display, display)
    SendNUIMessage({
        type = "toggle",
        status = display
    })
end

RegisterCommand('grupo', function()
    local checkPermission = vSERVER.checkPermission()

    if checkPermission then
        ToggleGroupPanel()
    else
        TriggerEvent("Notify", "negado", "Você não tem permissão para usar este comando.", 5000)
    end
end)

RegisterNUICallback('close', function(data, cb)
    display = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "toggle",
        status = display
    })
    cb('ok')
end)

function src.setUserDetails(userId)
    SendNUIMessage({
        type = "setUserDetails",
        user = vSERVER.getUserDetails(userId)
    })
end

RegisterNUICallback('getUserDetails', function(data, cb)
    SendNUIMessage({
        type = "setUserDetails",
        user = vSERVER.getUserDetails(data.userId)
    })

    cb('ok')
end)

RegisterNUICallback('addGroup', function(data, cb)
    vSERVER.addGroup(data.userId, data.group, data.isOnline)
    cb('ok')
end)

RegisterNUICallback('removeGroup', function(data, cb)
    vSERVER.removeGroup(data.userId, data.group, data.isOnline)
    cb('ok')
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    RefreshGroupsList()
end)

