const $ = (s) => document.querySelector(s);
const app = $('#app');
const grid = $('#grid');
const category = $('#category');
const search = $('#search');
const count = $('#count');
const mansion = $('#mansion');
const settings = $('#settings');
const modal = $('#configModal');
const priceList = $('#priceList');

let ctx = null;
let items = [];

const res = () => GetParentResourceName();
const post = async (name, data = {}) => {
  try {
    const response = await fetch(`https://${res()}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    return await response.json();
  } catch (e) {
    return { ok: false, message: 'Falha de comunicação com o jogo.' };
  }
};

const money = (value) => 'R$ ' + Number(value || 0).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const imageUrl = (item) => (ctx?.catalog?.imageBase || 'https://electron-services.com/assets/gtav/object/{model}.webp').replace('{model}', encodeURIComponent(item.model || ''));

const fallbackMap = {
  'Sofás':'sofas','Cadeiras':'cadeiras','Mesas':'mesas','Camas':'camas',
  'TV & Eletrônicos':'eletronicos','Iluminação':'iluminacao','Plantas':'plantas','Decoração':'decoracao',
  'Cozinha':'cozinha','Banheiro':'banheiro','Escritório':'escritorio','Bar & Lazer':'lazer',
  'Academia':'academia','Exterior':'exterior'
};
const fallbackImageUrl = (item) => `assets/fallback/${fallbackMap[item?.category] || 'decoracao'}.svg`;

function makeCard(item) {
  const card = document.createElement('article');
  card.className = 'furniture-card';

  const thumb = document.createElement('div');
  thumb.className = 'furniture-thumb';

  const fallback = document.createElement('div');
  fallback.className = 'furniture-fallback';

  const fallbackImg = document.createElement('img');
  fallbackImg.alt = `${item.category || 'Decoração'} - imagem alternativa`;
  fallbackImg.src = fallbackImageUrl(item);

  const fallbackBadge = document.createElement('span');
  fallbackBadge.className = 'furniture-fallback-badge';
  fallbackBadge.textContent = item.model || item.category || 'Mobília';
  fallback.append(fallbackImg, fallbackBadge);

  const img = document.createElement('img');
  img.className = 'furniture-main-image';
  img.loading = 'lazy';
  img.alt = item.name || item.model || 'Mobília';
  img.src = imageUrl(item);
  img.addEventListener('load', () => { fallback.style.display = 'none'; });
  img.addEventListener('error', () => { img.remove(); fallback.style.display = 'flex'; });

  thumb.append(fallback, img);

  const body = document.createElement('div');
  body.className = 'furniture-card-body';

  const name = document.createElement('div');
  name.className = 'furniture-name';
  name.title = item.name || '';
  name.textContent = item.name || item.model || 'Mobília';

  const model = document.createElement('div');
  model.className = 'furniture-model';
  model.title = item.model || '';
  model.textContent = item.model || '';

  const price = document.createElement('div');
  price.className = 'furniture-price';
  price.textContent = money(item.price);

  const buy = document.createElement('button');
  buy.className = 'furniture-buy';
  buy.type = 'button';
  buy.dataset.id = item.id;
  buy.textContent = 'COMPRAR';

  body.append(name, model, price, buy);
  card.append(thumb, body);
  return card;
}

function render() {
  const q = search.value.trim().toLowerCase();
  const cat = category.value;
  const filtered = items.filter((item) => {
    const haystack = `${item.name || ''} ${item.model || ''} ${item.category || ''}`.toLowerCase();
    return (!cat || item.category === cat) && (!q || haystack.includes(q));
  });

  count.textContent = `${filtered.length} mobília(s)`;
  grid.replaceChildren();

  if (!filtered.length) {
    const empty = document.createElement('div');
    empty.className = 'furniture-empty';
    empty.textContent = 'Nenhuma mobília encontrada para este filtro.';
    grid.appendChild(empty);
    return;
  }

  const fragment = document.createDocumentFragment();
  filtered.forEach((item) => fragment.appendChild(makeCard(item)));
  grid.appendChild(fragment);
}

function categories() {
  const current = category.value;
  const cats = [...new Set(items.map((i) => i.category).filter(Boolean))].sort((a, b) => a.localeCompare(b, 'pt-BR'));
  category.replaceChildren();

  const all = document.createElement('option');
  all.value = '';
  all.textContent = 'Todas as categorias';
  category.appendChild(all);

  cats.forEach((cat) => {
    const opt = document.createElement('option');
    opt.value = cat;
    opt.textContent = cat;
    category.appendChild(opt);
  });

  if (cats.includes(current)) category.value = current;
}

function openPanel(context) {
  ctx = context || {};
  items = Array.isArray(ctx?.catalog?.items) ? ctx.catalog.items : [];
  mansion.textContent = ctx?.mansionName ? `Mansão: ${ctx.mansionName}` : '';
  settings.classList.toggle('hidden', !ctx?.catalog?.canConfigure);
  search.value = '';
  category.value = '';
  categories();
  render();
  app.classList.remove('hidden');
}

window.addEventListener('message', (event) => {
  if (event.data?.action === 'open' && event.data.context) openPanel(event.data.context);
  if (event.data?.action === 'close') app.classList.add('hidden');
});

search.addEventListener('input', render);
category.addEventListener('change', render);

$('#close').addEventListener('click', () => {
  app.classList.add('hidden');
  post('close');
});

document.addEventListener('keydown', (event) => {
  if (event.key !== 'Escape' || app.classList.contains('hidden')) return;
  if (!modal.classList.contains('hidden')) modal.classList.add('hidden');
  else $('#close').click();
});

grid.addEventListener('click', async (event) => {
  const button = event.target.closest('.furniture-buy');
  if (!button) return;
  button.disabled = true;
  const result = await post('buy', { itemId: button.dataset.id });
  button.disabled = false;
  if (!result?.ok) post('notify', { type: 'negado', message: result?.message || 'Não foi possível iniciar a compra.' });
});

$('#edit').addEventListener('click', async () => {
  const result = await post('editMode');
  if (result?.ok) app.classList.add('hidden');
});

function renderPrices() {
  const q = $('#configSearch').value.trim().toLowerCase();
  priceList.replaceChildren();
  const fragment = document.createDocumentFragment();

  items.filter((item) => !q || `${item.name || ''} ${item.model || ''}`.toLowerCase().includes(q)).forEach((item) => {
    const row = document.createElement('div');
    row.className = 'furniture-price-row';

    const info = document.createElement('div');
    const strong = document.createElement('strong');
    strong.textContent = item.name || item.model || 'Mobília';
    const small = document.createElement('small');
    small.textContent = `${item.model || ''} · ${item.category || 'Sem categoria'}`;
    info.append(strong, small);

    const input = document.createElement('input');
    input.className = 'furniture-price-input';
    input.type = 'number';
    input.min = '0';
    input.step = '1';
    input.dataset.price = item.id;
    input.value = Number(item.price || 0);

    row.append(info, input);
    fragment.appendChild(row);
  });

  priceList.appendChild(fragment);
}

settings.addEventListener('click', () => {
  renderPrices();
  modal.classList.remove('hidden');
});
$('#configClose').addEventListener('click', () => modal.classList.add('hidden'));
$('#configSearch').addEventListener('input', renderPrices);
$('#setAll').addEventListener('click', () => {
  const value = Math.max(0, Math.floor(Number($('#bulkPrice').value) || 0));
  document.querySelectorAll('[data-price]').forEach((input) => { input.value = value; });
});
$('#savePrices').addEventListener('click', async () => {
  const prices = {};
  document.querySelectorAll('[data-price]').forEach((input) => { prices[input.dataset.price] = Number(input.value) || 0; });
  const result = await post('savePrices', { prices });
  if (result?.ok) {
    ctx.catalog = result.catalog;
    items = Array.isArray(result.catalog?.items) ? result.catalog.items : [];
    modal.classList.add('hidden');
    categories();
    render();
    post('notify', { type: 'sucesso', message: result.message });
  } else {
    post('notify', { type: 'negado', message: result?.message || 'Não foi possível salvar.' });
  }
});
