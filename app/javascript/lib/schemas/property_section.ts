import { z } from 'zod'

/** Keep in sync with `SectionTypes::ALL` in Ruby. */
export const SECTION_TYPE_VALUES = [
  'block',
  'tower',
  'floor',
  'parking',
  'storage',
  'commercial',
  'amenities',
  'entrance',
  'garden',
  'other',
] as const

export const propertySectionValidationKeys = {
  name_required: 'admin.property_sections.validations.name_required',
  section_type_required: 'admin.property_sections.validations.section_type_required',
  residential_property_required: 'admin.property_sections.validations.residential_property_required',
} as const

const emptyToUndefined = z.preprocess((v) => {
  if (v === '' || v === null || v === undefined) return undefined
  return v
}, z.string().optional())

const sectionTypeSchema = z.enum(SECTION_TYPE_VALUES, {
  required_error: propertySectionValidationKeys.section_type_required,
  invalid_type_error: propertySectionValidationKeys.section_type_required,
})

const positionSchema = z.preprocess((v) => {
  if (v === '' || v === null || v === undefined) return undefined
  const n = Number(v)
  return Number.isNaN(n) ? undefined : n
}, z.number().int().optional())

export const propertySectionSchema = z.object({
  name: z.string().min(1, propertySectionValidationKeys.name_required),
  code: emptyToUndefined,
  section_type: sectionTypeSchema,
  residential_property_id: z
    .string()
    .min(1, propertySectionValidationKeys.residential_property_required),
  parent_id: emptyToUndefined,
  position: positionSchema,
})

export type PropertySectionSchema = z.infer<typeof propertySectionSchema>
