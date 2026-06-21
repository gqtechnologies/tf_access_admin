<template>
  <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
    <div class="space-y-2">
      <div class="flex flex-wrap items-center gap-3">
        <h2 class="text-xl font-semibold">{{ visitorName }}</h2>
        <VisitStatusBadge :status="visit.status" :label="visit.status_label" />
      </div>
      <p v-if="documentNumber" class="text-muted-foreground text-sm">
        {{ t('admin.visits.show.header.document') }}: {{ documentNumber }}
      </p>
    </div>

    <VisitActionsDropdown
      v-if="hasActions"
      :visit="visit"
      variant="detail"
      hide-view
      @check-in="emit('checkIn', visit)"
      @check-out="emit('checkOut', visit)"
      @success="emit('success')"
    />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import VisitActionsDropdown from '@/components/admin/visits/VisitActionsDropdown.vue'
import VisitStatusBadge from '@/components/concierge/visits/VisitStatusBadge.vue'
import { isFullVisitDetail } from '@/lib/utils/visit_detail'
import type { AdminVisitShowItem } from '@/types/visit'

const props = defineProps<{
  visit: AdminVisitShowItem
}>()

const emit = defineEmits<{
  checkIn: [visit: AdminVisitShowItem]
  checkOut: [visit: AdminVisitShowItem]
  success: []
}>()

const { t } = useI18n()

const visitorName = computed(() => props.visit.visitor?.display_name ?? '—')

const documentNumber = computed(() => {
  if (!isFullVisitDetail(props.visit)) return null
  return props.visit.visitor_detail?.document_number ?? null
})

const hasActions = computed(() => {
  const permissions = props.visit.permissions as Record<string, boolean>
  return Object.entries(permissions).some(
    ([key, allowed]) => allowed && key !== 'show' && key !== 'full_detail' && key !== 'restricted_detail',
  )
})
</script>
