import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { VIEWS } from '../resources/[scriptcore]/ic_config/web/model.mjs';
import { FORM_SCHEMAS, schemaFor } from '../resources/[scriptcore]/ic_config/web/form-schema.mjs';
import { getPath, setPath, numericField, inferField, makeCatalogs } from '../resources/[scriptcore]/ic_config/web/forms.mjs';
import { searchKey } from '../resources/[scriptcore]/ic_config/web/catalog-picker.mjs';

test('every screen and additional action has an explicit structured editor contract', () => {
    assert.equal(VIEWS.length, 31);
    for (const view of VIEWS) {
        if (!['craft', 'mansions'].includes(view.id)) assert.ok(schemaFor(view.id)?.length, view.id);
        if (view.extraAction) assert.ok(schemaFor(view.id, true)?.length, `action ${view.id}`);
    }
    assert.ok(FORM_SCHEMAS.garages.some(field => field.key === 'spawnCoords' && field.type === 'list'));
    assert.ok(FORM_SCHEMAS.shops.find(field => field.key === 'data').fields.some(field => field.key === 'items' && field.type === 'map'));
});
test('form path updates cannot pollute prototypes and support empty Lua tables for outfits', () => {
    const original = { job: { uniforme: [] }, nested: { value: 'kept' } };
    setPath(original, ['job', 'uniforme', 'masculino'], { '3': [1, 2, 3] });
    assert.deepEqual(original.job.uniforme, { masculino: { '3': [1, 2, 3] } });
    assert.equal(getPath(original, ['nested', 'value']), 'kept');
    for (const path of [['__proto__', 'polluted'], ['constructor', 'prototype', 'polluted'], ['nested', 'webhook'], ['x', -1]]) assert.throws(() => setPath(original, path, true));
    assert.equal({}.polluted, undefined);
});
test('numeric fields preserve optional salary while rejecting malformed, infinite and out-of-range values', () => {
    assert.equal(numericField('', { label: 'Salário', empty: '' }), '');
    assert.equal(numericField('123', { label: 'Valor', min: 0 }), 123);
    for (const value of ['', 'Infinity', '-1', '1.5']) assert.throws(() => numericField(value, { label: 'Quantidade', min: 0, integer: true }));
});
test('advanced options remain typed controls and catalogs retain legacy selection identities', () => {
    const route = inferField('rotas', [[1, 2, 3]]);
    assert.equal(route.type, 'list'); assert.equal(route.entry.type, 'coords');
    const prices = inferField('valores_venda', { fish: [[1, 2], [3, 4]] });
    assert.equal(prices.type, 'map'); assert.equal(prices.keyCatalog, 'items');
    assert.equal(searchKey('MUNIÇÃO'), searchKey('municao'));
    const catalogs = makeCatalogs({ id: 'houses' }, { interiors: { Test: { type: 'Casa' } } }, { getItemList: [{ index: 'piece', name: 'Peça' }] });
    assert.equal(catalogs.items[0].value, 'piece'); assert.equal(catalogs.interiors[0].type, 'Casa');
});
test('the generic textarea/JSON editor is removed from the panel', async () => {
    const app = await readFile(new URL('../resources/[scriptcore]/ic_config/web/app.mjs', import.meta.url), 'utf8');
    const forms = await readFile(new URL('../resources/[scriptcore]/ic_config/web/forms.mjs', import.meta.url), 'utf8');
    assert.ok(!app.includes('function renderFields('));
    assert.ok(!app.includes('JSON.parse(input.node.value)'));
    assert.ok(!/createElement\(['"]textarea|element\(['"]textarea/.test(forms));
    assert.ok(!/innerHTML|insertAdjacentHTML|eval\(/.test(forms));
});
