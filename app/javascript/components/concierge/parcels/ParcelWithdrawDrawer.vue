<template>
  <Drawer v-model:open="open" direction="right">
    <DrawerContent
      class="flex h-full max-h-screen flex-col data-[vaul-drawer-direction=right]:w-full data-[vaul-drawer-direction=right]:sm:max-w-xl"
    >
      <DrawerHeader class="shrink-0 border-b pb-4">
        <div class="flex items-start justify-between gap-4">
          <div>
            <DrawerTitle>{{ t('concierge.parcels.withdraw.title') }}</DrawerTitle>
            <DrawerDescription>{{ t('concierge.parcels.withdraw.description') }}</DrawerDescription>
          </div>
          <DrawerClose as-child>
            <Button type="button" variant="ghost" size="icon" :aria-label="t('common.actions.cancel')">
              <X class="size-4" />
            </Button>
          </DrawerClose>
        </div>
      </DrawerHeader>

      <div v-if="parcel" class="flex-1 space-y-5 overflow-y-auto px-4 py-5">
        <div class="rounded-lg border px-4 py-3">
          <p class="font-medium">{{ parcel.unit.name }}</p>
          <p class="text-muted-foreground text-sm">
            {{ t(`concierge.parcels.delivery_types.${parcel.delivery_type}`) }}
            <template v-if="courierLine"> · {{ courierLine }}</template>
          </p>
          <p v-if="parcel.notes" class="text-muted-foreground mt-1 text-sm italic">{{ parcel.notes }}</p>
        </div>

        <div v-if="parcel.eligible_withdrawers.length" class="space-y-3">
          <Label>{{ t('concierge.parcels.withdraw.who') }}</Label>
          <RadioGroup v-model="personId" class="gap-2">
            <label
              v-for="person in parcel.eligible_withdrawers"
              :key="person.id"
              :for="`withdrawer-${person.id}`"
              class="flex cursor-pointer items-center gap-3 rounded-lg border px-4 py-3"
            >
              <RadioGroupItem :id="`withdrawer-${person.id}`" :value="person.id" />
              <span class="text-sm font-medium">{{ person.name }}</span>
            </label>
          </RadioGroup>
        </div>

        <div
          v-else
          class="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900"
        >
          {{ t('concierge.parcels.withdraw.none') }}
        </div>

        <div v-if="errors.length" class="rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3">
          <p v-for="error in errors" :key="error" class="text-destructive text-sm">{{ error }}</p>
        </div>
      </div>

      <DrawerFooter class="shrink-0 border-t px-4 py-4">
        <div class="flex w-full justify-end gap-2">
          <Button type="button" variant="outline" :disabled="submitting" @click="open = false">
            {{ t('common.actions.cancel') }}
          </Button>
          <Button type="button" :disabled="submitting || !personId" @click="confirm">
            <Loader2 v-if="submitting" class="size-4 animate-spin" />
            <Check v-else class="size-4" />
            {{ t('concierge.parcels.withdraw.confirm') }}
          </Button>
        </div>
      </DrawerFooter>
    </DrawerContent>
  </Drawer>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { Check, Loader2, X } from 'lucide-vue-next'
import { toast } from 'vue-sonner'
import { Button } from '@/components/ui/button'
import {
  Drawer,
  DrawerClose,
  DrawerContent,
  DrawerDescription,
  DrawerFooter,
  DrawerHeader,
  DrawerTitle,
} from '@/components/ui/drawer'
import { Label } from '@/components/ui/label'
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group'
import { useConciergeParcelSubmit } from '@/lib/composables/concierge/useConciergeParcels'
import type { ConciergeParcel, ParcelTab } from '@/types/parcel'

const props = defineProps<{
  parcel: ConciergeParcel | null
  tab: ParcelTab
}>()

const open = defineModel<boolean>('open', { default: false })

const { t } = useI18n()
const personId = ref('')

const { submitting, errors, submitWithdraw } = useConciergeParcelSubmit()

const courierLine = computed(() =>
  [props.parcel?.courier_company, props.parcel?.tracking_code].filter(Boolean).join(' · '),
)

watch(open, (isOpen) => {
  if (!isOpen) return

  // A single permitted resident is the common case: preselect them.
  const withdrawers = props.parcel?.eligible_withdrawers ?? []
  personId.value = withdrawers.length === 1 ? withdrawers[0].id : ''
  errors.value = []
})

function confirm() {
  if (!props.parcel || !personId.value) return

  submitWithdraw(props.parcel, { personId: personId.value, tab: props.tab }, () => {
    open.value = false
    toast.success(t('concierge.parcels.withdraw.success'))
  })
}
</script>
