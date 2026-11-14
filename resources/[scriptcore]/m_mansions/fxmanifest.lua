fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'MageLabs / OpenAI'
description 'Sistema de mansoes integrado ao Config Manager'
version '1.0.0'

shared_scripts {
    '@vrp/lib/utils.lua',
    'config.lua'
}

client_scripts {'client.lua'}
server_scripts {'server.lua'}

ui_page 'web/index.html'

files {
    'mansions.json',
    'furniture_catalog.json',
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/assets/fallback/*.svg'
}

dependency 'vrp'
dependency 'inventory'
dependency 'm_garage'
dependency 'doorsv2'
