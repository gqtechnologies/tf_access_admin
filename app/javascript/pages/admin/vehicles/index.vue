<template>
  <div>
    <Header :items-breadcrumb="itemsBreadcrumb" :title="t('admin.vehicles.index.title')" />

    <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
      <p class="text-muted-foreground max-w-2xl text-sm">{{ t('admin.vehicles.index.description') }}</p>
      <Card v-if="activeProperty" class="border-dashed">
        <CardContent class="flex items-center gap-3 p-4">
          <Building2 class="text-muted-foreground size-5" />
          <div>
            <p class="text-muted-foreground text-xs">{{ t('admin.vehicles.index.property') }}</p>
            <NativeSelect v-if="properties.length > 1" v-model="selectedPropertyId" :aria-label="t('admin.vehicles.index.property')">
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
      {{ t('admin.vehicles.index.no_property') }}
    </div>

    <template v-else>
      <AdminDataTable :columns="columns" :data="vehicles" :empty-message="query ? t('admin.vehicles.index.no_match') : t('admin.vehicles.index.empty')">
        <template #actions-table>
          <div class="flex w-full flex-col gap-2 md:flex-row">
            <Input type="search" v-model="search" :placeholder="t('admin.vehicles.index.search')" @search="onSearchClear" />
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

      <AlertDialog :open="removing !== null" @update:open="(value: boolean) => { if (!value) removing = null }">
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>{{ t('admin.vehicles.remove.title') }}</AlertDialogTitle>
            <AlertDialogDescription>{{ t('admin.vehicles.remove.body', { plate: removing?.plate_number ?? '' }) }}</AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>{{ t('common.actions.cancel') }}</AlertDialogCancel>
            <AlertDialogAction @click="remove">{{ t('admin.vehicles.remove.confirm') }}</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, h, onMounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { router } from '@inertiajs/vue3'
import { Building2, Search, Trash2 } from 'lucide-vue-next'
import { toast } from 'vue-sonner'
import Header from '@/components/admin/layout/Header.vue'
import AdminDataTable from '@/components/admin/table/index.vue'
import DataTablePagination from '@/components/admin/table/DataTablePagination.vue'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { NativeSelect, NativeSelectOption } from '@/components/ui/native-select'
import { useTable } from '@/lib/composables/useTable'
import { admin_vehicle_path, admin_vehicles_path } from '@/routes'
import type { BreadcrumbItem } from '@/types/layout'
import type { ColumnDef } from '@/types/table'
import type { AssignedPropertySummary } from '@/types/visit'

type VehicleRow = {
  id: string
  plate_number: string
  vehicle_type: string | null
  brand: string | null
  model: string | null
  color: string | null
  unit: string | null
  owner_name: string | null
  created_at: string
}

const props = defineProps<{
  vehicles: VehicleRow[]
  pagination?: { current_page: number; per_page: number; total_pages: number; total_count: number }
  query?: string | null
  properties: AssignedPropertySummary[]
  active_property?: AssignedPropertySummary | null
}>()

const { t } = useI18n()
const activeProperty = computed(() => props.active_property ?? null)
const removing = ref<VehicleRow | null>(null)

const itemsBreadcrumb = computed<BreadcrumbItem[]>(() => [
  { label: t('admin.sidebar.home'), href: '/admin/home/index' },
  { label: t('admin.vehicles.index.title') },
])

function load(searchValue: string, pageNumber: number, perPage: number, propertyId = activeProperty.value?.id) {
  const params: Record<string, unknown> = { property_id: propertyId, page: pageNumber, per_page: perPage }
  if (searchValue.trim()) params.q = { query: searchValue.trim() }
  router.get(admin_vehicles_path(), params as never, { preserveState: true, preserveScroll: true })
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
} = useTable(load, { skipInitialFetch: true, initialPagination: props.pagination })

watch(
  () => props.pagination,
  (meta) => {
    if (meta) setPagination(meta)
  },
)

onMounted(() => {
  if (props.query) search.value = props.query
})

const selectedPropertyId = ref(props.active_property?.id ?? '')
watch(
  () => props.active_property?.id,
  (id) => {
    selectedPropertyId.value = id ?? ''
  },
)
watch(selectedPropertyId, (propertyId) => {
  if (!propertyId || propertyId === props.active_property?.id) return
  search.value = ''
  load('', 1, itemsPerPage.value, propertyId)
})

function onSearchClear(event: Event) {
  const target = event.target as HTMLInputElement
  if (target?.value === '') triggerSearch()
}

function remove() {
  const vehicle = removing.value
  if (!vehicle) return

  router.delete(admin_vehicle_path(vehicle.id), {
    preserveScroll: true,
    onSuccess: () => toast.success(t('admin.vehicles.remove.done')),
    onFinish: () => {
      removing.value = null
    },
  })
}

const columns = computed<ColumnDef<VehicleRow, unknown>[]>(() => [
  {
    id: 'plate',
    header: () => t('admin.vehicles.table.plate'),
    cell: ({ row }) => h('span', { class: 'font-mono font-semibold tracking-wider' }, row.original.plate_number),
  },
  {
    id: 'vehicle',
    header: () => t('admin.vehicles.table.vehicle'),
    cell: ({ row }) =>
      h('span', [
        row.original.vehicle_type ? t(`admin.vehicles.types.${row.original.vehicle_type}`) : null,
        row.original.brand,
        row.original.model,
        row.original.color,
      ].filter(Boolean).join(' · ') || '—'),
  },
  {
    id: 'unit',
    header: () => t('admin.vehicles.table.unit'),
    cell: ({ row }) =>
      h('div', { class: 'space-y-0.5' }, [
        h('p', row.original.unit ?? '—'),
        h('p', { class: 'text-muted-foreground text-xs' }, row.original.owner_name ?? ''),
      ]),
  },
  {
    id: 'actions',
    header: () => t('common.table.actions'),
    cell: ({ row }) =>
      h(Button, { variant: 'outline', size: 'sm', class: 'gap-2', onClick: () => (removing.value = row.original) }, () => [
        h(Trash2, { class: 'size-4' }),
        t('admin.vehicles.remove.confirm'),
      ]),
  },
])
</script>
