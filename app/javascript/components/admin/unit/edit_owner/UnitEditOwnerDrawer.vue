<template>
  <Drawer v-model:open="open" direction="right" @update:open="onOpenChange">
    <DrawerContent
      class="flex h-full max-h-screen flex-col data-[vaul-drawer-direction=right]:w-full data-[vaul-drawer-direction=right]:sm:max-w-2xl"
    >
      <DrawerHeader class="shrink-0 border-b pb-4">
        <div class="flex items-start justify-between gap-4">
          <DrawerTitle class="text-lg font-semibold">
            {{ t('admin.units.show.owners.edit_owner.title') }}
          </DrawerTitle>
          <DrawerClose as-child>
            <Button
              type="button"
              variant="ghost"
              size="icon"
              :aria-label="t('admin.units.show.owners.add_owner.actions.close')"
            >
              <X class="size-4" />
            </Button>
          </DrawerClose>
        </div>
      </DrawerHeader>

      <div v-if="ownership" class="flex-1 space-y-6 overflow-y-auto px-4 py-5">
        <UnitAddOwnerUnitContext :unit="unit" />

        <div class="space-y-6">
          <div class="space-y-1">
            <h3 class="text-base font-semibold">
              {{ t('admin.units.show.owners.edit_owner.assign.title') }}
            </h3>
            <p class="text-sm text-muted-foreground">
              {{ t('admin.units.show.owners.edit_owner.assign.description') }}
            </p>
          </div>

          <div class="space-y-3">
            <div class="space-y-1">
              <h4 class="text-sm font-semibold">
                {{ t('admin.units.show.owners.add_owner.assign.person_section_title') }}
              </h4>
            </div>

            <UnitAddOwnerPersonCard :person="person" :show-change-action="false" />
          </div>

          <UnitAddOwnerOwnershipFields
            v-model:ownership-form="ownershipForm"
            :available-percentage="editableAvailablePercentage"
            :field-errors="fieldErrors"
            id-prefix="edit-owner"
          />
        </div>
      </div>

      <DrawerFooter class="shrink-0 border-t px-4 py-4">
        <UnitAddOwnerDrawerFooter
          :show-cancel="true"
          :primary-label="t('admin.units.show.owners.edit_owner.actions.submit')"
          :submitting="submitting"
          @cancel="closeDrawer"
          @primary="submit"
        />
      </DrawerFooter>
    </DrawerContent>
  </Drawer>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { router } from '@inertiajs/vue3'
import { X } from 'lucide-vue-next'
import UnitAddOwnerDrawerFooter from '@/components/admin/unit/add_owner/UnitAddOwnerDrawerFooter.vue'
import UnitAddOwnerOwnershipFields from '@/components/admin/unit/add_owner/UnitAddOwnerOwnershipFields.vue'
import UnitAddOwnerPersonCard from '@/components/admin/unit/add_owner/UnitAddOwnerPersonCard.vue'
import UnitAddOwnerUnitContext from '@/components/admin/unit/add_owner/UnitAddOwnerUnitContext.vue'
import { Button } from '@/components/ui/button'
import {
  Drawer,
  DrawerClose,
  DrawerContent,
  DrawerFooter,
  DrawerHeader,
  DrawerTitle,
} from '@/components/ui/drawer'
import {
  clearEditDrawerState,
  loadEditDrawerState,
  ownershipToAssignForm,
  saveEditDrawerState,
} from '@/lib/composables/unit/useUnitEditOwnerDrawer'
import { mapServerErrorsToForm } from '@/lib/forms/map_server_errors'
import { adminResidentialPropertyUnitOwnershipPath } from '@/lib/paths/unit_ownerships'
import { unitOwnershipAssignSchema, type UnitOwnershipAssignForm } from '@/lib/schemas/unit_ownership'
import { toPercentageNumber } from '@/lib/utils/unit'
import type { Person } from '@/types/person'
import type { UnitDetail, UnitOwnership } from '@/types/unit'

const props = defineProps<{
  unit: UnitDetail
  ownership: UnitOwnership | null
  errors?: Record<string, string[]>
}>()

const open = defineModel<boolean>('open', { required: true })

const { t } = useI18n()
const submitting = ref(false)
const clientFieldErrors = ref<Record<string, string | undefined>>({})
const ownershipForm = ref<UnitOwnershipAssignForm>({
  ownership_percentage: 50,
  starts_at: '',
  ends_at: '',
})

const serverFieldErrors = computed(() =>
  props.errors ? mapServerErrorsToForm(props.errors) : {},
)

const fieldErrors = computed(() => ({
  ...serverFieldErrors.value,
  ...clientFieldErrors.value,
}))

const person = computed<Person>(() => {
  const ownership = props.ownership
  if (!ownership) {
    return {
      display_name: '',
      person_type: 'natural',
      status: 'active',
    }
  }

  return {
    id: ownership.person_id,
    display_name: ownership.person_display_name,
    document_number: ownership.person_document_number ?? undefined,
    email: ownership.person_email ?? undefined,
    person_type: 'natural',
    status: ownership.status,
  }
})

const editableAvailablePercentage = computed(() => {
  const available = toPercentageNumber(props.unit.ownership_stats.available_percentage)
  if (!props.ownership || props.ownership.status !== 'active') return available

  return available + toPercentageNumber(props.ownership.ownership_percentage)
})

function closeDrawer() {
  open.value = false
}

function onOpenChange(value: boolean) {
  open.value = value
  if (!value) {
    clearEditDrawerState()
    clientFieldErrors.value = {}
  }
}

function initializeForm() {
  if (!props.ownership) return

  ownershipForm.value = ownershipToAssignForm(props.ownership)
}

function validateClientForm() {
  clientFieldErrors.value = {}
  const result = unitOwnershipAssignSchema.safeParse(ownershipForm.value)

  if (result.success) return true

  const errors: Record<string, string | undefined> = {}
  result.error.issues.forEach((issue) => {
    const key = issue.path[0]
    if (typeof key === 'string' && !errors[key]) errors[key] = issue.message
  })
  clientFieldErrors.value = errors
  return false
}

function submit() {
  if (!props.ownership?.id || !validateClientForm()) return

  submitting.value = true
  saveEditDrawerState({
    ownershipId: props.ownership.id,
    ownershipForm: { ...ownershipForm.value },
  })

  const payload = {
    unit_ownership: {
      ownership_percentage: ownershipForm.value.ownership_percentage,
      starts_at: ownershipForm.value.starts_at,
      ...(ownershipForm.value.ends_at ? { ends_at: ownershipForm.value.ends_at } : { ends_at: null }),
    },
  }

  router.patch(
    adminResidentialPropertyUnitOwnershipPath(
      props.unit.residential_property_id,
      props.unit.id,
      props.ownership.id,
    ),
    payload,
    {
      preserveScroll: true,
      onFinish: () => {
        submitting.value = false
      },
      onSuccess: () => {
        clearEditDrawerState()
        closeDrawer()
      },
    },
  )
}

function restoreFromServerErrors() {
  const state = loadEditDrawerState()
  if (!state || !props.ownership || state.ownershipId !== props.ownership.id) return

  ownershipForm.value = { ...state.ownershipForm }
}

watch(
  () => props.ownership,
  () => {
    initializeForm()
  },
  { immediate: true },
)

watch(
  () => props.errors,
  (errors) => {
    if (errors && Object.keys(errors).length > 0) {
      restoreFromServerErrors()
    }
  },
  { immediate: true },
)

watch(open, (isOpen) => {
  if (isOpen) {
    initializeForm()
    const hasServerErrors = props.errors && Object.keys(props.errors).length > 0
    if (hasServerErrors) restoreFromServerErrors()
  }
})
</script>
