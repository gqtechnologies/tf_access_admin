<template>
  <div class="flex flex-col items-center justify-center h-screen">
    <PersonStandingIcon class="size-16 mb-2" />
    <h1 class="text-2xl font-bold">{{ t('home.title') }}</h1>
    <p class="text-sm text-gray-500">{{ t('home.description') }}</p>
  </div>
</template>

<script setup>
import { PersonStandingIcon } from 'lucide-vue-next';
import { useI18n } from 'vue-i18n';
const { t } = useI18n();
</script>