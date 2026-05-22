import { computed, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { useRailsFetch } from '@/lib/composables/useRailsFetch'

import type {
  BulkImportConfigureForm,
  BulkImportImportMode,
  BulkImportMetadata,
  BulkImportRecord,
} from '@/types/bulk_import'
import { admin_residential_property_bulk_import_path, admin_residential_property_bulk_imports_path } from '@/routes'

export const BULK_UNITS_IMPORT_STEPS = ['method', 'configure', 'preview', 'import'] as const
export type BulkUnitsImportStep = (typeof BULK_UNITS_IMPORT_STEPS)[number]

export type BulkUnitsCreationMethod = 'bulk_import' | 'sequential'

export const BULK_UNITS_EXCEL_ACCEPT =
  '.xlsx,.xls,.csv,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-excel,text/csv'

type BulkImportResponse = {
  bulk_import: BulkImportRecord
}

type BulkImportErrorResponse = {
  errors?: Record<string, string[]>
}

function buildConfigureForm(metadata: BulkImportMetadata): BulkImportConfigureForm {
  const inspection = metadata.file_inspection
  const options = metadata.options

  return {
    selected_sheet: inspection.selected_sheet ?? inspection.sheets[0] ?? '',
    import_mode: (options.import_mode ?? 'create_skip_duplicates') as BulkImportImportMode,
    default_property_section_id: options.default_property_section_id ?? '',
    validate_owners: options.validate_owners ?? true,
  }
}

function errorMessage(data: BulkImportErrorResponse, fallback: string): string {
  return (
    data.errors?.base?.[0] ??
    data.errors?.file?.[0] ??
    data.errors?.selected_sheet?.[0] ??
    fallback
  )
}

export function useBulkUnitsImportWizard() {
  const { t } = useI18n()
  const { railsFetchJson, objectToRailsFormData } = useRailsFetch()

  const state = reactive({
    currentStep: 'method' as BulkUnitsImportStep,
    creationMethod: 'bulk_import' as BulkUnitsCreationMethod,
    selectedFile: null as File | null,
    fileError: null as string | null,
    bulkImport: null as BulkImportRecord | null,
    configureForm: null as BulkImportConfigureForm | null,
    isSubmitting: false,
    isRefreshingSheet: false,
  })

  const isConfigureStepValid = ref(false)

  const stepIndex = computed(() => BULK_UNITS_IMPORT_STEPS.indexOf(state.currentStep))

  const canGoNext = computed(() => {
    if (state.isSubmitting || state.isRefreshingSheet) return false

    if (state.currentStep === 'method') {
      if (state.creationMethod === 'sequential') return false
      return state.selectedFile !== null && state.fileError === null
    }

    if (state.currentStep === 'configure') {
      return (
        state.bulkImport !== null &&
        state.configureForm !== null &&
        isConfigureStepValid.value
      )
    }

    return false
  })

  const canGoBack = computed(() => state.currentStep === 'configure' && !state.isSubmitting)

  function reset() {
    state.currentStep = 'method'
    state.creationMethod = 'bulk_import'
    state.selectedFile = null
    state.fileError = null
    state.bulkImport = null
    state.configureForm = null
    state.isSubmitting = false
    state.isRefreshingSheet = false
    isConfigureStepValid.value = false
  }

  function applyBulkImportResponse(record: BulkImportRecord) {
    state.bulkImport = record
    state.configureForm = buildConfigureForm(record.metadata)
  }

  async function uploadBulkImport(
    residentialPropertyId: string,
    propertySectionId: string,
  ) {
    if (!state.selectedFile || state.fileError) return

    state.isSubmitting = true

    try {
      const bulkImportId = state.bulkImport?.id
      const formPayload: Record<string, unknown> = {
        file: state.selectedFile,
        import_type: 'units',
      }

      if (!bulkImportId) {
        formPayload.property_section_id = propertySectionId
      }

      const formData = objectToRailsFormData('bulk_import', formPayload)
      const url = bulkImportId
        ? admin_residential_property_bulk_import_path(residentialPropertyId, bulkImportId)
        : admin_residential_property_bulk_imports_path(residentialPropertyId)
      const method = bulkImportId ? 'PATCH' : 'POST'

      const { res, data } = await railsFetchJson<BulkImportResponse & BulkImportErrorResponse>(
        method,
        url,
        formData,
      )

      if (!res.ok) {
        toast.error(
          errorMessage(
            data,
            t('admin.residential_properties.structure.bulk_import.errors.upload_failed'),
          ),
        )
        return
      }

      applyBulkImportResponse(data.bulk_import)
      state.currentStep = 'configure'
      toast.success(
        bulkImportId
          ? t('admin.residential_properties.structure.bulk_import.upload.replaced_success')
          : t('admin.residential_properties.structure.bulk_import.upload.uploaded_success'),
      )
    } catch {
      toast.error(t('admin.residential_properties.structure.bulk_import.errors.upload_failed'))
    } finally {
      state.isSubmitting = false
    }
  }

  async function refreshSheetInspection(
    residentialPropertyId: string,
    selectedSheet: string,
  ) {
    const bulkImportId = state.bulkImport?.id
    if (!bulkImportId || !selectedSheet) return

    state.isRefreshingSheet = true

    try {
      const formData = objectToRailsFormData('bulk_import', { selected_sheet: selectedSheet })
      const { res, data } = await railsFetchJson<BulkImportResponse & BulkImportErrorResponse>(
        'PATCH',
        admin_residential_property_bulk_import_path(residentialPropertyId, bulkImportId),
        formData,
      )

      if (!res.ok) {
        toast.error(
          errorMessage(
            data,
            t('admin.residential_properties.structure.bulk_import.errors.sheet_refresh_failed'),
          ),
        )
        return
      }

      applyBulkImportResponse(data.bulk_import)
    } catch {
      toast.error(
        t('admin.residential_properties.structure.bulk_import.errors.sheet_refresh_failed'),
      )
    } finally {
      state.isRefreshingSheet = false
    }
  }

  function goToNextStep(
    residentialPropertyId?: string,
    propertySectionId?: string | null,
  ) {
    if (state.currentStep === 'method') {
      if (!residentialPropertyId || !propertySectionId) return
      void uploadBulkImport(residentialPropertyId, propertySectionId)
      return
    }

    const nextIndex = stepIndex.value + 1
    if (nextIndex < BULK_UNITS_IMPORT_STEPS.length) {
      state.currentStep = BULK_UNITS_IMPORT_STEPS[nextIndex]
    }
  }

  function goToPreviousStep() {
    if (state.currentStep === 'configure') {
      state.currentStep = 'method'
    }
  }

  function prepareFileReplacement() {
    state.currentStep = 'method'
    state.selectedFile = null
    state.fileError = null
    state.configureForm = null
    isConfigureStepValid.value = false
  }

  function setConfigureStepValid(valid: boolean) {
    isConfigureStepValid.value = valid
  }

  return {
    state,
    stepIndex,
    canGoNext,
    canGoBack,
    reset,
    goToNextStep,
    goToPreviousStep,
    prepareFileReplacement,
    refreshSheetInspection,
    setConfigureStepValid,
  }
}
