local resource = GetCurrentResourceName()
local selected, overrides = {}, {}
local function notify(player, kind, message)
    TriggerClientEvent('Notify', player, kind, message, 8)
end
local function applyLocations()
    for org, points in pairs(overrides) do
        if Config.Orgs[org] then
            for index, position in pairs(points) do
                index = tonumber(index)
                if index and (index == 1 or Config.Orgs[org].coords[index]) then
                    Config.Orgs[org].coords[index] = vector3(position.x, position.y, position.z)
                end
            end
        end
    end
end
local ok, data = pcall(json.decode, LoadResourceFile(resource, 'locations.json') or '{}')
if ok and type(data) == 'table' then overrides = data end
applyLocations()
RegisterNetEvent('m_ponto:requestLocations', function()
    TriggerClientEvent('m_ponto:locations', source, overrides)
end)
AddEventHandler('playerDropped', function() selected[source] = nil end)

-- Posicionamento direto pelo console na posicao real de um jogador conectado.
RegisterCommand('pontodp',function(source,args)
    if source~=0 then return end
    local player=tonumber(args[1])
    local ped=player and GetPlayerPed(player) or 0
    if not ped or ped==0 then print('[m_ponto] Jogador nao encontrado. Use pontodp ID_DO_SERVIDOR.');return end
    local position=GetEntityCoords(ped)
    local previous=overrides.Policia
    local updated={}
    for index,point in pairs(previous or {}) do updated[index]=point end
    updated['1']={x=position.x,y=position.y,z=position.z}
    overrides.Policia=updated
    if not SaveResourceFile(resource,'locations.json',json.encode(overrides),-1) then
        overrides.Policia=previous
        print('[m_ponto] Falha ao salvar o ponto da DP.');return
    end
    applyLocations()
    TriggerClientEvent('m_ponto:locations',-1,overrides)
    notify(player,'sucesso','Bate-ponto da Policia colocado aqui na sua posicao. Aproxime-se e pressione E.')
    print(('[m_ponto] DP posicionada no jogador %d: %.4f, %.4f, %.4f'):format(player,position.x,position.y,position.z))
end,false)

RegisterCommand('moverponto', function(player, args)
    local userId = vRP.getUserId(player)
    if not userId or not vRP.hasPermission(userId, ADMIN_PERMISSION) then return end
    local action = tostring(args[1] or ''):lower()
    -- Permite recriar/mover o ponto principal sem visitar o local antigo.
    for org in pairs(Config.Orgs) do
        if action == org:lower() then
            selected[player] = {org=org, index=1}
            action = 'salvar'
            break
        end
    end
    if action == 'cancelar' then
        selected[player] = nil
        notify(player, 'aviso', 'Mudanca de bate-ponto cancelada.')
        return
    end
    local ped = GetPlayerPed(player)
    if not ped or ped == 0 then return end
    local position = GetEntityCoords(ped)
    if action == 'salvar' then
        local target = selected[player]
        if not target then
            notify(player, 'negado', 'Primeiro use /moverponto perto do bate-ponto antigo.')
            return
        end
        local previous = overrides[target.org]
        local nextPoints = {}
        for index, point in pairs(previous or {}) do nextPoints[index] = point end
        nextPoints[tostring(target.index)] = {x=position.x, y=position.y, z=position.z}
        overrides[target.org] = nextPoints
        if not SaveResourceFile(resource, 'locations.json', json.encode(overrides), -1) then
            overrides[target.org] = previous
            notify(player, 'negado', 'Nao foi possivel salvar. O ponto antigo foi mantido.')
            return
        end
        applyLocations()
        TriggerClientEvent('m_ponto:locations', -1, overrides)
        selected[player] = nil
        notify(player, 'sucesso', 'Bate-ponto '..target.org..' movido para sua posicao. O local antigo foi removido.')
        return
    elseif action ~= '' then
        notify(player, 'aviso', 'Use /moverponto policia para colocar o ponto da DP aqui, ou /moverponto perto de outro ponto para move-lo.')
        return
    end
    local nearest, distance = nil, 5.0
    for org, config in pairs(Config.Orgs) do
        for index, point in ipairs(config.coords) do
            local d = #(position-point)
            if d < distance then nearest, distance = {org=org, index=index}, d end
        end
    end
    if not nearest then
        notify(player, 'negado', 'Fique a menos de 5 metros do bate-ponto que deseja mover.')
        return
    end
    selected[player] = nearest
    notify(player, 'sucesso', 'Selecionado: '..nearest.org..'. Va a nova DP e use /moverponto salvar no local desejado.')
end, false)
