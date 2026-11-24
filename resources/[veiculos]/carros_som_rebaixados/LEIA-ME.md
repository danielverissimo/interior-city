# Carros som rebaixados

## Paredao da Ford F-250

O modelo baller inclui ball_exhaust_mod.yft, agora registrado no modkit
1803_baller_modkit como VMT_EXHAUST (tipo 4, opcao 0). O /car f250 e o
spawn do painel aplicam essa opcao automaticamente. O arquivo original
foi preservado. Veiculos existentes podem receber a primeira opcao de
escapamento no tuning. A garagem restaura o paredao depois do tuning salvo.
Reinicie carros_som_rebaixados, vrp_admin e m_paineladm_v2, reconecte e
crie uma nova F250. Validar no jogo o visual e o alinhamento da peca;
a verificacao local confirma o registro e o arquivo, nao a geometria.

Recurso FiveM preparado para a base Interior City. O `ensure [veiculos]`
existente em `config/resources.cfg` inclui este recurso no proximo inicio.
Para carregar com o servidor ligado, execute no console: `refresh` e depois
`ensure carros_som_rebaixados`. Reconecte o cliente para testar o streaming.

## Modelos e comandos administrativos

| Carro | Comando no jogo |
| --- | --- |
| Ford F-250 Rebaixada | `/car f250` |
| Chevrolet Celta Motors Garage | `/car celta` |
| Chevrolet S10 2017 aro 24 | `/car s10` |
| Gol GTS baixo | `/car golgts` |
| Monza | `/car monza` |
| Saveiro Deboche (deboxe) | `/car saveirodeboche` |
| Saveiro EstiloDub | `/car saveiroestilodub` |
| Saveiro Summer | `/car saveirosummer` |

Os apelidos foram adicionados ao comando `/car` do `vrp_admin`. Tambem aceitam
espacos, por exemplo `/car gol gts`, `/car saveiro estilo dub` e
`/car saveiro summer`. S10 aceita ainda `/car ts10`, Gol aceita `/car gol`
e Saveiro Deboche aceita `/car saveirodeboxe`.
Os codigos originais continuam funcionando: `ingot`, `chevys10`, `blista2`,
`exemplar`, `zion`, `vwsava` e `oracle`, respectivamente.

Os sete carros estao na categoria de veiculos add-on do painel
`m_paineladm_v2`, com nomes descritivos e os sete prints fornecidos pelo usuario.
As fotos estao em `m_paineladm_v2/nui/imgs/vehicles/carros_som_*.png`.
Os botoes do painel usam os codigos reais dos modelos.
O catalogo do painel inclui automaticamente os sete carros ao iniciar, mesmo
se o JSON anterior ainda nao tiver esses cadastros. Os apelidos do `/car` e
do spawn manual do painel usam `vrp/cfg/carros_som.lua` como fonte comum.
Uma barra invertida no fim do comando copiado tambem e ignorada.
Para aplicar em servidor ligado, execute `restart vrp_admin` e
`restart m_paineladm_v2` no console, e reabra o painel.

Se as alteracoes ainda nao aparecerem no servidor, executar no console:

```text
refresh
ensure carros_som_rebaixados
restart vrp_admin
restart m_paineladm_v2
```

Depois reconectar ao servidor e abrir Veiculos > Veiculos addon. Procurar por
Celta, S10, Gol GTS, Monza ou Saveiro. No spawn manual pode digitar `celta`,
`s10`, `golgts`, `monza`, `saveirodeboche`, `saveiroestilodub`, `saveirosummer`.
O `config/resources.cfg` tambem possui `ensure carros_som_rebaixados` explicito.

O comando `/car` usa as permissoes administrativas ja existentes da base.
Celta, Gol, Monza, Saveiro deboxe e Summer sao replacements: substituem os
respectivos carros originais do GTA, inclusive os ja existentes em garagens
e no transito. Mantem o handling e o cadastro originais desses modelos.
S10 e EstiloDub sao add-ons com seus proprios metadados. Nao foram definidos
precos nem adicionadas ofertas na concessionaria.

## Integracao

- Originais e creditos preservados nas sete pastas recebidas.
- Copias dos modelos e texturas organizadas em `stream/`.
- S10 e EstiloDub extraidas dos `dlc.rpf`, incluindo `soms10.yft` e `som.yft`.
- Handling, vehicles, carcols e carvariations registrados pelo manifest.
- Modkits ajustados para 1800 (S10) e 1801 (EstiloDub), livres na verificacao
  da base. O ID original 135 da S10 ja era usado por outro recurso.
- Nao e necessario gerar RPF para instalar este recurso no FiveM.
- Extracao baseada na estrutura RPF7 documentada pelo codigo do CodeWalker:
  https://github.com/dexyfex/CodeWalker/blob/master/CodeWalker.Core/GameFiles/RpfFile.cs
  Script utilizado: `auditoria/carros_som/extract-rpf.ps1`.

## Validacao

Verificados os cabecalhos RSC7 e a descompactacao dos 27 arquivos de streaming,
a sintaxe XML dos dez arquivos meta e as referencias aos dois modelos de som
dos modkits. Nao foi realizado teste dentro do GTA/FiveM.

No jogo, testar os sete spawns, texturas, colisoes, bancos, rodas, direcao e
tuning. Na S10 e na EstiloDub, testar tambem a opcao de chassis do modkit que
instala o modelo de som. A presenca de caixas de som no modelo nao instala
um sistema de reproducao de musica; isso depende dos scripts do servidor.
Os nomes mostrados pelos menus da garagem nos replacements podem continuar
os nomes originais cadastrados na base.

## Paredao da S10 e da Saveiro EstiloDub

Os paredoes vieram nos RPFs e estao em `stream/chevys10/soms10.yft` e
`stream/vwsava/som.yft`. Sao mods `VMT_CHASSIS` (tipo 5, primeira opcao 0),
nao fazem parte da carroceria padrao. Os spawns administrativos do `/car`
e do painel agora instalam essa opcao nesses dois modelos. Se nao houver
opcao de chassis carregada, mostram um aviso em vez de ignorar o problema.
A garagem instala o paredao depois de restaurar o tuning salvo. O recurso
tambem repoe a peca quando o motorista tem controle do veiculo, inclusive
em carros ja criados.

## Conferencia do Celta

O pacote recebido do Celta contem somente `ingot.yft`, `ingot_hi.yft`,
`ingot.ytd`, `ingot+hi.ytd` e o texto de creditos/instalacao. O texto descreve
um replacement do Ingot, com interior funcional, sem instrucoes de som/tuning.
Os quatro arquivos de streaming foram comparados por SHA-256 com os originais
e sao identicos. Nao foram encontrados arquivos separados de paredao/modkit,
nem nomes de bones `extra_` na inspecao das strings dos dois modelos YFT.
Essa inspecao nao substitui visualizar a geometria em um editor 3D.
Portanto nao foi aplicado o ajuste de chassis da S10/Saveiro ao Celta:
nao ha uma peca de tuning equivalente identificada nesse pacote.
Para conferir o visual anunciado, comparar com o pacote original completo
ou com imagens da versao anunciada antes de trocar rodas/suspensao/modelo.
