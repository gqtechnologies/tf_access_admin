<template>
  <div>
    <Header :itemsBreadcrumb="itemsBreadcrumb" :title="t('admin.people.index.title')" />
    <AdminDataTable :columns="columns" :data="people">
      <template #actions-table>
        <div class="w-full flex items-center justify-between gap-2">
          <div class="w-full md:w-1/2 flex gap-2">
            <Input
              type="search"
              :placeholder="t('admin.people.index.input.search.placeholder')"
              v-model="search"
              @search="onSearchClear"
            />
            <Button variant="outline" @click="triggerSearch">
              <SearchIcon class="w-4 h-4" />
              {{ t('common.actions.search') }}
            </Button>
          </div>
          <Link :href="new_admin_person_path()">
            <Button>
              <PlusIcon class="w-4 h-4" />
              {{ t('admin.people.index.actions.create') }}
            </Button>
          </Link>
        </div>
      </template>
      <template #actions="{ row }">
        <ListItem as="link" :href="admin_person_path(row.id as string)">
          <span class="flex items-center gap-2">
            <EyeIcon class="w-4 h-4" />
            {{ t('admin.people.index.actions.view_profile') }}
          </span>
        </ListItem>
        <ListItem as="link" :href="edit_admin_person_path(row.id as string)">
          <span class="flex items-center gap-2">
            <PencilIcon class="w-4 h-4" />
            {{ t('common.actions.edit') }}
          </span>
        </ListItem>
        <ListItem
          as="confirm"
          :onClick="() => deletePerson(row.id as string)"
          :confirmTitle="t('admin.people.index.actions.delete')"
          :confirmDescription="
            t('admin.people.index.actions.delete_description', { name: row.display_name })
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
import { PlusIcon, SearchIcon, PencilIcon, TrashIcon, EyeIcon } from 'lucide-vue-next'
import { Input } from '@/components/ui/input'
import { new_admin_person_path, admin_person_path, edit_admin_person_path } from '@/routes'
import ListItem from '@/components/custom/list/ListItem.vue'
import Header from '@/components/admin/layout/Header.vue'
import PersonContextualRoleBadges from '@/components/admin/person/PersonContextualRoleBadges.vue'
import type { Person } from '@/types/person'
import { toast } from 'vue-sonner'
import { getPeopleBreadcrumbs } from '@/lib/breadcrumbs/person'

const { t } = useI18n()

const props = defineProps<{
  people: Person[]
  pagination?: {
    current_page: number
    per_page: number
    total_pages: number
    total_count: number
  }
  errors?: Record<string, string[]>
}>()

const fetchData = (search: string, page: number, itemsPerPage: number) => {
  router.get(
    '/admin/people',
    { page, per_page: itemsPerPage, q: { display_name_or_first_name_or_last_name_cont: search } },
    { preserveState: true }
  )
}

const itemsBreadcrumb = computed(() => getPeopleBreadcrumbs(t))
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
    if (firstError) toast.error(firstError)
  }
})

const columns: ColumnDef<Person, unknown>[] = [
  {
    accessorKey: 'display_name',
    header: () => t('admin.people.index.table.headers.display_name'),
    cell: ({ row }) => {
      const person = row.original
      if (!person.id) return h('span', person.display_name)

      return h(
        Link,
        {
          href: admin_person_path(person.id),
          class: 'font-medium text-primary hover:underline',
        },
        () => person.display_name,
      )
    },
  },
  {
    accessorKey: 'contextual_roles',
    header: () => t('admin.people.index.table.headers.contextual_roles'),
    cell: ({ row }) =>
      h(PersonContextualRoleBadges, {
        roles: row.original.contextual_roles ?? [],
      }),
  },
  {
    accessorKey: 'document_number',
    header: () => t('admin.people.index.table.headers.document_number'),
    cell: ({ getValue }) => h('span', (getValue() as string) || '—'),
  },
  {
    accessorKey: 'email',
    header: () => t('admin.people.index.table.headers.email'),
    cell: ({ getValue }) => h('span', (getValue() as string) || '—'),
  },
  {
    accessorKey: 'status',
    header: () => t('admin.people.index.table.headers.status'),
    cell: ({ getValue }) => h('span', t(`admin.people.statuses.${getValue()}`)),
  },
  {
    accessorKey: 'unit_ownerships_count',
    header: () => t('admin.people.index.table.headers.unit_ownerships_count'),
    cell: ({ getValue }) => h('span', (getValue() as number).toString()),
  },
]

const deletePerson = (id: string) => {
  router.delete(admin_person_path(id), {
    onSuccess: () => toast.success(t('admin.people.index.actions.delete_success')),
    onError: () => toast.error(t('admin.people.index.actions.delete_error')),
  })
}

const onSearchClear = (e: Event) => {
  const target = e.target as HTMLInputElement
  if (target?.value === '') triggerSearch()
}
</script>
