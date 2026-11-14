Concessionária LuxuryMotors — recurso independente
===========================================

Pasta do script: `luxurymotors`.

O recurso possui sua própria interface, marcadores, configuração, estoque,
eventos e consultas SQL. Não depende de `concessionaria` e pode ser iniciado,
parado ou removido sem parar a concessionária comum.

Instalação
----------

1. Coloque a pasta `luxurymotors` dentro de `resources/[scripts]`.
2. Inicie os recursos `vrp`, `oxmysql` e `m_garage` normalmente.
3. Adicione `ensure luxurymotors` à configuração do servidor.
4. No primeiro carregamento sem reiniciar o servidor, execute no console:

   ```text
   refresh
   ensure luxurymotors
   ```

Nesta base a pasta e o `ensure` já foram adicionados.

Posicionar o acesso
-------------------

Com um personagem que possua `developer.permissao`:

- Vá ao balcão da NOVA concessionária e digite `/setdeluxe`.
- O marcador de carro e o blip dourados aparecem nesse ponto para todos.
- Pressione E no marcador para abrir o painel LuxuryMotors.
- Opcional: numa área livre para o carro aparecer, fique na direção desejada
  e use `/settestdeluxe`. Isso habilita o test-drive da LuxuryMotors.
- `/removerdeluxe` remove o ponto LuxuryMotors. `/setdeluxe` pode movê-lo novamente.

Os pontos ficam salvos em `deluxe.json`. O script vem sem posição definida
para não abrir sobre o ponto da concessionária antiga.

Catálogo e estoque
------------------

`dealership.json` é próprio da LuxuryMotors. Foi copiado do catálogo atual para
manter os mesmos veículos nesta etapa. Ainda não há separação automática
entre carros GTA, add-ons e VIPs, nem mudança nas categorias ou nos preços.

O estoque da LuxuryMotors usa a tabela `bm_dealership_deluxe` e as consultas têm
prefixo `deluxe_dealership/`. A concessionária antiga continua usando seu
próprio JSON, sua tabela e suas consultas. Uma compra na LuxuryMotors não reduz
o estoque da loja comum.

Os veículos comprados continuam indo para a garagem normal dos jogadores,
em `vrp_user_veiculos`, com o pagamento e as verificações do servidor.
O catálogo técnico dos modelos continua vindo de `m_garage`.

O comando administrativo de estoque é `/concedeluxe`. O `/conce` pertence
somente à concessionária antiga.

Interface
---------

`web/index.html`, `web/deluxe.css` e `web/deluxe.js` são arquivos diretos:
não é necessário instalar npm ou recompilar para editar o painel.
