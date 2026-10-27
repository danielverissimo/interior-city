-- shared_script '@likizao_ac/client/library.lua'


fx_version "bodacious"
game "gta5"
lua54 'yes'

shared_script "@vrp/lib/utils.lua"

client_scripts {
   "client.lua"
}


server_scripts {
   "server.lua"
}

files {
    'damage-weapons/*.meta',
    'damage-weapons/**/**/*.meta'
}

data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weapons.meta'

data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weaponbottleaxe.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weaponbottle.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weaponbullpuprifle.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weaponcompactrifle.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weaponflashlight.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weapongusenberg.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weaponhatchet.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weaponheavypistol.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weaponknuckle.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weaponmachete.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weaponmachinepistol.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weaponminismg.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weaponmusket.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weaponpoolcue.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weaponrevolver.meta'

data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weapons_assaultrifle_mk2.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weapons_bullpuprifle_mk2.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weapons_carbinerifle_mk2.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weapons_pistol_mk2.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weapons_pumpshotgun_mk2.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weapons_smg_mk2.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weapons_snspistol_mk2.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weapons_specialcarbine_mk2.meta'

data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weaponsnspistol.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weaponspecialcarbine.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weaponstonehatchet.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weaponvintagepistol.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weaponwrench.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'damage-weapons/weaponparafal.meta'

