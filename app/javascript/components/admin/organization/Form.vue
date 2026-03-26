<template>
    <Card class="w-full">
        <CardHeader>
            <CardTitle v-if="props.title">{{ props.title }}</CardTitle>
            <CardDescription>
                {{ props.description }}
            </CardDescription>
        </CardHeader>
        <CardContent>
            <form id="form-organization" @submit="onSubmit">
                <FieldGroup class="mt-4 mb-8 flex justify-center w-full">
                    <AvatarInput
                        name="cover"
                        for="form-organization-cover"
                        accept="image/*"
                        :label="t('admin.organizations.input.cover.label')"
                        :defaultValue="props.defaultValues?.cover_path"
                        :alt="props.defaultValues?.name!"
                        @change="onCoverChange($event)"
                        @clear="clearCover()"
                        defaultImageType="cover"
                    />
                </FieldGroup>
                <FieldGroup class="flex flex-col md:flex-row">
                    <VeeField v-slot="{ field, errors }" name="name">
                        <Field :data-invalid="!!errors.length">
                            <FieldLabel for="form-organization-name">
                                {{ t('admin.organizations.input.name.label') }}
                            </FieldLabel>
                            <Input id="form-organization-name" v-bind="field"
                                :placeholder="t('admin.organizations.input.name.placeholder')" autocomplete="off"
                                :aria-invalid="!!errors.length" />
                            <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
                        </Field>
                    </VeeField>
                    <VeeField v-slot="{ field, errors }" name="subdomain">
                        <Field :data-invalid="!!errors.length">
                            <FieldLabel for="form-organization-subdomain">
                                {{ t('admin.organizations.input.subdomain.label') }}
                            </FieldLabel>
                            <Input id="form-organization-subdomain" v-bind="field"
                                :placeholder="t('admin.organizations.input.subdomain.placeholder')" autocomplete="off"
                                :aria-invalid="!!errors.length"
                                :disabled="editMode"
                                />
                            <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
                        </Field>
                    </VeeField>
                </FieldGroup>
                <FieldGroup class="mt-4 mb-8 flex justify-center w-1/2 pr-3">
                    <AvatarInput
                        name="logo"
                        for="form-organization-logo"
                        accept="image/*"
                        label="Logo"
                        placeholder="Selecciona tu logo"
                        :defaultValue="props.defaultValues?.logo_path"
                        :alt="props.defaultValues?.name!"
                        @change="onLogoChange($event)"
                        @clear="clearLogo()"
                        defaultImageType="cover"
                    />
                </FieldGroup>
            </form>
        </CardContent>
        <CardFooter>
            <Field orientation="horizontal" class="md:flex md:justify-end flex-col md:flex-row">
                <Button type="button" as="a" :href="admin_organizations_path()" variant="outline" class="w-full md:w-auto">
                    {{ props.cancelLabel || t('common.cancel') }}
                </Button>
                <Button type="submit" form="form-organization" class="w-full md:w-auto cursor-pointer">
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
import AvatarInput from '@/components/custom/inputs/AvatarInput.vue';
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
import { nameMax, nameMin, organizationSubdomainMax, organizationSubdomainMin, OrganizationSchema, organizationSchema } from '@/lib/schemas/organization';
import { useTranslateErrors } from '@/lib/composables/i18n/translate_errors';
import type { InertiaErrors } from '@/types/globals';
import { admin_organizations_path } from "@/routes"
import { Organization } from '@/types/organization';


const props = defineProps<{
    description: string;
    title?: string;
    cancelLabel?: string;
    defaultValues?: Organization;
    serverErrors?: Record<string, string[]>;
    submitLabel: string;
    editMode?: boolean;
}>();

const emit = defineEmits<{
    (e: 'submit', data: OrganizationSchema): void
}>();

const { t } = useI18n();

const { translateErrors, mapServerErrorsToForm } = useTranslateErrors({
    name_max: nameMax,
    name_min: nameMin,
    subdomain_max: organizationSubdomainMax,
    subdomain_min: organizationSubdomainMin,
});
const formSchema = toTypedSchema( organizationSchema);

const { handleSubmit, setErrors, setValues, setFieldValue } = useForm({
    validationSchema: formSchema,
    initialValues: {
        name: '',
        subdomain: '',
        cover: null,
        logo: null,
        remove_cover: false,
        remove_logo: false,
    },
})

onMounted(() => {
    if (props.defaultValues) {
        const { cover_path, logo_path, ...rest } = props.defaultValues;
        setValues({
            ...rest,
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
    emit('submit', data as OrganizationSchema)
})

function onCoverChange(event: Event) {
    const input = event.target as HTMLInputElement
    const file = input.files?.[0] ?? null
    setFieldValue('remove_cover', false)
    setFieldValue('cover', file, true)
}

function clearCover() {
    setFieldValue('remove_cover', true)
    setFieldValue('cover', null)
}

function onLogoChange(event: Event) {
    const input = event.target as HTMLInputElement
    const file = input.files?.[0] ?? null
    setFieldValue('remove_logo', false)
    setFieldValue('logo', file, true)
}

function clearLogo() {
    setFieldValue('remove_logo', true)
    setFieldValue('logo', null)
}

defineExpose<{
    applyServerErrors: ( errors: InertiaErrors ) => void
}>({
    applyServerErrors: ( errors: InertiaErrors ) => applyServerErrors(errors)
})
</script>