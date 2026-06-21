<template>
  <div class="space-y-6">
    <div class="space-y-1">
      <h3 class="text-base font-semibold">{{ t('admin.visits.new.general.title') }}</h3>
      <p class="text-sm text-muted-foreground">{{ t('admin.visits.new.general.description') }}</p>
    </div>

    <FieldGroup class="grid gap-4 md:grid-cols-2">
      <Field>
        <FieldLabel for="visit-property">{{ t('admin.visits.new.general.fields.property') }}</FieldLabel>
        <NativeSelect
          id="visit-property"
          v-model="form.residential_property_id"
          class="w-full"
          :disabled="lockPropertyUnit"
          :aria-invalid="!!fieldErrors.residential_property_id"
        >
          <NativeSelectOption value="">
            {{ t('admin.visits.new.general.placeholders.property') }}
          </NativeSelectOption>
          <NativeSelectOption v-for="property in properties" :key="property.id" :value="property.id">
            {{ property.name }}
          </NativeSelectOption>
        </NativeSelect>
        <FieldError
          v-if="fieldErrors.residential_property_id"
          :errors="translateErrors([fieldErrors.residential_property_id])"
        />
      </Field>

      <Field>
        <FieldLabel for="visit-unit">{{ t('admin.visits.new.general.fields.unit') }}</FieldLabel>
        <NativeSelect
          id="visit-unit"
          v-model="form.unit_id"
          class="w-full"
          :disabled="lockPropertyUnit || !form.residential_property_id || unitsLoading"
          :aria-invalid="!!fieldErrors.unit_id"
        >
          <NativeSelectOption value="">
            {{
              unitsLoading
                ? t('admin.visits.new.general.loading.units')
                : t('admin.visits.new.general.placeholders.unit')
            }}
          </NativeSelectOption>
          <NativeSelectOption v-for="unit in units" :key="unit.id" :value="unit.id">
            {{ unit.display_name ?? unit.identifier }}
          </NativeSelectOption>
        </NativeSelect>
        <FieldError v-if="fieldErrors.unit_id" :errors="translateErrors([fieldErrors.unit_id])" />
        <p
          v-else-if="form.residential_property_id && !unitsLoading && units.length === 0"
          class="text-xs text-muted-foreground"
        >
          {{ t('admin.visits.new.general.empty.units') }}
        </p>
      </Field>

      <Field class="md:col-span-2">
        <FieldLabel for="visit-host">{{ t('admin.visits.new.general.fields.host') }}</FieldLabel>
        <NativeSelect
          id="visit-host"
          v-model="form.host_person_id"
          class="w-full"
          :disabled="!form.unit_id || hostsLoading"
          :aria-invalid="!!fieldErrors.host_person_id"
        >
          <NativeSelectOption value="">
            {{
              hostsLoading
                ? t('admin.visits.new.general.loading.hosts')
                : t('admin.visits.new.general.placeholders.host')
            }}
          </NativeSelectOption>
          <NativeSelectOption v-for="host in hosts" :key="host.id" :value="host.id">
            {{ host.display_name }}
            <template v-if="host.document_number"> · {{ host.document_number }}</template>
          </NativeSelectOption>
        </NativeSelect>
        <FieldError
          v-if="fieldErrors.host_person_id"
          :errors="translateErrors([fieldErrors.host_person_id])"
        />
        <p
          v-else-if="form.unit_id && !hostsLoading && hosts.length === 0"
          class="text-xs text-muted-foreground"
        >
          {{ t('admin.visits.new.general.empty.hosts') }}
        </p>
      </Field>
    </FieldGroup>
  </div>
</template>

<script setup lang="ts">
import { computed, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { Field, FieldError, FieldGroup, FieldLabel } from '@/components/ui/field'
import { NativeSelect, NativeSelectOption } from '@/components/ui/native-select'
import { useTranslateErrors } from '@/lib/composables/i18n/translate_errors'
import type { VisitCreateForm, VisitHostOption } from '@/lib/schemas/visit_create'
import type { PropertySummary, UnitFilterOption } from '@/types/visit'

const form = defineModel<VisitCreateForm>('form', { required: true })

const props = defineProps<{
  properties: PropertySummary[]
  units: UnitFilterOption[]
  hosts: VisitHostOption[]
  unitsLoading?: boolean
  hostsLoading?: boolean
  fieldErrors?: Record<string, string | undefined>
  lockPropertyUnit?: boolean
}>()

const emit = defineEmits<{
  (e: 'property-change', propertyId: string): void
  (e: 'unit-change', unitId: string): void
}>()

const { t } = useI18n()
const { translateErrors } = useTranslateErrors()
const fieldErrors = computed(() => props.fieldErrors ?? {})
const lockPropertyUnit = computed(() => props.lockPropertyUnit ?? false)

watch(
  () => form.value.residential_property_id,
  (propertyId, previousPropertyId) => {
    if (lockPropertyUnit.value) return
    if (propertyId === previousPropertyId) return
    form.value.unit_id = ''
    form.value.host_person_id = ''
    emit('property-change', String(propertyId ?? ''))
  },
)

watch(
  () => form.value.unit_id,
  (unitId, previousUnitId) => {
    if (lockPropertyUnit.value) return
    if (unitId === previousUnitId) return
    form.value.host_person_id = ''
    emit('unit-change', String(unitId ?? ''))
  },
)
</script>
