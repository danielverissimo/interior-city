local function clone(v)
    if type(v)~="table" then return v end
    local o={} for k,x in pairs(v) do o[k]=clone(x) end return o
end

local function v3(v)
    return vector3(tonumber(v and v[1]) or 0.0,tonumber(v and v[2]) or 0.0,tonumber(v and v[3]) or 0.0)
end

local function apply(data)
    local s=data.settings or {}
    Config.SafeMinimum=tonumber(s.safeMinimum) or 0
    Config.SafeMax=tonumber(s.safeMax) or 0
    Config.Solda=tostring(s.solda or "c4")
    Config.itemqtd=tonumber(s.itemQtd) or 0
    Config.Furadeira=tostring(s.furadeira or "furadeira")
    Config.DinheiroSujo=tostring(s.dinheiroSujo or "dinheirosujo")
    Config.Cops=tonumber(s.cops) or 0
    Config.PermCops=tostring(s.permCops or "perm.policia")
    Config.MinPegar=tonumber(s.minPegar) or 0
    Config.MaxPegar=tonumber(s.maxPegar) or 0
    Config.Tempo=tonumber(s.tempoReset) or 1600
    Config.AllowedBags=clone(s.allowedBags or {})
    Config.DrillSpawns={}
    for _,p in ipairs(s.drillSpawns or {}) do Config.DrillSpawns[#Config.DrillSpawns+1]=v3(p) end
    Config.Boxes=clone(s.boxes or {})
    Config.BankRobbery={}

    for i,b in ipairs(data.banks or {}) do
        local rb={Doors={},Safes={},Money={},Hacking={},BankName=b.bankName or ("Banco "..i)}
        for _,d in ipairs(b.doors or {}) do
            local wp=d.weldPosition or {}
            rb.Doors[#rb.Doors+1]={
                Coords=v3(d.coords),Object=d.object or "",Heading=tonumber(d.heading) or 0,
                OpenHeading=d.openHeading and tonumber(d.openHeading) or nil,
                Hacking=d.hacking==true,Time=tonumber(d.time) or 0,Frozen=d.frozen~=false,
                WeldPosition={C=v3(wp.coords),H=tonumber(wp.heading) or 0}
            }
        end
        for _,sf in ipairs(b.safes or {}) do
            rb.Safes[#rb.Safes+1]={
                Looted=sf.looted==true,Coords=v3(sf.coords),Heading=tonumber(sf.heading) or 0,
                Cam={From=clone(sf.cam and sf.cam.from or {}),To=clone(sf.cam and sf.cam.to or {})}
            }
        end
        local m=b.money or {}
        rb.Money={StartMoney=tonumber(m.startMoney) or 0,Amount=tonumber(m.amount) or tonumber(m.startMoney) or 0,
            BoxPosition=v3(m.boxPosition),Box=m.box or "prop_cash_crate_01",Cam=clone(m.cam or {})}
        local h=b.hacking or {}
        rb.Hacking={Coords=v3(h.coords),Heading=tonumber(h.heading) or 0}
        Config.BankRobbery[#Config.BankRobbery+1]=rb
    end
end

RegisterNetEvent("m_banco_central:syncConfig",function(data)
    if type(data)=="table" then apply(data) end
end)

CreateThread(function()
    Wait(400)
    TriggerServerEvent("m_banco_central:requestConfig")
end)
