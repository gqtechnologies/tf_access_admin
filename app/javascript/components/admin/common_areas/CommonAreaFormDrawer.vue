<template>
  <Drawer v-model:open="open" direction="right">
    <DrawerContent
      class="flex h-full max-h-screen flex-col data-[vaul-drawer-direction=right]:w-full data-[vaul-drawer-direction=right]:sm:max-w-xl"
    >
      <DrawerHeader class="shrink-0 border-b pb-4">
        <div class="flex items-start justify-between gap-4">
          <div>
            <DrawerTitle>
              {{ area ? t('admin.common_areas.form.edit_title') : t('admin.common_areas.form.new_title') }}
            </DrawerTitle>
            <DrawerDescription>{{ t('admin.common_areas.form.description') }}</DrawerDescription>
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
          <Label for="area-name">{{ t('admin.common_areas.form.name') }}</Label>
          <Input id="area-name" v-model="form.name" maxlength="100" />
        </div>

        <div class="grid gap-4 sm:grid-cols-2">
          <div class="space-y-2">
            <Label for="area-type">{{ t('admin.common_areas.form.area_type') }}</Label>
            <NativeSelect id="area-type" v-model="form.area_type" class="w-full">
              <NativeSelectOption v-for="type in areaTypes" :key="type" :value="type">
                {{ t(`admin.common_areas.types.${type}`) }}
              </NativeSelectOption>
            </NativeSelect>
          </div>
          <div class="space-y-2">
            <Label for="area-capacity">{{ t('admin.common_areas.form.capacity') }}</Label>
            <Input id="area-capacity" v-model="form.capacity" type="number" min="1" :placeholder="t('admin.common_areas.form.optional')" />
          </div>
        </div>

        <label for="area-approval" class="flex cursor-pointer items-start justify-between gap-4 rounded-lg border px-4 py-3">
          <span class="space-y-0.5">
            <span class="block text-sm font-medium">{{ t('admin.common_areas.form.requires_approval') }}</span>
            <span class="text-muted-foreground block text-xs">{{ t('admin.common_areas.form.requires_approval_help') }}</span>
          </span>
          <Checkbox
            id="area-approval"
            :model-value="form.requires_approval"
            @update:model-value="(value: boolean | 'indeterminate') => (form.requires_approval = value === true)"
          />
        </label>

        <label v-if="area" for="area-active" class="flex cursor-pointer items-start justify-between gap-4 rounded-lg border px-4 py-3">
          <span class="space-y-0.5">
            <span class="block text-sm font-medium">{{ t('admin.common_areas.form.active') }}</span>
            <span class="text-muted-foreground block text-xs">{{ t('admin.common_areas.form.active_help') }}</span>
          </span>
          <Checkbox
            id="area-active"
            :model-value="form.active"
            @update:model-value="(value: boolean | 'indeterminate') => (form.active = value === true)"
          />
        </label>

        <div class="space-y-3 rounded-lg border px-4 py-4">
          <div>
            <p class="text-sm font-medium">{{ t('admin.common_areas.form.rules_title') }}</p>
            <p class="text-muted-foreground text-xs">{{ t('admin.common_areas.form.rules_help') }}</p>
          </div>
          <div class="grid gap-4 sm:grid-cols-2">
            <div class="space-y-2">
              <Label for="rule-opens">{{ t('admin.common_areas.rules.opens_at') }}</Label>
              <Input id="rule-opens" v-model="form.rules.opens_at" type="time" />
            </div>
            <div class="space-y-2">
              <Label for="rule-closes">{{ t('admin.common_areas.rules.closes_at') }}</Label>
              <Input id="rule-closes" v-model="form.rules.closes_at" type="time" />
            </div>
            <div class="space-y-2">
              <Label for="rule-duration">{{ t('admin.common_areas.rules.max_duration_minutes') }}</Label>
              <Input id="rule-duration" v-model="form.rules.max_duration_minutes" type="number" min="1" />
            </div>
            <div class="space-y-2">
              <Label for="rule-advance">{{ t('admin.common_areas.rules.min_advance_hours') }}</Label>
              <Input id="rule-advance" v-model="form.rules.min_advance_hours" type="number" min="0" />
            </div>
            <div class="space-y-2 sm:col-span-2">
              <Label for="rule-monthly">{{ t('admin.common_areas.rules.max_reservations_per_month') }}</Label>
              <Input id="rule-monthly" v-model="form.rules.max_reservations_per_month" type="number" min="1" />
            </div>
          </div>
          <div class="space-y-2">
            <Label for="rule-notes">{{ t('admin.common_areas.rules.notes') }}</Label>
            <Textarea id="rule-notes" v-model="form.rules.notes" rows="3" />
          </div>
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
          <Button type="button" :disabled="submitting || !form.name.trim()" @click="save">
            <Loader2 v-if="submitting" class="size-4 animate-spin" />
            <Save v-else class="size-4" />
            {{ t('admin.common_areas.form.save') }}
          </Button>
        </div>
      </DrawerFooter>
    </DrawerContent>
  </Drawer>
</template>

<script setup lang="ts">
import { reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { router } from '@inertiajs/vue3'
import { Loader2, Save, X } from 'lucide-vue-next'
import { toast } from 'vue-sonner'
import { Button } from '@/components/ui/button'
import { Checkbox } from '@/components/ui/checkbox'
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
import { admin_common_area_path, admin_common_areas_path } from '@/routes'
import type { AdminCommonArea } from '@/types/common_area'

const props = defineProps<{
  area: AdminCommonArea | null
  propertyId: string
  areaTypes: string[]
}>()

const open = defineModel<boolean>('open', { default: false })

const { t } = useI18n()
const submitting = ref(false)
const errors = ref<string[]>([])

// Inputs hold strings; blank rule values remove the rule on the server.
const form = reactive({
  name: '',
  area_type: 'other',
  capacity: '' as string | number,
  requires_approval: true,
  active: true,
  rules: {
    opens_at: '',
    closes_at: '',
    max_duration_minutes: '' as string | number,
    min_advance_hours: '' as string | number,
    max_reservations_per_month: '' as string | number,
    notes: '',
  },
})

watch(open, (isOpen) => {
  if (!isOpen) return

  const area = props.area
  form.name = area?.name ?? ''
  form.area_type = area?.area_type ?? props.areaTypes[0] ?? 'other'
  form.capacity = area?.capacity ?? ''
  form.requires_approval = area?.requires_approval ?? true
  form.active = area ? area.status === 'active' : true
  form.rules.opens_at = area?.rules.opens_at ?? ''
  form.rules.closes_at = area?.rules.closes_at ?? ''
  form.rules.max_duration_minutes = area?.rules.max_duration_minutes ?? ''
  form.rules.min_advance_hours = area?.rules.min_advance_hours ?? ''
  form.rules.max_reservations_per_month = area?.rules.max_reservations_per_month ?? ''
  form.rules.notes = area?.rules.notes ?? ''
  errors.value = []
})

function save() {
  submitting.value = true
  errors.value = []

  const data = {
    common_area: {
      name: form.name.trim(),
      area_type: form.area_type,
      capacity: form.capacity === '' ? null : form.capacity,
      requires_approval: form.requires_approval,
      ...(props.area ? { status: form.active ? 'active' : 'inactive' } : {}),
      rules: Object.fromEntries(Object.entries(form.rules).map(([key, value]) => [key, String(value ?? '').trim()])),
    },
  }
  const options = {
    preserveScroll: true,
    onSuccess: () => {
      open.value = false
      toast.success(t('admin.common_areas.form.saved'))
    },
    onError: (errs: Record<string, string | string[]>) => {
      errors.value = Object.values(errs).flatMap((value) => (Array.isArray(value) ? value : [value]))
    },
    onFinish: () => {
      submitting.value = false
    },
  }

  if (props.area) {
    router.patch(admin_common_area_path(props.area.id), data, options)
  } else {
    router.post(admin_common_areas_path({ property_id: props.propertyId }), data, options)
  }
}
</script>
