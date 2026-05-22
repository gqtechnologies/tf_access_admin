export type BulkImportColumnMapping = {
  source: string | null
  target: string
  required: boolean
  matched: boolean
}

export type BulkImportFileInspection = {
  sheets: string[]
  selected_sheet: string | null
  headers: string[]
  row_count: number
  error: string | null
}

export type BulkImportOptions = {
  import_mode: string
  default_property_section_id: string | null
  validate_owners: boolean
}

export type BulkImportMetadata = {
  file_inspection: BulkImportFileInspection
  column_mappings: BulkImportColumnMapping[]
  options: BulkImportOptions
}

export type BulkImportRecord = {
  id: string
  status: string
  import_type: string
  original_filename: string | null
  content_type: string | null
  file_size: number | null
  metadata: BulkImportMetadata
  residential_property_id: string | null
  property_section_id: string | null
  created_at: string
}

export type BulkImportImportMode =
  | 'create_skip_duplicates'
  | 'create_only'
  | 'update_only'

export type BulkImportConfigureForm = {
  selected_sheet: string
  import_mode: BulkImportImportMode
  default_property_section_id: string
  validate_owners: boolean
}
