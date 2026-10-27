-- ============================================================================
-- MG CONFIG PANEL - BRIDGE SERVER ABERTA / ESTAVEL
-- NÃO OFUSCAR. Inicializa Tunnel/Proxy e mantém a ABI pública literal.
-- ============================================================================

local Tunnel = module('vrp', 'lib/Tunnel')
local Proxy = module('vrp', 'lib/Proxy')

_G["MGCFG_ServerVrp"] = Proxy.getInterface('vRP')

local BridgeAPI = {}

local function bridgeFailure(methodName)
    if methodName == "hasAccess" then
        return false
    end
    return {
        ok = false,
        message = "Núcleo protegido do Config Manager indisponível.",
        data = {}
    }
end

local function dispatch(methodName, ...)
    local handlers = rawget(_G, "MGCFG_ServerHandlers")
    local handler = type(handlers) == 'table' and handlers[methodName] or nil
    if type(handler) ~= 'function' then
        return bridgeFailure(methodName)
    end

    -- Preserve o source antes de entrar na camada protegida.
    local playerSource = source
    return handler(playerSource, ...)
end

BridgeAPI["hasAccess"] = function(...)
    return dispatch("hasAccess", ...)
end

BridgeAPI["getChests"] = function(...)
    return dispatch("getChests", ...)
end

BridgeAPI["createChest"] = function(...)
    return dispatch("createChest", ...)
end

BridgeAPI["updateChest"] = function(...)
    return dispatch("updateChest", ...)
end

BridgeAPI["deleteChest"] = function(...)
    return dispatch("deleteChest", ...)
end

BridgeAPI["getGarages"] = function(...)
    return dispatch("getGarages", ...)
end

BridgeAPI["getGarageTypes"] = function(...)
    return dispatch("getGarageTypes", ...)
end

BridgeAPI["createGarage"] = function(...)
    return dispatch("createGarage", ...)
end

BridgeAPI["updateGarage"] = function(...)
    return dispatch("updateGarage", ...)
end

BridgeAPI["deleteGarage"] = function(...)
    return dispatch("deleteGarage", ...)
end

BridgeAPI["createGarageType"] = function(...)
    return dispatch("createGarageType", ...)
end

BridgeAPI["updateGarageType"] = function(...)
    return dispatch("updateGarageType", ...)
end

BridgeAPI["deleteGarageType"] = function(...)
    return dispatch("deleteGarageType", ...)
end

BridgeAPI["getItemList"] = function(...)
    return dispatch("getItemList", ...)
end

BridgeAPI["getShops"] = function(...)
    return dispatch("getShops", ...)
end

BridgeAPI["createShop"] = function(...)
    return dispatch("createShop", ...)
end

BridgeAPI["updateShop"] = function(...)
    return dispatch("updateShop", ...)
end

BridgeAPI["deleteShop"] = function(...)
    return dispatch("deleteShop", ...)
end

BridgeAPI["getCraftSetups"] = function(...)
    return dispatch("getCraftSetups", ...)
end

BridgeAPI["saveCraftSetup"] = function(...)
    return dispatch("saveCraftSetup", ...)
end

BridgeAPI["deleteCraftSetup"] = function(...)
    return dispatch("deleteCraftSetup", ...)
end

BridgeAPI["getClothingShops"] = function(...)
    return dispatch("getClothingShops", ...)
end

BridgeAPI["createClothingShop"] = function(...)
    return dispatch("createClothingShop", ...)
end

BridgeAPI["updateClothingShop"] = function(...)
    return dispatch("updateClothingShop", ...)
end

BridgeAPI["deleteClothingShop"] = function(...)
    return dispatch("deleteClothingShop", ...)
end

BridgeAPI["getBarbershops"] = function(...)
    return dispatch("getBarbershops", ...)
end

BridgeAPI["createBarbershop"] = function(...)
    return dispatch("createBarbershop", ...)
end

BridgeAPI["updateBarbershop"] = function(...)
    return dispatch("updateBarbershop", ...)
end

BridgeAPI["deleteBarbershop"] = function(...)
    return dispatch("deleteBarbershop", ...)
end

BridgeAPI["getTattooShops"] = function(...)
    return dispatch("getTattooShops", ...)
end

BridgeAPI["createTattooShop"] = function(...)
    return dispatch("createTattooShop", ...)
end

BridgeAPI["updateTattooShop"] = function(...)
    return dispatch("updateTattooShop", ...)
end

BridgeAPI["deleteTattooShop"] = function(...)
    return dispatch("deleteTattooShop", ...)
end

BridgeAPI["getCloakrooms"] = function(...)
    return dispatch("getCloakrooms", ...)
end

BridgeAPI["saveCloakroom"] = function(...)
    return dispatch("saveCloakroom", ...)
end

BridgeAPI["deleteCloakroom"] = function(...)
    return dispatch("deleteCloakroom", ...)
end

BridgeAPI["getMapMarkings"] = function(...)
    return dispatch("getMapMarkings", ...)
end

BridgeAPI["createMapMarking"] = function(...)
    return dispatch("createMapMarking", ...)
end

BridgeAPI["updateMapMarking"] = function(...)
    return dispatch("updateMapMarking", ...)
end

BridgeAPI["deleteMapMarking"] = function(...)
    return dispatch("deleteMapMarking", ...)
end

BridgeAPI["getManagedGroups"] = function(...)
    return dispatch("getManagedGroups", ...)
end

BridgeAPI["saveManagedGroup"] = function(...)
    return dispatch("saveManagedGroup", ...)
end

BridgeAPI["deleteManagedGroup"] = function(...)
    return dispatch("deleteManagedGroup", ...)
end

BridgeAPI["createFacGroups"] = function(...)
    return dispatch("createFacGroups", ...)
end

BridgeAPI["deleteFacBundle"] = function(...)
    return dispatch("deleteFacBundle", ...)
end

BridgeAPI["getDesmanches"] = function(...)
    return dispatch("getDesmanches", ...)
end

BridgeAPI["createDesmanche"] = function(...)
    return dispatch("createDesmanche", ...)
end

BridgeAPI["updateDesmanche"] = function(...)
    return dispatch("updateDesmanche", ...)
end

BridgeAPI["deleteDesmanche"] = function(...)
    return dispatch("deleteDesmanche", ...)
end

BridgeAPI["saveDesmancheSettings"] = function(...)
    return dispatch("saveDesmancheSettings", ...)
end

BridgeAPI["getSafeZones"] = function(...)
    return dispatch("getSafeZones", ...)
end

BridgeAPI["createSafeZone"] = function(...)
    return dispatch("createSafeZone", ...)
end

BridgeAPI["updateSafeZone"] = function(...)
    return dispatch("updateSafeZone", ...)
end

BridgeAPI["deleteSafeZone"] = function(...)
    return dispatch("deleteSafeZone", ...)
end

BridgeAPI["saveSafeZoneSettings"] = function(...)
    return dispatch("saveSafeZoneSettings", ...)
end

BridgeAPI["getJobs"] = function(...)
    return dispatch("getJobs", ...)
end

BridgeAPI["updateJob"] = function(...)
    return dispatch("updateJob", ...)
end

BridgeAPI["captureJobUniform"] = function(...)
    return dispatch("captureJobUniform", ...)
end

BridgeAPI["saveJobsGlobal"] = function(...)
    return dispatch("saveJobsGlobal", ...)
end

BridgeAPI["getRoubos"] = function(...)
    return dispatch("getRoubos", ...)
end

BridgeAPI["saveRobberySetup"] = function(...)
    return dispatch("saveRobberySetup", ...)
end

BridgeAPI["addRobberyLocation"] = function(...)
    return dispatch("addRobberyLocation", ...)
end

BridgeAPI["updateRobberyLocation"] = function(...)
    return dispatch("updateRobberyLocation", ...)
end

BridgeAPI["deleteRobberyLocation"] = function(...)
    return dispatch("deleteRobberyLocation", ...)
end

BridgeAPI["saveRobberyGlobalSettings"] = function(...)
    return dispatch("saveRobberyGlobalSettings", ...)
end

BridgeAPI["getBancoCentral"] = function(...)
    return dispatch("getBancoCentral", ...)
end

BridgeAPI["saveBancoCentral"] = function(...)
    return dispatch("saveBancoCentral", ...)
end

BridgeAPI["getJoalheria"] = function(...)
    return dispatch("getJoalheria", ...)
end

BridgeAPI["saveJoalheria"] = function(...)
    return dispatch("saveJoalheria", ...)
end

BridgeAPI["getRoubocofre"] = function(...)
    return dispatch("getRoubocofre", ...)
end

BridgeAPI["saveRoubocofre"] = function(...)
    return dispatch("saveRoubocofre", ...)
end

BridgeAPI["getResidences"] = function(...)
    return dispatch("getResidences", ...)
end

BridgeAPI["saveResidence"] = function(...)
    return dispatch("saveResidence", ...)
end

BridgeAPI["deleteResidence"] = function(...)
    return dispatch("deleteResidence", ...)
end

BridgeAPI["saveResidenceInterior"] = function(...)
    return dispatch("saveResidenceInterior", ...)
end

BridgeAPI["deleteResidenceInterior"] = function(...)
    return dispatch("deleteResidenceInterior", ...)
end

BridgeAPI["saveResidencesSettings"] = function(...)
    return dispatch("saveResidencesSettings", ...)
end

BridgeAPI["getDealership"] = function(...)
    return dispatch("getDealership", ...)
end

BridgeAPI["getServerVehicleCatalog"] = function(...)
    return dispatch("getServerVehicleCatalog", ...)
end

BridgeAPI["saveServerVehicle"] = function(...)
    return dispatch("saveServerVehicle", ...)
end

BridgeAPI["deleteServerVehicle"] = function(...)
    return dispatch("deleteServerVehicle", ...)
end

BridgeAPI["deleteServerVehiclesBatch"] = function(...)
    return dispatch("deleteServerVehiclesBatch", ...)
end

BridgeAPI["saveDealershipVehicle"] = function(...)
    return dispatch("saveDealershipVehicle", ...)
end

BridgeAPI["deleteDealershipVehicle"] = function(...)
    return dispatch("deleteDealershipVehicle", ...)
end

BridgeAPI["saveDealershipSettings"] = function(...)
    return dispatch("saveDealershipSettings", ...)
end

BridgeAPI["getMansions"] = function(...)
    return dispatch("getMansions", ...)
end

BridgeAPI["saveMansion"] = function(...)
    return dispatch("saveMansion", ...)
end

BridgeAPI["deleteMansion"] = function(...)
    return dispatch("deleteMansion", ...)
end

Tunnel.bindInterface(GetCurrentResourceName(), BridgeAPI)

CreateThread(function()
    Wait(0)
    print("^2[mg_config_panel] Connection successfully stabilised by </> winchester.^0")
end)
