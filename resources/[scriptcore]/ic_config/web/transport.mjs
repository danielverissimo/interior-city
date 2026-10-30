export class PanelError extends Error {
    constructor(code, message) { super(message); this.code = code; }
}

// Each mutation is sent once; losing a response never triggers another write.
export function createTransport({ resource = 'ic_config', fetcher = globalThis.fetch, timeout = 22000 } = {}) {
    let sequence = 0;
    const pending = new Map();
    return { pending, async call(method, payload = {}) {
        const requestId = `${Date.now().toString(36)}-${(++sequence).toString(36)}`;
        const controller = new AbortController();
        const timer = setTimeout(() => controller.abort(), timeout);
        pending.set(requestId, method);
        try {
            const response = await fetcher(`https://${resource}/request`, {
                method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify({ requestId, method, payload }), signal: controller.signal
            });
            const envelope = await response.json();
            if (envelope?.requestId && envelope.requestId !== requestId) throw new PanelError('RESPONSE_MISMATCH', 'Resposta de outra solicitação recusada.');
            if (envelope?.ok !== true) throw new PanelError(envelope?.error?.code || 'FAILED', envelope?.error?.message || envelope?.message || 'A operação não foi concluída.');
            return envelope.data;
        } catch (error) {
            if (error?.name === 'AbortError') throw new PanelError('TIMEOUT', 'Sem resposta. Atualize os dados antes de tentar salvar novamente.');
            throw error;
        } finally { clearTimeout(timer); pending.delete(requestId); }
    } };
}

export function escapeHtml(value) {
    return String(value ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

export function createLatestLoader(load, apply) {
    let generation = 0;
    return { cancel() { generation++; }, async run(...args) {
        const current = ++generation;
        try { const value = await load(...args); if (current === generation) { apply(value); return true; } }
        catch (error) { if (current === generation) throw error; }
        return false;
    } };
}

export function createWriteGate() {
    let busy = false;
    return { get busy() { return busy; }, async run(task) {
        if (busy) throw new PanelError('BUSY', 'Uma alteração já está em andamento.');
        busy = true;
        try { return await task(); } finally { busy = false; }
    } };
}
