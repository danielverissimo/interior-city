fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Interior City'
description 'Configuracoes da cidade com autorizacao local'
version '1.0.0'

shared_scripts { '@vrp/lib/utils.lua', 'config.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/core.lua', 'server/adapters.lua', 'server/organizations.lua', 'server/mansions.lua', 'server/runtime.lua' }
client_script 'client/main.lua'
ui_page 'web/index.html'
files { 'web/index.html', 'web/*.css', 'web/*.mjs' }
dependency 'vrp'
dependency 'oxmysql'
