-- Sistema de fome e sede da base.
-- Os valores internos de hunger/thirst seguem o padrão vRP legado:
-- 0 = satisfeito / barra cheia, 100 = vazio / necessidade máxima.
--
-- As velocidades abaixo são pontos percentuais da BARRA por minuto.
-- Ex.: 0.35 = a barra perde 0,35% por minuto. Estes valores podem ser
-- alterados em runtime pelo Painel ADM e ficam persistidos via KVP.
return {
    enabledByDefault = true,

    -- Intervalo do processamento. O desgaste é normalizado por minuto, então
    -- mudar tickMs não altera a velocidade configurada no Painel ADM.
    tickMs = 10000,
    hungerPerMinute = 0.35,
    thirstPerMinute = 0.50,

    -- Quando a barra chega a 0%, cada necessidade aplica o dano configurado
    -- independentemente a cada starvationCheckMs. Se fome E sede estiverem em
    -- 0%, os dois danos são somados.
    starvationCheckMs = 10000,
    hungerDamage = 5,
    thirstDamage = 5,
    minimumHealth = 105,

    -- Limites aceitos pelo configurador do Painel ADM.
    maxLossPerMinute = 100.0,
    maxDamage = 100,

    -- Intervalo usado apenas para garantir uma sincronização periódica do estado.
    syncEveryMs = 30000
}
