<template>
  <Card class="flex h-full flex-col gap-2">
    <CardHeader class="space-y-4 pb-4">
      <div class="flex items-center justify-between gap-2">
        <CardTitle class="text-base">
          {{ t('admin.residential_properties.structure.tree.title') }}
        </CardTitle>
      </div>
      <div class="relative">
        <Search class="absolute top-2.5 left-2.5 size-4 text-muted-foreground" />
        <Input
          v-model="searchModel"
          type="search"
          class="pl-8"
          :placeholder="t('admin.residential_properties.structure.tree.search_placeholder')"
        />
      </div>
    </CardHeader>
    <CardContent class="flex-1 space-y-4 overflow-y-auto overflow-x-visible">
      <div class="flex items-center gap-2 rounded-lg h-12 border bg-muted/20 px-3 py-2">
        <Building2 class="size-4 text-primary" />
        <span class="min-w-0 flex-1 truncate text-sm font-medium">{{ propertyName }}</span>
        <Badge variant="secondary" class="rounded-md text-primary/80 border-primary/20">{{ t('admin.residential_properties.structure.tree.root_badge') }}</Badge>
      </div>

      <Empty v-if="!hasSections" class="border-0 py-10">
        <EmptyHeader>
          <EmptyMedia
            variant="default"
            class="relative mb-2 flex size-32 items-center justify-center rounded-md bg-muted text-foreground"
          >
            <Building2 class="size-16" />
          </EmptyMedia>
          <EmptyTitle>{{ t('admin.residential_properties.structure.tree.empty_title') }}</EmptyTitle>
          <EmptyDescription>
            {{ t('admin.residential_properties.structure.tree.empty_description') }}
          </EmptyDescription>
        </EmptyHeader>
      </Empty>

      <p
        v-else-if="filteredTree.length === 0"
        class="py-6 text-center text-sm text-muted-foreground"
      >
        {{ t('admin.residential_properties.structure.tree.search_empty') }}
      </p>

      <ul
        v-else
        class="relative m-0 mt-2 list-none space-y-0.5 p-0"
      >
        <SectionTreeNode
          v-for="(node, index) in filteredTree"
          :key="node.id"
          :node="node"
          :depth="0"
          :is-last="index === filteredTree.length - 1"
          :selected-id="selectedId"
          :residential-property-id="residentialPropertyId"
          :force-expanded="searchModel.trim().length > 0"
          @select="emit('select', $event)"
          @add-subsection="emit('add-subsection', $event)"
          @edit="emit('edit', $event)"
          @delete="emit('delete', $event)"
        />
      </ul>
    </CardContent>
  </Card>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { Building2, Search } from 'lucide-vue-next'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from '@/components/ui/empty'
import SectionTreeNode from '@/components/admin/property_section/SectionTreeNode.vue'
import { usePropertySectionTree } from '@/lib/composables/property_section/usePropertySectionTree'
import type { PropertySectionTreeNode } from '@/types/property_section'

const props = defineProps<{
  propertyName: string
  residentialPropertyId: string
  tree: PropertySectionTreeNode[]
  selectedId?: string | null
  search: string
}>()

const emit = defineEmits<{
  (e: 'update:search', value: string): void
  (e: 'add-root'): void
  (e: 'select', node: PropertySectionTreeNode): void
  (e: 'add-subsection', parentId: string): void
  (e: 'edit', node: PropertySectionTreeNode): void
  (e: 'delete', node: PropertySectionTreeNode): void
}>()

const { t } = useI18n()

const searchModel = computed({
  get: () => props.search,
  set: (value: string) => emit('update:search', value),
})

const treeRef = computed(() => props.tree)
const searchRef = computed(() => props.search)
const { filteredTree, hasSections } = usePropertySectionTree(treeRef, searchRef)
</script>
