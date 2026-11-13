# Deploy automático da master no Uriel

O workflow `.github/workflows/deploy-uriel.yml` atende somente `push` na `master`
de `danielverissimo/interior-city` e execução manual nessa mesma branch. O runtime
continua no Uriel. O servidor infra executa um runner dedicado, sem Docker e sem
sudo, inscrito exclusivamente neste repositório pelo framework já instalado.

Fluxo: GitHub → runner no infra → SSH privado → receptor restrito no Uriel →
instalador existente. O Uriel abre um túnel SSH reverso persistente até o infra;
a porta `127.0.0.1:22247` do infra encaminha apenas ao SSH do Uriel. Nenhuma porta
pública adicional é aberta. As duas pontas verificam as chaves públicas dos hosts.
O usuário do túnel só pode encaminhar essa porta, sem sessão de terminal.

## Operação

- `URIEL_AUTO_DEPLOY_ENABLED=true`, variável do repositório, habilita publicação
  automática em novos pushes da master. Ausente ou diferente de `true`, o workflow
  executa apenas a verificação. Isso permite validar a instalação antes de ativar.
- Em **Actions → Deploy Uriel → Run workflow**, `validate_only=true` verifica rede,
  commit, estado persistente, segredos locais e disponibilidade dos objetos de
  assets, sem parar a cidade. `false` publica quando a variável acima está ativa.
- O receptor busca diretamente o repositório público e aceita apenas o SHA completo
  que é a master no momento da consulta. Não aceita tar enviado pelo runner, caminho,
  comando de shell ou branch arbitrária. Execuções antigas devem ser substituídas
  pela execução do commit mais recente.
- A fila do workflow não cancela um deploy em andamento. O receptor e o instalador
  também possuem locks no servidor.
- O instalador prepara a release e verifica assets antes da parada, preserva o estado,
  faz backup e ensaio de restauração, seleciona os provedores próprios e verifica
  runtime/healthchecks. As duas flags de transição são mantidas em atualizações;
  não significam reimportar repetidamente dados do legado.
- O deploy reinicia os serviços da cidade durante a troca. Não é uma implantação
  sem interrupção e pode desconectar jogadores.

Os arquivos de senha, `.env`, licenças, banco, dados dos jogadores e assets privados
permanecem no Uriel. Os jobs não recebem essas credenciais. Somente resumos sem dados
privados chegam ao log público; diagnósticos do instalador ficam em
`/var/lib/interior-city-actions/logs`, acessíveis por root.

## Instalação inicial explícita

`scripts/ci/setup-infra.sh` e `setup-uriel.sh` são comandos administrativos de
provisionamento, executados uma vez por operador autorizado, com material efêmero
em diretórios privados. Não são executados por pushes, testes ou pelo runner.
O registro usa o framework `/home/infra/bootstrap/infra-github-runners`, perfil
`basic`, sem alterar usuários/serviços dos demais projetos.

O infra recebe apenas token de registro temporário e chaves públicas. A chave
privada de deploy nasce no home do usuário exclusivo do runner. A chave privada
do túnel nasce no Uriel. Nunca coloque esses valores no GitHub, na documentação
ou em argumentos de comandos registrados em logs.

No Uriel são instalados o usuário `ic-deploy`, o comando forçado
`/usr/local/libexec/interior-city-ssh-command`, o receptor
`/usr/local/libexec/interior-city-actions` e uma regra sudo exclusiva para esse
receptor. Alterar o receptor exige uma nova instalação administrativa explícita;
o runner não modifica sua cópia privilegiada.

## Evidências e limites

| Classificação | Fonte e consequência |
| --- | --- |
| ESTABLISHED | `scripts/install-uriel-release.sh`: releases imutáveis, backup, locks, mounts e verificações de runtime já utilizados no Uriel. |
| ESTABLISHED | Framework do infra: usuário Unix, inscrição e serviço próprios para cada repositório. |
| ENFORCED | `scripts/ci/runner-deploy.sh` e `uriel-actions.py::parse_request/master_archive`: apenas repositório, eventos e master esperados; nenhum shell remoto arbitrário. |
| EXCEPTION | O repositório é público, enquanto o framework recomenda repositórios privados. Este runner usa conta própria sem Docker/sudo e não executa workflows de pull requests/forks. Não adicionar `pull_request` ou `pull_request_target` ao workflow de deploy. |
| CONFLICTING resolvido nesta entrega | A master não incluía suporte à listagem pública já ativa nem preservação do Spotify/mapa vazio de baús já usados no servidor. Esses trechos e seus testes acompanham a automação, para evitar regressão no próximo deploy. Também foi restaurada a leitura de webhooks de organizações por convars apenas no servidor; duas URLs privadas haviam retornado à configuração compartilhada na master. |

Validação de código, registro online, túnel funcional, verificação da candidata,
publicação efetiva e homologação no GTA são evidências diferentes. Um `check`
aprovado não comprova o build da imagem, aplicação de SQL, troca de release ou
entrada de jogadores. Assets novos ainda precisam ser publicados no armazenamento
privado antes do respectivo código.

Falha de prévia mantém a cidade em execução. Se houver falha depois de iniciar
escritores novos, o instalador pode parar a candidata e exigir correção orientada
pelos relatórios; não restaura o banco nem reativa automaticamente dados legados.
Não fazer retry de um deploy com efeitos parciais sem verificar o estado.
