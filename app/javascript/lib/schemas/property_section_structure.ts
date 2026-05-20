import { z } from 'zod'
import { SECTION_TYPE_VALUES } from '@/lib/schemas/property_section'

export const PLACEMENT_MODES = ['root', 'child'] as const

export const propertySectionStructureValidationKeys = {
  name_required: 'admin.property_sections.validations.name_required',
  section_type_required: 'admin.property_sections.validations.section_type_required',
  parent_required: 'admin.property_sections.validations.parent_required',
  position_min: 'admin.property_sections.validations.position_min',
} as const

const emptyToUndefined = z.preprocess((v) => {
  if (v === '' || v === null || v === undefined) return undefined
  return v
}, z.string().optional())

const sectionTypeSchema = z.enum(SECTION_TYPE_VALUES, {
  required_error: propertySectionStructureValidationKeys.section_type_required,
  invalid_type_error: propertySectionStructureValidationKeys.section_type_required,
})

const positionSchema = z.preprocess((v) => {
  if (v === '' || v === null || v === undefined) return undefined
  const n = Number(v)
  return Number.isNaN(n) ? undefined : n
}, z.number().int().min(1, propertySectionStructureValidationKeys.position_min).optional())

export const propertySectionStructureSchema = z
  .object({
    placement: z.enum(PLACEMENT_MODES),
    name: z.string().trim().min(1, propertySectionStructureValidationKeys.name_required),
    code: emptyToUndefined,
    section_type: sectionTypeSchema,
    parent_id: emptyToUndefined,
    position: positionSchema,
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

export type PropertySectionStructureSchema = z.infer<typeof propertySectionStructureSchema>
