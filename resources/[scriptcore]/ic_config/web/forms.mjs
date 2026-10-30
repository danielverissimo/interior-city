import { schemaFor, CATALOG_METHODS, fieldLabel, text, num, bool, object, sequence, coords, dictionary } from './form-schema.mjs';
import { catalogPicker } from './catalog-picker.mjs';

const clone = value => JSON.parse(JSON.stringify(value));
const own = (object, key) => object != null && Object.hasOwn(object, key);
const blocked = key => /webhook|password|secret|token|license|authorization|cookie|api.?key/i.test(String(key)) || ['__proto__', 'prototype', 'constructor'].includes(String(key));
const array = value => Array.isArray(value) ? value : value && !Object.keys(value).length ? [] : Object.values(value || {});
export function getPath(value, path) { for (const key of path) { if (!own(value, key)) return undefined; value = value[key]; } return value; }
export function setPath(root, path, value) {
    if (!path.length || path.some(key => blocked(key) || (typeof key === 'number' && (!Number.isSafeInteger(key) || key < 0 || key > 20000)))) throw new Error('Campo inválido.');
    let parent = root;
    for (let i = 0; i < path.length - 1; i++) {
        const key = path[i];
        if (!own(parent, key) || !parent[key] || typeof parent[key] !== 'object' || Array.isArray(parent[key]) && !parent[key].length && typeof path[i + 1] === 'string') parent[key] = typeof path[i + 1] === 'number' ? [] : {};
        parent = parent[key];
    }
    Object.defineProperty(parent, path.at(-1), { value, enumerable: true, configurable: true, writable: true });
}
export function numericField(value, descriptor) {
    if (value == null || String(value).trim() === '') {
        if (own(descriptor, 'empty')) return descriptor.empty;
        if (descriptor.optional) return undefined;
        throw new Error(`Informe ${descriptor.label}.`);
    }
    const number = Number(value);
    if (!Number.isFinite(number) || (descriptor.integer && !Number.isSafeInteger(number)) || (descriptor.min != null && number < descriptor.min) || (descriptor.max != null && number > descriptor.max)) throw new Error(`Valor inválido em ${descriptor.label}.`);
    return number;
}
export function blankLike(value) {
    if (Array.isArray(value)) return [];
    if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).filter(([key]) => !blocked(key)).map(([key, item]) => [key, blankLike(item)]));
    return typeof value === 'boolean' ? false : typeof value === 'number' ? null : '';
}
const vectorKeys = /^(coords|coordinates|position|boxPosition|interior|vaultCoords|wardobeCoords|inicio|central|npc|local_carga|local_venda|terreno|hackCoords|centerCoords|test_drive)$/;
export function inferField(key, value) {
    const label = fieldLabel(key ?? 'Valor');
    if (key === 'valores_venda' && value && typeof value === 'object' && !Array.isArray(value)) {
        return dictionary(key, label, sequence(null, 'Níveis de venda', object(null, 'Nível', [num(0, 'Mínimo', { min: 0 }), num(1, 'Máximo', { min: 0 })], { range: [0, 1] }), [0, 0]), [[0, 0]], { keyCatalog: 'items', keyLabel: 'Item' });
    }
    if (Array.isArray(value)) {
        if (vectorKeys.test(String(key)) && value.length >= 3 && value.length <= 4 && value.every(x => typeof x === 'number' || x == null)) return coords(key, label, { array: true, heading: value.length === 4 ? 'w' : false });
        let template = value[0];
        if (template == null) template = /rotas|locais_entrega|locais_retirada/.test(String(key)) ? { x: null, y: null, z: null } : /locais_pesca|locais_mineracao|bombLocations|drillSpawns/.test(String(key)) ? [null, null, null] : '';
        const entry = Array.isArray(template) && [3, 4].includes(template.length) && /rotas|locais|Spawns|Locations/.test(String(key)) ? coords(null, 'Posição', { array: true, heading: template.length === 4 ? 'w' : false }) : inferField(null, template);
        if (['peixes', 'minerios'].includes(String(key))) Object.assign(entry, { type: 'catalog', catalog: 'items' });
        if (key === 'veiculos') Object.assign(entry, { type: 'catalog', catalog: 'vehicles' });
        return sequence(key, label, entry, blankLike(template));
    }
    if (value && typeof value === 'object') return object(key, label, Object.entries(value).filter(([key]) => !blocked(key)).map(([key, child]) => inferField(key, child)), { flexible: true });
    if (typeof value === 'boolean') return bool(key, label);
    if (typeof value === 'number' || value === null) return num(key, label, { required: true });
    if (key === 'veiculo') return { key, label, type: 'catalog', catalog: 'vehicles' };
    if (['item', 'item_necessario'].includes(String(key))) return { key, label, type: 'catalog', catalog: 'items' };
    return text(key, label);
}
export function catalogRequirements(viewId, action) { return action ? [] : CATALOG_METHODS[viewId] || []; }
export function makeCatalogs(view, data, responses = {}) {
    const groups = view.id === 'groups' || view.id === 'fac' ? array(data) : [];
    const fleet = responses.getServerVehicleCatalog || (view.id === 'catalog' ? data : {}) || {};
    return {
        items: array(responses.getItemList).map(item => ({ value: String(item.index), label: item.name || item.index, description: item.image })),
        vehicles: Object.entries(fleet).map(([value, info]) => ({ value, label: info.name || value, description: info.type })),
        vehicleTypes: [...new Set(Object.values(fleet).map(info => info.type).filter(Boolean))].map(value => ({ value, label: value })),
        garageTypes: array(responses.getGarageTypes).map(value => ({ value: value.name, label: value.name })),
        permissions: [...new Set(groups.flatMap(group => array(group.permissions)))].map(value => ({ value, label: value })),
        zones: array(data?.safezones).map(zone => ({ value: zone.name, label: zone.name })),
        robberyTypes: Object.keys(data?.setups || {}).map(value => ({ value, label: value })),
        interiors: Object.entries(data?.interiors || {}).map(([value, info]) => ({ value, label: value, type: info.type })),
        colors: Array.from({ length: 81 }, (_, value) => ({ value, label: ({ 0: 'Branco', 1: 'Vermelho', 2: 'Verde', 3: 'Azul', 5: 'Amarelo', 7: 'Rosa', 17: 'Laranja' })[value] ? `${value} · ${({ 0: 'Branco', 1: 'Vermelho', 2: 'Verde', 3: 'Azul', 5: 'Amarelo', 7: 'Rosa', 17: 'Laranja' })[value]}` : `Cor ${value}` })),
        sprites: [...new Set([1, 40, 52, 60, 73, 106, 110, 120, 280, 357, 402, 417, 500, 643, ...array(view.id === 'mapmarkings' ? data : []).map(row => row.sprite)])].map(value => ({ value, label: `Ícone ${value}` }))
    };
}
const element = (tag, text, className) => { const el = document.createElement(tag); if (text != null) el.textContent = text; if (className) el.className = className; return el; };
const actionButton = (label, run, className = '') => { const el = element('button', label, className); el.type = 'button'; el.onclick = run; return el; };

export function mountStructuredForm({ container, value, view, row, action = false, data = {}, catalogs = {}, readOnly = false, capture, position, outfit, onError }) {
    const schema = schemaFor(view.id, action);
    if (!schema) throw new Error('Formulário ainda não registrado para esta tela.');
    const valueAtMount = clone(value), draft = clone(value), root = element('div', null, 'structured-form'); container.append(root);
    if (view.id === 'safezone' && !row && !action && !array(draft.zones).length) draft.zones = [{ minZ: null, maxZ: null, coords: [] }];
    let serial = 0, busy = false, picker = null, pending = 0, fields = [], collections = [], rules = [], widgets = new Map();
    let autoPermission = view.id === 'groups' && !row && !action;
    if (autoPermission && !array(draft.permissions).length) draft.permissions = [''];
    const locked = () => readOnly || busy;
    const visible = descriptor => !descriptor.when || getPath(draft, descriptor.when[0]) === descriptor.when[1];
    const pathFor = (base, descriptor) => descriptor.key == null ? base : [...base, descriptor.key];
    const keyFor = path => JSON.stringify(path);
    const report = error => { if (root.isConnected) onError(error); };
    function closePicker() { picker?.close(); picker = null; }
    function choices(descriptor) {
        let values = Array.isArray(descriptor.options) ? descriptor.options : catalogs[descriptor.options || descriptor.catalog || descriptor.suggest] || [];
        values = values.map(value => value && typeof value === 'object' ? value : { value, label: String(value) });
        if (descriptor.options === 'interiors') values = values.filter(option => !option.type || option.type === draft.type);
        return values;
    }
    function pick(parent, title, options, selected, multiple, choose) {
        if (locked()) return;
        closePicker();
        picker = catalogPicker({ parent, title, options, selected, multiple, locked, onChoose: values => { choose(values); rebuild(); }, onClose: () => { picker = null; } });
    }
    function box(parent, title, className = 'form-section') { const fieldset = element('fieldset', null, className); fieldset.append(element('legend', title)); parent.append(fieldset); return fieldset; }
    function note(parent, title) { parent.append(element('p', title, 'form-note')); }
    function asyncAction(parent, title, run) {
        const button = actionButton(title, async () => {
            if (locked()) return; pending++; button.disabled = true;
            try { const result = await run(); if (root.isConnected && !locked()) { result?.(); rebuild(); } }
            catch (error) { report(error); }
            finally { pending--; if (root.isConnected) sync(); }
        }, 'capture-position'); parent.append(button); return button;
    }
    function scalar(parent, descriptor, path, condition) {
        const wrapper = element('div', null, descriptor.type === 'boolean' ? 'field boolean' : 'field');
        const label = element('label', descriptor.label), input = element(descriptor.type === 'select' && !descriptor.custom ? 'select' : 'input');
        input.id = `structured-field-${++serial}`; label.htmlFor = input.id;
        const original = getPath(draft, path), binding = { descriptor, path, input, exists: original !== undefined, original, changed: false, condition };
        let options = choices(descriptor);
        if (descriptor.type === 'select' && !descriptor.custom) {
            options = [...options]; if (!options.some(option => option.value === original) && original != null && original !== '') options.push({ value: original, label: `${original} (atual)` });
            input.append(new Option('Selecione…', ''));
            options.forEach((option, index) => { const el = new Option(option.label ?? String(option.value), String(index)); el.selected = option.value === original; input.append(el); });
            if (original == null || original === '' && !options.some(option => option.value === '')) input.value = '';
        } else {
            input.type = descriptor.type === 'boolean' ? 'checkbox' : descriptor.type === 'number' ? 'number' : 'text';
            if (descriptor.type === 'boolean') input.checked = original === true;
            else input.value = original ?? descriptor.default ?? '';
            if (descriptor.type === 'number') { input.step = descriptor.integer ? '1' : 'any'; if (descriptor.min != null) input.min = descriptor.min; if (descriptor.max != null) input.max = descriptor.max; }
            if (descriptor.custom || descriptor.suggest) {
                const datalist = element('datalist'); datalist.id = `structured-options-${serial}`;
                for (const option of options) datalist.append(new Option(option.label ?? option.value, option.value)); wrapper.append(datalist); input.setAttribute('list', datalist.id);
            }
        }
        input.autocomplete = 'off';
        input.oninput = () => {
            if (locked() || descriptor.immutable && row) return;
            const next = descriptor.type === 'boolean' ? input.checked : descriptor.type === 'select' && !descriptor.custom ? (input.value === '' ? '' : options[Number(input.value)].value) : descriptor.type === 'number' ? (input.value === '' ? (own(descriptor, 'empty') ? descriptor.empty : descriptor.optional ? undefined : null) : Number(input.value)) : input.value;
            if (view.id === 'jobs' && path[0] === 'job' && ['xp_for_level', 'payment_for_level'].includes(path[1])) {
                const job = draft.job, total = Math.max(1, Number(job.total_nivel) || 1);
                if (path[1] === 'xp_for_level') job.xp_for_level = Array.from({ length: total - 1 }, (_, index) => job.xp_for_level?.[index] ?? 0);
                else job.payment_for_level = Array.from({ length: total }, (_, index) => job.payment_for_level?.[index] || [0, 0]);
            }
            setPath(draft, path, next); binding.changed = true;
            if (view.id === 'groups' && !row && path.length === 2 && path[0] === 'permissions' && path[1] === 0) autoPermission = false;
            if (autoPermission && path.length === 1 && path[0] === 'name') {
                const slug = String(next).normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/[^a-z0-9]/g, '');
                draft.permissions[0] = slug ? `perm.${slug}` : '';
                const permission = fields.find(field => keyFor(field.path) === '["permissions",0]'); if (permission) { permission.input.value = draft.permissions[0]; permission.changed = true; }
            }
        };
        if (descriptor.type === 'select') input.addEventListener('change', () => { input.oninput(); rebuild(); });
        if (view.id === 'houses' && path.length === 1 && path[0] === 'type') input.addEventListener('change', () => rebuild());
        if (view.id === 'jobs' && path.at(-1) === 'total_nivel') input.addEventListener('change', () => {
            const total = Number(input.value); if (!Number.isInteger(total) || total < 1 || total > 50) return;
            draft.job.xp_for_level = Array.from({ length: total - 1 }, (_, index) => draft.job.xp_for_level?.[index] ?? 0);
            if (draft.job.payment_for_level?.length) draft.job.payment_for_level = Array.from({ length: total }, (_, index) => draft.job.payment_for_level?.[index] || [0, 0]); rebuild();
        });
        fields.push(binding); wrapper.append(label, input); parent.append(wrapper);
    }
    function catalogField(parent, descriptor, path, condition) {
        const group = box(parent, descriptor.label, 'form-choice'), value = getPath(draft, path), options = choices(descriptor);
        const found = options.find(option => String(option.value) === String(value));
        const display = element('p', found?.label || value || 'Nenhuma opção selecionada', 'form-choice-name'); group.append(display);
        if (value) note(group, String(value));
        if (value && !found) note(group, 'Fora do catálogo atual · o valor existente será preservado.');
        const label = element('input'); label.type = 'hidden'; label.value = value ?? '';
        fields.push({ descriptor, path, input: label, original: value, exists: value !== undefined, condition });
        const button = actionButton(`Selecionar ${descriptor.label.toLowerCase()}`, () => pick(group, descriptor.label, options, [value], false, ([next]) => setPath(draft, path, next)));
        if (descriptor.immutable && row) button.dataset.fixedDisabled = 'true'; group.append(button);
    }
    function coordinateGroup(parent, descriptor, path, condition) {
        const group = box(parent, descriptor.label, 'form-coordinates'); widgets.set(keyFor(path), descriptor);
        const axes = ['x', 'y', 'z', ...(descriptor.heading ? [descriptor.heading] : [])];
        axes.forEach((axis, index) => scalar(group, num(descriptor.array ? index : axis, index > 2 ? 'Direção' : axis.toUpperCase(), { required: index < 3 || descriptor.headingRequired === true, optional: index > 2 && !descriptor.headingRequired, min: index > 2 ? -360 : -1000000, max: index > 2 ? 360 : 1000000 }), [...path, descriptor.array ? index : axis], condition));
        asyncAction(group, 'Usar minha posição no jogo', async () => { const result = await position(); return () => assignPosition(path, descriptor, result); });
        group.append(actionButton('Posicionar no jogo', () => capture(path, 'position', !!descriptor.heading, 'set'), 'capture-position'));
    }
    function assignPosition(path, descriptor, result) {
        if (!result || !['x', 'y', 'z'].every(axis => Number.isFinite(result[axis]))) throw new Error('Coordenadas de captura inválidas.');
        for (const [index, axis] of ['x', 'y', 'z'].entries()) setPath(draft, [...path, descriptor.array ? index : axis], result[axis]);
        if (descriptor.heading) setPath(draft, [...path, descriptor.array ? 3 : descriptor.heading], result.w ?? result.heading ?? result.h ?? 0);
    }
    function consumed(descriptor) {
        if (descriptor.key != null) return [String(descriptor.key)];
        if (descriptor.type === 'coords') return ['x', 'y', 'z', ...(descriptor.heading ? [descriptor.heading] : [])];
        if (descriptor.type === 'levels') return ['xp_for_level', 'payment_for_level', 'total_nivel'];
        if (descriptor.type === 'outfit') return ['masculino', 'feminino'];
        return (descriptor.fields || []).flatMap(consumed);
    }
    function renderObject(parent, descriptor, path, condition) {
        const group = descriptor.label ? box(parent, descriptor.label) : parent;
        for (const child of descriptor.fields || []) {
            const rendered = render(group, child, path, condition);
            if (descriptor.flexible && child.key != null && rendered) rendered.append(actionButton(`Remover opção ${child.label}`, () => { if (locked()) return; delete getPath(draft, path)[child.key]; rebuild(); }, 'delete'));
        }
        if (descriptor.range) rules.push(out => {
            if (!condition()) return; const min = getPath(out, [...path, descriptor.range[0]]), max = getPath(out, [...path, descriptor.range[1]]);
            if (min != null && max != null && Number(max) < Number(min)) throw new Error(`O máximo deve ser maior ou igual ao mínimo em ${descriptor.label}.`);
        });
        const known = new Set((descriptor.fields || []).flatMap(consumed));
        const source = getPath(draft, path), extra = source && typeof source === 'object' ? Object.keys(source).filter(key => !known.has(key) && !blocked(key) && !(view.id === 'catalog' && key === 'model')) : [];
        if (extra.length) {
            const details = element('details', null, 'form-additional'); details.append(element('summary', descriptor.flexible ? 'Outros campos' : 'Opções adicionais')); group.append(details);
            for (const key of extra) render(details, inferField(key, source[key]), path, condition);
        }
        if (descriptor.flexible) addProperty(group, path);
    }
    function addProperty(parent, path) {
        const controls = element('div', null, 'form-add-property'), name = element('input'), kind = element('select');
        name.placeholder = 'Nome da opção'; name.setAttribute('aria-label', 'Nome da nova opção');
        for (const [value, label] of [['text', 'Texto'], ['number', 'Número'], ['boolean', 'Ativar/desativar'], ['coords', 'Coordenadas'], ['list', 'Lista'], ['group', 'Grupo de campos']]) kind.append(new Option(label, value)); kind.setAttribute('aria-label', 'Tipo da nova opção');
        const add = actionButton('Adicionar opção', () => {
            const key = name.value.trim(); if (locked()) return;
            if (!key || key.length > 160 || /[\u0000-\u001f]/.test(key) || blocked(key) || own(getPath(draft, path), key)) { report(new Error('Informe um nome de opção válido e que ainda não exista.')); return; }
            setPath(draft, [...path, key], { text: '', number: 0, boolean: false, coords: { x: null, y: null, z: null }, list: [], group: {} }[kind.value]); rebuild();
        }); controls.append(name, kind, add); parent.append(controls);
    }
    function listGroup(parent, descriptor, path, condition) {
        const group = box(parent, descriptor.label, 'form-list-section'), source = getPath(draft, path), values = array(source);
        collections.push({ descriptor, path, condition }); widgets.set(keyFor(path), descriptor);
        const list = element('div', null, 'form-record-list'); group.append(list);
        values.forEach((value, index) => {
            const card = box(list, `${descriptor.entry.label || 'Registro'} ${index + 1}`, 'form-list-card');
            render(card, { ...descriptor.entry, label: descriptor.entry.type === 'object' ? null : descriptor.entry.label }, [...path, index], condition);
            card.append(actionButton('Remover registro', () => { if (locked()) return; const current = array(getPath(draft, path)); current.splice(index, 1); setPath(draft, path, current); rebuild(); }, 'delete'));
        });
        if (!values.length) note(list, 'Nenhum registro cadastrado.');
        if (descriptor.entry.type === 'catalog' || descriptor.entry.catalog) {
            group.append(actionButton(descriptor.addLabel || 'Adicionar opções', () => pick(group, descriptor.label, catalogs[descriptor.entry.catalog] || [], values, true, keys => {
                const current = array(getPath(draft, path)); for (const key of keys) if (!current.includes(key)) current.push(key); setPath(draft, path, current);
            })));
        } else group.append(actionButton(descriptor.addLabel || 'Adicionar registro', () => { if (locked()) return; const current = array(getPath(draft, path)); current.push(clone(descriptor.template ?? '')); setPath(draft, path, current); rebuild(); }));
        if (descriptor.capture) group.append(actionButton(descriptor.captureLabel || 'Posicionar novo ponto no jogo', () => capture(path, 'position', !!descriptor.heading, 'append'), 'capture-position'));
        if (descriptor.outfit) asyncAction(group, 'Adicionar fardamento atual', async () => {
            const result = await outfit(); return () => {
                validateOutfit(result); const current = array(getPath(draft, path)); current.push({ name: 'Novo fardamento', masculino: {}, feminino: {}, [result.gender]: result.outfit }); setPath(draft, path, current);
            };
        });
    }
    function mapGroup(parent, descriptor, path, condition) {
        const group = box(parent, descriptor.label, 'form-list-section'), source = getPath(draft, path) || {};
        collections.push({ descriptor, path, condition });
        for (const [key, value] of Object.entries(source)) {
            if (blocked(key)) continue;
            const card = box(group, key, 'form-list-card');
            if (descriptor.keyCatalog) {
                const option = (catalogs[descriptor.keyCatalog] || []).find(item => item.value === key); if (option) note(card, option.label);
                card.append(actionButton('Trocar item', () => pick(card, descriptor.keyLabel || 'Item', catalogs[descriptor.keyCatalog] || [], [key], false, ([next]) => {
                    const current = getPath(draft, path); if (next !== key && own(current, next)) { report(new Error('Este item já está na lista.')); return; }
                    const saved = current[key]; delete current[key]; setPath(draft, [...path, next], saved);
                })));
            } else {
                const input = element('input'); input.value = key; input.setAttribute('aria-label', descriptor.keyLabel || 'Nome do registro');
                input.onchange = () => { if (locked()) return; const next = input.value.trim(), current = getPath(draft, path); if (!next || blocked(next) || next !== key && own(current, next)) { input.value = key; report(new Error('Nome de registro inválido ou repetido.')); return; } const saved = current[key]; delete current[key]; setPath(draft, [...path, next], saved); rebuild(); }; card.append(input);
            }
            render(card, descriptor.entry, [...path, key], condition);
            card.append(actionButton('Remover registro', () => { if (locked()) return; delete getPath(draft, path)[key]; rebuild(); }, 'delete'));
        }
        if (descriptor.keyCatalog) group.append(actionButton(descriptor.addLabel || 'Adicionar item', () => pick(group, descriptor.keyLabel || 'Item', catalogs[descriptor.keyCatalog] || [], Object.keys(source), true, keys => {
            for (const key of keys) if (!own(getPath(draft, path), key)) setPath(draft, [...path, key], clone(descriptor.template));
        })));
        else {
            const name = element('input'); name.placeholder = descriptor.keyLabel || 'Nome do novo registro'; name.setAttribute('aria-label', descriptor.keyLabel || 'Nome do novo registro');
            group.append(name, actionButton('Adicionar registro', () => { const key = name.value.trim(); if (locked()) return; if (!key || blocked(key) || own(getPath(draft, path), key)) { report(new Error('Informe um nome válido e ainda não utilizado.')); return; } setPath(draft, [...path, key], clone(descriptor.template)); rebuild(); }));
        }
    }
    function polygon(parent, descriptor, path, condition) {
        const group = box(parent, descriptor.label || 'Polígono'); widgets.set(keyFor(path), descriptor);
        scalar(group, num('minZ', 'Altura mínima (minZ)', { required: true }), [...path, 'minZ'], condition);
        scalar(group, num('maxZ', 'Altura máxima (maxZ)', { required: true }), [...path, 'maxZ'], condition);
        group.append(actionButton('Desenhar polígono no jogo', () => capture(path, 'polygon', false, 'replace'), 'capture-position'));
        render(group, sequence('coords', 'Vértices do polígono', object(null, 'Vértice', [num('x', 'X', { required: true }), num('y', 'Y', { required: true })]), { x: null, y: null }, { minRows: 3 }), path, condition);
        rules.push(out => { if (!condition()) return; const value = getPath(out, path); if (Number(value?.maxZ) <= Number(value?.minZ)) throw new Error('A altura máxima do polígono deve ser maior que a mínima.'); });
    }
    function validateOutfit(result) { if (!result || !['masculino', 'feminino'].includes(result.gender) || !result.outfit || typeof result.outfit !== 'object') throw new Error('A captura não forneceu um fardamento válido.'); }
    function outfitGroup(parent, descriptor, path) {
        const group = box(parent, descriptor.label || 'Uniforme');
        for (const gender of ['masculino', 'feminino']) note(group, `${gender === 'masculino' ? 'Masculino' : 'Feminino'}: ${Object.keys(getPath(draft, [...path, gender]) || {}).length ? 'capturado' : 'não definido'}`);
        asyncAction(group, 'Capturar roupa atual', async () => { const result = await outfit(); return () => { validateOutfit(result); setPath(draft, [...path, result.gender], result.outfit); }; });
    }
    function levels(parent, path, condition) {
        const group = box(parent, 'Níveis, experiência e pagamentos'), job = getPath(draft, path) || {}, total = Math.min(50, Math.max(1, Number(job.total_nivel) || 1));
        for (let index = 0; index < total; index++) {
            const card = box(group, `Nível ${index + 1}`, 'form-level');
            if (index < total - 1) scalar(card, num(index, 'XP para o próximo nível', { min: 0, default: 0 }), [...path, 'xp_for_level', index], condition); else note(card, 'Último nível');
            scalar(card, num(0, 'Pagamento mínimo', { min: 0, default: 0 }), [...path, 'payment_for_level', index, 0], condition);
            scalar(card, num(1, 'Pagamento máximo', { min: 0, default: 0 }), [...path, 'payment_for_level', index, 1], condition);
            rules.push(out => { const pay = getPath(out, [...path, 'payment_for_level', index]); if (pay && Number(pay[1]) < Number(pay[0])) throw new Error(`Pagamento máximo menor que o mínimo no nível ${index + 1}.`); });
        }
    }
    function render(parent, descriptor, base, inherited = () => true) {
        if (descriptor.key != null && blocked(descriptor.key)) return;
        const path = pathFor(base, descriptor), condition = () => inherited() && visible(descriptor);
        const wrapper = element('div', null, 'form-widget'); wrapper.hidden = !condition(); parent.append(wrapper);
        if (descriptor.type === 'notice') { note(wrapper, descriptor.label); return; }
        if (descriptor.type === 'object' && descriptor.optionalGroup) {
            const label = element('label', null, 'field boolean'), enabled = element('input'); enabled.type = 'checkbox';
            enabled.checked = getPath(draft, path) != null;
            enabled.onchange = () => {
                if (locked()) return;
                if (enabled.checked) setPath(draft, path, clone(descriptor.template || {}));
                else { const parent = getPath(draft, path.slice(0, -1)); if (parent) delete parent[path.at(-1)]; }
                rebuild();
            };
            label.append(enabled, document.createTextNode(`Configurar ${descriptor.label.toLowerCase()}`)); wrapper.append(label);
            if (!enabled.checked) return wrapper;
        }
        if (['text', 'number', 'boolean', 'select'].includes(descriptor.type) && !descriptor.catalog) scalar(wrapper, descriptor, path, condition);
        else if (descriptor.type === 'catalog' || descriptor.catalog) catalogField(wrapper, descriptor, path, condition);
        else if (descriptor.type === 'object') renderObject(wrapper, descriptor, path, condition);
        else if (descriptor.type === 'coords') coordinateGroup(wrapper, descriptor, path, condition);
        else if (descriptor.type === 'list') listGroup(wrapper, descriptor, path, condition);
        else if (descriptor.type === 'map') mapGroup(wrapper, descriptor, path, condition);
        else if (descriptor.type === 'polygon') polygon(wrapper, descriptor, path, condition);
        else if (descriptor.type === 'outfit') outfitGroup(wrapper, descriptor, path);
        else if (descriptor.type === 'levels') levels(wrapper, path, condition);
        else if (descriptor.type === 'advanced') {
            const current = getPath(draft, path) || {};
            render(wrapper, object(null, descriptor.label, Object.entries(current).filter(([key]) => !blocked(key)).map(([key, value]) => inferField(key, value)), { flexible: true }), path, condition);
        }
        return wrapper;
    }
    function sync() {
        root.querySelectorAll('input,select,button').forEach(input => { input.disabled = locked() || input.dataset.fixedDisabled === 'true'; });
        for (const field of fields) if (!field.condition() || field.descriptor.immutable && row) field.input.disabled = true;
    }
    function rebuild() {
        closePicker(); fields = []; collections = []; rules = []; widgets = new Map(); root.replaceChildren();
        renderObject(root, { fields: schema }, [], () => true); sync();
    }
    root.addEventListener('keydown', event => { if (picker && event.key === 'Escape') { event.preventDefault(); event.stopPropagation(); closePicker(); } });
    rebuild();
    return {
        read() {
            if (pending) throw new Error('Aguarde a captura antes de salvar.');
            if (picker) throw new Error('Conclua ou cancele a seleção antes de salvar.');
            const output = clone(draft);
            for (const field of fields) {
                const { descriptor: d, path, input, condition } = field;
                if (!condition() || d.immutable && row || !field.exists && !field.changed && !d.required || field.original === null && getPath(valueAtMount, path) === null && !field.changed && !d.required) continue;
                let value = d.type === 'catalog' || d.catalog ? getPath(draft, path) : d.type === 'boolean' ? input.checked : d.type === 'select' && !d.custom ? getPath(draft, path) : input.value;
                if (d.type === 'number') value = numericField(value, d);
                if (d.required && (value == null || String(value).trim() === '')) throw new Error(`Informe ${d.label}.`);
                if (typeof value === 'string' && value !== getPath(valueAtMount, path)) value = value.trim();
                if (value === undefined && d.optional) { const parent = getPath(output, path.slice(0, -1)); if (parent) delete parent[path.at(-1)]; }
                else setPath(output, path, value);
            }
            for (const { descriptor: d, path, condition } of collections) {
                if (!condition()) continue; const value = getPath(output, path), count = value ? Object.keys(value).length : 0;
                if (d.minRows && count < d.minRows) throw new Error(`Cadastre ao menos ${d.minRows} registro(s) em ${d.label}.`);
                if (d.maxRows && count > d.maxRows) throw new Error(`A lista ${d.label} excede o limite.`);
            }
            for (const rule of rules) rule(output);
            if (view.id === 'catalog' && !action) output.data.model = output.spawn;
            return output;
        },
        setBusy(next) { busy = next; sync(); },
        applyCapture(path, result, mode, kind) {
            if (locked()) return;
            try {
                const descriptor = widgets.get(keyFor(path)); if (!descriptor) throw new Error('O destino da captura mudou. Abra o cadastro novamente.');
                if (kind === 'polygon') {
                    if (!Array.isArray(result?.coords) || result.coords.length < 3 || !Number.isFinite(result.minZ) || !Number.isFinite(result.maxZ)) throw new Error('Polígono capturado inválido.');
                    const previous = getPath(draft, path) || {}; setPath(draft, path, { ...previous, coords: clone(result.coords), minZ: result.minZ, maxZ: result.maxZ });
                } else if (mode === 'append') {
                    const values = array(getPath(draft, path)); const value = clone(descriptor.template); values.push(value); setPath(draft, path, values);
                    assignPosition(descriptor.pointKey ? [...path, values.length - 1, descriptor.pointKey] : [...path, values.length - 1], { array: descriptor.array, heading: descriptor.heading }, result);
                } else assignPosition(path, descriptor, result);
                rebuild();
            } catch (error) { report(error); }
        }
    };
}
