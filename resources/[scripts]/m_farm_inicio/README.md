# Inicio das rotas de farm

## Colocar o ponto da Mafia

1. Se o servidor ja estava ligado antes da instalacao, execute no console: `refresh`, depois `restart m_farm` e depois `ensure m_farm_inicio`. O restart do m_farm interrompe as rotas em andamento; faca isso quando nao houver jogadores em rota.
2. Entre no jogo com um personagem que tenha `admin.permissao`.
3. Fique a pe, exatamente no local onde deseja iniciar a rota.
4. Digite no chat: `/ponto_farm mafia`.
5. Um membro com `perm.mafia` deve se aproximar do ponto e apertar E para abrir o menu da rota de armas.

Para mover o ponto, va ao novo local e repita `/ponto_farm mafia`.
Para desativar: `/ponto_farm mafia remover`.

O comando salva a posicao em `points.json`, que permanece apos reiniciar o servidor. O marcador aparece para membros da organizacao e administradores. Administradores podem conferir a posicao, mas precisam da permissao da organizacao para abrir a rota.

## Posicionar outras organizacoes

No local desejado, use o comando correspondente:

| Organizacao | Comando | Rota |
| --- | --- | --- |
| Vanilla | `/ponto_farm vanilla` | Lavagem |
| Bahamas | `/ponto_farm bahamas` | Lavagem |
| Cartel | `/ponto_farm cartel` | Municao |
| Verdes | `/ponto_farm verdes` | Armas |
| Laranjas | `/ponto_farm laranjas` | Metanfetamina |
| Azul | `/ponto_farm azul` | Desmanche, Colete, LockPick |
| Roxos | `/ponto_farm roxos` ou `/ponto_farm roxo` | Cocaina |
| Vermelhos | `/ponto_farm vermelhos` | Algemas, Capuz, C4 |

Cada organizacao tem sua propria posicao e permissao. Os pontos so ficam ativos apos posicionar. Apos atualizar o recurso, execute `restart m_farm_inicio` no console para carregar os novos cadastros e comandos.

## Editar coordenadas

Em `points.json`, localize o registro com `"id": "mafia"`, defina `"enabled": true` e preencha `"coords": {"x": VALOR_X, "y": VALOR_Y, "z": VALOR_Z}` com numeros reais do local desejado. Depois use `/ponto_farm recarregar` como administrador dentro do jogo.

Os pontos com `enabled: false` ficam desativados ate receberem um local. Digite `/ponto_farm` para listar os IDs disponiveis.

O inicio usa um marcador no chao. As distancias e a aparencia ficam em `config.lua`. Os trajetos de coleta e as recompensas continuam no recurso `m_farm`.
