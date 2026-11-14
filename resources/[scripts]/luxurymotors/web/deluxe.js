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
        <button class="dlx-close" data-action="close" aria-label="Fechar concessionária">×</button>
      </header>
      <div class="dlx-toolbar"><nav class="dlx-tabs" aria-label="Categorias"></nav>
        <label class="dlx-search"><span aria-hidden="true">⌕</span><input type="search" placeholder="Encontre seu próximo carro" aria-label="Buscar veículo"></label>
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
  const $ = selector => root.querySelector(selector);
  const esc = value => String(value ?? '').replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
  const money = value => Number(value || 0).toLocaleString('pt-BR', {style:'currency',currency:'BRL',maximumFractionDigits:0});
  const state = {open:false, busy:false, category:'featured', query:'', vehicles:[], owned:[], featured:[], categories:[], selected:null, color:'#eeeeeb', testDriveEnabled:false, generation:0};
  let visible = [];

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
    if (img.dataset.fallback) { img.style.visibility = 'hidden'; return; }
    img.dataset.fallback = '1'; img.src = './default_vehicle.webp';
  }
  root.addEventListener('error', imageFallback, true);
  function setImage(img, vehicle) {
    delete img.dataset.fallback; img.style.visibility = '';
    img.src = vehicle?.image || './default_vehicle.webp'; img.alt = vehicle?.name || 'Veículo';
  }
  function drawTabs() {
    const tabs = [{id:'featured',label:'Destaques'}, ...state.categories.filter(c => c.id !== 'meus-veiculos'), {id:'meus-veiculos',label:'Meus carros'}];
    $('.dlx-tabs').innerHTML = tabs.map(c => `<button class="dlx-tab ${c.id === state.category ? 'active' : ''}" data-category="${esc(c.id)}" aria-pressed="${c.id === state.category}">${esc(c.label)}</button>`).join('');
  }
  function list() {
    let vehicles;
    if (state.category === 'meus-veiculos') vehicles = state.owned;
    else if (state.category === 'featured' && !state.query) vehicles = state.featured.length ? state.featured : state.vehicles.slice(0,4);
    else vehicles = state.category === 'featured' ? state.vehicles : state.vehicles.filter(v => v.category === state.category);
    const query = state.query.trim().toLocaleLowerCase('pt-BR');
    return vehicles.filter(v => String(v.name || v.spawn).toLocaleLowerCase('pt-BR').includes(query));
  }
  function drawDetail() {
    const vehicle = state.selected;
    const owned = state.category === 'meus-veiculos';
    $('.dlx-name').textContent = vehicle?.name || 'Seu próximo destino.';
    $('.dlx-model').textContent = vehicle?.spawn || 'LUXURYMOTORS COLLECTION';
    setImage($('.dlx-hero-image'), vehicle);
    $('.dlx-price strong').textContent = vehicle ? money(vehicle.value) : '—';
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
    $('.dlx-grid').innerHTML = visible.length ? visible.map((v,index) => `<button class="dlx-card ${v.spawn === state.selected?.spawn ? 'selected' : ''}" data-vehicle="${index}" aria-label="Selecionar ${esc(v.name)}"><span class="dlx-card-stock">${state.category === 'meus-veiculos' ? 'NA SUA GARAGEM' : Number(v.stock) > 0 ? `${esc(v.stock)} DISPONÍVEIS` : 'SEM ESTOQUE'}</span><img src="${esc(v.image || './default_vehicle.webp')}" alt="" loading="lazy"><strong>${esc(v.name)}</strong><div class="dlx-card-bottom"><span>${money(v.value)}</span><span>↗</span></div></button>`).join('') : '<div class="dlx-empty">Nenhum veículo encontrado.<br>Experimente outra categoria ou busca.</div>';
    drawTabs(); drawDetail();
  }
  async function load() {
    const generation = ++state.generation;
    status('Carregando a coleção…');
    try {
      const [vehicles,categories,featured,owned,settings] = await Promise.all([
        request('GET_VEHICLES'),request('GET_CATEGORIES'),request('GET_MOST_SOLD'),request('GET_MY_VEHICLES'),request('DELUXE_SETTINGS')
      ]);
      if (!state.open || generation !== state.generation) return;
      state.vehicles = Array.isArray(vehicles) ? vehicles : [];
      state.categories = Array.isArray(categories) ? categories : [];
      state.featured = Array.isArray(featured) ? featured.slice(0,4) : [];
      state.owned = Array.isArray(owned) ? owned : [];
      state.testDriveEnabled = settings?.testDriveEnabled === true;
      status(); draw();
    } catch (error) { if (state.open && generation === state.generation) { status(error.message,true); draw(); } }
  }
  function hide() { state.open = false; state.generation++; root.style.display = 'none'; $('.dlx-modal').hidden = true; }
  async function close() {
    try { await request('CLOSE'); hide(); } catch (error) { status(error.message,true); }
  }
  async function act(action) {
    if (state.busy || !state.selected) return;
    state.busy = true; drawDetail();
    const vehicle = {spawn:state.selected.spawn};
    const hex = state.color.slice(1);
    const color = `rgba(${parseInt(hex.slice(0,2),16)}, ${parseInt(hex.slice(2,4),16)}, ${parseInt(hex.slice(4,6),16)}, 1)`;
    try {
      const response = await request(action === 'test' ? 'TEST_DRIVE' : 'CAN_BUY', {vehicle,color});
      $('.dlx-modal').hidden = true;
      if (response?.ok !== true) { status(response?.message || 'Não foi possível concluir a operação.',true); return; }
      if (action === 'test') { hide(); return; }
      await load();
      status(`Compra concluída por ${money(response.price ?? state.selected?.value)}. Seu veículo está na garagem.`);
    } catch (error) { status(error.message,true); }
    finally { state.busy = false; if (state.open) drawDetail(); }
  }
  root.addEventListener('click', event => {
    const target = event.target.closest('button'); if (!target || target.disabled) return;
    if (target.dataset.action === 'close') { close(); return; }
    if (state.busy) return;
    if (target.dataset.category) { state.category = target.dataset.category; state.selected = null; status(); draw(); }
    if (target.dataset.vehicle !== undefined) { state.selected = visible[Number(target.dataset.vehicle)]; draw(); }
    if (target.dataset.color) { state.color = target.dataset.color; $('.dlx-paint input').value = state.color; drawDetail(); }
    if (target.dataset.action === 'purchase') {
      $('.dlx-confirm-description').textContent = `Adquirir ${state.selected.name} por ${money(state.selected.value)}? O valor será debitado conforme as regras da concessionária.`;
      $('.dlx-modal').hidden = false; $('[data-action="confirm"]').focus();
    }
    if (target.dataset.action === 'cancel') $('.dlx-modal').hidden = true;
    if (target.dataset.action === 'confirm') act('buy');
    if (target.dataset.action === 'test') act('test');
  });
  $('.dlx-search input').addEventListener('input', event => { state.query = event.target.value; draw(); });
  $('.dlx-paint input').addEventListener('input', event => { state.color = event.target.value; drawDetail(); });
  window.addEventListener('keydown', event => {
    if (!state.open) return;
    if (event.key === 'Escape') { event.preventDefault(); if (!$('.dlx-modal').hidden && !state.busy) $('.dlx-modal').hidden = true; else close(); }
    if (event.key === 'Tab') {
      const container = $('.dlx-modal').hidden ? root : $('.dlx-modal');
      const controls = [...container.querySelectorAll('button:not(:disabled),input')].filter(el => el.getClientRects().length);
      const first = controls[0], last = controls[controls.length - 1];
      if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last?.focus(); }
      else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first?.focus(); }
    }
  });
  window.addEventListener('message', ({data}) => {
    if (data?.action === 'close' || data?.action === 'open') hide();
    if (data?.action === 'openDeluxe') {
      state.open = true; state.category = 'featured'; state.query = ''; state.selected = null;
      $('.dlx-search input').value = ''; root.style.display = 'flex'; draw(); load(); $('[data-action="close"]').focus();
    }
    if (data?.action === 'categoriesUpdated' && state.open) load();
  });
})();
