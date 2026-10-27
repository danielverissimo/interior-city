m_robbernpc - v2.0.0 - vRPex
================================

INSTALAÇÃO
1. Use a pasta exatamente como: m_robbernpc
2. Garanta que vrp, inventory e m_garage iniciem antes.
3. Adicione no server.cfg:

   ensure m_robbernpc

O resource declara "provide m_trunkrobber" para manter compatibilidade com integrações antigas
que ainda chamem o nome anterior. Mesmo assim, novas integrações devem usar m_robbernpc.


1. ROUBO DE PORTA-MALAS
=======================
Todo o sistema anterior foi preservado:
- Prompt ARROMBAR na traseira real do veículo.
- Mesma tecla configurável em Config.Key (padrão N).
- Taskbar/animação de arrombamento.
- Loot de veículos NPC.
- Porta-malas real de veículos de jogadores.
- Cooldown de veículos de jogadores.
- Alertas policiais.
- Rastreador veicular oculto/persistente.
- Alarme em veículo rastreado.
- Recuperação do rastreador após arrombamento bem-sucedido.
- Rastreamento do ladrão por 90 segundos.

Comando administrativo de reset dos roubos:
/limparroubosportamalas
Permissão padrão: admin.permissao


2. NEGOCIAÇÃO DE DROGAS COM NPCs
================================
Novo sistema integrado ao mesmo resource e à mesma NUI do porta-malas.

FLUXO
- Ao passar bem perto de um NPC humano elegível, existe uma chance configurável de aparecer:
  N  NEGOCIAR DROGAS
- Chance padrão: 30% por NPC.
- A decisão é feita uma vez por NPC visto pelo jogador; não fica rerrolando a cada frame.
- A mesma tecla N inicia a abordagem.
- Policiais (perm.policia) não podem negociar.
- NPCs policiais/SWAT/exército, NPCs mortos, NPCs dentro de veículos e peds de missão são ignorados.

RESULTADOS DA ABORDAGEM
A) RECUSA
   O NPC exibe acima da cabeça:
   "O que? Drogas?!! Está maluco, eu vou chamar a polícia!"

   Em seguida ele foge do jogador e a polícia recebe imediatamente um NotifyPush/vrp_notifycall
   com o título VENDA DE DROGAS, coordenadas, blip e som.

B) ACEITAÇÃO
   O NPC para, olha para o jogador e exibe:
   "Shh, fala baixo... que drogas você tem ai?"

   A NUI mostra uma proposta como:
   "Deseja vender 3x Baseado?"

   N         = confirmar
   BACKSPACE = recusar

   O servidor sorteia de 1 a 5 unidades, limitado ao estoque real do jogador.
   Após a venda o NPC volta a caminhar normalmente e NÃO chama a polícia.

SEGURANÇA
- Item, quantidade e pagamento são calculados/validados no servidor.
- O client não consegue escolher quantidade ou valor recebido.
- A distância jogador/NPC é validada novamente pelo servidor na abordagem e na confirmação.
- O estoque é conferido novamente antes de remover a droga.
- O pagamento só é entregue depois que a remoção do item é confirmada.
- Cada NPC abordado é marcado para não ser reutilizado/farmado.
- Há proteção anti-spam de solicitações.


3. DROGAS E VALORES
===================
Foram usados os mesmos valores base do drogas_entregas enviado:

cocaina
- item: cocaina
- valor/unidade: $2.500

metanfetamina
- item: metanfetamina
- valor/unidade: $1.000

malote_maconha
- item: malote-maconha
- valor/unidade: $2.500

baseado (NOVO)
- item: baseado
- valor/unidade padrão: $500

O pagamento é entregue em:
dirty_money

Tudo pode ser alterado em Config.NPCDrugSales.Drugs e Config.NPCDrugSales.DirtyMoneyItem.


4. CONFIGURAÇÕES PRINCIPAIS DA VENDA NPC
=========================================
Arquivo: config.lua

Config.NPCDrugSales.EligibilityChance = 30
- Chance de um NPC mostrar NEGOCIAR DROGAS.

Config.NPCDrugSales.UndercoverChance = 25
- Depois que o NPC demonstra interesse e o jogador confirma a venda, esta é a chance de ele ser um oficial disfarçado.
- Nesse caso nenhuma droga é removida, o NPC não recebe o item e a polícia é avisada.

Config.NPCDrugSales.MinQuantity = 1
Config.NPCDrugSales.MaxQuantity = 5
- Quantidade sorteada por venda.

Config.NPCDrugSales.InteractionDistance = 1.65
- Distância para aparecer/interagir com o NPC.

Config.NPCDrugSales.OfferTimeout = 18
- Tempo máximo para confirmar uma proposta.

Config.NPCDrugSales.Dispatch
- Configuração do NotifyPush/vrp_notifycall.
- Permissão padrão da polícia: perm.policia


5. RASTREADOR_CARRO
===================
Para novas instalações, o item recomendado é:

["rastreador_carro"] = {
    index = "rastreador_carro",
    name = "Radar Veicular",
    png = "rastreador_carro",
    weight = 1.0,
    type = "use",
    func = function(user_id, source, item, slot, cb)
        return exports["m_robbernpc"]:useRadarItem(user_id, source, item, slot, cb)
    end
},

Não use keep_item = true.

Radares persistentes instalados quando o resource ainda se chamava m_trunkrobber continuam sendo
reconhecidos através de Config.LegacyRadarStoragePrefix.


6. OBSERVAÇÕES
==============
- drogas_entregas NÃO é dependência deste resource; ele foi usado apenas como referência de drogas,
  valores e padrão de NotifyPush solicitado.
- vrp_notifycall deve estar iniciado para o alerta policial da recusa ser enviado.
- Não é necessária tabela SQL nova para a negociação com NPCs.

ATUALIZACAO - INVENTARIO / NPC
- Corrigida validacao server-side de NPC: removido IsEntityDead, indisponivel no runtime server do FiveM.
- A opcao NEGOCIAR DROGAS agora so aparece quando o servidor confirma que o jogador possui ao menos uma droga configurada.
- O estado e atualizado periodicamente e imediatamente apos uma negociacao.
