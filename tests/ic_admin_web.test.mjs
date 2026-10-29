import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createTransport, escapeHtml, isAllowed, rowsOf } from '../resources/[scriptcore]/ic_admin/web/transport.mjs';
import { createMonitor } from '../resources/[scriptcore]/ic_admin/web/monitor.mjs';

test('mutation is sent once and keeps the server failure code', async () => {
    let calls = 0;
    const transport = createTransport({ fetcher: async (_url, options) => {
        calls++; const request = JSON.parse(options.body);
        assert.equal(request.method, 'vip.assign'); assert.equal(request.payload.targetId, 7);
        return { json: async () => ({ requestId: request.requestId, ok: false, error: { code: 'ALREADY_ACTIVE', message: 'VIP já ativo.' } }) };
    } });
    await assert.rejects(transport.call('vip.assign', { targetId: 7 }), error => error.code === 'ALREADY_ACTIVE');
    assert.equal(calls, 1); assert.equal(transport.pending.size, 0);
});

test('timeout aborts once without retrying economic changes', async () => {
    let calls = 0;
    const transport = createTransport({ timeout: 5, fetcher: (_url, { signal }) => {
        calls++;
        return new Promise((_resolve, reject) => signal.addEventListener('abort', () => reject(Object.assign(new Error('aborted'), { name: 'AbortError' }))));
    } });
    await assert.rejects(transport.call('economy.change', { amount: 100 }), error => error.code === 'TIMEOUT');
    assert.equal(calls, 1); assert.equal(transport.pending.size, 0);
});

test('each request has a distinct identifier and successful payload is returned', async () => {
    const ids = [];
    const transport = createTransport({ fetcher: async (_url, options) => {
        const request = JSON.parse(options.body); ids.push(request.requestId);
        return { json: async () => ({ ok: true, data: { targetId: 5 } }) };
    } });
    assert.deepEqual(await transport.call('players.snapshot'), { targetId: 5 });
    await transport.call('players.snapshot');
    assert.equal(new Set(ids).size, 2);
});

test('untrusted player names and audit details are HTML escaped', () => {
    assert.equal(escapeHtml('<img src=x onerror="steal()">\'&'), '&lt;img src=x onerror=&quot;steal()&quot;&gt;&#39;&amp;');
    assert.equal(isAllowed(null, 'ban'), false);
    assert.equal(isAllowed({ allowedActions: { ban: 'true' } }, 'ban'), false);
    assert.equal(isAllowed({ allowedActions: { ban: true } }, 'ban'), true);
    assert.deepEqual(rowsOf({ entries: [1] }, 'rows', 'entries'), [1]);
});

test('NUI contains all planned areas and no external executable scripts', async () => {
    const html = await readFile(new URL('../resources/[scriptcore]/ic_admin/web/index.html', import.meta.url), 'utf8');
    const app = await readFile(new URL('../resources/[scriptcore]/ic_admin/web/app.mjs', import.meta.url), 'utf8');
    assert.ok(!/<script[^>]+src=["']https?:/i.test(html));
    for (const page of ['server','players','warnings','map','calls','groups','identity','items','weapons','vips','vehicles','radio','locations','climate','logs']) {
        assert.match(app, new RegExp(`\\['${page}',`));
    }
    assert.match(html, /aria-modal|modal-layer/);
});

test('closing a monitor while start is pending terminates the late server session', async () => {
    globalThis.document = { querySelector: () => null };
    let resolveStart;
    const calls = [];
    const monitor = createMonitor({
        call: async (method, payload) => {
            calls.push({ method, payload });
            if (method === 'monitor.start') return new Promise(resolve => { resolveStart = resolve; });
            return {};
        },
        post: async () => { throw new Error('closed monitor must not signal ready'); }, toast: () => {}
    });
    const opening = monitor.start(2);
    monitor.stop();
    resolveStart({ token: 'late-session', options: {} });
    await opening;
    assert.ok(calls.some(entry => entry.method === 'monitor.stop' && entry.payload.token === 'late-session'));
    delete globalThis.document;
});


test('geographic projection uses the atlas CRS and omits invalid/outside coordinates', async () => {
    const {project}=await import('../resources/[scriptcore]/ic_admin/web/map.mjs');
    assert.deepEqual(project(0,0),{x:117.3/256,y:172.8/256});
    assert.ok(project(46,-899));
    assert.equal(project(NaN,2),null);assert.equal(project(100000,100000),null);
    const crs={centerX:128,centerY:128,scaleX:1,scaleY:1};
    assert.deepEqual(project(64,64,crs),{x:.75,y:.25});
});
