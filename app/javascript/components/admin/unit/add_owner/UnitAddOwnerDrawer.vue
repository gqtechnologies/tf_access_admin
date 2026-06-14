<template>
  <Drawer v-model:open="open" direction="right" @update:open="onOpenChange">
    <DrawerContent
      class="flex h-full max-h-screen flex-col data-[vaul-drawer-direction=right]:w-full data-[vaul-drawer-direction=right]:sm:max-w-2xl"
    >
      <DrawerHeader class="shrink-0 border-b pb-4">
        <div class="flex items-start justify-between gap-4">
          <DrawerTitle class="text-lg font-semibold">
            {{ t('admin.units.show.owners.add_owner.title') }}
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
        <UnitAddOwnerStepper :step-index="stepIndex" :visible-steps="visibleSteps" />
      </DrawerHeader>

      <div class="flex-1 space-y-6 overflow-y-auto px-4 py-5">
        <UnitAddOwnerUnitContext :unit="unit" />

        <UnitAddOwnerChooseStep
          v-if="currentStep === 'choose'"
          @select-search="startSearchFlow"
          @select-create="startCreateFlow"
        />

        <UnitAddOwnerSearchStep
          v-else-if="currentStep === 'search'"
          @select-person="selectPerson"
          @create-person="startCreateFlow"
        />

        <UnitAddOwnerCreateStep
          v-else-if="currentStep === 'create'"
          v-model:person-form="personForm"
          v-model:ownership-form="ownershipForm"
          :available-percentage="unit.ownership_stats.available_percentage"
          :field-errors="fieldErrors"
        />

        <UnitAddOwnerAssignStep
          v-else-if="currentStep === 'assign' && selectedPerson"
          v-model:ownership-form="ownershipForm"
          :person="selectedPerson"
          :available-percentage="unit.ownership_stats.available_percentage"
          :field-errors="fieldErrors"
          @change-person="clearSelectedPerson"
        />
      </div>

      <DrawerFooter class="shrink-0 border-t px-4 py-4">
        <UnitAddOwnerDrawerFooter
          :show-cancel="true"
          :primary-label="primaryActionLabel"
          :primary-disabled="!canSubmit"
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
import UnitAddOwnerAssignStep from '@/components/admin/unit/add_owner/UnitAddOwnerAssignStep.vue'
import UnitAddOwnerChooseStep from '@/components/admin/unit/add_owner/UnitAddOwnerChooseStep.vue'
import UnitAddOwnerCreateStep from '@/components/admin/unit/add_owner/UnitAddOwnerCreateStep.vue'
import UnitAddOwnerDrawerFooter from '@/components/admin/unit/add_owner/UnitAddOwnerDrawerFooter.vue'
import UnitAddOwnerSearchStep from '@/components/admin/unit/add_owner/UnitAddOwnerSearchStep.vue'
import UnitAddOwnerStepper from '@/components/admin/unit/add_owner/UnitAddOwnerStepper.vue'
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
  clearDrawerState,
  loadDrawerState,
  saveDrawerState,
  useUnitAddOwnerDrawer,
} from '@/lib/composables/unit/useUnitAddOwnerDrawer'
import { mapServerErrorsToForm } from '@/lib/forms/map_server_errors'
import { adminResidentialPropertyUnitOwnershipsPath } from '@/lib/paths/unit_ownerships'
import {
  addOwnerPersonSchema,
  unitOwnershipAssignSchema,
} from '@/lib/schemas/unit_ownership'
import type { UnitDetail } from '@/types/unit'

const props = defineProps<{
  unit: UnitDetail
  errors?: Record<string, string[]>
}>()

const open = defineModel<boolean>('open', { required: true })

const { t } = useI18n()
const submitting = ref(false)
const clientFieldErrors = ref<Record<string, string | undefined>>({})

const {
  flow,
  currentStep,
  visibleSteps,
  stepIndex,
  selectedPerson,
  personForm,
  ownershipForm,
  snapshot,
  restoreSnapshot,
  resetDrawer,
  startSearchFlow,
  startCreateFlow,
  selectPerson,
  clearSelectedPerson,
  buildSubmitPayload,
} = useUnitAddOwnerDrawer()

const serverFieldErrors = computed(() =>
  props.errors ? mapServerErrorsToForm(props.errors) : {},
)

const fieldErrors = computed(() => ({
  ...serverFieldErrors.value,
  ...clientFieldErrors.value,
}))

const primaryActionLabel = computed(() => {
  if (currentStep.value === 'create') {
    return t('admin.units.show.owners.add_owner.create.actions.submit')
  }
  if (currentStep.value === 'assign') {
    return t('admin.units.show.owners.add_owner.assign.actions.submit')
  }
  return undefined
})

const canSubmit = computed(() => {
  if (currentStep.value === 'create') return true
  if (currentStep.value === 'assign') return !!selectedPerson.value?.id
  return false
})

function closeDrawer() {
  open.value = false
}

function onOpenChange(value: boolean) {
  open.value = value
  if (!value) {
    resetDrawer()
    clearDrawerState()
    clientFieldErrors.value = {}
  }
}

function validateClientForm() {
  clientFieldErrors.value = {}
  const errors: Record<string, string | undefined> = {}

  const ownershipResult = unitOwnershipAssignSchema.safeParse(ownershipForm.value)
  if (!ownershipResult.success) {
    ownershipResult.error.issues.forEach((issue) => {
      const key = issue.path[0]
      if (typeof key === 'string' && !errors[key]) errors[key] = issue.message
    })
  }

  if (flow.value === 'create') {
    const personResult = addOwnerPersonSchema.safeParse(personForm.value)
    if (!personResult.success) {
      personResult.error.issues.forEach((issue) => {
        const key = issue.path[0]
        if (typeof key === 'string' && !errors[key]) errors[key] = issue.message
      })
    }
  }

  clientFieldErrors.value = errors
  return Object.keys(errors).length === 0
}

function submit() {
  if (!validateClientForm()) return
  if (flow.value === 'search' && !selectedPerson.value?.id) return

  submitting.value = true
  saveDrawerState(snapshot())

  router.post(
    adminResidentialPropertyUnitOwnershipsPath(props.unit.residential_property_id, props.unit.id),
    buildSubmitPayload(),
    {
      preserveScroll: true,
      onFinish: () => {
        submitting.value = false
      },
      onSuccess: () => {
        clearDrawerState()
        closeDrawer()
      },
    },
  )
}

function restoreFromServerErrors() {
  const state = loadDrawerState()
  if (!state?.flow) return

  restoreSnapshot(state)
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
    } else {
      resetDrawer()
    }
  }
})
</script>
