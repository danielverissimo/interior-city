-- Fila server-side persistente. A confirmação SQL é idempotente no m_hospital.
local key = 'sector_productivity_pending_v1'
local ok, decoded = pcall(json.decode, GetResourceKvpString(key) or '{}')
local pending = ok and type(decoded) == 'table' and decoded or {}
local function persist()
    SetResourceKvp(key, json.encode(pending))
end

local Proxy = module('vrp', 'lib/Proxy')
local vRP = Proxy.getInterface('vRP')
local mechanicGroups = {
    SportRacer = {'LiderSPORTRACER','SubLiderSPORTRACER','GerenteSPORTRACER',
                  'RecrutadorSPORTRACER','MembroSPORTRACER','NovatoSPORTRACER'},
    LSCustoms = {'LiderLSCustoms','SubLiderLSCustoms','GerenteGeralLSCustoms',
                 'GerenteLSCustoms','SupervisorLSCustoms','MecanicoLSCustoms','EstagiarioLSCustoms'},
    RedLine = {'LiderRedLine','SubLiderRedLine','GerenteRedLine',
               'RecrutadorRedLine','MembroRedLine','NovatoRedLine'},
}
local function resolveOrganization(userId)
    local ok, groups = pcall(vRP.getUserGroups, userId)
    if not ok or type(groups) ~= 'table' then groups = {} end
    local active, duty = {}, {}
    for org, names in pairs(mechanicGroups) do
        local hasGroup = false
        for _, name in ipairs(names) do
            if groups[name] ~= nil then hasGroup = true; break end
        end
        if hasGroup then active[#active+1] = org end
        if GetResourceState('m_ponto') == 'started' then
            local success, member = pcall(function() return exports['m_ponto']:getMembership(userId, org) end)
            if success and type(member) == 'table' and member.onDuty then
                duty[#duty+1] = org
                if not hasGroup then active[#active+1] = org end
            end
        end
    end
    if #duty == 1 then return duty[1] end
    if #active == 1 then return active[1] end
    return '' -- legado ou associação ambígua; não misturar oficinas.
end

function QueueSectorProductivity(call, actorId)
    if call.department ~= 'hospital' and call.department ~= 'mechanic' then return end
    local id = ('%s:%s:%s'):format(call.department, call.id, call.createdAt)
    pending[id] = {
        department=call.department, callId=call.id, createdAt=call.createdAt,
        actorId=actorId, patientId=call.playerId, acceptedAt=os.time(),
        organization=call.department == 'hospital' and 'Hospital' or resolveOrganization(actorId)
    }
    persist()
end

CreateThread(function()
    while true do
        Wait(3000)
        if GetResourceState('m_hospital') == 'started' then
            local batch = {}
            for id, item in pairs(pending) do batch[#batch+1]={id=id,item=item} end
            for _, entry in ipairs(batch) do
                local success, saved = pcall(function()
                    return exports['m_hospital']:RegisterSectorCallAccepted(entry.item)
                end)
                if success and saved == true then
                    pending[entry.id] = nil
                    persist()
                end
            end
        end
    end
end)
