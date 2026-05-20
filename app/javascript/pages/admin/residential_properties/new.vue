<template>
  <div>
    <Header :itemsBreadcrumb="itemsBreadcrumb" :title="t('admin.residential_properties.new.title')" />
    <Form
      ref="formRef"
      :description="t('admin.residential_properties.new.description')"
      :submitLabel="t('admin.residential_properties.new.submit')"
      :property-types="props.property_types"
      :server-errors="props.errors"
      @submit="onSubmit"
    />
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import Header from '@/components/admin/layout/Header.vue'
import { getResidentialPropertiesBreadcrumbs } from '@/lib/breadcrumbs/residential_property'
import { computed, ref } from 'vue'
import Form from '@/components/admin/residential_property/Form.vue'
import type { ResidentialPropertySchema } from '@/lib/schemas/residential_property'
import { router } from '@inertiajs/vue3'
import { toast } from 'vue-sonner'
import { applyErrorsToFormRef } from '@/lib/composables/forms/apply_errors_to_form_ref'

const { t } = useI18n()

const props = defineProps<{
  property_types: string[]
  errors?: Record<string, string[]>
}>()

const formRef = ref<InstanceType<typeof Form> | null>(null)
const itemsBreadcrumb = computed(() => getResidentialPropertiesBreadcrumbs(t))

function onSubmit(data: ResidentialPropertySchema) {
  router.post(
    '/admin/residential_properties',
    {
      residential_property: {
        name: data.name,
        code: data.code,
        property_type: data.property_type,
        address_line: data.address_line,
        city: data.city,
        region: data.region,
        country: data.country,
        timezone: data.timezone,
        status: data.status,
      },
    },
    {
      preserveScroll: true,
      preserveState: true,
      onSuccess: () => toast.success(t('admin.residential_properties.created_successfully')),
      onError: (errors) => {
        toast.error(t('admin.residential_properties.creation_failed'))
        applyErrorsToFormRef(formRef, errors)
      },
    }
  )
}
</script>
