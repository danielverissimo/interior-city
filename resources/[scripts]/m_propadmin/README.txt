INTERIOR CITY - m_propadmin (versao inicial para teste)

INSTALACAO
1. Copie a pasta m_propadmin para resources/[scripts]/.
2. No server.cfg (ou arquivo de recursos executado), adicione: ensure m_propadmin
3. No server.cfg, conceda permissao ACE para o seu identificador ou grupo:
   add_ace group.admin interior.propadmin allow
   add_principal identifier.license:SEU_LICENSE_AQUI group.admin
4. Reinicie o recurso e use /propadmin.

CATALOGO COMPLETO
O catalog.json fornecido e uma lista inicial de exemplos, NAO todos os modelos.
Para catalogo completo, baixe a lista JSON/CSV de https://fam-tools.com/data
ou ObjectList.ini de https://github.com/DurtyFree/gta-v-data-dumps
Converta para um array JSON simples de nomes de modelos e substitua catalog.json.
A aba Posicionar tambem aceita qualquer nome de prop manualmente.
O cliente valida IsModelValid e IsModelInCdimage antes de carregar.

PERSISTENCIA
placed.json e gerado automaticamente na pasta do recurso ao salvar.
Faca backup antes de atualizar ou reinstalar o recurso.

LIMITES
- So os props criados por m_propadmin podem ser apagados.
- Para apagar, o staff deve estar perto do objeto.
- Nao modifica craft, blips ou rotas.
- Nao foi executado em um servidor FiveM real: teste em ambiente de homologacao.
- Sem miniaturas embutidas: imagens de todos os props nao estao disponiveis no pacote.
- Alguns modelos de mapa/DLC nao podem ser criados isoladamente.
