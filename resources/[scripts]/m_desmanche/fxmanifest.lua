fx_version "adamant"
game "gta5"
author "IgorWinchester#2472"

shared_script {
    '@vrp/lib/utils.lua',
    'config.lua'
}

client_scripts {
    'client-side/config_sync.lua',
    'client-side/client.lua'
}

server_scripts {
    'server-side/config_manager.lua',
    'server-side/server.lua'
}

files {
    'config.json'
}
