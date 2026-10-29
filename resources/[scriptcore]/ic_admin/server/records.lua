local I=ICAdmin
local R={}
I.Records=R
local tables={calls='ic_admin_calls',ratings='ic_admin_ratings',vip_assignments='ic_admin_vip_assignments'}
local function name(kind) return assert(tables[kind],'Invalid record domain') end
local function decode(row)
    if not row then return nil end
    local ok,value=pcall(json.decode,row.payload)
    if not ok or type(value)~='table' then I.fail('CORRUPT_STATE','Registro administrativo inválido.') end
    value.id=value.id or tonumber(row.id) or row.id
    return value,tonumber(row.revision)
end
function R.get(kind,id)
    return decode(I.Store.query('SELECT id,payload,revision FROM '..name(kind)..' WHERE id=?',{id})[1])
end
function R.byIds(kind,ids)
    assert(#ids<=100);local values={}
    if #ids==0 then return values end
    local marks={};for _ in ipairs(ids) do marks[#marks+1]='?' end
    for _,row in ipairs(I.Store.query('SELECT id,payload,revision FROM '..name(kind)..' WHERE id IN ('..table.concat(marks,',')..')',ids)) do values[tostring(row.id)]=decode(row) end
    return values
end
-- Conditions and order are internal SQL fragments. Never pass NUI strings here.
function R.list(kind,where,params,page,limit)
    page=page or 1;limit=limit or 100
    assert(page>=1 and page%1==0 and limit>=1 and limit<=100)
    local values=I.copy(params or {})
    local clause=where and (' WHERE '..where) or ''
    local total=I.Store.query('SELECT COUNT(*) AS total FROM '..name(kind)..clause,values)[1]
    values[#values+1]=limit;values[#values+1]=(page-1)*limit
    local rows=I.Store.query('SELECT id,payload,revision FROM '..name(kind)..clause..' ORDER BY created_at DESC,id DESC LIMIT ? OFFSET ?',values)
    local entries={};for _,row in ipairs(rows) do entries[#entries+1]=decode(row) end
    return entries,tonumber(total and total.total) or 0
end
function R.metadata(kind,row)
    if kind=='calls' then return {row.requesterId,row.requesterSubject or '',row.acceptedBy or 0,row.acceptedSubject or '',row.state,row.department,row.createdAt or 0,0} end
    if kind=='ratings' then return {row.requesterId or 0,row.requesterSubject or '',row.staffId or 0,row.staffSubject or '', 'rated','staff',row.createdAt or 0,0} end
    return {row.userId,row.subjectKey or '',row.actorId or 0,'',row.state,row.group,row.assignedAt or 0,row.expiresAt or 0}
end
function R.statement(kind,row,revision)
    local values=R.metadata(kind,row);values[#values+1]=json.encode(row)
    values[#values+1]=row.id;values[#values+1]=revision
    return {query='UPDATE '..name(kind)..' SET owner_id=?,subject_key=?,actor_id=?,actor_subject=?,state=?,department=?,created_at=?,expires_at=?,payload=?,revision=revision+1 WHERE id=? AND revision=?',values=values}
end
function R.save(kind,row,revision)
    local encoded=json.encode(row)
    if #encoded>1000000 then I.fail('STATE_TOO_LARGE','Registro excede o limite individual.') end
    if revision==0 then
        local values=R.metadata(kind,row);values[#values+1]=encoded
        local fields='owner_id,subject_key,actor_id,actor_subject,state,department,created_at,expires_at,payload'
        local markers='?,?,?,?,?,?,?,?,?'
        if row.id then fields=fields..',id';markers=markers..',?';values[#values+1]=row.id end
        local inserted=I.Store.insert('INSERT INTO '..name(kind)..' ('..fields..') VALUES ('..markers..')',values)
        if not inserted then I.fail('CONFLICT','Registro não foi confirmado.') end
        row.id=row.id or inserted;return row,1
    end
    local query=R.statement(kind,row,revision)
    if I.Store.update(query.query,query.values)~=1 then I.fail('CONFLICT','Registro alterado. Atualize antes de continuar.') end
    return row,revision+1
end
function R.guarded(kind,row,revision,statements)
    -- Duplicate PK deliberately aborts the whole transaction on a stale/missing row.
    statements[#statements+1]={query='INSERT INTO ic_admin_schema(version) SELECT 1 WHERE NOT EXISTS (SELECT 1 FROM '..name(kind)..' WHERE id=? AND revision=? FOR UPDATE)',values={row.id,revision}}
    statements[#statements+1]=R.statement(kind,row,revision)
end
function R.each(kind,where,params,callback)
    local cursor=nil
    while true do
        local values=I.copy(params or {});local clause=where and ('('..where..')') or '1=1'
        if cursor then clause=clause..' AND id>?';values[#values+1]=cursor end
        local rows=I.Store.query('SELECT id,payload,revision FROM '..name(kind)..' WHERE '..clause..' ORDER BY id ASC LIMIT 100',values)
        for _,row in ipairs(rows) do local value,rev=decode(row);callback(value,rev);cursor=row.id end
        if #rows<100 then break end
    end
end
