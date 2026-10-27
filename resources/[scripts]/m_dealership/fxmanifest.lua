fx_version 'bodacious'
game 'gta5'

ui_page 'web/build/index.html'
files {
    "web/build/**/*",
    "dealership.json"
}

lua54 'yes'

shared_scripts {
    '@vrp/lib/utils.lua',
    'shared/shared.main.lua',
    'shared/shared.locations.lua',
    'shared/shared.vips.lua'
}

client_scripts {
    'client/config_sync.lua',
    'client/main.lua',
    'client/modules/routes.lua',
    'client/modules/testdrive.lua'
}

server_scripts {
    'server/00_audit.lua',
    'server/prepare.lua',
    'server/modules/dealer.lua',
    'server/config_manager.lua',
    'server/main.lua'
}
