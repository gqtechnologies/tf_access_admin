<script setup lang="ts">
import type { CollapsibleContentProps } from "reka-ui"
import { CollapsibleContent } from "reka-ui"
import type { HTMLAttributes } from "vue"
import { reactiveOmit } from "@vueuse/core"
import { cn } from "@/lib/utils"

const props = defineProps<
  CollapsibleContentProps & { class?: HTMLAttributes["class"] }
>()

const delegated = reactiveOmit(props, "class")
</script>

<template>
  <CollapsibleContent
    data-slot="collapsible-content"
    v-bind="delegated"
    :class="
      cn(
        'overflow-hidden data-[state=closed]:animate-collapsible-up data-[state=open]:animate-collapsible-down',
        props.class,
      )
    "
  >
    <slot />
  </CollapsibleContent>
</template>
