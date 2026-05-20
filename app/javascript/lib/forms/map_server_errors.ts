import type { InertiaErrors } from '@/types/globals'

function messagesToArray(messages: string | string[] | undefined): string[] {
  if (messages === undefined) return []
  return Array.isArray(messages) ? messages : [messages]
}

/** Convierte errores de Inertia/Rails al formato que espera VeeValidate (`setErrors`). */
export function mapServerErrorsToForm(errors: InertiaErrors): Record<string, string> {
  return Object.fromEntries(
    Object.entries(errors).map(([key, messages]) => {
      const arr = messagesToArray(messages)
      return [key, arr[0] ?? '']
    })
  )
}
