<template>
  <div class="space-y-4">
    <div class="space-y-1">
      <h3 class="text-base font-semibold">
        {{ t('admin.units.show.owners.add_owner.assign.ownership.title') }}
      </h3>
      <p class="text-sm text-muted-foreground">
        {{ t('admin.units.show.owners.add_owner.assign.ownership.description') }}
      </p>
    </div>

    <div class="rounded-lg border border-dashed bg-muted/30 px-4 py-3 text-sm">
      <span class="text-muted-foreground">
        {{ t('admin.units.show.owners.add_owner.assign.available_preview') }}
      </span>
      <span class="ml-1 font-semibold text-foreground">
        {{ formatOwnershipPercentage(remainingPercentage) }}
      </span>
    </div>

    <FieldGroup class="flex flex-col gap-4">
      <Field>
        <FieldLabel :for="`${idPrefix}-percentage`">
          {{ t('admin.units.show.owners.add_owner.assign.fields.percentage') }}
        </FieldLabel>
        <div class="relative">
          <Input
            :id="`${idPrefix}-percentage`"
            v-model.number="ownershipForm.ownership_percentage"
            type="number"
            min="0.01"
            max="100"
            step="0.01"
            :aria-invalid="!!fieldErrors.ownership_percentage"
          />
          <span
            class="pointer-events-none absolute inset-y-0 right-3 flex items-center text-sm text-muted-foreground"
          >
            %
          </span>
        </div>
        <FieldError
          v-if="fieldErrors.ownership_percentage"
          :errors="translateErrors([fieldErrors.ownership_percentage])"
        />
      </Field>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Field>
          <FieldLabel :for="`${idPrefix}-starts-at`">
            {{ t('admin.units.show.owners.add_owner.assign.fields.starts_at') }}
          </FieldLabel>
          <DatePicker
            :id="`${idPrefix}-starts-at`"
            v-model="ownershipForm.starts_at"
            :placeholder="t('admin.units.show.owners.add_owner.assign.fields.starts_at_placeholder')"
            :aria-invalid="!!fieldErrors.starts_at"
          />
          <FieldError
            v-if="fieldErrors.starts_at"
            :errors="translateErrors([fieldErrors.starts_at])"
          />
        </Field>

        <Field>
          <FieldLabel :for="`${idPrefix}-ends-at`">
            {{ t('admin.units.show.owners.add_owner.assign.fields.ends_at') }}
          </FieldLabel>
          <DatePicker
            :id="`${idPrefix}-ends-at`"
            v-model="ownershipForm.ends_at"
            :placeholder="t('admin.units.show.owners.add_owner.assign.fields.ends_at_placeholder')"
            :aria-invalid="!!fieldErrors.ends_at"
          />
          <FieldError v-if="fieldErrors.ends_at" :errors="translateErrors([fieldErrors.ends_at])" />
        </Field>
      </div>
    </FieldGroup>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import DatePicker from '@/components/ui/datepicker/DatePicker.vue'
import { Field, FieldError, FieldGroup, FieldLabel } from '@/components/ui/field'
import { Input } from '@/components/ui/input'
import { useTranslateErrors } from '@/lib/composables/i18n/translate_errors'
import type { UnitOwnershipAssignForm } from '@/lib/schemas/unit_ownership'
import { formatOwnershipPercentage, toPercentageNumber } from '@/lib/utils/unit'

const ownershipForm = defineModel<UnitOwnershipAssignForm>('ownershipForm', { required: true })

const props = withDefaults(
  defineProps<{
    availablePercentage: number | string
    fieldErrors?: Record<string, string | undefined>
    idPrefix?: string
  }>(),
  { idPrefix: 'add-owner' },
)

const { t } = useI18n()
const { translateErrors } = useTranslateErrors()

const fieldErrors = computed(() => props.fieldErrors ?? {})

const remainingPercentage = computed(() => {
  const available = toPercentageNumber(props.availablePercentage)
  const requested = toPercentageNumber(ownershipForm.value.ownership_percentage)
  return Math.max(available - requested, 0)
})
</script>
