<template>
  <button
    type="button"
    class="flex w-full items-center gap-3 rounded-lg border border-border bg-card p-4 text-left transition-colors hover:bg-muted/40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
    @click="emit('select')"
  >
    <span
      class="inline-flex size-12 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary"
      aria-hidden="true"
    >
      <component :is="icon" class="size-6" />
    </span>
    <span class="min-w-0 flex-1 space-y-1">
      <span class="block text-sm font-semibold text-foreground">{{ title }}</span>
      <span class="block text-xs text-muted-foreground">{{ description }}</span>
    </span>
    <ChevronRight class="size-5 shrink-0 text-muted-foreground" aria-hidden="true" />
  </button>
</template>

<script setup lang="ts">
import type { Component } from 'vue'
import { ChevronRight } from 'lucide-vue-next'

defineProps<{
  icon: Component
  title: string
  description: string
}>()

const emit = defineEmits<{
  (e: 'select'): void
}>()
</script>
