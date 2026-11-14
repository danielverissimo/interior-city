local Tunnel = module('vrp', 'lib/Tunnel')
local Proxy = module('vrp', 'lib/Proxy')
local vRP = Proxy.getInterface('vRP')
local API = {}
Tunnel.bindInterface(GetCurrentResourceName(), API)

local function getUserId(src)
    if vRP.getUserId then return vRP.getUserId(src) end
    if vRP.Passport then return vRP.Passport(src) end
end

local function hasPermission(src)
    if src == 0 then return true end
    if not Config.RequirePermission then return true end
    if Config.AcePermission ~= '' and IsPlayerAceAllowed(src, Config.AcePermission) then return true end
    local userId = getUserId(src)
    if not userId then return false end
    for _,permission in ipairs(Config.Permissions or {}) do
        local ok = false
        if vRP.hasPermission then ok = vRP.hasPermission(userId, permission)
        elseif vRP.HasPermission then ok = vRP.HasPermission(userId, permission)
        elseif vRP.HasGroup then ok = vRP.HasGroup(userId, permission) end
        if ok then return true end
    end
    return false
end

local function safeExport(resource, exportName, ...)
    if GetResourceState(resource) ~= 'started' then return false, ('O resource %s não está iniciado.'):format(resource) end
    local args = {...}
    local ok,a,b,c = pcall(function()
        local proxy = exports[resource]
        local fn = proxy[exportName]
        if not fn then error(('Export %s não encontrado em %s'):format(exportName, resource)) end
        return fn(proxy, table.unpack(args))
    end)
    if not ok then
        print(('^1[mg_config]^7 %s:%s -> %s'):format(resource, exportName, tostring(a)))
        return false, 'Falha ao comunicar com '..resource..'.'
    end
    return a,b,c
end

local function result(ok,msg,data) return { ok=ok == true, message=msg, data=data } end
function API.hasAccess() return hasPermission(source) end

-- BAÚS
function API.getChests()
    if not hasPermission(source) then return result(false,'Sem permissão.',{}) end
    local chests,msg = safeExport(Config.InventoryResource,'getChests')
    if chests == false then return result(false,msg,{}) end
    local out = {}
    for _,chest in ipairs(chests or {}) do
        local c=chest.coords or {}
        out[#out+1]={ name=tostring(chest.name or ''), weight=tonumber(chest.weight) or 0, permission=tostring(chest.permission or ''), coords={x=tonumber(c.x or c[1]) or 0,y=tonumber(c.y or c[2]) or 0,z=tonumber(c.z or c[3]) or 0} }
    end
    return result(true,nil,out)
end
function API.createChest(data)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.InventoryResource,'addChest',tostring(data.name or ''),tonumber(data.weight),tostring(data.permission or ''),data.coords or {})
    return result(ok,msg or (ok and 'Baú criado.' or 'Falha ao criar.'))
end
function API.updateChest(data)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.InventoryResource,'updateChest',tostring(data.name or ''),tonumber(data.weight),data.coords or {},tostring(data.permission or ''))
    return result(ok,msg or (ok and 'Baú atualizado.' or 'Falha ao atualizar.'))
end
function API.deleteChest(name)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.InventoryResource,'removeChest',tostring(name or ''))
    return result(ok,msg)
end

-- GARAGENS
function API.getGarages()
    if not hasPermission(source) then return result(false,'Sem permissão.',{}) end
    local garages,msg=safeExport(Config.GarageResource,'getGarages')
    if garages == false then return result(false,msg,{}) end
    return result(true,nil,garages or {})
end
function API.getGarageTypes()
    if not hasPermission(source) then return result(false,'Sem permissão.',{}) end
    local types,msg=safeExport(Config.GarageResource,'getGarageTypes')
    if types == false then return result(false,msg,{}) end
    local out={}
    for name,data in pairs(types or {}) do out[#out+1]={name=name,data=data} end
    table.sort(out,function(a,b) return a.name:lower()<b.name:lower() end)
    return result(true,nil,out)
end
function API.createGarage(data)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.GarageResource,'addGarage',data)
    return result(ok,msg)
end
function API.updateGarage(data)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.GarageResource,'updateGarage',tostring(data.originalId or data.id or ''),data)
    return result(ok,msg)
end
function API.deleteGarage(id)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.GarageResource,'removeGarage',tostring(id or ''))
    return result(ok,msg)
end
function API.createGarageType(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.GarageResource,'addGarageType',tostring(payload.name or ''),payload.data or {})
    return result(ok,msg)
end
function API.updateGarageType(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.GarageResource,'updateGarageType',tostring(payload.name or ''),payload.data or {})
    return result(ok,msg)
end
function API.deleteGarageType(name)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.GarageResource,'removeGarageType',tostring(name or ''))
    return result(ok,msg)
end



function API.getItemList()
    if not hasPermission(source) then return result(false,'Sem permissão.',{}) end

    local itemList = vRP.getAllItens and vRP.getAllItens() or {}
    local out = {}

    for k,v in pairs(itemList or {}) do
        out[#out+1] = {
            index = tostring(k),
            name = tostring((type(v) == 'table' and v.name) or k)
        }
    end

    table.sort(out,function(a,b)
        return a.name:lower() < b.name:lower()
    end)

    return result(true,nil,out)
end

-- LOJAS
function API.getShops()
    if not hasPermission(source) then return result(false,'Sem permissão.',{}) end
    local shops,msg=safeExport(Config.InventoryResource,'getShopConfigs')
    if shops == false then return result(false,msg,{}) end
    return result(true,nil,shops or {})
end

function API.createShop(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.InventoryResource,'createShopConfig',tostring(payload.name or ''),payload.data or {})
    return result(ok,msg)
end

function API.updateShop(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(
        Config.InventoryResource,
        'updateShopConfig',
        tostring(payload.originalName or payload.name or ''),
        tostring(payload.name or ''),
        payload.data or {}
    )
    return result(ok,msg)
end

function API.deleteShop(name)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.InventoryResource,'removeShopConfig',tostring(name or ''))
    return result(ok,msg)
end


-- CRAFT + FARM
function API.getCraftSetups()
    if not hasPermission(source) then return result(false,'Sem permissão.',{}) end
    local benches,msg=safeExport(Config.CraftResource,'getCraftBenches')
    if benches==false then return result(false,msg,{}) end
    local farm,fmsg=safeExport(Config.FarmResource,'getFarmConfig')
    if farm==false then return result(false,fmsg,{}) end
    return result(true,nil,{benches=benches or {},farm=farm or {}})
end

local function farmLinkUsage(benches, rewardType, exceptName)
    local n=0
    for _,b in ipairs(type(benches)=='table' and benches or {}) do
        if b.name~=exceptName and tostring(b.farmRewardType or '')==rewardType then n=n+1 end
    end
    return n
end

function API.saveCraftSetup(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local bench=payload and payload.bench or {}
    local farm=payload and payload.farm or {}
    local original=tostring(payload and payload.originalName or bench.name or '')
    local benches=safeExport(Config.CraftResource,'getCraftBenches')
    local oldReward=''
    if type(benches)=='table' then
        for _,b in ipairs(benches) do
            if b.name==original then oldReward=tostring(b.farmRewardType or '') break end
        end
    end

    if farm.enabled then
        local newReward=tostring(farm.rewardType or '')
        local ok,msg=safeExport(Config.FarmResource,'upsertFarmLink',{
            rewardType=newReward,
            routeType=tostring(farm.routeType or ''),
            permissions=farm.permissions or {},
            rewards=farm.rewards or {}
        })
        if not ok then return result(false,msg or 'Falha ao salvar farm.') end
        bench.farmRewardType=newReward
        bench.farmRouteType=tostring(farm.routeType or '')
        bench.farmPermissions=farm.permissions or {}

        if oldReward~='' and oldReward~=newReward and farmLinkUsage(benches,oldReward,original)==0 then
            safeExport(Config.FarmResource,'removeFarmLink',oldReward)
        end
    else
        bench.farmRewardType=''
        bench.farmRouteType=''
        bench.farmPermissions={}
        if oldReward~='' and farmLinkUsage(benches,oldReward,original)==0 then
            safeExport(Config.FarmResource,'removeFarmLink',oldReward)
        end
    end

    local ok,msg=safeExport(Config.CraftResource,'upsertCraftBench',original,bench)
    return result(ok,msg or (ok and 'Craft e farm salvos.' or 'Falha ao salvar bancada.'))
end

function API.deleteCraftSetup(name)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local benches=safeExport(Config.CraftResource,'getCraftBenches')
    local reward=''
    if type(benches)=='table' then
        for _,b in ipairs(benches) do if b.name==name then reward=tostring(b.farmRewardType or '') break end end
    end
    local ok,msg=safeExport(Config.CraftResource,'removeCraftBench',tostring(name or ''))
    if not ok then return result(false,msg) end
    if reward~='' and farmLinkUsage(benches,reward,tostring(name or ''))==0 then
        safeExport(Config.FarmResource,'removeFarmLink',reward)
    end
    return result(true,'Bancada removida. O farm só é removido quando não é compartilhado por outra bancada.')
end

function API.saveFarmRouteType(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    payload = type(payload) == 'table' and payload or {}
    local originalName = tostring(payload.originalName or '')
    local newName = tostring(payload.name or '')

    local ok,msg = safeExport(
        Config.FarmResource,
        'upsertRouteType',
        originalName,
        newName,
        payload.regions or {}
    )
    if not ok then
        return result(false,msg or 'Falha ao salvar tipo de rota.')
    end

    -- O m_craft também guarda farmRouteType como metadado da bancada.
    -- Ao renomear um tipo no m_farm, mantém todas as bancadas sincronizadas.
    if originalName ~= '' and newName ~= '' and originalName ~= newName then
        local benches = safeExport(Config.CraftResource,'getCraftBenches')
        if type(benches) == 'table' then
            for _,bench in ipairs(benches) do
                if tostring(bench.farmRouteType or '') == originalName then
                    bench.farmRouteType = newName
                    local saved,saveMsg = safeExport(Config.CraftResource,'upsertCraftBench',tostring(bench.name or ''),bench)
                    if not saved then
                        return result(false,saveMsg or ('O tipo foi renomeado no farm, mas não foi possível atualizar a bancada '..tostring(bench.name or '')..'.'))
                    end
                end
            end
        end
    end

    return result(true,msg or 'Tipo de rota salvo e sincronizado.')
end

function API.deleteFarmRouteType(name)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    name = tostring(name or '')

    -- Evita deixar metadados órfãos no m_craft, mesmo se a ligação do m_farm
    -- estiver incompleta por alguma configuração antiga.
    local benches = safeExport(Config.CraftResource,'getCraftBenches')
    local usages = {}
    if type(benches) == 'table' then
        for _,bench in ipairs(benches) do
            if tostring(bench.farmRouteType or '') == name then
                usages[#usages + 1] = tostring(bench.name or 'bancada')
            end
        end
    end
    if #usages > 0 then
        return result(false,('Este tipo de rota está vinculado às bancadas: %s. Troque o tipo nelas antes de excluir.'):format(table.concat(usages, ', ')))
    end

    local ok,msg = safeExport(Config.FarmResource,'removeRouteType',name)
    return result(ok,msg)
end


-- LOJA DE ROUPA
function API.getClothingShops()
    if not hasPermission(source) then return result(false,'Sem permissão.',{}) end
    local shops,msg=safeExport(Config.SkinshopResource,'getSkinShops')
    if shops==false then return result(false,msg,{}) end
    return result(true,nil,shops or {})
end

function API.createClothingShop(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.SkinshopResource,'addSkinshop',payload and payload.coords or {})
    return result(ok,msg)
end

function API.updateClothingShop(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.SkinshopResource,'updateSkinshop',payload and payload.id,payload and payload.coords or {})
    return result(ok,msg)
end

function API.deleteClothingShop(id)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.SkinshopResource,'removeSkinshop',id)
    return result(ok,msg)
end


-- BARBEARIA
function API.getBarbershops()
    if not hasPermission(source) then return result(false,'Sem permissão.',{}) end
    local shops,msg=safeExport(Config.BarbershopResource,'getBarberShops')
    if shops==false then return result(false,msg,{}) end
    return result(true,nil,shops or {})
end

function API.createBarbershop(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.BarbershopResource,'addBarberShop',payload and payload.coords or {})
    return result(ok,msg)
end

function API.updateBarbershop(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.BarbershopResource,'updateBarberShop',payload and payload.id,payload and payload.coords or {})
    return result(ok,msg)
end

function API.deleteBarbershop(id)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.BarbershopResource,'removeBarberShop',id)
    return result(ok,msg)
end


-- ESTÚDIO TATTOO
function API.getTattooShops()
    if not hasPermission(source) then
        return result(false,'Sem permissão.',{})
    end

    local shops,msg = safeExport(Config.TattooResource,'getTattooShops')

    if shops == false then
        return result(false,msg,{})
    end

    return result(true,nil,shops or {})
end

function API.createTattooShop(payload)
    if not hasPermission(source) then
        return result(false,'Sem permissão.')
    end

    local ok,msg = safeExport(
        Config.TattooResource,
        'addTattooShop',
        payload and payload.coords or {}
    )

    return result(ok,msg)
end

function API.updateTattooShop(payload)
    if not hasPermission(source) then
        return result(false,'Sem permissão.')
    end

    local ok,msg = safeExport(
        Config.TattooResource,
        'updateTattooShop',
        payload and payload.id,
        payload and payload.coords or {}
    )

    return result(ok,msg)
end

function API.deleteTattooShop(id)
    if not hasPermission(source) then
        return result(false,'Sem permissão.')
    end

    local ok,msg = safeExport(
        Config.TattooResource,
        'removeTattooShop',
        id
    )

    return result(ok,msg)
end


-- BLIP FARDAMENTO
function API.getCloakrooms()
    if not hasPermission(source) then return result(false,'Sem permissão.',{}) end
    local rooms,msg=safeExport(Config.CloakroomResource,'getCloakrooms')
    if rooms==false then return result(false,msg,{}) end
    return result(true,nil,rooms or {})
end

function API.saveCloakroom(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(
        Config.CloakroomResource,
        'upsertCloakroom',
        tostring(payload and payload.originalName or ''),
        payload and payload.room or {}
    )
    return result(ok,msg)
end

function API.deleteCloakroom(name)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.CloakroomResource,'removeCloakroom',tostring(name or ''))
    return result(ok,msg)
end


-- MARCAÇÕES MAPA
function API.getMapMarkings()
    if not hasPermission(source) then
        return result(false, 'Sem permissão.', {})
    end

    local list, msg = safeExport(
        Config.SnippetsResource,
        'getMapBlips'
    )

    if list == false then
        return result(false, msg, {})
    end

    return result(true, nil, list or {})
end

function API.createMapMarking(payload)
    if not hasPermission(source) then
        return result(false, 'Sem permissão.')
    end

    local ok, msg = safeExport(
        Config.SnippetsResource,
        'addMapBlip',
        payload or {}
    )

    return result(ok, msg)
end

function API.updateMapMarking(payload)
    if not hasPermission(source) then
        return result(false, 'Sem permissão.')
    end

    local ok, msg = safeExport(
        Config.SnippetsResource,
        'updateMapBlip',
        payload and payload.id,
        payload or {}
    )

    return result(ok, msg)
end

function API.deleteMapMarking(id)
    if not hasPermission(source) then
        return result(false, 'Sem permissão.')
    end

    local ok, msg = safeExport(
        Config.SnippetsResource,
        'removeMapBlip',
        id
    )

    return result(ok, msg)
end


-- ELEVADORES
function API.getElevators()
    if not hasPermission(source) then
        return result(false,'Sem permissão.',{})
    end

    local data,msg = safeExport(
        Config.SnippetsResource,
        'getElevators'
    )

    if data == false then
        return result(false,msg,{})
    end

    return result(true,nil,data or {})
end

function API.saveElevator(payload)
    if not hasPermission(source) then
        return result(false,'Sem permissão.')
    end

    payload = type(payload) == 'table' and payload or {}

    local ok,msg = safeExport(
        Config.SnippetsResource,
        'upsertElevator',
        tostring(payload.originalId or ''),
        payload.data or {}
    )

    return result(ok,msg)
end

function API.deleteElevator(id)
    if not hasPermission(source) then
        return result(false,'Sem permissão.')
    end

    local ok,msg = safeExport(
        Config.SnippetsResource,
        'removeElevator',
        tostring(id or '')
    )

    return result(ok,msg)
end


-- GERENCIAR CARGOS
function API.getManagedGroups()
    if not hasPermission(source) then
        return result(false,'Sem permissão.',{})
    end

    local list,msg=safeExport(Config.VrpResource,'getManagedGroups')
    if list==false then return result(false,msg,{}) end
    return result(true,nil,list or {})
end

function API.saveManagedGroup(payload)
    if not hasPermission(source) then
        return result(false,'Sem permissão.')
    end

    local ok,msg=safeExport(
        Config.VrpResource,
        'saveManagedGroup',
        tostring(payload and payload.originalName or ''),
        payload and payload.group or {}
    )

    return result(ok,msg)
end

function API.deleteManagedGroup(name)
    if not hasPermission(source) then
        return result(false,'Sem permissão.')
    end

    local ok,msg=safeExport(
        Config.VrpResource,
        'removeManagedGroup',
        tostring(name or '')
    )

    return result(ok,msg)
end


-- CRIAÇÃO DE FAC
function API.createFacGroups(payload)
    if not hasPermission(source) then
        return result(false,'Sem permissão.')
    end

    local orgName=tostring(payload and payload.orgName or '')
    local orgType=tostring(payload and payload.orgType or '')
    local goalItem=tostring(payload and payload.goalItem or '')
    local goalAmount=tonumber(payload and payload.goalAmount)
    local defaultReward=tonumber(payload and payload.defaultReward)

    -- Primeiro valida o m_orgs_v2 para não criar cargos pela metade.
    local canCreate,checkMsg=safeExport(
        Config.OrgsResource,
        'canCreateManagedOrganization',
        orgName
    )

    if not canCreate then
        return result(false,checkMsg or 'Esta FAC já existe no m_orgs_v2.')
    end

    local okGroups,msgGroups=safeExport(
        Config.VrpResource,
        'createFacGroups',
        orgName,
        orgType
    )

    if not okGroups then
        return result(false,msgGroups)
    end

    local okOrg,msgOrg=safeExport(
        Config.OrgsResource,
        'addManagedOrganization',
        orgName,
        goalItem,
        goalAmount,
        defaultReward
    )

    if not okOrg then
        -- Rollback dos cargos caso o m_orgs_v2 falhe.
        safeExport(Config.VrpResource,'removeFacGroups',orgName)
        return result(false,msgOrg or 'Falha ao cadastrar a FAC no m_orgs_v2. Os cargos foram revertidos.')
    end

    return result(true,('FAC %s criada nos cargos e no m_orgs_v2.'):format(orgName))
end

function API.deleteFacBundle(payload)
    if not hasPermission(source) then
        return result(false,'Sem permissão.')
    end

    local orgName=tostring(payload and payload.orgName or '')
    if orgName=='' then
        return result(false,'Selecione a FAC que deseja excluir.')
    end

    -- Remove primeiro os cargos. Isso dispara os eventos normais da vRP
    -- enquanto o m_orgs_v2 ainda conhece os grupos.
    local okGroups,msgGroups=safeExport(
        Config.VrpResource,
        'removeFacGroups',
        orgName
    )

    if not okGroups then
        return result(false,msgGroups)
    end

    local okOrg,msgOrg=safeExport(
        Config.OrgsResource,
        'removeManagedOrganization',
        orgName
    )

    if not okOrg then
        return result(false,(msgOrg or 'Os cargos foram removidos, mas houve falha ao excluir no m_orgs_v2.'))
    end

    return result(true,('FAC %s excluída dos cargos e do m_orgs_v2.'):format(orgName))
end


-- DESMANCHE
function API.getDesmanches()
    if not hasPermission(source) then
        return result(false,'Sem permissão.',{})
    end

    local data,msg=safeExport(
        Config.DesmancheResource,
        'getDesmancheConfig'
    )

    if data==false then
        return result(false,msg,{})
    end

    return result(true,nil,data or {})
end

function API.createDesmanche(payload)
    if not hasPermission(source) then
        return result(false,'Sem permissão.')
    end

    local ok,msg=safeExport(
        Config.DesmancheResource,
        'addDesmanche',
        payload or {}
    )

    return result(ok,msg)
end

function API.updateDesmanche(payload)
    if not hasPermission(source) then
        return result(false,'Sem permissão.')
    end

    local ok,msg=safeExport(
        Config.DesmancheResource,
        'updateDesmanche',
        tostring(payload and payload.originalName or ''),
        payload and payload.data or {}
    )

    return result(ok,msg)
end

function API.deleteDesmanche(name)
    if not hasPermission(source) then
        return result(false,'Sem permissão.')
    end

    local ok,msg=safeExport(
        Config.DesmancheResource,
        'removeDesmanche',
        tostring(name or '')
    )

    return result(ok,msg)
end

function API.saveDesmancheSettings(payload)
    if not hasPermission(source) then
        return result(false,'Sem permissão.')
    end

    local ok,msg=safeExport(
        Config.DesmancheResource,
        'updateDesmancheSettings',
        payload or {}
    )

    return result(ok,msg)
end


-- SAFEZONE / POLYSAFEZONE
function API.getSafeZones()
    if not hasPermission(source) then return result(false,'Sem permissão.',{}) end
    local data,msg=safeExport(Config.SafeZoneResource,'getSafeZoneConfig')
    if data==false then return result(false,msg,{}) end
    return result(true,nil,data or {})
end

function API.createSafeZone(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.SafeZoneResource,'addSafeZone',payload or {})
    return result(ok,msg)
end

function API.updateSafeZone(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(
        Config.SafeZoneResource,
        'updateSafeZone',
        tostring(payload and payload.originalName or ''),
        payload and payload.data or {}
    )
    return result(ok,msg)
end

function API.deleteSafeZone(name)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.SafeZoneResource,'removeSafeZone',tostring(name or ''))
    return result(ok,msg)
end

function API.saveSafeZoneSettings(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.SafeZoneResource,'updateSafeZoneSettings',payload or {})
    return result(ok,msg)
end


-- EMPREGOS
function API.getJobs()
    if not hasPermission(source) then return result(false,'Sem permissão.',{}) end
    local data,msg=safeExport(Config.EmpregosResource,'getJobsConfig')
    if data==false then return result(false,msg,{}) end
    return result(true,nil,data or {})
end

function API.updateJob(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end

    payload=type(payload)=="table" and payload or {}
    local name=tostring(payload.name or '')
    local job=type(payload.job)=="table" and payload.job or {}
    local requestedXp=tonumber(job.xp_per_action)

    local ok,msg=safeExport(
        Config.EmpregosResource,
        'updateJob',
        name,
        job,
        payload.extra or {}
    )
    if not ok then return result(false,msg) end

    -- Confirma no próprio m_empregos que o valor decimal foi realmente persistido.
    -- Isso evita o falso "salvo" quando uma versão antiga do m_empregos ainda
    -- está carregada e remove campos que ela não conhece.
    if requestedXp~=nil then
        local savedData,readMsg=safeExport(Config.EmpregosResource,'getJobsConfig')
        if savedData==false then
            return result(false,readMsg or 'Não foi possível validar o emprego após salvar.')
        end

        local savedJob=type(savedData)=='table' and type(savedData.jobs)=='table' and savedData.jobs[name] or nil
        local savedXp=savedJob and tonumber(savedJob.xp_per_action) or nil
        if savedXp==nil or math.abs(savedXp-requestedXp)>0.000001 then
            return result(false,'O m_empregos carregado não persistiu o XP por ação. Substitua/reinicie o m_empregos atualizado e tente novamente.')
        end
    end

    return result(true,msg)
end

function API.captureJobUniform(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg,data=safeExport(
        Config.EmpregosResource,
        'captureJobUniform',
        source,
        tostring(payload and payload.name or '')
    )
    return {ok=ok==true,message=msg,data=data}
end

function API.saveJobsGlobal(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.EmpregosResource,'updateJobsGlobal',payload or {})
    return result(ok,msg)
end


-- ROUBOS
function API.getRoubos()
    if not hasPermission(source) then return result(false,'Sem permissão.',{}) end
    local data,msg=safeExport(Config.RoubosResource,'getRoubosConfig')
    if data==false then return result(false,msg,{}) end
    return result(true,nil,data or {})
end

function API.saveRobberySetup(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.RoubosResource,'saveRobberySetup',tostring(payload and payload.type or ''),payload and payload.data or {})
    return result(ok,msg)
end

function API.addRobberyLocation(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.RoubosResource,'addRobberyLocation',payload or {})
    return result(ok,msg)
end

function API.updateRobberyLocation(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.RoubosResource,'updateRobberyLocation',
        tostring(payload and payload.originalType or ''),payload and payload.originalId,
        payload and payload.data or {})
    return result(ok,msg)
end

function API.deleteRobberyLocation(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.RoubosResource,'removeRobberyLocation',
        tostring(payload and payload.type or ''),payload and payload.id)
    return result(ok,msg)
end

function API.saveRobberyGlobalSettings(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.RoubosResource,'saveRobberyGlobalSettings',payload or {})
    return result(ok,msg)
end


-- Modulos de roubo opcionais: podem estar separados (base de venda) ou
-- dentro do m_roubos unificado. O m_roubos de comercio nao oferece os
-- exports de Banco Central, Joalheria e Cofres; nao tentar chama-los nele.
local ROBBERY_MODULES = {
    central = {
        label = 'Banco Central', dedicated = 'm_banco_central',
        configured = function() return Config.BancoCentralResource end,
        combinedPath = 'modules/banco_central/config_manager.lua'
    },
    jewelry = {
        label = 'Joalheria', dedicated = 'm_joalheria',
        configured = function() return Config.JoalheriaResource end,
        combinedPath = 'modules/joalheria/config_manager.lua'
    },
    vault = {
        label = 'Roubo a Cofres', dedicated = 'm_roubocofre',
        configured = function() return Config.RoubocofreResource end,
        combinedPath = 'modules/roubocofre/config_manager.lua'
    }
}

-- So invoca o export se houver um config_manager correspondente no recurso.
-- Assim, m_roubos usado apenas para roubos de comercio nao gera erros no console.
local function robberyBackend(kind, exportName)
    local moduleInfo = ROBBERY_MODULES[kind]
    local names, seen = {}, {}
    local function add(name)
        if type(name) == 'string' and name ~= '' and not seen[name] then
            names[#names + 1] = name
            seen[name] = true
        end
    end

    add(moduleInfo.dedicated)
    add(moduleInfo.configured())

    for _,resource in ipairs(names) do
        if GetResourceState(resource) == 'started' then
            local file = resource == 'm_roubos' and moduleInfo.combinedPath or 'config_manager.lua'
            local content = LoadResourceFile(resource, file)
            if type(content) == 'string' and content:find(exportName, 1, true) then
                return resource
            end
        end
    end
    return nil
end

local function robberyModuleCall(kind, exportName, ...)
    local resource = robberyBackend(kind, exportName)
    if not resource then
        return false, ROBBERY_MODULES[kind].label .. ' não está disponível neste servidor.', nil
    end
    local value, msg = safeExport(resource, exportName, ...)
    return value, msg, resource
end

local function robberyModuleGet(kind, exportName)
    if not hasPermission(source) then return result(false, 'Sem permissão.', {}) end
    local data, msg, resource = robberyModuleCall(kind, exportName)
    if data == false or data == nil then
        return {ok = false, message = msg or 'Módulo não disponível.', data = {}, unavailable = resource == nil}
    end
    return {ok = true, data = data, resource = resource}
end

local function robberyModuleSave(kind, exportName, payload)
    if not hasPermission(source) then return result(false, 'Sem permissão.') end
    local ok, msg = robberyModuleCall(kind, exportName, payload or {})
    return result(ok, msg)
end

function API.getBancoCentral()
    return robberyModuleGet('central', 'getBancoCentralConfig')
end

function API.saveBancoCentral(payload)
    return robberyModuleSave('central', 'saveBancoCentralConfig', payload)
end

function API.getJoalheria()
    return robberyModuleGet('jewelry', 'getJoalheriaConfig')
end

function API.saveJoalheria(payload)
    return robberyModuleSave('jewelry', 'saveJoalheriaConfig', payload)
end

function API.getRoubocofre()
    return robberyModuleGet('vault', 'getRoubocofreConfig')
end

function API.saveRoubocofre(payload)
    return robberyModuleSave('vault', 'saveRoubocofreConfig', payload)
end


-- CASAS / RESIDENCES
function API.getResidences()
    if not hasPermission(source) then return result(false,'Sem permissão.',{}) end
    local data,msg=safeExport(Config.ResidencesResource,'getResidencesConfig')
    if data==false then return result(false,msg,{}) end
    return result(true,nil,data or {})
end

function API.saveResidence(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(
        Config.ResidencesResource,
        'saveResidence',
        tostring(payload and payload.originalName or ''),
        payload and payload.data or {}
    )
    return result(ok,msg)
end

function API.deleteResidence(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.ResidencesResource,'removeResidence',tostring(payload and payload.name or ''))
    return result(ok,msg)
end

function API.saveResidenceInterior(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(
        Config.ResidencesResource,
        'saveInteriorTemplate',
        tostring(payload and payload.originalName or ''),
        tostring(payload and payload.name or ''),
        payload and payload.data or {}
    )
    return result(ok,msg)
end

function API.deleteResidenceInterior(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.ResidencesResource,'removeInteriorTemplate',tostring(payload and payload.name or ''))
    return result(ok,msg)
end

function API.saveResidencesSettings(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.ResidencesResource,'saveResidencesSettings',payload or {})
    return result(ok,msg)
end


-- CONCESSIONÁRIA / CATÁLOGO DO SERVIDOR
function API.getDealership()
    if not hasPermission(source) then return result(false,'Sem permissão.',{}) end
    local data,msg=safeExport(Config.DealershipResource,'getDealershipConfig')
    if data==false then return result(false,msg,{}) end
    return result(true,nil,data or {})
end

function API.getServerVehicleCatalog()
    if not hasPermission(source) then return result(false,'Sem permissão.',{}) end
    local data,msg=safeExport(Config.GarageResource,'getVehicleCatalog')
    if data==false then return result(false,msg,{}) end
    return result(true,nil,data or {})
end

function API.saveServerVehicle(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end

    local spawn=tostring(payload and payload.spawn or ''):lower()
    local ok,msg,data=safeExport(
        Config.GarageResource,
        'saveVehicleCatalogEntry',
        tostring(payload and payload.originalSpawn or ''),
        spawn,
        payload and payload.data or {}
    )

    if ok~=true then
        return {ok=false,message=msg,data=data}
    end

    -- Confirma que o cadastro não foi apenas gravado no arquivo: ele também
    -- precisa estar disponível no catálogo runtime que garagem/inventory/tuning usam.
    local live=safeExport(Config.GarageResource,'getVehicleCatalogEntry',spawn)
    if type(live)~='table' then
        return result(false,'O veículo foi salvo, mas não entrou no catálogo runtime do servidor. Reinicie o m_garage e tente novamente.')
    end

    return {ok=true,message=msg,data=live}
end

function API.deleteServerVehicle(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.GarageResource,'removeVehicleCatalogEntry',tostring(payload and payload.spawn or ''))
    return result(ok,msg)
end

function API.deleteServerVehiclesBatch(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.',{}) end
    local vehicles=payload and payload.vehicles or {}
    if type(vehicles)~='table' then return result(false,'Lista de veículos inválida.',{}) end

    local ok,msg,data=safeExport(Config.GarageResource,'removeVehicleCatalogEntries',vehicles)
    return {ok=ok==true,message=msg,data=data or {}}
end

function API.saveDealershipVehicle(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg,data=safeExport(
        Config.DealershipResource,
        'saveDealershipVehicle',
        tostring(payload and payload.spawn or ''),
        payload and payload.stock
    )
    return {ok=ok==true,message=msg,data=data}
end

function API.deleteDealershipVehicle(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.DealershipResource,'removeDealershipVehicle',tostring(payload and payload.spawn or ''))
    return result(ok,msg)
end

function API.saveDealershipSettings(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.DealershipResource,'saveDealershipSettings',payload or {})
    return result(ok,msg)
end


-- MANSÕES
function API.getMansions()
    if not hasPermission(source) then return result(false,'Sem permissão.',{}) end
    local data,msg=safeExport(Config.MansionsResource,'getMansions')
    if data==false then return result(false,msg,{}) end
    return result(true,nil,data or {mansions={}})
end

function API.saveMansion(payload)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.MansionsResource,'saveMansion',tostring(payload and payload.originalId or ''),payload and payload.data or {})
    return result(ok,msg)
end

function API.deleteMansion(id)
    if not hasPermission(source) then return result(false,'Sem permissão.') end
    local ok,msg=safeExport(Config.MansionsResource,'removeMansion',tostring(id or ''))
    return result(ok,msg)
end
