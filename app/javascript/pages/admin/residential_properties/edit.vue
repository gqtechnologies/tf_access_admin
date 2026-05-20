<template>
  <div>
    <Header :itemsBreadcrumb="itemsBreadcrumb" :title="t('admin.residential_properties.edit.title')" />
    <Form
      ref="formRef"
      :description="t('admin.residential_properties.edit.description')"
      :submitLabel="t('admin.residential_properties.edit.submit')"
      :property-types="props.property_types"
      :server-errors="props.errors"
      :default-values="props.residential_property"
      :cancel-label="t('common.back')"
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
import type { ResidentialProperty } from '@/types/residential_property'
import { admin_residential_property_path } from '@/routes'

const { t } = useI18n()

const props = defineProps<{
  residential_property: ResidentialProperty
  property_types: string[]
  errors?: Record<string, string[]>
}>()

const formRef = ref<InstanceType<typeof Form> | null>(null)
const itemsBreadcrumb = computed(() => getResidentialPropertiesBreadcrumbs(t))

function onSubmit(data: ResidentialPropertySchema) {
  router.put(
    admin_residential_property_path(props.residential_property.id as string),
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
      onSuccess: () => {
        toast.success(t('admin.residential_properties.updated_successfully'))
        router.reload({ only: ['residential_property'] })
      },
      onError: (errors) => {
        toast.error(t('admin.residential_properties.update_failed'))
        applyErrorsToFormRef(formRef, errors)
      },
    }
  )
}
</script>
