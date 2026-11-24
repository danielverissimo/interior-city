AddEventHandler('luxurymotors:walletUpdated',function(wallet)
    SendNUIMessage({route='DIAMOND_WALLET',payload=wallet})
end)
-- Also accept the server snapshot directly; displaying the wallet must not
-- depend on the dealership client's event relay having initialized first.
RegisterNetEvent('luxurymotors:diamondWallet',function(wallet)
    if type(wallet) ~= 'table' then return end
    local balance=tonumber(wallet.balance)
    SendNUIMessage({route='DIAMOND_WALLET',payload={ok=wallet.ok ~= false and balance ~= nil,balance=balance}})
end)
RegisterNUICallback('DIAMOND_WALLET',function(_,cb)
    local wallet={ok=false}
    if GetResourceState('luxurymotors')=='started' then
        local ok,result=pcall(function() return exports.luxurymotors:getDiamondWallet() end)
        if ok then wallet=result end
    end
    TriggerServerEvent('luxurymotors:requestDiamondWallet')
    cb(wallet)
end)
