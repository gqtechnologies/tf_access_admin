<template>
  <Alert variant="warning" class="border-amber-200 bg-amber-50 text-amber-950 dark:border-amber-900 dark:bg-amber-950/30 dark:text-amber-100">
    <TriangleAlert class="size-4" />
    <AlertTitle>{{ t('admin.units.show.occupants.add_occupant.warning.title') }}</AlertTitle>
    <AlertDescription class="space-y-3">
      <p>{{ t('admin.units.show.occupants.add_occupant.warning.description') }}</p>
      <ul class="space-y-2 text-sm">
        <li
          v-for="occupancy in occupancies"
          :key="occupancy.occupancy_id"
          class="rounded-md border border-amber-200/80 bg-background/70 px-3 py-2 dark:border-amber-900/60"
        >
          <p class="font-medium">
            {{ locationLabel(occupancy) }}
          </p>
          <p class="text-muted-foreground">
            {{ occupancy.occupancy_type_label }}
            ·
            {{ t('admin.units.show.occupants.add_occupant.warning.starts_at', { date: formatDate(occupancy.starts_at) }) }}
          </p>
        </li>
      </ul>
    </AlertDescription>
  </Alert>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { TriangleAlert } from 'lucide-vue-next'
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import type { ActiveElsewhereOccupancy } from '@/types/unit'

defineProps<{
  occupancies: ActiveElsewhereOccupancy[]
}>()

const { t, locale } = useI18n()

function locationLabel(occupancy: ActiveElsewhereOccupancy) {
  const unitLabel = occupancy.unit.display_name || occupancy.unit.identifier
  const section = occupancy.property_section?.name
  const parts = [occupancy.property.name, section, unitLabel].filter(Boolean)
  return parts.join(' › ')
}

function formatDate(value: string) {
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return new Intl.DateTimeFormat(locale.value, { dateStyle: 'medium' }).format(date)
}
</script>
