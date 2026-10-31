import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createTransport, createLatestLoader, createWriteGate, escapeHtml } from '../resources/[scriptcore]/ic_config/web/transport.mjs';
import { AREAS, VIEWS, recordsFor, mutationFor, editorValue, withoutPrivate, teleportCoords } from '../resources/[scriptcore]/ic_config/web/model.mjs';
import { mansionEditable, mansionDoor, mansionPermission } from '../resources/[scriptcore]/ic_config/web/mansions.mjs';

test('transport sends one identified mutation and preserves server error', async () => {
    let calls = 0;
    const rpc = createTransport({ fetcher: async (url, options) => {
        calls++; assert.equal(url, 'https://ic_config/request'); const request = JSON.parse(options.body);
        assert.equal(request.method, 'saveManagedGroup'); assert.equal(request.payload.group.name, 'Test');
        return { json: async () => ({ requestId: request.requestId, ok: false, error: { code: 'WRITES_DISABLED', message: 'Gravação desativada.' } }) };
    } });
    await assert.rejects(rpc.call('saveManagedGroup', { group: { name: 'Test' } }), error => error.code === 'WRITES_DISABLED');
    assert.equal(calls, 1); assert.equal(rpc.pending.size, 0);
});
test('transport rejects mismatched responses and never retries after a timeout', async () => {
    const mismatch = createTransport({ fetcher: async () => ({ json: async () => ({ requestId: 'other', ok: true, data: 'wrong' }) }) });
    await assert.rejects(mismatch.call('getChests'), error => error.code === 'RESPONSE_MISMATCH');
    let calls = 0;
    const timeout = createTransport({ timeout: 5, fetcher: async (_url, { signal }) => { calls++; return new Promise((_resolve, reject) => signal.addEventListener('abort', () => reject(Object.assign(new Error(), { name: 'AbortError' })))); } });
    await assert.rejects(timeout.call('deleteChest', { name: 'test' }), error => error.code === 'TIMEOUT');
    assert.equal(calls, 1); assert.equal(timeout.pending.size, 0);
});
test('late loads cannot replace the newly selected area or restore closed UI', async () => {
    const pending = new Map(), seen = [];
    const loader = createLatestLoader(key => new Promise(resolve => pending.set(key, resolve)), value => seen.push(value));
    const first = loader.run('old'), second = loader.run('new');
    pending.get('new')('new-result'); await second; pending.get('old')('old-result'); await first;
    assert.deepEqual(seen, ['new-result']);
    const closing = loader.run('closed'); loader.cancel(); pending.get('closed')('late'); await closing;
    assert.deepEqual(seen, ['new-result']);
});
test('write gate rejects repeated submission until its first mutation completes', async () => {
    const gate = createWriteGate(); let finish, calls = 0;
    const first = gate.run(() => { calls++; return new Promise(resolve => { finish = resolve; }); });
    await assert.rejects(gate.run(() => { calls++; }), error => error.code === 'BUSY');
    assert.equal(calls, 1); finish('done'); assert.equal(await first, 'done'); assert.equal(gate.busy, false);
});
test('all 17 areas expose original contract names without vendor runtime dependencies', () => {
    assert.equal(AREAS.length, 17);
    for (const [id] of AREAS) assert.ok(VIEWS.some(view => view.area === id), id);
    assert.ok(VIEWS.some(view => view.read === 'getGarageTypes'));
    assert.ok(VIEWS.some(view => view.update === 'saveServerVehicle'));
    assert.ok(VIEWS.some(view => view.update === 'saveRobberySetup'));
});
test('teleport uses the original destination for each location view and rejects missing/invalid coordinates', () => {
    const tp = (id, row) => teleportCoords(VIEWS.find(view => view.id === id), row);
    const p = { x: 1, y: 2, z: 3 };
    for (const id of ['chests', 'garages', 'mapmarkings', 'cloakroom', 'clothing', 'barbershop', 'tattoo']) assert.deepEqual(tp(id, { coords: p }), p);
    assert.deepEqual(tp('craft', { coords: [p, { x: 9, y: 9, z: 9 }] }), p);
    assert.deepEqual(tp('shops', { data: { coords: [{ coords: p }] } }), p);
    assert.deepEqual(tp('jobs', { data: { inicio: ['1', '2', '3'] } }), p);
    assert.deepEqual(tp('desmanche', { inicio: p }), p);
    assert.deepEqual(tp('mansions', { purchaseCoords: p }), p);
    assert.deepEqual(tp('houses', p), p); assert.deepEqual(tp('robberies', p), p);
    assert.deepEqual(tp('safezone', { zones: [{ coords: [{ x: 0, y: 0 }, { x: 6, y: 0 }, { x: 0, y: 6 }], minZ: 2, maxZ: 4 }] }), { x: 2, y: 2, z: 3 });
    for (const coords of [{ x: null, y: 2, z: 3 }, { x: '', y: 2, z: 3 }, { x: true, y: 2, z: 3 }, { x: Infinity, y: 2, z: 3 }, { x: 1000001, y: 2, z: 3 }]) assert.equal(tp('chests', { coords }), null);
    assert.equal(tp('craft', { coords: [] }), null);
    assert.equal(tp('safezone', { zones: [{ coords: [{ x: 1, y: 2 }], minZ: 0, maxZ: 1 }] }), null);
    assert.equal(tp('groups', { coords: p }), null); assert.equal(tp('garageTypes', { coords: p }), null);
    assert.equal(tp('catalog', { coords: p }), null); assert.equal(tp('robberySettings', p), null);
});
test('private configuration is excluded recursively and unsafe names remain inert', () => {
    const payload = JSON.parse('{"settings":{"webhook":"private","tax":2},"rows":[{"token":"private","name":"<img onerror=steal()>"}],"__proto__":{"polluted":true}}');
    assert.deepEqual(withoutPrivate(payload), { settings: { tax: 2 }, rows: [{ name: '<img onerror=steal()>' }] });
    assert.equal({}.polluted, undefined);
    assert.equal(escapeHtml('<img src=x onerror="x">\'&'), '&lt;img src=x onerror=&quot;x&quot;&gt;&#39;&amp;');
});
test('mutation adapters preserve original identity and collection formats', () => {
    const garage = VIEWS.find(view => view.id === 'garages');
    assert.deepEqual(mutationFor(garage, { id: 'new' }, { id: 'old' }), { method: 'updateGarage', payload: { id: 'new', originalId: 'old' } });
    const group = VIEWS.find(view => view.id === 'groups');
    assert.deepEqual(mutationFor(group, { name: 'new', permissions: ['perm.new'] }, { name: 'old' }), { method: 'saveManagedGroup', payload: { originalName: 'old', group: { name: 'new', permissions: ['perm.new'] } } });
    const robbery = VIEWS.find(view => view.id === 'robberies');
    assert.deepEqual(mutationFor(robbery, { type: 'bank', id: 2 }, { type: 'shop', id: 1 }).payload, { originalType: 'shop', originalId: 1, data: { type: 'bank', id: 2 } });
    const craft = VIEWS.find(view => view.id === 'craft');
    const data = { benches: [{ name: 'bench', farmRewardType: 'route' }], farm: { Routes: [{ rewardType: 'route', routeType: 'fixed', permissions: ['perm.route'] }], Rewards: { route: [{ items: [{ item: 'wood', min: 1, max: 2 }] }] } } };
    const value = editorValue(craft, recordsFor(craft, data)[0], data);
    assert.equal(value.farm.enabled, true); assert.equal(value.farm.routeType, 'fixed');
    assert.deepEqual(value.farm.rewards[0].items, [{ item: 'wood', min: 1, max: 2 }]);
});
test('NUI starts closed, has explicit synthetic preview and no remote scripts/assets', async () => {
    const html = await readFile(new URL('../resources/[scriptcore]/ic_config/web/index.html', import.meta.url), 'utf8');
    const app = await readFile(new URL('../resources/[scriptcore]/ic_config/web/app.mjs', import.meta.url), 'utf8');
    assert.match(html, /id="panel" hidden/); assert.match(html, /Dados fictícios/);
    assert.ok(!/<(?:script|link|img)[^>]+(?:src|href)=["']https?:/i.test(html));
    assert.ok(!/innerHTML|insertAdjacentHTML|eval\(/.test(app));
    assert.match(app, /get\('preview'\) === '1'/); assert.match(app, /role', 'tab'/);
});

test('mansion editing excludes ownership, members, tax dates, furniture and integration-controlled identifiers', () => {
    const original = { id: 'old', name: 'Mansion', group: 'MansaoVinewood', permission: 'perm.internal', ownerId: 7, residents: [{ id: 7 }], iptuDueAt: 123456, furniture: [{ id: 8 }], price: 100, voucher: 'valemansao1m', maxResidents: 3, purchaseCoords: { x: 1, y: 2, z: 3 }, chest: { enabled: true, name: 'owned_chest', weight: 50, coords: { x: 4, y: 5, z: 6 } }, garage: { enabled: false, originalId: 'runtime' }, doors: [{ hash: 123, x: 1, y: 2, z: 3, perm: 'private', mansionId: 'old', isGate: true }] };
    const view = VIEWS.find(view => view.id === 'mansions');
    const draft = editorValue(view, original, { mansions: [original] });
    assert.equal(draft.ownerId, undefined); assert.equal(draft.id, undefined); assert.equal(draft.residents, undefined); assert.equal(draft.iptuDueAt, undefined); assert.equal(draft.permission, undefined); assert.equal(draft.furniture, undefined);
    assert.equal(draft.chest.name, undefined); assert.equal(draft.garage.originalId, undefined); assert.equal(draft.doors[0].perm, undefined); assert.equal(draft.doors[0].mansionId, undefined);
    const mutation = mutationFor(view, { ...draft, ownerId: 99, permission: 'spoofed' }, original);
    assert.equal(mutation.method, 'saveMansion'); assert.equal(mutation.payload.originalId, 'old'); assert.equal(mutation.payload.data.ownerId, undefined); assert.equal(mutation.payload.data.permission, undefined);
    assert.equal(mansionPermission('Mansão São João'), 'perm.mansaosaojoao');
    assert.equal(mansionDoor({ lock: false }).lock, true);
    assert.equal(mansionEditable().chest.enabled, false);
});
