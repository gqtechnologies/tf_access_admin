<template>
    <div>
        <Header :itemsBreadcrumb="itemsBreadcrumb" :title="t('admin.users.edit.title')" />
        <Form
            ref="formRef"
            :description="t('admin.users.edit.description')"
            :submitLabel="t('admin.users.edit.submit')"
            :roles="props.roles"
            :languages="props.languages"
            :server-errors="props.errors"
            @submit="onSubmit"
            :default-values="props.user"
            :edit-mode="true"
            :cancel-label="t('common.back')"
        />
    </div>
</template>

<script setup lang="ts">
import { router } from '@inertiajs/vue3'
import Form from '@/components/admin/user/Form.vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue-sonner'
import type { UserSchema, UserEditSchema } from '@/lib/schemas/user'
import { ref, computed } from 'vue'
import { User } from '@/types/user'
import { admin_user_path } from '@/routes'
import Header from '@/components/admin/layout/Header.vue'
import { getUsersBreadcrumbs } from '@/lib/breadcrumbs/user'
import { applyErrorsToFormRef } from '@/lib/composables/forms/apply_errors_to_form_ref'
const { t } = useI18n()

const props = defineProps<{
    user: User,
    roles: string[];
    languages: string[];
    errors?: Record<string, string[]>;
}>();

const formRef = ref<InstanceType<typeof Form> | null>(null)
const itemsBreadcrumb = computed(() => getUsersBreadcrumbs(t))
function onSubmit(data: UserSchema | UserEditSchema) {
    router.put(admin_user_path(props.user.id as string), {
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
        onSuccess: () => {
            toast.success(t('admin.users.updated_successfully'))
        },
        onError: (errors) => {
            toast.error(t('admin.users.update_failed'))
            applyErrorsToFormRef(formRef, errors)
        },
    })
}
</script>