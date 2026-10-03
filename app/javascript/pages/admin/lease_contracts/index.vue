<template>
  <div>
    <Header :items-breadcrumb="itemsBreadcrumb" :title="t('admin.lease_contracts.index.title')" />

    <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
      <p class="text-muted-foreground max-w-2xl text-sm">{{ t('admin.lease_contracts.index.description') }}</p>
      <div v-if="activeProperty" class="flex w-full shrink-0 flex-col gap-3 sm:flex-row sm:items-center lg:w-auto">
        <Card class="border-dashed">
          <CardContent class="flex items-center gap-3 p-4">
            <Building2 class="text-muted-foreground size-5" />
            <div>
              <p class="text-muted-foreground text-xs">{{ t('admin.lease_contracts.index.property') }}</p>
              <NativeSelect v-if="properties.length > 1" v-model="selectedPropertyId" :aria-label="t('admin.lease_contracts.index.property')">
                <NativeSelectOption v-for="property in properties" :key="property.id" :value="property.id">{{ property.name }}</NativeSelectOption>
              </NativeSelect>
              <p v-else class="font-medium">{{ activeProperty.name }}</p>
            </div>
          </CardContent>
        </Card>
        <Button class="gap-2" @click="formOpen = true">
          <Plus class="size-4" />
          {{ t('admin.lease_contracts.index.new') }}
        </Button>
      </div>
    </div>

    <div v-if="!activeProperty" class="text-muted-foreground rounded-lg border border-dashed px-4 py-10 text-center text-sm">
      {{ t('admin.lease_contracts.index.no_property') }}
    </div>

    <template v-else>
      <div class="mb-4 flex flex-wrap gap-2">
        <Button v-for="name in tabs" :key="name" :variant="tab === name ? 'default' : 'outline'" size="sm" class="gap-2" @click="load({ tab: name, page: 1 })">
          {{ t(`admin.lease_contracts.tabs.${name}`) }}
          <Badge variant="secondary" class="tabular-nums">{{ counters[name] }}</Badge>
        </Button>
      </div>

      <div v-if="errors.length" class="mb-4 rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3">
        <p v-for="error in errors" :key="error" class="text-destructive text-sm">{{ error }}</p>
      </div>

      <AdminDataTable :columns="columns" :data="leases" :empty-message="t(`admin.lease_contracts.empty.${tab}`)">
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

      <LeaseFormDrawer v-model:open="formOpen" :property-id="activeProperty.id" :units="units" />

      <Dialog :open="acting !== null" @update:open="(value: boolean) => { if (!value) acting = null }">
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{{ acting ? t(`admin.lease_contracts.confirm.${acting.action}_title`) : '' }}</DialogTitle>
            <DialogDescription>
              {{ acting ? t(`admin.lease_contracts.confirm.${acting.action}_body`, { name: acting.lease.lessee_name ?? '', unit: acting.lease.unit }) : '' }}
            </DialogDescription>
          </DialogHeader>
          <div v-if="acting?.action === 'terminate'" class="space-y-2">
            <Label for="terminate-on">{{ t('admin.lease_contracts.confirm.terminate_on') }}</Label>
            <Input id="terminate-on" v-model="terminateOn" type="date" />
          </div>
          <DialogFooter>
            <Button variant="outline" :disabled="submitting" @click="acting = null">{{ t('common.actions.cancel') }}</Button>
            <Button :variant="acting?.action === 'terminate' ? 'destructive' : 'default'" :disabled="submitting" @click="runAction">
              {{ acting ? t(`admin.lease_contracts.actions.${acting.action}`) : '' }}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, h, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { router, usePage } from '@inertiajs/vue3'
import { Building2, Plus } from 'lucide-vue-next'
import { toast } from 'vue-sonner'
import Header from '@/components/admin/layout/Header.vue'
import AdminDataTable from '@/components/admin/table/index.vue'
import DataTablePagination from '@/components/admin/table/DataTablePagination.vue'
import LeaseFormDrawer from '@/components/admin/lease_contracts/LeaseFormDrawer.vue'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { NativeSelect, NativeSelectOption } from '@/components/ui/native-select'
import { useTable } from '@/lib/composables/useTable'
import { activate_admin_lease_contract_path, admin_lease_contracts_path, terminate_admin_lease_contract_path } from '@/routes'
import type { BreadcrumbItem } from '@/types/layout'
import type { ColumnDef } from '@/types/table'
import type { AssignedPropertySummary } from '@/types/visit'

type Tab = 'draft' | 'active' | 'terminated'
type LeaseRow = {
  id: string
  status: Tab
  unit: string
  lessee_name: string | null
  lessor_name: string | null
  starts_at: string
  ends_at: string | null
  can_authorize_visits: boolean
  can_reserve_common_areas: boolean
  can_withdraw_parcels: boolean
}

const props = defineProps<{
  leases: LeaseRow[]
  pagination?: { current_page: number; per_page: number; total_pages: number; total_count: number }
  tab: Tab
  counters: Record<Tab, number>
  properties: AssignedPropertySummary[]
  active_property?: AssignedPropertySummary | null
  units: { id: string; name: string; owners: { id: string; name: string }[] }[]
}>()

const { t, locale } = useI18n()
const page = usePage()
const tabs: Tab[] = ['active', 'draft', 'terminated']
const activeProperty = computed(() => props.active_property ?? null)
const formOpen = ref(false)
const acting = ref<{ action: 'activate' | 'terminate'; lease: LeaseRow } | null>(null)
const terminateOn = ref('')
const submitting = ref(false)

const errors = computed(() => {
  const base = (page.props.errors as Record<string, string | string[]> | undefined)?.base
  if (!base) return []
  return Array.isArray(base) ? base : [base]
})

const itemsBreadcrumb = computed<BreadcrumbItem[]>(() => [
  { label: t('admin.sidebar.home'), href: '/admin/home/index' },
  { label: t('admin.lease_contracts.index.title') },
])

const selectedPropertyId = ref(props.active_property?.id ?? '')
watch(() => props.active_property?.id, (id) => (selectedPropertyId.value = id ?? ''))
watch(selectedPropertyId, (propertyId) => {
  if (!propertyId || propertyId === props.active_property?.id) return
  load({ propertyId, page: 1 })
})

function load({ tab = props.tab, page: pageNumber = 1, perPage, propertyId = activeProperty.value?.id }: { tab?: Tab; page?: number; perPage?: number; propertyId?: string }) {
  router.get(admin_lease_contracts_path(), { property_id: propertyId, tab, page: pageNumber, per_page: perPage ?? itemsPerPage.value }, { preserveState: true, preserveScroll: true })
}

const { currentPage, totalPages, totalItems, itemsPerPage, itemsPerPageOptions, handlePageChange, handleItemsPerPageChange, setPagination } = useTable(
  (_search: string, pageNumber: number, perPage: number) => load({ page: pageNumber, perPage }),
  { skipInitialFetch: true, initialPagination: props.pagination },
)
watch(() => props.pagination, (meta) => { if (meta) setPagination(meta) })

function formatDate(value: string | null) {
  if (!value) return t('admin.lease_contracts.table.no_end')
  return new Intl.DateTimeFormat(locale.value, { dateStyle: 'medium', timeZone: 'UTC' }).format(new Date(value))
}

function act(action: 'activate' | 'terminate', lease: LeaseRow) {
  terminateOn.value = new Date().toISOString().slice(0, 10)
  acting.value = { action, lease }
}

function runAction() {
  const current = acting.value
  if (!current) return
  submitting.value = true
  const url = current.action === 'activate' ? activate_admin_lease_contract_path(current.lease.id) : terminate_admin_lease_contract_path(current.lease.id)
  router.post(url, current.action === 'terminate' ? { on: terminateOn.value } : {}, {
    preserveScroll: true,
    onSuccess: () => toast.success(t(`admin.lease_contracts.confirm.${current.action}_done`)),
    onFinish: () => {
      submitting.value = false
      acting.value = null
    },
  })
}

const columns = computed<ColumnDef<LeaseRow, unknown>[]>(() => {
  const base: ColumnDef<LeaseRow, unknown>[] = [
    { id: 'unit', header: () => t('admin.lease_contracts.table.unit'), cell: ({ row }) => h('span', { class: 'font-medium' }, row.original.unit) },
    {
      id: 'parties',
      header: () => t('admin.lease_contracts.table.parties'),
      cell: ({ row }) =>
        h('div', { class: 'space-y-0.5' }, [
          h('p', row.original.lessee_name ?? '—'),
          h('p', { class: 'text-muted-foreground text-xs' }, t('admin.lease_contracts.table.lessor', { name: row.original.lessor_name ?? '—' })),
        ]),
    },
    { id: 'term', header: () => t('admin.lease_contracts.table.term'), cell: ({ row }) => h('span', `${formatDate(row.original.starts_at)} → ${formatDate(row.original.ends_at)}`) },
    {
      id: 'permissions',
      header: () => t('admin.lease_contracts.table.permissions'),
      cell: ({ row }) =>
        h(
          'div',
          { class: 'flex flex-wrap gap-1' },
          (['can_authorize_visits', 'can_reserve_common_areas', 'can_withdraw_parcels'] as const)
            .filter((key) => row.original[key])
            .map((key) => h(Badge, { variant: 'outline' }, () => t(`admin.lease_contracts.permissions.${key}`))),
        ),
    },
  ]

  if (props.tab !== 'terminated') {
    base.push({
      id: 'actions',
      header: () => t('common.table.actions'),
      cell: ({ row }) =>
        row.original.status === 'draft'
          ? h(Button, { size: 'sm', onClick: () => act('activate', row.original) }, () => t('admin.lease_contracts.actions.activate'))
          : h(Button, { size: 'sm', variant: 'outline', onClick: () => act('terminate', row.original) }, () => t('admin.lease_contracts.actions.terminate')),
    })
  }

  return base
})
</script>
