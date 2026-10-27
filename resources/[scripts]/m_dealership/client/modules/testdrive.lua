VehicleEntityCode = VehicleEntityCode or 0
InTestDrive = InTestDrive or false
CountTestDrive = CountTestDrive or 0

local testDriveReturning = false
local activeTestDriveLocation = nil

local function notifyTestDrive(message)
    TriggerEvent("Notify", "negado", message, 5)
end

local function requestVehicleModel(vehicleHash, timeoutMs)
    if not IsModelInCdimage(vehicleHash) or not IsModelAVehicle(vehicleHash) then
        return false
    end

    RequestModel(vehicleHash)
    local deadline = GetGameTimer() + (timeoutMs or 8000)

    while not HasModelLoaded(vehicleHash) do
        if GetGameTimer() >= deadline then
            return false
        end
        RequestModel(vehicleHash)
        Wait(50)
    end

    return true
end

local function deleteTestVehicle()
    if VehicleEntityCode and VehicleEntityCode > 0 and DoesEntityExist(VehicleEntityCode) then
        SetEntityAsMissionEntity(VehicleEntityCode, true, true)
        DeleteVehicle(VehicleEntityCode)
        if DoesEntityExist(VehicleEntityCode) then
            DeleteEntity(VehicleEntityCode)
        end
    end
    VehicleEntityCode = 0
end

local function restoreFromTestDrive(reopenDealership, reason)
    if testDriveReturning then return end
    testDriveReturning = true

    local location = activeTestDriveLocation
    InTestDrive = false
    CountTestDrive = 0

    Server.endTestDrive(tostring(reason or "finalizado"))
    deleteTestVehicle()

    if location then
        DoScreenFadeOut(250)
        local timeout = GetGameTimer() + 1500
        while not IsScreenFadedOut() and GetGameTimer() < timeout do Wait(0) end

        local ped = PlayerPedId()
        SetEntityCoordsNoOffset(ped, location.coords.x, location.coords.y, location.coords.z, false, false, false)
        SetEntityHeading(ped, 0.0)

        Wait(250)
        if reopenDealership then Client.openDealership() end
        DoScreenFadeIn(250)
    else
        DoScreenFadeIn(250)
    end

    activeTestDriveLocation = nil
    testDriveReturning = false
end

function InitializeTestDrive(vehicle, indexLocation)
    if InTestDrive or testDriveReturning then return false end
    if type(vehicle) ~= 'string' or vehicle == '' or type(indexLocation) ~= 'number' then
        notifyTestDrive("Não foi possível identificar o veículo ou a concessionária.")
        return false
    end

    local location = TestDrive.Locations[indexLocation]
    if not location then
        notifyTestDrive("O ponto de test-drive desta concessionária não está configurado.")
        return false
    end

    local vehicleHash = GetHashKey(vehicle)
    if not requestVehicleModel(vehicleHash, 8000) then
        notifyTestDrive("O modelo deste veículo não pôde ser carregado.")
        SetModelAsNoLongerNeeded(vehicleHash)
        return false
    end

    activeTestDriveLocation = location
    DoScreenFadeOut(300)
    local fadeDeadline = GetGameTimer() + 1500
    while not IsScreenFadedOut() and GetGameTimer() < fadeDeadline do Wait(0) end

    if Server.startTestDrive(vehicle, indexLocation) ~= true then
        SetModelAsNoLongerNeeded(vehicleHash)
        activeTestDriveLocation = nil
        DoScreenFadeIn(250)
        notifyTestDrive("Não foi possível preparar a instância do test-drive.")
        return false
    end

    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, location.test_drive.x, location.test_drive.y, location.test_drive.z, false, false, false)
    SetEntityHeading(ped, location.test_drive.w)
    Wait(150)

    local vehicleEntity = CreateVehicle(
        vehicleHash,
        location.test_drive.x,
        location.test_drive.y,
        location.test_drive.z,
        location.test_drive.w,
        false,
        false
    )

    local entityDeadline = GetGameTimer() + 3000
    while vehicleEntity ~= 0 and not DoesEntityExist(vehicleEntity) and GetGameTimer() < entityDeadline do
        Wait(50)
    end

    if vehicleEntity == 0 or not DoesEntityExist(vehicleEntity) or not IsEntityAVehicle(vehicleEntity) then
        if vehicleEntity and vehicleEntity ~= 0 then DeleteEntity(vehicleEntity) end
        SetModelAsNoLongerNeeded(vehicleHash)
        restoreFromTestDrive(true, "falha_criacao_veiculo")
        notifyTestDrive("Não foi possível criar o veículo do test-drive.")
        return false
    end

    VehicleEntityCode = vehicleEntity
    SetEntityAsMissionEntity(vehicleEntity, true, true)
    SetVehicleNumberPlateText(vehicleEntity, "TESTDRIVE")
    SetVehicleOnGroundProperly(vehicleEntity)
    SetVehRadioStation(vehicleEntity, "OFF")
    SetVehicleDirtLevel(vehicleEntity, 0.0)
    SetVehicleDoorsLocked(vehicleEntity, 1)
    SetVehicleEngineHealth(vehicleEntity, 1000.0)
    SetVehicleBodyHealth(vehicleEntity, 1000.0)
    SetVehicleFuelLevel(vehicleEntity, 100.0)
    SetPedIntoVehicle(ped, vehicleEntity, -1)
    SetModelAsNoLongerNeeded(vehicleHash)

    InTestDrive = true
    CountTestDrive = math.max(1, math.floor(tonumber(TestDrive.cooldownTestDriver) or 60))
    Client.closeDealership()
    DoScreenFadeIn(250)

    CreateThread(function()
        local lastSecond = GetGameTimer()
        local maxDistance = tonumber(TestDrive.maxDistanceTestDriver) or 1500.0
        local startCoords = vector3(location.test_drive.x, location.test_drive.y, location.test_drive.z)

        while InTestDrive do
            DrawTXT("Para cancelar o test-drive pressione ~r~F6", 4, 0.5, 0.93, 0.50, 255, 255, 255, 120)
            DrawTXT("Tempo restante: ~b~" .. CountTestDrive .. "~w~ segundo(s)", 4, 0.5, 0.96, 0.50, 255, 255, 255, 120)

            local shouldReturn = false
            local returnReason = "finalizado"
            if IsControlJustPressed(0, 167) then
                shouldReturn = true
                returnReason = "cancelado_pelo_F6"
            elseif not DoesEntityExist(VehicleEntityCode) then
                shouldReturn = true
                returnReason = "veiculo_de_teste_inexistente"
            elseif not IsPedInVehicle(PlayerPedId(), VehicleEntityCode, false) then
                shouldReturn = true
                returnReason = "jogador_saiu_do_veiculo"
            elseif CountTestDrive <= 0 then
                shouldReturn = true
                returnReason = "tempo_encerrado"
            elseif #(GetEntityCoords(PlayerPedId()) - startCoords) > maxDistance then
                shouldReturn = true
                returnReason = "limite_de_distancia"
            end

            if shouldReturn then
                restoreFromTestDrive(true, returnReason)
                break
            end

            local now = GetGameTimer()
            if now - lastSecond >= 1000 then
                local elapsed = math.floor((now - lastSecond) / 1000)
                lastSecond = lastSecond + (elapsed * 1000)
                CountTestDrive = math.max(0, CountTestDrive - elapsed)
            end

            Wait(0)
        end
    end)

    return true
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    InTestDrive = false
    deleteTestVehicle()
end)
