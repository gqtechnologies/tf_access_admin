<template>
  <Empty class="border rounded-lg py-16">
    <EmptyHeader>
      <EmptyTitle>{{ title }}</EmptyTitle>
      <EmptyDescription>{{ description }}</EmptyDescription>
    </EmptyHeader>
  </Empty>
</template>

<script setup lang="ts">
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyTitle,
} from '@/components/ui/empty'

defineProps<{
  title: string
  description: string
}>()
</script>
