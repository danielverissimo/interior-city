export function list(value) { return Array.isArray(value) ? value : Object.values(value || {}); }
export function money(value) { return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(value) || 0); }
export function dateText(value) {
    const numeric = Number(value); if (!Number.isFinite(numeric) || numeric <= 0) return 'Não informado';
    const date = new Date(numeric < 1e12 ? numeric * 1000 : numeric); return date.toLocaleDateString('pt-BR', { timeZone: 'America/Sao_Paulo' });
}
export function taxExpired(value, now = Date.now()) { const numeric = Number(value); return !Number.isFinite(numeric) || numeric <= 0 || (numeric < 1e12 ? numeric * 1000 : numeric) < now; }
export function saleRefund(item, percent) { return Math.floor(Math.max(0, Number(item?.paidPrice) || 0) * Math.max(0, Math.min(100, Number(percent) || 0)) / 100); }
export function can(context, capability) { return context?.[capability] === true; }
export function residentId(value) { const number = Number(value); if (!Number.isSafeInteger(number) || number <= 0) throw new Error('Informe um passaporte válido.'); return number; }
export function filterCatalog(items, query = '', category = '') {
    const term = query.trim().toLocaleLowerCase('pt-BR');
    return list(items).filter(item => (!category || item.category === category) && (!term || `${item.name || ''} ${item.model || ''} ${item.category || ''}`.toLocaleLowerCase('pt-BR').includes(term)));
}
export function priceMap(items, draft) {
    const prices = {};
    for (const item of list(items)) {
        const value = draft.get(String(item.id));
        if (value === undefined) continue;
        if (value === '' || !Number.isSafeInteger(Number(value)) || Number(value) < 0) throw new Error(`Preço inválido para ${item.name || item.model}.`);
        prices[item.id] = Number(value);
    }
    return prices;
}

// Recovery shows a finite business summary, never a raw operation document.
export function operationSummary(operation) {
    const detail = operation?.detail || {}, rows = [];
    const append = (title, value) => { if (typeof value === 'string' || typeof value === 'number') rows.push([title, String(value).slice(0, 180)]); };
    append('Operação', operation?.id); append('Tipo', operation?.kind); append('Estado', operation?.phase); append('Mansão', operation?.mansionId); append('Responsável (ID)', operation?.actorId);
    if (Number.isFinite(Number(operation?.createdAt))) rows.push(['Criada em', dateText(operation.createdAt)]);
    if (typeof detail.amount === 'number') rows.push(['Valor envolvido', money(detail.amount)]);
    append('Vale', detail.voucher); append('Quantidade', detail.quantity); append('Morador afetado (ID)', detail.userId); append('Mobília', detail.furnitureId || detail.itemId);
    for (const [key, prefix] of [['before', 'Anterior'], ['after', 'Proposto']]) {
        const snapshot = detail[key]; if (!snapshot || typeof snapshot !== 'object') continue;
        append(`${prefix}: nome`, snapshot.name); append(`${prefix}: cargo`, snapshot.group); append(`${prefix}: proprietário (ID)`, snapshot.ownerId);
        rows.push([`${prefix}: moradores adicionais`, String(list(snapshot.members).length)], [`${prefix}: mobílias`, String(list(snapshot.furniture).length)]);
        if (snapshot.chest) append(`${prefix}: baú`, snapshot.chest.name || (snapshot.chest.enabled === true ? 'Ativado' : 'Desativado'));
        if (snapshot.garage) append(`${prefix}: garagem`, snapshot.garage.id || (snapshot.garage.enabled === true ? 'Ativada' : 'Desativada'));
        rows.push([`${prefix}: trancas`, String(list(snapshot.doors).length)]);
    }
    if (operation?.kind === 'admin_save' && !detail.before) rows.push(['Cadastro anterior', 'Não existia; este cadastro foi iniciado pela operação.']);
    const integrations = detail.integrations;
    if (integrations && typeof integrations === 'object') { append('Cargo registrado na integração', integrations.group?.name); append('Baú registrado na integração', integrations.chest?.name); append('Garagem registrada na integração', integrations.garage?.id); }
    const references = integrations?.groupAssignments;
    if (references && typeof references === 'object') {
        append('Cargo dos vínculos a conferir', references.group);
        const assignments = list(references.assignments), total = Number.isSafeInteger(references.count) && references.count >= 0 ? references.count : assignments.length;
        rows.push(['Vínculos registrados no cargo', String(total)]);
        let shown = 0;
        for (const assignment of assignments.slice(0, 200)) {
            const userId = Number(assignment?.userId); if (!Number.isSafeInteger(userId) || userId <= 0) continue;
            const status = assignment.online === true ? 'Online' : assignment.online === false ? 'Offline' : 'Sessão não informada';
            const expiresAt = Number(assignment.expiresAt);
            const validity = assignment.expiresAt != null && Number.isFinite(expiresAt) && expiresAt > 0
                ? `Validade: ${new Date(expiresAt < 1e12 ? expiresAt * 1000 : expiresAt).toLocaleString('pt-BR', { timeZone: 'America/Sao_Paulo' })} (registro: ${expiresAt})`
                : 'Sem validade registrada';
            rows.push([`Vínculo no cargo: ID ${userId}`, `${status} · ${validity}`]); shown++;
        }
        if (total > shown) rows.push(['Demais vínculos', `${total - shown} não exibidos nesta lista; confira o registro completo antes de declarar a reconciliação.`]);
    }
    return rows;
}
