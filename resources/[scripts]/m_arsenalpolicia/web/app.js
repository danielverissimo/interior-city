(() => {
  'use strict';
  const $ = selector => document.querySelector(selector);
  const root = $('#arsenal');
  const money = value => Number(value || 0).toLocaleString('pt-BR', {style:'currency',currency:'BRL',maximumFractionDigits:0});
  const labels = {todos:'Catálogo completo',armas:'Armas',municoes:'Munições',equipamentos:'Equipamentos'};
  const state = {open:false,busy:false,items:[],category:'todos',query:'',selected:null,canManage:false,canPurchase:false,money:0,location:null,editing:false,editId:null,editPrice:null,refreshPending:false,generation:0,management:{active:[],candidates:[]},manageTab:'active'};
  const esc = value => String(value ?? '').replace(/[&<>"']/g, c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const icon = category => {
    const shape = category === 'armas'
      ? '<path d="M8 39h26l9-7h57l6-5h23v12h-17l-9 7H78l-4 8H62l-3-8H48L34 60H22l8-16H8z"/><path d="M55 30h30v-7h12v7M104 31v-7h4v7M36 38v8M68 45v7" fill="none" stroke="currentColor" stroke-width="3"/>'
      : category === 'municoes'
      ? '<path d="M33 60V29l7-14 7 14v31zm27 0V24l7-14 7 14v36zm27 0V29l7-14 7 14v31z"/><path d="M33 48h14m13-4h14m13 4h14" stroke="#101315" stroke-width="3"/>'
      : '<path d="M51 12h13l5 9 5-9h13l5 13 13 8-8 28H41l-8-28 13-8z" fill="none" stroke="currentColor" stroke-width="3"/><path d="M51 29h35v12H51zm0 18h15v10H51zm21 0h14v10H72z" fill="currentColor" opacity=".5"/>';
    return `<svg viewBox="0 0 140 76" fill="currentColor" aria-hidden="true">${shape}</svg>`;
  };
  const art = item => item?.image
    ? `<img class="item-image" src="${esc(item.image)}" alt=""><span class="art-fallback" hidden>${icon(item.category)}</span>`
    : icon(item?.category || 'equipamentos');
  root.addEventListener('error',event=>{
    const img=event.target;
    if(img.tagName==='IMG' && img.classList.contains('item-image')){
      img.hidden=true;if(img.nextElementSibling)img.nextElementSibling.hidden=false;
    }
  },true);
  async function request(route, data={}) {
    const controller=new AbortController();const timeout=setTimeout(()=>controller.abort(),15000);
    try {
      const resource=typeof GetParentResourceName==='function'?GetParentResourceName():'m_arsenalpolicia';
      const response=await fetch(`https://${resource}/${route}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data),signal:controller.signal});
      if(!response.ok) throw Error('Falha de comunicação com o arsenal.');
      const result=await response.json();
      if(!result || typeof result!=='object') throw Error('Resposta inválida do arsenal.');
      return result;
    } catch(error) {
      throw Error(error.name==='AbortError'?'A resposta demorou. Confira sua mochila e saldo antes de tentar novamente.':error.message);
    } finally {clearTimeout(timeout);}
  }
  function status(text='',kind='') {$('#status').textContent=text;$('#status').className=kind;}
  function selected() {return state.items.find(item=>item.id===state.selected);}
  function quantity() {const item=selected();const value=Number($('#quantity').value);return item && Number.isInteger(value) && value>=1 && value<=item.maxQuantity ? value : null;}
  function apply(data) {
    const revision=Number(data.priceRevision)||0;
    if(revision<(state.priceRevision||0))return;
    state.priceRevision=revision;
    state.items=Array.isArray(data.items)?data.items:[];
    state.canManage=data.canManage===true;state.canPurchase=data.canPurchase===true;
    state.money=Number(data.money)||0;state.location=data.location;
    if(!selected()) state.selected=state.items[0]?.id || null;
    if(!state.canManage){state.editing=false;dismiss();}
    draw();
  }
  function draw() {
    $('#balance').textContent=money(state.money);
    $('.owner-tools').hidden=!state.canManage;
    $('#management-note').hidden=!state.editing;
    $('#manage-prices').classList.toggle('active',state.editing);
    document.querySelectorAll('[data-category]').forEach(button=>{
      const active=button.dataset.category===state.category;
      button.classList.toggle('active',active);button.setAttribute('aria-pressed',String(active));
    });
    Object.keys(labels).forEach(key=>{const count=key==='todos'?state.items.length:state.items.filter(item=>item.category===key).length;$(`[data-count="${key}"]`).textContent=count;});
    const query=state.query.toLocaleLowerCase('pt-BR');
    const visible=state.items.filter(item=>(state.category==='todos'||item.category===state.category)&&item.name.toLocaleLowerCase('pt-BR').includes(query));
    $('#category-title').textContent=state.query?'Resultados da busca':labels[state.category];
    $('#result-count').textContent=`${visible.length} ${visible.length===1?'item disponível':'itens disponíveis'}`;
    $('#catalog').innerHTML=visible.length ? visible.map(item=>`<button class="card ${state.selected===item.id?'selected':''}" data-item="${esc(item.id)}" aria-pressed="${state.selected===item.id}"><div class="card-top"><span>${esc(labels[item.category].toUpperCase())}</span><span>${state.editing?'EDITAR ↗':'◇'}</span></div><div class="card-art">${art(item)}</div><strong class="card-name">${esc(item.name)}</strong><div class="card-bottom"><span>${money(item.price)} <small>/ un.</small></span><span class="arrow">↗</span></div></button>`).join(''):'<div class="empty">Nenhum equipamento encontrado.</div>';
    drawDetail();
    $('#current-location').textContent=state.location?`X ${state.location.x.toFixed(2)}  ·  Y ${state.location.y.toFixed(2)}  ·  Z ${state.location.z.toFixed(2)}`:'Nenhum ponto definido';
  }
  function drawDetail() {
    const item=selected();
    $('#detail-art').innerHTML=art(item);
    $('#detail-name').textContent=item?.name || 'Selecione um equipamento';
    $('#detail-category').textContent=labels[item?.category] || 'CATÁLOGO';
    $('#detail-number').textContent=item?String(state.items.indexOf(item)+1).padStart(2,'0'):'—';
    $('#detail-description').textContent=item?.category==='municoes'?'Valor por munição individual. Escolha a quantidade que deseja receber na mochila.':item?.category==='armas'?'Arma entregue no inventário. Munições são adquiridas separadamente.':'Equipamento entregue no inventário após a confirmação do pagamento.';
    $('#unit-price').textContent=item?money(item.price):'—';
    $('#quantity').max=item?.maxQuantity || 1;
    const q=quantity(),total=q&&item?item.price*q:null;
    $('#total').textContent=total!==null?money(total):'—';
    $('#purchase').disabled=state.busy || !item || !q || !state.canPurchase || total>state.money;
    $('#quantity').disabled=state.busy || !item;
    $('#increase').disabled=state.busy || !item || (q || 1)>=item.maxQuantity;
    $('#decrease').disabled=state.busy || !item || (q || 1)<=1;
    $('#edit-price').hidden=!state.canManage || !item;
    $('#edit-price').disabled=state.busy;
    $('#purchase-note').textContent=!state.canPurchase?'Compras exigem permissão policial e presença no arsenal.':total>state.money?'Dinheiro em mãos insuficiente para esta compra.':'Pagamento com dinheiro em mãos. Sem retirada gratuita.';
    $('#relocate').disabled=state.busy;
    $('#clear-location').disabled=state.busy || !state.location;
    document.querySelectorAll('[data-toggle-item]').forEach(button=>button.disabled=state.busy);
    $('#price-form button[type="submit"]').disabled=state.busy;
  }
  async function refresh() {
    const generation=state.generation;
    const result=await request('refresh');
    if(!state.open || generation!==state.generation)return;
    if(result.ok)apply(result);else{status(result.message,'error');if(!state.canManage)close();}
  }
  async function action(fn) {
    if(state.busy)return;
    state.busy=true;drawDetail();
    try {await fn();} catch(error){status(error.message,'error');}
    finally {
      state.busy=false;drawDetail();
      if(state.refreshPending && state.open){state.refreshPending=false;refresh().catch(error=>status(error.message,'error'));}
    }
  }
  function dismiss() {$('#price-modal').hidden=true;$('#location-modal').hidden=true;$('#items-modal').hidden=true;state.editId=null;}
  function drawManagement() {
    const term=$('#manage-search').value.trim().toLocaleLowerCase('pt-BR');
    const rows=(state.management[state.manageTab] || []).filter(item=>(item.name+' '+item.id).toLocaleLowerCase('pt-BR').includes(term));
    document.querySelectorAll('[data-manage-tab]').forEach(button=>button.classList.toggle('active',button.dataset.manageTab===state.manageTab));
    $('#manage-list').innerHTML=rows.length?rows.map(item=>`<div class="manage-row"><div><strong>${esc(item.name)}</strong><small>${esc(labels[item.category] || 'Equipamentos')} · ${esc(item.id)}</small></div><button class="secondary" data-toggle-item="${esc(item.id)}" data-enabled="${state.manageTab!=='active'}" ${state.busy?'disabled':''}>${state.manageTab==='active'?'Retirar':'Adicionar'}</button></div>`).join(''):'<p class="empty">Nenhum item encontrado.</p>';
  }
  async function loadManagement() {
    const result=await request('management');
    if(!result.ok)throw Error(result.message || 'Não foi possível carregar os equipamentos.');
    state.management={active:Array.isArray(result.active)?result.active:[],candidates:Array.isArray(result.candidates)?result.candidates:[]};
    drawManagement();
  }
  function editPrice() {
    const item=selected();if(!state.canManage || !item || state.busy)return;
    state.editId=item.id;state.editPrice=item.price;
    $('#edit-name').textContent=item.name;$('#new-price').value=item.price;
    $('#price-modal').hidden=false;$('#new-price').focus();$('#new-price').select();
  }
  function close() {
    if(state.busy){status('Aguarde a conclusão da operação.');return;}
    state.open=false;state.generation++;root.hidden=true;dismiss();
    request('close').catch(()=>{});
  }
  $('#catalog').addEventListener('click',event=>{
    const button=event.target.closest('[data-item]');if(!button || state.busy)return;
    state.selected=button.dataset.item;$('#quantity').value=1;draw();status();
    if(state.editing)editPrice();
  });
  document.querySelectorAll('[data-category]').forEach(button=>button.addEventListener('click',()=>{state.category=button.dataset.category;draw();}));
  $('#search').addEventListener('input',event=>{state.query=event.target.value.trim();draw();});
  $('#quantity').addEventListener('input',drawDetail);
  $('#quantity').addEventListener('change',()=>{const item=selected();$('#quantity').value=Math.min(item?.maxQuantity || 1,Math.max(1,Math.floor(Number($('#quantity').value)||1)));drawDetail();});
  $('#increase').addEventListener('click',()=>{$('#quantity').value=Math.min(selected()?.maxQuantity || 1,(quantity()||1)+1);drawDetail();});
  $('#decrease').addEventListener('click',()=>{$('#quantity').value=Math.max(1,(quantity()||1)-1);drawDetail();});
  $('#close').addEventListener('click',close);
  $('#edit-price').addEventListener('click',editPrice);
  $('#manage-prices').addEventListener('click',()=>{if(!state.busy){state.editing=!state.editing;draw();}});
  $('#manage-location').addEventListener('click',()=>{if(state.canManage && !state.busy){$('#location-modal').hidden=false;$('#relocate').focus();}});
  $('#manage-items').addEventListener('click',()=>action(async()=>{
    if(!state.canManage)return;
    state.manageTab='active';$('#manage-search').value='';$('#manage-status').textContent='';
    await loadManagement();$('#items-modal').hidden=false;$('#manage-search').focus();
  }));
  document.querySelectorAll('[data-manage-tab]').forEach(button=>button.addEventListener('click',()=>{if(!state.busy){state.manageTab=button.dataset.manageTab;drawManagement();}}));
  $('#manage-search').addEventListener('input',drawManagement);
  $('#manage-list').addEventListener('click',event=>{
    const button=event.target.closest('[data-toggle-item]');if(!button || !state.canManage)return;
    action(async()=>{
      const result=await request('setItemEnabled',{id:button.dataset.toggleItem,enabled:button.dataset.enabled==='true'});
      $('#manage-status').textContent=result.message;status(result.message,result.ok?'success':'error');
      if(result.ok){await loadManagement();await refresh();}
    });
  });
  document.querySelectorAll('[data-dismiss]').forEach(button=>button.addEventListener('click',()=>{if(!state.busy)dismiss();}));
  $('#purchase').addEventListener('click',()=>action(async()=>{
    const item=selected(),q=quantity();if(!item || !q || !state.canPurchase)return;
    status('Processando sua compra...');
    const result=await request('purchase',{id:item.id,quantity:q,expectedPrice:item.price});
    if(result.money!==undefined)state.money=result.money;
    status(result.message,result.ok?'success':'error');
    await refresh();
  }));
  $('#price-form').addEventListener('submit',event=>{
    event.preventDefault();
    const value=Number($('#new-price').value);
    if(!Number.isInteger(value)||value<1||value>10000000){status('Informe um valor inteiro de R$ 1 a R$ 10.000.000.','error');return;}
    action(async()=>{
      const id=state.editId;
      const result=await request('setPrice',{id,price:value,expectedPrice:state.editPrice});
      status(result.message,result.ok?'success':'error');
      if(result.ok){
        const revision=Number(result.priceRevision)||0;
        if(revision>=(state.priceRevision||0)){
          const item=state.items.find(entry=>entry.id===id);
          if(item)item.price=result.price;
          state.priceRevision=revision;
        }
        dismiss();draw();await refresh();
      }
    });
  });
  $('#relocate').addEventListener('click',()=>action(async()=>{
    const result=await request('relocate');
    status(result.message,result.ok?'success':'error');
    if(result.ok){state.location=result.location;dismiss();await refresh();}
  }));
  $('#clear-location').addEventListener('click',()=>action(async()=>{
    const result=await request('clearLocation');
    status(result.message,result.ok?'success':'error');
    if(result.ok){state.location=false;await refresh();}
  }));
  window.addEventListener('message',({data})=>{
    if(data?.action==='open'){
      state.open=true;state.generation++;state.category='todos';state.query='';state.editing=false;state.priceRevision=0;
      state.selected=null;$('#search').value='';$('#quantity').value=1;dismiss();apply(data.data || {});
      root.hidden=false;status('Selecione um equipamento para começar.');$('#search').focus();
      if(data.token!==undefined)request('visible',{token:data.token}).catch(()=>{state.open=false;root.hidden=true;});
    } else if(data?.action==='close'){
      state.open=false;state.generation++;state.busy=false;root.hidden=true;dismiss();
    } else if(data?.action==='location'){
      state.location=data.data;if(state.open){state.canPurchase=false;draw();state.refreshPending=true;if(!state.busy){state.refreshPending=false;refresh().catch(error=>status(error.message,'error'));}}
    } else if(data?.action==='refresh' && state.open){
      if(state.busy)state.refreshPending=true;else refresh().catch(error=>status(error.message,'error'));
    }
  });
  document.addEventListener('keydown',event=>{
    if(!state.open)return;
    if(event.key==='Escape'){event.preventDefault();if(!state.busy){if(!$('#price-modal').hidden || !$('#location-modal').hidden || !$('#items-modal').hidden)dismiss();else close();}}
    if(event.key==='Tab'){
      const container=!$('#price-modal').hidden?$('#price-modal'):!$('#location-modal').hidden?$('#location-modal'):!$('#items-modal').hidden?$('#items-modal'):root;
      const elements=[...container.querySelectorAll('button:not(:disabled),input:not(:disabled)')].filter(el=>el.getClientRects().length);
      if(!elements.length)return;
      const first=elements[0],last=elements[elements.length-1];
      if(event.shiftKey && document.activeElement===first){event.preventDefault();last.focus();}
      else if(!event.shiftKey && document.activeElement===last){event.preventDefault();first.focus();}
    }
  });
})();
