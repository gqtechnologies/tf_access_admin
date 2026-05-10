<script setup lang="ts">
import { Loader2 } from 'lucide-vue-next'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover'

const open = defineModel<boolean>('open', { required: true })
const search = defineModel<string>('search', { required: true })

defineProps<{
  searchInputId: string
  searchLabel: string
  searchPlaceholder: string
  listAriaLabel: string
  loading: boolean
  showEmptyState: boolean
  emptyText: string
  loadingText: string
}>()

const emit = defineEmits<{
  scroll: [event: Event]
}>()
</script>

<template>
  <Popover v-model:open="open">
    <PopoverTrigger as-child>
      <slot name="trigger" :open="open" />
    </PopoverTrigger>
    <PopoverContent
      class="w-[var(--reka-popover-trigger-width)] min-w-0 max-w-[min(100vw-1rem,var(--reka-popover-trigger-width))] p-0"
      align="start"
    >
      <div class="flex flex-col gap-1 border-b p-2">
        <Label class="sr-only" :for="searchInputId">
          {{ searchLabel }}
        </Label>
        <Input
          :id="searchInputId"
          v-model="search"
          type="search"
          autocomplete="off"
          :placeholder="searchPlaceholder"
          class="h-9"
          @keydown.stop
        />
      </div>
      <div
        class="max-h-60 overflow-y-auto p-1"
        role="listbox"
        :aria-label="listAriaLabel"
        @scroll="emit('scroll', $event)"
      >
        <slot name="before-options" />
        <slot name="options" />
        <div
          v-if="showEmptyState"
          class="text-muted-foreground px-2 py-6 text-center text-sm"
        >
          {{ emptyText }}
        </div>
        <div
          v-if="loading"
          class="text-muted-foreground flex items-center justify-center gap-2 py-3 text-sm"
        >
          <slot name="loading">
            <Loader2 class="size-4 animate-spin" />
          </slot>
          {{ loadingText }}
        </div>
      </div>
    </PopoverContent>
  </Popover>
</template>
