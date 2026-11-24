local wallet={ok=false}
RegisterNetEvent('luxurymotors:diamondWallet',function(data)
    if type(data)~='table' then return end
    if data.ok == false then
        wallet={ok=false}
        TriggerEvent('luxurymotors:walletUpdated',wallet)
        SendNUIMessage({action='diamondWallet',data=wallet})
        return
    end
    if type(data.balance)~='number' or data.balance<0 then return end
    wallet={ok=true,balance=math.floor(data.balance)}
    TriggerEvent('luxurymotors:walletUpdated',wallet)
    SendNUIMessage({action='diamondWallet',data=wallet})
end)
exports('getDiamondWallet',function() return {ok=wallet.ok,balance=wallet.balance} end)
CreateThread(function()
    Wait(2000)
    while true do
        TriggerServerEvent('luxurymotors:requestDiamondWallet')
        Wait(30000)
    end
end)
