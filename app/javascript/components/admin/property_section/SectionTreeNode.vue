<template>
  <li class="relative list-none">
    <Collapsible
      :open="isOpen"
      class="w-full"
      @update:open="(value) => emit('toggle-expand', node.id, value)"
    >
      <div
        class="group relative z-10 flex min-h-10 items-center gap-1 rounded-lg pr-1 transition-colors"
        :class="[
          isSelected ? 'bg-primary/10 text-primary' : 'hover:bg-muted/50',
          node.disabled ? 'opacity-70' : '',
        ]"
      >
        <CollapsibleTrigger v-if="hasChildren" as-child @click.stop>
          <Button
            type="button"
            variant="ghost"
            size="icon"
            class="size-7 shrink-0 text-muted-foreground hover:bg-transparent hover:text-foreground"
            :aria-expanded="isOpen"
            :aria-label="
              isOpen
                ? t('admin.residential_properties.structure.tree.collapse')
                : t('admin.residential_properties.structure.tree.expand')
            "
          >
            <ChevronRight
              class="size-4 shrink-0 transition-transform duration-200"
              :class="{ 'rotate-90': isOpen }"
            />
          </Button>
        </CollapsibleTrigger>

        <span v-else class="flex size-7 shrink-0 items-center justify-center" aria-hidden="true" />

        <button
          type="button"
          class="flex min-w-0 flex-1 items-center gap-2 rounded-md py-1.5 pr-1 text-left outline-none focus-visible:ring-2 focus-visible:ring-ring"
          @click="emit('select', node)"
        >
          <div
            class="flex size-8 shrink-0 items-center justify-center rounded-md border border-border/60 bg-muted/50"
            :class="isSelected ? 'border-primary/25 bg-primary/10' : ''"
          >
            <component
              :is="iconFor(node.section_type)"
              class="size-4"
              :class="isSelected ? 'text-primary' : 'text-muted-foreground'"
            />
          </div>

          <span class="min-w-0 flex-1">
            <span
              class="block truncate text-sm font-medium"
              :class="isSelected ? 'text-primary' : ''"
            >
              {{ node.name }}
            </span>
            <span class="mt-0.5 flex flex-wrap items-center gap-1.5">
              <SectionStatusBadge :status="node.effective_status" />
              <span
                v-if="node.status !== node.effective_status"
                class="text-muted-foreground text-xs"
              >
                ({{
                  t('admin.residential_properties.structure.tree.persisted_status', {
                    status: t(`admin.property_sections.statuses.${node.status}`),
                  })
                }})
              </span>
            </span>
          </span>
        </button>

        <DropdownMenu v-if="showActionsMenu">
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
            <DropdownMenuItem
              v-if="node.permissions.add_child && !node.disabled"
              @click="emit('add-subsection', node.id)"
            >
              <Plus class="size-4" />
              {{ t('admin.residential_properties.structure.tree.add_subsection') }}
            </DropdownMenuItem>

            <DropdownMenuItem v-if="node.permissions.edit && !node.disabled" @click="emit('edit', node)">
              <Pencil class="size-4" />
              {{ t('common.actions.edit') }}
            </DropdownMenuItem>

            <DropdownMenuItem v-if="node.permissions.move && !node.disabled" @click="emit('move', node)">
              <ArrowRightLeft class="size-4" />
              {{ t('admin.residential_properties.structure.move.action') }}
            </DropdownMenuItem>

            <DropdownMenuSeparator v-if="node.permissions.archive" />

            <DropdownMenuItem
              v-if="node.permissions.archive"
              class="text-destructive focus:text-destructive"
              @click="emit('archive', node)"
            >
              <ArchiveIcon class="size-4" />
              {{ t('admin.residential_properties.structure.archive.action') }}
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>

      <CollapsibleContent v-if="hasChildren">
        <ul
          class="relative m-0 ml-3.5 mt-0.5 list-none space-y-0.5 border-l border-border/80 py-0.5 pl-3"
        >
          <SectionTreeNode
            v-for="(child, index) in visibleChildren"
            :key="child.id"
            :node="child"
            :depth="depth + 1"
            :is-last="index === visibleChildren.length - 1 && (node.units?.length ?? 0) === 0"
            :selected-id="selectedId"
            :is-expanded="isChildExpanded"
            :force-expanded="forceExpanded"
            :residential-property-id="residentialPropertyId"
            @select="emit('select', $event)"
            @add-subsection="emit('add-subsection', $event)"
            @edit="emit('edit', $event)"
            @move="emit('move', $event)"
            @archive="emit('archive', $event)"
            @toggle-expand="(nodeId, open) => emit('toggle-expand', nodeId, open)"
          />
          <SectionTreeUnit
            v-for="unit in node.units ?? []"
            :key="unit.id"
            :unit="unit"
            :residential-property-id="residentialPropertyId"
            :selected-id="selectedId"
          />
        </ul>
      </CollapsibleContent>
    </Collapsible>
  </li>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import {
  ArchiveIcon,
  ArrowRightLeft,
  ChevronRight,
  MoreVertical,
  Pencil,
  Plus,
} from 'lucide-vue-next'
import SectionStatusBadge from '@/components/admin/property_section/SectionStatusBadge.vue'
import SectionTreeUnit from '@/components/admin/property_section/SectionTreeUnit.vue'
import { Button } from '@/components/ui/button'
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from '@/components/ui/collapsible'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { PROPERTY_SECTION_MAX_DEPTH } from '@/lib/composables/property_section/usePropertySectionTree'
import { useSectionTypeIcon } from '@/lib/composables/property_section/useSectionTypeIcon'
import type { PropertySectionTreeNode } from '@/types/property_section'

defineOptions({ name: 'SectionTreeNode' })

const props = withDefaults(
  defineProps<{
    node: PropertySectionTreeNode
    depth: number
    isLast?: boolean
    selectedId?: string | null
    isExpanded?: (nodeId: string) => boolean
    forceExpanded?: boolean
    residentialPropertyId: string
  }>(),
  {
    isLast: false,
    selectedId: null,
    isExpanded: () => true,
    forceExpanded: false,
    residentialPropertyId: '',
  },
)

const emit = defineEmits<{
  (e: 'select', node: PropertySectionTreeNode): void
  (e: 'add-subsection', parentId: string): void
  (e: 'edit', node: PropertySectionTreeNode): void
  (e: 'move', node: PropertySectionTreeNode): void
  (e: 'archive', node: PropertySectionTreeNode): void
  (e: 'toggle-expand', nodeId: string, open: boolean): void
}>()

const { t } = useI18n()
const { iconFor } = useSectionTypeIcon()

const visibleChildren = computed(() =>
  props.depth >= PROPERTY_SECTION_MAX_DEPTH - 1 ? [] : props.node.children,
)

const hasChildren = computed(
  () => visibleChildren.value.length > 0 || (props.node.units?.length ?? 0) > 0,
)
const isSelected = computed(() => props.selectedId === props.node.id)
const isOpen = computed(() => props.forceExpanded || props.isExpanded(props.node.id))
const isChildExpanded = props.isExpanded
const showActionsMenu = computed(() => {
  const p = props.node.permissions
  return p.add_child || p.edit || p.move || p.archive
})
</script>
