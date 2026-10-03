<template>
  <div>
    <Header :items-breadcrumb="itemsBreadcrumb" :title="t('admin.incidents.index.title')" />

    <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
      <p class="text-muted-foreground max-w-2xl text-sm">{{ t('admin.incidents.index.description') }}</p>
      <Card v-if="activeProperty" class="border-dashed">
        <CardContent class="flex items-center gap-3 p-4">
          <Building2 class="text-muted-foreground size-5" />
          <div>
            <p class="text-muted-foreground text-xs">{{ t('admin.incidents.index.property') }}</p>
            <NativeSelect v-if="properties.length > 1" v-model="selectedPropertyId" :aria-label="t('admin.incidents.index.property')">
              <NativeSelectOption v-for="property in properties" :key="property.id" :value="property.id">
                {{ property.name }}
              </NativeSelectOption>
            </NativeSelect>
            <p v-else class="font-medium">{{ activeProperty.name }}</p>
          </div>
        </CardContent>
      </Card>
    </div>

    <div v-if="!activeProperty" class="text-muted-foreground rounded-lg border border-dashed px-4 py-10 text-center text-sm">
      {{ t('admin.incidents.index.no_property') }}
    </div>

    <template v-else>
      <div class="mb-4 flex flex-wrap gap-2">
        <Button
          v-for="name in tabs"
          :key="name"
          :variant="tab === name ? 'default' : 'outline'"
          size="sm"
          class="gap-2"
          @click="load({ tab: name, page: 1 })"
        >
          {{ t(`admin.incidents.tabs.${name}`) }}
          <Badge variant="secondary" class="tabular-nums">{{ counters[name] }}</Badge>
        </Button>
      </div>

      <div v-if="errors.length" class="mb-4 rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3">
        <p v-for="error in errors" :key="error" class="text-destructive text-sm">{{ error }}</p>
      </div>

      <AdminDataTable :columns="columns" :data="incidents" :empty-message="t(`admin.incidents.empty.${tab}`)">
        <template v-if="pagination" #footer>
          <DataTablePagination
            :current-page="currentPage"
            :total-pages="totalPages"
            :total-items="totalItems"
            :items-per-page="itemsPerPage"
            :items-per-page-options="itemsPerPageOptions"
            :on-page-change="handlePageChange"
            :on-items-per-page-change="handleItemsPerPageChange"
          />
        </template>
      </AdminDataTable>

      <IncidentDrawer
        v-model:open="drawerOpen"
        :incident="selected"
        :tab="tab"
        :assignees="assignees"
        :priorities="priorities"
      />
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, h, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { router, usePage } from '@inertiajs/vue3'
import { Building2, Pencil } from 'lucide-vue-next'
import Header from '@/components/admin/layout/Header.vue'
import AdminDataTable from '@/components/admin/table/index.vue'
import DataTablePagination from '@/components/admin/table/DataTablePagination.vue'
import IncidentDrawer from '@/components/admin/incidents/IncidentDrawer.vue'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { NativeSelect, NativeSelectOption } from '@/components/ui/native-select'
import { useTable } from '@/lib/composables/useTable'
import { admin_incidents_path } from '@/routes'
import type { AdminIncident, IncidentAssignee, IncidentTab } from '@/types/incident'
import type { BreadcrumbItem } from '@/types/layout'
import type { ColumnDef } from '@/types/table'
import type { AssignedPropertySummary } from '@/types/visit'

const props = defineProps<{
  incidents: AdminIncident[]
  pagination?: { current_page: number; per_page: number; total_pages: number; total_count: number }
  tab: IncidentTab
  counters: Record<IncidentTab, number>
  properties: AssignedPropertySummary[]
  active_property?: AssignedPropertySummary | null
  assignees: IncidentAssignee[]
  categories: string[]
  priorities: string[]
}>()

const { t, locale } = useI18n()
const page = usePage()
const tabs: IncidentTab[] = ['open', 'in_progress', 'closed']
const activeProperty = computed(() => props.active_property ?? null)
const drawerOpen = ref(false)
const selected = ref<AdminIncident | null>(null)

const errors = computed(() => {
  const base = (page.props.errors as Record<string, string | string[]> | undefined)?.base
  if (!base) return []
  return Array.isArray(base) ? base : [base]
})

const itemsBreadcrumb = computed<BreadcrumbItem[]>(() => [
  { label: t('admin.sidebar.home'), href: '/admin/home/index' },
  { label: t('admin.incidents.index.title') },
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
  load({ propertyId, page: 1 })
})

function load({
  tab = props.tab,
  page: pageNumber = 1,
  perPage,
  propertyId = activeProperty.value?.id,
}: {
  tab?: IncidentTab
  page?: number
  perPage?: number
  propertyId?: string
}) {
  router.get(
    admin_incidents_path(),
    { property_id: propertyId, tab, page: pageNumber, per_page: perPage ?? itemsPerPage.value },
    { preserveState: true, preserveScroll: true },
  )
}

const {
  currentPage,
  totalPages,
  totalItems,
  itemsPerPage,
  itemsPerPageOptions,
  handlePageChange,
  handleItemsPerPageChange,
  setPagination,
} = useTable((_search: string, pageNumber: number, perPage: number) => load({ page: pageNumber, perPage }), {
  skipInitialFetch: true,
  initialPagination: props.pagination,
})

watch(
  () => props.pagination,
  (meta) => {
    if (meta) setPagination(meta)
  },
)

function formatDateTime(value: string | null) {
  if (!value) return '—'
  return new Intl.DateTimeFormat(locale.value, { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value))
}

function edit(incident: AdminIncident) {
  selected.value = incident
  drawerOpen.value = true
}

const columns = computed<ColumnDef<AdminIncident, unknown>[]>(() => [
  {
    id: 'incident',
    header: () => t('admin.incidents.table.incident'),
    cell: ({ row }) =>
      h('div', { class: 'max-w-md space-y-1' }, [
        h('div', { class: 'flex flex-wrap items-center gap-1' }, [
          h(Badge, { variant: 'secondary' }, () => t(`admin.incidents.categories.${row.original.category}`)),
          ['high', 'urgent'].includes(row.original.priority)
            ? h(Badge, { variant: 'destructive' }, () => t(`admin.incidents.priorities.${row.original.priority}`))
            : null,
        ]),
        h('p', { class: 'line-clamp-2 text-sm' }, row.original.description),
      ]),
  },
  {
    id: 'place',
    header: () => t('admin.incidents.table.place'),
    cell: ({ row }) => h('span', [row.original.unit, row.original.common_area].filter(Boolean).join(' · ') || '—'),
  },
  {
    id: 'reporter',
    header: () => t('admin.incidents.table.reporter'),
    cell: ({ row }) =>
      h('div', { class: 'space-y-0.5' }, [
        h('p', row.original.reported_by_name ?? '—'),
        h('p', { class: 'text-muted-foreground text-xs' }, formatDateTime(row.original.created_at)),
      ]),
  },
  {
    id: 'assignee',
    header: () => t('admin.incidents.table.assignee'),
    cell: ({ row }) =>
      props.tab === 'closed'
        ? h('div', { class: 'space-y-0.5' }, [
            h(Badge, { variant: 'outline' }, () => t(`admin.incidents.status.${row.original.status}`)),
            h('p', { class: 'text-muted-foreground line-clamp-2 text-xs' }, row.original.resolution ?? ''),
          ])
        : h('span', row.original.assigned_to_name ?? t('admin.incidents.drawer.unassigned')),
  },
  {
    id: 'actions',
    header: () => t('common.table.actions'),
    cell: ({ row }) =>
      h(Button, { variant: 'outline', size: 'sm', class: 'gap-2', onClick: () => edit(row.original) }, () => [
        h(Pencil, { class: 'size-4' }),
        t('admin.incidents.table.manage'),
      ]),
  },
])
</script>
