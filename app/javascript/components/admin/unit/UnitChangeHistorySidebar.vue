<template>
  <Card class="flex h-full flex-col w-full">
    <CardHeader>
      <CardTitle class="text-base">{{ t('admin.units.show.change_history.title') }}</CardTitle>
    </CardHeader>
    <CardContent class="flex flex-1 flex-col">
      <Timeline
        :entries="entries"
        :empty-title="t('admin.units.show.change_history.empty_title')"
        :empty-description="t('admin.units.show.change_history.empty_description')"
        :locale="locale"
      />
      <Button variant="outline" class="mt-6 w-full" disabled>
        {{ t('admin.units.show.change_history.view_all') }}
      </Button>
    </CardContent>
  </Card>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import Timeline from '@/components/admin/shared/Timeline.vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import type { UnitChangeHistoryEntry } from '@/types/unit'

defineProps<{
  entries: UnitChangeHistoryEntry[]
}>()

const { t, locale } = useI18n()
</script>
