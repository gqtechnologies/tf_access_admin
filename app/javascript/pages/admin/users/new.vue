<template>
    <div>
        <Form
            ref="formRef"
            :title="t('users.new.title')"
            :description="t('users.new.description')"
            :submitLabel="t('users.new.submit')"
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
import { ref } from 'vue'

const { t } = useI18n()

const props = defineProps<{
    roles: string[];
    languages: string[];
    errors?: Record<string, string[]>;
}>();

const formRef = ref<InstanceType<typeof Form> | null>(null)

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
        onSuccess: () => toast.success(t('users.created_successfully')),
        onError: (errors: any) => {
            toast.error(t('users.creation_failed'))
            if (errors && Object.keys(errors).length > 0) {
                formRef.value?.applyServerErrors(errors)
            }
        },
    })
}
</script>