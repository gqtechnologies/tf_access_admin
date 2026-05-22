import { z } from 'zod'
import { BULK_IMPORT_IMPORT_MODES, BULK_IMPORT_REQUIRED_TARGETS } from '@/lib/constants/bulk_import'
import type { BulkImportColumnMapping } from '@/types/bulk_import'

export const bulkImportConfigureValidationKeys = {
  selected_sheet_required: 'admin.residential_properties.structure.bulk_import.configure.validations.selected_sheet_required',
  import_mode_required: 'admin.residential_properties.structure.bulk_import.configure.validations.import_mode_required',
  default_section_required:
    'admin.residential_properties.structure.bulk_import.configure.validations.default_section_required',
  required_columns_missing:
    'admin.residential_properties.structure.bulk_import.configure.validations.required_columns_missing',
} as const

const importModeSchema = z.enum(BULK_IMPORT_IMPORT_MODES, {
  required_error: bulkImportConfigureValidationKeys.import_mode_required,
  invalid_type_error: bulkImportConfigureValidationKeys.import_mode_required,
})

export const bulkImportConfigureFieldsSchema = z.object({
  selected_sheet: z.string().trim().min(1, bulkImportConfigureValidationKeys.selected_sheet_required),
  import_mode: importModeSchema,
  default_property_section_id: z
    .string()
    .trim()
    .min(1, bulkImportConfigureValidationKeys.default_section_required),
  validate_owners: z.boolean(),
})

export function createBulkImportConfigureSchema(columnMappings: BulkImportColumnMapping[]) {
  return bulkImportConfigureFieldsSchema.superRefine((_data, ctx) => {
    const missingRequired = columnMappings.filter(
      (mapping) =>
        BULK_IMPORT_REQUIRED_TARGETS.includes(
          mapping.target as (typeof BULK_IMPORT_REQUIRED_TARGETS)[number],
        ) && !mapping.matched,
    )

    if (missingRequired.length === 0) return

    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: bulkImportConfigureValidationKeys.required_columns_missing,
      path: ['column_mappings'],
    })
  })
}

export type BulkImportConfigureFieldsSchema = z.infer<typeof bulkImportConfigureFieldsSchema>
