# IC Admin — implementação e operação

O recurso `ic_admin` usa Lua/vRP e NUI própria para as quinze áreas do Mage Admin.
O Config Manager continua separado. O modo entregue nesta revisão é `active`, após autorização explícita da troca.
O instalador exige `--ic-admin-cutover` para essa configuração. O modo `preview`
continua disponível para ambientes isolados, sem assumir os serviços compartilhados.
Somente um provedor pode responder por clima, chamados e entregas VIP. Consulte `config/ic_admin.cfg` e o bootstrap do
recurso para os requisitos de habilitação.

Além do modo, `ic_admin_service_resource` seleciona o provedor consumido pela
cidade. A configuração anterior `7f01bd5` manteve o provedor antigo durante a prévia.
A revisão de troca seleciona `ic_admin` e retira o `ensure` do recurso anterior.
Para assumir serviços, o IC Admin exige modo `active`, provedor `ic_admin` e
recurso anterior configurado por `ic_admin_previous_resource` parado. Esse nome
fica na configuração da transição; os módulos novos não chamam seu código.

Nenhuma validação estática ou teste com stubs comprova execução dentro do GTA.
A troca no Uriel, a migração dos dados efetivos e a sessão com dois clientes reais
precisam de execução e evidências próprias. As instruções abaixo não executam
automaticamente deploy, parada de serviço ou importação.

## Contratos e evidências

| Classificação | Evidência e consequência |
| --- | --- |
| ENFORCED | Decisões aprovadas: somente NUI, cargos atuais, operações críticas exclusivas de Dono/Developer, disciplina preservada, auditoria técnica por 90 dias. |
| ESTABLISHED | `resources/[vrp]/vrp/server-side/group.lua`: `saveManagedGroups`, `addUserGroup` e expiração VIP; cargos e validade continuam sob responsabilidade da vRP. |
| ESTABLISHED | `resources/[voip]/radio/server.lua`: exports de rádios privadas e armazenamento persistente próprio; o painel usa esses exports. |
| ESTABLISHED | `compose.dev.yaml`: recursos montados como somente leitura; arquivos mutáveis precisam de overlay explícito ou banco. |
| CONFLICTING | `vRP.setBanned` insere `owner`/`staff`, ausentes no esquema original versionado; a migração aditiva acrescenta essas colunas se faltarem. |
| EMERGING | `database/ic_admin/001_initial.sql`, `scripts/ic-admin-migrate.py` e módulos `ic_admin`: novos contratos sujeitos à homologação do jogo. |

O REA examinou HTML/JavaScript como texto inerte. O grafo semântico foi parcial
pelo limite de nós; o núcleo Lua do fornecedor não foi deofuscado nem executado.
Evidências da análise prévia: Mage Admin
`ev_02369b350638e1715f9a57cdac78cbd95be89477af1f03d6aa888ad58b6fa350`
e Config Manager
`ev_6ff4bac1e0dc9d8eb9f50305a1781f5d0ba627b056bcb601d1ae6fcec091cfb0`.
Esses identificadores pertencem à sessão REA que produziu a análise, não a uma
captura de execução real.

### Matriz funcional de aceitação

| Área | Fluxos que precisam de evidência no GTA |
| --- | --- |
| Servidor | Whitelist, ban/desban, avisos, revive geral, limpezas e fome/sede com permissão e auditoria. |
| Jogadores | Lista, busca, perfil e alteração com alvo desconectando durante a operação. |
| Advertências | Aplicar castigo, reconectar, reiniciar o recurso e restaurar dimensão/posição ao término. |
| Mapa | Posições atualizadas, seleção correta e ações vinculadas ao passaporte correto. |
| Chamados | Staff/polícia/mecânica/hospital, dois atendentes concorrentes, aceite único, conclusão e avaliação. |
| Setagem | Hierarquia, caches da vRP e atualização das permissões com sessão aberta. |
| Alterar RG | Identidade/banco offline, manutenção recusada com alvo online ou ID de destino ocupado. |
| Itens | Quantidade/limites, entrega e remoção sem repetição após duplo clique ou resposta atrasada. |
| Armas | Catálogo reconhecido pela base e munição correta. |
| VIPs | Grupo existente, prazo inalterado na importação, reentrega ativa recusada e resgate único. |
| Veículos | Catálogo, spawn, garagem e ações no veículo atual com entidades válidas. |
| Rádio | Exports existentes, acesso às frequências e persistência após restart. |
| Locais | Categorias, captura, teleporte e integração com spawn. |
| Clima | Um único serviço autoritativo e leitura de `GlobalState.time` pela HUD. |
| Logs | Filtros, ator/alvo, destino privado, falha de Discord e retenção técnica de 90 dias. |

A manutenção de passaporte usa um registro explícito de tabelas da vRP e do
núcleo. Relacionamentos não reconhecidos com linhas para o alvo ou destino bloqueiam
a operação. `server/ownership.lua` adapta formatos conhecidos de `vrp_srv_data`,
`trafico`, `mirtin_organization_members` e `mirtin_users_homes` sem substituir
substrings em documentos serializados. Os formatos e guardas da revisão 1.1 estão
descritos adiante; um formato não reconhecido continua bloqueando a operação.
Não há varredura destrutiva genérica por colunas chamadas `user_id`, nem garantia
de apagar dados de um recurso cujo formato não foi mapeado. Essa recusa é um
resultado esperado de segurança e deve ser coberta na homologação.

### Comunicação e serviços

A NUI usa `ic_admin:request` e `ic_admin:response`. O envelope de solicitação
contém `requestId`, `method` e `payload`; o de resposta contém `requestId`, `ok`,
`data` ou `error`. A identidade do administrador vem do `source` no servidor.
O registro de métodos determina a permissão e a exigência de alvo online.
Timeout de mutação não significa falha do efeito e não autoriza repetição automática.

Os consumidores da cidade devem usar os exports próprios `sendLog`,
`createSectorCall`, `cancelSectorCall`, `getVipGarageSlotsForUser` e `getLocations`.
Os métodos e detalhes dos payloads têm sua fonte executável nos módulos do recurso;
a UI não recebe URLs privadas nem credenciais no bootstrap.

## Esquema e persistência

O esquema v1 cria somente tabelas `ic_admin_*`: documentos versionados,
operações, auditoria, identidades históricas e disciplina. A auditoria tem índices
por data, ação, ator e alvo; a disciplina não acompanha a limpeza de 90 dias.
`ic_admin_schema.version = 1` é gravado somente ao final do SQL. Como DDL no
MariaDB causa commit implícito, uma falha parcial deve ser investigada e a
migração idempotente reaplicada; não há promessa de rollback automático de DDL.

A revisão 1.1 exige esquema **v2**. `002_records.sql` acrescenta tabelas próprias
para chamados, avaliações e entregas VIP, com índices de identidade histórica,
responsável, setor, estado e data. O comando `schema --apply --writers-stopped`
aplica as duas DDLs, valida os formatos v1, promove os documentos antigos em uma
transação e grava o marcador 2 nessa transação. O contador antigo de chamados é
reservado antes da promoção. Os documentos v1 são preservados como cópia histórica;
o runtime 1.1 usa os registros individuais. A importação legada e sua verificação
também consultam os registros atuais e recusam sobrescrever alterações operacionais.

O recurso verifica a versão; não cria tabelas automaticamente. A ferramenta usa
Python padrão e o cliente `mariadb` que já existe no contêiner `db`. A senha é
lida dentro do contêiner por Docker secret e não entra nos argumentos do processo
host. SQL é enviado por stdin; erros do banco são suprimidos para impedir que
valores de jogadores ou credenciais apareçam nos relatórios da ferramenta.
As tabelas administrativas e de banimento necessárias à migração precisam ser
InnoDB; a verificação recusa motores não transacionais e não os converte
automaticamente. A manutenção também precisa validar os motores de seu conjunto
de tabelas antes da transação destrutiva.

Exemplo para o ambiente de desenvolvimento já configurado:

```bash
python3 scripts/ic-admin-migrate.py schema --dry-run
IC_ADMIN_COMPOSE_PROJECT="$(sed -n 's/^COMPOSE_PROJECT_NAME=//p' .env.dev | head -n 1)"
python3 scripts/ic-admin-migrate.py --env-file .env.dev \
  --project-name "$IC_ADMIN_COMPOSE_PROJECT" \
  --compose-file compose.yaml --compose-file compose.dev.yaml schema --verify
```

Para aplicar, depois do backup e com escritores parados, use os mesmos argumentos
de ambiente e `schema --apply --writers-stopped`. O campo é uma declaração do
operador, não uma prova automática de parada. Banco, volumes e projeto Compose
devem ser explicitamente escolhidos; o comando não descobre nem seleciona Uriel.

O arquivo vRP `cfg/groups.json` recebe overlay de
`state/resources/vrp/groups.json` no Uriel e
`state/dev/resources/vrp/groups.json` em desenvolvimento. Inicialização ocorre
somente quando o estado não existe. No primeiro upgrade, o instalador seleciona o
arquivo da release anterior, para os escritores e só então extrai o estado;
nunca substitui grupos existentes pelos padrões da candidata. O mesmo overlay
acompanha rollback. O backup já inclui `state/resources`.

Se o verificador da release antiga recusar alterações em `groups.json`, arquive
e revise o diff antes de prosseguir. Preserve o conteúdo efetivo no diretório de
estado com escritores parados; restaure o arquivo versionado da release somente
depois de preservar e verificar o estado. Não use a migração para contornar o
verificador de drift. Arquivos inválidos, diretórios ou symlinks são recusados.

## Importação dos dados do painel anterior

`snapshot` aceita explicitamente o diretório do recurso antigo, o `groups.json`
efetivo da vRP e um diretório novo de saída. Ele não procura dados no servidor nem
para serviços. Defina `IC_ADMIN_LEGACY_RESOURCE`, `IC_ADMIN_GROUPS_FILE` e
`IC_ADMIN_SNAPSHOT` com caminhos absolutos privados antes de executar:

```bash
python3 scripts/ic-admin-migrate.py snapshot \
  --source "$IC_ADMIN_LEGACY_RESOURCE" --groups "$IC_ADMIN_GROUPS_FILE" \
  --output "$IC_ADMIN_SNAPSHOT" --writers-stopped
python3 scripts/ic-admin-migrate.py import --snapshot "$IC_ADMIN_SNAPSHOT" --dry-run
```

O snapshot é privado (diretório 0700, arquivos 0600), contém inventário e
SHA-256, e é validado integralmente antes de ser criado. Devem estar parados todos
os escritores dos arquivos capturados. Não copie um KVP/LevelDB vivo esperando
consistência. Se o estado de clima existir somente em KVP, obtenha a representação
JSON autoritativa numa sessão controlada antes de selar; a ferramenta não deduz
estado de bytes opacos.

Importação cobre permissões, pacotes/entregas VIP, locais/categorias, chamados e
avaliações, clima e históricos de disciplina. Campos de pacote como salário e
título são confrontados com os grupos da vRP. A ferramenta não entrega itens,
veículos, salários ou grupos e não renova expirações. Estados de resgate VIP
desconhecidos exigem reconciliação explícita antes de importar. Castigo ativo
exige expiração e estado válido de restauração; histórico de ban/desban é
arquivado e não altera bans ativos da vRP.

Arquivos vazios conhecidos recebem somente os padrões documentados no parser.
JSON malformado, symlinks, checksums divergentes, referências inválidas e estados
não suportados bloqueiam a aplicação. Formatos novos devem receber conversor e
fixture específicos, sem heurística que descarte registros silenciosamente.

`logs_config.json` não é copiado. O relatório informa apenas quantos destinos
privados precisam de configuração. Cadastre os valores nos campos privados
`ic_secret_ic_admin_main_webhook`, `ic_secret_ic_admin_staff_webhook`,
`ic_secret_ic_admin_economy_webhook` e `ic_secret_ic_admin_world_webhook`, renderize
a configuração privada e recrie o FXServer no procedimento operacional aprovado.
O painel escolhe os aliases `main`, `staff`, `economy` e `world`.

Com esquema verificado e escritores parados, aplique usando os argumentos
explícitos do Compose:

```bash
python3 scripts/ic-admin-migrate.py --env-file .env.dev \
  --project-name "$IC_ADMIN_COMPOSE_PROJECT" \
  --compose-file compose.yaml --compose-file compose.dev.yaml \
  import --snapshot "$IC_ADMIN_SNAPSHOT" --apply --writers-stopped
python3 scripts/ic-admin-migrate.py --env-file .env.dev \
  --project-name "$IC_ADMIN_COMPOSE_PROJECT" \
  --compose-file compose.yaml --compose-file compose.dev.yaml \
  import --snapshot "$IC_ADMIN_SNAPSHOT" --verify
```

A aplicação usa transação InnoDB, identidades determinísticas para históricos e
marcador de migração com digest. Reaplicar o mesmo snapshot verifica o resultado
sem repetir a gravação. Dados divergentes são recusados. Um delta final só pode
usar `--replace-imported` quando os documentos no destino ainda corresponderem
aos hashes da importação anterior; alterações operacionais posteriores exigem
reconciliação, mesmo com a opção. Verificação após uso normal pode apontar
divergência legítima: não restaure dados antigos para fazer a verificação passar.

## Homologação, troca e rollback

Para instalar a prévia no Uriel, o instalador aceita um terceiro argumento
explícito `--ic-admin-schema`. Ele aplica o esquema aditivo exigido pela release depois
da parada dos escritores e do backup, antes de iniciar a release nova. Sem esse
argumento, o deploy não executa migrações. Esse fluxo mantém `preview` e não
importa dados do painel antigo nem seleciona os serviços novos. Falha na migração
retorna ao código anterior; alterações DDL já aplicadas permanecem.

1. Construir e testar em banco/estado isolados, com `preview` e o painel antigo
   responsável pelos serviços da cidade. Nenhuma rotina global concorrente deve
   ser habilitada nessa etapa.
2. Validar a matriz funcional em GTA real, inclusive dois clientes para chamados
   e vídeo, NAT que acione fallback, revogação de cargo, reconexão e restart.
3. Ensaiar snapshot, importação, comparação e restauração do backup em isolamento.
   Conservar o relatório de contagens, checksums e erros sem valores privados.
4. Depois da aprovação operacional, parar os escritores antigos, fazer backup de
   banco/estado, capturar o delta final e importá-lo. Migrar os consumidores,
   desligar o painel antigo, selecionar provedor `ic_admin` e modo `active`, e
   iniciar os serviços novos. O guard de autoridade recusa assumir os serviços
   enquanto o recurso anterior configurado estiver iniciado.
5. Verificar HUD, spawn, identidade, survival, VIPs, rádio e auditoria com o
   recurso antigo parado. Só então habilitar os aliases `/padm` e Insert previstos
   no modo ativo. Conservar a release anterior e seus dados de rollback.

Rollback anterior ao uso operacional pode restaurar o snapshot consistente do
ensaio. Após alterações pelo IC Admin, compare e reconcilie novos eventos,
patrimônio e benefícios antes de retornar ao código antigo. Voltar apenas o código
não desfaz banco, grupos ou rádio; reimportar o snapshot antigo pode apagar efeitos
legítimos. Mantenha um único serviço de clima/chamados/VIP em qualquer direção da
troca. O instalador não executa as migrações SQL automaticamente.

## Validações e limites

Os testes de migração em `tests/test_ic_admin_migration.py` usam fixtures sintéticas
e uma fronteira de banco simulada para verificar formatos, adulteração, exclusão
de URLs privadas, preservação de prazo VIP, idempotência e recusa de sobrescrita.
Eles não emulam o motor SQL nem provam atomicidade de transações MariaDB.

A suíte opt-in `tests/test_ic_admin_sql.py` foi executada em MariaDB 10.11.19 real,
descartável, sem rede, porta publicada, volume persistente ou credencial real.
Foram verificados esquema aditivo repetível, as 204 tabelas da base mais as seis
administrativas, compare-and-swap de documentos, unicidade de operações,
rollback de transação ao colidir passaporte, recusa transacional de revisão
obsoleta, retenção que preserva disciplina e importação idempotente seguida de
verificação. Esses testes usam o motor SQL real; não executam os natives FiveM.

Os harnesses Lua de núcleo, serviços e monitoramento e os testes JavaScript
exercitam os módulos reais com fronteiras FiveM simuladas. Sintaxe e testes da
infraestrutura também foram executados. Contagens finais pertencem ao relatório
da validação da revisão implementada, pois novos testes podem ser acrescentados.

Comandos locais:

```bash
python3 -m unittest discover -s tests -v
python3 scripts/ic-admin-migrate.py schema --dry-run
bash -n scripts/dev.sh scripts/install-uriel-release.sh scripts/prepare-uriel-secrets.sh
# Opt-in: inicia e remove somente um MariaDB descartável para a suíte SQL.
IC_ADMIN_SQL_TEST=1 python3 -m unittest discover -s tests -p test_ic_admin_sql.py -v
```

Restauração de backup operacional, migração dos dados efetivos, comportamento
FiveM e monitoramento com dois clientes continuam pendentes antes da troca no
Uriel. A validação SQL isolada não autoriza nem comprova essa troca.
Uma modificação preexistente em `m_patrulha.sql` permanece fora deste
trabalho e não deve ser revertida para obter um diff limpo.

### Resultado da validação local da primeira implementação (1.0)

A suíte padrão executou 74 casos: 68 passaram e seis SQL opt-in foram omitidos
nessa execução. Os seis casos SQL foram executados separadamente e passaram no
MariaDB descartável. A suíte padrão inclui os harnesses Lua de autorização/RPC,
serviços, monitoramento, disciplina, manutenção e armas/inventário, e os seis
casos Node de transporte/interface. O smoke de navegador sintético percorreu as
15 áreas e validou formulários de banimento, consulta de RG, histórico de bans,
VIP e armas, sem erros no navegador, nas resoluções 1280×720, 1920×1080 e ultrawide.
A configuração Compose local e a sintaxe dos 19 arquivos Lua existentes alterados
passaram. A importação dos templates locais do fornecedor foi validada em árvore
temporária: cinco documentos, sem acessar banco ou estado efetivo.

As permissões herdadas `radio_manage`, `weather_manage`, `time_manage` e
`ban_history` são respeitadas pelos nomes novos através de aliases explícitos;
um bloqueio importado não volta a ser liberado pelo padrão de Admin.

### Revisão 1.1 — lacunas implementadas

O [relatório de validação](IC_ADMIN_VALIDATION.md) reúne arquivos alterados,
verificações executadas, limitações e etapas que continuam exigindo GTA real.

| Classificação | Implementação e efeito |
| --- | --- |
| ENFORCED | `server/records.lua`: chamados, avaliações e entregas passam a registros com revisão; alterações concorrentes são recusadas por CAS. Não existe mais teto agregado de 4 MB nesses históricos. Cada registro tem limite de 1 MB. Configurações pequenas continuam em documentos limitados. |
| ENFORCED | `server/calls.lua`, `server/vips.lua`: listas de 50 registros, filtros por estado e paginação no SQL. Ranking é agregado no banco (100 primeiros). Avaliações da página são consultadas em lote. Visibilidade usa a identidade histórica e o setor permitido. |
| ENFORCED | `server/reconciliation.lua`: somente Dono/Developer conferem operações incertas e entregas VIP, com identificador digitado, motivo e evidência. A conferência altera somente o registro; nunca chama entrega de item, veículo ou grupo. |
| ENFORCED | Conferir um veículo como não entregue libera outra escolha explícita. Confirmar itens exige jogador online, sujeito histórico correspondente, grupo ativo e expiração vRP comprovada. Arquivar entrega incerta não remove efeitos já aplicados; correções patrimoniais são ações distintas auditadas. |
| ESTABLISHED | `server/ownership.lua`: guarda por comparação do valor original de documentos e moradores dentro da transação. Destinos ocupados, formatos desconhecidos, vínculos estrangeiros não mapeados e trabalhos ativos bloqueiam manutenção. |
| EMERGING | `web/map.mjs`: atlas local, zoom, arraste, teclado, localização de jogador e marcadores atualizados sem remontar a tela. A projeção usa o CRS visível na referência; alinhamento em coordenadas reais precisa de homologação GTA. |
| ESTABLISHED | `config/asset-aliases.json`, `scripts/assets.py`: mapa admitido no catálogo existente é identificado por hash e copiado para caminho próprio do IC Admin durante `assets sync`. Verificação recusa cópia modificada, origem fora do catálogo ou destino de código. Não há dependência do recurso antigo em execução nem download externo pela NUI. |
| ENFORCED | `server/world.lua`: criação e renomeação de categorias propagam os nomes aos locais. Categoria ocupada só pode ser excluída com transferência explícita; locais não são apagados nessa operação. |
| ENFORCED | `server/core.lua`: respostas de leitura também conferem identidade, cargo e sessão após as esperas, para não entregar dados a um `source` reutilizado. |

Na interface, a conferência fica em **Logs → Abrir conferência** e em
**VIPs → Conferir entregas pendentes**. O identificador das operações é um hash;
o identificador interno com token de sessão não é enviado à NUI. Reiniciar o
recurso transforma entregas/resgates em processamento em estado incerto; efeitos
não são repetidos automaticamente. Resolver somente a operação de transporte não
resolve o registro VIP, que exige conferência própria.

Em **Locais → Categorias**, a equipe cria, renomeia e exclui categorias conforme
as permissões existentes `add_location` e `remove_location`. Em manutenção de
passaporte, **Pré-verificar vínculos** permite examinar contagens e bloqueios;
a confirmação sempre executa a preparação novamente.

Formatos de propriedade suportados e limites:

- `trafico.user_id`: passaporte decimal simples; valores serializados desconhecidos
  bloqueiam a preparação.
- `mirtin_users_homes`: proprietário relacional e moradores como lista de passaportes
  ou mapa de passaporte para booleano/nome. Objetos de moradores de outro formato
  exigem adaptador. Recursos de casas ativos precisam ser pausados para esses vínculos.
- `mirtin_organization_members`: `user_id` explícito e campos de identidade
  `user_id`, `userId`, `passport` em `member_data`. Referências restantes não
  reconhecidas são recusadas. O cache de membros é atualizado pelo export restrito
  `m_orgs_v2:icAdminOwnershipCommitted`.
- `vrp_srv_data`: chaves de porta-malas `chest:u<ID>veh_<modelo>` e
  `wardrobe:<ID>`, ranking de craft por passaporte e detecção de trabalhos de craft
  ativos. Ranking exige pausa do escritor `m_craft`. Namespaces globais conhecidos
  de baús são preservados; namespaces não reconhecidos com referências ao alvo ou
  destino bloqueiam manutenção.
- O inventário bloqueia abertura de baús durante manutenção e exige baús fechados
  na preparação; seu cache é invalidado após o commit. Falha de cache após commit
  gera operação incerta para conferência, sem desfazer ou repetir SQL.

A revisão 1.1 foi implantada no Uriel após autorização operacional, na release
`4720106`, com esquema v2, dados efetivos importados e recurso antigo parado.
Foram migrados 3 pacotes VIP, 89 locais, 16 categorias, 6 chamados e 6 avaliações;
173 grupos foram preservados. Clima foi recuperado de KVP. O proprietário confirmou
a abertura de `/icadmin` no GTA. O relatório operacional está em `state/update-4720106.md`. Um retorno ao runtime 1.0 depois de promover o banco a v2
faz seu guard recusar o IC Admin antigo. Não apagar o marcador 2 nem copiar os
documentos históricos sobre registros atuais para forçar rollback. A cidade pode
continuar com o provedor anterior durante a prévia; troca definitiva exige ensaio
de retorno com código compatível e reconciliação dos dados.

Validação GTA permanece pendente: dois clientes para WebRTC/fallback e chamados,
alinhamento do atlas, ações reais de patrimônio, caches dos recursos e início da
cidade com o provedor antigo desligado. Testes locais não comprovam essas etapas.


### Troca operacional autorizada

O proprietário autorizou migrar os dados efetivos e desativar o provedor antigo.
O comando operacional é `scripts/deploy-uriel.sh --apply HEAD --ic-admin-cutover`.
O instalador recusa iniciar a configuração ativa sem essa opção explícita.

`scripts/ic-admin-cutover.py` verifica que os escritores pararam, valida o backup,
conserva os JSONs originais em arquivo privado e sela o snapshot. Apenas divergência
nos JSONs de estado conhecidos é aceita na release anterior; mudanças de código
ou configuração continuam bloqueadas. Bytecode `release.cpython-*.pyc` gerado
pela inspeção é classificado como cache, sem substituir o manifesto.

Quando não existe JSON de clima, uma instância temporária do mesmo FXServer lê
somente o namespace KVP anterior em uma cópia do RocksDB. O núcleo antigo não é
executado nessa recuperação. A instância usa a licença já existente enquanto a
cidade está parada, sem porta publicada, e é removida ao terminar. Estado de clima
não reconhecido bloqueia a migração; ausência comprovada de persistência conserva
os padrões configurados. O banco KVP original não é aberto nem alterado pela recuperação.

O backup é restaurado em MariaDB descartável sem rede/portas, comparando contagens
de todas as tabelas. Esquema e importação são ensaiados nesse banco e verificados
antes de aplicar no efetivo. IDs de históricos sem cadastro atual ficam sem vínculo
numérico em `ic_admin_subjects`, para não pertencerem a futuros donos do passaporte.

Depois de iniciar os novos escritores, falha de validação exige correção ou
reconciliação; não há restauração automática de dados antigos. Uma correção posterior
com o provedor IC Admin já ativo conserva os registros novos e não reimporta JSONs
legados. O relatório privado da troca informa contagens, digest, ensaio de restauração,
versão do esquema e verificação de autoridade. O controlador disponibiliza somente
um resumo sem credenciais ou registros pessoais.

Se o disco não comportar a reserva operacional, a preparação pode deduplicar por
hardlink somente assets idênticos e verificados de releases inativas com o mesmo
catálogo. Diretórios de cache regeneráveis dessas releases podem ser removidos.
Releases montadas por contêineres ativos, código, configurações, estado de jogadores
e backups não são removidos nem substituídos. A reserva mínima não é reduzida.
