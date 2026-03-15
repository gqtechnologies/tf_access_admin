<template>
    <Card class="w-full">
        <CardHeader>
            <CardTitle v-if="props.title">{{ props.title }}</CardTitle>
            <CardDescription>
                {{ props.description }}
            </CardDescription>
        </CardHeader>
        <CardContent>
            <form id="form-user" @submit="onSubmit">
                <FieldGroup class="flex flex-col md:flex-row">
                    <VeeField v-slot="{ field, errors }" name="name">
                        <Field :data-invalid="!!errors.length">
                            <FieldLabel for="form-user-name">
                                {{ t('admin.users.input.name.label') }}
                            </FieldLabel>
                            <Input id="form-user-name" v-bind="field"
                                :placeholder="t('admin.users.input.name.placeholder')" autocomplete="off"
                                :aria-invalid="!!errors.length" />
                            <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
                        </Field>
                    </VeeField>
                    <VeeField v-slot="{ field, errors }" name="email">
                        <Field :data-invalid="!!errors.length">
                            <FieldLabel for="form-user-email">
                                {{ t('admin.users.input.email.label') }}
                            </FieldLabel>
                            <Input id="form-user-email" v-bind="field"
                                :placeholder="t('admin.users.input.email.placeholder')" autocomplete="off"
                                :aria-invalid="!!errors.length" />
                            <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
                        </Field>
                    </VeeField>
                </FieldGroup>
                <FieldGroup class="mt-4 md:pr-2 flex w-full flex-col md:flex-row">
                    <VeeField v-slot="{ field, errors }" name="dni">
                        <Field :data-invalid="!!errors.length">
                            <FieldLabel for="form-user-dni">
                                {{ t('admin.users.input.dni.label') }}
                            </FieldLabel>
                            <Input id="form-user-dni" v-bind="field"
                                :placeholder="t('admin.users.input.dni.placeholder')" autocomplete="off"
                                :aria-invalid="!!errors.length" />
                            <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
                        </Field>
                    </VeeField>
                    <VeeField v-slot="{ field, errors }" name="language">
                        <Field :data-invalid="!!errors.length">
                            <FieldLabel for="form-user-language">
                                {{ t('admin.users.input.language.label') }}
                            </FieldLabel>
                            <SelectLanguage id="form-user-language" :languages="props.languages" v-bind="field"
                                :aria-invalid="!!errors.length" />
                            <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
                        </Field>
                    </VeeField>
                </FieldGroup>
                <FieldGroup class="mt-4 flex flex-col md:flex-row">
                    <VeeField v-slot="{ field, errors }" name="password">
                        <Field :data-invalid="!!errors.length">
                            <FieldLabel for="form-user-password">
                                {{ t('admin.users.input.password.label') }}
                            </FieldLabel>
                            <Input id="form-user-password" v-bind="field" type="password"
                                :placeholder="t('admin.users.input.password.placeholder')" autocomplete="off"
                                :aria-invalid="!!errors.length" />
                            <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
                        </Field>
                    </VeeField>
                    <VeeField v-slot="{ field, errors }" name="password_confirmation">
                        <Field :data-invalid="!!errors.length">
                            <FieldLabel for="form-user-password_confirmation">
                                {{ t('admin.users.input.password_confirmation.label') }}
                            </FieldLabel>
                            <Input id="form-user-password_confirmation" v-bind="field" type="password"
                                :placeholder="t('admin.users.input.password_confirmation.placeholder')" autocomplete="off"
                                :aria-invalid="!!errors.length" />
                            <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
                        </Field>
                    </VeeField>
                </FieldGroup>
            </form>
        </CardContent>
        <CardFooter>
            <Field orientation="horizontal" class="md:flex md:justify-end flex-col md:flex-row">
                <Button type="button" as="a" :href="admin_home_index_path()" variant="outline" class="w-full md:w-auto">
                    {{ props.cancelLabel || t('common.cancel') }}
                </Button>
                <Button type="submit" form="form-user" class="w-full md:w-auto">
                    {{ props.submitLabel }}
                </Button>
            </Field>
        </CardFooter>
    </Card>
</template>

<script setup lang="ts">
import { nextTick, onMounted } from 'vue'
import { toTypedSchema } from '@vee-validate/zod'
import { useForm, Field as VeeField } from 'vee-validate'
import { useI18n } from 'vue-i18n'
import { Button } from '@/components/ui/button'
import {
    Card,
    CardContent,
    CardDescription,
    CardFooter,
    CardHeader,
    CardTitle,
} from '@/components/ui/card'
import {
    Field,
    FieldError,
    FieldGroup,
    FieldLabel,
} from '@/components/ui/field'
import { Input } from '@/components/ui/input'
import SelectLanguage from '@/components/admin/user/language/inputs/SelectLanguage.vue';
import { profileEditSchema } from '@/lib/schemas/profile';
import { useTranslateErrors } from '@/lib/composables/i18n/translate_errors';
import type { InertiaErrors } from '@/types/globals';
import { admin_home_index_path } from "@/routes"
import { User } from '@/types/user';
import { ProfileEditSchema } from '@/lib/schemas/profile';


const props = defineProps<{
    description: string;
    submitLabel: string;
    languages: string[];
    title?: string;
    cancelLabel?: string;
    defaultValues?: User;
    serverErrors?: Record<string, string[]>;
}>();

const emit = defineEmits<{
    (e: 'submit', data: ProfileEditSchema): void
}>();

const { t } = useI18n();

const { translateErrors, mapServerErrorsToForm } = useTranslateErrors();
const formSchema = toTypedSchema( profileEditSchema);

const { handleSubmit, setErrors, setValues } = useForm({
    validationSchema: formSchema,
    initialValues: {
        name: '',
        dni: '',
        email: '',
        password: '',
        password_confirmation: '',
        language: '',
    },
})

onMounted(() => {
    if (props.defaultValues) {
        setValues({
            ...props.defaultValues
        })
    }
})

function applyServerErrors( errors: InertiaErrors ) {
    if (errors && Object.keys(errors).length > 0) {
        nextTick(() => {
            setErrors(mapServerErrorsToForm(errors))
        })
    }
}

const onSubmit = handleSubmit((data) => {
    emit('submit', data as ProfileEditSchema)
})

defineExpose<{
    applyServerErrors: ( errors: InertiaErrors ) => void
}>({
    applyServerErrors: ( errors: InertiaErrors ) => applyServerErrors(errors)
})
</script>