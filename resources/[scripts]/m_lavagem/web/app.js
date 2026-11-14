const $=id=>document.getElementById(id);let mode='worker',data={},tab='lavagem',faction='vanilla',draft={},amount=100000,depositAmount=100000,locationMode='current',notice='';
const money=n=>'R$ '+Math.floor(Number(n)||0).toLocaleString('pt-BR');
const num=n=>Number(n)||0;
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const post=(action,other={})=>fetch(`https://${GetParentResourceName()}/action`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action,...other})}).then(r=>r.json());
const close=()=>{fetch(`https://${GetParentResourceName()}/close`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}).catch(()=>{});$('panel').classList.add('hidden')};
$('close').onclick=close;document.addEventListener('keydown',e=>{if(e.key==='Escape')close()});
window.addEventListener('message',e=>{const m=e.data;if(m.type==='close'){$('panel').classList.add('hidden');return}if(m.type==='open'){mode=m.mode;data=m.payload||{};notice='';if(mode==='admin'){draft=structuredClone(data.factions||{});faction=Object.keys(draft)[0]||'vanilla';tab='lavagem'}else{const same=mode==='worker'&&faction===data.faction;faction=data.faction;if(!same)tab='lavagem'}$('panel').classList.remove('hidden');render()}});
const field=(label,value,id,type='text')=>`<div class="field"><label for="${id}">${label}</label><input id="${id}" type="${type}" value="${esc(value)}"></div>`;
function render(){
 $('heading').textContent=mode==='admin'?'Sprint Wash Admin':'Sprint Wash';$('subtitle').textContent=mode==='admin'?'Central de gerenciamento':'Sistema de Lavagem';
 if(mode==='worker'){if(tab==='bau'){renderWorkerVault();return}renderWorker();return}if(mode==='vault'){renderVault();return}renderAdmin();
}
function renderWorker(){const fee=num(data.fee),bleach=num(data.perBleach),n=Math.max(0,Math.floor(num(amount))),need=bleach>0?Math.ceil(n/bleach):0,dirty=num(data.dirty),stock=num(data.bleach);$('app').innerHTML=`<div class="tabs"><button id="workerWashTab" class="active">Lavagem</button><button id="workerVaultTab">Baú da lavagem</button></div><div class="stats"><div class="stat"><small>Dinheiro sujo em fila</small><strong>${money(dirty)}</strong></div><div class="stat"><small>Taxa da facção</small><strong>${fee}%</strong></div><div class="stat"><small>Alvejante</small><strong>${stock.toLocaleString('pt-BR')}</strong></div></div><div class="box"><h3>Depositar dinheiro sujo</h3>${field('Quantidade para depositar',depositAmount,'deposit','number')}<button class="button secondary" id="depositBtn">DEPOSITAR DINHEIRO SUJO</button></div><div class="field"><label>Quantidade para lavar</label><input id="amount" type="number" min="1" value="${n}"></div><div class="box"><div class="row"><b>Alvejante necessário</b><b class="${need>stock?'red':''}">${need.toLocaleString('pt-BR')} un.</b></div><small>1 alvejante lava ${money(bleach)} de dinheiro sujo.</small></div><div class="summary"><h3>▣ Detalhes da transação</h3><div class="row"><span class="muted">Valor inserido</span><b>${money(n)}</b></div><div class="row"><span class="muted">Comissão para baú ${esc(data.label)} (${fee}%)</span><b class="red">${money(n*fee/100)}</b></div><div class="row"><span class="muted">Alvejantes consumidos</span><b>${need} un.</b></div><hr><div class="row"><b>Notas limpas para entregar ao cliente</b><b class="green">${money(n-Math.floor(n*fee/100))}</b></div></div><button class="button" id="wash" ${!data.canWash||n<1||n>dirty||need>stock?'disabled':''}>${data.canWash?'LAVAR DINHEIRO':'SOMENTE FUNCIONÁRIOS PODEM LAVAR'}</button><button class="button secondary" id="refresh">ATUALIZAR</button>${notice?`<p class="message">${esc(notice)}</p>`:''}`;
 $('workerVaultTab').onclick=()=>{tab='bau';render()};$('amount').oninput=e=>{amount=e.target.value;renderWorker();$('amount').focus()};$('deposit').onchange=e=>depositAmount=e.target.value;
 $('depositBtn').onclick=()=>{depositAmount=$('deposit').value;post('deposit',{faction:data.faction,amount:Number(depositAmount)})};$('wash').onclick=()=>post('wash',{faction:data.faction,amount:Number(amount)});$('refresh').onclick=()=>post('refreshWorker',{faction:data.faction});
}
function renderWorkerVault(){
 const allowed=Boolean(data.canVault);
 $('app').innerHTML=`<div class="tabs"><button id="workerWashTab">Lavagem</button><button id="workerVaultTab" class="active">Baú da lavagem</button></div>
 <div class="summary"><h3>▣ Baú da lavagem</h3><small>Total retido das comissões da lavagem</small><h1 class="green">${money(data.vaultBalance)}</h1>
 <hr><div class="row"><span class="muted">Organização</span><b>${esc(data.label)}</b></div>
 <div class="row"><span class="muted">Permissão para sacar</span><b class="${allowed?'green':'red'}">${allowed?'Autorizado':'Restrito'}</b></div></div>
 <div class="box"><h3>Segurança do cofre</h3><small>Todos os funcionários autorizados podem consultar o saldo. Apenas líderes e cargos autorizados no /lavagemadmin podem sacar.</small></div>
 ${allowed?'<button class="button" id="workerOpenVault">ABRIR COFRE / SACAR</button>':'<div class="box"><b>🔒 Saque bloqueado</b><p class="muted">Seu cargo não pode retirar valores deste cofre.</p></div>'}
 <button class="button secondary" id="workerRefreshVault">ATUALIZAR SALDO</button>`;
 $('workerWashTab').onclick=()=>{tab='lavagem';render()};
 if(allowed)$('workerOpenVault').onclick=()=>post('openVault',{faction:data.faction});
 $('workerRefreshVault').onclick=()=>post('refreshWorker',{faction:data.faction});
}
function renderAdmin(){const f=draft[faction];if(!f)return;$('app').innerHTML=`<div class="stats"><div class="stat"><small>Facções</small><strong>2</strong></div><div class="stat"><small>Comissão</small><strong>${num(f.fee)}%</strong></div><div class="stat"><small>Status</small><strong class="${f.enabled?'green':'red'}">${f.enabled?'Ativo':'Inativo'}</strong></div></div><div class="factions">${Object.keys(draft).map(k=>`<button data-fac="${k}" class="${k===faction?'active':''}">${esc(draft[k].label||k)}</button>`).join('')}</div><div class="tabs"><button data-tab="lavagem" class="${tab==='lavagem'?'active':''}">Lavagem</button><button data-tab="local" class="${tab==='local'?'active':''}">Localização</button><button data-tab="bau" class="${tab==='bau'?'active':''}">Baú da lavagem</button></div><section id="content"></section><button class="button" id="save">SALVAR CONFIGURAÇÕES</button>${notice?`<p class="message">${esc(notice)}</p>`:''}`;
 document.querySelectorAll('[data-fac]').forEach(b=>b.onclick=()=>{faction=b.dataset.fac;notice='';render()});document.querySelectorAll('[data-tab]').forEach(b=>b.onclick=()=>{tab=b.dataset.tab;notice='';render()});
 if(tab==='lavagem')renderGeneral(f);else if(tab==='local')renderLocation(f);else renderAdminVault();
 if($('save'))$('save').onclick=()=>{const v=draft[faction];if(!Number.isInteger(num(v.perBleach))||num(v.perBleach)<1||!v.name){notice='Confira os valores e permissões.';render();return}post('saveFaction',{faction,config:v});notice='Solicitação enviada ao servidor.';render()};
}
function renderGeneral(f){$('content').innerHTML=`<h3 class="cyan">⚙ Configurações da lavagem</h3><div class="field"><label>Comissão para o baú da facção: <b id="feeText">${num(f.fee)}%</b></label><input id="fee" type="range" min="0" max="100" value="${num(f.fee)}"><small>Cliente recebe o restante.</small></div>${field('Dinheiro sujo lavado por 1 alvejante (R$)',f.perBleach,'perBleach','number')}<div class="box"><small>Permissão obrigatória de membro (fixa): <b>${esc(f.memberPermission)}</b></small></div>${renderRoleControls(f,'wash')}<div class="row"><span>Sistema habilitado</span><input class="toggle" id="enabled" type="checkbox" ${f.enabled?'checked':''}></div><div class="summary"><h3>▣ Simulador</h3>${field('Valor para simular',amount,'simulate','number')}<div class="row"><span>Alvejantes</span><b id="needed"></b></div><div class="row"><span>Baú da facção</span><b class="cyan" id="commission"></b></div><div class="row"><span>Cliente</span><b class="green" id="customer"></b></div></div>`;
 const calc=()=>{let n=Math.max(0,num($('simulate').value));$('needed').textContent=num(f.perBleach)>0?Math.ceil(n/num(f.perBleach)).toLocaleString('pt-BR'):'Inválido';$('commission').textContent=money(n*num(f.fee)/100);$('customer').textContent=money(n-Math.floor(n*num(f.fee)/100))};
 $('fee').oninput=e=>{f.fee=Number(e.target.value);$('feeText').textContent=f.fee+'%';calc()};$('perBleach').oninput=e=>{f.perBleach=e.target.value;calc()};bindRoleControls(f,'wash');$('enabled').onchange=e=>f.enabled=e.target.checked;$('simulate').oninput=e=>{amount=e.target.value;calc()};calc();
}
function renderLocation(f){const coords=f.coords||{x:'',y:'',z:''};$('content').innerHTML=`<h3 class="cyan">⌖ Localização da ${esc(f.label)}</h3><div class="modes"><button id="currentMode" class="${locationMode==='current'?'active':''}">Usar posição atual</button><button id="manualMode" class="${locationMode==='manual'?'active':''}">Inserir coordenadas</button></div><div id="position"></div>${field('Nome do blip no mapa',f.name,'name')}<div class="row"><span>Exibir blip no mapa</span><input id="blip" type="checkbox" class="toggle" ${f.blip?'checked':''}></div><div class="row"><span>Exibir marcador no chão</span><input id="marker" type="checkbox" class="toggle" ${f.marker?'checked':''}></div><div class="box"><small>Posição configurada</small><div id="currentCoords">${coords.x??'—'}, ${coords.y??'—'}, ${coords.z??'—'}</div></div>`;
 $('currentMode').onclick=()=>{locationMode='current';renderLocation(f)};$('manualMode').onclick=()=>{locationMode='manual';renderLocation(f)};
 const position=()=>{if(locationMode==='current'){$('position').innerHTML='<div class="box"><p>Vá até o ponto desejado dentro do FiveM e capture sua posição.</p><button class="button secondary" id="capture">CAPTURAR MINHA POSIÇÃO</button></div>';$('capture').onclick=async()=>{const r=await post('capture');if(r.coords){f.coords=r.coords;notice='Coordenadas capturadas. Clique em salvar.';render()}}}else{$('position').innerHTML=`<div class="coords">${['x','y','z'].map(k=>field(k.toUpperCase(),coords[k],'coord_'+k,'number')).join('')}</div>`;for(const k of ['x','y','z'])$('coord_'+k).oninput=e=>{f.coords=f.coords||{};f.coords[k]=e.target.value;$('currentCoords').textContent=`${f.coords.x||'—'}, ${f.coords.y||'—'}, ${f.coords.z||'—'}`}}};position();
 $('name').oninput=e=>f.name=e.target.value;$('blip').onchange=e=>f.blip=e.target.checked;$('marker').onchange=e=>f.marker=e.target.checked;
}
function renderHistory(){$('content').innerHTML=`<h3 class="cyan">Histórico das operações</h3><div class="history">${(data.history||[]).length?(data.history||[]).map(o=>`<div class="entry"><b>#${o.id} · ${esc(o.faction)}</b> · ${money(o.amount)} · funcionário ${o.employee} · baú ${money(o.commission)} · <span class="${o.status==='done'?'green':'red'}">${esc(o.status)}</span><br><small>Clientes: ${(o.payments||[]).map(p=>'ID '+p.userId).join(', ')}</small></div>`).join(''):'<p class="muted">Nenhuma operação registrada.</p>'}</div><button class="button secondary" id="refresh">ATUALIZAR HISTÓRICO</button>`;$('refresh').onclick=()=>post('refreshAdmin')}

function splitNames(value){return String(value||'').split(/[\\n,;]+/).map(x=>x.trim()).filter(Boolean)}
function renderAdminVault(){
 const f=draft[faction],v=(data.vaults||{})[faction]||{balance:0,withdrawals:[]};
 $('content').innerHTML=`<h3 class="cyan">▣ Cofre exclusivo da lavagem — ${esc(f.label)}</h3>
 <div class="summary"><small>Comissão retida (não entra no baú normal)</small><h2 class="green">${money(v.balance)}</h2>
 <small>Somente os cargos/permissões definidos abaixo, pertencentes à ${esc(f.label)}, poderão sacar.</small></div>
 ${renderRoleControls(f,'vault')}
 <div class="box"><h3>Últimos saques</h3>${(v.withdrawals||[]).slice(-10).reverse().map(x=>`<div class="entry">ID ${x.userId} · ${money(x.amount)} · ${esc(x.status)}</div>`).join('')||'<small>Nenhum saque</small>'}</div>
 <button class="button secondary" id="vaultRefresh">ATUALIZAR COFRE</button>`;
 $('vaultRefresh').onclick=()=>post('refreshAdmin');
 bindRoleControls(f,'vault');
}
function renderRoleControls(f,kind){
 const groups=f[kind+'Groups']||[],perms=f[kind+'Permissions']||[];
 const opts=(data.groups||[]).map(g=>`<option value="${esc(g)}"></option>`).join('');
 return `<div class="box"><h3>${kind==='wash'?'Cargos autorizados a lavar':'Cargos autorizados a abrir e sacar do cofre'}</h3>
 <small>O jogador também precisa ter a permissão de membro da organização: <b>${esc(f.memberPermission)}</b>. Uma permissão isolada de outra facção NÃO libera acesso.</small>
 <div class="field"><label>Pesquisar cargos da cidade (${(data.groups||[]).length} encontrados)</label><input list="allGroups" id="${kind}Pick" placeholder="Digite o nome exato do cargo"><datalist id="allGroups">${opts}</datalist></div>
 <button class="button secondary" id="${kind}Add">ADICIONAR CARGO</button>
 <div class="box">${groups.map((g,i)=>`<button class="button secondary" data-${kind}-remove="${i}">${esc(g)} ✕</button>`).join('')||'<small>Nenhum cargo</small>'}</div>
 <div class="field"><label>Permissões adicionais (uma por linha, OU com cargos)</label><textarea id="${kind}Perm" rows="3" style="width:100%;background:#111;color:white;border:1px solid #344;padding:10px">${esc(perms.join('\\n'))}</textarea></div></div>`;
}
function bindRoleControls(f,kind){
 $(`${kind}Add`).onclick=()=>{const g=$(`${kind}Pick`).value.trim();if(!(data.groups||[]).includes(g)){notice='Escolha um cargo existente na lista.';render();return}f[kind+'Groups']=f[kind+'Groups']||[];if(!f[kind+'Groups'].includes(g))f[kind+'Groups'].push(g);render()};
 document.querySelectorAll(`[data-${kind}-remove]`).forEach(b=>b.onclick=()=>{f[kind+'Groups'].splice(Number(b.dataset[kind+'Remove']),1);render()});
 $(`${kind}Perm`).onchange=e=>f[kind+'Permissions']=splitNames(e.target.value);
}
function renderVault(){
 $('app').innerHTML=`<div class="summary"><h3>▣ Cofre da lavagem — ${esc(data.label)}</h3><small>Total retido das comissões da lavagem</small><h1 class="green">${money(data.balance)}</h1></div>
 ${field('Quantidade para sacar',1000,'vaultAmount','number')}
 ${data.canWithdraw?'<button class="button" id="vaultWithdraw">SACAR DINHEIRO LIMPO</button>':'<div class="box">Saque restrito aos cargos autorizados.</div>'}
 <button class="button secondary" id="vaultRefresh">ATUALIZAR</button>
 <div class="box"><h3>Saques recentes</h3>${(data.withdrawals||[]).slice(-15).reverse().map(x=>`<div class="entry">ID ${x.userId} · ${money(x.amount)} · ${esc(x.status)}</div>`).join('')||'<small>Nenhum saque</small>'}</div>`;
 if(data.canWithdraw)$('vaultWithdraw').onclick=()=>post('withdrawVault',{faction:data.faction,amount:Number($('vaultAmount').value)});
 $('vaultRefresh').onclick=()=>post('openVault',{faction:data.faction});
}
