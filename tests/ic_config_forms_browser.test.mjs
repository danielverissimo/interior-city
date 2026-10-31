import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile, mkdir } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
import { formFixtures } from './ic_config_form_fixtures.mjs';
import { VIEWS, recordsFor, editorValue, mutationFor } from '../resources/[scriptcore]/ic_config/web/model.mjs';

test('all standard configuration screens use forms and preserve existing configuration on save', { skip: !process.env.IC_CONFIG_PLAYWRIGHT_MODULE }, async () => {
    const fixtures = await formFixtures();
    const { chromium } = await import(pathToFileURL(process.env.IC_CONFIG_PLAYWRIGHT_MODULE).href);
    const web = new URL('../resources/[scriptcore]/ic_config/web/', import.meta.url);
    const allowed = new Set(['index.html', 'style.css', 'mansions.css', 'craft.css', 'forms.css', 'app.mjs', 'model.mjs', 'mansions.mjs', 'craft.mjs', 'forms.mjs', 'form-schema.mjs', 'catalog-picker.mjs', 'transport.mjs']);
    const server = createServer(async (req, res) => {
        const name = new URL(req.url, 'http://localhost').pathname.slice(1) || 'index.html';
        if (!allowed.has(name)) { res.writeHead(404).end(); return; }
        res.setHeader('Content-Type', name.endsWith('.mjs') ? 'text/javascript' : name.endsWith('.css') ? 'text/css' : 'text/html');
        res.end(await readFile(new URL(name, web)));
    });
    await new Promise(done => server.listen(0, '127.0.0.1', done));
    let browser;
    const errors = [], requests = [], verified = [];
    let readOnly = false, denyItems = false, holdItems, releaseItems, itemArrived;
    fixtures.getPlayerPosition = { x: 7, y: 8, z: 9, w: 90 };
    fixtures.getCurrentOutfit = { gender: 'feminino', outfit: { '3': [4, 5, 6] } };
    try {
        browser = await chromium.launch({ headless: true, ...(process.env.IC_CONFIG_BROWSER_EXECUTABLE ? { executablePath: process.env.IC_CONFIG_BROWSER_EXECUTABLE } : {}) });
        const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } }); page.setDefaultTimeout(10000);
        page.on('pageerror', error => errors.push(error.message));
        await page.addInitScript(() => { window.GetParentResourceName = () => 'ic_config'; });
        const headers = { 'access-control-allow-origin': '*', 'access-control-allow-methods': 'POST,OPTIONS', 'access-control-allow-headers': 'Content-Type' };
        await page.route('https://ic_config/**', async route => {
            if (route.request().method() === 'OPTIONS') { await route.fulfill({ status: 204, headers }); return; }
            if (route.request().url().endsWith('/close')) { await route.fulfill({ status: 200, headers, body: '{}' }); return; }
            const request = route.request().postDataJSON(); requests.push(request);
            if (request.method === 'getItemList' && holdItems) { itemArrived?.(); await holdItems; }
            const data = request.method === 'bootstrap' ? { writesEnabled: !readOnly, methods: [] } : fixtures[request.method] || {};
            const error = request.method === 'getItemList' && denyItems ? { code: 'FORBIDDEN', message: 'Catálogo indisponível.' } : null;
            await route.fulfill({ status: 200, headers, contentType: 'application/json', body: JSON.stringify({ requestId: request.requestId, ok: !error, data, error }) });
        });
        await page.goto(`http://127.0.0.1:${server.address().port}/`);
        await page.evaluate(() => window.postMessage({ action: 'open' }, '*'));
        for (const view of VIEWS) {
            if (['craft', 'mansions'].includes(view.id)) continue; // Dedicated suites cover both custom editors.
            await page.locator(`#navigation [data-area="${view.area}"]`).click();
            await page.getByRole('tab', { name: view.title, exact: true }).click();
            await page.waitForFunction(() => document.querySelector('#refresh').disabled === false);
            const source = fixtures[view.read], row = recordsFor(view, source)[0];
            if (!row) { // Organization creation uses selectors and a preview-tested separate workflow.
                await page.locator('#create').click();
                await page.getByLabel('Organização', { exact: true }).waitFor();
                assert.equal(await page.locator('#fields select, #fields input[list], #fields .form-choice button').count() > 0, true, `${view.id}: expected selector`);
                assert.equal(await page.locator('#fields textarea').count(), 0);
                await page.locator('#cancel-edit').click(); verified.push(view.id); continue;
            }
            await page.locator('#records .record').first().getByRole('button', { name: 'Editar', exact: true }).click();
            await page.waitForFunction(() => document.querySelector('#fields .structured-form') && document.querySelector('#save').disabled === false);
            assert.equal(await page.locator('#fields textarea').count(), 0, `${view.id}: textarea editor`);
            assert.equal(await page.locator('#fields').evaluate(el => /\bJSON\b/i.test(el.textContent)), false, `${view.id}: raw data instructions`);
            assert.equal(await page.locator('#editor').evaluate(el => el.scrollWidth > el.clientWidth), false, `${view.id}: horizontal overflow`);
            const expected = mutationFor(view, editorValue(view, row, source), row);
            const before = requests.length; await page.locator('#save').click();
            try { await page.locator('#editor').waitFor({ state: 'hidden' }); }
            catch { throw new Error(`${view.id}: form did not save (${await page.locator('#editor-error').textContent()})`); }
            const saved = requests.slice(before).find(request => request.method === expected.method);
            assert.ok(saved, `${view.id}: expected save contract ${expected.method}`);
            try { assert.deepEqual(saved.payload, expected.payload); }
            catch { throw new Error(`${view.id}: saving an unchanged form altered public configuration (values suppressed)`); }
            verified.push(view.id); console.log(`verified form: ${view.id}`);
        }
        assert.equal(verified.length, 29); assert.deepEqual(errors, []);

        const open = async (id, create = false, index = 0) => {
            const view = VIEWS.find(view => view.id === id);
            await page.locator(`#navigation [data-area="${view.area}"]`).click();
            await page.getByRole('tab', { name: view.title, exact: true }).click();
            await page.waitForFunction(() => document.querySelector('#refresh').disabled === false);
            if (create) await page.locator('#create').click();
            else await page.locator('#records .record').nth(index).getByRole('button', { name: readOnly ? 'Ver detalhes' : 'Editar', exact: true }).click();
            await page.locator('#fields .structured-form').waitFor();
        };
        const save = async method => {
            const before = requests.length; await page.locator('#save').click();
            await page.locator('#editor').waitFor({ state: 'hidden' });
            const saved = requests.slice(before).find(request => request.method === method); assert.ok(saved, method); return saved.payload;
        };
        // All eight jobs have different advanced options; exercise every saved shape.
        for (let index = 1; index < Object.keys(fixtures.getJobs.jobs).length; index++) {
            await open('jobs', false, index);
            const view = VIEWS.find(view => view.id === 'jobs'), row = recordsFor(view, fixtures.getJobs)[index];
            assert.deepEqual(await save('updateJob'), mutationFor(view, editorValue(view, row, fixtures.getJobs), row).payload, `job variant ${index}`);
        }
        await open('groups', true);
        await page.getByLabel('Nome do cargo', { exact: true }).fill('Guarda São João');
        await page.getByLabel('Salário', { exact: true }).fill('');
        await page.getByLabel('PTR', { exact: true }).selectOption({ label: 'Desativado' });
        let payload = await save('saveManagedGroup');
        assert.deepEqual(payload.group.permissions, ['perm.guardasaojoao']); assert.equal(payload.group.config.ptr, false); assert.equal(payload.group.config.salario, '');

        await open('shops');
        const baselineShop = structuredClone(fixtures.getShops[0]);
        await page.getByRole('button', { name: 'Adicionar item à loja', exact: true }).click();
        let picker = page.getByRole('region', { name: 'Item', exact: true });
        await picker.getByRole('searchbox').fill('metal'); await picker.getByRole('searchbox').press('Enter');
        if (process.env.IC_CONFIG_FORMS_SCREENSHOTS) {
            await mkdir(process.env.IC_CONFIG_FORMS_SCREENSHOTS, { recursive: true });
            await picker.scrollIntoViewIfNeeded(); await page.screenshot({ path: `${process.env.IC_CONFIG_FORMS_SCREENSHOTS}/seletor-itens.png` });
        }
        await picker.getByRole('checkbox').check();
        await page.locator('#save').click(); await page.locator('#editor-error').filter({ hasText: 'Conclua ou cancele a seleção' }).waitFor();
        await picker.getByRole('button', { name: 'Adicionar selecionados', exact: true }).click();
        await page.getByRole('group', { name: 'metal', exact: true }).getByLabel('Preço', { exact: true }).fill('17');
        await page.getByRole('button', { name: 'Adicionar ponto da loja', exact: true }).click();
        await page.getByRole('group', { name: 'Posição', exact: true }).last().getByRole('button', { name: 'Usar minha posição no jogo', exact: true }).click();
        await page.getByRole('group', { name: 'Posição', exact: true }).last().getByLabel('X', { exact: true }).filter({ visible: true }).waitFor();
        await page.waitForFunction(() => [...document.querySelectorAll('#fields input[type=number]')].some(input => input.value === '7'));
        payload = await save('updateShop');
        assert.equal(payload.data.items.metal, 17); assert.deepEqual(payload.data.coords.at(-1).coords, { x: 7, y: 8, z: 9 });
        for (const [key, amount] of Object.entries(baselineShop.data.items)) if (key !== 'metal') assert.equal(payload.data.items[key], amount);
        assert.deepEqual(fixtures.getShops[0], baselineShop, 'editing must not mutate source data');

        await open('cloakroom');
        await page.getByRole('button', { name: 'Capturar roupa atual', exact: true }).click();
        await page.getByText('Feminino: capturado', { exact: true }).waitFor();
        payload = await save('saveCloakroom');
        assert.deepEqual(payload.room.uniforms[0].feminino, fixtures.getCurrentOutfit.outfit);
        assert.deepEqual(payload.room.uniforms[0].masculino, fixtures.getCloakrooms[0].uniforms[0].masculino);
        assert.equal(payload.room.uniforms[0].custom, 'retained');

        await open('jobs');
        await page.getByLabel('Tempo de entrega', { exact: true }).fill('55');
        await page.getByLabel('Total de níveis', { exact: true }).fill('2'); await page.getByLabel('Total de níveis', { exact: true }).press('Tab');
        await page.getByRole('group', { name: 'Nível 1', exact: true }).getByLabel('XP para o próximo nível', { exact: true }).fill('20');
        for (const level of [1, 2]) {
            const group = page.getByRole('group', { name: `Nível ${level}`, exact: true });
            await group.getByLabel('Pagamento mínimo', { exact: true }).fill('10'); await group.getByLabel('Pagamento máximo', { exact: true }).fill('30');
        }
        payload = await save('updateJob');
        assert.equal(payload.job.total_nivel, 2); assert.deepEqual(payload.job.xp_for_level, [20]); assert.deepEqual(payload.job.payment_for_level, [[10, 30], [10, 30]]);
        assert.equal(payload.extra.tempo_entrega, 55, 'rebuilding lists must preserve numeric types in advanced fields');

        await open('garageTypes', true);
        await page.getByLabel('Nome do tipo', { exact: true }).fill('Serviço teste');
        await page.getByLabel('Modo da garagem', { exact: true }).selectOption({ label: 'service' });
        await page.getByRole('group', { name: 'Veículos de serviço', exact: true }).getByRole('button', { name: 'Adicionar registro', exact: true }).click();
        await page.getByRole('button', { name: 'Selecionar veículo de serviço', exact: true }).click();
        await page.getByRole('region', { name: 'Veículo de serviço', exact: true }).getByRole('button', { name: /Carro de teste/ }).click();
        await page.getByLabel('Pintura / livery', { exact: true }).fill('2');
        payload = await save('createGarageType'); assert.deepEqual(payload.data.vehicles, [{ vehicle: 'testcar', livery: 2 }]);

        await open('centralBank');
        const welding = page.getByRole('checkbox', { name: 'Configurar posição de solda', exact: true });
        assert.equal(await welding.count(), 3); assert.equal(await welding.nth(2).isChecked(), false);
        await welding.nth(2).check(); assert.equal(await page.getByRole('group', { name: 'Local de solda', exact: true }).count(), 3);
        await welding.nth(2).uncheck();
        payload = await save('saveBancoCentral'); assert.equal(Object.hasOwn(payload.banks[0].doors[2], 'weldPosition'), false);

        await open('dealershipSettings');
        let collection = page.getByRole('group', { name: 'Descontos e vagas VIP', exact: true });
        await collection.getByRole('button', { name: 'Adicionar registro', exact: true }).click();
        await collection.getByLabel('Permissão VIP', { exact: true }).last().fill('perm.vipteste');
        await collection.getByLabel('Desconto (%)', { exact: true }).last().fill('15');
        await collection.getByLabel('Vagas extras', { exact: true }).last().fill('7');
        payload = await save('saveDealershipSettings'); assert.deepEqual(payload.vips.at(-1), { permission: 'perm.vipteste', discount: 15, maxCars: 7 });
        assert.deepEqual(payload.vips.slice(0, -1), fixtures.getDealership.vips);

        await open('robberySetups'); collection = page.getByRole('group', { name: 'Recompensas do roubo', exact: true });
        await collection.getByRole('button', { name: 'Adicionar item', exact: true }).click();
        picker = page.getByRole('region', { name: 'Item', exact: true });
        await picker.getByRole('searchbox').fill('metal'); await picker.getByRole('checkbox').check();
        await picker.getByRole('button', { name: 'Adicionar selecionados', exact: true }).click();
        const reward = collection.getByRole('group', { name: 'metal', exact: true });
        await reward.getByLabel('Mínimo', { exact: true }).fill('5'); await reward.getByLabel('Máximo', { exact: true }).fill('3');
        const beforeInvalid = requests.filter(request => request.method === 'saveRobberySetup').length;
        await page.locator('#save').click(); await page.locator('#editor-error').filter({ hasText: 'O máximo deve ser maior ou igual ao mínimo' }).waitFor();
        assert.equal(requests.filter(request => request.method === 'saveRobberySetup').length, beforeInvalid);
        await reward.getByLabel('Máximo', { exact: true }).fill('9'); payload = await save('saveRobberySetup');
        assert.deepEqual(payload.data.items.metal, { min: 5, max: 9 });

        // Cancellation discards drafts, including in-flight catalogue failures.
        await open('shops'); const count = requests.filter(request => request.method === 'updateShop').length;
        await page.getByLabel('Nome da loja', { exact: true }).fill('Não salvar'); await page.locator('#cancel-edit').click();
        assert.equal(requests.filter(request => request.method === 'updateShop').length, count);
        holdItems = new Promise(resolve => { releaseItems = resolve; });
        const arrived = new Promise(resolve => { itemArrived = resolve; });
        await page.locator('#records .record').first().getByRole('button', { name: 'Editar', exact: true }).click(); await arrived;
        await page.locator('#cancel-edit').click(); denyItems = true;
        const releasedResponse = page.waitForResponse(response => response.url().endsWith('/request')); releaseItems(); await releasedResponse;
        await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
        assert.equal(await page.locator('#editor').evaluate(el => el.open), false, 'late catalogue failure cannot reopen cancelled form');
        holdItems = null;
        await open('shops'); assert.equal(await page.locator('#save').isDisabled(), true); assert.equal(await page.locator('#fields input:enabled, #fields select:enabled').count(), 0);
        await page.locator('#cancel-edit').click(); denyItems = false;
        readOnly = true; await page.reload(); await page.evaluate(() => window.postMessage({ action: 'open' }, '*')); await open('shops');
        assert.equal(await page.locator('#save').isDisabled(), true); assert.equal(await page.locator('#fields input:enabled, #fields select:enabled, #fields button:enabled').count(), 0);
        if (process.env.IC_CONFIG_FORMS_SCREENSHOTS) {
            await mkdir(process.env.IC_CONFIG_FORMS_SCREENSHOTS, { recursive: true });
            await page.screenshot({ path: `${process.env.IC_CONFIG_FORMS_SCREENSHOTS}/loja-formulario.png` });
            await page.setViewportSize({ width: 720, height: 900 });
            assert.equal(await page.locator('#editor').evaluate(el => el.scrollWidth > el.clientWidth), false);
            await page.screenshot({ path: `${process.env.IC_CONFIG_FORMS_SCREENSHOTS}/loja-formulario-720.png` });
        }
        assert.deepEqual(errors, []);
    } finally { await browser?.close(); await new Promise(done => server.close(done)); }
});
