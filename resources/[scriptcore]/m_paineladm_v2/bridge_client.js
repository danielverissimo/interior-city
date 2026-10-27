// m_paineladm_v2 - NUI transport bridge (OPEN / DO NOT OBFUSCATE)
// v2.90.4 - Definitive obfuscation-safe transport.
// This file owns every CEF -> client callback so Lua virtualization never sits
// between a NUI button and the server response. AUTH remains in server.lua.

const MG_BUILD = '2.90.5-final-obfsafe';
const RESOURCE = GetCurrentResourceName();
const REQUEST_EVENT = `${RESOURCE}:bridgeRequestOfficial`;
const RESPONSE_EVENT = `${RESOURCE}:bridgeResponseOfficial`;
const LOCAL_REQUEST_EVENT = `${RESOURCE}:localBridgeRequestOfficial`;
const LOCAL_RESPONSE_EVENT = `${RESOURCE}:localBridgeResponseOfficial`;
const CLICK_EVENT = `${RESOURCE}:bridgeClickOfficial`;
const RELAY_FRAME_EVENT = `${RESOURCE}:bridgeRelayFrameOfficial`;
const VIP_RESPONSE_EVENT = `${RESOURCE}:vipPlayerBridgeResponseOfficial`;

let seq = 0;
const pendingMeta = new Map();

function nextId() {
    seq = (seq + 1) % 2147483000;
    return `${GetPlayerServerId(PlayerId())}:${GetGameTimer()}:${seq}`;
}

function sendNui(payload) {
    SendNuiMessage(JSON.stringify(payload));
}

function click() {
    emit(CLICK_EVENT);
}

function pendingResponse(requestId) {
    return { ok: true, __mgBridgePending: true, requestId };
}

function serverRequest(method, data = {}) {
    const requestId = nextId();
    const cleanData = data && typeof data === 'object' ? data : {};
    pendingMeta.set(requestId, { method: String(method || ''), data: cleanData });
    emitNet(REQUEST_EVENT, requestId, String(method || ''), cleanData);
    return pendingResponse(requestId);
}

function localRequest(method, data = {}) {
    const requestId = nextId();
    emit(LOCAL_REQUEST_EVENT, requestId, String(method || ''), data && typeof data === 'object' ? data : {});
    return pendingResponse(requestId);
}

function register(name, handler) {
    RegisterNuiCallback(name, (data, cb) => {
        try {
            const response = handler(data || {});
            cb(response || { ok: true });
        } catch (err) {
            console.log(`[m_paineladm_v2] JS bridge callback '${name}' failed: ${String(err)}`);
            cb({ ok: false, message: `Falha interna no transporte (${name}).`, build: MG_BUILD });
        }
    });
}

onNet(RESPONSE_EVENT, (requestId, response) => {
    const id = String(requestId || '');
    const meta = pendingMeta.get(id);
    pendingMeta.delete(id);

    // CRITICO: a NUI e destravada ANTES de qualquer efeito auxiliar.
    // Assim nenhum emit/notify secundario consegue prender um await post().
    sendNui({
        type: 'mgBridgeResponse',
        requestId: id,
        payload: response || { ok: false, message: 'Resposta vazia do servidor.' }
    });

    try {
        if (meta && meta.method === 'calls' && response && response.ok === false) {
            const mode = String(meta.data?.mode || '');
            if (mode === 'create' || mode === 'sectorAccept' || mode === 'rate') {
                emit('Notify', 'negado', String(response.message || 'Nao foi possivel concluir a acao.'), 6500);
            }
        }

        if (meta && meta.method === 'vipPlayer') {
            emit(VIP_RESPONSE_EVENT, meta.data || {}, response || {});
        }
    } catch (err) {
        console.log(`[m_paineladm_v2] Efeito auxiliar da resposta '${meta?.method || 'desconhecido'}' falhou: ${String(err)}`);
    }
});

on(LOCAL_RESPONSE_EVENT, (requestId, response) => {
    sendNui({
        type: 'mgBridgeResponse',
        requestId: String(requestId || ''),
        payload: response || { ok: false, message: 'Resposta vazia do client core.' }
    });
});

register('bridgePing', () => ({ ok: true, bridge: 'js-official', build: MG_BUILD, resource: RESOURCE }));
register('close', () => localRequest('closePanel', {}));

register('refreshPlayers', data => {
    if (data?.silent !== true) click();
    return serverRequest('refreshPlayers', data);
});

register('mapPlayers', () => serverRequest('mapPlayers', {}));

register('liveScreen', data => {
    const mode = String(data?.mode || '');
    if (mode === 'stop') return serverRequest('liveScreenStop', data);
    if (mode === 'ready') return serverRequest('liveScreenReady', data);
    click();
    return serverRequest('liveScreenStart', data);
});

register('liveScreenSignal', data => {
    emitNet(
        'm_paineladm_v2:liveScreenSignal',
        String(data?.token || ''),
        String(data?.kind || ''),
        data?.payload || {},
        String(data?.role || '')
    );
    return { ok: true };
});

register('liveScreenRelay', data => {
    if (String(data?.mode || '') === 'start') return serverRequest('liveScreenRelayStart', data);
    return { ok: false, message: 'Modo relay inválido.' };
});

register('liveScreenRelayFrame', data => {
    const token = String(data?.token || '');
    const frame = String(data?.frame || '');
    if (!token || !frame) return { ok: false };
    emit(RELAY_FRAME_EVENT, data || {});
    return { ok: true };
});

register('playerSnapshot', data => { click(); return serverRequest('playerSnapshot', data); });
register('identityEditor', data => {
    click();
    return serverRequest(String(data?.mode || 'get') === 'update' ? 'identityUpdate' : 'identityGet', data);
});
register('execute', data => { click(); return serverRequest('execute', { action: data?.action, payload: data?.payload || {} }); });
register('needsSettings', data => { click(); return serverRequest('needsSettings', data); });
register('radioAdmin', data => {
    if (data?.silent !== true) click();
    return serverRequest('radioAdmin', data);
});
register('vipAdmin', data => {
    if (data?.silent !== true) click();
    return serverRequest('vipAdmin', data);
});
register('logsAdmin', data => {
    if (data?.silent !== true) click();
    return serverRequest('logsAdmin', data);
});
register('auditAction', data => serverRequest('auditAction', data));
register('vipPlayer', data => serverRequest('vipPlayer', data));
register('banHistory', () => { click(); return serverRequest('banHistory', {}); });
register('warnings', data => {
    if (data?.silent !== true) click();
    return serverRequest('warnings', data);
});
register('changeGroup', data => { click(); return serverRequest('changeGroup', data); });
register('changeItem', data => { click(); return serverRequest('changeItem', data); });
register('calls', data => serverRequest('calls', data));
register('callUi', data => localRequest('callUi', data));
register('addVehicleCatalog', data => { click(); return serverRequest('addVehicleCatalog', data); });
register('addLocation', data => { click(); return serverRequest('addLocation', data); });
register('addLocationCategory', data => { click(); return serverRequest('addLocationCategory', data); });
register('removeLocation', data => { click(); return serverRequest('removeLocation', data); });
register('panelPermissions', data => {
    click();
    return serverRequest(data?.mode === 'get' ? 'panelPermissionsGet' : 'panelPermissionsUpdate', data?.mode === 'get' ? {} : data);
});
register('environment', data => {
    if (String(data?.action || '') !== 'setTime') click();
    return serverRequest('environment', data);
});
register('startLocationCapture', data => { click(); return localRequest('startLocationCapture', data); });
register('teleportLocation', data => { click(); return serverRequest('teleportLocation', data); });

console.log(`[m_paineladm_v2] JS NUI bridge ${MG_BUILD} loaded for ${RESOURCE}.`);
