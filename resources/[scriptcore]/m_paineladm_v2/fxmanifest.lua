fx_version "cerulean"
game "gta5"
lua54 "yes"

author "MageLabs"
description "m_paineladm_v2 - Painel administrativo modular para vRP"
version "2.90.5-final-obfsafe"

shared_scripts {
    "@vrp/lib/utils.lua",
    "shared_config.lua"
}

client_scripts {
    -- TRANSPORTE ABERTO: NAO OFUSCAR
    "bridge_client.js",
    "client_config.lua",
    -- CORE PROTEGIDO: OFUSCAR
    "client.lua"
}

server_scripts {
    -- TRANSPORTE/CONFIG ABERTO: NAO OFUSCAR
    "server_config.lua",
    -- CORE + AUTH padmv5: OFUSCAR
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



-- Se este resource tambem for protegido pelo Asset Escrow, estes arquivos
-- precisam permanecer legiveis porque formam a camada de transporte/config.
escrow_ignore {
    "bridge_client.js",
    "client_config.lua",
    "server_config.lua",
    "shared_config.lua",
    "nui/**",
    "*.json"
}
