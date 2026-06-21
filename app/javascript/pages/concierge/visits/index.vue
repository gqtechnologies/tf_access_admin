<template>
  <div>
    <Header :items-breadcrumb="itemsBreadcrumb" :title="t('concierge.visits.index.title')" />

    <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
      <p class="text-muted-foreground max-w-2xl text-sm">
        {{ t('concierge.visits.index.description') }}
      </p>
      <Card v-if="assignedProperty" class="w-full shrink-0 border-dashed lg:w-auto">
        <CardContent class="flex items-center gap-3 p-4">
          <Building2 class="text-muted-foreground size-5" />
          <div>
            <p class="text-muted-foreground text-xs">
              {{ t('concierge.visits.index.assigned_property') }}
            </p>
            <p class="font-medium">{{ assignedProperty.name }}</p>
          </div>
        </CardContent>
      </Card>
    </div>

    <div class="mb-4 flex flex-wrap gap-2">
      <Button
        v-for="tab in tabs"
        :key="tab.key"
        :variant="activeTab === tab.key ? 'default' : 'outline'"
        size="sm"
        class="gap-2"
        @click="changeTab(tab.key)"
      >
        {{ tab.label }}
        <Badge variant="secondary" class="tabular-nums">{{ tab.count }}</Badge>
      </Button>
    </div>

    <AdminDataTable :columns="columns" :data="visits">
      <template #actions-table>
        <div class="flex w-full flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div class="flex w-full flex-col gap-2 md:w-2/3 md:flex-row">
            <Input
              type="search"
              v-model="search"
              :placeholder="t('concierge.visits.index.search.placeholder')"
              @search="onSearchClear"
            />
            <Button variant="outline" @click="triggerSearch">
              <Search class="size-4" />
              {{ t('common.actions.search') }}
            </Button>
          </div>
          <Popover v-model:open="filtersOpen">
            <PopoverTrigger as-child>
              <Button variant="outline">
                <SlidersHorizontal class="size-4" />
                {{ t('concierge.visits.index.filters.button') }}
              </Button>
            </PopoverTrigger>
            <PopoverContent class="w-72 space-y-3" align="end">
              <p class="text-sm font-medium">{{ t('concierge.visits.index.filters.title') }}</p>
              <div class="space-y-2">
                <Label for="visit-type-filter">{{ t('concierge.visits.index.filters.visit_type') }}</Label>
                <NativeSelect id="visit-type-filter" v-model="visitTypeFilter" class="w-full">
                  <NativeSelectOption value="">
                    {{ t('concierge.visits.index.filters.all_types') }}
                  </NativeSelectOption>
                  <NativeSelectOption v-for="type in visitTypes" :key="type" :value="type">
                    {{ t(`admin.visits.visit_types.${type}`) }}
                  </NativeSelectOption>
                </NativeSelect>
              </div>
              <div class="flex justify-end gap-2">
                <Button variant="ghost" size="sm" @click="clearFilters">
                  {{ t('concierge.visits.index.filters.clear') }}
                </Button>
                <Button size="sm" @click="applyFilters">
                  {{ t('concierge.visits.index.filters.apply') }}
                </Button>
              </div>
            </PopoverContent>
          </Popover>
        </div>
      </template>

      <template v-if="paginationMeta" #footer>
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

    <VisitCheckInDrawer
      v-model:open="checkInOpen"
      :visit="selectedVisit"
      return-to="list"
      @success="refreshList"
    />
    <VisitCheckOutDrawer
      v-model:open="checkOutOpen"
      :visit="selectedVisit"
      return-to="list"
      @success="refreshList"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, h, onMounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { Building2, Search, SlidersHorizontal } from 'lucide-vue-next'
import Header from '@/components/admin/layout/Header.vue'
import AdminDataTable from '@/components/admin/table/index.vue'
import DataTablePagination from '@/components/admin/table/DataTablePagination.vue'
import VisitStatusBadge from '@/components/concierge/visits/VisitStatusBadge.vue'
import VisitActionsDropdown from '@/components/concierge/visits/VisitActionsDropdown.vue'
import VisitCheckInDrawer from '@/components/concierge/visits/VisitCheckInDrawer.vue'
import VisitCheckOutDrawer from '@/components/concierge/visits/VisitCheckOutDrawer.vue'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { NativeSelect, NativeSelectOption } from '@/components/ui/native-select'
import { useTable } from '@/lib/composables/useTable'
import { useConciergeVisitsList } from '@/lib/composables/concierge/useConciergeVisitsList'
import {
  visitAuthorizedTime,
  visitInitials,
  visitLastMovement,
} from '@/lib/utils/visit'
import type { ColumnDef } from '@/types/table'
import type {
  AssignedPropertySummary,
  ConciergeVisitCounters,
  ConciergeVisitListItem,
  ConciergeVisitTab,
} from '@/types/visit'
import type { BreadcrumbItem } from '@/types/layout'

const VISIT_TYPES = ['guest', 'delivery', 'service', 'other'] as const

const props = defineProps<{
  visits: ConciergeVisitListItem[]
  pagination?: {
    current_page: number
    per_page: number
    total_pages: number
    total_count: number
  }
  tab?: ConciergeVisitTab
  filters?: Record<string, string>
  counters: ConciergeVisitCounters
  assigned_property?: AssignedPropertySummary | null
}>()

const { t, locale } = useI18n()
const filtersOpen = ref(false)
const visitTypes = VISIT_TYPES
const selectedVisit = ref<ConciergeVisitListItem | null>(null)
const checkInOpen = ref(false)
const checkOutOpen = ref(false)

const initialTab = (props.tab ?? 'authorized') as ConciergeVisitTab
const { activeTab, visitTypeFilter, fetchVisits, refreshList } = useConciergeVisitsList(initialTab)

if (props.filters?.visit_type_eq) {
  visitTypeFilter.value = props.filters.visit_type_eq
}

const itemsBreadcrumb = computed<BreadcrumbItem[]>(() => [
  { label: t('admin.sidebar.home'), href: '/admin/home/index' },
  { label: t('concierge.visits.index.title') },
])

const tabs = computed(() => [
  {
    key: 'authorized' as const,
    label: t('concierge.visits.index.tabs.authorized'),
    count: props.counters.authorized,
  },
  {
    key: 'checked_in' as const,
    label: t('concierge.visits.index.tabs.checked_in'),
    count: props.counters.checked_in,
  },
  {
    key: 'recent_checked_out' as const,
    label: t('concierge.visits.index.tabs.recent_checked_out'),
    count: props.counters.recent_checked_out,
  },
])

const assignedProperty = computed(() => props.assigned_property ?? null)

function formatDateTime(value: string | null | undefined) {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value

  return new Intl.DateTimeFormat(locale.value, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(date)
}

function loadList(page: number, itemsPerPage: number) {
  fetchVisits({
    search: search.value,
    page,
    itemsPerPage,
    tab: activeTab.value,
    visitType: visitTypeFilter.value,
  })
}

const fetchData = (searchValue: string, page: number, itemsPerPage: number) => {
  fetchVisits({
    search: searchValue,
    page,
    itemsPerPage,
    tab: activeTab.value,
    visitType: visitTypeFilter.value,
  })
}

const {
  currentPage,
  totalPages,
  totalItems,
  itemsPerPage,
  itemsPerPageOptions,
  search,
  handlePageChange,
  handleItemsPerPageChange,
  setPagination,
  triggerSearch,
} = useTable(fetchData, {
  skipInitialFetch: true,
  initialPagination: props.pagination,
})

const paginationMeta = computed(() => props.pagination)

watch(
  () => props.pagination,
  (meta) => {
    if (meta) setPagination(meta)
  },
  { immediate: false },
)

watch(
  () => props.tab,
  (tab) => {
    if (tab) activeTab.value = tab
  },
)

onMounted(() => {
  const searchKey = 'visitor_person_display_name_or_host_person_display_name_or_unit_identifier_cont'
  if (props.filters?.[searchKey]) {
    search.value = props.filters[searchKey]
  }
})

function changeTab(tab: ConciergeVisitTab) {
  activeTab.value = tab
  loadList(1, itemsPerPage.value)
}

function applyFilters() {
  filtersOpen.value = false
  loadList(1, itemsPerPage.value)
}

function clearFilters() {
  visitTypeFilter.value = ''
  filtersOpen.value = false
  loadList(1, itemsPerPage.value)
}

function onSearchClear(event: Event) {
  const target = event.target as HTMLInputElement
  if (target?.value === '') triggerSearch()
}

function onCheckIn(visit: ConciergeVisitListItem) {
  selectedVisit.value = visit
  checkInOpen.value = true
}

function onCheckOut(visit: ConciergeVisitListItem) {
  selectedVisit.value = visit
  checkOutOpen.value = true
}

const columns = computed<ColumnDef<ConciergeVisitListItem, unknown>[]>(() => [
  {
    id: 'visitor',
    header: () => t('concierge.visits.index.table.headers.visitor'),
    cell: ({ row }) => {
      const visitor = row.original.visitor
      const name = visitor?.display_name ?? '—'
      return h('div', { class: 'flex items-center gap-3' }, [
        h(
          'div',
          {
            class:
              'bg-primary/10 text-primary flex size-9 shrink-0 items-center justify-center rounded-full text-xs font-semibold',
          },
          visitInitials(name),
        ),
        h('span', { class: 'font-medium' }, name),
      ])
    },
  },
  {
    id: 'unit',
    header: () => t('concierge.visits.index.table.headers.unit'),
    cell: ({ row }) => {
      const unit = row.original.unit
      return h('span', unit?.display_name ?? unit?.identifier ?? '—')
    },
  },
  {
    id: 'host',
    header: () => t('concierge.visits.index.table.headers.host'),
    cell: ({ row }) => h('span', row.original.host?.display_name ?? '—'),
  },
  {
    id: 'status',
    header: () => t('concierge.visits.index.table.headers.status'),
    cell: ({ row }) =>
      h(VisitStatusBadge, {
        status: row.original.status,
        label: row.original.status_label,
      }),
  },
  {
    id: 'authorized_time',
    header: () => t('concierge.visits.index.table.headers.authorized_time'),
    cell: ({ row }) => h('span', formatDateTime(visitAuthorizedTime(row.original))),
  },
  {
    id: 'last_movement',
    header: () => t('concierge.visits.index.table.headers.last_movement'),
    cell: ({ row }) => {
      const movement = visitLastMovement(row.original)
      if (!movement.at || !movement.kind) return h('span', '—')

      return h('div', { class: 'flex flex-col gap-0.5' }, [
        h('span', { class: 'text-sm' }, formatDateTime(movement.at)),
        h(
          'span',
          { class: 'text-muted-foreground text-xs' },
          t(`concierge.visits.index.movements.${movement.kind}`),
        ),
      ])
    },
  },
  {
    id: 'actions',
    header: () => t('common.table.actions'),
    cell: ({ row }) =>
      h(VisitActionsDropdown, {
        visit: row.original,
        onCheckIn: onCheckIn,
        onCheckOut: onCheckOut,
      }),
  },
])
</script>
