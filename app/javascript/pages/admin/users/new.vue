<template>
    <div>
        <Header :itemsBreadcrumb="itemsBreadcrumb" :title="t('admin.users.new.title')" />
        <Form
            ref="formRef"
            :description="t('admin.users.new.description')"
            :submitLabel="t('admin.users.new.submit')"
            :roles="props.roles"
            :languages="props.languages"
            :server-errors="props.errors"
            @submit="onSubmit"
        />
    </div>
</template>

<script setup lang="ts">
import { router } from '@inertiajs/vue3'
import Form from '@/components/admin/user/Form.vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import type { UserSchema } from '@/lib/schemas/user'
import { ref, computed } from 'vue'
import { getUsersBreadcrumbs } from '@/lib/breadcrumbs/user'
import Header from '@/components/admin/layout/Header.vue'
import { applyErrorsToFormRef } from '@/lib/composables/forms/apply_errors_to_form_ref'

const { t } = useI18n()

const props = defineProps<{
    roles: string[];
    languages: string[];
    errors?: Record<string, string[]>;
}>();

const formRef = ref<InstanceType<typeof Form> | null>(null)
const itemsBreadcrumb = computed(() => getUsersBreadcrumbs(t))
function onSubmit(data: UserSchema) {
    router.post('/admin/users', {
        user: {
            name: data.name,
            email: data.email,
            dni: data.dni,
            password: data.password,
            password_confirmation: data.password_confirmation,
            role: data.role,
            language: data.language,
        },
    }, {
        preserveScroll: true,
        preserveState: true,
        onSuccess: () => toast.success(t('admin.users.created_successfully')),
        onError: (errors) => {
            toast.error(t('admin.users.creation_failed'))
            applyErrorsToFormRef(formRef, errors)
        },
    })
}
</script>