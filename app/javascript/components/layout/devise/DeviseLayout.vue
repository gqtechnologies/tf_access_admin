<template>
    <div class="flex justify-center items-center h-screen">
        <div class="md:w-1/2 h-screen flex justify-center items-center">
            <Card class="md:w-2/3 h-fit mx-auto p-4">
                <CardHeader>
                    <CardTitle>{{ title }}</CardTitle>
                    <CardDescription>{{ description }}</CardDescription>
                </CardHeader>
                <CardContent>
                    <slot />
                </CardContent>
            </Card>
        </div>
        <div class="w-1/2 hidden md:block md:h-screen bg-gray-100">
        </div>
    </div>
</template>

<script setup lang="ts">
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card"
defineProps<{
    title: string
    description: string
}>()
</script>