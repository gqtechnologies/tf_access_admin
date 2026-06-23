<template>
  <Card class="flex h-full flex-col gap-2">
    <CardHeader class="space-y-4 pb-4">
      <div class="flex items-center justify-between gap-2">
        <CardTitle class="text-base">
          {{ t('admin.residential_properties.structure.tree.title') }}
        </CardTitle>
        <Button
          v-if="canCreateRoot"
          type="button"
          size="sm"
          variant="outline"
          @click="emit('add-root')"
        >
          <Plus class="mr-1 size-4" />
          {{ t('admin.residential_properties.structure.tree.add_root') }}
        </Button>
      </div>
      <div class="relative">
        <Search class="absolute top-2.5 left-2.5 size-4 text-muted-foreground" />
        <Input
          :model-value="search"
          type="search"
          class="pl-8"
          :placeholder="t('admin.residential_properties.structure.tree.search_placeholder')"
          @update:model-value="emit('update:search', String($event))"
        />
      </div>
    </CardHeader>
    <CardContent class="flex-1 space-y-4 overflow-y-auto overflow-x-visible">
      <div class="flex h-12 items-center gap-2 rounded-lg border bg-muted/20 px-3 py-2">
        <Building2 class="size-4 text-primary" />
        <span class="min-w-0 flex-1 truncate text-sm font-medium">{{ propertyName }}</span>
        <Badge variant="secondary" class="rounded-md border-primary/20 text-primary/80">
          {{ t('admin.residential_properties.structure.tree.root_badge') }}
        </Badge>
        <PropertyStatusBadge v-if="propertyStatus" :status="propertyStatus" />
      </div>

      <div v-if="loading" class="flex items-center justify-center py-10">
        <Loader2 class="text-muted-foreground size-8 animate-spin" />
      </div>

      <Empty v-else-if="!hasSections" class="border-0 py-10">
        <EmptyHeader>
          <EmptyMedia
            variant="default"
            class="relative mb-2 flex size-32 items-center justify-center rounded-md bg-muted text-foreground"
          >
            <Building2 class="size-16" />
          </EmptyMedia>
          <EmptyTitle>{{ t('admin.residential_properties.structure.tree.empty_title') }}</EmptyTitle>
          <EmptyDescription>
            {{ emptyDescription }}
          </EmptyDescription>
        </EmptyHeader>
        <Button v-if="canCreateRoot" class="mt-4" @click="emit('add-root')">
          <Plus class="mr-1 size-4" />
          {{ t('admin.residential_properties.structure.tree.add_root') }}
        </Button>
      </Empty>

      <p
        v-else-if="filteredTree.length === 0"
        class="py-6 text-center text-sm text-muted-foreground"
      >
        {{ t('admin.residential_properties.structure.tree.search_empty') }}
      </p>

      <ul v-else class="relative m-0 mt-2 list-none space-y-0.5 p-0">
        <SectionTreeNode
          v-for="(node, index) in filteredTree"
          :key="node.id"
          :node="node"
          :depth="0"
          :is-last="index === filteredTree.length - 1"
          :selected-id="selectedId"
          :is-expanded="isExpanded"
          :force-expanded="forceExpanded"
          :residential-property-id="residentialPropertyId"
          @select="emit('select', $event)"
          @add-subsection="emit('add-subsection', $event)"
          @edit="emit('edit', $event)"
          @move="emit('move', $event)"
          @archive="emit('archive', $event)"
          @toggle-expand="(nodeId, open) => emit('toggle-expand', nodeId, open)"
        />
      </ul>
    </CardContent>
  </Card>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { Building2, Loader2, Plus, Search } from 'lucide-vue-next'
import PropertyStatusBadge from '@/components/admin/residential_property/PropertyStatusBadge.vue'
import SectionTreeNode from '@/components/admin/property_section/SectionTreeNode.vue'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from '@/components/ui/empty'
import type { PropertySectionTreeNode } from '@/types/property_section'

const props = defineProps<{
  propertyName: string
  propertyStatus?: string
  residentialPropertyId: string
  filteredTree: PropertySectionTreeNode[]
  hasSections: boolean
  selectedId?: string | null
  search: string
  forceExpanded: boolean
  isExpanded: (nodeId: string) => boolean
  canCreateRoot: boolean
  loading?: boolean
  readOnly?: boolean
}>()

const emit = defineEmits<{
  (e: 'update:search', value: string): void
  (e: 'add-root'): void
  (e: 'select', node: PropertySectionTreeNode): void
  (e: 'add-subsection', parentId: string): void
  (e: 'edit', node: PropertySectionTreeNode): void
  (e: 'move', node: PropertySectionTreeNode): void
  (e: 'archive', node: PropertySectionTreeNode): void
  (e: 'toggle-expand', nodeId: string, open: boolean): void
}>()

const { t } = useI18n()

const emptyDescription = computed(() =>
  props.readOnly
    ? t('admin.residential_properties.structure.states.empty_read_only')
    : t('admin.residential_properties.structure.tree.empty_description'),
)
</script>
