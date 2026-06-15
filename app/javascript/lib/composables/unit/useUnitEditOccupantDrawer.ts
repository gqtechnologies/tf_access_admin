import {
  dateInputFromIso,
  type UnitOccupancyEditForm,
} from '@/lib/schemas/unit_occupancy'
import type { UnitOccupancy } from '@/types/unit'

export type UnitEditOccupantDrawerSnapshot = {
  occupancyId: string
  occupancyForm: UnitOccupancyEditForm
}

const EDIT_DRAWER_STATE_KEY = 'unitEditOccupantDrawerState'

export function occupancyToEditForm(occupancy: UnitOccupancy): UnitOccupancyEditForm {
  return {
    occupancy_type: occupancy.occupancy_type,
    can_authorize_visits: occupancy.can_authorize_visits,
    starts_at: dateInputFromIso(occupancy.starts_at),
    ends_at: dateInputFromIso(occupancy.ends_at),
    status: occupancy.status === 'inactive' ? 'inactive' : 'active',
  }
}

export function saveEditDrawerState(snapshot: UnitEditOccupantDrawerSnapshot) {
  sessionStorage.setItem(EDIT_DRAWER_STATE_KEY, JSON.stringify(snapshot))
}

export function loadEditDrawerState(): UnitEditOccupantDrawerSnapshot | null {
  const raw = sessionStorage.getItem(EDIT_DRAWER_STATE_KEY)
  if (!raw) return null

  try {
    return JSON.parse(raw) as UnitEditOccupantDrawerSnapshot
  } catch {
    return null
  }
}

export function clearEditDrawerState() {
  sessionStorage.removeItem(EDIT_DRAWER_STATE_KEY)
}
