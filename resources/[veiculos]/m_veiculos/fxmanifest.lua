-- shared_script '@comida/ai_module_fg-obfuscated.lua'
-- shared_script "@ThnAC/native.lua"
-- shared_script "@ThnAC/natives.lua"
-----------------------------------| Black Cars |-----------------------------------
--------------------------| https://discord.gg/blackcars |--------------------------
 fx_version 'adamant'
game 'gta5'
files {
	"data/**/*",
	"data/**",
	"data/*",
	"data/**/handling.meta",
	"data/**/vehiclelayouts.meta",
	"data/**/vehicles.meta",
	"data/**/carcols.meta",
	"data/**/carvariations.meta",
	"audio/*",
	"audio/**/*",
}
client_script "tuning.lua"
-- METAS
data_file "HANDLING_FILE" "data/**/handling.meta"
data_file "VEHICLE_LAYOUTS_FILE" "data/**/vehiclelayouts.meta"
data_file "VEHICLE_METADATA_FILE" "data/**/vehicles.meta"
data_file "CARCOLS_FILE" "data/**/carcols.meta"
data_file "VEHICLE_VARIATION_FILE" "data/**/carvariations.meta"
              