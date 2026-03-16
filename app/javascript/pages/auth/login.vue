<template>
  <div class="flex justify-center items-center h-screen">
    <div class="md:w-1/2 h-screen flex justify-center items-center">
      <Card class="md:w-2/3 h-fit mx-auto p-4">
        <CardHeader>
          <CardTitle>{{ t('admin.login.title') }}</CardTitle>
          <CardDescription>{{ t('admin.login.description') }}</CardDescription>
        </CardHeader>
        <CardContent>
          <form @submit.prevent="onSubmit" class="flex flex-col gap-4">
            <Field>
              <VeeField name="user.email" v-slot="{ field, errorMessage }">
                <FieldLabel for="user.email">
                  {{ t('admin.login.input.email.label') }}
                </FieldLabel>
                <InputGroup>
                  <InputGroupInput
                    id="user.email"
                    type="email"
                    v-bind="field"
                    :placeholder="t('admin.login.input.email.placeholder')"
                  />
                  <InputGroupAddon>
                    <MailIcon />
                  </InputGroupAddon>
                </InputGroup>
                <FieldError v-if="errorMessage">{{ t('admin.login.validation.email.required') }}</FieldError>
              </VeeField>
            </Field>

            <Field>
              <VeeField name="user.password" v-slot="{ field, errorMessage }">
                <FieldLabel for="user.password">
                  {{ t('admin.login.input.password.label') }}
                </FieldLabel>
                <InputGroup>
                  <InputGroupInput         
                    id="user.password"
                    type="password"
                    v-bind="field"
                    :placeholder="t('admin.login.input.password.placeholder')"
                  />
                  <InputGroupAddon>
                    <LockIcon />
                  </InputGroupAddon>
                </InputGroup>
                <FieldError v-if="inertiaForm.errors.base">
                  {{ t('admin.login.errors.invalid') }}
                </FieldError>
              </VeeField>
            </Field>
            <Button type="submit" :disabled="inertiaForm.processing">
              {{ inertiaForm.processing ? t('admin.login.processing') : t('admin.login.submit') }}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
    <div class="w-1/2 hidden md:block md:h-screen bg-gray-100">
    </div>
  </div>
</template>

<script setup>
import { Head, useForm as useInertiaForm } from "@inertiajs/vue3"
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card"
import { InputGroup, InputGroupInput, InputGroupAddon } from "@/components/ui/input-group"
import { Button } from "@/components/ui/button"
import { MailIcon, LockIcon } from "lucide-vue-next"
import { loginSchema } from "@/lib/schemas/auth"
import { useForm, Field as VeeField } from "vee-validate"
import { toTypedSchema } from "@vee-validate/zod"
import { Field, FieldLabel, FieldError } from "@/components/ui/field"
import { useI18n } from "vue-i18n"
const props = defineProps({
  submit_url: { type: String, required: true },
  errors: { type: Object, default: () => ({}) },
})
const { t } = useI18n()
const inertiaForm = useInertiaForm({
  user: {
    email: "",
    password: ""
  },
});

const { handleSubmit, setFieldError, setErrors } = useForm({
  validationSchema: toTypedSchema(loginSchema),
  initialValues: inertiaForm.data(),
});
const onSubmit = handleSubmit(
  (values) => {
    inertiaForm.transform((data) => values).post(props.submit_url);
  },
  () => {}
);
</script>