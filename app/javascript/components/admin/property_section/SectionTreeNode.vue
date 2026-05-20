<template>
  <li class="relative list-none">
    <template v-if="!isRoot">
      <span
        aria-hidden="true"
        class="pointer-events-none absolute -left-6 top-0 border-l border-dashed border-border"
        :class="isLast ? 'h-6' : '-bottom-2'"
      />
      <span
        aria-hidden="true"
        class="pointer-events-none absolute -left-6 top-6 h-3 w-6 rounded-bl-xl border-b border-l border-dashed border-border"
      />
    </template>

    <div
      class="group relative z-10 flex h-12 items-center gap-2 rounded-lg border p-3"
      :class="{
        'border-primary/35 bg-primary/5': selectedId === node.id,
      }"
    >
      <div class="flex h-8 w-8 shrink-0 items-center justify-center rounded-md bg-muted/50">
        <component
          :is="iconFor(node.section_type)"
          class="size-4 text-muted-foreground"
        />
      </div>

      <span class="min-w-0 flex-1 truncate text-sm font-medium">
        {{ node.name }}
      </span>

      <DropdownMenu>
        <DropdownMenuTrigger as-child>
          <Button
            variant="ghost"
            size="icon"
            class="size-7 shrink-0 opacity-0 transition-opacity group-hover:opacity-100 data-[state=open]:opacity-100"
          >
            <MoreVertical class="size-4" />
          </Button>
        </DropdownMenuTrigger>

        <DropdownMenuContent align="end">
          <DropdownMenuItem @click="emit('add-subsection', node.id)">
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

    <ul
      v-if="node.children.length > 0"
      class="relative m-0 ml-2.5 mt-2 list-none space-y-2 pl-6"
    >
      <SectionTreeNode
        v-for="(child, index) in node.children"
        :key="child.id"
        :node="child"
        :depth="depth + 1"
        :is-last="index === node.children.length - 1"
        :selected-id="selectedId"
        @add-subsection="emit('add-subsection', $event)"
        @edit="emit('edit', $event)"
        @delete="emit('delete', $event)"
      />
    </ul>
  </li>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { MoreVertical, Pencil, Plus, Trash2 } from 'lucide-vue-next'

import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'

import { useSectionTypeIcon } from '@/lib/composables/property_section/useSectionTypeIcon'
import type { PropertySectionTreeNode } from '@/types/property_section'

defineOptions({ name: 'SectionTreeNode' })

const props = withDefaults(
  defineProps<{
    node: PropertySectionTreeNode
    depth: number
    isLast?: boolean
    selectedId?: string | null
  }>(),
  {
    isLast: false,
    selectedId: null,
  },
)

const emit = defineEmits<{
  (e: 'add-subsection', parentId: string): void
  (e: 'edit', node: PropertySectionTreeNode): void
  (e: 'delete', node: PropertySectionTreeNode): void
}>()

const { t } = useI18n()
const { iconFor } = useSectionTypeIcon()

const isRoot = computed(() => props.depth === 0)
</script>
