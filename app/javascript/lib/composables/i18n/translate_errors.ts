import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import type { TranslationOptionalParams } from '@/types/form'
import type { InertiaErrors } from '@/types/globals'

/** Solo traduce si el mensaje parece una clave i18n (ej. "users.validations.xxx"); si no, lo devuelve tal cual (mensajes literales del servidor). */
function translateErrors(errors: Array<string | { message?: string } | undefined>, tOptionalParams: TranslationOptionalParams) {
  const { t } = useI18n()
  return errors.map((e) => {
    const msg = typeof e === 'string' ? e : (e?.message ?? '')
    return isI18nKey(msg) ? t(msg, tOptionalParams) : msg
  })
}

/** Claves i18n son tipo "users.validations.role_required"; mensajes del servidor son frases con espacios. */
function isI18nKey(message: string): boolean {
  return message.length > 0 && message.includes('.') && !message.includes(' ')
}

function messagesToArray(messages: string | string[] | undefined): string[] {
  if (messages === undefined) return []
  return Array.isArray(messages) ? messages : [messages]
}

/** Convierte errores de Inertia/Rails al formato que espera VeeValidate (`setErrors`). */
function mapServerErrorsToForm(errors: InertiaErrors): Record<string, string> {
  return Object.fromEntries(
    Object.entries(errors).map(([key, messages]) => {
      const arr = messagesToArray(messages)
      return [key, arr[0] ?? '']
    })
  )
}

export function useTranslateErrors( params?: TranslationOptionalParams ) {
  const tOptionalParams = ref<TranslationOptionalParams>({})
  onMounted(() => {
    if(Object.keys(params ?? {}).length > 0) {
      tOptionalParams.value = { ...tOptionalParams.value, ...params }
    }
  })
  return {
    translateErrors: (errors: Array<string | { message?: string } | undefined>) => translateErrors(errors, tOptionalParams.value),
    mapServerErrorsToForm,
  }
}