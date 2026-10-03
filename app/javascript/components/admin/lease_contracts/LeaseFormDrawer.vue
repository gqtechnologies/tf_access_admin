<template>
  <Drawer v-model:open="open" direction="right">
    <DrawerContent class="flex h-full max-h-screen flex-col data-[vaul-drawer-direction=right]:w-full data-[vaul-drawer-direction=right]:sm:max-w-xl">
      <DrawerHeader class="shrink-0 border-b pb-4">
        <div class="flex items-start justify-between gap-4">
          <div>
            <DrawerTitle>{{ t('admin.lease_contracts.form.title') }}</DrawerTitle>
            <DrawerDescription>{{ t('admin.lease_contracts.form.description') }}</DrawerDescription>
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
          <Label for="lease-unit">{{ t('admin.lease_contracts.form.unit') }}</Label>
          <NativeSelect id="lease-unit" v-model="form.unit_id" class="w-full">
            <NativeSelectOption value="">{{ t('admin.lease_contracts.form.unit_placeholder') }}</NativeSelectOption>
            <NativeSelectOption v-for="unit in units" :key="unit.id" :value="unit.id">{{ unit.name }}</NativeSelectOption>
          </NativeSelect>
        </div>

        <div class="space-y-3 rounded-lg border px-4 py-4">
          <p class="text-sm font-medium">{{ t('admin.lease_contracts.form.lessee') }}</p>
          <div class="space-y-2">
            <Label for="lessee-name">{{ t('admin.lease_contracts.form.name') }}</Label>
            <Input id="lessee-name" v-model="form.name" />
          </div>
          <div class="space-y-2">
            <Label for="lessee-email">{{ t('admin.lease_contracts.form.email') }}</Label>
            <Input id="lessee-email" v-model="form.email" type="email" />
          </div>
          <div class="grid gap-4 sm:grid-cols-2">
            <div class="space-y-2">
              <Label for="lessee-document">{{ t('admin.lease_contracts.form.document') }}</Label>
              <Input id="lessee-document" v-model="form.document" />
            </div>
            <div class="space-y-2">
              <Label for="lessee-phone">{{ t('admin.lease_contracts.form.phone') }}</Label>
              <Input id="lessee-phone" v-model="form.phone" />
            </div>
          </div>
        </div>

        <div class="space-y-2">
          <Label for="lease-lessor">{{ t('admin.lease_contracts.form.lessor') }}</Label>
          <NativeSelect id="lease-lessor" v-model="form.lessor_person_id" class="w-full" :disabled="!owners.length">
            <NativeSelectOption value="">{{ t('admin.lease_contracts.form.no_lessor') }}</NativeSelectOption>
            <NativeSelectOption v-for="owner in owners" :key="owner.id" :value="owner.id">{{ owner.name }}</NativeSelectOption>
          </NativeSelect>
        </div>

        <div class="grid gap-4 sm:grid-cols-2">
          <div class="space-y-2">
            <Label for="lease-start">{{ t('admin.lease_contracts.form.starts_at') }}</Label>
            <Input id="lease-start" v-model="form.starts_at" type="date" />
          </div>
          <div class="space-y-2">
            <Label for="lease-end">{{ t('admin.lease_contracts.form.ends_at') }}</Label>
            <Input id="lease-end" v-model="form.ends_at" type="date" />
          </div>
        </div>

        <div class="space-y-2 rounded-lg border px-4 py-3">
          <p class="text-sm font-medium">{{ t('admin.lease_contracts.form.permissions') }}</p>
          <label v-for="key in permissionKeys" :key="key" :for="`lease-${key}`" class="flex cursor-pointer items-center justify-between gap-4 py-1">
            <span class="text-sm">{{ t(`admin.lease_contracts.permissions.${key}`) }}</span>
            <Checkbox :id="`lease-${key}`" :model-value="form[key]" @update:model-value="(value: boolean | 'indeterminate') => (form[key] = value === true)" />
          </label>
        </div>

        <div v-if="errors.length" class="rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3">
          <p v-for="error in errors" :key="error" class="text-destructive text-sm">{{ error }}</p>
        </div>
      </div>

      <DrawerFooter class="shrink-0 border-t px-4 py-4">
        <div class="flex w-full justify-end gap-2">
          <Button type="button" variant="outline" :disabled="submitting" @click="open = false">{{ t('common.actions.cancel') }}</Button>
          <Button type="button" :disabled="submitting || !canSubmit" @click="save">
            <Loader2 v-if="submitting" class="size-4 animate-spin" />
            <Save v-else class="size-4" />
            {{ t('admin.lease_contracts.form.save') }}
          </Button>
        </div>
      </DrawerFooter>
    </DrawerContent>
  </Drawer>
</template>

<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { router } from '@inertiajs/vue3'
import { Loader2, Save, X } from 'lucide-vue-next'
import { toast } from 'vue-sonner'
import { Button } from '@/components/ui/button'
import { Checkbox } from '@/components/ui/checkbox'
import { Drawer, DrawerClose, DrawerContent, DrawerDescription, DrawerFooter, DrawerHeader, DrawerTitle } from '@/components/ui/drawer'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { NativeSelect, NativeSelectOption } from '@/components/ui/native-select'
import { admin_lease_contracts_path } from '@/routes'

type UnitOption = { id: string; name: string; owners: { id: string; name: string }[] }
type PermissionKey = 'can_authorize_visits' | 'can_reserve_common_areas' | 'can_withdraw_parcels'

const props = defineProps<{ propertyId: string; units: UnitOption[] }>()
const open = defineModel<boolean>('open', { default: false })

const { t } = useI18n()
const permissionKeys: PermissionKey[] = ['can_authorize_visits', 'can_reserve_common_areas', 'can_withdraw_parcels']
const submitting = ref(false)
const errors = ref<string[]>([])

const form = reactive({
  unit_id: '',
  name: '',
  email: '',
  document: '',
  phone: '',
  lessor_person_id: '',
  starts_at: '',
  ends_at: '',
  can_authorize_visits: true,
  can_reserve_common_areas: true,
  can_withdraw_parcels: true,
})

const owners = computed(() => props.units.find((unit) => unit.id === form.unit_id)?.owners ?? [])
const canSubmit = computed(() => Boolean(form.unit_id && form.name.trim() && form.email.trim() && form.starts_at))

watch(() => form.unit_id, () => (form.lessor_person_id = ''))
watch(open, (isOpen) => {
  if (!isOpen) return
  Object.assign(form, {
    unit_id: '', name: '', email: '', document: '', phone: '', lessor_person_id: '',
    starts_at: new Date().toISOString().slice(0, 10), ends_at: '',
    can_authorize_visits: true, can_reserve_common_areas: true, can_withdraw_parcels: true,
  })
  errors.value = []
})

function save() {
  if (!canSubmit.value) return
  submitting.value = true
  errors.value = []

  router.post(
    admin_lease_contracts_path({ property_id: props.propertyId }),
    {
      lessee: { name: form.name.trim(), email: form.email.trim(), document: form.document.trim() || undefined, phone: form.phone.trim() || undefined },
      lease: {
        unit_id: form.unit_id,
        lessor_person_id: form.lessor_person_id || undefined,
        starts_at: form.starts_at,
        ends_at: form.ends_at || undefined,
        can_authorize_visits: form.can_authorize_visits,
        can_reserve_common_areas: form.can_reserve_common_areas,
        can_withdraw_parcels: form.can_withdraw_parcels,
      },
    },
    {
      preserveScroll: true,
      onSuccess: (page) => {
        const base = (page.props.errors as Record<string, string | string[]> | undefined)?.base
        if (base) {
          errors.value = Array.isArray(base) ? base : [base]
          return
        }
        open.value = false
        toast.success(t('admin.lease_contracts.form.saved'))
      },
      onError: (errs) => {
        errors.value = Object.values(errs as Record<string, string | string[]>).flatMap((value) => (Array.isArray(value) ? value : [value]))
      },
      onFinish: () => {
        submitting.value = false
      },
    },
  )
}
</script>
