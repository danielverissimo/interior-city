-- shared_script '@likizao_ac/client/library.lua'
fx_version "bodacious"
game "gta5"
lua54 'yes'

resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

client_scripts {
	'@PolyZone/client.lua',
	"@vrp/lib/utils.lua",
	"client/mage_admin_logs.lua",
	"client.lua",
	-- "vipsystem/client/*.lua",
	"client_modules/*"
}

server_scripts {
	"@vrp/lib/utils.lua",
	"server/mage_admin_logs.lua",
	"server.lua",
	"logs.lua",
"modules/*"
}

-- ui_page "vipsystem/nui/index.html"
-- files { "vipsystem/nui/*" }          
                                          