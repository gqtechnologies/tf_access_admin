<template>
  <div>
    <Header :items-breadcrumb="itemsBreadcrumb" :title="t('admin.authorized_residents.index.title')" />

    <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
      <p class="text-muted-foreground max-w-2xl text-sm">{{ t('admin.authorized_residents.index.description') }}</p>
      <Card v-if="activeProperty" class="border-dashed">
        <CardContent class="flex items-center gap-3 p-4">
          <Building2 class="text-muted-foreground size-5" />
          <div>
            <p class="text-muted-foreground text-xs">{{ t('admin.authorized_residents.index.property') }}</p>
            <NativeSelect v-if="properties.length > 1" v-model="selectedPropertyId" :aria-label="t('admin.authorized_residents.index.property')">
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
      {{ t('admin.authorized_residents.index.no_property') }}
    </div>

    <template v-else>
      <div class="mb-4 flex flex-wrap gap-2">
        <Button
          v-for="name in tabs"
          :key="name"
          :variant="tab === name ? 'default' : 'outline'"
          size="sm"
          class="gap-2"
          @click="load({ tab: name, page: 1 })"
        >
          {{ t(`admin.authorized_residents.tabs.${name}`) }}
          <Badge variant="secondary" class="tabular-nums">{{ counters[name] }}</Badge>
        </Button>
      </div>

      <div v-if="errors.length" class="mb-4 rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3">
        <p v-for="error in errors" :key="error" class="text-destructive text-sm">{{ error }}</p>
      </div>

      <AdminDataTable :columns="columns" :data="authorized_residents" :empty-message="t(`admin.authorized_residents.empty.${tab}`)">
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

      <AlertDialog :open="confirming !== null" @update:open="(value: boolean) => { if (!value) confirming = null }">
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>{{ confirming ? t(`admin.authorized_residents.confirm.${confirming.action}_title`) : '' }}</AlertDialogTitle>
            <AlertDialogDescription>
              {{ confirming ? t(`admin.authorized_residents.confirm.${confirming.action}_body`, { name: confirming.record.name }) : '' }}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>{{ t('common.actions.cancel') }}</AlertDialogCancel>
            <AlertDialogAction :disabled="submitting" @click="runConfirmed">
              {{ confirming ? t(`admin.authorized_residents.actions.${confirming.action}`) : '' }}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, h, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { router, usePage } from '@inertiajs/vue3'
import { Building2, Check, Ban, X } from 'lucide-vue-next'
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
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { NativeSelect, NativeSelectOption } from '@/components/ui/native-select'
import { useTable } from '@/lib/composables/useTable'
import {
  admin_authorized_residents_path,
  approve_admin_authorized_resident_path,
  reject_admin_authorized_resident_path,
  revoke_admin_authorized_resident_path,
} from '@/routes'
import type { BreadcrumbItem } from '@/types/layout'
import type { ColumnDef } from '@/types/table'
import type { AssignedPropertySummary } from '@/types/visit'

type Tab = 'pending' | 'active' | 'closed'
type Action = 'approve' | 'reject' | 'revoke'
type AuthorizedRow = {
  id: string
  name: string | null
  document: string | null
  relationship_type: string
  status: string
  starts_at: string
  ends_at: string | null
  can_withdraw_parcels: boolean
  notes: string | null
  unit: string
  proposed_by_name: string | null
  created_at: string
}

const props = defineProps<{
  authorized_residents: AuthorizedRow[]
  pagination?: { current_page: number; per_page: number; total_pages: number; total_count: number }
  tab: Tab
  counters: Record<Tab, number>
  properties: AssignedPropertySummary[]
  active_property?: AssignedPropertySummary | null
}>()

const { t, locale } = useI18n()
const page = usePage()
const tabs: Tab[] = ['pending', 'active', 'closed']
const activeProperty = computed(() => props.active_property ?? null)
const confirming = ref<{ action: Action; record: AuthorizedRow } | null>(null)
const submitting = ref(false)

const errors = computed(() => {
  const base = (page.props.errors as Record<string, string | string[]> | undefined)?.base
  if (!base) return []
  return Array.isArray(base) ? base : [base]
})

const itemsBreadcrumb = computed<BreadcrumbItem[]>(() => [
  { label: t('admin.sidebar.home'), href: '/admin/home/index' },
  { label: t('admin.authorized_residents.index.title') },
])

const selectedPropertyId = ref(props.active_property?.id ?? '')
watch(
  () => props.active_property?.id,
  (id) => {
    selectedPropertyId.value = id ?? ''
  },
)
watch(selectedPropertyId, (propertyId) => {
  if (!propertyId || propertyId === props.active_property?.id) return
  load({ propertyId, page: 1 })
})

function load({
  tab = props.tab,
  page: pageNumber = 1,
  perPage,
  propertyId = activeProperty.value?.id,
}: {
  tab?: Tab
  page?: number
  perPage?: number
  propertyId?: string
}) {
  router.get(
    admin_authorized_residents_path(),
    { property_id: propertyId, tab, page: pageNumber, per_page: perPage ?? itemsPerPage.value },
    { preserveState: true, preserveScroll: true },
  )
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
} = useTable((_search: string, pageNumber: number, perPage: number) => load({ page: pageNumber, perPage }), {
  skipInitialFetch: true,
  initialPagination: props.pagination,
})

watch(
  () => props.pagination,
  (meta) => {
    if (meta) setPagination(meta)
  },
)

function formatDate(value: string | null) {
  if (!value) return t('admin.authorized_residents.table.no_end')
  return new Intl.DateTimeFormat(locale.value, { dateStyle: 'medium' }).format(new Date(value))
}

function runConfirmed() {
  const current = confirming.value
  if (!current) return

  const urls: Record<Action, (id: string) => string> = {
    approve: approve_admin_authorized_resident_path,
    reject: reject_admin_authorized_resident_path,
    revoke: revoke_admin_authorized_resident_path,
  }

  submitting.value = true
  router.post(urls[current.action](current.record.id), { tab: props.tab, property_id: activeProperty.value?.id }, {
    preserveScroll: true,
    onSuccess: () => toast.success(t(`admin.authorized_residents.confirm.${current.action}_done`)),
    onFinish: () => {
      submitting.value = false
      confirming.value = null
    },
  })
}

function actionButton(action: Action, record: AuthorizedRow, icon: typeof Check, variant: 'default' | 'outline') {
  return h(
    Button,
    { size: 'sm', variant, class: 'gap-2', onClick: () => (confirming.value = { action, record }) },
    () => [h(icon, { class: 'size-4' }), t(`admin.authorized_residents.actions.${action}`)],
  )
}

const columns = computed<ColumnDef<AuthorizedRow, unknown>[]>(() => {
  const base: ColumnDef<AuthorizedRow, unknown>[] = [
    {
      id: 'person',
      header: () => t('admin.authorized_residents.table.person'),
      cell: ({ row }) =>
        h('div', { class: 'space-y-0.5' }, [
          h('p', { class: 'font-medium' }, row.original.name ?? '—'),
          h('p', { class: 'text-muted-foreground text-xs' }, row.original.document ?? '—'),
        ]),
    },
    {
      id: 'unit',
      header: () => t('admin.authorized_residents.table.unit'),
      cell: ({ row }) =>
        h('div', { class: 'space-y-0.5' }, [
          h('p', row.original.unit),
          h('p', { class: 'text-muted-foreground text-xs' }, t('admin.authorized_residents.table.proposed_by', { name: row.original.proposed_by_name ?? '—' })),
        ]),
    },
    {
      id: 'relationship',
      header: () => t('admin.authorized_residents.table.relationship'),
      cell: ({ row }) =>
        h('div', { class: 'flex flex-wrap gap-1' }, [
          h(Badge, { variant: 'secondary' }, () => t(`admin.authorized_residents.relationships.${row.original.relationship_type}`)),
          row.original.can_withdraw_parcels
            ? h(Badge, { variant: 'outline' }, () => t('admin.authorized_residents.table.parcels'))
            : null,
        ]),
    },
    {
      id: 'validity',
      header: () => t('admin.authorized_residents.table.validity'),
      cell: ({ row }) => h('span', `${formatDate(row.original.starts_at)} → ${formatDate(row.original.ends_at)}`),
    },
  ]

  if (props.tab === 'closed') {
    base.push({
      id: 'status',
      header: () => t('admin.authorized_residents.table.status'),
      cell: ({ row }) => h(Badge, { variant: 'outline' }, () => t(`admin.authorized_residents.status.${row.original.status}`)),
    })
  } else {
    base.push({
      id: 'actions',
      header: () => t('common.table.actions'),
      cell: ({ row }) =>
        props.tab === 'pending'
          ? h('div', { class: 'flex gap-2' }, [
              actionButton('approve', row.original, Check, 'default'),
              actionButton('reject', row.original, X, 'outline'),
            ])
          : actionButton('revoke', row.original, Ban, 'outline'),
    })
  }

  return base
})
</script>
