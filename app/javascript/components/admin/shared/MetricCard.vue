<template>
  <Card class="py-2">
    <CardContent class="flex items-center gap-2 px-2">
      <div
        class="flex size-8 shrink-0 items-center justify-center rounded-lg"
        :class="iconWrapperClass"
      >
        <component :is="icon" class="size-4" :class="iconClass" />
      </div>
      <div class="min-w-0 text-xs space-y-1">
        <p class="text-muted-foreground">{{ label }}</p>
        <p class="font-semibold tabular-nums leading-tight">{{ value }}</p>
        <p v-if="description" class="text-muted-foreground">{{ description }}</p>
      </div>
    </CardContent>
  </Card>
</template>

<script setup lang="ts">
import type { Component } from 'vue'
import { Card, CardContent } from '@/components/ui/card'

defineProps<{
  icon: Component
  label: string
  value: string | number
  description?: string
  iconClass?: string
  iconWrapperClass?: string
}>()
</script>
