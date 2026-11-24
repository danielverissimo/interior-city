AddEventHandler('luxurymotors:walletUpdated',function(wallet)
    SendNUIMessage({action='diamondWallet',data=wallet})
end)
RegisterNetEvent('luxurymotors:diamondWallet',function(wallet)
    if type(wallet) ~= 'table' then return end
    local balance=tonumber(wallet.balance)
    SendNUIMessage({action='diamondWallet',data={ok=wallet.ok ~= false and balance ~= nil,balance=balance}})
end)
local function refreshDiamondWallet()
    if GetResourceState('luxurymotors')=='started' then
        local ok,wallet=pcall(function() return exports.luxurymotors:getDiamondWallet() end)
        if ok then SendNUIMessage({action='diamondWallet',data=wallet}) end
    end
    TriggerServerEvent('luxurymotors:requestDiamondWallet')
end

RegisterNUICallback('diamondWalletReady',function(_,cb)
    refreshDiamondWallet()
    cb({ok=true})
end)

AddEventHandler('onClientResourceStart',function(resource)
    if resource=='luxurymotors' then refreshDiamondWallet() end
end)

CreateThread(function()
    Wait(1500)
    while true do
        refreshDiamondWallet()
        Wait(30000)
    end
end)
