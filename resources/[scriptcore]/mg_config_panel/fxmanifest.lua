fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'MageLabs / OpenAI'
description 'Painel central de configuracoes - baus, garagens e lojas'
version '3.0.0'
shared_scripts {'@vrp/lib/utils.lua','config.lua'}
client_scripts {'client_config.lua','client.lua'}
server_scripts {'server_config.lua','server.lua'}
ui_page 'web/index.html'
files {'web/index.html','web/style.css','web/app.js'}
dependency 'inventory'
dependency 'm_garage'

dependency 'm_mansions'
