# Docker da nova base no Uriel

Esta implementação pertence à branch `migration/tocado-mago`. A `master` anterior não recebe merge e permanece preservada até a futura troca da branch principal. Os comandos abaixo preparam e implantam **apenas a nova base**; não executam essa troca de branches.

## Estrutura isolada

| Item | Nova base |
| --- | --- |
| Diretório no Uriel | `/opt/uriel/interior-city-tocado` |
| Projeto Compose | `interior-city-tocado` |
| Releases | `releases/<commit>` e link `current` |
| txAdmin | `127.0.0.1:40121` no host; 40120 dentro do contêiner |
| Jogo | TCP/UDP 30120 dentro do contêiner; sem porta publicada no host |
| Banco | MariaDB 10.11.19; volume próprio; usuário `vrp`; sem publicar 3306 |
| Estado | `state/txData`, `state/cache`, `state/manifests` |
| Credenciais | `secrets/`, fora de releases e imagens |
| Backups | `backups/`, neste host, com retenção de sete dias |
| Assets | pacotes privados em `/srv/diskaux/interior-city-assets/tocado-mago` |

O Compose contém FXServer Linux/txAdmin, MariaDB, backup e os serviços opcionais Playit e Caddy. O artefato FXServer e o agente Playit têm versão/checksum fixados nos Dockerfiles. Os contêineres não recebem Docker socket, GPU nem binários Windows. O jogo permanece fora da listagem pública.

## Credenciais locais

Requisitos das ferramentas: Python 3.10+, Git e SSH; no Uriel, Docker Compose e os utilitários Linux já usados nos scripts. Não há nova biblioteca Python nem instalação de componente de jogo no Ubuntu.

```bash
./scripts/dev.sh init
python3 scripts/configure-secrets.py set cfx_license
python3 scripts/configure-secrets.py set steam_web_api
python3 scripts/configure-secrets.py check
```

A entrada interativa fica oculta. `secrets/` tem modo 0700; arquivos usados como Docker secrets ficam 0444 para leitura pelos contêineres sem root. O diretório privado protege o acesso no host. Os valores não entram em argumentos, Git, imagem ou `.env`. Não exponha o diretório privado por SMB.

Por decisão do proprietário, as licenças do pacote foram importadas temporariamente **somente nos arquivos privados deste checkout**, inclusive tokens de integrações reconhecidas quando não eram placeholders. A licença Cfx fornecida foi exposta durante a inspeção inicial; deve ser substituída antes da publicação. A importação não verifica validade, titularidade ou autorização dos provedores.

A importação explícita, para uma configuração nova, é:

```bash
python3 scripts/configure-secrets.py import-package /caminho/base-original --include-resource-licenses
```

O importador não copia webhooks do fornecedor, usuários/senhas do banco antigo, dados de jogadores ou chaves da base anterior. Senhas independentes do MariaDB são geradas por checkout. Não substitua os arquivos de senha de um banco já inicializado sem rotacionar também seus usuários SQL.

## Chaves dos recursos

O arquivo privado `secrets/resource_secrets.json` usa os nomes de [../config/resource-secrets.example.json](../config/resource-secrets.example.json). O catálogo de nomes/tipos fica em [../config/resource-secrets.schema.json](../config/resource-secrets.schema.json). Edite o arquivo privado e depois rode:

```bash
python3 scripts/configure-secrets.py render
python3 scripts/configure-secrets.py check
```

O renderer valida nomes/caracteres e produz o Docker secret `resource_convars`. O entrypoint o trata como dados e gera apenas comandos `set` em `runtime/secrets.cfg`, em tmpfs. Não utiliza `setr`/`sets`, nem executa CFG fornecido como secret. A conexão do oxmysql também é gerada em tmpfs, com `multipleStatements=true`.

Webhooks podem ser definidos por recurso (`ic_secret_<recurso>_webhook`) ou pelo fallback comum `secrets/webhook_logs`. Campos vazios do JSON são omitidos para permitir o fallback. Os envios existentes de um mesmo recurso usam esse destino comum; não preservam os diversos canais do fornecedor. Sem destino configurado, os envios adaptados são ignorados.

Smartphone, survival e integração de logs administrativos possuem campos privados próprios. Os valores são lidos apenas no servidor; os do smartphone não participam da serialização JSON. A configuração compartilhada de organizações deixa esses campos vazios no cliente. Roubos e residências resolvem o destino no envio do servidor, sem inserir o secret nos JSONs compartilhados. A tela administrativa antiga não é a fonte dessas chaves: altere o arquivo privado e recrie o FXServer.

Os recursos de terceiros e seus protocolos ainda precisam de auditoria; há integrações externas legadas com HTTP. A separação de credenciais não é homologação de segurança desses serviços.

## Preparar e implantar

Faça commit das alterações nesta branch. O deploy usa o commit informado, não arquivos soltos ou ignorados do checkout:

```bash
./scripts/deploy-uriel.sh --prepare HEAD
```

Esse comando cria/valida um arquivo temporário local sem enviar nada nem acessar o host. Depois da aprovação da configuração no Uriel:

```bash
./scripts/deploy-uriel.sh --configure HEAD
```

`--configure` envia os arquivos privados por SSH para uma pasta temporária 0700, pede `sudo`, inicializa o diretório isolado e remove a cópia temporária ao sair. Não inicia contêineres. Recusa substituir uma configuração privada existente diferente; rotações posteriores precisam ser feitas explicitamente. A preparação manual equivalente é `sudo bash scripts/prepare-uriel-secrets.sh`, seguida da configuração das chaves no diretório privado do Uriel.

Revise `/opt/uriel/interior-city-tocado/.env`: ele contém apenas configurações operacionais. `IC_ASSET_PROFILE=core` é o padrão para a primeira validação; `full` instala também veículos/roupas/mapas, mas não habilita seus `ensure` comentados. `ASSET_STORE` aponta para `/srv/diskaux/interior-city-assets`. O disco USB precisa estar montado antes de instalar uma release.

Após a aprovação do deploy:

```bash
./scripts/deploy-uriel.sh --apply HEAD
```

O instalador usa um lock para impedir deploys concorrentes, valida o arquivo, instala/verifica assets do catálogo e constrói a imagem antes de parar a versão atual. Detecta arquivos alterados, adicionados ou removidos no release anterior, inclusive alterações de recursos/txAdmin. Interrompe para revisão, sem sobrescrevê-los silenciosamente. O estado conhecido de cache/runtime fica fora do manifesto.

Quando já existe uma release, para os escritores e cria backup do banco e txData antes da troca. Atualiza `current` e aguarda os healthchecks. Se a subida falhar, tenta retornar ao código anterior; **não restaura o banco automaticamente**. Releases anteriores e volumes permanecem. O mesmo comando `--apply <commit-anterior>` permite rollback de código com as mesmas verificações. Não use o instalador da `master` antiga nesta base.

O SQL `database/schema.sql` contém 204 definições de tabelas, sem dados importados. A inicialização acontece somente em volume novo. Seeds necessários, compatibilidade de SQL/recursos e criação do primeiro usuário ainda precisam de validação; nunca aplique o dump bruto do fornecedor no banco vivo anterior.

## txAdmin e conexão de teste

Abra o painel privado por SSH:

```bash
ssh -L 40121:127.0.0.1:40121 danyelsanches@100.124.79.57
```

No navegador, use `http://127.0.0.1:40121`. Vincule sua conta e associe os arquivos existentes `/server-data` e `server.cfg`, sem receita que substitua os recursos. São sete vagas. O healthcheck da release verifica o painel txAdmin; não comprova boot do jogo nem entrada de jogador.

Playit só é iniciado quando os dois endereços `PLAYIT_PUBLIC_ENDPOINT` e `PLAYIT_HTTPS_HOST` estiverem configurados junto da chave privada `playit_agent_key`. Use agente/túneis próprios da nova base durante a coexistência: TCP/UDP para 30120 e HTTPS para 8443 no namespace do FXServer. Não reutilize os túneis ativos do ambiente anterior antes da troca deliberada. O txAdmin não é exposto pelo Playit. `FIVEM_LISTING_ENABLED=false` permanece obrigatório neste fluxo de desenvolvimento.

Para operar manualmente no host após uma release, use sempre a configuração isolada:

```bash
cd /opt/uriel/interior-city-tocado
sudo docker compose --env-file .env --project-directory . -p interior-city-tocado -f current/compose.yaml ps
sudo docker compose --env-file .env --project-directory . -p interior-city-tocado -f current/compose.yaml run --rm --no-deps backup once
```

O dump tem checksum SHA-256 e gzip verificado. A restauração deve ser testada em banco isolado com as mesmas credenciais, sem substituir o banco atual; backups no mesmo host não cobrem perda do disco inteiro. Verifique logs, persistência, restauração, HTTPS/UDP e entrada de um cliente FiveM real antes de considerar a nova base pronta. Listagem pública e a substituição da branch principal ficam para uma etapa posterior.

## Evidências desta implementação

| Classificação | Evidência |
| --- | --- |
| ENFORCED | Decisão do proprietário: não integrar na `master`, preservar o ambiente anterior, guardar credenciais fora do código |
| ESTABLISHED | `compose.yaml`, `docker/fxserver/Dockerfile` e `docker/backup/backup.sh`: contêineres, artefato Linux fixado e dumps já presentes na estrutura anterior |
| EMERGING | `scripts/install-uriel-release.sh` (`compose_at`, `restore_old`), `scripts/release.py` (`extract`, `manifest`) e `scripts/configure-secrets.py` (`render`): fluxo adaptado à nova base, validado em testes isolados |
| EXCEPTION | `resources/[vrp]/vrp_player/server.lua` já utiliza `+=`, extensão do CfxLua não aceita pelo `luac` padrão; não foi alterada para Lua convencional |

Na preparação desta alteração passaram 34 testes, incluindo geração privada da configuração, rejeição de injeção, não serialização dos tokens do smartphone, ausência de leitura privada no cliente, normalização Unicode, validação do arquivo de release e simulações de backup/troca/rollback. Nas simulações, Docker e comandos privilegiados são substitutos locais: nenhum contêiner é iniciado. Também passaram sintaxe Bash, JavaScript do smartphone, configuração Compose e verificação dos 439 assets `core`. O `luac` padrão aprovou 21 dos 22 arquivos Lua alterados; o restante tem a extensão preexistente mencionada acima, também rejeitada no commit anterior.

O detector não identificou Spring ou Angular. Não foram executados provisionamento/deploy reais, build nativo da imagem, importação do MariaDB, boot dos recursos, restauração real de backup ou conexão de jogador para esta versão. Não houve publicação no GitHub nem troca de branch principal. Esses são limites da validação, não etapas consideradas concluídas pelos testes das ferramentas.
