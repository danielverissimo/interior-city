// Compare composited pixels: transparent CSS alone does not prove NUI transparency.
import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { tmpdir } from 'node:os';

for (const resource of ['ic_config', 'ic_mansions']) {
    test(`${resource}: closed, suspended and closed-again NUI preserve the game scene`, { skip: !process.env.IC_CONFIG_PLAYWRIGHT_MODULE }, async () => {
        const { chromium } = await import(pathToFileURL(process.env.IC_CONFIG_PLAYWRIGHT_MODULE).href);
        const root = new URL(`../resources/[scriptcore]/${resource}/web/`, import.meta.url);
        const output = resolve(process.env.IC_CONFIG_TRANSPARENCY_OUTPUT || join(tmpdir(), 'ic-config-transparency'));
        await mkdir(output, { recursive: true });
        const server = createServer(async (req, res) => {
            const path = new URL(req.url, 'http://localhost').pathname;
            if (path === '/host') {
                res.setHeader('Content-Type', 'text/html');
                res.end('<!doctype html><html style="background:rgb(20,180,100);color-scheme:light"><body style="margin:0"><iframe id="nui" style="position:fixed;inset:0;width:100%;height:100%;border:0" src="/index.html"></iframe></body></html>');
                return;
            }
            if (path === '/regression.css') {
                res.setHeader('Content-Type', 'text/css');
                res.end(':root{color-scheme:dark!important}');
                return;
            }
            const name = path.slice(1);
            if (!['index.html', 'style.css', 'mansions.css', 'craft.css', 'forms.css', 'recovery.css', 'app.mjs', 'model.mjs', 'transport.mjs', 'mansions.mjs', 'craft.mjs', 'forms.mjs', 'form-schema.mjs', 'catalog-picker.mjs'].includes(name)) { res.writeHead(404).end(); return; }
            try {
                res.setHeader('Content-Type', name.endsWith('.mjs') ? 'text/javascript' : name.endsWith('.css') ? 'text/css' : 'text/html');
                res.end(await readFile(new URL(name, root)));
            } catch { res.writeHead(404).end(); }
        });
        await new Promise(done => server.listen(0, '127.0.0.1', done));
        let browser;
        try {
            browser = await chromium.launch({ headless: true, ...(process.env.IC_CONFIG_BROWSER_EXECUTABLE ? { executablePath: process.env.IC_CONFIG_BROWSER_EXECUTABLE } : {}) });
            const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, colorScheme: 'light' });
            page.setDefaultTimeout(7000);
            const errors = [];
            page.on('pageerror', error => errors.push(error.message));
            await page.addInitScript(({ resource }) => {
                window.GetParentResourceName = () => resource;
                const nativeFetch = window.fetch;
                window.fetch = async (url, options) => {
                    if (!String(url).startsWith(`https://${resource}/`)) return nativeFetch(url, options);
                    const request = JSON.parse(options.body);
                    const data = request.method === 'bootstrap' ? { writesEnabled: false, methods: [] }
                        : request.method === 'getManagedGroups' ? []
                        : { mansionId: 'fixture', mansionName: 'Mansão de teste', members: [], furniture: [], maxResidents: 4 };
                    return { json: async () => ({ ok: true, requestId: request.requestId, data }) };
                };
            }, { resource });
            await page.goto(`http://127.0.0.1:${server.address().port}/host`);
            const frame = page.frames().find(value => value !== page.mainFrame());
            const panel = resource === 'ic_config' ? '#panel' : '#home';
            const close = resource === 'ic_config' ? '#close-panel' : '#close';
            await frame.waitForFunction(selector => typeof document.querySelector(selector)?.onclick === 'function', close);
            assert.equal(await frame.locator(panel).isVisible(), false);
            await page.locator('#nui').evaluate(el => el.style.visibility = 'hidden');
            const scene = await page.screenshot({ path: join(output, `${resource}-scene.png`) });
            await page.locator('#nui').evaluate(el => el.style.visibility = 'visible');
            const initial = await page.screenshot({ path: join(output, `${resource}-initial.png`) });
            await writeFile(join(output, `${resource}-initial-result.json`), JSON.stringify({ initialPreservesScene: initial.equals(scene) }));
            assert.deepEqual(initial, scene, 'a closed NUI must not cover the game with an opaque canvas');

            // Negative control: reintroducing the old root rule must reproduce the defect.
            const regression = await frame.addStyleTag({ url: `http://127.0.0.1:${server.address().port}/regression.css` });
            assert.notDeepEqual(await page.screenshot(), scene, 'the test must detect the original dark-root canvas');
            await regression.evaluate(el => el.remove());
            assert.deepEqual(await page.screenshot(), scene);

            await frame.evaluate(() => window.postMessage({ action: 'open' }, '*'));
            await frame.locator(panel).waitFor();
            assert.notDeepEqual(await page.screenshot(), scene, 'the opened panel must remain visible');
            assert.equal(await frame.locator(panel).evaluate(el => getComputedStyle(el).colorScheme), 'dark');
            await frame.locator('#confirmation').evaluate(el => el.showModal());
            assert.equal(await frame.locator('#confirmation').evaluate(el => getComputedStyle(el).colorScheme), 'dark');
            await frame.locator('#confirmation').evaluate(el => el.close());
            await frame.evaluate(() => window.postMessage({ action: 'suspend' }, '*'));
            await frame.locator(panel).waitFor({ state: 'hidden' });
            assert.deepEqual(await page.screenshot(), scene, 'position capture must reveal the game scene');
            await frame.evaluate(() => window.postMessage({ action: 'resume' }, '*'));
            await frame.locator(panel).waitFor();
            await frame.locator(close).click();
            await frame.locator(panel).waitFor({ state: 'hidden' });
            assert.deepEqual(await page.screenshot({ path: join(output, `${resource}-after-close.png`) }), scene, 'closing the panel must restore every scene pixel');
            assert.deepEqual(errors, []);
        } finally {
            if (browser) await browser.close();
            await new Promise(done => server.close(done));
        }
    });
}
