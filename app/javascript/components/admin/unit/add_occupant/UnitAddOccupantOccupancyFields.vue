<template>
  <div class="space-y-4">
    <div class="space-y-1">
      <h3 class="text-base font-semibold">
        {{ t('admin.units.show.occupants.add_occupant.assign.occupancy.title') }}
      </h3>
      <p class="text-sm text-muted-foreground">
        {{ t('admin.units.show.occupants.add_occupant.assign.occupancy.description') }}
      </p>
    </div>

    <FieldGroup class="flex flex-col gap-4">
      <Field>
        <FieldLabel :for="`${idPrefix}-occupancy-type`">
          {{ t('admin.units.show.occupants.add_occupant.assign.fields.occupancy_type') }}
        </FieldLabel>
        <Select v-model="occupancyForm.occupancy_type">
          <SelectTrigger :id="`${idPrefix}-occupancy-type`" :aria-invalid="!!fieldErrors.occupancy_type">
            <SelectValue :placeholder="t('admin.units.show.occupants.add_occupant.assign.fields.occupancy_type_placeholder')" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem v-for="option in occupancyTypes" :key="option.value" :value="option.value">
              {{ option.label }}
            </SelectItem>
          </SelectContent>
        </Select>
        <FieldError
          v-if="fieldErrors.occupancy_type"
          :errors="translateErrors([fieldErrors.occupancy_type])"
        />
      </Field>

      <Field orientation="horizontal" class="items-center justify-between rounded-lg border px-4 py-3">
        <div class="space-y-0.5">
          <FieldLabel :for="`${idPrefix}-can-authorize`" class="text-sm font-medium">
            {{ t('admin.units.show.occupants.add_occupant.assign.fields.can_authorize_visits') }}
          </FieldLabel>
          <p class="text-xs text-muted-foreground">
            {{ t('admin.units.show.occupants.add_occupant.assign.fields.can_authorize_visits_help') }}
          </p>
        </div>
        <Checkbox
          :id="`${idPrefix}-can-authorize`"
          :model-value="occupancyForm.can_authorize_visits"
          @update:model-value="(value: boolean | 'indeterminate') => {
            occupancyForm.can_authorize_visits = value === true
          }"
        />
      </Field>

      <Field v-if="showStatus">
        <FieldLabel :for="`${idPrefix}-status`">
          {{ t('admin.units.show.occupants.edit_occupant.fields.status') }}
        </FieldLabel>
        <Select v-model="statusModel">
          <SelectTrigger :id="`${idPrefix}-status`" :aria-invalid="!!fieldErrors.status">
            <SelectValue :placeholder="t('admin.units.show.occupants.edit_occupant.fields.status_placeholder')" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="active">
              {{ t('admin.units.show.occupants.statuses.active') }}
            </SelectItem>
            <SelectItem value="inactive">
              {{ t('admin.units.show.occupants.statuses.inactive') }}
            </SelectItem>
          </SelectContent>
        </Select>
        <FieldError v-if="fieldErrors.status" :errors="translateErrors([fieldErrors.status])" />
      </Field>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Field>
          <FieldLabel :for="`${idPrefix}-starts-at`">
            {{ t('admin.units.show.occupants.add_occupant.assign.fields.starts_at') }}
          </FieldLabel>
          <DatePicker
            :id="`${idPrefix}-starts-at`"
            v-model="occupancyForm.starts_at"
            :placeholder="t('admin.units.show.occupants.add_occupant.assign.fields.starts_at_placeholder')"
            :aria-invalid="!!fieldErrors.starts_at"
          />
          <FieldError
            v-if="fieldErrors.starts_at"
            :errors="translateErrors([fieldErrors.starts_at])"
          />
        </Field>

        <Field>
          <FieldLabel :for="`${idPrefix}-ends-at`">
            {{ t('admin.units.show.occupants.add_occupant.assign.fields.ends_at') }}
          </FieldLabel>
          <DatePicker
            :id="`${idPrefix}-ends-at`"
            v-model="occupancyForm.ends_at"
            :placeholder="t('admin.units.show.occupants.add_occupant.assign.fields.ends_at_placeholder')"
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
import { Checkbox } from '@/components/ui/checkbox'
import { Field, FieldError, FieldGroup, FieldLabel } from '@/components/ui/field'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { useTranslateErrors } from '@/lib/composables/i18n/translate_errors'
import type { UnitOccupancyAssignForm, UnitOccupancyEditForm } from '@/lib/schemas/unit_occupancy'
import type { OccupancyTypeOption } from '@/types/unit'

const occupancyForm = defineModel<UnitOccupancyAssignForm | UnitOccupancyEditForm>(
  'occupancyForm',
  { required: true },
)

const props = withDefaults(
  defineProps<{
    occupancyTypes: OccupancyTypeOption[]
    fieldErrors?: Record<string, string | undefined>
    idPrefix?: string
    showStatus?: boolean
  }>(),
  { idPrefix: 'add-occupant', showStatus: false },
)

const { t } = useI18n()
const { translateErrors } = useTranslateErrors()

const fieldErrors = computed(() => props.fieldErrors ?? {})

const statusModel = computed({
  get: () => ('status' in occupancyForm.value ? occupancyForm.value.status : 'active'),
  set: (value: 'active' | 'inactive') => {
    if ('status' in occupancyForm.value) {
      occupancyForm.value.status = value
    }
  },
})
</script>
