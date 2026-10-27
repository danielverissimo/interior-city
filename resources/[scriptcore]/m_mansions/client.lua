-- m_mansions - protected client core
-- Runtime-sensitive NUI/Tunnel/GTA operations are initialised by client_config.lua
-- before this file so the commercial client can be virtualised safely.

local RESOURCE = GetCurrentResourceName()
local PRODUCT_INDEX = "mansoesv1"

CreateThread(function()
    -- This core remains deliberately transport-free. All authoritative rules and
    -- authentication remain server-side in the protected server.lua.
    if RESOURCE ~= "m_mansions" then
        -- No gameplay bypass is granted here; server AUTH remains authoritative.
        return
    end
end)
