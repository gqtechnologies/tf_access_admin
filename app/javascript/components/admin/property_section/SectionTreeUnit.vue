<template>
  <li class="relative list-none">
    <div
      class="group flex min-h-9 items-center gap-1 rounded-lg py-1 pr-1 text-muted-foreground transition-colors hover:bg-muted/50"
      :class="isSelected ? 'bg-primary/10 text-primary' : ''"
    >
      <span class="flex size-7 shrink-0" aria-hidden="true" />
      <div
        class="flex size-8 shrink-0 items-center justify-center rounded-md border border-border/60 bg-muted/30"
        :class="isSelected ? 'border-primary/25 bg-primary/10' : ''"
      >
        <Home class="size-4" :class="isSelected ? 'text-primary' : ''" />
      </div>
      <span class="min-w-0 flex-1 truncate text-sm" :class="isSelected ? 'font-medium text-primary' : ''">
        {{ label }}
      </span>

      <DropdownMenu>
        <DropdownMenuTrigger as-child>
          <Button
            variant="ghost"
            size="icon"
            class="size-7 shrink-0 opacity-0 transition-opacity group-hover:opacity-100 data-[state=open]:opacity-100"
            @click.stop
          >
            <MoreVertical class="size-4" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuItem as-child>
            <Link :href="manageUnitHref" class="flex items-center gap-2">
              <Settings class="size-4" />
              {{ t('admin.residential_properties.structure.tree.manage_unit') }}
            </Link>
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    </div>
  </li>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { Link } from '@inertiajs/vue3'
import { useI18n } from 'vue-i18n'
import { Home, MoreVertical, Settings } from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { admin_residential_property_unit_path } from '@/routes'
import type { PropertySectionUnitTreeNode } from '@/types/property_section'

const props = defineProps<{
  unit: PropertySectionUnitTreeNode
  residentialPropertyId: string
  selectedId?: string | null
}>()

const { t } = useI18n()

const label = computed(
  () => props.unit.display_name?.trim() || props.unit.identifier
)

const isSelected = computed(() => props.selectedId === props.unit.id)

const manageUnitHref = computed(() =>
  admin_residential_property_unit_path(props.residentialPropertyId, props.unit.id)
)
</script>
