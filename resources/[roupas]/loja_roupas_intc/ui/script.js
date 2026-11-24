'use strict';
(() => {
  const $ = id => document.getElementById(id);
  const preview = typeof GetParentResourceName !== 'function';
  const icon = '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M9 3 5 5l-3 4 4 3 2-2v11h8V10l2 2 4-3-3-4-4-2a3 3 0 0 1-6 0Z" stroke-linejoin="round"/></svg>';
  let uniforms = [], room = '', worn = null, pending = false, gender = 'feminino', editorData = [];
  const parts = [
    ['11','Jaqueta'], ['8','Camiseta'], ['3','Braços'], ['4','Calça'], ['6','Sapatos'],
    ['9','Colete'], ['7','Acessórios'], ['5','Mochila'], ['1','Máscara'], ['10','Decalques'],
    ['p0','Chapéu'], ['p1','Óculos'], ['p2','Brincos'], ['p6','Relógio'], ['p7','Pulseira'],
  ];

  function showStatus(message, error = false) {
    $('status').textContent = message;
    $('status').classList.toggle('error', error);
  }

  function render() {
    const groups = new Map();
    for (const entry of uniforms) {
      const key = room === 'MILITAR' ? entry.name : entry.index;
      if (!groups.has(key)) groups.set(key, []);
      const list = groups.get(key);
      if (!list.some(v => v.jacket === entry.jacket && v.texture === entry.texture)) list.push(entry);
    }
    $('count').textContent = `${groups.size} ${groups.size === 1 ? 'UNIFORME' : 'UNIFORMES'}`;
    const list = document.createDocumentFragment();
    for (const variants of groups.values()) {
      const selected = variants.find(entry => entry.index === worn);
      const card = document.createElement('article');
      card.className = selected ? 'uniform active' : 'uniform';
      const action = document.createElement('button');
      action.type = 'button'; action.className = 'wear'; action.disabled = pending;
      action.innerHTML = `<span class="glyph">${icon}</span><strong></strong><span class="action"></span>`;
      action.querySelector('strong').textContent = variants[0].name;
      action.querySelector('.action').textContent = selected ? 'Em uso' : 'Vestir ›';
      action.setAttribute('aria-pressed', String(Boolean(selected)));
      action.onclick = () => equip(selected || variants[0]);
      card.append(action);
      if (variants.length > 1) {
        const options = document.createElement('div');
        options.className = 'variants';
        for (const entry of variants) {
          const option = document.createElement('button');
          option.type = 'button'; option.className = 'variant'; option.disabled = pending;
          option.textContent = `Jaqueta ${entry.jacket}`;
          option.setAttribute('aria-pressed', String(entry.index === worn));
          option.onclick = () => equip(entry);
          options.append(option);
        }
        card.append(options);
      }
      list.append(card);
    }
    $('uniforms').replaceChildren(list);
    $('remove').disabled = pending;
  }

  async function request(route, body = {}) {
    if (preview) return route === 'getUniformEditor' ? demoEditor : true;
    const response = await fetch(`https://${GetParentResourceName()}/${route}`, {
      method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(body),
    });
    return response.ok ? response.json() : false;
  }

  function toggleEditor(open) {
    $('editor').hidden = !open;
    $('uniforms').hidden = open;
    $('remove').hidden = open;
  }

  function fillParts() {
    const outfit = editorData[Number($('editor-uniform').value) - 1]?.[$('editor-gender').value] || {};
    const fragment = document.createDocumentFragment();
    for (const [key, label] of parts) {
      const row = document.createElement('div');
      row.className = 'editor-part';
      const name = document.createElement('span'); name.textContent = label;
      row.append(name);
      for (const [index, field] of ['Modelo', 'Variação'].entries()) {
        const input = document.createElement('input');
        input.type = 'number'; input.step = '1';
        input.min = index === 0 && key.startsWith('p') ? '-1' : '0';
        input.max = index === 0 ? '9999' : '999';
        input.value = outfit[key]?.[index] ?? (index === 0 ? '' : 0);
        input.name = key + '-' + index;
        input.setAttribute('aria-label', `${label} · ${field}`);
        row.append(input);
      }
      fragment.append(row);
    }
    $('editor-parts').replaceChildren(fragment);
  }

  $('edit').onclick = async () => {
    if ($('edit').hidden || pending || !$('editor').hidden) return;
    $('edit').disabled = true;
    try {
      const list = await request('getUniformEditor');
      if (!Array.isArray(list) || !list.length) throw new Error();
      editorData = list;
      const counts = list.reduce((out, item) => out.set(item.name, (out.get(item.name) || 0) + 1), new Map());
      $('editor-uniform').replaceChildren(...list.map((item, i) => {
        const option = document.createElement('option');
        option.value = i + 1;
        const jacket = item.feminino?.['11']?.[0];
        option.textContent = counts.get(item.name) > 1 && jacket != null ? `${item.name} · Jaqueta ${jacket}` : item.name;
        return option;
      }));
      $('editor-uniform').value = worn || 1;
      $('editor-gender').value = gender;
      fillParts(); toggleEditor(true); showStatus('');
    } catch {
      showStatus('Editor indisponível. Apenas o cargo dono pode editar.', true);
    } finally { $('edit').disabled = false; }
  };
  $('editor-uniform').onchange = $('editor-gender').onchange = fillParts;
  $('editor-back').onclick = () => { if (!pending) toggleEditor(false); };
  $('editor').onsubmit = async event => {
    event.preventDefault();
    if (pending) return;
    const index = Number($('editor-uniform').value);
    const selectedGender = $('editor-gender').value;
    const values = {};
    for (const [key] of parts) {
      const model = $('editor').elements.namedItem(key + '-0').value;
      const texture = $('editor').elements.namedItem(key + '-1').value;
      if (model !== '') values[key] = [Number(model), Number(texture || 0)];
    }
    pending = true; $('editor-save').disabled = true;
    try {
      if (await request('saveUniformNumbers', {index, gender:selectedGender, values}) !== true) throw new Error();
      const uniform = editorData[index - 1];
      uniform[selectedGender] = {...uniform[selectedGender], ...values};
      const entry = uniforms.find(option => option.index === index);
      if (entry && selectedGender === gender && values['11']) {
        [entry.jacket, entry.texture] = values['11'];
      }
      showStatus(preview ? 'Números atualizados nesta prévia.' : 'Números do uniforme salvos.');
    } catch {
      showStatus('Não foi possível salvar os números.', true);
    } finally {
      pending = false; $('editor-save').disabled = false; render();
    }
  };

  async function equip(option) {
    if (pending) return;
    pending = true; render();
    try {
      if (!await request('ButtonClick', {index:option.index})) throw new Error();
      worn = option.index;
      showStatus(`${option.name} equipado.`);
    } catch {
      showStatus('Não foi possível vestir este uniforme.', true);
    } finally {
      pending = false; render();
    }
  }

  async function close() {
    $('locker').hidden = true;
    if (!preview) await request('close').catch(() => {});
  }

  $('close').onclick = close;
  $('remove').onclick = async () => {
    if (pending) return;
    pending = true; render();
    try {
      if (!await request('rmv_un')) throw new Error();
      worn = null;
      if (preview) showStatus('Roupa anterior restaurada.');
      else await close();
    } catch {
      showStatus('Não foi possível retirar o uniforme.', true);
    } finally {
      pending = false; render();
    }
  };
  window.addEventListener('keydown', event => {
    if (event.key === 'Escape' && !$('locker').hidden && !pending) close();
  });

  function open(data) {
    room = String(data.room || '');
    uniforms = Array.isArray(data.uniforms) ? data.uniforms : [];
    worn = null; pending = false;
    gender = data.gender === 'masculino' ? 'masculino' : 'feminino';
    $('edit').hidden = data.canEdit !== true;
    toggleEditor(false);
    $('room').textContent = room === 'MILITAR' ? 'Polícia Militar' : room;
    showStatus('');
    $('locker').hidden = false;
    render();
    $('locker').focus();
  }

  window.addEventListener('message', ({data}) => {
    if (data?.showNUI === true) open(data);
    else if (data?.showNUI === false) $('locker').hidden = true;
  });

  let demoEditor = [];
  if (preview) {
    document.body.classList.add('preview');
    const demoUniforms = [
      {index:1,name:'Aluno',jacket:23,texture:0},
      {index:2,name:'Soldado',jacket:23,texture:1},
      {index:3,name:'Tenente',jacket:327,texture:8},
      {index:4,name:'Comando',jacket:327,texture:8},
      {index:5,name:'Comando',jacket:343,texture:0},
      {index:6,name:'Comando',jacket:329,texture:8},
    ];
    demoEditor = demoUniforms.map(entry => ({
      name:entry.name, masculino:{},
      feminino:{
        '11':[entry.jacket,entry.texture], '8':[entry.index <= 2 ? 35 : 159,0],
        '3':[entry.index <= 2 ? 0 : 49,0], '4':[entry.index === 1 ? 137 : 136,entry.index >= 4 ? 4 : 0],
        '6':[25,0], '9':[17,0], '7':[85,0]
      }
    }));
    const options = new URLSearchParams(location.search);
    open({room:'MILITAR', uniforms:demoUniforms, canEdit:!options.has('jogador')});
    if (options.has('editar')) $('edit').click();
  }
})();
