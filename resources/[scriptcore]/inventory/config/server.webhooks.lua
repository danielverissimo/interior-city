-- ============================================================================
-- LEGACY WEBHOOK COMPATIBILITY
-- ============================================================================
-- As webhooks do inventário não ficam mais hardcoded neste resource.
-- Todas as ações auditáveis são enviadas server-side para o sistema central do
-- m_paineladm_v2 e as URLs são cadastradas exclusivamente pela aba LOGS.
--
-- O objeto Webhook permanece apenas como compatibilidade para algum trecho
-- legado que ainda tente chamá-lo. Nenhuma URL é exposta ou enviada daqui.
-- ============================================================================

Webhook = setmetatable({
    config = {},
    colors = {
        red = 16711680,
        green = 65280,
        blue = 255,
        cyan = 35554,
        rose = 13798114,
        yellow = 16776960
    }
}, {
    __call = function()
        return false
    end
})

-- Mantido por compatibilidade com versões antigas do inventário.
CoopChests = {
    federal = true,
    convencional = true,
    elite = true
}
