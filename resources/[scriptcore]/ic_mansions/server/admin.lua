local M=ICM
local function slug(value)
    local replacements={['Á']='a',['À']='a',['Â']='a',['Ã']='a',['á']='a',['à']='a',['â']='a',['ã']='a',['É']='e',['Ê']='e',['é']='e',['ê']='e',['Í']='i',['í']='i',['Ó']='o',['Ô']='o',['Õ']='o',['ó']='o',['ô']='o',['õ']='o',['Ú']='u',['ú']='u',['Ç']='c',['ç']='c'}
    for from,to in pairs(replacements)do value=value:gsub(from,to)end
    return value:lower():gsub('[^a-z0-9]','')
end
local function normalize(data,old)
    M.table(data)
    local group=M.text(data.group);local permission='perm.'..slug(group)
    if permission=='perm.'then M.fail('INVALID_INPUT','Cargo da mansão inválido.')end
    local row={id=old and old.id or M.token('mansao'):gsub(':','_'),name=M.text(data.name),group=group,permission=permission,
        price=M.integer(data.price,0,1000000000000),iptuValue=M.integer(data.iptuValue,0,1000000000000),
        voucher=M.text(data.voucher),maxResidents=M.integer(data.maxResidents,1,1000),purchaseCoords=M.coords(data.purchaseCoords),
        chest={enabled=false},garage={enabled=false},doors={},members={},furniture={},createdAt=old and old.createdAt or os.time(),updatedAt=os.time()}
    if not(ICMConfig.AllowedVouchers or{})[row.voucher]then M.fail('INVALID_INPUT','Vale de mansão não reconhecido.')end
    if group=='developer'or group=='dono'or group=='admin'or group=='user'then M.fail('INVALID_INPUT','Escolha um cargo exclusivo da mansão.')end
    local chest=M.table(data.chest or{})
    row.chest={enabled=chest.enabled==true,name=old and old.chest and old.chest.name or('Mansao_'..row.id)}
    if row.chest.enabled then row.chest.weight=M.number(chest.weight,0,100000000);row.chest.coords=M.coords(chest.coords)end
    if not row.chest.enabled then
        row.chest.weight=old and old.chest and old.chest.weight
        row.chest.coords=old and old.chest and M.copy(old.chest.coords)
        local ok,value=pcall(M.coords,chest.coords);if ok then row.chest.coords=value end
        if type(chest.weight)=='number'and chest.weight>=0 and chest.weight<=100000000 then row.chest.weight=chest.weight end
    end
    local garage=M.table(data.garage or{})
    row.garage={enabled=garage.enabled==true,id=old and old.garage and old.garage.id or('Mansao_'..row.id)}
    if row.garage.enabled then
        row.garage.type=M.text(garage.type);row.garage.blipDistance=M.number(garage.blipDistance,0.01,1000)
        row.garage.coords=M.coords(garage.coords);row.garage.spawnCoords={}
        if #M.table(garage.spawnCoords)<1 or #garage.spawnCoords>100 then M.fail('INVALID_INPUT','Informe entre uma e cem vagas.')end
        for _,c in ipairs(garage.spawnCoords)do row.garage.spawnCoords[#row.garage.spawnCoords+1]=M.coords(c,true)end
    end
    if not row.garage.enabled then
        for _,field in ipairs({'type','blipDistance','coords','spawnCoords'})do row.garage[field]=old and old.garage and M.copy(old.garage[field])end
        if type(garage.type)=='string'and garage.type~=''then row.garage.type=garage.type end
        if type(garage.blipDistance)=='number'and garage.blipDistance>0 and garage.blipDistance<=1000 then row.garage.blipDistance=garage.blipDistance end
        local ok,value=pcall(M.coords,garage.coords);if ok then row.garage.coords=value end
        if type(garage.spawnCoords)=='table'and#garage.spawnCoords<=100 then
            local points={};local valid=true
            for _,coord in ipairs(garage.spawnCoords)do local good,p=pcall(M.coords,coord,true);if not good then valid=false;break end;points[#points+1]=p end
            if valid then row.garage.spawnCoords=points end
        end
    end
    if #M.table(data.doors or{})>256 then M.fail('INVALID_INPUT','Quantidade de portas excedida.')end
    for _,d in ipairs(data.doors or{})do
        local c=M.coords(d);c.hash=M.integer(d.hash,-2147483648,4294967295);c.dist=M.number(d.dist or 5,0.1,100)
        c.text=d.text~=false;c.isGate=d.isGate==true;c.lock=true;row.doors[#row.doors+1]=c
    end
    if old then
        for _,field in ipairs({'ownerId','members','furniture','purchasedAt','iptuPaidUntil','lastIptuPaidAt','createdAt'})do row[field]=M.copy(old[field])end
        row.members=row.members or{};row.furniture=row.furniture or{}
        if (row.ownerId and 1 or 0)+#row.members>row.maxResidents then M.fail('RESIDENT_LIMIT','O limite não pode ser menor que a ocupação atual.')end
    end
    return row
end
M.normalizeMansion=normalize
local function find(rows,key,value)for _,row in ipairs(rows or{})do if row[key]==value then return M.copy(row)end end end
local function verifyGarage(expected,id)
    -- The existing garage exporter can return true even when its native file
    -- write failed. Verify the actual persisted record before committing ours.
    local raw=LoadResourceFile(ICMConfig.Resources.Garage,'shared-side/garages.json')
    local ok,rows=pcall(json.decode,raw or'')
    if not ok or type(rows)~='table'then M.fail('PERSISTENCE_UNVERIFIED','Não foi possível conferir o arquivo de garagens.')end
    local stored=find(rows,'id',id)
    if not M.equal(stored,expected)then M.fail('PERSISTENCE_UNVERIFIED','O recurso não persistiu a configuração esperada da garagem.')end
end
local function snapshots(old,row)
    local groups=M.external('Vrp','getManagedGroups')
    local chests=M.external('Inventory','getChests')
    local garages=M.external('Garage','getGarages')
    local currentGroup=find(groups,'name',old and old.group or row.group)
    if not old and currentGroup then M.fail('CONFLICT','O cargo escolhido já pertence a outro cadastro.')end
    if old and old.group~=row.group and find(groups,'name',row.group)then M.fail('CONFLICT','O novo cargo já existe.')end
    local chestName=row.chest.name or old and old.chest.name
    local garageId=row.garage.id or old and old.garage.id
    if row.garage.enabled then
        local types=M.external('Garage','getGarageTypes')
        if not types[row.garage.type]then M.fail('INVALID_INPUT','Tipo de garagem não encontrado.')end
    end
    local assignments
    if currentGroup then assignments=M.external('Vrp','getManagedGroupAssignments',currentGroup.name)
    else assignments={group=row.group,assignments={},count=0}end
    M.table(assignments);M.table(assignments.assignments)
    if assignments.group~=(currentGroup and currentGroup.name or row.group)then M.fail('INVALID_RESPONSE','Referências do cargo não puderam ser verificadas.')end
    return{group=currentGroup,groupAssignments=assignments,chest=find(chests,'name',chestName),garage=find(garages,'id',garageId),
        doors=M.external('Doors','getMansionDoors',row.id)or{},chestName=chestName,garageId=garageId}
end
local function ensureChest(row,snapshot)
    if row.chest.enabled then
        if snapshot.chest then M.effect('Inventory','updateChest',row.chest.name,row.chest.weight,row.chest.coords,row.permission)
        else M.effect('Inventory','addChest',row.chest.name,row.chest.weight,row.permission,row.chest.coords)end
    elseif snapshot.chest then M.effect('Inventory','removeChest',snapshot.chest.name)end
end
local function ensureGarage(row,snapshot)
    if row.garage.enabled then
        local config=M.copy(row.garage);config.enabled=nil;config.permiss=row.permission
        if snapshot.garage then M.effect('Garage','updateGarage',snapshot.garage.id,config)else M.effect('Garage','addGarage',config)end
        verifyGarage(config,config.id)
    elseif snapshot.garage then M.effect('Garage','removeGarage',snapshot.garage.id);verifyGarage(nil,snapshot.garage.id)end
end
local function restore(row,snapshot)
    local failures=0
    local membershipsUncertain=false
    local function attempt(fn)local ok=pcall(fn);if not ok then failures=failures+1 end end
    attempt(function()M.effect('Doors','replaceMansionDoors',row.id,row.permission,snapshot.doors)end)
    attempt(function()
        local current=find(M.external('Garage','getGarages'),'id',snapshot.garageId)
        if snapshot.garage then M.effect('Garage',current and'updateGarage'or'addGarage',table.unpack(current and{snapshot.garageId,snapshot.garage}or{snapshot.garage}))
        elseif current then M.effect('Garage','removeGarage',snapshot.garageId)end
        verifyGarage(snapshot.garage,snapshot.garageId)
    end)
    attempt(function()
        local current=find(M.external('Inventory','getChests'),'name',snapshot.chestName)
        if snapshot.chest then
            local c=snapshot.chest
            if current then M.effect('Inventory','updateChest',c.name,c.weight,c.coords,c.permission)else M.effect('Inventory','addChest',c.name,c.weight,c.permission,c.coords)end
        elseif current then M.effect('Inventory','removeChest',snapshot.chestName)end
    end)
    attempt(function()
        local current=find(M.external('Vrp','getManagedGroups'),'name',row.group)
        if snapshot.group then M.effect('Vrp','saveManagedGroup',current and row.group or'',snapshot.group)
        elseif current then membershipsUncertain=true;M.effect('Vrp','removeManagedGroup',row.group)end
    end)
    -- Removing a newly-created group can also revoke a concurrent assignment
    -- outside this resource. Public group definitions cannot prove restoration.
    return failures==0 and not membershipsUncertain
end
local function adminContext(ctx)
    if GetInvokingResource()~='ic_config'then M.fail('FORBIDDEN','Export administrativo reservado ao IC Config.')end
    return M.admin(ctx)
end
function M.adminList(ctx)
    adminContext(ctx);local rows={}
    for _,row in ipairs(M.state().mansions)do local v=M.copy(row);v.residents=M.residents(row);v.occupiedCount=#v.residents;v.pendingOperations=M.pending(row.id);rows[#rows+1]=v end
    return{version=1,mansions=rows,allowedVouchers=M.copy(ICMConfig.AllowedVouchers or{})}
end
function M.adminSave(originalId,data,ctx)
    adminContext(ctx)
    return M.lock(function()
        local old,index
        if originalId and originalId~=''then old,index=M.find(originalId);M.noPending(old.id)end
        local row=normalize(data,old)
        for _,entry in ipairs(M.state().mansions)do if entry.id~=row.id and(entry.group:lower()==row.group:lower()or entry.permission==row.permission)then M.fail('CONFLICT','Já existe uma mansão com este cargo ou permissão.')end end
        local snapshot=snapshots(old,row)
        local state=M.copy(M.state());local op=M.operation(state,'admin_save',ctx,row.id,{before=M.copy(old),after=M.copy(row),integrations=snapshot})
        M.phase(state,op,'applying')
        local ok,err=pcall(function()
            M.admin(ctx)
            M.effect('Vrp','saveManagedGroup',old and old.group or'',{name=row.group,config={title=row.group},permissions={row.permission}})
            ensureChest(row,snapshot);ensureGarage(row,snapshot)
            M.effect('Doors','replaceMansionDoors',row.id,row.permission,row.doors)
            M.admin(ctx)
            if index then state.mansions[index]=row else state.mansions[#state.mansions+1]=row end
            M.complete(state,op)
        end)
        if not ok then
            if M.Store.quarantined then error(err,0)end
            local restored=restore(row,snapshot)
            local previous=M.copy(M.state());previous.mansions=M.copy(M.state().mansions)
            -- Any failed final save has left the active slot before the commit.
            previous.operations[op]=M.copy(state.operations[op]);previous.operations[op].phase=restored and'cancelled'or'uncertain'
            pcall(M.Store.save,previous)
            if not restored then M.fail('RECONCILIATION_REQUIRED','Integrações da mansão podem estar parcialmente alteradas. Reconcilie a operação registrada.')end
            error(err,0)
        end
        M.broadcast();return true,old and'Mansão atualizada.'or'Mansão cadastrada.'
    end)
end
function M.adminRemove(id,ctx)
    adminContext(ctx)
    return M.lock(function()
        local row,index=M.find(id);M.noPending(id)
        if row.ownerId then M.fail('OCCUPIED','Esta mansão possui dono. Use a limpeza confirmada antes de excluí-la.')end
        local snapshot=snapshots(row,row);local state=M.copy(M.state())
        local op=M.operation(state,'admin_remove',ctx,id,{before=M.copy(row),integrations=snapshot});M.phase(state,op,'applying')
        local groupRemovalAttempted=false
        local ok,err=pcall(function()
            if snapshot.chest then M.effect('Inventory','removeChest',snapshot.chest.name)end
            if snapshot.garage then M.effect('Garage','removeGarage',snapshot.garage.id);verifyGarage(nil,snapshot.garage.id)end
            M.effect('Doors','removeMansionDoors',id)
            if snapshot.group then groupRemovalAttempted=true;M.effect('Vrp','removeManagedGroup',row.group)end
            M.admin(ctx);table.remove(state.mansions,index);M.complete(state,op)
        end)
        if not ok then
            if M.Store.quarantined then error(err,0)end
            local restored=restore(row,snapshot)and not groupRemovalAttempted
            local prior=M.copy(M.state());prior.operations[op]=M.copy(state.operations[op]);prior.operations[op].phase=restored and'cancelled'or'uncertain';pcall(M.Store.save,prior)
            if not restored then M.fail('RECONCILIATION_REQUIRED','A remoção não foi concluída. Reconcilie as integrações registradas.')end
            error(err,0)
        end
        M.broadcast();return true,'Mansão removida.'
    end)
end
