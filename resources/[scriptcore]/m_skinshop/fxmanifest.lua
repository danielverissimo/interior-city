-- shared_script '@likizao_ac/client/library.lua'

fx_version "bodacious"
game "gta5"

ui_page "web-side/build/index.html"

shared_scripts {
    'shareds-side/*.lua'
}

files {
    'web-side/build/**/*',
    'shareds-side/localesSkinshop.json'
}

client_scripts {"@vrp/lib/utils.lua", "client-side/*"}

server_scripts {"@vrp/lib/utils.lua", "server-side/*"}


