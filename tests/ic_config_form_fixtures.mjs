// Only versioned default configuration, cleaned before it enters browser fixtures.
// No runtime snapshots, live database, credentials or network access.
import { readFile } from 'node:fs/promises';
import { withoutPrivate } from '../resources/[scriptcore]/ic_config/web/model.mjs';
const root = new URL('../', import.meta.url);
const read = async path => withoutPrivate(JSON.parse(await readFile(new URL(path, root), 'utf8')));
export async function formFixtures() {
    const [garages, types, shops, jobs, desmanche, zones, robberies, homes, dealership, central, jewelry, vaults] = await Promise.all([
        'resources/[scriptcore]/m_garage/shared-side/garages.json', 'resources/[scriptcore]/m_garage/shared-side/typeGarages.json',
        'resources/[scriptcore]/inventory/config/shared.shops.json', 'resources/[scriptcore]/m_empregos/jobs.json',
        'resources/[scripts]/m_desmanche/config.json', 'resources/[scriptcore]/PolySafeZone/safezones.json',
        'resources/[roubos]/m_roubos/roubos.json', 'resources/[scripts]/residences/residences.json',
        'resources/[scripts]/m_dealership/dealership.json', 'resources/[roubos]/m_banco_central/banco_central.json',
        'resources/[roubos]/m_joalheria/joalheria.json', 'resources/[roubos]/m_roubocofre/roubocofre.json'
    ].map(read));
    const firstEntry = object => Object.fromEntries(Object.entries(object).slice(0, 1));
    homes.residences = homes.residences.slice(0, 1); dealership.vehicles = firstEntry(dealership.vehicles);
    const point = { coords: { x: 1, y: 2, z: 3 } };
    return {
        getManagedGroups: [{ name: 'Grupo de teste', config: { gtype: 'staff', salario: 1000, ptr: false, title: 'Teste', orgName: '', orgType: '' }, permissions: ['perm.teste'] }],
        getItemList: [{ index: 'water', name: 'Água', image: 'water' }, { index: 'metal', name: 'Metal', image: 'metal' }, { index: 'keycard', name: 'Cartão', image: 'keycard' }],
        getChests: [{ name: 'Baú de teste', weight: 100, permission: 'perm.teste', ...point }],
        getGarages: garages.slice(0, 1), getGarageTypes: Object.entries(types).map(([name, data]) => ({ name, data })),
        getMapMarkings: [{ id: 1, name: 'Marca de teste', sprite: 1, color: 0, scale: 0.5, shortRange: true, ...point }],
        getCloakrooms: [{ name: 'Fardamento de teste', permission: 'perm.teste', ...point, uniforms: [{ name: 'Patrulha', masculino: { '3': [1, 2, 3] }, feminino: {}, custom: 'retained' }] }],
        getShops: Object.entries(shops).slice(0, 1).map(([name, data]) => ({ name, data })),
        getClothingShops: [{ id: 1, ...point }], getBarbershops: [{ id: 1, ...point }], getTattooShops: [{ id: 1, ...point }],
        getDesmanches: { ...desmanche, desmanches: desmanche.desmanches.slice(0, 1) }, getSafeZones: zones,
        getJobs: jobs, getRoubos: robberies, getResidences: homes, getDealership: dealership,
        getBancoCentral: central, getJoalheria: jewelry, getRoubocofre: vaults,
        getServerVehicleCatalog: { testcar: { model: 'testcar', name: 'Carro de teste', price: 1000, trunk: 10, type: 'sedans', banned: false, retained: true } }
    };
}
