<template>
  <div class="space-y-6">
    <div class="space-y-1">
      <h3 class="text-base font-semibold">
        {{ t('admin.units.show.occupants.add_occupant.create.title') }}
      </h3>
      <p class="text-sm text-muted-foreground">
        {{ t('admin.units.show.occupants.add_occupant.create.description') }}
      </p>
    </div>

    <div class="space-y-4">
      <div class="space-y-1">
        <h4 class="text-sm font-semibold">
          {{ t('admin.units.show.occupants.add_occupant.create.person_section_title') }}
        </h4>
        <p class="text-sm text-muted-foreground">
          {{ t('admin.units.show.occupants.add_occupant.create.person_section_description') }}
        </p>
      </div>

      <FieldGroup class="grid gap-4 md:grid-cols-3">
        <Field>
          <FieldLabel for="add-occupant-document">
            {{ t('admin.people.input.document_number.label') }}
          </FieldLabel>
          <Input
            id="add-occupant-document"
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
          <FieldLabel for="add-occupant-first-name">
            {{ t('admin.people.input.first_name.label') }}
          </FieldLabel>
          <Input
            id="add-occupant-first-name"
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
          <FieldLabel for="add-occupant-last-name">
            {{ t('admin.people.input.last_name.label') }}
          </FieldLabel>
          <Input
            id="add-occupant-last-name"
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
          <FieldLabel for="add-occupant-email">
            {{ t('admin.people.input.email.label') }}
          </FieldLabel>
          <Input
            id="add-occupant-email"
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
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { Field, FieldError, FieldGroup, FieldLabel } from '@/components/ui/field'
import { Input } from '@/components/ui/input'
import { useTranslateErrors } from '@/lib/composables/i18n/translate_errors'
import type { AddOccupantPersonForm } from '@/lib/schemas/unit_occupancy'

const personForm = defineModel<AddOccupantPersonForm>('personForm', { required: true })

const props = defineProps<{
  fieldErrors?: Record<string, string | undefined>
}>()

const { t } = useI18n()
const { translateErrors } = useTranslateErrors()

const fieldErrors = computed(() => props.fieldErrors ?? {})
</script>
