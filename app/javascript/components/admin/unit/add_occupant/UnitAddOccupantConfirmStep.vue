<template>
  <div class="space-y-6">
    <div class="space-y-1">
      <h3 class="text-base font-semibold">
        {{ t('admin.units.show.occupants.add_occupant.confirm.title') }}
      </h3>
      <p class="text-sm text-muted-foreground">
        {{ t('admin.units.show.occupants.add_occupant.confirm.description') }}
      </p>
    </div>

    <UnitAddOccupantActiveElsewhereWarning
      v-if="activeElsewhere.length > 0"
      :occupancies="activeElsewhere"
    />

    <div class="rounded-lg border bg-card divide-y">
      <div class="px-4 py-3">
        <p class="text-xs font-medium text-muted-foreground">
          {{ t('admin.units.show.occupants.add_occupant.confirm.person') }}
        </p>
        <p class="mt-1 text-sm font-semibold">{{ personDisplayName }}</p>
        <p v-if="personDocument" class="text-sm text-muted-foreground">{{ personDocument }}</p>
      </div>

      <div class="px-4 py-3">
        <p class="text-xs font-medium text-muted-foreground">
          {{ t('admin.units.show.occupants.add_occupant.confirm.unit') }}
        </p>
        <p class="mt-1 text-sm font-semibold">{{ unitTitle }}</p>
      </div>

      <div class="px-4 py-3">
        <p class="text-xs font-medium text-muted-foreground">
          {{ t('admin.units.show.occupants.add_occupant.confirm.occupancy_type') }}
        </p>
        <p class="mt-1 text-sm font-semibold">{{ occupancyTypeLabel }}</p>
      </div>

      <div class="px-4 py-3">
        <p class="text-xs font-medium text-muted-foreground">
          {{ t('admin.units.show.occupants.add_occupant.confirm.can_authorize_visits') }}
        </p>
        <p class="mt-1 text-sm font-semibold">{{ authorizationLabel }}</p>
      </div>

      <div class="px-4 py-3">
        <p class="text-xs font-medium text-muted-foreground">
          {{ t('admin.units.show.occupants.add_occupant.confirm.validity') }}
        </p>
        <p class="mt-1 text-sm font-semibold">{{ validityLabel }}</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import UnitAddOccupantActiveElsewhereWarning from '@/components/admin/unit/add_occupant/UnitAddOccupantActiveElsewhereWarning.vue'
import type { UnitOccupancyAssignForm } from '@/lib/schemas/unit_occupancy'
import type { ActiveElsewhereOccupancy, OccupancyTypeOption } from '@/types/unit'

const props = withDefaults(
  defineProps<{
    personDisplayName: string
    personDocument?: string
    unitTitle: string
    occupancyForm: UnitOccupancyAssignForm
    occupancyTypes: OccupancyTypeOption[]
    activeElsewhere?: ActiveElsewhereOccupancy[]
  }>(),
  { activeElsewhere: () => [] },
)

const { t, locale } = useI18n()

const occupancyTypeLabel = computed(
  () =>
    props.occupancyTypes.find((option) => option.value === props.occupancyForm.occupancy_type)
      ?.label ?? props.occupancyForm.occupancy_type,
)

const authorizationLabel = computed(() =>
  props.occupancyForm.can_authorize_visits
    ? t('admin.units.show.occupants.authorization.yes')
    : t('admin.units.show.occupants.authorization.no'),
)

const validityLabel = computed(() => {
  const start = formatDate(props.occupancyForm.starts_at)
  const end = props.occupancyForm.ends_at
    ? formatDate(props.occupancyForm.ends_at)
    : t('admin.units.show.occupants.open_ended')

  return `${start} – ${end}`
})

function formatDate(value: string) {
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return new Intl.DateTimeFormat(locale.value, { dateStyle: 'medium' }).format(date)
}
</script>
