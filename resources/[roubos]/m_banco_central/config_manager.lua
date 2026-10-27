local FILE="banco_central.json"
local BankData={name="Banco Central",settings={},banks={}}

local function clone(v)
    if type(v)~="table" then return v end
    local o={} for k,x in pairs(v) do o[k]=clone(x) end return o
end

local function vec3From(v)
    if type(v)~="table" then return vector3(0.0,0.0,0.0) end
    return vector3(tonumber(v[1]) or 0.0,tonumber(v[2]) or 0.0,tonumber(v[3]) or 0.0)
end

local function buildRuntime(data)
    local s=data.settings or {}
    local c={}
    c.SafeMinimum=tonumber(s.safeMinimum) or 0
    c.SafeMax=tonumber(s.safeMax) or 0
    c.Solda=tostring(s.solda or "c4")
    c.itemqtd=math.max(0,math.floor(tonumber(s.itemQtd) or 0))
    c.Furadeira=tostring(s.furadeira or "furadeira")
    c.DinheiroSujo=tostring(s.dinheiroSujo or "dinheirosujo")
    c.Cops=math.max(0,math.floor(tonumber(s.cops) or 0))
    c.PermCops=tostring(s.permCops or "perm.policia")
    c.MinPegar=math.max(0,math.floor(tonumber(s.minPegar) or 0))
    c.MaxPegar=math.max(c.MinPegar,math.floor(tonumber(s.maxPegar) or c.MinPegar))
    c.Tempo=math.max(1,math.floor(tonumber(s.tempoReset) or 1600))
    c.AllowedBags=clone(s.allowedBags or {})
    c.DrillSpawns={}
    for _,p in ipairs(s.drillSpawns or {}) do c.DrillSpawns[#c.DrillSpawns+1]=vec3From(p) end
    c.Boxes=clone(s.boxes or {})
    c.BankRobbery={}

    for i,b in ipairs(data.banks or {}) do
        local rb={Doors={},Safes={},Money={},Hacking={},BankName=tostring(b.bankName or ("Banco "..i))}
        for _,d in ipairs(b.doors or {}) do
            local wd=d.weldPosition or {}
            rb.Doors[#rb.Doors+1]={
                Coords=vec3From(d.coords),Object=tostring(d.object or ""),Heading=tonumber(d.heading) or 0.0,
                OpenHeading=d.openHeading and tonumber(d.openHeading) or nil,
                Hacking=d.hacking==true,Time=tonumber(d.time) or 0,Frozen=d.frozen~=false,
                WeldPosition={C=vec3From(wd.coords),H=tonumber(wd.heading) or 0.0}
            }
        end
        for _,sf in ipairs(b.safes or {}) do
            local cam=sf.cam or {}
            rb.Safes[#rb.Safes+1]={
                Looted=sf.looted==true,Coords=vec3From(sf.coords),Heading=tonumber(sf.heading) or 0.0,
                Cam={From=clone(cam.from or {}),To=clone(cam.to or {})}
            }
        end
        local m=b.money or {}
        rb.Money={
            StartMoney=math.max(0,math.floor(tonumber(m.startMoney) or 0)),
            Amount=math.max(0,math.floor(tonumber(m.amount) or tonumber(m.startMoney) or 0)),
            BoxPosition=vec3From(m.boxPosition),Box=tostring(m.box or "prop_cash_crate_01"),
            Cam=clone(m.cam or {})
        }
        local h=b.hacking or {}
        rb.Hacking={Coords=vec3From(h.coords),Heading=tonumber(h.heading) or 0.0}
        c.BankRobbery[#c.BankRobbery+1]=rb
    end
    return c
end

local function loadData()
    local raw=LoadResourceFile(GetCurrentResourceName(),FILE)
    local ok,data=pcall(json.decode,raw or "{}")
    if not ok or type(data)~="table" then
        print("^1[m_banco_central]^7 banco_central.json inválido.")
        data={name="Banco Central",settings={},banks={}}
    end
    BankData=data
    Config=buildRuntime(BankData)
end

local function saveData()
    if not SaveResourceFile(GetCurrentResourceName(),FILE,json.encode(BankData),-1) then
        return false,"Não foi possível salvar banco_central.json."
    end
    Config=buildRuntime(BankData)
    TriggerClientEvent("m_banco_central:syncConfig",-1,BankData)
    return true
end

loadData()

RegisterNetEvent("m_banco_central:requestConfig",function()
    TriggerClientEvent("m_banco_central:syncConfig",source,BankData)
end)

exports("getBancoCentralConfig",function() return clone(BankData) end)

exports("saveBancoCentralConfig",function(payload)
    if type(payload)~="table" then return false,"Configuração inválida." end
    if type(payload.settings)~="table" or type(payload.banks)~="table" then
        return false,"Estrutura do banco inválida."
    end
    BankData=clone(payload)
    BankData.name=BankData.name or "Banco Central"
    return saveData()
end)
