Config = {}

Config.Command = 'painelconfig'
Config.RequirePermission = true
-- Somente estes cargos exatos podem abrir/usar o painel.
-- A verificacao e feita novamente no servidor em todas as operacoes da NUI.
Config.AllowedGroups = { 'developer', 'dono' }

-- Mantidos apenas por compatibilidade com configuracoes antigas; nao concedem acesso
-- enquanto AllowedGroups estiver configurado.
Config.Permissions = {}
Config.AcePermission = ''

Config.InventoryResource = 'inventory'
Config.GarageResource = 'm_garage'

Config.CraftResource = 'm_craft'
Config.FarmResource = 'm_farm'

Config.SkinshopResource = 'm_skinshop'

Config.BarbershopResource = 'm_barbershop'

Config.TattooResource = 'm_tattoos'

Config.CloakroomResource = 'm_cloakroom'

Config.SnippetsResource = 'm_snippets'

Config.VrpResource = 'vrp'

Config.OrgsResource = 'm_orgs_v2'

Config.DesmancheResource = 'm_desmanche'

Config.SafeZoneResource = 'PolySafeZone'

Config.EmpregosResource = 'm_empregos'

Config.RoubosResource = 'm_roubos'

Config.BancoCentralResource = 'm_banco_central'

Config.JoalheriaResource = 'm_joalheria'

Config.RoubocofreResource = 'm_roubocofre'

Config.ResidencesResource = 'residences'

Config.DealershipResource = 'm_dealership'

Config.MansionsResource = 'm_mansions'
Config.DoorsResource = 'doorsv2'
