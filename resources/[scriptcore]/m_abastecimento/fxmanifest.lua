fx_version 'cerulean'
game 'gta5'

description 'Atendimento em postos de combustivel da Interior City'

ui_page 'nui/index.html'
files { 'nui/index.html', 'nui/style.css', 'nui/app.js' }

shared_script 'config.lua'
client_script 'client.lua'
server_scripts { '@vrp/lib/utils.lua', 'server.lua' }

dependencies { 'vrp', '/onesync' }
