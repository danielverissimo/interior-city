fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Interior City'
description 'IC Admin — administração independente da Interior City'
version '1.0.0'
shared_scripts { '@vrp/lib/utils.lua', 'config.lua' }
server_scripts {
    '@oxmysql/lib/MySQL.lua', 'server/core.lua', 'server/store.lua',
    'server/adapters.lua', 'server/audit.lua', 'server/actions.lua',
    'server/discipline.lua', 'server/maintenance.lua', 'server/calls.lua',
    'server/vips.lua', 'server/world.lua', 'server/monitor.lua', 'server/bootstrap.lua'
}
client_scripts { 'client/main.lua' }
ui_page 'web/index.html'
files { 'web/**' }
dependencies { 'vrp', 'oxmysql' }
