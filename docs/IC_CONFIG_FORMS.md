# Formulários do IC Config

Esta revisão substitui a edição de JSON por campos, seletores, listas e captura
no jogo. Abrange as 17 áreas e 31 telas de `web/model.mjs:VIEWS`, incluindo
as três ações adicionais, junto do teleporte e do editor de Craft + Farm.
O envio inicialmente adiado em 29/10/2026 foi autorizado pelo proprietário em
30/10/2026. O resultado operacional é registrado no relatório privado da release.
Não houve alteração de banco, dependências de produção ou métodos de gravação.

## Evidências e classificação

- **ESTABLISHED:** os contratos são os exports existentes dos recursos da cidade,
  adaptados em `resources/[scriptcore]/ic_config/server/adapters.lua`. O novo
  formulário continua usando `model.mjs:mutationFor` para gerar esses payloads.
- **ESTABLISHED:** o preenchimento anterior foi comparado com o JavaScript
  legível de `resources/[scriptcore]/mg_config_panel/web/app.js`, pelos símbolos
  abaixo, e com os arquivos versionados de configuração dos recursos.
  Não foi necessário executar o painel do fornecedor ou autenticar nele.
- **ENFORCED:** autorização e validação permanecem no servidor; modo de leitura,
  cancelamento e falha de catálogo bloqueiam gravação pela interface. Capturar
  posições ou roupas para o formulário atualiza somente o rascunho.
- **INFERRED:** propriedades adicionais que não têm esquema explícito são
  apresentadas pelo tipo observado: número, texto, checkbox, grupo ou lista.
  Seus nomes podem ser técnicos; seus valores existentes são preservados.
- **EXCEPTION:** o formulário antigo permitia editar webhooks. Credenciais e
  destinos privados continuam administrados exclusivamente no servidor. A tela
  de logs das residências explica isso e não expõe esses valores.
- **EXCEPTION:** sprites usam código com sugestões, e cores têm seletor. O
  catálogo visual completo de ícones do fornecedor não foi reconstruído.

O detector do projeto não identificou Spring ou Angular. A implementação segue
o recurso FiveM existente: Lua e NUI em módulos JavaScript, sem novos frameworks.

## Comparação por tela

Todos os nomes de função da coluna anterior se referem a `mg_config_panel/web/app.js`.
Os novos esquemas estão em `ic_config/web/form-schema.mjs:FORM_SCHEMAS`, exceto
os editores próprios indicados na tabela.

| Área / tela | Evidência anterior | Preenchimento no IC Config |
| --- | --- | --- |
| Cargos | `groupForm` | Nome, tipo com sugestões, salário opcional, PTR com três estados, título, organização e lista de permissões. Permissão inicial sugerida pelo nome ao criar. |
| Criar organização | `facForm` | Organização, tipo com sugestões, item da meta buscável, quantidade e recompensa. Exclusão mantém nome exato e prévia de impacto. |
| Baús | `chestForm` | Nome fixo na edição, capacidade, permissão, XYZ manual ou capturado. |
| Craft + Farm | `craftForm` | `craft.mjs:mountCraftForm`: receitas, produtos e materiais buscáveis, quantidade, tempo, armazém, permissões e múltiplas recompensas do farm. |
| Pontos de garagem | `garageForm` | Seletor de tipo, identificador, permissão, distância, posição e lista de vagas XYZ/direção com captura. |
| Tipos de garagem | `typeForm` | Público/serviço, blip, checkboxes de classes ou lista de veículos buscáveis com livery opcional. |
| Marcações do mapa | `mapMarkingForm` | Nome, sprite com sugestões, cor, escala, proximidade e XYZ capturável. |
| Fardamentos | `cloakroomForm` | Nome, permissão, posição, lista de uniformes e captura da roupa atual. Capturar um gênero preserva o outro. |
| Lojas | `shopForm` | Compra/venda, permissão, pagamento em mãos, itens buscáveis com preços, lista de pontos e configuração de blip. |
| Lojas de roupa | `clothingForm` | XYZ manual ou capturado. |
| Barbearias | `barbershopForm` | XYZ manual ou capturado. |
| Estúdios de tatuagem | `tattooForm` | XYZ manual ou capturado. |
| Desmanches | `desmancheForm` | Permissão, exigência de item, lista item/quantidade, quatro posições e direção das ferramentas. Nova ficha mantém a linha inicial lockpick do formulário anterior. |
| Regras do desmanche | `desmancheSettingsForm` | Percentuais numéricos e checkboxes para veículo próprio/de trabalho. |
| Zonas seguras | `safeZoneForm` | Lista de polígonos, minZ/maxZ, lista de vértices XY e desenho no jogo. |
| Regras das zonas | `safeZoneSettingsForm` | Integrações, intervalo e lista de exceções com cargo, seletor de zona e graduação. |
| Empregos | `jobForm` | Total de níveis, início capturável, XP e pagamentos por nível, uniforme e campos das opções específicas. Rotas têm pontos; itens e veículos usam busca quando aplicável. |
| Central de empregos | `jobsGlobalForm` | Central e NPC como posições capturáveis, incluindo direção do NPC. |
| Locais de roubo | `robberyLocationForm` | Tipo existente, ID, XYZ e direção. |
| Tipos de roubo | `robberyTypeForm` | Tempos, policiais, recompensas item/mínimo/máximo e requisitos item/quantidade. |
| Regras dos roubos | `robberyGlobalForm` | Permissão policial, lista de permissões bloqueadas e duração do blip. |
| Banco Central | `bancoCentralForm` | Regras, itens, bolsas, posições de furadeira, bancos, portas, solda opcional, cofres, dinheiro e câmeras em campos e listas. |
| Joalheria | `joalheriaForm` | Regras, itens, posições de hacking/C4, recompensas, vitrines e campos adicionais. |
| Cofres | `roubocofreForm` | Regras, itens, bancos nomeados, porta, início do roubo e pilha de dinheiro. |
| Residências | `residenceForm` | Casa/apartamento, interior filtrado por tipo, preço, vagas, valorização e posição. |
| Interiores | `residenceInteriorForm` | Nome, tipo, melhorias, moradores, capacidades e posições de entrada/baú/guarda-roupas. |
| Logs das residências | `residencesSettingsForm` | Aviso sobre administração privada dos destinos de log. |
| Mansões | Reconstrução própria já existente | `mansions.mjs:mountMansionForm`: campos, garagem, acessos, portas e captura; sem editor JSON. |
| Estoque da concessionária | `dealershipVehicleForm` | Busca no catálogo de veículos e estoque; spawn fixo ao editar. |
| Catálogo de veículos | `serverVehicleForm` | Spawn, nome, preço, porta-malas, categoria sugerida e bloqueio. Exclusão em lote usa seleção de veículos. |
| Regras da concessionária | `dealershipSettingsForm` | Percentuais, limites, comandos, cooldowns, VIPs, categorias, ranking e posições do test drive em listas/campos. |

Algumas partes do painel anterior já ofereciam JSON avançado, especialmente
roubos, concessionária e opções dos empregos. Essas partes também foram
convertidas em controles por tipo; não foi mantida uma caixa de JSON obrigatório.

## Componentes e preservação

- `web/forms.mjs:mountStructuredForm` monta os controles e valida números,
  quantidade mínima de registros e intervalos. Campos condicionais preservam
  os dados que estão ocultos. Posições usam números finitos; direções podem ser
  opcionais quando o recurso admite vetor de três componentes.
- `web/catalog-picker.mjs:catalogPicker` pesquisa por nome/código sem distinguir
  acentos. Registros antigos fora do catálogo são identificados e preservados.
  Busca não envia o formulário ao pressionar Enter. Seleção pendente precisa
  ser concluída ou cancelada antes de salvar.
- `web/form-schema.mjs:CATALOG_METHODS` solicita somente os catálogos de cada
  editor. Ações de prévia/exclusão não carregam catálogos desnecessários.
- Uniformes e posições capturados são aplicados ao rascunho; Cancelar descarta
  a alteração. Respostas atrasadas de carregamento não reabrem um editor fechado.
- Campos adicionais públicos permanecem no payload. Chaves privadas e chaves
  de protótipo são filtradas. Não há conversão do texto de um textarea em objeto.

## Validação reproduzível

```bash
node --test tests/ic_config_web.test.mjs tests/ic_config_craft.test.mjs tests/ic_config_forms.test.mjs tests/ic_mansions_web.test.mjs
python3 -m unittest discover -s tests -p 'test_ic_config*.py' -v
```

Para os testes reais de navegador, apontar `IC_CONFIG_PLAYWRIGHT_MODULE` para
o módulo Playwright já disponível e, se necessário,
`IC_CONFIG_BROWSER_EXECUTABLE` para o Chrome instalado. Não é preciso instalar
dependências de produção:

```bash
node --test --test-concurrency=1 tests/ic_config_browser.test.mjs tests/ic_config_craft_browser.test.mjs tests/ic_config_forms_browser.test.mjs tests/ic_config_transparency_browser.test.mjs
```

`tests/ic_config_forms_browser.test.mjs` abre todas as 29 telas padrão e verifica
ausência de edição JSON, ausência de transbordamento e payload sem alteração ao
salvar uma configuração existente. Também verifica as oito variantes de emprego,
edição com seletores, preços, posições, uniforme, níveis, veículos de serviço,
cancelamento, falha de catálogo e modo de leitura. Craft e mansões possuem suítes
próprias. As fixtures vêm apenas das configurações versionadas, filtradas antes
de entrar na página; não usam dados de produção.

Os testes da NUI simulam RPCs. Não comprovam natives FiveM nem interação dentro
do GTA. A revisão do painel anterior foi estática, sem sessão autenticada. Esses
limites permanecem para a homologação no jogo após o envio conjunto autorizado.

Resultados locais: 27 testes Node aprovados; cinco testes de navegador aprovados
(incluindo a matriz das 29 telas e transparência dos dois recursos); 22 testes
Python/Lua aprovados e sete opcionais ignorados. Os opcionais exigem ambiente
específico, como MariaDB/FXServer, e não foram ativados nesta revisão de frontend.
`git diff --check` passou. Capturas em 1440×1000 e 720×900 foram inspecionadas.
Não houve homologação dentro do GTA nestes testes. A publicação no Uriel usa
o instalador com backup, restauração de ensaio e verificação operacional.

## Arquivos da melhoria

Os caminhos abaixo são relativos à raiz da base. Incluem o editor de Craft +
Farm incluído junto desta revisão.

| Arquivo | Mudança |
| --- | --- |
| `resources/[scriptcore]/ic_config/web/app.mjs` | Integra editores próprios e padrão; remove editor JSON e protege cancelamento durante carregamento. |
| `resources/[scriptcore]/ic_config/web/model.mjs` | Notas, modo inicial de loja, linha inicial do desmanche e tela privada de logs residenciais. |
| `resources/[scriptcore]/ic_config/web/index.html` | Carrega os estilos dos novos formulários. |
| `resources/[scriptcore]/ic_config/web/form-schema.mjs` | Campos e catálogos por tela, condições e nomes legíveis. |
| `resources/[scriptcore]/ic_config/web/forms.mjs` | Seletores, listas, polígonos, posições, uniformes, níveis e validação. |
| `resources/[scriptcore]/ic_config/web/catalog-picker.mjs` | Busca e seleção local por nome/código. |
| `resources/[scriptcore]/ic_config/web/forms.css` | Layout responsivo dos controles e busca. |
| `resources/[scriptcore]/ic_config/web/craft.mjs` | Formulário de bancada/farm, receitas, armazém e seleção de itens. |
| `resources/[scriptcore]/ic_config/web/craft.css` | Estilos do editor de receitas. |
| `tests/ic_config_form_fixtures.mjs` | Configurações públicas versionadas para a matriz de formulários. |
| `tests/ic_config_forms.test.mjs` | Esquemas, caminhos seguros, números e inferência de campos. |
| `tests/ic_config_forms_browser.test.mjs` | Matriz, preservação, edição, cancelamento e falhas na NUI real. |
| `tests/ic_config_craft.test.mjs` | Preservação e validação do editor de receitas. |
| `tests/ic_config_craft_browser.test.mjs` | Uso dos seletores e capturas no editor de receitas. |
| `tests/ic_config_browser.test.mjs` | Fluxos existentes usando os novos controles. |
| `tests/ic_config_transparency_browser.test.mjs` | Serve os módulos novos no teste de composição/transparência. |
| `docs/IC_CONFIG.md` | Atualiza a descrição do preenchimento e do editor de receitas. |
| `docs/IC_CONFIG_FORMS.md` | Comparação, evidências, validação e limites desta revisão. |
| `scripts/prepare-ic-config-release.py` | Inclui este comparativo e aceita baseline explícita da release publicada para preservar trabalho alheio, mesmo já commitado. |
| `tests/test_ic_config_package.py` | Verifica preservação da branch, índice e alterações alheias locais ou commitadas. |
