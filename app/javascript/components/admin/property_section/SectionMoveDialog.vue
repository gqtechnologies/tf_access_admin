<template>
  <Sheet :open="open" @update:open="onOpenChange">
    <SheetContent side="right" class="w-full overflow-y-auto sm:max-w-md">
      <SheetHeader>
        <SheetTitle>{{ t('admin.residential_properties.structure.move.title') }}</SheetTitle>
        <SheetDescription>
          {{
            t('admin.residential_properties.structure.move.description', {
              name: node?.name ?? '',
            })
          }}
        </SheetDescription>
      </SheetHeader>

      <form id="form-section-move" class="mt-6 space-y-4" @submit.prevent="onSubmit">
        <Field>
          <FieldLabel for="move-parent">
            {{ t('admin.residential_properties.structure.move.parent_label') }}
          </FieldLabel>
          <select
            id="move-parent"
            v-model="parentSelection"
            class="border-input bg-background flex h-10 w-full rounded-md border px-3 py-2 text-sm"
            :disabled="submitting || !canChooseParent"
          >
            <option value="__root__">
              {{ t('admin.residential_properties.structure.move.root_option') }}
            </option>
            <option
              v-for="option in availableParentOptions"
              :key="option.id"
              :value="option.id"
            >
              {{ option.name }}
            </option>
          </select>
          <p v-if="!canChooseParent" class="text-muted-foreground mt-2 text-xs">
            {{ t('admin.residential_properties.structure.move.nested_root_hint') }}
          </p>
        </Field>

        <Field>
          <FieldLabel for="move-position">
            {{ t('admin.property_sections.input.position.label') }}
          </FieldLabel>
          <Input
            id="move-position"
            v-model="positionInput"
            type="number"
            min="1"
            :placeholder="t('admin.property_sections.input.position.placeholder')"
            :disabled="submitting"
          />
        </Field>
      </form>

      <SheetFooter class="mt-6">
        <Button type="button" variant="outline" :disabled="submitting" @click="onOpenChange(false)">
          {{ t('common.actions.cancel') }}
        </Button>
        <Button type="submit" form="form-section-move" :disabled="submitting || !node">
          <Loader2 v-if="submitting" class="mr-2 size-4 animate-spin" />
          {{ t('admin.residential_properties.structure.move.submit') }}
        </Button>
      </SheetFooter>
    </SheetContent>
  </Sheet>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { Loader2 } from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { Field, FieldLabel } from '@/components/ui/field'
import { Input } from '@/components/ui/input'
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
} from '@/components/ui/sheet'
import {
  canMoveUnderParent,
  nodeHasChildren,
} from '@/lib/composables/property_section/usePropertySectionTree'
import type { PropertySectionMoveSchema } from '@/lib/schemas/property_section_structure'
import type { PropertySectionParentOption, PropertySectionTreeNode } from '@/types/property_section'

const props = defineProps<{
  open: boolean
  node: PropertySectionTreeNode | null
  parentOptions: PropertySectionParentOption[]
  submitting?: boolean
}>()

const emit = defineEmits<{
  (e: 'update:open', value: boolean): void
  (e: 'submit', data: PropertySectionMoveSchema): void
}>()

const { t } = useI18n()

const parentSelection = ref('__root__')
const positionInput = ref('')

const canChooseParent = computed(() => {
  if (!props.node) return false
  if (props.node.depth === 1 && nodeHasChildren(props.node)) return false
  return availableParentOptions.value.length > 0
})

const availableParentOptions = computed(() => {
  if (!props.node) return []
  return props.parentOptions.filter((option) => {
    if (option.id === props.node?.id) return false
    return canMoveUnderParent(props.node!, option.id)
  })
})

watch(
  () => [props.open, props.node?.id] as const,
  ([isOpen]) => {
    if (!isOpen || !props.node) return
    parentSelection.value = props.node.parent_id ?? '__root__'
    positionInput.value = props.node.position?.toString() ?? ''
  },
  { immediate: true },
)

function onOpenChange(value: boolean) {
  emit('update:open', value)
}

function onSubmit() {
  if (!props.node) return

  const parentId =
    parentSelection.value === '__root__' ? undefined : parentSelection.value

  if (parentId && !canMoveUnderParent(props.node, parentId)) return

  const positionRaw = positionInput.value.trim()
  const position = positionRaw ? Number(positionRaw) : undefined

  emit('submit', {
    parent_id: parentId,
    position: Number.isNaN(position) ? undefined : position,
  })
}
</script>
