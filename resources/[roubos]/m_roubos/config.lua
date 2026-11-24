Config = { roubos = {}, setup = {}, webhooks = {}, settings = {} }
Config.AtmC4 = {
    plantSeconds = 6,
    fuseSeconds = 10,
    lootWindowSeconds = 180,
    models = {'prop_atm_01','prop_atm_02','prop_atm_03','prop_fleeca_atm'}
}

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
