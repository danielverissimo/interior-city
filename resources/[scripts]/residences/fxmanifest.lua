

fx_version "bodacious"
game "gta5"
ui_page 'nui/index.html'

client_scripts {
	"@vrp/lib/utils.lua",
	"client-side/*.lua"
}

server_scripts {
	"@vrp/lib/utils.lua",
	"server-side/prepares.lua",
	"server-side/config_manager.lua",
	"server-side/server.lua"
}

files {
	'nui/index.html',
	'nui/css/bootstrap.min.css',
	'nui/css/jquery-ui.css',
	'nui/css/style.css',
	'nui/js/jquery-2.2.4.min.js',
	'nui/js/jquery-ui.min.js',
	'nui/js/ui.js',
	'residences.json'
	

}              