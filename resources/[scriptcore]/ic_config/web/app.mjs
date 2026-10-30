import { createTransport, createLatestLoader, createWriteGate, PanelError } from './transport.mjs';
import { AREAS, VIEWS, recordsFor, displayName, editorValue, mutationFor, clone, withoutPrivate, teleportCoords } from './model.mjs';
import { mountMansionForm } from './mansions.mjs';

const $ = selector => document.querySelector(selector);
const preview = typeof GetParentResourceName !== 'function' && new URLSearchParams(location.search).get('preview') === '1';
const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'ic_config';
const transport = createTransport({ resource });
const writes = createWriteGate();
let activeArea = 'groups', activeView = VIEWS[0], data = null, rows = [], opened = false;
let editor = null, deletion = null, toastTimer = null, pendingView = null;
let writesEnabled = false, methods = new Map(), openGeneration = 0, editorSequence = 0, suspended = false;
let deletionExpiryTimer = null;
let teleportPending = null;
const captureTargets = new Map();
const labels = {
    name: 'Nome', id: 'Identificador', type: 'Tipo', data: 'Configuração', config: 'Propriedades do cargo',
    permissions: 'Permissões', permission: 'Permissão', permiss: 'Permissão', permissao: 'Permissão',
    weight: 'Capacidade (kg)', coords: 'Coordenadas', spawnCoords: 'Posições de saída',
    blipDistance: 'Distância do marcador', blip: 'Ícone no mapa', showBlip: 'Exibir no mapa',
    price: 'Preço', stock: 'Estoque', spawn: 'Spawn do veículo', model: 'Modelo', trunk: 'Porta-malas (kg)',
    banned: 'Bloqueado', group: 'Cargo', gtype: 'Tipo de cargo', salario: 'Salário', title: 'Título',
    orgName: 'Organização', orgType: 'Tipo da organização', goalItem: 'Item da meta', goalAmount: 'Quantidade da meta', defaultReward: 'Recompensa padrão',
    sprite: 'Ícone (sprite)', color: 'Cor', scale: 'Escala', shortRange: 'Exibir somente próximo',
    room: 'Ponto de fardamento', uniforms: 'Fardamentos', bench: 'Bancada', farm: 'Farm vinculado',
    craftPermission: 'Permissão de craft', armazemPermission: 'Permissão do armazém', craftItems: 'Receitas', armazemItems: 'Materiais do armazém',
    enabled: 'Ativado', rewardType: 'Identificador da recompensa', routeType: 'Tipo de rota', rewards: 'Recompensas',
    items: 'Itens', mode: 'Modo', perm: 'Permissão', onlyWalletPayment: 'Pagamento somente na carteira',
    debug: 'Modo de depuração', zones: 'Polígonos', useESX: 'Usar ESX', useWhitelist: 'Usar lista de acesso', checkLoopTime: 'Intervalo de verificação', whitelist: 'Lista de acesso',
    inicio: 'Local de início', local_veiculo: 'Local do veículo', local_ferramentas: 'Local das ferramentas', local_finalizar: 'Local de finalização',
    precisa_de_item: 'Exigir item', itens_necessarios: 'Itens necessários', job: 'Emprego', extra: 'Regras específicas',
    central: 'Central de empregos', npc: 'NPC da central', interior: 'Interior', residents: 'Moradores', vault: 'Capacidade do baú', fridge: 'Capacidade da geladeira',
    vaultCoords: 'Posição do baú', wardobeCoords: 'Posição do guarda-roupas', slot: 'Vagas', trade: 'Troca', valor: 'Valor',
    purchaseCoords: 'Local de compra', iptuValue: 'IPTU', maxResidents: 'Limite de moradores', chest: 'Baú', garage: 'Garagem', doors: 'Portas',
    settings: 'Regras gerais', testDrive: 'Test drive', categories: 'Categorias', vips: 'Benefícios VIP', vehicles: 'Veículos',
    x: 'X', y: 'Y', z: 'Z', w: 'Direção', h: 'Direção', heading: 'Direção'
};
const label = key => labels[key] || key;

function showError(target, error) {
    target.hidden = false;
    target.textContent = error?.message || 'Não foi possível concluir a operação.';
    if (error?.code) { const code = document.createElement('small'); code.textContent = `Código: ${error.code}`; target.append(code); }
}
function toast(message) {
    clearTimeout(toastTimer); $('#toast').textContent = message; $('#toast').hidden = false;
    toastTimer = setTimeout(() => { $('#toast').hidden = true; }, 4500);
}
function button(text, callback, className = '') {
    const node = document.createElement('button'); node.type = 'button'; node.textContent = text; node.className = className; node.onclick = callback; return node;
}
function disableWrites() { return preview || !writesEnabled || writes.busy; }
function unavailable(method) { return methods.get(method)?.available === false; }
function sample(view) {
    if (view.id === 'groups') return [{ name: 'Exemplo de cargo', config: { title: 'Dados fictícios' }, permissions: ['perm.exemplo'] }];
    if (view.id === 'chests') return [{ name: 'Baú de demonstração', weight: 100, permission: 'perm.exemplo', coords: { x: 1, y: 2, z: 3 } }];
    if (view.singleton) return {};
    const containers = { craft: { benches: [] }, desmanche: { desmanches: [] }, safezone: { safezones: [] }, jobs: { jobs: {} }, robberies: { locations: [], setups: {} }, houses: { residences: [], interiors: {} }, mansions: { mansions: [] }, dealership: { vehicles: {} } };
    return containers[view.id] || [];
}
const loader = createLatestLoader(async view => ({ view, value: preview ? sample(view) : await transport.call(view.read) }), ({ view, value }) => {
    if (!opened || activeView.id !== view.id) return;
    data = value; rows = recordsFor(view, value); $('#loading').hidden = true; $('#refresh').disabled = false;
    $('#error').hidden = true; renderRecords();
});

async function load() {
    $('#loading').hidden = false; $('#refresh').disabled = true; $('#error').hidden = true;
    data = null; rows = []; renderRecords();
    try { await loader.run(activeView); }
    catch (error) { $('#loading').hidden = true; $('#refresh').disabled = false; showError($('#error'), error); renderRecords(); }
}
function setArea(area) {
    activeArea = area; activeView = VIEWS.find(view => view.area === area); $('#search').value = ''; updateNavigation(); load();
}
function updateNavigation() {
    document.querySelectorAll('#navigation button').forEach(node => node.setAttribute('aria-current', node.dataset.area === activeArea ? 'page' : 'false'));
    const area = AREAS.find(([id]) => id === activeArea);
    $('#title').textContent = area[1]; $('#subtitle').textContent = 'Cadastros e integrações da sua base.';
    $('#tabs').replaceChildren(...VIEWS.filter(view => view.area === activeArea).map(view => {
        const tab = button(view.title, () => { activeView = view; $('#search').value = ''; updateNavigation(); load(); });
        tab.setAttribute('role', 'tab'); tab.setAttribute('aria-selected', String(view.id === activeView.id)); return tab;
    }));
    $('#view-note').textContent = activeView.note || ''; $('#view-note').hidden = !activeView.note;
    $('#create').hidden = !activeView.create; $('#create').disabled = disableWrites() || data === null || unavailable(activeView.create);
    $('#create').textContent = activeView.id === 'fac' ? 'Criar organização' : 'Novo cadastro';
    $('#additional').hidden = !activeView.extraAction;
    $('#additional').textContent = activeView.extraAction?.label || '';
    $('#additional').title = methods.get(activeView.extraAction?.method)?.reason || '';
    $('#additional').disabled = disableWrites() || data === null || unavailable(activeView.extraAction?.method);
}
async function teleportTo(row, view) {
    const coords = teleportCoords(view, row);
    if (!coords || preview || writes.busy || teleportPending) return;
    const pending = {}, generation = openGeneration;
    teleportPending = pending; renderRecords();
    try {
        await transport.call('teleport', { coords });
        if (opened && generation === openGeneration) await closePanel();
    } catch (error) {
        if (opened && generation === openGeneration) showError($('#error'), error);
    } finally {
        if (teleportPending === pending) teleportPending = null;
        if (opened && generation === openGeneration) renderRecords();
    }
}
function renderRecords() {
    updateNavigation();
    const query = $('#search').value.toLocaleLowerCase('pt-BR');
    const filtered = rows.filter(row => JSON.stringify(row).toLocaleLowerCase('pt-BR').includes(query));
    $('#count').textContent = data === null ? 'Aguardando dados do servidor' : `${filtered.length} de ${rows.length} ${activeView.singleton ? 'configuração' : 'cadastros'}`;
    const children = filtered.map(row => {
        const card = document.createElement('article'); card.className = 'record';
        const identity = document.createElement('div'); const name = document.createElement('div'); name.className = 'name';
        name.textContent = activeView.singleton ? activeView.title : displayName(row); identity.append(name);
        const sub = document.createElement('div'); sub.className = 'identity'; sub.textContent = row.name || row.spawn || row.id || activeView.read; identity.append(sub);
        const details = document.createElement('div'); details.className = 'details';
        details.textContent = row.permission || row.permiss || row.permissao || row.data?.name || row.config?.title || (row.stock != null ? `Estoque: ${row.stock}` : Object.keys(row).filter(key => !['name', 'id', 'spawn'].includes(key)).map(label).slice(0, 4).join(' · '));
        const actions = document.createElement('div'); actions.className = 'row-actions';
        if (teleportCoords(activeView, row)) {
            const view = activeView;
            const teleport = button('Teleportar', () => teleportTo(row, view));
            teleport.disabled = preview || writes.busy || !!teleportPending || unavailable('teleport');
            teleport.title = methods.get('teleport')?.reason || 'Teleportar para o ponto cadastrado';
            actions.append(teleport);
        }
        if (activeView.update) { const edit = button(disableWrites() ? 'Ver detalhes' : 'Editar', () => openEditor(row)); edit.title = methods.get(activeView.update)?.reason || ''; actions.append(edit); }
        if (activeView.remove) { const remove = button('Excluir', () => askDelete(row), 'delete'); remove.disabled = disableWrites() || unavailable(activeView.remove); remove.title = methods.get(activeView.remove)?.reason || ''; actions.append(remove); }
        card.append(identity, details, actions); return card;
    });
    if (!children.length) {
        const empty = document.createElement('div'); empty.className = 'empty'; const heading = document.createElement('strong');
        heading.textContent = data === null ? ($('#error').hidden ? 'Conectando às configurações' : 'Dados indisponíveis') : query ? 'Nenhum resultado' : 'Nenhum cadastro';
        const message = document.createElement('span'); message.textContent = data === null ? ($('#error').hidden ? 'Os dados aparecem após a resposta do servidor.' : 'Consulte a mensagem acima para verificar esta integração.') : query ? 'Experimente outro termo de busca.' : activeView.create ? 'Use Novo cadastro para começar.' : 'Esta seção depende das configurações disponíveis na base.';
        empty.append(heading, message); children.push(empty);
    }
    $('#records').replaceChildren(...children);
}

function getAt(object, path) { return path.reduce((parent, key) => parent?.[key], object); }
function setAt(object, path, value) { let target = object; for (const key of path.slice(0, -1)) target = target[key]; target[path.at(-1)] = value; }
function coordinateObject(value) { return value && typeof value === 'object' && !Array.isArray(value) && ['x', 'y', 'z'].every(key => Object.hasOwn(value, key)); }
async function captureInGame(path, kind, heading = false, mode = 'set') {
    if (!editor || preview) return;
    const target = `${editor.token}:${mode}:${JSON.stringify(path)}`;
    captureTargets.set(target, { token: editor.token, path, kind, mode });
    const method = kind === 'polygon' ? 'startSafeZonePolygon' : kind === 'doors' ? 'startMansionDoorCapture' : 'startPositionCapture';
    try { await transport.call(method, { target, heading }); }
    catch (error) { captureTargets.delete(target); showError($('#editor-error'), error); }
}
function renderFields(value, parent, path = [], depth = 0) {
    const entries = Object.entries(value);
    for (const [key, child] of entries) {
        const fieldPath = [...path, key];
        if (child && typeof child === 'object' && !Array.isArray(child) && Object.keys(child).length && depth < 2) {
            const group = document.createElement('fieldset'); group.className = 'object-group';
            const legend = document.createElement('legend'); legend.textContent = label(key); group.append(legend);
            renderFields(child, group, fieldPath, depth + 1);
            if (coordinateObject(child)) {
                const capture = button('Usar minha posição no jogo', async () => {
                    capture.disabled = true;
                    try {
                        const coords = await transport.call('getPlayerPosition');
                        if (!editor) return;
                        for (const axis of ['x', 'y', 'z', 'w', 'h', 'heading']) {
                            if (!Object.hasOwn(child, axis)) continue;
                            const next = ['w', 'h', 'heading'].includes(axis) ? (coords.w ?? coords.heading ?? 0) : coords[axis];
                            setAt(editor.draft, [...fieldPath, axis], next);
                            const input = editor.inputs.find(item => JSON.stringify(item.path) === JSON.stringify([...fieldPath, axis]));
                            if (input) input.node.value = next;
                        }
                    } catch (error) { showError($('#editor-error'), error); }
                    finally { capture.disabled = false; }
                }, 'capture-position'); capture.disabled = preview; group.append(capture);
                const position = button('Posicionar no jogo', () => captureInGame(fieldPath, 'position', ['w', 'h', 'heading'].some(axis => Object.hasOwn(child, axis))), 'capture-position'); position.disabled = preview; group.append(position);
            }
            parent.append(group); continue;
        }
        const holder = document.createElement('div'); holder.className = 'field';
        const id = `field-${editor.inputs.length}`;
        const title = document.createElement('label'); title.htmlFor = id; title.textContent = label(key); holder.append(title);
        let node, kind;
        if (child !== null && typeof child === 'object') {
            kind = 'json'; node = document.createElement('textarea'); node.spellcheck = false; node.value = JSON.stringify(child, null, 2); holder.classList.add('wide');
            const hint = document.createElement('small'); hint.textContent = Array.isArray(child) ? 'Lista JSON. Preserve os campos e o formato de cada elemento.' : 'Objeto JSON. Preserve os campos exigidos pelo recurso.'; holder.append(hint);
        } else if (typeof child === 'boolean') {
            kind = 'boolean'; node = document.createElement('input'); node.type = 'checkbox'; node.checked = child; holder.classList.add('boolean');
        } else if (typeof child === 'number' || child === null) {
            kind = 'number'; node = document.createElement('input'); node.type = 'number'; node.step = 'any'; node.value = child ?? ''; node.required = child === null;
        } else {
            kind = 'string'; node = document.createElement('input'); node.type = 'text'; node.value = String(child ?? '');
        }
        node.id = id; node.autocomplete = 'off'; holder.append(node);
        editor.inputs.push({ node, path: fieldPath, kind, original: child });
        if (key === 'zones' && Array.isArray(child)) {
            const polygon = button('Desenhar polígono no jogo', () => captureInGame(fieldPath, 'polygon'), 'capture-position'); polygon.disabled = preview; holder.append(polygon);
            const hint = document.createElement('small'); hint.textContent = 'E adiciona um vértice · Backspace conclui · X cancela. Revise minZ e maxZ no JSON após capturar.'; holder.append(hint);
        }
        if (key === 'uniforms' && Array.isArray(child)) {
            const capture = button('Adicionar fardamento atual', async () => {
                capture.disabled = true;
                try {
                    const current = await transport.call('getCurrentOutfit');
                    if (!['masculino', 'feminino'].includes(current?.gender) || !current.outfit) throw new Error('Roupa atual indisponível.');
                    const uniforms = JSON.parse(node.value); if (!Array.isArray(uniforms)) throw new Error('Fardamentos precisam ser uma lista JSON.');
                    uniforms.push({ name: 'Novo fardamento', masculino: {}, feminino: {}, [current.gender]: current.outfit }); node.value = JSON.stringify(uniforms, null, 2);
                } catch (error) { showError($('#editor-error'), error); } finally { capture.disabled = false; }
            }, 'capture-position'); capture.disabled = preview; holder.append(capture);
        }
        parent.append(holder);
    }
}
async function openEditor(row = null, extra = false) {
    if ((disableWrites() && !row) || writes.busy) return;
    const action = extra ? activeView.extraAction : null;
    captureTargets.clear();
    editor = { token: `e${++editorSequence}`, view: activeView, row, action, readOnly: disableWrites() || unavailable(activeView.update), draft: action ? withoutPrivate(action.initial(row)) : editorValue(activeView, row, data), inputs: [] };
    $('#editor-title').textContent = action?.label || (activeView.singleton ? activeView.title : row ? `Editar ${displayName(row)}` : `Novo · ${activeView.title}`);
    $('#editor-error').hidden = true; $('#fields').replaceChildren();
    if (activeView.id === 'mansions') {
        const current = editor;
        $('#save').disabled = true; $('#fields').textContent = 'Carregando tipos de garagem…'; $('#editor').showModal();
        try {
            const garageTypes = preview ? [] : await transport.call('getGarageTypes');
            if (editor !== current || !$('#editor').open) return;
            $('#fields').replaceChildren();
            editor.custom = mountMansionForm({ container: $('#fields'), value: editor.draft, row, garageTypes, allowedVouchers: data?.allowedVouchers,
                readOnly: editor.readOnly, capture: captureInGame, onError: error => showError($('#editor-error'), error) });
        } catch (error) { if (editor !== current) return; showError($('#editor-error'), error); editor.readOnly = true; }
    } else {
        renderFields(editor.draft, $('#fields'));
        if (action?.previewMethod) {
            const current = editor;
            const statusButton = button('Consultar exclusão pendente', async () => {
                try {
                    const value = readDraft(); editorBusy(true);
                    const status = await transport.call('getFacDeletionStatus', { orgName: value.orgName });
                    if (editor !== current || !opened) return;
                    if (status.state === 'none' || status.state === 'complete' || status.state === 'recreated') { toast(status.state === 'none' ? 'Não há exclusão pendente para esta organização.' : 'A exclusão anterior já foi concluída.'); return; }
                    displayRecoveryStatus(status, current.view.id);
                } catch (error) { showError($('#editor-error'), error); }
                finally { editorBusy(false); }
            }, 'capture-position'); $('#fields').append(statusButton);
        }
        const hint = document.createElement('p'); hint.className = 'json-help'; hint.textContent = 'Listas e configurações complexas usam JSON. Campos privados são mantidos no servidor.'; $('#fields').append(hint);
    }
    $('#save').textContent = action?.previewMethod ? 'Visualizar impacto' : action?.danger ? 'Continuar para exclusão' : 'Salvar alterações';
    $('#save').disabled = editor.readOnly;
    $('#edit-hint').textContent = editor.readOnly ? 'Visualização · Gravação indisponível.' : 'Revise os campos antes de salvar.';
    if (editor.readOnly) $('#fields').querySelectorAll('input,textarea,button').forEach(node => { node.disabled = true; });
    if (!$('#editor').open) $('#editor').showModal(); $('#fields input, #fields textarea, #fields select')?.focus();
}
function readDraft() {
    if (editor.custom) return editor.custom.read();
    const result = clone(editor.draft);
    for (const item of editor.inputs) {
        let value;
        if (item.kind === 'json') {
            try { value = JSON.parse(item.node.value); }
            catch { throw new Error(`JSON inválido no campo ${label(item.path.at(-1))}.`); }
            if (Array.isArray(item.original) ? !Array.isArray(value) : !value || typeof value !== 'object' || Array.isArray(value)) throw new Error(`Preserve o formato do campo ${label(item.path.at(-1))}.`);
        } else if (item.kind === 'number') {
            if (!item.node.value.trim()) throw new Error(`Informe ${label(item.path.at(-1))}.`);
            value = Number(item.node.value); if (!Number.isFinite(value)) throw new Error(`Número inválido em ${label(item.path.at(-1))}.`);
        } else value = item.kind === 'boolean' ? item.node.checked : item.node.value.trim();
        setAt(result, item.path, value);
    }
    return withoutPrivate(result);
}
function editorBusy(busy) { $('#edit-form').querySelectorAll('button,input,textarea,select').forEach(node => { node.disabled = busy; }); editor?.custom?.setBusy(busy); $('#cancel-editor').disabled = busy; }
async function commit(method, payload) {
    if (preview || !writesEnabled) throw new Error('Gravação desativada.');
    return writes.run(async () => {
        const result = await transport.call(method, payload);
        if (result?.state === 'recovery_required') throw new PanelError('RECOVERY_REQUIRED', result.message || 'A operação exige reconciliação manual. Confira o estado antes de continuar.');
        toast(result?.message || 'Alteração concluída.');
        return result;
    });
}
function askDelete(row) {
    deletion = { method: activeView.remove, payload: activeView.deletePayload(row), name: displayName(row), viewId: activeView.id };
    $('#confirmation-message').textContent = `Excluir “${deletion.name}”? Esta operação altera os dados administrados pelo recurso da base. Revise o cadastro antes de confirmar.`;
    resetDeletionPreview(); $('#confirmation-error').hidden = true; $('#confirmation').showModal(); $('#cancel-delete').focus();
}
function resetDeletionPreview() {
    clearTimeout(deletionExpiryTimer); deletionExpiryTimer = null;
    $('#deletion-impact').hidden = true; $('#deletion-impact').replaceChildren(); $('#deletion-phrase').hidden = true;
    $('#deletion-confirmation').value = ''; $('#confirm-delete').disabled = false; $('#confirm-delete').textContent = 'Excluir cadastro'; $('#confirmation-title').textContent = 'Excluir cadastro?';
}
function updateDeletionConfirmation() {
    const phrase = deletion?.preview?.confirmation || deletion?.recovery?.confirmation;
    if (!phrase) return;
    $('#confirm-delete').disabled = writes.busy || deletion.blocked || Date.now() >= deletion.expiresAt || $('#deletion-confirmation').value !== phrase;
}
function displayRecoveryStatus(status, viewId) {
    if (typeof status.orgName !== 'string' || typeof status.operationId !== 'string') throw new Error('O servidor não forneceu uma operação válida.');
    resetDeletionPreview();
    $('#confirmation-title').textContent = 'Retomar exclusão pendente';
    deletion = { method: 'resumeFacDeletion', payload: { orgName: status.orgName, operationId: status.operationId }, recovery: { confirmation: `RETOMAR ${status.orgName}` }, expiresAt: Infinity, blocked: status.canResume !== true, viewId };
    $('#confirmation-message').textContent = `A exclusão de “${status.orgName}” está no estado ${status.state}. Retomar continua a intenção registrada e exige conferir os dados da organização.`;
    const impact = $('#deletion-impact'); impact.hidden = false; const summary = document.createElement('p'); summary.textContent = `Operação: ${status.operationId} · Estado: ${status.state}`; impact.append(summary);
    if (status.counts) { const counts = document.createElement('p'); counts.textContent = `Cargos: ${status.counts.groups ?? 0} · Usuários online: ${status.counts.onlineUsers ?? 0} · Usuários offline: ${status.counts.offlineUsers ?? 0}`; impact.append(counts); }
    $('#deletion-phrase').hidden = false; $('#deletion-expected').textContent = `Digite exatamente: ${deletion.recovery.confirmation}`;
    $('#confirm-delete').textContent = 'Retomar exclusão'; $('#confirmation-error').hidden = true;
    if (!status.canResume) showError($('#confirmation-error'), new Error('Esta operação exige conferência manual antes de retomar.'));
    $('#confirmation').showModal(); $('#deletion-confirmation').focus(); updateDeletionConfirmation();
}
function displayDeletionPreview(preview, viewId) {
    if (!preview || typeof preview.previewId !== 'string' || typeof preview.orgName !== 'string' || typeof preview.confirmation !== 'string') throw new Error('O servidor não forneceu uma prévia válida da exclusão.');
    const expiresAt = typeof preview.expiresAt === 'number' ? (preview.expiresAt < 1e12 ? preview.expiresAt * 1000 : preview.expiresAt) : Date.parse(preview.expiresAt);
    if (!Number.isFinite(expiresAt) || expiresAt <= Date.now()) throw new Error('A prévia expirou. Solicite uma nova verificação.');
    resetDeletionPreview();
    deletion = { method: 'deleteFacBundle', payload: { orgName: preview.orgName, previewId: preview.previewId }, preview, expiresAt, name: preview.orgName, viewId };
    $('#confirmation-message').textContent = `Excluir a organização “${preview.orgName}”? A prévia abaixo foi calculada pelo servidor. A confirmação altera os cargos, vínculos e registros indicados.`;
    const impact = $('#deletion-impact'); impact.hidden = false;
    function heading(text) { const node = document.createElement('h3'); node.textContent = text; impact.append(node); }
    function list(values) { const ul = document.createElement('ul'); for (const value of values) { const li = document.createElement('li'); li.textContent = value; ul.append(li); } impact.append(ul); }
    heading('Cargos afetados'); list(preview.groups || []);
    heading('Impacto calculado');
    const table = document.createElement('table'); const body = document.createElement('tbody'); table.append(body);
    for (const [title, count] of [['Cargos', preview.counts?.groups], ['Usuários online', preview.counts?.onlineUsers], ['Usuários offline', preview.counts?.offlineUsers], ...Object.entries(preview.counts?.tables || {})]) {
        const row = document.createElement('tr'); const label = document.createElement('td'); label.textContent = title; const value = document.createElement('td'); value.textContent = String(count ?? 0); row.append(label, value); body.append(row);
    }
    impact.append(table);
    if (Array.isArray(preview.warnings) && preview.warnings.length) { heading('Observações'); list(preview.warnings); }
    const expiry = document.createElement('p'); expiry.textContent = `Prévia válida até ${new Date(expiresAt).toLocaleTimeString('pt-BR')}. Se o estado mudar, uma nova prévia será necessária.`; impact.append(expiry);
    $('#deletion-phrase').hidden = false; $('#deletion-expected').textContent = `Digite exatamente: ${preview.confirmation}`;
    $('#confirmation-error').hidden = true; $('#confirmation').showModal(); $('#deletion-confirmation').focus(); updateDeletionConfirmation();
    deletionExpiryTimer = setTimeout(() => { if (deletion?.preview?.previewId !== preview.previewId) return; deletion.blocked = true; updateDeletionConfirmation(); showError($('#confirmation-error'), new Error('A prévia expirou. Cancele e solicite uma nova verificação.')); }, Math.min(expiresAt - Date.now(), 2147483647));
}
function closeEditor() { if (!writes.busy) { $('#editor').close(); editor = null; } }
async function closePanel() {
    teleportPending = null;
    opened = false; openGeneration++; captureTargets.clear(); clearTimeout(deletionExpiryTimer); deletion = null; suspended = false; loader.cancel(); $('#panel').hidden = true; $('#editor').close(); $('#confirmation').close(); $('#toast').hidden = true;
    if (!preview) {
        try { await fetch(`https://${resource}/close`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' }); } catch { /* FiveM may be stopping the resource. */ }
    }
}
async function openPanel() {
    const generation = ++openGeneration;
    opened = true; suspended = false; writesEnabled = false; methods.clear(); $('#panel').hidden = false;
    $('#mode-banner').hidden = false; $('#mode-banner').textContent = 'Verificando acesso e disponibilidade de gravação…';
    updateNavigation();
    try {
        const info = await transport.call('bootstrap');
        if (!opened || generation !== openGeneration) return;
        writesEnabled = info?.writesEnabled === true; methods = new Map((info?.methods || []).map(method => [method.name, method]));
        $('#mode-banner').hidden = writesEnabled; $('#mode-banner').textContent = 'SOMENTE LEITURA · A gravação está desativada no servidor até validar a persistência.';
        await load();
    } catch (error) {
        if (generation !== openGeneration || !opened) return;
        $('#mode-banner').textContent = 'Acesso indisponível'; data = null; rows = []; showError($('#error'), error); renderRecords();
    }
}

for (const [id, title, number] of AREAS) {
    const nav = button('', () => setArea(id)); nav.dataset.area = id; nav.title = title; nav.setAttribute('aria-label', title);
    const icon = document.createElement('span'); icon.textContent = number; const text = document.createElement('span'); text.className = 'nav-text'; text.textContent = title;
    nav.append(icon, text); $('#navigation').append(nav);
}
$('#search').oninput = renderRecords;
$('#refresh').onclick = load;
$('#create').onclick = () => openEditor();
$('#additional').onclick = () => openEditor(null, true);
$('#cancel-editor').onclick = closeEditor; $('#cancel-edit').onclick = closeEditor;
$('#editor').addEventListener('cancel', event => { if (writes.busy) event.preventDefault(); else editor = null; });
$('#edit-form').onsubmit = async event => {
    event.preventDefault(); if (!editor || editor.readOnly || writes.busy) return;
    $('#editor-error').hidden = true;
    try {
        const value = readDraft();
        const operation = editor.action ? { method: editor.action.method, payload: value } : mutationFor(editor.view, value, editor.row);
        if (editor.action?.previewMethod) {
            const current = editor; editorBusy(true);
            const preview = await transport.call(editor.action.previewMethod, value);
            if (editor !== current || !opened) return;
            displayDeletionPreview(preview, current.view.id); return;
        }
        if (editor.action?.danger) {
            deletion = { ...operation, name: editor.action.label, viewId: editor.view.id };
            $('#confirmation-message').textContent = `Confirmar “${deletion.name}” com os identificadores informados? A exclusão altera os dados da base.`;
            resetDeletionPreview(); $('#confirmation-error').hidden = true; $('#confirmation').showModal(); $('#cancel-delete').focus(); return;
        }
        editorBusy(true); pendingView = editor.view.id;
        await commit(operation.method, operation.payload);
        $('#editor').close(); editor = null;
        if (opened && activeView.id === pendingView) await load();
    } catch (error) { showError($('#editor-error'), error); }
    finally { editorBusy(false); pendingView = null; }
};
$('#cancel-delete').onclick = () => { if (!writes.busy) { $('#confirmation').close(); deletion = null; } };
$('#deletion-confirmation').oninput = updateDeletionConfirmation;
$('#confirmation').addEventListener('cancel', event => { if (writes.busy) event.preventDefault(); else deletion = null; });
$('#confirm-delete').onclick = async () => {
    if (!deletion || writes.busy) return;
    const phrase = deletion.preview?.confirmation || deletion.recovery?.confirmation;
    if (phrase && (deletion.blocked || Date.now() >= deletion.expiresAt || $('#deletion-confirmation').value !== phrase)) { updateDeletionConfirmation(); return; }
    const current = deletion; $('#confirmation-error').hidden = true; $('#confirm-delete').disabled = true; $('#cancel-delete').disabled = true;
    try {
        await commit(current.method, { ...current.payload, ...(current.preview ? { confirmation: $('#deletion-confirmation').value } : {}) }); $('#confirmation').close(); $('#editor').close(); editor = null; deletion = null; clearTimeout(deletionExpiryTimer);
        if (opened && activeView.id === current.viewId) await load();
    } catch (error) { showError($('#confirmation-error'), error); if (current.preview || current.recovery) { current.blocked = true; const hint = document.createElement('small'); hint.textContent = 'Cancele e consulte o estado da exclusão antes de continuar.'; $('#confirmation-error').append(hint); } }
    finally { $('#confirm-delete').disabled = false; $('#cancel-delete').disabled = false; updateDeletionConfirmation(); }
};
$('#close-panel').onclick = closePanel;
document.addEventListener('keydown', event => { if (event.key === 'Escape' && !$('#editor').open && !$('#confirmation').open && opened) { event.preventDefault(); closePanel(); } });
window.addEventListener('message', event => {
    const message = event.data;
    if (message?.action === 'open') openPanel();
    if (message?.action === 'close') { opened = false; openGeneration++; teleportPending = null; captureTargets.clear(); clearTimeout(deletionExpiryTimer); deletion = null; suspended = false; loader.cancel(); $('#panel').hidden = true; $('#editor').close(); $('#confirmation').close(); }
    if (message?.action === 'suspend' && opened) { suspended = true; $('#panel').hidden = true; $('#editor').close(); $('#confirmation').close(); }
    if (message?.action === 'captureResult') {
        const capture = captureTargets.get(message.target); captureTargets.delete(message.target);
        if (!opened || !editor || !capture || capture.token !== editor.token || capture.kind !== message.kind) return;
        if (message.cancelled) { toast('Captura cancelada.'); return; }
        if (editor.custom) { editor.custom.applyCapture(capture.path, message.data, capture.mode, capture.kind); return; }
        if (capture.kind === 'position') {
            const current = getAt(editor.draft, capture.path);
            for (const axis of ['x', 'y', 'z', 'w', 'h', 'heading']) {
                if (!Object.hasOwn(current, axis)) continue;
                const value = message.data?.[axis]; if (!Number.isFinite(value)) continue;
                setAt(editor.draft, [...capture.path, axis], value);
                const input = editor.inputs.find(item => JSON.stringify(item.path) === JSON.stringify([...capture.path, axis])); if (input) input.node.value = value;
            }
        } else {
            const input = editor.inputs.find(item => JSON.stringify(item.path) === JSON.stringify(capture.path));
            if (input && Array.isArray(message.data?.coords)) {
                try {
                    const polygons = JSON.parse(input.node.value); if (!Array.isArray(polygons)) throw new Error();
                    polygons.push({ coords: message.data.coords, minZ: message.data.minZ, maxZ: message.data.maxZ }); input.node.value = JSON.stringify(polygons, null, 2);
                } catch { showError($('#editor-error'), new Error('A lista de polígonos possui JSON inválido. Corrija o campo antes de capturar novamente.')); }
            }
        }
    }
    if (message?.action === 'resume' && opened && suspended) { suspended = false; $('#panel').hidden = false; if (editor) $('#editor').showModal(); }
});
if (preview) { opened = true; $('#panel').hidden = false; $('#preview-banner').hidden = false; updateNavigation(); load(); }
