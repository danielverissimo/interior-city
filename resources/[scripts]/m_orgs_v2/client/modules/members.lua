----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CALLBACKS
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("GetMembers", function(data,cb) 
    local members = vTunnel.getMembers()
    cb(members)
end)

RegisterNuiCallback('ContractMember', function(data, cb ) 
    cb(vTunnel.inviteMember(data.id))
end)

RegisterNuiCallback('DemoteMember', function(data, cb ) 
cb(vTunnel.genMember({ memberId = data.id, action = 'demote' }))
end)

RegisterNuiCallback('PromoteMember', function(data, cb ) 
    cb(vTunnel.genMember({ memberId = data.id, action = 'promote' }))
end)

RegisterNuiCallback('DimissMember', function(data, cb ) 
    cb(vTunnel.genMember({ memberId = data.id, action = 'dismiss' }))
end)