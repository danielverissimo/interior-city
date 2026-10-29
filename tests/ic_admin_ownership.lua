-- Actual ownership adapters with deterministic JSON/SQL boundaries; no live data.
local root=arg[1] or '.'
local values={members={['42']=true,['7']=true},empty={},ranking={['42']=8,['7']=4},unknown={owner=42}}
local encoded
local function copy(t)local o={};for k,v in pairs(t)do o[k]=type(v)=='table' and copy(v)or v end;return o end
json={decode=function(raw)if not values[raw]then error('invalid')end;return copy(values[raw])end,
encode=function(value)encoded=value;return 'encoded'end}
local homes={{id=5,proprietario=7,moradores='members'}}
local srv={{dkey='chest:u42veh_sultan',dvalue='empty'},{dkey='orgChest:police',dvalue='empty'}}
local queries={}
ICAdmin={Store={},Ownership={}}
local I=ICAdmin
I.fail=function(code,message)error({code=code,message=message},0)end
I.Store.query=function(sql,params)
    queries[#queries+1]={sql,params}
    if sql=='SELECT id,proprietario,moradores FROM mirtin_users_homes'then return homes end
    if sql=='SELECT dkey,dvalue FROM vrp_srv_data'then return srv end
    if sql=='SELECT user_id FROM trafico'then return {{user_id='42'},{user_id='7'}}end
    return {}
end
GetResourceState=function()return 'missing'end
dofile(root..'/resources/[scriptcore]/ic_admin/server/ownership.lua')
local statements,tables=I.Ownership.prepare({mirtin_users_homes=true,vrp_srv_data=true,trafico=true},42,99,false)
assert(tables.mirtin_users_homes and tables.vrp_srv_data and tables.trafico)
assert(encoded['42']==nil and encoded['99']==true and encoded['7']==true,'Resident membership not preserved')
local renamed,guarded=false,false
for _,row in ipairs(statements)do
    assert(not row.query:find('REPLACE',1,true),'Never rewrite serialized data by substring')
    if row.query:find('SET dkey',1,true)then renamed=row.values[1]=='chest:u99veh_sultan' and row.values[2]=='chest:u42veh_sultan'end
    if row.query:find('FOR UPDATE',1,true)then guarded=true end
end
assert(renamed and guarded,'Serialized state must be guarded in same transaction')
srv={{dkey='unknown',dvalue='unknown'}}
local ok,err=pcall(I.Ownership.prepare,{vrp_srv_data=true},42,99,false)
assert(not ok and err.code=='UNHANDLED_RELATION','Unknown embedded ownership must block')
srv={{dkey='m_craft:ranking:users',dvalue='ranking'}}
local rows=I.Ownership.prepare({vrp_srv_data=true},42,nil,true)
assert(#rows==2 and encoded['42']==nil and encoded['7']==4,'Wipe must preserve unrelated ranking entries')
GetResourceState=function(resource)return resource=='m_craft' and 'started' or 'missing'end
ok,err=pcall(I.Ownership.prepare,{vrp_srv_data=true},42,99,false)
assert(not ok and err.code=='PREPARATION_REQUIRED','Live opaque cache writer must not overwrite transaction')
print('IC Admin ownership adapters: residents, scalar IDs, trunk names, ranking, unknown formats and writer cache guards passed')
