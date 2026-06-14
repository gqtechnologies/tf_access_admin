<template>
  <div class="space-y-6">
    <Breadcrumb :items="itemsBreadcrumb" />
    <Card class="w-full">
      <CardContent>
        <UnitPageHeader :unit="props.unit" />
      </CardContent>
    </Card>
    <TabNav v-model="activeTab" :tabs="tabs" :aria-label="t('admin.units.show.tabs.aria_label')" />
    <div class="w-full flex flex-col gap-4">
      <div class="w-full">
        <UnitOwnersPanel
          v-if="activeTab === 'owners'"
          :unit="props.unit"
          :ownerships="props.ownerships"
          :ownerships-pagination="props.ownerships_pagination"
          :errors="props.errors"
        />
        <UnitPlaceholderTab
          v-else
          :title="placeholderTitle"
          :description="t('admin.units.show.tabs.coming_soon')"
        />
      </div>

      <div class="w-full flex justify-center items-center">
        <UnitChangeHistorySidebar :entries="props.change_history" />
      </div>
    </div>
   
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import {
  Car,
  ClipboardList,
  FileText,
  History,
  LayoutGrid,
  UserRound,
  Users,
} from 'lucide-vue-next'
import Breadcrumb from '@/components/admin/layout/Breadcrumb.vue'
import TabNav, { type TabNavItem } from '@/components/admin/shared/TabNav.vue'
import UnitChangeHistorySidebar from '@/components/admin/unit/UnitChangeHistorySidebar.vue'
import UnitOwnersPanel from '@/components/admin/unit/UnitOwnersPanel.vue'
import UnitPageHeader from '@/components/admin/unit/UnitPageHeader.vue'
import UnitPlaceholderTab from '@/components/admin/unit/UnitPlaceholderTab.vue'
import { getUnitShowBreadcrumbs } from '@/lib/breadcrumbs/unit'
import type {
  UnitChangeHistoryEntry,
  UnitDetail,
  UnitOwnership,
  UnitOwnershipsPagination,
} from '@/types/unit'
import { Card, CardContent } from '@/components/ui/card'

const props = defineProps<{
  unit: UnitDetail
  ownerships: UnitOwnership[]
  ownerships_pagination?: UnitOwnershipsPagination
  change_history: UnitChangeHistoryEntry[]
  errors?: Record<string, string[]>
}>()

const { t } = useI18n()
const activeTab = ref('owners')

const itemsBreadcrumb = computed(() =>
  getUnitShowBreadcrumbs(
    t,
    props.unit.residential_property_id,
    props.unit.residential_property_name,
    props.unit.location_path,
    props.unit.title
  )
)

const tabs = computed<TabNavItem[]>(() => [
  { id: 'summary', label: t('admin.units.show.tabs.summary'), icon: LayoutGrid },
  { id: 'owners', label: t('admin.units.show.tabs.owners'), icon: Users },
  { id: 'residents', label: t('admin.units.show.tabs.residents'), icon: UserRound },
  { id: 'vehicles', label: t('admin.units.show.tabs.vehicles'), icon: Car },
  { id: 'visits', label: t('admin.units.show.tabs.visits'), icon: ClipboardList },
  { id: 'documents', label: t('admin.units.show.tabs.documents'), icon: FileText },
  { id: 'history', label: t('admin.units.show.tabs.history'), icon: History },
])

const placeholderTitle = computed(() => {
  const tab = tabs.value.find((item) => item.id === activeTab.value)
  return tab?.label ?? ''
})
</script>
