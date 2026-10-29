#!/usr/bin/env node
// Synthetic loading/HUD verification; no FiveM or production connection.
import assert from 'node:assert/strict';
import {createServer} from 'node:http';
import {readFile,mkdir,writeFile} from 'node:fs/promises';
import {dirname,resolve,join,extname} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
import {tmpdir} from 'node:os';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const loading=join(root,'resources/[scriptcore]/ic_loading/web');
const hud=join(root,'resources/[scriptcore]/m_hud/web/build');
const output=resolve(process.env.IC_LOADING_BROWSER_OUTPUT||join(tmpdir(),'ic-loading-browser'));
const playwright=process.env.IC_ADMIN_PLAYWRIGHT_MODULE?await import(pathToFileURL(resolve(process.env.IC_ADMIN_PLAYWRIGHT_MODULE)).href):await import('playwright');
const hash=data=>createHash('sha256').update(data).digest('hex');
const iconHash=hash(await readFile(join(root,'logo.png')));
const hudImage=await readFile(join(hud,'assets/logo-D8JhG3_9.png'));
const hudHash=hash(hudImage);
const lock=JSON.parse(await readFile(join(root,'assets.lock.json'),'utf8'));
const logos=lock.packages.flatMap(p=>p.files).filter(f=>/(?:^|\/)logo[^/]*\.(?:png|webp|svg|jpg)$/i.test(f.path));
for(const file of logos){assert.ok(file.path.endsWith('.png'),file.path);assert.equal(hash(await readFile(join(root,file.path))),file.path.startsWith('resources/[scriptcore]/m_hud/')?hudHash:iconHash,file.path);}
// FiveM's default shutdown remains in charge of the loading-screen lifetime.
assert.match(await readFile(join(root,'config/resources.cfg'),'utf8'),/^ensure ic_loading$/m);
assert.doesNotMatch(await readFile(join(root,'resources/[vrp]/vrp/fxmanifest.lua'),'utf8'),/^\s*loadscreen\s/m);
assert.doesNotMatch(await readFile(join(root,'resources/[scriptcore]/ic_loading/fxmanifest.lua'),'utf8'),/loadscreen_manual_shutdown/);
await mkdir(output,{recursive:true});
const types={'.html':'text/html','.css':'text/css','.js':'text/javascript','.webm':'video/webm','.png':'image/png','.svg':'image/svg+xml','.woff2':'font/woff2'};
const server=createServer(async(req,res)=>{
    const path=decodeURIComponent(new URL(req.url,'http://localhost').pathname);
    if(path.includes('..')){res.writeHead(400);res.end();return;}
    if(path==='/favicon.ico'){res.writeHead(204);res.end();return;}
    const base=path.startsWith('/hud/')?hud:loading;
    const relative=path.startsWith('/hud/')?path.slice(5):path==='/'?'index.html':path.slice(1);
    try{
        const data=await readFile(join(base,relative));const headers={'Content-Type':types[extname(relative)]||'application/octet-stream','Accept-Ranges':'bytes'};
        const range=/^bytes=(\d+)-(\d*)$/.exec(req.headers.range||'');
        if(range){const start=Number(range[1]),end=Math.min(data.length-1,range[2]?Number(range[2]):data.length-1);res.writeHead(206,{...headers,'Content-Range':`bytes ${start}-${end}/${data.length}`,'Content-Length':end-start+1});res.end(data.subarray(start,end+1));}
        else{res.writeHead(200,headers);res.end(data);}
    }catch{res.writeHead(404);res.end();}
});
await new Promise(done=>server.listen(0,'127.0.0.1',done));
const origin=`http://127.0.0.1:${server.address().port}`;
const browser=await playwright.chromium.launch({headless:true,channel:process.env.IC_ADMIN_BROWSER_CHANNEL||'chrome'});
try{
    const page=await browser.newPage({viewport:{width:1920,height:1080}});const errors=[],external=[];
    page.on('pageerror',e=>errors.push(e.message));
    await page.route('**/*',route=>{if(new URL(route.request().url()).origin!==origin){external.push(new URL(route.request().url()).hostname);return route.abort();}return route.continue();});
    await page.goto(origin);
    await page.waitForFunction(()=>{const v=document.querySelector('#intro');return v.videoWidth===1920&&!v.paused&&v.currentTime>.25&&document.body.classList.contains('video-ready');});
    assert.equal(await page.locator('header img').evaluate(el=>el.naturalWidth),96);
    const media=await page.locator('#intro').evaluate(v=>({width:v.videoWidth,height:v.videoHeight,playing:!v.paused,error:v.error?.code??null,local:new URL(v.currentSrc).origin===location.origin,codecSupported:!!v.canPlayType('video/webm; codecs="vp9,opus"')}));
    assert.equal(media.error,null);assert.equal(media.local,true);assert.equal(media.codecSupported,true);
    await page.evaluate(()=>window.postMessage({eventName:'loadProgress',loadFraction:.55},'*'));
    await page.waitForFunction(()=>document.querySelector('#progress').getAttribute('aria-valuenow')==='55');
    await page.evaluate(()=>{window.postMessage({eventName:'loadProgress',loadFraction:.1},'*');window.postMessage({eventName:'loadProgress',loadFraction:'invalid'},'*');});
    assert.equal(await page.locator('#percentage').textContent(),'55%');
    await page.locator('#sound').click();assert.equal(await page.locator('#intro').evaluate(v=>v.muted),false);
    await page.locator('#sound').click();assert.equal(await page.locator('#intro').evaluate(v=>v.muted),true);
    await page.screenshot({path:join(output,'loading-video.png')});
    await page.locator('#intro').evaluate(v=>{v.src='assets/not-present.webm';v.load();});
    await page.waitForFunction(()=>!document.body.classList.contains('video-ready'));
    assert.equal(await page.locator('.fallback img').evaluate(el=>el.naturalWidth),96);
    await page.screenshot({path:join(output,'loading-fallback.png')});
    assert.deepEqual(errors,[]);assert.deepEqual(external,[],'loading must work without remote requests');
    const hudPage=await browser.newPage({viewport:{width:1920,height:1080}});
    // Fonts and legacy RPC are outside this logo-rendering check.
    await hudPage.route('**/*',route=>new URL(route.request().url()).origin===origin?route.continue():route.abort());
    await hudPage.goto(origin+'/hud/index.html');
    await hudPage.waitForFunction(()=>{const img=document.querySelector('img.logo');return img?.complete&&img.naturalWidth>0;});
    const hudLogo=await hudPage.locator('img.logo').evaluate(el=>({width:el.naturalWidth,height:el.naturalHeight,source:el.getAttribute('src')}));
    assert.equal(hudLogo.width,hudImage.readUInt32BE(16));assert.equal(hudLogo.height,hudImage.readUInt32BE(20));
    await hudPage.screenshot({path:join(output,'hud-logo.png')});
    const report={synthetic:true,gta:false,logosVerified:logos.length,hudHash,iconHash,media,hudLogo,fallback:true,progress:true,externalRequests:external,browserErrors:errors};
    await writeFile(join(output,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report));
}finally{await browser.close();await new Promise(done=>server.close(done));}
