fx_version "cerulean"
game "gta5"

shared_script "@vrp/lib/utils.lua"
shared_script "config.lua"

client_script "client.lua"
client_script "client_atm.lua"

server_scripts {
    "config_manager.lua",
    "server.lua"
}

files {
    "roubos.json"
}
