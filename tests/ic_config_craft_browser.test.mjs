import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';

test('structured craft editor selects products/materials, preserves farm groups, validates and saves without JSON', { skip: !process.env.IC_CONFIG_PLAYWRIGHT_MODULE }, async () => {
    const { chromium } = await import(pathToFileURL(process.env.IC_CONFIG_PLAYWRIGHT_MODULE).href);
    const root = new URL('../resources/[scriptcore]/ic_config/web/', import.meta.url);
    const server = createServer(async (req, res) => {
        const path = new URL(req.url, 'http://localhost').pathname.slice(1) || 'index.html';
        if (!['index.html', 'style.css', 'mansions.css', 'craft.css', 'forms.css', 'app.mjs', 'model.mjs', 'transport.mjs', 'mansions.mjs', 'craft.mjs', 'forms.mjs', 'form-schema.mjs', 'catalog-picker.mjs'].includes(path)) { res.writeHead(404).end(); return; }
        res.setHeader('Content-Type', path.endsWith('.mjs') ? 'text/javascript' : path.endsWith('.css') ? 'text/css' : 'text/html');
        res.end(await readFile(new URL(path, root)));
    });
    await new Promise(done => server.listen(0, '127.0.0.1', done));
    let browser;
    const requests = [], errors = [];
    let readonly = false, denyItems = false;
    const catalog = [{ index: 'weapon_test', name: 'Pistola de teste', image: 'pistol' },
        { index: 'weapon_new', name: 'Produto <img src=x onerror=steal()>', image: 'new' },
        { index: 'pecadearma', name: 'Peça de arma', image: 'piece' }, { index: 'metal', name: 'Métal', image: 'metal' }, { index: 'extra', name: 'Extra', image: 'extra' }];
    const benches = [{ name: 'Mafia teste', craftPermission: 'perm.craft', armazemPermission: 'perm.store',
        coords: [{ x: -1870, y: 2061, z: 135, heading: 45 }], custom: { keep: true },
        craftItems: [{ spawn: 'weapon_test', name: 'Pistola original', image: 'old', amount: 1, time: 7, custom: 'recipe', requires: [{ name: 'pecadearma', amount: 10, custom: 'required' }] }],
        armazemItems: [{ spawn: 'pecadearma', name: 'Peça antiga', custom: true }, { spawn: 'extra', name: 'Extra', custom: 'extra' }],
        farmRewardType: 'Armas', farmRouteType: 'Armas', farmPermissions: ['perm.farm'] }];
    const farm = { Routes: [{ rewardType: 'Armas', routeType: 'Armas', permissions: ['perm.farm'] }], RouteBlips: { Armas: {}, Outros: {} }, Rewards: { Armas: [
        { name: 'ROTA DE ARMAS', image: 'WEAPON_TEST', custom: 'reward', items: [{ item: 'pecadearma', min: 5, max: 9, custom: true }] },
        { name: 'ROTA EXTRA', image: 'EXTRA', custom: 'second', items: [{ item: 'extra', min: 2, max: 3 }] }] } };
    try {
        browser = await chromium.launch({ headless: true, ...(process.env.IC_CONFIG_BROWSER_EXECUTABLE ? { executablePath: process.env.IC_CONFIG_BROWSER_EXECUTABLE } : {}) });
        const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } }); page.setDefaultTimeout(7000);
        page.on('pageerror', error => errors.push(error.message));
        await page.addInitScript(() => { window.GetParentResourceName = () => 'ic_config'; });
        const headers = { 'access-control-allow-origin': '*', 'access-control-allow-methods': 'POST,OPTIONS', 'access-control-allow-headers': 'Content-Type' };
        await page.route('https://ic_config/**', async route => {
            if (route.request().method() === 'OPTIONS') { await route.fulfill({ status: 204, headers }); return; }
            if (route.request().url().endsWith('/close')) { await route.fulfill({ status: 200, headers, body: '{}' }); return; }
            const request = route.request().postDataJSON(); requests.push(request); let data = {}, error;
            if (request.method === 'bootstrap') data = { writesEnabled: !readonly, methods: [] };
            else if (request.method === 'getManagedGroups') data = [];
            else if (request.method === 'getCraftSetups') data = { benches, farm };
            else if (request.method === 'getItemList') { if (denyItems) error = { code: 'FORBIDDEN', message: 'Catálogo indisponível para esta sessão.' }; else data = catalog; }
            else if (request.method === 'getPlayerPosition') data = { x: 7, y: 8, z: 9 };
            else if (request.method === 'startPositionCapture') data = { started: true };
            else if (request.method === 'saveCraftSetup') { benches[0] = request.payload.bench; farm.Rewards.Armas = request.payload.farm.rewards; data = { message: 'Salvo' }; }
            else error = { code: 'UNSUPPORTED', message: 'Fixture unavailable' };
            await route.fulfill({ status: 200, headers, contentType: 'application/json', body: JSON.stringify({ requestId: request.requestId, ok: !error, data, error }) });
        });
        await page.goto(`http://127.0.0.1:${server.address().port}/`);
        await page.evaluate(() => window.postMessage({ action: 'open' }, '*'));
        await page.locator('#navigation button[data-area="craft"]').click();
        await page.locator('#records .name').getByText('Mafia teste', { exact: true }).waitFor();
        await page.locator('#records').getByRole('button', { name: 'Editar', exact: true }).click();
        await page.getByLabel('Nome da bancada / organização', { exact: true }).waitFor();
        assert.equal(await page.locator('#fields textarea').count(), 0);
        await page.getByLabel('Nome da bancada / organização', { exact: true }).fill('Mafia revisada');
        await page.getByRole('button', { name: 'Usar minha posição atual', exact: true }).click();
        await page.getByRole('group', { name: 'Ponto 2', exact: true }).waitFor();
        await page.getByRole('button', { name: 'Posicionar novo ponto no jogo', exact: true }).click();
        await page.waitForFunction(() => document.querySelector('#save').disabled === false);
        const capture = requests.findLast(value => value.method === 'startPositionCapture');
        await page.evaluate(target => {
            window.postMessage({ action: 'suspend' }, '*');
            window.postMessage({ action: 'captureResult', target, kind: 'position', cancelled: false, data: { x: 10, y: 20, z: 30 } }, '*');
            window.postMessage({ action: 'resume' }, '*');
        }, capture.payload.target);
        await page.getByRole('group', { name: 'Ponto 3', exact: true }).waitFor();
        await page.getByRole('tab', { name: 'Editar receitas', exact: true }).click();
        let recipe = page.getByRole('group', { name: 'Receita 1', exact: true });
        await recipe.getByLabel('Quantidade produzida', { exact: true }).fill('2');
        await recipe.getByLabel('Tempo de produção (s)', { exact: true }).fill('9');
        await recipe.getByRole('button', { name: 'Adicionar materiais', exact: true }).click();
        let picker = page.getByRole('region', { name: 'Selecionar materiais', exact: true });
        await picker.getByRole('searchbox', { name: 'Buscar itens' }).fill('metal');
        await picker.getByRole('searchbox', { name: 'Buscar itens' }).press('Enter');
        assert.equal(requests.filter(value => value.method === 'saveCraftSetup').length, 0, 'search Enter must not submit the outer form');
        await picker.getByRole('checkbox').check();
        await page.locator('#save').click();
        await page.locator('#editor-error').filter({ hasText: 'Conclua ou cancele a seleção' }).waitFor();
        assert.equal(requests.filter(value => value.method === 'saveCraftSetup').length, 0);
        await picker.getByRole('button', { name: 'Adicionar selecionados' }).click();
        await recipe.getByLabel('Quantidade de Métal', { exact: true }).fill('5');
        if (process.env.IC_CONFIG_CRAFT_SCREENSHOT) {
            await page.locator('#edit-form').evaluate(el => { el.scrollTop = 0; });
            await page.screenshot({ path: process.env.IC_CONFIG_CRAFT_SCREENSHOT });
        }
        await page.getByRole('button', { name: 'Nova receita', exact: true }).click();
        recipe = page.getByRole('group', { name: 'Receita 2', exact: true });
        await recipe.getByRole('button', { name: 'Selecionar produto', exact: true }).click();
        picker = page.getByRole('region', { name: 'Selecionar produto', exact: true });
        await picker.getByRole('searchbox', { name: 'Buscar itens' }).fill('weapon_new');
        await picker.locator('.craft-picker-item').click();
        assert.equal(await page.locator('#fields img').count(), 0, 'catalog labels must remain inert text');
        await recipe.getByLabel('Quantidade produzida', { exact: true }).fill('3');
        await recipe.getByLabel('Tempo de produção (s)', { exact: true }).fill('12');
        await recipe.getByRole('button', { name: 'Adicionar materiais', exact: true }).click();
        picker = page.getByRole('region', { name: 'Selecionar materiais', exact: true });
        await picker.getByRole('searchbox', { name: 'Buscar itens' }).fill('metal'); await picker.getByRole('checkbox').check();
        await picker.getByRole('button', { name: 'Adicionar selecionados' }).click();
        await page.getByRole('button', { name: 'Nova receita', exact: true }).click();
        await page.getByRole('group', { name: 'Receita 3', exact: true }).getByRole('button', { name: 'Remover receita' }).click();
        assert.equal(await page.getByRole('group', { name: 'Receita 1', exact: true }).getByLabel('Quantidade produzida', { exact: true }).inputValue(), '2');
        const storage = page.getByRole('group', { name: 'Materiais do armazém', exact: true });
        await storage.locator('.craft-material').filter({ hasText: 'Extra' }).getByRole('button', { name: 'Remover do armazém' }).click();
        assert.equal(await storage.locator('.craft-material').filter({ hasText: 'Métal' }).getByRole('button', { name: 'Remover do armazém' }).isDisabled(), true);
        await page.setViewportSize({ width: 720, height: 900 });
        assert.equal(await page.locator('#editor').evaluate(el => el.scrollWidth > el.clientWidth), false);
        await page.setViewportSize({ width: 1440, height: 1000 });
        await page.getByRole('tab', { name: 'Bancada e farm', exact: true }).click();
        const reward = page.getByRole('group', { name: 'Recompensa 1', exact: true });
        await reward.getByLabel('Mínimo de Peça de arma', { exact: true }).fill('10');
        await reward.getByLabel('Máximo de Peça de arma', { exact: true }).fill('1');
        await page.locator('#save').click(); await page.locator('#editor-error').filter({ hasText: 'O máximo do farm' }).waitFor();
        assert.equal(requests.filter(value => value.method === 'saveCraftSetup').length, 0);
        await reward.getByLabel('Máximo de Peça de arma', { exact: true }).fill('12');
        await page.locator('#save').click(); await page.locator('#editor').waitFor({ state: 'hidden' });
        const saved = requests.find(value => value.method === 'saveCraftSetup').payload;
        assert.equal(saved.originalName, 'Mafia teste'); assert.equal(saved.bench.name, 'Mafia revisada');
        assert.deepEqual(saved.bench.coords[1], { x: 7, y: 8, z: 9 }); assert.deepEqual(saved.bench.coords[2], { x: 10, y: 20, z: 30 });
        assert.equal(saved.bench.coords[0].heading, 45); assert.equal(saved.bench.custom.keep, true);
        assert.equal(saved.bench.craftItems.length, 2); assert.equal(saved.bench.craftItems[0].amount, 2); assert.equal(saved.bench.craftItems[0].time, 9);
        assert.equal(saved.bench.craftItems[0].custom, 'recipe'); assert.equal(saved.bench.craftItems[0].requires[0].custom, 'required');
        assert.equal(saved.bench.craftItems[0].requires.find(item => item.name === 'metal').amount, 5);
        assert.equal(saved.bench.craftItems[1].spawn, 'weapon_new'); assert.equal(saved.bench.craftItems[1].amount, 3);
        assert.equal(saved.bench.armazemItems.length, 2); assert.ok(saved.bench.armazemItems.find(item => item.spawn === 'metal'));
        assert.equal(saved.farm.rewards.length, 2); assert.equal(saved.farm.rewards[0].custom, 'reward'); assert.equal(saved.farm.rewards[0].items[0].custom, true);
        assert.equal(saved.farm.rewards[0].items[0].max, 12); assert.equal(saved.farm.rewards[1].custom, 'second');
        await page.locator('#records .name').getByText('Mafia revisada', { exact: true }).waitFor();
        await page.locator('#records').getByRole('button', { name: 'Editar', exact: true }).click();
        await page.getByLabel('Nome da bancada / organização', { exact: true }).fill('Descartar mudança');
        await page.locator('#cancel-edit').click(); assert.equal(requests.filter(value => value.method === 'saveCraftSetup').length, 1);
        readonly = true;
        await page.evaluate(() => { window.postMessage({ action: 'close' }, '*'); window.postMessage({ action: 'open' }, '*'); });
        await page.locator('#mode-banner').filter({ hasText: 'SOMENTE LEITURA' }).waitFor();
        await page.locator('#records').getByRole('button', { name: 'Ver detalhes', exact: true }).click();
        await page.getByRole('tab', { name: 'Editar receitas', exact: true }).click();
        assert.equal(await page.getByRole('group', { name: 'Receita 1', exact: true }).getByLabel('Quantidade produzida', { exact: true }).isDisabled(), true);
        assert.equal(await page.locator('#save').isDisabled(), true); await page.locator('#cancel-edit').click();
        denyItems = true;
        await page.locator('#records').getByRole('button', { name: 'Ver detalhes', exact: true }).click();
        await page.locator('#editor-error').filter({ hasText: 'Catálogo indisponível' }).waitFor();
        assert.equal(await page.locator('#save').isDisabled(), true);
        assert.equal(requests.filter(value => value.method === 'saveCraftSetup').length, 1);
        assert.deepEqual(errors, []);
    } finally { await browser?.close(); await new Promise(done => server.close(done)); }
});
