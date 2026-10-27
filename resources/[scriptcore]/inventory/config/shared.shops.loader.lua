Shops = Shops or {}

local SHOPS_FILE <const> = "config/shared.shops.json"

local function normalizeShopPoint(point)
    if type(point) ~= "table" then return nil end
    local c = point.coords or point
    local x = tonumber(c.x or c[1])
    local y = tonumber(c.y or c[2])
    local z = tonumber(c.z or c[3])
    if not x or not y or not z then return nil end
    return {
        coords = vec3(x,y,z),
        blip = point.blip == true
    }
end

function LoadShopsFromJson()
    local raw = LoadResourceFile(GetCurrentResourceName(), SHOPS_FILE)
    if not raw or raw == "" then
        print("^1[inventory]^7 shared.shops.json não encontrado ou vazio.")
        Shops = {}
        return false
    end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= "table" then
        print("^1[inventory]^7 shared.shops.json inválido.")
        Shops = {}
        return false
    end

    local normalized = {}
    for name,data in pairs(decoded) do
        if type(name) == "string" and type(data) == "table" then
            local shop = {
                items = {},
                mode = tostring(data.mode or "buy"),
                coords = {}
            }

            for item,price in pairs(data.items or {}) do
                local value = tonumber(price)
                if type(item) == "string" and value then shop.items[item] = value end
            end

            if data.perm and tostring(data.perm) ~= "" then shop.perm = tostring(data.perm) end
            if data.onlyWalletPayment == true then shop.onlyWalletPayment = true end

            if type(data.blip) == "table" then
                shop.blip = {
                    text = tostring(data.blip.text or "Loja"),
                    index = tonumber(data.blip.index) or 52,
                    color = tonumber(data.blip.color) or 0,
                    scale = tonumber(data.blip.scale) or 0.5
                }
            end

            for _,point in pairs(data.coords or {}) do
                local p = normalizeShopPoint(point)
                if p then shop.coords[#shop.coords+1] = p end
            end

            normalized[name] = shop
        end
    end

    Shops = normalized
    return true
end

LoadShopsFromJson()
