<template>
  <div class="flex w-full items-center justify-between gap-3">
    <div class="flex items-center gap-2">
      <Button v-if="showBack" type="button" variant="outline" @click="emit('back')">
        {{ backLabel ?? t('common.actions.back') }}
      </Button>
      <Button
        v-else-if="showCancel"
        type="button"
        variant="outline"
        @click="emit('cancel')"
      >
        {{ cancelLabel ?? t('admin.units.show.occupants.add_occupant.actions.cancel') }}
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
  showBack?: boolean
  showCancel?: boolean
  backLabel?: string
  cancelLabel?: string
  primaryLabel?: string
  primaryDisabled?: boolean
  submitting?: boolean
}>()

const emit = defineEmits<{
  (e: 'back'): void
  (e: 'cancel'): void
  (e: 'primary'): void
}>()

const { t } = useI18n()
</script>
