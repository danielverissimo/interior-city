fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Interior City'
description 'Mansoes, moradores, IPTU e mobilias com servicos locais'
version '1.0.0'
shared_scripts {'@vrp/lib/utils.lua','config.lua'}
server_scripts {'server/store.lua','server/core.lua','server/admin.lua','server/gameplay.lua','server/furniture.lua','server/bootstrap.lua'}
client_script 'client/main.lua'
ui_page 'web/index.html'
files {'web/index.html','web/*.css','web/*.mjs'}
dependencies {'vrp','inventory','m_garage','doorsv2'}
