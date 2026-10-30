// Editable configuration only. Ownership, residents, tax dates and furniture are
// runtime state owned by m_mansions and never form part of a save payload.
const point = value => ({ x: value?.x ?? null, y: value?.y ?? null, z: value?.z ?? null });
const sequence = value => Array.isArray(value) ? value : Object.values(value || {});
export const MANSION_VOUCHERS = {
    valemansao500k: 'Vale Mansão 500K', valemansao1m: 'Vale Mansão 1M',
    valemansao8m: 'Vale Mansão 8M', valemansao10m: 'Vale Mansão 10M', valemansao100m: 'Vale Mansão 100M'
};
export function mansionPermission(group) {
    const slug = String(group || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/[^a-z0-9]/g, '');
    return slug ? `perm.${slug}` : '';
}
export function mansionDoor(value) {
    return { hash: value?.hash ?? null, ...point(value), dist: value?.dist ?? 5, isGate: value?.isGate === true, text: value?.text !== false, lock: true };
}
export function mansionEditable(value = {}) {
    return {
        name: value.name || '', group: value.group || '', price: value.price ?? 0, iptuValue: value.iptuValue ?? 1,
        voucher: value.voucher || '', maxResidents: value.maxResidents ?? 1, purchaseCoords: point(value.purchaseCoords),
        chest: { enabled: value.chest?.enabled === true, weight: value.chest?.weight ?? 1, coords: point(value.chest?.coords) },
        garage: { enabled: value.garage?.enabled === true, type: value.garage?.type || '', blipDistance: value.garage?.blipDistance ?? 5,
            coords: point(value.garage?.coords), spawnCoords: sequence(value.garage?.spawnCoords).map(coords => ({ ...point(coords), w: coords.w ?? 0 })) },
        doors: sequence(value.doors).map(mansionDoor)
    };
}

function node(tag, text, className) { const element = document.createElement(tag); if (text != null) element.textContent = text; if (className) element.className = className; return element; }
function action(text, handler, className = '') { const element = node('button', text, className); element.type = 'button'; element.onclick = handler; return element; }
function number(value, label, minimum, integer = false) {
    if (value === '' || value == null) throw new Error(`Informe ${label}.`);
    const parsed = Number(value);
    if (!Number.isFinite(parsed) || (minimum != null && parsed < minimum) || (integer && !Number.isInteger(parsed))) throw new Error(`Valor inválido em ${label}.`);
    return parsed;
}

export function mountMansionForm({ container, value, row, garageTypes = [], allowedVouchers = MANSION_VOUCHERS, readOnly = false, capture, onError }) {
    const draft = mansionEditable(value), controls = new Map(); let serial = 0, busy = false;
    const pathKey = path => JSON.stringify(path);
    const get = path => path.reduce((parent, key) => parent[key], draft);
    const set = (path, next) => { let parent = draft; for (const key of path.slice(0, -1)) parent = parent[key]; parent[path.at(-1)] = next; };
    function section(title, description) {
        const fieldset = node('fieldset', null, 'mansion-section'); fieldset.append(node('legend', title));
        if (description) fieldset.append(node('p', description, 'mansion-description')); container.append(fieldset); return fieldset;
    }
    function field(parent, title, path, { type = 'text', min, required = true, options = null, step = 'any' } = {}) {
        const holder = node('div', null, type === 'checkbox' ? 'field boolean' : 'field'); const id = `mansion-field-${++serial}`;
        const label = node('label', title); label.htmlFor = id; holder.append(label);
        let input;
        if (options) {
            input = node('select'); input.append(new Option('Selecione…', ''));
            for (const [key, title] of Object.entries(options)) input.append(new Option(title, key));
        } else { input = node('input'); input.type = type; if (type === 'number') { input.step = step; if (min != null) input.min = String(min); } }
        input.id = id; input.required = required && type !== 'checkbox'; input.disabled = readOnly;
        if (type === 'checkbox') input.checked = get(path); else input.value = get(path) ?? '';
        input.oninput = () => { set(path, type === 'checkbox' ? input.checked : input.value); if (pathKey(path) === '["group"]') permission.value = mansionPermission(input.value); };
        holder.append(input); parent.append(holder); controls.set(pathKey(path), { input, type, required, min, title, path }); return input;
    }
    function captureButton(parent, text, path, heading = false, mode = 'set', kind = 'position') {
        const button = action(text, () => capture(path, kind, heading, mode), 'capture-position'); button.disabled = readOnly; parent.append(button); return button;
    }
    function coordinates(parent, title, path, heading = false) {
        const group = node('fieldset', null, 'object-group mansion-coordinate'); group.append(node('legend', title));
        for (const axis of ['x', 'y', 'z', ...(heading ? ['w'] : [])]) field(group, axis === 'w' ? 'Direção' : axis.toUpperCase(), [...path, axis], { type: 'number' });
        captureButton(group, 'Posicionar no jogo', path, heading); parent.append(group); return group;
    }
    const identification = section('Identificação da mansão', 'Cargo, permissão e acessos são administrados pelas integrações existentes da base.');
    field(identification, 'Nome da mansão', ['name']); field(identification, 'Cargo da mansão', ['group']);
    const permissionHolder = node('div', null, 'field'); const permissionLabel = node('label', 'Permissão prevista');
    const permission = node('input'); permission.id = 'mansion-permission'; permissionLabel.htmlFor = permission.id; permission.readOnly = true; permission.value = mansionPermission(draft.group);
    permissionHolder.append(permissionLabel, permission); identification.append(permissionHolder);
    field(identification, 'Valor da mansão', ['price'], { type: 'number', min: 0 });
    field(identification, 'Valor do IPTU', ['iptuValue'], { type: 'number', min: 1 });
    const vouchers = { ...allowedVouchers }; if (draft.voucher && !vouchers[draft.voucher]) vouchers[draft.voucher] = `${draft.voucher} (atual)`;
    field(identification, 'Vale necessário para comprar', ['voucher'], { options: vouchers });
    field(identification, 'Máximo de moradores', ['maxResidents'], { type: 'number', min: 1, step: '1' });
    coordinates(identification, 'Local de compra', ['purchaseCoords']);

    const chest = section('Baú da mansão'); const chestEnabled = field(chest, 'Ativar baú da mansão', ['chest', 'enabled'], { type: 'checkbox', required: false });
    const chestFields = node('div', null, 'mansion-subfields'); chest.append(chestFields);
    field(chestFields, 'Capacidade do baú (kg)', ['chest', 'weight'], { type: 'number', min: 1 }); coordinates(chestFields, 'Local do baú', ['chest', 'coords']);

    const garage = section('Garagem da mansão'); const garageEnabled = field(garage, 'Ativar garagem da mansão', ['garage', 'enabled'], { type: 'checkbox', required: false });
    const garageFields = node('div', null, 'mansion-subfields'); garage.append(garageFields);
    const types = Object.fromEntries(sequence(garageTypes).map(type => [type.name, type.name])); if (draft.garage.type && !types[draft.garage.type]) types[draft.garage.type] = `${draft.garage.type} (atual)`;
    field(garageFields, 'Tipo da garagem', ['garage', 'type'], { options: types });
    field(garageFields, 'Distância do marcador', ['garage', 'blipDistance'], { type: 'number', min: 0.1 });
    coordinates(garageFields, 'Local da garagem', ['garage', 'coords']);
    const spawnGroup = node('fieldset', null, 'object-group'); spawnGroup.append(node('legend', 'Posições de saída dos veículos')); garageFields.append(spawnGroup);
    const spawnList = node('div', null, 'mansion-list'); spawnGroup.append(spawnList);
    const resetControls = prefix => { for (const [key, control] of controls) if (prefix.every((part, index) => control.path[index] === part)) controls.delete(key); };
    function renderSpawns() {
        resetControls(['garage', 'spawnCoords']); spawnList.replaceChildren();
        draft.garage.spawnCoords.forEach((coords, index) => {
            const item = node('div', null, 'mansion-list-card'); item.append(node('strong', `Vaga ${index + 1}`));
            coordinates(item, 'Posição e direção', ['garage', 'spawnCoords', index], true);
            const remove = action('Remover vaga', () => { syncInputs(); draft.garage.spawnCoords.splice(index, 1); renderSpawns(); syncToggles(); }, 'delete'); remove.disabled = readOnly; item.append(remove); spawnList.append(item);
        });
        if (!draft.garage.spawnCoords.length) spawnList.append(node('p', 'Nenhuma vaga cadastrada.', 'mansion-description'));
    }
    const manualSpawn = action('Adicionar vaga manual', () => { syncInputs(); draft.garage.spawnCoords.push({ ...point(), w: 0 }); renderSpawns(); syncToggles(); }); manualSpawn.disabled = readOnly; spawnGroup.append(manualSpawn);
    captureButton(spawnGroup, 'Capturar nova vaga no jogo', ['garage', 'spawnCoords'], true, 'append');
    renderSpawns();

    const doors = section('Trancas da mansão', 'Cada tranca recebe a permissão da mansão ao salvar. Capturar portas substitui a lista atual apenas no formulário.');
    const doorList = node('div', null, 'mansion-list'); doors.append(doorList);
    function renderDoors() {
        resetControls(['doors']); doorList.replaceChildren();
        draft.doors.forEach((door, index) => {
            const item = node('fieldset', null, 'object-group mansion-door'); item.append(node('legend', `Tranca ${index + 1}`));
            field(item, 'Modelo da porta (hash)', ['doors', index, 'hash'], { type: 'number', step: '1' });
            field(item, 'Distância de acesso', ['doors', index, 'dist'], { type: 'number', min: 0.1 });
            for (const axis of ['x', 'y', 'z']) field(item, axis.toUpperCase(), ['doors', index, axis], { type: 'number' });
            field(item, 'É um portão', ['doors', index, 'isGate'], { type: 'checkbox', required: false }); field(item, 'Exibir texto da tranca', ['doors', index, 'text'], { type: 'checkbox', required: false });
            const remove = action('Remover tranca', () => { syncInputs(); draft.doors.splice(index, 1); renderDoors(); }, 'delete'); remove.disabled = readOnly; item.append(remove); doorList.append(item);
        });
        if (!draft.doors.length) doorList.append(node('p', 'Nenhuma tranca cadastrada.', 'mansion-description'));
    }
    renderDoors();
    captureButton(doors, 'Capturar trancas no jogo', ['doors'], false, 'replace', 'doors');
    const manualDoor = action('Adicionar tranca manual', () => { syncInputs(); draft.doors.push(mansionDoor()); renderDoors(); }); manualDoor.disabled = readOnly; doors.append(manualDoor);
    const clearDoors = action('Limpar trancas do formulário', () => { syncInputs(); draft.doors = []; renderDoors(); }); clearDoors.disabled = readOnly; doors.append(clearDoors);
    if (row?.ownerId) { const info = section('Ocupação atual'); info.append(node('p', `Proprietário: ID ${row.ownerId} · ${row.occupiedCount ?? sequence(row.residents).length} de ${row.maxResidents} moradores. Estes dados são somente leitura.`, 'mansion-description')); }

    function syncInputs() { for (const { input, type, path } of controls.values()) set(path, type === 'checkbox' ? input.checked : input.value); }
    function syncToggles() {
        for (const [enabled, fields] of [[chestEnabled, chestFields], [garageEnabled, garageFields]]) {
            fields.classList.toggle('inactive', !enabled.checked);
            fields.querySelectorAll('input,select,button').forEach(input => { input.disabled = readOnly || busy || !enabled.checked; });
        }
    }
    chestEnabled.addEventListener('change', syncToggles); garageEnabled.addEventListener('change', syncToggles); syncToggles();
    return {
        read() {
            syncInputs(); const output = mansionEditable(draft);
            output.name = output.name.trim(); output.group = output.group.trim();
            if (!output.name || !output.group || !mansionPermission(output.group)) throw new Error('Informe o nome e um cargo válido para a mansão.');
            if (!output.voucher) throw new Error('Selecione o vale necessário para comprar.');
            output.price = number(output.price, 'valor da mansão', 0); output.iptuValue = number(output.iptuValue, 'IPTU', 1); output.maxResidents = number(output.maxResidents, 'máximo de moradores', 1, true);
            const readPoint = (coords, title, heading = false) => { const result = { x: number(coords.x, `${title}: X`), y: number(coords.y, `${title}: Y`), z: number(coords.z, `${title}: Z`) }; if (heading) result.w = number(coords.w, `${title}: direção`); return result; };
            output.purchaseCoords = readPoint(output.purchaseCoords, 'local de compra');
            if (output.chest.enabled) { output.chest.weight = number(output.chest.weight, 'capacidade do baú', 1); output.chest.coords = readPoint(output.chest.coords, 'local do baú'); } else output.chest = { enabled: false };
            if (output.garage.enabled) {
                if (!output.garage.type) throw new Error('Selecione o tipo da garagem.');
                output.garage.blipDistance = number(output.garage.blipDistance, 'distância do marcador', 0.1); output.garage.coords = readPoint(output.garage.coords, 'local da garagem');
                if (!output.garage.spawnCoords.length) throw new Error('Cadastre ao menos uma vaga de saída.');
                output.garage.spawnCoords = output.garage.spawnCoords.map((coords, index) => readPoint(coords, `vaga ${index + 1}`, true));
            } else output.garage = { enabled: false };
            output.doors = output.doors.map((door, index) => ({ ...mansionDoor(door), ...readPoint(door, `tranca ${index + 1}`), hash: number(door.hash, 'modelo da porta', undefined, true), dist: number(door.dist, 'distância da tranca', 0.1) }));
            return output;
        },
        applyCapture(path, data, mode, kind) {
            syncInputs();
            if (kind === 'doors') { draft.doors = sequence(data?.doors).map(mansionDoor); renderDoors(); return; }
            if (!data || ![data.x, data.y, data.z].every(Number.isFinite)) { onError(new Error('A captura não forneceu coordenadas válidas.')); return; }
            if (mode === 'append') { draft.garage.spawnCoords.push({ ...point(data), w: data.w ?? data.heading ?? 0 }); renderSpawns(); syncToggles(); return; }
            const current = get(path); Object.assign(current, point(data)); if (Object.hasOwn(current, 'w')) current.w = data.w ?? data.heading ?? 0;
            for (const axis of ['x', 'y', 'z', 'w']) { const field = controls.get(pathKey([...path, axis])); if (field) field.input.value = current[axis]; }
        },
        setBusy(next) { busy = next; container.querySelectorAll('input,select,button').forEach(input => { input.disabled = readOnly || busy; }); syncToggles(); permission.readOnly = true; }
    };
}
