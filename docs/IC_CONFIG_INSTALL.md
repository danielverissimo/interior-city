# Instalação explícita do IC Config e IC Mansions

Esta entrega substitui `mg_config_panel` e `m_mansions` por `ic_config` e
`ic_mansions`. Inclui as 17 áreas do painel, exclusão de organizações e o
sistema próprio de compra por vale, moradores, IPTU e mobílias.
O CFG do checkout mantém a seleção anterior. O instalador só seleciona os
recursos próprios dentro de uma candidata isolada, com `--ic-config-cutover`.

## Evidência e limites

**ESTABLISHED:** `scripts/install-uriel-release.sh` mantém releases imutáveis,
backup antes da troca e flags explícitas para schema. `compose.runtime.yaml`
mantém os cargos e o desmanche fora da release.

**ENFORCED nesta candidata:** `scripts/ic-config-cutover.py`, funções
`prepare`, `mark_starting` e `verify_runtime`, exigem escritores parados,
estado efetivo, restauração de ensaio, mounts persistentes e um só provedor.
O marcador `config/ic_config_release.json` impede instalação sem a flag.

**Limite de validação:** os testes Lua usam fronteiras FiveM/vRP simuladas;
os testes MariaDB usam bancos reais descartáveis. O ensaio nativo chegou ao
FXServer 35245, que exigiu uma licença Cfx legítima antes de carregar os recursos.
Esse teste foi ignorado por esse motivo; não houve execução das funções com
dois clientes GTA nem uso de dinheiro/vales reais. O relatório privado do
pacote distingue aprovado, ignorado e não executado. Não houve deploy.

## Gerar e revisar a candidata local

```bash
python3 scripts/prepare-ic-config-release.py \
  --output "$IC_CONFIG_PACKAGE" --validation-report "$IC_CONFIG_VALIDATION"
```

As duas variáveis são caminhos absolutos locais; o destino precisa ser novo.
O comando usa um índice Git temporário, inclui somente os caminhos da entrega
e cria uma referência local `codex/ic-config-candidate-<sha>`. Não modifica
HEAD, branch atual, índice padrão ou a alteração alheia em `m_patrulha.sql`.
Não faz push, SSH, upload ou deploy. Só admite os slots vazios de distribuição.

O diretório privado contém `candidate.json`, `validation.json`,
`release.tar.gz`, `source-manifest.json` e `provider-preview-manifest.json`.
O manifesto de prévia representa apenas a seleção dos provedores; o manifesto
final do servidor será selado depois de baixar os assets e renderizar suas URLs.
Assets grandes continuam separados do arquivo de código.

```bash
./scripts/deploy-uriel.sh --prepare "$IC_CONFIG_CANDIDATE" \
  --ic-admin-cutover --ic-config-cutover
```

`IC_CONFIG_CANDIDATE` é o SHA completo registrado em `candidate.json`.
Esse comando inspeciona o commit local e renderiza uma prévia temporária;
não acessa o host. As duas flags são necessárias nesta base porque o IC Admin
também está em modo ativo. A versão efetiva continua a anterior.

## Homologação necessária antes da troca

Em um servidor de homologação com licença Cfx válida e clientes GTA, validar:

1. Boot com somente os provedores próprios e leitura das 17 áreas.
2. Permissões de dono/developer/admin; revogação com NUI aberta e payload
   forjado; dois administradores disputando a mesma revisão.
3. Compra por vale, moradores offline, limite incluindo dono, IPTU/vencimento,
   mobília com preço alterado, cancelamento, venda e limpeza confirmada.
4. Exclusão e retomada de organização com membros offline, bloqueio de usuários
   online afetados, projeções, criação legítima posterior e restart intermediário.
5. Reinício e próxima release conservando cargos, ocupação, datas, mobílias e
   configurações; falhas reais dos exports e timeout depois de efeito econômico.
6. Snapshot/backup desse ambiente e restauração isolada, preservando os diários
   de operações e os efeitos observados. Não restaurar sobre produção para testar.

Os marcadores operacionais verificam boot, schema e mounts. Não certificam
compra, inventário, garagem, portas ou o comportamento de um jogador.

## Aplicação futura, após aprovação de deploy

Use um checkout limpo da candidata. O preparador de pacote preserva as mudanças
locais, e o comando `--apply` mantém a exigência preexistente de checkout limpo.
Não mova nem descarte a alteração de outro trabalho para satisfazer esse gate.
Um worktree separado da candidata atende esse requisito.

```bash
./scripts/deploy-uriel.sh --apply "$IC_CONFIG_CANDIDATE" \
  --ic-admin-cutover --ic-config-cutover
```

Esse é um comando de deploy, mostrado para revisão; não foi executado nesta
entrega. Credenciais e licença são fornecidas pelos arquivos privados já
configurados no host, nunca pelo pacote. Não execute `--configure` para copiar
credenciais por causa desta atualização.

O instalador realiza a sequência:

1. Verifica a release anterior. Aceita somente mudanças JSON nas configurações
   conhecidas, catálogo legado e estado IC Admin explicitamente autorizado.
   Código alterado, arquivo removido/adicionado e symlinks são recusados.
2. Extrai a candidata, verifica assets/segredos, renderiza URLs e seleciona os
   recursos próprios antes de selar seu manifesto. Valida/builda o Compose.
3. Para FXServer/proxy/túnel; faz backup do banco, KVP e estado persistente.
   O helper confirma pelo Docker que o único FXServer gerenciado está parado.
4. Descobre as fontes pelos mounts efetivos do container parado. Não usa os
   padrões da release para substituir arquivos que já estão montados.
5. Na primeira troca, importa as mansões legadas uma vez. Conserva IDs,
   ocupantes, preço pago, mobílias e datas; não renova IPTU nem reproduz compras.
   Em atualizações posteriores lê os slots próprios atuais e seu checksum;
   não reimporta o legado. Configurações ausentes/incompatíveis interrompem.
6. Restaura o dump recente com checksum válido em banco descartável isolado,
   aplica duas vezes/verifica o schema próprio e compara os dados preservados.
   Só depois aplica a migração aditiva no banco efetivo e prepara os mounts.
7. Registra a fase `starting` antes de iniciar escritores. Após o boot, verifica
   marcadores dos dois recursos, ausência dos provedores antigos, schema e os
   28 mounts de arquivos com escrita. Registra `active` somente se tudo passar.

## Persistência e backup

Sob a raiz gerenciada `/opt/uriel/interior-city-tocado`, os caminhos canônicos são:

| Conteúdo | Caminho relativo à raiz |
| --- | --- |
| Cargos vRP | `state/resources/vrp/groups.json` |
| Desmanche | `state/resources/m_desmanche/config.json` |
| Demais 26 JSON, incluindo slots e catálogo próprios | `state/resources/ic_config/data/<caminho relativo do recurso>` |
| Snapshot privado da preparação | `state/ic-config/prepare-<sha>/snapshot` |
| Overlays específicos de cada release | `state/ic-config/overlays/<sha>.yaml` |
| Relatório e seleção operacional | `state/ic-config/<sha>.json`, `state/ic-config/selection.json` |

Cada mount recusa origem ausente (`create_host_path: false`). Arquivos recebem
0600 e UID/GID 1000. Arquivo persistente existente que diverge da fonte
autoritativa exige reconciliação; não é sobrescrito. O overlay da release
anterior inclui somente destinos que já existem nela.

Os backups posteriores à seleção própria incluem o controle em
`/ic-config-control`, além de banco, KVP e `resource-state`. O primeiro backup
anterior à troca ainda pertence à release antiga; a captura privada complementa
o registro das fontes e da importação. Snapshots e relatórios operacionais têm
identificadores de jogadores e nunca devem ser publicados.

O helper genérico `ic-config-state.py` continua útil para ensaios manuais e
gera `compose.ic-config.yaml`. Esse arquivo não é o overlay consumido pelo
instalador: o fluxo integrado cria os overlays específicos descritos acima.

## Falha e recuperação

Antes de `mark-starting`, uma falha restaura o código anterior e o reinicia.
DDL aditivo já aplicado não é desfeito. Os mounts da release anterior apontam
para o estado compartilhado quando ele já foi preparado.

A partir de `mark-starting`, uma falha para os serviços da candidata e conserva
o código/estado para inspeção. Não volta automaticamente ao legado: operações
podem ter acontecido depois do boot. Verifique o relatório, a seleção, os
diários SQL/KVP, os slots próprios e os efeitos econômicos antes de reconciliar.
Prefira uma nova candidata corrigida com as mesmas flags e fontes atuais.
Restaurar o código antigo ou um snapshot prévio isoladamente pode perder
compras, moradores e alterações de organizações.

Uma pasta `prepare-<sha>` existente bloqueia nova preparação do mesmo SHA.
Inspecione a fase e seus arquivos: uma interrupção pode ter ocorrido entre DDL,
cópia e relatório. Não apague a pasta nem os arquivos persistentes para forçar
uma repetição. Uma candidata corrigida usa outro SHA; divergências operacionais
continuam exigindo reconciliação explícita.
