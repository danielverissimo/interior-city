local I=ICAdmin
local types={'CLEAR','EXTRASUNNY','CLOUDS','OVERCAST','RAIN','CLEARING','THUNDER','SMOG','FOGGY','NEUTRAL','SNOW','BLIZZARD','SNOWLIGHT','XMAS','HALLOWEEN'}
local lastTick,lastRotation=0,0
I.definitions.set_weather={key='set_weather',label='Alterar clima'}
I.definitions.set_time={key='set_time',label='Alterar horário'}

local function climate()
    local value,rev=I.Store.get('climate',{weather='CLEAR',hour=12,minute=0,freezeWeather=true,freezeTime=false,rotation=false})
    return value,rev
end
local function publish(state,target)
    if not I.active() then return end
    GlobalState.time={state.hour,state.minute}
    GlobalState.icAdminEnvironment=state
    TriggerClientEvent('ic_admin:environment',target or -1,state)
end
local function locations()
    local doc,rev=I.Store.get('locations',{locations={},categories={}})
    doc.locations=doc.locations or {}; doc.categories=doc.categories or {}
    return doc,rev
end
local function coord(v,min,max)
    local value=tonumber(v)
    if not value or value~=value or value==math.huge or value==-math.huge or value<min or value>max then I.fail('INVALID','Coordenada inválida.') end
    return value+0.0
end
local function position(p)
    p=type(p.coords)=='table' and p.coords or p
    return {x=coord(p.x,-20000,20000),y=coord(p.y,-20000,20000),z=coord(p.z,-2000,5000)}
end

I.register('world.get',{permission='view_climate',handler=function()
    local value=climate(); value.types=types; return value
end})

I.register('world.update',{permission='view_climate',mutating=true,handler=function(ctx,p)
    return I.withLock('climate',function()
        local state,rev=climate()
        local changesWeather=p.weather~=nil or p.freezeWeather~=nil or p.rotation~=nil
        local changesTime=p.hour~=nil or p.minute~=nil or p.minuteOfDay~=nil or p.freezeTime~=nil
        if not changesWeather and not changesTime then I.fail('INVALID','Nenhuma alteração de ambiente informada.') end
        if changesWeather then
            if not I.allowed(ctx.userId,'set_weather') then I.fail('FORBIDDEN','Sem permissão para alterar o clima.') end
            if p.weather~=nil then
                local found=false; for _,name in ipairs(types) do if name==p.weather then found=true end end
                if not found then I.fail('INVALID','Clima inválido.') end
                state.weather=p.weather
            end
            if p.freezeWeather~=nil then
                if type(p.freezeWeather)~='boolean' then I.fail('INVALID','Estado inválido.') end
                state.freezeWeather=p.freezeWeather
            end
            if p.rotation~=nil then
                if type(p.rotation)~='boolean' then I.fail('INVALID','Rotação inválida.') end
                state.rotation=p.rotation
            end
        end
        if changesTime then
            if not I.allowed(ctx.userId,'set_time') then I.fail('FORBIDDEN','Sem permissão para alterar o horário.') end
            if p.minuteOfDay~=nil then
                local value=I.int(p.minuteOfDay,0,1439,'Horário'); state.hour=math.floor(value/60); state.minute=value%60
            else
                if p.hour~=nil then state.hour=I.int(p.hour,0,23,'Hora') end
                if p.minute~=nil then state.minute=I.int(p.minute,0,59,'Minuto') end
            end
            if p.freezeTime~=nil then
                if type(p.freezeTime)~='boolean' then I.fail('INVALID','Estado inválido.') end
                state.freezeTime=p.freezeTime
            end
        end
        if changesWeather then ctx.permission='set_weather'; I.effect(ctx) end
        if changesTime then ctx.permission='set_time'; I.effect(ctx) end
        if not I.Store.put('climate',state,rev) then I.fail('CONFLICT','Clima alterado; atualize a tela.') end
        publish(state); local out={}; for key,value in pairs(state) do out[key]=value end; out.types=types; return out
    end)
end})

I.register('locations.list',{permission='view_locations',handler=function() return locations() end})
I.register('locations.save',{permission='add_location',mutating=true,handler=function(ctx,p)
    local xyz=position(p)
    local name=I.text(p.name,80,true,'Nome'); local category=I.text(p.category or 'Geral',80,true,'Categoria')
    return I.withLock('locations',function()
        local doc,rev=locations(); local entry
        if p.id then
            local id=I.int(p.id,1,2147483647,'Local')
            for _,row in ipairs(doc.locations) do if tonumber(row.id)==id then entry=row end end
            if not entry then I.fail('NOT_FOUND','Local não encontrado.') end
        else
            if #doc.locations>=5000 then I.fail('LIMIT','Limite de locais atingido.') end
            local id=0; for _,row in ipairs(doc.locations) do id=math.max(id,tonumber(row.id) or 0) end
            entry={id=id+1}; doc.locations[#doc.locations+1]=entry
        end
        entry.name=name; entry.category=category; entry.x=xyz.x; entry.y=xyz.y; entry.z=xyz.z
        local found=false; for _,value in ipairs(doc.categories) do if value==category then found=true end end
        if not found then doc.categories[#doc.categories+1]=category end
        I.effect(ctx)
        if not I.Store.put('locations',doc,rev) then I.fail('CONFLICT','Locais alterados; atualize a tela.') end
        return {location=entry,locations=doc.locations,categories=doc.categories}
    end)
end})
I.register('locations.delete',{permission='remove_location',mutating=true,handler=function(ctx,p)
    return I.withLock('locations',function()
        local id=I.int(p.id,1,2147483647,'Local'); local doc,rev=locations(); local found=false
        for index,row in ipairs(doc.locations) do if tonumber(row.id)==id then table.remove(doc.locations,index); found=true; break end end
        if not found then I.fail('NOT_FOUND','Local não encontrado.') end
        I.effect(ctx)
        if not I.Store.put('locations',doc,rev) then I.fail('CONFLICT','Locais alterados; atualize a tela.') end
        return doc
    end)
end})
I.register('locations.teleport',{permission='teleport_location',mutating=true,handler=function(ctx,p)
    local doc=locations(); local id=I.int(p.id,1,2147483647,'Local')
    for _,row in ipairs(doc.locations) do
        if tonumber(row.id)==id then
            I.effect(ctx); TriggerClientEvent('ic_admin:clientAction',ctx.source,'teleport',{coords=position(row)})
            return {location=row}
        end
    end
    I.fail('NOT_FOUND','Local não encontrado.')
end})

exports('getLocations',function()
    if not I.active() then return {} end
    local doc=locations(); return doc.locations
end)

AddEventHandler('ic_admin:ready',function()
    if I.active() then publish(climate()); lastTick=os.time(); lastRotation=os.time() end
end)

AddEventHandler('vRP:playerSpawn',function(_,playerSource)
    if I.active() then publish(climate(),playerSource) end
end)

CreateThread(function()
    while true do
        Wait(1000)
        if I.active() then
            local now=os.time()
            if now-lastTick>=10 then
                local ok=pcall(function()
                    I.withLock('climate',function()
                        local state,rev=climate()
                        if not state.freezeTime then
                            local minutes=((tonumber(state.hour) or 12)*60+(tonumber(state.minute) or 0)+2)%1440
                            state.hour=math.floor(minutes/60); state.minute=minutes%60
                        end
                        if state.rotation and not state.freezeWeather and now-lastRotation>=300 then
                            local index=1; for n,value in ipairs(types) do if value==state.weather then index=n end end
                            state.weather=types[(index%#types)+1]; lastRotation=now
                        end
                        if not I.Store.put('climate',state,rev) then return end
                        publish(state)
                    end)
                end)
                if ok then lastTick=now end
            end
        end
    end
end)

I.World={position=position,types=types}
