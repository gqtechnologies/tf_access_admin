<template>
  <div>
    <Header :items-breadcrumb="itemsBreadcrumb" :title="t('admin.visits.new.title')" />

    <p class="text-muted-foreground mb-6 max-w-3xl text-sm">
      {{ t('admin.visits.new.description') }}
    </p>

    <div class="grid gap-6 xl:grid-cols-[minmax(0,1fr)_320px]">
      <div class="rounded-xl border bg-card">
        <div class="border-b px-4 py-4 sm:px-6">
          <VisitCreateStepper :step-index="stepIndex" />
        </div>

        <div class="space-y-6 px-4 py-6 sm:px-6">
          <VisitCreateGeneralStep
            v-if="currentStep === 'general'"
            v-model:form="form"
            :properties="properties"
            :units="units"
            :hosts="hosts"
            :units-loading="unitsLoading"
            :hosts-loading="hostsLoading"
            :field-errors="fieldErrors"
            @property-change="handlePropertyChange"
            @unit-change="handleUnitChange"
          />

          <VisitCreateVisitorStep
            v-else-if="currentStep === 'visitor'"
            v-model:form="form"
            :field-errors="fieldErrors"
            @visitor-selected="visitorDisplayName = $event"
          />

          <VisitCreateScheduleStep
            v-else-if="currentStep === 'schedule'"
            v-model:form="form"
            :field-errors="fieldErrors"
          />

          <VisitCreateAdditionalStep
            v-else-if="currentStep === 'additional'"
            v-model:form="form"
            :visit-types="visitTypes"
            :field-errors="fieldErrors"
          />

          <VisitCreateConfirmStep
            v-else-if="currentStep === 'confirm'"
            v-model:form="form"
            :field-errors="fieldErrors"
          />
        </div>

        <div class="border-t px-4 py-4 sm:px-6">
          <VisitCreateFooter
            :show-back="stepIndex > 0"
            :show-cancel="stepIndex === 0"
            :primary-label="primaryActionLabel"
            :primary-disabled="false"
            :submitting="submitting"
            @back="handleBack"
            @cancel="handleCancel"
            @primary="handlePrimary"
          />
        </div>
      </div>

      <VisitAuthorizationSummary
        :properties="properties"
        :units="units"
        :hosts="hosts"
        :visit-types="visitTypes"
        :property-id="form.residential_property_id"
        :unit-id="form.unit_id"
        :host-person-id="form.host_person_id"
        :visitor-name="resolvedVisitorName"
        :visit-type="form.visit_type"
        :visit-date="form.visit_date"
        :start-time="form.start_time"
        :end-time="form.end_time"
        :vehicle-plate="form.vehicle.plate"
        :vehicle-brand-model="form.vehicle.brand_model"
        :initial-status-preview="initialStatusPreview"
        :status-loading="statusLoading"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { router } from '@inertiajs/vue3'
import Header from '@/components/admin/layout/Header.vue'
import VisitAuthorizationSummary from '@/components/admin/visits/create/VisitAuthorizationSummary.vue'
import VisitCreateAdditionalStep from '@/components/admin/visits/create/VisitCreateAdditionalStep.vue'
import VisitCreateConfirmStep from '@/components/admin/visits/create/VisitCreateConfirmStep.vue'
import VisitCreateFooter from '@/components/admin/visits/create/VisitCreateFooter.vue'
import VisitCreateGeneralStep from '@/components/admin/visits/create/VisitCreateGeneralStep.vue'
import VisitCreateScheduleStep from '@/components/admin/visits/create/VisitCreateScheduleStep.vue'
import VisitCreateStepper from '@/components/admin/visits/create/VisitCreateStepper.vue'
import VisitCreateVisitorStep from '@/components/admin/visits/create/VisitCreateVisitorStep.vue'
import {
  clearVisitCreateState,
  loadVisitCreateState,
  saveVisitCreateState,
  useAdminVisitCreate,
} from '@/lib/composables/admin/useAdminVisitCreate'
import { useAdminVisitFormData } from '@/lib/composables/admin/useAdminVisitFormData'
import { mapServerErrorsToForm } from '@/lib/forms/map_server_errors'
import { buildDisplayName } from '@/lib/schemas/unit_ownership'
import type { VisitTypeOption } from '@/lib/schemas/visit_create'
import { admin_visits_path } from '@/routes'
import type { PropertySummary } from '@/types/visit'

const props = defineProps<{
  properties: PropertySummary[]
  visit_types: VisitTypeOption[]
  errors?: Record<string, string[]>
}>()

const { t } = useI18n()
const submitting = ref(false)
const clientFieldErrors = ref<Record<string, string | undefined>>({})
const visitorDisplayName = ref('')

const defaultVisitType = props.visit_types[0]?.value ?? 'guest'

const {
  currentStep,
  form,
  stepIndex,
  snapshot,
  restoreSnapshot,
  goNext,
  goBack,
  validateStep,
  buildSubmitPayload,
} = useAdminVisitCreate(defaultVisitType)

const {
  units,
  hosts,
  initialStatusPreview,
  unitsLoading,
  hostsLoading,
  statusLoading,
  fetchUnits,
  fetchHosts,
  fetchInitialStatusPreview,
  refreshLocationData,
} = useAdminVisitFormData()

const itemsBreadcrumb = computed(() => [
  { label: t('admin.sidebar.manage_visits'), href: admin_visits_path() },
  { label: t('admin.visits.new.title') },
])

const visitTypes = computed(() => props.visit_types)
const properties = computed(() => props.properties)

const serverFieldErrors = computed(() =>
  props.errors ? mapVisitCreateServerErrors(props.errors) : {},
)

const fieldErrors = computed(() => ({
  ...serverFieldErrors.value,
  ...clientFieldErrors.value,
}))

const resolvedVisitorName = computed(() => {
  if (form.value.visitor_mode === 'create') {
    return (
      visitorDisplayName.value ||
      buildDisplayName(form.value.visitor.first_name, form.value.visitor.last_name)
    )
  }
  return visitorDisplayName.value
})

const primaryActionLabel = computed(() => {
  if (currentStep.value === 'confirm') {
    return t('admin.visits.new.actions.submit')
  }
  return t('admin.visits.new.actions.continue')
})

async function handlePropertyChange(propertyId: string) {
  await fetchUnits(propertyId)
}

async function handleUnitChange(unitId: string) {
  await Promise.all([fetchHosts(unitId), fetchInitialStatusPreview(unitId)])
}

function handleBack() {
  clientFieldErrors.value = {}
  goBack()
}

function handleCancel() {
  router.visit(admin_visits_path())
}

function handlePrimary() {
  clientFieldErrors.value = {}
  const errors = validateStep(currentStep.value)
  if (Object.keys(errors).length > 0) {
    clientFieldErrors.value = errors
    return
  }

  if (currentStep.value === 'confirm') {
    submit()
    return
  }

  goNext()
}

function submit() {
  submitting.value = true
  saveVisitCreateState(snapshot())

  router.post('/admin/visits', buildSubmitPayload(), {
    preserveScroll: true,
    onFinish: () => {
      submitting.value = false
    },
    onSuccess: () => {
      clearVisitCreateState()
    },
  })
}

function restoreFromServerErrors() {
  const state = loadVisitCreateState()
  if (!state) return

  restoreSnapshot(state)
  currentStep.value = 'confirm'
  refreshLocationData(state.form.residential_property_id, state.form.unit_id)
}

function mapVisitCreateServerErrors(errors: Record<string, string[]>) {
  const mapped = mapServerErrorsToForm(errors)
  ;['document_number', 'first_name', 'last_name', 'phone', 'display_name', 'email'].forEach((key) => {
    if (mapped[key]) {
      mapped[`visitor.${key}`] = mapped[key]
      delete mapped[key]
    }
  })
  return mapped
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
</script>
