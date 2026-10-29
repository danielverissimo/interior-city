-- Actual maintenance module, simulated DB and FiveM boundaries.
local root=arg[1] or '.'
local registry,handlers,exportsCalled={}, {}, {}
local online,blocked,engineDrift,unknownOwner,opaque,transactionOkay=false,false,false,false,false,true
local transactionCalls,statements,lockObserved=0,{},false
local documents={vip_assignments={assignments={{id='claim',userId=42,state='active'}}},calls={calls={{id=1,requesterId=42,acceptedBy=12,state='finished'}},ratings={{staffId=42}}}}
json={encode=function()return '{}'end}
GetResourceState=function()return 'missing'end
RegisterNetEvent=function()end
AddEventHandler=function(n,fn)handlers[n]=fn end
CancelEvent=function()end
exports=setmetatable({vrp={icAdminForgetUser=function(_,id)exportsCalled[#exportsCalled+1]=id;return true end,icAdminRefreshBanCaches=function()return true end}},{__call=function(_,name,fn)registry[name]=fn end})
ICAdmin={userLocks={},Config={},Store={},Adapter={},vRP={}}
local I=ICAdmin
I.fail=function(code,message)error({code=code,message=message},0)end
I.int=function(value,min,max)local n=tonumber(value);if not n or n%1~=0 or n<min or n>max then I.fail('INVALID','invalid')end;return n end
I.text=function(value,max,required)if type(value)~='string' or #value>max or required and value=='' then I.fail('INVALID','invalid')end;return value end
I.requireOwner=function(ctx)if ctx.role~='dono' and ctx.role~='developer' then I.fail('FORBIDDEN','owner')end end
I.target=function(id)return tonumber(id),online and 7 or nil end
I.subject=function()return 'original-person' end
I.withLock=function(_,fn)return fn()end
I.effect=function()lockObserved=I.userLocks[42]==true end
I.audit=function()end
I.register=function(name,descriptor)registry[name]=descriptor.handler end
I.vRP.getUserSource=function(id)if online and id==42 then return 7 end end
I.Adapter.banActive=function()return blocked end
local function copy(value)if type(value)~='table'then return value end;local out={};for k,v in pairs(value)do out[k]=copy(v)end;return out end
I.Store.get=function(key,default)return copy(documents[key] or default),1 end
I.Store.query=function(sql,params)
    if sql:find('information_schema.COLUMNS',1,true)then
        local rows={{TABLE_NAME='vrp_user_ids',COLUMN_NAME='user_id',DATA_TYPE='int'},{TABLE_NAME='vrp_users',COLUMN_NAME='id',DATA_TYPE='int'}}
        if unknownOwner then rows[#rows+1]={TABLE_NAME='houses',COLUMN_NAME='owner',DATA_TYPE='int'}end
        if opaque then rows[#rows+1]={TABLE_NAME='vrp_srv_data',COLUMN_NAME='dkey',DATA_TYPE='text'}end
        return rows
    elseif sql:find('information_schema.TABLES',1,true)then
        local rows={}
        for _,name in ipairs({'vrp_users','vrp_user_ids','ic_admin_subjects','ic_admin_discipline','ic_admin_documents','ic_admin_calls','ic_admin_ratings','ic_admin_vip_assignments','mirtin_bans','mirtin_bans_hwid','mirtin_bans_ip'})do rows[#rows+1]={TABLE_NAME=name,ENGINE=engineDrift and name=='vrp_user_ids' and 'MyISAM' or 'InnoDB'}end
        return rows
    elseif sql=='SELECT dkey,dvalue FROM vrp_srv_data' then return {{dkey='unknown',dvalue='opaque'}}
    elseif sql:find('COUNT',1,true)then return {{n=params and params[1]==99 and 0 or 1}}
    end
    return {}
end
I.Store.transaction=function(queries)transactionCalls=transactionCalls+1;statements=queries;return transactionOkay end
I.Records={
    each=function(kind,where,params,fn)
        assert(where:find('subject_key=?',1,true) and params[2]=='original-person','Maintenance must exclude previous owners of reused passports')
        local rows=kind=='vip_assignments' and documents.vip_assignments.assignments or (kind=='calls' and documents.calls.calls or documents.calls.ratings)
        for _,row in ipairs(rows)do fn(copy(row),1)end
    end,
    guarded=function(kind,row,rev,list)
        list[#list+1]={query='INSERT INTO ic_admin_schema SELECT 1 WHERE NOT EXISTS (SELECT 1 FROM ic_admin_'..kind..' WHERE revision=?)',values={rev}}
        list[#list+1]={query='UPDATE ic_admin_'..kind..' SET payload=?',values={'{}'}}
    end
}
dofile(root..'/resources/[scriptcore]/ic_admin/server/ownership.lua')
dofile(root..'/resources/[scriptcore]/ic_admin/server/maintenance.lua')
local ctx={source=1,userId=12,role='dono'}
local function run(mode,p)
    local ok,value=pcall(registry['maintenance.'..mode],ctx,p or {targetId=42,confirmId=42,newId=99,reason='Teste autorizado'})
    return ok,value
end
assert(not run('wipe',{targetId=42,confirmId=43,reason='Teste'}),'wrong confirmation accepted')
online=true;assert(not run('wipe'),'online target wiped');online=false
blocked=true;assert(not run('wipe'),'active ban wiped');blocked=false
unknownOwner=true;local ok,err=run('wipe');assert(not ok and err.code=='UNHANDLED_RELATION' and transactionCalls==0,'unhandled owner relation mutated');unknownOwner=false
opaque=true;assert(not run('wipe'),'opaque state was rewritten');opaque=false
engineDrift=true;assert(not run('wipe'),'nontransactional table allowed');engineDrift=false
transactionOkay=false;assert(not run('changeId'),'failed transaction succeeded');assert(I.userLocks[42]==nil and I.userLocks[99]==nil,'locks leaked after failure')
transactionOkay=true;assert(run('changeId'),'valid maintenance failed');assert(lockObserved,'writer exclusion missing')
local guarded,ratingUpdate,coreUpdate=false,false,false
for _,query in ipairs(statements)do
    if query.query:find('NOT EXISTS',1,true)then guarded=true end
    if query.query:find('UPDATE vrp_users',1,true)then coreUpdate=true end
    if query.query:find('ic_admin_ratings',1,true)then ratingUpdate=true end
end
assert(guarded and coreUpdate and ratingUpdate,'document revisions and ownership not part of same transaction')
assert(#exportsCalled==2 and exportsCalled[1]==42 and exportsCalled[2]==99,'passport caches not invalidated')
assert(I.userLocks[42]==nil and I.userLocks[99]==nil,'successful maintenance leaked locks')
print('IC Admin maintenance: online/ban/owner/opaque/engine refusals, rollback boundary, CAS, cache and locks passed')
