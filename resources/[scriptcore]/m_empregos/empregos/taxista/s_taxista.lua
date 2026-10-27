-- print('[DEBUG]: Server Taxista Init Sucess')

--[ VARIABLES ]-----------------------------------------------------------------------------------------------------------------

local taxiMeter = {}

--[ FUNCTIONS ]-----------------------------------------------------------------------------------------------------------
function src.checkPermission()
	local source = source
	local user_id = vRP.getUserId(source)
	return true
end

local empregado = {}


function src.checkPayment(payment)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return false end

    if not MageEmpregosHasJob(user_id, "Taxista") then
        MageEmpregosLogInvalid(source, "validar corrida de táxi", "Tentativa de validar uma corrida sem estar empregado como Taxista.")
        return false
    end

    local x,y,z = vRPclient.getPosition(source)
    empregado[user_id] = empregado[user_id] or { cooldown = 0, count = 0 }

    if (tonumber(empregado[user_id].cooldown) or 0) <= 0 then
        TriggerClientEvent("vrp_sound:source",source,'coins',0.5)
        empregado[user_id].cooldown = 10
        empregado[user_id].count = 1
        CreateThread(function()
            while empregado[user_id] and (tonumber(empregado[user_id].cooldown) or 0) > 0 do
                empregado[user_id].cooldown = empregado[user_id].cooldown - 1
                Citizen.Wait(1000)
            end
        end)
        return true
    end

    if empregado[user_id].count == 1 then
        empregado[user_id].count = 0
        MageEmpregosLog("job_taxista_suspicious_trigger", {
            actorId = user_id,
            details = ("O validador de corrida do Taxista foi chamado novamente durante o cooldown de segurança.\nValor informado pelo client: %s\nCoordenadas: %.2f, %.2f, %.2f\nTempo restante do cooldown: %ss"):format(
                tostring(payment or "-"), tonumber(x) or 0.0, tonumber(y) or 0.0, tonumber(z) or 0.0, tostring(empregado[user_id].cooldown or 0)
            )
        })
    end
    return false
end

--[ TAXIMETRO | FUNCTION ]-----------------------------------------------------------------------------------------------------------

function round(num, numDecimalPlaces)
  local mult = 5^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.3) / mult
end

function splitString(str, sep)
  if sep == nil then sep = "%s" end

  local t={}
  local i=1

  for str in string.gmatch(str, "([^"..sep.."]+)") do
    t[i] = str
    i = i + 1
  end

  return t
end


function tD(n)
    n = math.ceil(n * 100) / 100
    return n
end