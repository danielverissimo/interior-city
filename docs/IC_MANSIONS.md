# IC Mansões — sistema próprio e integração com o IC Config

## Escopo e estado

`resources/[scriptcore]/ic_mansions` substitui os serviços de mansões:
cadastro, compra por vale, IPTU, moradores, mobílias, preços, limpeza e acesso
aos pontos de baú/garagem/trancas. A implementação usa Lua/vRP e NUI próprias,
sem carregar o código ou consultar a autenticação do fornecedor. Os recursos
existentes de inventário, garagem, portas e vRP continuam como dependências.

O recurso está desabilitado por padrão e não foi incluído no CFG de boot.
O anterior `m_mansions` permanece intacto para rollback. Nenhum deploy,
importação efetiva ou alteração de dinheiro, itens ou moradores foi executado.
As funcionalidades foram implementadas e validadas localmente; homologação
dentro do GTA/FiveM ainda não foi executada.

## Evidência e regras preservadas

O detector local identificou uma base FiveM/vRP, sem Spring ou Angular.
Os contratos observados são ESTABLISHED em
`resources/[scriptcore]/m_mansions/{config.lua,client_config.lua}`, no formulário
de mansões de `mg_config_panel/web/app.js` e nos dados serializados do núcleo.
Os serviços e protocolos novos são EMERGING, com cobertura local descrita abaixo.

A análise REA anterior da NUI está em
`docs/evidence/ic-config-rea-static.json`. Para o carrier Lua, foi usado um
leitor Python inerte, separado do REA:

```bash
python3 scripts/analysis/inspect-mansion-contract.py \
  'resources/[scriptcore]/m_mansions/server.lua'
```

O leitor fixa o SHA-256 do arquivo, decodifica somente o carrier de dados,
percorre 87.401 bytes e 86 protótipos e emite apenas os contratos permitidos.
Não executa Lua do fornecedor, altera guardas de licença nem imprime constantes
de autenticação/endpoints. O resultado está em
`docs/evidence/ic-mansions-static-contract.json`. A interpretação estática não
é prova de equivalência de execução nem homologação do binário antigo.

| Fluxo | Regra observada e preservada |
| --- | --- |
| Compra | Consome exatamente um vale configurado. `price` é o valor anunciado da propriedade; não há segunda cobrança em dinheiro. Confirmação e disponibilidade/vale são revalidados. |
| IPTU | Ciclo padrão de 20 dias. Proprietário ou morador pode pagar com seu saldo; renovação parte do momento do pagamento. Cadastro legado sem prazo recebe a carência original ao primeiro acesso, sem cobrança. |
| Moradores | Somente proprietário adiciona/remove, inclusive alvo offline. Limite inclui dono + moradores. Não se introduz restrição de residir em apenas uma mansão. |
| Mobílias | Somente proprietário compra, move ou vende. Iniciar/cancelar posicionamento não cobra. Confirmar cobra o preço validado do catálogo; preço alterado exige nova confirmação. |
| Venda de mobília | Retorna `floor(paidPrice * 15 / 100)`, com percentual configurável. Não utiliza um preço de catálogo alterado posteriormente. |
| Preços | Edição global exclusiva de `dono`/`developer`; modelos e IDs vêm do catálogo local, não do payload de compra. |
| Limpeza | `dono`, `developer` ou `admin`, proximidade de 10 m e confirmação. Revoga ocupantes e remove móveis; preserva cadastro, baú, garagem e portas. Não dá reembolso. |
| Excluir cadastro | Exige mansão desocupada. Uma ocupada passa primeiro pelo fluxo explícito de limpeza. |

A compra verifica no servidor a proximidade de 2 m que a interface antiga
aplicava no cliente. Decoração exige proximidade de 80 m da mansão e posição
dentro de 100 m; editar/vender peça exige a proximidade de edição configurada.
Gestão de moradores preserva o seletor original: uma única propriedade do dono
pode ser administrada remotamente; múltiplas exigem seleção próxima em 35 m.

## Arquitetura e contratos novos

- `server/store.lua`: dois slots de estado, geração, checksum e confirmação de leitura.
- `server/core.lua`: contexto do ator, validação, locks, diário e projeções públicas.
- `server/admin.lua`: cadastro e integração com cargos/baús/garagens/portas.
- `server/gameplay.lua`: compra, IPTU, moradores, limpeza e reconciliação.
- `server/furniture.lua`: catálogo, contexto do jogador, compra/movimento/venda/preços.
- `server/bootstrap.lua`: RPC, exports, sincronização e limites por conexão.
- `client/main.lua`: comandos, blips/markers, objetos locais e posicionamento.
- `web/`: interface original para propriedade, moradores, catálogo e recuperação.

O RPC é `ic_mansions:request {requestId,method,payload}` com resposta somente
ao solicitante em `ic_mansions:response {requestId,ok,data,error}`. A identidade
vem do `source`, não de campos enviados pela NUI. Cada método valida a ação
no servidor; respostas de rede no cliente aceitam somente origem servidor.
IDs repetidos não repetem efeitos na conexão, e a NUI não faz retry financeiro.

Métodos principais: `getContext`, `requestPurchase`, `confirmPurchase`,
`payIptu`, `addResident`, `removeResident`, `beginFurniturePurchase`,
`confirmFurniturePlacement`, `updateFurniture`, `sellFurniture`,
`saveFurniturePrices`, `quoteCleanup`, `cleanupMansion`,
`getPendingOperations` e `reconcileOperation`.

O IC Config usa os exports próprios `getMansions(ctx)`,
`saveMansion(originalId,data,ctx)` e `removeMansion(id,ctx)`. Eles aceitam
somente o recurso chamador `ic_config` e revalidam o administrador. Edições
ignoram campos forjados de proprietário, membros, móveis e datas de IPTU;
esses campos são preservados a partir do registro efetivo.

`dm_spawn` consulta o export restrito `getUserMansions(userId)` e mantém a
prioridade estabelecida para a casa do jogador. Inventário e garagem consultam
`checkAccessByPermission`; portas de mansões consultam `checkAccessByMansionId`.
Esses exports são barreiras de IPTU/estado pendente; as permissões normais
continuam sendo verificadas pelos recursos proprietários. Permissão desconhecida
ou usuário sem vínculo não recebe autorização de grupo por esse gate.

O registro de permissões de mansão é publicado antes dos efeitos externos.
Enquanto o provedor está iniciado, os consumidores sempre o consultam. Se
estiver indisponível, permissões conhecidas de mansão permanecem bloqueadas;
as demais continuam disponíveis quando o registro permite distingui-las.
Sem registro conhecido, a seleção do provedor próprio falha de forma fechada.
Uma mansão com operação incerta não libera seus serviços.

Comandos: `/mansao`, `/mobilias`, `/addmorador`, `/tirarmorador` e
`/limparmansao`. Os comandos abrem os fluxos próprios e não executam limpeza
ou cobrança sem confirmação. No posicionamento: E confirma, Backspace cancela,
setas giram, PgUp/PgDn ajustam altura e scroll ajusta distância. Objetos da
prévia e mobílias renderizadas são locais; valores financeiros não são enviados
nas projeções públicas de sincronização.

## Persistência e falhas econômicas

`state-a.json` e `state-b.json` contêm envelopes
`{generation,state,payload,checksum}`. A escrita acontece no slot inativo e é
confirmada por leitura exata antes de trocar o estado ativo. O início seleciona
a maior geração válida e recusa conflito na mesma geração. Nunca converte
estado ausente/corrompido em cidade vazia. FNV-1a detecta inconsistência de
gravação; não é uma assinatura de segurança contra alteração por operador.

Antes de dinheiro, vale ou cargo, a operação é registrada de modo durável.
Falha entre efeito e confirmação não provoca cobrança, estorno ou entrega
automática após reiniciar. O registro preserva o estado anterior e os dados
necessários à conferência. Operações terminadas mantêm auditoria compacta;
pendentes mantêm snapshots completos. O limite de tamanho de cada slot é
16 MB; estados acima do limite são recusados antes de confirmar uma gravação.

MariaDB, inventário, saldo, grupos e arquivos não participam de uma única
transação. Há compensação quando o efeito é conhecido e verificável; em caso
incerto, o recurso exige reconciliação. A interface administrativa mostra
efeitos, snapshots e referências de cargo, incluindo atribuições manuais fora
da lista de moradores. Nenhum JSON bruto com dados alheios é renderizado.

Depois de conferir/restaurar manualmente dinheiro, vale, cargos e integrações
ao estado anterior, o administrador pode declarar a reconciliação com a frase
exata `RECONCILIADO <operação>`, checkbox e revisão atual. O método restaura o
cadastro anterior e encerra o diário; ele não efetua estorno nem adivinha o
resultado externo. Revisão obsoleta é recusada. O recurso pode ser aberto pelo
administrador para essa recuperação mesmo sem nenhuma mansão cadastrada.

O manager proprietário de garagens também foi corrigido: confirma ambos os
arquivos, propaga falha, tenta restaurar bytes/memória e persiste quarentena
se a restauração não puder ser comprovada. A releitura explícita verifica os
arquivos antes de liberar. Isso trata falhas observadas, mas não transforma
dois arquivos em uma transação atômica contra corte de energia.

## Importar os dados antigos

`scripts/ic-mansions-import.py` aceita somente origem e destino explícitos.
Ele valida os JSONs de mansões e catálogo, mantém IDs, ocupantes, móveis,
`paidPrice` e todas as datas existentes. Não renova IPTU, entrega itens,
atribui cargos, acessa banco nem chama o núcleo antigo.

```bash
python3 scripts/ic-mansions-import.py prepare \
  --source "$IC_MANSIONS_LEGACY" --output "$IC_MANSIONS_SNAPSHOT"
```

O comando só planeja, sem gravar. `--apply --writers-stopped` prepara um
diretório novo, privado, com os dois slots, catálogo sanitizado e manifesto.
Links, sobrescrita, identidades/permissões duplicadas, dados econômicos
incompletos e configurações dependentes inválidas são recusados.

```bash
python3 scripts/ic-mansions-import.py verify --output "$IC_MANSIONS_SNAPSHOT"
```

O catálogo local tem 200 IDs únicos. Dois registros originais repetiam ID,
modelo e preço com rótulos diferentes; a primeira ocorrência foi preservada.
Nenhuma URL de imagens/autenticação é copiada para o catálogo próprio.
Não publique snapshots: contêm ocupantes e histórico econômico.

O teste de importação carrega os slots resultantes pelo `Store.load` real,
incluindo UTF-8/checksum. Um snapshot interrompido sem manifesto não deve ser
utilizado. `verify` vale para o snapshot inicial; alterações operacionais
posteriores são esperadas e não justificam restaurar dados antigos por cima.

## Seleção e futura troca

`config/ic_mansions.example.cfg` não é carregado pelo boot. Os controles são
`setr ic_mansions_resource "ic_mansions"` e `set ic_mansions_enabled "true"`,
definidos antes de iniciar os consumidores. O recurso antigo precisa estar
parado/ausente; o próprio backend recusa dois provedores ativos.

Antes de ativar em qualquer ambiente, use o estado efetivo com escritores
parados, confirme a importação e prepare mounts/ownership de ambos os slots
e do catálogo. O helper `ic-config-state.py` inclui esses três arquivos,
mantendo os arquivos antigos para a estratégia de rollback. Use o mapa privado
de fontes para selecionar os arquivos importados em vez dos padrões vazios.
Esse override genérico permanece opcional para ensaios manuais. O instalador
Uriel agora integra a primeira importação e as atualizações próprias por
`--ic-config-cutover`, com descoberta dos mounts efetivos, backup, restauração
de ensaio e overlays específicos por release. Veja
[instalação e recuperação](IC_CONFIG_INSTALL.md). Nenhum deploy foi executado.

Rollback após uso exige reconciliar o estado atualizado, os efeitos econômicos,
os grupos e as configurações dos recursos; voltar apenas o código ou a cópia
antiga não desfaz compras, vendas ou moradores de modo consistente.

## Validação local e limites

```bash
python3 -m unittest discover -s tests -p 'test_ic_mansions*.py' -v
node --test tests/ic_mansions_web.test.mjs
```

Os harnesses exercitam Lua real com fronteiras FiveM/vRP/exports simuladas:
compra por vale, concorrência/replay, IPTU, moradores offline, privacidade,
mobílias/preço alterado/venda, limpeza, preservação de ocupantes, falhas antes
e depois dos efeitos, armazenamento incompleto, reinício e reconciliação.
Há testes do cliente real para origem falsa, respostas atrasadas, cancelamento,
confirmação única, modelos inválidos e limpeza de entidades/foco/blips.

A integração Chromium usa NUI simulada e verifica compra, moradores, IPTU,
posicionamento, venda, preços, limpeza e recuperação, inclusive layout móvel.
Execute o teste opt-in `tests/ic_mansions_browser.test.mjs` com as mesmas
variáveis de Playwright/Chromium já instalado descritas em `IC_CONFIG.md`.

O ensaio de boot nativo foi bloqueado pela exigência de licença Cfx legítima
antes de carregar os recursos; não foi aprovado. Não foram executados natives
das funções, duas sessões GTA, dinheiro/vouchers reais, importação do estado
efetivo ou deploy. A compilação do inventário antigo
usa normalização in-memory de sua sintaxe estendida para stock-luac; isso não
comprova o runtime legado. A operação em jogo e a futura troca continuam
dependendo de homologação explícita no ambiente escolhido.
