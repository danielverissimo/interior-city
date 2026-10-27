-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
local vRP = Proxy.getInterface("vRP")
local vRPclient = Tunnel.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
local cRP = {}
Tunnel.bindInterface("target",cRP)
local vCLIENT = Tunnel.getInterface("target")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONFIG / BASE M_AUX
-----------------------------------------------------------------------------------------------------------------------------------------
local PERMISSIONS = {
    police = "perm.policia",
    medic = "perm.unizk",
    mechanic = "perm.mecanica",
    staff = "perm.ptr.staff"
}

local MAX_BILLING = 500000
local REVIVE_REWARD = 1500
local actionCooldown = {}

local BLOCKED_FULL_REPAIR = {
    [-666449931] = true,
    [-583740866] = true,
    [-515440029] = true,
    [1188805452] = true,
    [-1469423443] = true,
    [897410613] = true,
    [2086007667] = true
}

local REMOVABLE_OBJECTS = {
    [-205311355] = true,
    [1245865676] = true,
    [-874338148] = true
}

-- Mesma base do m_aux: apreensão policial de itens configurados como ilegais.
local ILLEGAL_ITEMS = {
    "dirty_money", "dinheirosujo", "maconha", "cocaina", "lsd", "lockpick", "acido", "acidoc",
    "pacote_componentes", "componenteq", "capuz", "algemas", "adubo", "capsulas", "polvora",
    "tecido", "placa-metal", "placa-clonada", "gatilho", "relogioroubado", "pulseiraroubada",
    "colarroubado", "brincoroubado", "anelroubado", "perfumeroubado", "carteiraroubada",
    "tabletroubado", "keycard", "cartaovirgem", "pendrive", "papel", "ticket", "ticketcorrida",
    "c4", "contador", "linha", "pecadearma",

    "weapon_snspistol_mk2", "ammo_snspistol_mk2", "weapon_pistol_mk2", "ammo_pistol_mk2",
    "weapon_gusenberg", "ammo_gusenberg", "weapon_pistol50", "ammo_pistol50", "weapon_hatchet",
    "weapon_combatpistol", "ammo_combatpistol", "weapon_combatpdw", "ammo_combatpdw",
    "weapon_machinepistol", "ammo_machinepistol", "weapon_smg_mk2", "ammo_smg_mk2",
    "weapon_smg", "ammo_smg", "weapon_assaultsmg", "ammo_assaultsmg",
    "weapon_sawnoffshotgun", "ammo_sawnoffshotgun", "weapon_pumpshotgun_mk2", "ammo_pumpshotgun_mk2",
    "weapon_assaultrifle_mk2", "ammo_assaultrifle_mk2", "weapon_specialcarbine_mk2", "ammo_specialcarbine_mk2",
    "weapon_carbinerifle", "ammo_carbinerifle", "weapon_specialcarbine", "ammo_specialcarbine",
    "weapon_petrolcan", "ammo_petrolcan"
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- HELPERS
-----------------------------------------------------------------------------------------------------------------------------------------
local function notify(source,kind,message,time)
    TriggerClientEvent("Notify",source,kind,message,time or 5000)
end

local function userId(source)
    return source and vRP.getUserId(source) or nil
end

local function hasPermission(source,permission)
    local uid = userId(source)
    return uid and vRP.hasPermission(uid,permission) or false,uid
end

local function isStaff(source)
    local uid = userId(source)
    if not uid then return false,nil end
    return vRP.hasPermission(uid,PERMISSIONS.staff) or vRP.hasPermission(uid,"admin.permissao") or vRP.hasPermission(uid,"developer.permissao"),uid
end

local function getRole(source)
    local staff = isStaff(source)
    if staff then return "staff" end
    local uid = userId(source)
    if not uid then return "player" end
    if vRP.hasPermission(uid,PERMISSIONS.police) then return "police" end
    if vRP.hasPermission(uid,PERMISSIONS.medic) then return "medic" end
    if vRP.hasPermission(uid,PERMISSIONS.mechanic) then return "mechanic" end
    return "player"
end

local function getCoords(source)
    if not source then return nil end
    local x,y,z = vRPclient.getPosition(source)
    x,y,z = tonumber(x),tonumber(y),tonumber(z)
    if not x or not y or not z then return nil end
    return { x = x, y = y, z = z }
end

local function distance(a,b)
    if not a or not b then return math.huge end
    local x = (a.x or 0.0) - (b.x or 0.0)
    local y = (a.y or 0.0) - (b.y or 0.0)
    local z = (a.z or 0.0) - (b.z or 0.0)
    return math.sqrt(x*x + y*y + z*z)
end

local function targetFromPayload(payload)
    if type(payload) == "number" then return tonumber(payload) end
    if type(payload) ~= "table" then return nil end
    -- Vehicle payloads are { plate, model, entity, netId }; never interpret a numeric plate as a player source.
    if payload[4] ~= nil then return nil end
    local candidate = tonumber(payload[1])
    if candidate and candidate > 0 and vRP.getUserId(candidate) then return candidate end
    return nil
end

local function nearestPlayer(source,radius)
    local target = vRPclient.getNearestPlayer(source,radius or 5.0)
    if not target or target == source then return nil,nil end
    local targetId = vRP.getUserId(target)
    if not targetId then return nil,nil end
    return target,targetId
end

local function validPlayerTarget(source,payload,radius)
    local target = targetFromPayload(payload)
    if not target then return nearestPlayer(source,radius) end
    if target == source then return nil,nil end
    local targetId = vRP.getUserId(target)
    if not targetId then return nil,nil end
    if distance(getCoords(source),getCoords(target)) > (radius or 5.0) then return nil,nil end
    return target,targetId
end

local function vehicleNetFromPayload(payload)
    if type(payload) == "number" then return tonumber(payload) end
    if type(payload) ~= "table" then return 0 end
    return tonumber(payload[4]) or tonumber(payload.netId) or 0
end

local function validVehicle(source,payload,radius)
    local netId = vehicleNetFromPayload(payload)
    if netId <= 0 then return nil end
    local ok = vCLIENT.IsVehicleNear(source,netId,radius or 6.0)
    if not ok then return nil end
    return netId
end

local function actionAllowed(source,seconds)
    local now = os.time()
    if actionCooldown[source] and actionCooldown[source] > now then return false end
    actionCooldown[source] = now + (seconds or 1)
    return true
end

local function requireRole(source,roles)
    local role = getRole(source)
    for _,allowed in ipairs(roles) do
        if role == allowed then return true,userId(source),role end
    end
    notify(source,"negado","Você não possui permissão para esta função.")
    return false,nil,role
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TUNNEL PERMISSIONS / COMPATIBILITY
-----------------------------------------------------------------------------------------------------------------------------------------
function cRP.GetRole()
    return getRole(source)
end

function cRP.PermissionPolicia()
    return getRole(source) == "police"
end

function cRP.PermissionParamedico()
    return getRole(source) == "medic"
end

function cRP.PermissionMecanico()
    return getRole(source) == "mechanic"
end

function cRP.PermissionAdmin()
    return getRole(source) == "staff"
end

-- Compatibilidade com versões antigas do target que chamavam esta função.
function cRP.Desativado()
    return getRole(source) == "staff"
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ALGEMAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("vrp_policia:algemar")
AddEventHandler("vrp_policia:algemar",function(payload)
    local source = source
    local uid = userId(source)
    if not uid or not actionAllowed(source,1) then return end

    local target,targetId = validPlayerTarget(source,payload,3.0)
    if not target then return notify(source,"negado","Não há nenhum cidadão próximo.") end

    local cuffed = vRPclient.isHandcuffed(target) == true
    local privileged = vRP.hasPermission(uid,"perm.algemar") or getRole(source) == "staff"

    if not privileged then
        if cuffed then
            local hasKey = (tonumber(vRP.getInventoryItemAmount(uid,"chave_algemas")) or 0) > 0
            local hasCuffs = (tonumber(vRP.getInventoryItemAmount(uid,"algemas")) or 0) > 0
            if not hasKey and not hasCuffs then
                return notify(source,"negado","Você precisa de uma chave de algemas para soltar esta pessoa.")
            end
        else
            if (tonumber(vRP.getInventoryItemAmount(uid,"algemas")) or 0) <= 0 then
                return notify(source,"negado","Você precisa de algemas para realizar esta ação.")
            end
        end
    end

    vRPclient._setHandcuffed(target,not cuffed)
    if cuffed then
        notify(source,"sucesso","Cidadão desalgemado.")
        notify(target,"aviso","Você foi desalgemado.")
    else
        notify(source,"sucesso","Cidadão algemado.")
        notify(target,"aviso","Você foi algemado.")
    end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- COLOCAR / RETIRAR DO VEÍCULO
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("target:cv")
AddEventHandler("target:cv",function(payload)
    local source = source
    local ok = requireRole(source,{"police","medic","staff"})
    if not ok or not actionAllowed(source,1) then return end

    local target = validPlayerTarget(source,payload,5.0)
    if not target then return notify(source,"negado","Não há nenhum cidadão próximo.") end
    if not vRPclient.getNearestVehicle(source,6.0) then return notify(source,"negado","Não há nenhum veículo próximo.") end

    local placed = vRPclient.putInNearestVehicleAsPassenger(target,7.0)
    if placed then notify(source,"sucesso","Cidadão colocado no veículo.") else notify(source,"negado","Não foi possível colocar o cidadão no veículo.") end
end)

RegisterNetEvent("target:rv")
AddEventHandler("target:rv",function(payload)
    local source = source
    local ok = requireRole(source,{"police","medic","staff"})
    if not ok or not actionAllowed(source,1) then return end

    local target = validPlayerTarget(source,payload,6.0)
    if not target then return notify(source,"negado","Não há nenhum cidadão próximo.") end
    vRPclient._ejectVehicle(target)
    notify(source,"sucesso","Cidadão retirado do veículo.")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- COBRAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("target:cobrar")
AddEventHandler("target:cobrar",function(payload)
    local source = source
    local uid = userId(source)
    if not uid or not actionAllowed(source,1) then return end

    local target,targetId = validPlayerTarget(source,payload,5.0)
    if not target then return notify(source,"negado","Não há nenhum cidadão próximo.") end

    local amount = math.floor(tonumber(vRP.prompt(source,"Valor da cobrança:","")) or 0)
    if amount < 1 or amount > MAX_BILLING then
        return notify(source,"negado","Valor de cobrança inválido.")
    end

    if not vRP.request(target,("Deseja pagar a cobrança de R$ %s?"):format(vRP.format(amount)),20) then
        return notify(source,"negado","Cobrança recusada.")
    end

    if not vRP.tryFullPayment(targetId,amount) then
        notify(target,"negado","Você não possui saldo suficiente.")
        return notify(source,"negado","O cidadão não possui saldo suficiente.")
    end

    vRP.giveMoney(uid,amount)
    notify(target,"sucesso",("Pagamento de R$ %s realizado."):format(vRP.format(amount)))
    notify(source,"sucesso",("Você recebeu R$ %s."):format(vRP.format(amount)))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MÉDICO
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("target:deitarpaciente")
AddEventHandler("target:deitarpaciente",function(payload)
    local source = source
    local ok = requireRole(source,{"medic","staff"})
    if not ok or not actionAllowed(source,1) then return end
    local target = validPlayerTarget(source,payload,3.5)
    if not target then return notify(source,"negado","Não há nenhum paciente próximo.") end
    TriggerClientEvent("target:pacienteDeitar",target)
end)

RegisterNetEvent("target:tratamento")
AddEventHandler("target:tratamento",function(payload)
    local source = source
    local ok,uid = requireRole(source,{"medic","staff"})
    if not ok or not actionAllowed(source,1) then return end

    local target,targetId = validPlayerTarget(source,payload,3.5)
    if not target then return notify(source,"negado","Não há nenhum paciente próximo.") end
    if (tonumber(vRPclient.getHealth(target)) or 0) <= 105 then
        return notify(source,"negado","Reanime o paciente antes de iniciar o tratamento.")
    end

    vRPclient._playAnim(source,true,{{"amb@prop_human_parking_meter@female@idle_a","idle_a_female"}},true)
    TriggerClientEvent("progress",source,5,"Diagnosticando")
    TriggerClientEvent("progress",target,5,"Atendimento")
    notify(source,"aviso","Diagnosticando paciente...",5000)
    notify(target,"aviso","Você está sendo atendido.",5000)

    SetTimeout(5000,function()
        local currentSource = vRP.getUserSource(uid)
        local currentTarget = vRP.getUserSource(targetId)
        if not currentSource or not currentTarget then return end
        vRPclient._stopAnim(currentSource,false)
        TriggerClientEvent("target:clientTreatment",currentTarget,400)
        notify(currentSource,"sucesso","Tratamento iniciado.")
        notify(currentTarget,"sucesso","Tratamento iniciado.")
    end)
end)

RegisterNetEvent("target:reanimar")
AddEventHandler("target:reanimar",function(payload)
    local source = source
    local ok,uid = requireRole(source,{"medic","staff"})
    if not ok or not actionAllowed(source,1) then return end

    local target,targetId = validPlayerTarget(source,payload,3.5)
    if not target then return notify(source,"negado","Não há nenhum paciente próximo.") end
    if (tonumber(vRPclient.getHealth(target)) or 400) > 105 then
        return notify(source,"negado","A pessoa precisa estar em coma para ser reanimada.")
    end

    vRPclient._playAnim(source,false,{{"amb@medic@standing@tendtodead@base","base"},{"mini@cpr@char_a@cpr_str","cpr_pumpchest"}},true)
    TriggerClientEvent("progress",source,10,"Reanimando")
    notify(source,"aviso","Reanimação iniciada.",5000)

    SetTimeout(10000,function()
        local currentSource = vRP.getUserSource(uid)
        local currentTarget = vRP.getUserSource(targetId)
        if not currentSource or not currentTarget then return end
        if distance(getCoords(currentSource),getCoords(currentTarget)) > 5.0 then
            vRPclient._stopAnim(currentSource,false)
            return notify(currentSource,"negado","Reanimação cancelada: cidadão se afastou.")
        end
        if (tonumber(vRPclient.getHealth(currentTarget)) or 400) > 105 then
            vRPclient._stopAnim(currentSource,false)
            return notify(currentSource,"aviso","O cidadão já não está em coma.")
        end
        vRPclient._setHealth(currentTarget,300)
        vRPclient._stopAnim(currentSource,false)
        TriggerClientEvent("resetBleeding",currentTarget)
        if getRole(currentSource) == "medic" then vRP.giveMoney(uid,REVIVE_REWARD) end
        notify(currentSource,"sucesso","Cidadão reanimado com sucesso.")
        notify(currentTarget,"sucesso","Você foi reanimado.")
    end)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- APREENSÃO POLICIAL
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("target:apreender")
AddEventHandler("target:apreender",function(payload)
    local source = source
    local ok = requireRole(source,{"police","staff"})
    if not ok or not actionAllowed(source,1) then return end

    local target,targetId = validPlayerTarget(source,payload,5.0)
    if not target then return notify(source,"negado","Não há nenhum cidadão próximo.") end

    local removed = 0
    for _,item in ipairs(ILLEGAL_ITEMS) do
        local amount = tonumber(vRP.getInventoryItemAmount(targetId,item)) or 0
        if amount > 0 and vRP.tryGetInventoryItem(targetId,item,amount,true) then
            removed = removed + amount
        end
    end

    if removed > 0 then
        notify(target,"negado","Seus itens ilegais foram apreendidos.")
        notify(source,"sucesso",("Apreensão concluída: %s item(ns) removido(s)."):format(removed))
    else
        notify(source,"aviso","Nenhum item ilegal configurado foi encontrado com o cidadão.")
    end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PORTA-MALAS / SEQUESTRO
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("target:trunkin")
AddEventHandler("target:trunkin",function(payload)
    local source = source
    if not userId(source) or not actionAllowed(source,1) then return end
    local netId = validVehicle(source,payload,3.0)
    if not netId then return notify(source,"negado","Não há nenhum veículo válido próximo.") end
    TriggerClientEvent("target:clientToggleTrunk",source,netId,false)
end)

RegisterNetEvent("target:sequestrar")
AddEventHandler("target:sequestrar",function(payload)
    local source = source
    local uid = userId(source)
    if not uid or not actionAllowed(source,1) then return end

    local netId = validVehicle(source,payload,4.0)
    if not netId then return notify(source,"negado","Não há nenhum veículo válido próximo.") end

    local target,targetId = nearestPlayer(source,3.5)
    if not target then return notify(source,"negado","Não há nenhum cidadão próximo para sequestrar.") end

    local staff = getRole(source) == "staff"
    local cuffed = vRPclient.isHandcuffed(target) == true
    local health = tonumber(vRPclient.getHealth(target)) or 400
    if not staff and not cuffed and health > 105 then
        return notify(source,"negado","O cidadão precisa estar algemado ou em coma para ser colocado no porta-malas.")
    end

    TriggerClientEvent("target:clientToggleTrunk",target,netId,true)
    notify(source,"sucesso","Ação no porta-malas executada.")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REPAROS
-----------------------------------------------------------------------------------------------------------------------------------------
local function startRepair(source,uid,netId,mode,consumeItem,refundOnCancel)
    if consumeItem and not vRP.tryGetInventoryItem(uid,consumeItem,1,true) then
        if consumeItem == "pneus" then
            return notify(source,"negado","Você precisa de 1 Pneu.")
        end
        return notify(source,"negado","Você precisa de um Kit Reparo.")
    end

    vRPclient._playAnim(source,false,{{"mini@repair","fixing_a_player"}},true)
    TriggerClientEvent("progress",source,10,"Reparando")
    notify(source,"aviso","Reparo iniciado.")

    SetTimeout(10000,function()
        local currentSource = vRP.getUserSource(uid)
        if not currentSource then return end
        if not vCLIENT.IsVehicleNear(currentSource,netId,8.0) then
            vRPclient._stopAnim(currentSource,false)
            if consumeItem and refundOnCancel then vRP.giveInventoryItem(uid,consumeItem,1,true) end
            return notify(currentSource,"negado","Reparo cancelado: o veículo não está mais próximo.")
        end
        TriggerClientEvent("target:clientRepairVehicle",currentSource,netId,mode)
        vRPclient._stopAnim(currentSource,false)
        notify(currentSource,"sucesso","Reparo concluído.")
    end)
end

RegisterNetEvent("target:reparar")
AddEventHandler("target:reparar",function(payload)
    local source = source
    local uid = userId(source)
    if not uid or not actionAllowed(source,1) then return end
    if vRPclient.isInVehicle(source) then return notify(source,"negado","Saia do veículo para realizar o reparo.") end

    local netId = validVehicle(source,payload,5.0)
    if not netId then return notify(source,"negado","Não há nenhum veículo próximo.") end
    local model = tonumber(vCLIENT.GetVehicleModel(source,netId)) or 0
    if BLOCKED_FULL_REPAIR[model] then return notify(source,"negado","Este veículo não pode receber reparo completo por este sistema.") end

    local mechanic = vRP.hasPermission(uid,PERMISSIONS.mechanic)
    startRepair(source,uid,netId,"full",mechanic and nil or "repairkit3",true)
end)

RegisterNetEvent("target:rpneus")
AddEventHandler("target:rpneus",function(payload)
    local source = source
    local uid = userId(source)
    if not uid or not actionAllowed(source,1) then return end
    if vRPclient.isInVehicle(source) then return notify(source,"negado","Saia do veículo para reparar os pneus.") end

    local netId = validVehicle(source,payload,7.0)
    if not netId then return notify(source,"negado","Não há nenhum veículo próximo.") end
    startRepair(source,uid,netId,"tires","pneus",true)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- STAFF
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("target:adminFix")
AddEventHandler("target:adminFix",function(payload)
    local source = source
    local ok = requireRole(source,{"staff"})
    if not ok or not actionAllowed(source,1) then return end
    local netId = validVehicle(source,payload,12.0)
    if not netId then return notify(source,"negado","Veículo inválido ou muito distante.") end
    TriggerClientEvent("target:clientRepairVehicle",source,netId,"full")
    notify(source,"sucesso","Veículo reparado.")
end)

RegisterNetEvent("target:adminDeleteVehicle")
AddEventHandler("target:adminDeleteVehicle",function(payload)
    local source = source
    local ok = requireRole(source,{"staff"})
    if not ok or not actionAllowed(source,1) then return end
    local netId = validVehicle(source,payload,12.0)
    if not netId then return notify(source,"negado","Veículo inválido ou muito distante.") end
    TriggerClientEvent("target:clientDeleteEntity",-1,netId)
    notify(source,"sucesso","Veículo removido.")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVER OBJETO DO TARGET
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("trydeleteobj")
AddEventHandler("trydeleteobj",function(payload)
    local source = source
    if not userId(source) or not actionAllowed(source,1) then return end

    local model,netId
    if type(payload) == "table" then
        model = tonumber(payload[2])
        netId = tonumber(payload[3])
    else
        netId = tonumber(payload)
    end

    if not netId or netId <= 0 then return end
    if model and not REMOVABLE_OBJECTS[model] then return end
    if not vCLIENT.IsEntityNear(source,netId,4.0) then return end

    TriggerClientEvent("target:clientDeleteEntity",-1,netId)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLEANUP
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("playerDropped",function()
    actionCooldown[source] = nil
end)
