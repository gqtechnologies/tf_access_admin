import { ref } from 'vue'
import { router } from '@inertiajs/vue3'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { applyErrorsToFormRef } from '@/lib/composables/forms/apply_errors_to_form_ref'
import type { ExposedFormWithServerErrors } from '@/lib/composables/forms/useServerFormErrors'
import type {
  PropertySectionMoveSchema,
  PropertySectionStructureCreateSchema,
  PropertySectionStructureEditSchema,
} from '@/lib/schemas/property_section_structure'
import type { Ref } from 'vue'

type FormRef = Ref<ExposedFormWithServerErrors | null | undefined>

export function usePropertySectionSubmit(formRef: FormRef) {
  const { t } = useI18n()
  const isSubmitting = ref(false)

  function submitCreate(propertyId: string, data: PropertySectionStructureCreateSchema) {
    isSubmitting.value = true
    router.post(
      `/admin/residential_properties/${propertyId}/property_sections`,
      {
        property_section: {
          name: data.name,
          code: data.code,
          section_type: data.section_type,
          parent_id: data.placement === 'root' ? null : data.parent_id,
          position: data.position,
        },
      },
      {
        preserveScroll: true,
        preserveState: true,
        onSuccess: () => toast.success(t('admin.property_sections.created_successfully')),
        onError: (errors) => {
          toast.error(t('admin.property_sections.creation_failed'))
          applyErrorsToFormRef(formRef, errors)
        },
        onFinish: () => {
          isSubmitting.value = false
        },
      },
    )
  }

  function submitUpdate(
    propertyId: string,
    sectionId: string,
    data: PropertySectionStructureEditSchema,
  ) {
    isSubmitting.value = true
    router.put(
      `/admin/residential_properties/${propertyId}/property_sections/${sectionId}`,
      {
        property_section: {
          name: data.name,
          code: data.code,
          section_type: data.section_type,
          position: data.position,
          status: data.status,
        },
      },
      {
        preserveScroll: true,
        preserveState: true,
        onSuccess: () => toast.success(t('admin.property_sections.updated_successfully')),
        onError: (errors) => {
          toast.error(t('admin.property_sections.update_failed'))
          applyErrorsToFormRef(formRef, errors)
        },
        onFinish: () => {
          isSubmitting.value = false
        },
      },
    )
  }

  function submitMove(
    propertyId: string,
    sectionId: string,
    data: PropertySectionMoveSchema,
    options?: { onSuccess?: () => void; onFinish?: () => void },
  ) {
    isSubmitting.value = true
    router.post(
      `/admin/residential_properties/${propertyId}/property_sections/${sectionId}/move`,
      {
        property_section: {
          parent_id: data.parent_id ?? null,
          position: data.position,
        },
      },
      {
        preserveScroll: true,
        preserveState: true,
        onSuccess: () => {
          toast.success(t('admin.residential_properties.structure.move.success'))
          options?.onSuccess?.()
        },
        onError: () => {
          toast.error(t('admin.residential_properties.structure.move.error'))
        },
        onFinish: () => {
          isSubmitting.value = false
          options?.onFinish?.()
        },
      },
    )
  }

  function submitArchive(
    propertyId: string,
    sectionId: string,
    options?: { onSuccess?: () => void; onFinish?: () => void },
  ) {
    isSubmitting.value = true
    router.post(
      `/admin/residential_properties/${propertyId}/property_sections/${sectionId}/archive`,
      {},
      {
        preserveScroll: true,
        preserveState: true,
        onSuccess: () => {
          toast.success(t('admin.residential_properties.structure.archive.success'))
          options?.onSuccess?.()
        },
        onError: () => {
          toast.error(t('admin.residential_properties.structure.archive.error'))
        },
        onFinish: () => {
          isSubmitting.value = false
          options?.onFinish?.()
        },
      },
    )
  }

  return {
    isSubmitting,
    submitCreate,
    submitUpdate,
    submitMove,
    submitArchive,
  }
}
