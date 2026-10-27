const $ = (selector, root = document) => root.querySelector(selector);
const $$ = (selector, root = document) => Array.from(root.querySelectorAll(selector));


// ============================================================================
// TRANSPORTE NUI ABERTO / COMPATIVEL COM OFUSCACAO
// O fetch CEF recebe imediatamente um requestId do bridge_client.js e esta
// camada aguarda a resposta real sem depender de coroutine Lua ofuscada.
// ============================================================================
const MG_UI_BUILD = "2.90.5-final-obfsafe";
const mgBridgeWaiters = new Map();
const mgBridgeBacklog = new Map();
let mgBridgeLastTransportToastAt = 0;

function resolveMgBridgeResponse(requestId, payload) {
    const id = String(requestId || "");
    if (!id) return;

    const waiter = mgBridgeWaiters.get(id);
    if (waiter) {
        mgBridgeWaiters.delete(id);
        clearTimeout(waiter.timer);
        waiter.resolve(payload || { ok: false, message: "Resposta vazia do servidor." });
        return;
    }

    mgBridgeBacklog.set(id, payload || { ok: false, message: "Resposta vazia do servidor." });
    if (mgBridgeBacklog.size > 150) {
        const firstKey = mgBridgeBacklog.keys().next().value;
        if (firstKey) mgBridgeBacklog.delete(firstKey);
    }
}

function waitMgBridgeResponse(requestId, timeout = 20000) {
    const id = String(requestId || "");
    if (!id) return Promise.resolve({ ok: false, message: "ID de comunicacao invalido." });

    if (mgBridgeBacklog.has(id)) {
        const payload = mgBridgeBacklog.get(id);
        mgBridgeBacklog.delete(id);
        return Promise.resolve(payload);
    }

    return new Promise(resolve => {
        const timer = setTimeout(() => {
            mgBridgeWaiters.delete(id);
            resolve({ ok: false, message: "O servidor nao respondeu a solicitacao do painel." });
        }, timeout);
        mgBridgeWaiters.set(id, { resolve, timer });
    });
}

const resourceName = typeof GetParentResourceName === "function"
    ? GetParentResourceName()
    : "m_paineladm_v2";

const adminScreenAlert = $("#adminScreenAlert");
const adminScreenAlertKind = $("#adminScreenAlertKind");
const adminScreenAlertText = $("#adminScreenAlertText");
const adminScreenAlertTime = $("#adminScreenAlertTime");
let adminScreenAlertTimer = null;
let adminScreenAlertEndsAt = 0;

const punishmentScreenAlert = $("#punishmentScreenAlert");
const punishmentScreenAlertTime = $("#punishmentScreenAlertTime");
let punishmentScreenAlertTimer = null;
let punishmentScreenAlertEndsAt = 0;

function stopPunishmentScreenAlert() {
    if (punishmentScreenAlertTimer) {
        clearInterval(punishmentScreenAlertTimer);
        punishmentScreenAlertTimer = null;
    }
    punishmentScreenAlertEndsAt = 0;
    punishmentScreenAlert?.classList.remove("is-visible");
    punishmentScreenAlert?.setAttribute("aria-hidden", "true");
}

function showPunishmentScreenAlert(seconds) {
    stopPunishmentScreenAlert();

    const duration = Math.max(1, Math.min(604800, Number(seconds) || 60));
    punishmentScreenAlertEndsAt = Date.now() + (duration * 1000);
    if (punishmentScreenAlertTime) punishmentScreenAlertTime.textContent = formatAdminAlertTime(duration);

    punishmentScreenAlert?.classList.add("is-visible");
    punishmentScreenAlert?.setAttribute("aria-hidden", "false");

    punishmentScreenAlertTimer = setInterval(() => {
        const remaining = (punishmentScreenAlertEndsAt - Date.now()) / 1000;
        if (punishmentScreenAlertTime) punishmentScreenAlertTime.textContent = formatAdminAlertTime(remaining);
        if (remaining <= 0) stopPunishmentScreenAlert();
    }, 100);
}

function formatAdminAlertTime(totalSeconds) {
    const seconds = Math.max(0, Math.ceil(Number(totalSeconds) || 0));
    const minutes = Math.floor(seconds / 60);
    const remain = seconds % 60;
    return `${String(minutes).padStart(2, "0")}:${String(remain).padStart(2, "0")}`;
}

function stopAdminScreenAlert() {
    if (adminScreenAlertTimer) {
        clearInterval(adminScreenAlertTimer);
        adminScreenAlertTimer = null;
    }
    adminScreenAlertEndsAt = 0;
    adminScreenAlert?.classList.remove("is-visible");
    adminScreenAlert?.setAttribute("aria-hidden", "true");
}

function showAdminScreenAlert(message, seconds, scope = "general") {
    stopAdminScreenAlert();

    const duration = Math.max(1, Math.min(300, Number(seconds) || 8));
    adminScreenAlertEndsAt = Date.now() + (duration * 1000);

    if (adminScreenAlertKind) {
        adminScreenAlertKind.textContent = scope === "private"
            ? "MENSAGEM PRIVADA DA ADMINISTRAÇÃO"
            : "MENSAGEM GERAL DA ADMINISTRAÇÃO";
    }
    if (adminScreenAlertText) {
        const alertMessage = String(message || "Aviso administrativo");
        adminScreenAlertText.textContent = alertMessage;
        adminScreenAlertText.classList.toggle("is-long-text", alertMessage.length > 180 && alertMessage.length <= 420);
        adminScreenAlertText.classList.toggle("is-very-long-text", alertMessage.length > 420);
    }
    if (adminScreenAlertTime) adminScreenAlertTime.textContent = formatAdminAlertTime(duration);

    adminScreenAlert?.classList.add("is-visible");
    adminScreenAlert?.setAttribute("aria-hidden", "false");

    adminScreenAlertTimer = setInterval(() => {
        const remaining = (adminScreenAlertEndsAt - Date.now()) / 1000;
        if (adminScreenAlertTime) adminScreenAlertTime.textContent = formatAdminAlertTime(remaining);
        if (remaining <= 0) stopAdminScreenAlert();
    }, 100);
}

const iconPaths = {
    users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
    shield: '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>',
    package: '<path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><path d="m3.3 7 8.7 5 8.7-5M12 22V12"/>',
    car: '<path d="M5 17H3v-5l2-5h14l2 5v5h-2"/><path d="M5 17v2h3v-2h8v2h3v-2"/><path d="M5 12h14"/><circle cx="7.5" cy="14.5" r="1"/><circle cx="16.5" cy="14.5" r="1"/>',
    map: '<polygon points="3 6 9 3 15 6 21 3 21 18 15 21 9 18 3 21 3 6"/><path d="M9 3v15M15 6v15"/>',
    cloud: '<path d="M17.5 19H7a5 5 0 0 1-.7-9.95A7 7 0 0 1 19.7 11 4 4 0 0 1 17.5 19z"/><path d="M12 3v2M4.2 6.2l1.4 1.4M19.8 6.2l-1.4 1.4"/>',
    server: '<rect x="3" y="4" width="18" height="6" rx="2"/><rect x="3" y="14" width="18" height="6" rx="2"/><path d="M7 7h.01M7 17h.01"/>',
    refresh: '<path d="M20 11a8.1 8.1 0 0 0-15.5-2M4 4v5h5"/><path d="M4 13a8.1 8.1 0 0 0 15.5 2M20 20v-5h-5"/>',
    close: '<path d="M18 6 6 18M6 6l12 12"/>',
    search: '<circle cx="11" cy="11" r="7"/><path d="m20 20-4-4"/>',
    heart: '<path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.6l-1-1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8z"/>',
    activity: '<path d="M3 12h4l2-5 4 10 2-5h6"/>',
    sliders: '<path d="M4 21v-7M4 10V3M12 21v-9M12 8V3M20 21v-5M20 12V3"/><path d="M1 14h6M9 8h6M17 16h6"/>',
    bolt: '<path d="m13 2-9 12h8l-1 8 9-12h-8l1-8z"/>',
    clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    arrow: '<path d="m9 18 6-6-6-6"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    minus: '<path d="M5 12h14"/>',
    userplus: '<path d="M15 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8" cy="7" r="4"/><path d="M19 8v6M16 11h6"/>',
    userminus: '<path d="M15 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8" cy="7" r="4"/><path d="M16 11h6"/>',
    ban: '<circle cx="12" cy="12" r="9"/><path d="m5.6 5.6 12.8 12.8"/>',
    skull: '<circle cx="12" cy="10" r="7"/><path d="M8 17v3M12 17v3M16 17v3"/>',
    snow: '<path d="M12 2v20M4.9 6l14.2 12M19.1 6 4.9 18M5 12h14"/>',
    message: '<path d="M21 15a4 4 0 0 1-4 4H8l-5 3V7a4 4 0 0 1 4-4h10a4 4 0 0 1 4 4z"/>',
    id: '<rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="8" cy="11" r="2"/><path d="M6 16c.8-1.4 3.2-1.4 4 0M13 9h5M13 13h5"/>',
    wallet: '<path d="M4 5h14a2 2 0 0 1 2 2v12H4a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2z"/><path d="M16 11h6v5h-6a2.5 2.5 0 0 1 0-5z"/>',
    trash: '<path d="M3 6h18M8 6V4h8v2M6 6l1 15h10l1-15M10 10v7M14 10v7"/>',
    wrench: '<path d="M14.7 6.3a4 4 0 0 0-5-5l2.1 2.1-2.8 2.8-2.1-2.1a4 4 0 0 0 5 5L20 17l-3 3-7.8-7.8a4 4 0 0 0 5.5-5.9z"/>',
    sparkles: '<path d="m12 3-1.2 3.8L7 8l3.8 1.2L12 13l1.2-3.8L17 8l-3.8-1.2L12 3zM5 14l-.8 2.2L2 17l2.2.8L5 20l.8-2.2L8 17l-2.2-.8L5 14zM19 13l-.7 1.8-1.8.7 1.8.7L19 18l.7-1.8 1.8-.7-1.8-.7L19 13z"/>',
    pin: '<path d="M20 10c0 5-8 12-8 12S4 15 4 10a8 8 0 1 1 16 0z"/><circle cx="12" cy="10" r="2.5"/>',
    target: '<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3"/>',
    copy: '<rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>',
    alert: '<path d="M10.3 3.7 2.4 18a2 2 0 0 0 1.8 3h15.6a2 2 0 0 0 1.8-3L13.7 3.7a2 2 0 0 0-3.4 0z"/><path d="M12 9v4M12 17h.01"/>',
    check: '<path d="m5 12 4 4L19 6"/>',
    logout: '<path d="M10 17l5-5-5-5M15 12H3M14 3h5a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-5"/>',
    monitor: '<rect x="3" y="4" width="18" height="13" rx="2"/><path d="M8 21h8M12 17v4"/>',
    eye: '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
    maximize: '<path d="M8 3H3v5M16 3h5v5M8 21H3v-5M16 21h5v-5"/>',
    minimize: '<path d="M9 9H4V4M15 9h5V4M9 15H4v5M15 15h5v5"/>',
    star: '<path d="m12 2.8 2.8 5.7 6.3.9-4.6 4.5 1.1 6.3-5.6-3-5.6 3 1.1-6.3L2.9 9.4l6.3-.9L12 2.8z"/>',
    trophy: '<path d="M8 21h8M12 17v4M7 4h10v5a5 5 0 0 1-10 0V4z"/><path d="M7 6H4v2a4 4 0 0 0 4 4M17 6h3v2a4 4 0 0 1-4 4"/>',
    headset: '<path d="M4 13v-2a8 8 0 0 1 16 0v2"/><path d="M4 13h3v6H5a1 1 0 0 1-1-1v-5zM20 13h-3v6h2a1 1 0 0 0 1-1v-5z"/><path d="M17 19c0 2-2 2-5 2"/>',
    archive: '<path d="M4 7h16v13H4zM3 3h18v4H3zM9 11h6"/>',
    radio: '<path d="M5 15v4M9 12v7M13 9v10M17 6v13M21 3v16"/><path d="M3 19h20"/>',
    weapon: '<path d="M3 10h11l4-3 3 3-4 4h-4l-1 6H8l1-6H3z"/><path d="M6 10V7h8"/>',
    edit: '<path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L8 18l-4 1 1-4Z"/>'
};

function icon(name, size = 18) {
    const paths = iconPaths[name] || iconPaths.activity;
    return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${paths}</svg>`;
}

const NAV = [
    { id: "server", permission: "view_server", label: "Servidor", icon: "server", eyebrow: "ADMINISTRAÇÃO", title: "Servidor", description: "Central de ações administrativas gerais do servidor." },
    { id: "players", permission: "view_players", label: "Jogadores", icon: "users", eyebrow: "GERENCIAMENTO", title: "Jogadores online", description: "Encontre jogadores, consulte dados e execute ações rápidas." },
    { id: "warnings", permission: "view_warnings", label: "Advertências", icon: "alert", eyebrow: "DISCIPLINA", title: "Advertências", description: "Consulte o histórico de advertências aplicadas aos jogadores." },
    { id: "map", permission: "view_map", label: "Mapa", icon: "map", eyebrow: "MONITORAMENTO", title: "Mapa ao vivo", description: "Acompanhe a posição dos jogadores e execute ações em tempo real." },
    { id: "calls", permission: "view_calls", label: "Chamados", icon: "headset", eyebrow: "ATENDIMENTO", title: "Chamados", description: "Atenda solicitações da Staff e acompanhe histórico, ranking e avaliações." },
    { id: "groups", permission: "view_groups", label: "Setagem", icon: "shield", eyebrow: "PERMISSÕES", title: "Setagem", description: "Gerencie cargos e grupos com proteção de hierarquia integrada." },
    { id: "identity", permission: "view_identity_editor", label: "Alterar RG", icon: "id", eyebrow: "IDENTIDADE", title: "Alterar RG", description: "Consulte e altere os dados de identidade de qualquer passaporte." },
    { id: "items", permission: "view_items", label: "Itens", icon: "package", eyebrow: "INVENTÁRIO", title: "Itens", description: "Spawne rapidamente qualquer item do servidor para o seu próprio inventário." },
    { id: "weapons", permission: "view_weapons", label: "Armas", icon: "weapon", eyebrow: "ARSENAL", title: "Armas", description: "Receba armas e a munição correspondente diretamente no inventário." },
    { id: "vips", permission: "view_vips", label: "VIPs", icon: "star", eyebrow: "BENEFÍCIOS", title: "VIPs", description: "Crie pacotes VIP, configure benefícios e entregue cargos temporários de 30 dias." },
    { id: "vehicles", permission: "view_vehicles", label: "Veículos", icon: "car", eyebrow: "GARAGEM", title: "Veículos", description: "Spawne, entregue, remova, repare e gerencie veículos." },
    { id: "radio", permission: "view_radio", label: "Rádio", icon: "radio", eyebrow: "COMUNICAÇÃO", title: "Rádios privadas", description: "Gerencie frequências privadas e as permissões de acesso em tempo real." },
    { id: "locations", permission: "view_locations", label: "Locais", icon: "pin", eyebrow: "MUNDO", title: "Locais", description: "Cadastre e acesse os locais administrativos do servidor." },
    { id: "climate", permission: "view_climate", label: "Clima", icon: "cloud", eyebrow: "AMBIENTE", title: "Clima", description: "Controle o clima e o horário global do servidor." },
    { id: "logs", permission: "view_logs", label: "Logs", icon: "archive", eyebrow: "AUDITORIA", title: "Logs", description: "Cadastre as webhooks de cada ação do servidor em um único lugar." }
];

const F = {
    target: { name: "targetId", label: "Passaporte / ID", type: "number", placeholder: "Ex.: 15" },
    reason: { name: "reason", label: "Motivo", type: "textarea", placeholder: "Descreva o motivo...", required: true },
    message: { name: "message", label: "Mensagem", type: "textarea", placeholder: "Digite a mensagem..." },
    duration: { name: "durationSeconds", label: "Duração na tela (segundos)", type: "number", placeholder: "Ex.: 8", min: 1, max: 300, defaultValue: 8 },
    minutes: { name: "minutes", label: "Tempo de castigo (minutos)", type: "number", placeholder: "Ex.: 30", min: 1, max: 10080, defaultValue: 30 },
    amount: { name: "amount", label: "Quantidade", type: "number", placeholder: "Ex.: 1000" },
    account: { name: "account", label: "Destino", type: "select", options: [["wallet", "Carteira"], ["bank", "Banco"]] },
    vehicle: { name: "vehicle", label: "Spawn do veículo", type: "text", placeholder: "Ex.: sultan" },
    item: { name: "item", label: "Spawn do item", type: "text", placeholder: "Ex.: radio" },
    coords: { name: "coords", label: "Coordenada (X,Y,Z)", type: "text", placeholder: "Ex.: 46.63,-899.06,29.98", full: true }
};

const ACTIONS = {
    wladd: { title: "Liberar whitelist", description: "Libera o acesso do passaporte informado.", icon: "check", fields: [F.target] },
    wlrem: { title: "Remover whitelist", description: "Remove o acesso do passaporte informado.", icon: "ban", fields: [F.target], danger: true },
    god: { title: "Reviver jogador", description: "Restaura a vida do jogador selecionado.", icon: "heart", fields: [F.target] },
    godall: { title: "Reviver todos", description: "Restaura a vida de todos os jogadores online.", icon: "heart", fields: [] },
    kill: { title: "Matar jogador", description: "Define a vida do jogador como zero.", icon: "skull", fields: [F.target], danger: true },
    ban: { title: "Banir jogador", description: "Registra o banimento na estrutura de bans da sua vRP.", icon: "ban", fields: [F.target, F.reason], danger: true },
    unban: { title: "Desbanir jogador", description: "Remove o banimento do passaporte informado. O motivo do desbanimento é obrigatório.", icon: "check", fields: [F.target, F.reason] },
    kick: { title: "Expulsar jogador", description: "Desconecta o jogador do servidor com um motivo.", icon: "logout", fields: [F.target, F.reason], danger: true },
    freeze: { title: "Congelar jogador", description: "Bloqueia a movimentação do personagem.", icon: "snow", fields: [F.target] },
    unfreeze: { title: "Descongelar jogador", description: "Libera novamente a movimentação.", icon: "activity", fields: [F.target] },
    send_dm: { title: "Mensagem privada", description: "Exibe um aviso administrativo diretamente na tela do jogador.", icon: "message", fields: [F.target, F.message, F.duration] },
    send_adm: { title: "Aviso geral", description: "Exibe um aviso administrativo na tela de todos os jogadores.", icon: "message", fields: [F.message, F.duration] },
    warning: { title: "Advertência", description: "Envia o jogador para o castigo em uma dimensão isolada pelo tempo definido e registra o motivo.", icon: "alert", fields: [F.target, F.minutes, F.reason], danger: true },
    needs_manage: { title: "Fome e sede", description: "Liga ou desliga globalmente a fome e sede, as barras da HUD e o uso de alimentos/bebidas.", icon: "activity", fields: [] },
    wipe_user_data: { title: "Limpar Dados ID", description: "Apaga permanentemente todos os dados vinculados ao ID no banco e deixa o Passaporte livre para ser usado por outra pessoa.", icon: "trash", fields: [F.target], danger: true, critical: true },
    catch_rg: { title: "Consultar RG", description: "Exibe identidade, dinheiro, multas e cargos do passaporte.", icon: "id", fields: [F.target] },
    givemoney: { title: "Adicionar dinheiro", description: "Adiciona dinheiro na carteira ou no banco.", icon: "wallet", fields: [F.target, F.amount, F.account] },
    remove_money: { title: "Remover dinheiro", description: "Retira dinheiro da carteira ou do banco.", icon: "wallet", fields: [F.target, F.amount, F.account], danger: true },
    give_item: { title: "Adicionar item", description: "Entrega um item para um jogador online.", icon: "package", fields: [F.target, F.item, F.amount] },
    map_screen: { title: "Ver tela", description: "Acompanha o jogo do jogador em vídeo P2P em tempo real.", icon: "monitor", fields: [F.target] },
    spawn_self_item: { title: "Spawnar item", description: "Adiciona o item diretamente ao seu próprio inventário.", icon: "package", fields: [] },
    spawn_weapon: { title: "Puxar arma", description: "Adiciona a arma e a munição correspondente ao seu inventário.", icon: "weapon", fields: [] },
    remove_item: { title: "Remover item", description: "Retira uma quantidade do inventário do jogador.", icon: "package", fields: [F.target, F.item, F.amount], danger: true },
    clear_inv: { title: "Limpar inventário", description: "Remove todos os itens do inventário do jogador.", icon: "trash", fields: [F.target], danger: true },
    clear_weapons: { title: "Limpar armas", description: "Remove todas as armas salvas e equipadas.", icon: "trash", fields: [F.target], danger: true },
    give_veh: { title: "Adicionar veículo", description: "Adiciona um veículo diretamente na garagem do passaporte.", icon: "car", fields: [F.target, F.vehicle] },
    rem_veh: { title: "Remover veículo", description: "Remove um spawn específico da garagem do passaporte.", icon: "trash", fields: [F.target, F.vehicle], danger: true },
    spawn_veh: { title: "Spawnar veículo", description: "Cria um veículo administrativo próximo de você.", icon: "car", fields: [F.vehicle] },
    fix: { title: "Reparar veículo", description: "Repara o veículo atual ou o mais próximo.", icon: "wrench", fields: [] },
    tuning: { title: "Tunar veículo", description: "Aplica modificações máximas no veículo atual.", icon: "sparkles", fields: [] },
    tptome: { title: "Puxar jogador", description: "Teleporta o jogador selecionado até você.", icon: "target", fields: [F.target] },
    tpto: { title: "Ir até jogador", description: "Teleporta você até o jogador selecionado.", icon: "pin", fields: [F.target] },
    tpway: { title: "Ir ao waypoint", description: "Teleporta você para a marcação atual do mapa.", icon: "map", fields: [] },
    tpcds: { title: "Teleportar por coordenadas", description: "Cole a coordenada completa no formato X,Y,Z. Ex.: 46.63,-899.06,29.98", icon: "target", fields: [F.coords] },
    hash: { title: "Hash do veículo", description: "Exibe nome e hash do veículo atual ou mais próximo.", icon: "id", fields: [] },
    dv: { title: "Deletar veículo", description: "Remove o veículo atual ou o mais próximo.", icon: "trash", fields: [], danger: true },
    clear_allveh: { title: "Limpar veículos", description: "Inicia a limpeza global de veículos vazios após o aviso configurado.", icon: "trash", fields: [], danger: true },
    clear_props: { title: "Limpar props", description: "Remove objetos dentro do raio configurado ao redor da staff.", icon: "trash", fields: [], danger: true }
};

let liveMapTimer = null;
let liveMapSelectedId = null;
let liveMapTransform = { scale: 1, x: 0, y: 0 };
let liveMapFullscreen = false;
let liveMapDrag = null;
let liveMapInteractionCleanup = null;
let liveMapHdLoader = null;
let liveScreenSession = null;
let liveScreenPublisher = null;
let liveScreenRelayPublisher = null;
let liveScreenSignalQueue = Promise.resolve();

const state = {
    open: false,
    page: "server",
    bootstrap: null,
    config: { brand: {}, images: {}, locations: [], locationCategories: [], vehicles: [], weather: {}, cleanupDelay: 60 },
    environment: null,
    permissions: null,
    selectedPlayerId: null,
    snapshot: null,
    identityEditor: null,
    playerView: "profile",
    history: [],
    callsData: null,
    callsView: "open",
    warningsData: null,
    locationCategory: null,
    vehicleCategory: "game",
    weaponCategory: "Todas",
    radioAdmin: null,
    vipAdmin: null,
    logsAdmin: null,
    logsCategoryId: null,
    logsSubcategoryId: null
};

let vipEditorDraft = null;
let playerVipChoice = null;
let playerVipActionBusy = false;

const app = $("#app");
const content = $("#content");
const modalRoot = $("#modalRoot");
const toastRoot = $("#toastRoot");
const vipChoiceRoot = $("#vipChoiceRoot");
const vipTestOverlay = $("#vipTestOverlay");
let vipTestOverlaySession = 0;
let vipTestOverlayClosedSession = 0;


// Horário: o slider precisa responder em tempo real sem recriar a página
// a cada pixel arrastado. O envio ao servidor é limitado e o valor final
// sempre é confirmado ao soltar a barra.
let environmentTimeSendTimer = null;
let environmentTimePendingValue = null;
let environmentTimeRequestSerial = 0;

// ---------------------------------------------------------------------------
// Catálogos grandes: imagens sob demanda + filtros agrupados por frame.
// Isso evita decodificar centenas de PNGs e recalcular o layout inteiro
// enquanto a staff apenas percorre a lista.
// ---------------------------------------------------------------------------
let lazyImageObserver = null;
const filterTimers = new WeakMap();

function loadCatalogImage(img) {
    if (!img || img.dataset.loaded === "1") return;

    const src = img.dataset.src;
    if (!src) return;

    img.dataset.loaded = "1";
    img.removeAttribute("data-src");

    img.onerror = () => {
        const remote = img.dataset.remoteFallback;
        if (remote && img.dataset.remoteTried !== "1") {
            img.dataset.remoteTried = "1";
            img.src = remote;
            return;
        }

        const fallback = img.dataset.fallback;
        if (fallback && img.src && !img.src.endsWith(fallback)) {
            img.onerror = null;
            img.src = fallback;
            return;
        }

        img.style.display = "none";
    };

    img.src = src;
}

function prepareLazyImages(root = document) {
    const images = $$("img.lazy-catalog-image[data-src]", root);
    if (!images.length) return;

    if (!("IntersectionObserver" in window)) {
        images.forEach(loadCatalogImage);
        return;
    }

    if (!lazyImageObserver) {
        lazyImageObserver = new IntersectionObserver(entries => {
            for (const entry of entries) {
                if (!entry.isIntersecting) continue;
                lazyImageObserver.unobserve(entry.target);
                loadCatalogImage(entry.target);
            }
        }, {
            root: null,
            rootMargin: "260px 0px",
            threshold: 0.01
        });
    }

    images.forEach(img => lazyImageObserver.observe(img));
}

function scheduleCatalogFilter(input) {
    const previous = filterTimers.get(input);
    if (previous) clearTimeout(previous);

    const timer = setTimeout(() => {
        requestAnimationFrame(() => {
            filterBySelector(input);
            prepareLazyImages(document);
        });
    }, 70);

    filterTimers.set(input, timer);
}



const playerCallRoot = $("#playerCallRoot");
const sectorCallRoot = $("#sectorCallRoot");
const sectorCallNoticeRoot = $("#sectorCallNoticeRoot");
const callEvaluationRoot = $("#callEvaluationRoot");
const sectorCalls = new Map();
let sectorFocused = false;
let playerCallMenuState = { open: false, department: null };
let evaluationState = null;
let callsLoading = false;

const CALL_DEPARTMENTS = {
    staff: { label: "Staff", title: "Chamado Staff", action: "Chamar Staff", icon: "headset" },
    police: { label: "Polícia", title: "Chamado Polícia", action: "Chamar Polícia", icon: "shield" },
    mechanic: { label: "Mecânica", title: "Chamado Mecânica", action: "Chamar Mecânica", icon: "wrench" },
    hospital: { label: "Hospital", title: "Chamado Hospital", action: "Chamar Hospital", icon: "heart" }
};

function renderPlayerCallMenu() {
    if (!playerCallRoot) return;
    if (!playerCallMenuState.open) {
        playerCallRoot.classList.remove("is-open");
        playerCallRoot.setAttribute("aria-hidden", "true");
        playerCallRoot.innerHTML = "";
        return;
    }

    const department = playerCallMenuState.department;
    if (!department) {
        const cards = Object.entries(CALL_DEPARTMENTS).map(([key, meta]) => `
            <button type="button" class="player-call-type" data-player-call-type="${key}">
                <span>${icon(meta.icon, 22)}</span>
                <strong>${escapeHtml(meta.title)}</strong>
                <small>Solicitar atendimento</small>
            </button>
        `).join("");
        playerCallRoot.innerHTML = `
            <div class="player-call-modal">
                <div class="player-call-head">
                    <div><span>ATENDIMENTO</span><strong>Como podemos ajudar?</strong><small>Selecione o setor responsável pelo seu chamado.</small></div>
                    <button type="button" class="call-ui-close" data-call-menu-close>${icon("close", 17)}</button>
                </div>
                <div class="player-call-types">${cards}</div>
                <div class="player-call-hint">F5 abre e fecha esta tela.</div>
            </div>`;
    } else {
        const meta = CALL_DEPARTMENTS[department] || CALL_DEPARTMENTS.staff;
        playerCallRoot.innerHTML = `
            <form class="player-call-modal player-call-message-modal" id="playerCallForm" data-department="${department}">
                <div class="player-call-head">
                    <div><span>${escapeHtml(meta.title.toUpperCase())}</span><strong>Em que você precisa de ajuda?</strong><small>Explique a situação de forma objetiva para agilizar o atendimento.</small></div>
                    <button type="button" class="call-ui-close" data-call-menu-close>${icon("close", 17)}</button>
                </div>
                <textarea class="player-call-textarea" name="message" maxlength="500" placeholder="Digite aqui o que aconteceu..." required></textarea>
                <div class="player-call-actions">
                    <button type="button" class="button" data-player-call-back>Cancelar</button>
                    <button type="submit" class="button primary">${icon("message", 14)} ${escapeHtml(meta.action)}</button>
                </div>
            </form>`;
    }
    playerCallRoot.classList.add("is-open");
    playerCallRoot.setAttribute("aria-hidden", "false");
}

function renderSectorCalls() {
    if (!sectorCallRoot) return;
    const calls = Array.from(sectorCalls.values());
    sectorCallRoot.innerHTML = calls.map(call => {
        const meta = CALL_DEPARTMENTS[call.department] || { title: call.departmentLabel || "Chamado" };
        return `
            <article class="sector-call-card ${sectorFocused ? "is-focused" : ""}" data-sector-call-card="${Number(call.id)}">
                <div class="sector-call-head"><span>${icon(meta.icon || "message", 16)}</span><strong>${escapeHtml(meta.title || call.departmentLabel || "Chamado")}</strong><span class="sector-call-id">#${Number(call.id)}</span></div>
                <div class="sector-call-player"><strong>${escapeHtml(call.playerName || "Jogador")}</strong><span>ID #${Number(call.playerId || 0)}</span></div>
                <p>${escapeHtml(call.message || "Sem mensagem")}</p>
                <div class="sector-call-actions">
                    <button type="button" class="sector-call-accept" data-sector-call-accept="${Number(call.id)}">${icon("check", 13)} Aceitar</button>
                    <button type="button" class="sector-call-close" data-sector-call-dismiss="${Number(call.id)}">${icon("close", 13)} Fechar</button>
                </div>
                <small class="sector-call-focus-hint">${sectorFocused ? "Clique em uma opção" : "Pressione F5 para liberar o mouse"}</small>
            </article>`;
    }).join("");
    sectorCallRoot.classList.toggle("has-calls", calls.length > 0);
}

function showSectorCallNotice(payload = {}) {
    if (!sectorCallNoticeRoot) return;
    const el = document.createElement("div");
    el.className = `sector-call-notice ${payload.cancelled ? "is-cancelled" : ""}`;
    el.innerHTML = payload.cancelled
        ? `<span>${icon("alert", 15)}</span><div><strong>Chamado encerrado</strong><p>${escapeHtml(payload.playerName || "Jogador")} • ID #${Number(payload.playerId || 0)} saiu da cidade.</p></div>`
        : `<span>${icon("check", 15)}</span><div><strong>Chamado aceito</strong><p>Alguém acabou de aceitar o chamado de ${escapeHtml(payload.playerName || "jogador")} • ID #${Number(payload.playerId || 0)}</p></div>`;
    sectorCallNoticeRoot.appendChild(el);
    setTimeout(() => el.remove(), 6500);
}

function renderCallEvaluation() {
    if (!callEvaluationRoot) return;
    if (!evaluationState) {
        callEvaluationRoot.classList.remove("is-open");
        callEvaluationRoot.setAttribute("aria-hidden", "true");
        callEvaluationRoot.innerHTML = "";
        return;
    }
    const stars = [1,2,3,4,5].map(value => `<button type="button" class="evaluation-star ${Number(evaluationState.stars || 0) >= value ? "is-active" : ""}" data-evaluation-star="${value}" aria-label="${value} estrelas">${icon("star", 36)}</button>`).join("");
    callEvaluationRoot.innerHTML = `
        <div class="call-evaluation-modal">
            <span class="call-evaluation-eyebrow">ATENDIMENTO FINALIZADO</span>
            <h2>Avaliar atendimento de ${escapeHtml(evaluationState.staffName || "Staff")}</h2>
            <p>Selecione de 1 a 5 estrelas para registrar sua experiência.</p>
            <div class="evaluation-stars">${stars}</div>
            ${evaluationState.showMessage ? `<textarea id="evaluationMessage" class="evaluation-message" maxlength="500" placeholder="Conte o que achou sobre o atendimento...">${escapeHtml(evaluationState.message || "")}</textarea>` : ""}
            <div class="evaluation-actions">
                <button type="button" class="button" data-evaluation-message>${evaluationState.showMessage ? "Ocultar mensagem" : "Deixar mensagem"}</button>
                <button type="button" class="button primary" data-evaluation-submit>${icon("check", 14)} Concluir</button>
            </div>
        </div>`;
    callEvaluationRoot.classList.add("is-open");
    callEvaluationRoot.setAttribute("aria-hidden", "false");
}

async function refreshCallsPanelData(showError = false, auditView = "") {
    if (callsLoading || !state.open || state.page !== "calls") return;
    callsLoading = true;
    const response = await post("calls", { mode: "panelData", auditView });
    callsLoading = false;
    if (!response?.ok) {
        if (showError) toast("error", "Chamados", response?.message || "Não foi possível carregar os chamados.");
        return;
    }
    state.callsData = response.data || {};
    if (state.open && state.page === "calls") render();
}

function starLine(value, size = 14) {
    const stars = Math.max(0, Math.min(5, Number(value) || 0));
    return `<span class="staff-star-line">${[1,2,3,4,5].map(i => `<span class="${i <= Math.round(stars) ? "is-active" : ""}">${icon("star", size)}</span>`).join("")}<b>${stars ? stars.toFixed(1) : "0.0"}</b></span>`;
}

function renderCalls() {
    const data = state.callsData || {};
    const viewerId = Number(data.viewerId || state.bootstrap?.admin?.id || 0);
    const view = state.callsView || "open";
    const top = [
        canUse("calls_history") ? ["history", "Histórico de chamados", "archive"] : null,
        canUse("calls_ranking") ? ["ranking", "Ranking Staff", "trophy"] : null,
        canUse("calls_evaluations") ? ["evaluations", "Avaliações", "star"] : null,
        canUse("calls_staff_notes") ? ["notes", "Notas Staff", "activity"] : null
    ].filter(Boolean);
    const topButtons = top.map(([id,label,ico]) => `<button type="button" class="calls-top-option ${view === id ? "is-active" : ""}" data-calls-view="${id}"><span>${icon(ico, 19)}</span><strong>${escapeHtml(label)}</strong>${icon("arrow", 14)}</button>`).join("");

    let body = "";
    if (view === "history") {
        const rows = (data.history || []).map(call => `<article class="call-history-card"><div><span class="call-status done">FINALIZADO</span><strong>${escapeHtml(call.playerName)} <small>ID #${call.playerId}</small></strong><p>${escapeHtml(call.message)}</p></div><div class="call-history-side"><strong>${escapeHtml(call.staffName)}</strong><small>Staff ID #${call.staffId}</small><span>${escapeHtml(call.completedAtText || "-")}</span>${call.rating ? starLine(call.rating, 12) : '<em>Sem avaliação</em>'}</div></article>`).join("");
        body = `<div class="calls-section-head"><div><strong>Histórico de chamados</strong><span>Atendimentos Staff já finalizados e arquivados.</span></div><button type="button" class="button" data-calls-view="open">${icon("arrow",14)} Chamados abertos</button></div><div class="calls-scroll-list">${rows || '<div class="calls-empty">Nenhum chamado finalizado ainda.</div>'}</div>`;
    } else if (view === "ranking") {
        const rows = (data.ranking || []).map((staff,index) => `<article class="ranking-row rank-${index+1 <= 3 ? index+1 : 'other'}"><span class="ranking-position">${index+1}º</span><div class="ranking-avatar">${escapeHtml(initials(staff.name))}</div><div class="ranking-copy"><strong>${escapeHtml(staff.name)}</strong><span>ID #${staff.id} • ${staff.points} atendimento(s)</span></div><div class="ranking-rating">${staff.ratingCount ? starLine(staff.averageRating, 12) : '<span>Sem avaliações</span>'}</div></article>`).join("");
        body = `<div class="calls-section-head"><div><strong>Ranking Staff</strong><span>Cada chamado Staff finalizado soma 1 ponto.</span></div><button type="button" class="button" data-calls-view="open">${icon("arrow",14)} Chamados abertos</button></div><div class="ranking-list">${rows || '<div class="calls-empty">O ranking ainda está vazio.</div>'}</div>`;
    } else if (view === "evaluations") {
        const rows = (data.evaluations || []).map(item => `<article class="evaluation-history-card"><div class="evaluation-history-top"><div><strong>${escapeHtml(item.staffName)}</strong><span>atendimento ao ${escapeHtml(item.playerName)} • ID #${item.playerId}</span></div>${starLine(item.stars, 13)}</div><p>${escapeHtml(item.message || "sem-mensagem")}</p><small>${escapeHtml(item.createdAtText || "-")}</small></article>`).join("");
        body = `<div class="calls-section-head"><div><strong>Avaliações</strong><span>Notas e comentários deixados após os atendimentos.</span></div><button type="button" class="button" data-calls-view="open">${icon("arrow",14)} Chamados abertos</button></div><div class="calls-scroll-list evaluation-list">${rows || '<div class="calls-empty">Nenhuma avaliação recebida.</div>'}</div>`;
    } else if (view === "notes") {
        const rows = (data.staffNotes || []).map(staff => `<article class="staff-note-row"><div class="ranking-avatar">${escapeHtml(initials(staff.name))}</div><div><strong>${escapeHtml(staff.name)}</strong><span>ID #${staff.id} • ${staff.completed} chamado(s) atendido(s)</span></div><div class="staff-note-score">${staff.ratingCount ? starLine(staff.averageRating, 15) : '<strong>Sem avaliações</strong>'}<small>${staff.ratingCount} avaliação(ões)</small></div></article>`).join("");
        body = `<div class="calls-section-head"><div><strong>Notas Staff</strong><span>Média de estrelas de cada Staff que já atendeu chamados.</span></div><button type="button" class="button" data-calls-view="open">${icon("arrow",14)} Chamados abertos</button></div><div class="staff-notes-list">${rows || '<div class="calls-empty">Nenhum Staff concluiu chamados ainda.</div>'}</div>`;
    } else {
        const rows = (data.openCalls || []).map(call => {
            const acceptedByMe = call.status === "accepted" && Number(call.acceptedById) === viewerId;
            let action = "";
            if (call.status === "open") {
                action = canUse("calls_accept") ? `<button type="button" class="button primary call-accept-button" data-staff-call-accept="${call.id}">${icon("check", 14)} Aceitar chamado</button>` : '<span class="call-disabled-action">Aguardando Staff autorizado</span>';
            } else if (acceptedByMe) {
                action = canUse("calls_finish") ? `<button type="button" class="button success call-finish-button" data-staff-call-finish="${call.id}">${icon("check", 14)} Finalizar chamado</button>` : '<span class="call-disabled-action">Em atendimento por você</span>';
            } else {
                action = `<button type="button" class="button call-other-staff" disabled>${icon("users", 14)} Outro staff aceitou</button>`;
            }
            return `<article class="open-call-card ${call.status === "accepted" ? "is-accepted" : ""}"><div class="open-call-main"><div class="open-call-title"><span class="call-status ${call.status}">${call.status === "open" ? "ABERTO" : "EM ATENDIMENTO"}</span><strong>${escapeHtml(call.playerName)} <small>ID #${call.playerId}</small></strong></div><p>${escapeHtml(call.message)}</p><div class="open-call-meta"><span>${icon("clock", 12)} ${escapeHtml(call.createdAtText || "-")}</span>${call.acceptedByName ? `<span>${icon("users",12)} ${escapeHtml(call.acceptedByName)}</span>` : ""}</div></div><div class="open-call-action">${action}</div></article>`;
        }).join("");
        body = `<div class="calls-section-head"><div><strong>Chamados abertos</strong><span>${(data.openCalls || []).length} chamado(s) Staff aguardando ou em atendimento.</span></div><button type="button" class="button" data-calls-refresh>${icon("refresh", 14)} Atualizar</button></div><div class="calls-scroll-list open-calls-list">${rows || '<div class="calls-empty"><span>'+icon("headset",26)+'</span><strong>Nenhum chamado Staff aberto</strong><p>Novos chamados aparecerão aqui automaticamente.</p></div>'}</div>`;
    }

    return `<div class="calls-page bounded-page"><div class="calls-top-options">${topButtons}</div><section class="calls-main-card">${state.callsData ? body : '<div class="calls-loading"><span>'+icon("refresh",26)+'</span><strong>Carregando chamados...</strong></div>'}</section></div>`;
}

async function post(endpoint, data = {}) {
    try {
        const response = await fetch(`https://${resourceName}/${endpoint}`, {
            method: "POST",
            headers: { "Content-Type": "application/json; charset=UTF-8" },
            body: JSON.stringify(data)
        });

        const firstResponse = await response.json();
        if (firstResponse?.__mgBridgePending === true && firstResponse?.requestId) {
            return await waitMgBridgeResponse(firstResponse.requestId);
        }

        return firstResponse;
    } catch (error) {
        console.error(`[m_paineladm_v2] NUI callback '${endpoint}' falhou:`, error);
        const now = Date.now();
        if ((now - mgBridgeLastTransportToastAt) > 3500) {
            mgBridgeLastTransportToastAt = now;
            toast("error", "Falha de comunicacao", `Bridge JS ${MG_UI_BUILD} nao respondeu. Verifique bridge_client.js no fxmanifest.`);
        }
        return { ok: false, message: "Falha de comunicacao com o transporte NUI do resource." };
    }
}

function escapeHtml(value) {
    return String(value ?? "")
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#039;");
}

function initials(name) {
    const parts = String(name || "?").trim().split(/\s+/).filter(Boolean);
    return ((parts[0]?.[0] || "?") + (parts[1]?.[0] || "")).toUpperCase();
}

function formatMoney(value) {
    const number = Number(value || 0);
    try {
        return number.toLocaleString("pt-BR", { style: "currency", currency: "BRL", maximumFractionDigits: 0 });
    } catch {
        return `R$ ${number}`;
    }
}

function nowTime() {
    const d = new Date();
    return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
}

function addHistory(label) {
    state.history.unshift({ label, time: nowTime() });
    state.history = state.history.slice(0, 7);
}

function canUse(permission) {
    if (!permission) return true;
    return state.permissions?.allowedActions?.[permission] === true;
}

function canManagePanelPermissions() {
    return state.permissions?.canManage === true;
}

function visibleNavigation() {
    return NAV.filter(item => canUse(item.permission));
}

function firstVisiblePage() {
    return visibleNavigation()[0]?.id || "server";
}

function actionLabel(action) {
    return ACTIONS[action]?.title || action;
}

function toast(kind, title, message = "") {
    const el = document.createElement("div");
    el.className = `toast ${kind || "info"}`;
    const iconName = kind === "success" ? "check" : kind === "error" ? "alert" : "activity";
    el.innerHTML = `
        <div class="toast-icon">${icon(iconName, 15)}</div>
        <div>
            <strong>${escapeHtml(title)}</strong>
            ${message ? `<p>${escapeHtml(message)}</p>` : ""}
        </div>
    `;
    toastRoot.appendChild(el);
    setTimeout(() => el.remove(), 4300);
}

function setOpen(open) {
    state.open = open;
    app.classList.toggle("is-hidden", !open);
    app.setAttribute("aria-hidden", open ? "false" : "true");
    if (!open) {
        teardownLiveMap(true);
        closeModal();
    }
}

function pageMeta() {
    return NAV.find(item => item.id === state.page && canUse(item.permission)) || visibleNavigation()[0] || NAV[0];
}

function renderShell() {
    const brand = state.config.brand || {};
    $("#brandName").textContent = brand.name || "MAGE ADMIN";
    $("#brandVersion").textContent = `v${brand.version || "2.0.0"}`;

    const admin = state.bootstrap?.admin || { name: "Administrador", id: 0 };
    $("#adminName").textContent = admin.name || "Administrador";
    $("#adminId").textContent = `ID #${admin.id || 0}`;
    $("#adminAvatar").textContent = initials(admin.name);
    $("#onlineCount").textContent = state.bootstrap?.stats?.players ?? 0;
    $("#refreshButton").style.display = canUse("view_players") ? "" : "none";

    const needsTopToggle = $("#needsTopToggle");
    if (needsTopToggle) {
        const allowed = canUse("needs_manage");
        const enabled = state.bootstrap?.needsEnabled !== false;
        needsTopToggle.style.display = allowed ? "" : "none";
        if (allowed) {
            needsTopToggle.classList.toggle("is-on", enabled);
            needsTopToggle.classList.toggle("is-off", !enabled);
            needsTopToggle.dataset.nextState = enabled ? "false" : "true";
            needsTopToggle.setAttribute("aria-label", `Fome e sede: ${enabled ? "ativado" : "desativado"}. Clique para ${enabled ? "desligar" : "ligar"}.`);
            needsTopToggle.innerHTML = `
                <span class="needs-top-icon">${icon("activity", 16)}</span>
                <span class="needs-top-copy">
                    <small>FOME E SEDE</small>
                    <strong>${enabled ? "ATIVADO" : "DESATIVADO"}</strong>
                </span>
                <span class="needs-top-switch" aria-hidden="true"><span></span></span>
            `;
        }
    }

    const needsTopSettings = $("#needsTopSettings");
    if (needsTopSettings) {
        const allowed = canUse("needs_manage");
        const enabled = state.bootstrap?.needsEnabled !== false;
        needsTopSettings.style.display = allowed && enabled ? "" : "none";
        if (allowed && enabled) {
            needsTopSettings.innerHTML = `
                <span class="needs-settings-icon">${icon("sliders", 16)}</span>
                <span class="needs-settings-copy">
                    <small>FOME / SEDE</small>
                    <strong>CONFIGURAR</strong>
                </span>
            `;
        }
    }

    const navItems = visibleNavigation();
    $("#navigation").innerHTML = navItems.map(item => `
        <button type="button" class="nav-button ${state.page === item.id ? "is-active" : ""}" data-nav="${item.id}" title="${escapeHtml(item.label)}">
            ${icon(item.icon)}
            <span>${escapeHtml(item.label)}</span>
        </button>
    `).join("");

    const meta = pageMeta();
    $("#pageEyebrow").textContent = meta.eyebrow;
    $("#pageTitle").textContent = meta.title;
    $("#pageDescription").textContent = meta.description;
}

function needsToggleActionCard() {
    if (!canUse("needs_manage")) return "";
    const enabled = state.bootstrap?.needsEnabled !== false;
    return `
        <button type="button" class="action-card needs-toggle-card ${enabled ? "is-on" : "is-off"}" data-toggle-needs data-next-state="${enabled ? "false" : "true"}">
            <div class="action-card-top">
                <span class="action-card-icon">${icon("activity", 15)}</span>
                <strong>Fome e sede</strong>
                <span class="needs-status-pill ${enabled ? "is-on" : "is-off"}">${enabled ? "ATIVADO" : "DESATIVADO"}</span>
            </div>
            <p>${enabled ? "Sistema ativo. Clique para desligar fome, sede, HUD e consumo de alimentos." : "Sistema desligado. Clique para ativar fome, sede, HUD e consumo de alimentos."}</p>
        </button>
    `;
}

function actionCard(action, description) {
    if (action === "needs_manage") return needsToggleActionCard();
    const meta = ACTIONS[action];
    if (!meta || !canUse(action)) return "";
    return `
        <button type="button" class="action-card ${meta.danger ? "danger" : ""}" data-open-action="${action}">
            <div class="action-card-top">
                <span class="action-card-icon">${icon(meta.icon, 15)}</span>
                <strong>${escapeHtml(meta.title)}</strong>
            </div>
            <p>${escapeHtml(description || meta.description)}</p>
        </button>
    `;
}

function vehicleGarageActionCard(mode) {
    const isRemove = mode === "remove";
    const permission = isRemove ? "rem_veh" : "give_veh";
    if (!canUse(permission)) return "";
    return `
        <button type="button" class="action-card ${isRemove ? "danger" : ""}" data-open-vehicle-garage="${mode}">
            <div class="action-card-top">
                <span class="action-card-icon">${icon(isRemove ? "trash" : "plus", 15)}</span>
                <strong>${isRemove ? "Remover veículo" : "Dar veículo"}</strong>
            </div>
            <p>${isRemove ? "Remova rapidamente um veículo da garagem pelo catálogo ou spawn." : "Entregue rapidamente um veículo pelo catálogo ou digitando o spawn."}</p>
        </button>
    `;
}

function renderPlayerInventoryDetail(p) {
    const inventory = p?.inventory || [];
    const invHtml = inventory.length
        ? inventory.map(item => `
            <div class="item-card" data-search="${escapeHtml(`${item.name} ${item.index}`.toLowerCase())}">
                <div class="thumb">
                    <img class="lazy-catalog-image" data-src="${escapeHtml(itemImage(item.index))}" data-fallback="imgs/no-image.png" loading="lazy" decoding="async" alt="">
                </div>
                <div class="item-body">
                    <strong>${escapeHtml(item.name)}</strong>
                    <span>${escapeHtml(item.index)} • x${item.amount}</span>
                    ${canUse("remove_item") ? `<div class="item-actions">
                        <button class="button small danger" type="button" data-item-mode="remove" data-item="${escapeHtml(item.index)}">${icon("minus", 11)} Remover</button>
                    </div>` : ""}
                </div>
            </div>
        `).join("")
        : `<div class="empty-state inventory-empty"><div><strong>Inventário vazio</strong><p>Este jogador não possui itens no inventário neste momento.</p></div></div>`;

    return `
        <div class="inventory-inspector">
            <div class="inventory-inspector-head">
                <div class="profile-inline">
                    <div class="profile-avatar compact">${initials(p.name)}</div>
                    <div class="profile-copy">
                        <span class="inventory-eyebrow">INVENTÁRIO DO JOGADOR</span>
                        <h3>${escapeHtml(p.name)}</h3>
                        <p>Passaporte #${p.id} • ${inventory.length} slot(s) listado(s)</p>
                    </div>
                </div>
                <button class="button ghost" type="button" data-player-profile>${icon("arrow", 12)} Voltar ao jogador</button>
            </div>

            <div class="inventory-toolbar">
                <div class="search-box">
                    ${icon("search")}
                    <input class="input" type="text" placeholder="Buscar no inventário..." data-filter-selector="#playerInventoryInspect [data-search]">
                </div>
                ${canUse("give_item") ? `<button class="button primary" type="button" data-open-item-catalog>${icon("plus", 12)} ADD ITEM</button>` : ""}
                ${canUse("clear_inv") ? `<button class="button danger" type="button" data-open-action="clear_inv" data-default-target="${p.id}">${icon("trash", 12)} Limpar Inventário</button>` : ""}
            </div>

            <div id="playerInventoryInspect" class="item-grid scroll-list inventory-scroll">${invHtml}</div>
        </div>
    `;
}

function renderPlayerDetail() {
    const p = state.snapshot;
    if (!p) {
        return `
            <div class="empty-state" style="min-height:100%">
                <div>
                    <div class="empty-icon">${icon("users")}</div>
                    <strong>Selecione um jogador</strong>
                    <p>Clique em um jogador da lista para consultar identidade, cargos, saldo e ações disponíveis.</p>
                </div>
            </div>
        `;
    }

    if (state.playerView === "inventory" && canUse("inspect_inventory")) {
        return renderPlayerInventoryDetail(p);
    }

    const groupTags = (p.groups || []).length
        ? p.groups.map(group => `<span class="tag">${escapeHtml(group)}</span>`).join("")
        : `<span class="tag">Sem cargos carregados</span>`;

    const quick = [
        ["tpto", "Ir até"], ["tptome", "Puxar"], ["map_screen", "Ver tela"], ["god", "Reviver"],
        ["freeze", "Congelar"], ["unfreeze", "Descongelar"], ["send_dm", "Mensagem"], ["warning", "Advertência"], ["catch_rg", "RG"],
        ["givemoney", "Adicionar dinheiro"], ["remove_money", "Remover dinheiro"], ["clear_weapons", "Limpar armas"], ["kick", "Kick"],
        ["ban", "Banir"]
    ].filter(([action]) => canUse(action)).map(([action, label]) => `
        <button class="quick-button ${ACTIONS[action]?.danger ? "danger" : ""}" type="button"
            data-open-action="${action}" data-default-target="${p.id}">
            ${icon(ACTIONS[action]?.icon || "activity", 14)}
            <span>${escapeHtml(label)}</span>
        </button>
    `).join("");

    return `
        <div class="profile-hero">
            <div class="profile-avatar">${initials(p.name)}</div>
            <div class="profile-copy">
                <h3>${escapeHtml(p.name)}</h3>
                <p>Passaporte #${p.id} • Source ${p.source ?? "-"} • Bucket ${p.bucket ?? 0}</p>
            </div>
            <div class="profile-side-actions">
                ${canUse("inspect_inventory") ? `<button class="button primary inspect-button" type="button" data-inspect-inventory>${icon("package", 12)} Inspecionar Inventário</button>` : ""}
                <span class="status-badge ${p.online ? "" : "offline"}">${p.online ? "ONLINE" : "OFFLINE"}</span>
            </div>
        </div>

        <div class="info-grid">
            <div class="info-tile"><span>Carteira</span><strong>${formatMoney(p.wallet)}</strong></div>
            <div class="info-tile"><span>Banco</span><strong>${formatMoney(p.bank)}</strong></div>
            <div class="info-tile"><span>Multas</span><strong>${formatMoney(p.fines)}</strong></div>
            <div class="info-tile warning-count"><span>Advertências</span><strong>${Number(p.warnings || 0)}</strong></div>
            <div class="info-tile"><span>Ping</span><strong>${p.online ? `${p.ping ?? 0}ms` : "-"}</strong></div>
        </div>

        <div class="detail-section">
            <div class="detail-section-head">
                <strong>Ações rápidas</strong>
                <span>As permissões também são verificadas no servidor.</span>
            </div>
            <div class="quick-actions">${quick}</div>
        </div>

        <div class="detail-section">
            <div class="detail-section-head">
                <strong>Cargos atuais</strong>
                ${canUse("view_groups") ? `<button class="button small ghost" type="button" data-nav-target="groups" data-target="${p.id}">Gerenciar ${icon("arrow", 11)}</button>` : ""}
            </div>
            <div class="tag-list">${groupTags}</div>
        </div>
    `;
}

function renderWarnings() {
    const data = state.warningsData;
    if (!data) {
        return `<div class="warnings-page bounded-page"><div class="empty-state"><div><strong>Carregando advertências...</strong><p>Aguarde enquanto os registros são consultados.</p></div></div></div>`;
    }

    const players = Array.isArray(data.players) ? data.players : [];
    const rows = players.map(player => {
        const fullName = `${player.nome || "Sem"} ${player.sobrenome || "Identidade"}`.replace(/\s+/g, " ").trim();
        return `
            <button type="button" class="warning-player-card" data-warning-player="${Number(player.id)}"
                data-search="${escapeHtml(`${player.id} ${fullName}`.toLowerCase())}">
                <div class="warning-player-avatar">${initials(fullName)}</div>
                <div class="warning-player-info">
                    <span class="warning-player-kicker">ID #${Number(player.id)}</span>
                    <strong>${escapeHtml(fullName)}</strong>
                    <small>${player.active ? "CASTIGO ATIVO" : "Histórico de advertências"}</small>
                </div>
                <div class="warning-player-count">
                    <span>Advertências</span>
                    <strong>${Number(player.count || 0)}</strong>
                </div>
                ${icon("arrow", 15)}
            </button>`;
    }).join("");

    return `
        <div class="warnings-page bounded-page">
            <div class="warnings-stats-grid">
                <article class="warning-stat-card"><span>Jogadores advertidos</span><strong>${Number(data.totalPlayers || players.length)}</strong></article>
                <article class="warning-stat-card danger"><span>Total de advertências</span><strong>${Number(data.totalWarnings || 0)}</strong></article>
            </div>
            <article class="warnings-list-card">
                <div class="list-head warnings-list-head">
                    <div>
                        <strong>REGISTROS DE ADVERTÊNCIAS</strong>
                        <span>ID, nome, sobrenome e quantidade de advertências registradas.</span>
                    </div>
                    <div class="search-box">
                        ${icon("search", 18)}
                        <input class="input" type="text" placeholder="Buscar por ID, nome ou sobrenome..." data-filter-selector=".warning-player-card">
                    </div>
                </div>
                <div class="warnings-player-list scroll-area">
                    ${rows || `<div class="empty-state"><div><strong>Nenhuma advertência registrada</strong><p>Quando uma advertência for aplicada, o jogador aparecerá aqui.</p></div></div>`}
                </div>
            </article>
        </div>`;
}

async function refreshWarningsPanelData(silent = true) {
    const response = await post("warnings", { mode: "list", silent });
    if (!response?.ok) {
        if (!silent) toast("error", "Advertências", response?.message || "Não foi possível carregar os registros.");
        return false;
    }
    state.warningsData = response.data || { players: [], totalWarnings: 0, totalPlayers: 0 };
    if (state.page === "warnings") render();
    return true;
}

async function openWarningHistoryModal(targetId, silent = false) {
    targetId = Number(targetId || 0);
    if (!targetId) return;

    const response = await post("warnings", { mode: "detail", targetId, silent });
    if (!response?.ok || !response.data) {
        toast("error", "Advertências", response?.message || "Não foi possível carregar o histórico deste jogador.");
        return;
    }

    const player = response.data;
    const fullName = `${player.nome || "Sem"} ${player.sobrenome || "Identidade"}`.replace(/\s+/g, " ").trim();
    const entries = Array.isArray(player.entries) ? player.entries : [];
    const history = entries.map(entry => `
        <article class="warning-history-entry ${entry.active ? "is-active" : ""}">
            <div class="warning-history-head">
                <div>
                    <span class="warning-history-number">ADVERTÊNCIA #${Number(entry.id || 0)}</span>
                    <strong>${Number(entry.minutes || 0)} minuto${Number(entry.minutes || 0) === 1 ? "" : "s"}${entry.active ? " • CASTIGO ATIVO" : ""}</strong>
                </div>
                <span class="warning-history-date">${escapeHtml(entry.date || "-")} • ${escapeHtml(entry.time || "-")}</span>
            </div>
            <div class="warning-history-reason">
                <span>MOTIVO</span>
                <p>${escapeHtml(entry.reason || "Sem motivo registrado.")}</p>
            </div>
            <div class="warning-history-footer">
                <span>Aplicada por <strong>${escapeHtml(entry.actorName || (entry.actorId ? `ID #${entry.actorId}` : "Staff"))}</strong>${entry.actorId ? ` • ID #${Number(entry.actorId)}` : ""}</span>
                ${canUse("delete_warning") ? `<button class="button small danger" type="button" data-delete-warning="${Number(entry.id)}" data-warning-target="${targetId}">${icon("trash", 12)} Excluir advertência</button>` : ""}
            </div>
        </article>`).join("");

    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <div class="modal warning-history-modal">
            <div class="modal-head">
                <div class="modal-title">
                    <strong>${escapeHtml(fullName)}</strong>
                    <span>Passaporte #${targetId} • ${Number(player.count || entries.length)} advertência${Number(player.count || entries.length) === 1 ? "" : "s"}</span>
                </div>
                <button class="modal-close" type="button" data-modal-close>${icon("close", 17)}</button>
            </div>
            <div class="modal-body warning-history-modal-body">
                <div class="warning-history-list scroll-list">
                    ${history || `<div class="empty-state"><div><strong>Sem advertências</strong><p>Não há mais registros para este jogador.</p></div></div>`}
                </div>
            </div>
            <div class="modal-foot"><button class="button primary" type="button" data-modal-close>Fechar</button></div>
        </div>`;
}

function renderPlayers() {
    const players = state.bootstrap?.players || [];
    const stats = state.bootstrap?.stats || {};
    const playerStats = [
        { label: "Jogadores Online", value: stats.players ?? players.length, icon: "users", tone: "players" },
        { label: "Staff Online", value: stats.staff ?? 0, icon: "shield", tone: "staff" },
        { label: "Mecânicos Online", value: stats.mechanics ?? 0, icon: "wrench", tone: "mechanics" },
        { label: "Polícia Online", value: stats.police ?? 0, icon: "id", tone: "police" },
        { label: "Médicos Online", value: stats.medics ?? 0, icon: "heart", tone: "medics" },
        { label: "Ilegal Online", value: stats.illegal ?? 0, icon: "alert", tone: "illegal" }
    ];
    const statsHtml = playerStats.map(stat => `
        <article class="online-stat-card ${stat.tone}">
            <span class="online-stat-icon">${icon(stat.icon, 19)}</span>
            <div class="online-stat-copy">
                <strong>${escapeHtml(stat.value)}</strong>
                <span>${escapeHtml(stat.label)}</span>
            </div>
        </article>
    `).join("");

    const rows = players.map(player => `
        <button type="button"
            class="player-row ${Number(state.selectedPlayerId) === Number(player.id) ? "is-selected" : ""}"
            data-player="${player.id}"
            data-search="${escapeHtml(`${player.name} ${player.id}`.toLowerCase())}">
            <div class="player-avatar">${initials(player.name)}</div>
            <div class="player-info">
                <strong>${escapeHtml(player.name)}</strong>
                <span>ID #${player.id} • Bucket ${player.bucket ?? 0}</span>
            </div>
            <div class="player-meta">
                <strong>#${player.id}</strong>
                <span>${player.ping ?? 0}ms</span>
            </div>
        </button>
    `).join("");

    return `
        <div class="players-overview bounded-page">
            <div class="online-stats-grid">${statsHtml}</div>
            <div class="split-layout bounded-page players-page">
            <article class="player-list-card">
                <div class="list-head">
                    <div class="search-box">
                        ${icon("search")}
                        <input class="input" type="text" placeholder="Buscar por nome ou ID..." data-filter-selector=".player-row">
                    </div>
                </div>
                <div class="scroll-area">${rows || '<div class="empty-state"><strong>Nenhum jogador online</strong></div>'}</div>
            </article>

            <article class="detail-card ${state.playerView === "inventory" ? "inventory-mode" : "profile-mode"}">
                ${renderPlayerDetail()}
            </article>
            </div>
        </div>
    `;
}

function targetToolbar(id, mode, loaded = false) {
    const loadedPlayer = mode === "identity" ? state.identityEditor : state.snapshot;
    return `
        <div class="setagem-selector ${loaded ? "is-loaded" : "is-empty"}">
            <div class="setagem-selector-controls">
                <div class="setagem-id-field">
                    <label for="${mode}Target">Passaporte / ID</label>
                    <input id="${mode}Target" class="input" type="number" min="1" value="${id || ""}" placeholder="Digite o ID do jogador">
                </div>
                <button class="button primary setagem-load-button" type="button" data-load-target="${mode}">${icon("search", 17)} Carregar jogador</button>
            </div>
            ${loaded && loadedPlayer ? `
                <div class="setagem-loaded-player">
                    <span class="setagem-player-dot ${loadedPlayer.online ? "" : "is-offline"}"></span>
                    <div>
                        <strong>${escapeHtml(loadedPlayer.name)}</strong>
                        <span>Passaporte #${loadedPlayer.id}${loadedPlayer.online ? " • Online" : " • Offline"}</span>
                    </div>
                </div>
            ` : ""}
        </div>
    `;
}

function renderGroups() {
    const p = state.snapshot;
    const hasLoadedPlayer = Boolean(p?.id);
    const current = hasLoadedPlayer ? (p.groups || []) : [];
    const currentSet = new Set(current);
    const groups = state.bootstrap?.groups || [];

    if (!hasLoadedPlayer) {
        return `
            <div class="groups-page setagem-awaiting bounded-page">
                <div class="setagem-welcome">
                    <span class="setagem-welcome-eyebrow">SETAGEM DE JOGADOR</span>
                    <h2>Selecione quem deseja gerenciar</h2>
                    <p>Informe o Passaporte / ID para carregar os cargos atuais e as opções disponíveis.</p>
                    ${targetToolbar(state.selectedPlayerId, "groups", false)}
                </div>
            </div>
        `;
    }

    if (!p.online) {
        return `
            <div class="groups-page groups-offline bounded-page">
                ${targetToolbar(p.id, "groups", true)}

                <div class="setagem-offline-state">
                    <div class="setagem-offline-icon">${icon("users", 32)}</div>
                    <span class="setagem-offline-badge">OFFLINE</span>
                    <h2>JOGADOR OFFLINE NO MOMENTO</h2>
                    <p><strong>${escapeHtml(p.name)}</strong> não está conectado ao servidor. Para evitar alterações inconsistentes, os cargos só podem ser gerenciados quando o jogador estiver online.</p>
                    <span class="setagem-offline-id">Passaporte #${escapeHtml(p.id)}</span>
                </div>
            </div>
        `;
    }

    const currentHtml = current.length
        ? current.map(group => `
            <div class="catalog-card" data-search="${escapeHtml(group.toLowerCase())}">
                <div class="catalog-content">
                    <div class="catalog-title">${escapeHtml(group)}</div>
                    <div class="catalog-subtitle">Cargo atual do jogador</div>
                </div>
                <div class="catalog-actions">
                    ${canUse("remove_group") ? `<button class="button small danger" type="button" data-group-mode="remove" data-group="${escapeHtml(group)}">${icon("minus", 11)} Remover</button>` : ""}
                </div>
            </div>
        `).join("")
        : `<div class="empty-state"><div><strong>Nenhum cargo atual</strong><p>Este jogador não possui grupos carregados no momento.</p></div></div>`;

    const available = groups
        .filter(group => !currentSet.has(group.name))
        .map(group => `
            <div class="catalog-card" data-search="${escapeHtml(`${group.name} ${group.type || ""} ${group.org || ""}`.toLowerCase())}">
                <div class="catalog-content">
                    <div class="catalog-title">${escapeHtml(group.name)}</div>
                    <div class="catalog-subtitle">${escapeHtml(group.org || group.type || "outro")}${group.rank ? ` • nível ${group.rank}` : ""}</div>
                </div>
                <div class="catalog-actions">
                    ${canUse("set_group") ? `<button class="button small success" type="button" data-group-mode="add" data-group="${escapeHtml(group.name)}">${icon("plus", 11)} Adicionar</button>` : ""}
                </div>
            </div>
        `).join("");

    return `
        <div class="groups-page groups-loaded bounded-page">
            ${targetToolbar(p.id, "groups", true)}

            <div class="dual-grid bounded-grid">
                <article class="section-card">
                    <div class="section-head">
                        <div class="section-title"><strong>Cargos do jogador</strong><span>${current.length} grupo(s) carregado(s)</span></div>
                    </div>
                    <div class="section-body">
                        <div class="search-box" style="margin-bottom:10px">
                            ${icon("search")}
                            <input class="input" placeholder="Filtrar cargos atuais..." data-filter-selector="#currentGroups [data-search]">
                        </div>
                        <div id="currentGroups" class="catalog scroll-list">${currentHtml}</div>
                    </div>
                </article>

                <article class="section-card">
                    <div class="section-head">
                        <div class="section-title"><strong>Cargos disponíveis</strong><span>Filtrados e ordenados a partir do groups.json da vRP.</span></div>
                    </div>
                    <div class="section-body">
                        <div class="search-box" style="margin-bottom:10px">
                            ${icon("search")}
                            <input class="input" placeholder="Buscar cargo ou organização..." data-filter-selector="#availableGroups [data-search]">
                        </div>
                        <div id="availableGroups" class="catalog scroll-list">${available || '<div class="empty-state"><strong>Nenhum cargo disponível</strong></div>'}</div>
                    </div>
                </article>
            </div>
        </div>
    `;
}

function itemImage(item) {
    const base = state.config.images?.items || "";
    return `${base}${encodeURIComponent(item)}.png`;
}

function vehicleImage(spawn) {
    const base = state.config.images?.vehicles || "";
    return `${base}${encodeURIComponent(spawn)}.png`;
}

function renderItems() {
    const items = state.bootstrap?.items || [];
    const cards = canUse("spawn_self_item") ? items.map(item => `
        <button type="button" class="item-card self-item-card" data-self-item="${escapeHtml(item.index)}" data-item-name="${escapeHtml(item.name)}" data-search="${escapeHtml(`${item.name} ${item.index}`.toLowerCase())}">
            <div class="thumb">
                <img class="lazy-catalog-image" data-src="${escapeHtml(itemImage(item.index))}" data-fallback="imgs/no-image.png" loading="lazy" decoding="async" alt="">
            </div>
            <div class="item-body">
                <strong>${escapeHtml(item.name)}</strong>
                <span>${escapeHtml(item.index)}</span>
                <small class="self-item-hint">Clique para spawnar</small>
            </div>
        </button>
    `).join("") : "";

    return `
        <div class="items-page bounded-page">
            <div class="toolbar">
                <div class="search-box">
                    ${icon("search")}
                    <input class="input" placeholder="Buscar item pelo nome ou spawn..." data-filter-selector="#selfItemCatalog [data-search]">
                </div>
            </div>

            <div id="selfItemCatalog" class="item-grid scroll-list catalog-scroll self-item-grid">
                ${cards || `<div class="empty-state"><div><strong>${canUse("spawn_self_item") ? "Nenhum item encontrado" : "Spawn de itens bloqueado"}</strong><p>${canUse("spawn_self_item") ? "A vRP não retornou itens para o painel." : "Seu cargo não possui permissão para spawnar itens."}</p></div></div>`}
            </div>
        </div>
    `;
}


function weaponLocalImage(index) {
    return `imgs/weapons/${encodeURIComponent(String(index || "").toLowerCase())}.png`;
}

function weaponCategoryOrder(category) {
    const order = ["Pistolas", "Submetralhadoras", "Rifles", "Escopetas", "Snipers", "Pesadas", "Explosivos", "Corpo a corpo", "Utilitários", "Outras"];
    const pos = order.indexOf(category);
    return pos === -1 ? 999 : pos;
}

function renderWeapons() {
    const allWeapons = Array.isArray(state.bootstrap?.weapons) ? [...state.bootstrap.weapons] : [];
    allWeapons.sort((a, b) => weaponCategoryOrder(a.category) - weaponCategoryOrder(b.category) || String(a.name).localeCompare(String(b.name), "pt-BR"));
    const categories = ["Todas", ...new Set(allWeapons.map(item => item.category || "Outras"))]
        .sort((a, b) => a === "Todas" ? -1 : b === "Todas" ? 1 : weaponCategoryOrder(a) - weaponCategoryOrder(b));
    const selected = categories.includes(state.weaponCategory) ? state.weaponCategory : "Todas";
    state.weaponCategory = selected;
    const weapons = selected === "Todas" ? allWeapons : allWeapons.filter(item => (item.category || "Outras") === selected);

    const categoryButtons = categories.map(category => {
        const count = category === "Todas" ? allWeapons.length : allWeapons.filter(item => (item.category || "Outras") === category).length;
        return `<button type="button" class="weapon-category-button ${selected === category ? "is-active" : ""}" data-weapon-category="${escapeHtml(category)}"><span>${escapeHtml(category)}</span><b>${count}</b></button>`;
    }).join("");

    const cards = canUse("spawn_weapon") ? weapons.map(item => {
        const ammoText = item.ammo ? `${item.ammoName || item.ammo} • ${item.ammo}` : "Não utiliza munição";
        const localImage = weaponLocalImage(item.index);
        const remoteImage = itemImage(item.index);
        return `
            <button type="button" class="weapon-card" data-weapon-pull="${escapeHtml(item.index)}" data-weapon-name="${escapeHtml(item.name)}" data-weapon-ammo="${escapeHtml(item.ammo || "")}" data-search="${escapeHtml(`${item.name} ${item.index} ${item.category || ""} ${item.ammo || ""}`.toLowerCase())}">
                <div class="weapon-card-image">
                    <img class="lazy-catalog-image" data-src="${escapeHtml(localImage)}" data-remote-fallback="${escapeHtml(remoteImage)}" data-fallback="imgs/no-image.png" loading="lazy" decoding="async" alt="">
                </div>
                <div class="weapon-card-copy">
                    <div class="weapon-card-head"><strong>${escapeHtml(item.name)}</strong><span>${escapeHtml(item.category || "Outras")}</span></div>
                    <code>${escapeHtml(item.index)}</code>
                    <small>${icon("package", 12)} ${escapeHtml(ammoText)}</small>
                </div>
                <span class="weapon-card-action">${icon("weapon", 15)} Puxar</span>
            </button>`;
    }).join("") : "";

    return `
        <div class="weapons-page bounded-page">
            <div class="weapons-hero">
                <div class="weapons-hero-icon">${icon("weapon", 25)}</div>
                <div><span>ARSENAL DO SERVIDOR</span><strong>${allWeapons.length} armas disponíveis</strong><p>A arma é entregue como item no inventário junto da munição correspondente. Nada é equipado diretamente no ped.</p></div>
            </div>
            <div class="weapons-toolbar">
                <div class="search-box">${icon("search")}<input class="input" placeholder="Buscar arma pelo nome, spawn ou categoria..." data-filter-selector="#weaponCatalog [data-search]"></div>
            </div>
            <div class="weapon-category-strip">${categoryButtons}</div>
            <div id="weaponCatalog" class="weapon-grid scroll-list catalog-scroll">
                ${cards || `<div class="empty-state"><div><strong>${canUse("spawn_weapon") ? "Nenhuma arma encontrada" : "Arsenal bloqueado"}</strong><p>${canUse("spawn_weapon") ? "O inventário não retornou armas para esta categoria." : "Seu cargo não possui permissão para puxar armas."}</p></div></div>`}
            </div>
        </div>`;
}

function vipItemImage(index) {
    const base = state.vipAdmin?.images?.items || state.bootstrap?.vipAdmin?.images?.items || state.config.images?.items || "";
    return `${base}${encodeURIComponent(String(index || ""))}.png`;
}

function vipVehicleImage(spawn, images = null) {
    const base = images?.vehicles || state.vipAdmin?.images?.vehicles || state.bootstrap?.vipAdmin?.images?.vehicles || state.config.images?.vehicles || "";
    return `${base}${encodeURIComponent(String(spawn || "").toLowerCase())}.png`;
}

function vipMoney(value) {
    return `R$ ${Number(value || 0).toLocaleString("pt-BR")}`;
}

function vipGroupFromTitle(title) {
    let slug = String(title || "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().replace(/[^a-z0-9]+/g, "");
    return slug ? `vip_${slug}` : "";
}

async function refreshVipAdminData(silent = true) {
    const response = await post("vipAdmin", { mode: "list", silent });
    if (response?.ok && response.data) {
        state.vipAdmin = response.data;
        if (state.bootstrap) state.bootstrap.vipAdmin = response.data;
    }
    if (state.open && state.page === "vips") render();
    return response;
}

function renderVips() {
    const data = state.vipAdmin || state.bootstrap?.vipAdmin;
    if (!data) {
        return `<div class="vips-page bounded-page"><div class="empty-state"><div><strong>Carregando VIPs...</strong><p>Consultando os cargos com <code>gtype = vip</code> diretamente na vRP.</p></div></div></div>`;
    }

    const vips = Array.isArray(data.vips) ? data.vips : [];
    const cards = vips.map(vip => {
        const itemCount = Array.isArray(vip.items) ? vip.items.length : 0;
        const vehicleCount = Array.isArray(vip.vehicles) ? vip.vehicles.length : 0;
        const choices = Number(vip.vehicleChoices || 0);
        const garageSlots = Math.max(0, Number(vip.garageSlots || 0));
        const search = `${vip.title || ""} ${vip.group || ""} ${(vip.permissions || []).join(" ")}`.toLowerCase();
        return `
            <article class="vip-card" data-search="${escapeHtml(search)}">
                <button class="vip-card-main" type="button" data-vip-assign="${escapeHtml(vip.group)}">
                    <div class="vip-card-icon">${icon("star", 24)}</div>
                    <div class="vip-card-copy">
                        <div class="vip-card-title"><strong>${escapeHtml(vip.title || vip.group)}</strong><span>30 DIAS</span></div>
                        <code>${escapeHtml(vip.group)}</code>
                        <div class="vip-card-stats">
                            <span>${icon("wallet", 12)} ${escapeHtml(vipMoney(vip.salary))} salário</span>
                            <span>${icon("package", 12)} ${itemCount} item(ns)</span>
                            <span>${icon("car", 12)} ${vehicleCount} opção(ões) • escolhe ${choices}</span>
                            <span>${icon("car", 12)} +${garageSlots} vaga(s) na garagem</span>
                        </div>
                    </div>
                </button>
                <div class="vip-card-actions">
                    ${canUse("edit_vip") ? `<button class="vip-icon-button" type="button" data-vip-edit="${escapeHtml(vip.group)}" title="Editar VIP">${icon("edit", 15)}</button>` : ""}
                    ${canUse("delete_vip") ? `<button class="vip-icon-button danger" type="button" data-vip-delete="${escapeHtml(vip.group)}" title="Excluir VIP">${icon("trash", 15)}</button>` : ""}
                </div>
            </article>`;
    }).join("");

    return `
        <div class="vips-page bounded-page">
            <div class="vips-hero">
                <div class="vips-hero-copy"><span>GERENCIAMENTO DE BENEFÍCIOS</span><strong>VIPs do servidor</strong><p>Os cargos são gravados no mesmo <code>groups.json</code> utilizado pela vRP e pelo MG Config Panel. Todo VIP expira automaticamente após 30 dias.</p></div>
                ${canUse("create_vip") ? `<button class="button primary vip-create-button" type="button" data-vip-create>${icon("plus", 14)} CRIAR VIP</button>` : ""}
            </div>
            <div class="vips-toolbar">
                <div class="search-box">${icon("search", 16)}<input class="input" type="text" placeholder="Buscar VIP por nome, cargo ou permissão..." data-filter-selector="#vipCatalog [data-search]"></div>
                <button class="button" type="button" data-vip-refresh>${icon("refresh", 13)} Atualizar</button>
            </div>
            <div class="vips-summary">
                <div><span>VIPS DISPONÍVEIS</span><strong>${vips.length}</strong></div>
                <div><span>DURAÇÃO PADRÃO</span><strong>30 dias</strong></div>
                <p>Clique no VIP para setar em um jogador. Use o lápis para configurar salário, itens, veículos e vagas adicionais na garagem.</p>
            </div>
            <div id="vipCatalog" class="vip-grid scroll-list catalog-scroll">
                ${cards || `<div class="empty-state"><div><strong>Nenhum VIP encontrado</strong><p>Crie o primeiro VIP ou cadastre um cargo com <code>gtype = vip</code> no MG Config Panel.</p></div></div>`}
            </div>
        </div>`;
}

function vipDraftFrom(vip = null) {
    const title = String(vip?.title || "");
    return {
        originalGroup: vip?.group || "",
        group: vip?.group || vipGroupFromTitle(title),
        title,
        salary: Number(vip?.salary || 0),
        items: (vip?.items || []).map(item => ({ item: item.item, amount: Number(item.amount || 1) })),
        vehicles: (vip?.vehicles || []).map(vehicle => ({ spawn: vehicle.spawn, name: vehicle.name || vehicle.spawn, category: vehicle.category || "game" })),
        vehicleChoices: Number(vip?.vehicleChoices || ((vip?.vehicles || []).length ? 1 : 0)),
        garageSlots: Math.max(0, Number(vip?.garageSlots || 0))
    };
}

function vipDraftItemSummary() {
    if (!vipEditorDraft?.items?.length) return `<span class="vip-empty-selection">Nenhum item definido</span>`;
    return vipEditorDraft.items.map(item => {
        const catalog = (state.vipAdmin?.items || []).find(entry => entry.index === item.item);
        return `<span class="vip-selection-pill">${escapeHtml(catalog?.name || item.item)} <b>x${Number(item.amount || 1)}</b></span>`;
    }).join("");
}

function vipDraftVehicleSummary() {
    if (!vipEditorDraft?.vehicles?.length) return `<span class="vip-empty-selection">Nenhum veículo definido</span>`;
    return vipEditorDraft.vehicles.map(vehicle => `<span class="vip-selection-pill">${escapeHtml(vehicle.name || vehicle.spawn)}</span>`).join("");
}

function renderVipEditorModal() {
    if (!vipEditorDraft) return;
    const editing = Boolean(vipEditorDraft.originalGroup);
    const maxChoices = Math.max(0, vipEditorDraft.vehicles.length);
    if (maxChoices === 0) vipEditorDraft.vehicleChoices = 0;
    else vipEditorDraft.vehicleChoices = Math.max(1, Math.min(Number(vipEditorDraft.vehicleChoices || 1), maxChoices));

    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <form class="modal xlarge vip-editor-modal" id="vipEditorForm">
            <div class="modal-head">
                <div class="modal-title"><strong>${editing ? "EDITAR VIP" : "CRIAR VIP"}</strong><span>Configure o cargo, salário e todos os benefícios entregues ao jogador.</span></div>
                <button class="modal-close" type="button" data-modal-close>${icon("close",14)}</button>
            </div>
            <div class="modal-body vip-editor-body">
                <section class="vip-editor-general">
                    <div class="form-grid">
                        <div class="field"><label>Nome do VIP</label><input id="vipTitleInput" class="input" name="title" maxlength="80" value="${escapeHtml(vipEditorDraft.title)}" placeholder="Ex.: Diamante" required></div>
                        <div class="field"><label>Cargo na vRP</label><input id="vipGroupInput" class="input" name="group" maxlength="80" value="${escapeHtml(vipEditorDraft.group)}" placeholder="Ex.: vip_diamante" required ${editing ? "" : "data-vip-auto-group='1'"}></div>
                        <div class="field"><label>Salário</label><input class="input" name="salary" type="number" min="0" step="1" value="${Number(vipEditorDraft.salary || 0)}" required></div>
                        <div class="vip-duration-card"><span>${icon("clock",17)}</span><div><small>DURAÇÃO AUTOMÁTICA</small><strong>30 dias</strong><p>Ao vencer, a própria vRP remove o cargo automaticamente, inclusive após restart.</p></div></div>
                    </div>
                </section>

                <div class="vip-benefit-grid">
                    <section class="vip-benefit-card">
                        <div class="vip-benefit-head"><span class="vip-benefit-icon">${icon("package",20)}</span><div><strong>Itens do VIP</strong><p>Selecione quantos itens quiser e defina a quantidade individual de cada um.</p></div><button class="button" type="button" data-vip-open-items>${icon("edit",12)} Definir itens</button></div>
                        <div class="vip-selection-list">${vipDraftItemSummary()}</div>
                    </section>
                    <section class="vip-benefit-card">
                        <div class="vip-benefit-head"><span class="vip-benefit-icon">${icon("car",20)}</span><div><strong>Veículos para escolha</strong><p>Defina a lista exibida ao jogador. Ele poderá testar qualquer opção antes de escolher.</p></div><button class="button" type="button" data-vip-open-vehicles>${icon("edit",12)} Definir veículos</button></div>
                        <div class="vip-selection-list">${vipDraftVehicleSummary()}</div>
                        <div class="vip-choice-count-row">
                            <label>Quantos veículos o jogador poderá escolher?</label>
                            <input class="input" name="vehicleChoices" type="number" min="${maxChoices ? 1 : 0}" max="${maxChoices}" value="${vipEditorDraft.vehicleChoices}" ${maxChoices ? "" : "disabled"}>
                            <small>${maxChoices ? `Máximo: ${maxChoices} veículo(s) selecionado(s).` : "Selecione veículos para liberar esta opção."}</small>
                        </div>
                    </section>
                    <section class="vip-benefit-card vip-garage-slots-card">
                        <div class="vip-benefit-head">
                            <span class="vip-benefit-icon">${icon("car",20)}</span>
                            <div><strong>Vagas adicionais na garagem</strong><p>O jogador possui 5 vagas por padrão. Este valor é somado aos outros VIPs que ele tiver, de forma totalmente cumulativa.</p></div>
                            <div class="vip-garage-slots-input"><span>+</span><input class="input" name="garageSlots" type="number" min="0" max="1000" step="1" value="${Math.max(0, Number(vipEditorDraft.garageSlots || 0))}"><small>VAGAS</small></div>
                        </div>
                        <div class="vip-garage-example">Exemplo: Bronze +2 e Rubi +10 = <strong>17 veículos no total</strong> (5 padrão + 12 dos VIPs).</div>
                    </section>
                </div>
                <div class="vip-sync-note">${icon("shield",15)}<span>O cargo é salvo pela API dinâmica da própria vRP. Isso mantém o VIP sincronizado com o MG Config Panel e evita duas fontes diferentes de cargos/salários.</span></div>
            </div>
            <div class="modal-foot"><button class="button" type="button" data-modal-close>Cancelar</button><button class="button primary" type="submit">${icon("check",13)} ${editing ? "Salvar VIP" : "Criar VIP"}</button></div>
        </form>`;
    requestAnimationFrame(() => $("#vipTitleInput")?.focus());
}

function openVipEditorModal(group = null) {
    const vip = group ? (state.vipAdmin?.vips || []).find(entry => entry.group === group) : null;
    if (group && !vip) return;
    vipEditorDraft = vipDraftFrom(vip);
    renderVipEditorModal();
}

function renderVipItemsPicker() {
    if (!vipEditorDraft) return;
    const selected = new Map(vipEditorDraft.items.map(item => [item.item, Number(item.amount || 1)]));
    const cards = (state.vipAdmin?.items || []).map(item => {
        const amount = selected.get(item.index) || 1;
        const checked = selected.has(item.index);
        return `<article class="vip-picker-card ${checked ? "is-selected" : ""}" data-search="${escapeHtml(`${item.name} ${item.index}`.toLowerCase())}">
            <button type="button" class="vip-picker-select" data-vip-item-toggle="${escapeHtml(item.index)}">
                <img src="${escapeHtml(vipItemImage(item.index))}" onerror="this.onerror=null;this.src='imgs/no-image.png'" alt="">
                <div><strong>${escapeHtml(item.name)}</strong><code>${escapeHtml(item.index)}</code></div>
                <span class="vip-picker-check">${checked ? icon("check",13) : ""}</span>
            </button>
            <label class="vip-picker-amount ${checked ? "" : "is-disabled"}"><span>Qtd.</span><input class="input" type="number" min="1" max="100000" value="${amount}" data-vip-item-amount="${escapeHtml(item.index)}" ${checked ? "" : "disabled"}></label>
        </article>`;
    }).join("");
    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `<div class="modal xlarge vip-picker-modal"><div class="modal-head"><div class="modal-title"><strong>DEFINIR ITENS DO VIP</strong><span>Selecione vários itens e ajuste a quantidade de cada um.</span></div><button class="modal-close" type="button" data-vip-picker-back>${icon("close",14)}</button></div><div class="modal-body vip-picker-body"><div class="search-box">${icon("search",16)}<input class="input" placeholder="Buscar item por nome ou spawn..." data-filter-selector="#vipItemPicker [data-search]"></div><div id="vipItemPicker" class="vip-picker-grid scroll-list">${cards}</div></div><div class="modal-foot"><span class="vip-picker-selected-count">${selected.size} item(ns) selecionado(s)</span><button class="button primary" type="button" data-vip-picker-back>Concluir itens</button></div></div>`;
}

function renderVipVehiclesPicker() {
    if (!vipEditorDraft) return;
    const selected = new Set(vipEditorDraft.vehicles.map(item => String(item.spawn).toLowerCase()));
    const cards = (state.vipAdmin?.vehicles || []).map(vehicle => {
        const checked = selected.has(String(vehicle.spawn).toLowerCase());
        return `<button type="button" class="vip-vehicle-picker-card ${checked ? "is-selected" : ""}" data-vip-vehicle-toggle="${escapeHtml(vehicle.spawn)}" data-search="${escapeHtml(`${vehicle.name} ${vehicle.spawn} ${vehicle.category}`.toLowerCase())}">
            <div class="vip-vehicle-picker-image"><img src="${escapeHtml(vipVehicleImage(vehicle.spawn))}" onerror="this.style.opacity='.12'" alt=""></div>
            <div><strong>${escapeHtml(vehicle.name || vehicle.spawn)}</strong><code>${escapeHtml(vehicle.spawn)}</code><small>${vehicle.category === "addon" ? "Veículo addon" : "Veículo do jogo"}</small></div>
            <span class="vip-picker-check">${checked ? icon("check",13) : ""}</span>
        </button>`;
    }).join("");
    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `<div class="modal xlarge vip-picker-modal"><div class="modal-head"><div class="modal-title"><strong>VEÍCULOS DO VIP</strong><span>Escolha todos os veículos que poderão aparecer no modal do jogador.</span></div><button class="modal-close" type="button" data-vip-picker-back>${icon("close",14)}</button></div><div class="modal-body vip-picker-body"><div class="search-box">${icon("search",16)}<input class="input" placeholder="Buscar veículo por nome ou spawn..." data-filter-selector="#vipVehiclePicker [data-search]"></div><div id="vipVehiclePicker" class="vip-vehicle-picker-grid scroll-list">${cards}</div></div><div class="modal-foot"><span class="vip-picker-selected-count">${selected.size} veículo(s) selecionado(s)</span><button class="button primary" type="button" data-vip-picker-back>Concluir veículos</button></div></div>`;
}

function openVipAssignModal(group) {
    const vip = (state.vipAdmin?.vips || []).find(entry => entry.group === group);
    if (!vip) return;
    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `<form class="modal vip-assign-modal" id="vipAssignForm" data-vip-group="${escapeHtml(vip.group)}"><div class="modal-head"><div class="modal-title"><strong>SETAR VIP ${escapeHtml(String(vip.title || vip.group).toUpperCase())}</strong><span>O jogador receberá o cargo por 30 dias, os itens e a escolha de veículos configurada.</span></div><button class="modal-close" type="button" data-modal-close>${icon("close",14)}</button></div><div class="modal-body"><div class="vip-assign-summary"><div>${icon("star",22)}<span><small>VIP</small><strong>${escapeHtml(vip.title || vip.group)}</strong><code>${escapeHtml(vip.group)}</code></span></div><div><small>SALÁRIO</small><strong>${escapeHtml(vipMoney(vip.salary))}</strong></div><div><small>ITENS</small><strong>${(vip.items || []).length}</strong></div><div><small>VEÍCULOS</small><strong>Escolhe ${Number(vip.vehicleChoices || 0)}</strong></div><div><small>VAGAS EXTRAS</small><strong>+${Math.max(0, Number(vip.garageSlots || 0))}</strong></div></div><div class="field full"><label>Passaporte / ID do jogador</label><input class="input" name="targetId" type="number" min="1" placeholder="Ex.: 15" required autofocus></div>${Number(vip.vehicleChoices || 0) > 0 ? `<div class="vip-online-warning">${icon("alert",15)}<span>O jogador precisa estar <strong>online</strong>, pois a escolha dos veículos abrirá imediatamente na tela dele.</span></div>` : ""}</div><div class="modal-foot"><button class="button" type="button" data-modal-close>Cancelar</button><button class="button primary" type="submit">${icon("star",13)} Setar VIP por 30 dias</button></div></form>`;
}

function openVipDeleteModal(group) {
    const vip = (state.vipAdmin?.vips || []).find(entry => entry.group === group);
    if (!vip) return;
    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `<form class="modal" id="vipDeleteForm" data-vip-group="${escapeHtml(group)}"><div class="modal-head"><div class="modal-title"><strong>EXCLUIR VIP</strong><span>Esta operação também remove o cargo dos jogadores que o possuem.</span></div><button class="modal-close" type="button" data-modal-close>${icon("close",14)}</button></div><div class="modal-body"><div class="confirm-box">${icon("alert",15)}<span>Excluir permanentemente <strong>${escapeHtml(vip.title || group)}</strong> (<code>${escapeHtml(group)}</code>) do <code>groups.json</code> da vRP?</span></div></div><div class="modal-foot"><button class="button" type="button" data-modal-close>Cancelar</button><button class="button danger" type="submit">${icon("trash",12)} Excluir VIP</button></div></form>`;
}

function renderPlayerVipChoice(payload) {
    playerVipChoice = payload || null;
    if (!vipChoiceRoot) return;
    if (!payload || payload.completed || Number(payload.remainingChoices || 0) <= 0) {
        vipChoiceRoot.classList.remove("is-open");
        vipChoiceRoot.setAttribute("aria-hidden", "true");
        vipChoiceRoot.innerHTML = "";
        return;
    }
    const selected = new Set((payload.selectedVehicles || []).map(v => String(v).toLowerCase()));
    const cards = (payload.vehicles || []).map(vehicle => {
        const already = selected.has(String(vehicle.spawn).toLowerCase());
        return `<article class="player-vip-vehicle ${already ? "is-selected" : ""}"><div class="player-vip-image"><img src="${escapeHtml(vipVehicleImage(vehicle.spawn, payload.images))}" onerror="this.style.opacity='.15'" alt=""></div><div class="player-vip-copy"><strong>${escapeHtml(vehicle.name || vehicle.spawn)}</strong><code>${escapeHtml(vehicle.spawn)}</code>${already ? `<span class="player-vip-chosen">${icon("check",11)} JÁ ESCOLHIDO</span>` : ""}</div><div class="player-vip-actions"><button class="button" type="button" data-player-vip-test="${escapeHtml(vehicle.spawn)}" ${already ? "disabled" : ""}>${icon("car",12)} TESTAR VEÍCULO</button><button class="button primary" type="button" data-player-vip-choose="${escapeHtml(vehicle.spawn)}" ${already ? "disabled" : ""}>${icon("check",12)} ESCOLHER VEÍCULO</button></div></article>`;
    }).join("");
    const remaining = Number(payload.remainingChoices || 0);
    vipChoiceRoot.innerHTML = `<section class="player-vip-modal"><header><div class="player-vip-title-icon">${icon("star",24)}</div><div><small>BENEFÍCIO VIP</small><h2>ESCOLHA O VEÍCULO DO VIP ${escapeHtml(String(payload.title || "VIP").toUpperCase())}</h2><p>${remaining === 1 ? "Você pode escolher 1 veículo." : `Você pode escolher ${remaining} veículos.`} O teste é opcional: você pode escolher direto se quiser.</p></div><div class="player-vip-remaining"><span>RESTANTES</span><strong>${remaining}</strong></div></header>${payload.notice ? `<div class="player-vip-notice">${icon("check",14)} ${escapeHtml(payload.notice)}</div>` : ""}<div class="player-vip-grid">${cards}</div><footer>${icon("shield",13)} O teste acontece em uma dimensão privada durante 60 segundos e não confirma sua escolha.</footer></section>`;
    vipChoiceRoot.classList.add("is-open");
    vipChoiceRoot.setAttribute("aria-hidden", "false");
}

function renderVipTestOverlay(data) {
    if (!vipTestOverlay) return;
    const session = Math.max(0, Number(data?.session || 0));

    if (!data?.active) {
        if (session > 0) {
            vipTestOverlaySession = Math.max(vipTestOverlaySession, session);
            vipTestOverlayClosedSession = Math.max(vipTestOverlayClosedSession, session);
        } else if (vipTestOverlaySession > 0) {
            vipTestOverlayClosedSession = Math.max(vipTestOverlayClosedSession, vipTestOverlaySession);
        }
        vipTestOverlay.classList.remove("is-open");
        vipTestOverlay.setAttribute("aria-hidden", "true");
        vipTestOverlay.innerHTML = "";
        return;
    }

    // Um update de contagem pode chegar alguns ms depois do encerramento do
    // teste. Se a sessão já foi fechada, ele é descartado e não reabre a HUD.
    if (session > 0 && session <= vipTestOverlayClosedSession) return;
    if (session > 0) vipTestOverlaySession = Math.max(vipTestOverlaySession, session);

    vipTestOverlay.innerHTML = `<div class="vip-test-box"><span class="vip-test-icon">${icon("car",18)}</span><div><strong>Teste o veículo à vontade!</strong><p>Restam <b>${Math.max(0, Number(data.seconds || 0))} segundos</b> - pressione <kbd>F7</kbd> para sair</p></div></div>`;
    vipTestOverlay.classList.add("is-open");
    vipTestOverlay.setAttribute("aria-hidden", "false");
}

function renderVehicles() {
    const allVehicles = Array.isArray(state.config.vehicles) ? state.config.vehicles : [];
    const category = state.vehicleCategory === "addon" ? "addon" : "game";
    const vehicles = allVehicles.filter(vehicle => (vehicle.category === "addon" ? "addon" : "game") === category);

    const cards = vehicles.map(v => `
        <div class="vehicle-card" data-search="${escapeHtml(`${v.name} ${v.spawn}`.toLowerCase())}">
            <div class="thumb">
                <img class="lazy-catalog-image" data-src="${escapeHtml(vehicleImage(v.spawn))}" loading="lazy" decoding="async" alt="">
            </div>
            <div class="vehicle-body">
                <strong>${escapeHtml(v.name)}</strong>
                <span>${escapeHtml(v.spawn)}</span>
                <div class="vehicle-actions">
                    ${canUse("spawn_veh") ? `<button class="button small primary" data-vehicle-action="spawn" data-vehicle="${escapeHtml(v.spawn)}">${icon("car", 11)} Spawn</button>` : ""}
                    ${canUse("give_veh") ? `<button class="button small success" data-vehicle-action="give" data-vehicle="${escapeHtml(v.spawn)}">${icon("plus", 11)} Dar</button>` : ""}
                    ${canUse("rem_veh") ? `<button class="button small danger" data-vehicle-action="remove" data-vehicle="${escapeHtml(v.spawn)}">${icon("minus", 11)} Remover</button>` : ""}
                </div>
            </div>
        </div>
    `).join("");

    return `
        <div class="catalog-page bounded-page vehicle-page">
            <div class="server-actions vehicle-top-actions catalog-actions-fixed">
                ${actionCard("spawn_veh", "Spawn manual por nome.")}
                ${vehicleGarageActionCard("give")}
                ${vehicleGarageActionCard("remove")}
                ${actionCard("fix", "Reparar veículo atual/próximo.")}
                ${actionCard("tuning", "Aplicar tuning máximo.")}
                ${actionCard("dv", "Deletar veículo atual/próximo.")}
            </div>

            <div class="toolbar">
                <div class="search-box">
                    ${icon("search")}
                    <input class="input" placeholder="Buscar veículo pelo nome ou spawn..." data-filter-selector="#vehicleCatalog [data-search]">
                </div>
                ${(canUse("give_veh") || canUse("rem_veh")) ? `<div class="compact-field" style="width:180px">
                    <input id="vehicleTarget" class="input" type="number" min="1" value="${state.selectedPlayerId || ""}" placeholder="ID para garagem">
                </div>` : ""}
            </div>

            <div class="vehicle-catalog-header">
                <div class="vehicle-category-tabs">
                    <button type="button" class="vehicle-category-tab ${category === "game" ? "is-active" : ""}" data-vehicle-category="game">
                        ${icon("car", 13)}
                        <span>Veículos do jogo</span>
                    </button>
                    <button type="button" class="vehicle-category-tab ${category === "addon" ? "is-active" : ""}" data-vehicle-category="addon">
                        ${icon("plus", 13)}
                        <span>Veículos addon</span>
                    </button>
                </div>
                ${canUse("add_vehicle_catalog") ? `
                    <button type="button" class="button primary vehicle-add-button" data-add-vehicle-catalog>
                        ${icon("plus", 12)} Adicionar veículo
                    </button>
                ` : ""}
            </div>

            <div id="vehicleCatalog" class="vehicle-grid scroll-list catalog-scroll">
                ${cards || `<div class="empty-state vehicle-empty-state"><div><strong>Nenhum veículo nesta categoria</strong><p>${category === "addon" ? "Cadastre um veículo do servidor pelo botão Adicionar veículo." : "Nenhum veículo do jogo foi cadastrado."}</p></div></div>`}
            </div>
        </div>
    `;
}

function locationCategories() {
    const configured = Array.isArray(state.config.locationCategories) ? state.config.locationCategories : [];
    const fromLocations = (state.config.locations || []).map(location => String(location.category || "Geral").trim()).filter(Boolean);
    const seen = new Set();
    return [...configured, ...fromLocations, "Geral"]
        .map(category => String(category || "").trim())
        .filter(category => {
            const key = category.toLocaleLowerCase("pt-BR");
            if (!category || seen.has(key)) return false;
            seen.add(key);
            return true;
        })
        .sort((a, b) => a.localeCompare(b, "pt-BR", { sensitivity: "base" }));
}

function renderLocations() {
    const locations = state.config.locations || [];
    const categories = locationCategories();
    const selectedCategory = state.locationCategory && categories.find(category => category.toLocaleLowerCase("pt-BR") === String(state.locationCategory).toLocaleLowerCase("pt-BR"));

    if (!selectedCategory) {
        state.locationCategory = null;
        const categoryCards = categories.map(category => {
            const total = locations.filter(location => String(location.category || "Geral").toLocaleLowerCase("pt-BR") === category.toLocaleLowerCase("pt-BR")).length;
            return `
                <button class="location-category-card" type="button" data-location-category="${escapeHtml(category)}" data-search="${escapeHtml(category.toLowerCase())}">
                    <span class="location-category-icon">${icon("map", 20)}</span>
                    <span class="location-category-copy">
                        <strong>${escapeHtml(category)}</strong>
                        <small>${total} ${total === 1 ? "local cadastrado" : "locais cadastrados"}</small>
                    </span>
                    <span class="location-category-arrow">${icon("arrow", 15)}</span>
                </button>
            `;
        }).join("");

        return `
            <div class="locations-page bounded-page location-categories-page">
                <div class="locations-toolbar">
                    <div class="search-box">
                        ${icon("search")}
                        <input class="input" placeholder="Buscar categoria..." data-filter-selector="#locationCategoryCatalog [data-search]">
                    </div>
                    ${canUse("add_location") ? `<button class="button add-location-category-button" type="button" data-add-location-category>${icon("plus", 12)} NOVA CATEGORIA</button>` : ""}
                    ${canUse("add_location") ? `<button class="button primary add-location-button" type="button" data-add-location>${icon("plus", 12)} ADD LOCAL</button>` : ""}
                </div>

                <div id="locationCategoryCatalog" class="location-category-grid scroll-list catalog-scroll">
                    ${categoryCards || `<div class="empty-state location-empty"><div><div class="empty-icon">${icon("map")}</div><strong>Nenhuma categoria cadastrada</strong><p>Crie uma categoria para organizar seus locais administrativos.</p></div></div>`}
                </div>
            </div>
        `;
    }

    const categoryLocations = locations.filter(location => String(location.category || "Geral").toLocaleLowerCase("pt-BR") === selectedCategory.toLocaleLowerCase("pt-BR"));
    const cards = categoryLocations.map(location => `
        <article class="location-card" data-search="${escapeHtml(`${location.name} ${location.x} ${location.y} ${location.z}`.toLowerCase())}">
            <div class="location-top">
                <span class="location-icon">${icon("pin", 15)}</span>
                <span class="type-pill">#${location.index}</span>
            </div>
            <h4>${escapeHtml(location.name)}</h4>
            <span class="location-category-tag">${escapeHtml(selectedCategory)}</span>
            <p>${Number(location.x).toFixed(2)}, ${Number(location.y).toFixed(2)}, ${Number(location.z).toFixed(2)}</p>
            <div class="location-actions">
                ${canUse("teleport_location") ? `<button class="button small primary" type="button" data-location="${location.index}">${icon("target", 11)} Teleportar</button>` : ""}
                ${canUse("remove_location") ? `<button class="button small danger location-delete-button" type="button" data-delete-location="${location.index}">${icon("trash", 11)} Apagar</button>` : ""}
            </div>
        </article>
    `).join("");

    return `
        <div class="locations-page bounded-page location-category-detail-page">
            <div class="locations-category-header">
                <button class="button location-back-button" type="button" data-location-category-back>${icon("arrow", 12)} Voltar</button>
                <div class="locations-category-title">
                    <span>Categoria</span>
                    <strong>${escapeHtml(selectedCategory)}</strong>
                    <small>${categoryLocations.length} ${categoryLocations.length === 1 ? "local" : "locais"}</small>
                </div>
            </div>
            <div class="locations-toolbar">
                <div class="search-box">
                    ${icon("search")}
                    <input class="input" placeholder="Buscar em ${escapeHtml(selectedCategory)}..." data-filter-selector="#locationCatalog [data-search]">
                </div>
                ${canUse("add_location") ? `<button class="button primary add-location-button" type="button" data-add-location>${icon("plus", 12)} ADD LOCAL</button>` : ""}
            </div>

            <div id="locationCatalog" class="location-grid scroll-list catalog-scroll">
                ${cards || `<div class="empty-state location-empty"><div><div class="empty-icon">${icon("pin")}</div><strong>Nenhum local nesta categoria</strong><p>Use ADD LOCAL para cadastrar um ponto em ${escapeHtml(selectedCategory)}.</p></div></div>`}
            </div>
        </div>
    `;
}

function environmentTimeValue(env) {
    return ((Number(env?.hour || 0) * 60) + Number(env?.minute || 0)) % 1440;
}

function formatGameTime(value) {
    const total = Math.max(0, Math.min(1439, Number(value) || 0));
    const hour = Math.floor(total / 60);
    const minute = Math.floor(total % 60);
    return `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`;
}

function envToggle(label, description, enabled, action, iconName) {
    return `
        <button class="environment-toggle ${enabled ? "is-on" : ""}" type="button" data-env-toggle="${action}">
            <span class="environment-toggle-icon">${icon(iconName || "activity", 20)}</span>
            <span class="environment-toggle-copy">
                <strong>${escapeHtml(label)}</strong>
                <small>${escapeHtml(description)}</small>
            </span>
            <span class="toggle-switch"><i></i></span>
        </button>
    `;
}


function radioPermissionText(permissions) {
    const list = Array.isArray(permissions) ? permissions.filter(Boolean) : [];
    return list.length ? list.join(" • ") : "Sem permissão configurada";
}

async function refreshRadioAdminData(silent = true) {
    const response = await post("radioAdmin", { mode: "list", silent });
    if (response?.data) state.radioAdmin = response.data;
    else if (!state.radioAdmin) state.radioAdmin = { available: false, radios: [] };
    if (state.open && state.page === "radio") render();
    return response;
}

function renderRadio() {
    const data = state.radioAdmin || state.bootstrap?.radioAdmin;
    if (!data) {
        return `<div class="radio-page bounded-page"><div class="empty-state"><div><strong>Carregando rádios privadas...</strong><p>Aguarde enquanto o painel consulta o resource radio.</p></div></div></div>`;
    }

    if (data.available !== true) {
        return `<div class="radio-page bounded-page"><section class="radio-unavailable">${icon("alert", 24)}<div><strong>Resource de rádio indisponível</strong><p>${escapeHtml(data.message || "Inicie o resource radio e tente novamente.")}</p></div><button class="button" type="button" data-radio-refresh>${icon("refresh", 13)} Tentar novamente</button></section></div>`;
    }

    const radios = Array.isArray(data.radios) ? data.radios : [];
    const rows = radios.map(radio => {
        const enabled = radio.enabled !== false;
        const search = `${radio.name || ""} ${radio.channel || ""} ${radioPermissionText(radio.permissions)}`.toLowerCase();
        return `
            <article class="radio-card" data-search="${escapeHtml(search)}">
                <div class="radio-card-frequency"><span>${icon("radio", 22)}</span><strong>${Number(radio.channel || 0)}</strong><small>FREQUÊNCIA</small></div>
                <div class="radio-card-main">
                    <div class="radio-card-title"><strong>${escapeHtml(radio.name || "Rádio privada")}</strong><span class="radio-status ${enabled ? "active" : "inactive"}">${enabled ? "ATIVA" : "INATIVA"}</span></div>
                    <span class="radio-permissions-label">PERMISSÕES DE ACESSO</span>
                    <p>${escapeHtml(radioPermissionText(radio.permissions))}</p>
                </div>
                ${canUse("radio_manage") ? `<div class="radio-card-actions"><button type="button" class="button small" data-radio-edit="${Number(radio.id)}">${icon("edit",12)} Editar</button><button type="button" class="button small danger" data-radio-delete="${Number(radio.id)}">${icon("trash",12)} Excluir</button></div>` : ""}
            </article>`;
    }).join("");

    return `
        <div class="radio-page bounded-page">
            <div class="radio-toolbar">
                <div class="search-box">${icon("search", 17)}<input class="input" type="text" placeholder="Buscar por nome, frequência ou permissão..." data-filter-selector="#radioList [data-search]"></div>
                <button type="button" class="button" data-radio-refresh>${icon("refresh",13)} Atualizar</button>
                ${canUse("radio_manage") ? `<button type="button" class="button primary" data-radio-add>${icon("plus",13)} Nova rádio privada</button>` : ""}
            </div>
            <div class="radio-summary"><div><span>RÁDIOS PRIVADAS</span><strong>${radios.length}</strong></div><p>Alterações são salvas em <code>private_radios.json</code> e aplicadas sem reiniciar o rádio ou o voice.</p></div>
            <div id="radioList" class="radio-list scroll-list">${rows || `<div class="empty-state"><div><strong>Nenhuma rádio privada cadastrada</strong><p>Crie uma frequência e defina quais permissões poderão acessá-la.</p></div></div>`}</div>
        </div>`;
}

function openRadioEditorModal(id = null) {
    if (!canUse("radio_manage")) return;
    const radios = state.radioAdmin?.radios || state.bootstrap?.radioAdmin?.radios || [];
    const current = id ? radios.find(item => Number(item.id) === Number(id)) : null;
    const permissions = Array.isArray(current?.permissions) ? current.permissions.join(", ") : "";
    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <form class="modal radio-editor-modal" id="radioEditorForm" data-radio-id="${current ? Number(current.id) : ""}">
            <div class="modal-head"><div class="modal-title"><strong>${current ? "Editar rádio privada" : "Nova rádio privada"}</strong><span>Nome, frequência e permissões são aplicados em tempo real para todos os jogadores.</span></div><button class="modal-close" type="button" data-modal-close>${icon("close",14)}</button></div>
            <div class="modal-body">
                <div class="field-grid">
                    <div class="field"><label>Nome da rádio</label><input class="input" name="name" maxlength="60" value="${escapeHtml(current?.name || "")}" placeholder="Ex.: Polícia" required></div>
                    <div class="field"><label>Frequência</label><input class="input" name="channel" type="number" min="1" max="9999" step="1" value="${escapeHtml(current?.channel || "")}" placeholder="Ex.: 190" required></div>
                    <div class="field full"><label>Permissões</label><input class="input" name="permissions" maxlength="700" value="${escapeHtml(permissions)}" placeholder="Ex.: perm.policia, perm.countpolicia" required><small>Separe múltiplas permissões por vírgula. O jogador precisa possuir pelo menos uma delas.</small></div>
                </div>
                <label class="radio-enabled-control"><input type="checkbox" name="enabled" ${current?.enabled === false ? "" : "checked"}><span class="radio-enabled-switch"></span><div><strong>Rádio privada ativa</strong><small>Desativar remove a restrição desta frequência até você ativá-la novamente.</small></div></label>
                <div class="radio-editor-note">${icon("shield",16)}<span>A validação também acontece no servidor do pma-voice. Alterar a permissão remove automaticamente da frequência quem deixar de ter acesso.</span></div>
            </div>
            <div class="modal-foot"><button class="button" type="button" data-modal-close>Cancelar</button><button class="button primary" type="submit">${icon("check",12)} ${current ? "Salvar alterações" : "Criar rádio"}</button></div>
        </form>`;
    requestAnimationFrame(() => $("#radioEditorForm [name='name']")?.focus());
}

function openRadioDeleteModal(id) {
    if (!canUse("radio_manage")) return;
    const radios = state.radioAdmin?.radios || [];
    const radio = radios.find(item => Number(item.id) === Number(id));
    if (!radio) return;
    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <form class="modal" id="radioDeleteForm" data-radio-id="${Number(radio.id)}">
            <div class="modal-head"><div class="modal-title"><strong>Excluir rádio privada</strong><span>A frequência deixará de ser restrita pelo sistema.</span></div><button class="modal-close" type="button" data-modal-close>${icon("close",14)}</button></div>
            <div class="modal-body"><div class="confirm-box">${icon("alert",16)}<span>Excluir <strong>${escapeHtml(radio.name)}</strong> da frequência <strong>${Number(radio.channel)}</strong>? Jogadores conectados nela serão removidos antes da frequência deixar de ser privada.</span></div></div>
            <div class="modal-foot"><button class="button" type="button" data-modal-close>Cancelar</button><button class="button danger" type="submit">${icon("trash",12)} Excluir rádio</button></div>
        </form>`;
}

function renderClimate() {
    const env = state.environment || state.bootstrap?.environment || {
        weather: "CLEAR", weatherFrozen: true, rotating: false,
        hour: 12, minute: 0, timeFrozen: false
    };
    const weatherTypes = state.config.weather?.types || [];
    const current = String(env.weather || "CLEAR").toUpperCase();
    const timeValue = environmentTimeValue(env);

    const cards = canUse("weather_manage") ? weatherTypes.map(weather => {
        const name = String(weather.name || "").toUpperCase();
        const active = name === current;
        return `
            <button class="weather-card ${active ? "is-active" : ""}" type="button" data-weather="${escapeHtml(name)}">
                <span class="weather-card-icon">${icon(name.includes("RAIN") || name === "THUNDER" ? "cloud" : name.includes("SNOW") || name === "XMAS" ? "snow" : "sparkles", 22)}</span>
                <span class="weather-card-copy">
                    <strong>${escapeHtml(weather.label || name)}</strong>
                    <small>${escapeHtml(name)}</small>
                </span>
                ${active ? '<span class="weather-active-badge">ATUAL</span>' : ''}
            </button>
        `;
    }).join("") : "";

    const weatherSection = canUse("weather_manage") ? `
                <article class="section-card climate-weather-section">
                    <div class="section-head climate-section-head">
                        <div class="section-title">
                            <strong>Clima do servidor</strong>
                            <span>Selecione um clima ou ative a rotação automática.</span>
                        </div>
                        <div class="current-weather-pill">
                            <span class="pulse-dot"></span>
                            <div><small>CLIMA ATUAL</small><strong id="environmentWeatherName">${escapeHtml(current)}</strong></div>
                        </div>
                    </div>
                    <div class="climate-control-row">
                        ${envToggle("Congelar clima", "Mantém o clima selecionado fixo para todos.", Boolean(env.weatherFrozen), "freezeWeather", "snow")}
                        ${envToggle("Clima rotativo", "Alterna naturalmente entre climas comuns.", Boolean(env.rotating), "rotating", "refresh")}
                    </div>
                    <div id="weatherCatalog" class="weather-grid scroll-list">${cards}</div>
                </article>` : "";

    const timeSection = canUse("time_manage") ? `
                <article class="section-card climate-time-section">
                    <div class="section-head climate-section-head">
                        <div class="section-title">
                            <strong>Horário do servidor</strong>
                            <span>Arraste a barra para definir a hora global.</span>
                        </div>
                    </div>
                    <div class="time-control-body">
                        <div class="game-time-display" id="environmentTimeDisplay">${formatGameTime(timeValue)}</div>
                        <div class="time-slider-wrap">
                            <input id="environmentTimeRange" class="time-slider" type="range" min="0" max="1439" step="1" value="${timeValue}">
                            <div class="time-marks"><span>00:00</span><span>06:00</span><span>12:00</span><span>18:00</span><span>23:59</span></div>
                        </div>
                        ${envToggle("Congelar horário", "Pausa o relógio exatamente no horário escolhido.", Boolean(env.timeFrozen), "freezeTime", "clock")}
                        <div class="time-status-card">
                            <span>${icon("clock", 20)}</span>
                            <div><small>STATUS DO RELÓGIO</small><strong>${env.timeFrozen ? "CONGELADO" : "EM MOVIMENTO"}</strong></div>
                        </div>
                    </div>
                </article>` : "";

    return `
        <div class="climate-page bounded-page">
            <div class="climate-layout">
                ${weatherSection}
                ${timeSection}
                ${!weatherSection && !timeSection ? `<div class="empty-state"><div><strong>Sem permissões de ambiente</strong><p>Você não possui nenhuma função de clima ou horário liberada.</p></div></div>` : ""}
            </div>
        </div>
    `;
}

function updateEnvironmentTimeDom() {
    if (state.page !== "climate" || !state.environment) return;
    const range = $("#environmentTimeRange");

    // Enquanto o ADM está mexendo na barra, não deixa o sync do servidor
    // sobrescrever visualmente o valor que está sendo escolhido.
    if (range && document.activeElement === range) return;

    const value = environmentTimeValue(state.environment);
    const display = $("#environmentTimeDisplay");
    if (display) display.textContent = formatGameTime(value);
    if (range) range.value = String(value);
}

function applyEnvironmentTimePreview(minuteOfDay) {
    const value = Math.max(0, Math.min(1439, Math.floor(Number(minuteOfDay) || 0)));
    const display = $("#environmentTimeDisplay");
    if (display) display.textContent = formatGameTime(value);

    state.environment = state.environment || {};
    state.environment.hour = Math.floor(value / 60);
    state.environment.minute = value % 60;
    return value;
}

async function sendEnvironmentTime(minuteOfDay, showError = false, live = false) {
    const value = Math.max(0, Math.min(1439, Math.floor(Number(minuteOfDay) || 0)));
    const serial = ++environmentTimeRequestSerial;
    const response = await post("environment", { action: "setTime", minuteOfDay: value, live });

    if (!response?.ok) {
        if (showError && serial === environmentTimeRequestSerial) {
            toast("error", "Horário", response?.message || "Não foi possível alterar o horário.");
        }
        return false;
    }

    // Não chama render(): recriar a tela durante o drag faria o range perder
    // foco e causaria a sensação de slider travando.
    if (serial === environmentTimeRequestSerial && response.data) {
        state.environment = response.data;
    }
    return true;
}

function scheduleEnvironmentTime(minuteOfDay) {
    environmentTimePendingValue = applyEnvironmentTimePreview(minuteOfDay);
    if (environmentTimeSendTimer) return;

    environmentTimeSendTimer = setTimeout(async () => {
        environmentTimeSendTimer = null;
        const value = environmentTimePendingValue;
        environmentTimePendingValue = null;
        await sendEnvironmentTime(value, false, true);
    }, 120);
}

async function commitEnvironmentTime(minuteOfDay) {
    const value = applyEnvironmentTimePreview(minuteOfDay);
    environmentTimePendingValue = null;
    if (environmentTimeSendTimer) {
        clearTimeout(environmentTimeSendTimer);
        environmentTimeSendTimer = null;
    }
    await sendEnvironmentTime(value, true, false);
}

async function updateEnvironment(payload) {
    const response = await post("environment", payload);
    if (!response?.ok) {
        toast("error", "Clima", response?.message || "Não foi possível atualizar o ambiente.");
        return false;
    }
    state.environment = response.data || state.environment;
    toast("success", "Ambiente atualizado", response.message || "Alteração aplicada para todos.");
    render();
    return true;
}

function serverActionGrid(actions) {
    const cards = actions.map(action => actionCard(action)).filter(Boolean);
    return cards.length ? `<div class="server-actions">${cards.join("")}</div>` : "";
}

function serverCategory(title, description, actions) {
    const grid = serverActionGrid(actions);
    if (!grid) return "";
    return `
        <article class="section-card server-category-card">
            <div class="section-head">
                <div class="section-title">
                    <strong>${escapeHtml(title)}</strong>
                    <span>${escapeHtml(description)}</span>
                </div>
            </div>
            <div class="section-body">${grid}</div>
        </article>
    `;
}

function permissionManagerBanner() {
    if (!canManagePanelPermissions()) return "";
    return `
        <button type="button" class="panel-permissions-banner" data-open-panel-permissions>
            <span class="panel-permissions-banner-icon">${icon("shield", 25)}</span>
            <span class="panel-permissions-banner-copy">
                <small>CONTROLE DE ACESSO</small>
                <strong>Permissões do Painel</strong>
                <span>Defina exatamente quais funções Admin, Moderador e Suporte podem visualizar e utilizar.</span>
            </span>
            <span class="panel-permissions-banner-action">Gerenciar ${icon("arrow", 15)}</span>
        </button>
    `;
}

function banHistoryBanner() {
    if (!canUse("ban_history")) return "";
    return `
        <button type="button" class="ban-history-banner" data-open-ban-history>
            <span class="ban-history-banner-icon">${icon("archive", 25)}</span>
            <span class="ban-history-banner-copy">
                <small>HISTÓRICO DE MODERAÇÃO</small>
                <strong>Registros de ban e unban</strong>
                <span>Consulte quem baniu ou desbaniu, o jogador envolvido, IDs, data, hora e o motivo informado.</span>
            </span>
            <span class="ban-history-banner-action">Ver registros ${icon("arrow", 15)}</span>
        </button>
    `;
}

function banHistoryEntryHtml(entry) {
    const isBan = String(entry?.action || "") === "ban";
    const actor = entry?.actor || {};
    const target = entry?.target || {};
    const reason = String(entry?.reason || "Sem motivo informado");
    const search = `${isBan ? "ban banimento" : "unban desbanimento"} ${actor.name || ""} ${actor.id || ""} ${target.name || ""} ${target.id || ""} ${reason}`.toLowerCase();

    return `
        <article class="ban-history-entry" data-search="${escapeHtml(search)}">
            <div class="ban-history-entry-head">
                <span class="ban-history-status ${isBan ? "is-ban" : "is-unban"}">${isBan ? icon("ban", 15) : icon("check", 15)} ${isBan ? "BANIMENTO" : "DESBANIMENTO"}</span>
                <span class="ban-history-date">${escapeHtml(entry?.date || "-")} • ${escapeHtml(entry?.time || "-")}</span>
            </div>
            <div class="ban-history-entry-grid">
                <div class="ban-history-person">
                    <span>RESPONSÁVEL</span>
                    <strong>${escapeHtml(actor.name || "Sem identidade")}</strong>
                    <small>ID #${escapeHtml(actor.id || "-")}</small>
                </div>
                <div class="ban-history-person">
                    <span>JOGADOR</span>
                    <strong>${escapeHtml(target.name || "Sem identidade")}</strong>
                    <small>ID #${escapeHtml(target.id || "-")}</small>
                </div>
                <div class="ban-history-reason">
                    <span>MOTIVO</span>
                    <p>${escapeHtml(reason)}</p>
                </div>
            </div>
        </article>
    `;
}

async function openBanHistoryModal() {
    if (!canUse("ban_history")) return;

    const response = await post("banHistory", {});
    if (!response?.ok) {
        toast("error", "Registros de ban e unban", response?.message || "Não foi possível carregar os registros.");
        return;
    }

    const entries = Array.isArray(response.data?.entries) ? response.data.entries : [];
    const rows = entries.map(banHistoryEntryHtml).join("");

    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <div class="modal xlarge fixed-modal ban-history-modal">
            <div class="modal-head ban-history-modal-head">
                <div class="modal-title">
                    <strong>Registros de ban e unban</strong>
                    <span>${entries.length} registro${entries.length === 1 ? "" : "s"} armazenado${entries.length === 1 ? "" : "s"}.</span>
                </div>
                <button class="modal-close" type="button" data-modal-close>${icon("close", 17)}</button>
            </div>
            <div class="modal-body ban-history-modal-body">
                <div class="search-box ban-history-search">
                    ${icon("search", 18)}
                    <input class="input" type="text" placeholder="Buscar por nome, ID, motivo, ban ou unban..." data-filter-selector="#banHistoryList [data-search]">
                </div>
                <div id="banHistoryList" class="ban-history-list scroll-list">
                    ${rows || `<div class="empty-state"><div><strong>Nenhum registro ainda</strong><p>Os próximos bans e desbans feitos pelo painel aparecerão aqui.</p></div></div>`}
                </div>
            </div>
            <div class="modal-foot">
                <button class="button primary" type="button" data-modal-close>Fechar</button>
            </div>
        </div>
    `;

    requestAnimationFrame(() => modalRoot.querySelector(".ban-history-search input")?.focus());
}

function renderServer() {
    const generalActions = [
        "wladd", "wlrem", "ban", "unban", "catch_rg",
        "send_adm", "givemoney", "remove_money", "send_dm", "warning",
        "tpway", "tpcds", "hash", "fix",
        "godall", "clear_allveh", "clear_props", "dv", "wipe_user_data"
    ];

    const generalGrid = serverActionGrid(generalActions);
    const topTools = [permissionManagerBanner(), banHistoryBanner()].filter(Boolean).join("");

    return `
        <div class="server-home bounded-page">
            ${topTools ? `<div class="server-top-tools">${topTools}</div>` : ""}
            <div class="server-command-area">
                ${generalGrid ? `
                    <article class="section-card server-category-card server-general-card">
                        <div class="section-head">
                            <div class="section-title">
                                <strong>COMANDOS ADM GERAIS</strong>
                                <span>Todas as ações administrativas disponíveis reunidas em um único lugar.</span>
                            </div>
                        </div>
                        <div class="section-body">${generalGrid}</div>
                    </article>
                ` : `<div class="empty-state"><div><strong>Nenhuma função disponível</strong><p>Seu cargo não possui ações liberadas nesta aba.</p></div></div>`}
            </div>
        </div>
    `;
}

function liveMapConfig() {
    const cfg = state.config?.liveMap || {};
    return {
        updateIntervalMs: Math.max(1000, Number(cfg.updateIntervalMs || 5000)),
        // Transformação CRS usada pelos mapas Atlas/Leaflet de GTA V.
        // pixelNormX = (scaleX * worldX + centerX) / 256
        // pixelNormY = (-scaleY * worldY + centerY) / 256
        crsCenterX: Number(cfg.crsCenterX ?? 117.3),
        crsCenterY: Number(cfg.crsCenterY ?? 172.8),
        crsScaleX: Number(cfg.crsScaleX ?? 0.02072),
        crsScaleY: Number(cfg.crsScaleY ?? 0.0205),
        mapPreviewUrl: String(cfg.mapPreviewUrl || "imgs/gta-map-preview.jpg?v=237"),
        mapImageUrl: String(cfg.mapImageUrl || "https://www.bragitoff.com/wp-content/uploads/2015/11/GTAV-HD-MAP-roadmap.jpg"),
        mapFallbackUrl: String(cfg.mapFallbackUrl || "imgs/gta-map-sharp.png?v=237"),
        minScale: Math.max(0.35, Number(cfg.minScale || 0.55)),
        maxScale: Math.max(2, Number(cfg.maxScale || 6))
    };
}

function mapPoint(player) {
    const cfg = liveMapConfig();
    const worldX = Number(player.x);
    const worldY = Number(player.y);
    if (!Number.isFinite(worldX) || !Number.isFinite(worldY) || player.hasPosition === false) {
        return { valid: false, x: 0, y: 0, left: "0%", top: "0%" };
    }

    // Conversão exata do CRS do GTA V usado pelos mapas Leaflet/Atlas.
    // Diferente da aproximação antiga, não há clamp: coordenadas fora do mapa
    // são simplesmente ignoradas em vez de prender o marcador nas bordas.
    const normalizedX = (cfg.crsScaleX * worldX + cfg.crsCenterX) / 256;
    const normalizedY = (-cfg.crsScaleY * worldY + cfg.crsCenterY) / 256;
    const valid = normalizedX >= 0 && normalizedX <= 1 && normalizedY >= 0 && normalizedY <= 1;

    return {
        valid,
        x: normalizedX,
        y: normalizedY,
        left: `${(normalizedX * 100).toFixed(5)}%`,
        top: `${(normalizedY * 100).toFixed(5)}%`
    };
}


function renderIdentityEditor() {
    const p = state.identityEditor;
    const hasLoadedPlayer = Boolean(p?.id);

    if (!hasLoadedPlayer) {
        return `
            <div class="identity-editor-page setagem-awaiting bounded-page">
                <div class="setagem-welcome identity-welcome">
                    <span class="setagem-welcome-eyebrow">ALTERAÇÃO DE RG</span>
                    <h2>Selecione quem deseja gerenciar</h2>
                    <p>Informe o Passaporte / ID para verificar todas opções alteráveis</p>
                    ${targetToolbar(state.selectedPlayerId, "identity", false)}
                </div>
            </div>
        `;
    }

    const i = p.identity || {};
    const fields = [
        { key: "id", label: "ID", value: p.id, permission: "change_user_id", note: "Passaporte principal do jogador" },
        { key: "nome", label: "Nome", value: i.nome ?? "", permission: "edit_identity", note: "Nome registrado na identidade" },
        { key: "sobrenome", label: "Sobrenome", value: i.sobrenome ?? "", permission: "edit_identity", note: "Sobrenome registrado na identidade" },
        { key: "idade", label: "Idade", value: i.idade ?? "", permission: "edit_identity", note: "Idade registrada no personagem" },
        { key: "telefone", label: "Telefone", value: i.telefone ?? "", permission: "edit_identity", note: "Número de telefone da identidade" },
        { key: "registro", label: "RG", value: i.registro ?? "", permission: "edit_identity", note: "Registro geral do personagem" },
        { key: "wallet", label: "Carteira", value: Number(p.wallet || 0), permission: "edit_identity_balance", note: "Dinheiro atual no inventário", money: true },
        { key: "bank", label: "Banco", value: Number(p.bank || 0), permission: "edit_identity_balance", note: "Saldo atual da conta bancária", money: true }
    ];

    const rows = fields.map(field => `
        <article class="identity-edit-card">
            <div class="identity-edit-card-copy">
                <span>${escapeHtml(field.label)}</span>
                <strong>${field.money ? formatMoney(field.value) : escapeHtml(field.value === "" ? "-" : field.value)}</strong>
                <small>${escapeHtml(field.note)}</small>
            </div>
            ${canUse(field.permission) ? `
                <button class="identity-pencil" type="button" data-identity-edit="${field.key}" title="Editar ${escapeHtml(field.label)}" aria-label="Editar ${escapeHtml(field.label)}">
                    ${icon("edit", 16)}
                </button>
            ` : ""}
        </article>
    `).join("");

    return `
        <div class="identity-editor-page identity-loaded bounded-page">
            ${targetToolbar(p.id, "identity", true)}

            <article class="identity-editor-panel">
                <div class="identity-editor-head">
                    <div>
                        <span class="identity-editor-eyebrow">DADOS DE IDENTIDADE</span>
                        <h2>${escapeHtml(p.name)}</h2>
                        <p>Use o lápis ao lado de cada informação para alterar somente aquele dado.</p>
                    </div>
                    <span class="identity-status ${p.online ? "is-online" : "is-offline"}">${p.online ? "ONLINE" : "OFFLINE"}</span>
                </div>
                <div class="identity-edit-grid">${rows}</div>
            </article>
        </div>
    `;
}

function mapPlayerRows(players = []) {
    if (!players.length) {
        return `<div class="map-empty-list">Nenhum jogador online.</div>`;
    }
    return players.map(player => `
        <button type="button" class="map-player-row ${Number(liveMapSelectedId) === Number(player.id) ? "is-selected" : ""}" data-map-player="${player.id}" data-map-source="list" data-search="${escapeHtml(`${player.name} ${player.id}`.toLowerCase())}">
            <span class="map-player-avatar">${escapeHtml(initials(player.name))}</span>
            <span class="map-player-copy">
                <strong>${escapeHtml(player.name)}</strong>
                <small>ID #${player.id} • Bucket ${player.bucket ?? 0}</small>
            </span>
            <span class="map-player-ping">${Number(player.ping || 0)}ms</span>
        </button>
    `).join("");
}

function mapMarkers(players = []) {
    return players.map(player => {
        const pos = mapPoint(player);
        if (!pos.valid) return "";
        return `
            <button type="button" class="map-player-marker ${Number(liveMapSelectedId) === Number(player.id) ? "is-selected" : ""}"
                data-map-player="${player.id}" data-map-source="marker" style="left:${pos.left};top:${pos.top}" title="${escapeHtml(player.name)} #${player.id}">
                <span>${escapeHtml(initials(player.name).slice(0, 2))}</span>
            </button>
        `;
    }).join("");
}

function renderLiveMap() {
    const players = state.mapPlayers || state.bootstrap?.players || [];
    const updateSeconds = Math.max(1, Math.round(liveMapConfig().updateIntervalMs / 1000));
    return `
        <div class="live-map-page">
            <div class="live-map-meta-row">
                <div class="live-map-count"><span class="status-dot"></span><strong id="liveMapOnlineCount">${players.length}</strong> jogador(es) online</div>
                <div class="live-map-updated">${icon("refresh", 14)} <span>Atualizando a cada ${updateSeconds}s</span></div>
            </div>
            <div class="live-map-layout">
                <section class="live-map-card ${liveMapFullscreen ? "is-expanded" : ""}" id="liveMapCard">
                    <div class="live-map-viewport" id="liveMapViewport">
                        <div class="live-map-scroll" id="liveMapScroll">
                            <div class="live-map-stage" id="liveMapStage">
                                <img class="live-map-image" id="liveMapImage" src="${escapeHtml(liveMapConfig().mapImageUrl)}" data-hd="${escapeHtml(liveMapConfig().mapImageUrl)}" data-hd-loaded="1" data-fallback="${escapeHtml(liveMapConfig().mapFallbackUrl)}" draggable="false" referrerpolicy="no-referrer" decoding="async" fetchpriority="high" alt="Mapa de Los Santos">
                                <div class="live-map-markers" id="liveMapMarkers">${mapMarkers(players)}</div>
                            </div>
                        </div>
                        <div class="live-map-controls" aria-label="Controles do mapa">
                            <button type="button" data-map-zoom="in" title="Aproximar">${icon("plus", 18)}</button>
                            <button type="button" data-map-zoom="out" title="Afastar">${icon("minus", 18)}</button>
                            <button type="button" data-map-zoom="fullscreen" title="${liveMapFullscreen ? "Sair da tela cheia" : "Tela cheia"}">${icon(liveMapFullscreen ? "minimize" : "maximize", 17)}</button>
                        </div>
                        <div id="mapPlayerPopup"></div>
                    </div>
                </section>
                <aside class="map-online-panel">
                    <div class="map-online-head">
                        <div>${icon("users", 15)}<strong>ONLINE</strong></div>
                        <span class="map-online-badge" id="mapOnlineBadge">${players.length}</span>
                    </div>
                    <div class="map-player-list" id="mapPlayerList">${mapPlayerRows(players)}</div>
                </aside>
            </div>
        </div>
    `;
}

function applyLiveMapTransform() {
    const stage = $("#liveMapStage");
    const viewport = $("#liveMapViewport");
    const scroller = $("#liveMapScroll");
    if (!stage || !viewport || !scroller) return;

    // v2.35: o mapa é realmente maior que a janela e o pan usa scroll interno.
    // Isso é mais confiável no CEF do FiveM do que mover o stage com mousemove.
    const width = Math.max(1, viewport.clientWidth);
    const height = Math.max(1, viewport.clientHeight);
    const scaledWidth = Math.max(1, width * liveMapTransform.scale);
    const scaledHeight = Math.max(1, height * liveMapTransform.scale);
    const marginX = Math.max(0, (width - scaledWidth) / 2);
    const marginY = Math.max(0, (height - scaledHeight) / 2);

    stage.style.width = `${scaledWidth}px`;
    stage.style.height = `${scaledHeight}px`;
    stage.style.marginLeft = `${marginX}px`;
    stage.style.marginTop = `${marginY}px`;
    stage.style.left = "0px";
    stage.style.top = "0px";
    stage.style.transform = "none";

    const maxX = Math.max(0, scroller.scrollWidth - scroller.clientWidth);
    const maxY = Math.max(0, scroller.scrollHeight - scroller.clientHeight);
    scroller.scrollLeft = Math.max(0, Math.min(maxX, Number(liveMapTransform.x) || 0));
    scroller.scrollTop = Math.max(0, Math.min(maxY, Number(liveMapTransform.y) || 0));
    liveMapTransform.x = scroller.scrollLeft;
    liveMapTransform.y = scroller.scrollTop;
}
function liveMapEffectiveMaxScale() {
    const cfgMax = liveMapConfig().maxScale;
    const viewport = $("#liveMapViewport");
    const image = $("#liveMapImage");
    if (!viewport || !image || !image.naturalWidth || !image.naturalHeight) return cfgMax;

    // Nunca aproximar além de 1 pixel do asset para 1 pixel de tela.
    // Isso evita "zoom falso" que só amplia pixels e volta a borrar o mapa.
    const nativeX = image.naturalWidth / Math.max(1, viewport.clientWidth);
    const nativeY = image.naturalHeight / Math.max(1, viewport.clientHeight);
    return Math.max(liveMapConfig().minScale, Math.min(cfgMax, nativeX, nativeY));
}

function toggleLiveMapFullscreen() {
    liveMapFullscreen = !liveMapFullscreen;
    const card = $("#liveMapCard");
    if (card) card.classList.toggle("is-expanded", liveMapFullscreen);
    const button = $('[data-map-zoom="fullscreen"]');
    if (button) {
        button.title = liveMapFullscreen ? "Sair da tela cheia" : "Tela cheia";
        button.innerHTML = icon(liveMapFullscreen ? "minimize" : "maximize", 17);
    }
    requestAnimationFrame(() => {
        applyLiveMapTransform();
        updateMapPopup();
    });
}

function ensureLiveMapHd() {
    const image = $("#liveMapImage");
    if (!image || image.dataset.hdLoaded === "1" || image.dataset.hdLoading === "1") return;
    const hdUrl = image.dataset.hd;
    if (!hdUrl) return;

    image.dataset.hdLoading = "1";
    const loader = new Image();
    liveMapHdLoader = loader;
    loader.decoding = "async";
    loader.referrerPolicy = "no-referrer";

    const finish = async () => {
        try { if (typeof loader.decode === "function") await loader.decode(); } catch (_) {}
        const current = $("#liveMapImage");
        if (!current || liveMapHdLoader !== loader) return;
        current.src = hdUrl;
        current.dataset.hdLoaded = "1";
        current.dataset.hdLoading = "0";
        liveMapHdLoader = null;
        requestAnimationFrame(applyLiveMapTransform);
    };

    loader.onload = finish;
    loader.onerror = () => {
        const current = $("#liveMapImage");
        if (current) current.dataset.hdLoading = "0";
        if (liveMapHdLoader === loader) liveMapHdLoader = null;
    };
    // Compatibilidade/fallback: normalmente não é chamado na v2.49 porque o mapa HD
    // já é a fonte inicial da aba.
    loader.src = hdUrl;
}

function changeLiveMapZoom(mode, pointer = null) {
    if (mode === "fullscreen") {
        toggleLiveMapFullscreen();
        return;
    }

    const viewport = $("#liveMapViewport");
    const scroller = $("#liveMapScroll");
    const stage = $("#liveMapStage");
    if (!viewport || !scroller || !stage) return;

    const oldScale = liveMapTransform.scale;
    let next = oldScale;
    if (mode === "in") next = Math.min(liveMapEffectiveMaxScale(), oldScale + 0.25);
    if (mode === "out") next = Math.max(liveMapConfig().minScale, oldScale - 0.25);
    if (mode === "reset") {
        liveMapTransform = { scale: 1, x: 0, y: 0 };
        applyLiveMapTransform();
        updateMapPopup();
        return;
    }
    if (Math.abs(next - oldScale) < 0.001) return;

    // Mantém exatamente o ponto sob o mouse durante o zoom.
    const scrollRect = scroller.getBoundingClientRect();
    const stageRect = stage.getBoundingClientRect();
    const pointerX = pointer ? (pointer.clientX - scrollRect.left) : (scrollRect.width / 2);
    const pointerY = pointer ? (pointer.clientY - scrollRect.top) : (scrollRect.height / 2);
    const absolutePointerX = pointer ? pointer.clientX : (scrollRect.left + scrollRect.width / 2);
    const absolutePointerY = pointer ? pointer.clientY : (scrollRect.top + scrollRect.height / 2);
    const mapX = stageRect.width > 0 ? (absolutePointerX - stageRect.left) / stageRect.width : 0.5;
    const mapY = stageRect.height > 0 ? (absolutePointerY - stageRect.top) / stageRect.height : 0.5;

    const width = Math.max(1, viewport.clientWidth);
    const height = Math.max(1, viewport.clientHeight);
    const nextWidth = width * next;
    const nextHeight = height * next;
    const nextMarginX = Math.max(0, (width - nextWidth) / 2);
    const nextMarginY = Math.max(0, (height - nextHeight) / 2);

    liveMapTransform.scale = next;
    if (next > 1.15) ensureLiveMapHd();
    liveMapTransform.x = nextMarginX + (mapX * nextWidth) - pointerX;
    liveMapTransform.y = nextMarginY + (mapY * nextHeight) - pointerY;
    applyLiveMapTransform();
    updateMapPopup();
}
function selectedMapPlayer() {
    return (state.mapPlayers || []).find(player => Number(player.id) === Number(liveMapSelectedId)) || null;
}

function updateMapPopup() {
    const host = $("#mapPlayerPopup");
    const viewport = $("#liveMapViewport");
    const player = selectedMapPlayer();
    if (!host || !viewport || !player) {
        if (host) host.innerHTML = "";
        return;
    }

    const marker = $(`.map-player-marker[data-map-player="${player.id}"]`);
    if (!marker) {
        host.innerHTML = "";
        return;
    }

    const viewportRect = viewport.getBoundingClientRect();
    const markerRect = marker.getBoundingClientRect();
    const markerX = markerRect.left - viewportRect.left + markerRect.width / 2;
    const markerY = markerRect.top - viewportRect.top + markerRect.height / 2;
    const popupWidth = 270;
    const popupHeight = 154;
    const gap = 18;

    const placeRight = markerX + gap + popupWidth <= viewportRect.width - 10;
    let left = placeRight ? markerX + gap : markerX - gap - popupWidth;
    let top = markerY - popupHeight / 2;
    left = Math.max(10, Math.min(viewportRect.width - popupWidth - 10, left));
    top = Math.max(10, Math.min(viewportRect.height - popupHeight - 10, top));
    const arrowY = Math.max(20, Math.min(popupHeight - 20, markerY - top));

    const buttons = [
        canUse("tptome") ? `<button type="button" data-map-action="tptome" data-map-target="${player.id}">${icon("target", 14)} PUXAR</button>` : "",
        canUse("tpto") ? `<button type="button" data-map-action="tpto" data-map-target="${player.id}">${icon("pin", 14)} IR ATÉ</button>` : "",
        canUse("freeze") ? `<button type="button" data-map-action="freeze" data-map-target="${player.id}">${icon("snow", 14)} CONGELAR</button>` : "",
        canUse("map_screen") ? `<button type="button" data-map-action="map_screen" data-map-target="${player.id}">${icon("eye", 14)} VER TELA</button>` : ""
    ].filter(Boolean).join("");

    host.innerHTML = `
        <div class="map-player-popup ${placeRight ? "is-right" : "is-left"}" style="left:${left}px;top:${top}px;--map-popup-arrow-y:${arrowY}px">
            <button class="map-popup-close" type="button" data-map-popup-close>${icon("close", 13)}</button>
            <div class="map-popup-user-copy">
                <strong>${escapeHtml(player.name)}</strong>
                <small>ID #${player.id} • Ping ${Number(player.ping || 0)}ms • Bucket ${Number(player.bucket || 0)}</small>
            </div>
            <div class="map-popup-actions">${buttons || `<span class="map-popup-no-actions">Sem ações liberadas.</span>`}</div>
        </div>
    `;
}

function focusLiveMapPlayer(playerId) {
    requestAnimationFrame(() => requestAnimationFrame(() => {
        const viewport = $("#liveMapViewport");
        const marker = $(`.map-player-marker[data-map-player="${Number(playerId)}"]`);
        if (!viewport || !marker) {
            updateMapPopup();
            return;
        }
        const viewportRect = viewport.getBoundingClientRect();
        const markerRect = marker.getBoundingClientRect();
        const markerX = markerRect.left + markerRect.width / 2;
        const markerY = markerRect.top + markerRect.height / 2;
        const margin = 150;
        const outside = markerX < viewportRect.left + margin || markerX > viewportRect.right - margin || markerY < viewportRect.top + margin || markerY > viewportRect.bottom - margin;
        if (outside) {
            const targetX = viewportRect.left + viewportRect.width * 0.5;
            const targetY = viewportRect.top + viewportRect.height * 0.5;
            // Com pan baseado em scroll, aumentar scroll move o conteúdo para a esquerda/cima.
            liveMapTransform.x += markerX - targetX;
            liveMapTransform.y += markerY - targetY;
            applyLiveMapTransform();
        }
        requestAnimationFrame(updateMapPopup);
    }));
}

function updateLiveMapDom() {
    const players = state.mapPlayers || [];
    const markers = $("#liveMapMarkers");
    const list = $("#mapPlayerList");
    if (markers) markers.innerHTML = mapMarkers(players);
    if (list) list.innerHTML = mapPlayerRows(players);
    const count = $("#liveMapOnlineCount");
    const badge = $("#mapOnlineBadge");
    if (count) count.textContent = players.length;
    if (badge) badge.textContent = players.length;
    if (liveMapSelectedId && !players.some(player => Number(player.id) === Number(liveMapSelectedId))) {
        liveMapSelectedId = null;
    }
    requestAnimationFrame(() => {
        applyLiveMapTransform();
        updateMapPopup();
    });
}

async function refreshLiveMap(silent = true) {
    if (!state.open || state.page !== "map") return;
    const response = await post("mapPlayers");
    if (!response?.ok) {
        if (!silent) toast("error", "Mapa ao vivo", response?.message || "Não foi possível atualizar as posições.");
        return;
    }
    state.mapPlayers = response.data?.players || [];
    updateLiveMapDom();
}

function teardownLiveMap(stopScreen = false) {
    if (liveMapTimer) {
        clearInterval(liveMapTimer);
        liveMapTimer = null;
    }
    if (typeof liveMapInteractionCleanup === "function") {
        liveMapInteractionCleanup();
        liveMapInteractionCleanup = null;
    }
    liveMapDrag = null;
    liveMapHdLoader = null;
    if (stopScreen && liveScreenSession) stopLiveScreenSession();
}

function initLiveMapPage() {
    teardownLiveMap(false);
    const viewport = $("#liveMapViewport");
    const scroller = $("#liveMapScroll");
    if (!viewport || !scroller) return;

    const mapImage = $("#liveMapImage");
    if (mapImage) {
        mapImage.addEventListener("error", () => {
            const fallback = mapImage.dataset.fallback;
            if (fallback && !mapImage.dataset.fallbackLoaded) {
                mapImage.dataset.fallbackLoaded = "1";
                mapImage.src = fallback;
            }
        });
        mapImage.addEventListener("load", () => {
            mapImage.classList.add("is-loaded");
            applyLiveMapTransform();
        });
    }

    applyLiveMapTransform();
    refreshLiveMap(true);

    const updateInterval = liveMapConfig().updateIntervalMs;
    liveMapTimer = setInterval(() => refreshLiveMap(true), updateInterval);

    const syncScrollState = () => {
        liveMapTransform.x = scroller.scrollLeft;
        liveMapTransform.y = scroller.scrollTop;
        updateMapPopup();
    };

    const onWheel = event => {
        event.preventDefault();
        changeLiveMapZoom(event.deltaY < 0 ? "in" : "out", event);
    };

    // Pan real por scroll interno: clicar + segurar + arrastar reposiciona o mapa.
    // Usamos listeners em capture no document para o CEF não perder o movimento.
    const onMouseDown = event => {
        if (event.button !== 0) return;
        if (event.target.closest("button, .map-player-popup")) return;
        liveMapDrag = {
            startX: event.clientX,
            startY: event.clientY,
            originScrollLeft: scroller.scrollLeft,
            originScrollTop: scroller.scrollTop
        };
        viewport.classList.add("is-dragging");
        scroller.classList.add("is-dragging");
        event.preventDefault();
        event.stopPropagation();
    };

    const onMouseMove = event => {
        if (!liveMapDrag) return;
        const dx = event.clientX - liveMapDrag.startX;
        const dy = event.clientY - liveMapDrag.startY;
        scroller.scrollLeft = liveMapDrag.originScrollLeft - dx;
        scroller.scrollTop = liveMapDrag.originScrollTop - dy;
        syncScrollState();
        event.preventDefault();
        event.stopPropagation();
    };

    const endMouseDrag = event => {
        if (!liveMapDrag) return;
        liveMapDrag = null;
        viewport.classList.remove("is-dragging");
        scroller.classList.remove("is-dragging");
        if (event) {
            event.preventDefault();
            event.stopPropagation();
        }
    };

    const onDoubleClick = event => {
        if (event.target.closest("button, .map-player-popup")) return;
        changeLiveMapZoom("reset");
    };

    scroller.addEventListener("wheel", onWheel, { passive: false });
    scroller.addEventListener("mousedown", onMouseDown, true);
    scroller.addEventListener("scroll", syncScrollState, { passive: true });
    document.addEventListener("mousemove", onMouseMove, true);
    document.addEventListener("mouseup", endMouseDrag, true);
    window.addEventListener("blur", endMouseDrag);
    scroller.addEventListener("dblclick", onDoubleClick);

    liveMapInteractionCleanup = () => {
        scroller.removeEventListener("wheel", onWheel);
        scroller.removeEventListener("mousedown", onMouseDown, true);
        scroller.removeEventListener("scroll", syncScrollState);
        document.removeEventListener("mousemove", onMouseMove, true);
        document.removeEventListener("mouseup", endMouseDrag, true);
        window.removeEventListener("blur", endMouseDrag);
        scroller.removeEventListener("dblclick", onDoubleClick);
        viewport.classList.remove("is-dragging");
        scroller.classList.remove("is-dragging");
    };
}
// ============================================================================
// VER TELA v2.56 — Cfx game-view -> WebGL canvas -> WebRTC P2P + autoteste local direto
// ============================================================================
// Replica apenas o pequeno "hook" usado pelo CfxTexture oficial. Diferente do
// screenshot-basic, nenhum readPixels/toDataURL/JPG/base64 é executado.
function createCfxGameCapture(options = {}) {
    const width = Math.max(480, Math.min(1280, Number(options.width) || 960));
    const height = Math.max(270, Math.min(720, Number(options.height) || 540));
    const fps = Math.max(6, Math.min(20, Number(options.fps) || 12));

    const canvas = document.createElement("canvas");
    canvas.width = width;
    canvas.height = height;
    canvas.className = "live-screen-capture-canvas";
    canvas.setAttribute("aria-hidden", "true");
    document.body.appendChild(canvas);

    const gl = canvas.getContext("webgl", {
        alpha: false,
        antialias: false,
        depth: false,
        stencil: false,
        preserveDrawingBuffer: true,
        powerPreference: "low-power"
    });
    if (!gl) {
        canvas.remove();
        throw new Error("WebGL não está disponível na NUI deste jogador.");
    }

    const compileShader = (type, source) => {
        const shader = gl.createShader(type);
        gl.shaderSource(shader, source);
        gl.compileShader(shader);
        if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
            const error = gl.getShaderInfoLog(shader) || "Falha ao compilar shader.";
            gl.deleteShader(shader);
            throw new Error(error);
        }
        return shader;
    };

    const vertex = compileShader(gl.VERTEX_SHADER, `
        attribute vec2 aPosition;
        varying vec2 vUv;
        void main() {
            vec2 uv = aPosition * 0.5 + 0.5;
            // O render target do CfxTexture já chega na orientação esperada para
            // o canvas. Não inverter o Y aqui, senão a transmissão fica de cabeça para baixo.
            vUv = uv;
            gl_Position = vec4(aPosition, 0.0, 1.0);
        }
    `);
    const fragment = compileShader(gl.FRAGMENT_SHADER, `
        precision mediump float;
        varying vec2 vUv;
        uniform sampler2D uGameView;
        void main() {
            gl_FragColor = texture2D(uGameView, vUv);
        }
    `);

    const program = gl.createProgram();
    gl.attachShader(program, vertex);
    gl.attachShader(program, fragment);
    gl.linkProgram(program);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
        throw new Error(gl.getProgramInfoLog(program) || "Falha ao iniciar captura WebGL.");
    }
    gl.useProgram(program);

    const buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
        -1, -1,  1, -1, -1,  1,
        -1,  1,  1, -1,  1,  1
    ]), gl.STATIC_DRAW);
    const position = gl.getAttribLocation(program, "aPosition");
    gl.enableVertexAttribArray(position);
    gl.vertexAttribPointer(position, 2, gl.FLOAT, false, 0, 0);

    const texture = gl.createTexture();
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, false);
    gl.pixelStorei(gl.UNPACK_ALIGNMENT, 1);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texImage2D(
        gl.TEXTURE_2D, 0, gl.RGB, 1, 1, 0,
        gl.RGB, gl.UNSIGNED_BYTE, new Uint8Array([0, 0, 0])
    );

    // Sequência especial do @citizenfx/three/CfxTexture. O plugin do FiveM
    // intercepta estes valores e associa a textura ao render target do GTA.
    gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE); // 33071
    gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, 33648);
    gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);       // 10497

    const sampler = gl.getUniformLocation(program, "uGameView");
    gl.uniform1i(sampler, 0);
    gl.viewport(0, 0, width, height);

    let stopped = false;
    let animationFrame = 0;
    let lastDrawAt = 0;
    const frameInterval = 1000 / fps;

    const draw = now => {
        if (stopped) return;
        animationFrame = requestAnimationFrame(draw);
        if (now - lastDrawAt < frameInterval) return;
        lastDrawAt = now;
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.drawArrays(gl.TRIANGLES, 0, 6);
        gl.flush();
    };
    animationFrame = requestAnimationFrame(draw);

    if (typeof canvas.captureStream !== "function") {
        stopped = true;
        cancelAnimationFrame(animationFrame);
        canvas.remove();
        throw new Error("A versão do CEF/FiveM não oferece canvas.captureStream().");
    }

    const stream = canvas.captureStream(fps);
    const videoTrack = stream.getVideoTracks()[0];
    if (!videoTrack) {
        stopped = true;
        cancelAnimationFrame(animationFrame);
        canvas.remove();
        throw new Error("Não foi possível criar a trilha de vídeo da captura.");
    }
    try { videoTrack.contentHint = "motion"; } catch (_) {}

    return {
        canvas,
        gl,
        stream,
        width,
        height,
        fps,
        stop() {
            if (stopped) return;
            stopped = true;
            cancelAnimationFrame(animationFrame);
            try { stream.getTracks().forEach(track => track.stop()); } catch (_) {}
            try { gl.getExtension("WEBGL_lose_context")?.loseContext(); } catch (_) {}
            canvas.remove();
        }
    };
}

function liveScreenPeerConfig(options = {}) {
    const source = Array.isArray(options.iceServers) ? options.iceServers : [];
    const iceServers = source
        .map(item => typeof item === "string" ? { urls: item } : item)
        .filter(item => item && item.urls);
    return {
        iceServers,
        bundlePolicy: "balanced",
        rtcpMuxPolicy: "require",
        iceCandidatePoolSize: 2
    };
}

async function sendLiveScreenSignal(token, kind, payload, role) {
    return post("liveScreenSignal", { token, kind, payload: payload || {}, role: String(role || "") });
}

function liveScreenSetStatus(stateName, message) {
    if (!liveScreenSession) return;
    const badge = $("#liveScreenBadge");
    const loading = $("#liveScreenLoading");
    const meta = $(".live-screen-meta");
    if (badge) {
        badge.dataset.state = stateName || "connecting";
        const label = stateName === "live" ? "AO VIVO" : stateName === "error" ? "ERRO" : "CONECTANDO";
        badge.innerHTML = `<span class="status-dot"></span> ${label}`;
    }
    if (meta) {
        const isSelfTest = liveScreenSession.selfTest === true;
        const isRelay = liveScreenSession.transport === "relay";
        const suffix = stateName === "live"
            ? (isSelfTest ? "TESTE LOCAL • AO VIVO" : (isRelay ? "AO VIVO • RELAY SERVIDOR" : "AO VIVO • WebRTC P2P"))
            : stateName === "error"
                ? "TRANSMISSÃO INTERROMPIDA"
                : (isSelfTest ? "iniciando teste local" : (isRelay ? "conectando via relay do servidor" : "conectando via WebRTC P2P"));
        meta.textContent = `ID #${liveScreenSession.targetId} • ${suffix}`;
    }
    if (loading && message && stateName !== "live") {
        loading.innerHTML = `${icon(stateName === "error" ? "alert" : "monitor", 28)}<strong>${stateName === "error" ? "Não foi possível transmitir" : "Conectando à tela..."}</strong><span>${escapeHtml(message)}</span>`;
    }
}

function cleanupLiveScreenReceiver() {
    const session = liveScreenSession;
    if (!session) return;
    if (session.connectTimer) clearTimeout(session.connectTimer);
    session.connectTimer = null;
    try { session.pc?.close(); } catch (_) {}
    session.pc = null;
    try { session.localCapture?.stop(); } catch (_) {}
    session.localCapture = null;
    session.pendingCandidates = [];
    const video = $("#liveScreenVideo");
    if (video) {
        try { video.pause(); } catch (_) {}
        video.srcObject = null;
        video.classList.remove("is-visible");
    }
    const relayImage = $("#liveScreenRelayImage");
    if (relayImage) {
        relayImage.removeAttribute("src");
        relayImage.classList.remove("is-visible");
    }
}

async function startLiveScreenSelfTest(session) {
    if (!session || liveScreenSession !== session) return;
    liveScreenSetStatus("connecting", "Iniciando captura local do render do GTA. Neste teste não há P2P, STUN ou TURN.");

    let capture = null;
    try {
        capture = createCfxGameCapture(session.options || {});
        if (!liveScreenSession || liveScreenSession !== session) {
            capture.stop();
            return;
        }

        session.localCapture = capture;
        session.selfTest = true;

        const video = $("#liveScreenVideo");
        if (!video) throw new Error("Player de vídeo do painel não foi encontrado.");

        video.srcObject = capture.stream;
        video.muted = true;

        const markLive = () => {
            if (!liveScreenSession || liveScreenSession !== session) return;
            video.classList.add("is-visible");
            const loading = $("#liveScreenLoading");
            if (loading) loading.style.display = "none";
            liveScreenSetStatus("live");
        };

        video.onloadeddata = markLive;
        video.onplaying = markLive;
        await video.play().catch(() => {});

        // CanvasCaptureMediaStreamTrack é criado imediatamente. Mesmo que o
        // primeiro frame demore alguns ms, o teste não deve cair em timeout ICE.
        setTimeout(() => {
            if (!liveScreenSession || liveScreenSession !== session) return;
            const track = capture.stream.getVideoTracks()[0];
            if (!track || track.readyState === "ended") {
                liveScreenSetStatus("error", "A trilha local de vídeo foi encerrada pelo CEF/FiveM.");
                return;
            }
            if (video.readyState >= 2) markLive();
        }, 700);
    } catch (error) {
        try { capture?.stop(); } catch (_) {}
        if (liveScreenSession === session) {
            session.localCapture = null;
            liveScreenSetStatus("error", error?.message || "Falha ao iniciar o teste local do render.");
        }
    }
}

async function ensureLiveScreenReceiverPeer(session) {
    if (session.pc) return session.pc;
    if (typeof RTCPeerConnection !== "function") throw new Error("WebRTC não está disponível no CEF deste FiveM.");

    const pc = new RTCPeerConnection(liveScreenPeerConfig(session.options || {}));
    session.pc = pc;
    session.pendingCandidates = session.pendingCandidates || [];

    pc.onicecandidate = event => {
        if (!event.candidate || !liveScreenSession || liveScreenSession !== session) return;
        const candidate = event.candidate.toJSON ? event.candidate.toJSON() : {
            candidate: event.candidate.candidate,
            sdpMid: event.candidate.sdpMid,
            sdpMLineIndex: event.candidate.sdpMLineIndex
        };
        sendLiveScreenSignal(session.token, "candidate", candidate, "receiver");
    };

    pc.ontrack = event => {
        if (!liveScreenSession || liveScreenSession !== session) return;
        const video = $("#liveScreenVideo");
        if (!video) return;
        const stream = event.streams?.[0] || new MediaStream([event.track]);
        video.srcObject = stream;
        video.muted = true;
        video.play().catch(() => {});
        video.onloadeddata = () => {
            if (!liveScreenSession || liveScreenSession !== session) return;
            video.classList.add("is-visible");
            const loading = $("#liveScreenLoading");
            if (loading) loading.style.display = "none";
            liveScreenSetStatus("live");
        };
    };

    pc.onconnectionstatechange = () => {
        if (!liveScreenSession || liveScreenSession !== session) return;
        const stateName = pc.connectionState;
        if (stateName === "connected") {
            liveScreenSetStatus("live");
        } else if (stateName === "failed") {
            requestLiveScreenRelayFallback(session, "A conexão P2P falhou. Ativando modo compatibilidade pelo servidor...");
        } else if (stateName === "closed") {
            if (session.transport !== "relay") liveScreenSetStatus("error", "A conexão com o jogador foi encerrada.");
        } else if (stateName === "disconnected") {
            liveScreenSetStatus("connecting", "A conexão oscilou. Tentando recuperar automaticamente...");
        }
    };

    return pc;
}

async function startLiveScreenPublisher(token, options = {}) {
    if (!token) return;
    if (liveScreenPublisher?.token === token) return;
    if (liveScreenPublisher) stopLiveScreenPublisher(liveScreenPublisher.token);

    let capture = null;
    let pc = null;
    try {
        if (typeof RTCPeerConnection !== "function") throw new Error("WebRTC não está disponível no CEF deste FiveM.");
        capture = createCfxGameCapture(options);
        pc = new RTCPeerConnection(liveScreenPeerConfig(options));
        const publisher = {
            token,
            options,
            capture,
            pc,
            pendingCandidates: [],
            remoteReady: false
        };
        liveScreenPublisher = publisher;

        const track = capture.stream.getVideoTracks()[0];
        const sender = pc.addTrack(track, capture.stream);
        try {
            const parameters = sender.getParameters();
            if (!parameters.encodings || !parameters.encodings.length) parameters.encodings = [{}];
            parameters.encodings[0].maxBitrate = Math.max(350000, Math.min(3000000, Number(options.bitrate) || 1200000));
            parameters.encodings[0].maxFramerate = capture.fps;
            await sender.setParameters(parameters);
        } catch (_) {}

        pc.onicecandidate = event => {
            if (!event.candidate || liveScreenPublisher !== publisher) return;
            const candidate = event.candidate.toJSON ? event.candidate.toJSON() : {
                candidate: event.candidate.candidate,
                sdpMid: event.candidate.sdpMid,
                sdpMLineIndex: event.candidate.sdpMLineIndex
            };
            sendLiveScreenSignal(token, "candidate", candidate, "publisher");
        };

        pc.onconnectionstatechange = () => {
            if (liveScreenPublisher !== publisher) return;
            const connectionState = pc.connectionState;
            if (connectionState === "connected") {
                sendLiveScreenSignal(token, "status", { state: "connected", message: "Vídeo P2P conectado." }, "publisher");
            } else if (connectionState === "failed") {
                sendLiveScreenSignal(token, "status", { state: "p2p_failed", message: "A conexão WebRTC P2P falhou. Preparando modo compatibilidade." }, "publisher");
            } else if (connectionState === "disconnected") {
                sendLiveScreenSignal(token, "status", { state: "connecting", message: "A conexão P2P oscilou." }, "publisher");
            }
        };

        const offer = await pc.createOffer({ offerToReceiveAudio: false, offerToReceiveVideo: false });
        await pc.setLocalDescription(offer);
        await sendLiveScreenSignal(token, "offer", { type: pc.localDescription.type, sdp: pc.localDescription.sdp }, "publisher");
        await sendLiveScreenSignal(token, "status", {
            state: "capturing",
            message: `Render ${capture.width}x${capture.height} a ${capture.fps} FPS pronto. Negociando conexão P2P...`
        }, "publisher");
    } catch (error) {
        try { pc?.close(); } catch (_) {}
        try { capture?.stop(); } catch (_) {}
        if (liveScreenPublisher?.token === token) liveScreenPublisher = null;
        await sendLiveScreenSignal(token, "status", { state: "p2p_failed", message: error?.message || "Falha ao iniciar o WebRTC. Preparando modo compatibilidade." }, "publisher");
    }
}


async function requestLiveScreenRelayFallback(session, reason) {
    if (!session || liveScreenSession !== session || session.selfTest) return;
    if (session.transport === "relay" || session.relayStarting) return;

    session.relayStarting = true;
    session.transport = "relay";
    if (session.connectTimer) clearTimeout(session.connectTimer);
    session.connectTimer = null;

    liveScreenSetStatus("connecting", reason || "Ativando transmissão compatível via servidor...");

    try {
        try { session.pc?.close(); } catch (_) {}
        session.pc = null;
        session.pendingCandidates = [];
        session.remoteReady = false;

        const response = await post("liveScreenRelay", { mode: "start", token: session.token });
        if (!response?.ok) throw new Error(response?.message || "Não foi possível iniciar o modo compatibilidade.");

        session.options = { ...(session.options || {}), ...(response.data || {}) };
        liveScreenSetStatus("connecting", "P2P indisponível. Recebendo a tela pelo relay seguro do FXServer...");
    } catch (error) {
        session.transport = "p2p";
        liveScreenSetStatus("error", error?.message || "Falha ao iniciar o modo compatibilidade.");
    } finally {
        session.relayStarting = false;
    }
}

function stopLiveScreenRelayPublisher(token) {
    if (!liveScreenRelayPublisher) return;
    if (token && String(liveScreenRelayPublisher.token) !== String(token)) return;
    const relay = liveScreenRelayPublisher;
    liveScreenRelayPublisher = null;
    relay.stopped = true;
    if (relay.timer) clearTimeout(relay.timer);
    try { relay.capture?.stop(); } catch (_) {}
}

async function startLiveScreenRelayPublisher(token, options = {}) {
    token = String(token || "");
    if (!token) return;
    if (liveScreenRelayPublisher?.token === token) return;
    if (liveScreenRelayPublisher) stopLiveScreenRelayPublisher(liveScreenRelayPublisher.token);

    stopLiveScreenPublisher(token);

    let capture = null;
    try {
        const relayWidth = Math.max(480, Math.min(1280, Number(options.relayWidth) || 960));
        const relayHeight = Math.max(270, Math.min(720, Number(options.relayHeight) || 540));
        const relayFps = Math.max(1, Math.min(10, Number(options.relayFps) || 8));
        const relayQuality = Math.max(0.25, Math.min(0.85, Number(options.relayQuality) || 0.65));
        const intervalMs = Math.max(90, Math.floor(1000 / relayFps));

        capture = createCfxGameCapture({
            ...options,
            width: relayWidth,
            height: relayHeight,
            fps: Math.max(6, relayFps)
        });

        const relay = {
            token,
            capture,
            quality: relayQuality,
            intervalMs,
            timer: null,
            stopped: false,
            seq: 0
        };
        liveScreenRelayPublisher = relay;

        const sendFrame = async () => {
            if (relay.stopped || liveScreenRelayPublisher !== relay) return;
            const startedAt = performance.now();
            try {
                const frame = capture.canvas.toDataURL("image/jpeg", relay.quality);
                if (frame && frame.length > 128) {
                    relay.seq += 1;
                    await post("liveScreenRelayFrame", {
                        token,
                        seq: relay.seq,
                        frame
                    });
                }
            } catch (_) {}
            if (!relay.stopped && liveScreenRelayPublisher === relay) {
                // Mantém o FPS real próximo do configurado. Antes o tempo gasto
                // codificando/enviando o JPEG era somado ao intervalo e deixava
                // a transmissão perceptivelmente mais travada que o FPS definido.
                const elapsed = performance.now() - startedAt;
                relay.timer = setTimeout(sendFrame, Math.max(0, relay.intervalMs - elapsed));
            }
        };

        relay.timer = setTimeout(sendFrame, 250);
        await sendLiveScreenSignal(token, "status", {
            state: "relay",
            message: `Modo compatibilidade ${relayWidth}x${relayHeight} a ${relayFps} FPS iniciado.`
        }, "publisher");
    } catch (error) {
        try { capture?.stop(); } catch (_) {}
        if (liveScreenRelayPublisher?.token === token) liveScreenRelayPublisher = null;
        await sendLiveScreenSignal(token, "status", {
            state: "error",
            message: error?.message || "Falha ao iniciar o relay da tela."
        }, "publisher");
    }
}

function receiveLiveScreenRelayFrame(data) {
    const session = liveScreenSession;
    if (!session || String(session.token) !== String(data.token || "")) return;
    if (!data.frame || typeof data.frame !== "string") return;

    session.transport = "relay";
    const image = $("#liveScreenRelayImage");
    const video = $("#liveScreenVideo");
    if (!image) return;

    image.onload = () => {
        if (!liveScreenSession || String(liveScreenSession.token) !== String(data.token || "")) return;
        if (video) video.classList.remove("is-visible");
        image.classList.add("is-visible");
        const loading = $("#liveScreenLoading");
        if (loading) loading.style.display = "none";
        liveScreenSetStatus("live");
    };
    image.src = data.frame;
}

function stopLiveScreenPublisher(token) {
    if (!liveScreenPublisher) return;
    if (token && String(liveScreenPublisher.token) !== String(token)) return;
    const publisher = liveScreenPublisher;
    liveScreenPublisher = null;
    try { publisher.pc?.close(); } catch (_) {}
    try { publisher.capture?.stop(); } catch (_) {}
}

async function processLiveScreenSignal(data) {
    const token = String(data.token || "");
    const kind = String(data.kind || "");
    const payload = data.payload || {};
    const destinationRole = String(data.role || "");
    if (!token || !kind) return;

    const processPublisherSignal = async () => {
        if (!liveScreenPublisher || String(liveScreenPublisher.token) !== token) return;
        const publisher = liveScreenPublisher;
        const pc = publisher.pc;
        if (kind === "answer") {
            await pc.setRemoteDescription(payload);
            publisher.remoteReady = true;
            const pending = publisher.pendingCandidates.splice(0);
            for (const candidate of pending) await pc.addIceCandidate(candidate).catch(() => {});
        } else if (kind === "candidate") {
            if (publisher.remoteReady || pc.remoteDescription) await pc.addIceCandidate(payload).catch(() => {});
            else publisher.pendingCandidates.push(payload);
        }
    };

    const processReceiverSignal = async () => {
        const session = liveScreenSession;
        if (!session || String(session.token) !== token) return;

        if (kind === "status") {
            if (payload.state === "error") liveScreenSetStatus("error", payload.message || "Falha no stream do jogador.");
            else if (payload.state === "connected") liveScreenSetStatus("live");
            else if (payload.state === "p2p_failed") await requestLiveScreenRelayFallback(session, payload.message || "P2P indisponível. Ativando modo compatibilidade...");
            else if (payload.state === "relay") {
                session.transport = "relay";
                liveScreenSetStatus("connecting", payload.message || "Modo compatibilidade iniciado. Aguardando primeiro frame...");
            } else liveScreenSetStatus("connecting", payload.message || "Negociando conexão P2P...");
            return;
        }

        const pc = await ensureLiveScreenReceiverPeer(session);
        if (kind === "offer") {
            await pc.setRemoteDescription(payload);
            session.remoteReady = true;
            const answer = await pc.createAnswer();
            await pc.setLocalDescription(answer);
            await sendLiveScreenSignal(token, "answer", { type: pc.localDescription.type, sdp: pc.localDescription.sdp }, "receiver");
            const pending = (session.pendingCandidates || []).splice(0);
            for (const candidate of pending) await pc.addIceCandidate(candidate).catch(() => {});
        } else if (kind === "candidate") {
            if (session.remoteReady || pc.remoteDescription) await pc.addIceCandidate(payload).catch(() => {});
            else (session.pendingCandidates ||= []).push(payload);
        }
    };

    // O papel de destino torna o protocolo não ambíguo quando publisher e
    // receiver vivem no mesmo CEF (staff testando a própria tela).
    if (destinationRole === "publisher") {
        await processPublisherSignal();
        return;
    }
    if (destinationRole === "receiver") {
        await processReceiverSignal();
        return;
    }

    // Compatibilidade com eventos da v2.53 entre dois clients diferentes.
    if (liveScreenPublisher && String(liveScreenPublisher.token) === token && (kind === "answer" || kind === "candidate")) {
        await processPublisherSignal();
        return;
    }
    await processReceiverSignal();
}

function queueLiveScreenSignal(data) {
    liveScreenSignalQueue = liveScreenSignalQueue
        .then(() => processLiveScreenSignal(data))
        .catch(error => {
            if (liveScreenSession && String(liveScreenSession.token) === String(data.token || "")) {
                requestLiveScreenRelayFallback(
                    liveScreenSession,
                    error?.message ? `Falha no WebRTC (${error.message}). Ativando modo compatibilidade...` : "Falha na negociação WebRTC. Ativando modo compatibilidade..."
                );
            }
        });
}

async function openLiveScreenModal(player) {
    if (!player || !canUse("map_screen")) return;
    if (liveScreenSession) await stopLiveScreenSession();

    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <div class="modal live-screen-modal">
            <div class="modal-head live-screen-head">
                <div class="modal-title live-screen-title">
                    <span class="live-screen-title-icon">${icon("monitor", 18)}</span>
                    <div class="live-screen-heading">
                        <strong>Tela de ${escapeHtml(player.name)}</strong>
                        <span class="live-screen-meta">ID #${player.id} • preparando transmissão</span>
                    </div>
                </div>
                <button class="modal-close" type="button" data-modal-close>${icon("close", 15)}</button>
            </div>
            <div class="modal-body live-screen-body">
                <div class="live-screen-frame">
                    <video id="liveScreenVideo" autoplay muted playsinline></video>
                    <img id="liveScreenRelayImage" alt="Tela transmitida em modo compatibilidade">
                    <div class="live-screen-loading" id="liveScreenLoading">${icon("monitor", 28)}<strong>Conectando à tela...</strong><span>Preparando a captura em tempo real. Se o P2P falhar por NAT/CGNAT, o modo compatibilidade será ativado automaticamente.</span></div>
                    <div class="live-screen-badge" id="liveScreenBadge" data-state="connecting"><span class="status-dot"></span> CONECTANDO</div>
                </div>
            </div>
        </div>
    `;

    const response = await post("liveScreen", { mode: "start", targetId: player.id });
    if (!response?.ok) {
        closeModal();
        toast("error", "Ver tela", response?.message || "Não foi possível iniciar o monitoramento.");
        return;
    }

    liveScreenSession = {
        token: response.data?.token,
        targetId: player.id,
        name: player.name,
        pc: null,
        pendingCandidates: [],
        remoteReady: false,
        options: {},
        connectTimer: null,
        localCapture: null,
        selfTest: false,
        transport: "p2p",
        relayStarting: false
    };

    const ready = await post("liveScreen", { mode: "ready", token: liveScreenSession.token });
    if (!ready?.ok) {
        const message = ready?.message || "Não foi possível solicitar a transmissão ao jogador.";
        liveScreenSetStatus("error", message);
        toast("error", "Ver tela", message);
        return;
    }

    liveScreenSession.options = ready.data || {};
    liveScreenSession.selfTest = ready.data?.selfTest === true;

    if (liveScreenSession.selfTest) {
        await startLiveScreenSelfTest(liveScreenSession);
        return;
    }

    const timeoutMs = Math.max(8000, Math.min(30000, Number(ready.data?.timeoutMs) || 15000));
    liveScreenSession.connectTimer = setTimeout(() => {
        if (!liveScreenSession || String(liveScreenSession.token) !== String(response.data?.token)) return;
        const video = $("#liveScreenVideo");
        if (!video || video.readyState < 2) {
            requestLiveScreenRelayFallback(liveScreenSession, "A conexão P2P não foi estabelecida a tempo. Ativando modo compatibilidade automaticamente...");
        }
    }, timeoutMs);
}

async function stopLiveScreenSession() {
    const session = liveScreenSession;
    if (!session) return;
    cleanupLiveScreenReceiver();
    liveScreenSession = null;
    await post("liveScreen", { mode: "stop", token: session.token });
}

async function refreshLogsAdminData(silent = false) {
    const response = await post("logsAdmin", { mode: "list", silent });
    if (!response?.ok) {
        if (!silent) toast("error", "Logs", response?.message || "Não foi possível carregar as configurações de logs.");
        return response;
    }
    state.logsAdmin = response.data || { categories: [], configured: 0, total: 0 };
    if (state.open && state.page === "logs") render();
    return response;
}

function currentLogsCategory() {
    return (state.logsAdmin?.categories || []).find(category => String(category.id) === String(state.logsCategoryId)) || null;
}

function currentLogsSubcategory(category = currentLogsCategory()) {
    if (!category) return null;
    return (category.subcategories || []).find(subcategory => String(subcategory.id) === String(state.logsSubcategoryId)) || null;
}

function logsProgress(logs = []) {
    const total = logs.length;
    const configured = logs.filter(log => Boolean(log.configured || String(log.webhook || "").trim())).length;
    return { total, configured };
}

function logsCountForCategory(category) {
    const subcategories = category?.subcategories || [];
    if (subcategories.length) {
        const all = subcategories.flatMap(subcategory => subcategory.logs || []);
        return logsProgress(all);
    }
    return logsProgress(category?.logs || []);
}

function renderLogsCards(items, type) {
    return items.map(item => {
        const progress = type === "category" ? logsCountForCategory(item) : logsProgress(item.logs || []);
        const configuredClass = progress.total > 0 && progress.configured === progress.total ? "is-complete" : progress.configured > 0 ? "is-partial" : "";
        const attribute = type === "category" ? `data-logs-category="${escapeHtml(item.id)}"` : `data-logs-subcategory="${escapeHtml(item.id)}"`;
        return `
            <button type="button" class="logs-folder-card ${configuredClass}" ${attribute}>
                <span class="logs-folder-icon">${icon(type === "category" ? "server" : "archive", 20)}</span>
                <span class="logs-folder-copy">
                    <strong>${escapeHtml(item.label || "Logs")}</strong>
                    <small>${escapeHtml(item.description || (type === "category" ? "Abrir categorias de logs" : `${progress.total} logs disponíveis`))}</small>
                </span>
                <span class="logs-folder-progress"><b>${progress.configured}</b><small>/ ${progress.total}</small></span>
                ${icon("arrow", 17)}
            </button>`;
    }).join("");
}

function renderLogsEditor(category, subcategory = null) {
    const logs = subcategory ? (subcategory.logs || []) : (category.logs || []);
    const progress = logsProgress(logs);
    const title = subcategory?.label || category?.label || "Logs";
    const rows = logs.map(log => `
        <label class="log-webhook-row ${log.configured ? "is-configured" : ""}" data-log-row="${escapeHtml(log.key)}">
            <span class="log-webhook-status" aria-hidden="true"></span>
            <span class="log-webhook-copy">
                <strong>${escapeHtml(log.name || log.key)}</strong>
                <small>${escapeHtml(log.description || "")}</small>
            </span>
            <span class="log-webhook-input-wrap">
                <span>WEBHOOK DO DISCORD</span>
                <input class="input log-webhook-input" type="text" name="${escapeHtml(log.key)}" value="${escapeHtml(log.webhook || "")}" placeholder="" autocomplete="off" spellcheck="false" data-log-webhook="${escapeHtml(log.key)}">
            </span>
        </label>`).join("");

    return `
        <div class="logs-page bounded-page">
            <div class="logs-breadcrumb-row">
                <button type="button" class="button ghost" data-logs-back="${subcategory ? "subcategories" : "categories"}">${icon("arrow", 13)} Voltar</button>
                <div class="logs-breadcrumb-copy">
                    <span>PAINEL ADM ${subcategory ? ` / ${escapeHtml(category.label || "")}` : ""}</span>
                    <strong>${escapeHtml(title)}</strong>
                </div>
                <div class="logs-summary-chip"><b>${progress.configured}</b><span>de ${progress.total} configuradas</span></div>
            </div>
            <form id="logsWebhookForm" class="logs-webhook-form">
                <div class="logs-security-note">${icon("shield", 16)} <span>As URLs são salvas somente no servidor em <code>logs_config.json</code>. Deixe uma caixa vazia para desativar aquela log.</span></div>
                <div class="logs-webhook-list">${rows || `<div class="empty-state"><div><strong>Nenhuma log cadastrada</strong><p>Esta categoria ainda não possui funções de log.</p></div></div>`}</div>
                <div class="logs-save-bar">
                    <div><strong>Salvar webhooks desta aba</strong><span>Você pode preencher várias URLs e salvar todas de uma vez.</span></div>
                    <button class="button primary logs-save-button" type="submit">${icon("check", 14)} Salvar alterações</button>
                </div>
            </form>
        </div>`;
}

function renderLogs() {
    const data = state.logsAdmin;
    if (!data) {
        return `<div class="logs-page bounded-page"><div class="empty-state"><div><strong>Carregando logs...</strong><p>Consultando o catálogo e as webhooks salvas no servidor.</p></div></div></div>`;
    }

    const categories = data.categories || [];
    const category = currentLogsCategory();
    if (!category) {
        return `
            <div class="logs-page bounded-page">
                <div class="logs-hero">
                    <div class="logs-hero-icon">${icon("archive", 24)}</div>
                    <div><span>CENTRAL DE WEBHOOKS</span><strong>Logs do servidor</strong><p>Cada função possui sua própria webhook. O formato enviado ao Discord é padronizado automaticamente pelo Mage Admin.</p></div>
                    <div class="logs-global-progress"><strong>${Number(data.configured || 0)}</strong><span>de ${Number(data.total || 0)} configuradas</span></div>
                </div>
                <div class="logs-folder-grid">${renderLogsCards(categories, "category") || `<div class="empty-state"><div><strong>Nenhuma categoria</strong><p>O catálogo de logs está vazio.</p></div></div>`}</div>
            </div>`;
    }

    const subcategories = category.subcategories || [];
    const subcategory = currentLogsSubcategory(category);
    if (subcategories.length && !subcategory) {
        return `
            <div class="logs-page bounded-page">
                <div class="logs-breadcrumb-row">
                    <button type="button" class="button ghost" data-logs-back="categories">${icon("arrow", 13)} Voltar</button>
                    <div class="logs-breadcrumb-copy"><span>CATEGORIA</span><strong>${escapeHtml(category.label || "Logs")}</strong></div>
                    <div class="logs-summary-chip"><b>${logsCountForCategory(category).configured}</b><span>de ${logsCountForCategory(category).total} configuradas</span></div>
                </div>
                <div class="logs-folder-grid subcategories">${renderLogsCards(subcategories, "subcategory")}</div>
            </div>`;
    }

    return renderLogsEditor(category, subcategory);
}

function render() {
    const visible = visibleNavigation();
    if (!visible.length) {
        renderShell();
        content.innerHTML = `<div class="empty-state" style="height:100%"><div><div class="empty-icon">${icon("shield", 24)}</div><strong>Sem funções liberadas</strong><p>Seu cargo pode acessar o painel, mas ainda não recebeu nenhuma aba. Solicite a um Dono ou Developer.</p></div></div>`;
        return;
    }

    const currentMeta = NAV.find(item => item.id === state.page);
    if (!currentMeta || !canUse(currentMeta.permission)) {
        state.page = firstVisiblePage();
        state.playerView = "profile";
    }

    renderShell();

    const pages = {
        server: renderServer,
        players: renderPlayers,
        warnings: renderWarnings,
        map: renderLiveMap,
        calls: renderCalls,
        groups: renderGroups,
        identity: renderIdentityEditor,
        items: renderItems,
        weapons: renderWeapons,
        vips: renderVips,
        vehicles: renderVehicles,
        radio: renderRadio,
        locations: renderLocations,
        climate: renderClimate,
        logs: renderLogs
    };

    if (state.page !== "map") teardownLiveMap(false);
    content.innerHTML = (pages[state.page] || renderServer)();
    requestAnimationFrame(() => {
        prepareLazyImages(content);
        if (state.page === "map") initLiveMapPage();
        if (state.page === "calls" && !state.callsData) refreshCallsPanelData(false);
        if (state.page === "warnings" && !state.warningsData) refreshWarningsPanelData(true);
        if (state.page === "radio" && !state.radioAdmin) refreshRadioAdminData(true);
        if (state.page === "vips" && !state.vipAdmin) refreshVipAdminData(true);
        if (state.page === "logs" && !state.logsAdmin) refreshLogsAdminData(true);
    });
}

function parseCoordinateInput(value) {
    const raw = String(value ?? "").trim();
    if (!raw) return null;

    const parts = raw.split(",");
    if (parts.length !== 3) return null;

    const values = parts.map((part) => {
        const normalized = part.trim();
        if (!/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$/.test(normalized)) return NaN;
        return Number(normalized);
    });

    if (!values.every(Number.isFinite)) return null;
    return { x: values[0], y: values[1], z: values[2] };
}

function fieldHtml(field, defaults) {
    const value = defaults?.[field.name] ?? field.defaultValue ?? "";

    if (field.type === "textarea") {
        return `
            <div class="field full">
                <label>${escapeHtml(field.label)}</label>
                <textarea class="textarea" name="${field.name}" ${field.required ? "required" : ""} placeholder="${escapeHtml(field.placeholder || "")}">${escapeHtml(value)}</textarea>
            </div>
        `;
    }

    if (field.type === "select") {
        const options = (field.options || []).map(([v, label]) => `
            <option value="${escapeHtml(v)}" ${String(value || "") === String(v) ? "selected" : ""}>${escapeHtml(label)}</option>
        `).join("");
        return `
            <div class="field">
                <label>${escapeHtml(field.label)}</label>
                <select class="select" name="${field.name}">${options}</select>
            </div>
        `;
    }

    return `
        <div class="field${field.full ? " full" : ""}">
            <label>${escapeHtml(field.label)}</label>
            <input class="input" name="${field.name}" type="${field.type || "text"}"
                ${field.step ? `step="${field.step}"` : ""}
                ${field.min !== undefined ? `min="${field.min}"` : (field.type === "number" && !["x", "y", "z"].includes(field.name) ? 'min="1"' : "")}
                ${field.max !== undefined ? `max="${field.max}"` : ""}
                ${field.required ? "required" : ""}
                value="${escapeHtml(value)}"
                placeholder="${escapeHtml(field.placeholder || "")}">
        </div>
    `;
}

function openActionModal(action, defaults = {}, options = {}) {
    const meta = ACTIONS[action];
    if (!meta) return;

    const merged = { ...defaults };
    if (!merged.targetId && state.selectedPlayerId) merged.targetId = state.selectedPlayerId;

    // Quando a ação parte do perfil de um jogador já selecionado, o ID fica
    // preso ao jogador atual e não deve ser solicitado novamente ao administrador.
    const visibleFields = options.hideTarget
        ? meta.fields.filter(field => field.name !== "targetId")
        : meta.fields;

    const hiddenTarget = options.hideTarget && merged.targetId
        ? `<input type="hidden" name="targetId" value="${escapeHtml(merged.targetId)}">`
        : "";

    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <form class="modal" id="actionForm" data-action="${action}">
            ${hiddenTarget}
            <div class="modal-head">
                <div class="modal-title">
                    <strong>${escapeHtml(meta.title)}</strong>
                    <span>${escapeHtml(meta.description)}</span>
                </div>
                <button class="modal-close" type="button" data-modal-close>${icon("close", 14)}</button>
            </div>
            <div class="modal-body">
                ${visibleFields.length ? `<div class="field-grid">${visibleFields.map(field => fieldHtml(field, merged)).join("")}</div>` : ""}
                ${meta.danger ? `
                    <div class="confirm-box">
                        ${icon("alert", 15)}
                        <span>${meta.critical
                            ? "ATENÇÃO: esta ação é irreversível. O jogador será desconectado se estiver online, todos os registros vinculados ao ID serão apagados do banco e o ID ficará livre para outra pessoa."
                            : "Esta ação pode causar perda de dados, desconexão ou alteração imediata no servidor. Confirme somente se os dados acima estiverem corretos."}</span>
                    </div>
                ` : ""}
            </div>
            <div class="modal-foot">
                <button class="button" type="button" data-modal-close>Cancelar</button>
                <button class="button ${meta.danger ? "danger" : "primary"}" type="submit">
                    ${meta.danger ? icon("alert", 12) : icon("check", 12)}
                    ${meta.critical ? "Limpar dados definitivamente" : (meta.danger ? "Confirmar ação" : "Executar")}
                </button>
            </div>
        </form>
    `;

    requestAnimationFrame(() => {
        const first = $("#actionForm input:not([type=hidden]), #actionForm textarea, #actionForm select");
        if (first) first.focus();
    });
}

async function executeSelectedPlayerAction(action, targetId) {
    const meta = ACTIONS[action];
    const id = Number(targetId || 0);

    if (!meta || !id) {
        toast("error", "Jogador não selecionado", "Selecione um jogador antes de executar esta ação.");
        return;
    }

    // Ver Tela possui uma interface própria de vídeo e não deve cair no
    // executor administrativo genérico. Ao selecionar um player na aba
    // Jogadores, abre diretamente o mesmo monitor usado no mapa.
    if (action === "map_screen") {
        const selectedPlayer = Number(state.snapshot?.id) === id
            ? state.snapshot
            : (state.players || []).find(player => Number(player.id) === id);

        if (!selectedPlayer) {
            toast("error", "Ver tela", "Não foi possível localizar os dados deste jogador.");
            return;
        }

        await openLiveScreenModal(selectedPlayer);
        return;
    }

    const extraFields = meta.fields.filter(field => field.name !== "targetId");

    // Se o ID era o único dado necessário, executa imediatamente.
    if (extraFields.length === 0) {
        await executeAction(action, { targetId: id });
        return;
    }

    // Se ainda forem necessários motivo, mensagem, quantidade etc., abre o
    // modal somente com esses campos. O targetId segue oculto e travado.
    openActionModal(action, { targetId: id }, { hideTarget: true });
}

function formatNeedsEstimate(rate) {
    const value = Number(rate);
    if (!Number.isFinite(value) || value <= 0) return "Queda desativada";
    const minutes = 100 / value;
    if (minutes < 60) return `100% → 0% em aproximadamente ${Math.max(1, Math.round(minutes))} min`;
    const hours = Math.floor(minutes / 60);
    const remain = Math.round(minutes % 60);
    return `100% → 0% em aproximadamente ${hours}h${remain ? ` ${remain}min` : ""}`;
}

function openNeedsSettingsModal() {
    if (!canUse("needs_manage")) return;
    if (state.bootstrap?.needsEnabled === false) {
        toast("error", "Fome e sede", "Ative o sistema antes de alterar suas configurações.");
        return;
    }

    const settings = state.bootstrap?.needsSettings || {};
    const hungerRate = Number(settings.hungerPerMinute ?? 0.35);
    const thirstRate = Number(settings.thirstPerMinute ?? 0.50);
    const hungerDamage = Number(settings.hungerDamage ?? 5);
    const thirstDamage = Number(settings.thirstDamage ?? 5);
    const damageSeconds = Math.max(1, Math.round(Number(settings.starvationCheckMs || 10000) / 1000));

    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <form class="modal needs-settings-modal" id="needsSettingsForm">
            <div class="modal-head">
                <div class="modal-title">
                    <strong>Configurar fome e sede</strong>
                    <span>Defina separadamente a velocidade de queda e o dano de cada necessidade.</span>
                </div>
                <button class="modal-close" type="button" data-modal-close>${icon("close", 14)}</button>
            </div>
            <div class="modal-body needs-settings-body">
                <div class="needs-settings-info">
                    ${icon("activity", 18)}
                    <div><strong>Alterações em tempo real</strong><span>A velocidade é medida em % da barra perdida por minuto. O dano é aplicado a cada ${damageSeconds}s enquanto a respectiva barra estiver em 0%.</span></div>
                </div>
                <div class="needs-config-grid">
                    <section class="needs-config-card hunger">
                        <div class="needs-config-head">
                            <span class="needs-config-symbol">${icon("activity", 16)}</span>
                            <div><strong>Fome</strong><small id="hungerRateEstimate">${escapeHtml(formatNeedsEstimate(hungerRate))}</small></div>
                        </div>
                        <label class="field">
                            <span>Velocidade de queda (% por minuto)</span>
                            <input class="input" type="number" name="hungerPerMinute" min="0" max="100" step="0.01" value="${escapeHtml(String(hungerRate))}" required>
                            <small>0 = a fome não diminui. Quanto maior o valor, mais rápido a barra esvazia.</small>
                        </label>
                        <label class="field">
                            <span>Dano quando a fome estiver em 0%</span>
                            <input class="input" type="number" name="hungerDamage" min="0" max="100" step="1" value="${escapeHtml(String(hungerDamage))}" required>
                            <small>0 = fome zerada não causa dano.</small>
                        </label>
                    </section>
                    <section class="needs-config-card thirst">
                        <div class="needs-config-head">
                            <span class="needs-config-symbol">${icon("activity", 16)}</span>
                            <div><strong>Sede</strong><small id="thirstRateEstimate">${escapeHtml(formatNeedsEstimate(thirstRate))}</small></div>
                        </div>
                        <label class="field">
                            <span>Velocidade de queda (% por minuto)</span>
                            <input class="input" type="number" name="thirstPerMinute" min="0" max="100" step="0.01" value="${escapeHtml(String(thirstRate))}" required>
                            <small>0 = a sede não diminui. Quanto maior o valor, mais rápido a barra esvazia.</small>
                        </label>
                        <label class="field">
                            <span>Dano quando a sede estiver em 0%</span>
                            <input class="input" type="number" name="thirstDamage" min="0" max="100" step="1" value="${escapeHtml(String(thirstDamage))}" required>
                            <small>0 = sede zerada não causa dano.</small>
                        </label>
                    </section>
                </div>
                <div class="needs-settings-warning">${icon("alert", 16)}<span>Se fome e sede estiverem em 0% ao mesmo tempo, os dois valores de dano serão somados.</span></div>
            </div>
            <div class="modal-foot">
                <button class="button" type="button" data-modal-close>Cancelar</button>
                <button class="button primary" type="submit">${icon("check", 12)} Salvar configurações</button>
            </div>
        </form>
    `;

    const bindEstimate = (name, selector) => {
        const input = $(`#needsSettingsForm [name="${name}"]`);
        const output = $(selector);
        input?.addEventListener("input", () => {
            if (output) output.textContent = formatNeedsEstimate(input.value);
        });
    };
    bindEstimate("hungerPerMinute", "#hungerRateEstimate");
    bindEstimate("thirstPerMinute", "#thirstRateEstimate");

    requestAnimationFrame(() => $("#needsSettingsForm [name='hungerPerMinute']")?.focus());
}

function closeModal() {
    if (liveScreenSession) stopLiveScreenSession();
    modalRoot.classList.remove("is-open");
    modalRoot.innerHTML = "";
}

function permissionRoleSummary(roles = {}) {
    const labels = state.permissions?.roleLabels || {};
    return ["dono", "developer", "admin", "moderador", "suporte"]
        .filter(role => roles[role] === true)
        .map(role => labels[role] || role)
        .join(" • ");
}

function openPanelPermissionsModal() {
    if (!canManagePanelPermissions()) return;

    const definitions = state.permissions?.definitions || [];
    const rows = definitions.map(definition => `
        <div class="permission-function-row" data-search="${escapeHtml(`${definition.label} ${definition.category} ${definition.key}`.toLowerCase())}">
            <div class="permission-function-main">
                <span class="permission-category-pill">${escapeHtml(definition.category)}</span>
                <strong>${escapeHtml(definition.label)}</strong>
                <small>${escapeHtml(permissionRoleSummary(definition.roles))}</small>
            </div>
            <button class="button primary permission-edit-button" type="button" data-edit-panel-permission="${escapeHtml(definition.key)}">
                ${icon("shield", 13)} EDITAR PERMISSÕES
            </button>
        </div>
    `).join("");

    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <div class="modal permission-manager-modal fixed-modal">
            <div class="modal-head permission-modal-head">
                <div class="modal-title">
                    <strong>Permissões do Painel</strong>
                    <span>Gerencie a visibilidade e o acesso de cada função para Admin, Moderador e Suporte.</span>
                </div>
                <button class="modal-close" type="button" data-modal-close>${icon("close", 17)}</button>
            </div>
            <div class="modal-body permission-manager-body">
                <div class="permission-manager-note">
                    ${icon("shield", 19)}
                    <div><strong>Dono e Developer possuem acesso total permanente.</strong><span>Esses dois cargos não podem ser desmarcados. Toda alteração também é validada no servidor.</span></div>
                </div>
                <div class="search-box permission-search">
                    ${icon("search", 18)}
                    <input class="input" type="text" placeholder="Buscar função ou categoria..." data-filter-selector="#panelPermissionList [data-search]">
                </div>
                <div id="panelPermissionList" class="permission-function-list scroll-list">
                    ${rows || `<div class="empty-state"><strong>Nenhuma função encontrada</strong></div>`}
                </div>
            </div>
        </div>
    `;
}

function openPermissionEditorModal(key) {
    if (!canManagePanelPermissions()) return;
    const definition = (state.permissions?.definitions || []).find(item => item.key === key);
    if (!definition) return;

    const labels = state.permissions?.roleLabels || {};
    const roles = definition.roles || {};
    const roleCards = ["dono", "developer", "admin", "moderador", "suporte"].map(role => {
        const locked = role === "dono" || role === "developer";
        const checked = locked || roles[role] === true;
        return `
            <label class="permission-role-card ${checked ? "is-checked" : ""} ${locked ? "is-locked" : ""}">
                <input type="checkbox" name="role_${role}" value="1" ${checked ? "checked" : ""} ${locked ? "disabled" : ""}>
                <span class="permission-checkbox">${checked ? icon("check", 14) : ""}</span>
                <span class="permission-role-copy">
                    <strong>${escapeHtml(labels[role] || role)}</strong>
                    <small>${locked ? "Acesso total permanente" : checked ? "Função liberada" : "Função bloqueada"}</small>
                </span>
                ${locked ? `<span class="permission-lock-badge">FIXO</span>` : ""}
            </label>
        `;
    }).join("");

    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <form class="modal permission-editor-modal" id="panelPermissionForm" data-permission-key="${escapeHtml(key)}">
            <div class="modal-head permission-modal-head">
                <div class="modal-title">
                    <strong>${escapeHtml(definition.label)}</strong>
                    <span>${escapeHtml(definition.category)} • Escolha quais cargos podem visualizar e utilizar esta função.</span>
                </div>
                <button class="modal-close" type="button" data-modal-close>${icon("close", 17)}</button>
            </div>
            <div class="modal-body permission-editor-body">
                <button class="permission-back-button" type="button" data-back-panel-permissions>${icon("arrow", 14)} Voltar para todas as funções</button>
                <div class="permission-role-grid">${roleCards}</div>
                <div class="permission-security-note">${icon("alert", 18)}<span>Quando uma função for desmarcada, ela deixa de aparecer no painel daquele cargo e também será recusada pelo servidor.</span></div>
            </div>
            <div class="modal-foot permission-modal-foot">
                <button class="button" type="button" data-back-panel-permissions>Cancelar</button>
                <button class="button primary" type="submit">${icon("check", 13)} Salvar permissões</button>
            </div>
        </form>
    `;
}

function openWeaponAmmoModal(weapon) {
    if (!weapon) return;
    const hasAmmo = Boolean(weapon.ammo);
    const localImage = weaponLocalImage(weapon.index);
    const remoteImage = itemImage(weapon.index);
    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <form class="modal weapon-spawn-modal" id="weaponSpawnForm" data-weapon="${escapeHtml(weapon.index)}">
            <div class="modal-head">
                <div class="modal-title"><strong>Puxar arma</strong><span>${escapeHtml(weapon.category || "Armas")} • ${escapeHtml(weapon.index)}</span></div>
                <button class="modal-close" type="button" data-modal-close>${icon("close", 14)}</button>
            </div>
            <div class="modal-body">
                <div class="weapon-modal-preview">
                    <div class="weapon-modal-image"><img src="${escapeHtml(localImage)}" alt="" onerror="if(!this.dataset.remote){this.dataset.remote='1';this.src='${escapeHtml(remoteImage)}'}else{this.onerror=null;this.src='imgs/no-image.png'}"></div>
                    <div><span>ARMA SELECIONADA</span><strong>${escapeHtml(weapon.name || weapon.index)}</strong><code>${escapeHtml(weapon.index)}</code></div>
                </div>
                ${hasAmmo ? `
                    <div class="weapon-ammo-box">
                        <div class="weapon-ammo-head">${icon("package", 18)}<div><strong>Munição correspondente</strong><span>${escapeHtml(weapon.ammoName || weapon.ammo)} • ${escapeHtml(weapon.ammo)}</span></div></div>
                        <div class="field"><label>Quantidade de munição</label><input class="input" name="ammoAmount" type="number" min="0" max="100000" value="250" step="1" autofocus><small>A arma será adicionada 1x e esta quantidade será entregue no item de munição correto.</small></div>
                    </div>` : `
                    <div class="weapon-no-ammo">${icon("check", 18)}<div><strong>Esta arma não utiliza munição</strong><span>Ao confirmar, apenas 1x ${escapeHtml(weapon.index)} será adicionado ao inventário.</span></div></div>`}
                <div class="weapon-inventory-note">${icon("shield", 17)}<span>Entrega compatível com o inventário atual: a arma não é equipada pelo native <code>giveWeapons</code>; ela entra normalmente no inventário/hotbar.</span></div>
            </div>
            <div class="modal-foot"><button class="button" type="button" data-modal-close>Cancelar</button><button class="button primary" type="submit">${icon("weapon", 14)} Receber arma${hasAmmo ? " + munição" : ""}</button></div>
        </form>`;
}

function openSelfItemQuantityModal(item, name) {
    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <form class="modal" id="selfItemForm" data-item="${escapeHtml(item)}">
            <div class="modal-head">
                <div class="modal-title">
                    <strong>Spawnar item</strong>
                    <span>${escapeHtml(name || item)} • ${escapeHtml(item)}</span>
                </div>
                <button class="modal-close" type="button" data-modal-close>${icon("close", 14)}</button>
            </div>
            <div class="modal-body">
                <div class="selected-item-preview">
                    <div class="thumb">
                            <img src="${escapeHtml(itemImage(item))}" alt="" onerror="this.onerror=null;this.src='imgs/no-image.png'">
                    </div>
                    <div>
                        <strong>${escapeHtml(name || item)}</strong>
                        <span>${escapeHtml(item)}</span>
                    </div>
                </div>
                <div class="field">
                    <label>Quantidade</label>
                    <input class="input" name="amount" type="number" min="1" value="1" autofocus>
                </div>
            </div>
            <div class="modal-foot">
                <button class="button" type="button" data-modal-close>Cancelar</button>
                <button class="button primary" type="submit">Spawnar item</button>
            </div>
        </form>
    `;
}

function openQuantityModal(mode, item, targetId) {
    const title = mode === "give" ? "Adicionar item" : "Remover item";
    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <form class="modal" id="itemForm" data-mode="${mode}" data-item="${escapeHtml(item)}" data-target="${targetId || ""}">
            <div class="modal-head">
                <div class="modal-title">
                    <strong>${title}</strong>
                    <span>${escapeHtml(item)} • ID #${escapeHtml(targetId || "-")}</span>
                </div>
                <button class="modal-close" type="button" data-modal-close>${icon("close", 14)}</button>
            </div>
            <div class="modal-body">
                <div class="field">
                    <label>Quantidade</label>
                    <input class="input" name="amount" type="number" min="1" value="1" autofocus>
                </div>
                ${mode === "remove" ? `<div class="confirm-box">${icon("alert", 15)}<span>A quantidade será retirada imediatamente do inventário do jogador.</span></div>` : ""}
            </div>
            <div class="modal-foot">
                <button class="button" type="button" data-modal-close>Cancelar</button>
                <button class="button ${mode === "remove" ? "danger" : "primary"}" type="submit">${mode === "give" ? "Adicionar" : "Remover"}</button>
            </div>
        </form>
    `;
}

function openItemCatalogModal(targetId) {
    const items = state.bootstrap?.items || [];
    const cards = items.map(item => `
        <div class="item-card" data-search="${escapeHtml(`${item.name} ${item.index}`.toLowerCase())}">
            <div class="thumb">
                <img class="lazy-catalog-image" data-src="${escapeHtml(itemImage(item.index))}" data-fallback="imgs/no-image.png" loading="lazy" decoding="async" alt="">
            </div>
            <div class="item-body">
                <strong>${escapeHtml(item.name)}</strong>
                <span>${escapeHtml(item.index)}</span>
                <div class="item-actions">
                    <button class="button small success" type="button" data-add-catalog-item="${escapeHtml(item.index)}" data-target="${targetId}">${icon("plus", 11)} Adicionar</button>
                </div>
            </div>
        </div>
    `).join("");

    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <div class="modal xlarge fixed-modal">
            <div class="modal-head">
                <div class="modal-title">
                    <strong>ADD ITEM</strong>
                    <span>Selecione um item do servidor para adicionar ao ID #${escapeHtml(targetId)}.</span>
                </div>
                <button class="modal-close" type="button" data-modal-close>${icon("close", 14)}</button>
            </div>
            <div class="modal-body modal-flex-body">
                <div class="search-box">
                    ${icon("search")}
                    <input class="input" type="text" placeholder="Buscar item pelo nome ou spawn..." data-filter-selector="#addItemCatalog [data-search]">
                </div>
                <div id="addItemCatalog" class="item-grid scroll-list modal-catalog-scroll">${cards || '<div class="empty-state"><strong>Nenhum item encontrado</strong></div>'}</div>
            </div>
        </div>
    `;
    requestAnimationFrame(() => prepareLazyImages(modalRoot));
}

function resolveVehicleInput(value) {
    const raw = String(value || "").trim();
    if (!raw) return "";

    const needle = raw.toLowerCase();
    const match = (state.config.vehicles || []).find(vehicle =>
        String(vehicle.spawn || "").toLowerCase() === needle ||
        String(vehicle.name || "").toLowerCase() === needle
    );

    return match?.spawn || raw;
}

function openVehicleGarageModal(mode, targetId = "") {
    const isRemove = mode === "remove";
    const action = isRemove ? "rem_veh" : "give_veh";
    const initialTarget = Number(targetId || 0) > 0 ? Number(targetId) : "";
    const vehicles = state.config.vehicles || [];
    const cards = vehicles.map(vehicle => `
        <div class="vehicle-card vehicle-picker-card" data-search="${escapeHtml(`${vehicle.name} ${vehicle.spawn}`.toLowerCase())}">
            <div class="thumb">
                <img class="lazy-catalog-image" data-src="${escapeHtml(vehicleImage(vehicle.spawn))}" loading="lazy" decoding="async" alt="">
            </div>
            <div class="vehicle-body">
                <strong>${escapeHtml(vehicle.name)}</strong>
                <span>${escapeHtml(vehicle.spawn)}</span>
                <div class="vehicle-actions">
                    <button
                        class="button small ${isRemove ? "danger" : "success"}"
                        type="button"
                        data-garage-vehicle="${escapeHtml(vehicle.spawn)}"
                        data-garage-mode="${mode}">
                        ${icon(isRemove ? "minus" : "plus", 11)} ${isRemove ? "Remover" : "Dar"}
                    </button>
                </div>
            </div>
        </div>
    `).join("");

    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <div class="modal xlarge fixed-modal vehicle-garage-modal" data-vehicle-garage-action="${action}" data-vehicle-garage-mode="${mode}">
            <div class="modal-head">
                <div class="modal-title">
                    <strong>${isRemove ? "REMOVER VEÍCULO" : "DAR VEÍCULO"}</strong>
                    <span>Informe o jogador e o veículo ou selecione um veículo no catálogo abaixo.</span>
                </div>
                <button class="modal-close" type="button" data-modal-close>${icon("close", 14)}</button>
            </div>

            <div class="modal-body vehicle-garage-body">
                <div class="vehicle-manual-box vehicle-direct-box">
                    <div class="vehicle-manual-copy">
                        <span class="inventory-eyebrow">AÇÃO RÁPIDA</span>
                        <strong>${isRemove ? "Remover da garagem" : "Adicionar à garagem"}</strong>
                        <p>Digite o passaporte e o nome ou spawn do veículo.</p>
                    </div>
                    <form class="vehicle-manual-form vehicle-direct-form" id="vehicleGarageManualForm" data-action="${action}">
                        <div class="vehicle-direct-field">
                            <label>Passaporte / ID</label>
                            <input id="vehicleGarageTarget" class="input" name="targetId" type="number" min="1" autocomplete="off" value="${escapeHtml(initialTarget)}" placeholder="Ex.: 15" required>
                        </div>
                        <div class="vehicle-direct-field">
                            <label>Nome / Spawn do veículo</label>
                            <input id="vehicleGarageSpawn" class="input" name="vehicle" type="text" autocomplete="off" placeholder="Ex.: Sultan ou sultan" required>
                        </div>
                        <button class="button ${isRemove ? "danger" : "primary"} vehicle-direct-submit" type="submit">
                            ${icon(isRemove ? "trash" : "plus", 12)} ${isRemove ? "Remover veículo" : "Dar veículo"}
                        </button>
                    </form>
                </div>

                <div class="vehicle-picker-tools">
                    <div class="search-box">
                        ${icon("search")}
                        <input class="input" type="text" placeholder="Buscar veículo pelo nome ou spawn..." data-filter-selector="#vehicleGarageCatalog [data-search]">
                    </div>
                </div>

                <div id="vehicleGarageCatalog" class="vehicle-grid scroll-list modal-catalog-scroll vehicle-picker-grid">
                    ${cards || '<div class="empty-state"><strong>Nenhum veículo encontrado</strong></div>'}
                </div>
            </div>
        </div>
    `;

    requestAnimationFrame(() => {
        const targetInput = $("#vehicleGarageTarget");
        const spawnInput = $("#vehicleGarageSpawn");
        (initialTarget ? spawnInput : targetInput)?.focus();
    });
    requestAnimationFrame(() => prepareLazyImages(modalRoot));
}

function openAddVehicleCatalogModal() {
    const selected = state.vehicleCategory === "addon" ? "addon" : "game";

    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <form class="modal" id="vehicleCatalogForm">
            <div class="modal-head">
                <div class="modal-title">
                    <strong>ADICIONAR VEÍCULO</strong>
                    <span>Cadastre um spawn no catálogo administrativo.</span>
                </div>
                <button class="modal-close" type="button" data-modal-close>${icon("close", 14)}</button>
            </div>
            <div class="modal-body">
                <div class="field full">
                    <label>Spawn do veículo</label>
                    <input class="input" name="spawn" type="text" maxlength="80" placeholder="Ex.: sultan ou audirs6" autocomplete="off" required autofocus>
                </div>
                <div class="field full">
                    <label>Categoria</label>
                    <select class="select" name="category" required>
                        <option value="game" ${selected === "game" ? "selected" : ""}>Veículos do jogo</option>
                        <option value="addon" ${selected === "addon" ? "selected" : ""}>Veículos addon</option>
                    </select>
                </div>
            </div>
            <div class="modal-foot">
                <button class="button" type="button" data-modal-close>Cancelar</button>
                <button class="button primary" type="submit">${icon("plus", 12)} Adicionar veículo</button>
            </div>
        </form>
    `;
}

function openAddLocationCategoryModal() {
    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <form class="modal" id="locationCategoryForm">
            <div class="modal-head">
                <div class="modal-title">
                    <strong>NOVA CATEGORIA</strong>
                    <span>Crie uma categoria para organizar os locais administrativos.</span>
                </div>
                <button class="modal-close" type="button" data-modal-close>${icon("close", 14)}</button>
            </div>
            <div class="modal-body">
                <div class="field full">
                    <label>Nome da categoria</label>
                    <input class="input" name="name" type="text" maxlength="60" placeholder="Ex.: Mafia, Cartel, Vermelho" required autofocus>
                </div>
            </div>
            <div class="modal-foot">
                <button class="button" type="button" data-modal-close>Cancelar</button>
                <button class="button primary" type="submit">Criar categoria</button>
            </div>
        </form>
    `;
}

function openDeleteLocationModal(index) {
    const location = (state.config.locations || []).find(item => Number(item.index) === Number(index));
    if (!location) {
        toast("error", "Locais", "Não foi possível localizar este local.");
        return;
    }

    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <form class="modal" id="deleteLocationForm" data-location-index="${Number(location.index)}">
            <div class="modal-head">
                <div class="modal-title">
                    <strong>APAGAR LOCAL</strong>
                    <span>Confirme a remoção deste local cadastrado.</span>
                </div>
                <button class="modal-close" type="button" data-modal-close>${icon("close", 14)}</button>
            </div>
            <div class="modal-body">
                <div class="confirm-box">
                    ${icon("alert", 15)}
                    <span>Você está prestes a apagar <strong>${escapeHtml(location.name)}</strong> da categoria <strong>${escapeHtml(location.category || "Geral")}</strong>. Esta ação remove o ponto do arquivo de locais imediatamente.</span>
                </div>
                <div class="location-delete-preview">
                    <span>${escapeHtml(location.name)}</span>
                    <small>${Number(location.x).toFixed(2)}, ${Number(location.y).toFixed(2)}, ${Number(location.z).toFixed(2)}</small>
                </div>
            </div>
            <div class="modal-foot">
                <button class="button" type="button" data-modal-close>Cancelar</button>
                <button class="button danger" type="submit">${icon("trash", 12)} Apagar local</button>
            </div>
        </form>
    `;
}

function openAddLocationModal() {
    const categories = locationCategories();
    const selected = state.locationCategory && categories.includes(state.locationCategory) ? state.locationCategory : (categories.find(category => category.toLocaleLowerCase("pt-BR") === "geral") || categories[0] || "Geral");
    const options = categories.map(category => `<option value="${escapeHtml(category)}" ${category === selected ? "selected" : ""}>${escapeHtml(category)}</option>`).join("");

    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <form class="modal location-modal" id="locationForm">
            <div class="modal-head">
                <div class="modal-title">
                    <strong>ADD LOCAL</strong>
                    <span>Cadastre um novo ponto de teleporte administrativo.</span>
                </div>
                <button class="modal-close" type="button" data-modal-close>${icon("close", 14)}</button>
            </div>
            <div class="modal-body">
                <div class="field full">
                    <label>Nome</label>
                    <input class="input" name="name" type="text" maxlength="80" placeholder="Ex.: Praça Central" required autofocus>
                </div>

                <div class="field full">
                    <label>Categoria</label>
                    <select class="input location-category-select" name="category" id="locationCategorySelect">
                        ${options}
                        <option value="__new__">+ Criar nova categoria</option>
                    </select>
                </div>

                <div id="newLocationCategoryField" class="field full is-hidden">
                    <label>Nova categoria</label>
                    <input class="input" name="newCategory" type="text" maxlength="60" placeholder="Ex.: Mafia">
                </div>

                <div class="field full location-coordinate-field">
                    <label>Coordenada</label>
                    <button class="coordinate-selector" type="button" data-coordinate-selector>
                        <span id="coordinateSelectorText">Selecionar como definir a coordenada</span>
                        ${icon("arrow", 12)}
                    </button>
                    <div id="coordinateOptions" class="coordinate-options is-hidden">
                        <button type="button" data-coordinate-mode="typed">
                            <span class="coordinate-option-icon">${icon("copy", 15)}</span>
                            <span><strong>Digitar coordenada</strong><small>Cole X,Y,Z em um único campo.</small></span>
                        </button>
                        <button type="button" data-coordinate-mode="game">
                            <span class="coordinate-option-icon">${icon("target", 15)}</span>
                            <span><strong>Definir no jogo</strong><small>Feche o painel e pressione E no local desejado.</small></span>
                        </button>
                    </div>
                    <input id="coordinateMode" type="hidden" name="coordMode" value="">
                </div>

                <div id="typedCoordinates" class="form-grid is-hidden">
                    <div class="field full">
                        <label>Coordenada (X,Y,Z)</label>
                        <input class="input" name="coords" type="text" autocomplete="off" placeholder="Ex.: 46.63,-899.06,29.98">
                    </div>
                </div>

                <div id="gameCoordinateHint" class="capture-hint is-hidden">
                    ${icon("target", 16)}
                    <span>Ao confirmar, o painel será fechado. Vá até a posição desejada e pressione <strong>E</strong> para salvar o local.</span>
                </div>
            </div>
            <div class="modal-foot">
                <button class="button" type="button" data-modal-close>Cancelar</button>
                <button id="locationSubmit" class="button primary" type="submit">Cadastrar local</button>
            </div>
        </form>
    `;
}

function openIdentityModal(player) {
    const i = player.identity || {};
    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <div class="modal large">
            <div class="modal-head">
                <div class="modal-title">
                    <strong>RG completo • ID #${player.id}</strong>
                    <span>${escapeHtml(player.name)} • ${player.online ? "online" : "offline"}</span>
                </div>
                <button class="modal-close" type="button" data-modal-close>${icon("close", 14)}</button>
            </div>
            <div class="modal-body">
                <div class="identity-grid">
                    <div class="identity-item"><span>Nome</span><strong>${escapeHtml(player.name)}</strong></div>
                    <div class="identity-item"><span>Idade</span><strong>${escapeHtml(i.idade)}</strong></div>
                    <div class="identity-item"><span>Telefone</span><strong>${escapeHtml(i.telefone)}</strong></div>
                    <div class="identity-item"><span>Registro</span><strong>${escapeHtml(i.registro)}</strong></div>
                    <div class="identity-item"><span>Carteira</span><strong>${formatMoney(player.wallet)}</strong></div>
                    <div class="identity-item"><span>Banco</span><strong>${formatMoney(player.bank)}</strong></div>
                    <div class="identity-item"><span>Multas</span><strong>${formatMoney(player.fines)}</strong></div>
                    <div class="identity-item"><span>Bucket</span><strong>${player.bucket ?? "-"}</strong></div>
                    <div class="identity-item"><span>Ping</span><strong>${player.online ? `${player.ping ?? 0}ms` : "-"}</strong></div>
                </div>
                <div class="detail-section">
                    <div class="detail-section-head"><strong>Cargos</strong><span>${(player.groups || []).length} grupo(s)</span></div>
                    <div class="tag-list">${(player.groups || []).map(group => `<span class="tag">${escapeHtml(group)}</span>`).join("") || '<span class="tag">Nenhum cargo carregado</span>'}</div>
                </div>
            </div>
            <div class="modal-foot">
                <button class="button primary" type="button" data-modal-close>Fechar</button>
            </div>
        </div>
    `;
}


function openIdentityEditModal(field) {
    const p = state.identityEditor;
    if (!p?.id) return;

    const i = p.identity || {};
    const definitions = {
        id: { label: "ID", value: p.id, type: "number", permission: "change_user_id", placeholder: "Ex.: 10" },
        nome: { label: "Nome", value: i.nome ?? "", type: "text", permission: "edit_identity", placeholder: "Digite o novo nome" },
        sobrenome: { label: "Sobrenome", value: i.sobrenome ?? "", type: "text", permission: "edit_identity", placeholder: "Digite o novo sobrenome" },
        idade: { label: "Idade", value: i.idade ?? "", type: "number", permission: "edit_identity", placeholder: "Ex.: 25" },
        telefone: { label: "Telefone", value: i.telefone ?? "", type: "text", permission: "edit_identity", placeholder: "Digite o novo telefone" },
        registro: { label: "RG", value: i.registro ?? "", type: "text", permission: "edit_identity", placeholder: "Digite o novo RG" },
        wallet: { label: "Carteira", value: Number(p.wallet || 0), type: "number", permission: "edit_identity_balance", placeholder: "Ex.: 5000", balance: true },
        bank: { label: "Banco", value: Number(p.bank || 0), type: "number", permission: "edit_identity_balance", placeholder: "Ex.: 50000", balance: true }
    };

    const def = definitions[field];
    if (!def || !canUse(def.permission)) return;
    const changingId = field === "id";
    const changingBalance = field === "wallet" || field === "bank";

    modalRoot.classList.add("is-open");
    modalRoot.innerHTML = `
        <form class="modal identity-edit-modal" id="identityEditForm" data-field="${field}" data-target-id="${p.id}">
            <div class="modal-head">
                <div class="modal-title">
                    <strong>Editar ${escapeHtml(def.label)}</strong>
                    <span>${escapeHtml(p.name)} • Passaporte #${p.id}</span>
                </div>
                <button class="modal-close" type="button" data-modal-close>${icon("close", 14)}</button>
            </div>
            <div class="modal-body">
                <div class="field full">
                    <label>Novo ${escapeHtml(def.label)}</label>
                    <input class="input" name="value" type="${def.type}" ${def.type === "number" ? `min="${changingBalance ? 0 : 1}" step="1"` : 'maxlength="80"'} value="${escapeHtml(def.value)}" placeholder="${escapeHtml(def.placeholder)}" autocomplete="off" required autofocus>
                </div>
                ${changingId ? `
                    <div class="identity-id-warning">
                        ${icon("alert", 17)}
                        <div>
                            <strong>Alteração de Passaporte</strong>
                            <p>O novo ID será aplicado em todas as tabelas com <code>user_id</code> e também em <code>vrp_users</code>. Se o novo ID já estiver em uso, a alteração será bloqueada. O ID antigo ficará livre após a troca. Se o jogador estiver online, ele será desconectado para a vRP salvar os dados antigos antes da alteração.</p>
                        </div>
                    </div>
                ` : ""}
                ${changingBalance ? `
                    <div class="identity-id-warning">
                        ${icon("wallet", 17)}
                        <div>
                            <strong>Alteração de ${field === "wallet" ? "Carteira" : "Banco"}</strong>
                            <p>${field === "wallet" ? "A carteira usa o dinheiro do inventário. O saldo atual será substituído pelo valor informado e o jogador precisa estar online." : "O saldo bancário será definido exatamente para o novo valor informado pela própria vRP."}</p>
                        </div>
                    </div>
                ` : ""}
            </div>
            <div class="modal-foot">
                <button class="button" type="button" data-modal-close>Cancelar</button>
                <button class="button primary" type="submit">${icon("check", 14)} Salvar alteração</button>
            </div>
        </form>
    `;
}

async function loadIdentityEditor(id, renderAfter = true) {
    const targetId = Number(id);
    if (!targetId || targetId < 1) {
        toast("error", "Passaporte inválido", "Informe um ID maior que zero.");
        return false;
    }

    const response = await post("identityEditor", { mode: "get", targetId });
    if (!response?.ok) {
        toast("error", "Não foi possível carregar", response?.message || "Jogador não encontrado.");
        return false;
    }

    state.selectedPlayerId = targetId;
    state.identityEditor = response.data;
    if (renderAfter) render();
    return true;
}

function applyIdentityLiveUpdate(payload, shouldRender = true) {
    const data = payload && typeof payload === "object" ? payload : {};
    const id = Number(data.id || 0);
    if (!id) return;

    const identity = data.identity && typeof data.identity === "object" ? data.identity : {};
    const fullName = String(data.name || `${identity.nome || ""} ${identity.sobrenome || ""}`).replace(/\s+/g, " ").trim();

    if (state.identityEditor && Number(state.identityEditor.id) === id) {
        state.identityEditor = {
            ...state.identityEditor,
            name: fullName || state.identityEditor.name,
            identity: { ...(state.identityEditor.identity || {}), ...identity }
        };
    }

    if (state.snapshot && Number(state.snapshot.id) === id) {
        state.snapshot = {
            ...state.snapshot,
            name: fullName || state.snapshot.name,
            identity: { ...(state.snapshot.identity || {}), ...identity }
        };
    }

    if (state.bootstrap?.players) {
        state.bootstrap.players = state.bootstrap.players.map(player =>
            Number(player.id) === id
                ? { ...player, name: fullName || player.name, identity: { ...(player.identity || {}), ...identity } }
                : player
        );
    }

    if (Array.isArray(state.mapPlayers)) {
        state.mapPlayers = state.mapPlayers.map(player =>
            Number(player.id) === id ? { ...player, name: fullName || player.name } : player
        );
    }

    if (state.bootstrap?.admin && Number(state.bootstrap.admin.id) === id && fullName) {
        state.bootstrap.admin.name = fullName;
    }

    if (state.warningsData?.players) {
        state.warningsData.players = state.warningsData.players.map(player =>
            Number(player.id) === id
                ? { ...player, nome: identity.nome ?? player.nome, sobrenome: identity.sobrenome ?? player.sobrenome }
                : player
        );
    }

    if (shouldRender && state.open) render();
}

async function refreshPlayers(showToast = true) {
    // Atualizações automáticas/silenciosas não devem tocar o CONFIRM_BEEP.
    // O som fica reservado ao clique manual no botão de atualizar.
    const response = await post("refreshPlayers", { silent: !showToast });
    if (!response?.ok) {
        if (showToast) toast("error", "Falha ao atualizar", response?.message || "Erro desconhecido.");
        return;
    }

    state.bootstrap.players = response.data.players || [];
    state.bootstrap.stats = response.data.stats || state.bootstrap.stats;

    if (state.selectedPlayerId && !state.bootstrap.players.some(p => Number(p.id) === Number(state.selectedPlayerId))) {
        state.snapshot = state.snapshot ? { ...state.snapshot, online: false, source: null, ping: 0 } : null;
    }

    render();
    if (showToast) toast("success", "Jogadores atualizados", response.message || "Lista sincronizada.");
}

async function loadSnapshot(id, renderAfter = true) {
    const targetId = Number(id);
    if (!targetId || targetId < 1) {
        toast("error", "Passaporte inválido", "Informe um ID maior que zero.");
        return false;
    }

    const response = await post("playerSnapshot", { targetId });
    if (!response?.ok) {
        toast("error", "Não foi possível carregar", response?.message || "Jogador não encontrado.");
        return false;
    }

    state.selectedPlayerId = targetId;
    state.snapshot = response.data;
    if (renderAfter) render();
    return true;
}

async function executeAction(action, payload = {}) {
    const response = await post("execute", { action, payload });
    if (!response?.ok) {
        toast("error", actionLabel(action), response?.message || "A ação falhou.");
        return false;
    }

    addHistory(actionLabel(action));
    toast("success", actionLabel(action), response.message || "Ação executada.");

    if (action === "needs_manage" && response.data?.needsEnabled !== undefined) {
        if (state.bootstrap) state.bootstrap.needsEnabled = response.data.needsEnabled === true;
        render();
    }

    if (response.data?.kind === "identity" && response.data.player) {
        openIdentityModal(response.data.player);
    } else {
        closeModal();
    }

    if (response.data?.id) {
        state.snapshot = response.data;
        state.selectedPlayerId = response.data.id;
        if (response.data.warningSummary) state.warningsData = response.data.warningSummary;
        render();
    }

    if (["kick", "ban", "wipe_user_data"].includes(action)) {
        setTimeout(() => refreshPlayers(false), action === "wipe_user_data" ? 700 : 350);
    }

    if (action === "wipe_user_data") {
        state.warningsData = null;
        state.identityEditor = null;
        if (state.snapshot && Number(state.snapshot.id) === Number(payload.targetId || 0)) {
            state.snapshot = null;
            state.selectedPlayerId = null;
        }
    }

    if (["tpto", "tptome", "tpway", "tpcds", "spawn_veh"].includes(action)) {
        await closeNui();
    }

    return true;
}

async function closeNui() {
    setOpen(false);
    await post("close");
}

function filterBySelector(input) {
    const selector = input.dataset.filterSelector;
    if (!selector) return;

    const query = input.value.trim().toLowerCase();
    const elements = $$(selector);

    for (const el of elements) {
        const haystack = el.dataset.search || "";
        el.classList.toggle("is-filtered-out", Boolean(query) && !haystack.includes(query));
    }
}

document.addEventListener("click", async event => {

    const playerVipChoose = event.target.closest("[data-player-vip-choose]");
    if (playerVipChoose) {
        if (playerVipActionBusy) return;
        playerVipActionBusy = true;
        const vehicle = playerVipChoose.dataset.playerVipChoose;
        const assignmentId = Number(playerVipChoice?.assignmentId || 0) || undefined;
        playerVipChoose.disabled = true;
        try {
            const response = await post("vipPlayer", { mode: "choose", vehicle, assignmentId });
            if (!response?.ok) {
                playerVipChoose.disabled = false;
                if (response?.data) renderPlayerVipChoice(response.data);
                toast("error", "VIP", response?.message || "Não foi possível escolher este veículo.");
                return;
            }
            if (response.data?.completed) renderPlayerVipChoice(null);
            else renderPlayerVipChoice(response.data);
        } finally {
            playerVipActionBusy = false;
        }
        return;
    }

    const playerVipTest = event.target.closest("[data-player-vip-test]");
    if (playerVipTest) {
        if (playerVipActionBusy) return;
        playerVipActionBusy = true;
        const vehicle = playerVipTest.dataset.playerVipTest;
        const assignmentId = Number(playerVipChoice?.assignmentId || 0) || undefined;
        playerVipTest.disabled = true;
        try {
            const response = await post("vipPlayer", { mode: "startTest", vehicle, assignmentId });
            if (!response?.ok) {
                playerVipTest.disabled = false;
                if (response?.data) renderPlayerVipChoice(response.data);
                toast("error", "Teste VIP", response?.message || "Não foi possível iniciar o teste.");
            } else {
                // O servidor ja autorizou e disparou o test-drive para a bridge
                // client aberta. Fecha o seletor imediatamente para jamais
                // deixar a tela presa enquanto o client faz streaming do carro.
                renderPlayerVipChoice(null);
            }
        } finally {
            playerVipActionBusy = false;
        }
        return;
    }

    if (event.target.closest("[data-vip-create]")) { openVipEditorModal(); return; }
    const vipEdit = event.target.closest("[data-vip-edit]");
    if (vipEdit) { openVipEditorModal(vipEdit.dataset.vipEdit); return; }
    const vipDelete = event.target.closest("[data-vip-delete]");
    if (vipDelete) { openVipDeleteModal(vipDelete.dataset.vipDelete); return; }
    const vipAssign = event.target.closest("[data-vip-assign]");
    if (vipAssign) { if (canUse("assign_vip")) openVipAssignModal(vipAssign.dataset.vipAssign); return; }
    if (event.target.closest("[data-vip-refresh]")) {
        const response = await refreshVipAdminData(false);
        if (response?.ok) toast("success", "VIPs", "Lista de VIPs atualizada diretamente da vRP.");
        else toast("error", "VIPs", response?.message || "Não foi possível atualizar os VIPs.");
        return;
    }
    if (event.target.closest("[data-vip-open-items]")) { renderVipItemsPicker(); return; }
    if (event.target.closest("[data-vip-open-vehicles]")) { renderVipVehiclesPicker(); return; }
    if (event.target.closest("[data-vip-picker-back]")) { renderVipEditorModal(); return; }

    const vipItemToggle = event.target.closest("[data-vip-item-toggle]");
    if (vipItemToggle && vipEditorDraft) {
        const item = vipItemToggle.dataset.vipItemToggle;
        const pos = vipEditorDraft.items.findIndex(entry => entry.item === item);
        const selecting = pos < 0;

        if (selecting) vipEditorDraft.items.push({ item, amount: 1 });
        else vipEditorDraft.items.splice(pos, 1);

        // Atualiza apenas o card clicado. Não reconstruir o modal preserva
        // scroll, busca e posição visual mesmo em catálogos grandes.
        const card = vipItemToggle.closest(".vip-picker-card");
        if (card) {
            card.classList.toggle("is-selected", selecting);

            const amountWrap = card.querySelector(".vip-picker-amount");
            const amountInput = card.querySelector("[data-vip-item-amount]");
            const check = card.querySelector(".vip-picker-check");

            amountWrap?.classList.toggle("is-disabled", !selecting);
            if (amountInput) {
                amountInput.disabled = !selecting;
                if (selecting) amountInput.value = "1";
            }
            if (check) check.innerHTML = selecting ? icon("check", 13) : "";
        }

        const count = modalRoot.querySelector(".vip-picker-selected-count");
        if (count) count.textContent = `${vipEditorDraft.items.length} item(ns) selecionado(s)`;
        return;
    }

    const vipVehicleToggle = event.target.closest("[data-vip-vehicle-toggle]");
    if (vipVehicleToggle && vipEditorDraft) {
        const spawn = String(vipVehicleToggle.dataset.vipVehicleToggle || "").toLowerCase();
        const pos = vipEditorDraft.vehicles.findIndex(entry => String(entry.spawn).toLowerCase() === spawn);
        let selecting = pos < 0;

        if (!selecting) {
            vipEditorDraft.vehicles.splice(pos, 1);
        } else {
            const vehicle = (state.vipAdmin?.vehicles || []).find(entry => String(entry.spawn).toLowerCase() === spawn);
            if (vehicle) vipEditorDraft.vehicles.push({ spawn: vehicle.spawn, name: vehicle.name || vehicle.spawn, category: vehicle.category || "game" });
            else selecting = false;
        }

        if (!vipEditorDraft.vehicles.length) vipEditorDraft.vehicleChoices = 0;
        else vipEditorDraft.vehicleChoices = Math.min(Math.max(1, Number(vipEditorDraft.vehicleChoices || 1)), vipEditorDraft.vehicles.length);

        // Mesma regra dos itens: altera somente o card selecionado para não
        // zerar o scroll nem a busca ao marcar/desmarcar um veículo.
        const card = vipVehicleToggle.closest(".vip-vehicle-picker-card");
        if (card) {
            card.classList.toggle("is-selected", selecting);
            const check = card.querySelector(".vip-picker-check");
            if (check) check.innerHTML = selecting ? icon("check", 13) : "";
        }

        const count = modalRoot.querySelector(".vip-picker-selected-count");
        if (count) count.textContent = `${vipEditorDraft.vehicles.length} veículo(s) selecionado(s)`;
        return;
    }

    const radioAdd = event.target.closest("[data-radio-add]");
    if (radioAdd) { openRadioEditorModal(); return; }

    const radioEdit = event.target.closest("[data-radio-edit]");
    if (radioEdit) { openRadioEditorModal(Number(radioEdit.dataset.radioEdit)); return; }

    const radioDelete = event.target.closest("[data-radio-delete]");
    if (radioDelete) { openRadioDeleteModal(Number(radioDelete.dataset.radioDelete)); return; }

    const radioRefresh = event.target.closest("[data-radio-refresh]");
    if (radioRefresh) {
        const response = await refreshRadioAdminData(false);
        if (response?.ok) toast("success", "Rádio", "Lista de rádios privadas atualizada.");
        else toast("error", "Rádio", response?.message || "Não foi possível atualizar as rádios.");
        return;
    }

    const navButton = event.target.closest("[data-nav]");
    if (navButton) {
        state.page = navButton.dataset.nav;
        if (state.page === "players") state.playerView = "profile";
        if (state.page === "vehicles") state.vehicleCategory = "game";
        if (state.page === "radio" && !state.radioAdmin) refreshRadioAdminData(true);
        if (state.page === "calls") { state.callsView = "open"; state.callsData = null; }
        if (state.page === "warnings") state.warningsData = null;
        if (state.page === "logs") {
            state.logsCategoryId = null;
            state.logsSubcategoryId = null;
            state.logsAdmin = null;
        }
        render();
        return;
    }



    const logsCategoryButton = event.target.closest("[data-logs-category]");
    if (logsCategoryButton) {
        state.logsCategoryId = logsCategoryButton.dataset.logsCategory;
        state.logsSubcategoryId = null;
        render();
        return;
    }

    const logsSubcategoryButton = event.target.closest("[data-logs-subcategory]");
    if (logsSubcategoryButton) {
        state.logsSubcategoryId = logsSubcategoryButton.dataset.logsSubcategory;
        render();
        return;
    }

    const logsBackButton = event.target.closest("[data-logs-back]");
    if (logsBackButton) {
        if (logsBackButton.dataset.logsBack === "subcategories") {
            state.logsSubcategoryId = null;
        } else {
            state.logsCategoryId = null;
            state.logsSubcategoryId = null;
        }
        render();
        return;
    }

    const callsViewButton = event.target.closest("[data-calls-view]");
    if (callsViewButton) {
        state.callsView = callsViewButton.dataset.callsView || "open";
        render();
        if (state.callsView !== "open") refreshCallsPanelData(false, state.callsView);
        return;
    }

    if (event.target.closest("[data-calls-refresh]")) {
        state.callsData = null;
        render();
        await refreshCallsPanelData(true);
        return;
    }

    const acceptStaffCall = event.target.closest("[data-staff-call-accept]");
    if (acceptStaffCall) {
        const response = await post("calls", { mode: "acceptStaff", callId: Number(acceptStaffCall.dataset.staffCallAccept) });
        if (!response?.ok) { toast("error", "Chamados", response?.message || "Não foi possível aceitar o chamado."); return; }
        state.callsData = response.data || state.callsData;
        toast("success", "Chamado aceito", response.message || "Você assumiu o atendimento.");
        render();
        return;
    }

    const finishStaffCall = event.target.closest("[data-staff-call-finish]");
    if (finishStaffCall) {
        const response = await post("calls", { mode: "finishStaff", callId: Number(finishStaffCall.dataset.staffCallFinish) });
        if (!response?.ok) { toast("error", "Chamados", response?.message || "Não foi possível finalizar o chamado."); return; }
        state.callsData = response.data || state.callsData;
        toast("success", "Chamado finalizado", response.message || "Atendimento arquivado.");
        render();
        return;
    }

    const playerCallType = event.target.closest("[data-player-call-type]");
    if (playerCallType) {
        playerCallMenuState.department = playerCallType.dataset.playerCallType;
        renderPlayerCallMenu();
        return;
    }

    if (event.target.closest("[data-player-call-back]")) {
        playerCallMenuState.department = null;
        renderPlayerCallMenu();
        return;
    }

    if (event.target.closest("[data-call-menu-close]")) {
        playerCallMenuState = { open: false, department: null };
        renderPlayerCallMenu();
        await post("callUi", { mode: "closeMenu" });
        return;
    }

    const dismissSector = event.target.closest("[data-sector-call-dismiss]");
    if (dismissSector) {
        const callId = Number(dismissSector.dataset.sectorCallDismiss);
        sectorCalls.delete(callId);
        renderSectorCalls();
        await post("callUi", { mode: "sectorDismiss", callId });
        return;
    }

    const acceptSector = event.target.closest("[data-sector-call-accept]");
    if (acceptSector) {
        const callId = Number(acceptSector.dataset.sectorCallAccept);
        const response = await post("calls", { mode: "sectorAccept", callId });
        if (!response?.ok) {
            sectorCalls.delete(callId);
            renderSectorCalls();
            toast("error", "Chamado", response?.message || "Este chamado não está mais disponível.");
        } else {
            sectorFocused = false;
            renderSectorCalls();
            await post("callUi", { mode: "releaseSectorFocus" });
        }
        return;
    }

    const evalStar = event.target.closest("[data-evaluation-star]");
    if (evalStar && evaluationState) {
        evaluationState.stars = Number(evalStar.dataset.evaluationStar || 0);
        renderCallEvaluation();
        return;
    }

    if (event.target.closest("[data-evaluation-message]") && evaluationState) {
        if (evaluationState.showMessage) {
            evaluationState.message = $("#evaluationMessage")?.value || evaluationState.message || "";
        }
        evaluationState.showMessage = !evaluationState.showMessage;
        renderCallEvaluation();
        return;
    }

    if (event.target.closest("[data-evaluation-submit]") && evaluationState) {
        const stars = Number(evaluationState.stars || 0);
        if (stars < 1 || stars > 5) return;
        const message = evaluationState.showMessage ? ($("#evaluationMessage")?.value || "") : "";
        const response = await post("calls", { mode: "rate", callId: Number(evaluationState.callId), stars, message });
        if (!response?.ok) return;
        evaluationState = null;
        renderCallEvaluation();
        await post("callUi", { mode: "evaluationDone" });
        return;
    }

        const mapPlayerButton = event.target.closest("[data-map-player]");
    if (mapPlayerButton) {
        liveMapSelectedId = Number(mapPlayerButton.dataset.mapPlayer);
        const source = mapPlayerButton.dataset.mapSource || "marker";
        updateLiveMapDom();
        if (source === "list") focusLiveMapPlayer(liveMapSelectedId);
        return;
    }

    if (event.target.closest("[data-map-popup-close]")) {
        liveMapSelectedId = null;
        updateLiveMapDom();
        return;
    }

    const mapZoomButton = event.target.closest("[data-map-zoom]");
    if (mapZoomButton) {
        changeLiveMapZoom(mapZoomButton.dataset.mapZoom);
        updateMapPopup();
        return;
    }

    const mapActionButton = event.target.closest("[data-map-action]");
    if (mapActionButton) {
        const action = mapActionButton.dataset.mapAction;
        const targetId = Number(mapActionButton.dataset.mapTarget || 0);
        const player = (state.mapPlayers || []).find(entry => Number(entry.id) === targetId);
        if (!targetId || !player) return;
        if (action === "map_screen") {
            await openLiveScreenModal(player);
        } else {
            await executeAction(action, { targetId });
            if (state.page === "map") setTimeout(() => refreshLiveMap(true), 200);
        }
        return;
    }

    const navTarget = event.target.closest("[data-nav-target]");
    if (navTarget) {
        const id = Number(navTarget.dataset.target);
        if (id) await loadSnapshot(id, false);
        state.page = navTarget.dataset.navTarget;
        render();
        return;
    }

    const identityEditButton = event.target.closest("[data-identity-edit]");
    if (identityEditButton) {
        openIdentityEditModal(identityEditButton.dataset.identityEdit);
        return;
    }

    if (event.target.closest("[data-modal-close]")) {
        closeModal();
        return;
    }

    if (event.target.closest("[data-open-panel-permissions]")) {
        if (!canManagePanelPermissions()) return;
        const response = await post("panelPermissions", { mode: "get" });
        if (!response?.ok) {
            toast("error", "Permissões do Painel", response?.message || "Não foi possível carregar as permissões.");
            return;
        }
        state.permissions = response.data;
        if (state.bootstrap) state.bootstrap.permissions = response.data;
        openPanelPermissionsModal();
        return;
    }

    const permissionEdit = event.target.closest("[data-edit-panel-permission]");
    if (permissionEdit) {
        openPermissionEditorModal(permissionEdit.dataset.editPanelPermission);
        return;
    }

    if (event.target.closest("[data-back-panel-permissions]")) {
        openPanelPermissionsModal();
        return;
    }

    if (event.target.closest("[data-inspect-inventory]")) {
        if (!canUse("inspect_inventory")) return;
        if (!state.snapshot?.online) {
            toast("error", "Inventário", "O jogador precisa estar online para inspecionar o inventário.");
            return;
        }
        post("auditAction", { key: "inspect_inventory", targetId: Number(state.snapshot?.id || state.selectedPlayerId) });
        state.playerView = "inventory";
        render();
        return;
    }

    if (event.target.closest("[data-player-profile]")) {
        state.playerView = "profile";
        state.locationCategory = null;
        state.environment = state.bootstrap?.environment || null;
        state.mapPlayers = state.bootstrap?.players || [];
        liveMapSelectedId = null;
        liveMapTransform = { scale: 1, x: 0, y: 0 };
        liveMapFullscreen = false;
        render();
        return;
    }

    if (event.target.closest("[data-open-item-catalog]")) {
        if (!canUse("give_item")) return;
        const targetId = state.snapshot?.id || state.selectedPlayerId;
        if (!targetId) return;
        openItemCatalogModal(targetId);
        return;
    }

    const catalogItem = event.target.closest("[data-add-catalog-item]");
    if (catalogItem) {
        openQuantityModal("give", catalogItem.dataset.addCatalogItem, Number(catalogItem.dataset.target));
        return;
    }

    const locationCategoryButton = event.target.closest("[data-location-category]");
    if (locationCategoryButton) {
        state.locationCategory = String(locationCategoryButton.dataset.locationCategory || "");
        render();
        return;
    }

    if (event.target.closest("[data-location-category-back]")) {
        state.locationCategory = null;
        render();
        return;
    }

    if (event.target.closest("[data-add-location-category]")) {
        if (!canUse("add_location")) return;
        openAddLocationCategoryModal();
        return;
    }

    if (event.target.closest("[data-add-location]")) {
        if (!canUse("add_location")) return;
        openAddLocationModal();
        return;
    }

    const deleteLocationButton = event.target.closest("[data-delete-location]");
    if (deleteLocationButton) {
        if (!canUse("remove_location")) return;
        openDeleteLocationModal(Number(deleteLocationButton.dataset.deleteLocation));
        return;
    }

    const coordinateSelector = event.target.closest("[data-coordinate-selector]");
    if (coordinateSelector) {
        $("#coordinateOptions")?.classList.toggle("is-hidden");
        return;
    }

    const coordinateModeButton = event.target.closest("[data-coordinate-mode]");
    if (coordinateModeButton) {
        const mode = coordinateModeButton.dataset.coordinateMode;
        const hidden = $("#coordinateMode");
        if (hidden) hidden.value = mode;
        const text = $("#coordinateSelectorText");
        if (text) text.textContent = mode === "typed" ? "Digitar coordenada" : "Definir no jogo";
        $("#coordinateOptions")?.classList.add("is-hidden");
        $("#typedCoordinates")?.classList.toggle("is-hidden", mode !== "typed");
        $("#gameCoordinateHint")?.classList.toggle("is-hidden", mode !== "game");
        const submit = $("#locationSubmit");
        if (submit) submit.textContent = mode === "game" ? "Definir no jogo" : "Cadastrar local";
        return;
    }

    const vehicleCategoryButton = event.target.closest("[data-vehicle-category]");
    if (vehicleCategoryButton) {
        state.vehicleCategory = vehicleCategoryButton.dataset.vehicleCategory === "addon" ? "addon" : "game";
        render();
        return;
    }

    if (event.target.closest("[data-add-vehicle-catalog]")) {
        if (!canUse("add_vehicle_catalog")) return;
        openAddVehicleCatalogModal();
        return;
    }

    const garageQuickButton = event.target.closest("[data-open-vehicle-garage]");
    if (garageQuickButton) {
        const targetId = Number($("#vehicleTarget")?.value || state.selectedPlayerId || 0);
        openVehicleGarageModal(garageQuickButton.dataset.openVehicleGarage, targetId || "");
        return;
    }

    const garageVehicleButton = event.target.closest("[data-garage-vehicle]");
    if (garageVehicleButton) {
        const mode = garageVehicleButton.dataset.garageMode;
        const targetInput = $("#vehicleGarageTarget");
        const targetId = Number(targetInput?.value || 0);
        const vehicle = String(garageVehicleButton.dataset.garageVehicle || "").trim();

        if (!targetId) {
            toast("error", "Informe o passaporte", "Digite o ID do jogador no topo do modal.");
            targetInput?.focus();
            return;
        }
        if (!vehicle) return;

        await executeAction(mode === "remove" ? "rem_veh" : "give_veh", { targetId, vehicle });
        return;
    }

    const weatherButton = event.target.closest("[data-weather]");
    if (weatherButton) {
        if (!canUse("weather_manage")) return;
        await updateEnvironment({ action: "setWeather", weather: weatherButton.dataset.weather });
        return;
    }

    const envToggleButton = event.target.closest("[data-env-toggle]");
    if (envToggleButton) {
        const action = envToggleButton.dataset.envToggle;
        const envPermission = action === "freezeTime" ? "time_manage" : "weather_manage";
        if (!canUse(envPermission)) return;
        if (action === "freezeWeather") {
            await updateEnvironment({ action, enabled: !Boolean(state.environment?.weatherFrozen) });
        } else if (action === "rotating") {
            await updateEnvironment({ action, enabled: !Boolean(state.environment?.rotating) });
        } else if (action === "freezeTime") {
            await updateEnvironment({ action, enabled: !Boolean(state.environment?.timeFrozen) });
        }
        return;
    }

    if (event.target.closest("[data-open-ban-history]")) {
        await openBanHistoryModal();
        return;
    }

    const warningPlayerButton = event.target.closest("[data-warning-player]");
    if (warningPlayerButton) {
        await openWarningHistoryModal(Number(warningPlayerButton.dataset.warningPlayer));
        return;
    }

    const deleteWarningButton = event.target.closest("[data-delete-warning]");
    if (deleteWarningButton) {
        if (!canUse("delete_warning")) return;
        const warningId = Number(deleteWarningButton.dataset.deleteWarning || 0);
        const targetId = Number(deleteWarningButton.dataset.warningTarget || 0);
        if (!warningId || !targetId) return;

        const response = await post("warnings", { mode: "delete", warningId, targetId });
        if (!response?.ok) {
            toast("error", "Excluir advertência", response?.message || "Não foi possível excluir a advertência.");
            return;
        }

        if (response.data?.summary) state.warningsData = response.data.summary;
        if (state.bootstrap?.players) {
            const summary = response.data?.summary?.players || [];
            const countMap = new Map(summary.map(player => [Number(player.id), Number(player.count || 0)]));
            state.bootstrap.players = state.bootstrap.players.map(player => Number(player.id) === targetId
                ? { ...player, warnings: countMap.get(targetId) || 0 }
                : player);
        }
        if (state.snapshot && Number(state.snapshot.id) === targetId) {
            state.snapshot.warnings = Number(response.data?.player?.count || 0);
        }

        toast("success", "Advertência excluída", response.message || "O registro foi removido.");
        if (Number(response.data?.player?.count || 0) > 0) {
            await openWarningHistoryModal(targetId, true);
        } else {
            closeModal();
            if (state.page === "warnings") render();
        }
        return;
    }

    const needsSettingsButton = event.target.closest("#needsTopSettings");
    if (needsSettingsButton) {
        if (!canUse("needs_manage")) return;
        openNeedsSettingsModal();
        return;
    }

    const needsToggleButton = event.target.closest("[data-toggle-needs]");
    if (needsToggleButton) {
        if (!canUse("needs_manage")) return;
        const enabled = needsToggleButton.dataset.nextState === "true";
        await executeAction("needs_manage", { enabled });
        return;
    }

    const actionButton = event.target.closest("[data-open-action]");
    if (actionButton) {
        const action = actionButton.dataset.openAction;
        if (!canUse(action)) return;
        const hasSelectedTarget = actionButton.hasAttribute("data-default-target");
        const target = Number(actionButton.dataset.defaultTarget || 0);

        if (hasSelectedTarget && target) {
            await executeSelectedPlayerAction(action, target);
        } else {
            openActionModal(action, {});
        }
        return;
    }

    const playerButton = event.target.closest("[data-player]");
    if (playerButton) {
        const id = Number(playerButton.dataset.player);
        await loadSnapshot(id, false);
        state.page = "players";
        state.playerView = "profile";
        render();
        return;
    }

    const loadTarget = event.target.closest("[data-load-target]");
    if (loadTarget) {
        const mode = loadTarget.dataset.loadTarget;
        const input = $(`#${mode}Target`);
        const loaded = mode === "identity"
            ? await loadIdentityEditor(input?.value, false)
            : await loadSnapshot(input?.value, false);
        if (loaded) {
            state.page = mode;
            render();
        }
        return;
    }

    const groupButton = event.target.closest("[data-group-mode]");
    if (groupButton) {
        const targetId = state.snapshot?.id || state.selectedPlayerId;
        if (!targetId) {
            toast("error", "Selecione um jogador", "Carregue um jogador antes de alterar cargos.");
            return;
        }

        const response = await post("changeGroup", {
            targetId,
            group: groupButton.dataset.group,
            mode: groupButton.dataset.groupMode
        });

        if (!response?.ok) {
            toast("error", "Cargos", response?.message || "Não foi possível alterar o cargo.");
            return;
        }

        state.snapshot = response.data;
        addHistory(`${groupButton.dataset.groupMode === "add" ? "Adicionou" : "Removeu"} cargo ${groupButton.dataset.group}`);
        toast("success", "Cargo atualizado", response.message);
        render();
        return;
    }

    const weaponCategoryButton = event.target.closest("[data-weapon-category]");
    if (weaponCategoryButton) {
        state.weaponCategory = weaponCategoryButton.dataset.weaponCategory || "Todas";
        render();
        return;
    }

    const weaponPullButton = event.target.closest("[data-weapon-pull]");
    if (weaponPullButton) {
        if (!canUse("spawn_weapon")) return;
        const weapon = (state.bootstrap?.weapons || []).find(item => item.index === weaponPullButton.dataset.weaponPull);
        if (weapon) openWeaponAmmoModal(weapon);
        return;
    }

    const selfItemButton = event.target.closest("[data-self-item]");
    if (selfItemButton) {
        openSelfItemQuantityModal(selfItemButton.dataset.selfItem, selfItemButton.dataset.itemName);
        return;
    }

    const itemButton = event.target.closest("[data-item-mode]");
    if (itemButton) {
        const targetId = state.snapshot?.id || state.selectedPlayerId;
        if (!targetId) {
            toast("error", "Selecione um jogador", "Carregue um jogador antes de alterar itens.");
            return;
        }
        openQuantityModal(itemButton.dataset.itemMode, itemButton.dataset.item, targetId);
        return;
    }

    const vehicleButton = event.target.closest("[data-vehicle-action]");
    if (vehicleButton) {
        const spawn = vehicleButton.dataset.vehicle;
        const mode = vehicleButton.dataset.vehicleAction;

        if (mode === "spawn") {
            await executeAction("spawn_veh", { vehicle: spawn });
            return;
        }

        const targetId = Number($("#vehicleTarget")?.value || state.selectedPlayerId || 0);
        if (!targetId) {
            toast("error", "Informe o passaporte", "Digite o ID no campo acima para alterar a garagem.");
            return;
        }

        if (mode === "give") {
            openActionModal("give_veh", { targetId, vehicle: spawn });
        } else {
            openActionModal("rem_veh", { targetId, vehicle: spawn });
        }
        return;
    }

    const locationButton = event.target.closest("[data-location]");
    if (locationButton) {
        const response = await post("teleportLocation", { index: Number(locationButton.dataset.location) });
        if (!response?.ok) {
            toast("error", "Teleporte", response?.message || "Falha ao teleportar.");
            return;
        }
        addHistory("Teleportou por local");
        toast("success", "Teleporte", response.message);
        await closeNui();
    }
});

document.addEventListener("input", event => {
    if (event.target.matches("[data-vip-item-amount]") && vipEditorDraft) {
        const item = event.target.dataset.vipItemAmount;
        const entry = vipEditorDraft.items.find(current => current.item === item);
        if (entry) entry.amount = Math.max(1, Math.min(100000, Math.floor(Number(event.target.value || 1))));
        return;
    }
    if (event.target.id === "vipTitleInput" && vipEditorDraft) {
        vipEditorDraft.title = String(event.target.value || "");
        const groupInput = $("#vipGroupInput");
        if (!vipEditorDraft.originalGroup && groupInput?.dataset.vipAutoGroup === "1") {
            groupInput.value = vipGroupFromTitle(event.target.value);
            vipEditorDraft.group = groupInput.value;
        }
        return;
    }
    if (event.target.id === "vipGroupInput" && vipEditorDraft) {
        vipEditorDraft.group = String(event.target.value || "");
        if (!vipEditorDraft.originalGroup) event.target.dataset.vipAutoGroup = "0";
        return;
    }
    if (event.target.closest("#vipEditorForm") && event.target.name === "salary" && vipEditorDraft) {
        vipEditorDraft.salary = Math.max(0, Math.floor(Number(event.target.value || 0)));
        return;
    }
    if (event.target.closest("#vipEditorForm") && event.target.name === "vehicleChoices" && vipEditorDraft) {
        const maxChoices = Math.max(0, vipEditorDraft.vehicles.length);
        vipEditorDraft.vehicleChoices = maxChoices ? Math.max(1, Math.min(maxChoices, Math.floor(Number(event.target.value || 1)))) : 0;
        return;
    }
    if (event.target.closest("#vipEditorForm") && event.target.name === "garageSlots" && vipEditorDraft) {
        vipEditorDraft.garageSlots = Math.max(0, Math.min(1000, Math.floor(Number(event.target.value || 0))));
        return;
    }
    if (event.target.id === "mapPlayerSearch") {
        const query = event.target.value.trim().toLowerCase();
        $$(".map-player-row").forEach(row => {
            row.classList.toggle("is-filtered-out", Boolean(query) && !(row.dataset.search || "").includes(query));
        });
        return;
    }
    if (event.target.id === "environmentTimeRange") {
        scheduleEnvironmentTime(event.target.value);
        return;
    }

    if (event.target.matches("[data-filter-selector]")) {
        scheduleCatalogFilter(event.target);
    }
});

document.addEventListener("change", async event => {
    if (event.target.matches(".permission-role-card input[type=checkbox]")) {
        const card = event.target.closest(".permission-role-card");
        card?.classList.toggle("is-checked", event.target.checked);
        const note = card?.querySelector(".permission-role-copy small");
        if (note && !event.target.disabled) note.textContent = event.target.checked ? "Função liberada" : "Função bloqueada";
        const box = card?.querySelector(".permission-checkbox");
        if (box) box.innerHTML = event.target.checked ? icon("check", 14) : "";
        return;
    }

    if (event.target.id === "environmentTimeRange") {
        await commitEnvironmentTime(event.target.value);
    }
});

document.addEventListener("submit", async event => {
    if (event.target.id === "logsWebhookForm") {
        event.preventDefault();
        const form = event.target;
        const webhooks = {};
        $$('[data-log-webhook]', form).forEach(input => {
            webhooks[String(input.dataset.logWebhook || "")] = String(input.value || "").trim();
        });

        const button = form.querySelector('.logs-save-button');
        if (button) { button.disabled = true; button.classList.add('is-loading'); }
        const response = await post("logsAdmin", { mode: "save", webhooks });
        if (button) { button.disabled = false; button.classList.remove('is-loading'); }

        if (!response?.ok) {
            toast("error", "Logs", response?.message || "Não foi possível salvar as webhooks.");
            return;
        }

        state.logsAdmin = response.data || state.logsAdmin;
        toast("success", "Logs salvas", response.message || "Webhooks atualizadas com sucesso.");
        render();
        return;
    }
    if (event.target.id === "vipEditorForm") {
        event.preventDefault();
        if (!vipEditorDraft) return;
        const values = Object.fromEntries(new FormData(event.target).entries());
        const title = String(values.title || "").trim();
        const group = String(values.group || "").trim();
        const salary = Math.max(0, Math.floor(Number(values.salary || 0)));
        const garageSlots = Math.max(0, Math.min(1000, Math.floor(Number(values.garageSlots || 0))));
        let vehicleChoices = vipEditorDraft.vehicles.length ? Math.floor(Number(values.vehicleChoices || 1)) : 0;
        if (!title || !group) { toast("error", "VIPs", "Informe o nome do VIP e o cargo da vRP."); return; }
        if (vipEditorDraft.vehicles.length) vehicleChoices = Math.max(1, Math.min(vehicleChoices, vipEditorDraft.vehicles.length));
        else vehicleChoices = 0;
        const response = await post("vipAdmin", {
            mode: "save",
            originalGroup: vipEditorDraft.originalGroup || "",
            group, title, salary,
            items: vipEditorDraft.items,
            vehicles: vipEditorDraft.vehicles,
            vehicleChoices,
            garageSlots
        });
        if (!response?.ok) { toast("error", "VIPs", response?.message || "Não foi possível salvar o VIP."); return; }
        state.vipAdmin = response.data;
        if (state.bootstrap) state.bootstrap.vipAdmin = response.data;
        toast("success", "VIP salvo", response.message || "VIP atualizado em tempo real.");
        addHistory(`${vipEditorDraft.originalGroup ? "Editou" : "Criou"} VIP ${title}`);
        vipEditorDraft = null;
        closeModal();
        render();
        return;
    }

    if (event.target.id === "vipAssignForm") {
        event.preventDefault();
        const targetId = Math.floor(Number(new FormData(event.target).get("targetId") || 0));
        if (!targetId) { toast("error", "VIPs", "Informe um Passaporte / ID válido."); return; }
        const group = event.target.dataset.vipGroup;
        const response = await post("vipAdmin", { mode: "assign", group, targetId });
        if (!response?.ok) { toast("error", "Setar VIP", response?.message || "Não foi possível setar o VIP."); return; }
        state.vipAdmin = response.data || state.vipAdmin;
        if (state.bootstrap) state.bootstrap.vipAdmin = state.vipAdmin;
        toast("success", "VIP setado", response.message || "Benefícios entregues ao jogador.");
        addHistory(`Setou VIP ${group} no ID ${targetId}`);
        closeModal();
        render();

        // Quando a staff seta o VIP nela mesma, o evento server->client pode
        // chegar enquanto este submit ainda está aguardando a resposta do Tunnel.
        // Fazemos uma leitura direta da pendência como fallback determinístico.
        if (Number(state.bootstrap?.admin?.id || 0) === Number(targetId)) {
            const pending = await post("vipPlayer", { mode: "status" });
            if (pending?.ok && pending.data && !pending.data.completed) {
                renderPlayerVipChoice(pending.data);
            }
        }
        return;
    }

    if (event.target.id === "vipDeleteForm") {
        event.preventDefault();
        const group = event.target.dataset.vipGroup;
        const response = await post("vipAdmin", { mode: "delete", group });
        if (!response?.ok) { toast("error", "Excluir VIP", response?.message || "Não foi possível excluir o VIP."); return; }
        state.vipAdmin = response.data || state.vipAdmin;
        if (state.bootstrap) state.bootstrap.vipAdmin = state.vipAdmin;
        toast("success", "VIP excluído", response.message || "VIP removido.");
        addHistory(`Excluiu VIP ${group}`);
        closeModal();
        render();
        return;
    }

    if (event.target.id === "playerCallForm") {
        event.preventDefault();
        const form = event.target;
        const message = String(new FormData(form).get("message") || "").trim();
        if (!message) return;
        const response = await post("calls", { mode: "create", department: form.dataset.department, message });
        if (!response?.ok) return;
        playerCallMenuState = { open: false, department: null };
        renderPlayerCallMenu();
        await post("callUi", { mode: "closeMenu" });
        return;
    }

    if (event.target.id === "panelPermissionForm") {
        event.preventDefault();
        if (!canManagePanelPermissions()) return;

        const form = event.target;
        const formData = new FormData(form);
        const response = await post("panelPermissions", {
            mode: "update",
            key: form.dataset.permissionKey,
            roles: {
                admin: formData.get("role_admin") === "1",
                moderador: formData.get("role_moderador") === "1",
                suporte: formData.get("role_suporte") === "1"
            }
        });

        if (!response?.ok) {
            toast("error", "Permissões do Painel", response?.message || "Não foi possível salvar as permissões.");
            return;
        }

        state.permissions = response.data;
        if (state.bootstrap) state.bootstrap.permissions = response.data;
        toast("success", "Permissões atualizadas", response.message || "As novas permissões já estão valendo.");
        openPanelPermissionsModal();
        render();
        return;
    }

    if (event.target.id === "identityEditForm") {
        event.preventDefault();
        const form = event.target;
        const field = String(form.dataset.field || "");
        const targetId = Number(form.dataset.targetId || state.identityEditor?.id || 0);
        const value = String(new FormData(form).get("value") ?? "").trim();

        if (!targetId || !field || value === "") {
            toast("error", "Alterar RG", "Preencha o novo valor corretamente.");
            return;
        }

        if (field === "id" && (!/^\d+$/.test(value) || Number(value) < 1)) {
            toast("error", "Alterar RG", "Informe um novo ID válido.");
            return;
        }

        if (field === "idade" && (!/^\d+$/.test(value) || Number(value) < 1 || Number(value) > 150)) {
            toast("error", "Alterar RG", "Informe uma idade válida.");
            return;
        }

        if (["wallet", "bank"].includes(field) && (!/^\d+$/.test(value) || Number(value) < 0)) {
            toast("error", "Alterar RG", "Informe um saldo válido maior ou igual a zero.");
            return;
        }

        const response = await post("identityEditor", {
            mode: "update",
            operation: field === "id" ? "id" : (["wallet", "bank"].includes(field) ? "balance" : "field"),
            targetId,
            field,
            value,
            ...(field === "id" ? { newId: Number(value) } : {})
        });

        if (!response?.ok) {
            const message = String(response?.message || "Não foi possível salvar a alteração.");
            if (message === "ID JÁ EM USO") {
                toast("error", "ID JÁ EM USO", "Escolha outro Passaporte / ID para continuar.");
            } else {
                toast("error", "Alterar RG", message);
            }
            return;
        }

        state.identityEditor = response.data || state.identityEditor;
        if (state.identityEditor?.id) state.selectedPlayerId = Number(state.identityEditor.id);

        if (field !== "id" && !["wallet", "bank"].includes(field) && state.identityEditor?.identity) {
            applyIdentityLiveUpdate({
                id: state.identityEditor.id,
                name: state.identityEditor.name,
                identity: state.identityEditor.identity
            }, false);
        }

        addHistory(field === "id" ? "Alterou Passaporte / ID" : (["wallet", "bank"].includes(field) ? `Alterou saldo de ${field === "wallet" ? "carteira" : "banco"}` : `Alterou ${field}`));
        toast("success", "Alteração salva", response.message || "Informação atualizada com sucesso.");
        closeModal();
        render();

        // Mantém a lista de Jogadores sincronizada imediatamente após qualquer
        // alteração, sem precisar apertar o botão de atualizar do painel.
        if (field !== "id" && !["wallet", "bank"].includes(field)) {
            setTimeout(() => refreshPlayers(false), 50);
        }
        return;
    }

    if (event.target.id === "actionForm") {
        event.preventDefault();
        const action = event.target.dataset.action;
        const payload = Object.fromEntries(new FormData(event.target).entries());

        if (["ban", "unban"].includes(action) && !String(payload.reason || "").trim()) {
            toast("error", action === "ban" ? "Banir jogador" : "Desbanir jogador", "Informe o motivo para continuar.");
            event.target.querySelector('[name="reason"]')?.focus();
            return;
        }


        if (action === "warning" && !String(payload.reason || "").trim()) {
            toast("error", "Advertência", "Informe o motivo da advertência.");
            event.target.querySelector('[name="reason"]')?.focus();
            return;
        }

        if (action === "tpcds") {
            const parsed = parseCoordinateInput(payload.coords);
            if (!parsed) {
                toast("error", "Teleportar por coordenadas", "Digite uma coordenada correta!");
                event.target.querySelector('[name="coords"]')?.focus();
                return;
            }
            payload.coords = `${parsed.x},${parsed.y},${parsed.z}`;
            payload.x = parsed.x;
            payload.y = parsed.y;
            payload.z = parsed.z;
        }

        await executeAction(action, payload);
        return;
    }

    if (event.target.id === "needsSettingsForm") {
        event.preventDefault();
        if (!canUse("needs_manage")) return;

        const values = Object.fromEntries(new FormData(event.target).entries());
        const hungerPerMinute = Number(values.hungerPerMinute);
        const thirstPerMinute = Number(values.thirstPerMinute);
        const hungerDamage = Number(values.hungerDamage);
        const thirstDamage = Number(values.thirstDamage);

        const validRate = value => Number.isFinite(value) && value >= 0 && value <= 100;
        const validDamage = value => Number.isFinite(value) && value >= 0 && value <= 100 && Number.isInteger(value);

        if (!validRate(hungerPerMinute) || !validRate(thirstPerMinute)) {
            toast("error", "Configurar fome e sede", "A velocidade deve ficar entre 0 e 100% por minuto.");
            return;
        }
        if (!validDamage(hungerDamage) || !validDamage(thirstDamage)) {
            toast("error", "Configurar fome e sede", "O dano deve ser um número inteiro entre 0 e 100.");
            return;
        }

        const response = await post("needsSettings", {
            hungerPerMinute,
            thirstPerMinute,
            hungerDamage,
            thirstDamage
        });

        if (!response?.ok) {
            toast("error", "Configurar fome e sede", response?.message || "Não foi possível salvar as configurações.");
            return;
        }

        if (state.bootstrap) {
            state.bootstrap.needsSettings = response.data?.needsSettings || state.bootstrap.needsSettings;
            if (response.data?.needsEnabled !== undefined) state.bootstrap.needsEnabled = response.data.needsEnabled === true;
        }
        addHistory("Configurações de fome e sede");
        toast("success", "Fome e sede configuradas", response.message || "Configurações salvas em tempo real.");
        closeModal();
        renderShell();
        return;
    }

    if (event.target.id === "vehicleCatalogForm") {
        event.preventDefault();
        const values = Object.fromEntries(new FormData(event.target).entries());
        const spawn = String(values.spawn || "").trim();
        const category = values.category === "addon" ? "addon" : "game";

        if (!spawn) {
            toast("error", "Adicionar veículo", "Informe o spawn do veículo.");
            event.target.querySelector('[name="spawn"]')?.focus();
            return;
        }

        const response = await post("addVehicleCatalog", { spawn, category });
        if (!response?.ok) {
            toast("error", "Adicionar veículo", response?.message || "Não foi possível adicionar o veículo.");
            return;
        }

        state.config.vehicles = response.data?.vehicles || state.config.vehicles;
        state.vehicleCategory = response.data?.category === "addon" ? "addon" : "game";
        addHistory(`Adicionou veículo ${spawn} em ${state.vehicleCategory === "addon" ? "Veículos addon" : "Veículos do jogo"}`);
        toast("success", "Veículo adicionado", response.message || `${spawn} foi adicionado ao catálogo.`);
        closeModal();
        render();
        return;
    }

    if (event.target.id === "vehicleGarageManualForm") {
        event.preventDefault();
        const form = event.target;
        const values = Object.fromEntries(new FormData(form).entries());
        const targetId = Number(values.targetId || 0);
        const vehicle = resolveVehicleInput(values.vehicle);
        const action = form.dataset.action;

        if (!targetId) {
            toast("error", "Veículo", "Informe um Passaporte / ID válido.");
            $("#vehicleGarageTarget")?.focus();
            return;
        }

        if (!vehicle) {
            toast("error", "Veículo", "Informe o nome ou spawn do veículo.");
            $("#vehicleGarageSpawn")?.focus();
            return;
        }

        if (!["give_veh", "rem_veh"].includes(action)) {
            toast("error", "Veículo", "Ação inválida.");
            return;
        }

        await executeAction(action, { targetId, vehicle });
        return;
    }


    if (event.target.id === "radioEditorForm") {
        event.preventDefault();
        const form = event.target;
        const values = Object.fromEntries(new FormData(form).entries());
        const permissions = String(values.permissions || "").split(/[,;\n]+/).map(v => v.trim()).filter(Boolean);
        const channel = Number(values.channel || 0);
        if (!String(values.name || "").trim()) { toast("error", "Rádio", "Informe o nome da rádio."); return; }
        if (!Number.isInteger(channel) || channel < 1 || channel > 9999) { toast("error", "Rádio", "Informe uma frequência inteira entre 1 e 9999."); return; }
        if (!permissions.length) { toast("error", "Rádio", "Informe ao menos uma permissão."); return; }
        const response = await post("radioAdmin", { mode: "save", id: Number(form.dataset.radioId || 0) || undefined, name: String(values.name).trim(), channel, permissions, enabled: new FormData(form).has("enabled") });
        if (!response?.ok) { toast("error", "Rádio", response?.message || "Não foi possível salvar a rádio."); return; }
        state.radioAdmin = response.data || state.radioAdmin;
        if (state.bootstrap) state.bootstrap.radioAdmin = state.radioAdmin;
        addHistory(`${form.dataset.radioId ? "Editou" : "Criou"} rádio ${String(values.name).trim()}`);
        toast("success", "Rádio", response.message || "Configuração salva em tempo real.");
        closeModal(); render(); return;
    }

    if (event.target.id === "radioDeleteForm") {
        event.preventDefault();
        const id = Number(event.target.dataset.radioId || 0);
        const response = await post("radioAdmin", { mode: "delete", id });
        if (!response?.ok) { toast("error", "Rádio", response?.message || "Não foi possível excluir a rádio."); return; }
        state.radioAdmin = response.data || state.radioAdmin;
        if (state.bootstrap) state.bootstrap.radioAdmin = state.radioAdmin;
        addHistory(`Excluiu rádio privada #${id}`);
        toast("success", "Rádio", response.message || "Rádio removida.");
        closeModal(); render(); return;
    }

    if (event.target.id === "deleteLocationForm") {
        event.preventDefault();
        const index = Number(event.target.dataset.locationIndex || 0);
        if (!index) {
            toast("error", "Locais", "Local inválido.");
            return;
        }

        const location = (state.config.locations || []).find(item => Number(item.index) === index);
        const response = await post("removeLocation", { index });
        if (!response?.ok) {
            toast("error", "Apagar local", response?.message || "Não foi possível remover o local.");
            return;
        }

        state.config.locations = response.data?.locations || state.config.locations;
        state.config.locationCategories = response.data?.categories || state.config.locationCategories;
        addHistory(`Removeu local ${location?.name || `#${index}`}`);
        toast("success", "Local removido", response.message || "Local apagado com sucesso.");
        closeModal();
        render();
        return;
    }

    if (event.target.id === "locationCategoryForm") {
        event.preventDefault();
        const name = String(new FormData(event.target).get("name") || "").trim();
        if (!name) {
            toast("error", "Categorias", "Informe um nome para a categoria.");
            return;
        }
        const response = await post("addLocationCategory", { name });
        if (!response?.ok) {
            toast("error", "Categorias", response?.message || "Não foi possível criar a categoria.");
            return;
        }
        state.config.locationCategories = response.data?.categories || state.config.locationCategories;
        state.locationCategory = name;
        toast("success", "Categoria criada", response.message || `${name} foi criada.`);
        closeModal();
        render();
        return;
    }

    if (event.target.id === "locationForm") {
        event.preventDefault();
        const form = event.target;
        const values = Object.fromEntries(new FormData(form).entries());
        const name = String(values.name || "").trim();
        const mode = String(values.coordMode || "");
        const selectedCategory = String(values.category || "").trim();
        const category = selectedCategory === "__new__" ? String(values.newCategory || "").trim() : selectedCategory;

        if (!name) {
            toast("error", "ADD LOCAL", "Informe um nome para o local.");
            return;
        }

        if (!category) {
            toast("error", "ADD LOCAL", "Selecione ou crie uma categoria.");
            return;
        }

        if (!mode) {
            toast("error", "ADD LOCAL", "Selecione como deseja definir a coordenada.");
            return;
        }

        if (mode === "game") {
            const response = await post("startLocationCapture", { name, category });
            if (!response?.ok) {
                toast("error", "ADD LOCAL", response?.message || "Não foi possível iniciar a captura.");
                return;
            }
            closeModal();
            setOpen(false);
            return;
        }

        const parsedCoords = parseCoordinateInput(values.coords);
        if (!parsedCoords) {
            toast("error", "ADD LOCAL", "Digite uma coordenada correta!");
            form.querySelector('[name="coords"]')?.focus();
            return;
        }

        const { x, y, z } = parsedCoords;
        const response = await post("addLocation", {
            name,
            category,
            coords: `${x},${y},${z}`,
            x, y, z
        });
        if (!response?.ok) {
            toast("error", "ADD LOCAL", response?.message || "Não foi possível cadastrar o local.");
            return;
        }

        state.config.locations = response.data?.locations || state.config.locations;
        state.config.locationCategories = response.data?.categories || state.config.locationCategories;
        state.locationCategory = category;
        addHistory(`Cadastrou local ${name} em ${category}`);
        toast("success", "Local cadastrado", response.message || `${name} foi salvo.`);
        closeModal();
        render();
        return;
    }

    if (event.target.id === "weaponSpawnForm") {
        event.preventDefault();
        const form = event.target;
        const weaponIndex = String(form.dataset.weapon || "");
        const weapon = (state.bootstrap?.weapons || []).find(item => item.index === weaponIndex);
        if (!weapon) { toast("error", "Armas", "Arma inválida ou não carregada."); return; }
        const ammoAmount = weapon.ammo ? Number(new FormData(form).get("ammoAmount")) : 0;
        if (weapon.ammo && (!Number.isInteger(ammoAmount) || ammoAmount < 0 || ammoAmount > 100000)) {
            toast("error", "Armas", "Informe uma quantidade de munição entre 0 e 100.000.");
            return;
        }
        await executeAction("spawn_weapon", { weapon: weapon.index, ammoAmount });
        return;
    }

    if (event.target.id === "selfItemForm") {
        event.preventDefault();
        const form = event.target;
        const amount = Number(new FormData(form).get("amount"));

        if (!Number.isFinite(amount) || amount < 1) {
            toast("error", "Itens", "Informe uma quantidade válida.");
            return;
        }

        await executeAction("spawn_self_item", {
            item: form.dataset.item,
            amount
        });
        return;
    }

    if (event.target.id === "itemForm") {
        event.preventDefault();

        const form = event.target;
        const response = await post("changeItem", {
            targetId: Number(form.dataset.target),
            item: form.dataset.item,
            mode: form.dataset.mode,
            amount: Number(new FormData(form).get("amount"))
        });

        if (!response?.ok) {
            toast("error", "Inventário", response?.message || "Não foi possível alterar o item.");
            return;
        }

        state.snapshot = response.data;
        addHistory(`${form.dataset.mode === "give" ? "Adicionou" : "Removeu"} item ${form.dataset.item}`);
        toast("success", "Inventário atualizado", response.message);
        closeModal();
        render();
    }
});

$("#refreshButton").innerHTML = icon("refresh");
$("#closeButton").innerHTML = icon("close");

$("#refreshButton").addEventListener("click", () => refreshPlayers(true));
$("#closeButton").addEventListener("click", () => closeNui());

document.addEventListener("keydown", event => {
    if (event.key !== "Escape" || !state.open) return;

    if (modalRoot.classList.contains("is-open")) {
        closeModal();
    } else {
        closeNui();
    }
});

document.addEventListener("change", event => {
    if (event.target?.id === "locationCategorySelect") {
        const isNew = String(event.target.value || "") === "__new__";
        $("#newLocationCategoryField")?.classList.toggle("is-hidden", !isNew);
        if (isNew) $("#newLocationCategoryField input")?.focus();
    }
});

window.addEventListener("message", event => {
    const data = event.data || {};

    if (data.type === "mgBridgeResponse") {
        resolveMgBridgeResponse(data.requestId, data.payload);
        return;
    }

    if (data.type === "open") {
        state.bootstrap = data.payload?.bootstrap || {};
        state.config = data.payload?.config || state.config;
        state.permissions = state.bootstrap?.permissions || null;
        state.radioAdmin = state.bootstrap?.radioAdmin || null;
        state.vipAdmin = state.bootstrap?.vipAdmin || null;
        state.logsAdmin = null;
        state.logsCategoryId = null;
        state.logsSubcategoryId = null;
        state.page = firstVisiblePage();
        state.selectedPlayerId = null;
        state.snapshot = null;
        state.playerView = "profile";
        state.warningsData = null;
        state.vehicleCategory = "game";
        state.environment = state.bootstrap?.environment || null;
        render();
        setOpen(true);
        return;
    }

    if (data.type === "close") {
        setOpen(false);
        return;
    }

    if (data.type === "permissionsUpdated") {
        state.permissions = data.payload || state.permissions;
        if (state.bootstrap) state.bootstrap.permissions = state.permissions;
        if (state.open) {
            if (!canManagePanelPermissions() && modalRoot.classList.contains("is-open")) closeModal();
            render();
            if (modalRoot.classList.contains("is-open") && canManagePanelPermissions() && modalRoot.querySelector(".permission-manager-modal")) {
                openPanelPermissionsModal();
            }
        }
        return;
    }

    if (data.type === "identityUpdated") {
        applyIdentityLiveUpdate(data.payload || {}, true);
        return;
    }

    if (data.type === "playersUpdated") {
        const payload = data.payload && typeof data.payload === "object" ? data.payload : {};
        const players = Array.isArray(payload.players) ? payload.players : [];

        if (state.bootstrap) {
            state.bootstrap.players = players;
            if (payload.stats && typeof payload.stats === "object") {
                state.bootstrap.stats = payload.stats;
            }

            const adminId = Number(state.bootstrap.admin?.id || 0);
            const adminPlayer = players.find(player => Number(player.id) === adminId);
            if (adminPlayer?.name && state.bootstrap.admin) {
                state.bootstrap.admin.name = adminPlayer.name;
            }
        }

        if (state.snapshot) {
            const selected = players.find(player => Number(player.id) === Number(state.snapshot.id));
            if (selected) {
                state.snapshot = {
                    ...state.snapshot,
                    name: selected.name || state.snapshot.name,
                    online: true,
                    source: selected.source ?? state.snapshot.source,
                    ping: selected.ping ?? state.snapshot.ping,
                    warnings: selected.warnings ?? state.snapshot.warnings
                };
            }
        }

        if (Array.isArray(state.mapPlayers) && players.length) {
            const names = new Map(players.map(player => [Number(player.id), player.name]));
            state.mapPlayers = state.mapPlayers.map(player => ({
                ...player,
                name: names.get(Number(player.id)) || player.name
            }));
        }

        if (state.open) render();
        return;
    }

    if (data.type === "vipChoiceOpen") {
        renderVipTestOverlay({ active: false, session: vipTestOverlaySession });
        renderPlayerVipChoice(data.payload || {});
        return;
    }

    if (data.type === "vipChoiceClose") {
        renderVipTestOverlay({ active: false, session: vipTestOverlaySession });
        renderPlayerVipChoice(null);
        if (data.message) toast("info", "VIP", data.message);
        return;
    }

    if (data.type === "vipTestOverlay") {
        renderVipTestOverlay(data);
        return;
    }

    if (data.type === "warningsUpdated") {
        state.warningsData = data.payload || { players: [], totalWarnings: 0, totalPlayers: 0 };

        if (state.bootstrap?.players && Array.isArray(state.warningsData.players)) {
            const countMap = new Map(state.warningsData.players.map(player => [Number(player.id), Number(player.count || 0)]));
            state.bootstrap.players = state.bootstrap.players.map(player => ({
                ...player,
                warnings: countMap.get(Number(player.id)) || 0
            }));
        }
        if (state.snapshot) {
            const selected = (state.warningsData.players || []).find(player => Number(player.id) === Number(state.snapshot.id));
            state.snapshot.warnings = Number(selected?.count || 0);
        }
        if (state.open && state.page === "warnings") render();
        return;
    }


    if (data.type === "radioUpdated") {
        state.radioAdmin = data.payload || state.radioAdmin;
        if (state.bootstrap) state.bootstrap.radioAdmin = state.radioAdmin;
        if (state.open && state.page === "radio") render();
        return;
    }

    if (data.type === "needsState") {
        if (state.bootstrap) state.bootstrap.needsEnabled = data.payload?.enabled === true;
        if (state.open) renderShell();
        return;
    }

    if (data.type === "needsSettingsState") {
        if (state.bootstrap) state.bootstrap.needsSettings = data.payload || state.bootstrap.needsSettings;
        return;
    }

    if (data.type === "environmentState") {
        const previous = state.environment;
        state.environment = data.payload || state.environment;
        if (state.page === "climate" && state.environment) {
            const structuralChange = !previous
                || previous.weatherRevision !== state.environment.weatherRevision
                || previous.weatherFrozen !== state.environment.weatherFrozen
                || previous.rotating !== state.environment.rotating
                || previous.timeFrozen !== state.environment.timeFrozen;
            if (structuralChange) render();
            else updateEnvironmentTimeDom();
        }
        return;
    }

    if (data.type === "liveScreenPublisherStart") {
        startLiveScreenPublisher(String(data.token || ""), data.options || {});
        return;
    }

    if (data.type === "liveScreenPublisherStop") {
        stopLiveScreenPublisher(String(data.token || ""));
        stopLiveScreenRelayPublisher(String(data.token || ""));
        return;
    }

    if (data.type === "liveScreenRelayStart") {
        startLiveScreenRelayPublisher(String(data.token || ""), data.options || {});
        return;
    }

    if (data.type === "liveScreenRelayStop") {
        stopLiveScreenRelayPublisher(String(data.token || ""));
        return;
    }

    if (data.type === "liveScreenRelayFrame") {
        receiveLiveScreenRelayFrame(data);
        return;
    }

    if (data.type === "liveScreenSignal") {
        queueLiveScreenSignal(data);
        return;
    }

    if (data.type === "liveScreenError") {
        if (!liveScreenSession || String(liveScreenSession.token) !== String(data.token)) return;
        cleanupLiveScreenReceiver();
        liveScreenSetStatus("error", data.message || "A transmissão foi encerrada.");
        toast("error", "Ver tela", data.message || "Não foi possível atualizar a tela do jogador.");
        return;
    }

    if (data.type === "punishmentStart") {
        showPunishmentScreenAlert(data.seconds);
        return;
    }

    if (data.type === "punishmentStop") {
        stopPunishmentScreenAlert();
        return;
    }

    if (data.type === "screenAlert") {
        showAdminScreenAlert(data.message, data.seconds, data.scope || "general");
        return;
    }

    if (data.type === "screenAlertStop") {
        stopAdminScreenAlert();
        return;
    }

    if (data.type === "callMenuOpen") {
        playerCallMenuState = { open: true, department: null };
        renderPlayerCallMenu();
        return;
    }

    if (data.type === "callMenuClose") {
        playerCallMenuState = { open: false, department: null };
        renderPlayerCallMenu();
        return;
    }

    if (data.type === "sectorCallNew") {
        const payload = data.payload || {};
        if (payload.id) sectorCalls.set(Number(payload.id), payload);
        renderSectorCalls();
        return;
    }

    if (data.type === "sectorCallTaken") {
        const payload = data.payload || {};
        if (payload.id) sectorCalls.delete(Number(payload.id));
        renderSectorCalls();
        showSectorCallNotice(payload);
        return;
    }

    if (data.type === "sectorFocus") {
        sectorFocused = data.active === true;
        renderSectorCalls();
        return;
    }

    if (data.type === "callEvaluation") {
        evaluationState = { ...(data.payload || {}), stars: 0, message: "", showMessage: false };
        renderCallEvaluation();
        return;
    }

    if (data.type === "callEvaluationClose") {
        evaluationState = null;
        renderCallEvaluation();
        return;
    }

    if (data.type === "callsUpdated") {
        if (state.open && state.page === "calls") {
            state.callsData = null;
            refreshCallsPanelData(false);
        }
        return;
    }

    if (data.type === "toast") {
        toast(
            data.kind === "error" ? "error" : data.kind === "success" ? "success" : "info",
            data.kind === "error" ? "Atenção" : data.kind === "success" ? "Concluído" : "Informação",
            data.message || ""
        );
    }
});


window.addEventListener("beforeunload", () => {
    try { cleanupLiveScreenReceiver(); } catch (_) {}
    try { stopLiveScreenPublisher(); } catch (_) {}
});
