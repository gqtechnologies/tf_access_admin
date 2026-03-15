<template>
    <div class="w-full flex flex-col items-start justify-between">
        <Breadcrumb :items="itemsBreadcrumb" />
        <h1 class="text-3xl font-bold mt-2 mb-4">{{ title }}</h1>
    </div>
</template>

<script setup lang="ts">
import Breadcrumb from '@/components/admin/layout/Breadcrumb.vue'
import type { BreadcrumbItem } from '@/types/layout'

const props = defineProps<{
    title: string
    itemsBreadcrumb: BreadcrumbItem[]
}>()
</script>