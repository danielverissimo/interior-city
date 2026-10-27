fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'MageLabs / OpenAI'
description 'Sistema de mansoes integrado ao Config Manager'
version '1.0.1'

shared_scripts {
    '@vrp/lib/utils.lua',
    'config.lua'
}

client_scripts {
    'client_config.lua',
    'client.lua'
}
server_scripts {
    'server_config.lua',
    'server.lua'
}

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
