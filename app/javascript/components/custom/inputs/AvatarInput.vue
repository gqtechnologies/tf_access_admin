<template>
    <VeeField v-slot="{ handleBlur, errors }" :name="name">
        <Field :data-invalid="!!errors.length">
            <FieldLabel v-if="label" for="form-organization-name">{{ label }}</FieldLabel>
            <div class="relative w-full flex justify-center">
                <div class="relative"
                    :class="defaultImageType === 'cover' ? 'w-full h-56' : ''"
                >
                    <Avatar class="border-2 border-gray-200"
                            :class="defaultImageType === 'cover' ? '!rounded-sm bg-gray-200 !w-full !h-full' : 'h-32 w-32 '"
                        >
                        <AvatarImage
                            v-if="previewUrl || defaultValue"
                            :src="(previewUrl || defaultValue) ?? ''"
                            :alt="alt"
                            :class="defaultImageType === 'cover' ? '!object-cover' : ''"
                        />
                        <AvatarFallback class="bg-gray-200 uppercase text-3xl">{{ getStringFallback(alt) }}</AvatarFallback>
                    </Avatar>
                    <div class="absolute right-0 bottom-0 p-1 -translate-x-1/2 rounded-sm cursor-pointer"
                        :class="defaultImageType === 'cover' ? 'bg-white !-right-[30px] !-bottom-[15px] border-2 border-gray-200' : 'bg-gray-200 border-2 border-white'"
                        @click="onEditAvatar"
                    >
                        <PencilIcon fill="transparent" color="currentColor" :size=" defaultImageType === 'cover' ? 24 : 16" class="text-muted-foreground hover:text-foreground" />
                    </div>
                </div>
                <Input :id="for" type="file" :accept="accept" :aria-invalid="!!errors.length" class="pr-10 hidden"
                    @change="changeFile($event)" @blur="handleBlur" />
            </div>

            <FieldError v-if="errors.length" :errors="translateErrors(errors)" />
        </Field>
    </VeeField>
</template>
<script setup lang="ts">
import { ref, onBeforeUnmount } from 'vue'
import { Input } from '@/components/ui/input';
import { Field, FieldError, FieldLabel } from '@/components/ui/field';
import { Avatar, AvatarImage, AvatarFallback } from '@/components/ui/avatar';
import { Field as VeeField } from 'vee-validate'
import { PencilIcon } from 'lucide-vue-next'
import { useTranslateErrors } from '@/lib/composables/i18n/translate_errors';
import { getStringFallback } from '@/lib/user';

const props = withDefaults(defineProps<{
    name: string;
    for: string;
    accept: string;
    defaultValue: string | null | undefined;
    alt: string;
    defaultImageType: 'profile' | 'cover';
    label?: string;
}>(), {
    defaultImageType: 'cover',
    alt: "",
})

const emit = defineEmits<{
    (e: 'change', event: Event): void
    (e: 'clear'): void
}>();

const { translateErrors } = useTranslateErrors();

const previewUrl = ref<string | null>(null)

const changeFile = (e: Event) => {
    const input = e.target as HTMLInputElement | null
    const file = input?.files?.[0]

    if (previewUrl.value) {
        URL.revokeObjectURL(previewUrl.value)
        previewUrl.value = null
    }

    if (file) {
        previewUrl.value = URL.createObjectURL(file)
        emit('change', e)
        return
    }

    emit('clear')
}

const onEditAvatar = () => {
    const input = document.querySelector(`#${props.for}`) as HTMLInputElement | null
    if (input) {
        input.click()
    }
}

onBeforeUnmount(() => {
    if (previewUrl.value) {
        URL.revokeObjectURL(previewUrl.value)
    }
})
</script>