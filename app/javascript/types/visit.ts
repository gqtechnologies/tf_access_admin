export type VisitPersonSummary = {
  id: string
  display_name: string
}

export type VisitUnitSummary = {
  id: string
  identifier: string
  display_name: string | null
}

export type ConciergeVisitPermissions = {
  show: boolean
  check_in: boolean
  check_out: boolean
  restricted_detail: boolean
}

export type ConciergeVisitListItem = {
  id: string
  status: string
  status_label: string
  visit_type: string | null
  visit_type_label: string | null
  scheduled_at: string
  valid_from: string
  authorized_at: string | null
  checked_in_at: string | null
  checked_out_at: string | null
  visitor: VisitPersonSummary | null
  host: VisitPersonSummary | null
  unit: VisitUnitSummary | null
  permissions: ConciergeVisitPermissions
  actions: string[]
}

export type ConciergeVisitSummary = ConciergeVisitListItem & {
  valid_until: string | null
}

export type ConciergeVisitTab = 'authorized' | 'checked_in' | 'recent_checked_out'

export type ConciergeVisitCounters = {
  authorized: number
  checked_in: number
  recent_checked_out: number
}

export type AssignedPropertySummary = {
  id: string
  name: string
}
