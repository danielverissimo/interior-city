local FILE="joalheria.json"
JConfig={name="Joalheria",settings={},rewards={},displays={}}

local function clone(v)
    if type(v)~="table" then return v end
    local o={} for k,x in pairs(v) do o[k]=clone(x) end return o
end

local function load()
    local raw=LoadResourceFile(GetCurrentResourceName(),FILE)
    local ok,data=pcall(json.decode,raw or "{}")
    if ok and type(data)=="table" then JConfig=data else
        print("^1[m_joalheria]^7 joalheria.json inválido.")
    end
end
load()

RegisterNetEvent("m_joalheria:requestConfig",function()
    TriggerClientEvent("m_joalheria:syncConfig",source,JConfig)
end)

exports("getJoalheriaConfig",function() return clone(JConfig) end)
exports("saveJoalheriaConfig",function(payload)
    if type(payload)~="table" or type(payload.settings)~="table" or type(payload.displays)~="table" then
        return false,"Configuração inválida."
    end
    JConfig=clone(payload)
    if not SaveResourceFile(GetCurrentResourceName(),FILE,json.encode(JConfig),-1) then
        return false,"Não foi possível salvar joalheria.json."
    end
    TriggerClientEvent("m_joalheria:syncConfig",-1,JConfig)
    return true
end)
