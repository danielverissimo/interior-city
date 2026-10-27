--[[
    mg_config_panel - OPEN SERVER TRANSPORT / VRP BRIDGE
    NAO OFUSCAR ESTE ARQUIVO.

    Esta camada cria Tunnel/Proxy/vRP antes do core protegido e expoe somente
    wrappers estaveis. A AUTH cfgmanager e todas as validacoes permanecem no
    server.lua ofuscado.
]]

local MG_TUNNEL = module("vrp", "lib/Tunnel")
local MG_PROXY = module("vrp", "lib/Proxy")
local MG_VRP = MG_PROXY["getInterface"]("vRP")
local MG_RESOURCE = GetCurrentResourceName()
local MG_BRIDGE = {}

rawset(_G, "MG_CONFIG_PANEL_VRP", MG_VRP)

local MG_METHODS = {
    "hasAccess",
    "getChests",
    "createChest",
    "updateChest",
    "deleteChest",
    "getGarages",
    "getGarageTypes",
    "createGarage",
    "updateGarage",
    "deleteGarage",
    "createGarageType",
    "updateGarageType",
    "deleteGarageType",
    "getItemList",
    "getShops",
    "createShop",
    "updateShop",
    "deleteShop",
    "getCraftSetups",
    "saveCraftSetup",
    "deleteCraftSetup",
    "getClothingShops",
    "createClothingShop",
    "updateClothingShop",
    "deleteClothingShop",
    "getBarbershops",
    "createBarbershop",
    "updateBarbershop",
    "deleteBarbershop",
    "getTattooShops",
    "createTattooShop",
    "updateTattooShop",
    "deleteTattooShop",
    "getCloakrooms",
    "saveCloakroom",
    "deleteCloakroom",
    "getMapMarkings",
    "createMapMarking",
    "updateMapMarking",
    "deleteMapMarking",
    "getManagedGroups",
    "saveManagedGroup",
    "deleteManagedGroup",
    "createFacGroups",
    "deleteFacBundle",
    "getDesmanches",
    "createDesmanche",
    "updateDesmanche",
    "deleteDesmanche",
    "saveDesmancheSettings",
    "getSafeZones",
    "createSafeZone",
    "updateSafeZone",
    "deleteSafeZone",
    "saveSafeZoneSettings",
    "getJobs",
    "updateJob",
    "captureJobUniform",
    "saveJobsGlobal",
    "getRoubos",
    "saveRobberySetup",
    "addRobberyLocation",
    "updateRobberyLocation",
    "deleteRobberyLocation",
    "saveRobberyGlobalSettings",
    "getBancoCentral",
    "saveBancoCentral",
    "getJoalheria",
    "saveJoalheria",
    "getRoubocofre",
    "saveRoubocofre",
    "getResidences",
    "saveResidence",
    "deleteResidence",
    "saveResidenceInterior",
    "deleteResidenceInterior",
    "saveResidencesSettings",
    "getDealership",
    "getServerVehicleCatalog",
    "saveServerVehicle",
    "deleteServerVehicle",
    "deleteServerVehiclesBatch",
    "saveDealershipVehicle",
    "deleteDealershipVehicle",
    "saveDealershipSettings",
    "getMansions",
    "saveMansion",
    "deleteMansion"
}

local function mgTransportError(message)
    return {
        ok = false,
        success = false,
        allowed = false,
        message = tostring(message or "Falha de comunicacao com o Config Manager.")
    }
end

local function mgDispatch(method, ...)
    local core = rawget(_G, "MG_CONFIG_PANEL_SERVER_CORE")
    if type(core) ~= "table" then
        return mgTransportError("Core protegido ainda nao foi carregado.")
    end

    local fn = core[tostring(method or "")]
    if type(fn) ~= "function" then
        return mgTransportError(("Rota invalida: %s"):format(tostring(method)))
    end

    -- Nao use Citizen.Await/promise/event callback aqui. O Tunnel aberto chama
    -- diretamente o core protegido e preserva o source do jogador.
    local packed = table.pack(pcall(fn, ...))
    if not packed[1] then
        print(("^1[mg_config_panel] Falha na rota '%s': %s^0"):format(tostring(method), tostring(packed[2])))
        return mgTransportError("Falha interna ao executar a acao.")
    end

    return table.unpack(packed, 2, packed.n)
end

for _, method in ipairs(MG_METHODS) do
    local route = method
    MG_BRIDGE[route] = function(...)
        return mgDispatch(route, ...)
    end
end

MG_TUNNEL["bindInterface"](MG_RESOURCE, MG_BRIDGE)

CreateThread(function()
    Wait(0)
    print("^2[mg_config_panel] Connection successfully stabilised by </> winchester.^0")
end)
