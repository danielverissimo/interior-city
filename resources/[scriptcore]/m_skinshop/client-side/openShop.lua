CreateThread(function()
    while true do
        local thread = 1000

        local playerPed = PlayerPedId()

		if not IsPedInAnyVehicle(playerPed) and not creatingCharacter then
            local playerCoords = GetEntityCoords(playerPed)

            for _, parameters in pairs (locateShops) do
                local distancePlayerToShop = #(playerCoords - vector3(parameters[1],parameters[2],parameters[3]))

                if distancePlayerToShop <= 10 then
                    thread = 2

                    if distancePlayerToShop <= 5 then

                        DrawText3D(parameters[1],parameters[2],parameters[3],"Pressione ~r~E~w~ para abrir")

                        if distancePlayerToShop <= 2 then
                            if IsControlJustPressed(0,38) then
                                clientFunctions.openNuiShop()
                            end
                        end
                    end
                end
            end
        end
        Wait(thread)
    end
end)

function DrawText3D(x, y, z, text)
	local onScreen,_x,_y = World3dToScreen2d(x,y,z)
	SetTextFont(4)
	SetTextScale(0.50,0.50)
	SetTextColour(255,255,255,150)
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(_x,_y)
end


exports("openShop", function()
    clientFunctions.openNuiShop()
end)

RegisterNetEvent("skinshop:pending_coords", function(coords)
    locateShops[#locateShops + 1] = {coords.x, coords.y, coords.z, false, true}
end)