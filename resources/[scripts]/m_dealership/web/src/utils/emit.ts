import { isEnvBrowser } from './misc'

const NUI_TIMEOUT_MS = 15000

export async function emit<T = any>(
  eventName: string,
  data?: any,
  mockData?: T,
): Promise<T> {
  if (isEnvBrowser() && mockData !== undefined) return mockData

  const resourceName = (window as any).GetParentResourceName
    ? (window as any).GetParentResourceName()
    : 'nui-frame-app'

  const controller = new AbortController()
  const timeout = window.setTimeout(() => controller.abort(), NUI_TIMEOUT_MS)

  try {
    const resp = await fetch(`https://${resourceName}/${eventName}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: JSON.stringify(data ?? {}),
      signal: controller.signal,
    })

    if (!resp.ok) {
      throw new Error(`NUI ${eventName} retornou HTTP ${resp.status}`)
    }

    const text = await resp.text()
    if (!text) return false as T

    try {
      return JSON.parse(text) as T
    } catch {
      throw new Error(`Resposta inválida da rota NUI ${eventName}`)
    }
  } catch (error) {
    console.error(`[m_dealership] Falha na rota NUI ${eventName}:`, error)
    throw error
  } finally {
    window.clearTimeout(timeout)
  }
}
