-- print('[DEBUG]: Client Eletricista Init Sucess')

local inservice = false
local LADDER_VEHICLE_HASH = 241596819
local LADDER_PROP = `prop_ic_ladder`
-- local LADDER_PROP = `prop_byard_ladder01`
local etapa = 1
local currentPole = nil 
local EscadaObject = nil
local postesReparados = {}   -- [key] = true
local posteAlvo = nil
local posteAlvoKey = nil

local escadaData = nil
local escadaWatchdogRunning = false
local repair_timer = 10

-- Ajustes do emprego de Eletricista.
local SERVICE_GARAGE = vector3(-819.92, -742.11, 23.78)
-- O marcador de conserto permanece exatamente na altura original do emprego.
local REPAIR_MARKER_HEIGHT_OFFSET = 7.20
-- Altura máxima segura que o jogador pode subir na escada antes do topo.
local LADDER_SAFE_CLIMB_OFFSET = 5.95
-- A partir desta altura o E já pode ser usado, sem obrigar o ped a alcançar o fim da escada.
local LADDER_REPAIR_MIN_OFFSET = 5.15
local GARAGE_GUIDE_REMOVE_DISTANCE = 14.0

local garageGuideBlip = nil
local poleBlips = {}
local poleModelSet = {}
local ladderObject = nil
local carryingLadder = false
local vehicleBlockNotifyAt = 0

local function poleKey(ent)
    local c = GetEntityCoords(ent)
    -- arredonda em 0.1m (não muda e evita chave gigante)
    local x = math.floor(c.x * 10 + 0.5)
    local y = math.floor(c.y * 10 + 0.5)
    local z = math.floor(c.z * 10 + 0.5)
    return (x .. "_" .. y .. "_" .. z)
end

local POLE_MODELS = {
    -- postes de energia / telecom (bem comuns)
    `prop_telegraph_01a`,
    `prop_telegraph_01b`,
    `prop_telegraph_01c`,
    `prop_telegraph_01d`,
    `prop_telegraph_01e`,
    `prop_telegraph_02a`,
    `prop_telegraph_02b`,
    `prop_telegraph_03`,
    `prop_telegraph_04a`,
    `prop_telegraph_04b`,
    `prop_telegraph_05a`,
    `prop_telegraph_05b`,
    `prop_telegraph_06a`,
    `prop_telegraph_06b`,
    `prop_telegraph_07a`,
    `prop_telegraph_07b`,

    -- postes/luzes de rua (alguns modelos)
    `prop_streetlight_01`,
    `prop_streetlight_01b`,
    `prop_streetlight_02`,
    `prop_streetlight_03`,
    `prop_streetlight_03b`,
    `prop_streetlight_03c`,
    `prop_streetlight_04`,
    `prop_streetlight_05`,
}

for _, model in ipairs(POLE_MODELS) do
    poleModelSet[model] = true
end

local function removeGarageGuideBlip()
    if garageGuideBlip and DoesBlipExist(garageGuideBlip) then
        SetBlipRoute(garageGuideBlip, false)
        RemoveBlip(garageGuideBlip)
    end
    garageGuideBlip = nil
end

local function createGarageGuideBlip()
    removeGarageGuideBlip()

    garageGuideBlip = AddBlipForCoord(SERVICE_GARAGE.x, SERVICE_GARAGE.y, SERVICE_GARAGE.z)
    SetBlipSprite(garageGuideBlip, 357)
    SetBlipColour(garageGuideBlip, 5)
    SetBlipScale(garageGuideBlip, 0.78)
    SetBlipAsShortRange(garageGuideBlip, false)
    SetBlipRoute(garageGuideBlip, true)
    SetBlipRouteColour(garageGuideBlip, 5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Garagem do veículo de trabalho")
    EndTextCommandSetBlipName(garageGuideBlip)
end

local function removePoleBlip(key)
    local blip = poleBlips[key]
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
    poleBlips[key] = nil
end

local function clearPoleBlips()
    for key, blip in pairs(poleBlips) do
        if blip and DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
        poleBlips[key] = nil
    end
end

local function addPoleBlip(object)
    if not object or object == 0 or not DoesEntityExist(object) then return end

    local key = poleKey(object)
    if postesReparados[key] or poleBlips[key] then return end

    local coords = GetEntityCoords(object)
    if math.abs(coords.x) < 1.0 and math.abs(coords.y) < 1.0 then return end

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 0.28)
    SetBlipAlpha(blip, 190)
    SetBlipAsShortRange(blip, false)
    SetBlipDisplay(blip, 4)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Poste para conserto")
    EndTextCommandSetBlipName(blip)
    poleBlips[key] = blip
end

local function scanLoadedPoles()
    if not inservice then return end

    for _, object in ipairs(GetGamePool("CObject")) do
        if DoesEntityExist(object) and poleModelSet[GetEntityModel(object)] then
            addPoleBlip(object)
        end
    end
end

local function clearElectricianGuides()
    removeGarageGuideBlip()
    clearPoleBlips()
end

local function getNearbyLadderVehicle(pedCoords, radius)
    local closest = 0
    local closestDistance = tonumber(radius) or 3.0

    for _, veh in ipairs(GetGamePool("CVehicle")) do
        if DoesEntityExist(veh) and GetEntityModel(veh) == LADDER_VEHICLE_HASH then
            local distance = #(pedCoords - GetEntityCoords(veh))
            if distance <= closestDistance then
                closest = veh
                closestDistance = distance
            end
        end
    end

    return closest, closestDistance
end

local function storeCarriedLadderAtVehicle()
    local ped = PlayerPedId()
    local pickupDict = "pickup_object"
    local pickupAnim = "pickup_low"

    RequestAnimDict(pickupDict)
    while not HasAnimDictLoaded(pickupDict) do Wait(10) end

    TaskPlayAnim(ped, pickupDict, pickupAnim, 8.0, -8.0, 900, 0, 0, false, false, false)
    Wait(200)

    RemoverEscada()
    etapa = 1
    currentPole = nil
    posteAlvo = nil
    posteAlvoKey = nil

    TriggerEvent("Notify", "sucesso", "Você guardou a escada no veículo.", 8)
end

-----------------------------------------------------------------------------
------ BLIP THREAD
-----------------------------------------------------------------------------

Citizen.CreateThread(function()
    while true do
        local idle = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local distance = #(vec3(coords[1],coords[2],coords[3]) - vec3(cfg.list["Eletricista"]["inicio"][1],cfg.list["Eletricista"]["inicio"][2],cfg.list["Eletricista"]["inicio"][3]))
        if not inservice then
            if distance <= 10.0 then
                idle = 1
                DrawMarker(27,cfg.list["Eletricista"]["inicio"][1],cfg.list["Eletricista"]["inicio"][2],cfg.list["Eletricista"]["inicio"][3] - 0.95,0,0,0,0,0,0,1.5,1.5,1.5,132,102,226,180,0,0,0,1)
                if distance <= 3.0 then
                    DrawText3D(cfg.list["Eletricista"]["inicio"][1],cfg.list["Eletricista"]["inicio"][2],cfg.list["Eletricista"]["inicio"][3], "PRESSIONE  ~b~E~w~  PARA ~y~INICIAR ~w~COMO ELETRICISTA~b~")
        
					if distance <= 1.2 and IsControlJustPressed(0, 38) and vSERVER.checkEmp('Eletricista') and MageJobsBeginService("Eletricista") then
                        init_eletric()
                        createGarageGuideBlip()
                        TriggerEvent("Notify", "sucesso", "Você iniciou o trabalho como eletricista, pegue o veiculo de trabalho.",15)
                        TriggerEvent("Notify", "aviso", "Foi marcado o local de retirada do seu veículo de trabalho.", 10)
					end

                end
            end
        end

        if inservice then
            if distance <= 10.0 then
                idle = 1
                DrawMarker(27,cfg.list["Eletricista"]["inicio"][1],cfg.list["Eletricista"]["inicio"][2],cfg.list["Eletricista"]["inicio"][3] - 0.95,0,0,0,0,0,0,1.5,1.5,1.5,132,102,226,180,0,0,0,1)
                if distance <= 3.0 then
                    DrawText3D(cfg.list["Eletricista"]["inicio"][1],cfg.list["Eletricista"]["inicio"][2],cfg.list["Eletricista"]["inicio"][3], "PRESSIONE  ~b~E~w~  PARA ~r~ENCERRAR ~w~O EXPEDIENTE~b~")

					if distance <= 1.2 and IsControlJustPressed(0, 38) and vSERVER.checkEmp('Eletricista')  then
                        etapa = 1
                        RemoverEscada()
                        deletarEscada()
                        inservice = false
                        MageJobsEndService("Eletricista")
                        clearElectricianGuides()
                        currentPole = nil
                        EscadaObject = nil
                        posteAlvo = nil
                        posteAlvoKey = nil
                        postesReparados = {}
                        TriggerEvent("Notify", "negado", "Você encerrou o expediente, volte quando precisar.",15)
					end

                end
            end
        end

        Citizen.Wait(idle)
    end
end)

function init_eletric()
    inservice = true
    Citizen.CreateThread(function()
        while inservice do
            local idle = 1000
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)

            local vehicles = GetGamePool("CVehicle")

            if etapa == 1 then
                local vehicle, vehicleDistance = getNearbyLadderVehicle(pedCoords, 3.0)

                if vehicle ~= 0 and vehicleDistance <= 3.0 then
                    idle = 1
                    local vehCoords = GetEntityCoords(vehicle)

                    if IsPedInAnyVehicle(ped, false) then
                        DrawText3D(
                            vehCoords.x,
                            vehCoords.y,
                            vehCoords.z + 1.6,
                            "~r~SAIA DO VEÍCULO ~w~PARA PEGAR A ESCADA"
                        )
                    else
                        DrawText3D(
                            vehCoords.x,
                            vehCoords.y,
                            vehCoords.z + 1.6,
                            "~w~PRESSIONE ~g~E~w~ PARA PEGAR A ESCADA"
                        )

                        if vehicleDistance <= 2.0 and IsControlJustPressed(0, 38) then
                            if pegarEscada() then
                                TriggerEvent("Notify", "aviso", "Coloque a escada em um poste para repara-lo.",10)
                                etapa = 2
                            end
                        end
                    end
                end
            end

            if etapa == 2 then
                local ped = PlayerPedId()
                local pedCoords = GetEntityCoords(ped)
                local vehicle, vehicleDistance = getNearbyLadderVehicle(pedCoords, 3.0)

                -- A escada pode ser devolvida ao veículo a qualquer momento antes de ser posicionada.
                if carryingLadder and vehicle ~= 0 and vehicleDistance <= 3.0 then
                    idle = 1
                    local vehCoords = GetEntityCoords(vehicle)
                    DrawText3D(
                        vehCoords.x,
                        vehCoords.y,
                        vehCoords.z + 1.6,
                        "~w~PRESSIONE ~g~E~w~ PARA GUARDAR A ESCADA"
                    )

                    if vehicleDistance <= 2.0 and IsControlJustPressed(0, 38) then
                        storeCarriedLadderAtVehicle()
                    end
                else
                    local pole, dist = getNearestPole(pedCoords, 12.0)
                    if pole and pole ~= 0 and DoesEntityExist(pole) then
                        local key = poleKey(pole)
                        if postesReparados[key] then
                            pole = nil
                        end
                    end

                    if pole and dist <= 3.0 then
                        idle = 1
                        currentPole = pole

                        local poleCoords = GetEntityCoords(pole)
                        DrawText3D(
                            poleCoords.x, poleCoords.y, poleCoords.z + 2.8,
                            "~w~PRESSIONE ~g~E~w~ PARA POSICIONAR A ESCADA"
                        )

                        if dist <= 2.0 and IsControlJustPressed(0, 38) then
                            TriggerEvent("Notify", "aviso", "Suba na escada até o ponto indicado para reparar o poste.",10)
                            colocarEscada()
                            posteAlvo = currentPole
                            posteAlvoKey = poleKey(posteAlvo)
                            etapa = 3
                        end
                    end
                end
            end

            if etapa == 3 then
                local ped = PlayerPedId()
                local pedCoords = GetEntityCoords(ped)

                -- segurança: se perder o poste, volta pra etapa 2
                if not posteAlvo or not DoesEntityExist(posteAlvo) then
                    etapa = 2
                    posteAlvo = nil
                    posteAlvoKey = nil
                else
                    local poleCoords = GetEntityCoords(posteAlvo)

                    -- O marcador permanece EXATAMENTE na posição original do emprego.
                    -- A segurança da escada é feita separadamente e nunca move o poste/marker.
                    local drawPos = vector3(
                        poleCoords.x,
                        poleCoords.y,
                        poleCoords.z + REPAIR_MARKER_HEIGHT_OFFSET
                    )

                    local distToDraw = #(pedCoords - drawPos)
                    local horizontalDistance = math.sqrt(
                        ((pedCoords.x - poleCoords.x) * (pedCoords.x - poleCoords.x)) +
                        ((pedCoords.y - poleCoords.y) * (pedCoords.y - poleCoords.y))
                    )
                    local heightFromPole = pedCoords.z - poleCoords.z

                    -- Impede que o jogador alcance o último trecho da escada e seja lançado do topo.
                    -- Não altera posição do poste, da escada ou do marcador.
                    if horizontalDistance <= 2.2 and heightFromPole >= LADDER_SAFE_CLIMB_OFFSET then
                        idle = 1
                        DisableControlAction(0, 32, true)  -- W / subir
                        DisableControlAction(0, 31, true)  -- eixo frente/trás
                        DisableControlAction(0, 172, true) -- seta para cima
                        DisableControlAction(0, 22, true)  -- pular

                        local velocity = GetEntityVelocity(ped)
                        if velocity.z > 0.0 then
                            SetEntityVelocity(ped, velocity.x, velocity.y, 0.0)
                        end
                    elseif horizontalDistance <= 2.2 and heightFromPole >= 1.50 then
                        DisableControlAction(0, 22, true) -- evita salto acidental enquanto sobe
                    end

                    if distToDraw <= 10.0 then
                        idle = 1
                        DrawText3D(
                            drawPos.x,
                            drawPos.y,
                            drawPos.z,
                            "~w~PRESSIONE ~g~E~w~ PARA CONSERTAR O POSTE"
                        )

                        -- O E pode ser usado numa faixa segura antes do topo. O texto continua
                        -- no local original, mas o jogador não precisa atingir o limite da escada.
                        local canRepairSafely = horizontalDistance <= 1.85
                            and heightFromPole >= LADDER_REPAIR_MIN_OFFSET
                            and heightFromPole <= (LADDER_SAFE_CLIMB_OFFSET + 0.35)

                        if canRepairSafely and IsControlJustPressed(0, 38) then
                            TriggerEvent("Notify", "sucesso", "Você está concertando o poste, aguarde.",10)
                            concertandoPoste()
                        end
                    end
                end
            end

            if etapa == 4 then
                local ped = PlayerPedId()
                local pedCoords = GetEntityCoords(ped)

                local pole, dist = getNearestPole(pedCoords, 12.0) -- raio de busca maior
                if pole and dist <= 3.0 then
                    idle = 1
                    currentPole = pole

                    local poleCoords = GetEntityCoords(pole)
                    DrawText3D(
                        poleCoords.x, poleCoords.y, poleCoords.z + 0.95,
                        "~w~PRESSIONE ~g~E~w~ PARA PEGAR A ESCADA"
                    )

                    if dist <= 2.0 and IsControlJustPressed(0, 38) then
                        TriggerEvent("Notify", "aviso", "Coloque a escada de volta no carro.",10)
                        pegarEscada()
                        deletarEscada()
                        posteAlvo = nil
                        etapa = 5
                    end

                end
            end

            if etapa == 5 then
                local ped = PlayerPedId()
                local pedCoords = GetEntityCoords(ped)
                local vehicle, vehicleDistance = getNearbyLadderVehicle(pedCoords, 3.0)

                if vehicle ~= 0 and vehicleDistance <= 3.0 then
                    idle = 1
                    local vehCoords = GetEntityCoords(vehicle)
                    DrawText3D(
                        vehCoords.x,
                        vehCoords.y,
                        vehCoords.z + 1.6,
                        "~w~PRESSIONE ~g~E~w~ PARA COLOCAR A ESCADA"
                    )

                    if vehicleDistance <= 2.0 and IsControlJustPressed(0, 38) then
                        storeCarriedLadderAtVehicle()
                        TriggerEvent("Notify", "aviso", "Vá até o próximo poste.", 6)
                    end
                end
            end
            

            Citizen.Wait(idle)
        end
    end)
end

function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
end

function loadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
end

function attachLadder(ped)
    if not ladderObject or not DoesEntityExist(ladderObject) then return end

    AttachEntityToEntity(ladderObject, ped, GetPedBoneIndex(ped, 24817),
        0.00, 0.45, 0.00,
        0.0, 90.0, 180.0,
        true, true, false, true, 1, true
    )
end

function ensureCarryAnim(ped)
    if not IsEntityPlayingAnim(ped, "anim@heists@box_carry@", "idle", 3) then
        TaskPlayAnim(ped, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 49, 0, false, false, false)
    end
end

-- Watcher: se desanexar/sumir, recria e reanexa
function startLadderWatcher()
    if carryingLadder then return end
    carryingLadder = true

    Citizen.CreateThread(function()
        while carryingLadder do
            local ped = PlayerPedId()

            -- se o ped morreu / não existe, para
            if not DoesEntityExist(ped) or IsEntityDead(ped) then
                carryingLadder = false
                break
            end

            -- se o objeto sumiu, recria
            if not ladderObject or not DoesEntityExist(ladderObject) then
                local coords = GetEntityCoords(ped)
                loadModel(LADDER_PROP)

                ladderObject = CreateObject(LADDER_PROP, coords.x, coords.y, coords.z, true, true, false)
                SetEntityAsMissionEntity(ladderObject, true, true)

                -- garante network (evita “sumir” por migração)
                local netId = ObjToNet(ladderObject)
                SetNetworkIdCanMigrate(netId, false)
                SetNetworkIdExistsOnAllMachines(netId, true)

                SetEntityCollision(ladderObject, false, false)
                SetEntityCompletelyDisableCollision(ladderObject, true, true)
                FreezeEntityPosition(ladderObject, true)

                attachLadder(ped)
            else
                -- se desanexou por qualquer motivo, reanexa
                if not IsEntityAttachedToEntity(ladderObject, ped) then
                    attachLadder(ped)
                end
            end

            -- garante animação segurando
            ensureCarryAnim(ped)

            Wait(250)
        end
    end)
end

function requestControl(entity, timeoutMs)
    timeoutMs = timeoutMs or 1500
    if not entity or entity == 0 or not DoesEntityExist(entity) then return false end

    local t = GetGameTimer() + timeoutMs
    NetworkRequestControlOfEntity(entity)
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < t do
        Wait(10)
        NetworkRequestControlOfEntity(entity)
    end
    return NetworkHasControlOfEntity(entity)
end

function RemoverEscada()
    local ped = PlayerPedId()

    -- 1) Para o watcher primeiro (pra ele NÃO recriar)
    carryingLadder = false

    -- 2) Para animação
    ClearPedSecondaryTask(ped)

    -- 3) Deleta objeto com controle
    if ladderObject and DoesEntityExist(ladderObject) then
        -- tenta controlar
        requestControl(ladderObject, 2000)

        -- garante que é “mission entity” pro delete funcionar
        SetEntityAsMissionEntity(ladderObject, true, true)

        -- desanexa antes
        DetachEntity(ladderObject, true, true)

        -- tenta deletar de 2 formas
        DeleteEntity(ladderObject)
        DeleteObject(ladderObject)

        -- fallback: força não precisar mais
        SetEntityAsNoLongerNeeded(ladderObject)

        ladderObject = nil
    end
end

function pegarEscada(callback)
    local ped = PlayerPedId()

    if IsPedInAnyVehicle(ped, false) then
        TriggerEvent("Notify", "negado", "Saia do veículo para pegar a escada.", 6)
        return false
    end

    -- limpa antigo
    if ladderObject and DoesEntityExist(ladderObject) then
        DeleteEntity(ladderObject)
        ladderObject = nil
    end

    local pickupDict = "pickup_object"
    local pickupAnim = "pickup_low"

    local carryDict = "anim@heists@box_carry@"
    local carryAnim = "idle"

    loadAnimDict(pickupDict)
    loadAnimDict(carryDict)
    loadModel(LADDER_PROP)

    -- animação pegando
    TaskPlayAnim(ped, pickupDict, pickupAnim, 8.0, -8.0, 900, 0, 0, false, false, false)
    Wait(650)

    -- cria escada (networked)
    local coords = GetEntityCoords(ped)
    ladderObject = CreateObject(LADDER_PROP, coords.x, coords.y, coords.z, true, true, false)
    SetEntityAsMissionEntity(ladderObject, true, true)

    local netId = ObjToNet(ladderObject)
    SetNetworkIdCanMigrate(netId, false)
    SetNetworkIdExistsOnAllMachines(netId, true)

    SetEntityCollision(ladderObject, false, false)
    SetEntityCompletelyDisableCollision(ladderObject, true, true)
    FreezeEntityPosition(ladderObject, true)

    attachLadder(ped)

    -- idle segurando
    TaskPlayAnim(ped, carryDict, carryAnim, 8.0, -8.0, -1, 49, 0, false, false, false)

    -- começa a “proteção” pra não sumir
    startLadderWatcher()

    if callback then callback() end
    return true
end

function getNearestPole(pedCoords, radius)
    local bestObj = nil
    local bestDist = radius + 0.001

    for _,model in ipairs(POLE_MODELS) do
        local obj = GetClosestObjectOfType(pedCoords.x, pedCoords.y, pedCoords.z, radius, model, false, false, false)
        if obj and obj ~= 0 then
            local objCoords = GetEntityCoords(obj)
            local dist = #(pedCoords - objCoords)
            if dist < bestDist then
                bestDist = dist
                bestObj = obj
            end
        end
    end

    return bestObj, bestDist
end

local function norm2D(v)
    local l = math.sqrt(v.x*v.x + v.y*v.y)
    if l < 0.0001 then return vector3(0.0, 1.0, 0.0) end
    return vector3(v.x/l, v.y/l, 0.0)
end

local function loadModel(hash)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
end

function colocarEscada()
    if not currentPole or not DoesEntityExist(currentPole) then return end

    local ped = PlayerPedId()
    local poleCoords = GetEntityCoords(currentPole)
    local pedCoords  = GetEntityCoords(ped)

    local pickupDict = "pickup_object"
    local pickupAnim = "pickup_low"
    loadAnimDict(pickupDict)

    TaskPlayAnim(ped, pickupDict, pickupAnim, 8.0, -8.0, 900, 0, 0, false, false, false)
    Wait(200)

    local dir = norm2D(pedCoords - poleCoords)

    local baseDist = 0.10
    local pitch    = 0.0
    local yawOff   = 25.0

    local basePos = poleCoords + (dir * baseDist)

    local heading = GetHeadingFromVector_2d(poleCoords.x - basePos.x, poleCoords.y - basePos.y)
    heading = (heading + yawOff) % 360.0

    local hash = GetHashKey("hw1_06_ldr_")
    loadModel(hash)

    -- deleta antiga
    if EscadaObject and DoesEntityExist(EscadaObject) then
        DeleteEntity(EscadaObject)
        EscadaObject = nil
    end

    -- ✅ cria LOCAL (não network) pra não “migrar” nem ser alvo comum de cleanup
    EscadaObject = CreateObject(hash, basePos.x, basePos.y, basePos.z, false, false, false)
    SetEntityAsMissionEntity(EscadaObject, true, true)

    PlaceObjectOnGroundProperly(EscadaObject)
    SetEntityRotation(EscadaObject, pitch, 0.0, heading, 2, true)

    FreezeEntityPosition(EscadaObject, true)
    SetEntityCollision(EscadaObject, true, true)
    SetEntityInvincible(EscadaObject, true)
    SetEntityProofs(EscadaObject, true, true, true, true, true, true, true, true)
    SetEntityDynamic(EscadaObject, false)
    SetEntityLodDist(EscadaObject, 1000)

    -- ✅ salva a “receita” pra recriar idêntica se sumir
    escadaData = {
        pos = GetEntityCoords(EscadaObject),
        rot = GetEntityRotation(EscadaObject, 2)
    }

    startEscadaWatchdog()
    RemoverEscada()

    SetModelAsNoLongerNeeded(hash)
    return EscadaObject
end

function deletarEscada()

    escadaData = nil -- ⛔ para o watchdog (não recria mais)

    if EscadaObject and DoesEntityExist(EscadaObject) then
        -- garante controle da entidade (network safe)
        NetworkRequestControlOfEntity(EscadaObject)
        local timeout = GetGameTimer() + 2000
        while not NetworkHasControlOfEntity(EscadaObject) and GetGameTimer() < timeout do
            Wait(10)
            NetworkRequestControlOfEntity(EscadaObject)
        end

        SetEntityAsMissionEntity(EscadaObject, true, true)
        DeleteEntity(EscadaObject)
        DeleteObject(EscadaObject)

        EscadaObject = nil
    end
end

function concertandoPoste()
    local ped = PlayerPedId()

    local animDict = "amb@prop_human_parking_meter@female@idle_a"
    local animName = "idle_a_female"

    -- carrega a animação
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
    end

    -- trava controles durante o conserto
    local repairing = true
    Citizen.CreateThread(function()
        while repairing do
            -- trava movimento
            DisableControlAction(0, 30, true) -- MoveLeftRight
            DisableControlAction(0, 31, true) -- MoveUpDown
            DisableControlAction(0, 21, true) -- sprint
            DisableControlAction(0, 22, true) -- jump
            DisableControlAction(0, 32, true) -- W
            DisableControlAction(0, 33, true) -- S
            DisableControlAction(0, 34, true) -- A
            DisableControlAction(0, 35, true) -- D

            -- trava combate/ações
            DisableControlAction(0, 24, true) -- attack
            DisableControlAction(0, 25, true) -- aim
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 37, true)  -- weapon wheel
            DisablePlayerFiring(ped, true)

            Wait(0)
        end
    end)

    -- animação upper body (funciona na escada)
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 49, 0.0, false, false, false)

    TriggerEvent("progress", repair_timer)
    Wait(repair_timer * 1000)

    -- libera tudo
    repairing = false
    ClearPedSecondaryTask(ped)

    postesReparados[posteAlvoKey] = true
    removePoleBlip(posteAlvoKey)

    TriggerEvent("Notify", "sucesso", "Você concertou este poste, pegue sua escada e vá para o próximo.", 10)

    TriggerServerEvent('m_empregos:upgrade_level')
	TriggerServerEvent('m_empregos:payment')

    etapa = 4
end

function spawnEscadaPersistente()
    if not escadaData then return end

    local hash = GetHashKey("hw1_06_ldr_")
    loadModel(hash)

    -- cria LOCAL (não network) = muito mais difícil de scripts removerem
    -- (se você quiser que outros players vejam, eu te mando a versão server-side depois)
    EscadaObject = CreateObject(hash, escadaData.pos.x, escadaData.pos.y, escadaData.pos.z, false, false, false)

    SetEntityAsMissionEntity(EscadaObject, true, true)
    SetEntityCoordsNoOffset(EscadaObject, escadaData.pos.x, escadaData.pos.y, escadaData.pos.z, false, false, false)
    SetEntityRotation(EscadaObject, escadaData.rot.x, escadaData.rot.y, escadaData.rot.z, 2, true)

    FreezeEntityPosition(EscadaObject, true)
    SetEntityCollision(EscadaObject, true, true)
    SetEntityInvincible(EscadaObject, true)
    SetEntityProofs(EscadaObject, true, true, true, true, true, true, true, true)
    SetEntityDynamic(EscadaObject, false)
    SetEntityLodDist(EscadaObject, 1000)

    SetModelAsNoLongerNeeded(hash)
end

function startEscadaWatchdog()
    if escadaWatchdogRunning then return end
    escadaWatchdogRunning = true

    Citizen.CreateThread(function()
        while escadaData do
            if not EscadaObject or not DoesEntityExist(EscadaObject) then
                -- se alguém deletou, recria
                spawnEscadaPersistente()
            end
            Wait(500)
        end
        escadaWatchdogRunning = false
    end)
end

-- Descobre os postes que estão carregados pelo streaming e os mantém marcados
-- durante o expediente, no mesmo estilo dos pontos do Lixeiro.
Citizen.CreateThread(function()
    while true do
        if inservice then
            scanLoadedPoles()
            Wait(2500)
        else
            Wait(1000)
        end
    end
end)

-- A rota da garagem é apenas uma orientação inicial e some ao chegar.
Citizen.CreateThread(function()
    while true do
        local wait = 1000

        if inservice and garageGuideBlip and DoesBlipExist(garageGuideBlip) then
            local coords = GetEntityCoords(PlayerPedId())
            local distance = #(coords - SERVICE_GARAGE)
            if distance <= GARAGE_GUIDE_REMOVE_DISTANCE then
                removeGarageGuideBlip()
            end
        end

        Citizen.Wait(wait)
    end
end)

-- Enquanto carrega a escada, o jogador não pode entrar em veículos.
Citizen.CreateThread(function()
    while true do
        local wait = 500

        if carryingLadder then
            wait = 0
            local ped = PlayerPedId()

            DisableControlAction(0, 23, true) -- INPUT_ENTER

            if IsDisabledControlJustPressed(0, 23) then
                local now = GetGameTimer()
                if now >= vehicleBlockNotifyAt then
                    vehicleBlockNotifyAt = now + 1800
                    TriggerEvent("Notify", "negado", "Guarde a escada no veículo antes de entrar.", 5)
                end
                ClearPedTasks(ped)
            end

            if IsPedGettingIntoAVehicle(ped) then
                ClearPedTasksImmediately(ped)
            end
        end

        Citizen.Wait(wait)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    clearElectricianGuides()
    RemoverEscada()
    deletarEscada()
end)

Citizen.CreateThread(function()
	while true do
      local trava = 1000
      if inservice then
		trava = 1
			drawTxtEletric("~y~Siga concertando os~r~ POSTES ~w~ Espalhados Pela cidade ",4,0.270,0.905,0.45,255,255,255,200)
			drawTxtEletric("~w~Volte ao local de serviço para ~y~Finalizar ~w~o trabalho",4,0.270,0.93,0.45,255,255,255,200)  
            -- if IsControlJustPressed(0,168) then
            --     etapa = 1
            --     RemoverEscada()
            --     deletarEscada()
            --     inservice = false
            --     local currentPole = nil 
            --     local EscadaObject = nil
            --     local posteAlvo = nil
            --     postesReparados = {} 
            --     TriggerEvent("Notify", "sucesso", "Você encerrou o expediente, volte quando precisar.",15)
            -- end
        end
	  Citizen.Wait(trava)
	end
end)

function drawTxtEletric(text,font,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(r,g,b,a)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end