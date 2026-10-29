-- Explicit adapters for owning formats present in this base. Unknown formats fail closed.
local I=ICAdmin
local O={};I.Ownership=O
local function decoded(raw,label)
    local ok,value=pcall(json.decode,raw or '{}')
    if not ok or type(value)~='table' then I.fail('UNHANDLED_RELATION','Formato não reconhecido: '..label) end
    return value
end
local function guard(statements,tableName,column,key,old)
    statements[#statements+1]={query='INSERT INTO ic_admin_schema(version) SELECT 1 WHERE NOT EXISTS (SELECT 1 FROM '..tableName..' WHERE '..column..'=? AND BINARY dvalue=BINARY ? FOR UPDATE)',values={key,old}}
end
local function mentions(value,id)
    if type(value)~='table' then return tostring(value)==tostring(id) or (type(value)=='string' and tonumber(value)==id) end
    for key,entry in pairs(value) do
        if tostring(key)==tostring(id) or tonumber(key)==id or ((key=='user_id' or key=='userId' or key=='owner' or key=='startedBy' or key=='passport') and tostring(entry)==tostring(id)) then return true end
        if type(entry)=='table' and mentions(entry,id) then return true end
    end
    return false
end
function O.prepare(actual,id,newId,wiping)
    local statements,tables,summary={}, {},{}
    for _,resource in ipairs({'inventory','m_orgs_v2','m_craft','residences','m_homes','mirtin_homes'}) do
        local state=GetResourceState(resource)
        if state=='starting' or state=='stopping' then I.fail('PREPARATION_REQUIRED','Aguarde a estabilização do recurso '..resource..'.') end
    end
    local function touched(name,count) tables[name]=true;summary[#summary+1]={table=name,count=count} end
    if actual.mirtin_organization_members then
        for _,row in ipairs(I.Store.query('SELECT id,member_data FROM mirtin_organization_members WHERE user_id=?',{id})) do
            if row.member_data and row.member_data~='' then
                local data=decoded(row.member_data,'mirtin_organization_members.member_data');local changed=false
                for _,field in ipairs({'user_id','userId','passport'}) do
                    if tonumber(data[field])==id then data[field]=type(data[field])=='string' and tostring(newId or id) or (newId or id);changed=true end
                end
                if not wiping and (tonumber(data.id)==id or mentions(data,id)) then I.fail('UNHANDLED_RELATION','member_data contém vínculo sem adaptação explícita.') end
                if not wiping and changed then
                    statements[#statements+1]={query='INSERT INTO ic_admin_schema(version) SELECT 1 WHERE NOT EXISTS (SELECT 1 FROM mirtin_organization_members WHERE id=? AND user_id=? AND BINARY member_data=BINARY ? FOR UPDATE)',values={row.id,id,row.member_data}}
                    statements[#statements+1]={query='UPDATE mirtin_organization_members SET member_data=? WHERE id=?',values={json.encode(data),row.id}}
                    touched('mirtin_organization_members',1)
                end
            end
        end
    end
    if actual.mirtin_users_homes then
        for _,row in ipairs(I.Store.query('SELECT id,proprietario,moradores FROM mirtin_users_homes')) do
            local residents=decoded(row.moradores,'mirtin_users_homes.moradores')
            -- Supported contracts: ID-keyed membership maps and arrays of numeric passports.
            local changed=false;local array=#residents>0
            if array then
                for index=#residents,1,-1 do
                    local value=residents[index]
                    if not tonumber(value) or tonumber(value)%1~=0 or tonumber(value)<1 then I.fail('UNHANDLED_RELATION','Moradores em formato não reconhecido.') end
                    if tonumber(value)==id then if wiping then table.remove(residents,index) else residents[index]=type(value)=='string' and tostring(newId) or newId end;changed=true end
                end
            else
                for key,value in pairs(residents) do
                    if not tonumber(key) or (type(value)~='boolean' and (type(value)~='string' or tonumber(value))) then I.fail('UNHANDLED_RELATION','Mapa de moradores em formato não reconhecido.') end
                end
                local key=residents[tostring(id)]~=nil and tostring(id) or (residents[id]~=nil and id)
                if key then
                    if not wiping and (residents[newId]~=nil or residents[tostring(newId)]~=nil) then I.fail('ID_IN_USE','Novo passaporte já possui vínculo de moradia.') end
                    if not wiping then residents[tostring(newId)]=residents[key] end;residents[key]=nil;changed=true
                end
            end
            if changed or tonumber(row.proprietario)==id then
                for _,resource in ipairs({'m_homes','mirtin_homes','residences'}) do
                    if GetResourceState(resource)=='started' then I.fail('PREPARATION_REQUIRED','Pause o recurso de casas antes da manutenção de seus vínculos.') end
                end
                statements[#statements+1]={query='INSERT INTO ic_admin_schema(version) SELECT 1 WHERE NOT EXISTS (SELECT 1 FROM mirtin_users_homes WHERE id=? AND proprietario=? AND BINARY moradores=BINARY ? FOR UPDATE)',values={row.id,row.proprietario,row.moradores}}
                if wiping and tonumber(row.proprietario)==id then statements[#statements+1]={query='DELETE FROM mirtin_users_homes WHERE id=?',values={row.id}}
                else statements[#statements+1]={query='UPDATE mirtin_users_homes SET moradores=?,proprietario=? WHERE id=?',values={json.encode(residents),tonumber(row.proprietario)==id and newId or row.proprietario,row.id}} end
                touched('mirtin_users_homes',1)
            end
        end
    end
    if actual.trafico then
        for _,row in ipairs(I.Store.query('SELECT user_id FROM trafico')) do
            if not tostring(row.user_id):match('^%d+$') then I.fail('UNHANDLED_RELATION','trafico.user_id exige passaporte decimal simples.') end
            if tonumber(row.user_id)==id then
                statements[#statements+1]=wiping and {query='DELETE FROM trafico WHERE user_id=?',values={row.user_id}} or {query='UPDATE trafico SET user_id=? WHERE user_id=?',values={tostring(newId),row.user_id}}
                touched('trafico',1)
            end
        end
    end
    if actual.vrp_srv_data then
        for _,row in ipairs(I.Store.query('SELECT dkey,dvalue FROM vrp_srv_data')) do
            local key,updated,destination=row.dkey,nil,nil
            local owner=key:match('^chest:u(%d+)veh_') or key:match('^wardrobe:(%d+)$')
            if owner and tonumber(owner)==id then
                destination=key:match('^chest:u') and key:gsub('^chest:u'..id..'veh_','chest:u'..(newId or id)..'veh_') or ('wardrobe:'..(newId or id))
                if not wiping and I.Store.query('SELECT dkey FROM vrp_srv_data WHERE dkey=?',{destination})[1] then I.fail('ID_IN_USE','Destino já possui armazenamento pessoal.') end
                guard(statements,'vrp_srv_data','dkey',key,row.dvalue)
                statements[#statements+1]=wiping and {query='DELETE FROM vrp_srv_data WHERE dkey=?',values={key}} or {query='UPDATE vrp_srv_data SET dkey=? WHERE dkey=?',values={destination,key}}
                touched('vrp_srv_data',1)
            elseif key=='m_craft:ranking:users' then
                local ranking=decoded(row.dvalue,key);local entry=ranking[tostring(id)] or ranking[id]
                if entry~=nil then
                    if not wiping and ranking[tostring(newId)]~=nil then I.fail('ID_IN_USE','Destino já possui ranking de craft.') end
                    if not wiping then ranking[tostring(newId)]=entry end;ranking[tostring(id)]=nil;ranking[id]=nil;updated=ranking
                    if GetResourceState('m_craft')=='started' then I.fail('PREPARATION_REQUIRED','Pause m_craft para atualizar seu ranking persistente.') end
                end
            elseif key=='m_craft:active_jobs:v2' then
                if mentions(decoded(row.dvalue,key),id) then I.fail('ACTIVE_WORKFLOW','Conclua os trabalhos de craft deste passaporte.') end
            elseif not owner and not key:match('^orgChest:') and not key:match('^orgblacklist:') and not key:match('^WAREHOUSES:') and not key:match('^chest:') and not key:match('^m_craft:storage:') then
                local ok,value=pcall(json.decode,row.dvalue or '')
                if not ok or mentions(value,id) or (newId and mentions(value,newId)) or key:match('%f[%d]'..id..'%f[%D]') then I.fail('UNHANDLED_RELATION','Namespace compartilhado sem adaptador em vrp_srv_data.') end
            end
            if updated then
                guard(statements,'vrp_srv_data','dkey',key,row.dvalue)
                statements[#statements+1]={query='UPDATE vrp_srv_data SET dvalue=? WHERE dkey=?',values={json.encode(updated),key}};touched('vrp_srv_data',1)
            end
        end
    end
    if next(tables) and GetResourceState('inventory')=='started' then
        if exports['inventory']:icAdminOwnershipReady()~=true then I.fail('PREPARATION_REQUIRED','Feche os baús e inventários compartilhados antes da manutenção.') end
    end
    return statements,tables,summary
end
function O.finished(id,newId)
    if GetResourceState('inventory')=='started' and exports['inventory']:icAdminOwnershipCommitted()~=true then I.fail('RECONCILE','Manutenção gravada; o cache do inventário exige conferência antes de continuar.') end
    if GetResourceState('m_orgs_v2')=='started' and exports['m_orgs_v2']:icAdminOwnershipCommitted(id,newId)~=true then I.fail('RECONCILE','Manutenção gravada; o cache de organizações exige conferência.') end
end
