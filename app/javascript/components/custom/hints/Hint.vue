<template>
    <HoverCard>
    <HoverCardTrigger
    class="cursor-pointer"
    ><CircleQuestionMarkIcon class="w-4 h-4" /></HoverCardTrigger>
    <HoverCardContent align="start" class="text-sm">
        {{ text }}
    </HoverCardContent>
  </HoverCard>
</template>

<script setup lang="ts">
import { HoverCard, HoverCardTrigger, HoverCardContent } from "@/components/ui/hover-card"
import { CircleQuestionMarkIcon } from "lucide-vue-next"
defineProps<{
    text: string
}>()
</script>