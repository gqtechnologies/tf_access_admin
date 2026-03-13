<template>
  <div>
    <h1 class="mb-4 text-2xl font-semibold">{{ t('users.index.title') }}</h1>
    <AdminDataTable :columns="columns" :data="users">
      <template #actions-table>
        <div class="flex items-center gap-2">
          <div class="w-full flex gap-2">
            <Button variant="outline">
              <SearchIcon class="w-4 h-4" />
              {{ t('common.actions.search') }}
            </Button>
          </div>
          <Button>
            <PlusIcon class="w-4 h-4" />
            {{ t('users.index.actions.create') }}
          </Button>
        </div>
      </template>
      <template #actions="{ row }">
        <div class="flex flex-col items-center gap-2">
          <Link :href="`/admin/users/${row.id}/edit`" class="text-primary hover:underline text-sm font-medium">
            {{ t('common.actions.edit') }}
          </Link>
          <Link :href="`/admin/users/${row.id}/edit`" class="text-primary hover:underline text-sm font-medium">
            {{ t('common.actions.edit') }}
          </Link>
        </div>
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
import { h, watch } from "vue"
import { Link, router } from "@inertiajs/vue3"
import AdminDataTable from "@/components/admin/table/index.vue"
import DataTablePagination from "@/components/admin/table/DataTablePagination.vue"
import { useTable } from "@/lib/composables/useTable"
import { useI18n } from "vue-i18n"
import type { ColumnDef } from "@/types/table"
import { Button } from "@/components/ui/button"
import { PlusIcon, SearchIcon } from "lucide-vue-next"

const { t } = useI18n()

interface User {
  id: string | number
  name: string
  dni: string
  email: string
}

const props = defineProps<{
  users: User[]
  pagination?: {
    current_page: number
    per_page: number
    total_pages: number
    total_count: number
  }
}>()

const fetchData = (search: string, page: number, itemsPerPage: number) => {
  router.get("/admin/users", { page, per_page: itemsPerPage, search }, { preserveState: true })
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

const columns: ColumnDef<User, any>[] = [
  {
    accessorKey: "id",
    header: () => h('span', { class: 'block text-center' }, t("users.index.table.headers.id")),
    cell: ({ getValue }) => h("span", { class: "block text-center" }, getValue())
  },
  { accessorKey: "name", header: () => t("users.index.table.headers.name") },
  { accessorKey: "dni", header: () => t("users.index.table.headers.dni") },
  { accessorKey: "email", header: () => t("users.index.table.headers.email") },
]
</script>
