<template>
  <div class="space-y-6 w-full">
    <PanelHeader
      :title="t('admin.units.show.owners.title')"
      :description="t('admin.units.show.owners.description')"
    >
      <template #actions>
        <TooltipProvider>
          <Tooltip :disabled="canAddOwner">
            <TooltipTrigger as-child>
              <span class="inline-flex">
                <Button :disabled="!canAddOwner" @click="openAddOwnerDrawer">
                  <Plus class="size-4" />
                  {{ t('admin.units.show.owners.add_owner.title') }}
                </Button>
              </span>
            </TooltipTrigger>
            <TooltipContent>
              {{ t('admin.units.show.owners.add_owner.capacity_full') }}
            </TooltipContent>
          </Tooltip>
        </TooltipProvider>
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

    <UnitOwnersTable
      :ownerships="ownerships"
      :residential-property-id="unit.residential_property_id"
      :unit-id="unit.id"
      :ownerships-pagination="ownershipsPagination"
      @edit="openEditDrawer"
      @delete="confirmDelete"
    />

    <UnitAddOwnerDrawer v-model:open="addOwnerOpen" :unit="unit" :errors="addDrawerErrors" />

    <UnitEditOwnerDrawer
      v-model:open="editOwnerOpen"
      :unit="unit"
      :ownership="editingOwnership"
      :errors="editDrawerErrors"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { router } from '@inertiajs/vue3'
import { toast } from 'vue-sonner'
import { Clock, History, Percent, Plus, Users } from 'lucide-vue-next'
import MetricCard from '@/components/admin/shared/MetricCard.vue'
import PanelHeader from '@/components/admin/shared/PanelHeader.vue'
import UnitAddOwnerDrawer from '@/components/admin/unit/add_owner/UnitAddOwnerDrawer.vue'
import UnitEditOwnerDrawer from '@/components/admin/unit/edit_owner/UnitEditOwnerDrawer.vue'
import UnitOwnersTable from '@/components/admin/unit/UnitOwnersTable.vue'
import { Button } from '@/components/ui/button'
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip'
import { isOwnershipDrawerError } from '@/lib/composables/unit/useUnitAddOwnerDrawer'
import { loadEditDrawerState } from '@/lib/composables/unit/useUnitEditOwnerDrawer'
import { adminResidentialPropertyUnitOwnershipPath } from '@/lib/paths/unit_ownerships'
import { formatOwnershipPercentage, toPercentageNumber } from '@/lib/utils/unit'
import type { UnitDetail, UnitOwnership, UnitOwnershipsPagination } from '@/types/unit'

const props = defineProps<{
  unit: UnitDetail
  ownerships: UnitOwnership[]
  ownershipsPagination?: UnitOwnershipsPagination
  errors?: Record<string, string[]>
}>()

const { t } = useI18n()
const addOwnerOpen = ref(false)
const editOwnerOpen = ref(false)
const editingOwnership = ref<UnitOwnership | null>(null)

const addDrawerErrors = computed(() => {
  if (!props.errors || loadEditDrawerState()?.ownershipId) return undefined
  return props.errors
})

const editDrawerErrors = computed(() => {
  if (!props.errors || !loadEditDrawerState()?.ownershipId) return undefined
  return props.errors
})

const canAddOwner = computed(
  () => toPercentageNumber(props.unit.ownership_stats.available_percentage) > 0,
)

function openAddOwnerDrawer() {
  if (!canAddOwner.value) return
  addOwnerOpen.value = true
}

function openEditDrawer(ownership: UnitOwnership) {
  editingOwnership.value = ownership
  editOwnerOpen.value = true
}

function confirmDelete(ownership: UnitOwnership) {
  const confirmed = window.confirm(
    t('admin.units.show.owners.actions.delete_description', {
      name: ownership.person_display_name,
    }),
  )
  if (!confirmed) return

  router.delete(
    adminResidentialPropertyUnitOwnershipPath(
      props.unit.residential_property_id,
      props.unit.id,
      ownership.id,
    ),
    {
      preserveScroll: true,
      onSuccess: () => {
        toast.success(t('admin.units.show.owners.actions.delete_success'))
      },
      onError: () => {
        toast.error(t('admin.units.show.owners.actions.delete_error'))
      },
    },
  )
}

watch(
  () => props.errors,
  (errors) => {
    if (!isOwnershipDrawerError(errors)) return

    const editState = loadEditDrawerState()
    if (editState?.ownershipId) {
      const ownership = props.ownerships.find((item) => item.id === editState.ownershipId) ?? null
      editingOwnership.value = ownership
      editOwnerOpen.value = true
      return
    }

    if (canAddOwner.value) addOwnerOpen.value = true
  },
  { immediate: true },
)

watch(canAddOwner, (allowed) => {
  if (!allowed) addOwnerOpen.value = false
})

const metricCards = computed(() => {
  const stats = props.unit.ownership_stats

  return [
    {
      key: 'active',
      icon: Users,
      label: t('admin.units.show.owners.metrics.active'),
      value: String(stats.active_owners_count),
      iconClass: 'text-green-600',
      iconWrapperClass: 'bg-green-500/10',
    },
    {
      key: 'assigned',
      icon: Percent,
      label: t('admin.units.show.owners.metrics.assigned'),
      value: formatOwnershipPercentage(stats.assigned_percentage),
      iconClass: 'text-blue-600',
      iconWrapperClass: 'bg-blue-500/10',
    },
    {
      key: 'available',
      icon: Clock,
      label: t('admin.units.show.owners.metrics.available'),
      value: formatOwnershipPercentage(stats.available_percentage),
      iconClass: 'text-amber-600',
      iconWrapperClass: 'bg-amber-500/10',
    },
    {
      key: 'historical',
      icon: History,
      label: t('admin.units.show.owners.metrics.historical'),
      value: String(stats.historical_owners_count),
      iconClass: 'text-purple-600',
      iconWrapperClass: 'bg-purple-500/10',
    },
  ]
})
</script>
