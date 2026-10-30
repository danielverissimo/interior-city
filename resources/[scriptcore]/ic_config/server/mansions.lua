-- Management is delegated only to Interior City's independent mansion service.
local S=ICConfigServer
local function provider()
    if ICConfig.Resources.Mansions~='ic_mansions' then
        S.fail('PROVIDER_NOT_SELECTED','Selecione o sistema próprio de mansões antes de usar esta área.')
    end
end
local function actor(ctx)return {source=ctx.source,userId=ctx.userId}end
S.register('getMansions',false,function(ctx)
    provider()
    local result=S.call(ctx,'Mansions','getMansions',actor(ctx))
    if type(result)~='table'or type(result.mansions)~='table' then
        S.fail('INVALID_RESPONSE','O sistema de mansões não disponibilizou os cadastros.')
    end
    return result
end)
local function apply(ctx,exportName,...)
    provider()
    local ok,message,code=S.call(ctx,'Mansions',exportName,...)
    if ok~=true then
        -- Only the own service is called; its public messages contain no raw exceptions.
        local publicCode=type(code)=='string'and #code<=64 and code:match('^[A-Z_]+$')and code or'MANSION_OPERATION_FAILED'
        S.fail(publicCode,type(message)=='string' and message or 'O sistema de mansões recusou a operação. Confira o estado antes de repetir.')
    end
    return {message=type(message)=='string' and message or 'Configuração de mansão salva.'}
end
S.register('saveMansion',true,function(ctx,p)
    return apply(ctx,'saveMansion',S.text(p.originalId,true),S.table(p.data),actor(ctx))
end)
S.register('deleteMansion',true,function(ctx,p)
    return apply(ctx,'removeMansion',S.text(p.id),actor(ctx))
end)
