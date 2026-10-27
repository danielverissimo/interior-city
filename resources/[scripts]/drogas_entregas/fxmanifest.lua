fx_version 'cerulean'
game 'gta5'

name 'drogas_entregas'
author 'Toca do Mago / refinado'
description 'Rotas de venda de drogas com seleção NUI e integração vrp_notifycall'
version '2.0.0'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/caveira.png'
}

client_scripts {
    '@vrp/lib/utils.lua',
    'config.lua',
    'client.lua'
}

server_scripts {
    '@vrp/lib/utils.lua',
    'config.lua',
    'server.lua'
}

dependency 'vrp'
dependency 'oxmysql'
dependency 'vrp_notifycall'
