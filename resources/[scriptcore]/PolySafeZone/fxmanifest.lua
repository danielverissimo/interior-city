fx_version 'bodacious'
game 'gta5'

name "PolySafeZone"
description "Versao avancada de SafeZone - Criacao de Areas personalizadas com PolyZone"
author "Edited by ThePox"

ui_page 'html/index.html'

dependencies {
    'PolyZone'
}

shared_script {
    '@vrp/lib/utils.lua',
    'config.lua'
}

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/CircleZone.lua',
    '@PolyZone/ComboZone.lua',
    '@PolyZone/EntityZone.lua',
    'client/safezone.lua'
}

server_scripts {
    '@vrp/lib/utils.lua',
    'server/config_manager.lua',
    'server/server.lua'
}

files {
    'safezones.json',
    'html/index.html',
    'html/style.css',
    'html/reset.css',
    'html/listener.js'
}
