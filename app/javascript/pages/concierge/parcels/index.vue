<template>
  <div>
    <Header :items-breadcrumb="itemsBreadcrumb" :title="t('concierge.parcels.index.title')" />

    <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
      <p class="text-muted-foreground max-w-2xl text-sm">
        {{ t('concierge.parcels.index.description') }}
      </p>

      <div v-if="activeProperty" class="flex w-full shrink-0 flex-col gap-3 sm:flex-row sm:items-center lg:w-auto">
        <Card class="border-dashed">
          <CardContent class="flex items-center gap-3 p-4">
            <Building2 class="text-muted-foreground size-5" />
            <div>
              <p class="text-muted-foreground text-xs">
                {{ t('concierge.parcels.index.property') }}
              </p>
              <NativeSelect
                v-if="properties.length > 1"
                v-model="selectedPropertyId"
                :aria-label="t('concierge.parcels.index.property')"
              >
                <NativeSelectOption v-for="property in properties" :key="property.id" :value="property.id">
                  {{ property.name }}
                </NativeSelectOption>
              </NativeSelect>
              <p v-else class="font-medium">{{ activeProperty.name }}</p>
            </div>
          </CardContent>
        </Card>

        <Button class="gap-2" @click="receiveOpen = true">
          <Plus class="size-4" />
          {{ t('concierge.parcels.index.register') }}
        </Button>
      </div>
    </div>

    <div
      v-if="!activeProperty"
      class="text-muted-foreground rounded-lg border border-dashed px-4 py-10 text-center text-sm"
    >
      {{ t('concierge.parcels.index.no_property') }}
    </div>

    <template v-else>
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

      <AdminDataTable :columns="columns" :data="parcels" :empty-message="emptyStateMessage">
        <template #actions-table>
          <div class="flex w-full flex-col gap-2 md:flex-row">
            <Input
              type="search"
              v-model="search"
              :placeholder="t('concierge.parcels.index.search.placeholder')"
              @search="onSearchClear"
            />
            <Button variant="outline" @click="triggerSearch">
              <Search class="size-4" />
              {{ t('common.actions.search') }}
            </Button>
          </div>
        </template>
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

      <ParcelReceiveDrawer
        v-model:open="receiveOpen"
        :property-id="activeProperty.id"
        :tab="activeTab"
        :units="units"
        :delivery-types="delivery_types"
      />
      <ParcelWithdrawDrawer v-model:open="withdrawOpen" :parcel="selectedParcel" :tab="activeTab" />
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, h, onMounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { Building2, PackageCheck, Plus, Search } from 'lucide-vue-next'
import Header from '@/components/admin/layout/Header.vue'
import AdminDataTable from '@/components/admin/table/index.vue'
import DataTablePagination from '@/components/admin/table/DataTablePagination.vue'
import ParcelReceiveDrawer from '@/components/concierge/parcels/ParcelReceiveDrawer.vue'
import ParcelWithdrawDrawer from '@/components/concierge/parcels/ParcelWithdrawDrawer.vue'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { NativeSelect, NativeSelectOption } from '@/components/ui/native-select'
import { useTable } from '@/lib/composables/useTable'
import { useConciergeParcelsList } from '@/lib/composables/concierge/useConciergeParcels'
import type { ColumnDef } from '@/types/table'
import type { BreadcrumbItem } from '@/types/layout'
import type { ConciergeParcel, ParcelCounters, ParcelTab, ParcelUnitOption } from '@/types/parcel'
import type { AssignedPropertySummary } from '@/types/visit'

const props = defineProps<{
  parcels: ConciergeParcel[]
  pagination?: {
    current_page: number
    per_page: number
    total_pages: number
    total_count: number
  }
  tab?: ParcelTab
  query?: string | null
  counters: ParcelCounters
  properties: AssignedPropertySummary[]
  active_property?: AssignedPropertySummary | null
  units: ParcelUnitOption[]
  delivery_types: string[]
}>()

const { t, locale } = useI18n()
const selectedParcel = ref<ConciergeParcel | null>(null)
const receiveOpen = ref(false)
const withdrawOpen = ref(false)

const { activeTab, fetchParcels } = useConciergeParcelsList(props.tab ?? 'received')

const itemsBreadcrumb = computed<BreadcrumbItem[]>(() => [
  { label: t('admin.sidebar.home'), href: '/admin/home/index' },
  { label: t('concierge.parcels.index.title') },
])

const activeProperty = computed(() => props.active_property ?? null)
// Bound to the property select; follows the server's active property and
// triggers a reload when the user picks another one.
const selectedPropertyId = ref(props.active_property?.id ?? '')

const tabs = computed(() => [
  {
    key: 'received' as const,
    label: t('concierge.parcels.index.tabs.received'),
    count: props.counters.received,
  },
  {
    key: 'withdrawn' as const,
    label: t('concierge.parcels.index.tabs.withdrawn'),
    count: props.counters.withdrawn,
  },
])

const emptyStateMessage = computed(() => {
  if (props.query?.trim()) return t('concierge.parcels.index.empty.search')

  return t(`concierge.parcels.index.empty.${activeTab.value}`)
})

function formatDateTime(value: string | null | undefined) {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value

  return new Intl.DateTimeFormat(locale.value, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(date)
}

const fetchData = (searchValue: string, page: number, perPage: number) => {
  fetchParcels({
    search: searchValue,
    page,
    itemsPerPage: perPage,
    tab: activeTab.value,
    propertyId: activeProperty.value?.id,
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

watch(
  () => props.pagination,
  (meta) => {
    if (meta) setPagination(meta)
  },
)

watch(
  () => props.tab,
  (tab) => {
    if (tab) activeTab.value = tab
  },
)

onMounted(() => {
  if (props.query) search.value = props.query
})

function changeTab(tab: ParcelTab) {
  activeTab.value = tab
  fetchData(search.value, 1, itemsPerPage.value)
}

watch(
  () => props.active_property?.id,
  (id) => {
    selectedPropertyId.value = id ?? ''
  },
)

// Another property means other parcels and units: start from its first page
// with the search cleared.
watch(selectedPropertyId, (propertyId) => {
  if (!propertyId || propertyId === props.active_property?.id) return

  search.value = ''
  fetchParcels({
    search: '',
    page: 1,
    itemsPerPage: itemsPerPage.value,
    tab: activeTab.value,
    propertyId,
  })
})

function onSearchClear(event: Event) {
  const target = event.target as HTMLInputElement
  if (target?.value === '') triggerSearch()
}

function onWithdraw(parcel: ConciergeParcel) {
  selectedParcel.value = parcel
  withdrawOpen.value = true
}

const columns = computed<ColumnDef<ConciergeParcel, unknown>[]>(() => {
  const baseColumns: ColumnDef<ConciergeParcel, unknown>[] = [
    {
      id: 'unit',
      header: () => t('concierge.parcels.index.table.unit'),
      cell: ({ row }) => h('span', { class: 'font-medium' }, row.original.unit.name),
    },
    {
      id: 'delivery_type',
      header: () => t('concierge.parcels.index.table.delivery_type'),
      cell: ({ row }) =>
        h(Badge, { variant: 'secondary' }, () =>
          t(`concierge.parcels.delivery_types.${row.original.delivery_type}`),
        ),
    },
    {
      id: 'courier',
      header: () => t('concierge.parcels.index.table.courier'),
      cell: ({ row }) =>
        h(
          'span',
          [row.original.courier_company, row.original.tracking_code].filter(Boolean).join(' · ') ||
            '—',
        ),
    },
    {
      id: 'received_at',
      header: () => t('concierge.parcels.index.table.received_at'),
      cell: ({ row }) => h('span', formatDateTime(row.original.received_at)),
    },
    {
      id: 'notes',
      header: () => t('concierge.parcels.index.table.notes'),
      cell: ({ row }) => h('span', { class: 'text-muted-foreground' }, row.original.notes ?? '—'),
    },
  ]

  if (activeTab.value === 'withdrawn') {
    baseColumns.push({
      id: 'withdrawn',
      header: () => t('concierge.parcels.index.table.withdrawn'),
      cell: ({ row }) =>
        h('div', { class: 'space-y-0.5' }, [
          h('p', { class: 'text-sm font-medium' }, row.original.withdrawn_by_name ?? '—'),
          h(
            'p',
            { class: 'text-muted-foreground text-xs' },
            formatDateTime(row.original.withdrawn_at),
          ),
        ]),
    })
  } else {
    baseColumns.push({
      id: 'actions',
      header: () => t('common.table.actions'),
      cell: ({ row }) =>
        h(
          Button,
          {
            variant: 'outline',
            size: 'sm',
            class: 'gap-2',
            onClick: () => onWithdraw(row.original),
          },
          () => [
            h(PackageCheck, { class: 'size-4' }),
            t('concierge.parcels.index.table.withdraw'),
          ],
        ),
    })
  }

  return baseColumns
})
</script>
