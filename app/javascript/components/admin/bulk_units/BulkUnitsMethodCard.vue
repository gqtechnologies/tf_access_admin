<template>
  <Label
    :for="itemId"
    :class="
      cn(
        'flex cursor-pointer items-start gap-3 rounded-lg border border-border p-4 transition-colors hover:bg-muted/40',
        'has-[[data-state=checked]]:border-primary has-[[data-state=checked]]:bg-primary/5 has-[[data-state=checked]]:ring-1 has-[[data-state=checked]]:ring-primary/20',
      )
    "
  >
    <RadioGroupItem :id="itemId" :value="value" class="mt-1" />
    <span class="flex min-w-0 flex-1 flex-col gap-2">
      <span class="flex items-center gap-3">
        <span
          :class="
            cn(
              'inline-flex size-12 shrink-0 items-center justify-center rounded-lg bg-muted text-primary',
              iconColor,
            )
          "
          aria-hidden="true"
        >
          <component :is="icon" class="size-6" />
        </span>
        <span class="min-w-0 flex-1 space-y-1">
          <span class="block text-sm font-semibold text-foreground">{{ title }}</span>
          <span class="block text-xs text-muted-foreground">{{ description }}</span>
          <Badge
            v-if="badge"
            :variant="badgeVariant"
            class="mt-2 w-fit rounded-md text-xs"
          >
            {{ badge }}
          </Badge>
        </span>
      </span>
    </span>
  </Label>
</template>

<script setup lang="ts">
import type { Component } from 'vue'
import { useId } from 'vue'
import { Badge } from '@/components/ui/badge'
import { Label } from '@/components/ui/label'
import { RadioGroupItem } from '@/components/ui/radio-group'
import type { BulkUnitsCreationMethod } from '@/lib/composables/bulk_units/useBulkUnitsImportDrawer'
import { cn } from '@/lib/utils'

withDefaults(
  defineProps<{
    value: BulkUnitsCreationMethod
    title: string
    description: string
    icon: Component
    iconColor?: string
    badge?: string
    badgeVariant?: 'default' | 'secondary' | 'outline' | 'destructive'
  }>(),
  {
    badgeVariant: 'secondary',
    iconColor: '',
  }
)

const itemId = useId()
</script>
