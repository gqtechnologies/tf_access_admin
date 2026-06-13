<template>
  <div class="flex min-w-[7rem] items-center gap-2">
    <div class="h-1.5 flex-1 overflow-hidden rounded-full bg-muted">
      <div
        class="h-full rounded-full transition-all"
        :class="barClass"
        :style="{ width: `${clampedPercentage}%` }"
      />
    </div>
    <span class="shrink-0 text-sm tabular-nums text-muted-foreground">{{ formatted }}</span>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { formatOwnershipPercentage, toPercentageNumber } from '@/lib/utils/unit'

const props = withDefaults(
  defineProps<{
    percentage: number | string
    active?: boolean
  }>(),
  {
    active: true,
  },
)

const numericPercentage = computed(() => toPercentageNumber(props.percentage))
const clampedPercentage = computed(() =>
  Math.min(Math.max(numericPercentage.value, 0), 100)
)
const formatted = computed(() => formatOwnershipPercentage(numericPercentage.value))
const barClass = computed(() => (props.active ? 'bg-green-500' : 'bg-muted-foreground/50'))
</script>
