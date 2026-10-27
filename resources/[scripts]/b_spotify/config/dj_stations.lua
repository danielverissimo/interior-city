-- Configuração das Mesas de DJ
DJConfig = {
    showBlips = true,           -- Mostrar blips no mapa
    interactionDistance = 5.0,  -- Distância para interagir com a mesa
    allowMultipleDJs = true,   -- Permitir múltiplos DJs na mesma mesa
}

-- Estações de DJ disponíveis
DJStations = {
    -- {
    --     name = "Vanilla Unicorn",
    --     coords = vector3(120.5, -1281.0, 29.5), -- Coordenadas da mesa de DJ
    --     range = 60.0,           -- Alcance do som em metros
    --     maxVolume = 90,         -- Volume máximo (0-100)
    --     permission = nil,       -- Permissão necessária (opcional)
    --     requireItem = false,    -- Requer item para usar
    --     item = nil,             -- Item necessário (se requireItem = true)
    --     blip = {
    --         display = true,
    --         sprite = 136,       -- Ícone do blip
    --         color = 27,         -- Cor do blip (rosa)
    --         scale = 0.4
    --     }
    -- },
    -- {
    --     name = "Bahama Mamas",
    --     coords = vector3(-1380.05,-626.98,29.93),
    --     range = 60.0,
    --     maxVolume = 85,
    --     permission = nil,
    --     requireItem = false,
    --     item = nil,
    --     blip = {
    --         display = true,
    --         sprite = 136,
    --         color = 3,          -- Cor azul
    --         scale = 0.4
    --     }
    -- },
    -- {
    --     name = "Tequi-la-la",
    --     coords = vector3(-565.0, 276.5, 83.1),
    --     range = 70.0,
    --     maxVolume = 80,
    --     permission = nil,
    --     requireItem = false,
    --     item = nil,
    --     blip = {
    --         display = true,
    --         sprite = 136,
    --         color = 5,          -- Cor amarela
    --         scale = 0.4
    --     }
    -- },
    -- {
    --     name = "Galaxy Nightclub",
    --     coords = vector3(345.0, 283.5, 105.5),
    --     range = 100.0,          -- Nightclub tem alcance maior
    --     maxVolume = 95,
    --     permission = "dj.galaxy",
    --     requireItem = true,
    --     item = "dj_equipment",  -- Item necessário
    --     blip = {
    --         display = true,
    --         sprite = 136,
    --         color = 8,          -- Cor laranja
    --         scale = 0.4        -- Blip maior para nightclub
    --     }
    -- },
    -- {
    --     name = "Diamond Casino",
    --     coords = vector3(1089.5, 206.0, -49.0),
    --     range = 75.0,
    --     maxVolume = 85,
    --     permission = "dj.casino",
    --     requireItem = false,
    --     item = nil,
    --     blip = {
    --         display = true,
    --         sprite = 136,
    --         color = 4,          -- Cor verde
    --         scale = 0.4
    --     }
    -- }
}

-- Função para obter estação de DJ por índice
function GetDJStation(index)
    if DJStations[index] then
        return DJStations[index]
    end
    return nil
end

-- Função para obter estação de DJ mais próxima
function GetNearestDJStation(coords, maxDistance)
    local nearestStation = nil
    local nearestDistance = maxDistance or math.huge
    local nearestIndex = nil
    
    for i, station in ipairs(DJStations) do
        local distance = #(coords - station.coords)
        if distance < nearestDistance then
            nearestDistance = distance
            nearestStation = station
            nearestIndex = i
        end
    end
    
    return nearestStation, nearestIndex, nearestDistance
end