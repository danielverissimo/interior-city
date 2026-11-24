RegisterNUICallback("deleteOutfit", function (data, cb)
    local outfitName = type(data.target) == 'table' and data.target.name

    TriggerServerEvent("novak:playerOutfit", "deletar", { name = outfitName })
    TriggerEvent('dynamic:closeMenu')
    cb('ok')
end)


RegisterNUICallback("saveOutfit", function (data, cb)
    local outfitName = data['name']

    TriggerServerEvent("novak:playerOutfit", "salvar", { name = outfitName })
    TriggerEvent('dynamic:closeMenu')
    cb('ok')
end)
