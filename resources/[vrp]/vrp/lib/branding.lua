local branding = {}
local alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
function branding.logo()
    local raw = LoadResourceFile('vrp', 'branding/logo.png')
    if not raw or #raw > 256 * 1024 then return '' end
    local encoded = {}
    for i = 1, #raw, 3 do
        local a, b, c = raw:byte(i, i + 2)
        local bits = (a << 16) | ((b or 0) << 8) | (c or 0)
        encoded[#encoded + 1] = alphabet:sub(((bits >> 18) & 63) + 1, ((bits >> 18) & 63) + 1)
        encoded[#encoded + 1] = alphabet:sub(((bits >> 12) & 63) + 1, ((bits >> 12) & 63) + 1)
        encoded[#encoded + 1] = b and alphabet:sub(((bits >> 6) & 63) + 1, ((bits >> 6) & 63) + 1) or '='
        encoded[#encoded + 1] = c and alphabet:sub((bits & 63) + 1, (bits & 63) + 1) or '='
    end
    return 'data:image/png;base64,' .. table.concat(encoded)
end
return branding
