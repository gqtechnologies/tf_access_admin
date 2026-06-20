import type { ConciergeVisitListItem } from '@/types/visit'

export function visitInitials(name: string | undefined | null): string {
  if (!name?.trim()) return '?'

  const parts = name.trim().split(/\s+/).slice(0, 2)
  return parts.map((part) => part.charAt(0).toUpperCase()).join('')
}

export function visitStatusTone(status: string): 'success' | 'warning' | 'muted' {
  switch (status) {
    case 'checked_in':
      return 'success'
    case 'authorized':
      return 'warning'
    default:
      return 'muted'
  }
}

export function visitAuthorizedTime(visit: ConciergeVisitListItem): string | null {
  return visit.authorized_at ?? visit.valid_from ?? visit.scheduled_at
}

export function visitLastMovement(visit: ConciergeVisitListItem): {
  at: string | null
  kind: 'checked_out' | 'checked_in' | 'authorized' | null
} {
  if (visit.checked_out_at) {
    return { at: visit.checked_out_at, kind: 'checked_out' }
  }
  if (visit.checked_in_at) {
    return { at: visit.checked_in_at, kind: 'checked_in' }
  }
  if (visit.authorized_at) {
    return { at: visit.authorized_at, kind: 'authorized' }
  }

  return { at: null, kind: null }
}
