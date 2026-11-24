# Favelas Cold separadas

7 favelas mantidas por nomes e posicoes dos mapas. Cada uma tem seu fxmanifest.lua.
Modelos e texturas compartilhados ficam em favelas_cold_assets, necessaria para qualquer favela.

| Favela | Pasta | Referencia aproximada X, Y, Z | YMAPs |
| --- | --- | --- | --- |
| Barragem | cold_favela_barragem | 1366, 12, 128 | 16 |
| Cemiterio | cold_favela_cemiterio | -1793, -33, 93 | 11 |
| Horizonte | cold_favela_horizonte | 1355, -1359, 63 | 15 |
| Nova Esperanca | cold_favela_novaesperanca | -1129, 2433, 70 | 18 |
| Observatorio | cold_favela_observatorio | 856, 342, 111 | 12 |
| Rotatoria | cold_favela_rotatoria | 1221, -880, 66 | 8 |
| Trilho | cold_favela_trilho | 2440, -554, 78 | 13 |

## Instalacao

Copie favelas_cold_assets e as pastas desejadas para resources. Preserve os nomes das pastas.
Carregue os recursos abaixo em server.cfg. Remova as linhas das favelas que nao quiser usar.

```cfg
ensure favelas_cold_assets
ensure cold_favela_barragem
ensure cold_favela_cemiterio
ensure cold_favela_horizonte
ensure cold_favela_novaesperanca
ensure cold_favela_observatorio
ensure cold_favela_rotatoria
ensure cold_favela_trilho
```

Desative o recurso Favelas original e confira packs com os mesmos mapas antes de instalar.
Nao carregue a mesma favela em dois packs simultaneamente (por exemplo, Barragem de pacotes diferentes).
Esta entrega nao alterou resources ou server.cfg da cidade.

## Conferencia e limites

Todos os arquivos de stream foram preservados uma unica vez e conferidos por SHA-256.
desktop.ini e o manifest original foram preservados em originais e nao sao carregados.
Os 23 YTYPs estao registrados explicitamente nos manifests das respectivas pastas.
O caminho original stream/YTYP/mp_residential.ytyp nao correspondia ao arquivo do RAR;
a entrega registra o caminho real stream/mp_residential.ytyp.
YMAPs, YMFs, modelos, texturas e colisoes foram mantidos sem alteracao binaria.
Os mapas-base de vegetacao, objetos e colisoes foram associados pela regiao; suas celulas
podem ultrapassar os limites de uma favela e afetar areas vizinhas quando carregadas.
As coordenadas sao medias de entidades de mapas externos, nao entradas ou pisos de teleporte verificados.
Validacao estrutural feita nos arquivos. Carregamento, interiores, texturas e colisoes ainda
precisam de teste no FiveM, inclusive com cada favela carregada isoladamente.
inventario.json documenta o destino, tamanho e hash de cada arquivo.
