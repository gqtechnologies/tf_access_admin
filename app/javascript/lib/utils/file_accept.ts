/**
 * Comprueba si un archivo cumple el atributo HTML `accept` (tipos MIME, wildcards y extensiones).
 * @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/file#accept
 */
export function fileMatchesAccept(file: File, accept: string): boolean {
  const trimmed = accept.trim()
  if (!trimmed) return true

  const tokens = trimmed
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean)

  for (const token of tokens) {
    if (token.startsWith('.')) {
      const dot = file.name.lastIndexOf('.')
      const ext = dot >= 0 ? file.name.slice(dot).toLowerCase() : ''
      if (ext === token.toLowerCase()) return true
      continue
    }
    if (token.endsWith('/*')) {
      const prefix = token.slice(0, -1)
      if (file.type.startsWith(prefix)) return true
      continue
    }
    if (file.type === token) return true
  }

  return false
}
