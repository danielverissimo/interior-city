-- shared_script '@likizao_ac/client/library.lua'

fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'lotus_spawn'
author 'boynull'

ui_page 'web/build/index.html'

files {'web/build/*', 'web/build/**/*'}

shared_scripts {'@vrp/lib/utils.lua', 'shared/**'}

server_scripts {"server/server.lua" }

client_scripts {"client/client.lua", "client/utils.lua"}