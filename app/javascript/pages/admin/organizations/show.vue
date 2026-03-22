<template>
  <div>
    <Header :itemsBreadcrumb="itemsBreadcrumb" :title="t('admin.organizations.show.title')" />
    <Card class="w-full">

      <CardContent>
        asds
      </CardContent>
    </Card>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from "vue-i18n"
import Header from '@/components/admin/layout/Header.vue'
import{ getOrganizationsBreadcrumbs } from '@/lib/breadcrumbs/organization'
import type { Organization } from '@/types/organization'
import { computed } from "vue"
import { Card, CardContent } from "@/components/ui/card"
const { t } = useI18n()

const props = defineProps<{
  organization: Organization
}>()
const itemsBreadcrumb = computed(() => getOrganizationsBreadcrumbs(t))
</script>