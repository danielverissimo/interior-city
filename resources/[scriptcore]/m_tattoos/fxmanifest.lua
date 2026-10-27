-- shared_script '@likizao_ac/client/library.lua'

fx_version "bodacious"
game "gta5"

ui_page "web/build/index.html"

shared_scripts {
    "shared/*.lua"
}

files {
    "web/build/**/*",
    "shared/locations.json"
}

client_scripts {"@vrp/lib/utils.lua", "client/*"}

server_scripts {"@vrp/lib/utils.lua", "server/*"}
