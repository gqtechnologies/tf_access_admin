<template>
  <div class="space-y-2">
    <input
      ref="fileInputRef"
      type="file"
      class="sr-only"
      :accept="accept"
      :disabled="disabled"
      @change="onInputChange"
    />
    <button
      type="button"
      class="flex w-full cursor-pointer flex-col items-center justify-center gap-2 rounded-lg border border-dashed px-4 py-10 text-center transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50"
      :class="
        isDragging
          ? 'border-primary bg-primary/5'
          : 'border-input bg-muted/20 hover:border-primary/50 hover:bg-muted/40'
      "
      :disabled="disabled"
      :aria-label="browseLabel"
      @click="openFilePicker"
      @dragenter.prevent="onDragEnter"
      @dragover.prevent="onDragOver"
      @dragleave.prevent="onDragLeave"
      @drop.prevent="onDrop"
    >
      <Upload class="size-8 text-muted-foreground" aria-hidden="true" />
      <p class="text-sm font-medium text-foreground">
        {{ title }}
      </p>
      <p class="text-xs text-muted-foreground">
        {{ subtitle }}
      </p>
    </button>

    <div
      v-if="selectedFile"
      class="flex items-center justify-between gap-3 rounded-lg border bg-muted/30 px-3 py-2"
    >
      <div class="flex min-w-0 items-center gap-2">
        <FileSpreadsheet class="size-4 shrink-0 text-primary" aria-hidden="true" />
        <span class="truncate text-sm font-medium">{{ selectedFile.name }}</span>
      </div>
      <Button
        type="button"
        variant="ghost"
        size="icon"
        :aria-label="removeLabel"
        :disabled="disabled"
        @click="clearFile"
      >
        <X class="size-4" />
      </Button>
    </div>

    <p v-if="error" class="text-sm text-destructive">
      {{ error }}
    </p>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { FileSpreadsheet, Upload, X } from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { fileMatchesAccept } from '@/lib/utils/file_accept'

const props = withDefaults(
  defineProps<{
    accept: string
    selectedFile: File | null
    error?: string | null
    title: string
    subtitle: string
    browseLabel: string
    removeLabel: string
    invalidTypeMessage: string
    disabled?: boolean
  }>(),
  {
    error: null,
    disabled: false,
  }
)

const emit = defineEmits<{
  (e: 'update:selectedFile', value: File | null): void
  (e: 'update:error', value: string | null): void
}>()

const fileInputRef = ref<HTMLInputElement | null>(null)
const isDragging = ref(false)

function openFilePicker() {
  fileInputRef.value?.click()
}

function validateAndSet(file: File | null) {
  if (!file) {
    emit('update:selectedFile', null)
    emit('update:error', null)
    return
  }

  if (!fileMatchesAccept(file, props.accept)) {
    emit('update:selectedFile', null)
    emit('update:error', props.invalidTypeMessage)
    return
  }

  emit('update:selectedFile', file)
  emit('update:error', null)
}

function onInputChange(event: Event) {
  const input = event.target as HTMLInputElement
  validateAndSet(input.files?.[0] ?? null)
  input.value = ''
}

function clearFile() {
  validateAndSet(null)
  if (fileInputRef.value) fileInputRef.value.value = ''
}

function onDragEnter() {
  isDragging.value = true
}

function onDragOver() {
  isDragging.value = true
}

function onDragLeave() {
  isDragging.value = false
}

function onDrop(event: DragEvent) {
  isDragging.value = false
  validateAndSet(event.dataTransfer?.files?.[0] ?? null)
}
</script>
