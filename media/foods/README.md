# Comidas do interior

15 itens locais: 13 comidas e 2 bebidas. Os valores usam os itens semelhantes
já existentes como referência, conforme autorizado. Os doces usam a recuperação
da barra de chocolate e o preço do donut (100), já que a barra não está nos shops.
O café coado usa o fluxo comum de bebida, sem acrescentar bônus de velocidade.

| ID | Nome | Loja | Preço | Peso | Fome recuperada | Sede recuperada | Referência |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| `pamonha` | Pamonha | Lanchonete | 100 | 0,5 | 24 | 0 | `coxinha` |
| `curau` | Curau | Lanchonete | 100 | 0,2 | 16 | 0 | `donut` |
| `tapioca` | Tapioca | Lanchonete | 125 | 0,5 | 32 | 0 | `sanduiche` |
| `cuscuz` | Cuscuz | Restaurante | 125 | 0,5 | 32 | 0 | `sanduiche` |
| `bolodemilho` | Bolo de Milho | Lanchonete | 100 | 0,5 | 18 | 0 | `pao` |
| `galinhada` | Galinhada | Restaurante | 300 | 2,0 | 50 | 0 | `marmita` |
| `arrozcompequi` | Arroz com Pequi | Restaurante | 300 | 2,0 | 50 | 0 | `marmita` |
| `feijaotropeiro` | Feijão Tropeiro | Restaurante | 300 | 2,0 | 50 | 0 | `marmita` |
| `arrozcarreteiro` | Arroz Carreteiro | Restaurante | 300 | 2,0 | 50 | 0 | `marmita` |
| `docedeleite` | Doce de Leite | Lanchonete | 100 | 0,5 | 14 | 0 | `barrac` |
| `goiabada` | Goiabada | Lanchonete | 100 | 0,5 | 14 | 0 | `barrac` |
| `pacoca` | Paçoca | Lanchonete | 100 | 0,5 | 14 | 0 | `barrac` |
| `pedemoleque` | Pé de Moleque | Lanchonete | 100 | 0,5 | 14 | 0 | `barrac` |
| `caldodecana` | Caldo de Cana | Lanchonete | 200 | 0,5 | 0 | 36 | `sucol` |
| `cafecoado` | Café Coado | Restaurante | 200 | 0,25 | 0 | 20 | `cafe` |

## Arquivos e imagens

- `resources/[scriptcore]/inventory/config/shared.items.lua::Items`,
  `play_eat` e `play_drink`: cadastro, consumo e escolha do objeto da animação.
- `resources/[vrp]/vrp/cfg/items.lua::cfg.items`: nomes, pesos e necessidades
  coerentes com o catálogo do inventário.
- `resources/[scriptcore]/inventory/config/shared.shops.json`: acréscimos aos
  cardápios existentes; locais, permissões e itens anteriores preservados.
- `media/foods/catalog.json`: lista de IDs, imagens, lojas, preços e referências.
- `media/foods/images/*.png`: 15 ícones individuais de 512 × 512, RGBA com
  transparência, gerados pelo `image_gen` integrado, uma chamada por item.
- `media/foods/generation-prompts.json`: prompts completos de cada imagem.
- `media/foods/images.manifest.json`: tamanho e SHA-256 dos PNGs finais.
- `media/foods/preview.png`: folha de conferência dos 15 ícones.

Os PNGs novos ficam versionados em `media/foods`, separados dos pacotes
imutáveis do fornecedor. Os originais da geração permanecem no diretório do
ImageGen; as cópias selecionadas foram reduzidas para o inventário, preservando
transparência. O estilo é um recorte realista com iluminação uniforme e sem texto.
Os objetos nas mãos são modelos GTA já usados pela base, não modelos 3D novos
que reproduzam exatamente os pratos.

## Preparar as imagens na hospedagem existente

O inventário resolve `png` por `web/main.js::window.inventoryImageUrl` para
`/images/<id>.png`. Portanto copiar os PNGs apenas para uma release não os
publica: a mídia deve entrar no `state/www` persistente com seu manifesto,
seguindo `docs/WEB_ASSETS.md`. O comando abaixo é para preparação local em uma
cópia de mídia já inicializada. No Uriel, exige a aprovação da implantação.

Execute da raiz `code/Base`:

```bash
python3 - <<'PYCODE'
import hashlib
import json
from pathlib import Path
import runpy

root = Path.cwd()
media = root / 'media/foods'
web = runpy.run_path(str(root / 'scripts/web-assets.py'))
manifest = json.loads((media / 'images.manifest.json').read_text())
# Confere o lote inteiro antes de incluir qualquer arquivo.
for relative, record in manifest['files'].items():
    source = media / relative
    assert source.is_file() and not source.is_symlink()
    assert source.stat().st_size == record['size']
    assert hashlib.sha256(source.read_bytes()).hexdigest() == record['sha256']
for relative, record in manifest['files'].items():
    source = media / relative
    web['include_image'](source, root / 'state/www', source.name, record['sha256'])
print(web['verify_media'](root / 'state/www'))
PYCODE
```

O importador existente registra suplementos, aceita repetição do mesmo conteúdo
e recusa substituição de mídia divergente.

## Ativação e persistência dos cardápios

`shared.shops.json` faz parte do estado persistente administrado pelo IC Config
(`scripts/ic-config-state.py::FILES`). Em uma implantação, o estado efetivo pode
sobrepor o arquivo versionado. É necessário acrescentar os 15 IDs e preços do
catálogo aos cardápios efetivos usando o fluxo de configurações existente,
preservando lojas, coordenadas e alterações dos administradores. Apenas publicar
o código não garante que os itens aparecerão nas lojas já persistidas.

A preparação inicial foi local. A publicação posterior autorizada foi concluída
no Uriel em 30/10/2026; consulte `docs/DEPLOY_COMIDAS_MARCA_2026-10-30.md`. A homologação
FiveM deverá conferir compra, desconto, imagem no inventário/loja, uso, redução da
quantidade, fome/sede, animação e persistência depois de reiniciar os recursos.

## Evidência e validação

ESTABLISHED: `Items`, `Comer`, `Beber`, `ApplyNeeds` e
`config/shared.shops.loader.lua::LoadShopsFromJson` são os caminhos usados pela
base. ESTABLISHED: `scripts/web-assets.py::include_image` integra PNGs adicionais
à mídia persistente. EXCEPTION: os ícones novos estão em `media/foods`, pois
`resources/**/*.png` é ignorado para os assets fornecidos. O detector não encontrou
Spring ou Angular; essa família de arquitetura não se aplica a esta mudança.

```bash
python3 -m unittest discover -s tests -p test_inventory_foods.py -v
python3 -m unittest discover -s tests -p test_web_assets.py -v
luac -p 'resources/[scriptcore]/inventory/config/shared.items.lua'
luac -p 'resources/[vrp]/vrp/cfg/items.lua'
git diff --check
```

O teste Lua executa os cadastros reais e confere os 15 contratos entre inventário,
vRP e lojas; consumo e callbacks; bloqueio quando necessidades estão desligadas
ou o consumo falha; objetos e compatibilidade com animações anteriores. O teste
Python confere nomes, hashes, dimensões e canal alpha dos PNGs. Esses testes não
executam o GTA nem comprovam o comportamento do cliente FiveM.

Resultado local em 30/10/2026: os 2 testes de comidas e os 11 testes de mídia
passaram, sem testes pulados nesses dois grupos. A sintaxe dos dois cadastros Lua
e `git diff --check` passaram. Os 15 PNGs foram decodificados e inspecionados na
folha de conferência, com RGBA, 512 × 512 e transparência efetiva. As imagens foram
incluídas somente no `state/www` local pelo importador existente; o manifesto final
validou 2.774 mídias. O manifesto anterior foi preservado em
`state/foods-preparation/www.before-foods.manifest.json`.

Os itens antigos, preços, coordenadas e demais propriedades dos shops foram
comparados estruturalmente com `HEAD` e permaneceram iguais. A referência de
valores foi autorizada pelo usuário; a distribuição entre Lanchonete e Restaurante
reaproveita os dois pontos existentes. Não foram identificados conflitos locais.
A suíte completa, a hospedagem pública e os clientes FiveM não foram executados
nesta tarefa. A ativação posterior no Uriel foi concluída; a evidência está no relatório de publicação.
