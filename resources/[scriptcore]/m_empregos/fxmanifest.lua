fx_version "bodacious"
game "gta5"
this_is_a_map 'yes'

ui_page "nui/index.html"

shared_script "@vrp/lib/utils.lua"

client_scripts {
    "config.lua",
    "config_sync.lua",
    "client.lua",
    "empregos/**/c_*.lua"
}

server_scripts {
    "server_config.lua",
    "config.lua",
    "mage_logs.lua",
    "config_manager.lua",
    "server.lua",
    "empregos/**/s_*.lua"
}

files {
    "jobs.json",
    "nui/**",
    "nui/images/**",
    "empregos/**/**/"
}

data_file 'DLC_ITYP_REQUEST' 'stream/props.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/prop_ic_ladder.ydr'
