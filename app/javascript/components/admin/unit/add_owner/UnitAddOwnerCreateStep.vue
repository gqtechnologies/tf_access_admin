<template>
  <div class="space-y-6">
    <div class="space-y-1">
      <h3 class="text-base font-semibold">
        {{ t('admin.units.show.owners.add_owner.create.title') }}
      </h3>
      <p class="text-sm text-muted-foreground">
        {{ t('admin.units.show.owners.add_owner.create.description') }}
      </p>
    </div>

    <div class="space-y-4">
      <div class="space-y-1">
        <h4 class="text-sm font-semibold">
          {{ t('admin.units.show.owners.add_owner.create.person_section_title') }}
        </h4>
        <p class="text-sm text-muted-foreground">
          {{ t('admin.units.show.owners.add_owner.create.person_section_description') }}
        </p>
      </div>

      <FieldGroup class="grid gap-4 md:grid-cols-3">
        <Field>
          <FieldLabel for="add-owner-document">
            {{ t('admin.people.input.document_number.label') }}
          </FieldLabel>
          <Input
            id="add-owner-document"
            v-model="personForm.document_number"
            :placeholder="t('admin.people.input.document_number.placeholder')"
            :aria-invalid="!!fieldErrors.document_number"
          />
          <FieldError
            v-if="fieldErrors.document_number"
            :errors="translateErrors([fieldErrors.document_number])"
          />
        </Field>

        <Field>
          <FieldLabel for="add-owner-first-name">
            {{ t('admin.people.input.first_name.label') }}
          </FieldLabel>
          <Input
            id="add-owner-first-name"
            v-model="personForm.first_name"
            :placeholder="t('admin.people.input.first_name.placeholder')"
            :aria-invalid="!!fieldErrors.first_name"
          />
          <FieldError
            v-if="fieldErrors.first_name"
            :errors="translateErrors([fieldErrors.first_name])"
          />
        </Field>

        <Field>
          <FieldLabel for="add-owner-last-name">
            {{ t('admin.people.input.last_name.label') }}
          </FieldLabel>
          <Input
            id="add-owner-last-name"
            v-model="personForm.last_name"
            :placeholder="t('admin.people.input.last_name.placeholder')"
            :aria-invalid="!!fieldErrors.last_name"
          />
          <FieldError
            v-if="fieldErrors.last_name"
            :errors="translateErrors([fieldErrors.last_name])"
          />
        </Field>
      </FieldGroup>

      <FieldGroup class="grid gap-4 md:grid-cols-2">
        <Field>
          <FieldLabel for="add-owner-email">
            {{ t('admin.people.input.email.label') }}
          </FieldLabel>
          <Input
            id="add-owner-email"
            v-model="personForm.email"
            type="email"
            :placeholder="t('admin.people.input.email.placeholder')"
            :aria-invalid="!!fieldErrors.email"
          />
          <FieldError v-if="fieldErrors.email" :errors="translateErrors([fieldErrors.email])" />
        </Field>
      </FieldGroup>

      <FieldError v-if="fieldErrors.base" :errors="translateErrors([fieldErrors.base])" />
    </div>

    <UnitAddOwnerOwnershipFields
      v-model:ownership-form="ownershipForm"
      :available-percentage="availablePercentage"
      :field-errors="ownershipFieldErrors"
    />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import UnitAddOwnerOwnershipFields from '@/components/admin/unit/add_owner/UnitAddOwnerOwnershipFields.vue'
import { Field, FieldError, FieldGroup, FieldLabel } from '@/components/ui/field'
import { Input } from '@/components/ui/input'
import { useTranslateErrors } from '@/lib/composables/i18n/translate_errors'
import type { AddOwnerPersonForm, UnitOwnershipAssignForm } from '@/lib/schemas/unit_ownership'

const personForm = defineModel<AddOwnerPersonForm>('personForm', { required: true })
const ownershipForm = defineModel<UnitOwnershipAssignForm>('ownershipForm', { required: true })

const props = defineProps<{
  availablePercentage: number | string
  fieldErrors?: Record<string, string | undefined>
}>()

const { t } = useI18n()
const { translateErrors } = useTranslateErrors()

const fieldErrors = computed(() => props.fieldErrors ?? {})

const ownershipFieldErrors = computed(() => ({
  ownership_percentage: fieldErrors.value.ownership_percentage,
  starts_at: fieldErrors.value.starts_at,
  ends_at: fieldErrors.value.ends_at,
}))
</script>
