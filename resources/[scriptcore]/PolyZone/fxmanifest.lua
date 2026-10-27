

fx_version 'cerulean'
game 'gta5'

description 'Define zones of different shapes and test whether a point is inside or outside of the zone'
version '2.6.2'

shared_scripts {
    "@vrp/lib/utils.lua"
}

client_scripts {
    "@vrp/lib/utils.lua",
    'client.lua',
    'BoxZone.lua',
    'EntityZone.lua',
    'CircleZone.lua',
    'ComboZone.lua',
    'creation/client/*.lua',
    "safezone_creator.lua"
}

server_scripts {
    "@vrp/lib/utils.lua",
    'creation/server/*.lua',
    'server.lua'
}