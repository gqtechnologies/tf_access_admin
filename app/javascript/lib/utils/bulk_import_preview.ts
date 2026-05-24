import type { BulkImportPreviewFilter } from '@/lib/constants/bulk_import'
import type {
  BulkImportRowNormalizedPayload,
  BulkImportRowRecord,
  BulkImportValidationIssue,
} from '@/types/bulk_import'

export function rowHasOwnerData(payload: BulkImportRowNormalizedPayload): boolean {
  return Boolean(
      payload.owner_first_name?.trim() ||
      payload.owner_last_name?.trim() ||
      payload.owner_email?.trim() ||
      payload.owner_document?.trim() ||
      payload.ownership_percentage != null,
  )
}

export function primaryIssue(
  row: BulkImportRowRecord,
): BulkImportValidationIssue | null {
  if (row.validation_errors.length > 0) return row.validation_errors[0]
  if (row.validation_warnings.length > 0) return row.validation_warnings[0]
  return null
}

export function rowMatchesPreviewFilter(
  row: BulkImportRowRecord,
  filter: BulkImportPreviewFilter,
): boolean {
  switch (filter) {
    case 'all':
      return true
    case 'valid':
      return row.validation_status === 'valid'
    case 'warnings':
      return row.validation_status === 'warning' || row.validation_status === 'duplicate'
    case 'errors':
      return row.validation_status === 'error'
    default:
      return true
  }
}

export function rowMatchesSearch(row: BulkImportRowRecord, query: string): boolean {
  const normalized = query.trim().toLowerCase()
  if (!normalized) return true

  const payload = row.normalized_payload
  const haystack = [
    String(row.row_number),
    payload.section_path,
    payload.section_name,
    payload.unit_identifier,
    payload.unit_type,
    payload.status,
    payload.owner_first_name,
    payload.owner_last_name,
    payload.owner_email,
    payload.owner_document,
    payload.ownership_percentage != null ? String(payload.ownership_percentage) : null,
    ...row.validation_errors.map((issue) => issue.message),
    ...row.validation_warnings.map((issue) => issue.message),
  ]
    .filter(Boolean)
    .join(' ')
    .toLowerCase()

  return haystack.includes(normalized)
}

export function duplicateRowCount(rows: BulkImportRowRecord[]): number {
  return rows.filter((row) => row.validation_status === 'duplicate').length
}
