export class RpcError extends Error {
    constructor(code, message) { super(message); this.code = code; }
}

// Mutations are sent once. A timeout is deliberately not followed by a retry.
export function createTransport({ fetcher = globalThis.fetch, resource = 'ic_admin', timeout = 21000, onFailure = () => {} } = {}) {
    let sequence = 0;
    const pending = new Map();
    return {
        pending,
        async call(method, payload = {}) {
            const requestId = `${Date.now().toString(36)}-${(++sequence).toString(36)}`;
            const abort = new AbortController();
            const timer = setTimeout(() => abort.abort(), timeout);
            pending.set(requestId, method);
            try {
                const result = await fetcher(`https://${resource}/rpc`, {
                    method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                    body: JSON.stringify({ requestId, method, payload }), signal: abort.signal
                });
                const envelope = await result.json();
                if (!envelope || envelope.ok !== true) {
                    const error = envelope?.error || {};
                    throw new RpcError(error.code || 'FAILED', error.message || envelope?.message || 'A operação não foi concluída.');
                }
                return envelope.data;
            } catch (error) {
                if (error?.name === 'AbortError') {
                    const uncertain = new RpcError('TIMEOUT', 'Sem resposta. Atualize os dados antes de tentar a operação novamente.');
                    onFailure(uncertain); throw uncertain;
                }
                onFailure(error); throw error;
            } finally { clearTimeout(timer); pending.delete(requestId); }
        }
    };
}

export function escapeHtml(value) {
    return String(value ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

export function rowsOf(value, ...keys) {
    if (Array.isArray(value)) return value;
    for (const key of keys) if (Array.isArray(value?.[key])) return value[key];
    return [];
}

export function isAllowed(permissions, key) {
    return permissions?.allowedActions?.[key] === true || permissions?.[key] === true;
}
