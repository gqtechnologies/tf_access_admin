<template>
  <div>
    <Header :itemsBreadcrumb="itemsBreadcrumb" :title="t('admin.home.title')" />
    <div class="grid auto-rows-min gap-4 md:grid-cols-3">
      <div class="aspect-video rounded-xl bg-muted/50" />
      <div class="aspect-video rounded-xl bg-muted/50" />
      <div class="aspect-video rounded-xl bg-muted/50" />
    </div>
    <div class="min-h-[100vh] flex-1 rounded-xl bg-muted/50 md:min-h-min" />
  </div>
</template>
<script setup lang="ts">
import Header from '@/components/admin/layout/Header.vue'
import { computed } from 'vue'
import { getHomeBreadcrumbs } from '@/lib/breadcrumbs/home'
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
const itemsBreadcrumb = computed(() => getHomeBreadcrumbs(t))
</script>