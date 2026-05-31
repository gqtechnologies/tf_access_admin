<template>
  <div>
    <Header :itemsBreadcrumb="itemsBreadcrumb" :title="t('admin.people.new.title')" />
    <Form
      ref="formRef"
      :description="t('admin.people.new.description')"
      :submitLabel="t('admin.people.new.submit')"
      :roles="props.roles"
      :person-types="props.person_types"
      :statuses="props.statuses"
      :linkable-users="props.linkable_users"
      :server-errors="props.errors"
      @submit="onSubmit"
    />
  </div>
</template>

<script setup lang="ts">
import { router } from '@inertiajs/vue3'
import Form from '@/components/admin/person/Form.vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import type { PersonSchema } from '@/lib/schemas/person'
import { ref, computed } from 'vue'
import { getPeopleBreadcrumbs } from '@/lib/breadcrumbs/person'
import Header from '@/components/admin/layout/Header.vue'
import { applyErrorsToFormRef } from '@/lib/composables/forms/apply_errors_to_form_ref'
import type { LinkableUser } from '@/types/person'

const { t } = useI18n()

const props = defineProps<{
  roles: string[]
  person_types: string[]
  statuses: string[]
  linkable_users: LinkableUser[]
  errors?: Record<string, string[]>
}>()

const formRef = ref<InstanceType<typeof Form> | null>(null)
const itemsBreadcrumb = computed(() => getPeopleBreadcrumbs(t))

function onSubmit(data: PersonSchema) {
  router.post(
    '/admin/people',
    {
      person: {
        first_name: data.first_name,
        last_name: data.last_name,
        document_number: data.document_number,
        email: data.email,
        phone: data.phone,
        birthdate: data.birthdate,
      },
    },
    {
      preserveScroll: true,
      preserveState: true,
      onSuccess: () => toast.success(t('admin.people.created_successfully')),
      onError: (errors) => {
        toast.error(t('admin.people.creation_failed'))
        applyErrorsToFormRef(formRef, errors)
      },
    }
  )
}
</script>
