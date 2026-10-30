import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createTransport } from '../resources/[scriptcore]/ic_mansions/web/transport.mjs';
import { saleRefund, residentId, can, priceMap, filterCatalog, taxExpired, operationSummary } from '../resources/[scriptcore]/ic_mansions/web/model.mjs';

test('purchase transports the reviewed quote identity once and preserves the server refusal', async () => {
    let count = 0;
    const transport = createTransport({ fetcher: async (_url, options) => {
        count++; const request = JSON.parse(options.body);
        assert.deepEqual(request.payload, { id: 'm1', quoteToken: 'fixture-quote', confirmed: true });
        return { json: async () => ({ requestId: request.requestId, ok: false, error: { code: 'QUOTE_EXPIRED', message: 'Solicite nova proposta.' } }) };
    } });
    await assert.rejects(transport.call('confirmPurchase', { id: 'm1', quoteToken: 'fixture-quote', confirmed: true }), error => error.code === 'QUOTE_EXPIRED');
    assert.equal(count, 1);
});
test('timeouts never repeat financial effects and mismatched responses are refused', async () => {
    let count = 0;
    const transport = createTransport({ timeout: 5, fetcher: (_url, { signal }) => { count++; return new Promise((_resolve, reject) => signal.addEventListener('abort', () => reject(Object.assign(new Error(), { name: 'AbortError' })))); } });
    await assert.rejects(transport.call('payIptu', { mansionId: 'm1', confirmed: true }), error => error.code === 'TIMEOUT'); assert.equal(count, 1);
    const mismatch = createTransport({ fetcher: async () => ({ json: async () => ({ requestId: 'different', ok: true, data: {} }) }) });
    await assert.rejects(mismatch.call('getContext'), error => error.code === 'RESPONSE_MISMATCH');
});
test('furniture refunds use purchase cost rather than a changed catalogue price', () => {
    assert.equal(saleRefund({ paidPrice: 1001, price: 9000 }, 15), 150);
    assert.equal(saleRefund({ price: 9000 }, 15), 0);
    assert.equal(saleRefund({ paidPrice: 100 }, 500), 100);
});
test('resident and decoration actions require exact server flags and valid passports', () => {
    assert.equal(can({ canFurniture: 'true' }, 'canFurniture'), false); assert.equal(can({ canFurniture: true }, 'canFurniture'), true);
    assert.equal(residentId('42'), 42);
    for (const value of ['', 0, -1, 2.5, Infinity, 'name']) assert.throws(() => residentId(value));
});
test('price edits preserve hidden rows and reject negative or fractional values', () => {
    const items = [{ id: 'a', name: 'Chair' }, { id: 'b', name: 'Table' }];
    assert.deepEqual(priceMap(items, new Map([['a', '100'], ['b', '250'], ['unknown', '1000']])), { a: 100, b: 250 });
    assert.throws(() => priceMap(items, new Map([['a', '-1']]))); assert.throws(() => priceMap(items, new Map([['a', '2.5']])));
    assert.deepEqual(filterCatalog([{ name: 'Sofá', model: 'sofa', category: 'Sala' }, { name: 'Mesa', model: 'desk', category: 'Escritório' }], 'desk', 'Escritório').map(item => item.name), ['Mesa']);
    assert.equal(taxExpired(100, 100001), true); assert.equal(taxExpired(200, 100001), false);
});
test('own mansion NUI starts closed and has no supplier images or executable assets', async () => {
    const html = await readFile(new URL('../resources/[scriptcore]/ic_mansions/web/index.html', import.meta.url), 'utf8');
    const app = await readFile(new URL('../resources/[scriptcore]/ic_mansions/web/app.mjs', import.meta.url), 'utf8');
    assert.match(html, /id="home" hidden/); assert.match(app, /get\('preview'\) === '1'/);
    assert.ok(!/<(?:script|img|link)[^>]+(?:src|href)=["']https?:/.test(html));
    assert.ok(!/innerHTML|insertAdjacentHTML|eval\(|electron-services/.test(app));
    for (const method of ['getContext', 'requestPurchase', 'confirmPurchase', 'addResident', 'removeResident', 'payIptu', 'startFurniturePlacement', 'startFurnitureMove', 'sellFurniture', 'saveFurniturePrices', 'quoteCleanup', 'cleanupMansion']) assert.ok(app.includes(`'${method}'`), method);
});

test('recovery summaries expose bounded identifiers and financial effects without raw private detail', () => {
    const summary = operationSummary({ id: 'op-1', kind: 'purchase', phase: 'uncertain', mansionId: 'm1', actorId: 4, createdAt: 1700000000, detail: { amount: 1000, voucher: 'valemansao1m', quantity: 1, password: 'private-fixture', webhook: 'private-destination', before: { name: 'Mansion', group: 'MansionGroup', ownerId: 7, members: [2], furniture: [{ id: 'f1' }], secret: 'private-fixture' }, integrations: { group: { name: 'MansionGroup', password: 'private-fixture' } } } });
    assert.ok(summary.some(([key, value]) => key === 'Vale' && value === 'valemansao1m'));
    assert.ok(summary.some(([key, value]) => key === 'Anterior: moradores adicionais' && value === '1'));
    assert.ok(!JSON.stringify(summary).includes('private-fixture')); assert.ok(!JSON.stringify(summary).includes('private-destination'));
    assert.ok(operationSummary({ id: 'x'.repeat(500) }).every(([_key, value]) => value.length <= 180));
});

test('recovery lists manual group assignments with exact expiry while excluding identities and private fields', () => {
    const summary = operationSummary({ id: 'op-remove', kind: 'admin_remove', phase: 'uncertain', detail: { integrations: { groupAssignments: { group: 'MansionGroup', count: 202, assignments: Array.from({ length: 202 }, (_value, index) => ({ userId: index + 1, online: index === 0, ...(index === 0 ? { expiresAt: 1800000000 } : {}), name: 'private-identity', token: 'private-fixture' })) } } } });
    assert.ok(summary.some(([key, value]) => key === 'Cargo dos vínculos a conferir' && value === 'MansionGroup'));
    assert.ok(summary.some(([key, value]) => key === 'Vínculo no cargo: ID 1' && value.includes('Online') && value.includes('1800000000')));
    assert.ok(summary.some(([key, value]) => key === 'Vínculo no cargo: ID 2' && value.includes('Offline') && value.includes('Sem validade registrada')));
    assert.equal(summary.filter(([key]) => key.startsWith('Vínculo no cargo: ID ')).length, 200);
    assert.ok(summary.some(([key, value]) => key === 'Demais vínculos' && value.startsWith('2 não exibidos')));
    assert.ok(!JSON.stringify(summary).includes('private-identity')); assert.ok(!JSON.stringify(summary).includes('private-fixture'));
});
