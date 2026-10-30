import { createTransport, HomeError } from './transport.mjs';
import { list, money, dateText, taxExpired, saleRefund, can, residentId, filterCatalog, priceMap, operationSummary } from './model.mjs';

const $ = selector => document.querySelector(selector);
const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'ic_mansions';
const preview = typeof GetParentResourceName !== 'function' && new URLSearchParams(location.search).get('preview') === '1';
const rpc = createTransport({ resource });
let context = null, view = 'overview', opened = false, suspended = false, loading = false, busy = false, generation = 0, pendingConfirmation = null, toastTimer;
let query = '', category = '', memberDraft = '', pricesQuery = ''; const prices = new Map();
let operationFailure = null;
let recovery = { operations: [], loading: false, loaded: false, invalidated: false, error: null, revision: null }, recoveryGeneration = 0;

function node(tag, text, className) { const element = document.createElement(tag); if (text != null) element.textContent = text; if (className) element.className = className; return element; }
function action(text, handler, { primary = false, danger = false, disabled = false, write = false } = {}) {
    const element = node('button', text, primary ? 'primary' : danger ? 'danger' : ''); element.type = 'button'; element.onclick = handler;
    if (write) element.dataset.write = 'true'; element.disabled = disabled || (write && mutationDisabled()); return element;
}
function mutationDisabled() { return preview || busy || list(context?.pendingOperations).length > 0; }
function errorAt(target, error) { target.hidden = false; target.textContent = error?.message || 'A operação não foi concluída.'; if (error?.code) target.append(node('small', `Código: ${error.code}`)); }
function toast(message) { clearTimeout(toastTimer); $('#toast').textContent = message; $('#toast').hidden = false; toastTimer = setTimeout(() => { $('#toast').hidden = true; }, 4500); }
function id() { return context?.mansionId; }
function setBusy(value) {
    busy = value; $('#refresh').disabled = value || loading; $('#property-selector').disabled = value;
    document.querySelectorAll('[data-write]').forEach(element => { element.disabled = value || mutationDisabled() || element.dataset.allowed === 'false'; });
    document.querySelectorAll('[data-recovery]').forEach(element => { element.disabled = value || preview || recovery.invalidated; });
}
function guarded(button, allowed) { button.dataset.allowed = String(allowed); button.disabled = !allowed || mutationDisabled(); return button; }
function sample() { return { mansionId: 'preview', mansionName: 'Mansão de demonstração', ownerId: 1, members: [{ userId: 1, name: 'Morador de exemplo', owner: true }], maxResidents: 4, iptuValue: 1000, iptuPaidUntil: Math.floor(Date.now() / 1000) + 86400, price: 1000000, voucher: 'valemansao1m', voucherLabel: 'Vale Mansão 1M', canManage: false, canConfigure: false, canFurniture: false, canPurchase: false, canPayIptu: false, catalog: { items: [{ id: 'sofa', name: 'Sofá de demonstração', model: 'prop_exemplo', category: 'Sofás', price: 500 }] }, furniture: [], pendingOperations: [], sellPercent: 15 }; }
async function refresh(mansionId = id()) {
    const current = ++generation; loading = true; $('#loading').hidden = false; $('#refresh').disabled = true; $('#error').hidden = true;
    try {
        const next = preview ? sample() : await rpc.call('getContext', mansionId ? { mansionId } : {});
        if (current !== generation || !opened) return;
        context = next || {}; prices.clear(); renderHeader(); renderCurrent(); if (operationFailure) errorAt($('#error'), new Error(operationFailure));
        if (view === 'recovery') await loadRecovery();
    } catch (error) { if (current === generation && opened) { context = null; errorAt($('#error'), error); renderCurrent(); } }
    finally { if (current === generation) { loading = false; $('#loading').hidden = true; $('#refresh').disabled = busy; } }
}
async function mutate(method, payload, { refreshAfter = true, allowPending = false } = {}) {
    if (preview || busy || (list(context?.pendingOperations).length > 0 && !(allowPending && can(context, 'canConfigure')))) throw new HomeError('BUSY', 'Aguarde a operação atual ou a conferência da administração.');
    setBusy(true); $('#error').hidden = true; operationFailure = null;
    try {
        const result = await rpc.call(method, payload);
        if (result?.state === 'recovery_required') throw new HomeError('RECOVERY_REQUIRED', result.message || 'A operação precisa ser conferida pela administração.');
        if (refreshAfter && opened && !suspended) await refresh();
        return result;
    } finally { setBusy(false); }
}
async function doAction(task) { try { await task(); } catch (error) { errorAt($('#error'), error); } }
function renderHeader() {
    $('#property-name').textContent = context?.mansionName || 'Minha mansão';
    $('#property-subtitle').textContent = context?.ownerId ? 'Seu endereço, seus acessos, seus moradores.' : 'Conheça os detalhes desta propriedade.';
    $('#role').textContent = context?.canManage === true ? 'Proprietário' : context?.canConfigure === true ? 'Administração' : 'Acesso da mansão';
    const options = list(context?.mansions), select = $('#property-selector'); select.replaceChildren();
    for (const mansion of options) { const option = new Option(mansion.name || mansion.id, mansion.id); option.selected = String(mansion.id) === String(id()); select.append(option); }
    $('#property-selector-label').hidden = options.length < 2;
    const pending = list(context?.pendingOperations); $('#operation-note').hidden = !pending.length;
    $('#operation-note').textContent = pending.length ? 'Há uma operação pendente de conferência. As alterações desta mansão aguardam a administração.' : '';
    for (const button of document.querySelectorAll('[data-view]')) {
        button.setAttribute('aria-current', button.dataset.view === view ? 'page' : 'false');
        if (button.dataset.view === 'prices') button.hidden = !can(context, 'canConfigure') && context?.catalog?.canConfigure !== true;
        if (button.dataset.view === 'recovery') button.hidden = !can(context, 'canConfigure');
    }
}
function empty(title, description) { const box = node('div', null, 'empty'); box.append(node('strong', title), node('span', description)); return box; }
function sectionTitle(title, subtitle) { const header = node('div', null, 'section-head'); const text = node('div'); text.append(node('h2', title)); if (subtitle) text.append(node('p', subtitle)); header.append(text); return header; }
function stat(title, value, description) { const box = node('div', null, 'stat'); box.append(node('span', title), node('strong', value)); if (description) box.append(node('small', description)); return box; }
function confirmationDisabled() {
    if (!pendingConfirmation || preview || busy) return true;
    if (pendingConfirmation.recoveryPhrase) return !$('#recovery-settled').checked || $('#recovery-confirmation').value !== pendingConfirmation.recoveryPhrase || recovery.invalidated;
    return mutationDisabled();
}
function confirm({ title, description, details = [], label = 'Confirmar', run, recoveryPhrase = null }) {
    pendingConfirmation = { run, recoveryPhrase }; $('#confirm-title').textContent = title; $('#confirm-description').textContent = description; $('#confirm').textContent = label;
    const children = []; for (const [key, value] of details) children.push(node('dt', key), node('dd', value)); $('#confirm-details').replaceChildren(...children);
    $('#recovery-checks').hidden = !recoveryPhrase; $('#recovery-settled').checked = false; $('#recovery-confirmation').value = '';
    $('#recovery-settled').disabled = false; $('#recovery-confirmation').disabled = false; $('#recovery-expected').textContent = recoveryPhrase ? `Digite exatamente: ${recoveryPhrase}` : '';
    $('#confirm-error').hidden = true; $('#confirm').disabled = confirmationDisabled(); $('#confirmation').showModal(); $('#cancel-confirm').focus();
}
async function purchase() {
    await doAction(async () => {
        const quote = await mutate('requestPurchase', { id: id() }, { refreshAfter: false });
        if (!opened || !quote?.quoteToken) throw new Error('A cidade não forneceu uma proposta válida. Atualize a propriedade.');
        const mansionId = quote.id;
        confirm({ title: `Comprar ${quote.name || context.mansionName}`, description: 'A compra utiliza o vale indicado. O valor anunciado da propriedade é informativo; nenhum pagamento em dinheiro é solicitado nesta confirmação.',
            details: [['Vale necessário', quote.voucherLabel || quote.voucher], ['Valor anunciado', money(quote.price)], ['Limite de moradores', String(quote.maxResidents)]], label: 'Usar vale e comprar',
            run: () => mutate('confirmPurchase', { id: mansionId, quoteToken: quote.quoteToken, confirmed: true }) });
    });
}
function overview() {
    const fragment = document.createDocumentFragment(), hero = node('section', null, 'hero'), content = node('div');
    content.append(node('p', 'PROPRIEDADE', 'eyebrow'), node('h2', context.mansionName || 'Mansão'));
    content.append(node('p', context.ownerId ? 'Gerencie os moradores, acompanhe o IPTU e personalize os espaços da sua mansão.' : 'Confira o vale necessário e as condições desta propriedade antes de confirmar a compra.'));
    if (context.purchaseAvailable === true && can(context, 'canPurchase')) content.append(guarded(action('Comprar mansão', purchase, { primary: true, write: true }), true));
    const icon = node('div', '⌂', 'home-mark'); icon.setAttribute('aria-hidden', 'true'); hero.append(content, icon); fragment.append(hero);
    const stats = node('div', null, 'stat-grid'); stats.append(stat('VALOR ANUNCIADO', money(context.price), 'Valor de referência da propriedade'), stat('MORADORES', `${list(context.members).length} / ${context.maxResidents || 0}`, 'Inclui o proprietário'), stat('MOBÍLIAS', String(list(context.furniture).length), 'Objetos posicionados na mansão')); fragment.append(stats);
    const tax = node('section', null, 'section-card'); tax.append(node('h3', 'IPTU da mansão'));
    tax.append(node('p', `Valor: ${money(context.iptuValue)} · Vencimento: ${dateText(context.iptuPaidUntil)}${context.ownerId ? taxExpired(context.iptuPaidUntil) ? ' · Vencido' : ' · Em dia' : ''}`));
    if (can(context, 'canPayIptu')) tax.append(guarded(action('Pagar IPTU', () => confirm({ title: 'Pagar IPTU', description: 'Confirme o valor do IPTU desta mansão. A cidade verifica o pagamento e atualiza os acessos.', details: [['Mansão', context.mansionName], ['Valor', money(context.iptuValue)]], label: 'Confirmar pagamento', run: () => mutate('payIptu', { mansionId: id(), confirmed: true }) }), { primary: true, write: true }), true));
    fragment.append(tax);
    if (context.voucher) { const voucher = node('section', null, 'section-card'); voucher.append(node('h3', 'Vale de compra'), node('p', context.voucherLabel || context.voucher)); fragment.append(voucher); }
    if (can(context, 'canCleanup')) {
        const cleanup = node('section', null, 'section-card'); cleanup.append(node('h3', 'Limpar ocupação'), node('p', 'Ação administrativa para retirar os ocupantes e as mobílias da mansão. Não concede reembolsos. O cadastro e os pontos de acesso permanecem.'));
        cleanup.append(guarded(action('Revisar limpeza da ocupação', () => doAction(async () => {
            const quote = await mutate('quoteCleanup', { mansionId: id() }, { refreshAfter: false });
            if (!opened || !quote?.quoteToken) throw new Error('A cidade não forneceu uma prévia válida.');
            confirm({ title: 'Limpar ocupação da mansão', description: 'Os moradores perderão o acesso e as mobílias serão removidas, sem reembolso. O cadastro, baú, garagem e trancas permanecem.',
                details: [['Mansão', context.mansionName], ['Ocupantes afetados', list(quote.residents).map(resident => resident.name || `ID ${resident.userId ?? resident.id ?? resident}`).join(', ') || 'Nenhum'], ['Reembolsos', 'Nenhum']],
                label: 'Limpar ocupação sem reembolso', run: () => mutate('cleanupMansion', { mansionId: quote.mansionId, quoteToken: quote.quoteToken, confirmed: true }) });
        }), { danger: true, write: true }), true)); fragment.append(cleanup);
    }
    return fragment;
}
function residents() {
    const fragment = document.createDocumentFragment(); fragment.append(sectionTitle('Moradores', `${list(context.members).length} de ${context.maxResidents || 0} moradores · o limite inclui o proprietário.`));
    if (can(context, 'canManage')) {
        const form = node('form', null, 'member-form'), label = node('label', 'Passaporte do novo morador'), input = node('input'); input.type = 'number'; input.min = '1'; input.step = '1'; input.required = true; input.value = memberDraft; input.oninput = () => { memberDraft = input.value; }; label.append(input);
        const submit = node('button', 'Adicionar morador', 'primary'); submit.dataset.write = 'true'; submit.disabled = mutationDisabled(); form.append(label, submit);
        form.onsubmit = event => { event.preventDefault(); doAction(async () => { const userId = residentId(input.value); await mutate('addResident', { mansionId: id(), userId }); memberDraft = ''; toast('Morador adicionado.'); }); }; fragment.append(form);
    }
    for (const member of list(context.members)) {
        const row = node('article', null, 'member'), info = node('div'); info.append(node('strong', member.name || `Morador ${member.userId}`), node('small', `Passaporte ${member.userId}`)); row.append(info);
        if (member.owner === true || Number(member.userId) === Number(context.ownerId)) row.append(node('span', 'Proprietário', 'tag'));
        else if (can(context, 'canManage')) row.append(guarded(action('Remover morador', () => confirm({ title: 'Remover morador', description: `Remover o acesso de ${member.name || `ID ${member.userId}`} à mansão?`, details: [['Passaporte', String(member.userId)]], label: 'Remover acesso', run: () => mutate('removeResident', { mansionId: id(), userId: member.userId, confirmed: true }) }), { danger: true, write: true }), true));
        fragment.append(row);
    }
    if (!list(context.members).length) fragment.append(empty('Nenhum morador', 'Os vínculos aparecerão aqui após a compra da propriedade.'));
    return fragment;
}
function glyph(category) {
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg'); svg.setAttribute('viewBox', '0 0 100 80'); svg.setAttribute('aria-hidden', 'true');
    const paths = /planta/i.test(category || '') ? ['M49 68V32M49 48C24 46 21 29 23 23 42 22 50 31 49 48ZM49 39C50 21 68 14 78 18 77 35 65 42 49 39ZM35 68H65L61 48H39Z'] : /mesa/i.test(category || '') ? ['M15 29H85V38H15ZM23 38V67M77 38V67M27 50H73'] : /ilumina/i.test(category || '') ? ['M35 35 27 16H73L65 35ZM50 35V68M34 68H66'] : /cama/i.test(category || '') ? ['M15 56V24H85V66M15 45H85M15 56H85M15 66V56M24 34H44V45H24ZM56 34H76V45H56Z'] : ['M22 40V21Q22 14 29 14H71Q78 14 78 21V40M16 40H84V61H16ZM24 61V68M76 61V68M24 40V51H76V40'];
    for (const drawing of paths) { const path = document.createElementNS('http://www.w3.org/2000/svg', 'path'); path.setAttribute('d', drawing); svg.append(path); } return svg;
}
function catalog() {
    const fragment = document.createDocumentFragment(); fragment.append(sectionTitle('Catálogo de mobílias', 'Escolha uma peça e defina a posição dentro do jogo.'));
    const toolbar = node('div', null, 'toolbar'), search = node('input'); search.type = 'search'; search.placeholder = 'Buscar pelo nome, modelo ou categoria'; search.setAttribute('aria-label', 'Buscar mobília'); search.value = query;
    const select = node('select'); select.setAttribute('aria-label', 'Categoria da mobília'); select.append(new Option('Todas as categorias', ''));
    for (const category of [...new Set(list(context.catalog?.items).map(item => item.category).filter(Boolean))].sort()) select.append(new Option(category, category)); select.value = category;
    const results = node('div', null, 'catalog-grid'), count = node('span', '', 'category');
    function update() {
        query = search.value; category = select.value; const filtered = filterCatalog(context.catalog?.items, query, category); count.textContent = `${filtered.length} peças`; results.replaceChildren();
        for (const item of filtered) {
            const card = node('article', null, 'furniture-card'), art = node('div', null, 'furniture-art'); art.append(glyph(item.category));
            const body = node('div', null, 'furniture-body'); body.append(node('span', item.category || 'Mobília', 'category'), node('strong', item.name || item.model), node('small', item.model), node('div', money(item.price), 'price'));
            const buy = action('Posicionar na mansão', () => confirm({ title: item.name || item.model, description: 'Defina a posição no jogo e confirme para concluir a compra. Cancelar o posicionamento mantém a compra sem conclusão.', details: [['Valor da peça', money(item.price)]], label: 'Escolher posição', run: () => mutate('startFurniturePlacement', { mansionId: id(), itemId: item.id }, { refreshAfter: false }) }), { primary: true, write: true });
            body.append(guarded(buy, can(context, 'canFurniture'))); card.append(art, body); results.append(card);
        }
        if (!filtered.length) results.append(empty('Nenhuma peça encontrada', 'Experimente outro nome ou categoria.'));
    }
    search.oninput = update; select.onchange = update; toolbar.append(search, select, count); fragment.append(toolbar, results); update(); return fragment;
}
function placed() {
    const fragment = document.createDocumentFragment(); fragment.append(sectionTitle('Minhas mobílias', 'Mova as peças ou confirme a venda para receber o valor de retorno indicado.'));
    for (const item of list(context.furniture)) {
        const row = node('article', null, 'placed-row'), info = node('div'); info.append(node('strong', item.name || item.model), node('small', `${item.model} · Valor pago: ${money(item.paidPrice)}`));
        const actions = node('div', null, 'row-actions');
        actions.append(guarded(action('Mover', () => doAction(() => mutate('startFurnitureMove', { mansionId: id(), furnitureId: item.id }, { refreshAfter: false })), { write: true }), can(context, 'canFurniture')));
        actions.append(guarded(action('Vender', () => confirm({ title: 'Vender mobília', description: `Confirmar a venda de ${item.name || item.model}? A peça será removida da mansão.`, details: [['Valor pago', money(item.paidPrice)], ['Retorno da venda', money(saleRefund(item, context.sellPercent))]], label: 'Confirmar venda', run: () => mutate('sellFurniture', { mansionId: id(), furnitureId: item.id, confirmed: true }) }), { danger: true, write: true }), can(context, 'canFurniture')));
        row.append(info, actions); fragment.append(row);
    }
    if (!list(context.furniture).length) fragment.append(empty('Seu espaço está pronto para decorar', 'As peças posicionadas aparecerão aqui.'));
    return fragment;
}
function catalogPrices() {
    if (!can(context, 'canConfigure') && context.catalog?.canConfigure !== true) return empty('Acesso restrito', 'Somente os responsáveis pelo catálogo podem alterar os valores.');
    const fragment = document.createDocumentFragment(); fragment.append(sectionTitle('Valores do catálogo', 'As alterações são aplicadas ao catálogo da cidade.'));
    const toolbar = node('div', null, 'toolbar'), search = node('input'), bulk = node('input'); search.type = 'search'; search.placeholder = 'Buscar peça'; search.setAttribute('aria-label', 'Buscar preço de mobília'); search.value = pricesQuery;
    bulk.type = 'number'; bulk.min = '0'; bulk.step = '1'; bulk.placeholder = 'Valor para todas'; bulk.setAttribute('aria-label', 'Preço para todas as peças');
    const results = node('div');
    function update() {
        pricesQuery = search.value; results.replaceChildren();
        for (const item of filterCatalog(context.catalog?.items, pricesQuery)) {
            const row = node('div', null, 'price-row'), info = node('div'), input = node('input'); info.append(node('strong', item.name || item.model), node('small', item.model));
            input.type = 'number'; input.min = '0'; input.step = '1'; input.value = prices.get(String(item.id)) ?? item.price ?? 0; input.setAttribute('aria-label', `Preço: ${item.name || item.model}`); input.disabled = mutationDisabled(); input.oninput = () => { prices.set(String(item.id), input.value); }; row.append(info, input); results.append(row);
        }
    }
    const apply = action('Aplicar a todas', () => doAction(async () => { const amount = Number(bulk.value); if (!bulk.value || !Number.isSafeInteger(amount) || amount < 0) throw new Error('Informe um preço inteiro válido.'); for (const item of list(context.catalog?.items)) prices.set(String(item.id), String(amount)); update(); }), { write: true });
    const save = action('Revisar e salvar', () => doAction(async () => {
        const payload = priceMap(context.catalog?.items, prices); if (!Object.keys(payload).length) throw new Error('Altere ao menos um valor antes de salvar.');
        confirm({ title: 'Alterar valores do catálogo', description: 'Os novos preços serão usados nas próximas compras de mobília. As peças já adquiridas mantêm o valor pago.', details: [['Peças alteradas', String(Object.keys(payload).length)]], label: 'Salvar valores', run: () => mutate('saveFurniturePrices', { prices: payload }) });
    }), { primary: true, write: true });
    search.oninput = update; toolbar.append(search, bulk, apply); fragment.append(toolbar, results, save); update(); return fragment;
}
async function loadRecovery() {
    if (!opened || !can(context, 'canConfigure') || view !== 'recovery') return;
    const current = ++recoveryGeneration;
    recovery.loading = true; recovery.error = null; renderCurrent();
    try {
        const result = await rpc.call('getPendingOperations', {});
        if (current !== recoveryGeneration || !opened || view !== 'recovery' || !can(context, 'canConfigure')) return;
        recovery = { operations: list(result?.operations), loaded: true, loading: false, invalidated: false, error: null, revision: result?.revision ?? null };
    } catch (error) {
        if (current !== recoveryGeneration || !opened) return;
        recovery.error = error; recovery.loading = false; recovery.invalidated = true;
    }
    renderCurrent();
}
function reconciliation() {
    if (!can(context, 'canConfigure')) return empty('Acesso restrito', 'Esta seção está disponível aos responsáveis pela administração.');
    const fragment = document.createDocumentFragment(), title = sectionTitle('Reconciliação de operações', 'Conferência administrativa das operações que interromperam pagamentos ou integrações.');
    const reload = action('Recarregar pendências', loadRecovery, { disabled: recovery.loading || busy }); title.append(reload); fragment.append(title);
    const explanation = node('section', null, 'section-card'); explanation.append(node('h3', 'Conferência manual antes da liberação'), node('p', 'Confira pagamentos e vales e restaure grupos, baús, garagens e trancas ao estado anterior fora desta ação. A liberação restaura somente o cadastro anterior e marca a pendência como cancelada. Ela não devolve dinheiro ou vales e não ajusta cargos ou integrações.')); fragment.append(explanation);
    if (recovery.loading) { fragment.append(node('p', 'Consultando operações pendentes…')); return fragment; }
    if (recovery.error) { const box = node('p', null, 'error'); errorAt(box, recovery.error); fragment.append(box); }
    if (recovery.invalidated) fragment.append(node('p', 'Os dados precisam ser recarregados antes de qualquer nova confirmação.', 'notice'));
    const operations = [...recovery.operations].sort((a, b) => (Number(b.createdAt) || 0) - (Number(a.createdAt) || 0));
    for (const operation of operations.slice(0, 100)) {
        const card = node('article', null, 'section-card recovery-card'); card.append(node('h3', `Operação ${String(operation.id || '').slice(0, 100)}`));
        const details = document.createElement('details'), summary = node('summary', `Conferir ${String(operation.kind || 'operação').slice(0, 80)} · ${String(operation.phase || 'pendente').slice(0, 80)}`), fields = node('dl');
        for (const [key, value] of operationSummary(operation)) fields.append(node('dt', key), node('dd', value)); details.append(summary, fields); card.append(details);
        const review = action('Revisar liberação manual', () => {
            if (busy || preview || recovery.invalidated) return;
            const phrase = `RECONCILIADO ${operation.id}`, revision = recovery.revision;
            confirm({ title: 'Liberar registro após reconciliação manual', description: 'Confirme somente depois de concluir a conferência externa. Esta ação restaura o cadastro anterior e cancela a pendência; ela não realiza estornos, entregas de vales nem ajustes de grupos, baús, garagens ou trancas.',
                details: operationSummary(operation), label: 'Registrar reconciliação e liberar', recoveryPhrase: phrase,
                run: async () => {
                    try {
                        return await mutate('reconcileOperation', { operationId: operation.id, decision: 'cancel_after_manual_reconciliation', confirmation: $('#recovery-confirmation').value, confirmed: true, ...(revision != null ? { expectedRevision: revision } : {}) }, { allowPending: true });
                    } catch (error) { recovery.invalidated = true; renderCurrent(); throw error; }
                } });
        }, { danger: true }); review.dataset.recovery = 'true'; review.disabled = preview || busy || recovery.invalidated; card.append(review); fragment.append(card);
    }
    if (operations.length > 100) fragment.append(node('p', `Mostrando 100 de ${operations.length} operações.`, 'notice'));
    if (!operations.length && recovery.loaded && !recovery.error) fragment.append(empty('Nenhuma operação pendente', 'Os registros disponíveis estão concluídos ou cancelados.'));
    return fragment;
}
function renderCurrent() {
    renderHeader();
    if (!context) { $('#content').replaceChildren(empty('Mansão indisponível', 'Atualize os dados ou verifique a mensagem de acesso.')); return; }
    const builders = { overview, residents, catalog, placed, prices: catalogPrices, recovery: reconciliation }; $('#content').replaceChildren((builders[view] || overview)());
}
async function close() {
    opened = false; suspended = false; generation++; recoveryGeneration++; $('#home').hidden = true; $('#confirmation').close(); $('#toast').hidden = true; pendingConfirmation = null;
    if (!preview) { try { await fetch(`https://${resource}/close`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' }); } catch { /* Resource may be stopping. */ } }
}
function selectView(next) { view = next; recoveryGeneration++; renderCurrent(); if (view === 'recovery') loadRecovery(); }
for (const button of document.querySelectorAll('[data-view]')) button.onclick = () => selectView(button.dataset.view);
const mobile = node('nav', null, 'mobile-navigation'); mobile.setAttribute('aria-label', 'Seções da mansão no celular');
for (const button of document.querySelectorAll('aside [data-view]')) { const clone = button.cloneNode(true); clone.onclick = () => selectView(clone.dataset.view); mobile.append(clone); }
$('.property-selector').before(mobile);
$('#property-selector').onchange = () => { memberDraft = ''; prices.clear(); refresh($('#property-selector').value); };
$('#refresh').onclick = () => refresh(); $('#close').onclick = close;
$('#cancel-confirm').onclick = () => { if (!busy) { $('#confirmation').close(); pendingConfirmation = null; } };
$('#confirmation').addEventListener('cancel', event => { if (busy) event.preventDefault(); else pendingConfirmation = null; });
$('#confirm-form').onsubmit = async event => {
    event.preventDefault(); if (confirmationDisabled()) return;
    $('#confirm-error').hidden = true; $('#confirm').disabled = true; $('#cancel-confirm').disabled = true;
    $('#recovery-settled').disabled = true; $('#recovery-confirmation').disabled = true;
    try { const result = await pendingConfirmation.run(); $('#confirmation').close(); pendingConfirmation = null; if (result?.message) toast(result.message); }
    catch (error) { errorAt($('#confirm-error'), error); pendingConfirmation = null; }
    finally { $('#confirm').disabled = confirmationDisabled(); $('#cancel-confirm').disabled = false; }
};
$('#recovery-settled').onchange = () => { $('#confirm').disabled = confirmationDisabled(); };
$('#recovery-confirmation').oninput = () => { $('#confirm').disabled = confirmationDisabled(); };
document.addEventListener('keydown', event => { if (event.key === 'Escape' && opened && !$('#confirmation').open) { event.preventDefault(); close(); } });
window.addEventListener('message', event => {
    const message = event.data;
    if (message?.action === 'open') {
        opened = true; suspended = false; operationFailure = null; $('#confirmation').close(); pendingConfirmation = null;
        const requestedView = message.view || message.context?.view; view = ['overview', 'residents', 'catalog', 'placed', 'prices', 'recovery'].includes(requestedView) ? requestedView : 'overview';
        $('#home').hidden = false; refresh(message.context?.mansionId || message.mansionId);
    }
    if (message?.action === 'close') { opened = false; suspended = false; generation++; recoveryGeneration++; $('#home').hidden = true; $('#confirmation').close(); pendingConfirmation = null; }
    if (message?.action === 'suspend' && opened) { suspended = true; $('#home').hidden = true; $('#confirmation').close(); }
    if (message?.action === 'resume' && opened) { suspended = false; $('#home').hidden = false; refresh(); }
    if (message?.action === 'operationResult' && opened) { if (message.ok === true) { operationFailure = null; toast(message.message || 'Mobília atualizada.'); } else { operationFailure = message.message || 'A operação não foi concluída.'; errorAt($('#error'), new Error(operationFailure)); } }
});
if (preview) { opened = true; $('#home').hidden = false; $('#preview-note').hidden = false; refresh(); }
