-- shared_script '@likizao_ac/client/library.lua'


fx_version 'bodacious'
game 'gta5'

lua54 'yes'

authors { '_flaviin', 'ruanjkz', 'feijonts_' }

shared_script '@vrp/lib/utils.lua'
dependency 'm_ponto'
client_scripts {
    'client/client.lua',
    'client/modules/*.lua',
}
server_scripts {
    'config/*.lua',
    'server/server.lua',
    'server/modules/*.lua',
}

files {
    'web/build/**',
    'web/build/**/**',
}

ui_page 'web/build/index.html'