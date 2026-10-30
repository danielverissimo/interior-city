-- Server switches are deliberately opt-in. No vendor license service is used.
ICConfig = {
    Enabled = GetConvar('ic_config_enabled', 'false') == 'true',
    WritesEnabled = GetConvar('ic_config_writes_enabled', 'false') == 'true',
    PreviousResource = 'mg_config_panel',
    AllowedGroups = { developer = true, dono = true },
    Resources = {
        Inventory = 'inventory', Garage = 'm_garage', Craft = 'm_craft',
        Farm = 'm_farm', Skinshop = 'm_skinshop', Barbershop = 'm_barbershop',
        Tattoo = 'm_tattoos', Cloakroom = 'm_cloakroom', Snippets = 'm_snippets',
        Vrp = 'vrp', Orgs = 'm_orgs_v2', Desmanche = 'm_desmanche',
        SafeZone = 'PolySafeZone', Empregos = 'm_empregos', Roubos = 'm_roubos',
        BancoCentral = 'm_banco_central', Joalheria = 'm_joalheria',
        Roubocofre = 'm_roubocofre', Residences = 'residences',
        Dealership = 'm_dealership', Mansions = GetConvar('ic_mansions_resource','m_mansions'), Doors = 'doorsv2'
    }
}
