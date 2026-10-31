// Optional browser integration using an already installed Playwright module.
// No packages or browsers are downloaded by this test.
import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';

test('live NUI creates records, captures positions/polygons, keeps drafts and respects read-only bootstrap', { skip: !process.env.IC_CONFIG_PLAYWRIGHT_MODULE }, async () => {
    const { chromium } = await import(pathToFileURL(process.env.IC_CONFIG_PLAYWRIGHT_MODULE).href);
    const root = new URL('../resources/[scriptcore]/ic_config/web/', import.meta.url);
    const server = createServer(async (req, res) => {
        const path = req.url.split('?')[0] === '/' ? 'index.html' : req.url.split('?')[0].slice(1);
        if (!['index.html', 'style.css', 'mansions.css', 'craft.css', 'forms.css', 'app.mjs', 'model.mjs', 'transport.mjs', 'mansions.mjs', 'craft.mjs', 'forms.mjs', 'form-schema.mjs', 'catalog-picker.mjs'].includes(path)) { res.writeHead(404).end(); return; }
        res.setHeader('Content-Type', path.endsWith('.mjs') ? 'text/javascript' : path.endsWith('.css') ? 'text/css' : 'text/html');
        res.end(await readFile(new URL(path, root)));
    });
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
    let browser;
    try {
        browser = await chromium.launch({ headless: true, ...(process.env.IC_CONFIG_BROWSER_EXECUTABLE ? { executablePath: process.env.IC_CONFIG_BROWSER_EXECUTABLE } : {}) });
        const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
        page.setDefaultTimeout(7000);
        async function clickRpc(locator, method) { const response = page.waitForResponse(response => response.url() === 'https://ic_config/request' && response.request().postDataJSON()?.method === method); await locator.click(); await response; }
        const errors = [], requests = [], chests = [], mansions = []; let readonly = false, previewSequence = 0, conflictOnce = true, denyMansions = false, denyTeleport = true;
        page.on('pageerror', error => errors.push(error.message));
        await page.addInitScript(() => { window.GetParentResourceName = () => 'ic_config'; });
        const headers = { 'access-control-allow-origin': '*', 'access-control-allow-methods': 'POST,OPTIONS', 'access-control-allow-headers': 'Content-Type' };
        await page.route('https://ic_config/**', async route => {
            if (route.request().method() === 'OPTIONS') { await route.fulfill({ status: 204, headers }); return; }
            if (route.request().url().endsWith('/close')) { await route.fulfill({ status: 200, headers, body: '{}' }); return; }
            const request = route.request().postDataJSON(); requests.push(request);
            let data = {}, error = null;
            if (request.method === 'bootstrap') data = { writesEnabled: !readonly, methods: [] };
            else if (request.method === 'teleport') {
                if (denyTeleport) error = { code: 'FORBIDDEN', message: 'Permissão de teleporte revogada.' };
                else data = { coords: request.payload.coords };
            }
            else if (request.method === 'getCraftSetups') data = { benches: [{ name: 'Bancada de teste', coords: [{ x: 10, y: 20, z: 30 }, { x: 90, y: 80, z: 70 }] }, { name: 'Bancada sem ponto', coords: [] }], farm: {} };
            else if (request.method === 'getManagedGroups') data = [{ name: 'Developer', config: { gtype: 'staff' }, permissions: ['perm.test'] }];
            else if (request.method === 'getChests') data = chests;
            else if (request.method === 'getSafeZones') data = { safezones: [], settings: {}, whitelist: [] };
            else if (request.method === 'getGarageTypes') data = [{ name: 'Public', data: { type: 'public' } }];
            else if (request.method === 'getMansions') { if (denyMansions) error = { code: 'FORBIDDEN', message: 'Acesso revogado.' }; else data = { mansions }; }
            else if (request.method === 'getPlayerPosition') data = { x: 123.5, y: -456.25, z: 30.5, w: 90, heading: 90 };
            else if (['startPositionCapture', 'startSafeZonePolygon', 'startMansionDoorCapture'].includes(request.method)) data = { started: true };
            else if (request.method === 'createChest') { chests.push(request.payload); data = { message: 'saved' }; }
            else if (request.method === 'createSafeZone') data = { message: 'saved' };
            else if (request.method === 'saveMansion') {
                const index = mansions.findIndex(row => row.id === request.payload.originalId);
                const saved = { ...(index >= 0 ? mansions[index] : {}), ...request.payload.data, id: request.payload.originalId || 'new-mansion', ownerId: 7, residents: [{ id: 7 }], occupiedCount: 1 };
                if (index >= 0) mansions[index] = saved; else mansions.push(saved); data = { message: 'mansion saved' };
            }
            else if (request.method === 'deleteMansion') { const index = mansions.findIndex(row => row.id === request.payload.id); if (index >= 0) mansions.splice(index, 1); data = { message: 'mansion deleted' }; }
            else if (request.method === 'previewFacDeletion') data = { previewId: `preview-${++previewSequence}`, orgName: request.payload.orgName, confirmation: `EXCLUIR ${request.payload.orgName}`, expiresAt: Math.floor(Date.now() / 1000) + 120, groups: ['Lider-TestOrg', 'Gerente-TestOrg'], counts: { groups: 2, onlineUsers: 1, offlineUsers: 3, tables: { mirtin_organizations: 1 } }, warnings: ['Os vínculos serão removidos.'] };
            else if (request.method === 'deleteFacBundle') {
                if (conflictOnce) { conflictOnce = false; error = { code: 'CONFLICT', message: 'O estado mudou; solicite nova prévia.' }; }
                else if (request.payload.confirmation !== `EXCLUIR ${request.payload.orgName}`) error = { code: 'INVALID_CONFIRMATION', message: 'Frase incorreta.' };
                else data = { state: 'complete', operationId: 'fixture-operation', message: 'organization deleted' };
            }
            else if (request.method === 'getFacDeletionStatus') data = { operationId: 'fixture-pending-operation', orgName: request.payload.orgName, state: 'prepared', counts: { groups: 2, onlineUsers: 0, offlineUsers: 3 }, canResume: true };
            else if (request.method === 'resumeFacDeletion') data = { state: 'complete', operationId: request.payload.operationId, message: 'Deletion resumed' };
            else error = { code: 'UNSUPPORTED', message: 'Fixture method unavailable' };
            await route.fulfill({ status: 200, headers, contentType: 'application/json', body: JSON.stringify({ requestId: request.requestId, ok: !error, data, error }) });
        });
        await page.goto(`http://127.0.0.1:${server.address().port}/`);
        assert.equal(await page.locator('#panel').isVisible(), false);
        await page.evaluate(() => window.postMessage({ action: 'open' }, '*'));
        await page.getByText('Developer', { exact: true }).first().waitFor();
        await page.locator('#navigation button[data-area="chests"]').click();
        await page.locator('#create').click();
        await page.getByLabel('Nome', { exact: true }).fill('Test chest');
        await page.getByLabel('Capacidade (kg)', { exact: true }).fill('150');
        await page.getByLabel('Permissão', { exact: true }).fill('perm.test');
        await page.getByRole('button', { name: 'Usar minha posição no jogo', exact: true }).click();
        await page.getByRole('button', { name: 'Salvar alterações', exact: true }).click();
        await page.getByText('Test chest', { exact: true }).first().waitFor();
        const created = requests.find(request => request.method === 'createChest');
        assert.deepEqual(created.payload.coords, { x: 123.5, y: -456.25, z: 30.5 });
        assert.equal(created.payload.weight, 150);
        await page.locator('#create').click();
        await page.getByLabel('Nome', { exact: true }).fill('Captured chest');
        await clickRpc(page.getByRole('button', { name: 'Posicionar no jogo', exact: true }), 'startPositionCapture');
        const position = requests.findLast(request => request.method === 'startPositionCapture');
        await page.evaluate(target => {
            window.postMessage({ action: 'suspend' }, '*');
            window.postMessage({ action: 'captureResult', kind: 'position', target, cancelled: false, data: { x: 7, y: 8, z: 9, w: 10, h: 10, heading: 10 } }, '*');
            window.postMessage({ action: 'resume' }, '*');
        }, position.payload.target);
        await page.waitForFunction(() => document.querySelector('#editor').open && [...document.querySelectorAll('#fields input')].some(node => node.value === '7'));
        assert.equal(await page.getByLabel('X', { exact: true }).inputValue(), '7');
        assert.equal(await page.getByLabel('Nome', { exact: true }).inputValue(), 'Captured chest');
        await page.locator('#cancel-edit').click();
        await page.locator('#navigation button[data-area="safezone"]').click();
        await page.locator('#create').click();
        await page.getByLabel('Nome da zona segura', { exact: true }).fill('Captured zone');
        await clickRpc(page.getByRole('button', { name: 'Desenhar polígono no jogo' }), 'startSafeZonePolygon');
        const polygon = requests.findLast(request => request.method === 'startSafeZonePolygon');
        await page.evaluate(target => {
            window.postMessage({ action: 'suspend' }, '*');
            window.postMessage({ action: 'captureResult', kind: 'polygon', target, cancelled: false, data: { coords: [{ x: 1, y: 2 }, { x: 3, y: 4 }, { x: 5, y: 2 }], minZ: 20, maxZ: 24 } }, '*');
            window.postMessage({ action: 'resume' }, '*');
        }, polygon.payload.target);
        await page.getByRole('group', { name: 'Vértice 3', exact: true }).waitFor();
        assert.equal(await page.getByLabel('Altura mínima (minZ)', { exact: true }).inputValue(), '20');
        assert.equal(await page.locator('#fields textarea').count(), 0);
        await page.getByRole('button', { name: 'Salvar alterações', exact: true }).click();
        await page.locator('#editor').waitFor({ state: 'hidden' });
        assert.equal(requests.find(request => request.method === 'createSafeZone').payload.zones.length, 1);

        // Full mansion form uses configuration fields only; ownership is immutable.
        await page.locator('#navigation button[data-area="mansions"]').click();
        await page.locator('#create').click();
        await page.getByLabel('Nome da mansão', { exact: true }).fill('Test Mansion');
        await page.getByLabel('Cargo da mansão', { exact: true }).fill('MansaoTest');
        await page.getByLabel('Valor da mansão', { exact: true }).fill('1000000');
        await page.getByLabel('Valor do IPTU', { exact: true }).fill('10000');
        await page.getByLabel('Vale necessário para comprar', { exact: true }).selectOption('valemansao1m');
        await page.getByLabel('Máximo de moradores', { exact: true }).fill('4');
        const purchase = page.getByRole('group', { name: 'Local de compra', exact: true });
        for (const [axis, value] of [['X', '1'], ['Y', '2'], ['Z', '3']]) await purchase.getByLabel(axis, { exact: true }).fill(value);
        assert.equal(await page.getByLabel('Permissão prevista').inputValue(), 'perm.mansaotest');
        assert.equal(await page.getByLabel('Capacidade do baú (kg)').isDisabled(), true);
        await page.getByLabel('Ativar garagem da mansão').check();
        await page.getByLabel('Tipo da garagem', { exact: true }).selectOption('Public');
        const garage = page.getByRole('group', { name: 'Local da garagem', exact: true });
        for (const [axis, value] of [['X', '4'], ['Y', '5'], ['Z', '6']]) await garage.getByLabel(axis, { exact: true }).fill(value);
        await clickRpc(page.getByRole('button', { name: 'Capturar nova vaga no jogo', exact: true }), 'startPositionCapture');
        const spawnCapture = requests.findLast(request => request.method === 'startPositionCapture');
        await page.evaluate(target => {
            window.postMessage({ action: 'suspend' }, '*'); window.postMessage({ action: 'captureResult', kind: 'position', target, cancelled: false, data: { x: 10, y: 11, z: 12, w: 90, heading: 90 } }, '*'); window.postMessage({ action: 'resume' }, '*');
        }, spawnCapture.payload.target);
        await page.getByText('Vaga 1', { exact: true }).waitFor();
        await clickRpc(page.getByRole('button', { name: 'Capturar trancas no jogo', exact: true }), 'startMansionDoorCapture');
        const doorCapture = requests.findLast(request => request.method === 'startMansionDoorCapture');
        await page.evaluate(target => {
            window.postMessage({ action: 'suspend' }, '*'); window.postMessage({ action: 'captureResult', kind: 'doors', target, cancelled: false, data: { doors: [{ hash: 12345, x: 1, y: 2, z: 3, dist: 5, isGate: false, text: true }] } }, '*'); window.postMessage({ action: 'resume' }, '*');
        }, doorCapture.payload.target);
        await page.getByLabel('Modelo da porta (hash)').waitFor();
        await page.getByRole('button', { name: 'Salvar alterações', exact: true }).click();
        await page.getByText('Test Mansion', { exact: true }).first().waitFor();
        const mansionCreate = requests.find(request => request.method === 'saveMansion');
        assert.equal(mansionCreate.payload.originalId, ''); assert.equal(mansionCreate.payload.data.garage.spawnCoords[0].w, 90); assert.equal(mansionCreate.payload.data.doors[0].hash, 12345);
        assert.equal(mansionCreate.payload.data.chest.enabled, false); assert.equal(mansionCreate.payload.data.ownerId, undefined);
        await page.locator('#records').getByRole('button', { name: 'Editar', exact: true }).click();
        await page.getByText(/Proprietário: ID 7/).waitFor();
        assert.equal(await page.locator('#fields textarea').count(), 0);
        await page.getByLabel('Valor da mansão', { exact: true }).fill('2000000');
        await page.getByRole('button', { name: 'Salvar alterações', exact: true }).click();
        await page.locator('#editor').waitFor({ state: 'hidden' });
        const mansionEdit = requests.findLast(request => request.method === 'saveMansion');
        assert.equal(mansionEdit.payload.originalId, 'new-mansion'); assert.equal(mansionEdit.payload.data.price, 2000000);
        assert.equal(mansionEdit.payload.data.ownerId, undefined); assert.equal(mansionEdit.payload.data.residents, undefined);
        await page.locator('#records').getByRole('button', { name: 'Excluir', exact: true }).click();
        await page.locator('#confirm-delete').click(); await page.locator('#confirmation').waitFor({ state: 'hidden' });
        assert.equal(requests.find(request => request.method === 'deleteMansion').payload.id, 'new-mansion');
        denyMansions = true; await page.locator('#refresh').click(); await page.locator('#error').filter({ hasText: 'Acesso revogado.' }).waitFor();
        assert.equal(await page.locator('#create').isDisabled(), true);

        // Organization deletion shows a server-calculated preview and requires
        // the exact phrase. Stale previews cannot be retried automatically.
        await page.locator('#navigation button[data-area="groups"]').click();
        await page.getByRole('tab', { name: 'Criar organização', exact: true }).click();
        await page.locator('#additional').click();
        await page.getByLabel('Organização', { exact: true }).fill('TestOrg');
        await page.getByRole('button', { name: 'Visualizar impacto', exact: true }).click();
        await page.getByText('Lider-TestOrg', { exact: true }).waitFor();
        assert.equal(await page.locator('#confirm-delete').isDisabled(), true);
        await page.getByLabel('Digite a frase de confirmação').fill('TestOrg'); assert.equal(await page.locator('#confirm-delete').isDisabled(), true);
        await page.getByLabel('Digite a frase de confirmação').fill('EXCLUIR TestOrg');
        await page.locator('#confirm-delete').click(); await page.locator('#confirmation-error').filter({ hasText: 'O estado mudou; solicite nova prévia.' }).waitFor();
        assert.equal(await page.locator('#confirm-delete').isDisabled(), true);
        assert.equal(requests.filter(request => request.method === 'deleteFacBundle').length, 1);
        await page.locator('#cancel-delete').click();
        await page.getByRole('button', { name: 'Visualizar impacto', exact: true }).click();
        await page.getByLabel('Digite a frase de confirmação').fill('EXCLUIR TestOrg');
        await page.locator('#confirm-delete').click(); await page.locator('#confirmation').waitFor({ state: 'hidden' });
        const orgDeletion = requests.filter(request => request.method === 'deleteFacBundle');
        assert.equal(orgDeletion.length, 2); assert.notEqual(orgDeletion[0].payload.previewId, orgDeletion[1].payload.previewId);
        assert.equal(orgDeletion[1].payload.confirmation, 'EXCLUIR TestOrg');
        await page.locator('#additional').click(); await page.getByLabel('Organização', { exact: true }).fill('PendingOrg');
        await page.getByRole('button', { name: 'Consultar exclusão pendente', exact: true }).click();
        await page.getByRole('heading', { name: 'Retomar exclusão pendente', exact: true }).waitFor();
        assert.equal(await page.locator('#confirm-delete').isDisabled(), true);
        await page.getByLabel('Digite a frase de confirmação').fill('RETOMAR PendingOrg'); await page.getByRole('button', { name: 'Retomar exclusão', exact: true }).click();
        await page.locator('#confirmation').waitFor({ state: 'hidden' });
        assert.deepEqual(requests.find(request => request.method === 'resumeFacDeletion').payload, { orgName: 'PendingOrg', operationId: 'fixture-pending-operation' });
        readonly = true;
        await page.evaluate(() => { window.postMessage({ action: 'close' }, '*'); window.postMessage({ action: 'open' }, '*'); });
        await page.locator('#mode-banner').getByText(/SOMENTE LEITURA/).waitFor();
        assert.equal(await page.locator('#create').isDisabled(), true);
        // Row teleport remains available with config writes disabled, validates
        // server denial and closes only after a successful, single request.
        await page.locator('#navigation button[data-area="craft"]').click();
        const bench = page.locator('.record').filter({ hasText: 'Bancada de teste' });
        await bench.getByRole('button', { name: 'Teleportar', exact: true }).waitFor();
        assert.equal(await page.locator('.record').filter({ hasText: 'Bancada sem ponto' }).getByRole('button', { name: 'Teleportar' }).count(), 0);
        await bench.getByRole('button', { name: 'Teleportar', exact: true }).click();
        await page.locator('#error').filter({ hasText: 'Permissão de teleporte revogada.' }).waitFor();
        assert.equal(await page.locator('#panel').isVisible(), true);
        assert.deepEqual(requests.find(request => request.method === 'teleport').payload, { coords: { x: 10, y: 20, z: 30 } });
        denyTeleport = false;
        await bench.getByRole('button', { name: 'Teleportar', exact: true }).click();
        await page.locator('#panel').waitFor({ state: 'hidden' });
        assert.equal(requests.filter(request => request.method === 'teleport').length, 2);
        assert.deepEqual(errors, []);
        assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth), false);
    } finally { await browser?.close(); await new Promise(resolve => server.close(resolve)); }
});
