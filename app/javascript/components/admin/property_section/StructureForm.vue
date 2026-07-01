<template>
  <Card class="flex h-full flex-col">
    <CardHeader>
      <div class="flex flex-wrap items-start justify-between gap-3">
        <div>
          <CardTitle class="text-base">
            {{
              isEdit
                ? t('admin.residential_properties.structure.form.edit_title')
                : t('admin.residential_properties.structure.form.new_title')
            }}
          </CardTitle>
          <CardDescription>
            {{
              isEdit
                ? t('admin.residential_properties.structure.form.edit_description')
                : t('admin.residential_properties.structure.form.new_description')
            }}
          </CardDescription>
        </div>
        <SectionStatusBadge v-if="isEdit && editingNode" :status="editingNode.effective_status" />
      </div>
      <p
        v-if="readonlyReason"
        class="text-muted-foreground mt-3 text-sm"
        role="status"
      >
        {{ readonlyReason }}
      </p>
      <div class="space-y-1 w-full flex justify-end">
        <slot name="upload-multiple-units" />
      </div>
    </CardHeader>
    <CardContent class="flex-1 space-y-5 overflow-y-auto">
      <fieldset :disabled="readonly || submitting" class="m-0 border-0 p-0">
        <form id="form-property-section-structure" class="space-y-5" @submit="onSubmit">
          <Field>
            <FieldLabel>{{ t('admin.residential_properties.structure.form.property_label') }}</FieldLabel>
            <div class="flex items-center gap-2 rounded-lg border bg-muted/30 px-3 py-2">
              <Building2 class="size-4 text-primary" />
              <span class="text-sm font-medium">{{ propertyName }}</span>
            </div>
          </Field>

          <template v-if="!isEdit">
            <FieldSet>
              <FieldLegend>{{ t('admin.residential_properties.structure.form.placement_label') }}</FieldLegend>
              <div class="space-y-2">
                <label
                  class="flex cursor-pointer items-start gap-3 rounded-lg border p-3 transition-colors"
                  :class="values.placement === 'root' ? 'border-primary bg-primary/5' : 'hover:bg-muted/40'"
                >
                  <input v-model="placementModel" type="radio" value="root" class="mt-1" />
                  <span class="block text-sm font-medium">
                    {{ t('admin.residential_properties.structure.form.placement_root') }}
                  </span>
                </label>
                <label
                  class="flex cursor-pointer items-start gap-3 rounded-lg border p-3 transition-colors"
                  :class="[
                    values.placement === 'child' ? 'border-primary bg-primary/5' : 'hover:bg-muted/40',
                    { 'pointer-events-none opacity-50': !hasParentOptions },
                  ]"
                >
                  <input
                    v-model="placementModel"
                    type="radio"
                    value="child"
                    class="mt-1"
                    :disabled="!hasParentOptions"
                  />
                  <span>
                    <span class="block text-sm font-medium">
                      {{ t('admin.residential_properties.structure.form.placement_child') }}
                    </span>
                    <span v-if="!hasParentOptions" class="text-xs text-muted-foreground">
                      {{ t('admin.residential_properties.structure.form.no_parents_hint') }}
                    </span>
                  </span>
                </label>
              </div>
            </FieldSet>

            <VeeField v-if="values.placement === 'child'" v-slot="{ field, errors }" name="parent_id">
              <Field :data-invalid="!!errors.length">
                <FieldLabel for="form-structure-parent">
                  {{ t('admin.property_sections.input.parent_id.label') }}
                </FieldLabel>
                <select
                  id="form-structure-parent"
                  v-bind="field"
                  class="border-input bg-background flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  :aria-invalid="!!errors.length"
                >
                  <option value="">
                    {{ t('admin.property_sections.input.parent_id.placeholder') }}
                  </option>
                  <option v-for="option in parentOptions" :key="option.id" :value="option.id">
                    {{ option.name }}
                  </option>
                </select>
                <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
              </Field>
            </VeeField>
          </template>

          <FieldGroup class="flex flex-col gap-4 md:flex-row">
            <VeeField v-slot="{ componentField, errors }" name="name">
              <Field :data-invalid="!!errors.length" class="flex-1">
                <FieldLabel for="form-structure-name">
                  {{ t('admin.property_sections.input.name.label') }}
                </FieldLabel>
                <Input
                  id="form-structure-name"
                  v-bind="componentField"
                  :placeholder="t('admin.property_sections.input.name.placeholder')"
                  :aria-invalid="!!errors.length"
                />
                <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
              </Field>
            </VeeField>
            <VeeField v-slot="{ field, errors }" name="section_type">
              <Field :data-invalid="!!errors.length" class="flex-1">
                <FieldLabel for="form-structure-type">
                  {{ t('admin.property_sections.input.section_type.label') }}
                </FieldLabel>
                <select
                  id="form-structure-type"
                  v-bind="field"
                  class="border-input bg-background flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  :aria-invalid="!!errors.length"
                >
                  <option value="" disabled>
                    {{ t('admin.residential_properties.structure.form.section_type_placeholder') }}
                  </option>
                  <option v-for="st in sectionTypes" :key="st" :value="st">
                    {{ t(`admin.property_sections.section_types.${st}`) }}
                  </option>
                </select>
                <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
              </Field>
            </VeeField>
          </FieldGroup>

          <VeeField v-if="isEdit && showStatusField" v-slot="{ field, errors }" name="status">
            <Field :data-invalid="!!errors.length">
              <FieldLabel for="form-structure-status">
                {{ t('admin.property_sections.input.status.label') }}
              </FieldLabel>
              <select
                id="form-structure-status"
                v-bind="field"
                class="border-input bg-background flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                :aria-invalid="!!errors.length"
              >
                <option v-for="s in EDITABLE_SECTION_STATUSES" :key="s" :value="s">
                  {{ t(`admin.property_sections.statuses.${s}`) }}
                </option>
              </select>
              <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
            </Field>
          </VeeField>

          <Collapsible v-model:open="advancedOpen">
            <CollapsibleTrigger as-child>
              <Button type="button" variant="ghost" class="w-full justify-between px-0 hover:bg-transparent">
                {{ t('admin.residential_properties.structure.form.advanced_title') }}
                <ChevronDown class="size-4 transition-transform" :class="{ 'rotate-180': advancedOpen }" />
              </Button>
            </CollapsibleTrigger>
            <CollapsibleContent class="pt-3">
              <VeeField v-slot="{ componentField, errors }" name="position">
                <Field :data-invalid="!!errors.length">
                  <FieldLabel for="form-structure-position">
                    {{ t('admin.property_sections.input.position.label') }}
                  </FieldLabel>
                  <Input
                    id="form-structure-position"
                    v-bind="componentField"
                    type="number"
                    min="1"
                    :placeholder="t('admin.property_sections.input.position.placeholder')"
                    :aria-invalid="!!errors.length"
                  />
                  <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
                </Field>
              </VeeField>
            </CollapsibleContent>
          </Collapsible>

          <Alert class="border-sky-200 bg-sky-50 text-sky-950 dark:border-sky-900 dark:bg-sky-950/40 dark:text-sky-50">
            <AlertTitle>{{ t('admin.residential_properties.structure.form.preview_title') }}</AlertTitle>
            <AlertDescription class="text-sm">{{ previewPath }}</AlertDescription>
          </Alert>
        </form>
      </fieldset>
    </CardContent>
    <CardFooter v-if="showActions" class="flex flex-col gap-2 sm:flex-row sm:justify-end">
      <Button type="button" variant="outline" class="w-full sm:w-auto" @click="emit('cancel')">
        {{ t('common.actions.cancel') }}
      </Button>
      <Button
        type="submit"
        form="form-property-section-structure"
        class="w-full sm:w-auto"
        :disabled="submitting"
      >
        <Loader2 v-if="submitting" class="mr-2 size-4 animate-spin" />
        {{ submitButtonLabel }}
      </Button>
    </CardFooter>
  </Card>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { toTypedSchema } from '@vee-validate/zod'
import { useForm, Field as VeeField } from 'vee-validate'
import { useI18n } from 'vue-i18n'
import { Building2, ChevronDown, Loader2 } from 'lucide-vue-next'
import SectionStatusBadge from '@/components/admin/property_section/SectionStatusBadge.vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from '@/components/ui/collapsible'
import {
  Field,
  FieldError,
  FieldGroup,
  FieldLabel,
  FieldLegend,
  FieldSet,
} from '@/components/ui/field'
import { Input } from '@/components/ui/input'
import {
  propertySectionStructureCreateSchema,
  propertySectionStructureEditSchema,
  type PropertySectionStructureCreateSchema,
  type PropertySectionStructureEditSchema,
} from '@/lib/schemas/property_section_structure'
import {
  EDITABLE_SECTION_STATUSES,
  SECTION_TYPE_VALUES,
} from '@/lib/schemas/property_section'
import { useTranslateErrors } from '@/lib/composables/i18n/translate_errors'
import { useServerFormErrors } from '@/lib/composables/forms/useServerFormErrors'
import { buildSectionPreviewPath } from '@/lib/composables/property_section/usePropertySectionTree'
import type { PropertySectionParentOption, PropertySectionTreeNode } from '@/types/property_section'

const props = withDefaults(
  defineProps<{
    propertyName: string
    sectionTypes: string[]
    parentOptions: PropertySectionParentOption[]
    mode: 'create' | 'edit'
    editingNode?: PropertySectionTreeNode | null
    initialPlacement?: 'root' | 'child'
    initialParentId?: string | null
    readonly?: boolean
    readonlyReason?: string
    submitting?: boolean
    showActions?: boolean
    serverErrors?: Record<string, string[]>
  }>(),
  {
    editingNode: null,
    readonly: false,
    submitting: false,
    showActions: true,
  },
)

const emit = defineEmits<{
  (
    e: 'submit',
    data: PropertySectionStructureCreateSchema | PropertySectionStructureEditSchema,
  ): void
  (e: 'cancel'): void
}>()

const { t } = useI18n()
const { translateErrors } = useTranslateErrors()
const advancedOpen = ref(false)

const isEdit = computed(() => props.mode === 'edit')
const hasParentOptions = computed(() => props.parentOptions.length > 0)
const showStatusField = computed(
  () => isEdit.value && props.editingNode?.status !== 'archived',
)
const submitButtonLabel = computed(() =>
  props.submitting
    ? t('admin.residential_properties.structure.form.saving')
    : isEdit.value
      ? t('admin.residential_properties.structure.form.submit_edit')
      : t('admin.residential_properties.structure.form.submit_create'),
)

const formSchema = toTypedSchema(
  props.mode === 'edit' ? propertySectionStructureEditSchema : propertySectionStructureCreateSchema,
)

const { handleSubmit, setErrors, resetForm, values, setFieldValue } = useForm({
  validationSchema: formSchema,
  initialValues: buildInitialValues(),
})

const { applyServerErrors } = useServerFormErrors(setErrors)

watch(
  () => props.serverErrors,
  (errors) => {
    if (errors) applyServerErrors(errors)
  },
  { immediate: true, deep: true },
)

const placementModel = computed({
  get: () => values.placement,
  set: (value: 'root' | 'child') => {
    setFieldValue('placement', value)
    if (value === 'root') setFieldValue('parent_id', '')
  },
})

const previewPath = computed(() => {
  const parentId =
    typeof values.parent_id === 'string' && values.parent_id.length > 0
      ? values.parent_id
      : undefined

  return buildSectionPreviewPath(
    props.propertyName,
    values.placement ?? 'root',
    parentId,
    typeof values.name === 'string' ? values.name : '',
    props.parentOptions,
  )
})

function buildInitialValues() {
  if (isEdit.value) {
    return {
      placement: 'root' as const,
      name: '',
      section_type: SECTION_TYPE_VALUES[0],
      parent_id: '',
      position: undefined as number | undefined,
      status: 'active' as (typeof EDITABLE_SECTION_STATUSES)[number],
    }
  }

  return {
    placement: 'root' as const,
    name: '',
    section_type: SECTION_TYPE_VALUES[0],
    parent_id: '',
    position: undefined as number | undefined,
  }
}

function applyFormIntent() {
  if (isEdit.value && props.editingNode) {
    const node = props.editingNode
    const safeType = (SECTION_TYPE_VALUES as readonly string[]).includes(node.section_type)
      ? (node.section_type as (typeof SECTION_TYPE_VALUES)[number])
      : SECTION_TYPE_VALUES[0]
    const safeStatus =
      node.status === 'archived'
        ? 'inactive'
        : (EDITABLE_SECTION_STATUSES as readonly string[]).includes(node.status)
          ? (node.status as (typeof EDITABLE_SECTION_STATUSES)[number])
          : 'active'

    resetForm({
      values: {
        placement: node.parent_id ? 'child' : 'root',
        name: node.name,
        section_type: safeType,
        parent_id: node.parent_id ?? '',
        position: node.position ?? undefined,
        status: safeStatus,
      },
    })
    return
  }

  const placement = props.initialPlacement ?? 'root'
  resetForm({
    values: {
      placement,
      name: '',
      section_type: SECTION_TYPE_VALUES[0],
      parent_id: placement === 'child' ? (props.initialParentId ?? '') : '',
      position: undefined,
    },
  })
}

watch(
  () => [props.mode, props.editingNode?.id, props.initialPlacement, props.initialParentId] as const,
  () => applyFormIntent(),
  { immediate: true },
)

const onSubmit = handleSubmit((data) => {
  emit('submit', data)
})

defineExpose({ applyServerErrors })
</script>
