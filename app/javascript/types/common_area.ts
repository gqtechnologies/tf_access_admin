export type CommonAreaRules = Partial<{
  opens_at: string
  closes_at: string
  max_duration_minutes: number
  min_advance_hours: number
  max_reservations_per_month: number
  notes: string
}>

export type AdminCommonArea = {
  id: string
  name: string
  area_type: string
  capacity: number | null
  requires_approval: boolean
  status: 'active' | 'inactive'
  rules: CommonAreaRules
  upcoming_count: number
}

export type ReservationTab = 'pending' | 'upcoming' | 'history'

export type AdminReservation = {
  id: string
  status: 'pending' | 'approved' | 'rejected' | 'cancelled'
  starts_at: string
  ends_at: string
  guest_count: number | null
  rejection_reason: string | null
  common_area: { id: string; name: string }
  unit: { id: string; name: string }
  requested_by_name: string | null
  time_zone: string
}
