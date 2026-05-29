import { computed, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { useRailsFetch } from '@/lib/composables/useRailsFetch'

import type {
  BulkImportConfigureForm,
  BulkImportImportMode,
  BulkImportOwnerImportMode,
  BulkImportRecord,
  BulkImportRowsResponse,
} from '@/types/bulk_import'
import {
  canRevalidateBulkImport,
  isBulkImportLocked,
} from '@/lib/constants/bulk_import'
import {
  admin_residential_property_bulk_import_path,
  admin_residential_property_bulk_imports_path,
} from '@/routes'

function validateBulkImportPath(residentialPropertyId: string, bulkImportId: string) {
  return `${admin_residential_property_bulk_import_path(residentialPropertyId, bulkImportId)}/validate`
}

export const BULK_UNITS_IMPORT_STEPS = ['method', 'configure', 'preview', 'import'] as const
export type BulkUnitsImportStep = (typeof BULK_UNITS_IMPORT_STEPS)[number]

export type BulkUnitsCreationMethod = 'bulk_import' | 'sequential'

export const BULK_UNITS_EXCEL_ACCEPT =
  '.xlsx,.xls,.csv,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-excel,text/csv'

type BulkImportResponse = {
  bulk_import: BulkImportRecord
}

type BulkImportValidateResponse = BulkImportResponse & BulkImportRowsResponse

type BulkImportErrorResponse = {
  errors?: Record<string, string[]>
}

function resolveOwnerImportMode(options: BulkImportRecord['metadata']['options']): BulkImportOwnerImportMode {
  if (options.owner_import_mode === 'ignore' || options.owner_import_mode === 'link_existing' || options.owner_import_mode === 'create_missing') {
    return options.owner_import_mode
  }

  const validateOwners = options.validate_owners ?? true
  const createOwners = options.create_owners ?? false

  if (!validateOwners) return 'ignore'
  if (createOwners) return 'create_missing'
  return 'link_existing'
}

function buildConfigureForm(record: BulkImportRecord): BulkImportConfigureForm {
  const inspection = record.metadata.file_inspection
  const options = record.metadata.options

  return {
    selected_sheet: inspection.selected_sheet ?? inspection.sheets[0] ?? '',
    import_mode: (options.import_mode ?? 'create_skip_duplicates') as BulkImportImportMode,
    property_section_id:
      options.property_section_id ?? record.property_section_id ?? '',
    owner_import_mode: resolveOwnerImportMode(options),
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
    initialPreview: null as BulkImportRowsResponse | null,
    isSubmitting: false,
    isRefreshingSheet: false,
    isValidating: false,
  })

  const isConfigureStepValid = ref(false)
  const isPreviewStepConfirmable = ref(false)

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
        isConfigureStepValid.value &&
        !isBulkImportLocked(state.bulkImport.status)
      )
    }

    if (state.currentStep === 'preview') {
      return isPreviewStepConfirmable.value && !state.isValidating
    }

    if (state.currentStep === 'import') {
      return false
    }

    return false
  })

  const canGoBack = computed(
    () =>
      (state.currentStep === 'configure' ||
        state.currentStep === 'preview' ||
        state.currentStep === 'import') &&
      !state.isSubmitting &&
      !state.isValidating,
  )

  function reset() {
    state.currentStep = 'method'
    state.creationMethod = 'bulk_import'
    state.selectedFile = null
    state.fileError = null
    state.bulkImport = null
    state.configureForm = null
    state.initialPreview = null
    state.isSubmitting = false
    state.isRefreshingSheet = false
    state.isValidating = false
    isConfigureStepValid.value = false
    isPreviewStepConfirmable.value = false
  }

  function applyBulkImportResponse(record: BulkImportRecord) {
    state.bulkImport = record
    state.configureForm = buildConfigureForm(record)
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

  async function saveConfigureOptions(residentialPropertyId: string) {
    const bulkImportId = state.bulkImport?.id
    const form = state.configureForm
    if (!bulkImportId || !form) return false

    const formData = objectToRailsFormData('bulk_import', {
      selected_sheet: form.selected_sheet,
      import_mode: form.import_mode,
      property_section_id: form.property_section_id,
      owner_import_mode: form.owner_import_mode,
    })

    const { res, data } = await railsFetchJson<BulkImportResponse & BulkImportErrorResponse>(
      'PATCH',
      admin_residential_property_bulk_import_path(residentialPropertyId, bulkImportId),
      formData,
    )

    if (!res.ok) {
      toast.error(
        errorMessage(
          data,
          t('admin.residential_properties.structure.bulk_import.errors.configure_save_failed'),
        ),
      )
      return false
    }

    applyBulkImportResponse(data.bulk_import)
    return true
  }

  async function validateBulkImport(residentialPropertyId: string) {
    const bulkImportId = state.bulkImport?.id
    if (!bulkImportId) return false

    state.isValidating = true

    try {
      const { res, data } = await railsFetchJson<BulkImportValidateResponse & BulkImportErrorResponse>(
        'POST',
        validateBulkImportPath(residentialPropertyId, bulkImportId),
      )

      if (!res.ok) {
        toast.error(
          errorMessage(
            data,
            t('admin.residential_properties.structure.bulk_import.errors.validation_failed'),
          ),
        )
        return false
      }

      applyBulkImportResponse(data.bulk_import)
      state.initialPreview = {
        rows: data.rows ?? [],
        pagination: data.pagination,
        summary: data.summary,
      }
      return true
    } catch {
      toast.error(t('admin.residential_properties.structure.bulk_import.errors.validation_failed'))
      return false
    } finally {
      state.isValidating = false
    }
  }

  async function proceedFromConfigure(residentialPropertyId: string) {
    if (isBulkImportLocked(state.bulkImport?.status)) {
      toast.error(
        t('admin.residential_properties.structure.bulk_import.errors.wizard_locked'),
      )
      return
    }

    state.isSubmitting = true

    try {
      const saved = await saveConfigureOptions(residentialPropertyId)
      if (!saved) return

      if (
        state.bulkImport?.status === 'validated' &&
        state.initialPreview !== null
      ) {
        state.currentStep = 'preview'
        return
      }

      const validated = await validateBulkImport(residentialPropertyId)
      if (!validated) return

      state.currentStep = 'preview'
    } finally {
      state.isSubmitting = false
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

    if (state.currentStep === 'configure') {
      if (!residentialPropertyId || !propertySectionId) return
      void proceedFromConfigure(residentialPropertyId)
      return
    }

    const nextIndex = stepIndex.value + 1
    if (nextIndex < BULK_UNITS_IMPORT_STEPS.length) {
      state.currentStep = BULK_UNITS_IMPORT_STEPS[nextIndex]
    }
  }

  function goToPreviousStep() {
    if (state.currentStep === 'import') {
      state.currentStep = 'preview'
      return
    }

    if (state.currentStep === 'preview') {
      if (isBulkImportLocked(state.bulkImport?.status)) {
        toast.error(
          t('admin.residential_properties.structure.bulk_import.errors.wizard_locked'),
        )
        return
      }
      state.initialPreview = null
      state.currentStep = 'configure'
      return
    }

    if (state.currentStep === 'configure') {
      state.currentStep = 'method'
    }
  }

  function isBulkImportEditable() {
    return canRevalidateBulkImport(state.bulkImport?.status)
  }

  function prepareFileReplacement() {
    state.currentStep = 'method'
    state.selectedFile = null
    state.fileError = null
    state.configureForm = null
    state.initialPreview = null
    isConfigureStepValid.value = false
  }

  function setConfigureStepValid(valid: boolean) {
    isConfigureStepValid.value = valid
  }

  function setPreviewStepConfirmable(confirmable: boolean) {
    isPreviewStepConfirmable.value = confirmable
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
    setPreviewStepConfirmable,
    applyBulkImportResponse,
    isBulkImportEditable,
    isBulkImportLocked: () => isBulkImportLocked(state.bulkImport?.status),
  }
}
