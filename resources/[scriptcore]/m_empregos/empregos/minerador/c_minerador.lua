-----------------------------------------------------------------------------
------ VARIABLES
-----------------------------------------------------------------------------

local inservice = false
local random = nil
local rock = nil
local rockBlip = nil
local miner_terrain = { 2952.02,2788.46,41.48 }
local etapa = 0
local minerBlip = nil

local britadeira_timer = 10 
local picareta_timer = 10
local coletando_timer = 1 -- nao mexer

local miners_area = {
    [1] = { 2943.14,2796.81,40.69 },
    [2] = { 2930.19,2792.54,39.9 },
    [3] = { 2927.57,2806.67,42.06 },
    [4] = { 2945.44,2813.4,41.64 },
    [5] = { 2968.41,2800.79,40.83 },
    [6] = { 2975.31,2784.4,38.79 },
    [7] = { 2954.39,2788.25,40.96 },
    [8] = { 2938.83,2798.02,40.3 },
    [9] = { 2945.24,2781.17,39.01 },
    [10] = { 2964.89,2790.1,39.51 },
    [11] = { 2951.5,2821.97,42.7 }
}

local sell_location = { -621.94,-230.62,38.05 }

-----------------------------------------------------------------------------
------ BLIP THREAD
-----------------------------------------------------------------------------

Citizen.CreateThread(function()
    while true do
        local idle = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local distance = #(vec3(coords[1],coords[2],coords[3]) - vec3(cfg.list["Minerador"]["inicio"][1],cfg.list["Minerador"]["inicio"][2],cfg.list["Minerador"]["inicio"][3]))
        if not inservice and etapa == 0 then
            if distance <= 10.0 then
                idle = 1
                DrawMarker(27,cfg.list["Minerador"]["inicio"][1],cfg.list["Minerador"]["inicio"][2],cfg.list["Minerador"]["inicio"][3] - 0.95,0,0,0,0,0,0,1.5,1.5,1.5,132,102,226,180,0,0,0,1)
                if distance <= 3.0 then
                    DrawText3D(cfg.list["Minerador"]["inicio"][1],cfg.list["Minerador"]["inicio"][2],cfg.list["Minerador"]["inicio"][3], "PRESSIONE  ~b~E~w~  PARA ~y~INICIAR ~w~A ~b~MINERAÇÃO")
                    
					if distance <= 1.2 and IsControlJustPressed(0, 38) and vSERVER.checkEmp('Minerador')  then
                        minerando()
                        generateMiner()
                        criarAreaMineracao()
                        etapa = 1
                        TriggerEvent("Notify", "sucesso", "A área de mineração foi marcada em seu mapa, colete quantas pedras preciosas conseguir.")
					end

                end
            end
        end
        Citizen.Wait(idle)
    end
end)

-----------------------------------------------------------------------------
------ SELL THREAD
-----------------------------------------------------------------------------

Citizen.CreateThread(function()
    while true do
        local idle = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local distance = #(vec3(coords[1],coords[2],coords[3]) - vec3(sell_location[1],sell_location[2],sell_location[3]))

        if distance <= 10.0 and not inpesca then
            idle = 1
            DrawMarker(27,sell_location[1],sell_location[2],sell_location[3] - 0.95,0,0,0,0,0,0,1.5,1.5,1.5,132,102,226,180,0,0,0,1)
            if distance <= 3.0 then
                DrawText3D(sell_location[1],sell_location[2],sell_location[3], "PRESSIONE  ~b~E~w~  PARA ~g~VENDER~w~ SEUS ~b~MINERIOS")
                
                if distance <= 1.2  and IsControlJustPressed(0, 38) and vSERVER.checkEmp('Minerador') then
                    vSERVER.sellMiner()
                end

            end
        end
        
        Citizen.Wait(idle)
    end
end)

-----------------------------------------------------------------------------
------ MAIN THREAD MINER
-----------------------------------------------------------------------------

function generateMiner()
    Citizen.CreateThread(function()
        while inservice do
            local idle = 1000
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            local point = vec3(
                miners_area[random][1],
                miners_area[random][2],
                miners_area[random][3]
            )

            local distance = #(coords - point)

            if inservice and rock and random and etapa == 1 then

                if distance <= 50.0 then
                    idle = 1

                    DrawMarker(
                        22,
                        point.x, point.y, point.z+1.05,
                        0.0, 0.0, 0.0,        -- direção
                        180.0, 0.0, 0.0,      -- rotação (X = 180°)
                        1.00, 1.00, 1.00,     -- escala
                        0,81,255,100,       -- cor
                        1, 0, 0, 1
                    )

                    

                    if distance <= 15.0 then
                        DrawText3D(
                            point.x, point.y, point.z,
                            "PRESSIONE ~b~E~w~ PARA ~y~USAR ~w~A ~b~BRITADEIRA"
                        )

                        if distance <= 2.0 and IsControlJustPressed(0, 38) then
                            drill()
                        end
                    end
                end
            end

            if inservice and rock and random and etapa == 2 then

                if distance <= 20.0 then
                    idle = 1

                    DrawMarker(27, point.x, point.y, point.z - 0.95,
                        0,0,0,0,0,0,
                        1.5,1.5,1.5,
                        132,102,226,180,
                        0,0,0,1
                    )

                    if distance <= 15.0 then
                        DrawText3D(
                            point.x, point.y, point.z,
                            "PRESSIONE ~b~E~w~ PARA ~y~MINERAR ~w~ESTA ~b~ROCHA"
                        )

                        if distance <= 2.0 and IsControlJustPressed(0, 38) then
                            pickaxe()
                        end
                    end
                end
            end

             if inservice and rock and random and etapa == 3 then
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)

                local point = vec3(
                    miners_area[random][1],
                    miners_area[random][2],
                    miners_area[random][3]
                )

                local distance = #(coords - point)

                if distance <= 20.0 then
                    idle = 1

                    DrawMarker(
                        22,
                        point.x, point.y, point.z+0.5,
                        0.0, 0.0, 0.0,        -- direção
                        180.0, 0.0, 0.0,      -- rotação (X = 180°)
                        0.30, 0.30, 0.30,     -- escala
                        0,81,255,100,       -- cor
                        1, 0, 0, 1
                    )

                    if distance <= 15.0 then
                        DrawText3D(
                            point.x, point.y, point.z,
                            "PRESSIONE ~b~E~w~ PARA ~y~COLETAR ~w~OS ~b~MINERIOS"
                        )

                        if distance <= 2.0 and IsControlJustPressed(0, 38) then
                            pickup()
                            TriggerServerEvent('m_empregos:upgrade_level')
                        end
                    end
                end
            end

            Citizen.Wait(idle)
        end
    end)
end

-----------------------------------------------------------------------------
------ MAIN FUNCTIONS
-----------------------------------------------------------------------------

function minerando()
    if inservice then return end

    inservice = true
    random = math.random(1,#miners_area)

    spawnRock(miners_area[random][1],miners_area[random][2],miners_area[random][3])
    local rockCoords = {
        x = miners_area[random][1],
        y = miners_area[random][2],
        z = miners_area[random][3]
    }
end

function spawnSmallRock(x,y,z)
    local model = GetHashKey("prop_rock_5_smash1")

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end

    rock = CreateObject(
        model,
        x, y, z - 1.0,
        false, false, false
    )

    PlaceObjectOnGroundProperly(rock)
    FreezeEntityPosition(rock, true)
    SetEntityAsMissionEntity(rock, true, true)

    return rock
end

function spawnRock(x,y,z)
    local model = GetHashKey("prop_rock_1_d")

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end

    rock = CreateObject(
        model,
        x, y, z - 1.0,
        false, false, false
    )

    PlaceObjectOnGroundProperly(rock)
    FreezeEntityPosition(rock, true)
    SetEntityAsMissionEntity(rock, true, true)

    return rock
end

function gerarNovaRocha()
    
    if rock then
        deleteRock(rock)
        rock = nil
    end

    if rockBlip then
        RemoveBlip(rockBlip)
        rockBlip = nil
    end


    local old_random = random

    repeat
        random = math.random(1, #miners_area)
    until random ~= old_random

    local rockCoords = vec3(
        miners_area[random][1],
        miners_area[random][2],
        miners_area[random][3]
    )

    -- cria rocha
    rock = spawnRock(rockCoords.x, rockCoords.y, rockCoords.z)

end

function deleteRock(rock)
    if not DoesEntityExist(rock) then return end

    NetworkRequestControlOfEntity(rock)

    local timeout = 0
    while not NetworkHasControlOfEntity(rock) and timeout < 50 do
        Wait(10)
        timeout = timeout + 1
    end

    SetEntityAsMissionEntity(rock, true, true)
    DeleteEntity(rock)
end

function limparRochasArea(center, radius)
    local rockModels = {
        GetHashKey("prop_rock_5_smash1"),
        GetHashKey("prop_rock_4_big"),
        GetHashKey("prop_rock_1_a"),
        GetHashKey("prop_rock_1_b"),
        GetHashKey("prop_rock_1_c"),
        GetHashKey("prop_rock_1_d")
    }

    local objects = GetGamePool("CObject")

    for _,obj in pairs(objects) do
        if DoesEntityExist(obj) then
            local model = GetEntityModel(obj)

            for _,rockModel in pairs(rockModels) do
                if model == rockModel then
                    local coords = GetEntityCoords(obj)
                    local distance = #(coords - center)

                    if distance <= radius then
                        NetworkRequestControlOfEntity(obj)

                        local timeout = 0
                        while not NetworkHasControlOfEntity(obj) and timeout < 50 do
                            Wait(10)
                            timeout = timeout + 1
                        end

                        SetEntityAsMissionEntity(obj, true, true)
                        DeleteEntity(obj)
                    end
                end
            end
        end
    end
end

local lastPos = nil
local lastHeading = nil

function drill()

    local ped = PlayerPedId()

    if not DoesEntityExist(ped) then return end

    -- posição da rocha
    local rockCoords = GetEntityCoords(rock)

    -- heading alinhado com a rocha
    local heading = GetEntityHeading(rock)

    local pedCoords = GetEntityCoords(ped)
    lastPos = vector3(pedCoords.x, pedCoords.y, pedCoords.z)
    lastHeading = GetEntityHeading(ped)

    -- ajusta ped em cima da rocha
    SetEntityCoordsNoOffset(
        ped,
        rockCoords.x,
        rockCoords.y,
        rockCoords.z + 2.7, -- AJUSTE FINO AQUI
        false, false, false
    )

    SetEntityHeading(ped, heading)

    FreezeEntityPosition(ped, true)

    -- inicia a britadeira
    TaskStartScenarioInPlace(
        ped,
        "WORLD_HUMAN_CONST_DRILL",
        0,
        true
    )

    TriggerEvent("progress", britadeira_timer)
    Wait(britadeira_timer*1000)

    
    ClearPedTasksImmediately(ped)
    -- Aguarda 1 frame para o prop spawnar no chão
    Wait(0)
    -- Posição do player
    local coords = GetEntityCoords(ped)
    -- Procura a vara perto do player
    local obj = GetClosestObjectOfType(
        coords.x, coords.y, coords.z,
        2.0,
        GetHashKey("prop_tool_jackham"),
        false, false, false
    )
    if DoesEntityExist(obj) then
        NetworkRequestControlOfEntity(obj)
        SetEntityAsMissionEntity(obj, true, true)
        DeleteEntity(obj)
    end

    Wait(200)

     if lastPos then
        SetEntityCoordsNoOffset(
            ped,
            lastPos.x,
            lastPos.y,
            lastPos.z,
            false, false, false
        )
        SetEntityHeading(ped, lastHeading or 0.0)
    end

    lastPos = nil
    lastHeading = nil

    Wait(200)

    etapa = 2

end

function pickaxe()

    local ped = PlayerPedId()

    local pickaxe = "prop_tool_pickaxe"
    local animDict_p = "amb@world_human_hammering@male@base"
    local animName = "base"

    RequestAnimDict(animDict_p)
    while not HasAnimDictLoaded(animDict_p) do Wait(10) end

    RequestModel(GetHashKey(pickaxe))
    while not HasModelLoaded(GetHashKey(pickaxe)) do Wait(10) end

    local tool = CreateObject(GetHashKey(pickaxe), 1.0,1.0,1.0, true, true, true)

    AttachEntityToEntity(
        tool, ped, GetPedBoneIndex(ped, 57005),
        0.09, 0.03, -0.02,
        -78.0, 13.0, 28.0,
        true, true, false, true, 1, true
    )

    TaskPlayAnim(
        ped,
        animDict_p,
        animName,
        8.0, -8.0,
        -1,
        1, -- 
        0,
        false, false, false
    )

    TriggerEvent("progress", picareta_timer)
    Wait(picareta_timer*1000)

    ClearPedTasks(ped)
    DeleteEntity(tool)

    FreezeEntityPosition(ped, false)

    -- gerarNovaRocha()

    TriggerEvent(
        "Notify",
        "sucesso",
        "Você quebrou a rocha! Colete os minérios."
    )

    Wait(200)

    local rockCoords = GetEntityCoords(rock)

    if rock then
        deleteRock(rock)
        rock = nil
    end

    spawnSmallRock(rockCoords.x,rockCoords.y,rockCoords.z)
    etapa = 3

end

function pickup()

    local ped = PlayerPedId()

    local animDict_p = "pickup_object"
    local animName = "pickup_low"

    if not DoesEntityExist(ped) then return end

    FreezeEntityPosition(ped, true)

    RequestAnimDict(animDict_p)
    while not HasAnimDictLoaded(animDict_p) do Wait(10) end

    TaskPlayAnim(
        ped,
        animDict_p,
        animName,
        8.0, -8.0,
        2000,
        0, -- sem loop
        0,
        false, false, false
    )

    TriggerEvent("progress", coletando_timer)
    Wait(coletando_timer*1000)

    ClearPedTasks(ped)

    FreezeEntityPosition(ped, false)

    Wait(200)
    
    etapa = 1
    gerarNovaRocha()
    vSERVER.pickMinerio()
 
end

function criarAreaMineracao()
    if minerBlip then return end

    minerBlip = AddBlipForRadius(
        miner_terrain[1],
        miner_terrain[2],
        miner_terrain[3],
        50.0 -- raio do círculo (ajuste aqui)
    )

    SetBlipColour(minerBlip, 1) -- 🔴 vermelho
    SetBlipAlpha(minerBlip, 120) -- transparência (0–255)
end

function removerAreaMineracao()
    if minerBlip then
        RemoveBlip(minerBlip)
        minerBlip = nil
    end
end
-----------------------------------------------------------------------------
------ THREAD CANCEL
-----------------------------------------------------------------------------

Citizen.CreateThread(function()
    local ped = PlayerPedId()
	while true do
      local trava = 1000
      if inservice then
		trava = 1

		drawTxtMINER("~y~PRESSIONE ~r~F7 ~w~SE DESEJA FINALIZAR A MINERAÇÃO ",4,0.270,0.905,0.45,255,255,255,200)

        if IsControlJustPressed(0,168) then
            TriggerEvent("Notify", "aviso", "Você saiu de serviço!")
            limparRochasArea(vec3(2950.37,2748.41,43.46), 80.0)
            removerAreaMineracao()
            FreezeEntityPosition(ped, false)
            inservice = false
            etapa = 0
		end

      end
	  Citizen.Wait(trava)
	end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- FUNÇÕES
-----------------------------------------------------------------------------------------------------------------------------------------

function drawTxtMINER(text,font,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(r,g,b,a)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end
