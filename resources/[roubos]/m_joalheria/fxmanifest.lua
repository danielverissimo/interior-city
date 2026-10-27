fx_version "bodacious"
game "gta5"

shared_script "@vrp/lib/utils.lua"

client_scripts {
    "@vrp/lib/utils.lua",
    "client-side/config_sync.lua",
    "client-side/client.lua"
}

server_scripts {
    "@vrp/lib/utils.lua",
    "config_manager.lua",
    "server-side/server.lua"
}

files { "joalheria.json" }
