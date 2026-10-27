const app=document.getElementById('app');
const title=document.getElementById('title');
const views=[...document.querySelectorAll('.view')];
let state={mode:null,channels:[],models:[]};
const post=(name,data={})=>fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json; charset=UTF-8'},body:JSON.stringify(data)}).catch(()=>{});
function showView(id,newTitle){views.forEach(v=>v.classList.add('hidden'));document.getElementById(id).classList.remove('hidden');if(newTitle)title.textContent=newTitle}
function open(){app.classList.remove('hidden');app.setAttribute('aria-hidden','false')}
function close(){app.classList.add('hidden');app.setAttribute('aria-hidden','true');views.forEach(v=>v.classList.add('hidden'))}
function renderChannels(){const list=document.getElementById('channelList');list.innerHTML='';if(!state.channels?.length){list.innerHTML='<div class="empty">Nenhum canal disponível.</div>';return}state.channels.forEach(ch=>{const b=document.createElement('button');if(ch.active)b.classList.add('active');b.innerHTML=`<span>Canal #${ch.index} · ${escapeHtml(ch.name||'Canal')}</span><small>${ch.active?'ATUAL':'ASSISTIR'}</small>`;b.onclick=()=>post('selectChannel',{index:ch.index});list.appendChild(b)})}
function renderModels(){const list=document.getElementById('modelList');list.innerHTML='';(state.models||[]).forEach(m=>{const b=document.createElement('button');b.innerHTML=`<span>${escapeHtml(m.label||'TV')}</span><small>SELECIONAR</small>`;b.onclick=()=>post('selectModel',{model:m.model});list.appendChild(b)})}
function escapeHtml(s){return String(s).replace(/[&<>'"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]))}
window.addEventListener('message',e=>{const d=e.data||{};if(d.action==='openTV'){state.mode='tv';state.channels=d.channels||[];document.getElementById('volumeRange').value=d.volume??50;document.getElementById('volumeValue').textContent=`${d.volume??50}%`;renderChannels();showView('tvView','Televisão');open()}else if(d.action==='openBroadcast'){state.mode='broadcast';showView('broadcastView','Transmissão');const active=!!d.activeChannel;document.getElementById('broadcastInactive').classList.toggle('hidden',active);document.getElementById('broadcastActive').classList.toggle('hidden',!active);if(active){document.getElementById('broadcastChannelName').textContent=d.activeChannel.name||'Canal';document.getElementById('broadcastChannelIndex').textContent=`Canal #${d.activeIndex}`}open()}else if(d.action==='openModels'){state.mode='models';state.models=d.models||[];renderModels();showView('modelsView','Adicionar TV');open()}else if(d.action==='close'){close()}else if(d.action==='copyText'&&d.text){navigator.clipboard?.writeText(d.text).catch(()=>{const t=document.createElement('textarea');t.value=d.text;document.body.appendChild(t);t.select();document.execCommand('copy');t.remove()})}});
document.getElementById('closeBtn').onclick=()=>post('close');
document.querySelectorAll('[data-page]').forEach(b=>b.onclick=()=>{const p=b.dataset.page;showView(`${p}View`,p==='media'?'Reproduzir mídia':p==='browser'?'Navegador':p==='channels'?'Canais':'Volume')});
document.querySelectorAll('.backBtn').forEach(b=>b.onclick=()=>showView('tvView','Televisão'));
document.getElementById('playMediaBtn').onclick=()=>{const url=document.getElementById('mediaUrl').value.trim();if(url)post('playMedia',{url})};
document.getElementById('openBrowserBtn').onclick=()=>{const url=document.getElementById('browserUrl').value.trim();if(url)post('openBrowser',{url})};
document.getElementById('interactBtn').onclick=()=>post('interact');
document.getElementById('offBtn').onclick=()=>post('turnOff');
const vr=document.getElementById('volumeRange');vr.oninput=()=>{document.getElementById('volumeValue').textContent=`${vr.value}%`;post('setVolume',{volume:Number(vr.value)})};
document.getElementById('startBroadcastBtn').onclick=()=>{const name=document.getElementById('broadcastName').value.trim(),url=document.getElementById('broadcastUrl').value.trim();if(name&&url)post('startBroadcast',{name,url})};
document.getElementById('stopBroadcastBtn').onclick=()=>post('stopBroadcast');
window.addEventListener('keydown',e=>{if(e.key==='Escape'&&!app.classList.contains('hidden'))post('close')});
