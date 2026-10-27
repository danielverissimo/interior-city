cfg = cfg or {}

-- Valores seguros até o config.json ser sincronizado.
cfg.porcentagem_veiculocomum = 0.35
cfg.porcentagem_veiculovip = 0.50
cfg.desmanchar_proprio_veiculo = true
cfg.desmanchar_veiculo_trabalho = false

-- "none" é necessário porque o client inicia com type_desmanche = "none".
cfg.table = {
    ["none"] = {
        inicio = {0.0,0.0,0.0},
        local_veiculo = {0.0,0.0,0.0},
        local_ferramentas = {0.0,0.0,0.0,0.0},
        local_finalizar = {0.0,0.0,0.0},
        precisa_de_item = false,
        itens_necessarios = {
            { item = "lockpick", qtd = 1 }
        },
        permissao = "",
        log_webhook = ""
    }
}
