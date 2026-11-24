fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Interior City'
description 'Pontos independentes para iniciar as rotas existentes do m_farm'
version '1.0.0'

dependencies {'vrp','m_farm'}
shared_scripts {'@vrp/lib/utils.lua','config.lua'}
client_script 'client.lua'
server_script 'server.lua'
