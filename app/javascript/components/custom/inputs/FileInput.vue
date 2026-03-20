<template>
    <VeeField v-slot="{ handleBlur, errors, value }" :name="name">
        <Field :data-invalid="!!errors.length">
            <FieldLabel :for="for">
                {{ label }}
            </FieldLabel>

            <div class="relative">
                <Input :id="for" type="file" :accept="accept" :aria-invalid="!!errors.length" class="pr-10"
                    @change="changeFile($event)" @blur="handleBlur" />

                <button v-if="value" type="button"
                    class="absolute right-2 top-1/2 -translate-y-1/2 inline-flex h-6 w-6 items-center justify-center rounded-sm text-muted-foreground hover:text-foreground"
                    @click="clearFile($event)" :aria-label="t('common.clear')">
                    <X class="h-4 w-4" />
                </button>
            </div>

            <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
        </Field>
    </VeeField>
</template>
<script setup lang="ts">
import { Input } from '@/components/ui/input';
import { Field, FieldLabel, FieldError } from '@/components/ui/field';
import { Field as VeeField } from 'vee-validate'
import { X } from 'lucide-vue-next'
import { useTranslateErrors } from '@/lib/composables/i18n/translate_errors';
import { useI18n } from 'vue-i18n';

defineProps<{
    name: string;
    for: string;
    accept: string;
    label: string;
    placeholder: string;
}>()

const emit = defineEmits<{
    (e: 'change', event: Event): void
    (e: 'clear'): void
}>();

const { t } = useI18n();

const { translateErrors } = useTranslateErrors();
const changeFile = (e: Event) => {
    emit('change', e)
}

const clearFile = (e: Event) => {
    const button = e.currentTarget as HTMLElement
    const wrapper = button.closest('.relative')
    const input = wrapper?.querySelector('input[type="file"]') as HTMLInputElement | null

    if (input) {
        input.value = ''
    }
    emit('clear')
}
</script>