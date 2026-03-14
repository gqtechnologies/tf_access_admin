<template>
    <div>
        <Form
            ref="formRef"
            :title="t('users.edit.title')"
            :description="t('users.edit.description')"
            :submitLabel="t('users.edit.submit')"
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
import { ref } from 'vue'
import { User } from '@/types/user'
import { admin_user_path } from '@/routes'

const { t } = useI18n()

const props = defineProps<{
    user: User,
    roles: string[];
    languages: string[];
    errors?: Record<string, string[]>;
}>();

const formRef = ref<InstanceType<typeof Form> | null>(null)

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
            console.log('onSuccess')
            toast.success(t('users.updated_successfully'))
        },
        onError: (errors: any) => {
            console.log('errors', errors)
            toast.error(t('users.update_failed'))
            if (errors && Object.keys(errors).length > 0) {
                formRef.value?.applyServerErrors(errors)
            }
        },
    })
}
</script>