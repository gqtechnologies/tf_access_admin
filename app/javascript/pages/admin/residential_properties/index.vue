<template>
  <div>
    <Header :itemsBreadcrumb="itemsBreadcrumb" :title="t('admin.residential_properties.index.title')" />
    <AdminDataTable :columns="columns" :data="residential_properties">
      <template #actions-table>
        <div class="w-full flex items-center justify-between gap-2">
          <div class="w-full md:w-1/2 flex gap-2">
            <Input
              type="search"
              :placeholder="t('admin.residential_properties.index.input.search.placeholder')"
              v-model="search"
              @search="onSearchClear"
            />
            <Button variant="outline" @click="triggerSearch">
              <SearchIcon class="w-4 h-4" />
              {{ t('common.actions.search') }}
            </Button>
          </div>
          <Link :href="new_admin_residential_property_path()">
            <Button>
              <PlusIcon class="w-4 h-4" />
              {{ t('admin.residential_properties.index.actions.create') }}
            </Button>
          </Link>
        </div>
      </template>
      <template #actions="{ row }">
        <ListItem as="link" :href="edit_admin_residential_property_path(row.id as string)">
          <span class="flex items-center gap-2">
            <PencilIcon class="w-4 h-4" />
            {{ t('common.actions.edit') }}
          </span>
        </ListItem>
        <ListItem
          as="confirm"
          :onClick="() => deleteProperty(row.id as string)"
          :confirmTitle="t('admin.residential_properties.index.actions.delete')"
          :confirmDescription="
            t('admin.residential_properties.index.actions.delete_description', { name: row.name })
          "
        >
          <span class="flex items-center gap-2">
            <TrashIcon class="w-4 h-4" />
            {{ t('common.actions.delete') }}
          </span>
        </ListItem>
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
  </div>
</template>

<script setup lang="ts">
import { h, watch, onMounted, computed } from 'vue'
import { Link, router } from '@inertiajs/vue3'
import AdminDataTable from '@/components/admin/table/index.vue'
import DataTablePagination from '@/components/admin/table/DataTablePagination.vue'
import { useTable } from '@/lib/composables/useTable'
import { useI18n } from 'vue-i18n'
import type { ColumnDef } from '@/types/table'
import { Button } from '@/components/ui/button'
import { PlusIcon, SearchIcon, PencilIcon, TrashIcon } from 'lucide-vue-next'
import { Input } from '@/components/ui/input'
import {
  new_admin_residential_property_path,
  edit_admin_residential_property_path,
  admin_residential_property_path,
} from '@/routes'
import ListItem from '@/components/custom/list/ListItem.vue'
import Header from '@/components/admin/layout/Header.vue'
import type { ResidentialProperty } from '@/types/residential_property'
import { toast } from 'vue-sonner'
import { getResidentialPropertiesBreadcrumbs } from '@/lib/breadcrumbs/residential_property'

const { t } = useI18n()

const props = defineProps<{
  residential_properties: ResidentialProperty[]
  pagination?: {
    current_page: number
    per_page: number
    total_pages: number
    total_count: number
  }
  errors?: Record<string, string[]>
}>()

const fetchData = (search: string, page: number, itemsPerPage: number) => {
  router.get('/admin/residential_properties', { page, per_page: itemsPerPage, q: { name_or_code_or_city_cont: search } }, { preserveState: true })
}

const itemsBreadcrumb = computed(() => getResidentialPropertiesBreadcrumbs(t))
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
const paginationMeta = props.pagination

watch(
  () => props.pagination,
  (meta) => {
    if (meta) setPagination(meta)
  },
  { immediate: false }
)

onMounted(() => {
  if (props.errors) {
    const firstError = props.errors[0]
    if (firstError) {
      toast.error(firstError)
    }
  }
})

const columns: ColumnDef<ResidentialProperty, unknown>[] = [
  { accessorKey: 'name', header: () => t('admin.residential_properties.index.table.headers.name') },
  { accessorKey: 'code', header: () => t('admin.residential_properties.index.table.headers.code') },
  {
    accessorKey: 'property_type',
    header: () => t('admin.residential_properties.index.table.headers.property_type'),
    cell: ({ row }) =>
      h(
        'span',
        t(`admin.residential_properties.property_types.${row.original.property_type}`)
      ),
  },
  { accessorKey: 'city', header: () => t('admin.residential_properties.index.table.headers.city') },
  {
    accessorKey: 'status',
    header: () => t('admin.residential_properties.index.table.headers.status'),
    cell: ({ row }) => h('span', t(`admin.residential_properties.statuses.${row.original.status}`)),
  },
]

const deleteProperty = (id: string) => {
  router.delete(admin_residential_property_path(id), {
    onSuccess: () => {
      toast.success(t('admin.residential_properties.index.actions.delete_success'))
    },
    onError: () => {
      toast.error(t('admin.residential_properties.index.actions.delete_error'))
    },
  })
}

const onSearchClear = (e: Event) => {
  const target = e.target as HTMLInputElement
  if (target?.value === '') {
    triggerSearch()
  }
}
</script>
