<template>
  <div class="flex justify-center items-center h-screen">
    <div class="md:w-1/2 h-screen flex justify-center items-center">
      <Card class="md:w-2/3 h-fit mx-auto p-4">
        <CardHeader>
          <CardTitle>Iniciar sesión</CardTitle>
          <CardDescription>Inicia sesión para continuar</CardDescription>
        </CardHeader>
        <CardContent>
          <form @submit.prevent="onSubmit" class="flex flex-col gap-4">
            <Field>
              <VeeField name="user.email" v-slot="{ field, errorMessage }">
                <FieldLabel for="user.email">
                  Email
                </FieldLabel>
                <InputGroup>
                  <InputGroupInput
                    id="user.email"
                    type="email"
                    v-bind="field"
                    placeholder="Enter your email"
                  />
                  <InputGroupAddon>
                    <MailIcon />
                  </InputGroupAddon>
                </InputGroup>
                <FieldError v-if="errorMessage">{{ errorMessage }}</FieldError>
              </VeeField>
            </Field>

            <Field>
              <VeeField name="user.password" v-slot="{ field, errorMessage }">
                <FieldLabel for="user.password">
                  Contraseña
                </FieldLabel>
                <InputGroup>
                  <InputGroupInput         
                    id="user.password"
                    type="password"
                    v-bind="field"
                    placeholder="Enter your password"
                  />
                  <InputGroupAddon>
                    <LockIcon />
                  </InputGroupAddon>
                </InputGroup>
                <FieldError v-if="errorMessage">{{ errorMessage }}</FieldError>
              </VeeField>
            </Field>
            <Button type="submit" :disabled="inertiaForm.processing">
              {{ inertiaForm.processing ? "Entrando…" : "Entrar" }}
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
import { Card } from "@/components/ui/card"
import { InputGroup, InputGroupInput, InputGroupAddon } from "@/components/ui/input-group"
import { Button } from "@/components/ui/button"
import { MailIcon, LockIcon } from "lucide-vue-next"
import { loginSchema } from "@/lib/schemas/auth"
import { useForm, Field as VeeField } from "vee-validate"
import { toTypedSchema } from "@vee-validate/zod"

const props = defineProps({
  submit_url: { type: String, required: true },
  errors: { type: Object, default: () => ({}) },
})

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
  () => {
    // Opcional: segundo callback cuando la validación falla
  }
);
</script>