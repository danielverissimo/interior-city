-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ENTRA AI BB: https://discord.gg/DQswMRDMVV  Toca do Mago FiveM
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

fx_version "bodacious"
game "gta5"

ui_page "nui/index.html"

shared_script "@vrp/lib/utils.lua"

client_scripts {
    "client.lua",
    "config.lua"
}

server_scripts {
    "server.lua",
    "config.lua"
}

files {
    "nui/**",
    "nui/images/**"
}