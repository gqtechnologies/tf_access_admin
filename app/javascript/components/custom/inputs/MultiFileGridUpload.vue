<template>
  <Field :data-invalid="(errors?.length ?? 0) > 0">
    <FieldLabel :for="resolvedInputId">
      {{ label }}
    </FieldLabel>
    <FieldDescription v-if="descriptionText" :id="descriptionId">
      {{ descriptionText }}
    </FieldDescription>

    <div
      :class="
        cn(
          'grid grid-cols-2 gap-4 md:flex md:flex-wrap',
          (errors?.length ?? 0) > 0 &&
            'rounded-lg ring-2 ring-destructive ring-offset-2 ring-offset-background',
        )
      "
    >
      <button
        v-if="canAddMore"
        type="button"
        :disabled="disabled"
        class="h-24 cursor-pointer border-input bg-background text-foreground hover:bg-accent/50 focus-visible:ring-ring flex aspect-square items-center justify-center rounded-lg border border-dashed text-base font-semibold transition-colors focus-visible:ring-2 focus-visible:outline-none disabled:pointer-events-none disabled:opacity-50"
        :aria-label="browseLabel"
        @click="openFilePicker"
      >
        {{ t('common.multi_file_upload.browse') }}
      </button>

      <!-- Fotos ya persistidas (URL + signed_id para remove_photos) -->
      <div
        v-for="ex in visibleExisting"
        :key="'existing-' + ex.signed_id"
        class="relative aspect-square overflow-hidden rounded-lg border border-border bg-muted h-24"
      >
        <img
          v-if="ex.url"
          :src="ex.url"
          :alt="existingAlt(ex)"
          class="size-full object-cover"
        />
        <div
          v-else
          class="flex size-full flex-col items-center justify-center gap-1 p-2 text-center"
        >
          <FileIcon class="text-muted-foreground size-8 shrink-0" aria-hidden="true" />
        </div>
        <button
          type="button"
          class="cursor-pointer bg-background/80 text-foreground hover:bg-background absolute left-2 top-2 inline-flex size-5 items-center justify-center rounded-full shadow-sm backdrop-blur-sm transition-colors focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none"
          :aria-label="t('common.multi_file_upload.remove_file', { name: existingAlt(ex) })"
          :disabled="disabled"
          @click="removeExisting(ex.signed_id)"
        >
          <X class="size-4" />
        </button>
      </div>

      <!-- Archivos nuevos (solo File en el campo `name`) -->
      <div
        v-for="(file, index) in fileList"
        :key="fileKey(file, index)"
        class="relative aspect-square overflow-hidden rounded-lg border border-border bg-muted h-24"
      >
        <img
          v-if="isImageFile(file) && previewUrls[index]"
          :src="previewUrls[index]"
          :alt="file.name"
          class="size-full object-cover"
        />
        <div
          v-else
          class="flex size-full flex-col items-center justify-center gap-1 p-2 text-center"
        >
          <FileIcon class="text-muted-foreground size-8 shrink-0" aria-hidden="true" />
          <span class="text-muted-foreground line-clamp-2 text-xs leading-tight break-all">
            {{ file.name }}
          </span>
        </div>

        <button
          type="button"
          class="cursor-pointer bg-background/80 text-foreground hover:bg-background absolute left-2 top-2 inline-flex size-5 items-center justify-center rounded-full shadow-sm backdrop-blur-sm transition-colors focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none"
          :aria-label="t('common.multi_file_upload.remove_file', { name: file.name })"
          :disabled="disabled"
          @click="removeNewAt(index)"
        >
          <X class="size-4" />
        </button>
      </div>
    </div>

    <input
      :id="resolvedInputId"
      ref="fileInputRef"
      type="file"
      class="sr-only"
      :multiple="maxFiles > 1"
      :accept="accept"
      :disabled="disabled"
      :aria-invalid="(errors?.length ?? 0) > 0"
      :aria-describedby="descriptionId"
      @change="onFileInputChange"
      @blur="handleBlur"
    />

    <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
  </Field>
</template>

<script setup lang="ts">
import { useField } from 'vee-validate'
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { FileIcon, X } from 'lucide-vue-next'
import { Field, FieldDescription, FieldError, FieldLabel } from '@/components/ui/field'
import { useTranslateErrors } from '@/lib/composables/i18n/translate_errors'
import { fileMatchesAccept } from '@/lib/utils/file_accept'
import { cn } from '@/lib/utils'
import { ProductPhotoRef } from '@/types/product'

const props = withDefaults(
  defineProps<{
    /** Nombre del campo vee-validate con los archivos nuevos (File[]) */
    name: string
    label: string
    accept?: string
    maxFiles?: number
    maxFileSizeBytes?: number
    disabled?: boolean
    description?: string
    inputId?: string
    /** Imágenes ya guardadas en servidor; al quitar se añade signed_id a `removeFieldName`. */
    existingPhotos?: ProductPhotoRef[]
    /** Campo vee-validate (array de string) donde acumular signed_id a purgar en el backend. */
    removeFieldName?: string
  }>(),
  {
    accept: 'image/*',
    maxFiles: 5,
    maxFileSizeBytes: undefined,
    disabled: false,
    description: undefined,
    inputId: undefined,
    existingPhotos: () => [],
    removeFieldName: 'remove_photos',
  },
)

const { t } = useI18n()
const { translateErrors } = useTranslateErrors()

const { value, errors, handleBlur, setValue, setErrors } = useField<File[]>(() => props.name)

const { value: removeIdsRaw, setValue: setRemoveIds } = useField<string[]>(
  () => props.removeFieldName,
)

const removeIds = computed(() =>
  Array.isArray(removeIdsRaw.value) ? removeIdsRaw.value : [],
)

const fileInputRef = ref<HTMLInputElement | null>(null)

const resolvedInputId = computed(() => props.inputId ?? `${props.name}-file-input`)
const descriptionId = computed(() => `${resolvedInputId.value}-description`)

const fileList = computed(() => (Array.isArray(value.value) ? value.value : []))

const visibleExisting = computed(() => {
  const pending = new Set(removeIds.value)
  return (props.existingPhotos ?? []).filter((p) => p.signed_id && !pending.has(p.signed_id))
})

const totalSlots = computed(() => visibleExisting.value.length + fileList.value.length)

const canAddMore = computed(() => !props.disabled && totalSlots.value < props.maxFiles)

const previewUrls = ref<string[]>([])

watch(
  () => fileList.value,
  (files) => {
    previewUrls.value.forEach((u) => {
      if (u) URL.revokeObjectURL(u)
    })
    previewUrls.value = files.map((f) => (isImageFile(f) ? URL.createObjectURL(f) : ''))
  },
  { deep: true, immediate: true },
)

onBeforeUnmount(() => {
  previewUrls.value.forEach((u) => {
    if (u) URL.revokeObjectURL(u)
  })
})

const descriptionText = computed(() => {
  if (props.description !== undefined && props.description !== '') return props.description
  return t('common.multi_file_upload.hint', { count: props.maxFiles })
})

const browseLabel = computed(() =>
  t('common.multi_file_upload.browse_aria', { max: props.maxFiles }),
)

function existingAlt(ex: ProductPhotoRef): string {
  return ex.url ? 'image' : ex.signed_id.slice(0, 8)
}

function isImageFile(file: File): boolean {
  return file.type.startsWith('image/')
}

function fileKey(file: File, index: number): string {
  return `${file.name}-${file.size}-${file.lastModified}-${index}`
}

function openFilePicker() {
  fileInputRef.value?.click()
}

function removeExisting(signedId: string) {
  if (!signedId || removeIds.value.includes(signedId)) return
  setRemoveIds([...removeIds.value, signedId])
  setErrors([])
}

function removeNewAt(index: number) {
  const next = [...fileList.value]
  next.splice(index, 1)
  setValue(next)
  setErrors([])
}

function onFileInputChange(ev: Event) {
  const input = ev.target as HTMLInputElement
  const selected = Array.from(input.files || [])
  input.value = ''

  if (selected.length === 0) return

  const merged = [...fileList.value]
  const rejected: string[] = []

  for (const file of selected) {
    const nextTotal = visibleExisting.value.length + merged.length
    if (nextTotal >= props.maxFiles) {
      rejected.push(t('common.multi_file_upload.max_files_reached'))
      break
    }
    if (!fileMatchesAccept(file, props.accept)) {
      rejected.push(
        t('common.multi_file_upload.file_type_not_allowed', { name: file.name }),
      )
      continue
    }
    if (props.maxFileSizeBytes != null && file.size > props.maxFileSizeBytes) {
      rejected.push(
        t('common.multi_file_upload.file_too_large', { name: file.name }),
      )
      continue
    }
    merged.push(file)
  }

  if (rejected.length > 0) {
    setErrors(rejected[0])
  } else {
    setErrors([])
  }

  setValue(merged)
}
</script>
