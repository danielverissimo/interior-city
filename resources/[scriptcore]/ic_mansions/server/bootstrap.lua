local M=ICM
local syncTimes={}
local function validate(value,depth,budget)
    if depth>12 then M.fail('INVALID_INPUT','Estrutura excede o limite.')end
    local kind=type(value)
    if kind=='table'then
        for key,item in pairs(value)do
            budget.count=budget.count+1
            if budget.count>10000 or(type(key)~='string'and type(key)~='number')then M.fail('INVALID_INPUT','Estrutura excede o limite.')end
            if type(key)=='string'and(#key>160 or key:find('[%c]'))then M.fail('INVALID_INPUT','Campo inválido.')end
            validate(item,depth+1,budget)
        end
    elseif kind=='number'then M.number(value,-1000000000000,1000000000000)
    elseif kind=='string'then if #value>4096 then M.fail('INVALID_INPUT','Texto excede o limite.')end
    elseif kind~='boolean'and kind~='nil'then M.fail('INVALID_INPUT','Tipo de dado inválido.')end
end
function M.request(sourceId,request)
    local id=type(request)=='table'and request.requestId or nil
    if type(id)~='string'or #id<1 or #id>96 or not id:match('^[%w_.:%-]+$')then return end
    local response={requestId=id,ok=false};local actor,method,mutating
    local ok,value=pcall(function()
        actor=M.user(sourceId);method=M.text(request.method);local definition=M.methods[method]
        if not definition then M.fail('UNKNOWN_METHOD','Operação desconhecida.')end
        mutating=definition.mutating
        local session=M.sessions[sourceId]
        if not session or session.userId~=actor then session={userId=actor,seen={},count=0,started=os.time(),rate=0};M.sessions[sourceId]=session end
        if os.time()-session.started>=10 then session.started=os.time();session.rate=0 end
        session.rate=session.rate+1;if session.rate>80 then M.fail('RATE_LIMIT','Aguarde antes de continuar.')end
        if session.seen[id]then M.fail('DUPLICATE_REQUEST','Solicitação já recebida. Atualize os dados antes de continuar.')end
        if session.count>=4096 then M.fail('SESSION_LIMIT','Reconecte para iniciar uma nova sessão.')end
        session.seen[id]=true;session.count=session.count+1
        local payload=request.payload or{};M.table(payload);validate(payload,0,{count=0})
        local ctx={source=sourceId,userId=actor,requestId=id}
        local function invoke()return definition.fn(ctx,payload)end
        local result
        if mutating then result=M.lock(invoke)else result=invoke()end
        M.user(sourceId,actor)
        return result
    end)
    if ok then response.ok=true;response.data=value else response.error=M.error(value)end
    if mutating then print(('[ic_mansions:audit] actor=%s method=%s outcome=%s'):format(tostring(actor or 0),method or'invalid',response.ok and'confirmed'or response.error.code))end
    TriggerClientEvent('ic_mansions:response',sourceId,response)
end
RegisterNetEvent('ic_mansions:request',function(request)M.request(source,request)end)
AddEventHandler('playerDropped',function()
    local src=source;M.sessions[src]=nil
    syncTimes[src]=nil
    for id,q in pairs(M.quotes)do if q.source==src then M.quotes[id]=nil end end
    for id,q in pairs(M.placements)do if q.source==src then M.placements[id]=nil end end
end)
local function sync(sourceId)
    local now=GetGameTimer()
    if syncTimes[sourceId]and now-syncTimes[sourceId]<1000 then return false end
    syncTimes[sourceId]=now
    local ok=pcall(function()M.user(sourceId);M.broadcast(sourceId)end)
    return ok
end
RegisterNetEvent('ic_mansions:requestSync',function()sync(source)end)
RegisterNetEvent('ic_mansions:requestFurnitureSync',function()sync(source)end)
AddEventHandler('vRP:playerSpawn',function(_,sourceId)
    SetTimeout(1500,function()sync(sourceId)end)
end)
local function administrative(fn,...)
    local args=table.pack(...);local result=table.pack(pcall(function()return fn(table.unpack(args,1,args.n))end))
    if result[1]then return table.unpack(result,2,result.n)end
    local err=M.error(result[2]);return false,err.message,err.code
end
exports('getMansions',function(ctx)return M.adminList(ctx)end)
exports('saveMansion',function(originalId,data,ctx)return administrative(M.adminSave,originalId,data,ctx)end)
exports('removeMansion',function(id,ctx)return administrative(M.adminRemove,id,ctx)end)
exports('getPublicMansions',function()M.ready();return M.publicMansions()end)
exports('getUserMansions',function(userId)
    M.ready()
    if GetInvokingResource()~='dm_spawn'then M.fail('FORBIDDEN','Consulta reservada ao recurso de spawn.')end
    userId=M.integer(userId);local out={}
    for _,row in ipairs(M.state().mansions)do
        if M.isMember(row,userId)and#M.pending(row.id)==0 then out[#out+1]={id=row.id,name=row.name,purchaseCoords=M.copy(row.purchaseCoords),ownerId=row.ownerId,members=M.copy(row.members or{}),purchasedAt=row.purchasedAt}end
    end
    return out
end)
local function access(sourceId,row)
    local userId=M.user(sourceId)
    if not row then return true end
    if #M.pending(row.id)>0 then return false end
    local ctx={source=sourceId,userId=userId}
    if M.taxValid(row,ctx,true)then return true end
    TriggerClientEvent('ic_mansions:taxDue',sourceId,{id=row.id,name=row.name,amount=row.iptuValue})
    return false
end
exports('checkAccessByMansionId',function(sourceId,id)
    local ok,value=pcall(function()
        M.ready();local row
        for _,entry in ipairs(M.state().mansions)do if entry.id==tostring(id or'')then row=entry;break end end
        return access(sourceId,row)
    end)
    return ok and value==true
end)
exports('checkAccessByPermission',function(sourceId,permission)
    local ok,value=pcall(function()
        M.ready();local row
        for _,op in pairs(M.state().operations)do
            if op.phase~='done'and op.phase~='cancelled'then
                for _,field in ipairs({'before','after'})do local snapshot=op.detail and op.detail[field]
                    if snapshot and snapshot.permission==permission then return false end
                end
            end
        end
        for _,entry in ipairs(M.state().mansions)do if entry.permission==permission then row=entry;break end end
        return access(sourceId,row)
    end)
    return ok and value==true
end)
CreateThread(function()
    Wait(0)
    local ok=pcall(function()M.ready();M.broadcast()end)
    if GetConvar('ic_mansions_enabled','false')=='true'then
        print('[ic_mansions:operational] '..json.encode({active=ok,provider='ic_mansions',generation=ok and M.Store.generation or 0}))
    end
    if not ok and GetConvar('ic_mansions_enabled','false')=='true'then
        print('[ic_mansions] Inicialização bloqueada; confira seleção do provedor e os arquivos de estado.')
    end
end)
