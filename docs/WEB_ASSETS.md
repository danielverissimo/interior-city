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
