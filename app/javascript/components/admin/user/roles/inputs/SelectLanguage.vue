<script setup lang="ts">
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectLabel,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { computed, useAttrs } from 'vue'
import { useI18n } from 'vue-i18n'

defineOptions({ inheritAttrs: false })

const { t } = useI18n()

const props = defineProps<{
  languages: string[];
  id?: string;
}>();

const attrs = useAttrs() as {
  value?: string;
  onChange?: (e: unknown) => void;
  'onUpdate:modelValue'?: (v: string | undefined | null) => void;
  'aria-invalid'?: boolean | string;
  [key: string]: unknown;
};

const triggerAttrs = computed(() => {
  const { value, onChange, 'onUpdate:modelValue': _onUpdate, ...rest } = attrs as Record<string, unknown>;
  return rest;
});

function onUpdateValue(v: unknown) {
  const fn = attrs['onUpdate:modelValue'];
  const value = typeof v === 'string' ? v : undefined;
  if (typeof fn === 'function') fn(value);
  else attrs.onChange?.(v);
}
</script>

<template>
  <Select
    :model-value="attrs.value"
    @update:model-value="onUpdateValue"
  >
    <SelectTrigger :id="props.id" class="w-[180px]" v-bind="triggerAttrs">
      <SelectValue :placeholder="t('users.input.language.placeholder')" />
    </SelectTrigger>
    <SelectContent>
      <SelectGroup>
        <SelectLabel>{{ t('users.input.language.label') }}</SelectLabel>
        <SelectItem v-for="language in languages" :key="language" :value="language">
          {{ t(`languages.${language}`) }}
        </SelectItem>
      </SelectGroup>
    </SelectContent>
  </Select>
</template>
