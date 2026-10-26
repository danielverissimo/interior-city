# Interior City no Uriel

O desenvolvimento continua em `code/Base`. Cada implantação copia um arquivo Git do commit para `/opt/uriel/interior-city/releases/<commit>`, sem `cache/` nem `.replxx_history`. O executável Windows não entra na imagem. Os binários Linux oficiais de FXServer e Playit são baixados e verificados por SHA-256 durante o build.

## Estrutura

| Caminho no Uriel | Finalidade |
| --- | --- |
| `current` | Link para o release ativo |
| `releases/<commit>` | Arquivos da base e recursos existentes |
| `state/txData` | Configurações, perfis e logs do txAdmin |
| `state/cache` | Cache do FXServer |
| `state/manifests` | Checksums para detectar edições do txAdmin |
| `secrets` | Arquivos privados usados como Docker secrets |
| `backups` | Dumps locais do banco e cópias do txData |
| `.env` | Endereços Playit e caminho do release, sem credenciais |

O Compose tem MariaDB, FXServer/txAdmin, Playit e backup. Há um quinto serviço opcional, Caddy, para o endpoint HTTPS: [Playit encaminha TLS, mas não o termina](https://playit.gg/support/https-tunnel/). Ele inicia quando `PLAYIT_HTTPS_HOST` estiver configurado. Banco e jogo não publicam portas no host. Apenas txAdmin usa `127.0.0.1:40120`. Playit e Caddy compartilham a rede do FXServer e alcançam as portas locais 30120 e 8443. Não há Docker socket ou GPU nos contêineres.

## Preparação única

1. Obtenha **novas** chaves Cfx, Steam Web API (se necessária) e Playit Premium. Revogue as antigas expostas no histórico. Conclua conta, pagamento e autenticação na interface dos provedores. Não coloque as chaves no Git, em argumentos de linha de comando ou neste documento.
2. Copie `scripts/prepare-uriel-secrets.sh` para o Uriel e execute com `sudo bash`. Ele gera senhas independentes do banco e pede as demais chaves sem eco no terminal. Steam e webhooks podem ficar vazios. A pasta de secrets no host é `root:root` modo 0700. Os arquivos ficam 0444 porque o Compose monta arquivos preservando seu modo e FXServer/Playit rodam sem root; a pasta privada impede acesso direto por outros usuários do host. Cada serviço recebe somente os secrets declarados para ele.
3. Confira `/opt/uriel/interior-city/.env`: `INTERIOR_CITY_RELEASE_PATH=/opt/uriel/interior-city/current`. Deixe os dois `PLAYIT_*` vazios na primeira inicialização.

O SQL é montado em `/docker-entrypoint-initdb.d/01-base.sql` e roda **somente com o volume MariaDB vazio**. Ele contém `DROP DATABASE IF EXISTS vrp`: nunca o execute manualmente num banco vivo. O jogo usa a conta própria `vrp`, e a URI do `oxmysql` preserva `multipleStatements=true`. Trocar a senha de um banco existente exige alterar também o usuário SQL; substituir só o arquivo secret não faz essa rotação.

## Release e txAdmin

1. Faça commit local. Rode `scripts/deploy-uriel.sh --prepare` para inspecionar o pacote sem mudanças remotas. Após a aprovação da implantação, rode `scripts/deploy-uriel.sh --apply <commit>` numa árvore de trabalho limpa. O script transfere o pacote por SSH/Tailscale e solicita `sudo` no Uriel.
2. No primeiro início, abra o painel por `ssh -L 40120:127.0.0.1:40120 danyelsanches@100.124.79.57` e acesse `http://127.0.0.1:40120` localmente. No txAdmin, selecione os arquivos existentes em `/server-data` e `server.cfg`. Não escolha uma receita que substitua os recursos. Mantenha 7 vagas.
3. Em atualizações, o instalador compara o release ativo ao manifesto original. Alterações feitas pelo editor do txAdmin interrompem a implantação para revisão. Ele para FXServer/Playit, salva banco e txData, troca `current`, constrói e inicia a nova versão. Se a subida falhar, tenta restaurar o link e os contêineres anteriores. O diretório do release anterior permanece. Rollback de código **não** desfaz alterações no banco.

Reconcilie alterações feitas no txAdmin com os arquivos locais antes da próxima implantação. O script de instalação deve vir do mesmo commit implantado.

## Playit e listagem

Depois que o agente aparecer na conta Playit, crie dois túneis nele:

1. **FiveM TCP+UDP**, origem `127.0.0.1:30120`. Anote IPv4 e porta públicos em `PLAYIT_PUBLIC_ENDPOINT` no `.env` do Uriel.
2. **HTTPS**, origem `127.0.0.1:8443`, associado a um domínio Playit. Coloque somente o hostname em `PLAYIT_HTTPS_HOST`. O Caddy obtém certificado pelo túnel TLS transparente e encaminha ao FXServer em 30120. Verifique seus logs antes de divulgar o endereço.

Defina ambos os valores juntos e recrie os serviços. O entrypoint gera `sv_forceIndirectListing`, `sv_listingHostOverride` e `sv_endpoints` em tmpfs, seguindo o [fluxo de proxy Cfx](https://docs.fivem.net/docs/server-manual/proxy-setup/). `sv_endpoints` deve receber **IPv4:porta**, não o hostname Playit. Se a listagem não aparecer após o período normal de atualização, use conexão direta temporária pelo endereço Playit e registre a limitação. O guia FiveM da Playit mostra conexão direta, sem garantir listagem.

Não exponha o txAdmin pela Playit. Acesse-o por SSH/Tailscale. Nenhuma porta do roteador precisa ser encaminhada.

## Backup, restauração e aceite

O contêiner de backup gera `mariadb-dump` comprimido ao iniciar e a cada 24 horas; mantém sete dias em `backups` no Uriel. Antes de cada implantação posterior, também arquiva txData. Verifique `*.sha256` e `gzip -t` antes de restaurar. Backups apenas nesse host não cobrem perda do disco.

Restaure num volume de banco isolado ou parado, após uma cópia de segurança atual. O dump inclui `CREATE DATABASE vrp`; descomprima e importe por `mariadb -uroot`, depois confira as 15 tabelas e registros representativos. Restaure txData em diretório vazio, com FXServer parado.

Após a aprovação: validar Compose, contar 15 tabelas, ler logs de inicialização dos recursos, reiniciar e confirmar persistência, restaurar um backup em volume isolado, confirmar 40120 somente no loopback, testar `https://<domínio-Playit>/info.json` e `/client` de uma rede externa, entrar com um cliente FiveM real, verificar TCP/UDP e confirmar listagem e botão **Conectar**. Contêiner ativo sozinho não prova que o jogo ou o túnel funcionam.
