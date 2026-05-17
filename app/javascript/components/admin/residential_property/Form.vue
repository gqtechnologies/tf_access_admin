<template>
  <Card class="w-full">
    <CardHeader>
      <CardTitle v-if="props.title">{{ props.title }}</CardTitle>
      <CardDescription>
        {{ props.description }}
      </CardDescription>
    </CardHeader>
    <CardContent>
      <form id="form-residential-property" @submit="onSubmit">
        <FieldGroup class="flex flex-col md:flex-row">
          <VeeField v-slot="{ componentField, errors }" name="name">
            <Field :data-invalid="!!errors.length">
              <FieldLabel for="form-residential-property-name">
                {{ t('admin.residential_properties.input.name.label') }}
              </FieldLabel>
              <Input
                id="form-residential-property-name"
                v-bind="componentField"
                :placeholder="t('admin.residential_properties.input.name.placeholder')"
                autocomplete="off"
                :aria-invalid="!!errors.length"
              />
              <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
            </Field>
          </VeeField>
          <VeeField v-slot="{ componentField, errors }" name="code">
            <Field :data-invalid="!!errors.length">
              <FieldLabel for="form-residential-property-code">
                {{ t('admin.residential_properties.input.code.label') }}
              </FieldLabel>
              <Input
                id="form-residential-property-code"
                v-bind="componentField"
                :placeholder="t('admin.residential_properties.input.code.placeholder')"
                autocomplete="off"
                :aria-invalid="!!errors.length"
              />
              <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
            </Field>
          </VeeField>
        </FieldGroup>
        <FieldGroup class="mt-4 flex flex-col md:flex-row">
          <VeeField v-slot="{ field, errors }" name="property_type">
            <Field :data-invalid="!!errors.length">
              <FieldLabel for="form-residential-property-property-type">
                {{ t('admin.residential_properties.input.property_type.label') }}
              </FieldLabel>
              <select
                id="form-residential-property-property-type"
                v-bind="field"
                class="border-input bg-background ring-offset-background placeholder:text-muted-foreground focus-visible:ring-ring flex h-10 w-full rounded-md border px-3 py-2 text-sm focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:outline-none disabled:cursor-not-allowed disabled:opacity-50"
                :aria-invalid="!!errors.length"
              >
                <option v-for="pt in props.propertyTypes" :key="pt" :value="pt">
                  {{ t(`admin.residential_properties.property_types.${pt}`) }}
                </option>
              </select>
              <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
            </Field>
          </VeeField>
          <VeeField v-slot="{ field, errors }" name="status">
            <Field :data-invalid="!!errors.length">
              <FieldLabel for="form-residential-property-status">
                {{ t('admin.residential_properties.input.status.label') }}
              </FieldLabel>
              <select
                id="form-residential-property-status"
                v-bind="field"
                class="border-input bg-background ring-offset-background placeholder:text-muted-foreground focus-visible:ring-ring flex h-10 w-full rounded-md border px-3 py-2 text-sm focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:outline-none disabled:cursor-not-allowed disabled:opacity-50"
                :aria-invalid="!!errors.length"
              >
                <option v-for="s in RESIDENTIAL_PROPERTY_STATUSES" :key="s" :value="s">
                  {{ t(`admin.residential_properties.statuses.${s}`) }}
                </option>
              </select>
              <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
            </Field>
          </VeeField>
        </FieldGroup>
        <FieldGroup class="mt-4 flex flex-col md:flex-row">
          <VeeField v-slot="{ componentField, errors }" name="address_line">
            <Field :data-invalid="!!errors.length">
              <FieldLabel for="form-residential-property-address">
                {{ t('admin.residential_properties.input.address_line.label') }}
              </FieldLabel>
              <Input
                id="form-residential-property-address"
                v-bind="componentField"
                :placeholder="t('admin.residential_properties.input.address_line.placeholder')"
                autocomplete="off"
                :aria-invalid="!!errors.length"
              />
              <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
            </Field>
          </VeeField>
        </FieldGroup>
        <FieldGroup class="mt-4 flex flex-col md:flex-row">
          <VeeField v-slot="{ componentField, errors }" name="city">
            <Field :data-invalid="!!errors.length">
              <FieldLabel for="form-residential-property-city">
                {{ t('admin.residential_properties.input.city.label') }}
              </FieldLabel>
              <Input
                id="form-residential-property-city"
                v-bind="componentField"
                :placeholder="t('admin.residential_properties.input.city.placeholder')"
                autocomplete="off"
                :aria-invalid="!!errors.length"
              />
              <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
            </Field>
          </VeeField>
          <VeeField v-slot="{ componentField, errors }" name="region">
            <Field :data-invalid="!!errors.length">
              <FieldLabel for="form-residential-property-region">
                {{ t('admin.residential_properties.input.region.label') }}
              </FieldLabel>
              <Input
                id="form-residential-property-region"
                v-bind="componentField"
                :placeholder="t('admin.residential_properties.input.region.placeholder')"
                autocomplete="off"
                :aria-invalid="!!errors.length"
              />
              <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
            </Field>
          </VeeField>
        </FieldGroup>
        <FieldGroup class="mt-4 flex flex-col md:flex-row">
          <VeeField v-slot="{ componentField, errors }" name="country">
            <Field :data-invalid="!!errors.length">
              <FieldLabel for="form-residential-property-country">
                {{ t('admin.residential_properties.input.country.label') }}
              </FieldLabel>
              <Input
                id="form-residential-property-country"
                v-bind="componentField"
                :placeholder="t('admin.residential_properties.input.country.placeholder')"
                autocomplete="off"
                :aria-invalid="!!errors.length"
              />
              <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
            </Field>
          </VeeField>
          <VeeField v-slot="{ componentField, errors }" name="timezone">
            <Field :data-invalid="!!errors.length">
              <FieldLabel for="form-residential-property-timezone">
                {{ t('admin.residential_properties.input.timezone.label') }}
              </FieldLabel>
              <Input
                id="form-residential-property-timezone"
                v-bind="componentField"
                :placeholder="t('admin.residential_properties.input.timezone.placeholder')"
                autocomplete="off"
                :aria-invalid="!!errors.length"
              />
              <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
            </Field>
          </VeeField>
        </FieldGroup>
      </form>
    </CardContent>
    <CardFooter>
      <Field orientation="horizontal" class="md:flex md:justify-end flex-col md:flex-row">
        <Button type="button" as="a" :href="admin_residential_properties_path()" variant="outline" class="w-full md:w-auto">
          {{ props.cancelLabel || t('common.back') }}
        </Button>
        <Button type="submit" form="form-residential-property" class="w-full md:w-auto">
          {{ props.submitLabel }}
        </Button>
      </Field>
    </CardFooter>
  </Card>
</template>

<script setup lang="ts">
import { nextTick, watch } from 'vue'
import { toTypedSchema } from '@vee-validate/zod'
import { useForm, Field as VeeField } from 'vee-validate'
import { useI18n } from 'vue-i18n'
import { Button } from '@/components/ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import {
  Field,
  FieldError,
  FieldGroup,
  FieldLabel,
} from '@/components/ui/field'
import { Input } from '@/components/ui/input'
import {
  residentialPropertySchema,
  RESIDENTIAL_PROPERTY_STATUSES,
  PROPERTY_TYPE_VALUES,
  type ResidentialPropertySchema,
} from '@/lib/schemas/residential_property'
import { useTranslateErrors } from '@/lib/composables/i18n/translate_errors'
import type { InertiaErrors } from '@/types/globals'
import { admin_residential_properties_path } from '@/routes'
import type { ResidentialProperty } from '@/types/residential_property'

const props = defineProps<{
  description: string
  submitLabel: string
  propertyTypes: string[]
  title?: string
  cancelLabel?: string
  defaultValues?: ResidentialProperty
  serverErrors?: Record<string, string[]>
}>()

const emit = defineEmits<{
  (e: 'submit', data: ResidentialPropertySchema): void
}>()

const { t } = useI18n()

const { translateErrors, mapServerErrorsToForm } = useTranslateErrors()
const formSchema = toTypedSchema(residentialPropertySchema)

const { handleSubmit, setErrors, resetForm } = useForm({
  validationSchema: formSchema,
  initialValues: {
    name: '',
    code: '',
    property_type: PROPERTY_TYPE_VALUES[0],
    address_line: '',
    city: '',
    region: '',
    country: 'Chile',
    timezone: 'America/Santiago',
    status: 'active' as (typeof RESIDENTIAL_PROPERTY_STATUSES)[number],
  },
})

function formValuesFromResidentialProperty(defaults: ResidentialProperty) {
  const pt = defaults.property_type
  const safeType =
    pt && (PROPERTY_TYPE_VALUES as readonly string[]).includes(pt)
      ? (pt as (typeof PROPERTY_TYPE_VALUES)[number])
      : PROPERTY_TYPE_VALUES[0]
  const st = defaults.status
  const safeStatus =
    st && (RESIDENTIAL_PROPERTY_STATUSES as readonly string[]).includes(st)
      ? (st as (typeof RESIDENTIAL_PROPERTY_STATUSES)[number])
      : 'active'

  const countryRaw = defaults.country

  const country =
    countryRaw != null && String(countryRaw).trim() !== ''
      ? String(countryRaw).trim()
      : 'Chile'

  const timezoneRaw = defaults.timezone
  const timezone =
    timezoneRaw != null && String(timezoneRaw).trim() !== ''
      ? String(timezoneRaw).trim()
      : 'America/Santiago'
  
  return {
    name: defaults.name ?? '',
    code: defaults.code ?? '',
    property_type: safeType,
    address_line: defaults.address_line ?? '',
    city: defaults.city ?? '',
    region: defaults.region ?? '',
    country,
    timezone,
    status: safeStatus,
  }
}

watch(
  () => props.defaultValues,
  (defaults) => {
    if (!defaults) return
    nextTick(() => {
      resetForm({ values: formValuesFromResidentialProperty(defaults) })
    })
  },
  { immediate: true, deep: true }
)

function applyServerErrors(errors: InertiaErrors) {
  if (errors && Object.keys(errors).length > 0) {
    nextTick(() => {
      setErrors(mapServerErrorsToForm(errors))
    })
  }
}

const onSubmit = handleSubmit((data) => {
  emit('submit', data)
})

defineExpose<{
  applyServerErrors: (errors: InertiaErrors) => void
}>({
  applyServerErrors: (errors: InertiaErrors) => applyServerErrors(errors),
})

</script>
