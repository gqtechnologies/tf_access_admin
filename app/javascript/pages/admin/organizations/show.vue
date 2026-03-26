<template>
  <div>
    <Header :itemsBreadcrumb="itemsBreadcrumb" :title="t('admin.organizations.show.title')" />
    <Card class="w-full">

      <CardContent>
        <div class="flex flex-col items-center gap-4">
          <div class="w-full h-56 flex flex-col gap-2">
            <Label class="text-sm font-bold">{{ t("admin.organizations.show.cover") }}</Label>
            <div class="w-full h-56 rounded-md overflow-hidden">
              <img :src="props.organization.cover_path" :alt="t('admin.organizations.show.cover')"
              class="w-full h-full object-cover" />
            </div>
          </div>
          <div class="flex flex-col gap-2 w-full md:w-[60%] py-4">
            <div class="w-full flex justify-center">
              <Label class="text-lg">{{ t("admin.organizations.show.subtitle") }}</Label>
            </div>
            <div class="flex justify-between items-center min-h-12 gap-2 border-b border-gray-200 pb-2">
              <Label class="text-sm font-bold">{{ t("admin.organizations.show.name") }}</Label>
              <p class="pl-8">{{ props.organization.name }}</p>
            </div>
            <div class="flex justify-between items-center min-h-12 gap-2 border-b border-gray-200 pb-2">
              <Label class="text-sm font-bold">{{ t("admin.organizations.show.subdomain") }}</Label>
              <p class="pl-8">{{ props.organization.subdomain }}</p>
            </div>

            <div class="flex justify-between items-center min-h-12 gap-2 border-b border-gray-200 pb-2">
              <Label class="text-sm font-bold">{{ t("admin.organizations.show.plan") }}</Label>
              <p class="pl-8">{{ t(`plans.${props.organization.plan}`) }}</p>
            </div>
            <div class="flex justify-between items-center min-h-12 gap-2 border-b border-gray-200 pb-2">
              <Label class="text-sm font-bold">{{ t("admin.organizations.show.logo") }}</Label>
              <div class="w-32 h-32 rounded-md overflow-hidden">
                <img :src="props.organization.logo_path" :alt="t('admin.organizations.show.logo')"
                class="w-full h-full object-cover" />
              </div>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from "vue-i18n"
import Header from '@/components/admin/layout/Header.vue'
import { getOrganizationsBreadcrumbs } from '@/lib/breadcrumbs/organization'
import type { Organization } from '@/types/organization'
import { computed } from "vue"
import { Card, CardContent } from "@/components/ui/card"
import { Label } from "@/components/ui/label"
const { t } = useI18n()

const props = defineProps<{
  organization: Organization
}>()
const itemsBreadcrumb = computed(() => getOrganizationsBreadcrumbs(t))
</script>