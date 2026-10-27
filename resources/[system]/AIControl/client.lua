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
PedDensity = 4.0 --- Quantidade de NPCS que irão aparecer
ScenarioPedDensity = 4.0,4.0 ----- Quantida de de NPCS que irão aparecer por lugar
VehicleDensity = 4.0  ---- Quantidade de NPCS que irão aparecer em veiculos
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
                SetScenarioPedDensityMultiplierThisFrame(ScenarioPedDensity)
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

            Wait(7)
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