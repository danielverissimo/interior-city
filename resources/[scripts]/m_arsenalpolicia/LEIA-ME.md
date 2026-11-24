# Arsenal policial — Interior City

Recurso FiveM para esta base vRP. O catálogo contém 64 itens existentes no inventário: 23 armas, 24 tipos de munição e 17 equipamentos. Todos começam em **R$ 1.000 por unidade**. A compra consome **dinheiro em mãos**, entrega o item na mochila e verifica o peso disponível. Não há retirada gratuita nem desconto para o dono.

## Instalação

1. Extraia a pasta `m_arsenalpolicia` do ZIP em `resources/[scripts]/`.
2. Em `config/resources.cfg`, depois de `vrp` e `inventory`, adicione:

   ```cfg
   ensure m_arsenalpolicia
   ```

3. Para instalar com o servidor já ligado, execute no **console do servidor/txAdmin**:

   ```text
   refresh
   ensure m_arsenalpolicia
   ```

Não precisa compilar o painel, instalar Node ou criar tabelas SQL. Requer OneSync e as funções de dinheiro/inventário desta base vRP. A pasta de desenvolvimento já foi criada nesta base; não foi adicionada ao arquivo de inicialização nem iniciada automaticamente.

## Acesso

- Ponto inicial: **447.30, -975.65, 30.68**. Aproxime-se do marcador e pressione **E**.
- O ponto ativo também aparece no mapa como **Arsenal Policial**, para policiais e dono. Mover ou remover o ponto atualiza o blip imediatamente.
- Comando: **`/arsenalpolicia`**.
- Policiais precisam de `perm.policia` ou `perm.militar` e estar a até 4 metros do ponto para comprar. A tecla E aparece a até 2 metros.
- O cargo **`dono`** pode abrir o painel de qualquer lugar para administrar. Comprar continua exigindo permissão policial e proximidade do arsenal.
- **ESC** ou o botão **×** fecha o painel.
- **`/fechararsenal`** fecha a interface à força e libera o foco. No F8, use `fechararsenal` sem a barra.
- Iniciar o recurso não abre o painel nem captura o mouse. O foco só é ativado depois da confirmação de que a interface foi renderizada. Se o carregamento falhar, a tentativa é encerrada em até 8 segundos.

## Alterar preços

Entre com o cargo `dono`, abra o arsenal e use **Editar preços** na lateral. Clique no item, informe o preço e salve. Também existe **Editar valor deste item** no detalhe do equipamento.

Valores precisam ser inteiros, de R$ 1 a R$ 10.000.000. Preço zero é recusado no servidor. O preço é por **unidade**, inclusive munição: inicialmente, 10 munições custam R$ 10.000. Armas vêm sem munição gratuita. É possível mudar os valores das munições individualmente.

As mudanças aparecem para os painéis abertos e permanecem após reiniciar o recurso.

## Mover o arsenal pelo painel

1. Com cargo `dono`, vá até onde deve ficar o novo marcador, a pé e no chão.
2. Abra **`/arsenalpolicia`**, mesmo estando longe do arsenal antigo.
3. Clique em **Localização do arsenal**.
4. Clique em **Usar minha posição atual**.

O servidor lê a posição atual do personagem, substitui o ponto anterior e salva o novo local imediatamente. Existe **um único ponto ativo**. Não é necessário apagar o antigo manualmente nem reiniciar o script.

Se preferir apagar primeiro, clique em **Remover ponto atual**. O marcador e o blip antigos somem e o arsenal fica sem ponto de compra até o dono clicar em **Usar minha posição atual**. O dono continua podendo abrir `/arsenalpolicia` de qualquer lugar para configurar o novo ponto.

## Adicionar e retirar equipamentos

Com cargo `dono`, abra **Gerenciar equipamentos** na lateral:

- **No arsenal**: lista os itens disponíveis aos policiais. Clique em **Retirar** para remover uma arma, munição ou equipamento do painel e bloquear sua compra no servidor.
- **Adicionar itens**: pesquise por nome ou código do item e clique em **Adicionar**. A lista inclui equipamentos já retirados e outros itens de uso, armas e munições registrados no inventário da base. Itens de dinheiro/moedas não são oferecidos.
- Um item novo começa em R$ 1.000 por unidade; ajuste depois em **Editar preços**. Recolocar um item mantém o preço personalizado que ele já tinha.

Só o dono pode consultar e alterar esse gerenciamento. As mudanças são salvas em `settings.json`, atualizam os painéis abertos e permanecem depois de reiniciar o recurso. Retirar do catálogo não apaga itens que jogadores já possuem. Munições são itens separados: retire também a munição correspondente se não quiser vendê-la.

## Arquivos persistentes

- **`settings.json`**: preços personalizados, única localização ativa, equipamentos retirados (`disabled`) e itens adicionados (`customItems`). Faça backup deste arquivo antes de atualizar o recurso; não o substitua se quiser manter sua configuração.
- **`audit.json`**: criado automaticamente; mantém os últimos 500 registros de compras, alterações de preço/local e falhas. Os registros também vão para o console.
- **`config.lua`**: permissões, comando, limites e catálogo. Novos itens devem existir no inventário da base.

Uma configuração persistente inválida impede a abertura do arsenal e é informada no console; o recurso não substitui preços/local salvos silenciosamente. Itens que não existem no inventário ficam ocultos.

## Catálogo inicial

**Armas:** Glock, Five-Seven, Pistol, HeavyPistol, AP Pistol, Desert Eagle, Revolver, M4, M4 MK2, G36, G3 MK2, Rifle Tático, Heavy Rifle, Military Rifle, AUG, Parafal, Combat PDW, SMG, SMG MK2, Pump Shotgun, Pump Shotgun MK2, Sniper e Sniper Pesada MK2.

**Munições:** munições individuais correspondentes às 23 armas, mais carga de gás. A Parafal usa o item `ammo_parafal`; a G36 usa `ammo_specialcarbine`, diferenciados no catálogo.

**Equipamentos:** taser, cassetete, lanterna, gás, algemas, chave de algemas, distintivo policial, colete, rádio, rastreador, radar veicular, paraquedas, kit de mergulho, kit de reparo, pneus, mochila e bandagem.

Inclui 48 imagens originais já disponíveis na base, copiadas para o próprio recurso. Os demais itens usam ilustrações de categoria. Não depende de links externos para mostrar as imagens.

## Verificação

Testes automatizados cobrem permissões, distância, quantidade, preços adulterados, saldo, peso, entrega paga, estorno quando a entrega falha, proteção contra compra concorrente, persistência dos preços e substituição da localização. A interface foi testada no navegador com dados simulados, incluindo busca, filtros, compra, edição de valores e localização.

O teste final dentro do FiveM depende de iniciar o recurso: confira uma compra com saldo insuficiente, uma compra válida, a edição de preço e a mudança do marcador. O script não altera nem remove outros sistemas de armamento existentes na base.

## Correção 1.0.1

Removido o modo de cor escuro da página NUI, que podia produzir uma tela preta mesmo com o arsenal fechado no FiveM. O fundo de HTML e body fica explicitamente transparente. A abertura agora aguarda confirmação da interface antes de capturar o mouse e conta com limite de tempo e comando de fechamento de emergência. Preços e localização salvos em `settings.json` são preservados.

## Atualização 1.1.0

Blip do mapa vinculado ao ponto ativo; remoção explícita de localização; gerenciamento de itens exclusivo do dono para retirar, restaurar e adicionar equipamentos do inventário. A atualização lê o `settings.json` das versões anteriores sem apagar preços ou posição. Para atualizar uma instalação existente, substitua os arquivos do recurso **preservando seu `settings.json` e `audit.json`**, e execute `restart m_arsenalpolicia`.
