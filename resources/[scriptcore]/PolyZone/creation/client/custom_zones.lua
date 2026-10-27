-- Auto-created zones (moved from server config.lua to client-side)
-- Because PolyZone is a CLIENT library, zones must be created on the client.

CreateThread(function()
    -- If PolyZone isn't ready yet for any reason, wait a tick
    Wait(0)

    -- Zone: zoneMecanica
    local zoneMecanica = PolyZone:Create({
        vector2(847.37, -996.14),
        vector2(847.20, -995.26),
        vector2(797.31, -997.00),
        vector2(793.16, -911.98),
        vector2(856.90, -916.75),
        vector2(838.88, -914.37),
        vector2(847.55, -990.43),
        vector2(849.55, -965.80),
        vector2(851.82, -943.26),
        vector2(859.77, -933.67),
        vector2(854.68, -918.59),
        vector2(857.99, -917.61),
        vector2(855.25, -921.92),
        vector2(848.72, -919.41),
        vector2(804.76, -997.33),
        vector2(799.89, -996.87),
        vector2(796.93, -995.48)
    }, {
        name = "zoneMecanica",
        minZ = 23.50,
        maxZ = 33.50
    })

    -- Zone: safezone_1751690784
    local zonesafezone_1751690784 = PolyZone:Create({
        vector2(-1513.53, -1462.91),
        vector2(-1513.53, -1462.91),
        vector2(-1515.08, -1464.06),
        vector2(-1546.14, -1478.36),
        vector2(-1527.38, -1529.17),
        vector2(-1492.59, -1519.99),
        vector2(-1493.71, -1483.35)
    }, {
        name = "safezone_1751690784",
        minZ = 0.04,
        maxZ = 10.04
    })

    -- If you need to use these zones in other client scripts, you can export or store them globally:
    -- _G.zoneMecanica = zoneMecanica
    -- _G.zonesafezone_1751690784 = zonesafezone_1751690784
end)
