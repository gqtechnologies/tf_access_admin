<template>
  <div>
    <Header :itemsBreadcrumb="breadcrumbs" :title="t('admin.operational_roles.assignments.title')" />

    <div class="p-6 space-y-4">
      <!-- Filters row + action button -->
      <div class="flex items-center justify-between gap-3 flex-wrap">
        <div class="flex items-center gap-2 flex-1">
          <Input
            type="search"
            :placeholder="t('admin.operational_roles.assignments.filters.search_person')"
            v-model="searchQuery"
            class="max-w-xs"
            @keyup.enter="applyFilters"
          />
          <select
            v-model="roleFilter"
            class="h-9 rounded-md border border-input bg-background px-3 text-sm"
            @change="applyFilters"
          >
            <option value="">{{ t('admin.operational_roles.assignments.filters.all_roles') }}</option>
            <option v-for="r in available_roles" :key="r.key" :value="r.key">{{ r.name }}</option>
          </select>
          <select
            v-model="propertyFilter"
            class="h-9 rounded-md border border-input bg-background px-3 text-sm"
            @change="applyFilters"
          >
            <option value="">{{ t('admin.operational_roles.assignments.filters.all_properties') }}</option>
            <option v-for="p in accessible_properties" :key="p.id" :value="p.id">{{ p.name }}</option>
          </select>
        </div>
        <Button v-if="permissions.create" @click="drawerOpen = true">
          <PlusIcon class="w-4 h-4 mr-1" />
          {{ t('admin.operational_roles.assignments.new_assignment_button') }}
        </Button>
      </div>

      <!-- Assignments table -->
      <div class="rounded-lg border bg-card">
        <div v-if="assignments.length === 0" class="px-6 py-12 text-center text-muted-foreground text-sm">
          {{ t('admin.operational_roles.assignments.empty_message') }}
        </div>
        <table v-else class="w-full text-sm">
          <thead>
            <tr class="border-b bg-muted/40">
              <th class="text-left px-6 py-3 font-medium text-muted-foreground">{{ t('admin.operational_roles.assignments.table_headers.person') }}</th>
              <th class="text-left px-6 py-3 font-medium text-muted-foreground">{{ t('admin.operational_roles.assignments.table_headers.role') }}</th>
              <th class="text-left px-6 py-3 font-medium text-muted-foreground">{{ t('admin.operational_roles.assignments.table_headers.property') }}</th>
              <th class="text-left px-6 py-3 font-medium text-muted-foreground">{{ t('admin.operational_roles.assignments.table_headers.from') }}</th>
              <th class="text-left px-6 py-3 font-medium text-muted-foreground">{{ t('admin.operational_roles.assignments.table_headers.to') }}</th>
              <th class="px-6 py-3"></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="a in assignments" :key="a.id" class="border-b last:border-0 hover:bg-muted/20">
              <td class="px-6 py-3 font-medium">{{ a.person_name ?? '—' }}</td>
              <td class="px-6 py-3">
                <Badge variant="outline">{{ a.role ?? a.role_key ?? '—' }}</Badge>
              </td>
              <td class="px-6 py-3 text-muted-foreground">{{ a.property_name ?? '—' }}</td>
              <td class="px-6 py-3 text-muted-foreground">{{ a.starts_at ?? '—' }}</td>
              <td class="px-6 py-3 text-muted-foreground">{{ a.ends_at ?? '—' }}</td>
              <td class="px-6 py-3 text-right">
                <DropdownMenu>
                  <DropdownMenuTrigger as-child>
                    <Button variant="ghost" size="icon">
                      <MoreHorizontalIcon class="w-4 h-4" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuItem
                      class="text-destructive focus:text-destructive cursor-pointer"
                      @click="confirmRevoke(a)"
                    >
                      <XCircleIcon class="w-4 h-4 mr-2" />
                      {{ t('admin.operational_roles.assignments.revoke_action') }}
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination -->
      <DataTablePagination
        v-if="pagination"
        :current-page="currentPage"
        :total-pages="totalPages"
        :total-items="totalItems"
        :items-per-page="itemsPerPage"
        :items-per-page-options="[10, 25, 50]"
        :on-page-change="handlePageChange"
        :on-items-per-page-change="handleItemsPerPageChange"
      />
    </div>

    <!-- Revoke confirmation dialog -->
    <AlertDialog :open="!!revokeTarget" @update:open="revokeTarget = null">
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>{{ t('admin.operational_roles.assignments.revoke_confirmation_title') }}</AlertDialogTitle>
          <AlertDialogDescription>
            {{ t('admin.operational_roles.assignments.revoke_confirmation_description', {
              role: revokeTarget?.role,
              person: revokeTarget?.person_name
            }) }}
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel @click="revokeTarget = null">{{ t('admin.operational_roles.assignments.revoke_cancel') }}</AlertDialogCancel>
          <AlertDialogAction variant="destructive" @click="submitRevoke">{{ t('admin.operational_roles.assignments.revoke_confirm') }}</AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>

    <!-- Assignment drawer -->
    <AssignRoleDrawer
      :open="drawerOpen"
      :available_roles="available_roles"
      :accessible_properties="accessible_properties"
      @close="drawerOpen = false"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from "vue"
import { router } from "@inertiajs/vue3"
import { useI18n } from "vue-i18n"
import Header from "@/components/admin/layout/Header.vue"
import DataTablePagination from "@/components/admin/table/DataTablePagination.vue"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import {
  DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger
} from "@/components/ui/dropdown-menu"
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent,
  AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle
} from "@/components/ui/alert-dialog"
import { PlusIcon, MoreHorizontalIcon, XCircleIcon } from "lucide-vue-next"
import AssignRoleDrawer from "@/components/admin/operational_roles/AssignRoleDrawer.vue"
import type { AssignmentRow, AccessibleProperty } from "@/types/operational_roles"

const { t } = useI18n()

interface PaginationMeta {
  current_page: number
  total_pages: number
  total_count: number
  per_page: number
}

const props = defineProps<{
  assignments: AssignmentRow[]
  pagination: PaginationMeta | null
  available_roles: Array<{ key: string; name: string }>
  accessible_properties: AccessibleProperty[]
  permissions: { create: boolean }
}>()

const breadcrumbs = [
  { label: t('admin.sidebar.home'), href: "/admin/home/index" },
  { label: t('admin.operational_roles.index.title'), href: "/admin/operational_roles" },
  { label: t('admin.operational_roles.assignments.title') }
]

const drawerOpen = ref(false)
const revokeTarget = ref<AssignmentRow | null>(null)
const searchQuery = ref("")
const roleFilter = ref("")
const propertyFilter = ref<string | number>("")

const currentPage = computed(() => props.pagination?.current_page ?? 1)
const totalPages = computed(() => props.pagination?.total_pages ?? 1)
const totalItems = computed(() => props.pagination?.total_count ?? 0)
const itemsPerPage = computed(() => props.pagination?.per_page ?? 10)

function applyFilters() {
  router.get("/admin/operational_roles/assignments", {
    q: searchQuery.value || undefined,
    role: roleFilter.value || undefined,
    property_id: propertyFilter.value || undefined
  }, { preserveState: true })
}

function handlePageChange(page: number) {
  router.get("/admin/operational_roles/assignments", { page }, { preserveState: true })
}

function handleItemsPerPageChange(perPage: number) {
  router.get("/admin/operational_roles/assignments", { per_page: perPage, page: 1 }, { preserveState: true })
}

function confirmRevoke(assignment: AssignmentRow) {
  revokeTarget.value = assignment
}

function submitRevoke() {
  if (!revokeTarget.value) return
  router.delete(`/admin/operational_roles/assignments/${revokeTarget.value.id}`, {
    onFinish: () => { revokeTarget.value = null }
  })
}
</script>
