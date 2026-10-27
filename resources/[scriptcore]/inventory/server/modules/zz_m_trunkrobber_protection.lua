-- m_trunkrobber v1.15 - proteção temporária do rastreador roubado
--
-- Este arquivo NÃO substitui nenhum módulo do seu inventory.
-- Basta colocá-lo em: inventory/server/modules/zz_m_trunkrobber_protection.lua
-- O fxmanifest do inventory já carrega server/modules/** automaticamente.

local function protectedItemError()
    return {
        error = "Você não pode descartar, guardar ou enviar este rastreador enquanto estiver sendo rastreado."
    }
end

local function isProtected(user_id, source, item)
    if not user_id or not source or not item then return false end
    if GetResourceState("m_robbernpc") ~= "started" then return false end

    local ok, result = pcall(function()
        return exports["m_robbernpc"]:isProtectedRadarItem(user_id, source, item)
    end)

    return ok and result == true
end

local function getSlotItem(user_id, slot)
    if not user_id or not slot then return nil end
    return vRP.getSlotItem(user_id, slot)
end

-- Os módulos originais do inventory são carregados no startup. Esperamos um
-- instante e envolvemos apenas as funções que conseguem tirar o item da mochila.
CreateThread(function()
    Wait(1000)

    if type(API) ~= "table" then
        print("^1[m_trunkrobber/inventory]^7 API do inventory não encontrada; proteção do rastreador não foi aplicada.")
        return
    end

    if type(API.dropItem) == "function" then
        local originalDropItem = API.dropItem
        API.dropItem = function(slot, amount)
            local src = source
            local user_id = vRP.getUserId(src)
            local slot_data = getSlotItem(user_id, slot)

            if slot_data and isProtected(user_id, src, slot_data.item) then
                return protectedItemError()
            end

            return originalDropItem(slot, amount)
        end
    end

    if type(API.sendItem) == "function" then
        local originalSendItem = API.sendItem
        API.sendItem = function(slot, amount)
            local src = source
            local user_id = vRP.getUserId(src)
            local slot_data = getSlotItem(user_id, slot)

            if slot_data and isProtected(user_id, src, slot_data.item) then
                return protectedItemError()
            end

            return originalSendItem(slot, amount)
        end
    end

    if type(API.storeChestItem) == "function" then
        local originalStoreChestItem = API.storeChestItem
        API.storeChestItem = function(slot, amount)
            local src = source
            local user_id = vRP.getUserId(src)
            local slot_data = getSlotItem(user_id, slot)

            if slot_data and isProtected(user_id, src, slot_data.item) then
                return protectedItemError()
            end

            return originalStoreChestItem(slot, amount)
        end
    end

    if type(API.putInspectItem) == "function" then
        local originalPutInspectItem = API.putInspectItem
        API.putInspectItem = function(from_slot, to_slot, amount)
            local src = source
            local user_id = vRP.getUserId(src)
            local slot_data = getSlotItem(user_id, from_slot)

            if slot_data and isProtected(user_id, src, slot_data.item) then
                return protectedItemError()
            end

            return originalPutInspectItem(from_slot, to_slot, amount)
        end
    end

    print("^2[m_trunkrobber/inventory]^7 Proteção temporária do rastreador carregada.")
end)
