// Public configuration contracts reconstructed from the installed resource APIs.
// No protected code, remote license calls, supplier assets or default city data.
import { mansionEditable } from './mansions.mjs';
export const AREAS = [
    ['groups', 'Cargos', '01'], ['chests', 'Baús', '02'], ['craft', 'Craft + Farm', '03'],
    ['garages', 'Garagens', '04'], ['mapmarkings', 'Mapa', '05'], ['cloakroom', 'Fardamentos', '06'],
    ['shops', 'Lojas', '07'], ['clothing', 'Roupas', '08'], ['barbershop', 'Barbearias', '09'],
    ['tattoo', 'Tatuagens', '10'], ['desmanche', 'Desmanches', '11'], ['safezone', 'Zonas seguras', '12'],
    ['jobs', 'Empregos', '13'], ['robberies', 'Roubos', '14'], ['houses', 'Residências', '15'],
    ['mansions', 'Mansões', '16'], ['dealership', 'Veículos', '17']
];
const xyz = () => ({ x: null, y: null, z: null });
const objectRows = (value, key = 'name') => Object.entries(value || {}).map(([id, data]) => ({ [key]: id, data }));
const list = value => Array.isArray(value) ? value : objectRows(value);
const identity = value => value;
const privateKey = key => /webhook|token|password|secret|license|authorization/i.test(key) || ['__proto__', 'constructor', 'prototype'].includes(key);
export function withoutPrivate(value) {
    if (Array.isArray(value)) return value.map(withoutPrivate);
    if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).filter(([key]) => !privateKey(key)).map(([key, child]) => [key, withoutPrivate(child)]));
    return value;
}
export function clone(value) { return JSON.parse(JSON.stringify(value)); }

function view(area, id, title, read, options) {
    return { area, id, title, read, rows: list, initial: () => ({}), toEditor: identity, pack: identity, ...options };
}
function pointView(area, title, read, create, update, remove) {
    return view(area, area, title, read, { initial: () => ({ coords: xyz() }), create, update, remove,
        toEditor: row => ({ coords: row.coords }), pack: (data, row) => row ? { id: row.id, ...data } : data,
        deletePayload: row => ({ id: row.id }) });
}
export const VIEWS = [
    view('groups', 'groups', 'Cargos', 'getManagedGroups', { create: 'saveManagedGroup', update: 'saveManagedGroup', remove: 'deleteManagedGroup',
        initial: () => ({ name: '', config: { gtype: '', salario: '', ptr: '', title: '', orgName: '', orgType: '' }, permissions: [] }),
        pack: (group, row) => ({ originalName: row?.name || '', group }), deletePayload: row => ({ name: row.name }) }),
    view('groups', 'fac', 'Criar organização', 'getManagedGroups', { rows: () => [], create: 'createFacGroups',
        initial: () => ({ orgName: '', orgType: '', goalItem: '', goalAmount: 1, defaultReward: 0 }),
        note: 'Cria os cargos e a organização usando as integrações da base. A exclusão do conjunto exige informar o nome exato.',
        extraAction: { method: 'deleteFacBundle', previewMethod: 'previewFacDeletion', label: 'Excluir organização', initial: () => ({ orgName: '' }), danger: true } }),
    view('chests', 'chests', 'Baús', 'getChests', { create: 'createChest', update: 'updateChest', remove: 'deleteChest',
        initial: () => ({ name: '', weight: 1, permission: '', coords: xyz() }), deletePayload: row => ({ name: row.name }) }),
    view('craft', 'craft', 'Bancadas e farm', 'getCraftSetups', { rows: data => data?.benches || [], create: 'saveCraftSetup', update: 'saveCraftSetup', remove: 'deleteCraftSetup',
        initial: () => ({ bench: { name: '', craftPermission: '', armazemPermission: '', coords: [], craftItems: [], armazemItems: [], farmRewardType: '' }, farm: { enabled: false, rewardType: '', routeType: '', permissions: [], rewards: [] } }),
        toEditor: (bench, all) => { const route = (all.farm?.Routes || []).find(item => item.rewardType === bench.farmRewardType) || {}; return { bench, farm: { enabled: !!bench.farmRewardType, rewardType: bench.farmRewardType || '', routeType: bench.farmRouteType || route.routeType || '', permissions: bench.farmPermissions || route.permissions || [], rewards: all.farm?.Rewards?.[bench.farmRewardType] || [] } }; },
        pack: (payload, row) => ({ originalName: row?.name || '', ...payload }), deletePayload: row => ({ name: row.name }),
        note: 'Receitas, materiais, pontos e recompensas são editados em listas JSON. O farm vinculado permanece explícito no formulário.' }),
    view('garages', 'garages', 'Pontos de garagem', 'getGarages', { create: 'createGarage', update: 'updateGarage', remove: 'deleteGarage',
        initial: () => ({ id: '', type: '', permiss: '', blipDistance: 5, coords: xyz(), spawnCoords: [] }),
        pack: (data, row) => ({ ...data, originalId: row?.id }), deletePayload: row => ({ id: row.id }) }),
    view('garages', 'garageTypes', 'Tipos de garagem', 'getGarageTypes', { create: 'createGarageType', update: 'updateGarageType', remove: 'deleteGarageType',
        initial: () => ({ name: '', data: { type: 'public', blip: { showBlip: false, name: '', blipId: 357, blipColor: 0, blipScale: 0.5 }, listCars: { vehicle: true, boat: true, heli: true }, vehicles: [] } }), deletePayload: row => ({ name: row.name }) }),
    view('mapmarkings', 'mapmarkings', 'Marcações do mapa', 'getMapMarkings', { create: 'createMapMarking', update: 'updateMapMarking', remove: 'deleteMapMarking',
        initial: () => ({ name: '', sprite: 1, color: 0, scale: 0.5, shortRange: true, coords: xyz() }), deletePayload: row => ({ id: row.id }) }),
    view('cloakroom', 'cloakroom', 'Fardamentos', 'getCloakrooms', { create: 'saveCloakroom', update: 'saveCloakroom', remove: 'deleteCloakroom',
        initial: () => ({ name: '', permission: '', coords: xyz(), uniforms: [] }), pack: (room, row) => ({ originalName: row?.name || '', room }), deletePayload: row => ({ name: row.name }) }),
    view('shops', 'shops', 'Lojas', 'getShops', { create: 'createShop', update: 'updateShop', remove: 'deleteShop',
        initial: () => ({ name: '', data: { mode: '', perm: '', onlyWalletPayment: false, items: {}, coords: [], blip: { enabled: false, text: '', index: 52, color: 0, scale: 0.5 } } }),
        pack: (data, row) => ({ ...data, originalName: row?.name }), deletePayload: row => ({ name: row.name }) }),
    pointView('clothing', 'Lojas de roupa', 'getClothingShops', 'createClothingShop', 'updateClothingShop', 'deleteClothingShop'),
    pointView('barbershop', 'Barbearias', 'getBarbershops', 'createBarbershop', 'updateBarbershop', 'deleteBarbershop'),
    pointView('tattoo', 'Estúdios de tatuagem', 'getTattooShops', 'createTattooShop', 'updateTattooShop', 'deleteTattooShop'),
    view('desmanche', 'desmanche', 'Desmanches', 'getDesmanches', { rows: data => data?.desmanches || [], create: 'createDesmanche', update: 'updateDesmanche', remove: 'deleteDesmanche',
        initial: () => ({ name: '', permissao: '', precisa_de_item: false, itens_necessarios: [], inicio: xyz(), local_veiculo: xyz(), local_ferramentas: { ...xyz(), w: 0 }, local_finalizar: xyz() }),
        pack: (data, row) => row ? { originalName: row.name, data } : data, deletePayload: row => ({ name: row.name }) }),
    view('safezone', 'safezone', 'Zonas seguras', 'getSafeZones', { rows: data => data?.safezones || [], create: 'createSafeZone', update: 'updateSafeZone', remove: 'deleteSafeZone',
        initial: () => ({ name: '', debug: false, zones: [] }), pack: (data, row) => row ? { originalName: row.name, data } : data, deletePayload: row => ({ name: row.name }),
        note: 'Cada polígono usa coords [{x,y},…], minZ e maxZ. São necessários pelo menos três pontos.' }),
    view('jobs', 'jobs', 'Empregos', 'getJobs', { rows: data => objectRows(data?.jobs), update: 'updateJob',
        toEditor: (row, all) => ({ job: row.data, extra: all.extras?.[row.name] || {} }), pack: (payload, row) => ({ name: row.name, ...payload }),
        extraAction: { method: 'captureJobUniform', label: 'Capturar uniforme', initial: row => ({ name: row?.name || '' }) } }),
    view('robberies', 'robberies', 'Locais de roubo', 'getRoubos', { rows: data => data?.locations || [], create: 'addRobberyLocation', update: 'updateRobberyLocation', remove: 'deleteRobberyLocation',
        initial: () => ({ type: '', id: 1, x: null, y: null, z: null, h: 0 }), pack: (data, row) => row ? { originalType: row.type, originalId: row.id, data } : data,
        deletePayload: row => ({ type: row.type, id: row.id }) }),
    view('robberies', 'robberySetups', 'Tipos de roubo', 'getRoubos', { rows: data => objectRows(data?.setups, 'type'), update: 'saveRobberySetup',
        toEditor: row => row.data, pack: (data, row) => ({ type: row.type, data }) }),
    view('houses', 'houses', 'Residências', 'getResidences', { rows: data => data?.residences || [], create: 'saveResidence', update: 'saveResidence', remove: 'deleteResidence',
        initial: () => ({ name: '', type: 'Casa', interior: '', price: 0, slot: 1, trade: 0, x: null, y: null, z: null }),
        pack: (data, row) => ({ originalName: row?.name || '', data }), deletePayload: row => ({ name: row.name }) }),
    view('houses', 'interiors', 'Interiores', 'getResidences', { rows: data => objectRows(data?.interiors), create: 'saveResidenceInterior', update: 'saveResidenceInterior', remove: 'deleteResidenceInterior',
        initial: () => ({ name: '', data: { type: 'Casa', valor: 0, residents: 1, vault: 0, fridge: 0, interior: [], vaultCoords: [], wardobeCoords: [] } }),
        pack: (data, row) => ({ originalName: row?.name || '', ...data }), deletePayload: row => ({ name: row.name }) }),
    view('mansions', 'mansions', 'Mansões', 'getMansions', { rows: data => data?.mansions || [], create: 'saveMansion', update: 'saveMansion', remove: 'deleteMansion',
        initial: () => mansionEditable(), toEditor: mansionEditable,
        pack: (data, row) => ({ originalId: row?.id || '', data: mansionEditable(data) }), deletePayload: row => ({ id: row.id }),
        note: 'Configure os acessos, baú, garagem e trancas. Proprietário, moradores e estado de compra permanecem sob responsabilidade do sistema de mansões.' }),
    view('dealership', 'dealership', 'Estoque da concessionária', 'getDealership', { rows: data => Object.entries(data?.vehicles || {}).map(([spawn, state]) => ({ spawn, stock: typeof state === 'object' ? state.stock : state })),
        create: 'saveDealershipVehicle', update: 'saveDealershipVehicle', remove: 'deleteDealershipVehicle', initial: () => ({ spawn: '', stock: 0 }), deletePayload: row => ({ spawn: row.spawn }) }),
    view('dealership', 'catalog', 'Catálogo de veículos', 'getServerVehicleCatalog', { rows: data => objectRows(data, 'spawn'), create: 'saveServerVehicle', update: 'saveServerVehicle', remove: 'deleteServerVehicle',
        initial: () => ({ spawn: '', data: { model: '', name: '', price: 0, trunk: 0, type: '', banned: false } }),
        pack: (data, row) => ({ originalSpawn: row?.spawn || '', ...data }), deletePayload: row => ({ spawn: row.spawn }),
        extraAction: { method: 'deleteServerVehiclesBatch', label: 'Excluir vários veículos', initial: () => ({ vehicles: [] }), danger: true } })
];

function settings(area, id, title, read, update, select) {
    VIEWS.push(view(area, id, title, read, { singleton: true, rows: data => [select(data || {})], update, toEditor: identity, note: 'Destinos de logs e credenciais permanecem privados no servidor.' }));
}
settings('desmanche', 'desmancheSettings', 'Regras do desmanche', 'getDesmanches', 'saveDesmancheSettings', data => data.settings || {});
settings('safezone', 'safezoneSettings', 'Regras das zonas', 'getSafeZones', 'saveSafeZoneSettings', data => ({ ...(data.settings || {}), whitelist: data.whitelist || [] }));
settings('jobs', 'jobsSettings', 'Central de empregos', 'getJobs', 'saveJobsGlobal', data => ({ central: data.central || [], npc: data.npc || [] }));
settings('robberies', 'robberySettings', 'Regras dos roubos', 'getRoubos', 'saveRobberyGlobalSettings', data => data.settings || {});
settings('robberies', 'centralBank', 'Banco Central', 'getBancoCentral', 'saveBancoCentral', identity);
settings('robberies', 'jewelry', 'Joalheria', 'getJoalheria', 'saveJoalheria', identity);
settings('robberies', 'vaults', 'Cofres', 'getRoubocofre', 'saveRoubocofre', identity);
settings('dealership', 'dealershipSettings', 'Regras da concessionária', 'getDealership', 'saveDealershipSettings', data => ({ settings: data.settings || {}, testDrive: data.testDrive || {}, categories: data.categories || [], vips: data.vips || [] }));

export function recordsFor(view, data) {
    const source = view.rows(data) || [];
    // Empty Lua tables may be encoded as {} rather than [] by the NUI bridge.
    return (Array.isArray(source) ? source : Object.values(source)).map(value => withoutPrivate(value));
}
export function displayName(row) { return String(row?.name ?? row?.spawn ?? (row?.type ? `${row.type} #${row.id ?? ''}` : row?.id) ?? 'Configuração'); }
function defaults(template, value) {
    if (!template || typeof template !== 'object' || Array.isArray(template) || !value || typeof value !== 'object' || Array.isArray(value)) return value;
    const merged = clone(template);
    for (const [key, child] of Object.entries(value)) merged[key] = Object.hasOwn(template, key) ? defaults(template[key], child) : child;
    return merged;
}
export function editorValue(view, row, data) { return withoutPrivate(clone(row ? defaults(view.initial(), view.toEditor(row, data)) : view.initial())); }
export function mutationFor(view, value, row) {
    const method = row ? view.update : view.create;
    if (!method) throw new Error('Esta operação não está disponível nesta área.');
    return { method, payload: view.pack(withoutPrivate(value), row) };
}
