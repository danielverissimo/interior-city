m_television - versão adaptada para a base vRP/Creative

COMANDOS
/tv         - abre o controle da TV mais próxima.
/broadcast  - cria/encerra um canal ao vivo do servidor (staff por padrão).
/addtv      - ferramenta de posicionamento de novas TVs (staff por padrão).

DEPENDÊNCIAS
- vrp

A versão adaptada NÃO depende de ox_lib e NÃO depende de generic_texture_renderer.

USO
1. Aproxime-se de uma TV cujo modelo esteja em Config.Models.
2. Use /tv.
3. Escolha mídia, navegador, canal, interação com a tela ou volume.
4. O estado da TV é sincronizado para todos os jogadores; o volume é individual.

/addtv
Escolha um modelo no menu e posicione a TV. ENTER confirma e copia a entrada de
Config.Locations para a área de transferência/F8. BACKSPACE cancela.

PERMISSÕES
Config.Permissions.Use.Everyone = true por padrão.
Broadcast e /addtv aceitam os grupos dono/developer/owner e owner.permissao.
A camada server é compatível com Passport/getUserId, HasGroup/hasGroup,
HasPermission/hasPermission e GetUserGroups/getUserGroups.

SEGURANÇA
Toda mudança de tela é validada novamente no servidor: permissão, modelo,
distância e URL. Config.BannedWords continua sendo respeitado.

COMPATIBILIDADE EXTRA DE TVs
----------------------------
A revisão atual inclui suporte aos móveis/TVs integrados dos apartamentos GTA Online,
incluindo apa_mp_h_str_avunitl_04 (hash -1820646534), que utiliza o render target nativo tvscreen.
Também foram adicionadas as demais variações apa_mp_h_str_avunit* e telas nativas compatíveis.
