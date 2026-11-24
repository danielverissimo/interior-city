fx_version "bodacious"
game "gta5"


ui_page "ui/index.html"

shared_script "@vrp/lib/utils.lua"

client_scripts {
    "client.lua"
}

server_scripts {
    "server.lua"
}

files {
    "ui/**",
    "ui/images/**",
    "config.json"
}
