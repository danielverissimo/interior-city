local root=arg[1]or'.'
local rows,encoded,counter={},{},0
local function copy(value)if type(value)~='table'then return value end;local o={};for k,v in pairs(value)do o[k]=copy(v)end;return o end
json={encode=function(value)counter=counter+1;local key=tostring(counter);encoded[key]=copy(value);return key end,decode=function(value)return copy(encoded[value])end}
ICAdmin={Store={},copy=copy,fail=function(code)error({code=code},0)end}
local I=ICAdmin;local lastQuery,lastParams
I.Store.query=function(sql,params)
    lastQuery,lastParams=sql,params
    if sql:find('COUNT',1,true)then return {{total=105}}end
    if sql:find('WHERE id=?',1,true)then local row=rows[params[1]];return row and {copy(row)}or{}end
    return {}
end
I.Store.insert=function(sql,params)local id=params[10]or 1;assert(not rows[id]);rows[id]={id=id,payload=params[9],revision=1};return id end
I.Store.update=function(sql,params)
    local row=rows[params[10]]
    if not row or row.revision~=params[11]then return 0 end
    row.payload=params[9];row.revision=row.revision+1;return 1
end
dofile(root..'/resources/[scriptcore]/ic_admin/server/records.lua')
local R=I.Records
local value={requesterId=42,requesterSubject='stable',state='open',department='staff',createdAt=1}
R.save('calls',value,0);assert(value.id==1)
local first,rev=R.get('calls',1);local stale=copy(first)
first.state='accepted';R.save('calls',first,rev)
stale.state='finished';local ok,err=pcall(R.save,'calls',stale,rev)
assert(not ok and err.code=='CONFLICT','Stale write must not win over accepted owner')
assert(R.get('calls',1).state=='accepted')
R.list('calls','subject_key=?',{'stable'},2,50)
assert(lastQuery:find('LIMIT ? OFFSET ?',1,true)and lastParams[2]==50 and lastParams[3]==50,'Pagination must reach SQL')
local statements={};R.guarded('calls',first,2,statements)
assert(#statements==2 and statements[1].query:find('FOR UPDATE',1,true))
assert(statements[2].query:find('AND revision=?',1,true),'Maintenance must retain row CAS')
print('IC Admin records: SQL pagination, stale write exclusion, stable IDs and transactional guards passed')
