/** Mirrors BulkImportServices::UnitsColumnMapper::TARGET_FIELDS required flags */
export const BULK_IMPORT_REQUIRED_TARGETS = ['unit_identifier', 'unit_type'] as const

export const BULK_IMPORT_IMPORT_MODES = [
  'create_skip_duplicates',
  'create_only',
  'update_only',
] as const
