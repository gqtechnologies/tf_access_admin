<template>
  <Drawer v-model:open="open" direction="right">
    <DrawerContent
      class="flex h-full max-h-screen flex-col data-[vaul-drawer-direction=right]:w-full data-[vaul-drawer-direction=right]:sm:max-w-xl"
    >
      <DrawerHeader class="shrink-0 border-b pb-4">
        <div class="flex items-start justify-between gap-4">
          <div>
            <DrawerTitle>{{ t('concierge.parcels.receive.title') }}</DrawerTitle>
            <DrawerDescription>{{ t('concierge.parcels.receive.description') }}</DrawerDescription>
          </div>
          <DrawerClose as-child>
            <Button type="button" variant="ghost" size="icon" :aria-label="t('common.actions.cancel')">
              <X class="size-4" />
            </Button>
          </DrawerClose>
        </div>
      </DrawerHeader>

      <div class="flex-1 space-y-4 overflow-y-auto px-4 py-5">
        <div class="space-y-2">
          <Label for="parcel-unit">{{ t('concierge.parcels.receive.unit') }}</Label>
          <NativeSelect id="parcel-unit" v-model="form.unit_id" class="w-full">
            <NativeSelectOption value="">
              {{ t('concierge.parcels.receive.unit_placeholder') }}
            </NativeSelectOption>
            <NativeSelectOption v-for="unit in units" :key="unit.id" :value="unit.id">
              {{ unit.name }}
            </NativeSelectOption>
          </NativeSelect>
        </div>

        <div class="space-y-2">
          <Label for="parcel-type">{{ t('concierge.parcels.receive.delivery_type') }}</Label>
          <NativeSelect id="parcel-type" v-model="form.delivery_type" class="w-full">
            <NativeSelectOption v-for="type in deliveryTypes" :key="type" :value="type">
              {{ t(`concierge.parcels.delivery_types.${type}`) }}
            </NativeSelectOption>
          </NativeSelect>
        </div>

        <div class="space-y-2">
          <Label for="parcel-courier">{{ t('concierge.parcels.receive.courier_company') }}</Label>
          <Input
            id="parcel-courier"
            v-model="form.courier_company"
            maxlength="120"
            :placeholder="t('concierge.parcels.receive.optional')"
          />
        </div>

        <div class="space-y-2">
          <Label for="parcel-tracking">{{ t('concierge.parcels.receive.tracking_code') }}</Label>
          <Input
            id="parcel-tracking"
            v-model="form.tracking_code"
            maxlength="120"
            :placeholder="t('concierge.parcels.receive.optional')"
          />
        </div>

        <div class="space-y-2">
          <Label for="parcel-notes">{{ t('concierge.parcels.receive.notes') }}</Label>
          <Textarea
            id="parcel-notes"
            v-model="form.notes"
            :maxlength="notesMaxLength"
            rows="3"
            :placeholder="t('concierge.parcels.receive.optional')"
          />
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
          <Button type="button" :disabled="submitting || !canSubmit" @click="confirm">
            <Loader2 v-if="submitting" class="size-4 animate-spin" />
            <Check v-else class="size-4" />
            {{ t('concierge.parcels.receive.confirm') }}
          </Button>
        </div>
      </DrawerFooter>
    </DrawerContent>
  </Drawer>
</template>

<script setup lang="ts">
import { computed, reactive, watch } from 'vue'
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
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { NativeSelect, NativeSelectOption } from '@/components/ui/native-select'
import { Textarea } from '@/components/ui/textarea'
import { useConciergeParcelSubmit } from '@/lib/composables/concierge/useConciergeParcels'
import type { ParcelTab, ParcelUnitOption } from '@/types/parcel'

const props = defineProps<{
  propertyId: string
  tab: ParcelTab
  units: ParcelUnitOption[]
  deliveryTypes: string[]
}>()

const open = defineModel<boolean>('open', { default: false })

const { t } = useI18n()
const notesMaxLength = 500

const form = reactive({
  unit_id: '',
  delivery_type: 'parcel',
  courier_company: '',
  tracking_code: '',
  notes: '',
})

const { submitting, errors, submitReceive } = useConciergeParcelSubmit()

const canSubmit = computed(() => Boolean(form.unit_id && form.delivery_type))

watch(open, (isOpen) => {
  if (!isOpen) return

  form.unit_id = ''
  form.delivery_type = props.deliveryTypes[0] ?? 'parcel'
  form.courier_company = ''
  form.tracking_code = ''
  form.notes = ''
  errors.value = []
})

function confirm() {
  if (!canSubmit.value) return

  submitReceive(
    { propertyId: props.propertyId, tab: props.tab },
    {
      unit_id: form.unit_id,
      delivery_type: form.delivery_type,
      courier_company: form.courier_company.trim() || undefined,
      tracking_code: form.tracking_code.trim() || undefined,
      notes: form.notes.trim() || undefined,
    },
    () => {
      open.value = false
      toast.success(t('concierge.parcels.receive.success'))
    },
  )
}
</script>
