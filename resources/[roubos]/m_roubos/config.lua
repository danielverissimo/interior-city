Config = { roubos = {}, setup = {}, webhooks = {}, settings = {} }

-- Integração padrão com vrp_notifycall.
-- Pode ser reaproveitada nos próximos roubos sem precisar alterar a NUI.
Config.NotifyCall = {
    enabled = true,
    event = "NotifyPush",
    code = "911",
    rgba = { 255, 48, 66, 255 },
    blipSprite = 161,
    blipColor = 1,
    blipScale = 0.85
}
