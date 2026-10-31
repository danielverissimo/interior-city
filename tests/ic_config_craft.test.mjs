import test from 'node:test';
import assert from 'node:assert/strict';
import { craftDraft, readCraftDraft } from '../resources/[scriptcore]/ic_config/web/craft.mjs';

const fixture = () => ({ bench: { name: 'Mafia teste', craftPermission: 'perm.craft', armazemPermission: 'perm.store', custom: { keep: true },
    coords: [{ x: 1, y: 2, z: 3, heading: 45 }], craftItems: [{ spawn: 'old-product', name: 'Produto antigo', image: 'old-image', amount: 1, time: 7, custom: 'recipe', requires: [{ name: 'piece', image: 'piece-image', amount: 10, custom: 'require' }] }],
    armazemItems: [{ spawn: 'piece', name: 'Peça antiga', image: 'piece-image', custom: 'store' }, { spawn: 'extra', name: 'Extra', custom: true }] },
    farm: { enabled: true, rewardType: 'Armas', routeType: 'Armas', permissions: ['perm.farm'], custom: true, rewards: [
        { name: 'Primeira rota', image: 'first', custom: 'reward', items: [{ item: 'piece', min: 5, max: 9, custom: true }] },
        { name: 'Segunda rota', image: 'second', items: [{ item: 'extra', min: 2, max: 3 }] }] } });
test('opening and reading craft preserves legacy items, multiple farm groups and all unrelated metadata', () => {
    const original = fixture();
    assert.deepEqual(readCraftDraft(original, []), original);
    const draft = craftDraft(original); draft.bench.craftItems[0].amount = 2;
    assert.equal(original.bench.craftItems[0].amount, 1);
    assert.equal(readCraftDraft(draft).bench.craftItems[0].amount, 2);
});
test('recipe edits add required storage materials without removing extras, duplicates or cash configuration', () => {
    const draft = fixture(); draft.bench.armazemItems.push({ spawn: 'piece', custom: 'duplicate' });
    draft.bench.craftItems[0].requires.push({ name: 'metal', amount: '5' }, { name: 'money', amount: 100 });
    draft.bench.craftItems[0].amount = '2'; draft.bench.craftItems[0].time = '0';
    const result = readCraftDraft(draft, [{ index: 'metal', name: 'Metal', image: 'metal-art' }]);
    assert.equal(result.bench.craftItems[0].amount, 2); assert.equal(result.bench.craftItems[0].time, 0);
    assert.equal(result.bench.armazemItems.filter(item => item.spawn === 'piece').length, 2);
    assert.ok(result.bench.armazemItems.some(item => item.spawn === 'extra'));
    assert.deepEqual(result.bench.armazemItems.at(-1), { spawn: 'metal', name: 'Metal', image: 'metal-art' });
    assert.equal(result.bench.armazemItems.some(item => item.spawn === 'money'), false);
});
test('invalid amounts, time, products, points and farm intervals are rejected without silent defaults', () => {
    for (const update of [
        value => value.bench.craftItems[0].amount = '', value => value.bench.craftItems[0].amount = 0,
        value => value.bench.craftItems[0].amount = 1.5, value => value.bench.craftItems[0].time = -1,
        value => value.bench.craftItems[0].spawn = '', value => value.bench.coords[0].x = '',
        value => value.bench.craftItems[0].requires[0].amount = 0,
        value => value.farm.rewards[0].items[0].max = 1
    ]) { const value = fixture(); update(value); assert.throws(() => readCraftDraft(value)); }
});
test('empty Lua collections normalize safely; disabling farm preserves its previous groups', () => {
    const draft = craftDraft({ bench: { name: 'Nova', coords: {}, craftItems: {}, armazemItems: {} }, farm: { enabled: false, permissions: {}, rewards: {} } });
    assert.deepEqual(draft.bench.coords, []); assert.deepEqual(draft.farm.rewards, []);
    const old = fixture(); old.farm.enabled = false;
    assert.deepEqual(readCraftDraft(old).farm.rewards, old.farm.rewards);
});
