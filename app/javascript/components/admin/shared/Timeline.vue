<template>
  <div class="space-y-4">
    <Empty v-if="entries.length === 0" class="border-0 py-8">
      <EmptyHeader>
        <EmptyTitle>{{ emptyTitle }}</EmptyTitle>
        <EmptyDescription v-if="emptyDescription">{{ emptyDescription }}</EmptyDescription>
      </EmptyHeader>
    </Empty>

    <ol v-else class="relative m-0 list-none space-y-6 p-0">
      <li
        v-for="(entry, index) in entries"
        :key="entry.id"
        class="relative pl-6"
      >
        <span
          class="absolute left-0 top-1.5 size-2.5 rounded-full ring-4 ring-background"
          :class="toneDotClass(entry.tone)"
        />
        <span
          v-if="index < entries.length - 1"
          class="absolute left-[4px] top-4 h-[calc(100%+0.75rem)] w-px bg-border"
          aria-hidden="true"
        />
        <p class="text-xs text-muted-foreground">{{ formatDateTime(entry.occurred_at) }}</p>
        <p class="mt-1 text-sm leading-snug">{{ entry.description }}</p>
        <p class="mt-0.5 text-xs text-muted-foreground">{{ entry.actor_name }}</p>
      </li>
    </ol>
  </div>
</template>

<script setup lang="ts">
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyTitle,
} from '@/components/ui/empty'

export type TimelineEntry = {
  id: string
  occurred_at: string
  description: string
  actor_name: string
  tone?: 'success' | 'warning' | 'neutral'
}

const props = defineProps<{
  entries: TimelineEntry[]
  emptyTitle: string
  emptyDescription?: string
  locale?: string
}>()

function toneDotClass(tone: TimelineEntry['tone'] = 'neutral') {
  if (tone === 'success') return 'bg-green-500'
  if (tone === 'warning') return 'bg-amber-500'
  return 'bg-muted-foreground'
}

function formatDateTime(value: string) {
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value

  return new Intl.DateTimeFormat(props.locale, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(date)
}
</script>
