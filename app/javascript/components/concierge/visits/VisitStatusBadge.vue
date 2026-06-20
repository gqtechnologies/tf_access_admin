<template>
  <StatusDotBadge :label="label" :tone="tone" />
</template>

<script setup lang="ts">
import { computed } from 'vue'
import StatusDotBadge from '@/components/admin/shared/StatusDotBadge.vue'
import { visitStatusTone } from '@/lib/utils/visit'

const props = defineProps<{
  status: string
  label: string
}>()

const tone = computed(() => visitStatusTone(props.status))
</script>
