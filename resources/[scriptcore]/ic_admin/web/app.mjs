import { createTransport, escapeHtml as h, rowsOf, isAllowed } from './transport.mjs';
import { createMonitor } from './monitor.mjs';

const $ = (s, root = document) => root.querySelector(s);
const $$ = (s, root = document) => [...root.querySelectorAll(s)];
const rpc = createTransport({ resource: typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'ic_admin' });
const state = { page: 'server', bootstrap: null, data: null, selected: null, sequence: 0, modalCleanup: null };
const money = value => Number(value || 0).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
const date = value => value ? new Date(typeof value === 'number' && value < 1e12 ? value * 1000 : value).toLocaleString('pt-BR') : '—';
const nav = [
    ['server', 'Servidor', '⌘', 'view_server', 'Ações gerais e estado da cidade.'],
    ['players', 'Jogadores', '♟', 'view_players', 'Encontre jogadores e consulte seus dados.'],
    ['warnings', 'Advertências', '△', 'view_warnings', 'Histórico de disciplina e castigos.'],
    ['map', 'Mapa', '⌖', 'view_map', 'Posições dos jogadores e monitoramento ao vivo.'],
    ['calls', 'Chamados', '☏', 'view_calls', 'Atendimento, histórico e avaliações da equipe.'],
    ['groups', 'Setagem', '♜', 'view_groups', 'Gerencie os grupos de jogadores conectados.'],
    ['identity', 'Alterar RG', '▣', 'view_identity_editor', 'Identidade, saldos e manutenção de passaporte.'],
    ['items', 'Itens', '◇', 'view_items', 'Catálogo de itens da cidade.'],
    ['weapons', 'Armas', '⌁', 'view_weapons', 'Armas e munições reconhecidas pelo inventário.'],
    ['vips', 'VIPs', '☆', 'view_vips', 'Pacotes de 30 dias e benefícios sem duplicação.'],
    ['vehicles', 'Veículos', '▰', 'view_vehicles', 'Catálogo, garagem e veículos administrativos.'],
    ['radio', 'Rádio', '≋', 'view_radio', 'Frequências privadas e permissões de acesso.'],
    ['locations', 'Locais', '⌂', 'view_locations', 'Pontos e teleportes administrativos.'],
    ['climate', 'Clima', '☀', 'view_climate', 'Clima e horário sincronizados da cidade.'],
    ['logs', 'Logs', '≡', 'view_logs', 'Auditoria e destinos de notificações.']
];
const can = key => isAllowed(state.bootstrap?.permissions, key);
const action = (key, title, fields = [], dangerous = false, permission = key) => ({ key, title, fields, dangerous, permission });
const targetField = { name: 'targetId', label: 'Passaporte / ID', type: 'number', required: true, min: 1 };
const reasonField = { name: 'reason', label: 'Motivo', type: 'textarea', required: true, maxLength: 500, full: true };
const amountField = { name: 'amount', label: 'Quantidade', type: 'number', min: 1, required: true };
const actions = [
    action('wladd', 'Liberar whitelist', [targetField, reasonField]), action('wlrem', 'Remover whitelist', [targetField, reasonField], true),
    action('ban', 'Banir jogador', [targetField, reasonField], true), action('unban', 'Desbanir jogador', [targetField, reasonField]),
    action('kick', 'Expulsar jogador', [targetField, reasonField], true), action('god', 'Reviver jogador', [targetField]),
    action('godall', 'Reviver todos', [reasonField]), action('kill', 'Abater jogador', [targetField, reasonField], true),
    action('freeze', 'Congelar jogador', [targetField]), action('unfreeze', 'Descongelar jogador', [targetField]),
    action('send_dm', 'Mensagem privada', [targetField, { name: 'message', label: 'Mensagem', required: true, type: 'textarea', full: true }, { name: 'durationSeconds', label: 'Duração (segundos)', type: 'number', value: 8, min: 1, max: 300 }]),
    action('send_adm', 'Aviso geral', [{ name: 'message', label: 'Mensagem', type: 'textarea', full: true, required: true }, { name: 'durationSeconds', label: 'Duração (segundos)', type: 'number', min: 1, max: 300, value: 8 }]),
    action('tpto', 'Ir até jogador', [targetField]), action('tptome', 'Trazer jogador', [targetField]),
    action('tpway', 'Ir ao waypoint'), action('tpcds', 'Teleportar por coordenadas', [{ name: 'x', label: 'X', type: 'number', step: 'any', required: true }, { name: 'y', label: 'Y', type: 'number', step: 'any', required: true }, { name: 'z', label: 'Z', type: 'number', step: 'any', required: true }]),
    action('spawn_veh', 'Spawnar veículo', [{ name: 'vehicle', label: 'Spawn do veículo', required: true }]),
    action('give_veh', 'Entregar veículo', [targetField, { name: 'vehicle', label: 'Spawn do veículo', required: true }, reasonField]),
    action('rem_veh', 'Remover da garagem', [targetField, { name: 'vehicle', label: 'Spawn do veículo', required: true }, reasonField], true),
    action('fix', 'Reparar veículo'), action('tuning', 'Tunar veículo'), action('hash', 'Consultar hash'), action('dv', 'Deletar veículo', [reasonField], true),
    action('clear_allveh', 'Limpar veículos vazios', [reasonField], true), action('clear_props', 'Limpar props próximos', [reasonField], true),
    action('clear_inv', 'Limpar inventário', [targetField, reasonField], true, 'clear_inv'), action('clear_weapons', 'Limpar armas', [targetField, reasonField], true)
];
const actionById = new Map(actions.map(entry => [entry.key, entry]));
const visibleNav = () => nav.filter(entry => can(entry[3]));
const metric = (label, value) => `<article class="metric"><small>${h(label)}</small><strong>${h(value)}</strong></article>`;
const empty = (title, text = '') => `<div class="empty"><strong>${h(title)}</strong><span>${h(text)}</span></div>`;
const btn = (label, attrs, style = '') => `<button type="button" class="button ${style}" ${attrs}>${h(label)}</button>`;
const heading = (title, subtitle = '', right = '') => `<div class="section-heading"><div><h2>${h(title)}</h2><p>${h(subtitle)}</p></div>${right}</div>`;
const toolbar = placeholder => `<div class="toolbar"><input class="input" id="page-search" placeholder="${h(placeholder || 'Buscar nesta área...')}" aria-label="Buscar nesta área"></div>`;
const table = (heads, rows) => rows.length ? `<div class="table-scroll"><table><thead><tr>${heads.map(x => `<th>${h(x)}</th>`).join('')}</tr></thead><tbody>${rows.join('')}</tbody></table></div>` : empty('Nenhum registro encontrado', 'Atualize a área ou ajuste os filtros.');
const row = (cells, search = '') => `<tr data-search="${h(search.toLocaleLowerCase())}">${cells.map(x => `<td>${x}</td>`).join('')}</tr>`;
const online = yes => `<span class="pill ${yes ? 'green' : ''}">${yes ? 'Online' : 'Offline'}</span>`;

function toast(message, error = false) {
    const el = document.createElement('div'); el.className = `toast ${error ? 'error' : ''}`; el.textContent = message;
    $('#toast-layer').append(el); setTimeout(() => el.remove(), error ? 9000 : 4500);
}

async function call(method, payload = {}) {
    $('#status').textContent = 'Aguardando servidor...';
    try { return await rpc.call(method, payload); }
    finally { $('#status').textContent = 'Conectado à cidade'; }
}

function updateShell() {
    const metadata = nav.find(x => x[0] === state.page) || nav[0];
    $('#navigation').innerHTML = visibleNav().map(([id, label, icon]) => `<button type="button" data-nav="${id}" class="${id === state.page ? 'active' : ''}" title="${h(label)}"><span class="nav-icon">${icon}</span><span class="nav-text">${h(label)}</span></button>`).join('');
    $('#title').textContent = metadata[1]; $('#description').textContent = metadata[4];
    const admin = state.bootstrap?.admin || {};
    $('#staff-name').textContent = `${admin.name || 'Equipe'} · #${admin.id || '?'}`;
    $('#staff-role').textContent = admin.role || '';
    $('#online-count').textContent = `${state.bootstrap?.stats?.players ?? state.bootstrap?.players?.length ?? 0} online`;
    $('#permissions').hidden = state.bootstrap?.permissions?.canManage !== true;
}

async function loadPage() {
    const serial = ++state.sequence;
    updateShell(); $('#content').innerHTML = '<div class="loading">Carregando dados da cidade...</div>';
    try {
        let data;
        if (state.page === 'server') data = can('view_players') ? await call('players.list') : { players: [], stats: state.bootstrap.stats || {} };
        else if (state.page === 'players' || state.page === 'map') data = await call('players.list');
        else if (state.page === 'warnings') data = await call('warnings.list', {});
        else if (state.page === 'calls') data = await call('calls.list', {});
        else if (['items', 'weapons', 'vehicles', 'groups'].includes(state.page)) data = await call('catalog.get');
        else if (state.page === 'vips') data = await call('vip.list');
        else if (state.page === 'radio') data = await call('radio.list');
        else if (state.page === 'locations') data = await call('locations.list');
        else if (state.page === 'climate') data = await call('world.get');
        else if (state.page === 'logs') { const [audit, destinations] = await Promise.all([call('audit.list', { page: 1 }), call('audit.destinations')]); data = { audit, destinations }; }
        else data = {};
        if (serial !== state.sequence) return;
        state.data = data; renderPage();
    } catch (error) {
        if (serial !== state.sequence) return;
        $('#content').innerHTML = empty('Não foi possível carregar', error.message);
        toast(error.message, true);
    }
}

function actionCards(keys = actions.map(x => x.key)) {
    const descriptions = {wladd:'Autorize a entrada do passaporte na cidade.',wlrem:'Retire a autorização de acesso à cidade.',ban:'Bloqueie o acesso do jogador, registrando o motivo.',unban:'Remova o bloqueio de acesso de um passaporte.',send_adm:'Envie uma mensagem para todos os jogadores.',godall:'Reanime todos os jogadores conectados.',tpway:'Vá para a marcação atual do seu mapa.',tpcds:'Informe a posição para onde deseja ir.',clear_allveh:'Agende a remoção de veículos sem ocupantes.',clear_props:'Remova objetos próximos do seu personagem.',spawn_veh:'Crie um veículo próximo do seu personagem.',give_veh:'Adicione um veículo à garagem do jogador.',rem_veh:'Retire um veículo da garagem do jogador.',fix:'Repare seu veículo atual ou o mais próximo.',tuning:'Aplique melhorias ao veículo atual.',hash:'Consulte o modelo e o hash do veículo.',dv:'Remova o veículo atual ou o mais próximo.'};
    return `<div class="cards">${keys.map(key => actionById.get(key)).filter(x => x && can(x.permission)).map(x => `<article class="card" data-search="${h(x.title.toLowerCase())}"><h3>${h(x.title)}</h3><p>${h(descriptions[x.key] || 'Selecione o jogador e confira os dados da ação.')}</p>${btn('Abrir ação', `data-action="${x.key}"`, x.dangerous ? 'danger' : '')}</article>`).join('')}</div>`;
}

function renderPage() {
    const data = state.data || {};
    const page = state.page;
    let html = '';
    if (page === 'server') {
        const players = rowsOf(data, 'players'); state.bootstrap.players = players; state.bootstrap.stats = data.stats || {players:players.length}; updateShell();
        const shortcuts = `<div class="actions">${can('catch_rg') ? btn('Consultar RG','data-command="lookup"') : ''}${can('ban_history_view') ? btn('Histórico de bans','data-command="ban-history"') : ''}</div>`;
        html = `<div class="metrics">${metric('JOGADORES ONLINE', state.bootstrap.stats.players ?? players.length)}${metric('SEU PASSAPORTE', `#${state.bootstrap.admin?.id || '?'}`)}${metric('AMBIENTE', state.bootstrap.mode === 'active' ? 'Ativo' : 'Homologação')}</div>${heading('Administração da cidade', 'Cada operação registra o administrador e seu resultado.',shortcuts)}${toolbar()}${actionCards(['wladd','wlrem','ban','unban','send_adm','godall','tpway','tpcds','clear_allveh','clear_props'])}`;
        if (can('needs_manage')) html += `<article class="card"><h3>Fome e sede</h3><p>Controle o consumo e os efeitos do sistema.</p>${btn('Configurar', 'data-command="needs"')}</article>`;
        if (['dono', 'developer'].includes(state.bootstrap.admin?.role)) html += heading('Manutenção de passaporte', 'Operações exclusivas de Dono e Developer, com o alvo desconectado.') + `<div class="actions">${btn('Trocar passaporte', 'data-command="changeId"', 'danger')}${btn('Limpar cadastro e patrimônio', 'data-command="wipe"', 'danger')}</div>`;
    } else if (page === 'players') {
        const players = rowsOf(data, 'players'); state.bootstrap.players = players;
        html = toolbar('Buscar por nome ou passaporte...') + table(['Jogador', 'Passaporte', 'Ping', 'Ações'], players.map(p => row([`${h(p.name)}${p.groups ? `<span class="sub">${h(p.groups.join(', '))}</span>` : ''}`, `#${h(p.id)}`, `${h(p.ping || 0)} ms`, btn('Ver perfil', `data-player="${Number(p.id)}"`)], `${p.name} ${p.id}`)));
    } else if (page === 'identity') {
        html = `<article class="card"><h3>Consultar passaporte</h3><p>Identidade e banco também podem ser administrados com o jogador desconectado.</p><form id="identity-search" class="toolbar"><input class="input" type="number" name="targetId" min="1" placeholder="Passaporte" required><button class="button primary">Consultar</button></form></article><div id="identity-result"></div>`;
    } else if (page === 'groups') {
        html = `<article class="card"><h3>Alterar grupo de jogador online</h3><p>A hierarquia da equipe é validada a cada alteração.</p>${btn('Adicionar ou remover grupo', 'data-command="groups"', 'primary')}</article>${heading('Cargos disponíveis')}${toolbar()}${table(['Cargo', 'Tipo', 'Permissões'], rowsOf(data, 'groups').map(g => row([h(g.name), h(g.config?.gtype || '—'), h((g.permissions || []).join(', '))], `${g.name} ${(g.permissions || []).join(' ')}`)))}`;
    } else if (page === 'items' || page === 'weapons') {
        const entries = rowsOf(data, page === 'weapons' ? 'weapons' : 'items');
        html = heading(page === 'weapons' ? 'Armas e munições' : 'Catálogo de itens', page === 'weapons' ? 'Receba uma arma e sua munição compatível no próprio inventário.' : 'Entregas exigem alvo online e motivo.') + toolbar() + `<div class="cards">${entries.map(item => `<article class="card" data-search="${h(`${item.name} ${item.id}`.toLowerCase())}"><div class="catalog-card">${item.image ? `<img src="${h(item.image)}" alt="" loading="lazy" referrerpolicy="no-referrer">` : ''}<div><h3>${h(item.name || item.id)}</h3><span class="muted small-text">${h(item.id)} · ${h(item.weight || 0)} kg</span></div></div><div class="actions">${page === 'weapons' ? (can('spawn_weapon') ? btn('Receber arma', `data-weapon="${h(item.id)}"`, 'primary') : '') : btn('Entregar', `data-item="${h(item.id)}"`, 'primary')}</div></article>`).join('')}</div>`;
    } else if (page === 'vehicles') {
        html = actionCards(['spawn_veh','give_veh','rem_veh','fix','tuning','hash','dv']) + heading('Catálogo de veículos') + toolbar() + table(['Nome', 'Spawn', 'Ação'], rowsOf(data, 'vehicles').map(v => row([h(v.name || v.id), h(v.id || v.spawn), btn('Spawnar', `data-spawn="${h(v.id || v.spawn)}"`)], `${v.name} ${v.id || v.spawn}`)));
    } else if (page === 'warnings') {
        const list = rowsOf(data, 'warnings', 'entries', 'players');
        html = heading('Advertências', 'A disciplina permanece no histórico após a manutenção de ID.', can('warning') ? btn('Aplicar advertência', 'data-command="warning"', 'primary') : '') + toolbar() + table(['Alvo', 'Motivo', 'Início / término', 'Estado', 'Ação'], list.map(w => row([`#${h(w.user_id || w.targetId || w.id)} ${h(w.name || w.target_name || '')}`, h(w.reason || w.motivo || ''), `${date(w.starts_at || w.createdAt)}<span class="sub">${date(w.ends_at || w.expiresAt)}</span>`, h(w.state || w.status || 'histórico'), can('delete_warning') ? btn('Arquivar', `data-warning-archive="${h(w.id)}"`, 'danger small') : '—'], `${w.user_id || w.targetId} ${w.reason}`)));
    } else if (page === 'map') {
        const players = rowsOf(data, 'players');
        html = `<div class="map">${players.filter(p => p.coords || p.position).map(p => {
            const c = p.coords || p.position; const x = Array.isArray(c) ? c[0] : c.x; const y = Array.isArray(c) ? c[1] : c.y;
            return `<button class="map-marker" data-player="${Number(p.id)}" data-map-x="${Number(x)}" data-map-y="${Number(y)}">#${h(p.id)} ${h(p.name)}</button>`;
        }).join('')}<span class="map-axes">Visualização de coordenadas GTA · clique no jogador para abrir o perfil</span></div>${heading('Jogadores no mapa')}${table(['Jogador', 'Posição', 'Ações'], players.map(p => row([`#${h(p.id)} ${h(p.name)}`, h(JSON.stringify(p.coords || p.position || 'Indisponível')), `${btn('Perfil', `data-player="${Number(p.id)}"`)} ${can('map_screen') ? btn('Ver tela', `data-monitor="${Number(p.id)}"`) : ''}`], `${p.id} ${p.name}`)))}`;
    } else if (page === 'calls') {
        const calls = rowsOf(data, 'calls');
        html = heading('Atendimentos', 'O aceite é exclusivo: somente uma pessoa assume cada chamado.', btn('Novo chamado', 'data-command="call"', 'primary')) + toolbar() + table(['Chamado', 'Solicitante', 'Setor / estado', 'Mensagem', 'Ação'], calls.map(c => row([`#${h(c.id)}`, `#${h(c.requesterId)} ${h(c.requesterName)}`, `${h(c.department)}<span class="sub">${h(c.state)}</span>`, h(c.message), c.canAccept === true ? btn('Atender', `data-call-accept="${h(c.id)}"`, 'primary small') : c.canFinish === true ? btn('Finalizar', `data-call-finish="${h(c.id)}"`, 'small') : c.canRate === true ? btn('Avaliar', `data-call-rate="${h(c.id)}"`, 'small') : '—'], `${c.id} ${c.requesterName} ${c.message} ${c.state}`)));
        html += heading('Ranking da equipe') + table(['Staff', 'Concluídos', 'Média'], rowsOf(data, 'ranking').map(r => row([h(r.name || r.acceptedName || r.staffId || r.id), h(r.total || r.count || r.finished || 0), h(r.average || r.stars || '—')])));
        html += heading('Avaliações') + table(['Chamado', 'Nota', 'Comentário'], rowsOf(data, 'ratings').map(r => row([h(r.callId), `${h(r.stars)} / 5`, h(r.message)])));
    } else if (page === 'vips') {
        html = heading('Pacotes VIP', 'Validade de 30 dias. Um pacote ativo não pode ser entregue novamente.', can('create_vip') ? btn('Criar pacote', 'data-command="vip-new"', 'primary') : '') + toolbar() + `<div class="cards">${rowsOf(data, 'packages', 'vips').map(v => `<article class="card" data-search="${h(`${v.title} ${v.group}`.toLowerCase())}"><h3>☆ ${h(v.title || v.group)}</h3><p>${h(v.group)}<br>${money(v.salary)} de salário · +${Number(v.garageSlots || 0)} vagas<br>${(v.items || []).length} itens · ${Number(v.vehicleChoices || 0)} escolha(s) de veículo</p><div class="actions">${can('assign_vip') ? btn('Entregar', `data-vip-assign="${h(v.group)}"`, 'primary') : ''}${can('edit_vip') ? btn('Editar', `data-vip-edit="${h(v.group)}"`) : ''}${can('delete_vip') ? btn('Excluir', `data-vip-delete="${h(v.group)}"`, 'danger') : ''}</div></article>`).join('')}</div>`;
        html += heading('Entregas e resgates') + table(['Jogador', 'Pacote', 'Estado', 'Expiração'], rowsOf(data, 'assignments').map(v => row([`#${h(v.userId || v.targetId)}`, h(v.group), h(v.state || v.status), date(v.expiresAt)])));
    } else if (page === 'radio') {
        html = heading('Rádios privadas', 'Configurações sincronizadas pelo recurso de rádio.', can('radio_save') ? btn('Nova frequência', 'data-command="radio-new"', 'primary') : '') + toolbar() + table(['Nome', 'Frequência', 'Permissões', 'Estado', 'Ações'], rowsOf(data, 'radios').map(r => row([h(r.name), h(r.channel), h((r.permissions || []).join(', ')), r.enabled ? '<span class="pill green">Ativa</span>' : 'Desativada', `${can('radio_save') ? btn('Editar', `data-radio-edit="${r.id}"`) : ''} ${can('radio_delete') ? btn('Excluir', `data-radio-delete="${r.id}"`, 'danger') : ''}`], `${r.name} ${r.channel}`)));
    } else if (page === 'locations') {
        html = heading('Locais administrativos', 'Coordenadas capturadas dentro do jogo ou informadas manualmente.', can('add_location') ? btn('Novo local', 'data-command="location-new"', 'primary') : '') + toolbar() + table(['Nome', 'Categoria', 'Coordenadas', 'Ações'], rowsOf(data, 'locations').map(l => row([h(l.name), h(l.category), `${Number(l.x).toFixed(2)}, ${Number(l.y).toFixed(2)}, ${Number(l.z).toFixed(2)}`, `${btn('Ir até', `data-location-tp="${h(l.id)}"`)} ${can('add_location') ? btn('Editar', `data-location-edit="${h(l.id)}"`) : ''} ${can('remove_location') ? btn('Excluir', `data-location-delete="${h(l.id)}"`, 'danger') : ''}`], `${l.name} ${l.category}`)));
    } else if (page === 'climate') {
        html = `<div class="metrics">${metric('CLIMA ATUAL', data.weather || 'CLEAR')}${metric('HORÁRIO', `${String(data.hour ?? 12).padStart(2, '0')}:${String(data.minute ?? 0).padStart(2, '0')}`)}${metric('RELÓGIO', data.freezeTime ? 'Congelado' : 'Em andamento')}</div><article class="card"><h3>Clima e horário</h3><p>As alterações afetam todos os jogadores e permanecem após restart.</p>${btn('Configurar ambiente', 'data-command="climate"', 'primary')}</article>`;
    } else if (page === 'logs') {
        const a = data.audit || {};
        html = `<div class="metrics">${metric('RETENÇÃO TÉCNICA', '90 dias')}${metric('REGISTROS', a.total ?? rowsOf(a, 'entries').length)}</div><form id="audit-filter" class="toolbar"><input class="input" name="action" placeholder="Ação"><input class="input" name="actorId" type="number" min="1" placeholder="Staff ID"><input class="input" name="targetId" type="number" min="1" placeholder="Alvo ID"><button class="button">Filtrar</button></form>` + table(['Data', 'Ação', 'Administrador', 'Alvo', 'Detalhes'], rowsOf(a, 'entries').map(e => row([date(e.created_at || e.createdAt), h(e.action), `#${h(e.actor_id || e.actorId || '—')} ${h(e.actor_name || '')}`, `#${h(e.target_id || e.targetId || '—')} ${h(e.target_name || '')}`, btn('Consultar', `data-audit-detail="${h(e.id)}"`)])));
        html += `<div class="actions">${a.page > 1 ? btn('Anterior', `data-audit-page="${a.page - 1}"`) : ''}${Number(a.total) > Number(a.page || 1) * 50 ? btn('Próxima', `data-audit-page="${Number(a.page || 1) + 1}"`) : ''}</div>`;
        html += heading('Notificações no Discord', 'URLs cadastradas na configuração privada do servidor.') + (can('logs_manage') ? btn('Associar categoria a destino', 'data-command="audit-route"') : '') + table(['Destino', 'Configuração'], rowsOf(data.destinations, 'destinations').map(d => row([h(d.label || d.id), d.configured ? '<span class="pill green">Configurado</span>' : 'Não configurado'])));
    }
    $('#content').innerHTML = html || empty('Nenhuma função disponível', 'As permissões desta área podem ter sido revogadas.');
    $$('[data-map-x]').forEach(marker => {
        marker.style.left = `${Math.max(3, Math.min(97, (Number(marker.dataset.mapX) + 4000) / 8500 * 100))}%`;
        marker.style.top = `${Math.max(5, Math.min(95, (8000 - Number(marker.dataset.mapY)) / 12000 * 100))}%`;
    });
}

let previousFocus = null;
function closeModal() {
    state.modalCleanup?.(); state.modalCleanup = null;
    $('#modal-layer').hidden = true; $('#modal-layer').replaceChildren();
    previousFocus?.focus?.(); previousFocus = null;
}

function modal(title, body, options = {}) {
    closeModal(); previousFocus = document.activeElement;
    const layer = $('#modal-layer'); layer.hidden = false;
    layer.innerHTML = `<section class="modal ${options.wide ? 'wide' : ''}" role="dialog" aria-modal="true" aria-labelledby="modal-title"><div class="modal-head"><div><h2 id="modal-title">${h(title)}</h2>${options.description ? `<p>${h(options.description)}</p>` : ''}</div>${btn('✕', 'data-modal-close aria-label="Fechar diálogo"')}</div>${body}</section>`;
    requestAnimationFrame(() => $('input:not([type=hidden]),textarea,select,button', layer)?.focus());
}

function fieldHtml(field, defaults = {}) {
    const value = defaults[field.name] ?? field.value ?? '';
    const attributes = `name="${h(field.name)}" ${field.required ? 'required' : ''} ${field.min != null ? `min="${field.min}"` : ''} ${field.max != null ? `max="${field.max}"` : ''} ${field.maxLength ? `maxlength="${field.maxLength}"` : ''}`;
    let control;
    if (field.type === 'select') control = `<select ${attributes}>${(field.options || []).map(option => { const [v, label] = Array.isArray(option) ? option : [option, option]; return `<option value="${h(v)}" ${String(value) === String(v) ? 'selected' : ''}>${h(label)}</option>`; }).join('')}</select>`;
    else if (field.type === 'textarea' || field.type === 'json') control = `<textarea ${attributes} ${field.type === 'json' ? 'data-json="true"' : ''}>${h(field.type === 'json' && typeof value === 'object' ? JSON.stringify(value, null, 2) : value)}</textarea>`;
    else if (field.type === 'checkbox') control = `<input type="checkbox" ${attributes} ${value ? 'checked' : ''}>`;
    else control = `<input class="input" type="${field.type || 'text'}" ${attributes} value="${h(value)}" step="${field.step || 1}" autocomplete="off">`;
    return `<label class="field ${field.full || ['textarea', 'json'].includes(field.type) ? 'full' : ''}"><span>${h(field.label)}</span>${control}${field.hint ? `<small>${h(field.hint)}</small>` : ''}</label>`;
}

function form(title, method, fields, defaults = {}, options = {}) {
    modal(title, `<form id="operation-form" data-method="${h(method)}"><div class="modal-body">${options.warning ? `<div class="warning">${h(options.warning)}</div>` : ''}<div class="form-grid">${fields.map(f => fieldHtml(f, defaults)).join('')}</div>${options.capture ? `<div class="actions">${btn('Usar minha posição', 'data-capture-position')}</div>` : ''}</div><div class="modal-foot">${btn('Cancelar', 'data-modal-close')}<button class="button ${options.dangerous ? 'danger' : 'primary'}" type="submit">${h(options.submit || 'Confirmar')}</button></div></form>`, options);
    $('#operation-form')._fields = fields;
    $('#operation-form')._defaults = defaults;
}

function showAction(key, defaults = {}) {
    const entry = actionById.get(key); if (!entry || !can(entry.permission)) return;
    form(entry.title, 'action.execute', entry.fields, { targetId: state.selected?.id || '', ...defaults, action: key }, { dangerous: entry.dangerous, warning: entry.dangerous ? 'Confirme o passaporte e o efeito desta ação. O resultado será registrado na auditoria.' : '' });
}

async function showPlayer(id) {
    const p = await call('players.snapshot', { targetId: Number(id) }); state.selected = p;
    const info = p.identity || {};
    modal(`Passaporte #${p.id} · ${p.name || ''}`, `<div class="modal-body"><div class="data-grid">${[['Estado',p.online?'Online':'Offline'],['Nome',`${info.nome || ''} ${info.sobrenome || ''}`],['RG',info.registro],['Telefone',info.telefone],['Idade',info.idade],['Carteira',money(p.wallet)],['Banco',money(p.bank)],['Cargos',(p.groups||[]).join(', ')]].map(([k,v]) => `<div class="datum"><small>${h(k)}</small><strong>${h(v || '—')}</strong></div>`).join('')}</div>${heading('Ações do jogador')}<div class="actions">${actions.filter(a => a.fields.some(f => f.name === 'targetId') && can(a.permission)).map(a => btn(a.title, `data-action="${a.key}" data-target="${p.id}"`, a.dangerous ? 'danger' : '')).join('')}${can('map_screen') && p.online ? btn('Ver tela', `data-monitor="${p.id}"`, 'primary') : ''}${can('warning') ? btn('Advertir', `data-command="warning" data-target="${p.id}"`, 'danger') : ''}${can('give_item') && p.online ? btn('Entregar item', `data-command="item" data-target="${p.id}"`) : ''}${can('givemoney') || can('remove_money') ? btn('Alterar dinheiro', `data-command="money" data-target="${p.id}"`) : ''}${can('edit_identity') ? btn('Editar identidade', `data-command="identity" data-target="${p.id}"`) : ''}</div>${can('inspect_inventory') ? heading('Inventário') + table(['Item', 'Quantidade', 'Slot'], (p.inventory || []).map(item => row([h(item.name || item.item), h(item.amount), h(item.slot || '—')]))) : ''}</div>`, { wide: true });
}

function showIdentityLookup(player) {
    const identity=player.identity||{};
    modal(`Consultar RG · #${player.id}`,`<div class="modal-body"><div class="data-grid">${[['Nome',player.name||`${identity.nome||''} ${identity.sobrenome||''}`],['RG',identity.registro],['Telefone',identity.telefone],['Idade',identity.idade],['Carteira',player.wallet==null?'Indisponível offline':money(player.wallet)],['Banco',player.bank==null?'—':money(player.bank)],['Cargos',(player.groups||[]).join(', ')],['Estado',player.online?'Online':'Offline']].map(([label,value])=>`<div class="datum"><small>${h(label)}</small><strong>${h(value||'—')}</strong></div>`).join('')}</div></div>`,{description:'Consulta de identidade, sem alterar os dados.'});
}

async function showBanHistory() {
    const data=await call('bans.list');
    const now=Math.floor(Date.now()/1000);
    const bans=rowsOf(data,'bans').filter(ban=>!Number(ban.time)||Number(ban.time)>now);
    modal('Histórico de banimentos',`<div class="modal-body">${heading('Banimentos vigentes')}${table(['Passaporte','Motivo','Aplicação','Término'],bans.map(ban=>row([`#${h(ban.user_id)}`,h(ban.motivo),h(ban.banimento||'—'),Number(ban.time)>0?date(Number(ban.time)):'Permanente'])))}${heading('Histórico de bans e desbans')}${table(['Data','Alvo','Administrador','Ação','Motivo'],rowsOf(data,'history').map(entry=>row([date(entry.starts_at),`#${h(entry.user_id)}`,`#${h(entry.actor_id)}`,h(entry.kind==='unban'?'Desbanimento':'Banimento'),h(entry.reason)])))}</div>`,{wide:true});
}

const reason = () => ({ ...reasonField });
async function command(name, element) {
    const target = Number(element?.dataset.target || state.selected?.id) || '';
    if (name === 'lookup') form('Consultar RG','players.lookup',[targetField],{targetId:target},{submit:'Consultar'});
    else if (name === 'ban-history') await showBanHistory();
    else if (name === 'warning') form('Aplicar advertência', 'warnings.apply', [targetField, { name:'minutes',label:'Tempo de castigo (minutos)',type:'number',min:1,max:10080,value:30,required:true },reason()], {targetId:target}, {dangerous:true,warning:'O jogador será colocado em uma dimensão isolada durante o castigo.'});
    else if (name === 'money') form('Alterar saldo', 'economy.change', [targetField,{name:'account',label:'Conta',type:'select',options:[['wallet','Carteira (online)'],['bank','Banco']]},{name:'mode',label:'Operação',type:'select',options:[['give','Adicionar'],['remove','Remover'],['set','Definir saldo']]},amountField,reason()], {targetId:target});
    else if (name === 'item') form('Entregar ou remover item', 'items.change', [targetField,{name:'item',label:'Item',required:true},{name:'mode',label:'Operação',type:'select',options:[['give','Entregar'],['remove','Remover']]},amountField,reason()], {targetId:target || state.bootstrap?.admin?.id || '',item:element?.dataset.item || ''});
    else if (name === 'groups') form('Alterar grupo', 'groups.change', [targetField,{name:'group',label:'Cargo',type:'select',required:true,options:rowsOf(state.data,'groups').map(g=>g.name)},{name:'mode',label:'Operação',type:'select',options:[['add','Adicionar'],['remove','Remover']]},reason()], {targetId:target});
    else if (name === 'identity') form('Editar identidade', 'identity.update', [targetField,{name:'field',label:'Campo',type:'select',options:[['nome','Nome'],['sobrenome','Sobrenome'],['idade','Idade'],['telefone','Telefone'],['registro','RG']]},{name:'value',label:'Novo valor',required:true},reason()],{targetId:target});
    else if (name === 'wipe' || name === 'changeId') form(name === 'wipe' ? 'Limpar cadastro e patrimônio' : 'Trocar passaporte', `maintenance.${name}`, [targetField,...(name==='changeId'?[{name:'newId',label:'Novo passaporte',type:'number',min:1,required:true}]:[]),{name:'confirmId',label:'Digite novamente o passaporte atual',type:'number',min:1,required:true},reason()], {targetId:target}, {dangerous:true,warning:'O alvo deve estar desconectado. A operação exige validação de todos os vínculos; a disciplina e a auditoria são preservadas. A limpeza será recusada se houver ban ativo.'});
    else if (name === 'call') form('Criar chamado', 'calls.create', [{name:'department',label:'Setor',type:'select',options:[['staff','Staff'],['police','Polícia'],['mechanic','Mecânica'],['hospital','Hospital']]},{name:'message',label:'Solicitação',type:'textarea',required:true,maxLength:500}], {}, {submit:'Enviar chamado'});
    else if (name === 'location-new') locationForm();
    else if (name === 'radio-new') radioForm();
    else if (name === 'vip-new') await vipForm();
    else if (name === 'climate') form('Ambiente da cidade','world.update',[{name:'weather',label:'Clima',type:'select',options:state.data.types||['CLEAR','EXTRASUNNY','CLOUDS','OVERCAST','RAIN','THUNDER','FOGGY','SMOG','XMAS']},{name:'hour',label:'Hora',type:'number',min:0,max:23,required:true},{name:'minute',label:'Minuto',type:'number',min:0,max:59,required:true},{name:'freezeTime',label:'Congelar horário',type:'checkbox'},{name:'freezeWeather',label:'Congelar clima',type:'checkbox'},{name:'rotation',label:'Rotação automática de clima',type:'checkbox'}],state.data);
    else if (name === 'needs') {
        const data=await call('needs.get');
        form('Fome e sede','needs.update',[{name:'enabled',label:'Sistema ativo',type:'checkbox'},{name:'hungerPerMinute',label:'Queda de fome por minuto',type:'number',min:0,step:'any'},{name:'thirstPerMinute',label:'Queda de sede por minuto',type:'number',min:0,step:'any'},{name:'hungerDamage',label:'Dano por fome',type:'number',min:0,step:'any'},{name:'thirstDamage',label:'Dano por sede',type:'number',min:0,step:'any'}],{...data.settings,enabled:data.enabled});
    } else if (name === 'audit-route') {
        const data=state.data.destinations || {};
        form('Destino da categoria','audit.update',[{name:'category',label:'Categoria / chave de log',required:true},{name:'destination',label:'Destino privado',type:'select',options:[['','Envio desativado'],...rowsOf(data,'destinations').filter(d=>d.configured).map(d=>[d.id,d.label||d.id])]}]);
    }
}

function locationForm(value={}) {
    form(value.id?'Editar local':'Novo local','locations.save',[{name:'name',label:'Nome',required:true},{name:'category',label:'Categoria',required:true},{name:'x',label:'X',type:'number',step:'any',required:true},{name:'y',label:'Y',type:'number',step:'any',required:true},{name:'z',label:'Z',type:'number',step:'any',required:true}],value,{capture:true});
}
function radioForm(value={}) {
    form(value.id?'Editar rádio':'Nova rádio','radio.save',[{name:'name',label:'Nome',required:true},{name:'channel',label:'Frequência',type:'number',min:1,max:9999,required:true},{name:'permissions',label:'Permissões separadas por vírgula',required:true,full:true},{name:'enabled',label:'Frequência ativa',type:'checkbox'}],{...value,permissions:(value.permissions||[]).join(', '),enabled:value.enabled!==false});
}
async function vipForm(value={}) {
    const catalog=await call('catalog.get');
    form(value.group?'Editar pacote VIP':'Criar pacote VIP','vip.save',[
        {name:'group',label:'Cargo vRP',required:true},
        {name:'title',label:'Nome do pacote',required:true},
        {name:'salary',label:'Salário',type:'number',min:0,value:0,required:true},
        {name:'garageSlots',label:'Vagas adicionais',type:'number',min:0,value:0,required:true},
        {name:'vehicleChoices',label:'Número de escolhas de veículos',type:'number',min:0,value:0,required:true}
    ],{...value,originalGroup:value.group||''},{description:'Prazo de 30 dias. O mesmo VIP ativo não é entregue novamente.'});
    const formElement=$('#operation-form');formElement._catalog=catalog;
    if(value.group)formElement.elements.namedItem('group').readOnly=true;
    $('.modal-body',formElement).insertAdjacentHTML('beforeend',
        `${heading('Itens incluídos','Defina o item e a quantidade.',btn('Adicionar item','data-vip-add-item'))}<div id="vip-items"></div>${heading('Opções de veículos','O jogador escolhe entre os veículos cadastrados.',btn('Adicionar veículo','data-vip-add-vehicle'))}<div id="vip-vehicles"></div>`);
    for(const item of value.items||[])addVipItemRow(item);
    for(const vehicle of value.vehicles||[])addVipVehicleRow(typeof vehicle==='string'?{spawn:vehicle}:vehicle);
}
function addVipItemRow(value={}) {
    const catalog=$('#operation-form')._catalog;
    $('#vip-items').insertAdjacentHTML('beforeend',`<div class="benefit-row" data-vip-item><label class="field"><span>Item</span><select data-item-select required>${rowsOf(catalog,'items').map(item=>`<option value="${h(item.id)}" ${item.id===value.item?'selected':''}>${h(item.name||item.id)} · ${h(item.id)}</option>`).join('')}</select></label><label class="field"><span>Quantidade</span><input class="input" data-item-amount type="number" min="1" max="1000000" value="${Number(value.amount)||1}" required></label>${btn('Remover','data-remove-benefit','danger')}</div>`);
}
function addVipVehicleRow(value={}) {
    const catalog=$('#operation-form')._catalog;
    $('#vip-vehicles').insertAdjacentHTML('beforeend',`<div class="benefit-row vehicle" data-vip-vehicle><label class="field"><span>Veículo</span><select data-vehicle-select required>${rowsOf(catalog,'vehicles').map(vehicle=>`<option value="${h(vehicle.id||vehicle.spawn)}" ${(vehicle.id||vehicle.spawn)===value.spawn?'selected':''}>${h(vehicle.name||vehicle.id||vehicle.spawn)} · ${h(vehicle.id||vehicle.spawn)}</option>`).join('')}</select></label>${btn('Remover','data-remove-benefit','danger')}</div>`);
}

function confirmOperation(title, method, payload, warning) {
    form(title,method,[reason()],payload,{dangerous:true,warning:warning||'A alteração será aplicada imediatamente e registrada na auditoria.'});
}

async function showPermissions() {
    const data = await call('permissions.get');
    const definitions = data.definitions || state.bootstrap.permissions.definitions || [];
    modal('Permissões da equipe', `<div class="modal-body"><p class="small-text muted">Dono e Developer têm acesso permanente. A hierarquia é verificada pelo servidor.</p>${toolbar('Buscar função...')}${table(['Função','Categoria','Acesso'],definitions.map(def=>row([h(def.label||def.key),h(def.category||''),btn('Configurar',`data-permission-edit="${h(def.key)}"`)],`${def.label} ${def.category} ${def.key}`)))}</div>`,{wide:true});
    $('#modal-layer')._permissions=data;
}

async function showPublicCalls() {
    const data=await call('calls.list',{});
    modal('Atendimentos',`<div class="modal-body"><p class="muted small-text">Consulte suas solicitações e os chamados do seu setor.</p>${table(['Chamado','Setor / estado','Mensagem','Ação'],rowsOf(data,'calls').map(c=>row([`#${h(c.id)}`,`${h(c.department)} · ${h(c.state)}`,h(c.message),c.canAccept===true?btn('Atender',`data-call-accept="${h(c.id)}"`):c.canFinish===true?btn('Finalizar',`data-call-finish="${h(c.id)}"`):c.canRate===true?btn('Avaliar',`data-call-rate="${h(c.id)}"`):'—'])))}</div>`,{wide:true});
}

const monitor = createMonitor({ call, post: async (endpoint,payload) => {
    const r=await fetch(`https://${typeof GetParentResourceName==='function'?GetParentResourceName():'ic_admin'}/${endpoint}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(payload)});return r.json();
}, toast });

async function showMonitor(targetId) {
    modal(`Ver tela · #${targetId}`, `<div class="modal-body"><div class="video-screen"><video id="monitor-video" autoplay playsinline muted></video><img id="monitor-relay" alt="Transmissão ao vivo" hidden><span id="monitor-status" class="video-status">Conectando...</span></div><p class="small-text muted">A transmissão não é gravada. Feche este diálogo para encerrar.</p></div>`,{wide:true});
    state.modalCleanup=()=>monitor.stop();
    await monitor.start(Number(targetId));
}

document.addEventListener('click', async event => {
    const button=event.target.closest('button');if(!button)return;
    try {
        if(button.matches('[data-nav]')){closeModal();state.page=button.dataset.nav;state.selected=null;await loadPage();}
        else if(button.matches('[data-modal-close]')){if($('#app').hidden)await closePanel();else closeModal();}
        else if(button.matches('[data-player]'))await showPlayer(button.dataset.player);
        else if(button.matches('[data-action]'))showAction(button.dataset.action,{targetId:Number(button.dataset.target)||state.selected?.id});
        else if(button.matches('[data-command]'))await command(button.dataset.command,button);
        else if(button.matches('[data-item]'))await command('item',button);
        else if(button.matches('[data-weapon]')){
            const weapon=rowsOf(state.data,'weapons').find(item=>item.id===button.dataset.weapon);
            form(`Receber ${weapon?.name||button.dataset.weapon}`,'weapons.give',[
                {name:'ammoAmount',label:'Quantidade de munição',type:'number',min:0,max:10000,value:0,required:true,hint:weapon?.ammo?`Munição compatível: ${weapon.ammo}`:'Sem munição configurada para este modelo. Deixe a quantidade em zero.'},reason()
            ],{weapon:button.dataset.weapon},{description:'A arma e a munição serão entregues ao seu próprio inventário.'});
        }
        else if(button.matches('[data-spawn]'))showAction('spawn_veh',{vehicle:button.dataset.spawn});
        else if(button.matches('[data-monitor]'))await showMonitor(button.dataset.monitor);
        else if(button.matches('[data-capture-position]')){const pos=await call('position.capture');for(const key of ['x','y','z'])$(`[name=${key}]`,$('#operation-form')).value=Number(pos[key]).toFixed(2);}
        else if(button.matches('[data-warning-archive]'))confirmOperation('Arquivar advertência','warnings.archive',{warningId:Number(button.dataset.warningArchive)},'A advertência permanecerá no histórico arquivado.');
        else if(button.matches('[data-call-accept]')){await call('calls.accept',{callId:Number(button.dataset.callAccept)});toast('Chamado assumido.');if($('#app').hidden)await showPublicCalls();else await loadPage();}
        else if(button.matches('[data-call-finish]')){await call('calls.finish',{callId:Number(button.dataset.callFinish)});toast('Chamado finalizado.');if($('#app').hidden)await showPublicCalls();else await loadPage();}
        else if(button.matches('[data-call-rate]'))form('Avaliar atendimento','calls.rate',[{name:'stars',label:'Nota',type:'select',options:[1,2,3,4,5],value:5},{name:'message',label:'Comentário',type:'textarea',maxLength:500}],{callId:Number(button.dataset.callRate)});
        else if(button.matches('[data-vip-edit]'))await vipForm(rowsOf(state.data,'packages','vips').find(v=>v.group===button.dataset.vipEdit));
        else if(button.matches('[data-vip-add-item]'))addVipItemRow();
        else if(button.matches('[data-vip-add-vehicle]'))addVipVehicleRow();
        else if(button.matches('[data-remove-benefit]'))button.closest('.benefit-row').remove();
        else if(button.matches('[data-vip-assign]'))form('Entregar pacote VIP','vip.assign',[targetField,reason()],{group:button.dataset.vipAssign});
        else if(button.matches('[data-vip-delete]'))confirmOperation('Excluir pacote VIP','vip.delete',{group:button.dataset.vipDelete},'O cargo VIP será removido conforme a validação do servidor. Confirme os efeitos antes de excluir.');
        else if(button.matches('[data-radio-edit]'))radioForm(rowsOf(state.data,'radios').find(r=>Number(r.id)===Number(button.dataset.radioEdit)));
        else if(button.matches('[data-radio-delete]'))confirmOperation('Excluir rádio','radio.delete',{id:Number(button.dataset.radioDelete)});
        else if(button.matches('[data-location-edit]'))locationForm(rowsOf(state.data,'locations').find(l=>String(l.id)===button.dataset.locationEdit));
        else if(button.matches('[data-location-delete]'))confirmOperation('Excluir local','locations.delete',{id:button.dataset.locationDelete});
        else if(button.matches('[data-location-tp]')){await call('locations.teleport',{id:button.dataset.locationTp});await closePanel();}
        else if(button.matches('[data-audit-detail]')){const entry=rowsOf(state.data.audit,'entries').find(e=>String(e.id)===button.dataset.auditDetail);modal('Detalhes da auditoria',`<div class="modal-body"><pre class="json-preview">${h(JSON.stringify(entry,null,2))}</pre></div>`,{wide:true});}
        else if(button.matches('[data-audit-page]')){state.data.audit=await call('audit.list',{page:Number(button.dataset.auditPage)});renderPage();}
        else if(button.matches('[data-permission-edit]')){
            const data=$('#modal-layer')._permissions || {};
            const definition=(data.definitions||state.bootstrap.permissions.definitions||[]).find(d=>d.key===button.dataset.permissionEdit)||{};
            const roles=definition.roles||data.rules?.[button.dataset.permissionEdit]||{};
            form(definition.label||button.dataset.permissionEdit,'permissions.update',['admin','moderador','suporte'].map(role=>({name:`role_${role}`,label:role,type:'checkbox',value:roles[role]===true})),{key:button.dataset.permissionEdit});
        } else if(button.matches('[data-vip-choose]')){button.disabled=true;await call('vip.choose',{assignmentId:button.dataset.assignment,vehicle:button.dataset.vipChoose});toast('Veículo resgatado.');$('#vip-choice').hidden=true;await closePanel();}
        else if(button.matches('[data-vip-test]')){button.disabled=true;await call('vip.test',{assignmentId:button.dataset.assignment,vehicle:button.dataset.vipTest,mode:'start'});$('#vip-choice').hidden=true;}
    }catch(error){toast(error.message,true);button.disabled=false;}
});

function valuesOf(formElement) {
    const result={...formElement._defaults};
    for(const field of formElement._fields||[]){
        const el=formElement.elements.namedItem(field.name);let value;
        if(field.type==='checkbox')value=el.checked;
        else if(field.type==='number')value=el.value===''?undefined:Number(el.value);
        else if(field.type==='json'){try{value=JSON.parse(el.value||'[]');}catch{throw new Error(`JSON inválido em ${field.label}.`);}}
        else value=el.value.trim();
        result[field.name]=value;
    }
    if(formElement.dataset.method==='vip.save'){
        result.items=$$('[data-vip-item]',formElement).map(row=>({item:$('[data-item-select]',row).value,amount:Number($('[data-item-amount]',row).value)}));
        result.vehicles=$$('[data-vip-vehicle]',formElement).map(row=>{const spawn=$('[data-vehicle-select]',row).value;const vehicle=rowsOf(formElement._catalog,'vehicles').find(entry=>(entry.id||entry.spawn)===spawn);return {spawn,name:vehicle?.name||spawn};});
    }
    if(result.permissions && typeof result.permissions==='string')result.permissions=result.permissions.split(/[,;\n]/).map(x=>x.trim()).filter(Boolean);
    if(formElement.dataset.method==='permissions.update'){
        result.roles={};for(const role of ['admin','moderador','suporte']){result.roles[role]=result[`role_${role}`];delete result[`role_${role}`];}
    }
    return result;
}

document.addEventListener('submit',async event=>{
    event.preventDefault();const formElement=event.target;
    if(formElement.id==='operation-form'){
        const submit=$('button[type=submit]',formElement);submit.disabled=true;
        try{
            const method=formElement.dataset.method;const data=valuesOf(formElement);
            if(method==='action.execute'&&data.action==='tpcds')data.coords={x:data.x,y:data.y,z:data.z};
            const result=await call(method,data);
            if(method==='players.lookup'){showIdentityLookup(result);return;}
            closeModal();toast('Operação concluída.');
            if(method==='permissions.update'){state.bootstrap.permissions=await call('permissions.get');await showPermissions();}
            else if(!$('#app').hidden)await loadPage();
            else if(method==='calls.create'){await closePanel();}
        }catch(error){toast(error.message,true);if(submit.isConnected)submit.disabled=false;}
    }else if(formElement.id==='identity-search'){
        try{
            const p=await call('identity.get',{targetId:Number(new FormData(formElement).get('targetId'))});state.selected=p;
            $('#identity-result').innerHTML=heading(`Passaporte #${p.id}`,p.name||'')+`<div class="data-grid">${Object.entries(p.identity||{}).map(([key,value])=>`<div class="datum"><small>${h(key)}</small><strong>${h(value)}</strong></div>`).join('')}<div class="datum"><small>Banco</small><strong>${money(p.bank)}</strong></div></div><div class="actions">${btn('Editar identidade','data-command="identity"','primary')}${btn('Alterar saldo','data-command="money"')}</div>`;
        }catch(error){toast(error.message,true);}
    }else if(formElement.id==='audit-filter'){
        try{const query=Object.fromEntries(new FormData(formElement));for(const key of ['actorId','targetId'])if(query[key])query[key]=Number(query[key]);state.data.audit=await call('audit.list',{...query,page:1});renderPage();}catch(error){toast(error.message,true);}
    }
});

document.addEventListener('input',event=>{
    if(event.target.id!=='page-search')return;
    const root=event.target.closest('.modal')||$('#content');const term=event.target.value.toLocaleLowerCase().trim();
    $$('[data-search]',root).forEach(el=>{el.hidden=term&&!el.dataset.search.includes(term);});
});
document.addEventListener('keydown',event=>{
    if(event.key==='Escape'){
        if(!$('#modal-layer').hidden&&!$('#app').hidden)closeModal();else closePanel();
    }else if(event.key==='Tab'&&!$('#modal-layer').hidden){
        const list=$$('button:not([disabled]),input:not([disabled]),select:not([disabled]),textarea:not([disabled]),[tabindex="0"]',$('#modal-layer'));
        if(!list.length)return;
        if(event.shiftKey&&document.activeElement===list[0]){event.preventDefault();list.at(-1).focus();}
        else if(!event.shiftKey&&document.activeElement===list.at(-1)){event.preventDefault();list[0].focus();}
    }
});
async function closePanel(){closeModal();$('#app').hidden=true;$('#vip-choice').hidden=true;await call('ui.close').catch(()=>{});}
$('#close').onclick=closePanel;$('#refresh').onclick=loadPage;$('#permissions').onclick=()=>showPermissions().catch(e=>toast(e.message,true));
$('#public-call-dismiss').onclick=()=>{$('#public-call').hidden=true;};
let currentCall=null;
$('#public-call-accept').onclick=async()=>{try{await call('calls.accept',{callId:currentCall?.id||currentCall?.callId});toast('Chamado assumido.');$('#public-call').hidden=true;}catch(e){toast(e.message,true);}};
let noticeTimer,punishmentTimer;
window.addEventListener('message',async event=>{
    const message=event.data||{},data=message.payload||{};
    if(message.type==='open'){
        state.bootstrap=data;state.selected=null;
        state.page=visibleNav()[0]?.[0]||'server';$('#app').hidden=false;
        if(!visibleNav().length){updateShell();$('#content').innerHTML=empty('Sem funções liberadas','Solicite ao Dono ou Developer a configuração do seu cargo.');return;}
        await loadPage();
    }else if(message.type==='close'){closeModal();monitor.stop();$('#app').hidden=true;$('#vip-choice').hidden=true;}
    else if(message.type==='publicCallsList'){
        try{await showPublicCalls();}catch(error){toast(error.message,true);}
    }else if(message.type==='publicCalls'){
        command('call');
    }else if(message.type==='notice'){
        clearTimeout(noticeTimer);$('#notice-layer').hidden=false;$('#notice-kind').textContent=data.kind||'ADMINISTRAÇÃO · INTERIOR CITY';$('#notice-message').textContent=data.message||data.text||'';
        noticeTimer=setTimeout(()=>{$('#notice-layer').hidden=true;},Math.min(300,Number(data.seconds||data.durationSeconds||data.duration)||8)*1000);
    }else if(message.type==='callNotice'){
        currentCall=data.call||data;$('#public-call').hidden=false;$('#public-call-title').textContent=`Chamado ${currentCall.department||''} · #${currentCall.id||currentCall.callId||''}`;$('#public-call-message').textContent=`${currentCall.message||''} · ${currentCall.state||'open'} · /icchamados para consultar`;$('#public-call-accept').hidden=currentCall.canAccept!==true;
    }else if(message.type==='vipChoice'){
        const layer=$('#vip-choice');layer.hidden=false;
        layer.innerHTML=`<h2>Seus benefícios VIP</h2><p class="muted">Escolha seu veículo. Cada resgate é registrado uma única vez.</p><div class="cards">${(data.vehicles||[]).map(vehicle=>{const spawn=typeof vehicle==='string'?vehicle:vehicle.spawn;return `<article class="card"><h3>${h(vehicle.name||spawn)}</h3><div class="actions">${btn('Escolher',`data-vip-choose="${h(spawn)}" data-assignment="${h(data.assignmentId)}"`,'primary')}${btn('Testar',`data-vip-test="${h(spawn)}" data-assignment="${h(data.assignmentId)}"`)}</div></article>`;}).join('')}</div>${btn('Fechar','id="vip-choice-close"')}`;
        $('#vip-choice-close').onclick=closePanel;
    }else if(message.type==='punishment'){
        clearInterval(punishmentTimer);const until=Number(data.endsAt||data.ends_at||0)*1000;$('#punishment').hidden=until<=Date.now();
        const tick=()=>{const seconds=Math.max(0,Math.ceil((until-Date.now())/1000));$('#punishment-clock').textContent=`${Math.floor(seconds/60)}:${String(seconds%60).padStart(2,'0')}`;if(!seconds){$('#punishment').hidden=true;clearInterval(punishmentTimer);}};tick();punishmentTimer=setInterval(tick,1000);
    }else if(message.type==='monitorMessage')monitor.message(data);
    else if(message.type==='environment'&&state.page==='climate'&&!$('#app').hidden){state.data=data;renderPage();}
});
setInterval(()=>{if(!$('#app').hidden&&state.page==='map'&&$('#modal-layer').hidden)loadPage();},5000);
