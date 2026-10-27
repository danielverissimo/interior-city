---shared_script '@likizao_ac/client/library.lua'



fx_version 'adamant'
games { 'gta5' }

ui_page 'html/index.html'
files {
	'html/index.html',
	'html/pricedown.ttf',
	'html/cursor.png',
	'html/background.png',
	'html/style.css',
	'html/scripts.js',
	'html/nui.png',
	'html/debounce.min.js',
	'private_radios.json'
}

client_scripts {
	'@vrp/lib/utils.lua',
	'client/main.lua'
}

server_scripts {
    '@vrp/lib/utils.lua',
	'server.lua'
}                            

dependency 'pma-voice'
