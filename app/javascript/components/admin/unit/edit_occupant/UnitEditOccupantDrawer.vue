<template>
  <Drawer v-model:open="open" direction="right" @update:open="onOpenChange">
    <DrawerContent
      class="flex h-full max-h-screen flex-col data-[vaul-drawer-direction=right]:w-full data-[vaul-drawer-direction=right]:sm:max-w-2xl"
    >
      <DrawerHeader class="shrink-0 border-b pb-4">
        <div class="flex items-start justify-between gap-4">
          <DrawerTitle class="text-lg font-semibold">
            {{ t('admin.units.show.occupants.edit_occupant.title') }}
          </DrawerTitle>
          <DrawerClose as-child>
            <Button
              type="button"
              variant="ghost"
              size="icon"
              :aria-label="t('admin.units.show.occupants.add_occupant.actions.close')"
            >
              <X class="size-4" />
            </Button>
          </DrawerClose>
        </div>
      </DrawerHeader>

      <div v-if="occupancy" class="flex-1 space-y-6 overflow-y-auto px-4 py-5">
        <UnitAddOwnerUnitContext :unit="unit" />

        <div class="space-y-6">
          <div class="space-y-1">
            <h3 class="text-base font-semibold">
              {{ t('admin.units.show.occupants.edit_occupant.assign.title') }}
            </h3>
            <p class="text-sm text-muted-foreground">
              {{ t('admin.units.show.occupants.edit_occupant.assign.description') }}
            </p>
          </div>

          <div class="space-y-3">
            <div class="space-y-1">
              <h4 class="text-sm font-semibold">
                {{ t('admin.units.show.occupants.add_occupant.assign.person_section_title') }}
              </h4>
            </div>

            <UnitAddOwnerPersonCard :person="person" :show-change-action="false" />
          </div>

          <UnitAddOccupantOccupancyFields
            v-model:occupancy-form="occupancyForm"
            :occupancy-types="occupancyTypes"
            :field-errors="fieldErrors"
            :show-status="true"
            id-prefix="edit-occupant"
          />

          <FieldError v-if="fieldErrors.base" :errors="translateErrors([fieldErrors.base])" />
        </div>
      </div>

      <DrawerFooter class="shrink-0 border-t px-4 py-4">
        <UnitAddOccupantDrawerFooter
          :show-cancel="true"
          :cancel-label="t('admin.units.show.occupants.add_occupant.actions.cancel')"
          :primary-label="t('admin.units.show.occupants.edit_occupant.actions.submit')"
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
import UnitAddOwnerPersonCard from '@/components/admin/unit/add_owner/UnitAddOwnerPersonCard.vue'
import UnitAddOwnerUnitContext from '@/components/admin/unit/add_owner/UnitAddOwnerUnitContext.vue'
import UnitAddOccupantDrawerFooter from '@/components/admin/unit/add_occupant/UnitAddOccupantDrawerFooter.vue'
import UnitAddOccupantOccupancyFields from '@/components/admin/unit/add_occupant/UnitAddOccupantOccupancyFields.vue'
import { Button } from '@/components/ui/button'
import {
  Drawer,
  DrawerClose,
  DrawerContent,
  DrawerFooter,
  DrawerHeader,
  DrawerTitle,
} from '@/components/ui/drawer'
import { FieldError } from '@/components/ui/field'
import { useTranslateErrors } from '@/lib/composables/i18n/translate_errors'
import {
  clearEditDrawerState,
  loadEditDrawerState,
  occupancyToEditForm,
  saveEditDrawerState,
} from '@/lib/composables/unit/useUnitEditOccupantDrawer'
import { mapServerErrorsToForm } from '@/lib/forms/map_server_errors'
import { adminResidentialPropertyUnitOccupancyPath } from '@/lib/paths/unit_occupancies'
import {
  unitOccupancyEditSchema,
  type UnitOccupancyEditForm,
} from '@/lib/schemas/unit_occupancy'
import type { Person } from '@/types/person'
import type { OccupancyTypeOption, UnitDetail, UnitOccupancy } from '@/types/unit'

const props = defineProps<{
  unit: UnitDetail
  occupancy: UnitOccupancy | null
  occupancyTypes: OccupancyTypeOption[]
  errors?: Record<string, string[]>
}>()

const open = defineModel<boolean>('open', { required: true })

const { t } = useI18n()
const { translateErrors } = useTranslateErrors()
const submitting = ref(false)
const clientFieldErrors = ref<Record<string, string | undefined>>({})
const occupancyForm = ref<UnitOccupancyEditForm>({
  occupancy_type: 'tenant',
  can_authorize_visits: false,
  starts_at: '',
  ends_at: '',
  status: 'active',
})

const serverFieldErrors = computed(() =>
  props.errors ? mapServerErrorsToForm(props.errors) : {},
)

const fieldErrors = computed(() => ({
  ...serverFieldErrors.value,
  ...clientFieldErrors.value,
}))

const person = computed<Person>(() => {
  const occupancy = props.occupancy
  if (!occupancy) {
    return {
      display_name: '',
      person_type: 'natural',
      status: 'active',
    }
  }

  return {
    id: occupancy.person_id,
    display_name: occupancy.person_display_name,
    document_number: occupancy.person_document_number ?? undefined,
    email: occupancy.person_email ?? undefined,
    person_type: 'natural',
    status: occupancy.status,
  }
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
  if (!props.occupancy) return
  occupancyForm.value = occupancyToEditForm(props.occupancy)
}

function validateClientForm() {
  clientFieldErrors.value = {}
  const result = unitOccupancyEditSchema.safeParse(occupancyForm.value)

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
  if (!props.occupancy?.id || !validateClientForm()) return

  submitting.value = true
  saveEditDrawerState({
    occupancyId: props.occupancy.id,
    occupancyForm: { ...occupancyForm.value },
  })

  router.patch(
    adminResidentialPropertyUnitOccupancyPath(
      props.unit.residential_property_id,
      props.unit.id,
      props.occupancy.id,
    ),
    {
      unit_occupancy: {
        occupancy_type: occupancyForm.value.occupancy_type,
        can_authorize_visits: occupancyForm.value.can_authorize_visits,
        status: occupancyForm.value.status,
        starts_at: occupancyForm.value.starts_at,
        ...(occupancyForm.value.ends_at
          ? { ends_at: occupancyForm.value.ends_at }
          : { ends_at: null }),
      },
    },
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
  if (!state || !props.occupancy || state.occupancyId !== props.occupancy.id) return

  occupancyForm.value = { ...state.occupancyForm }
}

watch(
  () => props.occupancy,
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
