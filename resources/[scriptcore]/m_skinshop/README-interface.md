# Loja de roupas — Interior City

A interface ativa está em `web-side/build/index.html`, com CSS e JavaScript locais e sem etapa de compilação. `index.legacy.html` conserva a entrada anterior.

## Ativação

No console do servidor, execute `restart m_skinshop`. A alteração ainda precisa ser validada dentro do FiveM; este ambiente não tem uma sessão de jogo conectada. Não reinicie durante uma compra de um jogador.

## Miniaturas reais

O recurso original não inclui fotos das peças. Sem foto cadastrada, os cartões exibem uma ilustração local da categoria, o selo "Ilustrativo" e o número do modelo. As 15 ilustrações SVG ficam em `web-side/build/illustrations/` e são compartilhadas entre os modelos da mesma categoria, sem associação com o formato ou a cor real da peça. O botão de remover acessórios continua sem ilustração. A prévia real acontece no personagem ao clicar em Experimentar.

Adicione imagens WebP em `web-side/build/thumbnails/male/torso/14.webp`, por exemplo. Registre em `web-side/build/thumbnails.js`:

```js
window.SKINSHOP_THUMBNAILS = {
  "male/torso/14": "thumbnails/male/torso/14.webp",
  "female/torso/14": "thumbnails/female/torso/14.webp"
};
```

Chaves de categoria: torso, tshirt, arms, pants, shoes, vest, backpack, accessory, decals, mask, hat, glass, ear, watch, bracelet. O número deve corresponder ao drawable da versão atual das roupas do servidor. Use fotos capturadas dentro do jogo; imagens de catálogos genéricos podem não corresponder às roupas personalizadas. Recomenda-se WebP de 256×256, fundo transparente e até aproximadamente 30 KB por imagem. Nenhuma requisição de miniatura é feita se ela não estiver cadastrada. Imagem ausente volta ao ícone.

## Desempenho

- Máximo de 20 cartões na página; demais peças são criadas ao trocar de página.
- Miniaturas locais com carregamento lazy e decodificação assíncrona.
- Sem React, dependências de interface, fontes externas, vídeo, animação contínua ou imagem de fundo pesada.
- Eventos delegados na grade e categorias; sem processamento em loop quando fechada.
- Controles de câmera mantêm uma requisição em andamento e somente o valor mais recente na fila.
- Alterações de roupas são serializadas até a confirmação do callback.
- Cobrança continua sendo de R$ 100 pelo look completo, conforme o servidor existente.

## Verificação no jogo

1. Abrir com personagem masculino e feminino e confirmar que a peça e a cor atuais estão selecionadas.
2. Experimentar modelo 0, último modelo, cores, acessórios 0 e opção Remover.
3. Pesquisar número, paginar e trocar categoria.
4. Girar personagem, aproximar câmera e ajustar altura.
5. Cancelar / ESC e verificar restauração do visual anterior; confirmar e verificar persistência.
6. Reiniciar o recurso com o provador aberto e conferir foco do mouse e câmera.
7. Comparar `resmon 1` com o recurso anterior, aberto e fechado. Não há medição de FPS ou consumo real neste ambiente.

A prévia de layout pode ser aberta num navegador em `web-side/build/index.html?preview=1`. Os itens desta prévia são fictícios para conferir layout; no jogo os limites vêm do personagem.

## Verificações realizadas neste ambiente

Sintaxe JavaScript e referências aos IDs do HTML verificadas. Teste com DOM simulado passou para abertura, limite de 20 cartões em catálogo com 621 modelos, próxima página, busca do último modelo, remoção de acessórios, seleção do modelo zero, mudança de cor e limpeza ao fechar. Esses testes não substituem renderização no Chromium/FiveM nem validam natives Lua. Tentativa de prévia no Edge foi impedida por falhas do navegador neste ambiente. Arquivos ativos da interface somam aproximadamente 18 KB, sem fotos; isso é tamanho de arquivo, não medição de memória ou FPS.

## Correção de fundo preto com a loja fechada

O `color-scheme: dark` global foi removido da raiz e restrito aos controles de `.store` e `.camera`. `html` e `body` têm fundo explicitamente transparente. A NUI permanece carregada com a loja fechada e não deve pintar o fundo do jogo. Requer validação dentro do FiveM após `restart m_skinshop`.
