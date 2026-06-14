<template>
  <div class="space-y-6">
    <div class="space-y-1">
      <h3 class="text-base font-semibold">
        {{ t('admin.units.show.owners.add_owner.assign.title') }}
      </h3>
      <p class="text-sm text-muted-foreground">
        {{ t('admin.units.show.owners.add_owner.assign.description') }}
      </p>
    </div>

    <div class="space-y-3">
      <div class="space-y-1">
        <h4 class="text-sm font-semibold">
          {{ t('admin.units.show.owners.add_owner.assign.person_section_title') }}
        </h4>
        <p class="text-sm text-muted-foreground">
          {{ t('admin.units.show.owners.add_owner.assign.person_section_description') }}
        </p>
      </div>

      <UnitAddOwnerPersonCard :person="person" @change-person="emit('change-person')" />
    </div>

    <UnitAddOwnerOwnershipFields
      v-model:ownership-form="ownershipForm"
      :available-percentage="availablePercentage"
      :field-errors="fieldErrors"
    />

    <FieldError v-if="fieldErrors?.person_id" :errors="translateErrors([fieldErrors.person_id])" />
    <FieldError v-if="fieldErrors?.base" :errors="translateErrors([fieldErrors.base])" />
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import UnitAddOwnerOwnershipFields from '@/components/admin/unit/add_owner/UnitAddOwnerOwnershipFields.vue'
import UnitAddOwnerPersonCard from '@/components/admin/unit/add_owner/UnitAddOwnerPersonCard.vue'
import { FieldError } from '@/components/ui/field'
import { useTranslateErrors } from '@/lib/composables/i18n/translate_errors'
import type { UnitOwnershipAssignForm } from '@/lib/schemas/unit_ownership'
import type { Person } from '@/types/person'

defineProps<{
  person: Person
  availablePercentage: number | string
  fieldErrors?: Record<string, string | undefined>
}>()

const ownershipForm = defineModel<UnitOwnershipAssignForm>('ownershipForm', { required: true })

const emit = defineEmits<{
  (e: 'change-person'): void
}>()

const { t } = useI18n()
const { translateErrors } = useTranslateErrors()
</script>
