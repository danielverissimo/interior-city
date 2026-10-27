local Tunnel = module('vrp', 'lib/Tunnel')
local Proxy = module('vrp', 'lib/Proxy')
vRP = Proxy.getInterface('vRP')
vRPclient = Tunnel.getInterface('vRP')

Server = {}
Tunnel.bindInterface(GetCurrentResourceName(), Server)
Client = Tunnel.getInterface(GetCurrentResourceName())

local activeTestDrives = {}

local function finishTestDriveSession(playerSource, reason)
    playerSource = tonumber(playerSource)
    if not playerSource then return false end

    local session = activeTestDrives[playerSource]
    if GetPlayerName(playerSource) then
        SetPlayerRoutingBucket(playerSource, 0)
    end
    if not session then return false end

    activeTestDrives[playerSource] = nil
    local user_id = tonumber(session.user_id) or vRP.getUserId(playerSource)
    local elapsed = math.max(0, os.time() - (tonumber(session.startedAt) or os.time()))
    local car = Dealership and Dealership:getCar(session.vehicle) or nil

    DealershipAudit.Log("dealership_testdrive_finished", {
        actorId = user_id,
        actorName = not user_id and (GetPlayerName(playerSource) or "Desconhecido") or nil,
        details = DealershipAudit.VehicleDetails(session.vehicle, car, {
            ("Duração aproximada: **%s segundo(s)**"):format(elapsed),
            ("Motivo do encerramento: **%s**"):format(tostring(reason or "finalizado")),
            ("Concessionária/ponto: **%s**"):format(tostring(session.locationIndex or "-"))
        })
    })

    return true
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PREPARE DEALERSHIP
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
    for k,v in pairs(Prepare) do
        vRP.prepare(k,v)
    end
    vRP.execute("bm_module/dealership/createTable",{})
end)

function Server.getVehicles()
    local source = source

    return Dealership.list
end

function Server.getMyVehicles()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return {} end

    return Dealership:getUserVehicles(user_id)
end

function Server.buyVehicle(vehicle, color)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return { ok = false, message = "Jogador inválido." } end
    if type(vehicle) ~= "table" or type(vehicle.spawn) ~= "string" or vehicle.spawn == "" then
        DealershipAudit.Log("dealership_security_invalid_purchase", {
            actorId=user_id,
            details="Enviou uma estrutura de compra inválida diretamente ao servidor."
        })
        return { ok = false, message = "Veículo inválido." }
    end

    return Dealership:buyVehicle(user_id, source, string.lower(vehicle.spawn), color)
end

function Server.sellVehicle(vehicle)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return { ok = false, message = "Jogador inválido." } end
    if type(vehicle) ~= "string" or vehicle == "" then
        DealershipAudit.Log("dealership_security_invalid_sale", {
            actorId=user_id,
            details="Enviou uma estrutura de venda inválida diretamente ao servidor."
        })
        return { ok = false, message = "Veículo inválido." }
    end

    return Dealership:sellVehicle(user_id, source, string.lower(vehicle))
end

function Server.startTestDrive(vehicle, locationIndex)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return false end

    vehicle = string.lower(tostring(vehicle or ""))
    locationIndex = tonumber(locationIndex)
    local car = Dealership:getCar(vehicle)
    local location = locationIndex and TestDrive.Locations[locationIndex] or nil

    if activeTestDrives[source] then
        DealershipAudit.Log("dealership_security_invalid_testdrive", {
            actorId = user_id,
            details = "Tentou iniciar um novo test-drive enquanto já possuía uma sessão ativa."
        })
        return false
    end

    if vehicle == "" or not car or not location then
        DealershipAudit.Log("dealership_security_invalid_testdrive", {
            actorId = user_id,
            details = ("Solicitação inválida de test-drive. Spawn: `%s` | Ponto: `%s`."):format(vehicle, tostring(locationIndex))
        })
        return false
    end

    local near, detectedIndex = DealershipAudit.IsNearDealership(source, 8.0)
    if not near or tonumber(detectedIndex) ~= locationIndex then
        DealershipAudit.Log("dealership_security_invalid_testdrive", {
            actorId = user_id,
            details = DealershipAudit.VehicleDetails(vehicle, car, {
                ("Tentou iniciar o test-drive fora do ponto informado (**%s**)."):format(tostring(locationIndex)),
                DealershipAudit.CoordsLine(source)
            })
        })
        return false
    end

    local startedAt = os.time()
    activeTestDrives[source] = {
        user_id = user_id,
        vehicle = vehicle,
        locationIndex = locationIndex,
        startedAt = startedAt
    }

    SetPlayerRoutingBucket(source, user_id)
    DealershipAudit.Log("dealership_testdrive_started", {
        actorId = user_id,
        details = DealershipAudit.VehicleDetails(vehicle, car, {
            ("Concessionária/ponto: **%s**"):format(locationIndex),
            ("Tempo máximo configurado: **%s segundo(s)**"):format(tonumber(TestDrive.cooldownTestDriver) or 60),
            ("Distância máxima configurada: **%s m**"):format(tonumber(TestDrive.maxDistanceTestDriver) or 1500.0),
            DealershipAudit.CoordsLine(source)
        })
    })

    -- Watchdog server-side: mesmo que um client manipulado não finalize o teste,
    -- a dimensão privada não permanece ativa indefinidamente.
    local watchdogSource = source
    local watchdogStartedAt = startedAt
    local watchdogMs = (math.max(1, tonumber(TestDrive.cooldownTestDriver) or 60) + 10) * 1000
    SetTimeout(watchdogMs, function()
        local session = activeTestDrives[watchdogSource]
        if session and tonumber(session.startedAt) == watchdogStartedAt then
            finishTestDriveSession(watchdogSource, "encerrado_pelo_watchdog_do_servidor")
        end
    end)

    return true
end

function Server.endTestDrive(reason)
    return finishTestDriveSession(source, reason or "finalizado")
end

-- Compatibilidade com versões antigas do client. Não é mais permitido criar
-- buckets privados arbitrariamente usando este método.
function Server.setDimension(status)
    local source = source
    if status == false then
        if activeTestDrives[source] then
            return finishTestDriveSession(source, "encerramento_legado")
        end
        return false
    end

    local user_id = vRP.getUserId(source)
    if user_id then
        DealershipAudit.Log("dealership_security_invalid_testdrive", {
            actorId = user_id,
            details = "Tentou criar uma dimensão de test-drive pelo método legado sem uma sessão validada."
        })
    end
    return false
end

function Server.getMostSold()
    return Dealership:getTopSoldVehicles()
end

RegisterCommand('conce',function(source,args)
    local user_id=vRP.getUserId(source)
    if not user_id then return end
    if not vRP.hasPermission(user_id,"developer.permissao") then
        DealershipAudit.Log("dealership_security_admin_command_denied", {
            actorId=user_id,
            details=("Tentou utilizar o comando administrativo `/conce` sem possuir `developer.permissao`.\n%s"):format(
                DealershipAudit.CoordsLine(source) or "Coordenadas indisponíveis."
            )
        })
        return
    end

    local spawn=vRP.prompt(source,"Spawn do veículo: ","")
    if not spawn or spawn=="" then return end

    local stock=tonumber(vRP.prompt(source,"Quantidade em estoque: ","0"))
    if not stock or stock<0 then return end

    local ok,msg=exports[GetCurrentResourceName()]:saveDealershipVehicle(spawn,stock,{
        actorId=user_id,
        actorLabel="STAFF",
        source=source,
        origin="comando /conce"
    })
    TriggerClientEvent("Notify",source,ok and "sucesso" or "negado",msg or "Operação concluída.",5)
end,false)


AddEventHandler("playerDropped", function(reason)
    local playerSource = source
    if activeTestDrives[playerSource] then
        finishTestDriveSession(playerSource, "jogador_desconectou: " .. tostring(reason or "sem motivo"))
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for playerSource in pairs(activeTestDrives) do
        if GetPlayerName(playerSource) then
            SetPlayerRoutingBucket(playerSource, 0)
        end
    end
    activeTestDrives = {}
end)

exports('getUserAmountCars', function(user_id)
    return Dealership:getUserAmountCars(user_id)
end)