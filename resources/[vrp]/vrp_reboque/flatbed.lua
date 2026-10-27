local DECOR = {
    FLOAT = 1,
    BOOL = 2,
    INT = 3,
    UNK = 4,
    TIME = 5,
}

local DECORATORS = {
    ["flatbed3_bed"] = DECOR.INT, -- The bed entity
    ["flatbed3_car"] = DECOR.INT, -- The car entity
    ["flatbed3_attached"] = DECOR.BOOL, -- Is a car attached?
    ["flatbed3_lowered"] = DECOR.BOOL, -- Is the bed lowered?
    ["flatbed3_state"] = DECOR.INT, -- Multi-state for the bed
}

for k,v in next, DECORATORS do
    DecorRegister(k, v)
end

function lerp(a, b, t)
    return a + (b - a) * t
end

local LERP_VALUE = 0.0

local lastFlatbed = nil
local lastBed = nil

local backOffset = {vector3(0.0, -4.0, 0.0), vector3(0.0, 0.0, 0.0)}
local loweredOffset = {vector3(0.0, -0.4, -1.0), vector3(12.0, 0.0, 0.0)}
local raisedOffset = {vector3(0.0, -3.8, 0.45), vector3(0.0, 0.0, 0.0)}

local attachmentOffset = {vector3(0.0, 1.5, 0.3), vector3(0.0, 0.0, 0.0)}
local bedController = {vector3(-2.5, -3.8, -1.0), vector3(0.0, 0.0, 0.0)}

local controllerMessageLoweredCar = "OMNI_FB3_INST_LC"
local controllerMessageLoweredNoCar = "OMNI_FB3_INST_LN"
local controllerMessageRaised = "OMNI_FB3_INST_R"

AddTextEntry(controllerMessageLoweredCar, "Pressione ~INPUT_CONTEXT~ para ~y~subir ~w~a rampa.~n~Pressione ~INPUT_DETONATE~ para ~r~soltar ~w~o veiculo.")
AddTextEntry(controllerMessageLoweredNoCar, "Pressione ~INPUT_CONTEXT~ para ~y~subir ~w~a rampa.~n~Pressione ~INPUT_DETONATE~ para ~g~prender ~w~o veiculo.")
AddTextEntry(controllerMessageRaised, "Pressione ~INPUT_CONTEXT~ para ~y~descer ~w~a rampa.")

local function log(text)
    print("[omni_flatbed/client] " .. text)
end

local function requestControl(entity, timeout)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return false
    end

    timeout = timeout or 1000
    local start = GetGameTimer()

    NetworkRequestControlOfEntity(entity)

    while not NetworkHasControlOfEntity(entity) and (GetGameTimer() - start) < timeout do
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    end

    return NetworkHasControlOfEntity(entity)
end

local function drawMarker(pos)
    local plyPos = GetEntityCoords(PlayerPedId(), true)

    if IsPedInAnyVehicle(PlayerPedId(), true) then
        return false
    end

    local dist = #(pos - plyPos)

    if dist < 25.0 then
        DrawMarker(2, pos, vector3(0.0, 0.0, 0.0), vector3(0.0, 0.0, 0.0), vector3(1.0, 1.0, 1.0), 255, 255, 255, 150)

        if dist < 1.5 then
            return true
        end
    end

    return false
end

local function showHelpText(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringTextLabel(text)
    EndTextCommandDisplayHelp(0, 0, 1, -1)
end

local function getVehicleInDirection(coordFrom, coordTo)
    local rayHandle = CastRayPointToPoint(
        coordFrom.x, coordFrom.y, coordFrom.z,
        coordTo.x, coordTo.y, coordTo.z,
        10,
        PlayerPedId(),
        0
    )

    local _, _, _, _, vehicle = GetRaycastResult(rayHandle)
    return vehicle
end

local function setupBedEntity(bed)
    if not bed or bed == 0 or not DoesEntityExist(bed) then
        return 0
    end

    SetEntityAsMissionEntity(bed, true, true)
    SetEntityCollision(bed, true, true)
    FreezeEntityPosition(bed, false)
    SetEntityVisible(bed, true, false)

    local bedNet = ObjToNet(bed)

    if bedNet and bedNet ~= 0 then
        SetNetworkIdExistsOnAllMachines(bedNet, true)
        SetNetworkIdCanMigrate(bedNet, true)
    end

    return bedNet
end

local function createBedForVehicle(veh)
    if not veh or veh == 0 or not DoesEntityExist(veh) then
        return nil
    end

    requestControl(veh, 1000)

    local _, _, _, pos = GetEntityMatrix(veh)

    local bed = CreateObjectNoOffset(
        GetHashKey("inm_flatbed_base"),
        pos.x, pos.y, pos.z,
        true, true, false
    )

    if not bed or bed == 0 or not DoesEntityExist(bed) then
        log("ERRO AO CRIAR BED")
        return nil
    end

    local bedNet = setupBedEntity(bed)

    if not bedNet or bedNet == 0 then
        DeleteEntity(bed)
        log("ERRO AO GERAR NETWORK ID DA BED")
        return nil
    end

    DecorSetInt(veh, "flatbed3_bed", bedNet)

    AttachEntityToEntity(
        bed,
        veh,
        GetEntityBoneIndexByName(veh, "chassis"),
        raisedOffset[1],
        raisedOffset[2],
        0, 0, 1, 0, 0, 1
    )

    lastBed = bed
    log("BED CRIADA E ANEXADA")

    return bed
end

local function getOrCreateBed(veh)
    if not veh or veh == 0 or not DoesEntityExist(veh) then
        return nil
    end

    local bedNet = 0

    if DecorExistOn(veh, "flatbed3_bed") then
        bedNet = DecorGetInt(veh, "flatbed3_bed")
    else
        DecorSetInt(veh, "flatbed3_bed", 0)
    end

    local bed = nil

    if bedNet and bedNet ~= 0 then
        bed = NetToObj(bedNet)

        if not bed or bed == 0 or not DoesEntityExist(bed) then
            log("BED NET INVALIDA, RECRIANDO")
            DecorSetInt(veh, "flatbed3_bed", 0)
            bed = nil
        end
    end

    if not bed or bed == 0 or not DoesEntityExist(bed) then
        bed = createBedForVehicle(veh)
    else
        setupBedEntity(bed)
        lastBed = bed
    end

    return bed
end

local function ensureDecorDefaults(veh)
    if not DecorExistOn(veh, "flatbed3_attached") then
        DecorSetBool(veh, "flatbed3_attached", false)
    end

    if not DecorExistOn(veh, "flatbed3_lowered") then
        DecorSetBool(veh, "flatbed3_lowered", false)
    end

    if not DecorExistOn(veh, "flatbed3_state") then
        DecorSetInt(veh, "flatbed3_state", 0)
    end

    if not DecorExistOn(veh, "flatbed3_car") then
        DecorSetInt(veh, "flatbed3_car", 0)
    end
end

local function safeAttachBed(bed, veh, offsetPos, offsetRot)
    if not bed or bed == 0 or not DoesEntityExist(bed) then
        return false
    end

    if not veh or veh == 0 or not DoesEntityExist(veh) then
        return false
    end

    requestControl(veh, 500)
    requestControl(bed, 500)

    if not IsEntityAttachedToEntity(bed, veh) then
        DetachEntity(bed, false, false)
    else
        DetachEntity(bed, false, false)
    end

    AttachEntityToEntity(
        bed,
        veh,
        GetEntityBoneIndexByName(veh, "chassis"),
        offsetPos,
        offsetRot,
        0, 0, 1, 0, 0, 1
    )

    SetEntityCollision(bed, true, true)
    SetEntityVisible(bed, true, false)

    return true
end


local function keepCarAttachedToBed(car, bed)
    if not car or car == 0 or not DoesEntityExist(car) then
        return false
    end

    if not bed or bed == 0 or not DoesEntityExist(bed) then
        return false
    end

    requestControl(car, 500)
    requestControl(bed, 500)

    if not IsEntityAttachedToEntity(car, bed) then
        AttachEntityToEntity(
            car,
            bed,
            0,
            attachmentOffset[1],
            attachmentOffset[2],
            0, 0, false, false, 2, true
        )
    end

    SetVehicleHandbrake(car, true)
    SetVehicleEngineOn(car, false, true, true)
    SetEntityCollision(car, true, true)
    SetEntityVisible(car, true, false)

    return true
end

Citizen.CreateThread(function()
    log("Flatbed Loading")

    RequestModel(GetHashKey("inm_flatbed_base"))

    while not HasModelLoaded(GetHashKey("inm_flatbed_base")) do
        Wait(0)
    end

    log("Flatbed Loading Complete")

    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, true)

        if veh and veh ~= 0 and DoesEntityExist(veh) and GetEntityModel(veh) ~= GetHashKey("flatbed3") then
            veh = lastFlatbed
        end

        if lastFlatbed and lastFlatbed ~= 0 and not DoesEntityExist(lastFlatbed) then
            log("FLATBED DELETED?")

            if lastBed and lastBed ~= 0 and DoesEntityExist(lastBed) then
                log("BED STILL EXISTS, DELETANDO")
                DeleteEntity(lastBed)
            end

            lastBed = nil
            lastFlatbed = nil
        end

        if veh and veh ~= 0 and DoesEntityExist(veh) and GetEntityModel(veh) == GetHashKey("flatbed3") then
            lastFlatbed = veh

            requestControl(veh, 500)

            local rightDir, fwdDir, upDir, pos = GetEntityMatrix(veh)

            SetVehicleExtra(veh, 1, true)

            local bed = getOrCreateBed(veh)

            if bed and bed ~= 0 and DoesEntityExist(bed) then
                ensureDecorDefaults(veh)

                local attached = DecorGetBool(veh, "flatbed3_attached")
                local lowered = DecorGetBool(veh, "flatbed3_lowered")
                local state = DecorGetInt(veh, "flatbed3_state")

                local carNet = DecorGetInt(veh, "flatbed3_car")
                local car = nil

                if carNet and carNet ~= 0 then
                    car = NetToVeh(carNet)

                    if not car or car == 0 or not DoesEntityExist(car) then
                        DecorSetInt(veh, "flatbed3_car", 0)
                        DecorSetBool(veh, "flatbed3_attached", false)
                        attached = false
                        car = nil
                    end
                end

                -- Se tem veículo preso, mantém ele grudado na rampa sempre.
                -- Isso evita ele soltar sozinho quando anda ou quando a rampa é reanexada.
                if attached and car and car ~= 0 and DoesEntityExist(car) then
                    keepCarAttachedToBed(car, bed)
                end

                local data = bedController
                local x = pos.x + (fwdDir.x * data[1].x) + (rightDir.x * data[1].y) + (upDir.x * data[1].z)
                local y = pos.y + (fwdDir.y * data[1].x) + (rightDir.y * data[1].y) + (upDir.y * data[1].z)
                local z = pos.z + (fwdDir.z * data[1].x) + (rightDir.z * data[1].y) + (upDir.z * data[1].z)
                local controllerPos = vector3(x, y, z)

                if state == 0 then
                    -- Raised
                    if lowered then
                        safeAttachBed(bed, veh, raisedOffset[1], raisedOffset[2])
                        DecorSetBool(veh, "flatbed3_lowered", false)
                        lowered = false
                    else
                        -- Mantem a rampa presa mesmo se o FiveM tentar desincronizar.
                        if not IsEntityAttachedToEntity(bed, veh) then
                            safeAttachBed(bed, veh, raisedOffset[1], raisedOffset[2])
                        end
                    end

                    if drawMarker(controllerPos) then
                        showHelpText(controllerMessageRaised)

                        if IsControlJustPressed(0, 38) then
                            LERP_VALUE = 0.0
                            state = 1
                            DecorSetInt(veh, "flatbed3_state", state)
                        end
                    end

                elseif state == 1 then
                    -- Moving back
                    local offsetPos = raisedOffset[1]
                    local offsetRot = raisedOffset[2]

                    offsetPos = offsetPos + vector3(
                        lerp(0.0, backOffset[1].x, LERP_VALUE),
                        lerp(0.0, backOffset[1].y, LERP_VALUE),
                        lerp(0.0, backOffset[1].z, LERP_VALUE)
                    )

                    offsetRot = offsetRot + vector3(
                        lerp(0.0, backOffset[2].x, LERP_VALUE),
                        lerp(0.0, backOffset[2].y, LERP_VALUE),
                        lerp(0.0, backOffset[2].z, LERP_VALUE)
                    )

                    safeAttachBed(bed, veh, offsetPos, offsetRot)

                    LERP_VALUE = LERP_VALUE + (1.0 * Timestep()) / 4.0

                    if LERP_VALUE >= 1.0 then
                        state = 2
                        DecorSetInt(veh, "flatbed3_state", state)
                        LERP_VALUE = 0.0
                    end

                elseif state == 2 then
                    -- Lowering
                    local offsetPos = raisedOffset[1] + backOffset[1]
                    local offsetRot = raisedOffset[2] + backOffset[2]

                    offsetPos = offsetPos + vector3(
                        lerp(0.0, loweredOffset[1].x, LERP_VALUE),
                        lerp(0.0, loweredOffset[1].y, LERP_VALUE),
                        lerp(0.0, loweredOffset[1].z, LERP_VALUE)
                    )

                    offsetRot = offsetRot + vector3(
                        lerp(0.0, loweredOffset[2].x, LERP_VALUE),
                        lerp(0.0, loweredOffset[2].y, LERP_VALUE),
                        lerp(0.0, loweredOffset[2].z, LERP_VALUE)
                    )

                    safeAttachBed(bed, veh, offsetPos, offsetRot)

                    LERP_VALUE = LERP_VALUE + (1.0 * Timestep()) / 2.0

                    if LERP_VALUE >= 1.0 then
                        state = 3
                        DecorSetInt(veh, "flatbed3_state", state)
                        LERP_VALUE = 0.0
                    end

                elseif state == 3 then
                    -- Lowered
                    local offsetPos = raisedOffset[1] + backOffset[1] + loweredOffset[1]
                    local offsetRot = raisedOffset[2] + backOffset[2] + loweredOffset[2]

                    if not lowered then
                        safeAttachBed(bed, veh, offsetPos, offsetRot)
                        DecorSetBool(veh, "flatbed3_lowered", true)
                        lowered = true
                    else
                        if not IsEntityAttachedToEntity(bed, veh) then
                            safeAttachBed(bed, veh, offsetPos, offsetRot)
                        end
                    end

                    if drawMarker(controllerPos) then
                        if attached then
                            showHelpText(controllerMessageLoweredCar)
                        else
                            showHelpText(controllerMessageLoweredNoCar)
                        end

                        if IsControlJustPressed(0, 38) then
                            LERP_VALUE = 0.0
                            state = 4
                            DecorSetInt(veh, "flatbed3_state", state)
                        end

                        if IsControlJustPressed(0, 47) then
                            if attached and car and car ~= 0 and DoesEntityExist(car) then
                                requestControl(car, 1000)
                                SetVehicleHandbrake(car, false)
                                DetachEntity(car, false, true)
                                DecorSetInt(veh, "flatbed3_car", 0)
                                DecorSetBool(veh, "flatbed3_attached", false)
                                attached = false
                                car = nil
                            else
                                local bedPos = GetEntityCoords(bed, false)
                                local newCar = getVehicleInDirection(
                                    bedPos + vector3(0.0, 0.0, 0.25),
                                    bedPos + vector3(0.0, 0.0, 2.25)
                                )

                                if newCar and newCar ~= 0 and DoesEntityExist(newCar) and newCar ~= veh then
                                    local carPos = GetEntityCoords(newCar, false)

                                    requestControl(newCar, 1500)

                                    SetVehicleHandbrake(newCar, true)
                                    SetVehicleEngineOn(newCar, false, true, true)

                                    AttachEntityToEntity(
                                        newCar,
                                        bed,
                                        0,
                                        attachmentOffset[1],
                                        attachmentOffset[2],
                                        0, 0, false, false, 2, true
                                    )

                                    car = newCar
                                    DecorSetInt(veh, "flatbed3_car", VehToNet(newCar))
                                    DecorSetBool(veh, "flatbed3_attached", true)
                                    attached = true
                                end
                            end
                        end
                    end

                elseif state == 4 then
                    -- Raising
                    local offsetPos = raisedOffset[1] + backOffset[1]
                    local offsetRot = raisedOffset[2] + backOffset[2]

                    offsetPos = offsetPos + vector3(
                        lerp(loweredOffset[1].x, 0.0, LERP_VALUE),
                        lerp(loweredOffset[1].y, 0.0, LERP_VALUE),
                        lerp(loweredOffset[1].z, 0.0, LERP_VALUE)
                    )

                    offsetRot = offsetRot + vector3(
                        lerp(loweredOffset[2].x, 0.0, LERP_VALUE),
                        lerp(loweredOffset[2].y, 0.0, LERP_VALUE),
                        lerp(loweredOffset[2].z, 0.0, LERP_VALUE)
                    )

                    safeAttachBed(bed, veh, offsetPos, offsetRot)

                    LERP_VALUE = LERP_VALUE + (1.0 * Timestep()) / 2.0

                    if LERP_VALUE >= 1.0 then
                        state = 5
                        DecorSetInt(veh, "flatbed3_state", state)
                        LERP_VALUE = 0.0
                    end

                elseif state == 5 then
                    -- Moving forward
                    local offsetPos = raisedOffset[1]
                    local offsetRot = raisedOffset[2]

                    offsetPos = offsetPos + vector3(
                        lerp(backOffset[1].x, 0.0, LERP_VALUE),
                        lerp(backOffset[1].y, 0.0, LERP_VALUE),
                        lerp(backOffset[1].z, 0.0, LERP_VALUE)
                    )

                    offsetRot = offsetRot + vector3(
                        lerp(backOffset[2].x, 0.0, LERP_VALUE),
                        lerp(backOffset[2].y, 0.0, LERP_VALUE),
                        lerp(backOffset[2].z, 0.0, LERP_VALUE)
                    )

                    safeAttachBed(bed, veh, offsetPos, offsetRot)

                    LERP_VALUE = LERP_VALUE + (1.0 * Timestep()) / 4.0

                    if LERP_VALUE >= 1.0 then
                        state = 0
                        DecorSetInt(veh, "flatbed3_state", state)
                        DecorSetBool(veh, "flatbed3_lowered", false)
                        LERP_VALUE = 0.0
                    end

                else
                    LERP_VALUE = 0.0
                    state = 0
                    DecorSetInt(veh, "flatbed3_state", state)
                    DecorSetBool(veh, "flatbed3_lowered", false)
                    safeAttachBed(bed, veh, raisedOffset[1], raisedOffset[2])
                end
            end
        end

        Wait(0)
    end
end)
