# Separação da base TocadoMago

Registro de 26/10/2026. Branch local: `migration/tocado-mago`.

## Resultado

| Item | Medição |
| --- | --- |
| Recursos encontrados | 89 |
| Código/configuração importados | 3.289 arquivos; 66,2 MiB |
| Assets separados | 16.435 arquivos; 13,318 GiB sem compressão |
| Pacotes privados | 84 arquivos tar/gzip; 13,091 GiB armazenados |
| Perfil `core` instalado e verificado | 39 pacotes; 439 arquivos; aproximadamente 191,8 MiB |
| Esquema SQL sem dados | 204 definições CREATE TABLE |

O checkout da migração fica em `/Volumes/Extreme SSD/gta/InteriorCity-code`. A origem `/Volumes/Extreme SSD/gta/TocadoMago_delux/TocadoMago_delux` permanece preservada. O checkout e os ambientes da base anterior não foram substituídos.

Os pacotes, recibos e catálogo estão no disco USB do Uriel em `/srv/diskaux/interior-city-assets/tocado-mago`. Foram conferidos 84 objetos e 84 recibos, com arquivos em modo `0600` e diretório privado. Nenhum serviço de jogo foi alterado por esta separação.

SHA-256 do catálogo selado, também guardado junto aos pacotes:

```
6b3dcbb721586183909d40b2ba8d15245920ac75a58b139170328cf0db911dc9
```

## Conferências realizadas

- 18 testes automatizados das ferramentas passaram.
- Publicação por streaming SSH com validação dos membros e hashes no destino; retomada reutilizou os pacotes concluídos.
- Download real e verificação integral dos 439 assets do perfil `core`.
- Tentativa de instalação `full` recusada na checagem prévia de espaço, sem iniciar o download.
- Cobertura dos caminhos importáveis conferida contra a origem: código no índice e nenhum dos 16.435 payloads de assets no Git. Nomes foram comparados em NFC por causa da normalização de Unicode no macOS.
- Credenciais/estado local excluídos do índice; JSONs sanitizados válidos. Valores removidos não constam do relatório de redações.
- Sintaxe dos scripts de shell e configuração Compose de desenvolvimento válidas.
- Verificação de whitespace passou nas ferramentas, infraestrutura e documentação. O código de terceiros importado mantém ocorrências preexistentes de espaços finais; a verificação global as aponta e não foi tratada como aprovada.

## Limites e próximos passos

A nova base não foi executada: inicialização do banco, seeds necessários, compatibilidade dos recursos, whitelist, acesso de jogador e comportamento no Mac ainda não foram validados. `core` é um perfil de instalação, não uma garantia de servidor mínimo jogável. Não foi feito push para o GitHub nem deploy da nova base.

A infraestrutura usa projeto/volumes próprios, portas 30121/40121 e perfil Colima `interior-city-tocado`. O inicializador cria arquivos privados locais; nenhuma licença da base anterior foi transferida. A configuração do fornecedor ainda exige revisão antes de iniciar.

São pendentes a auditoria de segurança dos scripts, a revisão de direitos/licenças de terceiros, a adaptação do fluxo de releases e uma cópia dos pacotes fora do disco do Uriel. Para instalar `full`, primeiro disponibilize espaço físico suficiente. Para versões que removam assets, use um checkout/release novo; o instalador não apaga arquivos automaticamente.
