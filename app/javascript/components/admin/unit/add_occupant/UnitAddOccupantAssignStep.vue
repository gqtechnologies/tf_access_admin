<template>
  <div class="space-y-6">
    <div class="space-y-1">
      <h3 class="text-base font-semibold">
        {{ t('admin.units.show.occupants.add_occupant.assign.title') }}
      </h3>
      <p class="text-sm text-muted-foreground">
        {{ t('admin.units.show.occupants.add_occupant.assign.description') }}
      </p>
    </div>

    <div class="space-y-3">
      <div class="space-y-1">
        <h4 class="text-sm font-semibold">
          {{ t('admin.units.show.occupants.add_occupant.assign.person_section_title') }}
        </h4>
        <p class="text-sm text-muted-foreground">
          {{ t('admin.units.show.occupants.add_occupant.assign.person_section_description') }}
        </p>
      </div>

      <UnitAddOwnerPersonCard
        :person="person"
        :show-change-action="showChangePerson"
        @change-person="emit('change-person')"
      />
    </div>

    <UnitAddOccupantActiveElsewhereWarning
      v-if="activeElsewhere.length > 0"
      :occupancies="activeElsewhere"
    />

    <UnitAddOccupantOccupancyFields
      v-model:occupancy-form="occupancyForm"
      :occupancy-types="occupancyTypes"
      :field-errors="occupancyFieldErrors"
    />

    <FieldError v-if="fieldErrors?.person_id" :errors="translateErrors([fieldErrors.person_id])" />
    <FieldError v-if="fieldErrors?.base" :errors="translateErrors([fieldErrors.base])" />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import UnitAddOwnerPersonCard from '@/components/admin/unit/add_owner/UnitAddOwnerPersonCard.vue'
import UnitAddOccupantActiveElsewhereWarning from '@/components/admin/unit/add_occupant/UnitAddOccupantActiveElsewhereWarning.vue'
import UnitAddOccupantOccupancyFields from '@/components/admin/unit/add_occupant/UnitAddOccupantOccupancyFields.vue'
import { FieldError } from '@/components/ui/field'
import { useTranslateErrors } from '@/lib/composables/i18n/translate_errors'
import type { UnitOccupancyAssignForm } from '@/lib/schemas/unit_occupancy'
import type { ActiveElsewhereOccupancy, OccupancyTypeOption } from '@/types/unit'
import type { Person } from '@/types/person'

const occupancyForm = defineModel<UnitOccupancyAssignForm>('occupancyForm', { required: true })

const props = withDefaults(
  defineProps<{
    person: Person
    occupancyTypes: OccupancyTypeOption[]
    activeElsewhere?: ActiveElsewhereOccupancy[]
    showChangePerson?: boolean
    fieldErrors?: Record<string, string | undefined>
  }>(),
  {
    activeElsewhere: () => [],
    showChangePerson: true,
  },
)

const emit = defineEmits<{
  (e: 'change-person'): void
}>()

const { t } = useI18n()
const { translateErrors } = useTranslateErrors()

const occupancyFieldErrors = computed(() => ({
  occupancy_type: props.fieldErrors?.occupancy_type,
  starts_at: props.fieldErrors?.starts_at,
  ends_at: props.fieldErrors?.ends_at,
}))
</script>
