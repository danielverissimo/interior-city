RobConfig={}
BankHeists=BankHeists or {}

local function apply(data)
    RobConfig=(data and data.settings) or {}
    local out={}
    for name,b in pairs((data and data.banks) or {}) do
        local v=b.bankVault or {}
        local st=b.startRobbing or {}
        local cp=b.cashPile or {}
        out[name]={
            Money=tonumber(b.money) or 0,
            Bank_Vault={
                model=tonumber(v.model) or 0,
                x=tonumber(v.x) or 0.0,y=tonumber(v.y) or 0.0,z=tonumber(v.z) or 0.0,
                hStart=tonumber(v.hStart) or 0.0,hEnd=tonumber(v.hEnd) or 0.0
            },
            Start_Robbing={
                x=tonumber(st.x) or 0.0,y=tonumber(st.y) or 0.0,z=tonumber(st.z) or 0.0,h=tonumber(st.h) or 0.0
            },
            Cash_Pile={
                x=tonumber(cp.x) or 0.0,y=tonumber(cp.y) or 0.0,z=tonumber(cp.z) or 0.0,h=tonumber(cp.h) or 0.0
            }
        }
    end
    BankHeists=out
    if ResetDoors then ResetDoors() end
end

RegisterNetEvent("m_roubocofre:syncConfig",function(data)
    if type(data)=="table" then apply(data) end
end)

CreateThread(function()
    Wait(500)
    TriggerServerEvent("m_roubocofre:requestConfig")
end)
