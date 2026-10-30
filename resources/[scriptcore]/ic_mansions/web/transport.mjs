export class HomeError extends Error { constructor(code, message) { super(message); this.code = code; } }
export function createTransport({ resource = 'ic_mansions', fetcher = globalThis.fetch, timeout = 25000 } = {}) {
    let sequence = 0;
    return { async call(method, payload = {}) {
        const requestId = `${Date.now().toString(36)}-${(++sequence).toString(36)}`, controller = new AbortController();
        const timer = setTimeout(() => controller.abort(), timeout);
        try {
            const response = await fetcher(`https://${resource}/request`, { method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify({ requestId, method, payload }), signal: controller.signal });
            const result = await response.json();
            if (result?.requestId && result.requestId !== requestId) throw new HomeError('RESPONSE_MISMATCH', 'A resposta não pertence a esta solicitação.');
            if (result?.ok !== true) throw new HomeError(result?.error?.code || 'FAILED', result?.error?.message || result?.message || 'Não foi possível concluir a operação.');
            return result.data;
        } catch (error) {
            if (error?.name === 'AbortError') throw new HomeError('TIMEOUT', 'Sem resposta da cidade. Atualize antes de tentar novamente.');
            throw error;
        } finally { clearTimeout(timer); }
    } };
}
