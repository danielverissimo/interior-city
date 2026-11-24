--CONFIG
EnableDensityControl = true
EnableTrains = true

RemovePedWeapons = true
DisableDropsWeaponsWhenDead = true
DisablePlayerWantedLevel = true
RelationshipBetweenGroups = false
GarbageTrucks = false
RandomBoats = false
CreateRandomCops = false
RandomCopsNotOnScenarios = false
RandomCopsOnScenarios = false
RandomCops = false
RandomCopsNotOnScenarios = false
DisableVehicleDistlights = true
-- As densidades ambientais usam a faixa de 0.0 a 1.0 (populacao normal).
PedDensity = 1.0
ScenarioPedDensity = 1.0
ScenarioPedDensityExterior = 0.5
VehicleDensity = 1.0
RandomVehicle = 0.3 ----  Variação de carros 
ParkedVehicleDensity = 0.0   --- Veiculos estacionados 
ParkedVehicles = 0.0    ----- veiculos estacionados
CopCarSirens = false
AudioScene = "CHARACTER_CHANGE_IN_SKY_SCENE"
AudioFlag = "PoliceScannerDisabled"

--FUNCTIONS
local function DensityControl()
    Citizen.CreateThread(function()
        while true do
            
                SetNumberOfParkedVehicles(ParkedVehicles)
                SetRandomVehicleDensityMultiplierThisFrame(RandomVehicle)
                DisableVehicleDistantlights(DisableVehicleDistlights)
                SetParkedVehicleDensityMultiplierThisFrame(ParkedVehicleDensity)
                SetVehicleDensityMultiplierThisFrame(VehicleDensity)
                SetGarbageTrucks(GarbageTrucks)
                SetRandomBoats(RandomBoats)
                SetCreateRandomCops(RandomCops)
                SetCreateRandomCopsOnScenarios(RandomCopsOnScenarios)
                SetCreateRandomCopsNotOnScenarios(RandomCopsNotOnScenarios)
                SetPedDensityMultiplierThisFrame(PedDensity)
                SetScenarioPedDensityMultiplierThisFrame(ScenarioPedDensity, ScenarioPedDensityExterior)
                StartAudioScene(AudioScene)
                SetAudioFlag(AudioFlag,true)
                DistantCopCarSirens(CopCarSirens)

                EnableDispatchService(4, false)    -- Bombeiros
                EnableDispatchService(5, false)    -- ambulancia 
                EnableDispatchService(6, true)     -- ambulancia e policia  

                if VehicleDensity == 0.0 then
                    local x,y,z = table.unpack(GetEntityCoords(PlayerPedId()))
                    ClearAreaOfVehicles(x,y,z, 1000, false, false, false, false, false)
                    RemoveVehiclesFromGeneratorsInArea(x - 500.0, y - 500.0, z - 500.0, x + 500.0, y + 500.0, z + 500.0);
                end

            Wait(0) -- As natives ThisFrame precisam ser aplicadas a cada frame.
        end
    end)
end

local function AiControl()
    local handle, ped = FindFirstPed()
    local finished = false
    
    repeat
        Wait(300)
        finished, ped = FindNextPed(handle)
        if DoesEntityExist(ped) then
            if not IsPedAPlayer(ped) then
                if RelationshipBetweenGroups then
                    if GetRelationshipBetweenGroups(GetPedRelationshipGroupHash(PlayerPedId()),GetPedRelationshipGroupHash(ped)) ~= 1 and IsPedHuman(ped) == 1 then
                        --SetPedRelationshipGroupHash(PlayerPedId(),GetHashKey('PLAYER'))
                        SetRelationshipBetweenGroups(1, GetHashKey('PLAYER'), GetPedRelationshipGroupHash(ped))
                        SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(ped), GetHashKey('PLAYER'))
                    end
                end
                if RemovePedWeapons then
                    RemoveAllPedWeapons(ped, true)
                end
            end
            if DisableDropsWeaponsWhenDead then
                SetPedDropsWeaponsWhenDead(ped, false)
            end
        end
    until not finished
    EndFindPed(handle)
end

-- Recupera pedestres ambientais ociosos na área simulada por este cliente.
-- Cenários, interações e NPCs de outros resources conservam suas tarefas.
local function canResumeWalking(ped)
    if IsPedAPlayer(ped) or not IsPedHuman(ped) or IsEntityDead(ped) then return false end
    local population = GetEntityPopulationType(ped)
    if population < 1 or population > 5 or IsEntityAMissionEntity(ped) then return false end
    if NetworkGetEntityIsNetworked(ped) and not NetworkHasControlOfEntity(ped) then return false end
    if IsEntityPositionFrozen(ped) or not HasCollisionLoadedAroundEntity(ped) then return false end
    if IsPedInAnyVehicle(ped, true) or IsPedRagdoll(ped) or IsPedFalling(ped) then return false end
    if IsPedFleeing(ped) or IsPedInCombat(ped, 0) or IsPedUsingAnyScenario(ped) then return false end
    if IsPedActiveInScenario(ped) or GetEntitySpeed(ped) >= 0.25 then return false end
    local taskStatus = GetScriptTaskStatus(ped, joaat('SCRIPT_TASK_ANY'))
    return taskStatus == 3 or taskStatus == 7
end

CreateThread(function()
    local idleSince = {}
    while true do
        local now = GetGameTimer()
        local playerCoords = GetEntityCoords(PlayerPedId())
        local nearbyIdle = {}
        for _, ped in ipairs(GetGamePool('CPed')) do
            if DoesEntityExist(ped) and #(GetEntityCoords(ped) - playerCoords) <= 100.0
                and canResumeWalking(ped) then
                local since = idleSince[ped] or now
                if now - since >= 6000 then
                    TaskWanderStandard(ped, 10.0, 10)
                    since = now
                end
                nearbyIdle[ped] = since
            end
        end
        idleSince = nearbyIdle
        Wait(2000)
    end
end)


local function setTrains()
    SwitchTrainTrack(0, true)
    SwitchTrainTrack(3, true)
    SetTrainTrackSpawnFrequency(0, 120000)
    SetTrainTrackSpawnFrequency(3, 120000)
    SetRandomTrains(true)
end

--THREAD
Citizen.CreateThread(function()
    if DisablePlayerWantedLevel then
        SetMaxWantedLevel(0)
    end
    if EnableTrains then
        setTrains()
    end
    if EnableDensityControl then
        DensityControl()
    end
        while true do
            AiControl()
        Wait(100)
    end
end)
