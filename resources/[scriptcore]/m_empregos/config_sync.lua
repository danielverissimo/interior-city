RegisterNetEvent("m_empregos:syncConfig",function(data)
    if type(data)~="table" then return end
    cfg.central=data.central or cfg.central or {}
    cfg.npcloc=data.npc or cfg.npcloc or {}
    cfg.list=data.jobs or cfg.list or {}
    cfg.extra=data.extras or cfg.extra or {}
    TriggerEvent("m_empregos:clientConfigUpdated",data)
end)

CreateThread(function()
    Wait(500)
    TriggerServerEvent("m_empregos:requestConfig")
end)
