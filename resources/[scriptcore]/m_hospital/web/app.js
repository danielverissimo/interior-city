const resource = typeof GetParentResourceName === 'function'
    ? GetParentResourceName()
    : 'm_hospital';

const $ = (q) => document.querySelector(q);
const $$ = (q) => [...document.querySelectorAll(q)];

const ICONS = {
    medical: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M9.5 3.5h5v6h6v5h-6v6h-5v-6h-6v-5h6z"/></svg>',
    mechanic: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M22.7 19 13.6 9.9c.9-2.3.4-5-1.5-6.9C10.2 1.1 7.3.6 5 1.7l4.3 4.3-3 3L1.9 4.7C.8 7 .3 9.9 2.2 11.8c1.9 1.9 4.6 2.4 6.9 1.5l9.1 9.1c.4.4 1 .4 1.4 0l3.1-3.1c.4-.3.4-.9 0-1.3Z"/></svg>',
};

let state = null;
let currentView = 'team';
let modalAction = null;
let refreshTimer = null;

let diagnosisOpen = false;
let diagnosisBusy = false;
let diagnosisData = null;

async function nui(event, data = {}) {
    try {
        const res = await fetch(`https://${resource}/${event}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data),
        });
        return await res.json();
    } catch (_) {
        return { ok: false, message: 'Não foi possível comunicar com o painel.' };
    }
}

function escapeHtml(value) {
    return String(value ?? '').replace(
        /[&<>'"]/g,
        (c) => ({
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            "'": '&#39;',
            '"': '&quot;',
        }[c]),
    );
}

function panelInfo() {
    return state?.panel || {};
}

function panelTexts() {
    return panelInfo().texts || {};
}

function panelDisplayName() {
    return panelInfo().displayName || panelInfo().organization || 'Organização';
}

function toast(message, ok = true) {
    const el = $('#toast');
    el.textContent = message || (ok ? 'Operação realizada.' : 'Não foi possível concluir.');
    el.className = `toast ${ok ? 'success' : 'error'}`;
    clearTimeout(el._timer);
    el._timer = setTimeout(() => el.classList.add('hidden'), 3400);
}

function applyPanelPresentation() {
    const panel = panelInfo();
    const texts = panelTexts();
    const app = $('#app');

    const themeClass = `theme-${panel.theme || 'hospital'}`;

    app.classList.remove('theme-hospital', 'theme-mechanic', 'theme-lscustoms');
    app.classList.add(themeClass);

    // O modal fica fora de #app no HTML, então ele não herdava as variáveis
    // de cor da Sport Racer e continuava usando o rosa padrão do Hospital.
    const modalLayer = $('#modalLayer');
    if (modalLayer) {
        modalLayer.classList.remove('theme-hospital', 'theme-mechanic', 'theme-lscustoms');
        modalLayer.classList.add(themeClass);
    }

    $('#brandTitle').textContent = panel.brand || panelDisplayName().toUpperCase();
    $('#brandSubtitle').textContent = panel.brandSubtitle || 'Gestão de equipe';
    $('#brandIcon').innerHTML = ICONS[panel.icon] || ICONS.medical;

    $('#actorStatus').textContent = texts.actorStatus || 'Equipe';
    $('#teamHeading').textContent = texts.teamHeading || 'Equipe online';
    $('#teamDescription').textContent =
        texts.teamDescription || 'ID, identificação, cargo e situação no bate-ponto.';

    $('#rankingHeading').textContent = texts.rankingHeading || 'Ranking de horas';
    $('#rankingDescription').textContent =
        texts.rankingDescription || 'Horas acumuladas em serviço.';

    $('#rankingPersonHeader').textContent = texts.personColumn || 'Membro';
    $('#teamEmpty').textContent = texts.teamEmpty || 'Nenhum membro está online agora.';
    $('#rankingEmpty').textContent =
        texts.rankingEmpty || 'Ainda não existem dados de serviço.';

    $('#statThirdLabel').textContent = texts.thirdStatLabel || 'Horas acumuladas';
    $('#statThirdSmall').textContent = texts.thirdStatSmall || 'horas em serviço';

    const showCalls = panel.metric === 'calls';
    $('#rankingCallsHeader').classList.toggle('hidden', !showCalls);

    switchView(currentView);
}

function renderStats() {
    const s = state?.stats || {};
    const panel = panelInfo();

    $('#statOnline').textContent = s.online ?? 0;
    $('#statDuty').textContent = s.onDuty ?? 0;
    $('#statThird').textContent =
        panel.metric === 'calls'
            ? (s.calls ?? 0)
            : (s.totalHours ?? 0);
}

function actorCanManageTarget(member) {
    const actor = state?.actor;

    if (!actor?.canManage || Number(member.id) === Number(actor.userId)) {
        return false;
    }

    return Number(member.rank) > Number(actor.rank);
}

function renderTeam() {
    const body = $('#teamBody');
    const rows = state?.roster || [];
    const orgName = panelDisplayName();

    $('#teamEmpty').classList.toggle('hidden', rows.length > 0);

    body.innerHTML = rows.map((member) => {
        const canManage = actorCanManageTarget(member);

        const actions = canManage
            ? `
                <div class="row-actions">
                    <button class="btn small ghost" data-promote="${member.id}">Promover</button>
                    <button class="btn small danger" data-dismiss="${member.id}">Exonerar</button>
                </div>`
            : '<span style="color:#596174;font-size:9px">—</span>';

        return `
            <tr>
                <td>#${member.id}</td>
                <td class="member-name">${escapeHtml(member.nome || '-')}</td>
                <td>${escapeHtml(member.sobrenome || '-')}</td>
                <td><span class="role-badge">${escapeHtml(member.cargoLabel || member.cargo)}</span></td>
                <td><span class="status-badge ${member.emServico ? 'duty' : 'off'}">${member.emServico ? 'Em serviço' : 'Paisana'}</span></td>
                <td>${actions}</td>
            </tr>`;
    }).join('');

    $$('[data-promote]').forEach((btn) => {
        btn.onclick = () => {
            const id = Number(btn.dataset.promote);
            const member = rows.find((x) => Number(x.id) === id);

            openConfirm(
                'Promover funcionário',
                `Deseja promover ${member?.nomeCompleto || `ID ${id}`} para o próximo cargo da hierarquia da ${orgName}?`,
                () => perform('promote', id),
            );
        };
    });

    $$('[data-dismiss]').forEach((btn) => {
        btn.onclick = () => {
            const id = Number(btn.dataset.dismiss);
            const member = rows.find((x) => Number(x.id) === id);

            openConfirm(
                'Exonerar funcionário',
                `Deseja remover ${member?.nomeCompleto || `ID ${id}`} da equipe da ${orgName}?`,
                () => perform('dismiss', id),
                true,
            );
        };
    });
}

function renderRanking() {
    const body = $('#rankingBody');
    const rows = state?.ranking || [];
    const showCalls = panelInfo().metric === 'calls';

    $('#rankingEmpty').classList.toggle('hidden', rows.length > 0);

    body.innerHTML = rows.map((row) => {
        const cls = row.posicao <= 3 ? `top${row.posicao}` : '';
        const callsCell = showCalls ? `<td>${row.chamados ?? 0}</td>` : '';

        return `
            <tr>
                <td><span class="rank-medal ${cls}">${row.posicao}º</span></td>
                <td class="member-name">${escapeHtml(row.nomeCompleto)}</td>
                <td><span class="role-badge">${escapeHtml(row.cargoLabel || row.cargo)}</span></td>
                <td>${escapeHtml(row.tempo || '00:00:00')}</td>
                ${callsCell}
                <td><span class="status-badge ${row.emServico ? 'duty' : 'off'}">${row.emServico ? 'Em serviço' : (row.online ? 'Online' : 'Offline')}</span></td>
            </tr>`;
    }).join('');
}

function renderProductivity() {
    const data = state?.productivity || {};
    const columns = Array.isArray(data.columns) ? data.columns : [];
    const query = $('#productivitySearch').value.trim().toLocaleLowerCase('pt-BR');
    const rows = (Array.isArray(data.rows) ? data.rows : []).filter(row =>
        String(row.id).includes(query) || String(row.name).toLocaleLowerCase('pt-BR').includes(query));
    const number = value => Math.max(0, Number(value) || 0).toLocaleString('pt-BR');
    $('#productivityHead').innerHTML = `<tr><th>ID</th><th>Membro / cargo</th>${columns.map(c=>`<th>${escapeHtml(c.label)}</th>`).join('')}<th>Total</th></tr>`;
    $('#productivityBody').innerHTML = data.available === true ? rows.map(row=>`<tr>
        <td>#${number(row.id)}</td>
        <td class="member-name">${escapeHtml(row.name)}<small>${escapeHtml(row.role)} · ${row.online?'Online':'Offline'}</small></td>
        ${columns.map(c=>`<td>${number(row.counts?.[c.key])}</td>`).join('')}
        <td><strong>${number(row.total)}</strong></td>
    </tr>`).join('') : '';
    $('#productivitySummary').innerHTML = data.available === true ? columns.map(c=>`<div><span>${escapeHtml(c.label)}</span><strong>${number(data.totals?.[c.key])}</strong></div>`).join('') : '';
    $('#productivityEmpty').textContent = data.available === true ? 'Nenhum membro encontrado.' : (data.message || 'Produtividade indisponível.');
    $('#productivityEmpty').classList.toggle('hidden', data.available === true && rows.length > 0);
}

function renderActor() {
    const a = state?.actor || {};

    $('#actorRole').textContent = a.roleLabel || panelDisplayName();
    $('#actorStatus').textContent = panelTexts().actorStatus || 'Equipe';
    $('#hireButton').classList.toggle('hidden', !a.canHire);
}

function renderAll() {
    if (!state) return;

    applyPanelPresentation();
    renderStats();
    renderActor();
    renderTeam();
    renderRanking();
    renderProductivity();
}

function switchView(view) {
    currentView = view;

    $$('.nav-item').forEach((x) => {
        x.classList.toggle('active', x.dataset.view === view);
    });

    $('#teamView').classList.toggle('active', view === 'team');
    $('#rankingView').classList.toggle('active', view === 'ranking');
    $('#productivityView').classList.toggle('active', view === 'productivity');

    const texts = panelTexts();

    if (view === 'productivity') {
        $('#pageTitle').textContent = `Produtividade • ${panelDisplayName()}`;
        $('#pageSubtitle').textContent = 'Quantidade de cada serviço realizado pelos membros da equipe.';
    } else if (view === 'team') {
        $('#pageTitle').textContent =
            texts.teamTitle || `Equipe da ${panelDisplayName()}`;
        $('#pageSubtitle').textContent =
            texts.teamSubtitle || 'Membros online organizados por hierarquia.';
    } else {
        $('#pageTitle').textContent =
            texts.rankingTitle || `Ranking da ${panelDisplayName()}`;
        $('#pageSubtitle').textContent =
            texts.rankingSubtitle || 'Tempo de serviço registrado pelo bate-ponto.';
    }
}

function openHire() {
    const panel = panelInfo();
    const texts = panelTexts();
    const initialRole = panel.initialRoleLabel || 'cargo inicial';

    modalAction = async () => {
        const id = Number($('#hireId').value);

        if (!id || id < 1) {
            return toast('Informe um ID válido.', false);
        }

        await perform('hire', id);
    };

    $('#modalTitle').textContent = 'Contratar funcionário';
    $('#modalText').textContent =
        `Informe o ID do jogador online. Ele será cadastrado como ${initialRole}. ${texts.hireDescription || ''}`.trim();

    $('#hireInputWrap').classList.remove('hidden');
    $('#hireId').value = '';
    $('#modalConfirm').classList.remove('danger');
    $('#modalLayer').classList.remove('hidden');

    setTimeout(() => $('#hireId').focus(), 50);
}

function openConfirm(title, text, action, danger = false) {
    modalAction = action;
    $('#modalTitle').textContent = title;
    $('#modalText').textContent = text;
    $('#hireInputWrap').classList.add('hidden');
    $('#modalConfirm').classList.toggle('danger', danger);
    $('#modalLayer').classList.remove('hidden');
}

function closeModal() {
    modalAction = null;
    $('#modalLayer').classList.add('hidden');
    $('#modalConfirm').classList.remove('danger');
}

async function perform(action, id) {
    const response = await nui(action, { id });

    if (!response?.ok) {
        return toast(response?.message || 'Não foi possível concluir.', false);
    }

    if (response.data?.ok) {
        state = response.data;
    } else {
        await refreshData(false);
    }

    renderAll();
    closeModal();
    toast(response.message || 'Operação concluída.');
}

async function refreshData(feedback = false) {
    const data = await nui('refresh');

    if (!data?.ok) {
        if (feedback) {
            toast(data?.message || 'Não foi possível atualizar.', false);
        }
        return;
    }

    state = data;
    renderAll();

    if (feedback) {
        toast('Painel atualizado.');
    }
}

function openApp(data) {
    state = data;
    currentView = 'team';
    $('#productivitySearch').value = '';

    $('#app').classList.remove('hidden');
    renderAll();

    clearInterval(refreshTimer);
    refreshTimer = setInterval(
        () => refreshData(false),
        Number(data?.refreshSeconds || 15) * 1000,
    );
}

function closeApp() {
    $('#app').classList.add('hidden');
    closeModal();

    clearInterval(refreshTimer);
    refreshTimer = null;
}


function renderDiagnosis(data) {
    diagnosisData = data || {};

    $('#diagnosisPatient').textContent =
        `${diagnosisData.patientName || 'Paciente'} • ID ${diagnosisData.patientId || '-'}`;

    const health = diagnosisData.health || {};
    const percent = Math.max(0, Math.min(100, Number(health.percent) || 0));

    $('#diagnosisHealthText').textContent = `${Math.round(percent)}%`;
    $('#diagnosisRawHealth').textContent =
        `${Number(health.current) || 0} / ${Number(health.maximum) || 0} HP`;

    const fill = $('#diagnosisHealthFill');
    fill.style.width = `${percent}%`;

    if (percent < 40) {
        fill.style.background = '#e64747';
    } else if (percent < 60) {
        fill.style.background = '#f0a649';
    } else if (percent < 80) {
        fill.style.background = '#39a9ff';
    } else {
        fill.style.background = '#46cf88';
    }

    const status = $('#diagnosisStatus');
    status.textContent = diagnosisData.status || 'ESTÁVEL';
    status.className = `diagnosis-status ${diagnosisData.statusClass || 'stable'}`;

    $('#diagnosisText').textContent = diagnosisData.diagnosis || 'Sem alterações relevantes.';
    $('#diagnosisPartLabel').textContent = diagnosisData.injuredPartLabel || '—';
    $('#diagnosisStateText').textContent = diagnosisData.status || '—';
    $('#diagnosisMessage').textContent = '';

    $$('#diagnosisBody .body-part').forEach((part) => {
        part.classList.toggle('is-injured', part.dataset.part === diagnosisData.injuredPart);
    });
}

function openDiagnosis(data) {
    diagnosisOpen = true;
    diagnosisBusy = false;
    renderDiagnosis(data);

    $('#diagnosisTreatButton').disabled = false;
    $('#diagnosisPanel').classList.remove('hidden');
    $('#diagnosisPanel').setAttribute('aria-hidden', 'false');
}

function hideDiagnosis(send = false) {
    if (!diagnosisOpen && !send) return;

    diagnosisOpen = false;
    diagnosisBusy = false;
    diagnosisData = null;

    $('#diagnosisPanel').classList.add('hidden');
    $('#diagnosisPanel').setAttribute('aria-hidden', 'true');
    $('#diagnosisMessage').textContent = '';
    $('#diagnosisTreatButton').disabled = false;

    if (send) {
        nui('diagnosisClose');
    }
}

async function medicateDiagnosis() {
    if (!diagnosisOpen || diagnosisBusy) return;

    diagnosisBusy = true;
    const button = $('#diagnosisTreatButton');
    button.disabled = true;
    $('#diagnosisMessage').textContent = 'Iniciando tratamento...';

    const result = await nui('diagnosisMedicate', {
        sessionId: diagnosisData?.sessionId,
    });

    if (!result?.ok) {
        diagnosisBusy = false;
        button.disabled = false;
        $('#diagnosisMessage').textContent =
            result?.message || 'Não foi possível iniciar o tratamento.';
        return;
    }

    hideDiagnosis(false);
}

$('#diagnosisTreatButton').onclick = medicateDiagnosis;

window.addEventListener('message', (event) => {
    const msg = event.data || {};

    if (msg.action === 'open') {
        openApp(msg.data);
    }

    if (msg.action === 'update' && msg.data?.ok) {
        state = msg.data;
        renderAll();
    }

    if (msg.action === 'close') {
        closeApp();
    }

    if (msg.action === 'diagnosis:open') {
        openDiagnosis(msg.data || {});
    }

    if (msg.action === 'diagnosis:close') {
        hideDiagnosis(false);
    }
});

$$('.nav-item').forEach((btn) => {
    btn.onclick = () => switchView(btn.dataset.view);
});

$('#closeButton').onclick = () => nui('close');
$('#hireButton').onclick = openHire;
$('#modalCancel').onclick = closeModal;

$('#modalConfirm').onclick = async () => {
    if (modalAction) {
        await modalAction();
    }
};

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        if (diagnosisOpen) {
            e.preventDefault();
            hideDiagnosis(true);
            return;
        }

        if (!$('#modalLayer').classList.contains('hidden')) {
            closeModal();
        } else if (!$('#app').classList.contains('hidden')) {
            nui('close');
        }
    }

    if (
        e.key === 'Enter'
        && !$('#modalLayer').classList.contains('hidden')
        && modalAction
    ) {
        modalAction();
    }
});

$('#productivitySearch').addEventListener('input', renderProductivity);
