<template>
  <div class="group flex min-h-10 items-center gap-1 rounded-lg pr-1 pl-8 transition-colors hover:bg-muted/50">
    <div class="flex size-8 shrink-0 items-center justify-center rounded-md border border-border/60 bg-muted/30">
      <Home class="text-muted-foreground size-4" />
    </div>

    <div class="flex min-w-0 flex-1 items-center gap-2">
      <span class="truncate text-sm font-medium">{{ unit.display_name || unit.identifier }}</span>
      <Badge variant="secondary" class="shrink-0 font-normal">{{ typeLabel }}</Badge>
    </div>

    <DropdownMenu>
      <DropdownMenuTrigger as-child>
        <Button
          variant="ghost"
          size="icon"
          class="size-7 shrink-0 opacity-70 transition-opacity group-hover:opacity-100 data-[state=open]:opacity-100"
          :aria-label="t('admin.property_setup.step3.manual.actions.menu')"
          @click.stop
        >
          <MoreHorizontal class="size-4" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem @select="emit('edit', unit)">
          <Pencil class="size-4" />
          {{ t('admin.property_setup.step3.manual.actions.edit') }}
        </DropdownMenuItem>
        <DropdownMenuSeparator />
        <DropdownMenuItem variant="destructive" @select="emit('delete', unit)">
          <Trash2 class="size-4" />
          {{ t('admin.property_setup.step3.manual.actions.delete') }}
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { Home, MoreHorizontal, Pencil, Trash2 } from 'lucide-vue-next'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'

export type UnitNode = {
  id: string
  identifier: string
  display_name?: string | null
  unit_type: string
  area_m2?: number | null
}

const props = defineProps<{
  unit: UnitNode
}>()

const emit = defineEmits<{
  (e: 'edit', unit: UnitNode): void
  (e: 'delete', unit: UnitNode): void
}>()

const { t } = useI18n()

const typeLabel = computed(() => t(`admin.units.unit_types.${props.unit.unit_type}`))
</script>
