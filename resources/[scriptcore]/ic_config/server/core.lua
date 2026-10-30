-- Interior City configuration transport. No vendor runtime or remote authorization.
ICConfigServer = { methods = {}, sessions = {}, locked = false }
local S = ICConfigServer
local Proxy = module('vrp', 'lib/Proxy')
S.vRP = Proxy.getInterface('vRP')

function S.fail(code, message)
    error({ icConfig = true, code = code, message = message }, 0)
end

function S.text(value, optional)
    if optional and (value == nil or value == '') then return '' end
    if type(value) ~= 'string' or #value < 1 or #value > 160 or value:find('[%c]') then
        S.fail('INVALID_INPUT', 'Identificador inválido.')
    end
    return value
end

function S.number(value, minimum, maximum)
    if type(value) ~= 'number' or value ~= value or value == math.huge or value == -math.huge
        or value < (minimum or -1000000) or value > (maximum or 1000000) then
        S.fail('INVALID_INPUT', 'Valor numérico inválido.')
    end
    return value
end

function S.table(value)
    if type(value) ~= 'table' then S.fail('INVALID_INPUT', 'Estrutura inválida.') end
    return value
end

function S.coords(value, heading)
    S.table(value)
    local out = {x=S.number(value.x or value[1]),y=S.number(value.y or value[2]),z=S.number(value.z or value[3])}
    if heading then out.w=S.number(value.w or value.h or value[4],-360,360) end
    return out
end

local function privateKey(key)
    key=tostring(key):lower()
    return key:find('webhook',1,true) or key:find('password',1,true) or key:find('secret',1,true)
        or key:find('token',1,true) or key=='authorization' or key=='cookie' or key=='license' or key=='api_key' or key=='apikey'
end
S.privateKey=privateKey

function S.copy(value, clean, depth)
    depth=depth or 0
    if depth>16 then S.fail('INVALID_INPUT','Estrutura excede o limite.') end
    if type(value)=='table' then
        local out={}
        for key,item in pairs(value) do
            if not clean or not privateKey(key) then out[key]=S.copy(item,clean,depth+1) end
        end
        return out
    end
    if clean and type(value)=='string' and value:find('/api/webhooks/',1,true) then return '[destino privado omitido]' end
    return value
end

local function containsPrivate(value)
    if type(value)~='table' then return false end
    for key,item in pairs(value) do if privateKey(key) or containsPrivate(item) then return true end end
    return false
end
local function samePublic(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for key,value in pairs(a) do if not samePublic(value,b[key]) then return false end end
    for key in pairs(b) do if a[key]==nil then return false end end
    return true
end
-- Preserve credentials only on the server when saving public full-document editors.
-- Match secret-bearing list entries by stable identity, never by a moved row index.
function S.preservePrivate(current, public)
    local out=S.copy(public)
    for key,item in pairs(current or {}) do
        if privateKey(key) then out[key]=S.copy(item)
        elseif type(key)=='number' and type(item)=='table' and containsPrivate(item) then
            local identity
            for _,field in ipairs({'id','name','spawn'}) do
                if type(item[field])=='string' or type(item[field])=='number' then identity=field;break end
            end
            if identity then
                local target
                for publicKey,row in pairs(public) do
                    if type(row)=='table' and row[identity]==item[identity] then
                        if target then S.fail('CONFLICT','Identidade duplicada em uma lista com dados privados.') end
                        target=publicKey
                    end
                end
                if target then out[target]=S.preservePrivate(item,out[target]) end
            else
                if not samePublic(S.copy(item,true),out[key]) then
                    S.fail('PRIVATE_FIELD','Uma lista com dados privados sem identificador não pode ser alterada pelo painel.')
                end
                out[key]=S.preservePrivate(item,out[key])
            end
        elseif type(item)=='table' and type(out[key])=='table' then
            out[key]=S.preservePrivate(item,out[key])
        end
    end
    return out
end

local function validateTree(value, depth, budget)
    if depth>12 then S.fail('INVALID_INPUT','Estrutura excede o limite.') end
    local kind=type(value)
    if kind=='table' then
        for key,item in pairs(value) do
            budget.count=budget.count+1
            if budget.count>20000 or (type(key)~='string' and type(key)~='number') then S.fail('INVALID_INPUT','Estrutura excede o limite.') end
            if type(key)=='string' and (#key>160 or privateKey(key)) then S.fail('PRIVATE_FIELD','Campos privados são administrados fora do painel.') end
            validateTree(item,depth+1,budget)
        end
    elseif kind=='number' then S.number(value,-1e12,1e12)
    elseif kind=='string' then
        if #value>4096 or value:find('/api/webhooks/',1,true) then S.fail('INVALID_INPUT','Texto inválido ou privado.') end
    elseif kind~='boolean' and kind~='nil' then S.fail('INVALID_INPUT','Tipo de dado inválido.') end
end

function S.authorize(playerSource, expectedUser)
    if GetConvar('ic_config_enabled','false')~='true' then S.fail('DISABLED','IC Config desabilitado.') end
    local previous=ICConfig.PreviousResource or 'mg_config_panel'
    local state=GetResourceState(previous)
    if state~='stopped' and state~='missing' then S.fail('PROVIDER_CONFLICT','Pare o painel anterior antes de usar o IC Config.') end
    if type(playerSource)~='number' or playerSource<=0 then S.fail('FORBIDDEN','Acesso restrito a jogadores autorizados.') end
    local id=S.vRP.getUserId(playerSource)
    if not id or (expectedUser and expectedUser~=id) then S.fail('FORBIDDEN','Sessão inválida.') end
    local groups=S.vRP.getUserGroups(id) or {}
    for name,present in pairs(groups) do
        if present and ICConfig.AllowedGroups[name]==true then return id end
    end
    S.fail('FORBIDDEN','Acesso exclusivo de Dono e Developer.')
end

function S.register(name, mutating, handler)
    assert(not S.methods[name], 'Duplicate IC Config method')
    S.methods[name]={mutating=mutating,handler=handler}
end

function S.call(ctx, resourceKey, exportName, ...)
    S.authorize(ctx.source,ctx.userId)
    if ctx.mutating and GetConvar('ic_config_writes_enabled','false')~='true' then S.fail('WRITE_DISABLED','Gravação desabilitada.') end
    local resource=ICConfig.Resources[resourceKey]
    if type(resource)~='string' or GetResourceState(resource)~='started' then S.fail('RESOURCE_UNAVAILABLE','Recurso necessário indisponível: '..resourceKey) end
    local args=table.pack(...)
    local result=table.pack(pcall(function() return exports[resource][exportName](nil,table.unpack(args,1,args.n)) end))
    -- FiveM export proxies accept the conventional colon receiver. Do not relay raw failures.
    if not result[1] then S.fail('EXPORT_FAILED','A integração falhou. Confira o estado antes de repetir a operação.') end
    return table.unpack(result,2,result.n)
end

function S.mutate(ctx, resourceKey, exportName, ...)
    local ok=S.call(ctx,resourceKey,exportName,...)
    if ok~=true then S.fail('OPERATION_FAILED','O recurso recusou ou não confirmou a gravação. Confira o estado antes de repetir.') end
    return {message='Operação confirmada pelo recurso da cidade.'}
end

S.register('hasAccess',false,function() return true end)
-- Authorize and validate each self-teleport; never accept a target player/entity.
S.register('teleport',false,function(_,payload)
    return {coords=S.coords(payload.coords)}
end)
S.register('bootstrap',false,function()
    local methods={}
    for name,definition in pairs(S.methods) do
        methods[#methods+1]={name=name,mutating=definition.mutating,available=definition.available~=false,reason=definition.reason}
    end
    table.sort(methods,function(a,b)return a.name<b.name end)
    return {brand='Interior City',writesEnabled=GetConvar('ic_config_writes_enabled','false')=='true',methods=methods}
end)

function S.request(playerSource, request)
    local requestId=type(request)=='table' and request.requestId or nil
    if type(requestId)~='string' or #requestId<1 or #requestId>96 or not requestId:match('^[%w_.:%-]+$') then return end
    local response={requestId=requestId,ok=false}
    local actor,method,mutating
    local acquired=false
    local ok,result=pcall(function()
        actor=S.authorize(playerSource)
        method=S.text(request.method)
        local definition=S.methods[method]
        if not definition then S.fail('UNKNOWN_METHOD','Operação não reconhecida.') end
        mutating=definition.mutating
        local session=S.sessions[playerSource]
        if not session or session.userId~=actor then session={userId=actor,seen={},count=0,started=os.time(),requests=0};S.sessions[playerSource]=session end
        local now=os.time()
        if now-session.started>=10 then session.started=now;session.requests=0 end
        session.requests=session.requests+1
        if session.requests>80 then S.fail('RATE_LIMIT','Aguarde antes de continuar.') end
        if session.seen[requestId] then S.fail('DUPLICATE_REQUEST','Solicitação já recebida; confira o estado antes de repetir.') end
        if session.count>=4096 then S.fail('SESSION_LIMIT','Reconecte para iniciar uma nova sessão de configuração.') end
        session.seen[requestId]=true;session.count=session.count+1
        local payload=request.payload or {}
        S.table(payload);validateTree(payload,0,{count=0})
        if mutating then
            if GetConvar('ic_config_writes_enabled','false')~='true' then S.fail('WRITE_DISABLED','Gravação desabilitada até preparar e validar a persistência.') end
            if S.locked then S.fail('BUSY','Outra configuração está sendo gravada. Atualize antes de tentar novamente.') end
            S.locked=true;acquired=true
        end
        local data=definition.handler({source=playerSource,userId=actor,mutating=mutating},payload)
        if not mutating then S.authorize(playerSource,actor) end
        return S.copy(data,true)
    end)
    if acquired then S.locked=false end
    if ok then response.ok=true;response.data=result
    elseif type(result)=='table' and result.icConfig then response.error={code=result.code,message=result.message}
    else response.error={code='INTERNAL_ERROR',message='Falha interna. Confira o estado antes de repetir a operação.'} end
    if mutating then print(('[ic_config:audit] actor=%s method=%s outcome=%s'):format(tostring(actor or 0),method or 'invalid',response.ok and 'confirmed' or response.error.code)) end
    TriggerClientEvent('ic_config:response',playerSource,response)
end

RegisterNetEvent('ic_config:request',function(request) S.request(source,request) end)
AddEventHandler('playerDropped',function() S.sessions[source]=nil end)
