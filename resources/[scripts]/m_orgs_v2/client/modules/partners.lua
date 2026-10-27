RegisterNUICallback('GetPartners', function(data, cb)
    cb(vTunnel.GetPartners())
end)

RegisterNUICallback('NewPartner', function(data, cb)
    cb(vTunnel.addPartner(data))
end)

RegisterNUICallback('DeletePartner', function(data,cb)
    cb(vTunnel.deletePartner(data.partner))
end)
