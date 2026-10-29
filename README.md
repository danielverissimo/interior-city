# Interior City — base TocadoMago

Este repositório separa código e pacotes de assets da base fornecida. O código principal fica em `/Users/danyelsanches/Documents/projetos/interior_city/code/Base`, na branch `master`, promovida de `migration/tocado-mago` sem merge com a base anterior. O diretório Git é local a esta pasta; não depende da antiga worktree no SSD. O pacote original permanece preservado.

As medições, verificações e pendências desta importação estão em [docs/SEPARACAO.md](docs/SEPARACAO.md).

O fluxo Docker, as chaves privadas e o deploy da nova base estão em [docs/URIEL_DOCKER.md](docs/URIEL_DOCKER.md). A substituição local da branch principal não altera o GitHub nem a versão em execução no Uriel. A homologação com jogadores e dos sistemas da cidade continua sendo uma etapa separada da validação de infraestrutura.

## Organização

| Caminho | Conteúdo |
| --- | --- |
| `resources/` | Lua, configurações, manifests e interfaces, incluindo metadados editáveis dos veículos/mapas |
| `assets.lock.json` | Pacotes imutáveis e roster SHA-256 de cada arquivo de asset |
| `database/schema.sql` | Estrutura extraída sem INSERTs, dados de jogadores ou comandos de remoção do banco |
| `docs/import-redactions.json` | Localizações e contagens das remoções de credenciais, sem seus valores |
| `docker/`, `compose*.yaml` | Infraestrutura Linux reaproveitada, com banco novo e volumes próprios |
| `scripts/assets.py` | Inventário, envio, instalação e verificação dos pacotes privados |

Veículos, roupas, mapas, mídias e binários são distribuídos pelo armazenamento privado. `resources/` não é ignorado por completo: os scripts, manifests, `.meta`, XML de configuração e demais configurações permanecem no Git. XML de modelagem (como `*.yft.xml`) acompanha os assets. Os diretórios `build`/`dist` das NUIs não são excluídos genericamente, pois alguns recursos já são fornecidos compilados.

O FXServer Windows, crashes, cache, estado de txAdmin/LevelDB, arquivos `.env` e `config/keys.cfg` não são importados para o Git. Os valores sensíveis identificados foram removidos do código; os consumidores adaptados leem a configuração privada no servidor. As concessões administrativas ligadas a identidades do fornecedor no CFG também foram removidas. Isso não constitui auditoria de segurança de todos os recursos; a origem/licença dos componentes de terceiros ainda exige revisão antes de redistribuição ou execução.

## Instalar os assets

Requisitos: Python 3.10+, SSH e acesso ao armazenamento privado, quando utilizado. Somente a biblioteca padrão é necessária. Copie `.assets-store.example.json` para `.assets-store.json` e configure seu destino privado; esse arquivo é ignorado pelo Git. Também é possível definir `ASSET_STORE` ou passar `--store`.

```bash
python3 scripts/assets.py sync --profile core
python3 scripts/assets.py verify --profile core
```

`core` instala os assets dos recursos de scripts, interfaces e sistemas. `full` inclui também os grupos `[veiculos]`, `[roupas]` e `[mapas]`. Esses perfis selecionam arquivos para instalação; não comprovam que um conjunto parcial é jogável nem alteram a ordem dos `ensure` do fornecedor.

```bash
python3 scripts/assets.py sync --profile full
python3 scripts/assets.py verify --profile full
```

O instalador verifica espaço físico, checksum do pacote e roster de seus membros antes de gravar. Recusa links, caminhos que escapem do destino, arquivos extras e assets locais modificados. Não remove arquivos automaticamente. Para trocar uma versão com remoções de assets, utilize um novo diretório de release/checkout, evitando sobras da versão anterior.

O perfil completo exige espaço para os assets ausentes, um pacote temporário e 1 GiB de reserva. O Mac e o SSD estavam com pouco espaço na separação; não baixe `full` sem resolver essa capacidade. Montagem SMB deve servir para distribuição/gestão dos pacotes; o jogo deve usar uma cópia local quando for executado.

## Atualizar os pacotes

O comando de preparação destina-se a uma nova importação e não sobrescreve um catálogo existente:

```bash
python3 scripts/assets.py prepare --source /caminho/base-original --destination /caminho/checkout-novo
python3 scripts/assets.py publish --source /caminho/base-original
```

Os pacotes são divididos por recurso em partes de aproximadamente 512 MiB sem compressão. O ID deriva do roster de caminhos, tamanhos e hashes; o transporte usa tar/gzip determinístico. O envio ao Uriel ocorre por streaming SSH, sem criar outra cópia integral no Mac. O servidor valida cada arquivo do pacote antes de concluir o armazenamento e devolve um recibo com SHA-256. Objetos concluídos são imutáveis; a publicação pode retomar pacotes já concluídos. Mantenha cópia independente do armazenamento do Uriel.

## Docker e estado da migração

A imagem utiliza o artefato Linux oficial com versão/checksum fixados. O Compose aponta apenas para `database/schema.sql`; as migrações da base anterior não se aplicam automaticamente aqui. O seed do fornecedor não foi executado e precisa ser revisto para separar dados necessários de dados privados. Não importe esse esquema no banco vivo da base anterior.

O script de desenvolvimento usa um projeto Compose distinto, portas locais **30121/40121** e, no Mac, um perfil Colima próprio chamado `interior-city-tocado`. Não copia credenciais nem volumes do ambiente anterior. As licenças fornecidas no pacote foram carregadas temporariamente nos arquivos privados por solicitação do proprietário; a validade ainda depende dos provedores.

```bash
./scripts/dev.sh init
./scripts/dev.sh mac-start  # somente no Mac Apple Silicon
./scripts/dev.sh set-license
./scripts/dev.sh config
./scripts/dev.sh up
```

Antes de `up`, instale/verifique os assets do perfil escolhido e revise a compatibilidade dos recursos, dependências, seeds e credenciais. A configuração preserva a ordem de recursos fornecida; nenhuma receita foi aplicada. Os scripts desta branch integram código e assets em releases isoladas no Uriel. A execução da nova base ainda precisa de homologação; não use o instalador da branch anterior.

## Painéis administrativos no Uriel

O `server.cfg` carrega `config/config.cfg`, que executa [config/resources.cfg](config/resources.cfg). Esse arquivo já inicia os painéis nesta ordem quando o FXServer sobe:

```cfg
ensure m_paineladm_v2
ensure mg_config_panel
```

Para aplicar esses comandos no servidor em execução, abra um túnel SSH no Mac e mantenha o terminal aberto:

```bash
ssh -L 40121:127.0.0.1:40121 danyelsanches@100.124.79.57
```

Acesse `http://127.0.0.1:40121`, entre no txAdmin, abra **Console** e execute as duas linhas acima, uma de cada vez, na mesma ordem. É necessário ter permissão de escrita no console. O comando `ensure` inicia um recurso parado ou reinicia um recurso já iniciado; portanto, os painéis podem ficar brevemente indisponíveis. Consulte também [txAdmin e conexão de teste](docs/URIEL_DOCKER.md#txadmin-e-conexão-de-teste) e os [comandos oficiais da Cfx](https://docs.fivem.net/docs/server-manual/server-commands/).

## IC Admin próprio

O novo recurso está implementado em `resources/[scriptcore]/ic_admin`, com as
15 áreas, serviços próprios, importador e testes. Consulte
[implementação, contratos e operação](docs/IC_ADMIN.md).

A configuração entregue inicia em **preview**: `/icadmin` (F10) permite a
homologação após preparar o esquema em banco isolado. Mutações e serviços globais
continuam bloqueados até a troca operacional explícita. O provedor anterior
permanece selecionado; nenhum deploy ou migração do banco efetivo foi executado.
A independência completa e o vídeo entre dois jogadores exigem homologação GTA
com o painel antigo parado antes da troca no Uriel.

## Validação das ferramentas

```bash
python3 -m unittest discover -s tests -v
bash -n scripts/dev.sh
./scripts/dev.sh config
git diff --check
```

Os testes cobrem separação, SQL sem dados, remoção de credenciais, arquivos originais preservados, hashes, pacote determinístico, rejeição de corrupção/alteração, links e caminhos inseguros. Validação de bytes não comprova execução do jogo, segurança dos scripts ou direitos de redistribuição.
