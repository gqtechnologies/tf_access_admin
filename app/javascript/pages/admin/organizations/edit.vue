<template>
  <div>
    <Header :itemsBreadcrumb="itemsBreadcrumb" :title="t('admin.organizations.edit.title')" />
    <Form
      ref="formRef"
      :description="t('admin.organizations.edit.description')"
      :submitLabel="t('admin.organizations.edit.submit')"
      :defaultValues="props.organization"
      :editMode="true"
      @submit="onSubmit"
    />
  </div>
</template>

<script setup lang="ts">
import { useI18n } from "vue-i18n"
import Header from '@/components/admin/layout/Header.vue'
import{ getOrganizationBreadcrumbs } from '@/lib/breadcrumbs/organization'
import type { Organization } from '@/types/organization'
import { computed, ref } from "vue"
import Form from '@/components/admin/organization/Form.vue'
import { OrganizationSchema } from '@/lib/schemas/organization'
import { router } from "@inertiajs/vue3"
import { admin_organization_path } from "@/routes"
import { toast } from "vue-sonner"
const { t } = useI18n()

const props = defineProps<{
  organization: Organization
}>()

const itemsBreadcrumb = computed(() => getOrganizationBreadcrumbs(t))
const formRef = ref<InstanceType<typeof Form> | null>(null)
  function onSubmit(data: OrganizationSchema) {
    router.put(admin_organization_path(props.organization.id as string), {
        organization: {
            name: data.name,
            subdomain: data.subdomain,
            ...(data.cover ? { cover: data.cover } : {}),
            ...(data.logo ? { logo: data.logo } : {}),
            ...(data.remove_cover ? { remove_cover: true } : {}),
            ...(data.remove_logo ? { remove_logo: true } : {}),
        },
    }, {
        preserveScroll: true,
        preserveState: true,
        onSuccess: () => {
            toast.success(t('admin.organizations.updated_successfully'))
        },
        onError: (errors: any) => {
            toast.error(t('admin.organizations.update_failed'))
            if (errors && Object.keys(errors).length > 0) {
                formRef.value?.applyServerErrors(errors)
            }
        },
    })
}
</script>