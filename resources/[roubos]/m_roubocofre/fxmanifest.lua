fx_version 'bodacious'
game 'gta5'

shared_script "@vrp/lib/utils.lua"

client_scripts {
    "@vrp/lib/utils.lua",
    "client.lua",
    "config_sync.lua"
}

server_scripts {
    "@vrp/lib/utils.lua",
    "config_manager.lua",
    "server.lua"
}

files {
    "roubocofre.json"
}
