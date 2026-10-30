# IC Config — reconstrução independente do painel de configurações

## Correção da tela preta da NUI — 29/10/2026

As NUIs `ic_config` e `ic_mansions` forçavam `color-scheme:dark` na raiz,
reproduzindo o defeito anterior documentado em `IC_ADMIN_VALIDATION.md`.
Mesmo fechadas, cobriam a cena do hospedeiro no Chromium. A correção mantém
`color-scheme:normal` e fundos transparentes em `html,body`; o tema escuro
fica somente no painel visível e nos diálogos. Não altera Lua, dados ou schema.

O teste `tests/ic_config_transparency_browser.test.mjs` embute cada NUI real
sobre uma cena colorida e compara os pixels no início, durante suspensão para
posicionamento e depois de fechar. Os dois recursos falharam antes da correção.
O teste inclui controle negativo: forçar novamente o esquema escuro na raiz
deve voltar a cobrir a cena. Verifica também painel e diálogo visíveis com
controles escuros. É uma reprodução Chromium; a confirmação no GTA depende
do cliente após carregar a versão atualizada.

## Estado desta entrega

O recurso novo `resources/[scriptcore]/ic_config` implementa configuração da
cidade em Lua/vRP e NUI própria. O painel autoriza pelas associações exatas
`developer` e `dono` da vRP em cada solicitação e antes de cada export. Não usa
o núcleo, a chave ou o servidor de autenticação do `mg_config_panel`.
Os recursos de gameplay continuam sendo os instalados na base; a independência
do painel não comprova independência desses recursos.

Os recursos são distribuídos desabilitados por padrão e sem `ensure` no
`config/resources.cfg`; a seleção é feita pelo instalador explícito. Não há
equivalência completa com o painel original em apresentação: algumas listas
complexas ainda usam editor JSON. Craft + Farm e mansões têm formulários próprios.
As 17 áreas estão implementadas; mansões usam o módulo independente
`ic_mansions`, incluindo compra, moradores, IPTU, mobílias e limpeza.
Consulte [IC_MANSIONS.md](IC_MANSIONS.md) para contratos e importação.

## Descoberta e evidência

| Classificação | Fonte e conclusão |
| --- | --- |
| ENFORCED | Solicitação: usar REA para criar painel próprio sem depender da autenticação do fornecedor. Preservar os cargos atuais e os contratos efetivamente encontrados. |
| ESTABLISHED | Detector `detect_project.py`: nenhuma aplicação Spring/Angular, confiança 0. A base usa FiveM, Lua/vRP e NUI JavaScript. |
| ESTABLISHED | `resources/[scriptcore]/mg_config_panel/{fxmanifest.lua,server_config.lua,client_config.lua}`: `dispatch` e `requestProtectedOpen` chamam handlers de um núcleo protegido. |
| ESTABLISHED | `resources/[scriptcore]/mg_config_panel/web/{index.html,app.js}`: 17 áreas, payloads e respostas da NUI; transporte em `nui`. |
| ESTABLISHED | `resources/[scriptcore]/ic_admin/{client/main.lua,server/bootstrap.lua}`: precedente local para envelopes, identidade pelo source e erros estruturados. |
| CONFLICTING | README antigo ainda lista os dois painéis administrativos; a seleção IC Admin posterior e `config/resources.cfg` são mais recentes. Esta entrega não altera a seleção administrativa. |
| CONFLICTING | `compose.dev.yaml` monta recursos somente leitura. `compose.runtime.yaml` preserva poucos arquivos de configuração; alterações diretas em outras configurações da release geram drift/perda na próxima atualização. |
| EMERGING | `ic_config/server`, `client`, `web` e `scripts/ic-config-state.py`: implementação nova com testes locais; contratos de runtime ainda precisam de homologação. |
| ESTABLISHED | Leitor inerte `scripts/analysis/inspect-mansion-contract.py`: ABI de mansões recuperada do artefato identificado. As APIs originais também dependem de licença; o recurso novo `ic_mansions` implementa os serviços localmente. |

O REA analisou `mg_config_panel/web/app.js` e `index.html` como texto inerte:

- Artefato: SHA-256 `619b8e0b35e600d9cc1aff66e1e0cddd7387f55e1ad15550da2a86190254932c`.
- Evidência principal: `ev_856ea299659c3d0a37e6fe329feff7033fa54841d8ac785609022e76d3236996`.
- Vista de resumo: `ev_1c851c292ec666fd0a63bb184c47433531d87f980754203f6c1e6dbc28d41160`.
- Endpoints: `ev_fac5f93284dd628c5ce11daf10f769ecfa67617fa29ff4168e89330b4c207ae6`.
- Registros exatos das vistas: [evidence/ic-config-rea-static.json](evidence/ic-config-rea-static.json).

A primeira tentativa falhou por ENOSPC no temporário; a repetição com perfil
menor leu os dois arquivos e reteve grafo semântico parcial, limitado a 1.000
nós e 300 desconhecidos. As duas chamadas `fetch` identificadas estaticamente
usam o transporte NUI dinâmico e o catálogo de blips Cfx. Isso não identifica
a autenticação do núcleo Lua. A etapa seguinte leu o carrier de dados e os
protótipos Lua estaticamente com Python, sem executar o código do fornecedor;
o comando reproduzível está em `scripts/analysis/inspect-mansion-contract.py`.
Nenhum endpoint do fornecedor foi acessado. Os hashes e IDs identificam os
artefatos e as observações; não comprovam execução nem equivalência funcional.

## Cobertura e contratos

As integrações reais estão registradas explicitamente em
`ic_config/server/adapters.lua`. A fonte de formato e regra de cada domínio
continua no export correspondente; não há escrita genérica em banco/arquivos
nem endpoint que aceite nomes arbitrários de recurso/export.

| Área | Integração observada | Cobertura da candidata |
| --- | --- | --- |
| Cargos | `vrp/server-side/group.lua:getManagedGroups/saveManagedGroup/removeManagedGroup` | Ler, cadastrar, editar e excluir cargos. |
| Organizações | `ic_config/server/organizations.lua`, APIs proprietárias de grupos/organizações e `database/ic_config/001_organizations.sql` | Criação; prévia e exclusão confirmada com transação SQL, barreiras contra gravações atrasadas e retomada por diário. |
| Baús | `inventory/server/modules/chest.lua` | Consultar, criar, alterar e remover configuração; não apagar conteúdo de jogadores por rotina própria. |
| Craft/farm | `m_craft` e `m_farm`: exports de bancadas e vínculos | Leitura, cadastro, alteração, exclusão; snapshot dos vínculos afetados e compensação. Vínculo compartilhado com outra bancada é recusado. |
| Garagens | `m_garage/server-side/configManager.lua` | Pontos e tipos, incluindo vagas de spawn. |
| Mapa | `m_snippets`: exports de blips | Cadastro, alteração e exclusão; ícones numéricos, sem baixar catálogo externo. |
| Fardamentos | `m_cloakroom`: exports de pontos | Cadastro, alteração, exclusão e captura do fardamento freemode atual. |
| Lojas | `inventory`: exports de configuração de lojas | Cadastro, alteração, exclusão e itens/preços em objeto configurável. |
| Roupas/barbearia/tattoo | Exports públicos de cada recurso | Gerenciamento dos pontos. |
| Desmanche | `m_desmanche`: exports de configuração | Locais e regras gerais. |
| SafeZone | `PolySafeZone/server/config_manager.lua` | Polígonos, limites Z, regras e whitelist. |
| Empregos | `m_empregos/config_manager.lua` | Editar existentes, central/NPC e captura de uniforme pelo recurso. |
| Roubos | `m_roubos` e managers de banco/joalheria/cofres | Locais, tipos e regras; destinos privados ficam no servidor. |
| Residências | `residences/server-side/config_manager.lua` | Casas e interiores; backend também expõe configurações gerais. |
| Mansões | `ic_mansions/server/{admin,gameplay,furniture,bootstrap}.lua` | Cadastro, edição, exclusão desocupada, ocupantes preservados, baús/garagens/trancas, compra, IPTU, moradores, mobílias e limpeza administrativa. |
| Concessionária | `m_dealership/server/config_manager.lua` e catálogo da garagem | Estoque, catálogo, exclusão em lote e configurações gerais. |

A NUI usa campos, seletores e listas nas 17 áreas e 31 telas, sem exigir edição
de JSON. Mansões têm formulário próprio com vagas de garagem e captura de portas
no jogo. Craft + Farm usa editor de receitas com busca no catálogo, produtos,
materiais, quantidades e tempo de produção. Pontos, permissões, armazém e
recompensas do farm têm controles próprios. As demais telas usam os contratos
de `web/form-schema.mjs` e os controles de `web/forms.mjs`, incluindo listas
complexas, polígonos, uniformes e opções específicas de empregos e roubos.
Veja a [comparação de todas as telas com o painel anterior](IC_CONFIG_FORMS.md).
O botão **Teleportar** está disponível nos cadastros com localização válida,
incluindo Craft + Farm. Como no painel anterior, bancadas e lojas usam o primeiro
ponto; zonas seguras usam o centro médio do primeiro polígono. Cargos, tipos,
catálogos e configurações gerais não têm destino de teleporte. O catálogo visual
de ícones não foi reconstruído.
As respostas indisponíveis e falhas aparecem explicitamente na interface.

Cada teleporte passa pela autorização atual de `dono`/`developer` no servidor e
pela validação de coordenadas finitas. Move somente o próprio personagem ou seu
veículo atual, aplica o deslocamento vertical de 0,25 m do recurso anterior e
fecha a NUI liberando o foco. Permanece disponível com gravações de configuração
desligadas; não altera cadastros. Captura ativa, pedidos simultâneos, permissão
revogada, painel fechado e respostas atrasadas impedem o efeito. A prévia local
não executa teleporte.

`client/main.lua` registra `/icconfig` e F9. `/painelconfig` e Home só são
registrados com `setr ic_config_legacy_aliases "true"` antes do início do recurso.
Aliases do painel antigo devem ser habilitados apenas durante uma troca aprovada.

O envelope de rede é `ic_config:request {requestId,method,payload}` e a resposta
é `ic_config:response {requestId,ok,data,error:{code,message}}`, enviada somente
ao solicitante. O cliente aceita resposta exclusivamente do servidor. A NUI usa
`POST /request` e `/close`; não chama autenticação externa. A marca `source`
vem do evento no servidor, nunca do payload da interface.

Capturas `getPlayerPosition`, `getCurrentOutfit`, `startPositionCapture` e
`startSafeZonePolygon` exigem autorização atual. O posicionamento interativo
usa E para confirmar e Backspace para cancelar. No polígono, E adiciona,
Backspace conclui com pelo menos três pontos e X cancela. A captura devolve
vértices XY e limites Z iniciais editáveis de um metro abaixo e dois acima dos
pontos coletados. Iniciar ou terminar uma captura não grava configuração.

## Editor de Craft + Farm

`web/craft.mjs:mountCraftForm` usa o contrato existente `getItemList` para buscar
por nome ou código, com comparação sem distinção de acentos. O editor tem abas
para bancada/farm e receitas. Não pede edição de JSON para pontos, produtos,
materiais, quantidades, tempo, permissões ou recompensas. Capturas de posição
usam o fluxo existente e atualizam apenas o rascunho.

O salvamento mantém `saveCraftSetup` e o formato esperado pelos recursos.
Itens antigos fora do catálogo, metadados não editados e múltiplos grupos de
recompensas permanecem no rascunho. Materiais novos necessários às receitas são
incluídos no armazém; itens extras existentes só saem por ação explícita. Dinheiro
não gera nova entrada de armazém automaticamente, como no formulário anterior.
Quantidades e limites do farm são validados; erro não descarta o formulário.
Cancelar não salva. Falha de catálogo impede salvar; modo de leitura permite
trocar as abas e consultar receitas sem habilitar alterações.

Cobertura: `tests/ic_config_craft.test.mjs` verifica preservação/validação dos
dados; `tests/ic_config_craft_browser.test.mjs` usa Chrome com NUI simulada para
seleção, captura, edição, cancelamento, modo de leitura e falha do catálogo.
Os testes de transparência também cobrem a página com os novos módulos.
Estas melhorias e o teleporte compõem a atualização conjunta. O envio adiado
em 29/10/2026 foi autorizado em 30/10/2026; o resultado operacional acompanha
o relatório privado da release. A tentativa anterior foi cancelada antes da ativação.

## Falhas, permissões e limites

- `ic_config_enabled` precisa ser `true` e o painel anterior deve estar parado
  ou ausente; o guard é repetido a cada export. Não existe bypass pelo console.
- Gravação exige também `ic_config_writes_enabled=true`; o padrão é `false`.
- Há limite de solicitações e serialização das mutações deste painel. Isso
  não bloqueia escritores de outros recursos ou painéis.
- IDs recebidos são lembrados até a desconexão, com teto de 4.096 pedidos por
  sessão. ID repetido não reaplica a mutação. A NUI não faz retry automático.
- `PARTIAL_EFFECT` significa que pode haver efeito parcial entre recursos.
  Criação de FAC pode ter criado cargos antes de falhar a organização;
  não se removem cargos automaticamente porque podem já ter sido atribuídos.
  Craft/farm tenta restaurar os vínculos; uma falha/renomeação de bancada pode
  afetar fabricações pendentes internas, fora do alcance do snapshot público.
- Timeout também exige consultar o estado antes de repetir. Não há promessa
  de transação distribuída ou exactly-once depois de restart/reconexão.
- Valores privados são removidos das respostas e recusados no payload. Ao
  salvar documentos públicos completos, campos privados existentes são
  recompostos no servidor a partir da configuração atual.
- A auditoria própria registra ator, método e resultado no console, sem
  payload/credenciais. Logs adicionais dos recursos continuam sob controle deles.

## Preparar persistência sem alterar um servidor

`scripts/ic-config-state.py` inventaria 28 JSONs de configuração conhecidos,
incluindo cargos e organizações, e cria cópias independentes (sem hardlinks).
O manifesto guarda caminhos relativos e SHA-256; os arquivos copiados podem
conter estado privado e recebem modo 0600 em diretório 0700. Não publique esse
snapshot. Nenhum snapshot efetivo foi aplicado nesta entrega.

Use uma origem explícita que represente os arquivos **efetivos** com todos os
escritores parados. Arquivos já montados externamente, especialmente cargos e
desmanche, precisam de um mapa privado `--source-map`: objeto JSON de caminho
relativo conhecido para caminho absoluto efetivo. A ferramenta não descobre
containers ou servidores nem substitui esses arquivos por padrões da release.

```bash
python3 scripts/ic-config-state.py prepare \
  --source-root "$IC_CONFIG_RELEASE" --output "$IC_CONFIG_STATE"
```

O comando acima só valida e informa contagem/tamanho. `--apply
--writers-stopped` cria o destino **novo** e a cópia; links simbólicos,
destino existente, JSON inválido ou fontes ausentes são recusados. A opção é
declaração do operador, não prova automática de parada. O manifesto é escrito
por último; um processo interrompido pode deixar cópia incompleta, que deve
ser investigada e nunca usada como estado selado.

```bash
python3 scripts/ic-config-state.py verify --output "$IC_CONFIG_STATE"
```

`verify` compara os hashes do snapshot inicial. Depois de gravações legítimas,
diferenças são esperadas; não restaure o snapshot antigo para eliminar o diff.
Banco, KVP, dados de jogadores e backup completo não fazem parte desse snapshot.

O diretório contém `compose.ic-config.yaml` com os mounts explícitos, sem
criação automática de fontes ausentes. É um override **opcional para validação
manual/isolada**, aplicado após os Compose escolhidos pelo operador. Prepare
ownership compatível com o UID/GID do FXServer; os arquivos locais 0600 não
recebem chown automático. O instalador integrado usa outros overlays, específicos
de cada release, criados por `ic-config-cutover.py` com a flag explícita
`--ic-config-cutover`. Ele configura ownership, backup e preservação dos mounts
da release anterior. Veja [instalação e recuperação](IC_CONFIG_INSTALL.md).

## Validação e instalação explícita

O exemplo `config/ic_config.example.cfg` mantém gravações/aliases desligados.
Não é executado pelo CFG principal. Para homologação isolada, selecione os
mounts/ownership, pare o painel anterior nesse ambiente e habilite somente
o recurso próprio. Primeiro confirme leituras e permissões; depois valide
gravação persistente e restart antes de habilitar o restante.

```bash
python3 -m unittest discover -s tests -p 'test_ic_config*.py' -v
node --test tests/ic_config_web.test.mjs
```

Os testes exercitam Lua real com fronteiras FiveM/vRP/exports simuladas,
sintaxe Lua, payloads, permissões revogadas, replay, campos privados, falhas
parciais, capturas, ciclo de vida da NUI e preparação de estado sintético.
Não substituem natives FiveM, DB real, exports da cidade em execução nem
comparação de comportamento com o painel original autenticado.

O relatório privado `validation.json` do pacote registra os resultados finais
da suíte completa e os testes opcionais. Os testes IC Config/MariaDB passaram
em execução explícita, incluindo restauração real de dump, migração repetida e
preservação de diário pendente na atualização. As NUIs passaram em 17 testes Node e 2 testes Chromium
com NUI/servidor simulados e Playwright já instalado. A prévia foi inspecionada em
1440×1000 e 1280×720 sem transbordamento. O teste de navegador é reproduzível
com `IC_CONFIG_PLAYWRIGHT_MODULE` apontando ao `index.mjs` já instalado e,
quando necessário, `IC_CONFIG_BROWSER_EXECUTABLE` ao Chromium existente:

```bash
node --test tests/ic_config_browser.test.mjs
```

Sem essas variáveis o teste de navegador é ignorado, sem instalar pacotes.
O `git diff --check` global encontra espaços em uma alteração concorrente de
`m_patrulha.sql`; esse arquivo e as demais alterações concorrentes foram
preservados. A verificação de whitespace dos arquivos desta entrega é separada.

Prévia visual: servir apenas `ic_config/web` em loopback e abrir
`?preview=1`. Dados são fictícios e gravações ficam desabilitadas. A interface
normal inicia fechada; não habilite uma página de demonstração em um servidor.

Antes de qualquer troca, ainda faltam: homologar cada domínio no GTA,
persistência após restart e nova release, autorização revogada com NUI aberta,
erros de dependência, concorrência entre dois administradores, timeout após
efeito real, restauração dos backups desse ambiente e efeitos dos logs subjacentes.
O instalador e os testes de recuperação estão integrados; o boot nativo de
homologação ficou bloqueado pela exigência de licença Cfx legítima.
A implementação própria de mansões e a estratégia transacional das organizações
estão concluídas localmente; os testes descritos não comprovam comportamento no GTA.

## Exclusão de organizações

`server/organizations.lua` consulta os cargos efetivos, os usuários com esses
cargos e as seis tabelas já utilizadas pelo `removeManagedOrganization` da base.
A prévia dura 120 segundos e é vinculada ao administrador, conexão e estado
consultado. A confirmação exige a frase exata `EXCLUIR <organização>`.
Associações online afetadas, prévia vencida, mudanças nos dados, JSON inválido,
esquema incompleto ou motores não transacionais impedem o início da exclusão.

O esquema aditivo v1 cria o diário e marcadores de grupos removidos, mais
barreiras de INSERT/UPDATE nas tabelas de organização e de datatables. A
transação retira os registros das seis tabelas e limpa os cargos dos usuários
offline. Os arquivos e caches dos recursos proprietários são finalizados em
seguida. Não se promete uma transação única entre MariaDB, JSON e caches:
depois da confirmação SQL, a recuperação avança até concluir a exclusão e
nunca restaura silenciosamente os dados antigos sobre eventos posteriores.

A NUI oferece consulta e retomada explícita, com `RETOMAR <organização>`.
Recriar uma organização com nome igual é permitido após a finalização e a
verificação de ausência de vínculos remanescentes; o diário anterior fica
arquivado como `recreated`. Não é uma proibição permanente de nomes.

Antes da primeira intenção SQL, a vRP arma um marcador persistente de
recuperação. Se houver falha transitória do banco no próximo início, permissões
ficam bloqueadas até recarregar os marcadores de exclusão. Instalações não
armadas e o painel apenas em leitura não passam a exigir esse esquema para
os demais recursos funcionarem. O marcador não é removido só por desligar a UI.

O migrador nunca escolhe um servidor ou aplica DDL automaticamente:

```bash
python3 scripts/ic-config-migrate.py schema --dry-run
```

Aplicar/verificar exige selecionar explicitamente `--env-file`, `--project-name`
e os arquivos Compose. `schema --apply --writers-stopped` executa a DDL aditiva;
`schema --verify` confere colunas, InnoDB, versão e definições dos 14 triggers.
Credenciais são lidas por secret dentro do contêiner, não nos argumentos host.
Como DDL causa commits implícitos, falha parcial exige inspeção e reaplicação
idempotente; não há rollback automático de DDL. Não houve aplicação em banco vivo.

Testes MariaDB reais e isolados podem ser executados explicitamente com
`IC_CONFIG_SQL_TEST=1 python3 -m unittest discover -s tests -p test_ic_config_org_sql.py -v`.
O teste cria contêiner descartável sem rede, portas ou volumes persistentes.
Os cinco testes passaram em MariaDB 10.11.19, incluindo SQL emitido pelos
handlers Lua reais, rollback de todas as tabelas, proteção contra escritores
atrasados, recriação e aplicação/verificação repetida do esquema.

## Arquivos desta entrega

| Caminho | Conteúdo |
| --- | --- |
| `resources/[scriptcore]/ic_config/{fxmanifest.lua,config.lua}` | Recurso novo, dependências existentes e seleção dos recursos da cidade. |
| `resources/[scriptcore]/ic_config/client/main.lua` | Ciclo de vida, transporte, aliases opcionais e capturas. |
| `resources/[scriptcore]/ic_config/server/{core.lua,adapters.lua}` | Autorização, validação, exports e preservação de campos privados. |
| `resources/[scriptcore]/ic_config/web/{index.html,style.css,app.mjs,model.mjs,transport.mjs}` | Interface e contratos próprios. |
| `config/ic_config.example.cfg` | Exemplo opcional, não carregado na inicialização. |
| `scripts/ic-config-state.py` | Planejamento e cópia privada de configurações com overlay opcional. |
| `tests/{ic_config_client.lua,ic_config_server.lua,test_ic_config_client.py,test_ic_config_runtime.py,test_ic_config_state.py,ic_config_web.test.mjs,ic_config_browser.test.mjs}` | Contratos, falhas, ciclo de vida, persistência e navegador. |
| `docs/IC_CONFIG.md`, `docs/evidence/ic-config-rea-static.json` | Cobertura, operação, limites e vistas estáticas do REA. |

A conclusão acrescenta `resources/[scriptcore]/ic_mansions/`,
`database/ic_config/001_organizations.sql`, `scripts/ic-config-migrate.py`,
`scripts/ic-mansions-import.py`, o leitor inerte de análise e seus testes.
Os serviços proprietários alterados para integração/consistência são:
`dm_spawn/server/server.lua`, `inventory/server/modules/chest.lua`,
`m_garage/server-side/{functions.lua,configManager.lua}`,
`doorsv2/{doors_client.lua,doors_server.lua}`, `vrp/{base.lua,server-side/group.lua}`
e `m_orgs_v2/server/00_dynamic_orgs.lua`, nas respectivas pastas de recursos.
O inventário detalhado de mansões está em `IC_MANSIONS.md`.
