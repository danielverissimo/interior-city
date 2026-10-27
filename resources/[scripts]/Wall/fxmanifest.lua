clr_disable_task_scheduler "yes"
fx_version "adamant"
game "gta5"

author "PEDRIN#0001"

ui_page "web/index.html"

files {
    "web/index.html",
    "web/style.css",
    "web/app.js"
}

server_scripts {
    "@vrp/lib/utils.lua",
    "src/_s.lua"
}

client_scripts {
    "@vrp/lib/utils.lua",
    "src/_c.lua"
}
