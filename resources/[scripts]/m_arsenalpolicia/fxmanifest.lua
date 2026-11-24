fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'm_arsenalpolicia'
author 'Interior City'
description 'Arsenal policial com compras, precos e localizacao editaveis pelo dono'
version '1.1.0'

dependencies { '/onesync', 'vrp', 'inventory' }
ui_page 'web/index.html'
files { 'web/**/*' }
shared_scripts { '@vrp/lib/utils.lua', 'config.lua' }
client_script 'client.lua'
server_scripts { 'server/service.lua', 'server/main.lua' }
