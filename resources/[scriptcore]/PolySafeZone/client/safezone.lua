-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPGserver = Tunnel.getInterface("PolySafeZone")

local job=""
local grade=0
local display=false
local SafeData={settings={},safezones={},whitelist={}}
local AllCreatedZones={}
local IsLoopStarted=false
local IsPlayerCanAttackInSafeZone=nil
local WhatIsLastLoop=""

RegisterNetEvent('nui:on')
AddEventHandler('nui:on',function()
    SendNUIMessage({type="uisafe",display=true})
end)

RegisterNetEvent('nui:off')
AddEventHandler('nui:off',function()
    SendNUIMessage({type="uisafe",display=false})
end)

local function destroyZones()
    WhatIsLastLoop=""
    IsLoopStarted=false
    IsPlayerCanAttackInSafeZone=nil
    NetworkSetFriendlyFireOption(true)
    TriggerEvent("nui:off")

    for i=#AllCreatedZones,1,-1 do
        local z=AllCreatedZones[i]
        if z and z.destroy then pcall(function() z:destroy() end) end
        AllCreatedZones[i]=nil
    end
end

local function whitelistTable()
    local out={}
    for _,entry in ipairs(SafeData.whitelist or {}) do
        local j=tostring(entry.job or ""):lower()
        local z=tostring(entry.zone or "")
        if j~="" and z~="" then
            out[j]=out[j] or {}
            out[j][z]=tonumber(entry.minGrade) or 0
        end
    end
    return out
end

local function EnteredZone(isPointInside,Name)
    if isPointInside and WhatIsLastLoop~=Name then
        CreateThread(function()
            WhatIsLastLoop=Name
            IsLoopStarted=true
            TriggerEvent("nui:on")

            local whitelist=whitelistTable()
            while WhatIsLastLoop==Name do
                local allowed=false
                if SafeData.settings and SafeData.settings.useWhitelist then
                    local byJob=whitelist[string.lower(job or "")]
                    local needed=byJob and byJob[Name]
                    allowed=needed~=nil and tonumber(grade or 0)>=tonumber(needed or 0)
                end

                if not allowed then
                    NetworkSetFriendlyFireOption(false)
                    DisablePlayerFiring(PlayerPedId(),true)
                    DisableControlAction(0,140,true)
                    DisableControlAction(0,25,true)
                    IsPlayerCanAttackInSafeZone=false
                    Wait(3)
                else
                    IsPlayerCanAttackInSafeZone=true
                    Wait(500)
                end
            end

            NetworkSetFriendlyFireOption(true)
            IsPlayerCanAttackInSafeZone=nil
            IsLoopStarted=false
            TriggerEvent("nui:off")
        end)
    else
        WhatIsLastLoop=""
    end
end

local function rebuildZones()
    destroyZones()
    local check=tonumber(SafeData.settings and SafeData.settings.checkLoopTime) or 1000

    for _,entry in ipairs(SafeData.safezones or {}) do
        local temp={}
        for idx,poly in ipairs(entry.zones or {}) do
            local points={}
            for _,p in ipairs(poly.coords or {}) do
                points[#points+1]=vector2(tonumber(p.x) or 0.0,tonumber(p.y) or 0.0)
            end

            if #points>=3 then
                local zone=PolyZone:Create(points,{
                    name=tostring(entry.name).."_"..idx,
                    minZ=tonumber(poly.minZ),
                    maxZ=tonumber(poly.maxZ),
                    debugPoly=entry.debug==true,
                    debugGrid=entry.debug==true
                })
                temp[#temp+1]=zone
                AllCreatedZones[#AllCreatedZones+1]=zone
            end
        end

        if #temp>1 then
            local combo=ComboZone:Create(temp,{name=tostring(entry.name).."_combo"})
            combo:onPlayerInOut(function(inside)
                EnteredZone(inside,tostring(entry.name))
            end,check)
            AllCreatedZones[#AllCreatedZones+1]=combo
        elseif #temp==1 then
            temp[1]:onPointInOut(PolyZone.getPlayerPosition,function(inside)
                EnteredZone(inside,tostring(entry.name))
            end,check)
        end
    end
end

RegisterNetEvent("PolySafeZone:syncConfig",function(data)
    SafeData=type(data)=="table" and data or {settings={},safezones={},whitelist={}}
    rebuildZones()
end)

CreateThread(function()
    TriggerEvent("nui:off")
    Wait(500)
    TriggerServerEvent("PolySafeZone:requestConfig")
end)

-- ESX é mantido por compatibilidade. Se a configuração estiver ativa, inicializa após sync.
CreateThread(function()
    while not SafeData.settings do Wait(500) end
    if not SafeData.settings.useESX then return end

    local ESX=nil
    while ESX==nil do
        TriggerEvent("esx:getSharedObject",function(obj) ESX=obj end)
        Wait(100)
    end
    while ESX.GetPlayerData().job==nil do Wait(100) end
    job=ESX.GetPlayerData().job.name
    grade=ESX.GetPlayerData().job.grade

    RegisterNetEvent("esx:setJob")
    AddEventHandler("esx:setJob",function(newJob)
        job=newJob.name
        grade=newJob.grade
    end)
end)

AddEventHandler('onResourceStop',function(resourceName)
    if GetCurrentResourceName()~=resourceName then return end
    destroyZones()
end)

exports("InSafeZone",function() return IsLoopStarted end)
exports("SafeZoneName",function() return WhatIsLastLoop end)
exports("CanAttackInSafeZone",function() return IsPlayerCanAttackInSafeZone end)
exports("SetJobAndGrade",function(newJob,newGrade)
    job=newJob
    grade=tonumber(newGrade) or 0
end)
