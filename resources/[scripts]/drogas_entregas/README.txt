DROGAS_ENTREGAS - V2
====================

1. Entre no ponto inicial e pressione E.
2. Escolha Cocaína, Metanfetamina ou Malote de Maconha.
3. Confirme o aviso de risco.
4. Siga o GPS e pressione E nos destinos.
5. Cada venda remove entre minQuantity e maxQuantity do item escolhido.
6. O pagamento é entregue no item Config.Route.dirtyMoneyItem (padrão: dirty_money).
7. Quando o comprador recusa, o item NÃO é removido e a polícia recebe NotifyPush.
8. F7 encerra a rota.

CONFIGURAÇÃO
============
Todas as configurações importantes ficam em config.lua.

IMAGENS
=======
Por padrão a NUI busca:
http://127.0.0.1/images/<nome-do-item>.png

Isso corresponde ao htdocs/images configurado no XAMPP.
Se as imagens estiverem em outro host/CDN, altere somente Config.ImageBaseUrl.

NOTIFYCALL
==========
O resource usa exclusivamente o evento NotifyPush do vrp_notifycall.
Permissão policial padrão: perm.policia.


=== SISTEMA DE REPUTAÇÃO ===
A tabela drogas_reputation é criada automaticamente pelo resource.
INTACTA: 100% dos ganhos; 1 prisão por Venda de drogas -> MEDIA.
MEDIA: 85% dos ganhos; 2 prisões -> BAIXA; 5 vendas limpas -> INTACTA.
BAIXA: 65% dos ganhos; 2 prisões -> HORRÍVEL; 10 vendas limpas -> MEDIA.
HORRÍVEL: 45% dos ganhos; 10 vendas limpas -> BAIXA.
Todos os percentuais e metas podem ser alterados em Config.Reputation.
O m_mdt deste pacote registra a reputação quando a acusação/prisão por Venda de drogas é confirmada no MDT; pagar fiança não apaga a ocorrência.
