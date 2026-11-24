# Roubo de ATM com C4

O jogador pode usar a C4 no inventario perto de um ponto de ATM cadastrado ou pressionar G no ponto de roubo.

1. O servidor valida distancia, requisitos, policiais e cooldown; consome a C4 uma unica vez.
2. O personagem instala e arma a carga durante 6 segundos, com animacao e C4 na mao.
3. A carga fica no caixa e inicia uma contagem de 10 segundos. O jogador fica livre para fugir.
4. Um unico client proximo executa a explosao de rede com dano, evitando explosoes duplicadas por jogador conectado.
5. Depois da explosao, o jogador volta ao local e pressiona G para coletar. A coleta usa o tempo e as recompensas existentes em `roubos.json`.

O servidor so paga apos a coleta completa, perto do caixa e com o personagem vivo. O dinheiro fica disponivel por ate 180 segundos para iniciar a coleta; outro jogador pode recolher se ninguem tiver reservado a coleta. Cancelar a coleta nao paga recompensa parcial.

O ATM fica indisponivel para operacoes bancarias desde a instalacao ate a restauracao. A carga armada continua contando mesmo se o autor desconectar. Reiniciar o recurso encerra roubos pendentes sem gerar pagamento.

`config.lua`, em `Config.AtmC4`, controla instalacao, contagem e janela de coleta. Os 40 pontos de ATM conhecidos do banco e dos roubos ficam em `roubos.json`. Os quatro modelos padrao sao suportados, incluindo os de parede. Novos ATMs de mapas personalizados precisam de ponto de roubo cadastrado no painel de configuracao.

Validacao: `auditoria/tools/test-atm-c4.ps1` e `auditoria/tools/test-atm-interaction.ps1`. Os testes simulam o fluxo do servidor e o client; animacao, dano e aparencia precisam ser conferidos no FiveM.
