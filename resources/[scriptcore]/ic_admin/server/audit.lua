local I = ICAdmin
I.Config.ownerOnly = I.Config.ownerOnly or {}
I.Config.ownerOnly.logs_manage = true
local aliases = { main = 'Geral', staff = 'Equipe', economy = 'Economia', world = 'Mundo' }
local queue, sending, lastPrune = {}, false, 0
local hidden = { token=true, password=true, secret=true, license=true, identifier=true, identifiers=true, ip=true, webhook=true, url=true,
    api_key=true,apikey=true,authorization=true,cookie=true }
local identifierKinds={license=true,license2=true,steam=true,fivem=true,discord=true,xbl=true,live=true}

local function cleanText(value)
    value=value:gsub('https?://[^%s<>"\']+','[URL omitida]')
    value=value:gsub('cfxk_[%w_%-]+','[credencial omitida]')
    value=value:gsub('([%a%d_]+):([%w_%-]+)',function(kind,identifier)
        return identifierKinds[kind:lower()] and '[identificador omitido]' or kind..':'..identifier
    end)
    value=value:gsub('(%d+)%.(%d+)%.(%d+)%.(%d+)',function(a,b,c,d)
        if tonumber(a)<=255 and tonumber(b)<=255 and tonumber(c)<=255 and tonumber(d)<=255 then return '[IP omitido]' end
        return a..'.'..b..'.'..c..'.'..d
    end)
    value=value:gsub('([%a_][%w_]*)(%s*[:=]%s*)([^%s,;]+)',function(key,separator,entry)
        local lower=key:lower()
        if hidden[lower] or lower:find('password',1,true) or lower:find('token',1,true) or lower:find('secret',1,true) then
            return key..separator..'[omitido]'
        end
        return key..separator..entry
    end)
    return value:gsub('[Bb]earer%s+[%w%.%-%_]+','Bearer [omitido]'):sub(1,4000)
end

local function clean(value, depth)
    depth = depth or 0
    if depth > 5 then return '[limite]' end
    if type(value) == 'string' then
        return cleanText(value)
    end
    if type(value) == 'table' then
        local out, count = {}, 0
        for key, item in pairs(value) do
            count = count + 1
            if count > 80 then break end
            local name = tostring(key):lower()
            local blocked = hidden[name] or name:find('password',1,true) or name:find('webhook',1,true)
                or name:find('token',1,true) or name:find('secret',1,true)
            out[tostring(key):sub(1,80)] = blocked and '[omitido]' or clean(item,depth+1)
        end
        return out
    end
    if type(value) == 'number' or type(value) == 'boolean' then return value end
    return nil
end

local function displayName(id)
    if not id then return nil end
    local ok, identity = pcall(I.vRP.getUserIdentity,id)
    if ok and type(identity)=='table' then
        return (tostring(identity.nome or '')..' '..tostring(identity.sobrenome or '')):sub(1,128)
    end
    return 'Passaporte '..tostring(id)
end

local function destination(alias)
    if not aliases[alias] then return nil end
    local url = GetConvar('ic_secret_ic_admin_'..alias..'_webhook','')
    if url:match('^https://discord%.com/api/webhooks/%d+/[%w_%.%-]+$')
        or url:match('^https://discordapp%.com/api/webhooks/%d+/[%w_%.%-]+$') then return url end
end

local function categoryFor(action)
    if action:find('vip',1,true) or action:find('money',1,true) or action:find('bank',1,true)
        or action:find('inventory',1,true) or action:find('item',1,true) then return 'economy' end
    if action:find('world',1,true) or action:find('weather',1,true) or action:find('location',1,true)
        or action:find('garage',1,true) or action:find('vehicle',1,true) then return 'world' end
    if action:find('call',1,true) or action:find('warning',1,true) or action:find('ban',1,true)
        or action:find('permission',1,true) then return 'staff' end
    return 'main'
end

local function enqueue(action, entry)
    local routes = I.Store.get('audit_routes',{routes={}})
    local category = categoryFor(action)
    local alias = (routes.routes or {})[action] or (routes.routes or {})[category]
    if not alias or not destination(alias) then return end
    if #queue >= 250 then table.remove(queue,1) end
    queue[#queue+1] = {alias=alias,attempts=0,body=json.encode({
        allowed_mentions={parse={}}, embeds={{title='IC Admin • '..action,color=4892671,
            description=('Administrador: %s (#%s)\nAlvo: %s (#%s)\n```json\n%s\n```'):format(
                entry.actor_name or 'Servidor',entry.actor_id or '-',entry.target_name or '-',entry.target_id or '-',
                json.encode(entry.payload):sub(1,2800))}}
    })}
end

function I.audit(action, ctx, targetId, payload)
    if not I.ready then return false end
    action=tostring(action or ''):sub(1,96)
    if action=='' then return false end
    ctx=type(ctx)=='table' and ctx or {}
    local entry={action=action,actor_id=tonumber(ctx.userId),actor_name=displayName(tonumber(ctx.userId)),
        target_id=tonumber(targetId),target_name=displayName(tonumber(targetId)),payload=clean(payload or {})}
    local ok = pcall(function()
        I.Store.insert('INSERT INTO ic_admin_audit (action,actor_id,actor_name,target_id,target_name,payload) VALUES (?,?,?,?,?,?)',
            {entry.action,entry.actor_id or 0,entry.actor_name or 'Servidor',entry.target_id or 0,
             entry.target_name or '-',json.encode(entry.payload)})
        enqueue(action,entry)
    end)
    if not ok then print('^1[ic_admin]^7 Auditoria indisponível; detalhe privado omitido.') end
    return ok
end

exports('sendLog',function(key,payload)
    if not I.active() then return false,'inactive' end
    payload=type(payload)=='table' and payload or {}
    return I.audit(key,{userId=tonumber(payload.actorId)},tonumber(payload.targetId),payload)
end)

I.register('audit.list',{permission='view_logs',handler=function(_,p)
    local page=I.int(p.page or 1,1,100000,'Página')
    local where,params={'1=1'},{}
    for _,field in ipairs({'actorId','targetId'}) do
        if p[field] and tostring(p[field])~='' then
            where[#where+1]=(field=='actorId' and 'actor_id' or 'target_id')..'=?'
            params[#params+1]=I.int(p[field],1,2147483647,'Passaporte')
        end
    end
    if p.action and p.action~='' then where[#where+1]='action=?'; params[#params+1]=I.text(p.action,96,true,'Ação') end
    local condition=table.concat(where,' AND ')
    local count=I.Store.query('SELECT COUNT(*) total FROM ic_admin_audit WHERE '..condition,params)
    local listParams={table.unpack(params)}; listParams[#listParams+1]=50; listParams[#listParams+1]=(page-1)*50
    local rows=I.Store.query('SELECT id,action,actor_id,actor_name,target_id,target_name,payload,created_at FROM ic_admin_audit WHERE '..condition..' ORDER BY id DESC LIMIT ? OFFSET ?',listParams)
    for _,row in ipairs(rows) do local ok,data=pcall(json.decode,row.payload or '{}'); row.payload=ok and data or {} end
    return {entries=rows,total=tonumber(count[1] and count[1].total) or 0,page=page}
end})

I.register('audit.destinations',{permission='view_logs',handler=function()
    local list={}
    for _,id in ipairs({'main','staff','economy','world'}) do list[#list+1]={id=id,label=aliases[id],configured=destination(id)~=nil} end
    local doc=I.Store.get('audit_routes',{routes={}})
    return {destinations=list,routes=doc.routes or {},categories={'main','staff','economy','world'}}
end})

I.register('audit.update',{permission='logs_manage',mutating=true,handler=function(ctx,p)
    I.requireOwner(ctx)
    local category=I.text(p.category,96,true,'Categoria')
    if not category:match('^[%w_.%-]+$') then I.fail('INVALID','Categoria inválida.') end
    local alias=I.text(p.destination or '',16,false,'Destino')
    if alias~='' and not destination(alias) then I.fail('INVALID','Destino privado não configurado.') end
    return I.withLock('audit_routes',function()
        local doc,rev=I.Store.get('audit_routes',{routes={}})
        doc.routes=doc.routes or {}; doc.routes[category]=alias~='' and alias or nil
        I.effect(ctx)
        if not I.Store.put('audit_routes',doc,rev) then I.fail('CONFLICT','Configuração alterada; atualize a tela.') end
        return {routes=doc.routes}
    end)
end})

CreateThread(function()
    while true do
        Wait(1500)
        if I.active() then
            if os.time()-lastPrune>=86400 then
                local ok=pcall(I.Store.update,'DELETE FROM ic_admin_audit WHERE created_at < DATE_SUB(UTC_TIMESTAMP(), INTERVAL 90 DAY)',{})
                if ok then lastPrune=os.time() end
            end
            if not sending and queue[1] then
                local entry=table.remove(queue,1); local url=destination(entry.alias)
                if url then
                    sending=true; entry.attempts=entry.attempts+1
                    PerformHttpRequest(url,function(status)
                        sending=false
                        if (status==429 or status>=500 or status==0) and entry.attempts<3 and #queue<250 then queue[#queue+1]=entry end
                    end,'POST',entry.body,{['Content-Type']='application/json'})
                end
            end
        end
    end
end)

I.Audit={clean=clean,categoryFor=categoryFor}
