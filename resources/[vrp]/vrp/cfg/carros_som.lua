local pack = {}

pack.vehicles = {
    { spawn = 'baller', name = 'Ford F-250 Rebaixada' },
    { spawn = 'ingot', name = 'Chevrolet Celta Motors Garage', image = 'imgs/vehicles/carros_som_ingot.png' },
    { spawn = 'chevys10', name = 'Chevrolet S10 2017 Aro 24', image = 'imgs/vehicles/carros_som_chevys10.png' },
    { spawn = 'blista2', name = 'Volkswagen Gol GTS Rebaixado', image = 'imgs/vehicles/carros_som_blista2.png' },
    { spawn = 'exemplar', name = 'Chevrolet Monza Rebaixado', image = 'imgs/vehicles/carros_som_exemplar.png' },
    { spawn = 'zion', name = 'Volkswagen Saveiro Deboche', image = 'imgs/vehicles/carros_som_zion.png' },
    { spawn = 'vwsava', name = 'Volkswagen Saveiro Estilo Dub', image = 'imgs/vehicles/carros_som_vwsava.png' },
    { spawn = 'oracle', name = 'Volkswagen Saveiro Summer', image = 'imgs/vehicles/carros_som_oracle.png' }
}

pack.aliases = {
    f250 = 'baller', fordf250 = 'baller',
    celta = 'ingot', s10 = 'chevys10', ts10 = 'chevys10',
    gol = 'blista2', golgts = 'blista2', monza = 'exemplar',
    saveirodeboche = 'zion', saveirodeboxe = 'zion',
    saveiroestilodub = 'vwsava', saveirosummer = 'oracle',
    unoescada = 'unoservice', patinete = 'serv_electricscooter',
    mix150 = '150', hondamix = '150',
    twister = 'bati', cbx150 = 'bati', cbx250 = 'bati', cbxtwister = 'bati',
    bros = 'bros150', hondabros150 = 'bros150', hornet = 'hornetagstore'
}

function pack.resolve(value)
    local model = tostring(value or ''):lower():gsub('^%s+', ''):gsub('%s+$', '')
    model = model:gsub('^/car%s+', ''):gsub('\\', '')
    local alias = model:gsub('[%s_%-]', '')
    return pack.aliases[alias] or model
end

return pack
