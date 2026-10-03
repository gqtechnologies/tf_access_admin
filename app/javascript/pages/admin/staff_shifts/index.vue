<template>
  <div>
    <Header :items-breadcrumb="itemsBreadcrumb" :title="t('admin.staff_shifts.index.title')" />

    <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
      <p class="text-muted-foreground max-w-2xl text-sm">{{ t('admin.staff_shifts.index.description') }}</p>
      <div v-if="activeProperty" class="flex flex-col gap-3 sm:flex-row sm:items-center">
        <Card class="border-dashed">
          <CardContent class="flex items-center gap-3 p-4">
            <Building2 class="text-muted-foreground size-5" />
            <div>
              <p class="text-muted-foreground text-xs">{{ t('admin.staff_shifts.index.property') }}</p>
              <NativeSelect v-if="properties.length > 1" v-model="selectedPropertyId" :aria-label="t('admin.staff_shifts.index.property')">
                <NativeSelectOption v-for="property in properties" :key="property.id" :value="property.id">
                  {{ property.name }}
                </NativeSelectOption>
              </NativeSelect>
              <p v-else class="font-medium">{{ activeProperty.name }}</p>
            </div>
          </CardContent>
        </Card>
        <div class="space-y-1">
          <Label for="shift-day" class="text-xs">{{ t('admin.staff_shifts.index.day') }}</Label>
          <Input id="shift-day" v-model="selectedDay" type="date" />
        </div>
      </div>
    </div>

    <div v-if="!activeProperty" class="text-muted-foreground rounded-lg border border-dashed px-4 py-10 text-center text-sm">
      {{ t('admin.staff_shifts.index.no_property') }}
    </div>

    <AdminDataTable v-else :columns="columns" :data="shifts" :empty-message="t('admin.staff_shifts.index.empty')" />
  </div>
</template>

<script setup lang="ts">
import { computed, h, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { router } from '@inertiajs/vue3'
import { Building2 } from 'lucide-vue-next'
import Header from '@/components/admin/layout/Header.vue'
import AdminDataTable from '@/components/admin/table/index.vue'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { NativeSelect, NativeSelectOption } from '@/components/ui/native-select'
import { admin_staff_shifts_path } from '@/routes'
import type { BreadcrumbItem } from '@/types/layout'
import type { ColumnDef } from '@/types/table'
import type { AssignedPropertySummary } from '@/types/visit'

type ShiftRow = {
  id: string
  person_name: string | null
  status: string
  started_at: string | null
  ended_at: string | null
  notes: string | null
  parcels_received: number
}

const props = defineProps<{
  shifts: ShiftRow[]
  day: string
  time_zone: string
  properties: AssignedPropertySummary[]
  active_property?: AssignedPropertySummary | null
}>()

const { t, locale } = useI18n()
const activeProperty = computed(() => props.active_property ?? null)
const selectedPropertyId = ref(props.active_property?.id ?? '')
const selectedDay = ref(props.day)

const itemsBreadcrumb = computed<BreadcrumbItem[]>(() => [
  { label: t('admin.sidebar.home'), href: '/admin/home/index' },
  { label: t('admin.staff_shifts.index.title') },
])

watch(() => props.active_property?.id, (id) => (selectedPropertyId.value = id ?? ''))
watch(() => props.day, (day) => (selectedDay.value = day))

function load(propertyId: string, day: string) {
  router.get(admin_staff_shifts_path(), { property_id: propertyId, day }, { preserveState: true, preserveScroll: true })
}

watch(selectedPropertyId, (propertyId) => {
  if (propertyId && propertyId !== props.active_property?.id) load(propertyId, selectedDay.value)
})
watch(selectedDay, (day) => {
  if (day && day !== props.day && activeProperty.value) load(activeProperty.value.id, day)
})

// In the property's time zone, whatever the browser's is.
function formatTime(value: string | null) {
  if (!value) return '—'
  return new Intl.DateTimeFormat(locale.value, { timeZone: props.time_zone, dateStyle: 'short', timeStyle: 'short' }).format(new Date(value))
}

function duration(row: ShiftRow) {
  if (!row.started_at) return '—'
  const end = row.ended_at ? new Date(row.ended_at).getTime() : Date.now()
  const minutes = Math.max(0, Math.round((end - new Date(row.started_at).getTime()) / 60000))
  return t('admin.staff_shifts.index.duration', { hours: Math.floor(minutes / 60), minutes: minutes % 60 })
}

const columns = computed<ColumnDef<ShiftRow, unknown>[]>(() => [
  {
    id: 'person',
    header: () => t('admin.staff_shifts.table.person'),
    cell: ({ row }) =>
      h('div', { class: 'flex items-center gap-2' }, [
        h('span', { class: 'font-medium' }, row.original.person_name ?? '—'),
        row.original.status === 'in_progress' ? h(Badge, {}, () => t('admin.staff_shifts.table.on_duty')) : null,
      ]),
  },
  { id: 'start', header: () => t('admin.staff_shifts.table.start'), cell: ({ row }) => h('span', formatTime(row.original.started_at)) },
  { id: 'end', header: () => t('admin.staff_shifts.table.end'), cell: ({ row }) => h('span', formatTime(row.original.ended_at)) },
  { id: 'duration', header: () => t('admin.staff_shifts.table.duration'), cell: ({ row }) => h('span', { class: 'tabular-nums' }, duration(row.original)) },
  {
    id: 'parcels',
    header: () => t('admin.staff_shifts.table.parcels'),
    cell: ({ row }) => h('span', { class: 'tabular-nums' }, row.original.parcels_received),
  },
  {
    id: 'notes',
    header: () => t('admin.staff_shifts.table.notes'),
    cell: ({ row }) => h('p', { class: 'text-muted-foreground max-w-md whitespace-pre-line text-sm' }, row.original.notes ?? '—'),
  },
])
</script>
