<template>
    <div>
        <Header :itemsBreadcrumb="itemsBreadcrumb" :title="t('admin.organizations.new.title')" />
        <Form
            ref="formRef"
            :description="t('admin.organizations.new.description')"
            :submitLabel="t('admin.organizations.new.submit')"
            @submit="onSubmit"
            :plans="plans"
        />
    </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { router } from '@inertiajs/vue3'
import Header from '@/components/admin/layout/Header.vue'
import { getOrganizationsBreadcrumbs } from '@/lib/breadcrumbs/organization'
import { computed, ref } from 'vue'
import Form from '@/components/admin/organization/Form.vue'
import type { OrganizationSchema } from '@/lib/schemas/organization'
import { toast } from 'vue-sonner'
import { applyErrorsToFormRef } from '@/lib/composables/forms/apply_errors_to_form_ref'

defineProps<{
    plans: string[]
}>()

const { t } = useI18n()
const itemsBreadcrumb = computed(() => getOrganizationsBreadcrumbs(t))

const formRef = ref<InstanceType<typeof Form> | null>(null)
function onSubmit(data: OrganizationSchema) {
    router.post('/admin/organizations', {
        organization: {
            name: data.name,
            subdomain: data.subdomain,
            cover: data.cover,
            logo: data.logo,
            plan: data.plan,
        },
    }, {
        preserveScroll: true,
        preserveState: true,
        onSuccess: () => toast.success(t('admin.organizations.created_successfully')),
        onError: (errors) => {
            toast.error(t('admin.organizations.creation_failed'))
            applyErrorsToFormRef(formRef, errors)
        },
    })
}
</script>