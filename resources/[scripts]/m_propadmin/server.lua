local resource = GetCurrentResourceName()
local placed, nextId = {}, 1
local function allowed(src)
    return src == 0 or IsPlayerAceAllowed(src, Config.AcePermission)
end
local function persist()
    SaveResourceFile(resource, 'placed.json', json.encode({nextId=nextId, props=placed}), -1)
end
local function load()
    local raw = LoadResourceFile(resource, 'placed.json')
    if not raw then return end
    local ok, data = pcall(json.decode, raw)
    if ok and type(data)=='table' then
        placed = type(data.props)=='table' and data.props or {}
        nextId = tonumber(data.nextId) or 1
    end
end
load()
local function cleanModel(m)
    return type(m)=='string' and #m>1 and #m<=Config.MaxModelLength and m:match('^[%w_]+$') ~= nil
end
local function validPlacement(src, p)
    if type(p)~='table' or not cleanModel(p.model) then return false end
    for _, k in ipairs({'x','y','z','heading'}) do
        if type(p[k])~='number' or p[k]~=p[k] or math.abs(p[k])>100000 then return false end
    end
    local ped=GetPlayerPed(src)
    if ped==0 then return false end
    local c=GetEntityCoords(ped)
    local dx,dy,dz=c.x-p.x,c.y-p.y,c.z-p.z
    return dx*dx+dy*dy+dz*dz <= Config.MaxDistance^2
end
RegisterCommand(Config.Command,function(src)
    if src==0 then return end
    if not allowed(src) then TriggerClientEvent('chat:addMessage',src,{args={'PropAdmin','Sem permissao.'}});return end
    TriggerClientEvent('m_propadmin:open',src)
end,false)
RegisterNetEvent('m_propadmin:request',function()
    local src=source
    if allowed(src) then TriggerClientEvent('m_propadmin:sync',src,placed) end
end)
RegisterNetEvent('m_propadmin:save',function(requestId,p)
    local src=source
    if not allowed(src) or not validPlacement(src,p) or #placed>=Config.MaxProps then
        TriggerClientEvent('m_propadmin:result',src,requestId,false,'Sem permissao, limite atingido ou posicao invalida.') return
    end
    local id=nextId;nextId=id+1
    local item={id=id,model=p.model,x=p.x,y=p.y,z=p.z,heading=p.heading}
    placed[#placed+1]=item
    persist()
    TriggerClientEvent('m_propadmin:sync',-1,placed)
    TriggerClientEvent('m_propadmin:result',src,requestId,true,'Prop salvo.')
end)
RegisterNetEvent('m_propadmin:delete',function(id)
    local src=source
    if not allowed(src) then return end
    id=tonumber(id)
    for i,p in ipairs(placed) do
        if p.id==id then
            local c=GetEntityCoords(GetPlayerPed(src))
            local dx,dy,dz=c.x-p.x,c.y-p.y,c.z-p.z
            if dx*dx+dy*dy+dz*dz > (Config.MaxDistance*Config.MaxDistance) then
                TriggerClientEvent('m_propadmin:notice',src,'Aproxime-se do prop para apagar.') return
            end
            table.remove(placed,i);persist()
            TriggerClientEvent('m_propadmin:sync',-1,placed)
            TriggerClientEvent('m_propadmin:notice',src,'Prop removido.')
            return
        end
    end
end)
