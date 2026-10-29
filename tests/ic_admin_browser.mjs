#!/usr/bin/env node
// Synthetic browser verification only: this does not connect to FXServer/GTA.
// Uses an existing Playwright installation; it never installs dependencies/browsers.
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { dirname, join, resolve, extname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { tmpdir } from 'node:os';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const webRoot = join(root, 'resources/[scriptcore]/ic_admin/web');
const output = resolve(process.env.IC_ADMIN_BROWSER_OUTPUT || join(tmpdir(), 'ic-admin-browser'));
let playwright;
try {
    playwright = process.env.IC_ADMIN_PLAYWRIGHT_MODULE
        ? await import(pathToFileURL(resolve(process.env.IC_ADMIN_PLAYWRIGHT_MODULE)).href)
        : await import('playwright');
} catch {
    console.error('Use an existing Playwright installation: IC_ADMIN_PLAYWRIGHT_MODULE=/absolute/path/to/playwright/index.mjs node tests/ic_admin_browser.mjs');
    process.exit(2);
}
await mkdir(output, { recursive: true });
const types = { '.html':'text/html', '.mjs':'text/javascript', '.css':'text/css', '.png':'image/png' };
const server = createServer(async (request, response) => {
    const name = new URL(request.url, 'http://localhost').pathname;
    if (name === '/favicon.ico') { response.writeHead(204); response.end(); return; }
    const file = name === '/' ? 'index.html' : name.slice(1);
    if (!['index.html','style.css','app.mjs','transport.mjs','monitor.mjs','map.mjs','assets/map.png'].includes(file)) { response.writeHead(404); response.end(); return; }
    try { response.writeHead(200, { 'Content-Type':types[extname(file)] || 'text/plain' }); response.end(await readFile(join(webRoot,file))); }
    catch { response.writeHead(500); response.end(); }
});
await new Promise(done => server.listen(0, '127.0.0.1', done));
const browser = await playwright.chromium.launch({
    headless: true,
    channel: process.env.IC_ADMIN_BROWSER_EXECUTABLE ? undefined : (process.env.IC_ADMIN_BROWSER_CHANNEL || 'chrome'),
    executablePath: process.env.IC_ADMIN_BROWSER_EXECUTABLE || undefined
});
const errors = [];
const page = await browser.newPage({ viewport:{width:1920,height:1080} });
page.on('pageerror', error => errors.push(error.message));
const pages = ['server','players','warnings','map','calls','groups','identity','items','weapons','vips','vehicles','radio','locations','climate','logs'];
try {
    await page.addInitScript(() => {
        window.testRequests = [];
        window.testFixtures = {
            'players.list': {players:[{id:1,name:'Equipe Interior City',ping:20,groups:['dono'],coords:{x:46,y:-899,z:30}},{id:2,name:'Jogador de homologação',ping:36,groups:['user'],coords:{x:1000,y:1200,z:30}}],stats:{players:2}},
            'players.snapshot': {id:2,name:'Jogador de homologação',online:true,identity:{nome:'Jogador',sobrenome:'de homologação',idade:25,telefone:'555-0000',registro:'TESTE'},wallet:250,bank:1000,groups:['user'],inventory:[{item:'water',name:'Água',amount:3,slot:1}]},
            'catalog.get': {items:[{id:'water',name:'Água',weight:.2,type:'use'}],weapons:[{id:'WEAPON_PISTOL',name:'Pistola',type:'equip',weight:1,ammo:'pistol_ammo'}],vehicles:[{id:'sultan',name:'Sultan'}],groups:[{name:'user',permissions:[],config:{gtype:'user'}}]},
            'bans.list': {bans:[{user_id:2,motivo:'Ban vigente de teste',banimento:'28/10/2026',time:0}],history:[{id:1,user_id:2,actor_id:1,kind:'ban',reason:'Histórico de teste',starts_at:1}]},
            'warnings.list': {warnings:[{id:1,user_id:2,reason:'Advertência de homologação',starts_at:1,ends_at:2,state:'archived'}]},
            'calls.list': {calls:[{id:1,requesterId:2,requesterName:'Jogador de homologação',department:'staff',message:'Atendimento de homologação',state:'open',canAccept:true,canFinish:false,canRate:false}],ranking:[],ratings:[]},
            'vip.list': {packages:[{group:'vip_teste',title:'Pacote de homologação',salary:10,items:[{item:'water',amount:1}],vehicles:[{spawn:'sultan',name:'Sultan'}],vehicleChoices:1,garageSlots:1}],assignments:[]},
            'radio.list': {radios:[{id:1,name:'Polícia',channel:100,permissions:['perm.policia'],enabled:true}]},
            'locations.list': {locations:[{id:'1',name:'Praça',category:'Cidade',x:46,y:-899,z:30}],categories:['Cidade']},
            'world.get': {weather:'CLEAR',hour:12,minute:0,freezeWeather:true,freezeTime:false,rotation:false,types:['CLEAR','RAIN']},
            'needs.get': {enabled:true,settings:{hungerPerMinute:2,thirstPerMinute:3,hungerDamage:1,thirstDamage:1}},
            'audit.list': {entries:[{id:1,created_at:'2026-10-28T00:00:00Z',action:'ban',actor_id:1,target_id:2,payload:{reason:'Teste'}}],total:1,page:1},
            'audit.destinations': {destinations:[{id:'staff',label:'Equipe',configured:true}],routes:{}}
        };
        window.testFixtures['reconciliation.list']={operations:[{id:'a'.repeat(64),actor_id:1,method:'vip.assign',state:'uncertain',payload:{targetId:2}}],assignments:[{id:'review-test',userId:2,group:'vip_teste',state:'uncertain',claims:[]}],total:1,totalAssignments:1,page:1};
        window.testFixtures['map.players']=window.testFixtures['players.list'];
        window.testFixtures['players.lookup'] = window.testFixtures['players.snapshot'];
        const nativeFetch = window.fetch;
        window.fetch = async (url, options) => {
            if (!String(url).startsWith('https://ic_admin/')) return nativeFetch(url,options);
            const request = JSON.parse(options.body); window.testRequests.push(request);
            if (window.failNextMethod === request.method) {
                window.failNextMethod = null;
                return {json:async()=>({ok:false,error:{code:'FORBIDDEN',message:'Acesso de homologação recusado.'}})};
            }
            return {json:async()=>({ok:true,data:window.testFixtures[request.method] || {}})};
        };
        window.openFixture = () => {
            const allowedActions = {};
            for (const key of ['view_server','view_players','view_warnings','view_map','view_calls','view_groups','view_identity_editor','view_items','view_weapons','view_vips','view_vehicles','view_radio','view_locations','view_climate','view_logs','wladd','wlrem','ban','unban','send_adm','godall','tpway','tpcds','clear_allveh','clear_props','needs_manage','create_vip','edit_vip','assign_vip','delete_vip','give_item','spawn_self_item','spawn_weapon','inspect_inventory','map_screen','warning','radio_save','radio_delete','add_location','remove_location','teleport_location','logs_manage','catch_rg','ban_history_view','reconciliation_manage']) allowedActions[key] = true;
            window.postMessage({type:'open',payload:{admin:{id:1,name:'Equipe Interior City',role:'dono'},permissions:{allowedActions,canManage:true},players:window.testFixtures['players.list'].players,stats:{players:2},mode:'preview'}},'*');
        };
    });
    await page.goto(`http://127.0.0.1:${server.address().port}/`);
    await page.evaluate(() => window.openFixture());
    await page.waitForSelector('.card');
    const checks = [];
    for (const id of pages) {
        await page.locator(`[data-nav=${id}]`).click();
        await page.waitForFunction(() => !document.querySelector('.loading'));
        assert.equal(await page.locator('#content').evaluate(el=>el.textContent.includes('Não foi possível')),false,`screen ${id}`);
        assert.equal(await page.locator('.shell').evaluate(el=>el.scrollWidth>el.clientWidth),false,`overflow ${id}`);
        checks.push(id);
    }
    await page.evaluate(()=>window.postMessage({type:'close'},'*'));
    await page.evaluate(()=>window.postMessage({type:'publicCallsList'},'*'));
    await page.waitForSelector('#modal-title');
    assert.equal(await page.locator('#modal-title').textContent(),'Atendimentos');
    await page.locator('[data-modal-close]').click();
    await page.evaluate(()=>window.openFixture());
    await page.waitForSelector('.card');
    await page.locator('[data-nav=server]').click();
    await page.waitForSelector('[data-action=ban]');
    await page.locator('[data-action=ban]').click();
    await page.locator('[name=targetId]').fill('2');
    await page.locator('[name=reason]').fill('Homologação de formulário');
    await page.locator('#operation-form button[type=submit]').click();
    await page.waitForFunction(() => document.querySelector('#modal-layer').hidden);
    const ban = await page.evaluate(() => window.testRequests.find(r=>r.method==='action.execute'&&r.payload.action==='ban'));
    assert.deepEqual(ban.payload,{targetId:2,action:'ban',reason:'Homologação de formulário'});
    await page.locator('[data-command=lookup]').click();
    await page.locator('[name=targetId]').fill('2');
    await page.locator('#operation-form button[type=submit]').click();
    await page.waitForFunction(() => document.querySelector('#modal-title').textContent.includes('Consultar RG · #2'));
    assert.equal(await page.locator('#operation-form').count(),0,'RG lookup is read-only');
    const lookup=await page.evaluate(()=>window.testRequests.find(r=>r.method==='players.lookup'));
    assert.deepEqual(lookup.payload,{targetId:2});
    await page.locator('[data-modal-close]').click();
    await page.locator('[data-command=ban-history]').click();
    await page.waitForFunction(()=>document.querySelector('#modal-layer').textContent.includes('Ban vigente de teste'));
    assert.ok((await page.locator('#modal-layer').textContent()).includes('Histórico de teste'));
    await page.locator('[data-modal-close]').click();
    await page.locator('[data-nav=weapons]').click();
    await page.waitForSelector('[data-weapon=WEAPON_PISTOL]');
    await page.locator('[data-weapon=WEAPON_PISTOL]').click();
    assert.equal(await page.locator('[name=targetId]').count(),0,'weapons target is self, not client-selected');
    await page.locator('[name=ammoAmount]').fill('12');
    await page.locator('[name=reason]').fill('Homologação de arma e munição');
    await page.locator('#operation-form button[type=submit]').click();
    await page.waitForFunction(()=>document.querySelector('#modal-layer').hidden);
    const weapon=await page.evaluate(()=>window.testRequests.find(r=>r.method==='weapons.give'));
    assert.deepEqual(weapon.payload,{weapon:'WEAPON_PISTOL',ammoAmount:12,reason:'Homologação de arma e munição'});
    await page.locator('[data-nav=vips]').click();
    await page.waitForSelector('[data-command=vip-new]');
    await page.locator('[data-command=vip-new]').click();
    await page.waitForSelector('#operation-form');
    assert.equal(await page.locator('#operation-form textarea').count(),0,'VIP editor must use catalog controls');
    await page.locator('[name=group]').fill('vip_teste_novo');
    await page.locator('[name=title]').fill('VIP de homologação');
    await page.locator('[name=vehicleChoices]').fill('1');
    await page.locator('[data-vip-add-item]').click();
    await page.locator('[data-item-amount]').fill('5');
    await page.locator('[data-vip-add-vehicle]').click();
    await page.locator('#operation-form button[type=submit]').click();
    await page.waitForFunction(() => document.querySelector('#modal-layer').hidden);
    const vip = await page.evaluate(() => window.testRequests.find(r=>r.method==='vip.save'));
    assert.deepEqual(vip.payload.items,[{item:'water',amount:5}]);
    assert.deepEqual(vip.payload.vehicles,[{spawn:'sultan',name:'Sultan'}]);
    // The map loads locally; zoom, keyboard and marker selection survive refresh.
    await page.locator('[data-nav=map]').click();
    await page.waitForFunction(()=>document.querySelector('.atlas-image')?.naturalWidth>0);
    await page.locator('[data-map-in]').click();
    assert.equal(await page.locator('[data-map-scale]').textContent(),'140%');
    await page.locator('.atlas').focus();await page.keyboard.press('Home');
    assert.equal(await page.locator('[data-map-scale]').textContent(),'100%');
    await page.locator('.atlas-player[data-player="2"]').click();
    await page.waitForSelector('#modal-title');await page.locator('[data-modal-close]').click();
    await page.screenshot({path:join(output,'ic-admin-map.png')});
    // Categories submit the original category and reason, without deleting locations.
    await page.locator('[data-nav=locations]').click();await page.locator('[data-command=categories]').click();
    await page.locator('[data-category-edit="Cidade"]').click();await page.locator('[name=name]').fill('Centro');await page.locator('[name=reason]').fill('Organizar locais');
    await page.locator('#operation-form button[type=submit]').click();await page.waitForFunction(()=>document.querySelector('#modal-layer').hidden);
    const category=await page.evaluate(()=>window.testRequests.find(r=>r.method==='locations.categorySave'));
    assert.deepEqual(category.payload,{original:'Cidade',name:'Centro',reason:'Organizar locais'});
    // Manual reconciliation requires the record confirmation and evidence.
    await page.locator('[data-nav=vips]').click();await page.locator('[data-command=reconciliation]').click();
    await page.locator('[data-review-vip="review-test"]').click();
    await page.locator('[name=outcome]').selectOption('archive');await page.locator('[name=evidence]').fill('Conferência de inventário e grupo');await page.locator('[name=reason]').fill('Arquivar após conferência');await page.locator('[name=confirmId]').fill('review-test');
    await page.locator('#operation-form button[type=submit]').click();await page.waitForFunction(()=>document.querySelector('#modal-title').textContent==='Conferência administrativa');
    const review=await page.evaluate(()=>window.testRequests.find(r=>r.method==='reconciliation.resolve'));
    assert.equal(review.payload.kind,'vip');assert.equal(review.payload.id,'review-test');assert.equal(review.payload.outcome,'archive');
    await page.locator('[data-modal-close]').click();
    // A refused read must yield a visible error, not silently render stale data.
    await page.evaluate(() => { window.failNextMethod='radio.list'; });
    await page.locator('[data-nav=radio]').click();
    await page.waitForFunction(() => document.querySelector('#content').textContent.includes('Não foi possível'));
    assert.ok(await page.locator('.toast.error').count());
    await page.locator('[data-nav=server]').click();
    await page.waitForSelector('.card');
    await page.evaluate(() => document.querySelector('#toast-layer').replaceChildren());
    const screenshots=[];
    for (const [label,width,height] of [['1280',1280,720],['1920',1920,1080],['ultrawide',3440,1440]]) {
        await page.setViewportSize({width,height});
        await page.waitForTimeout(100);
        // Bottom navigation must remain reachable when the sidebar needs scrolling.
        await page.locator('[data-nav=logs]').click();
        await page.waitForFunction(() => !document.querySelector('.loading'));
        await page.locator('[data-nav=server]').click();
        await page.waitForSelector('.card');
        assert.equal(await page.locator('.shell').evaluate(el=>el.scrollWidth>el.clientWidth),false,`overflow ${label}`);
        assert.equal(await page.locator('.brand').evaluate(el=>el.getBoundingClientRect().top>=document.querySelector('.shell').getBoundingClientRect().top),true,`clipped brand ${label}`);
        const filename=join(output,`ic-admin-${label}.png`);
        await page.screenshot({path:filename});screenshots.push(filename);
    }
    assert.deepEqual(errors,[],'browser runtime errors');
    const report={synthetic:true,gta:false,checks,banPayload:ban.payload,lookupPayload:lookup.payload,weaponPayload:weapon.payload,vipPayload:vip.payload,browserErrors:errors,screenshots};
    await writeFile(join(output,'report.json'),JSON.stringify(report,null,2)+'\n');
    console.log(JSON.stringify(report,null,2));
} finally {
    await browser.close();
    await new Promise(done=>server.close(done));
}
