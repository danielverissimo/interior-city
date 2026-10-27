
-- SE ESTIVER REPLICANDO, NÃO ESQUECE DE COLOCAR ESSE TRIGGER, PROCURE NO SEU VSCODE
-- SE ESTIVER REPLICANDO, NÃO ESQUECE DE COLOCAR ESSE TRIGGER, PROCURE NO SEU VSCODE
-- SE ESTIVER REPLICANDO, NÃO ESQUECE DE COLOCAR ESSE TRIGGER, PROCURE NO SEU VSCODE
-- SE ESTIVER REPLICANDO, NÃO ESQUECE DE COLOCAR ESSE TRIGGER, PROCURE NO SEU VSCODE
-- SE ESTIVER REPLICANDO, NÃO ESQUECE DE COLOCAR ESSE TRIGGER, PROCURE NO SEU VSCODE
RegisterNetEvent('garage:tryInsertTracker', function(veh, info)
    while not DoesEntityExist(veh) do
        Wait(200)
    end

    if info and next(info) then
        if info.tracker then
            SetTracker(veh)
        end
    end
end)

function clientFunctions.insertTracker(vehNetId)
	local vehEntity = NetworkGetEntityFromNetworkId(vehNetId)

    if vehEntity and DoesEntityExist(vehEntity) then
        SetTracker(vehEntity)
    end
end

function clientFunctions.changeHood(vehNetId, state)
    local vehEntity = NetworkGetEntityFromNetworkId(vehNetId)

    if vehEntity and DoesEntityExist(vehEntity) then
        ExecuteCommand('capo')
        FreezeEntityPosition(vehEntity, state)
        FreezeEntityPosition(PlayerPedId(), state)
    end
end

function clientFunctions.removeTracker(blipId)
	if DoesBlipExist(blipId) then
		RemoveBlip(blipId)
	end
end

function SetTracker(veh)
	local blip = AddBlipForEntity(veh)
    SetBlipSprite(blip, 225)
    SetBlipColour(blip, 64)
    SetBlipScale(blip, 0.8)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Rastreador")
    EndTextCommandSetBlipName(blip)

	local model = GetEntityModel(veh)

	serverFunctions.insertTracker(model, blip)
end