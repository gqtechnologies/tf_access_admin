import type { FlashData, SharedProps } from '@/types'

declare module '@inertiajs/core' {
  export interface InertiaConfig {
    sharedPageProps: SharedProps
    flashDataType: FlashData
    /** Inertia puede entregar un string o array por campo según versión / adapter. */
    errorValueType: string | string[]
  }
}

/** Errores de página / `onError` de visits; valores homogeneizados en `mapServerErrorsToForm`. */
export type InertiaErrors = Record<string, string | string[]>