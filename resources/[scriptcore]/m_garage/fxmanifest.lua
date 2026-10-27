-- shared_script '@likizao_ac/client/library.lua'

fx_version "bodacious"
game "gta5"

ui_page "web-side/build/index.html"
files {
    "web-side/**/*",
    "shared-side/garages.json",
    "shared-side/typeGarages.json",
    "shared-side/listcars.json"
}

shared_scripts {
    "shared-side/shared.config.lua",
    "shared-side/shared.listcars.lua",
    "shared-side/shared.sellBlackList.lua",
    "shared-side/dynamic.garages.lua"
}

client_scripts {"@vrp/lib/utils.lua", "client-side/*"}
server_scripts {"@vrp/lib/utils.lua", "server-side/*"}
