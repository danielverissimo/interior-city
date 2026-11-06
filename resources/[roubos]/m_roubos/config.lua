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


-- QRU de Disparo: utiliza o mesmo NotifyPush dos alertas de roubo.
-- O intervalo e aplicado individualmente a cada jogador, no servidor.
Config.GunshotQRU = {
    enabled = true,
    cooldownSeconds = 25,
    title = "QRU de Disparo",
    text = "Disparos de arma de fogo foram registrados nesta localização. Verifique a ocorrência."
}
