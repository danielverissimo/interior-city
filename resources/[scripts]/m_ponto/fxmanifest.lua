-- shared_script '@likizao_ac/client/library.lua'

fx_version   'cerulean'
lua54        'yes'
game         'gta5'

--[[ Resource Information ]]--

--[[ Manifest ]]--
dependencies {
    '/server:5181',
    '/onesync',
    'vrp',
    'inventory',
}

shared_scripts {
    '@vrp/lib/utils.lua',
    'shared/**'
}

server_scripts {
    "config.lua",
    "server/server.lua"
}

client_scripts {
    "client/utils.lua",
    "client/client.lua",
}

ui_page 'web/build/index.html'

files {
    'web/build/**'
    
}
