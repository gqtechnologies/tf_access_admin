<template>
    <div>
        <Breadcrumb>
            <BreadcrumbList>
                <BreadcrumbItem v-for="(item, index) in items" :key="item.href">
                    <BreadcrumbLink v-if="item.href" :href="item.href">
                        {{ item.label }}
                    </BreadcrumbLink>
                    <BreadcrumbPage v-else>
                        {{ item.label }}
                    </BreadcrumbPage>
                    <BreadcrumbSeparator  v-if="index < items.length - 1" />
                </BreadcrumbItem>
            </BreadcrumbList>
        </Breadcrumb>
    </div>
</template>

<script setup lang="ts">
import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from '@/components/ui/breadcrumb'
import type { BreadcrumbItem as BreadcrumbItemType } from '@/types/layout'
const props = defineProps<{
    items: BreadcrumbItemType[]
}>()
</script>