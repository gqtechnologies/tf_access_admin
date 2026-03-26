<template>
  <div class="relative h-screen flex flex-col items-center justify-center overflow-hidden">
    <div v-if="organization?.cover_path" class="w-screen h-screen">
      <img :src="organization.cover_path" alt="Cover" class="w-screen h-screen object-cover" loading="lazy">
    </div>
    <div class="h-screen w-full absolute top-0 left-0 z-10 flex flex-col items-center justify-center"
      :class="{ 'bg-black/50': organization?.cover_path }">
      <div class="mb-8 min-w-52 flex items-center justify-center">
        <img v-if="organization?.logo_path" :src="organization.logo_path" alt="Logo"
          class="w-24 h-24 object-cover rounded-xl">
        <PersonStandingIcon v-else class="size-16 mb-2"
          :class="{ 'text-white': organization?.cover_path }" />
      </div>
      <h1 class="text-2xl font-bold" :class="{ 'text-white': organization?.cover_path }">{{ t('home.title') }}</h1>
      <p class="text-sm" :class="{ 'text-white': organization?.cover_path }">{{ t('home.description') }}</p>
      <p v-if="organization" class="text-xs mt-1" :class="{ 'text-white': organization?.cover_path }">{{
        organization.name }}</p>
      <div v-if="organization?.id" class="mt-4">
        <Button variant="default" class="min-w-52" @click="onClickLogin">
          {{ t('home.login') }}
        </Button>

      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { Organization } from '@/types/organization';
import { PersonStandingIcon } from 'lucide-vue-next';
import { useI18n } from 'vue-i18n';
import { new_user_session_path } from '@/routes';
import { Button } from '@/components/ui/button';
const { t } = useI18n();

const props = defineProps<{
  organization: Organization
}>()

const onClickLogin = () => {
  window.location.href = new_user_session_path()
}
</script>