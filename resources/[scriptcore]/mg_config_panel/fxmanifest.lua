fx_version 'bodacious'
game 'gta5'
lua54 'yes'
author 'MageLabs / OpenAI'
description 'Painel central de configuracoes - baus, garagens e lojas'
version '3.0.3-capture-edit-fix'
shared_scripts {'@vrp/lib/utils.lua','config.lua'}
client_scripts {'client.lua'}
server_scripts {'server.lua'}
ui_page 'web/index.html'
files {'web/index.html','web/style.css','web/app.js'}
dependency 'inventory'
dependency 'm_garage'

dependency 'm_mansions'
