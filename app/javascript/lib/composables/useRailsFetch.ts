export type RailsFetchInit = Omit<RequestInit, 'method' | 'body'> & {
  /** No añade la cabecera `X-CSRF-Token` (casos excepcionales). */
  skipCsrf?: boolean
}

export type RailsFormDataSource = Record<string, unknown>

/**
 * Convierte un objeto plano en `FormData` con claves `rootKey[campo]` (parámetros anidados de Rails).
 * Omite `null` y `undefined`; los `false` booleanos se omiten (equivalente a checkbox sin marcar).
 * Los `File`/`Blob` se envían como archivo; el resto se convierte con `String(...)`.
 */
export function objectToRailsFormData(rootKey: string, data: RailsFormDataSource): FormData {
  const fd = new FormData()
  for (const [key, value] of Object.entries(data)) {
    if (value === undefined || value === null) continue
    if (value === false) continue
    const field = `${rootKey}[${key}]`
    if (value instanceof File) {
      fd.append(field, value)
    } else if (value instanceof Blob) {
      fd.append(field, value)
    } else if (typeof value === 'boolean') {
      fd.append(field, value ? '1' : '0')
    } else if (typeof value === 'number') {
      fd.append(field, String(value))
    } else {
      fd.append(field, String(value))
    }
  }
  return fd
}

function readCsrfToken(): string | undefined {
  if (typeof document === 'undefined') return undefined
  return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') ?? undefined
}

/**
 * Peticiones `fetch` al mismo origen con CSRF y credenciales por defecto (Rails + sesión cookie).
 * No usa Inertia: apto para endpoints JSON desde modales u otras vistas Inertia.
 */
export function useRailsFetch() {
  /**
   * @param method HTTP (GET, POST, PATCH, …)
   * @param url Ruta absoluta o relativa (p. ej. salida de `*_path` en `routes.js`)
   * @param body Opcional; omitir en GET/HEAD
   */
  async function railsFetch(
    method: string,
    url: string,
    body?: BodyInit | null,
    init: RailsFetchInit = {},
  ): Promise<Response> {
    const { skipCsrf, headers: userHeaders, ...rest } = init
    const headers = new Headers(userHeaders)

    if (!skipCsrf) {
      const token = readCsrfToken()
      if (token) headers.set('X-CSRF-Token', token)
    }
    if (!headers.has('Accept')) {
      headers.set('Accept', 'application/json')
    }

    return fetch(url, {
      ...rest,
      method,
      body: body ?? undefined,
      credentials: rest.credentials ?? 'same-origin',
      headers,
    })
  }

  async function railsFetchJson<T = unknown>(
    method: string,
    url: string,
    body?: BodyInit | null,
    init: RailsFetchInit = {},
  ): Promise<{ res: Response; data: T }> {
    const res = await railsFetch(method, url, body, init)
    let data = {} as T
    try {
      data = (await res.json()) as T
    } catch {
      /* cuerpo vacío o no JSON */
    }
    return { res, data }
  }

  return {
    railsFetch,
    railsFetchJson,
    objectToRailsFormData,
    readCsrfToken,
  }
}
