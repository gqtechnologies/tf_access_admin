<template>
  <div class="space-y-5">
    <p class="text-muted-foreground text-sm">{{ t('admin.property_setup.step2.description') }}</p>

    <div class="grid gap-3 md:grid-cols-3">
      <button
        v-for="mode in modes"
        :key="mode.id"
        type="button"
        class="rounded-lg border p-4 text-left transition"
        :class="selectedMode === mode.id ? 'border-primary ring-1 ring-primary' : 'hover:border-muted-foreground/40'"
        @click="selectedMode = mode.id"
      >
        <div class="flex items-start gap-3">
          <component :is="mode.icon" class="text-muted-foreground mt-0.5 size-5 shrink-0" />
          <div class="min-w-0">
            <div class="flex items-center gap-2">
              <span
                class="inline-flex size-4 shrink-0 items-center justify-center rounded-full border"
                :class="selectedMode === mode.id ? 'border-primary' : 'border-muted-foreground/40'"
              >
                <span v-if="selectedMode === mode.id" class="bg-primary size-2 rounded-full" />
              </span>
              <p class="font-medium">{{ mode.label }}</p>
            </div>
            <p class="text-muted-foreground mt-1 pl-6 text-sm">{{ mode.description }}</p>
          </div>
        </div>
      </button>
    </div>

    <div v-if="fieldError('structure') || fieldError('structure_mode')" class="space-y-2">
      <p v-if="fieldError('structure_mode')" class="text-destructive text-sm">
        {{ translateErrors([fieldError('structure_mode')])[0] }}
      </p>
      <p v-if="fieldError('structure')" class="text-destructive text-sm">
        {{ translateErrors([fieldError('structure')])[0] }}
      </p>
      <p v-if="fieldError('quick_structure')" class="text-destructive text-sm">
        {{ translateErrors([fieldError('quick_structure')])[0] }}
      </p>
    </div>

    <section v-if="selectedMode === 'quick'" class="space-y-4 rounded-lg border p-4">
      <h3 class="text-sm font-medium">{{ t('admin.property_setup.step2.quick.title') }}</h3>

      <div class="grid gap-3 md:grid-cols-3">
        <Field v-for="field in quickNumericFields" :key="field.key" :data-invalid="!!fieldError(field.errorKey)">
          <FieldLabel>{{ field.label }}</FieldLabel>
          <Input
            v-model.number="quickStructure[field.key as 'towers' | 'floors_per_tower' | 'units_per_floor']"
            type="number"
            min="1"
            :aria-invalid="!!fieldError(field.errorKey)"
          />
          <FieldError
            v-if="fieldError(field.errorKey)"
            :errors="translateErrors([fieldError(field.errorKey)])"
          />
        </Field>
      </div>

      <div class="grid gap-3 md:grid-cols-2">
        <Field :data-invalid="!!fieldError('quick_structure.tower_prefix')">
          <FieldLabel>{{ t('admin.property_setup.step2.quick.tower_prefix') }}</FieldLabel>
          <Input v-model="quickStructure.tower_prefix" :aria-invalid="!!fieldError('quick_structure.tower_prefix')" />
          <FieldError
            v-if="fieldError('quick_structure.tower_prefix')"
            :errors="translateErrors([fieldError('quick_structure.tower_prefix')])"
          />
        </Field>
        <Field :data-invalid="!!fieldError('quick_structure.floor_prefix')">
          <FieldLabel>{{ t('admin.property_setup.step2.quick.floor_prefix') }}</FieldLabel>
          <Input v-model="quickStructure.floor_prefix" :aria-invalid="!!fieldError('quick_structure.floor_prefix')" />
          <FieldError
            v-if="fieldError('quick_structure.floor_prefix')"
            :errors="translateErrors([fieldError('quick_structure.floor_prefix')])"
          />
        </Field>
      </div>

      <Alert>
        <Info class="size-4" />
        <AlertDescription>{{ t('admin.property_setup.step2.quick.info') }}</AlertDescription>
      </Alert>
    </section>

    <ManualSectionForm
      v-if="selectedMode === 'manual' && propertyId"
      :property-id="propertyId"
      :section-types="sectionTypes"
      :tree="structureTree"
      :selected-mode="selectedMode"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { Box, Info, Layers, Zap } from 'lucide-vue-next'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Input } from '@/components/ui/input'
import { Field, FieldError, FieldLabel } from '@/components/ui/field'
import ManualSectionForm from '@/components/admin/property_setup/ManualSectionForm.vue'
import type { QuickStructureParams } from '@/lib/property_setup/structurePreview'
import { useTranslateErrors } from '@/lib/composables/i18n/translate_errors'
import { usePropertySetupStepValidation } from '@/lib/composables/property_setup/usePropertySetupStepValidation'
import type { PropertySetupStep2Values } from '@/lib/schemas/property_setup'

const props = defineProps<{
  propertyId?: string
  wizard: Record<string, unknown>
  sectionTypes: string[]
  preview: Record<string, any>
}>()

const { t } = useI18n()
const { translateErrors } = useTranslateErrors()
const { fieldError, validateStep2 } = usePropertySetupStepValidation()
const selectedMode = ref((props.wizard.structure_mode as string) || 'none')
const quickStructure = reactive<QuickStructureParams>({
  towers: 2,
  floors_per_tower: 10,
  units_per_floor: 4,
  tower_prefix: 'Torre',
  floor_prefix: 'Piso',
})

watch(
  () => props.wizard.structure_mode,
  (mode) => {
    if (mode) selectedMode.value = mode as string
  },
)

const structureTree = computed(() => props.preview?.structure?.tree ?? [])
const sectionsCount = computed(() => structureTree.value.length)

const modes = computed(() => [
  {
    id: 'none',
    icon: Box,
    label: t('admin.property_setup.step2.modes.none.title'),
    description: t('admin.property_setup.step2.modes.none.description'),
  },
  {
    id: 'manual',
    icon: Layers,
    label: t('admin.property_setup.step2.modes.manual.title'),
    description: t('admin.property_setup.step2.modes.manual.description'),
  },
  {
    id: 'quick',
    icon: Zap,
    label: t('admin.property_setup.step2.modes.quick.title'),
    description: t('admin.property_setup.step2.modes.quick.description'),
  },
])

const quickNumericFields = computed(() => [
  { key: 'towers', label: t('admin.property_setup.step2.quick.towers'), errorKey: 'quick_structure.towers' },
  {
    key: 'floors_per_tower',
    label: t('admin.property_setup.step2.quick.floors_per_tower'),
    errorKey: 'quick_structure.floors_per_tower',
  },
  {
    key: 'units_per_floor',
    label: t('admin.property_setup.step2.quick.units_per_floor'),
    errorKey: 'quick_structure.units_per_floor',
  },
])

const quickStructureSnapshot = computed(() => ({ ...quickStructure }))

const exposedStructureMode = computed(() => selectedMode.value)

function getValues() {
  return {
    structure_mode: selectedMode.value,
    quick_structure_confirmed: selectedMode.value === 'quick',
    quick_structure:
      selectedMode.value === 'quick'
        ? { ...quickStructure }
        : undefined,
  }
}

function validate() {
  return validateStep2(getValues() as PropertySetupStep2Values, sectionsCount.value)
}

defineExpose({
  getValues,
  validate,
  selectedMode: exposedStructureMode,
  quickStructure: quickStructureSnapshot,
})
</script>
