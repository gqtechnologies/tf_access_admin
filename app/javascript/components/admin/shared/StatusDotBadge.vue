<template>
  <Badge :variant="variant" class="gap-1.5 font-normal">
    <span class="size-1.5 rounded-full" :class="dotClass" aria-hidden="true" />
    <slot>{{ label }}</slot>
  </Badge>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { Badge } from '@/components/ui/badge'

const props = withDefaults(
  defineProps<{
    label: string
    tone?: 'success' | 'warning' | 'muted' | 'destructive'
    variant?: 'default' | 'secondary' | 'outline' | 'destructive'
  }>(),
  {
    tone: 'muted',
    variant: 'secondary',
  },
)

const dotClass = computed(() => {
  switch (props.tone) {
    case 'success':
      return 'bg-green-500'
    case 'warning':
      return 'bg-amber-500'
    case 'destructive':
      return 'bg-destructive'
    default:
      return 'bg-muted-foreground'
  }
})
</script>
