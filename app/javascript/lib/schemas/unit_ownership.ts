import { z } from 'zod'

export const unitOwnershipValidationKeys = {
  percentage_required: 'admin.unit_ownerships.validations.percentage_required',
  percentage_invalid: 'admin.unit_ownerships.validations.percentage_invalid',
  starts_at_required: 'admin.unit_ownerships.validations.starts_at_required',
} as const

export const addOwnerPersonValidationKeys = {
  document_required: 'admin.units.show.owners.add_owner.create.validations.document_required',
  first_name_required: 'admin.units.show.owners.add_owner.create.validations.first_name_required',
  last_name_required: 'admin.units.show.owners.add_owner.create.validations.last_name_required',
  email_invalid: 'admin.people.validations.email_invalid',
} as const

export const addOwnerPersonSchema = z.object({
  document_number: z.string().trim().min(1, addOwnerPersonValidationKeys.document_required),
  first_name: z.string().trim().min(1, addOwnerPersonValidationKeys.first_name_required),
  last_name: z.string().trim().min(1, addOwnerPersonValidationKeys.last_name_required),
  email: z.union([z.string().email(addOwnerPersonValidationKeys.email_invalid), z.literal('')]).optional(),
})

export const unitOwnershipAssignSchema = z.object({
  ownership_percentage: z
    .coerce.number({ invalid_type_error: unitOwnershipValidationKeys.percentage_invalid })
    .gt(0, unitOwnershipValidationKeys.percentage_invalid)
    .max(100, unitOwnershipValidationKeys.percentage_invalid),
  starts_at: z.string().trim().min(1, unitOwnershipValidationKeys.starts_at_required),
  ends_at: z.string().optional(),
})

export type AddOwnerPersonForm = z.infer<typeof addOwnerPersonSchema>
export type UnitOwnershipAssignForm = z.infer<typeof unitOwnershipAssignSchema>

export function buildDisplayName(firstName: string, lastName: string): string {
  return [firstName, lastName].map((part) => part.trim()).filter(Boolean).join(' ')
}

export function todayIsoDate(): string {
  return new Date().toISOString().slice(0, 10)
}
