import { z } from 'zod'

/** Keep in sync with `PropertyTypes::ALL` in Ruby. */
export const PROPERTY_TYPE_VALUES = [
  'building',
  'condominium',
  'horizontal_community',
  'residential_complex',
  'mixed_use',
  'tower',
  'sector',
  'other',
] as const

export const RESIDENTIAL_PROPERTY_STATUSES = ['active', 'inactive'] as const

export const residentialPropertyValidationKeys = {
  name_required: 'admin.residential_properties.validations.name_required',
  property_type_required: 'admin.residential_properties.validations.property_type_required',
  status_required: 'admin.residential_properties.validations.status_required',
  country_required: 'admin.residential_properties.validations.country_required',
  timezone_required: 'admin.residential_properties.validations.timezone_required',
} as const

const emptyToUndefined = z.preprocess((v) => {
  if (v === '' || v === null || v === undefined) return undefined
  return v
}, z.string().optional())

const propertyTypeSchema = z.enum(PROPERTY_TYPE_VALUES, {
  required_error: residentialPropertyValidationKeys.property_type_required,
  invalid_type_error: residentialPropertyValidationKeys.property_type_required,
})

const statusSchema = z.enum(RESIDENTIAL_PROPERTY_STATUSES, {
  required_error: residentialPropertyValidationKeys.status_required,
  invalid_type_error: residentialPropertyValidationKeys.status_required,
})

/** Nombre distinto de `country` para evitar que el autofill del navegador vacíe el input (`name="country"`). */
export const residentialPropertySchema = z.object({
  name: z.string().min(1, residentialPropertyValidationKeys.name_required),
  code: emptyToUndefined,
  property_type: propertyTypeSchema,
  address_line: emptyToUndefined,
  city: emptyToUndefined,
  region: emptyToUndefined,
  country: z.string().min(1, residentialPropertyValidationKeys.country_required),
  timezone: z.string().min(1, residentialPropertyValidationKeys.timezone_required),
  status: statusSchema,
})

export type ResidentialPropertySchema = z.infer<typeof residentialPropertySchema>
