fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'luxurymotors'
description 'Concessionária LuxuryMotors independente da concessionária comum'

dependencies { '/onesync', 'vrp', 'oxmysql', 'm_garage' }

ui_page 'web/index.html'
files { 'web/**/*' }

shared_scripts {
    '@vrp/lib/utils.lua',
    'shared/shared.main.lua',
    'shared/shared.locations.lua',
    'shared/shared.deluxe.lua',
    'shared/shared.vips.lua'
}

client_scripts {
    'client/config_sync.lua',
    'client/main.lua',
    'client/preview.lua',
    'client/diamond_wallet.lua',
    'client/modules/routes.lua',
    'client/modules/testdrive.lua',
    'client/deluxe.lua'
}

server_scripts {
    '@vrp/lib/utils.lua',
    'server/00_audit.lua',
    'server/prepare.lua',
    'server/modules/dealer.lua',
    'server/deluxe.lua',
    'server/config_manager.lua',
    'server/main.lua',
    'server/diamonds.lua',
    'server/showroom_catalog.lua'
}
