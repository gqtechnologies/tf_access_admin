<template>
  <div class="flex flex-wrap items-center gap-3">
    <MetricCard
      v-for="card in cards"
      :key="card.key"
      :icon="card.icon"
      :label="card.label"
      :value="card.value"
      :icon-class="card.iconClass"
      :icon-wrapper-class="card.iconWrapperClass"
    />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { ChartPie, Home, Ruler, Users } from 'lucide-vue-next'
import MetricCard from '@/components/admin/shared/MetricCard.vue'
import { formatOwnershipPercentage } from '@/lib/utils/unit'
import type { UnitDetail } from '@/types/unit'

const props = defineProps<{
  unit: UnitDetail
}>()

const { t } = useI18n()

const cards = computed(() => {
  const stats = props.unit.ownership_stats
  const area =
    props.unit.area_m2 != null
      ? t('admin.units.show.summary.area_value', { value: Number(props.unit.area_m2) })
      : '—'

  return [
    {
      key: 'type',
      icon: Home,
      label: t('admin.units.show.summary.type'),
      value: t(`admin.residential_properties.structure.bulk_import.preview.unit_types.${props.unit.unit_type}`),
      iconClass: 'text-primary',
      iconWrapperClass: 'bg-primary/10',
    },
    {
      key: 'area',
      icon: Ruler,
      label: t('admin.units.show.summary.area'),
      value: area,
      iconClass: 'text-blue-600',
      iconWrapperClass: 'bg-blue-500/10',
    },
    {
      key: 'owners',
      icon: Users,
      label: t('admin.units.show.summary.owners'),
      value: t('admin.units.show.summary.owners_value', { count: stats.active_owners_count }),
      iconClass: 'text-green-600',
      iconWrapperClass: 'bg-green-500/10',
    },
    {
      key: 'assigned',
      icon: ChartPie,
      label: t('admin.units.show.summary.assigned_percentage'),
      value: formatOwnershipPercentage(stats.assigned_percentage),
      iconClass: 'text-amber-600',
      iconWrapperClass: 'bg-amber-500/10',
    },
  ]
})
</script>
