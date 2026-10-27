-- m_mansions - stable server ABI / bridge (DO NOT OBFUSCATE)
-- Creates vRP/Tunnel interfaces before the protected server core is loaded.

local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

MG_MANSIONS_VRP = Proxy["getInterface"]("vRP")
MG_MANSIONS_VRPCLIENT = Tunnel["getInterface"]("vRP")
MG_MANSIONS_API = MG_MANSIONS_API or {}

-- Stable mutable-resource storage (DO NOT OBFUSCATE)
-- File I/O stays outside the protected core because SaveResourceFile / LoadResourceFile
-- can be affected by some Lua virtualizers. The protected server only calls this ABI.
local MG_MANSIONS_RESOURCE = GetCurrentResourceName()

local function mgMansionsDirectPath(filename)
    local base = GetResourcePath(MG_MANSIONS_RESOURCE)
    if not base or base == '' then return nil end
    return (base .. '/' .. tostring(filename)):gsub('\\','/')
end

local function mgMansionsIoRead(filename)
    if not io or type(io.open) ~= 'function' then return nil end
    local path = mgMansionsDirectPath(filename)
    if not path then return nil end

    local ok, data = pcall(function()
        local file = io.open(path, 'rb')
        if not file then return nil end
        local content = file:read('*a')
        file:close()
        return content
    end)

    if ok and type(data) == 'string' then return data end
    return nil
end

local function mgMansionsIoWrite(filename, data)
    if not io or type(io.open) ~= 'function' then return false end
    local path = mgMansionsDirectPath(filename)
    if not path then return false end

    local ok, written = pcall(function()
        local file = io.open(path, 'wb')
        if not file then return false end
        local success = file:write(data) ~= nil
        file:flush()
        file:close()
        return success
    end)

    return ok and written == true
end

MG_MANSIONS_STORAGE_READ = function(filename)
    if type(filename) ~= 'string' or filename == '' then
        return nil, 'Nome de arquivo inválido.'
    end

    local ok, data = pcall(LoadResourceFile, MG_MANSIONS_RESOURCE, filename)
    if ok and type(data) == 'string' then
        return data
    end

    data = mgMansionsIoRead(filename)
    if type(data) == 'string' then
        return data
    end

    return nil, ('Não foi possível ler %s.'):format(filename)
end

MG_MANSIONS_STORAGE_WRITE = function(filename, data)
    if type(filename) ~= 'string' or filename == '' then
        return false, 'Nome de arquivo inválido.'
    end
    if type(data) ~= 'string' or data == '' then
        return false, 'Conteúdo inválido para gravação.'
    end

    -- Use the explicit byte length. This is more deterministic than -1 on
    -- builds where the native wrapper behaves differently after virtualization.
    local ok, result = pcall(SaveResourceFile, MG_MANSIONS_RESOURCE, filename, data, #data)
    if ok and result == true then
        return true
    end

    -- Some artifacts expose no boolean return even when the write succeeds.
    -- Confirm by reading the exact bytes before deciding that it failed.
    if ok and result ~= false then
        local readBack = nil
        local readOk, nativeData = pcall(LoadResourceFile, MG_MANSIONS_RESOURCE, filename)
        if readOk then readBack = nativeData end
        if type(readBack) == 'string' and readBack == data then
            return true
        end

        readBack = mgMansionsIoRead(filename)
        if type(readBack) == 'string' and readBack == data then
            return true
        end
    end

    -- Native write failed (or could not be confirmed). As a server-side fallback,
    -- write directly inside this resource only, then verify the persisted bytes.
    if mgMansionsIoWrite(filename, data) then
        local readBack = mgMansionsIoRead(filename)
        if type(readBack) == 'string' and readBack == data then
            return true
        end
    end

    local reason = ok and ('SaveResourceFile retornou %s.'):format(tostring(result)) or tostring(result)
    return false, reason
end

Tunnel["bindInterface"](GetCurrentResourceName(), MG_MANSIONS_API)

MG_MANSIONS_REGISTER_EXPORT = function(name, handler)
    return exports(name, handler)
end

MG_MANSIONS_REGISTER_COMMAND = function(name, handler, restricted)
    return RegisterCommand(name, handler, restricted == true)
end

MG_MANSIONS_REGISTER_NET_EVENT = function(name, handler)
    return RegisterNetEvent(name, handler)
end

MG_MANSIONS_ADD_EVENT_HANDLER = function(name, handler)
    return AddEventHandler(name, handler)
end

CreateThread(function()
    Wait(0)
    print("^2[m_mansions] Connection successfully stabilised by </> winchester.^0")
end)
