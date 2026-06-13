<template>
  <div class="flex flex-col gap-4">
    <div class="space-y-3 w-full flex justify-between items-center">
      <div class="flex flex-wrap items-center gap-3">
        <h1 class="text-2xl font-bold tracking-tight sm:text-3xl">{{ unit.title }}</h1>
        <Badge :variant="statusBadgeVariant">{{ statusLabel }}</Badge>
      </div>
      <div class="flex items-center gap-2">
        <Button variant="outline" disabled>
          <Pencil class="size-4" />
          {{ t('admin.units.show.actions.edit') }}
        </Button>
        <DropdownMenu>
          <DropdownMenuTrigger as-child>
            <Button variant="outline" size="icon" :aria-label="t('common.table.actions')">
              <MoreVertical class="size-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem disabled>
              {{ t('admin.units.show.actions.more_coming_soon') }}
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </div>
    <div class="w-full flex flex-col lg:flex-row lg:justify-between lg:items-center gap-2">
      <div class="flex flex-col items-start gap-2 text-muted-foreground">
        <span class="text-sm">{{ unitTypeLabel }}</span>
        <span v-if="locationLabel" class="inline-flex items-center gap-1.5 text-xs">
          <Building2 class="size-4 shrink-0" />
          {{ locationLabel }}
        </span>
      </div>
      <UnitSummaryCards :unit="unit" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { Building2, MoreVertical, Pencil } from 'lucide-vue-next'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import type { UnitDetail } from '@/types/unit'
import UnitSummaryCards from './UnitSummaryCards.vue'

const props = defineProps<{
  unit: UnitDetail
}>()

const { t } = useI18n()

const statusLabel = computed(() =>
  t(`admin.residential_properties.structure.bulk_import.preview.unit_statuses.${props.unit.status}`)
)

const statusBadgeVariant = computed(() => {
  if (props.unit.status === 'available') return 'success' as const
  if (props.unit.status === 'inactive') return 'secondary' as const
  return 'outline' as const
})

const unitTypeLabel = computed(() =>
  t(`admin.residential_properties.structure.bulk_import.preview.unit_types.${props.unit.unit_type}`)
)

const locationLabel = computed(() => {
  const segments = [props.unit.residential_property_name, ...props.unit.location_path]
  return segments.filter(Boolean).join(' › ')
})
</script>
