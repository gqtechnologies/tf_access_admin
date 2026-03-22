<template>
    <div>
        <Header :itemsBreadcrumb="itemsBreadcrumb" :title="t('admin.profile.edit.title')" />
        <Form
            ref="formRef"
            :description="t('admin.profile.edit.description')"
            :submitLabel="t('admin.profile.edit.submit')"
            :languages="props.languages"
            :server-errors="props.errors"
            @submit="onSubmit"
            :default-values="props.user"
            :cancel-label="t('common.back')"
        />
    </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { router } from '@inertiajs/vue3'
import Header from '@/components/admin/layout/Header.vue'
import { admin_profile_path } from '@/routes'
import { useI18n } from 'vue-i18n'
import { getProfileBreadcrumbs } from '@/lib/breadcrumbs/profile'
import Form from '@/components/admin/profile/Form.vue'
import { User } from '@/types/user'
import { ProfileEditSchema } from '@/lib/schemas/profile'
import { ref } from 'vue'
import { toast } from 'vue-sonner'
const { t } = useI18n()

const props = defineProps<{
    user: User,
    languages: string[];
    errors?: Record<string, string[]>;
}>();


const formRef = ref<InstanceType<typeof Form> | null>(null)
const itemsBreadcrumb = computed(() => getProfileBreadcrumbs(t))
function onSubmit(data: ProfileEditSchema) {
    router.put(admin_profile_path(props.user.id as string), {
        user: {
            name: data.name,
            email: data.email,
            dni: data.dni,
            password: data.password,
            password_confirmation: data.password_confirmation,
            language: data.language,
            ...(data.avatar ? { avatar: data.avatar } : {}),
            ...(data.remove_avatar ? { remove_avatar: true } : {}),
        },
    }, {
        preserveScroll: true,
        preserveState: true,
        onSuccess: () => {
            toast.success(t('admin.profile.updated_successfully'))
        },
        onError: (errors: any) => {
            toast.error(t('admin.profile.update_failed'))
            if (errors && Object.keys(errors).length > 0) {
                formRef.value?.applyServerErrors(errors)
            }
        },
    })
}
</script>