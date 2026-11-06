fx_version "bodacious"
game "gta5"
lua54 "yes"

author "MageLabs"
description "m_paineladm_v2 - Painel administrativo modular para vRP"
version "2.90.2"

shared_scripts {
    "@vrp/lib/utils.lua",
    "shared_config.lua"
}

client_scripts {
    "client_config.lua",
    "client.lua"
}

server_scripts {
    "server_config.lua",
    "productivity_bridge.lua",
    "server.lua"
}

ui_page "nui/index.html"

files {
    "nui/index.html",
    "nui/style.css",
    "nui/script.js",
    "locations.json",
    "location_categories.json",
    "vehicles.json",
    "panel_permissions.json",
    "warnings_data.json",
    "vip_packages.json",
    "vip_assignments.json",
    "nui/imgs/**"
}

