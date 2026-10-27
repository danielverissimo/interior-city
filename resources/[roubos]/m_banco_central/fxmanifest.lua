fx_version 'bodacious'
game 'gta5'

author 'unknown'
dependency "vrp"

shared_script {
  "@vrp/lib/utils.lua",
  "cfg/config.lua"
}

client_scripts{
  "@vrp/lib/utils.lua",
  "client-side/config_sync.lua",
  "client-side/client.lua"
}

server_scripts{
  "@vrp/lib/utils.lua",
  "config_manager.lua",
  "server.lua"
}

files {
  "banco_central.json"
}
