lua54 'yes'

fx_version 'bodacious'
game 'gta5'

shared_script { '@vrp/lib/utils.lua', "lib/*.lua", 'config.lua' }
client_script { '@vrp/lib/utils.lua', 'client/**/*.lua'}
server_scripts { '@vrp/lib/utils.lua', 'server/00_dynamic_orgs.lua', 'server/main.lua', 'server/modules/*.lua' }

ui_page 'ui/build/index.html'
files {
	'dynamic_orgs.json',
	'ui/build/*',
	'ui/build/**/*'
}
