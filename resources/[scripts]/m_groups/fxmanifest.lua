
fx_version 'adamant'
game 'gta5'

lua54 'yes'

shared_script { '@vrp/lib/utils.lua', 'lib/tunnel.lua' }
client_scripts { 'client.lua' }
server_scripts { 'server.lua'}

ui_page 'web-side/index.html'
files { 'web-side/*', 'web-side/assets/*' }
