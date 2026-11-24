# Veiculos personalizados fora do trafego NPC

`vehicle_population.lua` aplica SetVehicleModelIsSuppressed aos modelos de
`restricted_vehicle_models.lua`. O Ingot/Celta tambem esta bloqueado.
Os oito modelos do pack de som/rebaixados estao bloqueados, assim como
os modelos personalizados de resources/[veiculos] e os modelos classificados
como vip/vips/brasileiros/som no catalogo do m_garage.

A lista inicial inclui nomes de pecas de tuning YFT junto dos modelos: esses
nomes nao sao veiculos de populacao, portanto nao geram nenhuma entidade.
Atualizacoes de catalogo VIP/brasileiro recebidas em tempo real tambem entram
no bloqueio. Modelos ja bloqueados continuam bloqueados se forem removidos
do catalogo, pois o arquivo de streaming ainda pode continuar instalado.

Para regenerar a lista depois de instalar novos packs, executar da raiz:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File auditoria/carros_som/generate-traffic-models.ps1
```

O bloqueio e de geracao ambiental. Nao ha varredura que apaga veiculos,
nem modificacao das garagens, compras ou comandos de spawn. Veiculos de NPC
ja criados podem continuar circulando ate a renovacao natural da populacao.
Os metadados da S10 e Saveiro EstiloDub tambem receberam frequency/maxNum=0.

Aplicar o filtro: `restart AIControl`. Para recarregar os metadados do pack,
reiniciar o servidor e reconectar os jogadores.

Validacao: auditoria/tools/test-trafego-sem-mods.cjs testa com natives simulados
os oito modelos do pack, inclusao de novo VIP/brasileiro e reaplicacao periodica.
O teste tambem verifica que nenhum modelo e liberado explicitamente e que
modelos fora da lista nao sao alterados. Teste de circulacao no FiveM pendente.
