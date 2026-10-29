# IC Admin 1.1 — implementação e validação local

Data: 28/10/2026. Perfil detectado: Lua/vRP + NUI; Spring/Angular não se aplica.

## Entrega

| Frente | Arquivos principais | Resultado |
| --- | --- | --- |
| Históricos extensos | `database/ic_admin/002_records.sql`, `server/records.lua`, `server/calls.lua`, `server/vips.lua` | Registros individuais, revisão por linha, filtros e paginação SQL. |
| Promoção de dados | `scripts/ic-admin-migrate.py`, `server/bootstrap.lua`, `config.lua` | Esquema v2 explícito, promoção transacional dos documentos v1, preservação dos originais e verificação idempotente. |
| Conferência | `server/reconciliation.lua`, `web/app.mjs` | Dono/Developer, confirmação do registro, motivo e evidência; nenhum efeito patrimonial automático. |
| Manutenção | `server/ownership.lua`, `server/maintenance.lua`, `inventory/server/modules/chest.lua`, `m_orgs_v2/server/main.lua` | Adaptadores explícitos, pré-verificação, CAS de valores serializados, exclusão de escritores e invalidação de caches. |
| Mapa | `web/map.mjs`, `web/style.css`, `config/asset-aliases.json`, `scripts/assets.py` | Atlas próprio local por hash, zoom, navegação, teclado e seleção de jogador; sem dependência do painel antigo em execução. |
| Categorias | `server/world.lua`, `web/app.mjs` | Criar, renomear e transferir locais ao excluir categoria ocupada. |
| Sessões | `server/core.lua` | Respostas de leitura descartadas após reutilização de source ou revogação da sessão/cargo. |

Os caminhos `server/` e `web/` acima são relativos a
`resources/[scriptcore]/ic_admin/`. Os adaptadores do inventário e de organizações
ficam nos recursos correspondentes, sem usar os arquivos do painel antigo.

## Verificações executadas

| Verificação | Evidência |
| --- | --- |
| `python3 -m unittest discover -s tests -q` | 83 casos: 73 aprovados e 10 SQL opt-in omitidos na suíte padrão. |
| `IC_ADMIN_SQL_TEST=1 python3 -m unittest discover -s tests -p test_ic_admin_sql.py -v` | Os dez casos SQL passaram em MariaDB 10.11.19 descartável, sem rede, porta publicada ou dados reais. |
| Harnesses Lua | Código real com fronteiras FiveM/SQL simuladas: sessão, deduplicação, registros, chamados, VIP, reconciliação, categorias, manutenção, propriedade, disciplina, monitoramento e inventário. |
| SQL real | Promoção v1/v2 repetível, contador preservado, snapshots, históricos acima de 4 MB, paginação, CAS obsoleto, rollback, retenção, importação e predicado de visibilidade emitido pelo módulo Lua real para cinco perfis. |
| Navegador sintético | Quinze áreas; mapa local carregado, zoom, teclado, perfil do marcador, categorias, conferência VIP e formulários existentes. Sem erros JavaScript. 1280×720, 1920×1080 e 3440×1440. |
| Sintaxe e integridade | Lua do IC Admin, Lua de organizações, JavaScript, Bash e `git diff --check` no escopo passaram. Aliases de mídia validam SHA-256 e recusam alteração, origem desconhecida e destino de código. |

O inventário completo contém `+=`, extensão CfxLua preexistente também rejeitada
por `luac` no commit anterior. Os exports novos foram compilados isoladamente;
não se declara aprovação do arquivo completo por Lua convencional. Sua execução
depende da homologação FiveM.

O relatório sintético do navegador está fora do código de produção, em
`../../../ic-admin-preview-v2/report.json`, com capturas correspondentes. Não é
evidência de cliente GTA, WebRTC real ou funcionamento dos natives.

## Limites e operação

- Formatos de propriedade desconhecidos e referências sem tratamento continuam
  bloqueando limpeza/troca de passaporte, conforme o contrato de segurança.
- Casas com recursos ativos e ranking do craft com escritor ativo exigem pausa;
  baús devem estar fechados. Pré-verificação não substitui a preparação na confirmação.
- Falha de cache depois do commit exige conferência; SQL aplicado não é repetido.
- A migração de esquema exige backup e escritores parados. Foi executada no Uriel
  após restauração do backup em banco isolado e comparação de 218 tabelas. A versão 1.0 recusa esquema v2; rollback de código precisa
  respeitar essa incompatibilidade e a reconciliação dos dados.
- Permanecem pendentes: teste real de dois clientes para chamados/vídeo/fallback,
  alinhamento do atlas, patrimônio/caches, snapshot efetivo, restauração de backup
  e cidade funcionando com o painel antigo desligado.
- Troca autorizada concluída no Uriel, release `4720106`, esquema v2 e provedor IC Admin ativo; o recurso antigo está parado. O proprietário confirmou a abertura de `/icadmin`.
- Alterações externas ao trabalho em `logo.png` e
  `resources/[scripts]/m_patrulha/m_patrulha.sql` foram preservadas.

As escolhas de formatos suportados, a execução em homologação e a compatibilidade
dos recursos com caches são EMERGING. A recusa de formatos não reconhecidos e as
permissões são ENFORCED no servidor. Não há conflito arquitetural pendente com
Spring/Angular, pois o detector não encontrou essa família no projeto.

## Evidência operacional posterior

Em 29/10/2026 foram verificados backup, snapshot selado, restauração/importação em
MariaDB isolado, importação efetiva e runtime. Contagens: 3 pacotes VIP, 89 locais,
16 categorias, 6 chamados e 6 avaliações; 173 grupos preservados. Entregas e
advertências estavam vazias. A inspeção complementar do KVP recuperou a matriz de
76 permissões, persistida com auditoria sem mudar os acessos efetivos; destinos de
webhook estavam vazios. Clima recuperado de KVP. Nenhum VIP renovado ou benefício
reentregue pela migração.

A suíte atual tem 96 casos: 85 passaram na execução padrão e 11 SQL opt-in ficaram
omitidos nela; os 11 SQL passaram separadamente. Foram acrescentados guardas de
capacidade, deduplicação de assets imutáveis, prontidão assíncrona, históricos de
IDs órfãos, reserva do contador importado, alias de clima `rotating` e reconciliação
de permissões/destinos KVP com JSON, recusando conflitos e registros desconhecidos.

O runtime e a abertura do painel foram confirmados. A homologação de ações críticas
e vídeo com dois clientes permanece pendente. O relatório completo com digest e
limitações está em `../state/update-4720106.md` (registro operacional local ignorado
pelo Git). Os ajustes posteriores de ferramentas de verificação/importação não
alteraram os scripts do jogo da release ativa nem exigiram outro reinício.
