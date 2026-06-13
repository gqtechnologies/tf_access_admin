<template>
  <nav class="border-b" :aria-label="ariaLabel">
    <ul class="flex flex-wrap gap-1">
      <li v-for="tab in tabs" :key="tab.id">
        <button
          type="button"
          class="inline-flex items-center gap-2 border-b-2 px-3 py-2.5 text-sm font-medium transition-colors"
          :class="
            tab.id === modelValue
              ? 'border-primary text-primary'
              : 'border-transparent text-muted-foreground hover:border-muted-foreground/30 hover:text-foreground'
          "
          @click="emit('update:modelValue', tab.id)"
        >
          <component v-if="tab.icon" :is="tab.icon" class="size-4 shrink-0" />
          {{ tab.label }}
        </button>
      </li>
    </ul>
  </nav>
</template>

<script setup lang="ts">
import type { Component } from 'vue'

export type TabNavItem = {
  id: string
  label: string
  icon?: Component
}

defineProps<{
  tabs: TabNavItem[]
  modelValue: string
  ariaLabel?: string
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void
}>()
</script>
