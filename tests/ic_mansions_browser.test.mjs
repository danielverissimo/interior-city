import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';

test('mansion NUI reviews quotes, manages residents/IPTU, decorates, sells by paid cost and respects member restrictions', { skip: !process.env.IC_CONFIG_PLAYWRIGHT_MODULE }, async () => {
    const { chromium } = await import(pathToFileURL(process.env.IC_CONFIG_PLAYWRIGHT_MODULE).href);
    const root = new URL('../resources/[scriptcore]/ic_mansions/web/', import.meta.url);
    const server = createServer(async (request, response) => {
        const filename = request.url === '/' ? 'index.html' : request.url.split('?')[0].slice(1);
        if (!['index.html', 'style.css', 'recovery.css', 'app.mjs', 'model.mjs', 'transport.mjs'].includes(filename)) { response.writeHead(404).end(); return; }
        response.setHeader('Content-Type', filename.endsWith('.mjs') ? 'text/javascript' : filename.endsWith('.css') ? 'text/css' : 'text/html'); response.end(await readFile(new URL(filename, root)));
    });
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve)); let browser;
    try {
        browser = await chromium.launch({ headless: true, ...(process.env.IC_CONFIG_BROWSER_EXECUTABLE ? { executablePath: process.env.IC_CONFIG_BROWSER_EXECUTABLE } : {}) });
        const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } }); page.setDefaultTimeout(7000);
        const requests = [], errors = []; let staleRecovery = true;
        let pendingRecovery = [{ id: 'pending-review', kind: 'furniture_purchase', phase: 'uncertain', mansionId: 'm1', actorId: 1, createdAt: 1700000000, detail: { amount: 1000, itemId: 'sofa', secret: 'private-fixture', before: { name: 'Test Mansion', group: 'MansaoTest', ownerId: 1, members: [2], furniture: [] }, integrations: { groupAssignments: { group: 'MansaoTest', count: 1, assignments: [{ userId: 42, online: false, expiresAt: 1800000000, name: 'private-identity' }] } } } }];
        const state = { mansionId: 'm1', mansionName: 'Test Mansion', mansions: [{ id: 'm1', name: 'Test Mansion' }], ownerId: 0, members: [], maxResidents: 4, price: 1000000, voucher: 'valemansao1m', voucherLabel: 'Vale Mansão 1M', iptuValue: 10000, iptuPaidUntil: 0, canManage: false, canConfigure: true, canFurniture: false, canPayIptu: false, canPurchase: true, canCleanup: false, purchaseAvailable: true, catalog: { items: [{ id: 'sofa', name: 'Sofá <img src=x onerror=steal()>', model: 'prop_sofa', category: 'Sala', price: 5000 }], canConfigure: true }, furniture: [], pendingOperations: [], sellPercent: 15 };
        page.on('pageerror', error => errors.push(error.message)); await page.addInitScript(() => { window.GetParentResourceName = () => 'ic_mansions'; });
        const headers = { 'access-control-allow-origin': '*', 'access-control-allow-methods': 'POST,OPTIONS', 'access-control-allow-headers': 'Content-Type' };
        await page.route('https://ic_mansions/**', async route => {
            if (route.request().method() === 'OPTIONS') { await route.fulfill({ status: 204, headers }); return; }
            if (route.request().url().endsWith('/close')) { await route.fulfill({ status: 200, headers, body: '{}' }); return; }
            const request = route.request().postDataJSON(); requests.push(request); let data = {}, error = null;
            if (request.method === 'getContext') data = state;
            else if (request.method === 'requestPurchase') data = { quoteToken: 'purchase-quote', id: 'm1', name: 'Test Mansion', price: 1000000, voucher: 'valemansao1m', voucherLabel: 'Vale Mansão 1M', maxResidents: 4 };
            else if (request.method === 'confirmPurchase') { state.ownerId = 1; state.members = [{ userId: 1, name: 'Owner', owner: true }]; Object.assign(state, { canManage: true, canFurniture: true, canPayIptu: true, canPurchase: false, purchaseAvailable: false }); data = { message: 'Purchased' }; }
            else if (request.method === 'addResident') { state.members.push({ userId: request.payload.userId, name: 'Friend', owner: false }); data = { message: 'Added' }; }
            else if (request.method === 'removeResident') { state.members = state.members.filter(member => member.userId !== request.payload.userId); data = { message: 'Removed' }; }
            else if (request.method === 'payIptu') { state.iptuPaidUntil = Math.floor(Date.now() / 1000) + 86400; data = { message: 'Tax paid' }; }
            else if (request.method === 'startFurniturePlacement' || request.method === 'startFurnitureMove') data = { started: true };
            else if (request.method === 'sellFurniture') { state.furniture = []; data = { message: 'Sold' }; }
            else if (request.method === 'saveFurniturePrices') { state.catalog.items[0].price = request.payload.prices.sofa; data = { message: 'Prices saved' }; }
            else if (request.method === 'quoteCleanup') data = { quoteToken: 'cleanup-quote', mansionId: 'm1', residents: state.members };
            else if (request.method === 'cleanupMansion') { state.ownerId = 0; state.members = []; state.furniture = []; data = { message: 'Occupation cleared' }; }
            else if (request.method === 'getPendingOperations') data = { revision: 7, operations: pendingRecovery };
            else if (request.method === 'reconcileOperation') {
                if (staleRecovery) { staleRecovery = false; error = { code: 'CONFLICT', message: 'A revisão mudou. Recarregue as pendências.' }; }
                else { pendingRecovery = []; state.pendingOperations = []; data = { message: 'Reconciliation recorded' }; }
            }
            else error = { code: 'UNSUPPORTED', message: 'Fixture method unavailable.' };
            await route.fulfill({ status: 200, headers, contentType: 'application/json', body: JSON.stringify({ requestId: request.requestId, ok: !error, data, error }) });
        });
        await page.goto(`http://127.0.0.1:${server.address().port}/`); assert.equal(await page.locator('#home').isVisible(), false);
        await page.evaluate(() => window.postMessage({ action: 'open', context: { mansionId: 'm1' } }, '*'));
        await page.getByRole('button', { name: 'Comprar mansão', exact: true }).click();
        await page.getByRole('button', { name: 'Usar vale e comprar', exact: true }).waitFor();
        assert.equal(requests.filter(request => request.method === 'confirmPurchase').length, 0);
        assert.match(await page.locator('#confirm-description').textContent(), /nenhum pagamento em dinheiro/);
        await page.getByRole('button', { name: 'Usar vale e comprar', exact: true }).click(); await page.locator('#confirmation').waitFor({ state: 'hidden' });
        assert.deepEqual(requests.find(request => request.method === 'confirmPurchase').payload, { id: 'm1', quoteToken: 'purchase-quote', confirmed: true });
        if (process.env.IC_MANSIONS_SCREENSHOT) await page.screenshot({ path: process.env.IC_MANSIONS_SCREENSHOT });
        await page.locator('aside [data-view="residents"]').click();
        await page.getByLabel('Passaporte do novo morador').fill('2'); await page.getByRole('button', { name: 'Adicionar morador', exact: true }).click(); await page.getByText('Friend', { exact: true }).waitFor();
        assert.equal(await page.getByRole('button', { name: 'Remover morador', exact: true }).count(), 1);
        await page.getByRole('button', { name: 'Remover morador', exact: true }).click(); await page.getByRole('button', { name: 'Remover acesso', exact: true }).click(); await page.locator('#confirmation').waitFor({ state: 'hidden' });
        assert.equal(requests.find(request => request.method === 'removeResident').payload.userId, 2);
        assert.equal(requests.find(request => request.method === 'removeResident').payload.confirmed, true);
        await page.locator('aside [data-view="overview"]').click(); await page.getByRole('button', { name: 'Pagar IPTU', exact: true }).click(); await page.getByRole('button', { name: 'Confirmar pagamento', exact: true }).click(); await page.locator('#confirmation').waitFor({ state: 'hidden' });
        assert.deepEqual(requests.find(request => request.method === 'payIptu').payload, { mansionId: 'm1', confirmed: true });
        await page.locator('aside [data-view="catalog"]').click();
        assert.equal(await page.locator('#content img').count(), 0); await page.getByRole('button', { name: 'Posicionar na mansão', exact: true }).click(); await page.getByRole('button', { name: 'Escolher posição', exact: true }).click();
        await page.locator('#confirmation').waitFor({ state: 'hidden' }); assert.deepEqual(requests.find(request => request.method === 'startFurniturePlacement').payload, { mansionId: 'm1', itemId: 'sofa' });
        state.furniture.push({ id: 'f1', itemId: 'sofa', name: 'Owned Sofa', model: 'prop_sofa', paidPrice: 1000, price: 5000, x: 1, y: 2, z: 3, heading: 0 });
        await page.evaluate(() => { window.postMessage({ action: 'suspend' }, '*'); window.postMessage({ action: 'operationResult', ok: true, message: 'Placed' }, '*'); window.postMessage({ action: 'resume' }, '*'); });
        await page.locator('aside [data-view="placed"]').click(); await page.getByText('Owned Sofa', { exact: true }).waitFor();
        await page.getByRole('button', { name: 'Mover', exact: true }).click(); await page.waitForFunction(() => document.querySelector('#refresh').disabled === false);
        assert.deepEqual(requests.find(request => request.method === 'startFurnitureMove').payload, { mansionId: 'm1', furnitureId: 'f1' });
        await page.getByRole('button', { name: 'Vender', exact: true }).click(); assert.match(await page.locator('#confirm-details').textContent(), /150,00/);
        await page.getByRole('button', { name: 'Confirmar venda', exact: true }).click(); await page.locator('#confirmation').waitFor({ state: 'hidden' });
        assert.equal(requests.find(request => request.method === 'sellFurniture').payload.confirmed, true);
        await page.locator('aside [data-view="prices"]').click(); await page.getByLabel('Preço: Sofá <img src=x onerror=steal()>', { exact: true }).fill('7000');
        await page.getByRole('button', { name: 'Revisar e salvar', exact: true }).click(); await page.getByRole('button', { name: 'Salvar valores', exact: true }).click(); await page.locator('#confirmation').waitFor({ state: 'hidden' });
        assert.equal(requests.find(request => request.method === 'saveFurniturePrices').payload.prices.sofa, 7000);
        Object.assign(state, { canManage: false, canFurniture: false, canConfigure: false, canPayIptu: true }); state.catalog.canConfigure = false;
        await page.locator('#refresh').click(); await page.locator('aside [data-view="residents"]').click(); assert.equal(await page.getByRole('button', { name: 'Adicionar morador', exact: true }).count(), 0);
        await page.locator('aside [data-view="catalog"]').click(); assert.equal(await page.getByRole('button', { name: 'Posicionar na mansão', exact: true }).isDisabled(), true);
        assert.equal(await page.locator('aside [data-view="recovery"]').isVisible(), false);
        state.canCleanup = true; await page.locator('#refresh').click(); await page.locator('aside [data-view="overview"]').click(); await page.getByRole('button', { name: 'Revisar limpeza da ocupação', exact: true }).click();
        await page.getByRole('heading', { name: 'Limpar ocupação da mansão', exact: true }).waitFor();
        assert.equal(requests.filter(request => request.method === 'cleanupMansion').length, 0);
        assert.match(await page.locator('#confirm-description').textContent(), /sem reembolso/);
        await page.getByRole('button', { name: 'Limpar ocupação sem reembolso', exact: true }).click(); await page.locator('#confirmation').waitFor({ state: 'hidden' });
        assert.deepEqual(requests.find(request => request.method === 'cleanupMansion').payload, { mansionId: 'm1', quoteToken: 'cleanup-quote', confirmed: true });
        state.pendingOperations = [{ operationId: 'pending-review', state: 'uncertain' }]; await page.locator('#refresh').click();
        await page.locator('#operation-note').filter({ hasText: 'pendente de conferência' }).waitFor();
        assert.equal(await page.getByRole('button', { name: 'Pagar IPTU', exact: true }).isDisabled(), true);
        await page.evaluate(() => { window.postMessage({ action: 'operationResult', ok: false, message: 'Operação precisa de conferência.' }, '*'); window.postMessage({ action: 'resume' }, '*'); });
        await page.locator('#error').filter({ hasText: 'Operação precisa de conferência.' }).waitFor();
        state.canConfigure = true; state.catalog.canConfigure = true; await page.locator('#refresh').click();
        await page.locator('aside [data-view="recovery"]').click(); await page.getByText('Operação pending-review', { exact: true }).waitFor();
        assert.equal(requests.filter(request => request.method === 'reconcileOperation').length, 0);
        assert.ok(!(await page.locator('#content').textContent()).includes('private-fixture'));
        await page.getByRole('button', { name: 'Revisar liberação manual', exact: true }).click();
        await page.getByText('Vínculo no cargo: ID 42', { exact: true }).last().waitFor();
        assert.ok((await page.locator('#confirm-details').textContent()).includes('1800000000'));
        assert.ok(!(await page.locator('#confirm-details').textContent()).includes('private-identity'));
        await page.getByLabel('Digite a frase de confirmação', { exact: true }).fill('RECONCILIADO pending-review');
        assert.equal(await page.getByRole('button', { name: 'Registrar reconciliação e liberar', exact: true }).isDisabled(), true);
        await page.locator('#recovery-settled').check(); await page.getByLabel('Digite a frase de confirmação', { exact: true }).fill('pending-review');
        assert.equal(await page.getByRole('button', { name: 'Registrar reconciliação e liberar', exact: true }).isDisabled(), true);
        await page.getByLabel('Digite a frase de confirmação', { exact: true }).fill('RECONCILIADO pending-review');
        if (process.env.IC_MANSIONS_RECOVERY_SCREENSHOT) await page.screenshot({ path: process.env.IC_MANSIONS_RECOVERY_SCREENSHOT });
        await page.getByRole('button', { name: 'Registrar reconciliação e liberar', exact: true }).click();
        await page.locator('#confirm-error').filter({ hasText: 'A revisão mudou.' }).waitFor();
        assert.equal(await page.getByRole('button', { name: 'Registrar reconciliação e liberar', exact: true }).isDisabled(), true);
        await page.locator('#cancel-confirm').click();
        assert.equal(await page.getByRole('button', { name: 'Revisar liberação manual', exact: true }).isDisabled(), true);
        await page.getByRole('button', { name: 'Recarregar pendências', exact: true }).click();
        await page.getByRole('button', { name: 'Revisar liberação manual', exact: true }).click();
        await page.locator('#recovery-settled').check(); await page.getByLabel('Digite a frase de confirmação', { exact: true }).fill('RECONCILIADO pending-review');
        await page.getByRole('button', { name: 'Registrar reconciliação e liberar', exact: true }).click(); await page.locator('#confirmation').waitFor({ state: 'hidden' });
        const reconciliations = requests.filter(request => request.method === 'reconcileOperation'); assert.equal(reconciliations.length, 2);
        assert.deepEqual(reconciliations[1].payload, { operationId: 'pending-review', decision: 'cancel_after_manual_reconciliation', confirmation: 'RECONCILIADO pending-review', confirmed: true, expectedRevision: 7 });
        await page.getByText('Nenhuma operação pendente', { exact: true }).waitFor();
        await page.locator('#refresh').click(); await page.evaluate(() => window.postMessage({ action: 'resume' }, '*'));
        assert.equal(requests.filter(request => request.method === 'reconcileOperation').length, 2);
        await page.setViewportSize({ width: 650, height: 900 }); assert.equal(await page.locator('.mobile-navigation').isVisible(), true);
        assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth), false); assert.deepEqual(errors, []);
    } finally { await browser?.close(); await new Promise(resolve => server.close(resolve)); }
});
