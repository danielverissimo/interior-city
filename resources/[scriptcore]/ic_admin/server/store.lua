local I=ICAdmin
I.Store={}
function I.Store.query(sql,params) return MySQL.query.await(sql,params or {}) or {} end
function I.Store.update(sql,params) return MySQL.update.await(sql,params or {}) end
function I.Store.insert(sql,params) return MySQL.insert.await(sql,params or {}) end
function I.Store.transaction(statements) return MySQL.transaction.await(statements) end
function I.Store.get(key,default)
    local row=I.Store.query('SELECT payload,revision FROM ic_admin_documents WHERE doc_key=?',{key})[1]
    if not row then return I.copy(default or {}),0 end
    local ok,value=pcall(json.decode,row.payload)
    if not ok or type(value)~='table' then I.fail('CORRUPT_STATE','Configuração persistida inválida: '..key) end
    return value,tonumber(row.revision)
end
function I.Store.put(key,value,expected)
    local encoded=json.encode(value)
    if #encoded>4000000 then I.fail('STATE_TOO_LARGE','Configuração excede o limite.') end
    if expected==nil then
        return I.Store.update('INSERT INTO ic_admin_documents(doc_key,payload,revision) VALUES(?,?,1) ON DUPLICATE KEY UPDATE payload=VALUES(payload),revision=revision+1',{key,encoded})>0
    elseif expected==0 then
        return I.Store.update('INSERT IGNORE INTO ic_admin_documents(doc_key,payload,revision) VALUES(?,?,1)',{key,encoded})==1
    end
    return I.Store.update('UPDATE ic_admin_documents SET payload=?,revision=revision+1 WHERE doc_key=? AND revision=?',{encoded,key,expected})==1
end
function I.subject(userId)
    local row=I.Store.query('SELECT subject_key FROM ic_admin_subjects WHERE user_id=?',{userId})[1]
    if row then return row.subject_key end
    local key=('ic:%d:%x:%x'):format(userId,os.time(),math.random(1,0x7fffffff))
    I.Store.update('INSERT IGNORE INTO ic_admin_subjects(subject_key,user_id) VALUES(?,?)',{key,userId})
    row=I.Store.query('SELECT subject_key FROM ic_admin_subjects WHERE user_id=?',{userId})[1]
    if not row then I.fail('STORAGE_ERROR','Não foi possível vincular o histórico.') end
    return row.subject_key
end
