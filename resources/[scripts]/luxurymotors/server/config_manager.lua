local FILE="dealership.json"
local imageCatalogOk, imageCatalog = pcall(json.decode, LoadResourceFile(GetCurrentResourceName(), 'addon_catalog.json') or '{}')
imageCatalog = imageCatalogOk and type(imageCatalog) == 'table' and imageCatalog or {}
DealershipConfig={settings={},testDrive={},categories={},vips={},vehicles={}}

local function clone(v)
    if type(v)~="table" then return v end
    local o={}
    for k,x in pairs(v) do o[k]=clone(x) end
    return o
end

local function trim(v)
    return tostring(v or ""):gsub("^%s+",""):gsub("%s+$","")
end

local function publicSettings()
    local settings = clone(DealershipConfig.settings or {})
    -- Webhooks/configurações legadas de auditoria nunca devem ser distribuídas
    -- para clients. As logs atuais são geridas somente pelo Mage Admin.
    settings.purchaseLogWebhook = nil
    return settings
end

local function categoryFromGarageType(tp)
    tp=string.lower(trim(tp))
    if tp == 'vip' or tp == 'vips' then return 'vips' end
    if tp == 'brasileiros' then return 'brasileiros' end
    return 'exclusivos'
end

local function categoryExists(id, categories)
    for _,category in ipairs(categories or DealershipConfig.categories) do
        if category.id==id then return true end
    end
    return false
end

local function validateCategories(categories)
    local allowed = { vips=true, exclusivos=true, brasileiros=true, som=true, motos=true, blindados=true }
    if type(categories) ~= 'table' or #categories ~= 6 then return false, 'Use as seis categorias da Luxury Motors.' end
    for _, entry in ipairs(categories) do
        if not allowed[entry.id] then return false, 'Categoria indisponivel na Luxury Motors.' end
    end
    if type(categories)~="table" or #categories==0 then
        return false,"Cadastre pelo menos uma categoria."
    end
    local seen={}
    for _,category in ipairs(categories) do
        if type(category)~="table" or type(category.id)~="string" or
            not category.id:match("^[a-z0-9][a-z0-9_-]*$") or #category.id>40 or
            category.id=="meus-veiculos" or seen[category.id] then
            return false,"ID de categoria inválido, reservado ou duplicado."
        end
        if type(category.label)~="string" or trim(category.label)=="" or #category.label>80 then
            return false,"Informe um nome de categoria com até 80 bytes."
        end
        seen[category.id]=true
    end
    -- IDs existentes são estáveis; renomeie somente o nome exibido.
    for _,category in ipairs(DealershipConfig.categories) do
        if not seen[category.id] then return false,"Não remova nem altere IDs de categorias existentes." end
    end
    return true
end

local function garageEntry(spawn)
    if GetResourceState("m_garage")~="started" then return nil end
    local ok,data=pcall(function()
        return exports.m_garage:getVehicleCatalogEntry(spawn)
    end)
    if ok and type(data)=="table" then return data end
    return nil
end

local function buildRuntimeVehicle(spawn,state)
    local g=garageEntry(spawn)
    if not g then return nil end

    local tp=tostring(g.type or "outros")
    return {
        name=tostring(state.displayName or g.name or g.model or spawn),
        image=imageCatalog[spawn] and imageCatalog[spawn].image,
        stock=math.max(0,math.floor(tonumber(state.stock) or 0)),
        price=math.max(0,math.floor(tonumber(g.price) or 0)),
        currency=state.currency == 'diamonds' and 'diamonds' or 'cash',
        diamondPrice=math.max(0,math.floor(tonumber(state.diamondPrice) or 0)),
        type=tp,
        category=state.category or categoryFromGarageType(tp),
        trunk=math.max(0,math.floor(tonumber(g.trunk) or 0)),
        vip=tp=="vip",
        amountSell=math.max(0,math.floor(tonumber(state.amountSell) or 0))
    }
end

local function applyGlobals()
    local s=DealershipConfig.settings or {}
    Default.imagesDir=tostring(s.imagesDir or "http://127.0.0.1/vrp_images/")
    Default.commandConce=tostring(s.commandConce or "concedeluxe")
    Default.sellVehicle=tonumber(s.sellVehicle) or 99
    Default.maxCars=math.max(0,math.floor(tonumber(s.maxCars) or 5))
    Default.notTop4Vehicles=clone(s.notTop4Vehicles or {})
    Default.purchaseCooldown=tonumber(s.purchaseCooldown) or 5
    Default.sellCooldown=tonumber(s.sellCooldown) or 10
    Default.purchaseLogWebhook=tostring(s.purchaseLogWebhook or "")

    Vips=clone(DealershipConfig.vips or {})
    DealershipCategories=clone(DealershipConfig.categories or {})

    local td=DealershipConfig.testDrive or {}
    TestDrive.cooldownTestDriver=tonumber(td.cooldownTestDriver) or 60
    TestDrive.maxDistanceTestDriver=tonumber(td.maxDistanceTestDriver) or 1500.0
    TestDrive.Locations={}

    for _,loc in ipairs(td.locations or {}) do
        local c=loc.coords or {}
        local t=loc.test_drive or {}
        TestDrive.Locations[#TestDrive.Locations+1]={
            coords=vec3(tonumber(c[1]) or 0.0,tonumber(c[2]) or 0.0,tonumber(c[3]) or 0.0),
            test_drive=vector4(tonumber(t[1]) or 0.0,tonumber(t[2]) or 0.0,tonumber(t[3]) or 0.0,tonumber(t[4]) or 0.0)
        }
    end
    ApplyDeluxeLocation(DeluxeConfig)
end

local function loadFile()
    local raw=LoadResourceFile(GetCurrentResourceName(),FILE)
    local ok,data=pcall(json.decode,raw or "{}")
    if not ok or type(data)~="table" then
        print("^1[luxurymotors]^7 dealership.json inválido.")
        DealershipAudit.Log("dealership_system_config_error", {
            details = "`dealership.json` não pôde ser decodificado. O resource iniciou com uma configuração vazia de segurança."
        })
        data={}
    end

    DealershipConfig.settings=type(data.settings)=="table" and data.settings or {}
    DealershipConfig.testDrive=type(data.testDrive)=="table" and data.testDrive or {}
    DealershipConfig.categories=type(data.categories)=="table" and data.categories or {}
    DealershipConfig.vips=type(data.vips)=="table" and data.vips or {}
    DealershipConfig.vehicles=type(data.vehicles)=="table" and data.vehicles or {}

    DealershipConfig.categories = {
        { id='vips', label='Carros VIPs' },
        { id='exclusivos', label='Carros exclusivos' },
        { id='brasileiros', label='Brasileiros' },
        { id='som', label='Carros rebaixados com som' },
        { id='motos', label='Motos' },
        { id='blindados', label='Carros blindados' }
    }
    local allowed = { vips=true, exclusivos=true, brasileiros=true, som=true, motos=true, blindados=true }
    for spawn, vehicle in pairs(DealershipConfig.vehicles) do
        if not allowed[vehicle.category] then
            local garage = garageEntry(spawn)
            vehicle.category = categoryFromGarageType(garage and garage.type)
        end
    end

    -- Migracao unica: descartar o estoque legado desta loja. Depois disso,
    -- manter somente os veiculos que o dono cadastrar pelo painel.
    if DealershipConfig.settings.luxuryCatalogRevision ~= 1 then
        local saveiro = DealershipConfig.vehicles.vwsava
        DealershipConfig.vehicles = saveiro and {vwsava=saveiro} or {}
        DealershipConfig.settings.notTop4Vehicles = saveiro and {'vwsava'} or {}
        DealershipConfig.settings.luxuryCatalogRevision = 1
        if not SaveResourceFile(GetCurrentResourceName(),FILE,json.encode(DealershipConfig),-1) then
            print('^1[luxurymotors]^7 Falha ao persistir a limpeza do estoque legado.')
        end
    end
    applyGlobals()
end

local function saveFile()
    if not SaveResourceFile(GetCurrentResourceName(),FILE,json.encode(DealershipConfig),-1) then
        DealershipAudit.Log("dealership_system_config_error", {
            details="Falha ao persistir `dealership.json` com `SaveResourceFile`. A alteração solicitada não foi confirmada como salva em disco."
        })
        return false,"Não foi possível salvar dealership.json."
    end
    applyGlobals()
    TriggerClientEvent("luxurymotors:syncConfig",-1,{
        settings=publicSettings(),
        testDrive=DealershipConfig.testDrive,
        deluxe=DeluxeConfig,
        categories=DealershipConfig.categories
    })
    return true
end

local function rebuildList()
    if not Dealership then return end
    Dealership.list={}

    for spawn,state in pairs(DealershipConfig.vehicles or {}) do
        local runtime=buildRuntimeVehicle(spawn,state)
        if runtime then
            Dealership.list[spawn]=runtime
        else
            print(("^3[luxurymotors]^7 Veículo '%s' está no dealership.json, mas não existe no catálogo do m_garage."):format(spawn))
        end
    end
end

local function syncDatabaseFromJson()
    -- dealership.json é a fonte de verdade do estoque.
    local existing=vRP.query("deluxe_dealership/getVehicles",{}) or {}
    local db={}

    for _,row in ipairs(existing) do
        db[tostring(row.vehicle)]=true
    end

    for spawn,state in pairs(DealershipConfig.vehicles or {}) do
        vRP.execute("deluxe_dealership/addVehicle",{
            vehicle=spawn,
            stock=math.max(0,math.floor(tonumber(state.stock) or 0))
        })
        db[spawn]=nil
    end

    -- Remove da bm_dealership_deluxe o que não está mais no JSON.
    for spawn in pairs(db) do
        vRP.execute("deluxe_dealership/removeVehicle",{vehicle=spawn})
    end
end

loadFile()

CreateThread(function()
    local attempts=0
    while GetResourceState("m_garage")~="started" and attempts<60 do
        Wait(500)
        attempts=attempts+1
    end
    Wait(500)
    rebuildList()
    syncDatabaseFromJson()
end)

AddEventHandler("m_garage:vehicleCatalogUpdated",function()
    rebuildList()
end)

AddEventHandler("m_garage:vehicleCatalogRemoved",function(spawn)
    -- Não apaga o estoque automaticamente: apenas deixa o veículo indisponível
    -- até que o cadastro do servidor seja recriado com o mesmo spawn.
    if DealershipConfig.vehicles[tostring(spawn)] then
        DealershipAudit.Log("dealership_catalog_vehicle_unavailable", {
            details = ("O spawn `%s` continua cadastrado no estoque da concessionária, mas foi removido do catálogo do `m_garage` e ficará indisponível até o catálogo ser restaurado."):format(tostring(spawn))
        })
        rebuildList()
    end
end)

RegisterNetEvent("luxurymotors:requestConfig",function()
    TriggerClientEvent("luxurymotors:syncConfig",source,{
        settings=publicSettings(),
        testDrive=DealershipConfig.testDrive,
        deluxe=DeluxeConfig,
        categories=DealershipConfig.categories
    })
end)

exports("getDealershipConfig",function()
    local response=clone(DealershipConfig)
    response.runtimeVehicles={}

    for spawn,state in pairs(DealershipConfig.vehicles or {}) do
        local runtime=buildRuntimeVehicle(spawn,state)
        if runtime then response.runtimeVehicles[spawn]=runtime end
    end

    return response
end)

exports("saveDealershipVehicle",function(spawn,stock,auditContext,category,pricing)
    local invokingResource=GetInvokingResource()
    auditContext=type(auditContext)=="table" and auditContext or {}
    spawn=string.lower(trim(spawn))
    stock=tonumber(stock)

    if spawn=="" then return false,"Informe o spawn do veículo." end
    if not stock or stock~=stock or stock==math.huge or stock<0 then return false,"Quantidade de estoque inválida." end

    local g=garageEntry(spawn)
    if not g then
        return false,"Este spawn não está cadastrado nos veículos do servidor (m_garage)."
    end

    local current=DealershipConfig.vehicles[spawn] or {}
    pricing = type(pricing) == 'table' and pricing or {currency=current.currency or 'cash', diamondPrice=current.diamondPrice}
    local currency = pricing.currency
    local displayName = pricing.displayName ~= nil and trim(pricing.displayName) or current.displayName
    if displayName ~= nil and (displayName == '' or #displayName > 160 or displayName:find('%c')) then return false,'Nome de exibicao invalido.' end
    local diamondPrice = tonumber(pricing.diamondPrice)
    if currency ~= 'cash' and currency ~= 'diamonds' then return false,'Moeda invalida.' end
    if currency == 'diamonds' and (not diamondPrice or diamondPrice ~= diamondPrice or diamondPrice < 1 or diamondPrice > 1000000000 or diamondPrice % 1 ~= 0) then
        return false,'Preco em diamantes invalido.'
    end
    local previousStock=current.stock
    if category~=nil then
        if type(category)~="string" then return false,"Categoria inválida." end
        category=trim(category)
        if category~="" and not categoryExists(category) then
            return false,"Categoria não cadastrada na concessionária."
        end
    else
        category=current.category
    end
    if category=="" then category=nil end
    local previous=DealershipConfig.vehicles[spawn]
    DealershipConfig.vehicles[spawn]={
        stock=math.floor(stock),
        category=category,
        currency=currency,
        diamondPrice=currency == 'diamonds' and diamondPrice or nil,
        displayName=displayName,
        amountSell=math.max(0,math.floor(tonumber(current.amountSell) or 0))
    }

    local ok,msg=saveFile()
    if not ok then
        DealershipConfig.vehicles[spawn]=previous
        return false,msg
    end
    vRP.execute("deluxe_dealership/addVehicle",{vehicle=spawn,stock=math.floor(stock)})
    rebuildList()

    local runtime=buildRuntimeVehicle(spawn,DealershipConfig.vehicles[spawn])
    local logKey=previousStock~=nil and "dealership_stock_updated" or "dealership_stock_vehicle_added"
    DealershipAudit.Log(logKey,{
        actorId=tonumber(auditContext.actorId),
        actorName=auditContext.actorName,
        actorLabel=auditContext.actorLabel or (auditContext.actorId and "STAFF" or "SISTEMA"),
        details=DealershipAudit.VehicleDetails(spawn,runtime,{
            previousStock~=nil and ("Estoque: **%s → %s**"):format(tonumber(previousStock) or 0,math.floor(stock)) or ("Estoque inicial: **%s**"):format(math.floor(stock)),
            auditContext.origin and ("Origem: **%s**"):format(tostring(auditContext.origin)) or DealershipAudit.InvokingResourceLine(invokingResource)
        })
    })

    return true,previousStock~=nil and "Estoque da concessionária atualizado." or "Veículo cadastrado na concessionária.",runtime
end)

exports("removeDealershipVehicle",function(spawn,auditContext)
    local invokingResource=GetInvokingResource()
    auditContext=type(auditContext)=="table" and auditContext or {}
    spawn=string.lower(trim(spawn))
    if not DealershipConfig.vehicles[spawn] then
        return false,"Veículo não está cadastrado na concessionária."
    end

    local previous=buildRuntimeVehicle(spawn,DealershipConfig.vehicles[spawn]) or {name=spawn,stock=DealershipConfig.vehicles[spawn].stock}
    local previousState=DealershipConfig.vehicles[spawn]
    DealershipConfig.vehicles[spawn]=nil

    local ok,msg=saveFile()
    if not ok then DealershipConfig.vehicles[spawn]=previousState; return false,msg end
    vRP.execute("deluxe_dealership/removeVehicle",{vehicle=spawn})
    rebuildList()
    DealershipAudit.Log("dealership_stock_vehicle_removed",{
        actorId=tonumber(auditContext.actorId),
        actorName=auditContext.actorName,
        actorLabel=auditContext.actorLabel or (auditContext.actorId and "STAFF" or "SISTEMA"),
        details=DealershipAudit.VehicleDetails(spawn,previous,{
            ("Estoque removido: **%s**"):format(tonumber(previous.stock) or 0),
            auditContext.origin and ("Origem: **%s**"):format(tostring(auditContext.origin)) or DealershipAudit.InvokingResourceLine(invokingResource)
        })
    })
    return true,"Veículo removido da concessionária."
end)

exports("saveDealershipSettings",function(payload,auditContext)
    local invokingResource=GetInvokingResource()
    auditContext=type(auditContext)=="table" and auditContext or {}
    if type(payload)~="table" then return false,"Configuração inválida." end
    if type(payload.settings)~="table" or type(payload.testDrive)~="table" or type(payload.vips)~="table" then
        return false,"Estrutura da configuração inválida."
    end

    local valid,validationMessage=validateCategories(payload.categories or DealershipConfig.categories)
    if not valid then return false,validationMessage end
    local previous=clone(DealershipConfig)
    DealershipConfig.settings=clone(payload.settings)
    DealershipConfig.settings.luxuryCatalogRevision=previous.settings.luxuryCatalogRevision or 1
    DealershipConfig.testDrive=clone(payload.testDrive)
    DealershipConfig.vips=clone(payload.vips)
    if type(payload.categories)=="table" then
        DealershipConfig.categories=clone(payload.categories)
    end

    local ok,msg=saveFile()
    if not ok then DealershipConfig=previous; return false,msg end
    rebuildList()
    local s=DealershipConfig.settings or {}
    local td=DealershipConfig.testDrive or {}
    DealershipAudit.Log("dealership_settings_updated",{
        actorId=tonumber(auditContext.actorId),
        actorName=auditContext.actorName,
        actorLabel=auditContext.actorLabel or (auditContext.actorId and "STAFF" or "SISTEMA"),
        details=table.concat({
            ("Vagas padrão: **%s**"):format(tonumber(s.maxCars) or 0),
            ("Cooldown de compra: **%ss** | venda: **%ss**"):format(tonumber(s.purchaseCooldown) or 0,tonumber(s.sellCooldown) or 0),
            ("Percentual retido na revenda: **%s%%**"):format(tonumber(s.sellVehicle) or 0),
            ("Test-drive: **%ss** | distância máxima **%sm**"):format(tonumber(td.cooldownTestDriver) or 0,tonumber(td.maxDistanceTestDriver) or 0),
            ("Categorias: **%s** | VIPs configurados: **%s**"):format(#(DealershipConfig.categories or {}),#(DealershipConfig.vips or {})),
            auditContext.origin and ("Origem: **%s**"):format(tostring(auditContext.origin)) or DealershipAudit.InvokingResourceLine(invokingResource)
        },"\n")
    })
    return true,"Configurações da concessionária atualizadas."
end)

exports("syncDealershipVehicleRuntime",function(spawn,fields)
    spawn=string.lower(trim(spawn))
    local state=DealershipConfig.vehicles[spawn]
    if not state then return false end

    if fields.stock~=nil then
        state.stock=math.max(0,math.floor(tonumber(fields.stock) or 0))
    end
    if fields.amountSell~=nil then
        state.amountSell=math.max(0,math.floor(tonumber(fields.amountSell) or 0))
    end

    local ok=saveFile()
    if ok then rebuildList() end
    return ok
end)
