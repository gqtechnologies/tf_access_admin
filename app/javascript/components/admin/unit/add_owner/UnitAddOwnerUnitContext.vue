<template>
  <div class="rounded-lg border bg-card px-4 py-3">
    <p class="text-xs font-medium text-muted-foreground">
      {{ t('admin.units.show.owners.add_owner.unit_label') }}
    </p>
    <p class="mt-1 text-sm font-medium">{{ breadcrumb }}</p>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import type { UnitDetail } from '@/types/unit'

const props = defineProps<{
  unit: UnitDetail
}>()

const { t } = useI18n()

const breadcrumb = computed(() => {
  const segments = [props.unit.residential_property_name, ...props.unit.location_path, props.unit.title]
  return segments.filter(Boolean).join(' › ')
})
</script>
