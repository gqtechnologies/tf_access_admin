<template>
  <Drawer v-model:open="open" direction="right" @update:open="onOpenChange">
    <DrawerContent
      class="flex h-full max-h-screen flex-col data-[vaul-drawer-direction=right]:w-full data-[vaul-drawer-direction=right]:sm:max-w-2xl"
    >
      <DrawerHeader class="shrink-0 border-b pb-4">
        <div class="flex items-start justify-between gap-4">
          <DrawerTitle class="text-lg font-semibold">
            {{ t('admin.units.show.occupants.add_occupant.title') }}
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
        <UnitAddOccupantStepper
          v-if="currentStep !== 'success'"
          :step-index="stepIndex"
          :visible-steps="visibleSteps"
        />
      </DrawerHeader>

      <div class="flex-1 space-y-6 overflow-y-auto px-4 py-5">
        <UnitAddOwnerUnitContext :unit="unit" />

        <UnitAddOccupantChooseStep
          v-if="currentStep === 'choose'"
          @select-search="startSearchFlow"
          @select-create="startCreateFlow"
        />

        <UnitAddOccupantSearchStep
          v-else-if="currentStep === 'search'"
          @select-person="handleSelectPerson"
          @create-person="startCreateFlow"
        />

        <UnitAddOccupantCreateStep
          v-else-if="currentStep === 'create'"
          v-model:person-form="personForm"
          :field-errors="fieldErrors"
        />

        <UnitAddOccupantAssignStep
          v-else-if="currentStep === 'assign' && assignPerson"
          v-model:occupancy-form="occupancyForm"
          :person="assignPerson"
          :occupancy-types="occupancyTypes"
          :active-elsewhere="activeElsewhere"
          :show-change-person="flow === 'search'"
          :field-errors="fieldErrors"
          @change-person="clearSelectedPerson"
        />

        <UnitAddOccupantConfirmStep
          v-else-if="currentStep === 'confirm'"
          :person-display-name="confirmPersonDisplayName"
          :person-document="confirmPersonDocument"
          :unit-title="unit.title"
          :occupancy-form="occupancyForm"
          :occupancy-types="occupancyTypes"
          :active-elsewhere="activeElsewhere"
        />

        <UnitAddOccupantSuccessStep
          v-else-if="currentStep === 'success' && successSummary"
          :summary="successSummary"
        />
      </div>

      <DrawerFooter class="shrink-0 border-t px-4 py-4">
        <UnitAddOccupantDrawerFooter
          :show-back="showBack"
          :show-cancel="showCancel"
          :cancel-label="cancelLabel"
          :primary-label="primaryActionLabel"
          :primary-disabled="!canProceed"
          :submitting="submitting"
          @back="goBack"
          @cancel="closeDrawer"
          @primary="handlePrimary"
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
import UnitAddOwnerUnitContext from '@/components/admin/unit/add_owner/UnitAddOwnerUnitContext.vue'
import UnitAddOccupantAssignStep from '@/components/admin/unit/add_occupant/UnitAddOccupantAssignStep.vue'
import UnitAddOccupantChooseStep from '@/components/admin/unit/add_occupant/UnitAddOccupantChooseStep.vue'
import UnitAddOccupantConfirmStep from '@/components/admin/unit/add_occupant/UnitAddOccupantConfirmStep.vue'
import UnitAddOccupantCreateStep from '@/components/admin/unit/add_occupant/UnitAddOccupantCreateStep.vue'
import UnitAddOccupantDrawerFooter from '@/components/admin/unit/add_occupant/UnitAddOccupantDrawerFooter.vue'
import UnitAddOccupantSearchStep from '@/components/admin/unit/add_occupant/UnitAddOccupantSearchStep.vue'
import UnitAddOccupantStepper from '@/components/admin/unit/add_occupant/UnitAddOccupantStepper.vue'
import UnitAddOccupantSuccessStep from '@/components/admin/unit/add_occupant/UnitAddOccupantSuccessStep.vue'
import { Button } from '@/components/ui/button'
import {
  Drawer,
  DrawerClose,
  DrawerContent,
  DrawerFooter,
  DrawerHeader,
  DrawerTitle,
} from '@/components/ui/drawer'
import { useUnitAddOccupantActiveElsewhere } from '@/lib/composables/unit/useUnitAddOccupantActiveElsewhere'
import {
  clearDrawerState,
  clearSuccessState,
  loadDrawerState,
  personPreviewFromForm,
  saveDrawerState,
  useUnitAddOccupantDrawer,
} from '@/lib/composables/unit/useUnitAddOccupantDrawer'
import { mapServerErrorsToForm } from '@/lib/forms/map_server_errors'
import { adminResidentialPropertyUnitOccupanciesPath } from '@/lib/paths/unit_occupancies'
import {
  addOccupantPersonSchema,
  unitOccupancyAssignSchema,
} from '@/lib/schemas/unit_occupancy'
import type { OccupancyTypeOption, UnitDetail } from '@/types/unit'
import type { Person } from '@/types/person'

const props = defineProps<{
  unit: UnitDetail
  occupancyTypes: OccupancyTypeOption[]
  errors?: Record<string, string[]>
}>()

const open = defineModel<boolean>('open', { required: true })

const { t } = useI18n()
const submitting = ref(false)
const clientFieldErrors = ref<Record<string, string | undefined>>({})

const defaultOccupancyType = props.occupancyTypes[0]?.value ?? 'tenant'

const {
  flow,
  currentStep,
  visibleSteps,
  stepIndex,
  selectedPerson,
  personForm,
  occupancyForm,
  successSummary,
  snapshot,
  restoreSnapshot,
  resetDrawer,
  startSearchFlow,
  startCreateFlow,
  selectPerson,
  clearSelectedPerson,
  goToAssignFromCreate,
  goToConfirm,
  showSuccess,
  restoreSuccess,
  goBack,
  buildSubmitPayload,
  buildSuccessSummary,
} = useUnitAddOccupantDrawer(defaultOccupancyType)

const { occupancies: activeElsewhere, fetchForPerson, reset: resetActiveElsewhere } =
  useUnitAddOccupantActiveElsewhere()

const serverFieldErrors = computed(() =>
  props.errors ? mapServerErrorsToForm(props.errors) : {},
)

const fieldErrors = computed(() => ({
  ...serverFieldErrors.value,
  ...clientFieldErrors.value,
}))

const assignPerson = computed<Person | null>(() => {
  if (flow.value === 'search') return selectedPerson.value
  if (flow.value === 'create') return personPreviewFromForm(personForm.value)
  return null
})

const confirmPersonDisplayName = computed(() => assignPerson.value?.display_name ?? '')
const confirmPersonDocument = computed(() => assignPerson.value?.document_number)

const showBack = computed(
  () => currentStep.value !== 'choose' && currentStep.value !== 'success',
)
const showCancel = computed(
  () => currentStep.value === 'choose' || currentStep.value === 'success',
)

const cancelLabel = computed(() => {
  if (currentStep.value === 'success') {
    return t('admin.units.show.occupants.add_occupant.actions.close')
  }
  return undefined
})

const primaryActionLabel = computed(() => {
  if (currentStep.value === 'create') {
    return t('admin.units.show.occupants.add_occupant.create.actions.continue')
  }
  if (currentStep.value === 'assign') {
    return t('admin.units.show.occupants.add_occupant.assign.actions.continue')
  }
  if (currentStep.value === 'confirm') {
    return t('admin.units.show.occupants.add_occupant.confirm.actions.submit')
  }
  if (currentStep.value === 'success') {
    return t('admin.units.show.occupants.add_occupant.success.actions.view_occupants')
  }
  return undefined
})

const canProceed = computed(() => {
  if (currentStep.value === 'create') return true
  if (currentStep.value === 'assign') {
    return flow.value === 'create' || !!selectedPerson.value?.id
  }
  if (currentStep.value === 'confirm') return true
  if (currentStep.value === 'success') return true
  return false
})

async function handleSelectPerson(person: Person) {
  selectPerson(person)
  if (person.id) {
    await fetchForPerson(props.unit.residential_property_id, props.unit.id, person.id)
  }
}

async function handlePrimary() {
  if (currentStep.value === 'create') {
    if (!validatePersonForm()) return
    goToAssignFromCreate()
    return
  }

  if (currentStep.value === 'assign') {
    if (!validateOccupancyForm()) return
    goToConfirm()
    return
  }

  if (currentStep.value === 'confirm') {
    submit()
    return
  }

  if (currentStep.value === 'success') {
    closeDrawer()
  }
}

function validatePersonForm() {
  clientFieldErrors.value = {}
  const result = addOccupantPersonSchema.safeParse(personForm.value)
  if (result.success) return true

  const errors: Record<string, string | undefined> = {}
  result.error.issues.forEach((issue) => {
    const key = issue.path[0]
    if (typeof key === 'string' && !errors[key]) errors[key] = issue.message
  })
  clientFieldErrors.value = errors
  return false
}

function validateOccupancyForm() {
  clientFieldErrors.value = {}
  const result = unitOccupancyAssignSchema.safeParse(occupancyForm.value)
  if (!result.success) {
    const errors: Record<string, string | undefined> = {}
    result.error.issues.forEach((issue) => {
      const key = issue.path[0]
      if (typeof key === 'string' && !errors[key]) errors[key] = issue.message
    })
    clientFieldErrors.value = errors
    return false
  }
  return true
}

function submit() {
  if (!validateOccupancyForm()) return
  if (flow.value === 'search' && !selectedPerson.value?.id) return

  submitting.value = true
  saveDrawerState(snapshot())

  const occupancyTypeLabel =
    props.occupancyTypes.find((option) => option.value === occupancyForm.value.occupancy_type)
      ?.label ?? occupancyForm.value.occupancy_type

  router.post(
    adminResidentialPropertyUnitOccupanciesPath(props.unit.residential_property_id, props.unit.id),
    buildSubmitPayload(),
    {
      preserveScroll: true,
      onFinish: () => {
        submitting.value = false
      },
      onSuccess: () => {
        showSuccess(buildSuccessSummary(occupancyTypeLabel, props.unit.title))
      },
    },
  )
}

function closeDrawer() {
  open.value = false
}

function onOpenChange(value: boolean) {
  open.value = value
  if (!value) {
    resetDrawer()
    resetActiveElsewhere()
    clearDrawerState()
    clearSuccessState()
    clientFieldErrors.value = {}
  }
}

function restoreFromServerErrors() {
  const state = loadDrawerState()
  if (!state?.flow) return

  restoreSnapshot(state)
  if (state.selectedPerson?.id) {
    fetchForPerson(props.unit.residential_property_id, props.unit.id, state.selectedPerson.id)
  }
}

watch(
  () => props.errors,
  (errors) => {
    if (errors && Object.keys(errors).length > 0) {
      restoreFromServerErrors()
    }
  },
  { immediate: true },
)

watch(open, (isOpen, wasOpen) => {
  if (isOpen && !wasOpen) {
    const hasServerErrors = props.errors && Object.keys(props.errors).length > 0
    if (hasServerErrors) {
      restoreFromServerErrors()
      return
    }

    if (restoreSuccess()) return

    resetDrawer()
    resetActiveElsewhere()
  }
})
</script>
