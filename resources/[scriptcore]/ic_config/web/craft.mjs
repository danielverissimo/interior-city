// Structured Craft + Farm editor. Keep resource-owned fields and legacy items.
const copy = value => JSON.parse(JSON.stringify(value));
const list = value => Array.isArray(value) ? value : Object.values(value || {});
const indexOf = value => String(value?.spawn || value?.item || value?.name || '');
function numeric(value, title, minimum, integer = false) {
    if (value === '' || value == null) throw new Error(`Informe ${title}.`);
    const result = Number(value);
    if (!Number.isFinite(result) || (minimum != null && result < minimum) || (integer && !Number.isSafeInteger(result))) throw new Error(`Valor inválido em ${title}.`);
    return result;
}
export function craftDraft(value = {}) {
    const result = copy(value), bench = result.bench ||= {}, farm = result.farm ||= {};
    bench.name ??= ''; bench.craftPermission ??= ''; bench.armazemPermission ??= '';
    bench.coords = list(bench.coords); bench.craftItems = list(bench.craftItems); bench.armazemItems = list(bench.armazemItems);
    for (const recipe of bench.craftItems) recipe.requires = list(recipe.requires);
    farm.enabled = farm.enabled === true; farm.rewardType ??= bench.farmRewardType || bench.name;
    farm.routeType ??= bench.farmRouteType || ''; farm.permissions = list(farm.permissions); farm.rewards = list(farm.rewards);
    for (const reward of farm.rewards) reward.items = list(reward.items);
    return result;
}
export function readCraftDraft(value, items = []) {
    const result = craftDraft(value), { bench, farm } = result;
    bench.name = String(bench.name).trim();
    if (!bench.name) throw new Error('Informe o nome da bancada.');
    for (const key of ['craftPermission', 'armazemPermission']) bench[key] = String(bench[key]).trim();
    bench.coords = bench.coords.map((point, i) => ({ ...point, ...Object.fromEntries(['x', 'y', 'z'].map(axis => {
        const number = numeric(point[axis], `ponto ${i + 1}: ${axis.toUpperCase()}`);
        if (Math.abs(number) > 1000000) throw new Error('Coordenada fora do limite.');
        return [axis, number];
    })) }));
    const catalog = new Map(list(items).map(item => [String(item.index), item]));
    const storage = [...bench.armazemItems], stored = new Set(storage.map(indexOf));
    bench.craftItems = bench.craftItems.map((recipe, i) => {
        if (!recipe.spawn) throw new Error(`Selecione o produto da receita ${i + 1}.`);
        recipe.amount = numeric(recipe.amount, `quantidade produzida na receita ${i + 1}`, 1, true);
        recipe.time = numeric(recipe.time, `tempo da receita ${i + 1}`, 0);
        recipe.requires = recipe.requires.map((material, j) => {
            const key = indexOf(material);
            if (!key) throw new Error(`Selecione o material ${j + 1} da receita ${i + 1}.`);
            material.amount = numeric(material.amount, `quantidade do material ${j + 1} na receita ${i + 1}`, 1, true);
            if (key !== 'money' && !stored.has(key)) {
                const item = catalog.get(key);
                storage.push({ spawn: key, name: item?.name || key, image: item?.image || key }); stored.add(key);
            }
            return material;
        });
        return recipe;
    });
    // Add newly required materials without deleting existing storage entries/metadata.
    bench.armazemItems = storage;
    if (farm.enabled) {
        farm.rewardType = String(farm.rewardType || bench.name).trim();
        if (!farm.rewardType || !farm.routeType) throw new Error('Informe o identificador do farm e selecione o tipo de rota.');
        farm.rewards = farm.rewards.map((reward, i) => ({ ...reward, items: reward.items.map((item, j) => {
            if (!item.item) throw new Error(`Selecione o item ${j + 1} da recompensa ${i + 1}.`);
            const min = numeric(item.min, `mínimo do item ${j + 1} do farm`, 1, true);
            const max = numeric(item.max, `máximo do item ${j + 1} do farm`, 1, true);
            if (max < min) throw new Error('O máximo do farm deve ser maior ou igual ao mínimo.');
            return { ...item, min, max };
        }) }));
    }
    return result;
}

const node = (tag, text, className) => { const el = document.createElement(tag); if (text != null) el.textContent = text; if (className) el.className = className; return el; };
const action = (title, run, className = '') => { const el = node('button', title, className); el.type = 'button'; el.onclick = run; return el; };

export function mountCraftForm({ container, value, items = [], farmConfig = {}, readOnly = false, capture, position, onError }) {
    const draft = craftDraft(value), { bench, farm } = draft, root = node('div', null, 'craft-form'); container.append(root);
    const catalog = new Map(list(items).map(item => [String(item.index), item]));
    let busy = false, serial = 0, picker = null;
    const locked = () => readOnly || busy;
    const itemName = key => catalog.get(String(key))?.name || key || 'Nenhum item selecionado';
    function field(parent, title, object, key, { type = 'text', min, step = 'any', options } = {}) {
        const holder = node('div', null, type === 'checkbox' ? 'field boolean' : 'field');
        const label = node('label', title), input = node(options ? 'select' : 'input');
        input.id = `craft-field-${++serial}`; label.htmlFor = input.id;
        if (options) {
            input.append(new Option('Selecione…', ''));
            for (const option of options) input.append(new Option(option, option));
            if (object[key] && !options.includes(object[key])) input.append(new Option(`${object[key]} (atual)`, object[key]));
        } else { input.type = type; if (type === 'number') { input.step = step; if (min != null) input.min = String(min); } }
        if (type === 'checkbox') input.checked = object[key]; else input.value = object[key] ?? '';
        input.oninput = () => { object[key] = type === 'checkbox' ? input.checked : input.value; };
        holder.append(label, input); parent.append(holder); return input;
    }
    function section(parent, title, description) {
        const box = node('fieldset', null, 'craft-section'); box.append(node('legend', title));
        if (description) box.append(node('p', description, 'craft-note')); parent.append(box); return box;
    }
    function remove(parent, text, run) { parent.append(action(text, () => { if (!locked()) { run(); sync(); } }, 'delete')); }
    function empty(parent, text) { parent.append(node('p', text, 'craft-note')); }
    function closePicker() { picker?.remove(); picker = null; }
    function pick(parent, title, selected, multiple, choose) {
        if (locked()) return;
        closePicker(); picker = node('section', null, 'craft-picker'); picker.setAttribute('aria-label', title);
        const selectedKeys = new Set(selected), search = node('input'), results = node('div', null, 'craft-picker-results');
        search.type = 'search'; search.placeholder = 'Buscar por nome ou código…'; search.setAttribute('aria-label', 'Buscar itens');
        const picked = node('p', null, 'craft-note');
        const footer = node('div', null, 'craft-picker-actions');
        const finish = action('Adicionar selecionados', () => { if (locked()) return; choose([...selectedKeys]); closePicker(); sync(); }, 'primary');
        footer.append(action('Cancelar seleção', closePicker)); if (multiple) footer.append(finish);
        function render() {
            const normalize = value => String(value).normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLocaleLowerCase('pt-BR');
            const query = normalize(search.value.trim());
            const matched = [...catalog.values()].filter(item => normalize(`${item.name} ${item.index}`).includes(query));
            results.replaceChildren(); picked.textContent = multiple ? `${selectedKeys.size} selecionados` : 'Selecione o produto da receita.';
            finish.disabled = locked() || !selectedKeys.size;
            for (const item of matched.slice(0, 80)) {
                const row = node(multiple ? 'label' : 'button', null, 'craft-picker-item');
                if (!multiple) { row.type = 'button'; row.onclick = () => { if (locked()) return; choose([String(item.index)]); closePicker(); sync(); }; }
                else {
                    const check = node('input'); check.type = 'checkbox'; check.checked = selectedKeys.has(String(item.index));
                    check.onchange = () => { if (check.checked) selectedKeys.add(String(item.index)); else selectedKeys.delete(String(item.index)); render(); };
                    row.append(check);
                }
                const text = node('span'); text.append(node('strong', item.name || item.index), node('small', item.index)); row.append(text); results.append(row);
            }
            if (!matched.length) empty(results, 'Nenhum item encontrado.');
            if (matched.length > 80) empty(results, `Exibindo 80 de ${matched.length}. Refine a busca.`);
        }
        picker.append(node('h3', title), search, picked, results, footer); parent.append(picker);
        search.addEventListener('keydown', event => { if (event.key === 'Enter') event.preventDefault(); });
        search.oninput = render; render(); search.focus();
    }
    function itemBadge(parent, key, fallback) {
        const info = node('div', null, 'craft-item-name'); info.append(node('strong', catalog.has(key) ? itemName(key) : fallback || itemName(key)), node('small', key || 'Escolha um item'));
        if (key && !catalog.has(key)) info.append(node('small', 'Fora do catálogo atual · cadastro preservado', 'craft-missing'));
        parent.append(info);
    }
    const tabs = node('div', null, 'craft-tabs'); tabs.setAttribute('role', 'tablist'); tabs.setAttribute('aria-label', 'Edição de Craft e Farm');
    const general = node('div'), recipesView = node('div'); recipesView.hidden = true;
    const generalTab = action('Bancada e farm', () => show('general')), recipesTab = action('Editar receitas', () => show('recipes'));
    for (const tab of [generalTab, recipesTab]) tab.setAttribute('role', 'tab');
    general.id = 'craft-general'; recipesView.id = 'craft-recipes';
    generalTab.id = 'craft-general-tab'; recipesTab.id = 'craft-recipes-tab';
    generalTab.setAttribute('aria-controls', general.id); recipesTab.setAttribute('aria-controls', recipesView.id);
    for (const [panel, tab] of [[general, generalTab], [recipesView, recipesTab]]) { panel.setAttribute('role', 'tabpanel'); panel.setAttribute('aria-labelledby', tab.id); }
    root.addEventListener('keydown', event => { if (event.key === 'Escape' && picker) { event.preventDefault(); event.stopPropagation(); closePicker(); } });
    tabs.append(generalTab, recipesTab); root.append(tabs, general, recipesView);
    function show(view) {
        closePicker(); general.hidden = view !== 'general'; recipesView.hidden = view !== 'recipes';
        generalTab.setAttribute('aria-selected', String(view === 'general')); recipesTab.setAttribute('aria-selected', String(view === 'recipes'));
        generalTab.tabIndex = view === 'general' ? 0 : -1; recipesTab.tabIndex = view === 'recipes' ? 0 : -1;
    }
    tabs.addEventListener('keydown', event => {
        if (busy || !['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return;
        event.preventDefault();
        const view = event.key === 'Home' ? 'general' : event.key === 'End' ? 'recipes' : general.hidden ? 'general' : 'recipes';
        show(view); (view === 'general' ? generalTab : recipesTab).focus();
    });
    const identity = section(general, 'Bancada');
    field(identity, 'Nome da bancada / organização', bench, 'name'); field(identity, 'Permissão de craft', bench, 'craftPermission'); field(identity, 'Permissão do armazém', bench, 'armazemPermission');
    const pointsBox = section(general, 'Pontos da bancada', 'Locais onde o painel de craft abre.');
    const pointsList = node('div', null, 'craft-list'); pointsBox.append(pointsList);
    function renderPoints() {
        pointsList.replaceChildren();
        bench.coords.forEach((point, index) => {
            const row = node('fieldset', null, 'craft-point'); row.append(node('legend', `Ponto ${index + 1}`));
            for (const axis of ['x', 'y', 'z']) field(row, axis.toUpperCase(), point, axis, { type: 'number' });
            row.append(action('Posicionar ponto no jogo', () => capture(['bench', 'coords', index], 'position', false, 'set'), 'capture-position'));
            remove(row, 'Remover ponto', () => { bench.coords.splice(index, 1); renderPoints(); }); pointsList.append(row);
        });
        if (!bench.coords.length) empty(pointsList, 'Nenhum ponto cadastrado.');
    }
    pointsBox.append(action('Usar minha posição atual', async () => {
        if (locked()) return;
        try {
            const coords = await position(); if (!root.isConnected || locked()) return;
            appendPosition(coords); renderPoints(); sync();
        } catch (error) { if (root.isConnected) onError(error); }
    }, 'capture-position'));
    pointsBox.append(action('Posicionar novo ponto no jogo', () => capture(['bench', 'coords'], 'position', false, 'append'), 'capture-position'));
    pointsBox.append(action('Adicionar ponto manual', () => { if (locked()) return; bench.coords.push({ x: null, y: null, z: null }); renderPoints(); sync(); }));
    renderPoints();
    const recipeShortcut = action('', () => show('recipes'), 'craft-recipe-shortcut'); general.append(recipeShortcut);
    const recipesBox = section(recipesView, 'Receitas', 'Escolha os produtos e materiais pelo catálogo de itens da cidade.');
    const recipesList = node('div', null, 'craft-list'); recipesBox.append(recipesList);
    const storageBox = section(recipesView, 'Materiais do armazém', 'Materiais usados nas receitas são incluídos ao salvar. Itens extras já cadastrados são preservados.');
    const storageList = node('div', null, 'craft-list'); storageBox.append(storageList);
    function usedMaterials() { return new Set(bench.craftItems.flatMap(recipe => recipe.requires.map(indexOf))); }
    function renderStorage() {
        storageList.replaceChildren(); const used = usedMaterials();
        const all = new Map(bench.armazemItems.map(item => [indexOf(item), item]));
        for (const key of used) if (key && key !== 'money' && !all.has(key)) all.set(key, { spawn: key });
        for (const [key, value] of all) {
            const row = node('div', null, 'craft-material'); itemBadge(row, key, value.name);
            row.append(node('span', used.has(key) ? 'Usado nas receitas' : 'Extra do armazém', 'craft-tag'));
            const button = action('Remover do armazém', () => { if (locked() || used.has(key)) return; bench.armazemItems = bench.armazemItems.filter(item => indexOf(item) !== key); renderStorage(); sync(); }, 'delete');
            button.dataset.fixedDisabled = String(used.has(key)); button.title = used.has(key) ? 'Remova o material das receitas antes de retirá-lo do armazém.' : 'Remover somente este item extra'; row.append(button); storageList.append(row);
        }
        if (!all.size) empty(storageList, 'O armazém será preenchido com os materiais das receitas.');
    }
    storageBox.append(action('Adicionar item extra ao armazém', () => pick(storageBox, 'Itens extras do armazém', bench.armazemItems.map(indexOf), true, keys => {
        for (const key of keys) if (!bench.armazemItems.some(item => indexOf(item) === key)) bench.armazemItems.push({ spawn: key, name: itemName(key), image: catalog.get(key)?.image || key }); renderStorage();
    })));
    function renderRecipes() {
        closePicker(); recipesList.replaceChildren(); recipeShortcut.textContent = `Editar receitas · ${bench.craftItems.length} receitas`;
        bench.craftItems.forEach((recipe, index) => {
            const card = node('fieldset', null, 'craft-recipe'); card.append(node('legend', `Receita ${index + 1}`));
            const product = node('div', null, 'craft-product'); itemBadge(product, String(recipe.spawn || ''), recipe.name);
            product.append(action(recipe.spawn ? 'Trocar produto' : 'Selecionar produto', () => pick(card, 'Selecionar produto', [recipe.spawn], false, ([key]) => {
                Object.assign(recipe, { spawn: key, name: itemName(key), image: catalog.get(key)?.image || key }); renderRecipes();
            }))); card.append(product);
            field(card, 'Quantidade produzida', recipe, 'amount', { type: 'number', min: 1, step: '1' }); field(card, 'Tempo de produção (s)', recipe, 'time', { type: 'number', min: 0 });
            const materials = node('fieldset', null, 'craft-materials'); materials.append(node('legend', 'Materiais necessários')); card.append(materials);
            recipe.requires.forEach((material, index) => {
                const row = node('div', null, 'craft-material'); itemBadge(row, indexOf(material));
                field(row, `Quantidade de ${itemName(indexOf(material))}`, material, 'amount', { type: 'number', min: 1, step: '1' });
                remove(row, 'Remover material', () => { recipe.requires.splice(index, 1); renderRecipes(); }); materials.append(row);
            });
            if (!recipe.requires.length) empty(materials, 'Nenhum material necessário cadastrado.');
            materials.append(action('Adicionar materiais', () => pick(materials, 'Selecionar materiais', recipe.requires.map(indexOf), true, keys => {
                for (const key of keys) if (!recipe.requires.some(item => indexOf(item) === key)) recipe.requires.push({ name: key, image: catalog.get(key)?.image || key, amount: 1 }); renderRecipes();
            })));
            remove(card, 'Remover receita', () => { bench.craftItems.splice(index, 1); renderRecipes(); }); recipesList.append(card);
        });
        if (!bench.craftItems.length) empty(recipesList, 'Nenhuma receita cadastrada. Adicione o primeiro produto.'); renderStorage();
    }
    recipesBox.append(action('Nova receita', () => { if (locked()) return; bench.craftItems.push({ spawn: '', name: '', image: '', amount: 1, time: 5, requires: [] }); renderRecipes(); sync(); }));
    renderRecipes();
    const farmBox = section(general, 'Farm vinculado');
    const enabled = field(farmBox, 'Criar/atualizar farm para esta bancada', farm, 'enabled', { type: 'checkbox' });
    const farmFields = node('div', null, 'craft-farm-fields'); farmBox.append(farmFields);
    field(farmFields, 'Tipo de rota', farm, 'routeType', { options: Object.keys(farmConfig.RouteBlips || {}) });
    field(farmFields, 'Identificador do reward', farm, 'rewardType');
    const permissionModel = { text: farm.permissions.join(', ') };
    const permissions = field(farmFields, 'Permissões do farm (separadas por vírgula)', permissionModel, 'text');
    permissions.addEventListener('input', () => { farm.permissions = permissions.value.split(',').map(value => value.trim()).filter(Boolean); });
    const rewardsList = node('div', null, 'craft-list'); farmFields.append(rewardsList);
    function renderRewards() {
        closePicker(); rewardsList.replaceChildren();
        farm.rewards.forEach((reward, groupIndex) => {
            const card = node('fieldset', null, 'craft-reward'); card.append(node('legend', `Recompensa ${groupIndex + 1}`));
            field(card, 'Nome exibido da rota', reward, 'name'); field(card, 'Imagem da rota (index)', reward, 'image');
            const itemsBox = node('fieldset', null, 'craft-materials'); itemsBox.append(node('legend', 'Itens recebidos no farm')); card.append(itemsBox);
            reward.items.forEach((item, itemIndex) => {
                const row = node('div', null, 'craft-material'); itemBadge(row, item.item);
                field(row, `Mínimo de ${itemName(item.item)}`, item, 'min', { type: 'number', min: 1, step: '1' }); field(row, `Máximo de ${itemName(item.item)}`, item, 'max', { type: 'number', min: 1, step: '1' });
                remove(row, 'Remover item do farm', () => { reward.items.splice(itemIndex, 1); renderRewards(); }); itemsBox.append(row);
            });
            if (!reward.items.length) empty(itemsBox, 'Nenhum item cadastrado neste grupo.');
            itemsBox.append(action('Adicionar itens ao farm', () => pick(itemsBox, 'Selecionar itens do farm', reward.items.map(item => item.item), true, keys => {
                for (const key of keys) if (!reward.items.some(item => item.item === key)) reward.items.push({ item: key, min: 1, max: 1 }); renderRewards();
            })));
            remove(card, 'Remover grupo de recompensas', () => { farm.rewards.splice(groupIndex, 1); renderRewards(); }); rewardsList.append(card);
        });
        if (!farm.rewards.length) empty(rewardsList, 'Nenhum grupo de recompensas cadastrado.');
    }
    farmFields.append(action('Adicionar grupo de recompensas', () => { if (locked() || !farm.enabled) return; farm.rewards.push({ name: 'ROTA DE FARM', image: '', items: [] }); renderRewards(); sync(); }));
    renderRewards(); enabled.addEventListener('change', () => { closePicker(); sync(); });
    function sync() {
        root.querySelectorAll('button,input,select').forEach(input => { input.disabled = locked() || input.dataset.fixedDisabled === 'true'; });
        generalTab.disabled = busy; recipesTab.disabled = busy;
        farmFields.querySelectorAll('button,input,select').forEach(input => { input.disabled = locked() || !farm.enabled; });
        farmFields.classList.toggle('inactive', !farm.enabled);
    }
    function appendPosition(coords) {
        if (!coords || !['x', 'y', 'z'].every(axis => Number.isFinite(coords[axis]) && Math.abs(coords[axis]) <= 1000000)) throw new Error('A captura não forneceu coordenadas válidas.');
        bench.coords.push({ x: coords.x, y: coords.y, z: coords.z });
    }
    show('general'); sync();
    return {
        read() { if (picker) throw new Error('Conclua ou cancele a seleção de itens antes de salvar.'); return readCraftDraft(draft, items); },
        setBusy(next) { busy = next; sync(); },
        applyCapture(path, coords, mode) {
            if (locked()) return;
            if (path[0] !== 'bench' || path[1] !== 'coords') return;
            if (!coords || !['x', 'y', 'z'].every(axis => Number.isFinite(coords[axis]) && Math.abs(coords[axis]) <= 1000000)) { onError(new Error('A captura não forneceu coordenadas válidas.')); return; }
            if (mode === 'append') appendPosition(coords);
            else {
                const point = bench.coords[path[2]]; if (!point) return;
                Object.assign(point, { x: coords.x, y: coords.y, z: coords.z });
            }
            renderPoints(); sync();
        }
    };
}
