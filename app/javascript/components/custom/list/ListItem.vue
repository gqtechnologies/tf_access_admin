<template>
  <div :class="cn('flex items-center justify-between', props.class)">
    <div v-if="props.as === 'span'" class="w-full flex items-center p-2 gap-2">
        <slot />
    </div>
    <div v-else-if="props.as === 'link'" class="w-full flex items-center gap-2 rounded-md hover:bg-gray-200 transition-colors">
        <Link :href="props.href" class="w-full h-full p-2">
            <slot />
        </Link>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { HTMLAttributes } from "vue";
import { cn } from "@/lib/utils";
import { Link } from "@inertiajs/vue3";

const props = withDefaults(
  defineProps<{
    class?: HTMLAttributes["class"];
    as?: "span" | "link";
    href?: string;
  }>(),
  { as: "span", class: "" }
);
</script>