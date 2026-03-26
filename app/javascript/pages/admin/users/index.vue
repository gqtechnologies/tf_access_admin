<template>
  <div>
    <Header :itemsBreadcrumb="itemsBreadcrumb" :title="t('admin.users.index.title')" />
    <AdminDataTable :columns="columns" :data="users">
      <template #actions-table>
        <div class="w-full flex items-center justify-between gap-2">
          <div class="w-full md:w-1/2 flex gap-2">
            <Input type="search" :placeholder="t('admin.users.index.input.search.placeholder')" v-model="search" 
            @search="onSearchClear"/>
            <Button variant="outline" @click="triggerSearch">
              <SearchIcon class="w-4 h-4" />
              {{ t('common.actions.search') }}
            </Button>
          </div>
          <Link :href="new_admin_user_path()">
            <Button>
              <PlusIcon class="w-4 h-4" />
              {{ t('admin.users.index.actions.create') }}
            </Button>
          </Link>
        </div>
      </template>
      <template #actions="{ row }">
        <ListItem as="link" :href="`/admin/users/${row.id}/edit`">
          <span class="flex items-center gap-2">
            <PencilIcon class="w-4 h-4" />
          {{ t('common.actions.edit') }}
          </span>
        </ListItem>
        <ListItem as="confirm" :onClick="() => deleteUser(row.id as number)"
          :confirmTitle="t('admin.users.index.actions.delete')"
          :confirmDescription="t('admin.users.index.actions.delete_description', { name: row.name })"
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
import { h, watch, onMounted, computed } from "vue"
import { Link, router } from "@inertiajs/vue3"
import AdminDataTable from "@/components/admin/table/index.vue"
import DataTablePagination from "@/components/admin/table/DataTablePagination.vue"
import { useTable } from "@/lib/composables/useTable"
import { useI18n } from "vue-i18n"
import type { ColumnDef } from "@/types/table"
import { Button } from "@/components/ui/button"
import { PlusIcon, SearchIcon, PencilIcon, TrashIcon } from "lucide-vue-next"
import { Input } from "@/components/ui/input"
import { new_admin_user_path, admin_user_path } from "@/routes"
import ListItem from "@/components/custom/list/ListItem.vue"
import Header from '@/components/admin/layout/Header.vue'
import { User } from "@/types/user"
import { toast } from "vue-sonner"
import { getUsersBreadcrumbs } from '@/lib/breadcrumbs/user'
const { t } = useI18n()

const props = defineProps<{
  users: User[] 
  pagination?: {
    current_page: number
    per_page: number
    total_pages: number
    total_count: number
  }
  errors?: Record<string, string[]>;
}>()

const fetchData = (search: string, page: number, itemsPerPage: number) => {
  router.get("/admin/users", { page, per_page: itemsPerPage, 
    q: { name_or_email_or_dni_cont: search } }, { preserveState: true })
}

const itemsBreadcrumb = computed(() => getUsersBreadcrumbs(t))
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

const columns: ColumnDef<User, any>[] = [
  { accessorKey: "dni", header: () => t("admin.users.index.table.headers.dni") },
  { accessorKey: "name", header: () => t("admin.users.index.table.headers.name") },
  { accessorKey: "email", header: () => t("admin.users.index.table.headers.email") },
  { accessorKey: "role", header: () => t("admin.users.index.table.headers.role"), cell: ({ getValue }) => h("span", getValue() ? t(`roles.${getValue()}`) : t('no_role')) },
]

const deleteUser = (id: number) => {
  router.delete( admin_user_path(id), {
    onSuccess: () => {
      toast.success(t('admin.users.index.actions.delete_success'))
    },
    onError: () => {
      toast.error(t('admin.users.index.actions.delete_error'))
    }
  })
}

const onSearchClear = (e: Event) => {
  const target = e.target as HTMLInputElement
  if (target?.value === '') {
    triggerSearch()
  }
}
</script>
