fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'MageLabs / m_robbernpc'
description 'Roubo de porta-malas + negociação dinâmica de drogas com NPCs integrado ao vRPex'
version '2.1.0'

-- Compatibilidade com resources antigos que ainda referenciam m_trunkrobber.
provide 'm_trunkrobber'

shared_scripts {
    '@vrp/lib/utils.lua',
    'config.lua'
}

client_script 'client.lua'
client_script 'lockpick_client.lua'
client_script 'ped_robbery_client.lua'
server_scripts { 'lockpick_server.lua', 'npc_loot.lua', 'server.lua', 'ped_robbery_server.lua' }

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js',
    'nui/lockpick.js',
    'nui/lockpick.css',
    'nui/img/*.svg'
}

dependencies {
    'vrp',
    'inventory',
    'm_garage'
}
