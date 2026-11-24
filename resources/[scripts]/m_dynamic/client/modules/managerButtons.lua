local history, currentTargets = {}, {}

local function imagePath(image)
    if type(image) ~= 'string' then return nil end
    return './assets/' .. image .. '.svg'
end

local function closeMenu()
    history, currentTargets = {}, {}
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function renderMenu()
    local page = history[#history]
    if not page then return closeMenu() end
    currentTargets = {}
    local targets = {}
    local function add(key, option)
        if type(option) ~= 'table' then return end
        local id = #targets + 1
        currentTargets[id] = option
        targets[id] = {
            id = id, name = option.name or tostring(key),
            type = option.options and 'menu' or 'button',
            image = imagePath(option.image), description = option.description,
            delete = option.delete == true, modal = option.modal == true
        }
    end
    for index, option in ipairs(page.options) do add(index, option) end
    local keys = {}
    for key in pairs(page.options) do
        if type(key) ~= 'number' then keys[#keys+1] = key end
    end
    table.sort(keys)
    for _, key in ipairs(keys) do add(key, page.options[key]) end
    SendNUIMessage({ action = 'open', targets = targets, type = 'menu',
        title = page.title, status = #history > 1 and 'back' or 'close' })
    SetNuiFocus(true, true)
end

local function createMenu(components)
    if type(components) ~= 'table' then return end
    history = {{ title = 'Ações rápidas', options = components }}
    renderMenu()
end

exports('createMenu', createMenu)
exports('createButton', createMenu)

RegisterNUICallback('target', function(data, cb)
    local target = type(data.target) == 'table' and currentTargets[tonumber(data.target.id)]
    if not target then cb(false) return end
    if target.options then
        history[#history+1] = { title = target.name or data.target.name, options = target.options }
        renderMenu()
    elseif type(target.trigger) == 'table' then
        local trigger = target.trigger
        local args = type(trigger.args) == 'table' and trigger.args or {}
        closeMenu()
        if trigger.type == 'command' then
            local command = trigger.name
            for _, value in ipairs(args) do command = command .. ' ' .. tostring(value) end
            ExecuteCommand(command)
        elseif trigger.isServer then
            TriggerServerEvent(trigger.name, table.unpack(args))
        else
            TriggerEvent(trigger.name, table.unpack(args))
        end
    end
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb) closeMenu() cb('ok') end)
RegisterNUICallback('back', function(_, cb)
    if #history > 1 then table.remove(history) renderMenu() else closeMenu() end
    cb('ok')
end)
RegisterNetEvent('dynamic:closeMenu', closeMenu)
AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() then SetNuiFocus(false, false) end
end)