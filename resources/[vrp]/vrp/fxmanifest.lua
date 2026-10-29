
-- shared_script '@likizao_ac/client/library.lua'

lua54 'yes'

fx_version 'adamant'
game 'gta5'

ui_page "web-side/index.html"

server_scripts {
	"@oxmysql/lib/MySQL.lua",
	"lib/utils.lua",
	"base.lua",
	"@inventory/config/shared.items.lua",
	"server-side/*",
-- "mysql_driver.lua"
}

client_scripts {
	"lib/utils.lua",
	"lib/custom.lua",
	"client-side/*"
}

files {
	'cfg/groups.json',
	"lib/Tunnel.lua",
	"lib/Proxy.lua",
	"lib/Tools.lua",
	"lib/Protect.lua",
	"web-side/**/*",
	"web-side/*",
	'loading/*',
	'loading/css/**',
    'loading/fonts/**',
    'loading/icons/**',
	'loading/js/**',
	'loading/intro/**'
}

loadscreen "loading/index.html"   


-- Adicione estas linhas no final do seu vrp/fxmanifest.lua
server_exports {
	'getProxy'
  }
