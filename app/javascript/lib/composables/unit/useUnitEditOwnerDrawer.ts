import type { UnitOwnershipAssignForm } from '@/lib/schemas/unit_ownership'
import type { UnitOwnership } from '@/types/unit'

export type UnitEditOwnerDrawerSnapshot = {
  ownershipId: string
  ownershipForm: UnitOwnershipAssignForm
}

const EDIT_DRAWER_STATE_KEY = 'unitEditOwnerDrawerState'

export function ownershipToAssignForm(ownership: UnitOwnership): UnitOwnershipAssignForm {
  return {
    ownership_percentage: Number(ownership.ownership_percentage),
    starts_at: ownership.starts_at,
    ends_at: ownership.ends_at ?? '',
  }
}

export function saveEditDrawerState(snapshot: UnitEditOwnerDrawerSnapshot) {
  sessionStorage.setItem(EDIT_DRAWER_STATE_KEY, JSON.stringify(snapshot))
}

export function loadEditDrawerState(): UnitEditOwnerDrawerSnapshot | null {
  const raw = sessionStorage.getItem(EDIT_DRAWER_STATE_KEY)
  if (!raw) return null

  try {
    return JSON.parse(raw) as UnitEditOwnerDrawerSnapshot
  } catch {
    return null
  }
}

export function clearEditDrawerState() {
  sessionStorage.removeItem(EDIT_DRAWER_STATE_KEY)
}
