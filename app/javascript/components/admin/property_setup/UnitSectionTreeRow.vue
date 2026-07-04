<template>
  <div class="group flex min-h-10 items-center gap-1 rounded-lg pr-1 transition-colors hover:bg-muted/50">
    <div class="flex size-8 shrink-0 items-center justify-center rounded-md border border-border/60 bg-muted/50">
      <component :is="iconFor(section.section_type)" class="text-muted-foreground size-4" />
    </div>

    <div class="flex min-w-0 flex-1 items-center gap-2">
      <span class="truncate text-sm font-medium">{{ section.name }}</span>
      <Badge variant="secondary" class="shrink-0 font-normal">{{ typeLabel }}</Badge>
      <Badge variant="outline" class="shrink-0 font-normal">
        {{ t('admin.property_setup.step3.manual.unit_count', { count: unitCount }) }}
      </Badge>
    </div>

    <Button
      v-if="eligible"
      type="button"
      variant="ghost"
      size="sm"
      class="shrink-0 opacity-70 transition-opacity group-hover:opacity-100"
      @click="emit('add-unit', section)"
    >
      <Plus class="size-4" />
      {{ t('admin.property_setup.step3.manual.add_unit') }}
    </Button>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { Plus } from 'lucide-vue-next'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { useSectionTypeIcon } from '@/lib/composables/property_section/useSectionTypeIcon'
import type { UnitNode } from '@/components/admin/property_setup/UnitTreeRow.vue'

type SectionNode = {
  id: string
  name: string
  section_type: string
  children?: SectionNode[]
  units?: UnitNode[]
}

const props = defineProps<{
  section: SectionNode
  eligible: boolean
}>()

const emit = defineEmits<{
  (e: 'add-unit', section: SectionNode): void
}>()

const { t } = useI18n()
const { iconFor } = useSectionTypeIcon()

const typeLabel = computed(() => t(`admin.property_sections.section_types.${props.section.section_type}`))
const unitCount = computed(() => props.section.units?.length ?? 0)
</script>
