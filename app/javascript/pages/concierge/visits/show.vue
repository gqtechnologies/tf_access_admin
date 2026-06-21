<template>
  <div>
    <Header :items-breadcrumb="itemsBreadcrumb" :title="visit.visitor?.display_name ?? t('concierge.visits.show.title')" />

    <div class="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
      <VisitStatusBadge :status="visit.status" :label="visit.status_label" />
      <VisitActionsDropdown
        :visit="visit"
        @check-in="openCheckIn"
        @check-out="openCheckOut"
      />
    </div>

    <Card>
      <CardContent class="grid gap-4 p-6 sm:grid-cols-2">
        <div>
          <p class="text-muted-foreground text-xs">{{ t('concierge.visits.show.fields.unit') }}</p>
          <p class="font-medium">{{ visit.unit?.display_name ?? visit.unit?.identifier ?? '—' }}</p>
        </div>
        <div>
          <p class="text-muted-foreground text-xs">{{ t('concierge.visits.show.fields.host') }}</p>
          <p class="font-medium">{{ visit.host?.display_name ?? '—' }}</p>
        </div>
        <div>
          <p class="text-muted-foreground text-xs">{{ t('concierge.visits.show.fields.scheduled_at') }}</p>
          <p class="font-medium">{{ formatDateTime(visit.scheduled_at) }}</p>
        </div>
        <div>
          <p class="text-muted-foreground text-xs">{{ t('concierge.visits.show.fields.authorized_at') }}</p>
          <p class="font-medium">{{ formatDateTime(visit.authorized_at) }}</p>
        </div>
        <div v-if="visit.checked_in_at">
          <p class="text-muted-foreground text-xs">{{ t('concierge.visits.show.fields.checked_in_at') }}</p>
          <p class="font-medium">{{ formatDateTime(visit.checked_in_at) }}</p>
        </div>
        <div v-if="visit.checked_out_at">
          <p class="text-muted-foreground text-xs">{{ t('concierge.visits.show.fields.checked_out_at') }}</p>
          <p class="font-medium">{{ formatDateTime(visit.checked_out_at) }}</p>
        </div>
      </CardContent>
    </Card>

    <div class="mt-4">
      <Link href="/concierge/visits">
        <Button variant="outline">{{ t('concierge.visits.show.back_to_list') }}</Button>
      </Link>
    </div>

    <VisitCheckInDrawer
      v-model:open="checkInOpen"
      :visit="visit"
      return-to="detail"
      @success="reloadVisit"
    />
    <VisitCheckOutDrawer
      v-model:open="checkOutOpen"
      :visit="visit"
      return-to="detail"
      @success="reloadVisit"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { Link, router } from '@inertiajs/vue3'
import { useI18n } from 'vue-i18n'
import Header from '@/components/admin/layout/Header.vue'
import VisitStatusBadge from '@/components/concierge/visits/VisitStatusBadge.vue'
import VisitActionsDropdown from '@/components/concierge/visits/VisitActionsDropdown.vue'
import VisitCheckInDrawer from '@/components/concierge/visits/VisitCheckInDrawer.vue'
import VisitCheckOutDrawer from '@/components/concierge/visits/VisitCheckOutDrawer.vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import type { ConciergeVisitSummary } from '@/types/visit'
import type { BreadcrumbItem } from '@/types/layout'

const props = defineProps<{
  visit: ConciergeVisitSummary
}>()

const { t, locale } = useI18n()
const checkInOpen = ref(false)
const checkOutOpen = ref(false)

const itemsBreadcrumb = computed<BreadcrumbItem[]>(() => [
  { label: t('admin.sidebar.home'), href: '/admin/home/index' },
  { label: t('concierge.visits.index.title'), href: '/concierge/visits' },
  { label: props.visit.visitor?.display_name ?? t('concierge.visits.show.title') },
])

function formatDateTime(value: string | null | undefined) {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value

  return new Intl.DateTimeFormat(locale.value, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(date)
}

function openCheckIn() {
  checkInOpen.value = true
}

function openCheckOut() {
  checkOutOpen.value = true
}

function reloadVisit() {
  router.reload({ only: ['visit'] })
}
</script>
