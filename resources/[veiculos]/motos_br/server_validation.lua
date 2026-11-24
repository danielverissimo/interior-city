local pending={}
RegisterCommand('testarmotos',function(source)
    if source~=0 then return end
    local players=GetPlayers()
    if not players[1] then print('[motos_br] Sem jogador conectado para verificar os modelos.');return end
    local player=tonumber(players[1])
    local token=tostring(GetGameTimer())
    pending[player]=token
    TriggerClientEvent('motos_br:validate',player,token)
    SetTimeout(50000,function()
        if pending[player]==token then pending[player]=nil;print('[motos_br] Diagnostico sem resposta do client.') end
    end)
end,false)
RegisterNetEvent('motos_br:validation',function(token,result)
    if not pending[source] or pending[source]~=token then return end
    pending[source]=nil
    if type(result)~='table' or #result~=3 then return end
    for _,bike in ipairs(result) do
        print(('[motos_br] %s: registrado=%s carregado=%s classe=%s'):format(tostring(bike.spawn),tostring(bike.valid),tostring(bike.loaded),tostring(bike.class)))
    end
end)
AddEventHandler('playerDropped',function()pending[source]=nil end)
