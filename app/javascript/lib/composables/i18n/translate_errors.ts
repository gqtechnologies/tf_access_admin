import { useI18n } from 'vue-i18n'

/** Solo traduce si el mensaje parece una clave i18n (ej. "users.validations.xxx"); si no, lo devuelve tal cual (mensajes literales del servidor). */
function translateErrors(errors: Array<string | { message?: string } | undefined>) {
  const { t } = useI18n()
  return errors.map((e) => {
    const msg = typeof e === 'string' ? e : (e?.message ?? '')
    return isI18nKey(msg) ? t(msg) : msg
  })
}

/** Claves i18n son tipo "users.validations.role_required"; mensajes del servidor son frases con espacios. */
function isI18nKey(message: string): boolean {
  return message.length > 0 && message.includes('.') && !message.includes(' ')
}

function mapServerErrorsToForm(errors: Record<string, string[]>): Record<string, string> {
    return Object.fromEntries(
        Object.entries(errors).map(([key, messages]) => {
            const message = Array.isArray(messages) ? messages[0] : messages
            return [key, message ?? '']
        })
    )
}

export function useTranslateErrors() {
  return {
    translateErrors,
    mapServerErrorsToForm,
  }
}