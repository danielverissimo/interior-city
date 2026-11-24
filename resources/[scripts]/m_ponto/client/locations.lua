RegisterNetEvent('m_ponto:locations', function(overrides)
    if type(overrides) ~= 'table' then return end
    for org, points in pairs(overrides) do
        if Config.Orgs[org] and type(points) == 'table' then
            for index, position in pairs(points) do
                index = tonumber(index)
                if index and (index == 1 or Config.Orgs[org].coords[index]) and type(position) == 'table' then
                    local x,y,z = tonumber(position.x),tonumber(position.y),tonumber(position.z)
                    if x and y and z then Config.Orgs[org].coords[index] = vector3(x,y,z) end
                end
            end
        end
    end
end)
CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(500) end
    Wait(1000)
    TriggerServerEvent('m_ponto:requestLocations')
end)
