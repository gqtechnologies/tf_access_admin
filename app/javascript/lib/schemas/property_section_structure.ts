import { z } from 'zod'
import {
  EDITABLE_SECTION_STATUSES,
  SECTION_TYPE_VALUES,
} from '@/lib/schemas/property_section'

export const PLACEMENT_MODES = ['root', 'child'] as const

export const propertySectionStructureValidationKeys = {
  name_required: 'admin.property_sections.validations.name_required',
  section_type_required: 'admin.property_sections.validations.section_type_required',
  parent_required: 'admin.property_sections.validations.parent_required',
  position_min: 'admin.property_sections.validations.position_min',
  status_required: 'admin.property_sections.validations.status_required',
} as const

const emptyToUndefined = z.preprocess((v) => {
  if (v === '' || v === null || v === undefined) return undefined
  return v
}, z.string().optional())

const sectionTypeSchema = z.enum(SECTION_TYPE_VALUES, {
  required_error: propertySectionStructureValidationKeys.section_type_required,
  invalid_type_error: propertySectionStructureValidationKeys.section_type_required,
})

const editableStatusSchema = z.enum(EDITABLE_SECTION_STATUSES, {
  required_error: propertySectionStructureValidationKeys.status_required,
  invalid_type_error: propertySectionStructureValidationKeys.status_required,
})

const positionSchema = z.preprocess((v) => {
  if (v === '' || v === null || v === undefined) return undefined
  const n = Number(v)
  return Number.isNaN(n) ? undefined : n
}, z.number().int().min(1, propertySectionStructureValidationKeys.position_min).optional())

const sharedFields = {
  name: z.string().trim().min(1, propertySectionStructureValidationKeys.name_required),
  code: emptyToUndefined,
  section_type: sectionTypeSchema,
  parent_id: emptyToUndefined,
  position: positionSchema,
}

/** Create flow — no lifecycle status (backend defaults to active). */
export const propertySectionStructureCreateSchema = z
  .object({
    placement: z.enum(PLACEMENT_MODES),
    ...sharedFields,
  })
  .superRefine((data, ctx) => {
    if (data.placement === 'child' && !data.parent_id) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: propertySectionStructureValidationKeys.parent_required,
        path: ['parent_id'],
      })
    }
  })

/** Edit flow — descriptive fields plus active/inactive status only. */
export const propertySectionStructureEditSchema = z.object({
  placement: z.enum(PLACEMENT_MODES),
  status: editableStatusSchema,
  ...sharedFields,
})

export type PropertySectionStructureCreateSchema = z.infer<
  typeof propertySectionStructureCreateSchema
>
export type PropertySectionStructureEditSchema = z.infer<
  typeof propertySectionStructureEditSchema
>
export type PropertySectionStructureSchema =
  | PropertySectionStructureCreateSchema
  | PropertySectionStructureEditSchema

export const propertySectionMoveSchema = z.object({
  parent_id: emptyToUndefined,
  position: positionSchema,
})

export type PropertySectionMoveSchema = z.infer<typeof propertySectionMoveSchema>
