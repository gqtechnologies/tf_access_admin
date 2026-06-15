<template>
  <div class="space-y-6 w-full">
    <PanelHeader
      :title="t('admin.units.show.occupants.title')"
      :description="t('admin.units.show.occupants.description')"
    >
      <template #actions>
        <Button v-if="permissions.create" @click="openAddOccupantDrawer">
          <Plus class="size-4" />
          {{ t('admin.units.show.occupants.add_occupant.title') }}
        </Button>
      </template>
    </PanelHeader>

    <div class="flex flex-col lg:flex-row lg:justify-start lg:items-start lg:gap-2 gap-4">
      <MetricCard
        v-for="card in metricCards"
        :key="card.key"
        :icon="card.icon"
        :label="card.label"
        :value="card.value"
        :icon-class="card.iconClass"
        :icon-wrapper-class="card.iconWrapperClass"
      />
    </div>

    <UnitOccupantsTable
      :occupancies="occupancies"
      :residential-property-id="unit.residential_property_id"
      :unit-id="unit.id"
      :occupancies-pagination="occupanciesPagination"
      :include-inactive="includeInactive"
      :permissions="permissions"
      @update:include-inactive="updateIncludeInactive"
      @edit="handleEdit"
      @toggle-status="toggleStatus"
      @delete="confirmDelete"
    />

    <UnitAddOccupantDrawer
      v-model:open="addOccupantOpen"
      :unit="unit"
      :occupancy-types="occupancyTypes"
      :errors="addDrawerErrors"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { router, usePage } from '@inertiajs/vue3'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import { History, Plus, ShieldCheck, UserRound, Users } from 'lucide-vue-next'
import MetricCard from '@/components/admin/shared/MetricCard.vue'
import PanelHeader from '@/components/admin/shared/PanelHeader.vue'
import UnitAddOccupantDrawer from '@/components/admin/unit/add_occupant/UnitAddOccupantDrawer.vue'
import UnitOccupantsTable from '@/components/admin/unit/UnitOccupantsTable.vue'
import { Button } from '@/components/ui/button'
import {
  isOccupancyDrawerError,
  loadSuccessState,
} from '@/lib/composables/unit/useUnitAddOccupantDrawer'
import { adminResidentialPropertyUnitOccupancyPath } from '@/lib/paths/unit_occupancies'
import { admin_residential_property_unit_path } from '@/routes'
import type {
  OccupancyTypeOption,
  UnitDetail,
  UnitOccupanciesPagination,
  UnitOccupancy,
  UnitOccupancyPermissions,
} from '@/types/unit'

const props = defineProps<{
  unit: UnitDetail
  occupancies: UnitOccupancy[]
  occupanciesPagination?: UnitOccupanciesPagination
  occupancyTypes: OccupancyTypeOption[]
  permissions: UnitOccupancyPermissions
  occupanciesIncludeInactive?: boolean
  errors?: Record<string, string[]>
}>()

const { t } = useI18n()
const page = usePage()
const addOccupantOpen = ref(!!loadSuccessState())

const addDrawerErrors = computed(() => props.errors)

function openAddOccupantDrawer() {
  if (!props.permissions.create) return
  addOccupantOpen.value = true
}

watch(
  () => props.errors,
  (errors) => {
    if (!isOccupancyDrawerError(errors)) return
    if (props.permissions.create) addOccupantOpen.value = true
  },
  { immediate: true },
)

const includeInactive = ref(props.occupanciesIncludeInactive ?? readIncludeInactiveFromUrl())

watch(
  () => props.occupanciesIncludeInactive,
  (value) => {
    if (typeof value === 'boolean') includeInactive.value = value
  },
)

function readIncludeInactiveFromUrl() {
  const url = new URL(page.url, window.location.origin)
  return url.searchParams.get('occupancies_include_inactive') === 'true'
}

function unitShowParams(extra: Record<string, string | number | boolean> = {}) {
  return {
    tab: 'occupants',
    occupancies_include_inactive: includeInactive.value,
    ...extra,
  }
}

function updateIncludeInactive(checked: boolean) {
  includeInactive.value = checked
  router.get(
    admin_residential_property_unit_path(props.unit.residential_property_id, props.unit.id),
    unitShowParams({ occupancies_page: 1 }),
    { preserveState: true, preserveScroll: true },
  )
}

function handleEdit(_occupancy: UnitOccupancy) {
  toast.info(t('admin.units.show.occupants.actions.edit_coming_soon'))
}

function toggleStatus(occupancy: UnitOccupancy) {
  if (!props.permissions.update) return

  const nextStatus = occupancy.status === 'active' ? 'inactive' : 'active'

  router.patch(
    adminResidentialPropertyUnitOccupancyPath(
      props.unit.residential_property_id,
      props.unit.id,
      occupancy.id,
    ),
    { unit_occupancy: { status: nextStatus } },
    {
      preserveScroll: true,
      onSuccess: () => {
        toast.success(
          nextStatus === 'active'
            ? t('admin.units.show.occupants.actions.activate_success')
            : t('admin.units.show.occupants.actions.deactivate_success'),
        )
      },
      onError: () => {
        toast.error(t('admin.units.show.occupants.actions.status_error'))
      },
    },
  )
}

function confirmDelete(occupancy: UnitOccupancy) {
  if (!props.permissions.destroy) return

  const confirmed = window.confirm(
    t('admin.units.show.occupants.actions.delete_description', {
      name: occupancy.person_display_name,
    }),
  )
  if (!confirmed) return

  router.delete(
    adminResidentialPropertyUnitOccupancyPath(
      props.unit.residential_property_id,
      props.unit.id,
      occupancy.id,
    ),
    {
      preserveScroll: true,
      onSuccess: () => {
        toast.success(t('admin.units.show.occupants.actions.delete_success'))
      },
      onError: () => {
        toast.error(t('admin.units.show.occupants.actions.delete_error'))
      },
    },
  )
}

const metricCards = computed(() => {
  const stats = props.unit.occupancy_stats

  return [
    {
      key: 'active',
      icon: Users,
      label: t('admin.units.show.occupants.metrics.active'),
      value: String(stats.active_occupants_count),
      iconClass: 'text-green-600',
      iconWrapperClass: 'bg-green-500/10',
    },
    {
      key: 'authorizers',
      icon: ShieldCheck,
      label: t('admin.units.show.occupants.metrics.authorizers'),
      value: String(stats.active_authorizers_count),
      iconClass: 'text-blue-600',
      iconWrapperClass: 'bg-blue-500/10',
    },
    {
      key: 'historical',
      icon: History,
      label: t('admin.units.show.occupants.metrics.historical'),
      value: String(stats.historical_occupants_count),
      iconClass: 'text-purple-600',
      iconWrapperClass: 'bg-purple-500/10',
    },
    {
      key: 'total',
      icon: UserRound,
      label: t('admin.units.show.occupants.metrics.total'),
      value: String(stats.total_occupants_count),
      iconClass: 'text-amber-600',
      iconWrapperClass: 'bg-amber-500/10',
    },
  ]
})
</script>
