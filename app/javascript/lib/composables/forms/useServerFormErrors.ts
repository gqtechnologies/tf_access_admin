import { nextTick } from 'vue'
import type { InertiaErrors } from '@/types/globals'
import { mapServerErrorsToForm } from '@/lib/forms/map_server_errors'

export type ApplyServerErrors = (errors: InertiaErrors) => void

export interface ExposedFormWithServerErrors {
  applyServerErrors: ApplyServerErrors
}

type SetFormErrors = (errors: Record<string, string | undefined>) => void

/** Aplica errores del servidor (Inertia/Rails) a un formulario VeeValidate vía `setErrors`. */
export function useServerFormErrors(setErrors: SetFormErrors) {
  function applyServerErrors(errors: InertiaErrors) {
    if (!errors || Object.keys(errors).length === 0) return

    nextTick(() => {
      setErrors(mapServerErrorsToForm(errors))
    })
  }

  return { applyServerErrors }
}
