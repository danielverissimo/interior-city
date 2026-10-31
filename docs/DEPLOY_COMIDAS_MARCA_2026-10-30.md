# Publicação das comidas e da marca — 30/10/2026

A publicação autorizada foi concluída no Uriel. A release ativa é
`9f71dfecbb8fb04f28fbbd97e7e0222959543f23`, criada sobre a versão efetiva anterior
`c17c2897fbc38ea6fcdaaa35f45094d3c384de57`. A branch e o índice locais foram preservados;
a candidata está na referência local `codex/interior-city-foods-9f71dfecbb8f`.
Não houve push para o GitHub.

## Resultado conferido no servidor

- Nome e projeto: **INTERIOR CITY**.
- Descrição: **Viva sua história na Interior City.**
- Ícone publicado pelo FXServer idêntico ao PNG da marca Interior City.
- 15 novos itens nos cardápios persistentes existentes, com seus preços previstos.
- Comparação estrutural confirmou que os demais itens, preços, coordenadas,
  permissões e propriedades dos shops permaneceram iguais.
- 15 PNGs acessíveis por HTTPS, com HTTP 200, MIME `image/png` e SHA-256 correto.
- Identidade conferida também pelo endpoint público do servidor.
- FXServer, banco e Playit saudáveis; Caddy e backup em execução.
- IC Admin, IC Config e IC Mansões ativos; provedores legados desativados.
- 28 mounts de estado verificados e nenhuma reimportação dos dados legados.
- Nenhum `SCRIPT ERROR` ou erro de parsing nos logs do novo contêiner durante
  a conferência posterior à implantação.

A verificação foi registrada em `2026-10-30T03:54:01.664194+00:00` (UTC; 00:54 de Brasília).

## Backup, fluxo e escopo

O backup pré-deploy `vrp-20261030T035201Z.sql.gz` passou em checksum e gzip.
O instalador executou dois ensaios de restauração em bancos isolados, conferindo
contagens de tabelas e repetição das migrações aditivas. Banco efetivo e estado
persistente foram mantidos. A release anterior foi preservada.

ESTABLISHED: o instalador existente em `scripts/install-uriel-release.sh` fez a
verificação dos assets, seleção de provedores, build, parada dos escritores,
backup, continuidade do estado, troca de release e verificação de runtime.

EXCEPTION operacional registrada: uma cópia privada desse instalador recebeu
três chamadas adicionais para esta publicação: instalar os PNGs verificados sob
o mesmo lock; acrescentar somente os novos itens aos shops depois do backup com
os escritores parados; restaurar os shops originais antes de eventual rollback
automático pré-boot. O instalador versionado e o arquivo da release não foram
alterados. A cópia e seus hashes ficaram no registro privado da operação.

Os hooks recusam conflito de preço, mudança da release-base e mount inesperado.
O JSON anterior dos shops e o manifesto anterior de mídia foram preservados.
Foram testados preservação de campos anteriores, repetição sem alterações e
recusa de colisão de preços. A sintaxe dos scripts operacionais passou.

A diferença alheia de `resources/[scripts]/m_patrulha/m_patrulha.sql` entre HEAD e
a release anterior foi excluída da candidata. Seu hash permaneceu idêntico ao
que já estava no servidor.

## Validações

- 2 testes de contrato/consumo/imagens das comidas: passaram.
- 11 testes da hospedagem de mídia: passaram.
- 25 testes do instalador e das releases: passaram.
- Nenhum teste pulado nesses três grupos.
- Preparação isolada do pacote, sintaxe Lua e `git diff --check`: passaram.
- Instalador no Uriel: retorno 0; verificações operacionais e públicas passaram.

Não foram executados clientes GTA/FiveM nem a suíte completa do repositório.
Compra, desconto, consumo e animações com um jogador real continuam pendentes.
Os objetos nas mãos reutilizam modelos existentes da base. O cartão de última
conexão do cliente pode precisar renovar os dados depois de reconectar.

## Evidências privadas

No Uriel: `state/foods-release-9f71dfecbb8fb04f28fbbd97e7e0222959543f23/`, incluindo `verification.json`,
`deployment.json`, `startup-errors.json`, `media.json`, `shops-change.json`,
`shops.before.json`, manifesto anterior, hooks revisados e log da instalação.
Os relatórios próprios de IC Admin e IC Config também registram runtime ativo.

Cópia local sem URLs ou credenciais: `state/foods-release-20261030/verification.json`.
O pacote local mantém `candidate.json`, o arquivo da release, os hashes de staging
e o registro dos hooks. Esses diretórios de estado não entram no Git.

## Arquivos incluídos na candidata

- `config/config.cfg`
- `docs/BRANDING.md`
- `media/foods/README.md`
- `media/foods/catalog.json`
- `media/foods/generation-prompts.json`
- `media/foods/images.manifest.json`
- `media/foods/images/arrozcarreteiro.png`
- `media/foods/images/arrozcompequi.png`
- `media/foods/images/bolodemilho.png`
- `media/foods/images/cafecoado.png`
- `media/foods/images/caldodecana.png`
- `media/foods/images/curau.png`
- `media/foods/images/cuscuz.png`
- `media/foods/images/docedeleite.png`
- `media/foods/images/feijaotropeiro.png`
- `media/foods/images/galinhada.png`
- `media/foods/images/goiabada.png`
- `media/foods/images/pacoca.png`
- `media/foods/images/pamonha.png`
- `media/foods/images/pedemoleque.png`
- `media/foods/images/tapioca.png`
- `media/foods/preview.png`
- `resources/[scriptcore]/inventory/config/shared.items.lua`
- `resources/[scriptcore]/inventory/config/shared.shops.json`
- `resources/[vrp]/vrp/cfg/items.lua`
- `tests/inventory_foods.lua`
- `tests/test_inventory_foods.py`
