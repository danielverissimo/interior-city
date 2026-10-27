fx_version "cerulean"
game "gta5"
lua54 "yes"

ui_page "nui/index.html"

shared_script "@vrp/lib/utils.lua"

shared_scripts {
    "config.lua"
}

client_scripts {
    "client.lua"
}

server_scripts {
    "server.lua"
}

files {
    "nui/index.html",
    "nui/style.css",
    "nui/script.js"
}
