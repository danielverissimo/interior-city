local M=ICM
M.vRP=module('vrp','lib/Proxy').getInterface('vRP')
function M.fail(code,message)error({icMansions=true,code=code,message=message},0)end
function M.text(v,optional,max)
    if optional and (v==nil or v=='')then return ''end
    if type(v)~='string'or #v<1 or #v>(max or 160)or v:find('[%c]')then M.fail('INVALID_INPUT','Texto ou identificador inválido.')end
    return v
end
function M.number(v,min,max)
    if type(v)~='number'or v~=v or v==math.huge or v==-math.huge or v<(min or -1000000)or v>(max or 1000000)then M.fail('INVALID_INPUT','Valor numérico inválido.')end
    return v
end
function M.integer(v,min,max)M.number(v,min or 1,max or 2147483647);if v%1~=0 then M.fail('INVALID_INPUT','Informe um número inteiro.')end;return v end
function M.table(v)if type(v)~='table'then M.fail('INVALID_INPUT','Estrutura inválida.')end;return v end
function M.coords(v,heading)
    M.table(v);local out={x=M.number(v.x or v[1]),y=M.number(v.y or v[2]),z=M.number(v.z or v[3])}
    if heading then out.w=M.number(v.w or v.heading or v.h or v[4]or 0,-360,360)end
    return out
end
function M.active()
    if GetConvar('ic_mansions_enabled','false')~='true'or GetConvar('ic_mansions_resource','m_mansions')~=GetCurrentResourceName()then M.fail('DISABLED','IC Mansões desabilitado ou não selecionado.')end
    local legacy=GetResourceState('m_mansions')
    if legacy~='stopped'and legacy~='missing'then M.fail('PROVIDER_CONFLICT','Pare o sistema anterior de mansões antes de habilitar o próprio.')end
end
function M.ready()
    M.active()
    if M.Store.quarantined then M.fail('STORAGE_UNCERTAIN','Persistência bloqueada; confira os arquivos antes de reiniciar o recurso.')end
    if M.Store.generation==nil then M.Store.load()end
    if M.permissionPublishFailed then M.fail('PERMISSION_STATE_UNAVAILABLE','O estado de acesso não pôde ser publicado. Aguarde a recuperação do recurso.')end
end
function M.user(sourceId,expected)
    M.ready()
    if type(sourceId)~='number'or sourceId<=0 then M.fail('FORBIDDEN','Sessão de jogador necessária.')end
    local id=M.vRP.getUserId(sourceId)
    if not id or(expected and id~=expected)then M.fail('FORBIDDEN','Sessão inválida.')end
    return id
end
function M.inGroups(id,allowed)
    for name,present in pairs(M.vRP.getUserGroups(id)or{})do if present and allowed[name]then return true end end
    return false
end
function M.admin(ctx)
    M.table(ctx);local id=M.user(ctx.source,ctx.userId)
    if not M.inGroups(id,ICMConfig.AdminGroups or{developer=true,dono=true})then M.fail('FORBIDDEN','Acesso exclusivo de Dono e Developer.')end
    return id
end
function M.state()if not M.Store.state then M.Store.load()end;return M.Store.state end
function M.find(id,state)
    id=M.text(id);for i,row in ipairs((state or M.state()).mansions)do if row.id==id then return row,i end end
    M.fail('NOT_FOUND','Mansão não encontrada.')
end
function M.isMember(row,userId)
    if row.ownerId==userId then return true end
    for _,id in ipairs(row.members or{})do if tonumber(id)==userId then return true end end
    return false
end
function M.position(sourceId)
    local ped=GetPlayerPed(sourceId)
    if not ped or ped==0 then M.fail('POSITION_UNAVAILABLE','Posição do jogador indisponível.')end
    local c=GetEntityCoords(ped);return{x=c.x,y=c.y,z=c.z}
end
function M.distance(a,b)return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2)end
function M.near(sourceId,row,radius)
    if M.distance(M.position(sourceId),row.purchaseCoords)>radius then M.fail('TOO_FAR','Aproxime-se da mansão para continuar.')end
end
function M.owner(ctx,row,forFurniture)
    M.user(ctx.source,ctx.userId)
    if row.ownerId~=ctx.userId then M.fail('FORBIDDEN','Somente o proprietário pode executar esta operação.')end
    if forFurniture then M.near(ctx.source,row,ICMConfig.FurnitureAccessRadius or 80)end
    if not forFurniture then
        local owned=0;for _,entry in ipairs(M.state().mansions)do if entry.ownerId==ctx.userId then owned=owned+1 end end
        if owned>1 then M.near(ctx.source,row,ICMConfig.ManagementNearestDistance or 35)end
    end
end
function M.pending(id)
    local out={}
    for key,op in pairs(M.state().operations)do
        if op.mansionId==id and op.phase~='done'and op.phase~='cancelled'then out[#out+1]={id=key,kind=op.kind,phase=op.phase,createdAt=op.createdAt}end
    end
    return out
end
function M.noPending(id)
    if #M.pending(id)>0 then M.fail('RECONCILIATION_REQUIRED','Existe uma operação pendente nesta mansão. Reconcilie o registro antes de repetir efeitos.')end
end
function M.lock(fn)
    if M.locked then M.fail('BUSY','Outra operação está em andamento. Atualize antes de repetir.')end
    M.locked=true;local results=table.pack(pcall(fn));M.locked=false
    if not results[1]then error(results[2],0)end
    return table.unpack(results,2,results.n)
end
function M.token(prefix)
    M.serial=(M.serial or 0)+1
    return(prefix or'op')..':'..os.time()..':'..GetGameTimer()..':'..M.serial..':'..math.random(1,2147483647)
end
function M.operation(state,kind,ctx,mansionId,detail)
    local id=M.token(kind);state.operations[id]={id=id,kind=kind,actorId=ctx.userId,mansionId=mansionId,phase='prepared',createdAt=os.time(),detail=M.copy(detail or{})}
    M.Store.save(state);return id
end
function M.phase(state,id,phase)state.operations[id].phase=phase;state.operations[id].updatedAt=os.time();M.Store.save(state)end
function M.complete(state,id)
    -- Full recovery snapshots are needed only while an effect is unresolved.
    -- Keep operation metadata, amounts and targets after completion without
    -- retaining a quadratic copy of every historical furniture collection.
    local committed=M.copy(state);local op=committed.operations[id]
    op.phase='done';op.updatedAt=os.time()
    if op.detail then op.detail.before=nil;op.detail.after=nil;op.detail.integrations=nil end
    M.Store.save(committed)
end
function M.external(key,name,...)
    M.active();local resource=(ICMConfig.Resources or{})[key]
    if M.permissionPublishFailed then M.fail('PERMISSION_STATE_UNAVAILABLE','O estado de acesso não pôde ser publicado.')end
    if not resource or GetResourceState(resource)~='started'then M.fail('RESOURCE_UNAVAILABLE','Integração indisponível: '..key)end
    local args=table.pack(...)
    local result=table.pack(pcall(function()return exports[resource][name](nil,table.unpack(args,1,args.n))end))
    if not result[1]then M.fail('EXPORT_FAILED','A integração falhou; confira o estado antes de repetir.')end
    return table.unpack(result,2,result.n)
end
function M.effect(key,name,...)
    local ok=M.external(key,name,...)
    if ok~=true then M.fail('OPERATION_FAILED','A integração recusou ou não confirmou a alteração.')end
    return true
end
function M.group(id,name,adding)return M.effect('Vrp',adding and'addManagedUserGroup'or'removeManagedUserGroup',id,name)end
function M.notify(sourceId,message,kind)
    if sourceId then TriggerClientEvent('Notify',sourceId,kind or'aviso',message,5000)end
end
function M.identity(id)
    local v=M.vRP.getUserIdentity(id)
    if not v then M.fail('INVALID_USER','Passaporte não encontrado.')end
    local name=tostring(v.nome or v.name or'')..' '..tostring(v.sobrenome or v.firstname or'')
    return name:match('^%s*(.-)%s*$')~=''and name or('Passaporte #'..id)
end
function M.residents(row)
    local out={}
    if row.ownerId then local ok,name=pcall(M.identity,row.ownerId);out[#out+1]={userId=row.ownerId,id=row.ownerId,name=ok and name or('Passaporte #'..row.ownerId),owner=true}end
    for _,id in ipairs(row.members or{})do local ok,name=pcall(M.identity,id);out[#out+1]={userId=id,id=id,name=ok and name or('Passaporte #'..id),owner=false}end
    return out
end
function M.publicMansions()
    local rows={};for _,m in ipairs(M.state().mansions)do rows[#rows+1]={id=m.id,name=m.name,price=m.price,iptuValue=m.iptuValue,iptuPaidUntil=m.iptuPaidUntil,maxResidents=m.maxResidents,purchaseCoords=M.copy(m.purchaseCoords),occupied=m.ownerId~=nil}end;return rows
end
function M.publicFurniture()
    local rows={};for _,m in ipairs(M.state().mansions)do for _,f in ipairs(m.furniture or{})do rows[#rows+1]={id=f.id,mansionId=m.id,model=f.model,x=f.x,y=f.y,z=f.z,heading=f.heading}end end;return rows
end
function M.publishPermissions()
    if GlobalState then
        local permissions={}
        for _,row in ipairs(M.state().mansions)do permissions[row.permission]=true end
        for _,op in pairs(M.state().operations)do
            if op.phase~='done'and op.phase~='cancelled'then
                for _,field in ipairs({'before','after'})do local row=op.detail and op.detail[field];if row and row.permission then permissions[row.permission]=true end end
            end
        end
        local ok=pcall(function()GlobalState.ic_mansions_permissions=permissions end)
        M.permissionPublishFailed=not ok
        if not ok then pcall(function()GlobalState.ic_mansions_permissions=nil end)end
        return ok
    end
    return true
end
function M.broadcast(target)
    M.publishPermissions()
    TriggerClientEvent('ic_mansions:sync',target or-1,M.publicMansions())
    TriggerClientEvent('ic_mansions:furnitureSync',target or-1,M.publicFurniture())
end
function M.register(name,mutating,fn)assert(not M.methods[name]);M.methods[name]={mutating=mutating,fn=fn}end
function M.error(value)
    if type(value)=='table'and value.icMansions then return{code=value.code,message=value.message}end
    return{code='INTERNAL_ERROR',message='Operação não confirmada. Confira o estado antes de repetir.'}
end
