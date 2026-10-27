fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'MageLabs / OpenAI'
description 'Painel central de configuracoes - obfuscation-safe transport + AUTH cfgmanager'
version '3.0.1-final-obfsafe'

shared_scripts {
    '@vrp/lib/utils.lua',
    'config.lua'
}

client_scripts {
    -- TRANSPORTE/NATIVES ABERTOS: NAO OFUSCAR
    'client_config.lua',
    -- CORE PROTEGIDO: OFUSCAR
    'client.lua'
}

server_scripts {
    -- TUNNEL/PROXY/VRP ABERTOS: NAO OFUSCAR
    'server_config.lua',
    -- CORE + AUTH cfgmanager: OFUSCAR
    'server.lua'
}

ui_page 'web/index.html'
files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}

dependency 'inventory'
dependency 'm_garage'
dependency 'm_mansions'

-- Caso use Asset Escrow, estes arquivos formam a ABI/transporte estavel e
-- precisam permanecer legiveis. A logica sensivel e a AUTH ficam no server.lua.
escrow_ignore {
    'client_config.lua',
    'server_config.lua',
    'config.lua',
    'web/**'
}
