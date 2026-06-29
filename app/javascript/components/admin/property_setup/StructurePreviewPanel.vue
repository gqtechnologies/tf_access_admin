<template>
  <Card class="flex max-h-[calc(100vh-12rem)] flex-col">
    <CardHeader class="shrink-0 space-y-1 pb-3">
      <CardTitle class="text-base">{{ t('admin.property_setup.step2.preview.title') }}</CardTitle>
      <p class="text-muted-foreground text-xs">{{ t('admin.property_setup.step2.preview.subtitle') }}</p>
    </CardHeader>

    <CardContent class="flex min-h-0 flex-1 flex-col gap-4 text-sm">
      <Card class="flex min-h-0 flex-1 flex-col border bg-background shadow-none">
        <CardContent class="min-h-0 flex-1 overflow-y-auto p-3">
          <ul v-if="tree.length" class="space-y-2">
            <StructurePreviewTreeNode
              v-for="node in tree"
              :key="node.id"
              :node="node"
            />
          </ul>
          <p v-else class="text-muted-foreground">{{ placeholder }}</p>
        </CardContent>
      </Card>

      <div v-if="showStats" class="grid shrink-0 grid-cols-3 gap-2 border-t pt-3">
        <div
          v-for="stat in statCards"
          :key="stat.key"
          class="flex flex-col items-center gap-1 rounded-lg border bg-muted/30 px-2 py-2.5 text-center"
        >
          <component :is="stat.icon" class="text-primary size-4" />
          <p class="text-base leading-none font-semibold">{{ stat.value }}</p>
          <p class="text-muted-foreground text-[11px] leading-tight">{{ stat.label }}</p>
        </div>
      </div>
    </CardContent>
  </Card>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { Building2, DoorOpen, Layers } from 'lucide-vue-next'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import StructurePreviewTreeNode from '@/components/admin/property_setup/StructurePreviewTreeNode.vue'
import {
  buildTreeFromPreviewNodes,
  type PreviewNode,
} from '@/lib/property_setup/structurePreview'

type QuickPreview = {
  nodes: PreviewNode[]
  counts: { level_1: number; level_2: number; sections: number }
}

const props = defineProps<{
  preview: Record<string, any>
  structureMode?: string
  quickPreview?: QuickPreview
}>()

const { t } = useI18n()

const isQuickMode = computed(() => props.structureMode === 'quick')

const tree = computed(() => {
  if (isQuickMode.value && props.quickPreview) {
    return buildTreeFromPreviewNodes(props.quickPreview.nodes)
  }

  return props.preview?.structure?.tree ?? []
})

const showStats = computed(() => props.structureMode !== 'none')

const statCards = computed(() => {
  if (isQuickMode.value) {
    const counts = props.quickPreview?.counts ?? { level_1: 0, level_2: 0, sections: 0 }
    return [
      {
        key: 'level_1',
        icon: Building2,
        value: counts.level_1,
        label: t('admin.property_setup.step2.preview.stats.level_1'),
      },
      {
        key: 'level_2',
        icon: Layers,
        value: counts.level_2,
        label: t('admin.property_setup.step2.preview.stats.level_2'),
      },
      {
        key: 'sections',
        icon: DoorOpen,
        value: counts.sections,
        label: t('admin.property_setup.step2.preview.stats.sections'),
      },
    ]
  }

  return [
    {
      key: 'towers',
      icon: Building2,
      value: props.preview?.counts?.towers ?? 0,
      label: t('admin.property_setup.step2.preview.stats.towers'),
    },
    {
      key: 'floors',
      icon: Layers,
      value: props.preview?.counts?.floors ?? 0,
      label: t('admin.property_setup.step2.preview.stats.floors'),
    },
    {
      key: 'sections',
      icon: DoorOpen,
      value: props.preview?.counts?.sections ?? 0,
      label: t('admin.property_setup.step2.preview.stats.sections'),
    },
  ]
})

const placeholder = computed(() => {
  if (props.structureMode === 'none') {
    return t('admin.property_setup.step2.preview.none')
  }

  return t('admin.property_setup.step2.preview.placeholder')
})
</script>
