<template>
  <div>
    <Header :items-breadcrumb="itemsBreadcrumb" :title="t('admin.common_areas.index.title')" />

    <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
      <p class="text-muted-foreground max-w-2xl text-sm">{{ t('admin.common_areas.index.description') }}</p>

      <div v-if="activeProperty" class="flex w-full shrink-0 flex-col gap-3 sm:flex-row sm:items-center lg:w-auto">
        <Card class="border-dashed">
          <CardContent class="flex items-center gap-3 p-4">
            <Building2 class="text-muted-foreground size-5" />
            <div>
              <p class="text-muted-foreground text-xs">{{ t('admin.common_areas.index.property') }}</p>
              <NativeSelect v-if="properties.length > 1" v-model="selectedPropertyId" :aria-label="t('admin.common_areas.index.property')">
                <NativeSelectOption v-for="property in properties" :key="property.id" :value="property.id">
                  {{ property.name }}
                </NativeSelectOption>
              </NativeSelect>
              <p v-else class="font-medium">{{ activeProperty.name }}</p>
            </div>
          </CardContent>
        </Card>
        <Button class="gap-2" @click="openForm(null)">
          <Plus class="size-4" />
          {{ t('admin.common_areas.index.new') }}
        </Button>
      </div>
    </div>

    <div v-if="!activeProperty" class="text-muted-foreground rounded-lg border border-dashed px-4 py-10 text-center text-sm">
      {{ t('admin.common_areas.index.no_property') }}
    </div>

    <template v-else>
      <AdminDataTable :columns="columns" :data="common_areas" :empty-message="t('admin.common_areas.index.empty')" />

      <CommonAreaFormDrawer
        v-model:open="formOpen"
        :area="editing"
        :property-id="activeProperty.id"
        :area-types="area_types"
      />
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, h, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { router } from '@inertiajs/vue3'
import { Building2, Pencil, Plus } from 'lucide-vue-next'
import Header from '@/components/admin/layout/Header.vue'
import AdminDataTable from '@/components/admin/table/index.vue'
import CommonAreaFormDrawer from '@/components/admin/common_areas/CommonAreaFormDrawer.vue'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { NativeSelect, NativeSelectOption } from '@/components/ui/native-select'
import { admin_common_areas_path } from '@/routes'
import type { AdminCommonArea } from '@/types/common_area'
import type { BreadcrumbItem } from '@/types/layout'
import type { ColumnDef } from '@/types/table'
import type { AssignedPropertySummary } from '@/types/visit'

const props = defineProps<{
  common_areas: AdminCommonArea[]
  properties: AssignedPropertySummary[]
  active_property?: AssignedPropertySummary | null
  area_types: string[]
}>()

const { t } = useI18n()
const activeProperty = computed(() => props.active_property ?? null)
const formOpen = ref(false)
const editing = ref<AdminCommonArea | null>(null)

const itemsBreadcrumb = computed<BreadcrumbItem[]>(() => [
  { label: t('admin.sidebar.home'), href: '/admin/home/index' },
  { label: t('admin.common_areas.index.title') },
])

const selectedPropertyId = ref(props.active_property?.id ?? '')
watch(
  () => props.active_property?.id,
  (id) => {
    selectedPropertyId.value = id ?? ''
  },
)
watch(selectedPropertyId, (propertyId) => {
  if (!propertyId || propertyId === props.active_property?.id) return
  router.get(admin_common_areas_path(), { property_id: propertyId }, { preserveState: true })
})

function openForm(area: AdminCommonArea | null) {
  editing.value = area
  formOpen.value = true
}

function rulesSummary(area: AdminCommonArea) {
  const rules = area.rules
  const parts: string[] = []
  if (rules.opens_at || rules.closes_at) {
    parts.push(t('admin.common_areas.summary.hours', { opens: rules.opens_at ?? '00:00', closes: rules.closes_at ?? '24:00' }))
  }
  if (rules.max_duration_minutes) parts.push(t('admin.common_areas.summary.duration', { minutes: rules.max_duration_minutes }))
  if (rules.min_advance_hours) parts.push(t('admin.common_areas.summary.advance', { hours: rules.min_advance_hours }))
  if (rules.max_reservations_per_month) parts.push(t('admin.common_areas.summary.monthly', { count: rules.max_reservations_per_month }))
  return parts.join(' · ') || '—'
}

const columns = computed<ColumnDef<AdminCommonArea, unknown>[]>(() => [
  {
    id: 'name',
    header: () => t('admin.common_areas.table.name'),
    cell: ({ row }) =>
      h('div', { class: 'space-y-1' }, [
        h('p', { class: 'font-medium' }, row.original.name),
        h('p', { class: 'text-muted-foreground text-xs' }, t(`admin.common_areas.types.${row.original.area_type}`)),
      ]),
  },
  {
    id: 'capacity',
    header: () => t('admin.common_areas.table.capacity'),
    cell: ({ row }) => h('span', row.original.capacity ?? '—'),
  },
  {
    id: 'approval',
    header: () => t('admin.common_areas.table.approval'),
    cell: ({ row }) =>
      h(Badge, { variant: row.original.requires_approval ? 'secondary' : 'outline' }, () =>
        row.original.requires_approval ? t('admin.common_areas.table.requires_approval') : t('admin.common_areas.table.instant'),
      ),
  },
  {
    id: 'rules',
    header: () => t('admin.common_areas.table.rules'),
    cell: ({ row }) => h('span', { class: 'text-muted-foreground text-sm' }, rulesSummary(row.original)),
  },
  {
    id: 'status',
    header: () => t('admin.common_areas.table.status'),
    cell: ({ row }) =>
      h(Badge, { variant: row.original.status === 'active' ? 'default' : 'outline' }, () =>
        t(`admin.common_areas.status.${row.original.status}`),
      ),
  },
  {
    id: 'upcoming',
    header: () => t('admin.common_areas.table.upcoming'),
    cell: ({ row }) => h('span', { class: 'tabular-nums' }, row.original.upcoming_count),
  },
  {
    id: 'actions',
    header: () => t('common.table.actions'),
    cell: ({ row }) =>
      h(Button, { variant: 'outline', size: 'sm', class: 'gap-2', onClick: () => openForm(row.original) }, () => [
        h(Pencil, { class: 'size-4' }),
        t('admin.common_areas.table.edit'),
      ]),
  },
])
</script>
