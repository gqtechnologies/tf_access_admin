import type { Ref } from 'vue'
import type { InertiaErrors } from '@/types/globals'
import type { ExposedFormWithServerErrors } from '@/lib/composables/forms/useServerFormErrors'

/** Delega errores de `onError` de Inertia al método expuesto por un Form admin. */
export function applyErrorsToFormRef(
  formRef: Ref<ExposedFormWithServerErrors | null | undefined>,
  errors: InertiaErrors
) {
  if (!errors || Object.keys(errors).length === 0) return
  formRef.value?.applyServerErrors(errors)
}
