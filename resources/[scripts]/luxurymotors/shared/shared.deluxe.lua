DeluxeConfig = DeluxeConfig or { enabled = false }

function ApplyDeluxeLocation(config)
    DeluxeConfig = type(config) == 'table' and config or { enabled = false }
    for index = #TestDrive.Locations, 1, -1 do
        if TestDrive.Locations[index].panel == 'deluxe' then table.remove(TestDrive.Locations, index) end
    end
    local coords = DeluxeConfig.coords
    if DeluxeConfig.enabled ~= true or type(coords) ~= 'table' or #coords ~= 3 then return end
    local test = DeluxeConfig.test_drive
    TestDrive.Locations[#TestDrive.Locations + 1] = {
        coords = vec3(coords[1], coords[2], coords[3]),
        test_drive = type(test) == 'table' and #test == 4 and vector4(test[1], test[2], test[3], test[4]) or nil,
        panel = 'deluxe'
    }
end
