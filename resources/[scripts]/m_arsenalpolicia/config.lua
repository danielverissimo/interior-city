Config = {}
Config.Command = 'arsenalpolicia'
Config.OwnerGroup = 'dono'
Config.PolicePermissions = { 'perm.policia', 'perm.militar' }
Config.DefaultLocation = { x=447.30, y=-975.65, z=30.68 }
Config.DrawDistance = 12.0
Config.InteractionDistance = 2.0
Config.ServerDistance = 4.0
Config.MaxPrice = 10000000
Config.MaxPurchaseTotal = 1000000000
Config.PurchaseCooldownMs = 1000
Config.Blip = { sprite=110, color=5, scale=0.65, name='Arsenal Policial' }
Config.DefaultPrice = 1000
Config.Items = {
    { id='weapon_parafal', image='./images/weapon_parafal.png', name='PARAFAL', category='armas', maxQuantity=1, unit='unidade' },
    { id='ammo_parafal', name='Municao Parafal', category='municoes', maxQuantity=250, unit='municao' },
    { id='weapon_carbinerifle', image='./images/weapon_carbinerifle.png', name='M4', category='armas', maxQuantity=1, unit='unidade' },
    { id='ammo_carbinerifle', image='./images/ammo_carbinerifle.png', name='M-M4', category='municoes', maxQuantity=250, unit='municao' },
    { id='weapon_combatpistol', image='./images/weapon_combatpistol.png', name='Glock', category='armas', maxQuantity=1, unit='unidade' },
    { id='ammo_combatpistol', image='./images/ammo_combatpistol.png', name='M-Glock', category='municoes', maxQuantity=250, unit='municao' },
    { id='weapon_smg', image='./images/weapon_smg.png', name='SMG', category='armas', maxQuantity=1, unit='unidade' },
    { id='ammo_smg', image='./images/ammo_smg.png', name='M-SMG', category='municoes', maxQuantity=250, unit='municao' },
    { id='body_armor', image='./images/body_armor.png', name='Colete', category='equipamentos', maxQuantity=10, unit='unidade' },
    { id='radio', image='./images/radio.png', name='Radio', category='equipamentos', maxQuantity=10, unit='unidade' },
    { id='algemas', image='./images/algemas.png', name='Algemas', category='equipamentos', maxQuantity=10, unit='unidade' },
    { id='weapon_stungun', image='./images/weapon_stungun.png', name='Taser', category='equipamentos', maxQuantity=10, unit='unidade' },
    { id='weapon_nightstick', image='./images/weapon_nightstick.png', name='Cassetete', category='equipamentos', maxQuantity=10, unit='unidade' },
    { id='gadget_parachute', image='./images/gadget_parachute.png', name='Paraquedas', category='equipamentos', maxQuantity=10, unit='unidade' },
}
