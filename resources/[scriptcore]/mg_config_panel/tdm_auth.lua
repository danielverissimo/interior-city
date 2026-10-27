-- Toca do Mago - AUTH Client v2 (server-side FiveM)
-- Este arquivo é genérico e NÃO precisa ser alterado de produto para produto.

local AUTH_ENDPOINT = "http://104.234.65.115/auth.php"

local AUTH = {
    initialized = false,
    authorized = false,
    ready = false,
    serverName = nil,
    productName = nil,
    productIndex = nil,
    lastReason = "not_initialized"
}

local function encodeQuery(value)
    return tostring(value):gsub("([^%w%-_%.~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
end

local function normalizeIndex(value)
    value = tostring(value or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if not value:match("^[a-z0-9][a-z0-9_%-]+$") or #value < 2 or #value > 32 then
        return nil
    end
    return value
end

local function setAuthState(authorized, reason, serverName, productName)
    AUTH.authorized = authorized == true
    AUTH.ready = true
    AUTH.lastReason = reason or (AUTH.authorized and "authorized" or "unknown")
    AUTH.serverName = serverName
    AUTH.productName = productName or AUTH.productIndex
end

local function checkAuthentication(silent)
    if not AUTH.initialized or not AUTH.productIndex then return end

    local url = AUTH_ENDPOINT .. "?index=" .. encodeQuery(AUTH.productIndex)

    PerformHttpRequest(url, function(statusCode, body, headers)
        if statusCode ~= 200 or not body or body == "" then
            local wasAuthorized = AUTH.authorized
            setAuthState(false, "http_" .. tostring(statusCode))
            if not silent or wasAuthorized then
                print(("^1[Toca do Mago] AUTH indisponível para [%s]. HTTP: %s^0"):format(AUTH.productIndex, tostring(statusCode)))
            end
            return
        end

        local ok, data = pcall(json.decode, body)
        if not ok or type(data) ~= "table" then
            local wasAuthorized = AUTH.authorized
            setAuthState(false, "invalid_response")
            if not silent or wasAuthorized then
                print(("^1[Toca do Mago] Resposta inválida da AUTH para [%s].^0"):format(AUTH.productIndex))
            end
            return
        end

        if data.authorized == true then
            local serverName = data.server and data.server.name or "Servidor autorizado"
            local productName = data.product and data.product.name or AUTH.productIndex
            local wasAuthorized = AUTH.authorized
            setAuthState(true, "authorized", serverName, productName)

            if not silent or not wasAuthorized then
                print(("^2[Toca do Mago] %s [%s] autenticado com sucesso para: %s^0"):format(productName, AUTH.productIndex, serverName))
            end
        else
            local wasAuthorized = AUTH.authorized
            setAuthState(false, data.reason or "not_authorized")

            if not silent or wasAuthorized then
                print(("^1[Toca do Mago] Script [%s] NÃO autenticado. Motivo: %s^0"):format(AUTH.productIndex, AUTH.lastReason))
            end
        end
    end, "GET", "", {
        ["Accept"] = "application/json",
        ["User-Agent"] = "TDM-FiveM-Auth/2"
    })
end

-- Chame UMA VEZ no server.lua do produto:
-- TDMAuthInit("padmv5")
function TDMAuthInit(productIndex)
    if AUTH.initialized then
        if AUTH.productIndex ~= normalizeIndex(productIndex) then
            print(("^1[Toca do Mago] TDMAuthInit já foi iniciado para [%s].^0"):format(tostring(AUTH.productIndex)))
        end
        return AUTH.productIndex ~= nil
    end

    local normalized = normalizeIndex(productIndex)
    if not normalized then
        AUTH.initialized = true
        AUTH.ready = true
        AUTH.authorized = false
        AUTH.lastReason = "invalid_product_index"
        print("^1[Toca do Mago] PRODUCT INDEX inválido. AUTH bloqueada.^0")
        return false
    end

    AUTH.initialized = true
    AUTH.productIndex = normalized
    AUTH.productName = normalized
    AUTH.lastReason = "not_checked"

    CreateThread(function()
        checkAuthentication(false)

        -- Revalidação periódica: desativar/remover uma licença passa a surtir efeito
        -- sem restart; falhas temporárias também se recuperam automaticamente.
        while true do
            Wait(15 * 60 * 1000)
            checkAuthentication(true)
        end
    end)

    return true
end

function TDMAuthIsReady()
    return AUTH.ready
end

function TDMAuthIsAuthorized()
    return AUTH.authorized == true
end

function TDMAuthGetState()
    return {
        initialized = AUTH.initialized,
        authorized = AUTH.authorized,
        ready = AUTH.ready,
        serverName = AUTH.serverName,
        productName = AUTH.productName,
        productIndex = AUTH.productIndex,
        reason = AUTH.lastReason
    }
end
