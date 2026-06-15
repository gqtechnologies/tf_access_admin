<template>
  <div class="flex flex-col items-center justify-center space-y-6 py-8 text-center">
    <div class="flex size-16 items-center justify-center rounded-full bg-green-500/10 text-green-600">
      <CircleCheck class="size-8" aria-hidden="true" />
    </div>

    <div class="space-y-2">
      <h3 class="text-xl font-semibold">
        {{ t('admin.units.show.occupants.add_occupant.success.title') }}
      </h3>
      <p class="text-sm text-muted-foreground">
        {{ t('admin.units.show.occupants.add_occupant.success.description') }}
      </p>
    </div>

    <div class="w-full max-w-md rounded-lg border bg-card divide-y text-left">
      <div class="px-4 py-3">
        <p class="text-xs font-medium text-muted-foreground">
          {{ t('admin.units.show.occupants.add_occupant.success.occupant') }}
        </p>
        <p class="mt-1 text-sm font-semibold">{{ summary.personDisplayName }}</p>
      </div>
      <div class="px-4 py-3">
        <p class="text-xs font-medium text-muted-foreground">
          {{ t('admin.units.show.occupants.add_occupant.success.unit') }}
        </p>
        <p class="mt-1 text-sm font-semibold">{{ summary.unitTitle }}</p>
      </div>
      <div class="px-4 py-3">
        <p class="text-xs font-medium text-muted-foreground">
          {{ t('admin.units.show.occupants.add_occupant.success.occupancy_type') }}
        </p>
        <p class="mt-1 text-sm font-semibold">{{ summary.occupancyTypeLabel }}</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { CircleCheck } from 'lucide-vue-next'
import type { UnitAddOccupantSuccessSummary } from '@/lib/composables/unit/useUnitAddOccupantDrawer'

defineProps<{
  summary: UnitAddOccupantSuccessSummary
}>()

const { t } = useI18n()
</script>
