(() => {
  'use strict';
  const root = document.createElement('section');
  root.id = 'deluxe-showroom';
  root.setAttribute('aria-label', 'Concessionária LuxuryMotors');
  root.innerHTML = `
    <div class="dlx-panel" role="dialog" aria-modal="true" aria-label="Showroom LuxuryMotors" style="position:relative">
      <header class="dlx-header">
        <div class="dlx-brand"><div class="dlx-monogram"><span>LM</span></div><div><strong>LUXURY MOTORS</strong><small>INTERIOR CITY · AUTOMOTIVE</small></div></div>
        <span class="dlx-header-note">Uma nova experiência ao dirigir</span>
        <span class="dlx-diamonds" role="status">◆ <span class="dlx-balance">—</span> diamantes</span>
        <button class="dlx-close" data-action="close" aria-label="Fechar concessionária">×</button>
      </header>
      <div class="dlx-toolbar"><nav class="dlx-tabs" aria-label="Categorias"></nav>
        <button class="dlx-secondary dlx-add-vehicle" data-action="add-vehicle" hidden>+ Adicionar veículo</button>
        <button class="dlx-secondary dlx-remove-vehicle" data-action="remove-vehicle" hidden disabled>− Remover veículo</button>
        <button class="dlx-secondary dlx-edit-vehicle" data-action="edit-vehicle" hidden disabled>Editar veículo / preço</button>
        <label class="dlx-search"><span aria-hidden="true">⌕</span><input type="search" placeholder="Buscar veículo" aria-label="Buscar veículo"></label>
      </div>
      <div class="dlx-content">
        <div class="dlx-detail">
          <p class="dlx-eyebrow">O próximo capítulo começa aqui</p><h1 class="dlx-name">Seu próximo destino.</h1><span class="dlx-model">LUXURYMOTORS COLLECTION</span>
          <div class="dlx-stage"><img class="dlx-hero-image" src="./default_vehicle.webp" alt=""></div>
          <div class="dlx-specs"></div>
          <div class="dlx-order"><div class="dlx-price"><small>VALOR DO VEÍCULO</small><strong>—</strong></div>
            <div class="dlx-paint"><span>Cor</span>${['#eeeeeb','#222427','#a29b8e','#8e1e1e','#183d67'].map(color => `<button data-color="${color}" style="background:${color}" aria-label="Cor ${color}"></button>`).join('')}<input type="color" value="#eeeeeb" aria-label="Escolher cor personalizada"></div>
          </div>
          <div class="dlx-actions"><button class="dlx-primary" data-action="purchase" disabled>Adquirir veículo ↗</button><button class="dlx-secondary" data-action="test" disabled>Test-drive</button></div>
        </div>
        <div class="dlx-catalog"><div class="dlx-list-heading"><h2>Destaques da coleção</h2><span class="dlx-count"></span></div><div class="dlx-grid" aria-live="polite"></div></div>
      </div>
      <footer class="dlx-footer"><span><kbd>ESC</kbd> Fechar showroom</span><span class="dlx-status" role="status"></span><span>DELUXE · ESCOLHAS EXTRAORDINÁRIAS</span></footer>
      <div class="dlx-modal" hidden><div class="dlx-dialog" role="alertdialog" aria-modal="true" aria-labelledby="dlx-confirm-title"><p class="dlx-eyebrow">LuxuryMotors Automotive</p><h3 id="dlx-confirm-title">Confirmar compra</h3><p class="dlx-confirm-description"></p><div class="dlx-actions"><button class="dlx-secondary" data-action="cancel">Voltar</button><button class="dlx-primary" data-action="confirm">Confirmar</button></div></div></div>
    </div>`;
  document.body.appendChild(root);
  const showroomCategories = [
    {id:'vips', label:'Carros VIPs'}, {id:'exclusivos', label:'Carros exclusivos'},
    {id:'brasileiros', label:'Brasileiros'}, {id:'som', label:'Carros rebaixados com som'}, {id:'motos', label:'Motos'},
    {id:'blindados', label:'Carros blindados'}
  ];
  const editor = document.createElement('div');
  editor.className = 'dlx-modal dlx-editor'; editor.hidden = true;
  editor.innerHTML = `<form class="dlx-dialog dlx-editor-form" aria-label="Adicionar veículo">
    <h3>Adicionar veículo</h3><p>Escolha um modelo instalado na cidade e a categoria em que ele será vendido.</p>
    <input name="mode" type="hidden" value="add">
    <label>Buscar nos veículos personalizados<input class="dlx-addon-search" type="search" placeholder="Nome ou spawn do veículo" autocomplete="off"></label>
    <div class="dlx-addon-count" role="status"></div><div class="dlx-addon-grid" aria-label="Veículos personalizados instalados"></div>
    <label>Modelo selecionado<input name="spawn" required readonly maxlength="80" placeholder="Selecione um veículo na galeria" autocomplete="off"></label>
    <label>Nome que aparece na loja<input name="name" required maxlength="80" placeholder="Ex.: Volkswagen Gol Quadrado"></label>
    <div class="dlx-form-row"><label>Preço (R$)<input name="price" type="number" min="0" max="1000000000000" step="1" required></label>
    <label>Porta-malas (kg)<input name="trunk" type="number" min="0" max="100000" step="1" required></label></div>
    <div class="dlx-form-row"><label>Moeda de venda<select name="currency"><option value="cash">Dinheiro da cidade (R$)</option><option value="diamonds">Diamantes (◆)</option></select></label>
    <label class="dlx-diamond-field" hidden>Preço em diamantes<input name="diamondPrice" type="number" min="1" max="1000000000" step="1" disabled></label></div>
    <div class="dlx-form-row"><label>Categoria<select name="category">${showroomCategories.map(c=>`<option value="${c.id}">${c.label}</option>`).join('')}</select></label>
    <label>Estoque disponível<input name="stock" type="number" min="0" max="10000" step="1" value="1" required></label></div>
    <p class="dlx-editor-note">Personalize o nome nesta loja sem alterar o spawn. Valor em R$ e porta-malas já cadastrados são mantidos.</p>
    <p class="dlx-editor-status" role="status"></p><div class="dlx-actions"><button type="button" class="dlx-secondary" data-action="cancel-add">Cancelar</button><button type="submit" class="dlx-primary">Salvar veículo</button></div>
  </form>`;
  root.querySelector('.dlx-panel').appendChild(editor);
  const $ = selector => root.querySelector(selector);
  const preview = document.createElement('div');
  preview.className='dlx-preview-tools'; preview.hidden=true;
  preview.innerHTML=`<strong class="dlx-preview-name"></strong><span>Prévia 3D · Escolha a cor do veículo</span><div class="dlx-paint">${['#eeeeeb','#222427','#a29b8e','#8e1e1e','#183d67'].map(color=>`<button type="button" data-color="${color}" style="background:${color}" aria-label="Cor ${color}"></button>`).join('')}<input type="color" value="#eeeeeb" aria-label="Cor personalizada da prévia"></div><div class="dlx-actions"><button class="dlx-secondary" data-action="rotate-left">↶ Girar</button><button class="dlx-secondary" data-action="rotate-right">Girar ↷</button><button class="dlx-primary" data-action="back-preview">Voltar à loja</button></div><p class="dlx-preview-status" role="status"></p>`;
  $('.dlx-panel').appendChild(preview);
  let previewOpen=false, previewVersion=0;
  function endPreview() {
    previewVersion++; previewOpen=false; preview.hidden=true; root.classList.remove('dlx-preview-mode');
    request('STOP_PREVIEW').catch(()=>{});
  }
  async function showColor() {
    if (!state.selected || state.busy) return;
    const version=++previewVersion;
    previewOpen=true; preview.hidden=false; root.classList.add('dlx-preview-mode');
    preview.querySelector('.dlx-preview-name').textContent=state.selected.name;
    preview.querySelector('input').value=state.color;
    preview.querySelector('.dlx-preview-status').textContent='Carregando veículo…';
    try {
      const response=await request('PREVIEW_VEHICLE',{spawn:state.selected.spawn,color:state.color});
      if(version!==previewVersion)return;
      preview.querySelector('.dlx-preview-status').textContent=response?.ok ? '' : response?.message || 'Não foi possível abrir a prévia.';
    } catch(error) { if(version===previewVersion)preview.querySelector('.dlx-preview-status').textContent=error.message; }
  }
  const esc = value => String(value ?? '').replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
  const money = value => Number(value || 0).toLocaleString('pt-BR', {style:'currency',currency:'BRL',maximumFractionDigits:0});
  const priceLabel = vehicle => vehicle?.currency === 'diamonds' ? `◆ ${Number(vehicle.diamondPrice || 0).toLocaleString('pt-BR')} diamantes` : money(vehicle?.value);
  const state = {open:false, busy:false, category:'vips', query:'', vehicles:[], owned:[], featured:[], categories:[], selected:null, color:'#eeeeeb', testDriveEnabled:false, generation:0, canManage:false, catalog:{}};
  let visible = [];
  let confirmation = {mode:'buy',spawn:null};

  async function request(route, data = {}) {
    if (typeof GetParentResourceName !== 'function') throw new Error('Conexão com a cidade indisponível.');
    const response = await fetch(`https://${GetParentResourceName()}/${route}`, {
      method:'POST', headers:{'Content-Type':'application/json; charset=UTF-8'}, body:JSON.stringify(data)
    });
    if (!response.ok) throw new Error('Não foi possível comunicar com a concessionária.');
    return response.json();
  }
  function status(message = '', error = false) {
    $('.dlx-status').textContent = message;
    $('.dlx-status').classList.toggle('error', error);
  }
  function imageFallback(event) {
    if (event.target.tagName !== 'IMG') return;
    const img = event.target;
    if (img.dataset.armored === '1') { img.style.visibility = 'hidden'; return; }
    if (img.dataset.fallback) { img.style.visibility = 'hidden'; return; }
    img.dataset.fallback = '1'; img.src = './default_vehicle.webp';
  }
  root.addEventListener('error', imageFallback, true);
  function setImage(img, vehicle) {
    delete img.dataset.fallback; img.style.visibility = '';
    img.dataset.armored = vehicle?.category === 'blindados' ? '1' : '0';
    if (img.dataset.armored === '1' && !vehicle.image) {
      img.removeAttribute('src');
      img.alt = '';
      img.style.visibility = 'hidden';
      return;
    }
    img.src = vehicle?.image || './default_vehicle.webp'; img.alt = vehicle?.name || 'Veículo';
  }
  function cardImage(vehicle) {
    const armored = vehicle.category === 'blindados';
    if (armored && !vehicle.image) return '<div class="dlx-card-image-empty" aria-hidden="true"></div>';
    return `<img src="${esc(vehicle.image || './default_vehicle.webp')}" alt="" loading="lazy"${armored ? ' data-armored="1"' : ''}>`;
  }
  function drawTabs() {
    const tabs = showroomCategories;
    $('.dlx-tabs').innerHTML = tabs.map(c => `<button class="dlx-tab ${c.id === state.category ? 'active' : ''}" data-category="${esc(c.id)}" aria-pressed="${c.id === state.category}">${esc(c.label)}</button>`).join('');
  }
  function list() {
    const vehicles = state.vehicles.filter(v => v.category === state.category);
    const query = state.query.trim().toLocaleLowerCase('pt-BR');
    return vehicles.filter(v => String(v.name || v.spawn).toLocaleLowerCase('pt-BR').includes(query));
  }
  function drawDetail() {
    const vehicle = state.selected;
    $('.dlx-remove-vehicle').disabled = state.busy || !state.canManage || !vehicle;
    $('.dlx-edit-vehicle').disabled = state.busy || !state.canManage || !vehicle || !state.catalog[vehicle.spawn];
    const owned = state.category === 'meus-veiculos';
    $('.dlx-name').textContent = vehicle?.name || 'Seu próximo destino.';
    $('.dlx-model').textContent = vehicle?.spawn || 'LUXURYMOTORS COLLECTION';
    setImage($('.dlx-hero-image'), vehicle);
    $('.dlx-price strong').textContent = vehicle ? priceLabel(vehicle) : '—';
    const specs = [['Aceleração',vehicle?.acceleration],['Porta-malas',vehicle ? `${vehicle.trunk || 0} kg` : null],['Velocidade',vehicle ? `${vehicle.speed || 0} km/h` : null],['Assentos',vehicle?.seats]];
    $('.dlx-specs').innerHTML = specs.map(([title,value]) => `<div><small>${title}</small><strong>${esc(value ?? '—')}</strong></div>`).join('');
    const buy = $('[data-action="purchase"]');
    buy.textContent = state.busy ? 'Aguarde…' : owned ? 'Veículo na sua garagem' : 'Adquirir veículo ↗';
    buy.disabled = state.busy || !vehicle || owned || Number(vehicle.stock) <= 0;
    const test = $('[data-action="test"]');
    test.disabled = state.busy || !vehicle || owned || !state.testDriveEnabled;
    test.title = state.testDriveEnabled ? 'Experimentar este veículo' : 'Test-drive indisponível neste showroom';
    $('.dlx-paint').style.visibility = owned ? 'hidden' : 'visible';
    root.querySelectorAll('[data-color]').forEach(button => button.classList.toggle('active',button.dataset.color === state.color));
  }
  function draw() {
    visible = list();
    const selected = visible.find(v => v.spawn === state.selected?.spawn);
    state.selected = selected || visible[0] || null;
    $('.dlx-list-heading h2').textContent = state.query ? 'Resultados da busca' : state.category === 'featured' ? 'Destaques da coleção' : state.category === 'meus-veiculos' ? 'Sua garagem' : 'Explore a coleção';
    $('.dlx-count').textContent = `${visible.length} ${visible.length === 1 ? 'veículo' : 'veículos'}`;
    $('.dlx-grid').innerHTML = visible.length ? visible.map((v,index) => `<button class="dlx-card ${v.spawn === state.selected?.spawn ? 'selected' : ''}" data-vehicle="${index}" aria-label="Selecionar ${esc(v.name)}"><span class="dlx-card-stock">${state.category === 'meus-veiculos' ? 'NA SUA GARAGEM' : Number(v.stock) > 0 ? `${esc(v.stock)} DISPONÍVEIS` : 'SEM ESTOQUE'}</span>${cardImage(v)}<strong>${esc(v.name)}</strong><div class="dlx-card-bottom"><span>${priceLabel(v)}</span><span>↗</span></div></button>`).join('') : '<div class="dlx-empty">Nenhum veículo encontrado.<br>Experimente outra categoria ou busca.</div>';
    drawTabs(); drawDetail();
  }
  async function load() {
    const generation = ++state.generation;
    status('Carregando a coleção…');
    try {
      const [vehicles,categories,settings,permissions,balance] = await Promise.all([
        request('GET_VEHICLES'),request('GET_CATEGORIES'),request('DELUXE_SETTINGS'),request('SHOWROOM_EDITOR'),
        request('DIAMOND_BALANCE').catch(() => ({ok:false}))
      ]);
      if (!state.open || generation !== state.generation) return;
      state.vehicles = Array.isArray(vehicles) ? vehicles : [];
      if (!state.vehicles.some(v=>v.category===state.category) && !state.query && state.vehicles.length) state.category=state.vehicles[0].category;
      state.categories = Array.isArray(categories) ? categories : [];
      state.testDriveEnabled = settings?.testDriveEnabled === true;
      state.canManage = permissions?.canManage === true;
      state.catalog = state.canManage ? permissions.catalog || {} : {};
      $('.dlx-balance').textContent = balance?.ok ? Number(balance.balance || 0).toLocaleString('pt-BR') : 'indisponível';
      $('.dlx-add-vehicle').hidden = !state.canManage;
      $('.dlx-remove-vehicle').hidden = !state.canManage;
      $('.dlx-edit-vehicle').hidden = !state.canManage;
      status(); draw();
    } catch (error) { if (state.open && generation === state.generation) { status(error.message,true); draw(); } }
  }
  function hide() { endPreview(); state.open = false; state.generation++; root.style.display = 'none'; $('.dlx-modal').hidden = true; editor.hidden = true; }
  async function close() {
    try { await request('CLOSE'); hide(); } catch (error) { status(error.message,true); }
  }
  async function removeSelected() {
    if(state.busy || !state.canManage || !confirmation.spawn) return;
    const spawn=confirmation.spawn;
    state.busy=true; drawDetail();
    try {
      const response=await request('REMOVE_SHOWROOM_VEHICLE',{spawn});
      if(!response?.ok) throw new Error(response?.message || 'Não foi possível remover o veículo.');
      if(state.catalog[spawn]) {
        state.catalog[spawn] = {...state.catalog[spawn], inStore:false};
        delete state.catalog[spawn].category;
        delete state.catalog[spawn].stock;
      }
      state.vehicles = state.vehicles.filter(vehicle => vehicle.spawn !== spawn);
      drawAddons();
      $('.dlx-modal').hidden=true; state.selected=null;
      await load(); status(response.message || 'Veículo removido desta loja.');
    } catch(error) { $('.dlx-modal').hidden=true; status(error.message,true); }
    finally { state.busy=false; drawDetail(); }
  }
  async function act(action) {
    if (state.busy || !state.selected) return;
    state.busy = true; drawDetail();
    const selected = state.selected;
    const vehicle = {spawn:selected.spawn};
    const hex = state.color.slice(1);
    const color = `rgba(${parseInt(hex.slice(0,2),16)}, ${parseInt(hex.slice(2,4),16)}, ${parseInt(hex.slice(4,6),16)}, 1)`;
    try {
      const response = await request(action === 'test' ? 'TEST_DRIVE' : 'CAN_BUY', {vehicle,color});
      $('.dlx-modal').hidden = true;
      if (response?.ok !== true) { status(response?.message || 'Não foi possível concluir a operação.',true); return; }
      if (action === 'test') { hide(); return; }
      await load();
      status(`Compra concluída por ${priceLabel({...selected, value:response.price ?? selected.value, diamondPrice:response.price ?? selected.diamondPrice, currency:response.currency || (response.paymentMethod === 'diamonds' ? 'diamonds' : selected.currency)})}. Seu veículo está na garagem.`);
    } catch (error) { status(error.message,true); }
    finally { state.busy = false; if (state.open) drawDetail(); }
  }
  function drawAddons() {
    const query = editor.querySelector('.dlx-addon-search').value.trim().toLocaleLowerCase('pt-BR');
    const form = editor.querySelector('form');
    const entries = Object.entries(state.catalog).filter(([spawn, entry]) => `${spawn} ${entry.name}`.toLocaleLowerCase('pt-BR').includes(query))
      .sort((a,b) => String(a[1].name).localeCompare(String(b[1].name), 'pt-BR'));
    editor.querySelector('.dlx-addon-count').textContent = `${entries.length} veículos personalizados disponíveis`;
    editor.querySelector('.dlx-addon-grid').innerHTML = entries.length ? entries.map(([spawn,entry]) => `<button type="button" class="dlx-addon ${form.elements.spawn.value === spawn ? 'selected' : ''}" data-addon="${esc(spawn)}" aria-pressed="${form.elements.spawn.value === spawn}" ${entry.inStore?'disabled':''}><img src="${esc(entry.image || './default_vehicle.webp')}" alt="" loading="lazy"><strong>${esc(entry.name)}</strong><small>${esc(spawn)}</small>${entry.inStore?'<span class="dlx-added-label">Este veículo já foi adicionado ao painel</span>':''}</button>`).join('') : '<p>Nenhum veículo encontrado. Verifique se o pacote está iniciado.</p>';
  }
  function currencyFields() {
    const form = editor.querySelector('form');
    const diamonds = form.elements.currency.value === 'diamonds';
    editor.querySelector('.dlx-diamond-field').hidden = !diamonds;
    form.elements.diamondPrice.disabled = !diamonds;
    form.elements.diamondPrice.required = diamonds;
  }
  function chooseAddon(spawn) {
    const entry = state.catalog[spawn]; if (!entry) return;
    const form = editor.querySelector('form');
    form.elements.spawn.value = spawn;
    ['name','price','trunk'].forEach(key => { form.elements[key].readOnly = key !== 'name' && entry.registered === true; form.elements[key].value = entry[key] ?? ''; });
    form.elements.currency.value = entry.currency || 'cash';
    form.elements.diamondPrice.value = entry.diamondPrice || '';
    form.elements.stock.value = entry.stock ?? 1;
    form.elements.category.value = entry.category || state.category;
    editor.querySelector('.dlx-editor-status').textContent = '';
    currencyFields(); drawAddons();
  }
  root.addEventListener('click', async event => {
    const target = event.target.closest('button'); if (!target || target.disabled) return;
    if (target.dataset.action === 'close') { close(); return; }
    if (state.busy) return;
    if (target.dataset.action === 'back-preview') { endPreview(); return; }
    if (target.dataset.action === 'rotate-left' || target.dataset.action === 'rotate-right') { request('ROTATE_PREVIEW',{direction:target.dataset.action === 'rotate-left' ? -1 : 1}).catch(()=>{}); return; }
    if (target.dataset.addon) { chooseAddon(target.dataset.addon); return; }
    if (target.dataset.action === 'cancel-add') { editor.hidden = true; return; }
    if (target.dataset.action === 'remove-vehicle' && state.canManage && state.selected) {
      confirmation={mode:'remove',spawn:state.selected.spawn};
      $('#dlx-confirm-title').textContent='Remover veículo da loja';
      $('.dlx-confirm-description').textContent=`Remover ${state.selected.name} desta loja? Os veículos dos jogadores e os arquivos do modelo serão mantidos.`;
      $('[data-action="confirm"]').textContent='Remover veículo';
      $('.dlx-modal').hidden=false; $('[data-action="cancel"]').focus(); return;
    }
    if ((target.dataset.action === 'add-vehicle' || target.dataset.action === 'edit-vehicle') && state.canManage) {
      // The catalogue can change through removal or another admin panel while
      // this showroom stays open. Never open the gallery from a stale snapshot.
      const generation = state.generation;
      state.busy = true; drawDetail();
      try {
        const permissions = await request('SHOWROOM_EDITOR');
        if(!state.open || generation !== state.generation) return;
        if(permissions?.canManage !== true) throw new Error('Sem permissão para alterar veículos.');
        state.catalog = permissions.catalog || {};
      } catch(error) { status(error.message,true); return; }
      finally { state.busy = false; drawDetail(); }
      const form = editor.querySelector('form'); form.reset();
      const editing=target.dataset.action==='edit-vehicle';
      form.elements.mode.value=editing?'edit':'add';
      editor.querySelector('h3').textContent=editing?'Editar veículo':'Adicionar veículo';
      editor.querySelector('.dlx-addon-search').closest('label').hidden=editing;
      editor.querySelector('.dlx-addon-grid').hidden=editing;
      editor.querySelector('.dlx-addon-count').hidden=editing;
      ['name','price','trunk'].forEach(key => { form.elements[key].readOnly = false; });
      form.elements.category.value = state.category;
      editor.querySelector('.dlx-addon-search').value = '';
      currencyFields(); drawAddons();
      if(editing && state.selected)chooseAddon(state.selected.spawn);
      editor.querySelector('.dlx-editor-status').textContent = '';
      editor.hidden = false; (editing?form.elements.name:editor.querySelector('.dlx-addon-search')).focus(); return;
    }
    if (target.dataset.category) { state.category = target.dataset.category; state.selected = null; status(); draw(); }
    if (target.dataset.vehicle !== undefined) { state.selected = visible[Number(target.dataset.vehicle)]; draw(); }
    if (target.dataset.color) { state.color = target.dataset.color; $('.dlx-paint input').value = state.color; drawDetail(); showColor(); }
    if (target.dataset.action === 'purchase') {
      confirmation={mode:'buy',spawn:state.selected.spawn};
      $('#dlx-confirm-title').textContent='Confirmar compra';
      $('[data-action="confirm"]').textContent='Confirmar';
      $('.dlx-confirm-description').textContent = `Adquirir ${state.selected.name} por ${priceLabel(state.selected)}? ${state.selected.currency === 'diamonds' ? 'A compra libera o veículo por 30 dias. Ao vencer, renove na garagem pelo mesmo valor.' : 'O valor será debitado conforme as regras da concessionária.'}`;
      $('.dlx-modal').hidden = false; $('[data-action="confirm"]').focus();
    }
    if (target.dataset.action === 'cancel') $('.dlx-modal').hidden = true;
    if (target.dataset.action === 'confirm') { if(confirmation.mode==='remove') removeSelected(); else act('buy'); }
    if (target.dataset.action === 'test') act('test');
  });
  $('.dlx-search input').addEventListener('input', event => { state.query = event.target.value; draw(); });
  $('.dlx-paint input').addEventListener('input', event => { state.color = event.target.value; drawDetail(); showColor(); });
  preview.querySelector('input').addEventListener('input', event => { state.color=event.target.value; $('.dlx-paint input').value=state.color; drawDetail(); showColor(); });
  editor.querySelector('.dlx-addon-search').addEventListener('input', drawAddons);
  editor.querySelector('[name="currency"]').addEventListener('change', currencyFields);
  editor.querySelector('form').addEventListener('submit', async event => {
    event.preventDefault(); if(state.busy || !state.canManage) return;
    const form = event.target;
    if (!state.catalog[form.elements.spawn.value]) { editor.querySelector('.dlx-editor-status').textContent='Selecione um veículo na galeria.'; return; }
    if(form.elements.mode.value==='add' && state.catalog[form.elements.spawn.value].inStore){editor.querySelector('.dlx-editor-status').textContent='Este veículo já foi adicionado ao painel.';return;}
    const payload = Object.fromEntries(new FormData(form));
    state.busy = true; form.querySelector('[type="submit"]').disabled = true;
    try {
      const response = await request('ADD_SHOWROOM_VEHICLE', payload);
      if(!response?.ok) throw new Error(response?.message || 'Não foi possível cadastrar.');
      state.category = response.category; state.query=''; $('.dlx-search input').value='';
      await load(); editor.hidden=true; status(response.message || 'Veículo adicionado.');
    } catch(error) { editor.querySelector('.dlx-editor-status').textContent=error.message; }
    finally { state.busy=false; form.querySelector('[type="submit"]').disabled=false; drawDetail(); }
  });
  window.addEventListener('keydown', event => {
    if (!state.open) return;
    if (event.key === 'Escape') { event.preventDefault(); if(previewOpen) { endPreview(); } else if(!editor.hidden) { if(!state.busy) editor.hidden=true; } else if (!$('.dlx-modal').hidden && !state.busy) $('.dlx-modal').hidden = true; else close(); }
    if (event.key === 'Tab') {
      const container = previewOpen ? preview : !editor.hidden ? editor : $('.dlx-modal').hidden ? root : $('.dlx-modal');
      const controls = [...container.querySelectorAll('button:not(:disabled),input,select')].filter(el => el.getClientRects().length);
      const first = controls[0], last = controls[controls.length - 1];
      if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last?.focus(); }
      else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first?.focus(); }
    }
  });
  window.addEventListener('message', ({data}) => {
    if (data?.action === 'close' || data?.action === 'open') hide();
    if (data?.action === 'openDeluxe') {
      state.open = true; state.category = 'vips'; state.query = ''; state.selected = null; state.canManage=false; $('.dlx-add-vehicle').hidden=true; $('.dlx-remove-vehicle').hidden=true; $('.dlx-edit-vehicle').hidden=true;
      $('.dlx-search input').value = ''; root.style.display = 'flex'; draw(); load(); $('[data-action="close"]').focus();
    }
    if (data?.action === 'categoriesUpdated' && state.open) load();
    if (data?.action === 'diamondWallet' && state.open) $('.dlx-balance').textContent=data.data?.ok?Number(data.data.balance).toLocaleString('pt-BR'):'indisponível';
  });
})();
