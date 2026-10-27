-- Auditoria dos poucos comandos administrativos que existem somente no client.
ClientAudit = ClientAudit or {}
local NativeRegisterCommand = RegisterCommand
local AuditedClientCommands = {
    flash = true,
    flash2 = true,
    jump = true,
    verentidades = true,
    checkdriver = true,
    vozes = true
}

function ClientAudit.RegisterCommand(name, handler, restricted)
    return NativeRegisterCommand(name, function(source, args, rawCommand)
        local packed = table.pack(handler(source, args, rawCommand))
        if AuditedClientCommands[tostring(name or "")] then
            TriggerServerEvent("vrp_admin:auditClientCommand", name, type(args) == "table" and args or {})
        end
        return table.unpack(packed, 1, packed.n)
    end, restricted or false)
end
