<template>
  <div class="space-y-6 w-full">
    <PanelHeader
      :title="t('admin.units.show.owners.title')"
      :description="t('admin.units.show.owners.description')"
    >
      <template #actions>
        <Button @click="addOwnerOpen = true">
          <Plus class="size-4" />
          {{ t('admin.units.show.owners.add_owner.title') }}
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

    <UnitOwnersTable
      :ownerships="ownerships"
      :residential-property-id="unit.residential_property_id"
      :unit-id="unit.id"
      :ownerships-pagination="ownershipsPagination"
    />

    <UnitAddOwnerDrawer v-model:open="addOwnerOpen" :unit="unit" />
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { Clock, History, Percent, Plus, Users } from 'lucide-vue-next'
import MetricCard from '@/components/admin/shared/MetricCard.vue'
import PanelHeader from '@/components/admin/shared/PanelHeader.vue'
import UnitAddOwnerDrawer from '@/components/admin/unit/add_owner/UnitAddOwnerDrawer.vue'
import UnitOwnersTable from '@/components/admin/unit/UnitOwnersTable.vue'
import { Button } from '@/components/ui/button'
import { formatOwnershipPercentage } from '@/lib/utils/unit'
import type { UnitDetail, UnitOwnership, UnitOwnershipsPagination } from '@/types/unit'

const props = defineProps<{
  unit: UnitDetail
  ownerships: UnitOwnership[]
  ownershipsPagination?: UnitOwnershipsPagination
}>()

const { t } = useI18n()
const addOwnerOpen = ref(false)

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
