# Marca e introdução da Interior City

As imagens fornecidas pelo proprietário são distribuídas pelo catálogo privado
`assets.lock.json`. A logo quadrada corresponde a `logo.png` da raiz (96×96);
a logo transparente da HUD corresponde ao arquivo fornecido para a marca grande
(419×199). Nenhuma imagem foi redesenhada ou redimensionada.

## Imagens nas interfaces

Foram substituídos 34 caminhos de imagens de marca. Os três caminhos da HUD
(`m_hud/web/build/assets/logo-D8JhG3_9.png`, `web/build/images/logo.png` e
`web/public/images/logo.png`) usam a imagem transparente. As demais interfaces usam
a imagem quadrada: cadastro, identidade, creator, barbearia, roupas, tatuagens,
survival, craft, concessionária, ponto, MDT, organizações, caixas, IC Admin e introdução.

Além dos assets presentes, foram completados caminhos de logos referenciados por
chunks Vite do fornecedor que não tinham o arquivo correspondente. Logos SVG e
WebP foram trocadas por PNG com referências atualizadas; os bytes dos arquivos
fornecidos foram preservados. Os pacotes antigos permanecem imutáveis no storage.

Os defaults remotos de marca do MDT e de organizações usam arquivos locais das
respectivas NUIs. Imagens personalizadas em registros de organizações não são
reescritas. As imagens de veículos, mapas, instituições e bibliotecas que não são
marca da cidade não fazem parte da substituição.

Os cartões de conexão/ban da vRP usam `lib/branding.lua`, que lê a imagem distribuída
em `branding/logo.png` e gera uma data URI PNG. Assim a imagem do cartão não depende
de URL externa nem de o cliente já ter baixado os recursos. A thumbnail opcional
do webhook é omitida quando a imagem é local: Discord não recebe uma data URI como
URL remota. Regras e dados de ban não foram alterados.

## Introdução

O único dono do metadata `loadscreen` é `ic_loading`, iniciado explicitamente por
`config/resources.cfg`. A declaração antiga em vRP foi retirada. O encerramento
permanece automático e sob responsabilidade do FiveM e do fluxo de spawn existente;
não há `loadscreen_manual_shutdown` nem novo bloqueio de entrada.

A introdução fornecida foi convertida de H.264/AAC para WebM VP9/Opus, mantendo
1920×1080 e aproximadamente oito segundos. O caminho novo evita reutilizar a URL
do MP4 anterior. A interface usa somente HTML/CSS/JavaScript e arquivos locais,
com progresso real de `loadProgress`, reprodução em loop e som inicialmente mudo.
Se o vídeo falhar, a logo local continua visível durante o carregamento.

A publicação anterior comprovava instalação e reprodução em Chrome, não reprodução
no CEF do FiveM. O suporte a codecs proprietários depende da compilação do CEF,
conforme a [documentação do Chromium](https://www.chromium.org/audio-video/).
A incompatibilidade do MP4 é uma hipótese para o problema relatado; não foi obtido
log de mídia do cliente real. O novo recurso resolve a dependência do MP4 e as
dependências remotas da página antiga sem alterar o fluxo de login.
O contrato de carregamento e encerramento segue a
[documentação oficial de loading screens](https://docs.fivem.net/docs/scripting-manual/nui-development/loading-screens/).

## Validação e operação

`tests/ic_loading_browser.mjs` confere hashes de todas as logos do catálogo, renderiza
a HUD compilada e testa a página de introdução sem acesso externo: vídeo, dimensões,
progresso, botão de som e fallback em falha real de mídia. Usa Playwright já disponível;
não instala dependências ou navegadores. Os testes de IC Admin também cobrem sua
nova imagem e continuam conferindo transparência quando fechado.

Essas verificações são sintéticas. A confirmação da nova introdução e da HUD no GTA
continua sendo uma etapa separada após a implantação. O perfil da base é Lua/vRP/NUI
(ESTABLISHED), o catálogo privado e a declaração única de `loadscreen` são ENFORCED;
a hipótese de codec é INFERRED. Não há conflito com o perfil Spring/Angular, que não
foi detectado neste repositório.
