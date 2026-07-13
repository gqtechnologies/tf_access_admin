<template>
  <div class="space-y-6">
    <div class="rounded-lg border border-green-200 bg-green-50/80 p-4 dark:border-green-900 dark:bg-green-950/30">
      <div class="flex items-start gap-3">
        <CheckCircle2 class="mt-0.5 size-5 shrink-0 text-green-600" aria-hidden="true" />
        <div class="min-w-0 flex-1 space-y-4">
          <div>
            <h3 class="text-base font-semibold text-green-900 dark:text-green-100">
              {{ t('admin.people.bulk_import.import.ready.title') }}
            </h3>
            <p class="text-sm text-green-800/90 dark:text-green-200/80">
              {{ t('admin.people.bulk_import.import.ready.description') }}
            </p>
          </div>

          <div class="grid gap-3 sm:grid-cols-3">
            <Card
              v-for="card in summaryStatCards"
              :key="card.key"
              class="border-green-100 bg-white/70 py-3 dark:border-green-900 dark:bg-background/60"
            >
              <CardContent class="flex items-center gap-3 px-4">
                <component :is="card.icon" class="size-5 shrink-0" :class="card.iconClass" />
                <div>
                  <p class="text-xs text-muted-foreground">{{ card.label }}</p>
                  <p class="text-lg font-semibold tabular-nums">{{ card.value }}</p>
                </div>
              </CardContent>
            </Card>
          </div>

          <div
            v-if="summary && summary.errorRows > 0"
            class="flex items-start gap-2 rounded-md border border-amber-200 bg-amber-50/80 px-3 py-2 text-sm text-amber-900 dark:border-amber-900 dark:bg-amber-950/40 dark:text-amber-100"
          >
            <AlertTriangle class="size-4 shrink-0" aria-hidden="true" />
            <span>{{ t('admin.people.bulk_import.import.ready.errors_pending') }}</span>
          </div>

          <label
            v-if="hasPendingIssues"
            class="flex cursor-pointer items-start gap-3 rounded-md border border-green-200/80 bg-white/60 px-3 py-3 dark:border-green-900 dark:bg-background/40"
          >
            <Checkbox
              :model-value="importValidRowsOnly"
              class="mt-0.5"
              :disabled="isProcessing || isCompleted"
              @update:model-value="emit('update:importValidRowsOnly', Boolean($event))"
            />
            <span class="text-sm leading-snug">{{ t('admin.people.bulk_import.import.ready.valid_rows_only') }}</span>
          </label>
        </div>
      </div>
    </div>

    <Card class="gap-0 overflow-hidden py-0" :class="progressCardBorderClass">
      <CardHeader class="border-b px-4 py-3">
        <CardTitle class="text-sm font-semibold">{{ t('admin.people.bulk_import.import.progress.title') }}</CardTitle>
      </CardHeader>
      <CardContent class="space-y-4 px-4 py-4">
        <div class="space-y-2">
          <p class="text-sm font-medium">{{ progressStatusTitle }}</p>
          <p class="text-xs text-muted-foreground">{{ progressStatusDescription }}</p>
        </div>

        <div class="space-y-2">
          <div class="flex items-center justify-between text-xs text-muted-foreground">
            <span>{{ progressPercentage }}%</span>
            <span v-if="progressCounter">{{ progressCounter }}</span>
          </div>
          <div
            class="h-2 w-full overflow-hidden rounded-full bg-muted"
            role="progressbar"
            :aria-valuenow="progressPercentage"
            aria-valuemin="0"
            aria-valuemax="100"
          >
            <div
              class="h-full rounded-full bg-primary transition-all duration-500 ease-out"
              :style="{ width: `${progressPercentage}%` }"
            />
          </div>
        </div>

        <ul
          v-if="displayLogs.length > 0"
          class="max-h-48 space-y-2 overflow-y-auto rounded-md border bg-muted/20 p-3"
        >
          <li
            v-for="(log, index) in displayLogs"
            :key="`${log.rowNumber}-${log.createdAt ?? index}`"
            class="flex items-start justify-between gap-3 text-sm"
          >
            <div class="flex min-w-0 items-start gap-2">
              <component :is="logIcon(log.status)" class="mt-0.5 size-4 shrink-0" :class="logIconClass(log.status)" aria-hidden="true" />
              <span class="min-w-0">
                {{ t('admin.people.bulk_import.import.progress.log_line', { row: log.rowNumber, message: log.message }) }}
              </span>
            </div>
            <span class="shrink-0 text-xs tabular-nums text-muted-foreground">{{ formatLogTime(log.createdAt) }}</span>
          </li>
        </ul>
      </CardContent>
    </Card>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { AlertTriangle, CheckCircle2, CircleAlert, CircleCheck, Copy, UserPlus } from 'lucide-vue-next'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Checkbox } from '@/components/ui/checkbox'
import type {
  BulkImportImportLog,
  BulkImportImportLogStatus,
  BulkImportImportPhase,
  BulkImportImportProgress,
  BulkImportImportSummary,
} from '@/types/bulk_import'

const props = defineProps<{
  summary: BulkImportImportSummary | null
  phase: BulkImportImportPhase
  importValidRowsOnly: boolean
  progress: BulkImportImportProgress | null
  logs: BulkImportImportLog[]
  hasPendingIssues: boolean
  formatLogTime: (iso?: string) => string
}>()

const emit = defineEmits<{
  'update:importValidRowsOnly': [value: boolean]
}>()

const { t } = useI18n()

const isProcessing = computed(() => props.phase === 'processing')
const isCompleted = computed(() => props.phase === 'completed')
const isFailed = computed(() => props.phase === 'failed')

const summaryStatCards = computed(() => {
  const current = props.summary
  return [
    {
      key: 'new',
      label: t('admin.people.bulk_import.import.ready.stats.new_people'),
      value: current?.newUnits ?? 0,
      icon: UserPlus,
      iconClass: 'text-green-600',
    },
    {
      key: 'duplicates',
      label: t('admin.people.bulk_import.import.ready.stats.duplicates'),
      value: current?.duplicateRows ?? 0,
      icon: Copy,
      iconClass: 'text-amber-600',
    },
    {
      key: 'errors',
      label: t('admin.people.bulk_import.import.ready.stats.errors'),
      value: current?.errorRows ?? 0,
      icon: AlertTriangle,
      iconClass: 'text-destructive',
    },
  ]
})

const progressPercentage = computed(() => {
  if (isCompleted.value) return 100
  return props.progress?.percentage ?? 0
})

const progressCounter = computed(() => {
  if (!props.progress || props.progress.total === 0) return null
  return t('admin.people.bulk_import.import.progress.counter', {
    processed: props.progress.created,
    total: props.progress.total,
  })
})

const progressStatusTitle = computed(() => {
  if (isCompleted.value) return t('admin.people.bulk_import.import.progress.completed.title')
  if (isFailed.value) return t('admin.people.bulk_import.import.progress.failed.title')
  if (isProcessing.value) return t('admin.people.bulk_import.import.progress.processing.title')
  return t('admin.people.bulk_import.import.progress.waiting.title')
})

const progressStatusDescription = computed(() => {
  if (isCompleted.value) {
    return t('admin.people.bulk_import.import.progress.completed.description', {
      created: props.progress?.created ?? 0,
      skipped: props.progress?.skipped ?? 0,
      failed: props.progress?.failed ?? 0,
    })
  }
  if (isFailed.value) return t('admin.people.bulk_import.import.progress.failed.description')
  if (isProcessing.value) return t('admin.people.bulk_import.import.progress.processing.description')
  return t('admin.people.bulk_import.import.progress.waiting.description')
})

const progressCardBorderClass = computed(() => {
  if (isProcessing.value) return 'border-primary/40'
  if (isCompleted.value) return 'border-green-200 dark:border-green-900'
  if (isFailed.value) return 'border-destructive/40'
  return ''
})

const displayLogs = computed(() => props.logs.slice(0, 15))

function logIcon(status: BulkImportImportLogStatus) {
  if (status === 'success') return CircleCheck
  if (status === 'warning') return AlertTriangle
  return CircleAlert
}

function logIconClass(status: BulkImportImportLogStatus) {
  if (status === 'success') return 'text-green-600'
  if (status === 'warning') return 'text-amber-600'
  return 'text-destructive'
}
</script>
