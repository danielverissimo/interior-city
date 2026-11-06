fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'MageLabs'
description 'm_hospital - Hospital + Sport Racer + LS Customs, com equipes e produtividade isoladas'
version '1.0.0'

shared_scripts {
    '@vrp/lib/utils.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}

dependencies {
    'vrp',
    'oxmysql',
    'm_ponto',
    'm_aux'
}
