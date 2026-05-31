<script setup lang="ts">
import type { DateValue } from '@internationalized/date'
import {
  DateFormatter,
  getLocalTimeZone,
  parseDate,
} from '@internationalized/date'
import { CalendarIcon } from 'lucide-vue-next'
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { Button } from '@/components/ui/button'
import { Calendar } from '@/components/ui/calendar'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { cn } from '@/lib/utils'

const props = withDefaults(
  defineProps<{
    modelValue?: string
    id?: string
    placeholder?: string
    class?: string
    'aria-invalid'?: boolean | string
  }>(),
  {
    modelValue: undefined,
    placeholder: undefined,
  },
)

const emit = defineEmits<{
  (e: 'update:modelValue', value: string | undefined): void
}>()

const { locale } = useI18n()

const df = computed(
  () =>
    new DateFormatter(locale.value, {
      dateStyle: 'long',
    }),
)

const calendarValue = computed<DateValue | undefined>({
  get() {
    if (!props.modelValue) return undefined

    try {
      return parseDate(props.modelValue)
    } catch {
      return undefined
    }
  },
  set(value) {
    emit('update:modelValue', value ? value.toString() : undefined)
  },
})

const displayLabel = computed(() => {
  if (!calendarValue.value) return props.placeholder ?? 'Pick a date'

  return df.value.format(calendarValue.value.toDate(getLocalTimeZone()))
})
</script>

<template>
  <Popover>
    <PopoverTrigger as-child>
      <Button
        :id="props.id"
        type="button"
        variant="outline"
        :aria-invalid="props['aria-invalid']"
        :class="cn(
          'w-full justify-start text-left font-normal',
          !calendarValue && 'text-muted-foreground',
          props.class,
        )"
      >
        <CalendarIcon class="mr-2 h-4 w-4" />
        {{ displayLabel }}
      </Button>
    </PopoverTrigger>
    <PopoverContent class="w-auto p-0">
      <Calendar v-model="calendarValue" initial-focus />
    </PopoverContent>
  </Popover>
</template>
