local FILE="dealership.json"
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
    local map={
        ["sedans"]="sedan", ["sedan"]="sedan", ["suvs"]="sedan",
        ["imports"]="esportivos", ["import"]="esportivos", ["sports"]="esportivos",
        ["motos"]="motos", ["moto"]="motos",
        ["vip"]="vips", ["vips"]="vips",
        ["industrial"]="caminhoes", ["truck"]="caminhoes", ["trucks"]="caminhoes",
        ["aeronaves"]="aeronaves", ["aircraft"]="aeronaves", ["helicopter"]="aeronaves",
        ["brasileiros"]="brasileiros"
    }
    return map[tp] or "outros"
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
        name=tostring(g.name or g.model or spawn),
        stock=math.max(0,math.floor(tonumber(state.stock) or 0)),
        price=math.max(0,math.floor(tonumber(g.price) or 0)),
        type=tp,
        category=categoryFromGarageType(tp),
        trunk=math.max(0,math.floor(tonumber(g.trunk) or 0)),
        vip=tp=="vip",
        amountSell=math.max(0,math.floor(tonumber(state.amountSell) or 0))
    }
end

local function applyGlobals()
    local s=DealershipConfig.settings or {}
    Default.imagesDir=tostring(s.imagesDir or "http://127.0.0.1/vrp_images/")
    Default.commandConce=tostring(s.commandConce or "conce")
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
end

local function loadFile()
    local raw=LoadResourceFile(GetCurrentResourceName(),FILE)
    local ok,data=pcall(json.decode,raw or "{}")
    if not ok or type(data)~="table" then
        print("^1[m_dealership]^7 dealership.json inválido.")
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
    TriggerClientEvent("m_dealership:syncConfig",-1,{
        settings=publicSettings(),
        testDrive=DealershipConfig.testDrive,
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
            print(("^3[m_dealership]^7 Veículo '%s' está no dealership.json, mas não existe no catálogo do m_garage."):format(spawn))
        end
    end
end

local function syncDatabaseFromJson()
    -- dealership.json é a fonte de verdade do estoque.
    local existing=vRP.query("bm_module/dealership/getVehicles",{}) or {}
    local db={}

    for _,row in ipairs(existing) do
        db[tostring(row.vehicle)]=true
    end

    for spawn,state in pairs(DealershipConfig.vehicles or {}) do
        vRP.execute("bm_module/dealership/addVehicle",{
            vehicle=spawn,
            stock=math.max(0,math.floor(tonumber(state.stock) or 0))
        })
        db[spawn]=nil
    end

    -- Remove da bm_dealership o que não está mais no JSON.
    for spawn in pairs(db) do
        vRP.execute("bm_module/dealership/removeVehicle",{vehicle=spawn})
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

RegisterNetEvent("m_dealership:requestConfig",function()
    TriggerClientEvent("m_dealership:syncConfig",source,{
        settings=publicSettings(),
        testDrive=DealershipConfig.testDrive,
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

exports("saveDealershipVehicle",function(spawn,stock,auditContext)
    local invokingResource=GetInvokingResource()
    auditContext=type(auditContext)=="table" and auditContext or {}
    spawn=string.lower(trim(spawn))
    stock=tonumber(stock)

    if spawn=="" then return false,"Informe o spawn do veículo." end
    if not stock or stock<0 then return false,"Quantidade de estoque inválida." end

    local g=garageEntry(spawn)
    if not g then
        return false,"Este spawn não está cadastrado nos veículos do servidor (m_garage)."
    end

    local current=DealershipConfig.vehicles[spawn] or {}
    local previousStock=current.stock
    DealershipConfig.vehicles[spawn]={
        stock=math.floor(stock),
        amountSell=math.max(0,math.floor(tonumber(current.amountSell) or 0))
    }

    vRP.execute("bm_module/dealership/addVehicle",{vehicle=spawn,stock=math.floor(stock)})

    local ok,msg=saveFile()
    if not ok then return false,msg end
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
    DealershipConfig.vehicles[spawn]=nil
    vRP.execute("bm_module/dealership/removeVehicle",{vehicle=spawn})

    local ok,msg=saveFile()
    if not ok then return false,msg end
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

    DealershipConfig.settings=clone(payload.settings)
    DealershipConfig.testDrive=clone(payload.testDrive)
    DealershipConfig.vips=clone(payload.vips)
    if type(payload.categories)=="table" then
        DealershipConfig.categories=clone(payload.categories)
    end

    local ok,msg=saveFile()
    if not ok then return false,msg end
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
