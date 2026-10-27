local FILE="roubocofre.json"
RoubocofreData={name="Roubo a Cofres",settings={},banks={}}
RobConfig={}
BankHeists=BankHeists or {}

local function clone(v)
    if type(v)~="table" then return v end
    local o={} for k,x in pairs(v) do o[k]=clone(x) end return o
end

local function apply()
    RobConfig=clone(RoubocofreData.settings or {})
    local out={}
    for name,b in pairs(RoubocofreData.banks or {}) do
        out[name]={Money=tonumber(b.money) or 0}
    end
    BankHeists=out
end

local function load()
    local raw=LoadResourceFile(GetCurrentResourceName(),FILE)
    local ok,data=pcall(json.decode,raw or "{}")
    if ok and type(data)=="table" then
        RoubocofreData=data
    else
        print("^1[m_roubocofre]^7 roubocofre.json inválido.")
    end
    apply()
end

local function save()
    if not SaveResourceFile(GetCurrentResourceName(),FILE,json.encode(RoubocofreData),-1) then
        return false,"Não foi possível salvar roubocofre.json."
    end
    apply()
    TriggerClientEvent("m_roubocofre:syncConfig",-1,RoubocofreData)
    return true
end

load()

RegisterNetEvent("m_roubocofre:requestConfig",function()
    TriggerClientEvent("m_roubocofre:syncConfig",source,RoubocofreData)
end)

exports("getRoubocofreConfig",function() return clone(RoubocofreData) end)

exports("saveRoubocofreConfig",function(payload)
    if type(payload)~="table" or type(payload.settings)~="table" or type(payload.banks)~="table" then
        return false,"Configuração inválida."
    end
    RoubocofreData=clone(payload)
    RoubocofreData.name=RoubocofreData.name or "Roubo a Cofres"
    return save()
end)
