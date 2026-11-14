local Proxy = module('vrp', 'lib/Proxy')
local vrp = Proxy.getInterface('vRP')
local file = 'deluxe.json'
local ok, config = pcall(json.decode, LoadResourceFile(GetCurrentResourceName(), file) or '{}')
DeluxeConfig = ok and type(config) == 'table' and config or { enabled = false }

local function save(config, player)
    if not SaveResourceFile(GetCurrentResourceName(), file, json.encode(config), -1) then
        TriggerClientEvent('Notify', player, 'negado', 'Não foi possível salvar a concessionária LuxuryMotors.', 5)
        return false
    end
    ApplyDeluxeLocation(config)
    TriggerClientEvent('luxurymotors:syncDeluxe', -1, DeluxeConfig)
    return true
end

local function admin(player)
    local user = vrp.getUserId(player)
    return user and vrp.hasPermission(user, 'developer.permissao')
end

local function placement(player)
    if player <= 0 or not admin(player) then
        if player > 0 then TriggerClientEvent('Notify', player, 'negado', 'Você não tem permissão para configurar a LuxuryMotors.', 5) end
        return
    end
    local ped = GetPlayerPed(player)
    if ped == 0 then return end
    local pos = GetEntityCoords(ped)
    return { pos.x, pos.y, pos.z }, GetEntityHeading(ped)
end

RegisterCommand('setdeluxe', function(player)
    local coords = placement(player)
    if not coords then return end
    local config = { enabled = true, coords = coords, test_drive = DeluxeConfig.test_drive }
    if save(config, player) then
        TriggerClientEvent('Notify', player, 'sucesso', 'Acesso da LuxuryMotors salvo neste local. Use /settestdeluxe em uma área livre para configurar o test-drive.', 8)
    end
end, false)

RegisterCommand('settestdeluxe', function(player)
    local coords, heading = placement(player)
    if not coords then return end
    if not DeluxeConfig.enabled then
        TriggerClientEvent('Notify', player, 'negado', 'Primeiro posicione o acesso com /setdeluxe.', 5)
        return
    end
    local config = { enabled = true, coords = DeluxeConfig.coords, test_drive = { coords[1], coords[2], coords[3], heading } }
    if save(config, player) then TriggerClientEvent('Notify', player, 'sucesso', 'Saída do test-drive da LuxuryMotors salva.', 5) end
end, false)

RegisterCommand('removerdeluxe', function(player)
    if player <= 0 or not admin(player) then return end
    if save({ enabled = false }, player) then TriggerClientEvent('Notify', player, 'sucesso', 'Ponto da LuxuryMotors removido.', 5) end
end, false)
