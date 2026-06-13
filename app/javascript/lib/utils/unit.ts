export function unitDisplayTitle(displayName: string | null | undefined, identifier: string): string {
  const trimmed = displayName?.trim()
  if (trimmed) return trimmed

  return identifier
}

export function personInitials(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean)
  if (parts.length === 0) return '?'
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase()

  return `${parts[0][0]}${parts[parts.length - 1][0]}`.toUpperCase()
}

export function toPercentageNumber(value: number | string | null | undefined): number {
  const numeric = Number(value)
  if (!Number.isFinite(numeric)) return 0

  return numeric
}

export function formatOwnershipPercentage(value: number | string | null | undefined): string {
  const numeric = toPercentageNumber(value)
  const rounded = Number.isInteger(numeric) ? numeric : Number(numeric.toFixed(1))
  return `${rounded}%`
}
