fx_version 'bodacious'
game 'gta5'

author ''
contact ''
version '1.0.0'

ui_page 'web/build/index.html'

client_script{
    '@vrp/lib/utils.lua',
    'client.lua',
    'config.lua'
}

server_script {
    '@vrp/lib/utils.lua',
	'server.lua',
    'config.lua'
}

files {
  'web/build/index.html',
  'web/build/**/*'
}
