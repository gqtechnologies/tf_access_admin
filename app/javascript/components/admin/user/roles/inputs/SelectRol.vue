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
import { useI18n } from 'vue-i18n'

const { t } = useI18n()

const props = defineProps<{
  roles: string[];
}>();
</script>

<template>
  <Select>
    <SelectTrigger class="w-[180px]">
      <SelectValue :placeholder="t('users.input.rol.placeholder')" />
    </SelectTrigger>
    <SelectContent>
      <SelectGroup>
        <SelectLabel>{{ t('users.input.rol.label') }}</SelectLabel>
        <SelectItem v-for="role in roles" :value="role">
          {{ t(`roles.${role}`) }}
        </SelectItem>
      </SelectGroup>
    </SelectContent>
  </Select>
</template>
