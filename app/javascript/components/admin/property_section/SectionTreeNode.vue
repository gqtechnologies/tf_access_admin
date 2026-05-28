<template>
  <li class="relative list-none">
    <Collapsible v-model:open="isOpen" class="w-full">
      <div
        class="group relative z-10 flex min-h-10 items-center gap-1 rounded-lg pr-1 transition-colors"
        :class="isSelected ? 'bg-primary/10 text-primary' : 'hover:bg-muted/50'"
      >
        <CollapsibleTrigger
          v-if="hasChildren"
          as-child
          @click.stop
        >
          <Button
            type="button"
            variant="ghost"
            size="icon"
            class="size-7 shrink-0 text-muted-foreground hover:text-foreground hover:bg-transparent"
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

        <span
          v-else
          class="flex size-7 shrink-0 items-center justify-center"
          aria-hidden="true"
        >
         
        </span>

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

          <span
            class="min-w-0 flex-1 truncate text-sm font-medium"
            :class="isSelected ? 'text-primary' : ''"
          >
            {{ node.name }}
          </span>
        </button>

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
          <DropdownMenuItem
            v-if="canAddSubsection"
            @click="emit('add-subsection', node.id)"
          >
            <Plus class="size-4" />
            {{ t('admin.residential_properties.structure.tree.add_subsection') }}
          </DropdownMenuItem>

            <DropdownMenuItem @click="emit('edit', node)">
              <Pencil class="size-4" />
              {{ t('common.actions.edit') }}
            </DropdownMenuItem>

            <DropdownMenuSeparator />

            <DropdownMenuItem
              class="text-destructive focus:text-destructive"
              @click="emit('delete', node)"
            >
              <Trash2 class="size-4" />
              {{ t('common.actions.delete') }}
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>

      <CollapsibleContent v-if="hasChildren">
        <ul
          class="relative m-0 ml-3.5 mt-0.5 list-none space-y-0.5 border-l border-border/80 py-0.5 pl-3"
        >
          <SectionTreeNode
            v-for="(child, index) in node.children"
            :key="child.id"
            :node="child"
            :depth="depth + 1"
            :is-last="index === node.children.length - 1 && (node.units?.length ?? 0) === 0"
            :selected-id="selectedId"
            :force-expanded="forceExpanded"
            @select="emit('select', $event)"
            @add-subsection="emit('add-subsection', $event)"
            @edit="emit('edit', $event)"
            @delete="emit('delete', $event)"
          />
          <li
            v-for="(unit, index) in node.units ?? []"
            :key="unit.id"
            class="relative list-none"
          >
            <div
              class="flex min-h-9 items-center gap-2 rounded-lg py-1 pr-1 text-muted-foreground"
              :class="index < node.units.length - 1 ? '' : ''"
            >
              <span class="flex size-7 shrink-0" aria-hidden="true" />
              <div
                class="flex size-8 shrink-0 items-center justify-center rounded-md border border-border/60 bg-muted/30"
              >
                <Home class="size-4" />
              </div>
              <span class="min-w-0 flex-1 truncate text-sm">
                {{ unitLabel(unit) }}
              </span>
            </div>
          </li>
        </ul>
      </CollapsibleContent>
    </Collapsible>
  </li>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { ChevronRight, Home, MoreVertical, Pencil, Plus, Trash2 } from 'lucide-vue-next'

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

import { useSectionTypeIcon } from '@/lib/composables/property_section/useSectionTypeIcon'
import type {
  PropertySectionTreeNode,
  PropertySectionUnitTreeNode,
} from '@/types/property_section'

defineOptions({ name: 'SectionTreeNode' })

const props = withDefaults(
  defineProps<{
    node: PropertySectionTreeNode
    depth: number
    isLast?: boolean
    selectedId?: string | null
    forceExpanded?: boolean
  }>(),
  {
    isLast: false,
    selectedId: null,
    forceExpanded: false,
  },
)

const emit = defineEmits<{
  (e: 'select', node: PropertySectionTreeNode): void
  (e: 'add-subsection', parentId: string): void
  (e: 'edit', node: PropertySectionTreeNode): void
  (e: 'delete', node: PropertySectionTreeNode): void
}>()

const { t } = useI18n()
const { iconFor } = useSectionTypeIcon()

const hasChildren = computed(
  () => props.node.children.length > 0 || (props.node.units?.length ?? 0) > 0,
)
const isSelected = computed(() => props.selectedId === props.node.id)
const canAddSubsection = computed(() => !props.node.parent_id)
const isOpen = ref(true)

function unitLabel(unit: PropertySectionUnitTreeNode) {
  return unit.display_name?.trim() || unit.identifier
}

function nodeContainsId(nodes: PropertySectionTreeNode[], id: string): boolean {
  for (const item of nodes) {
    if (item.id === id) return true
    if (nodeContainsId(item.children, id)) return true
  }
  return false
}

watch(
  () => props.selectedId,
  (id) => {
    if (id && hasChildren.value && nodeContainsId(props.node.children, id)) {
      isOpen.value = true
    }
  },
  { immediate: true },
)

watch(
  () => props.forceExpanded,
  (expanded) => {
    if (expanded && hasChildren.value) {
      isOpen.value = true
    }
  },
)
</script>
