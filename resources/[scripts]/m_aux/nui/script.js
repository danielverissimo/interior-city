const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'm_aux';

const panel = document.getElementById('panel');
const actionsEl = document.getElementById('actions');
const titleEl = document.getElementById('panelTitle');
const subtitleEl = document.getElementById('panelSubtitle');
const actionCountEl = document.getElementById('actionCount');
const searchEl = document.getElementById('search');
const valueModal = document.getElementById('valueModal');
const detailsModal = document.getElementById('detailsModal');
const valueInput = document.getElementById('valueInput');
const valueTitle = document.getElementById('valueTitle');
const valueDescription = document.getElementById('valueDescription');
const confirmValue = document.getElementById('confirmValue');
const detailsTitle = document.getElementById('detailsTitle');
const detailsGrid = document.getElementById('detailsGrid');
const toast = document.getElementById('toast');
const departmentScreenAlert = document.getElementById('departmentScreenAlert');
const departmentScreenAlertKind = document.getElementById('departmentScreenAlertKind');
const departmentScreenAlertText = document.getElementById('departmentScreenAlertText');
const departmentScreenAlertTime = document.getElementById('departmentScreenAlertTime');


let state = {
    open: false,
    role: null,
    options: [],
    pendingAction: null,
    busy: false
};

async function nui(event, data = {}) {
    const response = await fetch(`https://${resource}/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    });
    try { return await response.json(); } catch (_) { return {}; }
}

function escapeHtml(value) {
    return String(value ?? '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
}

function formatMoney(value) {
    const number = Number(value || 0);
    return new Intl.NumberFormat('pt-BR').format(Number.isFinite(number) ? number : 0);
}

function showToast(message, error = false) {
    if (!message) return;
    toast.textContent = message;
    toast.classList.remove('hidden', 'error');
    if (error) toast.classList.add('error');
    clearTimeout(showToast.timer);
    showToast.timer = setTimeout(() => toast.classList.add('hidden'), 2800);
}

function setAccent(color) {
    const hex = /^#[0-9a-f]{6}$/i.test(color || '') ? color : '#4ea8ff';
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    document.documentElement.style.setProperty('--accent', hex);
    document.documentElement.style.setProperty('--accent-soft', `rgba(${r},${g},${b},.12)`);
    document.documentElement.style.setProperty('--accent-border', `rgba(${r},${g},${b},.42)`);
    document.documentElement.style.setProperty('--accent-glow', `rgba(${r},${g},${b},.18)`);
}

let departmentAlertTimer = null;
let departmentAlertEndsAt = 0;
let departmentAlertToken = 0;

function formatDepartmentAlertTime(totalSeconds) {
    const seconds = Math.max(0, Math.ceil(Number(totalSeconds) || 0));
    const minutes = Math.floor(seconds / 60);
    const remain = seconds % 60;
    return `${String(minutes).padStart(2, '0')}:${String(remain).padStart(2, '0')}`;
}

function parseAlertAccent(color) {
    const hex = /^#[0-9a-f]{6}$/i.test(color || '') ? color : '#4ea8ff';
    return {
        hex,
        r: parseInt(hex.slice(1, 3), 16),
        g: parseInt(hex.slice(3, 5), 16),
        b: parseInt(hex.slice(5, 7), 16)
    };
}

function stopDepartmentScreenAlert() {
    if (departmentAlertTimer) {
        clearInterval(departmentAlertTimer);
        departmentAlertTimer = null;
    }
    departmentAlertEndsAt = 0;
    departmentScreenAlert?.classList.remove('is-visible');
    departmentScreenAlert?.setAttribute('aria-hidden', 'true');
}

function showDepartmentScreenAlert(data = {}) {
    stopDepartmentScreenAlert();
    const token = ++departmentAlertToken;
    const duration = Math.max(3, Math.min(300, Number(data.duration) || 15));
    const accent = parseAlertAccent(data.accent);
    const message = String(data.message || 'Comunicado do setor.');

    departmentAlertEndsAt = Date.now() + (duration * 1000);
    departmentScreenAlert?.style.setProperty('--notice-accent', accent.hex);
    departmentScreenAlert?.style.setProperty('--notice-rgb', `${accent.r}, ${accent.g}, ${accent.b}`);
    if (departmentScreenAlertKind) departmentScreenAlertKind.textContent = String(data.title || 'AVISO').toUpperCase();
    if (departmentScreenAlertText) {
        departmentScreenAlertText.textContent = message;
        departmentScreenAlertText.classList.toggle('is-long-text', message.length > 180 && message.length <= 420);
        departmentScreenAlertText.classList.toggle('is-very-long-text', message.length > 420);
    }
    if (departmentScreenAlertTime) departmentScreenAlertTime.textContent = formatDepartmentAlertTime(duration);

    departmentScreenAlert?.classList.add('is-visible');
    departmentScreenAlert?.setAttribute('aria-hidden', 'false');

    departmentAlertTimer = setInterval(() => {
        if (token !== departmentAlertToken) return;
        const remaining = (departmentAlertEndsAt - Date.now()) / 1000;
        if (departmentScreenAlertTime) departmentScreenAlertTime.textContent = formatDepartmentAlertTime(remaining);
        if (remaining <= 0) stopDepartmentScreenAlert();
    }, 100);
}

function renderActions() {
    const q = searchEl.value.trim().toLowerCase();
    const filtered = state.options.filter(opt => {
        const text = `${opt.nome || ''} ${opt.descricao || ''}`.toLowerCase();
        return !q || text.includes(q);
    });

    actionCountEl.textContent = `${filtered.length} ${filtered.length === 1 ? 'função' : 'funções'}`;

    if (!filtered.length) {
        actionsEl.innerHTML = '<div class="empty-state">Nenhuma função encontrada.</div>';
        return;
    }

    actionsEl.innerHTML = filtered.map(opt => `
        <button class="action-card" data-action="${escapeHtml(opt.func_)}">
            <span class="action-copy">
                <strong>${escapeHtml(opt.nome)}</strong>
                <small>${escapeHtml(opt.descricao || 'Executar esta função')}</small>
            </span>
            <span class="action-arrow">›</span>
        </button>
    `).join('');

    actionsEl.querySelectorAll('.action-card').forEach(button => {
        button.addEventListener('click', () => {
            const opt = state.options.find(item => item.func_ === button.dataset.action);
            if (opt) selectAction(opt);
        });
    });
}

function openPanel(data) {
    state.open = true;
    state.role = data.type;
    const tableKey = `${data.type}_options`;
    state.options = Array.isArray(data.table?.[tableKey]) ? data.table[tableKey] : [];
    const info = data.roleInfo || {};
    setAccent(info.accent);
    titleEl.textContent = info.title || 'PAINEL DE SERVIÇO';
    subtitleEl.textContent = info.subtitle || 'Selecione uma ação operacional';
    searchEl.value = '';
    renderActions();
    panel.classList.remove('hidden');
    panel.setAttribute('aria-hidden', 'false');
    setTimeout(() => searchEl.focus(), 80);
}

function hidePanel() {
    state.open = false;
    state.busy = false;
    panel.classList.add('hidden');
    panel.setAttribute('aria-hidden', 'true');
    valueModal.classList.add('hidden');
    detailsModal.classList.add('hidden');
}

async function requestClose() {
    hidePanel();
    await nui('close');
}

function selectAction(option) {
    if (state.busy) return;
    if (option.pede_valor) {
        state.pendingAction = option;
        valueTitle.textContent = option.nome || 'Informe o valor';
        valueDescription.textContent = state.role === 'medic'
            ? 'Digite o valor do atendimento. Use 0 para atendimento gratuito.'
            : 'Digite o valor da cobrança que será enviada ao cidadão.';
        valueInput.value = state.role === 'medic' ? Number(option.valor_tratamento || 0) : '';
        valueModal.classList.remove('hidden');
        setTimeout(() => { valueInput.focus(); valueInput.select(); }, 50);
        return;
    }
    executeAction(option, undefined);
}

async function executeAction(option, value) {
    if (!option || state.busy) return;
    state.busy = true;
    actionsEl.querySelectorAll('button').forEach(btn => btn.disabled = true);

    try {
        const result = await nui('action', {
            role: state.role,
            action: option.func_,
            value
        });

        if (result?.details) {
            showDetails(result.details, result.detailsType);
            if (result.message) showToast(result.message, !result.ok);
        } else if (result?.message && result.close === false) {
            showToast(result.message, !result.ok);
        }

        if (result?.close === true) hidePanel();
    } catch (_) {
        showToast('Não foi possível concluir esta ação.', true);
    } finally {
        state.busy = false;
        actionsEl.querySelectorAll('button').forEach(btn => btn.disabled = false);
    }
}

function showDetails(details, type) {
    detailsTitle.textContent = type === 'vehicle' ? 'Consulta de placa' : 'Dados do cidadão';
    const rows = [];
    if (type === 'vehicle') {
        rows.push(['Placa', details.placa || 'Não informado']);
        rows.push(['Veículo', details.veiculo || 'Não informado']);
    }
    rows.push(['Nome', `${details.nome || ''} ${details.sobrenome || ''}`.trim() || 'Não informado', true]);
    rows.push(['ID', details.id ?? '—']);
    rows.push(['Registro', details.registro || '—']);
    rows.push(['Idade', `${details.idade ?? '—'} anos`]);
    rows.push(['Telefone', details.telefone || '—']);
    rows.push(['Multas', `R$ ${formatMoney(details.multas)}`]);
    rows.push(['Carteira', `R$ ${formatMoney(details.carteira)}`]);
    rows.push(['Banco', `R$ ${formatMoney(details.banco)}`]);

    detailsGrid.innerHTML = rows.map(([label, value, wide]) => `
        <div class="detail ${wide ? 'wide' : ''}">
            <span>${escapeHtml(label)}</span>
            <strong>${escapeHtml(value)}</strong>
        </div>
    `).join('');
    detailsModal.classList.remove('hidden');
}

confirmValue.addEventListener('click', () => {
    if (!state.pendingAction) return;
    const value = Number(valueInput.value);
    if (!Number.isFinite(value) || value < 0 || value > 500000 || (state.role === 'mecanic' && value < 1)) {
        showToast('Digite um valor válido.', true);
        return;
    }
    const option = state.pendingAction;
    state.pendingAction = null;
    valueModal.classList.add('hidden');
    executeAction(option, Math.floor(value));
});

valueInput.addEventListener('keydown', event => {
    if (event.key === 'Enter') confirmValue.click();
});

searchEl.addEventListener('input', renderActions);

document.querySelectorAll('[data-close-modal]').forEach(button => {
    button.addEventListener('click', () => {
        const modal = button.dataset.closeModal;
        if (modal === 'value') {
            state.pendingAction = null;
            valueModal.classList.add('hidden');
        } else {
            detailsModal.classList.add('hidden');
        }
    });
});

document.addEventListener('keydown', event => {
    if (event.key !== 'Escape') return;
    if (!detailsModal.classList.contains('hidden')) {
        detailsModal.classList.add('hidden');
        return;
    }
    if (!valueModal.classList.contains('hidden')) {
        state.pendingAction = null;
        valueModal.classList.add('hidden');
        return;
    }
    if (state.open) requestClose();
});

window.addEventListener('message', event => {
    const data = event.data || {};
    if (data.action === 'open') openPanel(data);
    if (data.action === 'close') hidePanel();
    if (data.action === 'departmentAlert') showDepartmentScreenAlert(data);
});
