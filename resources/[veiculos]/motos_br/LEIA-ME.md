# Motos brasileiras

Modelos novos ativos:

| Moto | Spawn | Observacao |
| --- | --- | --- |
| Honda CBX 250 Twister | `bati` | Substituicao da Bati, conforme o pacote recebido. |
| Honda Bros 150 | `bros150` | Convertida do DLC RPF para arquivos FiveM. |
| Honda Hornet | `hornetagstore` | Assets e metadados da versao FiveM recebida. |

As tres motos constam na garagem, no painel administrativo e na aba Motos da Luxury Motors por 1.000 diamantes. Os apelidos `twister`, `cbx150`, `cbx250`, `bros` e `hornet` sao resolvidos pelo comando administrativo `/car`.

A pasta recebida da Twister identifica CBX 250, embora tenha sido chamada de 150 no pedido. Os arquivos da antiga Titan 160/2016 (citada como 2026) e da Today 125 foram retirados do streaming. Os metadados orfaos da Titan 2008, sem modelo correspondente, tambem foram retirados.

Os registros GTA `pcj` e `enduro` da garagem foram preservados para nao invalidar veiculos ja possuidos; sem os assets personalizados, passam a usar os modelos originais do GTA. Nenhuma posse de veiculo foi alterada no banco de dados.

Os fontes recebidos, incluindo o DLC da Bros e as versoes alternativas GTA V, e os arquivos retirados ficam em `auditoria/backup-motos-novas-*`. O recurso ativo usa somente os arquivos selecionados em `stream` e `data`; nao carrega os scripts ou manifests dos pacotes originais.

O recurso ja esta incluido em `config/resources.cfg`. As alteracoes carregam na proxima inicializacao. Sem reiniciar a base, use `refresh` e reinicie `motos_br`, `m_garage`, `luxurymotors`, `concessionaria`, `m_paineladm_v2`, `vrp_admin` e `AIControl`.

Validacao estatica: `auditoria/tools/test-motos-novas.ps1`. Verifica RSC7, descompressao, assets, metadados, handling e cadastros.

Com um jogador conectado, `testarmotos` no console verifica se os tres modelos estao registrados e carregam no cliente, sem criar veiculos. Classe esperada: 8 (motos). Validacao visual, dirigibilidade e som ainda precisam ser conferidos no jogo.

Creditos dos pacotes recebidos: Twister por lucas henrique, convertida/editada por CH4P4X; Bros por NiinoMods. Demais creditos originais foram preservados junto aos fontes arquivados.
