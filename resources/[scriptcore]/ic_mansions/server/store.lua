-- Two independently readable slots. A torn inactive-slot write never destroys
-- the current slot. No supplier runtime, network or automatic economic replay.
ICM = {methods={},sessions={},quotes={},placements={},locked=false}
local M=ICM
M.Store={generation=nil,slot=nil,state=nil}
local S=M.Store
local function copy(value)
    if type(value)~='table' then return value end
    local out={};for k,v in pairs(value)do out[k]=copy(v)end;return out
end
local function equal(a,b)
    if type(a)~=type(b)then return false end
    if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not equal(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end
    return true
end
local function fail(message)error({icMansions=true,code='STORAGE_ERROR',message=message},0)end
local function checksum(raw)
    local hash=2166136261
    for i=1,#raw do hash=((hash~raw:byte(i))*16777619)&0xffffffff end
    return('%08x'):format(hash)
end
local function valid(value)
    local base=type(value)=='table' and type(value.generation)=='number' and value.generation>=0
        and value.generation%1==0 and type(value.state)=='table' and value.state.version==1
        and type(value.state.mansions)=='table' and type(value.state.operations)=='table'
        and type(value.state.catalogPrices)=='table'
    if not base then return false end
    if value.payload==nil then return value.generation==0 end
    if type(value.payload)~='string'or value.checksum~=checksum(value.payload)then return false end
    local ok,payload=pcall(json.decode,value.payload)
    return ok and equal(payload,value.state)
end
function S.load()
    local candidates={}
    local files=ICMConfig.StateFiles or {'state-a.json','state-b.json'}
    for i,path in ipairs(files)do
        local raw=LoadResourceFile(GetCurrentResourceName(),path)
        if type(raw)=='string' and #raw<=16000000 then
            local ok,value=pcall(json.decode,raw)
            if ok and valid(value)then candidates[#candidates+1]={slot=i,value=value}end
        end
    end
    if #candidates==0 then fail('Os dois arquivos de estado estão ausentes ou inválidos. Não houve reinicialização dos dados.')end
    table.sort(candidates,function(a,b)return a.value.generation>b.value.generation end)
    if #candidates==2 and candidates[1].value.generation==candidates[2].value.generation
        and not equal(candidates[1].value.state,candidates[2].value.state)then
        fail('Arquivos de estado com a mesma revisão possuem conteúdos diferentes.')
    end
    S.generation=candidates[1].value.generation;S.slot=candidates[1].slot;S.state=copy(candidates[1].value.state)
    if M.publishPermissions then M.publishPermissions()end
    return copy(S.state)
end
function S.save(state)
    if S.generation==nil then S.load()end
    local nextGeneration=S.generation+1
    -- Compact only the clone being committed. A failed write leaves the caller's
    -- full pending snapshot intact for compensation and the old slot unchanged.
    local persisted=copy(state)
    local auditFields={amount=true,voucher=true,quantity=true,userId=true,userIds=true,furnitureId=true,itemId=true}
    for _,op in pairs(persisted.operations or{})do
        if op.phase=='done'or op.phase=='cancelled'then
            local detail={};for key,value in pairs(op.detail or{})do if auditFields[key]then detail[key]=value end end
            op.detail=detail
        end
    end
    local payload=json.encode(persisted)
    local envelope={generation=nextGeneration,state=persisted,payload=payload,checksum=checksum(payload)}
    if not valid(envelope)then fail('Estado incompatível; nenhuma gravação realizada.')end
    local ok,raw=pcall(json.encode,envelope)
    if not ok or #raw>16000000 then fail('Estado inválido ou acima do limite de armazenamento.')end
    local slot=S.slot==1 and 2 or 1
    local files=ICMConfig.StateFiles or {'state-a.json','state-b.json'}
    local wrote,result=pcall(SaveResourceFile,GetCurrentResourceName(),files[slot],raw,#raw)
    local readOk,readback=pcall(LoadResourceFile,GetCurrentResourceName(),files[slot])
    -- Exact readback is authoritative even on artifact builds that return no
    -- boolean (or an inaccurate false) after a successful file write.
    if not readOk or type(readback)~='string' then
        S.quarantined=true
        error({icMansions=true,code='STORAGE_UNCERTAIN',message='Não foi possível conferir a gravação. O estado foi bloqueado para evitar repetição de efeitos.'},0)
    end
    if readback~=raw then
        fail('A persistência não foi confirmada. Confira o estado antes de continuar.')
    end
    S.slot=slot;S.generation=nextGeneration;S.state=copy(persisted)
    if M.publishPermissions then M.publishPermissions()end
    return true
end
M.copy=copy;M.equal=equal
