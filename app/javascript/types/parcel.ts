export type ParcelTab = 'received' | 'withdrawn'

export type ParcelWithdrawer = {
  id: string
  name: string
}

export type ConciergeParcel = {
  id: string
  delivery_type: string
  courier_company: string | null
  tracking_code: string | null
  notes: string | null
  status: ParcelTab
  received_at: string
  withdrawn_at: string | null
  withdrawn_by_name: string | null
  unit: { id: string; name: string }
  // Residents with the withdrawal permission; empty once withdrawn.
  eligible_withdrawers: ParcelWithdrawer[]
}

export type ParcelCounters = Record<ParcelTab, number>

export type ParcelUnitOption = {
  id: string
  name: string
}

export type ParcelReceivePayload = {
  unit_id: string
  delivery_type: string
  courier_company?: string
  tracking_code?: string
  notes?: string
}
