DealershipConfigReady = false

RegisterNetEvent("m_dealership:syncConfig",function(data)
    if type(data)~="table" then return end
    DealershipConfigReady = true
    local s=data.settings or {}
    Default.imagesDir=tostring(s.imagesDir or Default.imagesDir or "http://127.0.0.1/vrp_images/")
    Default.commandConce=tostring(s.commandConce or Default.commandConce or "conce")
    Default.sellVehicle=tonumber(s.sellVehicle) or Default.sellVehicle or 99
    Default.maxCars=tonumber(s.maxCars) or Default.maxCars or 5
    Default.notTop4Vehicles=s.notTop4Vehicles or Default.notTop4Vehicles or {}
    DealershipCategories=data.categories or DealershipCategories or {}

    local td=data.testDrive or {}
    TestDrive.cooldownTestDriver=tonumber(td.cooldownTestDriver) or TestDrive.cooldownTestDriver or 60
    TestDrive.maxDistanceTestDriver=tonumber(td.maxDistanceTestDriver) or TestDrive.maxDistanceTestDriver or 1500.0
    TestDrive.Locations={}
    for _,loc in ipairs(td.locations or {}) do
        local c=loc.coords or {}
        local t=loc.test_drive or {}
        TestDrive.Locations[#TestDrive.Locations+1]={
            coords=vec3(tonumber(c[1]) or 0.0,tonumber(c[2]) or 0.0,tonumber(c[3]) or 0.0),
            test_drive=vector4(tonumber(t[1]) or 0.0,tonumber(t[2]) or 0.0,tonumber(t[3]) or 0.0,tonumber(t[4]) or 0.0)
        }
    end
end)

CreateThread(function()
    -- Handshake confiável: em restart/ensure o client pode ficar pronto antes do
    -- handler server-side. Repetimos somente até receber a primeira configuração.
    Wait(250)
    while not DealershipConfigReady do
        TriggerServerEvent("m_dealership:requestConfig")
        Wait(1500)
    end
end)
