<template>
  <div>
    <Header :items-breadcrumb="itemsBreadcrumb" :title="t('admin.reservations.index.title')" />

    <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
      <p class="text-muted-foreground max-w-2xl text-sm">{{ t('admin.reservations.index.description') }}</p>

      <Card v-if="activeProperty" class="border-dashed">
        <CardContent class="flex items-center gap-3 p-4">
          <Building2 class="text-muted-foreground size-5" />
          <div>
            <p class="text-muted-foreground text-xs">{{ t('admin.reservations.index.property') }}</p>
            <NativeSelect v-if="properties.length > 1" v-model="selectedPropertyId" :aria-label="t('admin.reservations.index.property')">
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
      {{ t('admin.reservations.index.no_property') }}
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
          {{ t(`admin.reservations.tabs.${name}`) }}
          <Badge variant="secondary" class="tabular-nums">{{ counters[name] }}</Badge>
        </Button>
      </div>

      <div v-if="errors.length" class="mb-4 rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3">
        <p v-for="error in errors" :key="error" class="text-destructive text-sm">{{ error }}</p>
      </div>

      <AdminDataTable :columns="columns" :data="reservations" :empty-message="t(`admin.reservations.empty.${tab}`)">
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

      <Dialog :open="pendingAction !== null" @update:open="(value: boolean) => { if (!value) pendingAction = null }">
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {{ pendingAction?.kind === 'reject' ? t('admin.reservations.reject.title') : t('admin.reservations.cancel.title') }}
            </DialogTitle>
            <DialogDescription>
              {{ pendingAction?.kind === 'reject' ? t('admin.reservations.reject.description') : t('admin.reservations.cancel.description') }}
            </DialogDescription>
          </DialogHeader>
          <div class="space-y-2">
            <Label for="reservation-reason">{{ t('admin.reservations.reason') }}</Label>
            <Textarea id="reservation-reason" v-model="reason" rows="3" maxlength="500" />
          </div>
          <DialogFooter>
            <Button variant="outline" :disabled="submitting" @click="pendingAction = null">{{ t('common.actions.cancel') }}</Button>
            <Button variant="destructive" :disabled="submitting" @click="runPendingAction">
              {{ pendingAction?.kind === 'reject' ? t('admin.reservations.actions.reject') : t('admin.reservations.actions.cancel') }}
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
import { Building2, Check, X } from 'lucide-vue-next'
import { toast } from 'vue-sonner'
import Header from '@/components/admin/layout/Header.vue'
import AdminDataTable from '@/components/admin/table/index.vue'
import DataTablePagination from '@/components/admin/table/DataTablePagination.vue'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Label } from '@/components/ui/label'
import { NativeSelect, NativeSelectOption } from '@/components/ui/native-select'
import { Textarea } from '@/components/ui/textarea'
import { useTable } from '@/lib/composables/useTable'
import {
  admin_reservations_path,
  approve_admin_reservation_path,
  cancel_admin_reservation_path,
  reject_admin_reservation_path,
} from '@/routes'
import type { AdminReservation, ReservationTab } from '@/types/common_area'
import type { BreadcrumbItem } from '@/types/layout'
import type { ColumnDef } from '@/types/table'
import type { AssignedPropertySummary } from '@/types/visit'

const props = defineProps<{
  reservations: AdminReservation[]
  pagination?: { current_page: number; per_page: number; total_pages: number; total_count: number }
  tab: ReservationTab
  counters: Record<ReservationTab, number>
  properties: AssignedPropertySummary[]
  active_property?: AssignedPropertySummary | null
}>()

const { t, locale } = useI18n()
const page = usePage()
const tabs: ReservationTab[] = ['pending', 'upcoming', 'history']
const activeProperty = computed(() => props.active_property ?? null)
const submitting = ref(false)
const pendingAction = ref<{ kind: 'reject' | 'cancel'; reservation: AdminReservation } | null>(null)
const reason = ref('')

const errors = computed(() => {
  const base = (page.props.errors as Record<string, string | string[]> | undefined)?.base
  if (!base) return []
  return Array.isArray(base) ? base : [base]
})

const itemsBreadcrumb = computed<BreadcrumbItem[]>(() => [
  { label: t('admin.sidebar.home'), href: '/admin/home/index' },
  { label: t('admin.reservations.index.title') },
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
  tab?: ReservationTab
  page?: number
  perPage?: number
  propertyId?: string
}) {
  router.get(
    admin_reservations_path(),
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

// Shown in the property's own time zone, whatever the browser's is.
function formatSlot(reservation: AdminReservation) {
  const options = { timeZone: reservation.time_zone }
  const day = new Intl.DateTimeFormat(locale.value, { ...options, dateStyle: 'medium' }).format(new Date(reservation.starts_at))
  const time = new Intl.DateTimeFormat(locale.value, { ...options, timeStyle: 'short' })
  return `${day} · ${time.format(new Date(reservation.starts_at))}–${time.format(new Date(reservation.ends_at))}`
}

function approve(reservation: AdminReservation) {
  submitting.value = true
  router.post(approve_admin_reservation_path(reservation.id), {}, {
    preserveScroll: true,
    onSuccess: () => toast.success(t('admin.reservations.approved')),
    onFinish: () => {
      submitting.value = false
    },
  })
}

function askFor(kind: 'reject' | 'cancel', reservation: AdminReservation) {
  reason.value = ''
  pendingAction.value = { kind, reservation }
}

function runPendingAction() {
  const action = pendingAction.value
  if (!action) return

  submitting.value = true
  const url =
    action.kind === 'reject'
      ? reject_admin_reservation_path(action.reservation.id)
      : cancel_admin_reservation_path(action.reservation.id)

  router.post(url, { reason: reason.value.trim() }, {
    preserveScroll: true,
    onSuccess: () =>
      toast.success(action.kind === 'reject' ? t('admin.reservations.rejected') : t('admin.reservations.cancelled')),
    onFinish: () => {
      submitting.value = false
      pendingAction.value = null
    },
  })
}

const columns = computed<ColumnDef<AdminReservation, unknown>[]>(() => {
  const base: ColumnDef<AdminReservation, unknown>[] = [
    {
      id: 'area',
      header: () => t('admin.reservations.table.area'),
      cell: ({ row }) => h('span', { class: 'font-medium' }, row.original.common_area.name),
    },
    {
      id: 'slot',
      header: () => t('admin.reservations.table.slot'),
      cell: ({ row }) => h('span', formatSlot(row.original)),
    },
    {
      id: 'unit',
      header: () => t('admin.reservations.table.unit'),
      cell: ({ row }) =>
        h('div', { class: 'space-y-0.5' }, [
          h('p', row.original.unit.name),
          h('p', { class: 'text-muted-foreground text-xs' }, row.original.requested_by_name ?? '—'),
        ]),
    },
    {
      id: 'guests',
      header: () => t('admin.reservations.table.guests'),
      cell: ({ row }) => h('span', { class: 'tabular-nums' }, row.original.guest_count ?? 0),
    },
  ]

  if (props.tab === 'history') {
    base.push({
      id: 'status',
      header: () => t('admin.reservations.table.status'),
      cell: ({ row }) =>
        h('div', { class: 'space-y-0.5' }, [
          h(Badge, { variant: row.original.status === 'approved' ? 'secondary' : 'outline' }, () =>
            t(`admin.reservations.status.${row.original.status}`),
          ),
          row.original.rejection_reason
            ? h('p', { class: 'text-muted-foreground text-xs' }, row.original.rejection_reason)
            : null,
        ]),
    })
  } else {
    base.push({
      id: 'actions',
      header: () => t('common.table.actions'),
      cell: ({ row }) => {
        const reservation = row.original
        if (props.tab === 'pending') {
          return h('div', { class: 'flex gap-2' }, [
            h(Button, { size: 'sm', class: 'gap-2', disabled: submitting.value, onClick: () => approve(reservation) }, () => [
              h(Check, { class: 'size-4' }),
              t('admin.reservations.actions.approve'),
            ]),
            h(Button, { variant: 'outline', size: 'sm', class: 'gap-2', onClick: () => askFor('reject', reservation) }, () => [
              h(X, { class: 'size-4' }),
              t('admin.reservations.actions.reject'),
            ]),
          ])
        }
        return h(Button, { variant: 'outline', size: 'sm', onClick: () => askFor('cancel', reservation) }, () =>
          t('admin.reservations.actions.cancel'),
        )
      },
    })
  }

  return base
})
</script>
