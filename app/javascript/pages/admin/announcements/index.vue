<template>
  <div>
    <Header :items-breadcrumb="itemsBreadcrumb" :title="t('admin.announcements.index.title')" />

    <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
      <p class="text-muted-foreground max-w-2xl text-sm">
        {{ t('admin.announcements.index.description') }}
      </p>

      <div v-if="activeProperty" class="flex w-full shrink-0 flex-col gap-3 sm:flex-row sm:items-center lg:w-auto">
        <Card class="border-dashed">
          <CardContent class="flex items-center gap-3 p-4">
            <Building2 class="text-muted-foreground size-5" />
            <div>
              <p class="text-muted-foreground text-xs">{{ t('admin.announcements.index.property') }}</p>
              <NativeSelect
                v-if="properties.length > 1"
                v-model="selectedPropertyId"
                :aria-label="t('admin.announcements.index.property')"
              >
                <NativeSelectOption v-for="property in properties" :key="property.id" :value="property.id">
                  {{ property.name }}
                </NativeSelectOption>
              </NativeSelect>
              <p v-else class="font-medium">{{ activeProperty.name }}</p>
              <p class="text-muted-foreground mt-1 text-xs">
                {{ t('admin.announcements.index.audience', { count: audience_count }, audience_count) }}
              </p>
            </div>
          </CardContent>
        </Card>

        <Button class="gap-2" @click="openForm(null)">
          <Plus class="size-4" />
          {{ t('admin.announcements.index.new') }}
        </Button>
      </div>
    </div>

    <div
      v-if="!activeProperty"
      class="text-muted-foreground rounded-lg border border-dashed px-4 py-10 text-center text-sm"
    >
      {{ t('admin.announcements.index.no_property') }}
    </div>

    <template v-else>
      <div class="mb-4 flex flex-wrap gap-2">
        <Button
          v-for="status in statuses"
          :key="status"
          :variant="activeTab === status ? 'default' : 'outline'"
          size="sm"
          class="gap-2"
          @click="load({ tab: status, page: 1 })"
        >
          {{ t(`admin.announcements.tabs.${status}`) }}
          <Badge variant="secondary" class="tabular-nums">{{ counters[status] }}</Badge>
        </Button>
      </div>

      <div v-if="errors.length" class="mb-4 rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3">
        <p v-for="error in errors" :key="error" class="text-destructive text-sm">{{ error }}</p>
      </div>

      <AdminDataTable
        :columns="columns"
        :data="announcements"
        :empty-message="t(`admin.announcements.empty.${activeTab}`)"
      >
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

      <AnnouncementFormDrawer
        v-model:open="formOpen"
        :announcement="editing"
        :property-id="activeProperty.id"
        :categories="categories"
        :priorities="priorities"
      />

      <AlertDialog :open="confirming !== null" @update:open="(value: boolean) => { if (!value) confirming = null }">
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              {{ confirming?.action === 'publish' ? t('admin.announcements.confirm.publish_title') : t('admin.announcements.confirm.archive_title') }}
            </AlertDialogTitle>
            <AlertDialogDescription>
              {{
                confirming?.action === 'publish'
                  ? t('admin.announcements.confirm.publish_body', { count: audience_count }, audience_count)
                  : t('admin.announcements.confirm.archive_body')
              }}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>{{ t('common.actions.cancel') }}</AlertDialogCancel>
            <AlertDialogAction :disabled="submitting" @click="runConfirmed">
              {{ confirming?.action === 'publish' ? t('admin.announcements.actions.publish') : t('admin.announcements.actions.archive') }}
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
import { Archive, Building2, Pencil, Plus, Send } from 'lucide-vue-next'
import { toast } from 'vue-sonner'
import Header from '@/components/admin/layout/Header.vue'
import AdminDataTable from '@/components/admin/table/index.vue'
import DataTablePagination from '@/components/admin/table/DataTablePagination.vue'
import AnnouncementFormDrawer from '@/components/admin/announcements/AnnouncementFormDrawer.vue'
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
  admin_announcements_path,
  archive_admin_announcement_path,
  publish_admin_announcement_path,
} from '@/routes'
import type { AdminAnnouncement, AnnouncementStatus } from '@/types/announcement'
import type { BreadcrumbItem } from '@/types/layout'
import type { ColumnDef } from '@/types/table'
import type { AssignedPropertySummary } from '@/types/visit'

const props = defineProps<{
  announcements: AdminAnnouncement[]
  pagination?: { current_page: number; per_page: number; total_pages: number; total_count: number }
  tab: AnnouncementStatus
  counters: Record<AnnouncementStatus, number>
  properties: AssignedPropertySummary[]
  active_property?: AssignedPropertySummary | null
  audience_count: number
  categories: string[]
  priorities: string[]
}>()

const { t, locale } = useI18n()
const page = usePage()

const statuses: AnnouncementStatus[] = ['published', 'draft', 'archived']
const activeTab = computed(() => props.tab)
const activeProperty = computed(() => props.active_property ?? null)

const formOpen = ref(false)
const editing = ref<AdminAnnouncement | null>(null)
const confirming = ref<{ action: 'publish' | 'archive'; announcement: AdminAnnouncement } | null>(null)
const submitting = ref(false)

const errors = computed(() => {
  const base = (page.props.errors as Record<string, string | string[]> | undefined)?.base
  if (!base) return []
  return Array.isArray(base) ? base : [base]
})

const itemsBreadcrumb = computed<BreadcrumbItem[]>(() => [
  { label: t('admin.sidebar.home'), href: '/admin/home/index' },
  { label: t('admin.announcements.index.title') },
])

// Bound to the property select; follows the server's active property and
// reloads the page when the user picks another one.
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
  tab = activeTab.value,
  page: pageNumber = 1,
  perPage,
  propertyId = activeProperty.value?.id,
}: {
  tab?: AnnouncementStatus
  page?: number
  perPage?: number
  propertyId?: string
}) {
  router.get(
    admin_announcements_path(),
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

function openForm(announcement: AdminAnnouncement | null) {
  editing.value = announcement
  formOpen.value = true
}

function runConfirmed() {
  const current = confirming.value
  if (!current) return

  submitting.value = true
  const url =
    current.action === 'publish'
      ? publish_admin_announcement_path(current.announcement.id)
      : archive_admin_announcement_path(current.announcement.id)

  router.post(url, {}, {
    preserveScroll: true,
    onSuccess: () => {
      toast.success(
        current.action === 'publish' ? t('admin.announcements.confirm.published') : t('admin.announcements.confirm.archived'),
      )
    },
    onFinish: () => {
      submitting.value = false
      confirming.value = null
    },
  })
}

function formatDateTime(value: string | null) {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value

  return new Intl.DateTimeFormat(locale.value, { dateStyle: 'medium', timeStyle: 'short' }).format(date)
}

const columns = computed<ColumnDef<AdminAnnouncement, unknown>[]>(() => {
  const base: ColumnDef<AdminAnnouncement, unknown>[] = [
    {
      id: 'title',
      header: () => t('admin.announcements.table.title'),
      cell: ({ row }) =>
        h('div', { class: 'max-w-md space-y-1' }, [
          h('p', { class: 'font-medium' }, row.original.title),
          h('p', { class: 'text-muted-foreground line-clamp-2 text-xs' }, row.original.content),
        ]),
    },
    {
      id: 'category',
      header: () => t('admin.announcements.table.category'),
      cell: ({ row }) =>
        h('div', { class: 'flex flex-wrap gap-1' }, [
          row.original.category
            ? h(Badge, { variant: 'secondary' }, () => t(`admin.announcements.categories.${row.original.category}`))
            : null,
          h(
            Badge,
            { variant: ['high', 'urgent'].includes(row.original.priority) ? 'destructive' : 'outline' },
            () => t(`admin.announcements.priorities.${row.original.priority}`),
          ),
        ]),
    },
    {
      id: 'date',
      header: () =>
        activeTab.value === 'draft' ? t('admin.announcements.table.created_at') : t('admin.announcements.table.published_at'),
      cell: ({ row }) =>
        h('span', formatDateTime(activeTab.value === 'draft' ? row.original.created_at : row.original.published_at)),
    },
  ]

  if (activeTab.value !== 'draft') {
    base.push({
      id: 'reads',
      header: () => t('admin.announcements.table.reads'),
      cell: ({ row }) =>
        h('div', { class: 'space-y-0.5 text-sm tabular-nums' }, [
          h('p', t('admin.announcements.table.read_count', { count: row.original.read_count }, row.original.read_count)),
          row.original.requires_acknowledgement
            ? h(
                'p',
                { class: 'text-muted-foreground text-xs' },
                t('admin.announcements.table.acknowledged_count', { count: row.original.acknowledged_count }, row.original.acknowledged_count),
              )
            : null,
        ]),
    })
  }

  if (activeTab.value !== 'archived') {
    base.push({
      id: 'actions',
      header: () => t('common.table.actions'),
      cell: ({ row }) => {
        const announcement = row.original

        if (announcement.status === 'draft') {
          return h('div', { class: 'flex gap-2' }, [
            h(Button, { variant: 'outline', size: 'sm', class: 'gap-2', onClick: () => openForm(announcement) }, () => [
              h(Pencil, { class: 'size-4' }),
              t('admin.announcements.actions.edit'),
            ]),
            h(
              Button,
              { size: 'sm', class: 'gap-2', onClick: () => (confirming.value = { action: 'publish', announcement }) },
              () => [h(Send, { class: 'size-4' }), t('admin.announcements.actions.publish')],
            ),
          ])
        }

        return h(
          Button,
          {
            variant: 'outline',
            size: 'sm',
            class: 'gap-2',
            onClick: () => (confirming.value = { action: 'archive', announcement }),
          },
          () => [h(Archive, { class: 'size-4' }), t('admin.announcements.actions.archive')],
        )
      },
    })
  }

  return base
})
</script>
