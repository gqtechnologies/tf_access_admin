/** Mirrors BulkImportServices::UnitsColumnMapper::TARGET_FIELDS required flags */
export const BULK_IMPORT_REQUIRED_TARGETS = ['unit_identifier', 'unit_type'] as const

export const BULK_IMPORT_IMPORT_MODES = [
  'create_skip_duplicates',
  'create_only',
  'update_only',
] as const

export const BULK_IMPORT_OWNER_IMPORT_MODES = [
  'ignore',
  'link_existing',
  'create_missing',
] as const

export const BULK_IMPORT_VALIDATION_STATUSES = [
  'pending',
  'valid',
  'warning',
  'error',
  'duplicate',
] as const

export type BulkImportValidationStatus = (typeof BULK_IMPORT_VALIDATION_STATUSES)[number]

export const BULK_IMPORT_PREVIEW_FILTERS = ['all', 'valid', 'warnings', 'errors'] as const

export type BulkImportPreviewFilter = (typeof BULK_IMPORT_PREVIEW_FILTERS)[number]

export const BULK_IMPORT_PREVIEW_PER_PAGE = 10

export const BULK_IMPORT_PREVIEW_PER_PAGE_OPTIONS = [10, 25, 50] as const
