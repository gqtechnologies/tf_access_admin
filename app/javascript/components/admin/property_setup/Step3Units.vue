<template>
  <div class="space-y-5">
    <div class="bg-muted flex flex-wrap items-center gap-x-3 gap-y-1 rounded-md px-3 py-2 text-sm">
      <span class="flex items-center gap-1.5 font-medium">
        <Building2 class="size-3.5 shrink-0" />
        {{ property?.name }}
      </span>
      <template v-if="towerCount">
        <span class="text-muted-foreground" aria-hidden="true">|</span>
        <span class="text-muted-foreground flex items-center gap-1.5">
          <Building class="size-3.5 shrink-0" />
          {{ t('admin.property_setup.step3.context.towers', { count: towerCount }) }}
        </span>
      </template>
      <template v-if="floorCount">
        <span class="text-muted-foreground" aria-hidden="true">|</span>
        <span class="text-muted-foreground flex items-center gap-1.5">
          <Layers class="size-3.5 shrink-0" />
          {{ t('admin.property_setup.step3.context.floors', { count: floorCount }) }}
        </span>
      </template>
    </div>

    <div class="space-y-5">
        <div class="space-y-3">
          <p class="text-muted-foreground text-sm">{{ t('admin.property_setup.step3.description') }}</p>

          <div class="grid gap-3 md:grid-cols-2">
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
        </div>

        <section v-if="selectedMode === 'automatic'" class="space-y-4 rounded-lg border p-4">
          <h3 class="text-sm font-medium">{{ t('admin.property_setup.step3.automatic.title') }}</h3>
          <div class="grid gap-4 md:grid-cols-2">
            <Field :data-invalid="!!fieldError('unit_generation.unit_type')">
              <FieldLabel>{{ t('admin.property_setup.step3.automatic.unit_type') }}</FieldLabel>
              <select
                v-model="autoForm.unit_type"
                class="border-input bg-background flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                :aria-invalid="!!fieldError('unit_generation.unit_type')"
              >
                <option v-for="type in unitTypes" :key="type" :value="type">
                  {{ t(`admin.units.unit_types.${type}`) }}
                </option>
              </select>
              <FieldError
                v-if="fieldError('unit_generation.unit_type')"
                :errors="translateErrors([fieldError('unit_generation.unit_type')])"
              />
            </Field>
            <Field :data-invalid="!!fieldError('unit_generation.identifier_format')">
              <FieldLabel>{{ t('admin.property_setup.step3.automatic.identifier_format') }}</FieldLabel>
              <select
                v-model="autoForm.identifier_format"
                class="border-input bg-background flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                :aria-invalid="!!fieldError('unit_generation.identifier_format')"
              >
                <option value="floor_sequential">
                  {{ t('admin.property_setup.step3.automatic.formats.floor_sequential') }}
                </option>
                <option value="sequential">
                  {{ t('admin.property_setup.step3.automatic.formats.sequential') }}
                </option>
              </select>
              <FieldError
                v-if="fieldError('unit_generation.identifier_format')"
                :errors="translateErrors([fieldError('unit_generation.identifier_format')])"
              />
            </Field>
            <Field>
              <FieldLabel>{{ t('admin.property_setup.step3.automatic.example') }}</FieldLabel>
              <Input :model-value="exampleIdentifiers" readonly class="bg-muted" />
            </Field>
            <Field :data-invalid="!!fieldError('unit_generation.quantity_per_floor')">
              <FieldLabel>{{ t('admin.property_setup.step3.automatic.quantity_per_floor') }}</FieldLabel>
              <Input
                v-model.number="autoForm.quantity_per_floor"
                type="number"
                min="1"
                :aria-invalid="!!fieldError('unit_generation.quantity_per_floor')"
              />
              <FieldError
                v-if="fieldError('unit_generation.quantity_per_floor')"
                :errors="translateErrors([fieldError('unit_generation.quantity_per_floor')])"
              />
            </Field>
          </div>
          <div class="flex items-center justify-between gap-3 rounded-md border px-3 py-2.5 text-sm">
            <div>
              <p class="font-medium">{{ t('admin.property_setup.step3.automatic.parking.title') }}</p>
              <p class="text-muted-foreground text-xs">{{ t('admin.property_setup.step3.automatic.parking.hint') }}</p>
            </div>
            <span
              class="bg-muted relative inline-flex h-5 w-9 shrink-0 cursor-not-allowed rounded-full opacity-50"
              aria-hidden="true"
            >
              <span class="bg-background absolute top-0.5 left-0.5 size-4 rounded-full border shadow-sm" />
            </span>
          </div>
        </section>

        <section v-else-if="selectedMode === 'import' && propertyId" class="space-y-3 rounded-lg border p-4">
          <p class="text-muted-foreground text-sm">{{ t('admin.property_setup.step3.import.description') }}</p>
          <Button variant="outline" @click="importOpen = true">
            {{ t('admin.property_setup.step3.import.open') }}
          </Button>
          <BulkUnitsImportDrawer
            v-model:open="importOpen"
            :property-name="String(property?.name ?? '')"
            :residential-property-id="propertyId"
            property-section-id=""
            :section-tree="sectionTree"
            :selected-section="null"
          />
        </section>

        <div v-if="issues.length || fieldError('units_mode')" class="space-y-2">
          <p v-if="fieldError('units_mode')" class="text-destructive text-sm">
            {{ translateErrors([fieldError('units_mode')])[0] }}
          </p>
          <p v-for="issue in issues" :key="issue" class="text-destructive text-sm">{{ issue }}</p>
        </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { Building, Building2, FileSpreadsheet, Layers, Sparkles } from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Field, FieldError, FieldLabel } from '@/components/ui/field'
import BulkUnitsImportDrawer from '@/components/admin/bulk_units/BulkUnitsImportDrawer.vue'
import { useTranslateErrors } from '@/lib/composables/i18n/translate_errors'
import { usePropertySetupStepValidation } from '@/lib/composables/property_setup/usePropertySetupStepValidation'
import type { PropertySetupStep3Values } from '@/lib/schemas/property_setup'
import { buildTreeWithUnits, buildUnitsPreviewFromTree, countUnitsPreviewGroups } from '@/lib/property_setup/unitsPreview'

const props = defineProps<{
  property: Record<string, unknown> | null
  wizard: Record<string, unknown>
  unitTypes: string[]
  preview: Record<string, any>
  errors?: Record<string, string[]>
}>()

const { t } = useI18n()
const { translateErrors } = useTranslateErrors()
const { fieldError, validateStep3, setFieldErrors } = usePropertySetupStepValidation()
const importOpen = ref(false)
const selectedMode = ref((props.wizard.units_mode as string) || 'automatic')
const autoForm = reactive({
  unit_type: 'apartment',
  identifier_format: 'floor_sequential',
  quantity_per_floor: 4,
})

watch(
  () => props.wizard.units_mode,
  (mode) => {
    if (mode) selectedMode.value = mode as string
  },
)

watch(
  () => props.errors,
  (errors) => {
    if (!errors) return
    const mapped = Object.fromEntries(
      Object.entries(errors).map(([key, messages]) => [key, messages[0]]),
    )
    setFieldErrors(mapped)
  },
  { immediate: true, deep: true },
)

const propertyId = computed(() => props.property?.id as string | undefined)
const towerCount = computed(() => props.preview?.counts?.towers ?? 0)
const floorCount = computed(() => props.preview?.counts?.floors ?? 0)
const sectionTree = computed(() => props.preview?.structure?.tree ?? [])

const exampleIdentifiers = computed(() => {
  const qty = Math.max(autoForm.quantity_per_floor, 1)
  if (autoForm.identifier_format === 'floor_sequential') {
    return Array.from({ length: qty }, (_, index) => 101 + index).join(', ')
  }
  return Array.from({ length: qty }, (_, index) => index + 1).join(', ')
})

const previewParams = computed(() => ({
  unit_type: autoForm.unit_type,
  identifier_format: autoForm.identifier_format,
  quantity_per_floor: autoForm.quantity_per_floor,
}))

const isAutomaticMode = computed(() => selectedMode.value === 'automatic')

const attempted = ref(false)

const issues = computed(() => {
  const list: string[] = []
  if (props.errors) {
    Object.values(props.errors).forEach((messages) => list.push(...messages))
  }
  // Proactive server blocking errors (e.g. "no units yet") are only surfaced
  // after the user tries to continue, not on first render.
  if (attempted.value && props.preview?.blocking_errors?.length) {
    list.push(...props.preview.blocking_errors)
  }
  if (props.preview?.warnings?.length) list.push(...props.preview.warnings)
  return list
})

const modes = computed(() => [
  {
    id: 'automatic',
    icon: Sparkles,
    label: t('admin.property_setup.step3.modes.automatic.title'),
    description: t('admin.property_setup.step3.modes.automatic.description'),
  },
  {
    id: 'import',
    icon: FileSpreadsheet,
    label: t('admin.property_setup.step3.modes.import.title'),
    description: t('admin.property_setup.step3.modes.import.description'),
  },
])

const estimatedUnitsCount = computed(() => {
  if (selectedMode.value !== 'automatic') return null
  const groups = buildUnitsPreviewFromTree(
    sectionTree.value,
    previewParams.value,
  )
  return countUnitsPreviewGroups(groups)
})

function getValues() {
  if (selectedMode.value === 'automatic') {
    return {
      units_mode: selectedMode.value,
      unit_generation: { ...autoForm },
    }
  }

  return {
    units_mode: selectedMode.value,
    unit_generation: {
      unit_type: autoForm.unit_type,
      quantity_per_floor: autoForm.quantity_per_floor,
    },
  }
}

function validate() {
  attempted.value = true
  return validateStep3(getValues() as PropertySetupStep3Values)
}

const clientPreviewTree = computed(() => {
  if (selectedMode.value !== 'automatic') return undefined
  return buildTreeWithUnits(sectionTree.value, previewParams.value)
})

defineExpose({ getValues, previewParams, isAutomaticMode, validate, estimatedUnitsCount, clientPreviewTree })
</script>
