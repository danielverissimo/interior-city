JewelryConfig={}
JewelryCenter={x=-622.18,y=-230.92,z=38.05}
JewelryRadius=20.0
JewelryWeapons={"WEAPON_ASSAULTRIFLE_MK2","WEAPON_SMG"}

local function apply(data)
    JewelryConfig=data or {}
    local s=JewelryConfig.settings or {}
    local h=s.hackCoords or {-631.39,-230.25,38.05}
    coordenadaX,coordenadaY,coordenadaZ=tonumber(h[1]) or -631.39,tonumber(h[2]) or -230.25,tonumber(h[3]) or 38.05
    local c=s.centerCoords or {-622.18,-230.92,38.05}
    JewelryCenter={x=tonumber(c[1]) or -622.18,y=tonumber(c[2]) or -230.92,z=tonumber(c[3]) or 38.05}
    JewelryRadius=tonumber(s.centerRadius) or 20.0
    JewelryWeapons=s.requiredWeapons or JewelryWeapons
    locais=JewelryConfig.displays or {}
    bombLocs=s.bombLocations or {}
end

function isAllowedJewelryWeapon(hash)
    for _,name in ipairs(JewelryWeapons or {}) do
        if hash==GetHashKey(name) then return true end
    end
    return false
end

RegisterNetEvent("m_joalheria:syncConfig",function(data)
    if type(data)=="table" then apply(data) end
end)

CreateThread(function()
    Wait(500)
    TriggerServerEvent("m_joalheria:requestConfig")
end)
