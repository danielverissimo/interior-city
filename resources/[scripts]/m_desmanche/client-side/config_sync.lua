local function applyConfig(data)
    if type(data) ~= "table" then return end

    local settings = data.settings or {}

    cfg.porcentagem_veiculocomum = tonumber(settings.porcentagem_veiculocomum) or 0.35
    cfg.porcentagem_veiculovip = tonumber(settings.porcentagem_veiculovip) or 0.50
    cfg.desmanchar_proprio_veiculo = settings.desmanchar_proprio_veiculo == true
    cfg.desmanchar_veiculo_trabalho = settings.desmanchar_veiculo_trabalho == true

    cfg.table = {
        ["none"] = {
            inicio = {0.0,0.0,0.0},
            local_veiculo = {0.0,0.0,0.0},
            local_ferramentas = {0.0,0.0,0.0,0.0},
            local_finalizar = {0.0,0.0,0.0},
            precisa_de_item = false,
            itens_necessarios = {
                { item="lockpick", qtd=1 }
            },
            permissao = "",
            log_webhook = ""
        }
    }

    for _,item in ipairs(data.desmanches or {}) do
        cfg.table[item.name] = {
            precisa_de_item = item.precisa_de_item == true,
            itens_necessarios = item.itens_necessarios or {},
            permissao = tostring(item.permissao or ""),
            inicio = {
                tonumber(item.inicio and item.inicio.x) or 0.0,
                tonumber(item.inicio and item.inicio.y) or 0.0,
                tonumber(item.inicio and item.inicio.z) or 0.0
            },
            local_veiculo = {
                tonumber(item.local_veiculo and item.local_veiculo.x) or 0.0,
                tonumber(item.local_veiculo and item.local_veiculo.y) or 0.0,
                tonumber(item.local_veiculo and item.local_veiculo.z) or 0.0
            },
            local_ferramentas = {
                tonumber(item.local_ferramentas and item.local_ferramentas.x) or 0.0,
                tonumber(item.local_ferramentas and item.local_ferramentas.y) or 0.0,
                tonumber(item.local_ferramentas and item.local_ferramentas.z) or 0.0,
                tonumber(item.local_ferramentas and item.local_ferramentas.w) or 0.0
            },
            local_finalizar = {
                tonumber(item.local_finalizar and item.local_finalizar.x) or 0.0,
                tonumber(item.local_finalizar and item.local_finalizar.y) or 0.0,
                tonumber(item.local_finalizar and item.local_finalizar.z) or 0.0
            },
            log_webhook = tostring(item.log_webhook or "")
        }
    end
end

RegisterNetEvent("m_desmanche:syncConfig",function(data)
    applyConfig(data)
end)

CreateThread(function()
    Wait(500)
    TriggerServerEvent("m_desmanche:requestConfig")
end)
