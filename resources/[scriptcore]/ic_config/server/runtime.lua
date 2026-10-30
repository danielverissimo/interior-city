-- Installation health evidence contains no users, credentials or configuration data.
CreateThread(function()
    if GetConvar('ic_config_enabled','false')~='true' then return end
    local deadline=GetGameTimer()+120000
    local active=false
    repeat
        active=pcall(function()
            if GetResourceState(ICConfig.PreviousResource)~='stopped' and GetResourceState(ICConfig.PreviousResource)~='missing' then error('previous provider') end
            if GetConvar('ic_mansions_resource','m_mansions')~='ic_mansions' or GetResourceState('ic_mansions')~='started' then error('mansion provider') end
            ICConfigServer.Organizations.schema()
        end)
        if not active then Wait(1000) end
    until active or GetGameTimer()>deadline
    print('[ic_config:operational] '..json.encode({active=active,schemaVersion=active and 1 or 0,provider='ic_config'}))
end)
