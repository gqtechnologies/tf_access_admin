import { computed } from 'vue'
import type { BulkImportPreviewSummary } from '@/types/bulk_import'

export function useBulkUnitsPreview(summary: () => BulkImportPreviewSummary | null) {
  const summaryState = computed(() => {
    const value = summary()
    return {
      total: value?.total_rows ?? 0,
      valid: value?.valid_rows ?? 0,
      warnings: value?.warning_rows ?? 0,
      errors: value?.error_rows ?? 0,
      duplicates: value?.duplicate_rows ?? 0,
      skipped: value?.skipped_rows ?? 0,
    }
  })

  const canContinueToImport = computed(() => {
    const current = summaryState.value
    const hasImportableRows =
      current.valid > 0 || current.warnings > 0 || current.duplicates > 0
    return current.errors === 0 && hasImportableRows
  })

  const hasDownloadableErrors = computed(() => summaryState.value.errors > 0)

  const showAttentionAlert = computed(
    () =>
      summaryState.value.errors > 0 ||
      summaryState.value.warnings > 0 ||
      summaryState.value.duplicates > 0,
  )

  return {
    summary: summaryState,
    canContinueToImport,
    hasDownloadableErrors,
    showAttentionAlert,
  }
}
