import { z } from 'zod'
import {
  addOwnerPersonSchema,
  todayIsoDate,
  type AddOwnerPersonForm,
} from '@/lib/schemas/unit_ownership'

export const unitOccupancyValidationKeys = {
  occupancy_type_required: 'admin.units.show.occupants.add_occupant.assign.validations.occupancy_type_required',
  starts_at_required: 'admin.units.show.occupants.add_occupant.assign.validations.starts_at_required',
} as const

export const unitOccupancyAssignSchema = z.object({
  occupancy_type: z.string().trim().min(1, unitOccupancyValidationKeys.occupancy_type_required),
  can_authorize_visits: z.boolean(),
  starts_at: z.string().trim().min(1, unitOccupancyValidationKeys.starts_at_required),
  ends_at: z.string().optional(),
})

export type UnitOccupancyAssignForm = z.infer<typeof unitOccupancyAssignSchema>
export type AddOccupantPersonForm = AddOwnerPersonForm

export const unitOccupancyEditSchema = unitOccupancyAssignSchema.extend({
  status: z.enum(['active', 'inactive']),
})

export type UnitOccupancyEditForm = z.infer<typeof unitOccupancyEditSchema>

export { addOwnerPersonSchema as addOccupantPersonSchema }

export function dateInputFromIso(value: string | null | undefined): string {
  if (!value) return ''
  if (/^\d{4}-\d{2}-\d{2}$/.test(value)) return value
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value.slice(0, 10)
  return date.toISOString().slice(0, 10)
}

export function createEmptyOccupancyForm(defaultType = 'tenant'): UnitOccupancyAssignForm {
  return {
    occupancy_type: defaultType,
    can_authorize_visits: false,
    starts_at: todayIsoDate(),
    ends_at: '',
  }
}
