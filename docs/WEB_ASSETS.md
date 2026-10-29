# Imagens e mídias sem XAMPP

As mídias estáticas ficam no Uriel em
`/opt/uriel/interior-city-tocado/state/www`, fora das releases e do Git.
O Caddy já utilizado pelo projeto monta somente essa pasta em `/srv/www`, em modo
somente leitura, e atende `/images/`, `/vrp_images/` e `/loading/` no mesmo domínio
HTTPS do túnel existente. Os demais caminhos continuam no proxy do FXServer.
Não é necessário instalar Apache, XAMPP ou outra imagem de produção.

## Importar e conferir

No Mac, a importação da pasta original é:

```bash
python3 scripts/web-assets.py import \
  --source '/Volumes/Extreme SSD/gta/htdocs Base INTERIOR CITY' \
  --destination state/www
python3 scripts/web-assets.py verify --destination state/www
```

O importador preserva os nomes, copia somente imagens de `images`/`vrp_images` e
áudio/vídeo de `loading`, e verifica tamanho e SHA-256 de todos os arquivos.
O manifesto fica em `state/www.manifest.json`, fora da raiz publicada. Uma
reexecução com o mesmo conteúdo é permitida; divergências, links e arquivos
extras no destino interrompem a operação sem sobrescrever mídias diferentes.
PHP, HTML, arquivos de edição e arquivos compactados não são publicados.
`jester` e `smartphone` são aplicações legadas e não fazem parte desta migração.

Para levar a cópia preparada ao Uriel, transfira `state/www` e
`state/www.manifest.json` para uma pasta de staging do usuário SSH. Com uma sessão
administrativa no Uriel, instale-os em `state/` do projeto e execute novamente o
comando `verify` da release candidata contra o destino efetivo. Preserve as
permissões: diretórios 0755, mídias 0644 e manifesto 0600; o projeto continua
protegido pelo diretório externo privado. Não substitua uma pasta existente
divergente sem guardar e revisar sua versão anterior.

## URLs e atualização da base

Por padrão o instalador usa `https://<PLAYIT_HTTPS_HOST>` como origem das mídias.
Para usar uma hospedagem HTTPS diferente, configure `IC_ASSETS_BASE_URL` no `.env`
privado do Uriel e publique nessa hospedagem as mesmas três pastas. O valor deve
ser uma origem HTTPS, sem caminho, credenciais, query string ou fragmento.

Antes de gerar o manifesto da release, `scripts/install-uriel-release.sh` chama
`scripts/web-assets.py configure`. Esse passo substitui **somente** os prefixos
legados `http://127.0.0.1/` e `http://localhost/` dessas três pastas em arquivos
de recursos Lua, JSON, JavaScript, HTML, CSS e TypeScript. Inclui inventário,
garagem, concessionária, banco, farm, entregas, craft, organizações, notificações
e as referências das interfaces antigas. URLs de outros provedores são
preservadas. O craft fornecido também passa a pedir `.png` em vez de `.PNG`,
compatível com os arquivos importados e o filesystem Linux.

A transformação ocorre apenas na candidata isolada; o checkout Git e a release
anterior são preservados. `config/web-assets.runtime.json` registra a origem e os
hashes dos consumidores transformados, e entra no manifesto da release.
Reutilizar uma release com outra origem ou código alterado é recusado. Uma troca
de origem exige preparar uma nova release. Os testes locais usam domínios
reservados; não representam um endereço de produção configurado.

A validação da mídia acontece antes da troca e da parada dos escritores. Sem
origem válida ou manifesto íntegro, uma candidata com referências legadas não é
instalada. A ativação segue o fluxo de deploy existente, inclusive a exigência
de cutover do IC Admin quando aplicável; não há migração de banco adicional.

As mídias persistem nas trocas e no rollback de código. Guarde o SSD e uma cópia
independente do manifesto: o backup diário de banco/runtime não inclui `www`.
Releases anteriores a este ajuste ainda contêm URLs locais; voltar para elas
também volta ao comportamento antigo de imagens.

## Verificação

```bash
python3 -m unittest discover -s tests -p test_web_assets.py -v
python3 -m unittest discover -s tests -p test_docker_release.py -v
IC_TEST_CADDY=1 python3 -m unittest discover -s tests -p test_web_assets_http.py -v
git diff --check
```

O teste HTTP usa o Caddy 2.10.2 em um contêiner temporário, com porta aleatória
somente em loopback e fixtures, e remove o contêiner ao terminar. Confere imagens,
CORS, integridade, leitura parcial de vídeo, 404 e a separação do proxy do jogo.
O teste não exige XAMPP nem inicia o jogo/banco.

Depois da ativação no Uriel, confira uma imagem em cada pasta pelo domínio real
e abra inventário, garagem, concessionária e craft em um cliente FiveM. Testes
locais não comprovam TLS/túnel reais nem a experiência de um jogador externo.

## Evidência e classificação

| Classificação | Evidência |
| --- | --- |
| ESTABLISHED | `compose.yaml::connect_proxy` e `docker/caddy/Caddyfile`: Caddy existente e proxy do FXServer |
| ESTABLISHED | `scripts/install-uriel-release.sh::compose_at` e `scripts/release.py::manifest`: releases isoladas e estado persistente |
| EMERGING | `scripts/web-assets.py::import_media`, `verify_media`, `configure_release`: importação filtrada, hashes e transformação antes de selar a candidata |
| EXCEPTION | Os fontes legados conservam suas URLs originais; o instalador transforma os consumidores, incluindo bundles fornecidos sem reconstruir suas interfaces |

O roteamento estático segue os blocos
[`handle`](https://caddyserver.com/docs/caddyfile/directives/handle) e
[`file_server`](https://caddyserver.com/docs/caddyfile/directives/file_server) do Caddy.

## Preparação local em 29/10/2026

- Importadas e verificadas 2.758 mídias (1.052.736.605 bytes); 624 arquivos foram
  excluídos pelo filtro. O original do SSD permanece preservado.
- A prévia privada em `state/web-assets-preview` transformou os 19 consumidores
  versionados encontrados, sem referências legadas restantes; JavaScript/Lua
  passaram nas verificações de sintaxe e os JSONs foram decodificados.
- A suíte Python executou 106 testes: 95 passaram e 11 testes optativos de
  MariaDB foram pulados. O teste HTTP do Caddy foi habilitado e passou.
- Passaram a configuração Compose local, `caddy validate`, compilação Python e
  sintaxe Bash. `git diff --check` passou para os arquivos desta alteração; a
  alteração preexistente em `resources/[scripts]/m_patrulha/m_patrulha.sql`
  permanece intacta e contém avisos de whitespace fora deste escopo.
- Não houve commit, push, implantação, alteração do banco ou reinício do servidor.
  A sessão SSH disponível exige autenticação interativa de `sudo` e não permite
  ler o diretório protegido do projeto nem acessar Docker no Uriel. A origem
  efetiva, o TLS/túnel e o cliente FiveM ainda precisam de verificação no servidor.

Arquivos de implementação alterados/adicionados: `.env.example`, `compose.yaml`,
`docker/caddy/Caddyfile`, `docker/caddy/assets.caddy`, `scripts/web-assets.py` e
`scripts/install-uriel-release.sh`. Testes: `tests/test_docker_release.py`,
`tests/test_web_assets.py` e `tests/test_web_assets_http.py`. Documentação:
`README.md`, `docs/URIEL_DOCKER.md` e este arquivo.

## Ativação no Uriel em 29/10/2026

A release `25e0ce7c714c4cd764ff9ef57bca321f28715ebb` foi implantada pelo
instalador existente, com backup prévio e verificação operacional do IC Admin.
A verificação continuou a migração existente sem reimportar o JSON legado.
Não houve push para o Git remoto. A alteração local preexistente em
`m_patrulha.sql` ficou fora do commit e da implantação.

As 2.758 mídias foram instaladas em
`/opt/uriel/interior-city-tocado/state/www` e conferidas contra o manifesto.
O Caddy monta esse destino em modo somente leitura. A configuração usou o
domínio HTTPS já existente, sem registrar o endereço no código.

A verificação pública confirmou HTTP 200, CORS e SHA-256 do conteúdo em
`images`, `vrp_images` e `loading`; PHP e arquivo inexistente retornaram 404.
O proxy de `/info.json` respondeu com o IC Admin ativo. Os 19 consumidores
transformados ficaram sem referências antigas de imagens locais.

FXServer, MariaDB e Playit ficaram `healthy`; Caddy e backup ficaram em execução.
A evidência privada fica em
`state/web-assets-verification-25e0ce7c714c4cd764ff9ef57bca321f28715ebb.json`
no Uriel. A conferência visual das interfaces em um cliente GTA/FiveM continua
pendente; a verificação HTTP não substitui essa etapa.

## Correção dos ícones do inventário

A captura de um cliente mostrou que confirmar a hospedagem de uma imagem de
amostra não cobria os nomes efetivamente pedidos pelo inventário. O pacote do
XAMPP contém `WEAPON_PISTOL_MK2.png`, por exemplo, enquanto a interface pede
`weapon_pistol_mk2.png`. No Linux esses são caminhos diferentes. O primeiro
deploy não havia tratado essa incompatibilidade.

`scripts/web-assets.py aliases --destination state/www` preserva os nomes
originais e acrescenta hardlinks com nomes em minúsculas em filesystems que
distinguem maiúsculas e minúsculas. O conteúdo é verificado antes/depois, o
manifesto anterior fica guardado fora da raiz pública e a operação é idempotente.
Em um filesystem que já resolve ambos os nomes, não cria entradas redundantes.
O instalador executa essa preparação no Uriel antes de configurar as URLs.

Foram acrescentados 934 nomes compatíveis no Uriel. A RayPistol não estava no
antigo `htdocs/images`; sua imagem foi encontrada entre os assets já fornecidos
em `resources/[scriptcore]/m_paineladm_v2/nui/imgs/weapons/weapon_raypistol.png`.
Ela foi incluída com o SHA-256 do catálogo `assets.lock.json`, sem substituir
arquivos existentes. O comando `include` registra suplementos no manifesto,
preservados em reimportações. O total passou a 3.693 caminhos de mídia, contando
os aliases e esse ícone adicional; os hardlinks não duplicam os bytes das imagens.

As respostas 404 anteriores também traziam `Cache-Control: max-age=3600`.
`docker/caddy/assets.caddy` passa a reservar esse cache para 2xx/304 e a devolver
`no-store` nos erros de mídia. O inventário centraliza suas URLs em
`window.inventoryImageUrl`, respeita o campo `png` e usa a versão
`v=20261029-2` para que o cliente deixe de reutilizar os 404 anteriores. Isso cobre
slots, seleção, atalhos, HUD e armas equipadas.

Arquivos da correção: `scripts/web-assets.py`, `scripts/install-uriel-release.sh`,
`docker/caddy/assets.caddy`, `resources/[scriptcore]/inventory/web/main.js`,
`resources/[scriptcore]/inventory/web/modules/Inventory.js`,
`resources/[scriptcore]/inventory/web/modules/Weapons.js`,
`tests/test_web_assets.py`, `tests/test_web_assets_http.py` e este documento.
A alteração em `m_patrulha.sql` e o trabalho separado em `ic_config` ficam fora
da correção e da implantação.

A suíte Python local passou, com os testes optativos de banco e o teste HTTP
local pulados. O Docker local deixou de responder; o teste HTTP foi executado
em um contêiner temporário isolado no Uriel, onde passou, incluindo imagens,
requisições parciais, cache 200/304 e ausência de cache nos 404. Também passaram
os testes da função de URL e do HTML dos slots usando Node, mais a sintaxe dos
três arquivos JavaScript alterados.

A release corretiva `09bc3d714202b9c9e003b7ebf455a02abf12e613` foi instalada
no Uriel com backup prévio, continuidade do IC Admin e reinício validado. O
teste público passou para os seis arquivos da captura: `weapon_pistol_mk2`,
`weapon_assaultrifle`, `ammo_specialcarbine_mk2`, `weapon_specialcarbine_mk2`,
`weapon_flaregun` e `weapon_raypistol`, todos com HTTP 200, MIME `image/png` e
SHA-256 correto. Um arquivo inexistente retornou 404 com `Cache-Control: no-store`.
A função de URL versionada está na release efetiva e o endpoint do jogo respondeu.
FXServer, banco e Playit ficaram saudáveis; Caddy e backup ficaram em execução.

A evidência privada é
`state/web-assets-inventory-verification-09bc3d714202b9c9e003b7ebf455a02abf12e613.json`
no Uriel, com cópia local em `state/web-assets-case-fix/verification.json`.
Os seis PNGs também foram decodificados pelo utilitário de imagens do macOS.
O teste visual dentro do GTA continua dependente de reconectar o cliente e
abrir o inventário; não foi executado automaticamente. Não houve push.
