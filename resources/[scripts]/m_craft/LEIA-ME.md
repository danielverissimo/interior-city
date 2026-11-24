# Central de fabricacao · Interior City

Painel v2 integrado ao servidor. Sem seletor de faccoes, saldos ficticios ou
receitas globais na interface. A bancada e escolhida pela proximidade no mundo.
O servidor confere distancia e permissao em todas as operacoes do painel.

## Bancadas

| Organizacao | Permissao | Receitas |
| --- | --- | --- |
| Mafia | perm.mafia | Fajuta, Tec-9, MTAR, AK 47, G3 MK2, Five-Seven |
| Cartel | perm.cartel | Municoes correspondentes as seis armas da Mafia |
| Verdes | perm.verdes | Baseado: 1 malote de maconha + 1 papel = 10 baseados |
| Azul | perm.azul | Lock Pick, MasterPick e Colete |
| Vermelhos | perm.vermelhos | Capuz, Algemas e C4 |

As coordenadas e os demais cadastros foram preservados em `shared/config.json`.
O cadastro efetivo vem deste JSON. Bancadas sem receitas mostram o estado vazio
e permitem consultar/depositar somente os materiais configurados.

## Municoes do Cartel

Cada receita rende **100 municoes por lote**. Requisitos e tempo sao por lote.

| Municao | Spawn | Polvora | Capsulas | Segundos |
| --- | --- | ---: | ---: | ---: |
| M-Fajuta | ammo_snspistol_mk2 | 85 | 110 | 7 |
| M-Five-Seven | ammo_pistol_mk2 | 165 | 110 | 7 |
| M-Tec-9 | ammo_machinepistol | 165 | 110 | 10 |
| M-MTAR | ammo_assaultsmg | 165 | 110 | 10 |
| M-AK 47 | ammo_assaultrifle | 220 | 110 | 25 |
| M-G3 | ammo_specialcarbine_mk2 | 240 | 110 | 25 |

O acesso anterior exigia `perm.lidercartel` para listar as municoes, apesar de
membros com `perm.cartel` conseguirem abrir o armazem. Os membros agora podem
fabricar; outras organizacoes continuam sem acesso. O mesmo criterio de acesso
de membro foi aplicado as outras cinco bancadas produtivas acima.

## Fluxo

1. Aproxime-se da bancada e pressione E.
2. Deposite materiais pelo Armazem, todos os disponiveis ou um material especifico.
3. Escolha a receita e os lotes. Tempo, requisitos e resultado total sao exibidos.
4. O servidor reserva os materiais e persiste o trabalho. Uma producao por bancada.
5. O personagem executa a animacao de trabalho manual apos confirmacao do servidor.
6. A animacao para ao terminar, morrer, entrar em veiculo, andar/afastar-se, ser
   interrompida por outra task ou reiniciar o resource. Parar a animacao nao entrega
   itens nem cancela o trabalho. E possivel fechar a interface e voltar para coletar.
7. A coleta so e liberada quando o servidor confirma que o trabalho terminou.
   Sem espaco na mochila ou com entrega recusada, o trabalho permanece pronto.

ESC fecha a interface. `/fecharcraft` libera o cursor em caso de falha da NUI.
O painel sincroniza periodicamente o estado real da bancada, inclusive se outro
membro depositar materiais ou coletar o resultado.

## Persistencia e ranking

Os mesmos identificadores de estoque `m_craft:storage:<organizacao>` e trabalhos
`m_craft:active_jobs:v2` foram preservados. Nenhum estoque ou inventario foi zerado.
Deposito, consumo e coleta sao serializados por bancada para evitar sobrescrita
concorrente de materiais. A contagem por lote e validada no servidor (1 a 1000).

O ranking novo e separado por organizacao (`m_craft:ranking:org:<nome>`). O ranking
global anterior permanece armazenado, mas nao e exibido como se fosse da faccao.
O ranking por organizacao passa a acumular a partir desta versao.

## Aplicar

Depois de os arquivos atualizados estarem na base, executar `restart m_craft` no
console do servidor. Nao e necessario reiniciar a cidade. Trabalhos pendentes sao
recarregados pelo servidor. O client antigo foi mantido para referencia, mas nao
e carregado pelo fxmanifest; apenas `client/workshop.lua` fica ativo.

## Validacao

`auditoria/tools/test-craft-v2.ps1` executa testes Lua de servidor/client com
simulacao das natives e das interfaces vRP. Cobre escopo por faccao, materiais,
lotes, temporizacao, persistencia, mochila cheia, entrega recusada, concorrencia,
falhas, animacao e foco da NUI. `craft-v2-ui-check.js` cobre a interface real em
Chromium com respostas NUI simuladas. Os arquivos `craft-live-*-result.html`
registram os resultados.

A conferenca final no FiveM deve validar altura/alinhamento da animacao em cada
bancada, deposito com itens reais, fabricacao, coleta, recarga da municao e
permissoes dos cargos. Testes simulados nao substituem essa verificacao no jogo.
