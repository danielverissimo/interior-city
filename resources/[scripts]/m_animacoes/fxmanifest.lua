fx_version "bodacious"
game "gta5"

ui_page "nui/index.html"

shared_script "@vrp/lib/utils.lua"

client_scripts {
    "config.lua",
    "client.lua"
}

server_scripts {
    "config.lua",
    "server.lua"
}

files {
    "nui/index.html",
    "nui/style.css",
    "nui/script.js"
}
