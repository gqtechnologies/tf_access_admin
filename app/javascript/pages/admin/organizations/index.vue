<template>
  <div>
    <Header :itemsBreadcrumb="itemsBreadcrumb" :title="t('admin.organizations.index.title')" />
    <AdminDataTable :columns="columns" :data="organizations">
      <template #actions-table>
        <div class="w-full flex items-center justify-between gap-2">
          <div class="w-full md:w-1/2 flex gap-2">
            <Input type="search" :placeholder="t('admin.organizations.index.input.search.placeholder')" v-model="search" 
            @search="onSearchClear"/>
            <Button variant="outline" @click="triggerSearch">
              <SearchIcon class="w-4 h-4" />
              {{ t('common.actions.search') }}
            </Button>
          </div>
          <Link :href="`#`">
            <Button>
              <PlusIcon class="w-4 h-4" />
              {{ t('admin.organizations.index.actions.create') }}
            </Button>
          </Link>
        </div>
      </template>
      <template #actions="{ row }">
        <ListItem as="link" :href="`/admin/organizations/${row.id}/edit`">
          <span class="flex items-center gap-2">
            <PencilIcon class="w-4 h-4" />
          {{ t('common.actions.edit') }}
          </span>
        </ListItem>
        <ListItem as="confirm" :onClick="() => deleteOrganization(row.id as number)"
          :confirmTitle="t('admin.organizations.index.actions.delete')"
          :confirmDescription="t('admin.organizations.index.actions.delete_description', { name: row.name })"
          >
          <span class="flex items-center gap-2">
            <TrashIcon class="w-4 h-4" />
          {{ t('common.actions.delete') }}
          </span>
        </ListItem>
      </template>
      <template v-if="paginationMeta" #footer>
        <DataTablePagination :current-page="currentPage" :total-pages="totalPages" :total-items="totalItems"
          :items-per-page="itemsPerPage" :items-per-page-options="itemsPerPageOptions"
          :on-page-change="handlePageChange" :on-items-per-page-change="handleItemsPerPageChange" />
      </template>
    </AdminDataTable>
  </div>
</template>

<script setup lang="ts">
import { watch, computed } from "vue"
import { Link, router } from "@inertiajs/vue3"
import AdminDataTable from "@/components/admin/table/index.vue"
import DataTablePagination from "@/components/admin/table/DataTablePagination.vue"
import { useTable } from "@/lib/composables/useTable"
import { useI18n } from "vue-i18n"
import type { ColumnDef } from "@/types/table"
import { Button } from "@/components/ui/button"
import { PlusIcon, SearchIcon, PencilIcon, TrashIcon } from "lucide-vue-next"
import { Input } from "@/components/ui/input"
import ListItem from "@/components/custom/list/ListItem.vue"
import Header from '@/components/admin/layout/Header.vue'
import { getOrganizationsBreadcrumbs } from '@/lib/breadcrumbs/organization'
import type { Organization } from '@/types/organization'
const { t } = useI18n()

const props = defineProps<{
  organizations: Organization[] 
  pagination?: {
    current_page: number
    per_page: number
    total_pages: number
    total_count: number
  }
  errors?: Record<string, string[]>;
}>()
const fetchData = (search: string, page: number, itemsPerPage: number) => {
  router.get("/admin/organizations", { page, per_page: itemsPerPage, 
    q: { name_cont: search } }, { preserveState: true })
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
const itemsBreadcrumb = computed(() => getOrganizationsBreadcrumbs(t))
const paginationMeta = props.pagination

watch(
  () => props.pagination,
  (meta) => {
    if (meta) setPagination(meta)
  },
  { immediate: false }
)


const columns: ColumnDef<Organization, any>[] = [
  { accessorKey: "subdomain", header: () => t("admin.organizations.index.table.headers.subdomain") },
  { accessorKey: "name", header: () => t("admin.organizations.index.table.headers.name") },
]

const deleteOrganization = (id: number) => {
  console.log("delete organization", id)
}

const onSearchClear = (e: Event) => {
  const target = e.target as HTMLInputElement
  if (target?.value === '') {
    triggerSearch()
  }
}
</script>