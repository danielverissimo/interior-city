-- Explicit adapters reconstructed from the installed resources' public exports.
local S=ICConfigServer
local function read(name,key,exportName,transform)
    S.register(name,false,function(ctx)
        local value=S.call(ctx,key,exportName)
        if type(value)~='table' then S.fail('INVALID_RESPONSE','O recurso não forneceu uma configuração válida.') end
        value=S.copy(value)
        return transform and transform(value) or value
    end)
end
local function write(name,key,exportName,args)
    S.register(name,true,function(ctx,p)
        local values=table.pack(args(p,ctx))
        return S.mutate(ctx,key,exportName,table.unpack(values,1,values.n))
    end)
end
local function tableField(p,key) return S.table(p[key]) end
local function name(p) return S.text(p.name) end
local function id(p)
    if type(p.id)=='number' then return S.number(p.id,1,2147483647) end
    return S.text(p.id)
end
local function coordsField(p) S.coords(p.coords);return p.coords end
local function mutationTable(p)
    return S.table(p.data or p)
end

read('getChests','Inventory','getChests')
write('createChest','Inventory','addChest',function(p)return name(p),S.number(p.weight,0,100000000),S.text(p.permission,true),coordsField(p) end)
write('updateChest','Inventory','updateChest',function(p)return name(p),S.number(p.weight,0,100000000),coordsField(p),S.text(p.permission,true) end)
write('deleteChest','Inventory','removeChest',name)
read('getShops','Inventory','getShopConfigs')
write('createShop','Inventory','createShopConfig',function(p)return name(p),tableField(p,'data') end)
write('updateShop','Inventory','updateShopConfig',function(p)return S.text(p.originalName),name(p),tableField(p,'data') end)
write('deleteShop','Inventory','removeShopConfig',name)
S.register('getItemList',false,function()
    local catalog=S.vRP.getAllItens() or {}
    local out={}
    for index,item in pairs(catalog) do
        if type(item)=='table' then out[#out+1]={index=index,name=item.name or index,image=item.index or index,weight=tonumber(item.weight) or 0} end
    end
    table.sort(out,function(a,b)return tostring(a.index)<tostring(b.index) end)
    return out
end)

read('getGarages','Garage','getGarages')
read('getGarageTypes','Garage','getGarageTypes',function(types)
    local rows={}
    for key,data in pairs(types) do rows[#rows+1]={name=key,data=data} end
    table.sort(rows,function(a,b)return a.name<b.name end)
    return rows
end)
local function garage(p)
    S.text(p.id);S.text(p.type);S.coords(p.coords)
    local spawns=tableField(p,'spawnCoords')
    if #spawns<1 then S.fail('INVALID_INPUT','Informe ao menos uma vaga.') end
    for _,v in ipairs(spawns) do S.coords(v,true) end
    return p
end
write('createGarage','Garage','addGarage',garage)
write('updateGarage','Garage','updateGarage',function(p)return S.text(p.originalId),garage(p) end)
write('deleteGarage','Garage','removeGarage',id)
write('createGarageType','Garage','addGarageType',function(p)return name(p),tableField(p,'data') end)
write('updateGarageType','Garage','updateGarageType',function(p)return name(p),tableField(p,'data') end)
write('deleteGarageType','Garage','removeGarageType',name)

for _,spec in ipairs({
    {'ClothingShop','getClothingShops','Skinshop','getSkinShops','addSkinshop','updateSkinshop','removeSkinshop'},
    {'Barbershop','getBarbershops','Barbershop','getBarberShops','addBarberShop','updateBarberShop','removeBarberShop'},
    {'TattooShop','getTattooShops','Tattoo','getTattooShops','addTattooShop','updateTattooShop','removeTattooShop'}
}) do
    local item=spec
    read(item[2],item[3],item[4])
    write('create'..item[1],item[3],item[5],coordsField)
    write('update'..item[1],item[3],item[6],function(p)return id(p),coordsField(p) end)
    write('delete'..item[1],item[3],item[7],id)
end
read('getCloakrooms','Cloakroom','getCloakrooms')
write('saveCloakroom','Cloakroom','upsertCloakroom',function(p)
    local room=tableField(p,'room');S.text(room.name);S.coords(room.coords)
    return S.text(p.originalName,true),room
end)
write('deleteCloakroom','Cloakroom','removeCloakroom',name)
read('getMapMarkings','Snippets','getMapBlips')
local function mapMark(p)
    S.text(p.name);S.coords(p.coords);S.number(p.sprite,0,10000);S.number(p.color,0,1000);S.number(p.scale,0.01,100)
    return p
end
write('createMapMarking','Snippets','addMapBlip',mapMark)
write('updateMapMarking','Snippets','updateMapBlip',function(p)return id(p),mapMark(p) end)
write('deleteMapMarking','Snippets','removeMapBlip',id)

read('getManagedGroups','Vrp','getManagedGroups')
write('saveManagedGroup','Vrp','saveManagedGroup',function(p)
    local group=S.table(p.group or p.data)
    S.text(group.name);S.table(group.config);S.table(group.permissions)
    return S.text(p.originalName,true),group
end)
write('deleteManagedGroup','Vrp','removeManagedGroup',name)
-- Creation has explicit preflight; a cross-resource failure is reported as partial.
-- Never remove groups automatically: another writer may already have assigned them.
S.register('createFacGroups',true,function(ctx,p)
    local orgName=S.text(p.orgName);local orgType=S.text(p.orgType)
    local goalItem=S.text(p.goalItem);local amount=S.number(p.goalAmount,1,1e9)
    local reward=S.number(p.defaultReward,0,1e12)
    if S.Organizations then S.Organizations.beforeCreation(ctx,orgName) end
    local canCreate=S.call(ctx,'Orgs','canCreateManagedOrganization',orgName)
    if canCreate~=true then S.fail('CONFLICT','A organização já existe ou não pode ser criada.') end
    local groups=S.call(ctx,'Vrp','getManagedGroups')
    local ranks={'Recrutador','Novato','Membro','Gerente','SubLider','Lider'}
    for _,group in ipairs(groups) do
        for _,rank in ipairs(ranks) do
            if group.name==rank..orgName then S.fail('CONFLICT','Um dos cargos da organização já existe.') end
        end
    end
    local attempted,created=pcall(S.call,ctx,'Vrp','createFacGroups',orgName,orgType)
    if not attempted then S.fail('PARTIAL_EFFECT','Não foi possível confirmar o estado dos cargos. Reconcilie a organização antes de continuar.') end
    if created~=true then S.fail('OPERATION_FAILED','Não foi possível confirmar a criação dos cargos.') end
    local applied,added=pcall(S.call,ctx,'Orgs','addManagedOrganization',orgName,goalItem,amount,reward)
    if not applied or added~=true then
        S.fail('PARTIAL_EFFECT','Os cargos foram criados, mas a organização não foi confirmada. Reconcilie o estado antes de continuar; não repita automaticamente.')
    end
    return {message='Cargos e organização confirmados pelos recursos da cidade.'}
end)

S.register('getCraftSetups',false,function(ctx)
    return {benches=S.copy(S.call(ctx,'Craft','getCraftBenches')),farm=S.copy(S.call(ctx,'Farm','getFarmConfig'))}
end)
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for key,value in pairs(a) do if not equal(value,b[key]) then return false end end
    for key in pairs(b) do if a[key]==nil then return false end end
    return true
end
local function farmSnapshot(config,key)
    local route
    for _,entry in ipairs(config.Routes or {}) do
        if entry.rewardType==key then
            if route then S.fail('CONFLICT','Existem rotas duplicadas para o vínculo de farm.') end
            route=entry
        end
    end
    local rewards=(config.Rewards or {})[key]
    if (route~=nil)~=(rewards~=nil) then S.fail('CONFLICT','O vínculo de farm possui rota ou recompensa incompleta.') end
    return route and {rewardType=key,routeType=route.routeType,permissions=S.copy(route.permissions or {}),rewards=S.copy(rewards)} or false
end
local function restoreFarm(ctx,snapshots)
    if next(snapshots)==nil then return true end
    for key,snapshot in pairs(snapshots) do
        local ok,result=pcall(function()
            if snapshot then return S.call(ctx,'Farm','upsertFarmLink',snapshot) end
            return S.call(ctx,'Farm','removeFarmLink',key)
        end)
        if not ok or result~=true then return false end
    end
    local ok,current=pcall(S.call,ctx,'Farm','getFarmConfig')
    if not ok then return false end
    for key,snapshot in pairs(snapshots) do
        local valid,value=pcall(farmSnapshot,current,key)
        if not valid or not equal(snapshot,value) then return false end
    end
    return true
end
local function craftChange(ctx,p,deleting)
    local original=deleting and name(p) or S.text(p.originalName,true)
    local bench=not deleting and S.copy(tableField(p,'bench')) or nil
    local farm=not deleting and tableField(p,'farm') or {enabled=false}
    if bench then
        S.text(bench.name);S.table(bench.coords);S.table(bench.craftItems);S.table(bench.armazemItems)
        for _,coord in ipairs(bench.coords) do S.coords(coord) end
    end
    local benches=S.copy(S.call(ctx,'Craft','getCraftBenches'))
    local previous
    for _,entry in ipairs(benches) do
        if entry.name==original then previous=entry end
        if bench and entry.name==bench.name and entry.name~=original then S.fail('CONFLICT','Já existe uma bancada com esse nome.') end
    end
    if original~='' and not previous then S.fail('CONFLICT','A bancada original não existe; atualize a tela.') end
    local oldKey=previous and previous.farmRewardType or ''
    local newKey=farm.enabled==true and S.text(farm.rewardType) or ''
    local snapshots={}
    local farmConfig
    if oldKey~='' or newKey~='' then
        farmConfig=S.copy(S.call(ctx,'Farm','getFarmConfig'))
        for _,entry in ipairs(benches) do
            if entry.name~=original and entry.farmRewardType and entry.farmRewardType~=''
                and (entry.farmRewardType==oldKey or entry.farmRewardType==newKey) then
                S.fail('SHARED_FARM','Este farm está vinculado a outra bancada. Reconcilie os vínculos antes de editar.')
            end
        end
        if oldKey~='' then snapshots[oldKey]=farmSnapshot(farmConfig,oldKey) end
        if newKey~='' then
            snapshots[newKey]=farmSnapshot(farmConfig,newKey)
            S.text(farm.routeType);S.table(farm.permissions);S.table(farm.rewards)
            if not (farmConfig.RouteBlips or {})[farm.routeType] then S.fail('INVALID_INPUT','Tipo de rota inexistente.') end
        end
    end
    if bench then
        bench.farmRewardType=newKey
        bench.farmRouteType=newKey~='' and farm.routeType or nil
        bench.farmPermissions=newKey~='' and S.copy(farm.permissions) or nil
    end
    local farmOk=pcall(function()
        if newKey~='' then
            S.mutate(ctx,'Farm','upsertFarmLink',{rewardType=newKey,routeType=farm.routeType,permissions=farm.permissions,rewards=farm.rewards})
        end
        if oldKey~='' and oldKey~=newKey then S.mutate(ctx,'Farm','removeFarmLink',oldKey) end
    end)
    if not farmOk then
        if restoreFarm(ctx,snapshots) then S.fail('OPERATION_FAILED','O farm não foi confirmado; seus vínculos anteriores foram restaurados. Atualize a tela.') end
        S.fail('PARTIAL_EFFECT','Falha ao alterar/restaurar o farm. Reconcilie os vínculos antes de continuar.')
    end
    local benchOk,result=pcall(function()
        if deleting then return S.mutate(ctx,'Craft','removeCraftBench',original) end
        return S.mutate(ctx,'Craft','upsertCraftBench',original,bench)
    end)
    if not benchOk then
        local restored=pcall(function()
            if previous then S.mutate(ctx,'Craft','upsertCraftBench',bench and bench.name or original,previous)
            elseif bench then S.mutate(ctx,'Craft','removeCraftBench',bench.name) end
            local current=S.call(ctx,'Craft','getCraftBenches')
            local found
            for _,entry in ipairs(current) do if entry.name==(previous and previous.name or bench.name) then found=entry end end
            if previous then
                if not equal(previous,found) then S.fail('PARTIAL_EFFECT','A restauração da bancada não foi confirmada.') end
            elseif found then S.fail('PARTIAL_EFFECT','A bancada criada ainda existe.') end
        end)
        local farmRestored=restoreFarm(ctx,snapshots)
        -- The craft export may move active manufacturing jobs before a failed save.
        -- Public config reads cannot establish restoration of that private job state.
        S.fail('PARTIAL_EFFECT',(restored and farmRestored)
            and 'A bancada não foi confirmada. Configurações anteriores foram reenviadas; confira também fabricações pendentes antes de continuar.'
            or 'A bancada ou o farm podem ter alterações parciais. Confira configurações e fabricações pendentes antes de continuar.')
    end
    return result
end
S.register('saveCraftSetup',true,function(ctx,p)return craftChange(ctx,p,false) end)
S.register('deleteCraftSetup',true,function(ctx,p)return craftChange(ctx,p,true) end)

read('getDesmanches','Desmanche','getDesmancheConfig')
local function desmanche(p)
    p=mutationTable(p);S.text(p.name)
    for _,key in ipairs({'inicio','local_veiculo','local_ferramentas','local_finalizar'}) do S.coords(p[key]) end
    return p
end
write('createDesmanche','Desmanche','addDesmanche',desmanche)
S.register('updateDesmanche',true,function(ctx,p)
    local original=S.text(p.originalName)
    local data=desmanche(p)
    local current=S.call(ctx,'Desmanche','getDesmancheConfig')
    for _,entry in ipairs(current.desmanches or {}) do
        if entry.name==original then
            return S.mutate(ctx,'Desmanche','updateDesmanche',original,S.preservePrivate(entry,data))
        end
    end
    S.fail('CONFLICT','O desmanche original não existe; atualize a tela.')
end)
write('deleteDesmanche','Desmanche','removeDesmanche',name)
write('saveDesmancheSettings','Desmanche','updateDesmancheSettings',function(p)return p end)
read('getSafeZones','SafeZone','getSafeZoneConfig')
local function safezone(p)
    p=mutationTable(p);S.text(p.name);S.table(p.zones)
    if #p.zones<1 then S.fail('INVALID_INPUT','Informe ao menos um polígono.') end
    for _,zone in ipairs(p.zones) do
        S.table(zone.coords);S.number(zone.minZ);S.number(zone.maxZ)
        if #zone.coords<3 or zone.maxZ<=zone.minZ then S.fail('INVALID_INPUT','Polígono inválido.') end
        for _,point in ipairs(zone.coords) do S.number(point.x);S.number(point.y) end
    end
    return p
end
write('createSafeZone','SafeZone','addSafeZone',safezone)
write('updateSafeZone','SafeZone','updateSafeZone',function(p)return S.text(p.originalName),safezone(p) end)
write('deleteSafeZone','SafeZone','removeSafeZone',name)
write('saveSafeZoneSettings','SafeZone','updateSafeZoneSettings',function(p)return p end)

read('getJobs','Empregos','getJobsConfig')
write('updateJob','Empregos','updateJob',function(p)
    return name(p),tableField(p,'job'),tableField(p,'extra')
end)
write('saveJobsGlobal','Empregos','updateJobsGlobal',function(p)return p end)
write('captureJobUniform','Empregos','captureJobUniform',function(p,ctx)return ctx.source,name(p) end)

read('getRoubos','Roubos','getRoubosConfig')
write('saveRobberySetup','Roubos','saveRobberySetup',function(p)return S.text(p.type),tableField(p,'data') end)
local function robbery(p)
    p=mutationTable(p);S.text(p.type);S.number(p.id,1,2147483647)
    for _,key in ipairs({'x','y','z','h'}) do S.number(p[key]) end
    return p
end
write('addRobberyLocation','Roubos','addRobberyLocation',robbery)
write('updateRobberyLocation','Roubos','updateRobberyLocation',function(p)return S.text(p.originalType),S.number(p.originalId,1,2147483647),robbery(p) end)
write('deleteRobberyLocation','Roubos','removeRobberyLocation',function(p)return S.text(p.type),S.number(p.id,1,2147483647) end)
write('saveRobberyGlobalSettings','Roubos','saveRobberyGlobalSettings',function(p)return p end)

local function privateDocument(readName,saveName,key,getExport,saveExport,required)
    read(readName,key,getExport)
    S.register(saveName,true,function(ctx,p)
        for _,field in ipairs(required) do S.table(p[field]) end
        local current=S.call(ctx,key,getExport)
        return S.mutate(ctx,key,saveExport,S.preservePrivate(current,p))
    end)
end
privateDocument('getBancoCentral','saveBancoCentral','BancoCentral','getBancoCentralConfig','saveBancoCentralConfig',{'settings','banks'})
privateDocument('getJoalheria','saveJoalheria','Joalheria','getJoalheriaConfig','saveJoalheriaConfig',{'settings','displays','rewards'})
privateDocument('getRoubocofre','saveRoubocofre','Roubocofre','getRoubocofreConfig','saveRoubocofreConfig',{'settings','banks'})

read('getResidences','Residences','getResidencesConfig')
write('saveResidence','Residences','saveResidence',function(p)
    local data=tableField(p,'data');S.text(data.name)
    for _,key in ipairs({'x','y','z'}) do S.number(data[key]) end
    return S.text(p.originalName,true),data
end)
write('deleteResidence','Residences','removeResidence',name)
write('saveResidenceInterior','Residences','saveInteriorTemplate',function(p)return S.text(p.originalName,true),name(p),tableField(p,'data') end)
write('deleteResidenceInterior','Residences','removeInteriorTemplate',name)
S.register('saveResidencesSettings',true,function(ctx,p)
    local current=S.call(ctx,'Residences','getResidencesConfig')
    return S.mutate(ctx,'Residences','saveResidencesSettings',S.preservePrivate(current.settings,p))
end)

read('getDealership','Dealership','getDealershipConfig')
read('getServerVehicleCatalog','Garage','getVehicleCatalog')
local function audit(ctx)return {actorId=ctx.userId,actorLabel='IC CONFIG',origin='ic_config'} end
write('saveDealershipVehicle','Dealership','saveDealershipVehicle',function(p,ctx)return S.text(p.spawn),S.number(p.stock,0,100000000),audit(ctx) end)
write('deleteDealershipVehicle','Dealership','removeDealershipVehicle',function(p,ctx)return S.text(p.spawn),audit(ctx) end)
S.register('saveDealershipSettings',true,function(ctx,p)
    for _,key in ipairs({'settings','testDrive','vips','categories'}) do S.table(p[key]) end
    local current=S.call(ctx,'Dealership','getDealershipConfig')
    return S.mutate(ctx,'Dealership','saveDealershipSettings',S.preservePrivate(current,p),audit(ctx))
end)
write('saveServerVehicle','Garage','saveVehicleCatalogEntry',function(p)
    local data=tableField(p,'data');S.text(data.name);S.number(data.price,0,1e12);S.number(data.trunk,0,1e9)
    return S.text(p.originalSpawn,true),S.text(p.spawn),data
end)
write('deleteServerVehicle','Garage','removeVehicleCatalogEntry',function(p)return S.text(p.spawn) end)
S.register('deleteServerVehiclesBatch',true,function(ctx,p)
    local vehicles=tableField(p,'vehicles')
    if #vehicles<1 or #vehicles>200 then S.fail('INVALID_INPUT','Selecione de 1 a 200 veículos.') end
    local catalog=S.call(ctx,'Garage','getVehicleCatalog');local seen={}
    for _,spawn in ipairs(vehicles) do
        S.text(spawn)
        if seen[spawn] or not catalog[spawn] then S.fail('CONFLICT','A seleção contém veículo repetido ou ausente; atualize o catálogo.') end
        seen[spawn]=true
    end
    return S.mutate(ctx,'Garage','removeVehicleCatalogEntries',vehicles)
end)
