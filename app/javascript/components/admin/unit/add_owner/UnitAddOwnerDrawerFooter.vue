<template>
  <div class="flex w-full items-center justify-between gap-3">
    <div class="flex items-center gap-2">
      <Button
        v-if="showCancel"
        type="button"
        variant="outline"
        @click="emit('cancel')"
      >
        {{ t('admin.units.show.owners.add_owner.actions.cancel') }}
      </Button>
    </div>

    <div class="flex items-center gap-2">
      <Button
        v-if="primaryLabel"
        type="button"
        :disabled="primaryDisabled || submitting"
        @click="emit('primary')"
      >
        {{ primaryLabel }}
      </Button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { Button } from '@/components/ui/button'

defineProps<{
  showCancel?: boolean
  primaryLabel?: string
  primaryDisabled?: boolean
  submitting?: boolean
}>()

const emit = defineEmits<{
  (e: 'cancel'): void
  (e: 'primary'): void
}>()

const { t } = useI18n()
</script>
