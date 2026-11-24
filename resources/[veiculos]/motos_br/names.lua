local motorcycles={
    {spawn='bati',label='Honda CBX 250 Twister',gameName='BATI'},
    {spawn='bros150',label='Honda Bros 150',gameName='bros150'},
    {spawn='hornetagstore',label='Honda Hornet',gameName='hornetagstore'}
}
for _,bike in ipairs(motorcycles) do AddTextEntry(bike.gameName,bike.label) end

-- Diagnostico acionado exclusivamente pelo console do servidor.
-- Carrega os modelos para verificar o streaming, sem criar veiculos no mapa.
RegisterNetEvent('motos_br:validate',function(token)
    local result={}
    for _,bike in ipairs(motorcycles) do
        local hash=GetHashKey(bike.spawn)
        local valid=IsModelInCdimage(hash) and IsModelAVehicle(hash)
        local loaded=false
        if valid then
            RequestModel(hash)
            local deadline=GetGameTimer()+15000
            while not HasModelLoaded(hash) and GetGameTimer()<deadline do Wait(50) end
            loaded=HasModelLoaded(hash)
        end
        result[#result+1]={spawn=bike.spawn,valid=valid,loaded=loaded,class=valid and GetVehicleClassFromName(hash) or -1}
        if loaded then SetModelAsNoLongerNeeded(hash) end
    end
    TriggerServerEvent('motos_br:validation',token,result)
end)
