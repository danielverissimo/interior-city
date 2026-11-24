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
# Categorias e cadastro pelo dono

O showroom possui somente Carros VIPs, Carros exclusivos, Brasileiros e
Carros com som. As categorias antigas foram reagrupadas mantendo os 153
estoques e contadores de vendas existentes. A aba de som fica disponivel
para os cadastros do dono; nao foram inventados precos para os carros do pack.

O botao Adicionar veiculo aparece apenas para o grupo exato `dono`.
O servidor repete essa verificacao a cada cadastro (permissoes genericas de
admin ou developer nao autorizam essa funcao). O formulario recebe modelo,
nome, preco, porta-malas, categoria e estoque. O modelo precisa estar
instalado/carregado. Apelidos como celta e s10 tambem sao aceitos.

Modelos existentes preservam nome, preco e porta-malas do m_garage; o cadastro
altera a categoria e o estoque desta loja. Modelos novos sao cadastrados no
m_garage para permitir compra e armazenamento. O estoque informado substitui
o estoque atual, nao soma. Dados persistem nos JSONs existentes da base.

Aplicar: `restart luxurymotors` no console e reabrir a loja.

Validacao: scripts Lua compilados; harness de cadastro com permissao de dono,
recusa de outros cargos, numeros/categorias invalidos, cadastro novo, dados
existentes preservados e rollback de nova entrada quando a loja nao salva.
Os estoques/contadores anteriores foram comparados com o backup em auditoria.
Teste visual e compra no FiveM ainda pendentes.

## Galeria de addons e diamantes (14/11/2026)

O botao Adicionar veiculo abre uma galeria com busca, foto, nome e spawn dos
modelos personalizados. Carros originais sem substituicao nao entram na lista.
Packs de substituicao personalizados (como F-250 e Celta) entram. Recursos
parados e modelos que o cliente nao carregou sao ocultados.

O indice `addon_catalog.json` foi gerado a partir dos vehicles.meta presentes.
Ao instalar ou retirar packs, execute na raiz da base:
`powershell -NoProfile -ExecutionPolicy Bypass -File auditoria/generate-luxury-addons.ps1`
e reinicie luxurymotors. As fotos usam os arquivos existentes no painel admin;
modelos sem imagem exibem a imagem padrao, sem impedir o cadastro.

Selecione o carro, categoria, estoque e moeda (dinheiro da cidade ou diamantes).
Para diamantes, informe o preco inteiro positivo. Carros ja na loja tambem
podem ser selecionados para atualizar estoque, categoria e moeda. Precos em
diamantes ficam no dealership.json e nao alteram o preco da garagem comum.
Os precos atuais continuam em dinheiro ate o dono alterar cada veiculo.

A carteira premium usa as tabelas InnoDB `luxury_diamond_wallets` e
`luxury_diamond_ledger`, criadas automaticamente ao iniciar o resource.
Nao usa o item fisico diamante. O saldo aparece no showroom.
Debito e entrega do carro acontecem em uma transacao MySQL. O estoque e
reservado antes do pagamento; resultados indeterminados ficam reservados
para conferencia. Falhas confirmadas devolvem a reserva. Veiculos adquiridos
com diamantes nao podem ser revendidos por dinheiro, mesmo apos trocar a moeda.

Enquanto nao houver site, apos confirmar o Pix, o dono pode creditar com:
`/luxurydiamantes 123 100 PIX-20261114-001`
Isso credita 100 diamantes ao ID 123. No console, use sem a barra.
Use o identificador real e unico do pagamento. Repetir o mesmo pedido nao soma
saldo novamente; reutilizar com outro ID ou quantidade e recusado. Somente o
grupo dono e o console podem executar. Nao envie pedidos diferentes para
repetir o mesmo pagamento. O comando nao verifica o Pix no Mercado Pago.

Para um futuro site, o resource integrador deve verificar o pagamento e chamar
no servidor `exports.luxurymotors:creditDiamonds(userId, quantidade, pedido)`.
Autorize somente esse resource no server.cfg:
`add_ace resource.NOME_DO_INTEGRADOR luxurymotors.creditDiamonds allow`
Nao ha evento de rede publico para conceder diamantes. Nenhuma integracao de
pagamento externo esta ativa; a escolha do site/provedor ficou para depois.

Aplicacao: `restart luxurymotors` e reabra o painel. Os carros, precos e estoques
ja configurados nao foram alterados por esta atualizacao.
Testes automatizados: `auditoria/tools/test-luxury-editor-diamonds.cjs` (Lua e
regras do servidor) e `auditoria/tools/test-luxury-gallery.cjs` (Edge com NUI
simulada). A compra real com MySQL/FiveM deve ser validada no servidor.

## Nome de exibicao, test-drive e cores

O campo Nome que aparece na loja pode ser editado mesmo para carros existentes.
Selecione novamente o carro na galeria para renomear. O nome e gravado em
`displayName` no estoque da Luxury Motors; spawn e nome da garagem permanecem
iguais. Atualizar apenas estoque por outro painel preserva esse nome.

O ponto de test-drive da Luxury Motors foi configurado no mesmo local de
teste usado pela concessionaria comum (pista de Sandy Shores). O comando
`/settestdeluxe` continua disponivel para trocar esse local.

Clicar numa cor abre uma previa 3D real com pintura primaria e secundaria,
seletor de cor personalizada e botoes para girar. Voltar a loja ou ESC encerra
a previa, remove o carro local e restaura a camera. A previa nao gera veiculo
de rede nem altera o carro do jogador. A pintura depende dos materiais
configurados pelo autor do mod; adesivos/texturas fixas nao sao repintados.
A cor selecionada tambem e aplicada no test-drive e na compra.

Aplicar com `restart luxurymotors`. Testes: `test-luxury-preview.cjs` cobre
nome persistido, RGB, rotacao, limpeza da camera/entidade, timeout e test-drive.
`test-luxury-gallery.cjs` valida o fluxo NUI simulado no Edge. Aparencia 3D e
dirigibilidade precisam de verificacao dentro do FiveM.

## Estoque proprio e remocao

O estoque inicial da Luxury Motors foi limpo para manter somente `vwsava`,
a Saveiro branca ja cadastrada. O preco e o estoque dela foram preservados.
A aba `som` agora se chama Carros de som e rebaixados.
O marcador interno `settings.luxuryCatalogRevision` registra a limpeza unica;
novos carros cadastrados depois disso permanecem nos proximos reinicios.

O dono pode selecionar um carro da aba atual e usar Remover veiculo, ao lado
de Adicionar veiculo. A confirmacao retira somente o anuncio desta loja.
Arquivos do modelo, catalogo da garagem, concessionaria comum e veiculos
pertencentes a jogadores permanecem. Para mover a outra aba, use Adicionar
veiculo, selecione novamente o modelo e escolha a categoria desejada.
Ao reiniciar, a sincronizacao existente tambem limpa o estoque SQL legado.
Aplicar com `restart luxurymotors` e reabrir a loja.

## Bloqueio de duplicatas e carteira no HUD/inventario

Adicionar recusa um spawn que ja esta no estoque, inclusive por apelido ou
mudanca de maiusculas. A galeria desativa o carro e mostra o aviso de que ja
foi adicionado. Use Editar veiculo para alterar nome, categoria, estoque ou
moeda de um carro existente. Remover permite cadastra-lo novamente depois.

O saldo premium aparece abaixo do microfone no HUD e como carteira de diamantes
no inventario. Os tres paineis leem a mesma carteira MySQL; nao se cria uma
segunda pilha de moeda transferivel na mochila. O item de mineracao `diamante`
continua separado da moeda premium. Ao gastar, o saldo diminui nos tres
paineis e a mensagem informa a quantidade e o carro adquirido. Ao zerar,
o simbolo da pilha no inventario some e o HUD informa zero.

Creditos e compras confirmados enviam a atualizacao ao jogador. Login e
reinicios recuperam o saldo, com atualizacao periodica para reconciliacao.
Nao existe evento de rede para o cliente alterar o saldo do servidor.
O carro comprado vai para `vrp_user_veiculos` na mesma transacao do debito.

Reinicie `luxurymotors`, `m_hud` e `inventory` para carregar essa integracao.
O script de carteira do HUD esta em web/public/diamonds.js e tambem foi copiado
para web/build/diamonds.js, preservando seu carregamento em futuras builds.

## Spawn administrativo de diamantes

Na aba Itens do Mage Admin, Diamantes usa o mesmo formulario de quantidade
dos demais itens. A entrega e sempre ao proprio administrador. Nao foi
adicionado campo de ID nem alterado o layout. O item tem icone local proprio.

No F8, use `item diamantes 100` para receber 100 diamantes ou
`item diamantes 100 42` para creditar 100 ao ID 42. No chat, use a barra inicial.
As permissoes existentes do comando /item e da acao spawn_self_item continuam
obrigatorias. Cada credito tem registro unico na carteira e log administrativo.
IDs e quantidades invalidos sao recusados. O ID informado pode estar offline;
o saldo sera recuperado no proximo login.

O indice `diamantes` credita a carteira premium exibida no inventario/HUD,
nao cria uma copia fisica nem altera o item de mineracao `diamante`.
Os outros itens continuam passando pelas rotinas anteriores.
Reinicie `luxurymotors`, `vrp_admin` e `m_paineladm_v2` e reabra o painel.


### Catalogo de rebaixados e motos

A aba Carros rebaixados com som contem os 8 modelos do pack carros_som_rebaixados. A aba Motos contem 22 modelos personalizados identificados nas pastas, incluindo as substituicoes enduro e pcj. Todos foram configurados inicialmente por 1000 diamantes, com estoque inicial 10 nos novos cadastros e estoque existente preservado.

Para alterar o preco: entre com cargo dono, selecione o veiculo, clique em Editar veiculo / preco, ajuste Preco em diamantes e salve. O valor fica persistido em dealership.json.

Reinicie o servidor para carregar o catalogo atualizado da garagem e a Luxury Motors. Validacao estatica: 30 modelos presentes nos catalogos de addons e garagem, cinco categorias e precos conferidos. Teste dentro do jogo ainda necessario.
