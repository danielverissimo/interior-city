local collection = 'mp_m_milpolvest'
local vestSlot = 9

RegisterCommand('fardaspm', function()
    local ped = PlayerPedId()
    if GetEntityModel(ped) ~= joaat('mp_m_freemode_01') then
        print('[Fardas PM] A colecao esta disponivel para o personagem freemode masculino.')
        return
    end

    local count = GetNumberOfPedCollectionDrawableVariations(ped, vestSlot, collection)
    if count <= 0 then
        print('[Fardas PM] O FiveM ainda nao carregou a colecao de coletes.')
        return
    end

    for localIndex = 0, count - 1 do
        local model = GetPedDrawableGlobalIndexFromCollection(ped, vestSlot, collection, localIndex)
        print(('[Fardas PM] Colete %d | Modelo na loja %d | Textura 0'):format(localIndex + 1, model))
    end
end, false)
