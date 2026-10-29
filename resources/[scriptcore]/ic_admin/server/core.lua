ICAdmin = { Config = ICAdminConfig, ready = false, methods = {}, definitions = {}, sessions = {}, locks = {} }
local I = ICAdmin
local Proxy = module('vrp','lib/Proxy')
I.vRP = Proxy.getInterface('vRP')
function I.fail(code, message) error({ icAdmin = true, code = code, message = message }, 0) end
function I.int(value, minimum, maximum, label)
    local n = tonumber(value)
    if not n or n ~= n or n == math.huge or n == -math.huge or n % 1 ~= 0 or n < (minimum or 0) or n > (maximum or 2147483647) then
        I.fail('INVALID_INPUT', (label or 'Número') .. ' inválido.')
    end
    return n
end
function I.text(value, maximum, required, label)
    if type(value) ~= 'string' then if not required and value == nil then return '' end I.fail('INVALID_INPUT', (label or 'Texto') .. ' inválido.') end
    value = value:match('^%s*(.-)%s*$')
    if #value > (maximum or 500) or value:find('[%z\1-\8\11\12\14-\31]') or (required and value == '') then
        I.fail('INVALID_INPUT', (label or 'Texto') .. ' inválido.')
    end
    return value
end
function I.copy(value)
    if type(value) ~= 'table' then return value end
    local out = {}; for k,v in pairs(value) do out[k] = I.copy(v) end; return out
end
function I.canonical(value, depth)
    depth = depth or 0
    if depth > 12 then I.fail('INVALID_INPUT','Dados excessivamente aninhados.') end
    if type(value) ~= 'table' then
        if type(value)=='number' and (value~=value or math.abs(value)==math.huge) then I.fail('INVALID_INPUT','Número inválido.') end
        if type(value)~='string' and type(value)~='number' and type(value)~='boolean' and value~=nil then I.fail('INVALID_INPUT','Tipo inválido.') end
        return json.encode(value)
    end
    local keys={}; for k in pairs(value) do
        if type(k)~='string' and type(k)~='number' then I.fail('INVALID_INPUT','Chave inválida.') end
        keys[#keys+1]=k
    end
    if #keys>2000 then I.fail('INVALID_INPUT','Dados excessivos.') end
    table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
    local fields={}; for _,k in ipairs(keys) do fields[#fields+1]=json.encode(tostring(k))..':'..I.canonical(value[k],depth+1) end
    return '{'..table.concat(fields,',')..'}'
end
function I.active()
    if not I.ready or GetConvar('ic_admin_mode','preview')~='active' or GetConvar('ic_admin_service_resource','ic_admin')~='ic_admin' then return false end
    local previous=GetConvar('ic_admin_previous_resource','')
    if previous=='' or previous=='ic_admin' then return true end
    local state=GetResourceState(previous)
    return state~='started' and state~='starting' and state~='stopping'
end
function I.role(userId)
    for _,role in ipairs(I.Config.roles) do if I.vRP.hasGroup(userId,role) then return role end end
end
function I.allowed(userId, permission, policies)
    local role=I.role(userId)
    if not role then return false end
    if I.Config.ownerOnly[permission] then return role=='dono' or role=='developer' end
    if role=='dono' or role=='developer' then return true end
    local perms = policies or (I.ready and I.Store.get('permissions',{actions={}}) or {actions={}})
    local entry = (perms.actions or {})[permission]
    if not entry and I.Config.permissionAliases[permission] then entry=(perms.actions or {})[I.Config.permissionAliases[permission]] end
    if I.role(userId)~=role then return false end
    if type(entry)=='table' and type(entry[role])=='boolean' then return entry[role] end
    return role=='admin'
end
function I.requireOwner(ctx)
    local role=I.role(ctx.userId)
    if I.vRP.getUserId(ctx.source)~=ctx.userId or (role~='dono' and role~='developer') then I.fail('FORBIDDEN','Acesso exclusivo de Dono e Developer.') end
end
function I.target(value, online)
    local id=I.int(value,1,2147483647,'Passaporte')
    if I.userLocks and I.userLocks[id] then I.fail('MAINTENANCE','Passaporte em manutenção.') end
    local source=tonumber(I.vRP.getUserSource(id))
    if online and (not source or I.vRP.getUserId(source)~=id) then I.fail('PLAYER_OFFLINE','O jogador precisa estar online.') end
    if not online and not source then
        local rows=I.Store.query('SELECT id FROM vrp_users WHERE id=? LIMIT 1',{id})
        if not rows[1] then I.fail('NOT_FOUND','Passaporte não encontrado.') end
    end
    return id,source
end
function I.withLock(key, fn)
    if I.locks[key] then I.fail('BUSY','Operação em andamento. Aguarde.') end
    I.locks[key]=true
    local result=table.pack(pcall(fn))
    I.locks[key]=nil
    if not result[1] then error(result[2],0) end
    return table.unpack(result,2,result.n)
end
function I.effect(ctx)
    local session=I.sessions[ctx.source]
    if I.vRP.getUserId(ctx.source) ~= ctx.userId or not session or session.id~=ctx.sessionId or session.userId~=ctx.userId or session.expires<os.time() then I.fail('SESSION_EXPIRED','Sessão encerrada.') end
    if ctx.permission and not I.allowed(ctx.userId,ctx.permission) then I.fail('FORBIDDEN','Permissão revogada.') end
    -- Permission storage may yield. Revocation must still win before the effect.
    session=I.sessions[ctx.source]
    if not session or session.id~=ctx.sessionId or session.userId~=ctx.userId or session.expires<os.time() or I.vRP.getUserId(ctx.source)~=ctx.userId then I.fail('SESSION_EXPIRED','Sessão encerrada.') end
    ctx.effectStarted=true
end
function I.register(name, descriptor)
    assert(not I.methods[name], 'Método duplicado: '..name)
    assert(type(descriptor.handler)=='function','Handler ausente')
    I.methods[name]=descriptor
    if descriptor.permission then I.definitions[descriptor.permission]={key=descriptor.permission,label=descriptor.label or name} end
end
for _,tab in ipairs(I.Config.tabs) do I.definitions[tab.permission]={key=tab.permission,label=tab.label} end
function I.permissions(userId)
    local allowedActions,defs={},{}
    local policies=I.Store.get('permissions',{actions={}})
    for key,def in pairs(I.definitions) do
        allowedActions[key]=I.allowed(userId,key,policies)
        defs[#defs+1]={key=key,label=def.label,roles=(policies.actions or {})[key] or (policies.actions or {})[I.Config.permissionAliases[key] or ''] or {admin=true,moderador=false,suporte=false}}
    end
    table.sort(defs,function(a,b)return a.key<b.key end)
    local role=I.role(userId)
    return {allowedActions=allowedActions,canManage=role=='dono' or role=='developer',definitions=defs,roles=I.Config.roles}
end
function I.newSession(source,userId)
    local token=('%x-%x-%x-%x'):format(os.time(),GetGameTimer(),math.random(1,0x7fffffff),source)
    I.sessions[source]={id=token,userId=userId,expires=os.time()+I.Config.sessionSeconds,role=I.role(userId)}
    return token
end
function I.closeSession(source)
    I.sessions[source]=nil
    TriggerClientEvent('ic_admin:sessionClosed',source)
    TriggerEvent('ic_admin:sessionRevoked',source)
end
local rates={}
local function rate(source, mutating)
    local key=tostring(source)..(mutating and ':m' or ':r')
    local now=GetGameTimer(); local r=rates[key] or {at=now,tokens=mutating and I.Config.mutationRate or I.Config.readRate}
    local limit=mutating and I.Config.mutationRate or I.Config.readRate
    r.tokens=math.min(limit,r.tokens+math.max(0,now-r.at)/1000*limit);r.at=now;rates[key]=r
    if r.tokens<1 then I.fail('RATE_LIMIT','Muitas solicitações. Aguarde.') end
    r.tokens=r.tokens-1
end
function I.dispatch(source,request)
    local requestId=type(request)=='table' and request.requestId or ''
    local ctx,opKey,descriptor,canonical
    local ok,result=pcall(function()
        if type(request)~='table' then I.fail('INVALID_INPUT','Solicitação inválida.') end
        requestId=I.text(requestId,96,true,'Identificador')
        local name=I.text(request.method,96,true,'Método')
        descriptor=I.methods[name]
        if not descriptor then I.fail('UNKNOWN_METHOD','Função desconhecida.') end
        rate(source,descriptor.mutating)
        if not I.ready then I.fail('SCHEMA_REQUIRED','Banco do IC Admin indisponível. Execute a migração e reinicie o recurso.') end
        local userId=I.vRP.getUserId(source)
        if not userId then I.fail('UNAUTHENTICATED','Jogador não identificado.') end
        local role=I.role(userId)
        if not descriptor.public and not role then I.fail('FORBIDDEN','Você não tem acesso ao painel.') end
        if descriptor.permission and not I.allowed(userId,descriptor.permission) then I.fail('FORBIDDEN','Função não permitida.') end
        if name~='bootstrap' and name~='player.bootstrap' then
            local s=I.sessions[source]
            if not s or s.userId~=userId or s.id~=request.sessionId or s.expires<os.time() then I.fail('SESSION_EXPIRED','Abra o painel novamente.') end
            s.expires=os.time()+I.Config.sessionSeconds
        end
        if descriptor.mutating and not I.active() then I.fail('PREVIEW_MODE','Painel em homologação: alterações estão desativadas.') end
        local payload=request.payload or {}
        if type(payload)~='table' then I.fail('INVALID_INPUT','Dados inválidos.') end
        canonical=I.canonical(payload)
        if #canonical>I.Config.maxPayloadBytes then I.fail('INVALID_INPUT','Solicitação muito grande.') end
        ctx={source=source,userId=userId,role=role,sessionId=request.sessionId,requestId=requestId,permission=descriptor.permission}
        if descriptor.online then I.target(payload.targetId,true) end
        if descriptor.validate then descriptor.validate(ctx,payload) end
        if descriptor.mutating then
            opKey=('%d:%s:%s'):format(userId,request.sessionId,requestId)
            local inserted=I.Store.update("INSERT IGNORE INTO ic_admin_operations(operation_key,actor_id,method,payload,state) VALUES(?,?,?,?,'pending')",{opKey,userId,name,canonical})
            if inserted~=1 then
                local old=I.Store.query('SELECT method,payload,state,result FROM ic_admin_operations WHERE operation_key=?',{opKey})[1]
                if not old or old.method~=name or old.payload~=canonical then I.fail('REQUEST_CONFLICT','Identificador de solicitação já utilizado.') end
                if old.state=='applied' or old.state=='failed' then return json.decode(old.result) end
                I.fail('OPERATION_UNCERTAIN','Operação pendente de conferência. Não repita a entrega.')
            end
        end
        if opKey then ctx.operationOwned=true end
        local data=descriptor.handler(ctx,payload)
        local response={requestId=requestId,ok=true,data=data or {}}
        if opKey then
            I.Store.update("UPDATE ic_admin_operations SET state='applied',result=?,updated_at=CURRENT_TIMESTAMP WHERE operation_key=?",{json.encode(response),opKey})
            if I.audit then I.audit(descriptor.audit or name,ctx,tonumber(payload.targetId),{result='applied',operationRequest=requestId,request=payload}) end
        end
        return response
    end)
    if ok then return result end
    local typed=type(result)=='table' and result.icAdmin
    local response={requestId=type(requestId)=='string' and requestId:sub(1,96) or '',ok=false,error={code=typed and result.code or 'INTERNAL_ERROR',message=typed and result.message or 'Erro interno. Consulte a auditoria operacional.'}}
    if opKey then
        -- Only the request which INSERTed owns the operation. Duplicate requests never rewrite it.
        local existing=I.Store.query('SELECT state FROM ic_admin_operations WHERE operation_key=?',{opKey})[1]
        if ctx and ctx.operationOwned and existing and existing.state=='pending' then
            pcall(I.Store.update,"UPDATE ic_admin_operations SET state=?,result=?,updated_at=CURRENT_TIMESTAMP WHERE operation_key=?",{ctx.effectStarted and 'uncertain' or 'failed',json.encode(response),opKey})
        end
    end
    return response
end
RegisterNetEvent('ic_admin:request',function(request)
    local actor=source
    if type(actor)~='number' or actor<=0 then return end
    local ok,response=pcall(I.dispatch,actor,request)
    if not ok then response={requestId=type(request)=='table' and tostring(request.requestId or ''):sub(1,96) or '',ok=false,error={code='STORAGE_ERROR',message='Armazenamento indisponível. Não repita alterações pendentes.'}} end
    TriggerClientEvent('ic_admin:response',actor,response)
end)
AddEventHandler('playerDropped',function()
    local actor=source; I.sessions[actor]=nil
    rates[tostring(actor)..':m']=nil;rates[tostring(actor)..':r']=nil
    TriggerEvent('ic_admin:sessionRevoked',actor)
end)
AddEventHandler('vRP:playerJoinGroup',function(id)
    local actor=I.vRP.getUserSource(id)
    if actor and I.sessions[actor] and I.sessions[actor].role~=I.role(id) then I.closeSession(actor) end
end)
AddEventHandler('vRP:playerLeaveGroup',function(id)
    local actor=I.vRP.getUserSource(id)
    if actor and I.sessions[actor] and I.sessions[actor].role~=I.role(id) then I.closeSession(actor) end
end)
