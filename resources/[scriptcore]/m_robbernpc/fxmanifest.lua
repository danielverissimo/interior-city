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
server_script 'server.lua'

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js',
    'nui/img/*.svg'
}

dependencies {
    'vrp',
    'inventory',
    'm_garage'
}
