fx_version "cerulean"
game "gta5"

author "Pickle Mods / adaptação m_television"
version "2.0.1"

lua54 "yes"

ui_page "html/menu.html"

dependency "vrp"

files {
    "html/menu.html",
    "html/menu.css",
    "html/menu.js",
    "html/screen.html",
    "html/screen.css",
    "html/screen.js",
    "html/VCR_OSD_MONO_1.001.ttf"
}

shared_scripts {
    "@vrp/lib/utils.lua",
    "config.lua",
    "shared/main.lua"
}

client_scripts {
    "client/dui.lua",
    "client/cursor.lua",
    "client/tv.lua",
    "client/main.lua"
}

server_scripts {
    "server/main.lua"
}
