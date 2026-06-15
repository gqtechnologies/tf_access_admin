import { computed, ref } from 'vue'
import { buildDisplayName } from '@/lib/schemas/unit_ownership'
import {
  createEmptyOccupancyForm,
  type AddOccupantPersonForm,
  type UnitOccupancyAssignForm,
} from '@/lib/schemas/unit_occupancy'
import type { Person } from '@/types/person'

export const UNIT_ADD_OCCUPANT_STEPS = [
  'choose',
  'search',
  'create',
  'assign',
  'confirm',
  'success',
] as const

export type UnitAddOccupantStep = (typeof UNIT_ADD_OCCUPANT_STEPS)[number]
export type UnitAddOccupantFlow = 'search' | 'create'

export type UnitAddOccupantStepperStep = Exclude<UnitAddOccupantStep, 'success'>

export type UnitAddOccupantDrawerSnapshot = {
  flow: UnitAddOccupantFlow
  currentStep: UnitAddOccupantStep
  selectedPerson: Person | null
  personForm: AddOccupantPersonForm
  occupancyForm: UnitOccupancyAssignForm
}

export type UnitAddOccupantSuccessSummary = {
  personDisplayName: string
  occupancyTypeLabel: string
  unitTitle: string
  canAuthorizeVisits: boolean
  startsAt: string
  endsAt: string | null
}

const DRAWER_STATE_KEY = 'unitAddOccupantDrawerState'
const DRAWER_SUCCESS_KEY = 'unitAddOccupantDrawerSuccess'

const OCCUPANCY_DRAWER_ERROR_KEYS = [
  'occupancy_type',
  'starts_at',
  'ends_at',
  'person_id',
  'base',
  'document_number',
  'email',
  'display_name',
  'first_name',
  'last_name',
  'can_authorize_visits',
  'status',
] as const

export function createEmptyPersonForm(): AddOccupantPersonForm {
  return {
    document_number: '',
    first_name: '',
    last_name: '',
    email: '',
  }
}

export function saveDrawerState(snapshot: UnitAddOccupantDrawerSnapshot) {
  sessionStorage.setItem(DRAWER_STATE_KEY, JSON.stringify(snapshot))
}

export function loadDrawerState(): UnitAddOccupantDrawerSnapshot | null {
  const raw = sessionStorage.getItem(DRAWER_STATE_KEY)
  if (!raw) return null

  try {
    return JSON.parse(raw) as UnitAddOccupantDrawerSnapshot
  } catch {
    return null
  }
}

export function clearDrawerState() {
  sessionStorage.removeItem(DRAWER_STATE_KEY)
}

export function saveSuccessState(summary: UnitAddOccupantSuccessSummary) {
  sessionStorage.setItem(DRAWER_SUCCESS_KEY, JSON.stringify(summary))
}

export function loadSuccessState(): UnitAddOccupantSuccessSummary | null {
  const raw = sessionStorage.getItem(DRAWER_SUCCESS_KEY)
  if (!raw) return null

  try {
    return JSON.parse(raw) as UnitAddOccupantSuccessSummary
  } catch {
    return null
  }
}

export function clearSuccessState() {
  sessionStorage.removeItem(DRAWER_SUCCESS_KEY)
}

export function isOccupancyDrawerError(errors?: Record<string, string[]>) {
  if (!errors || Object.keys(errors).length === 0) return false

  return Object.keys(errors).some((key) =>
    OCCUPANCY_DRAWER_ERROR_KEYS.includes(key as (typeof OCCUPANCY_DRAWER_ERROR_KEYS)[number]),
  )
}

export function personPreviewFromForm(form: AddOccupantPersonForm): Person {
  return {
    id: '',
    display_name: buildDisplayName(form.first_name, form.last_name),
    document_number: form.document_number,
    email: form.email || undefined,
    phone: undefined,
    person_type: 'natural',
    status: 'active',
  }
}

export function resolveVisibleSteps(flow: UnitAddOccupantFlow | null): readonly UnitAddOccupantStepperStep[] {
  if (flow === 'search') return ['choose', 'search', 'assign', 'confirm']
  if (flow === 'create') return ['choose', 'create', 'assign', 'confirm']
  return ['choose']
}

export function resolveBackStep(
  currentStep: UnitAddOccupantStep,
  flow: UnitAddOccupantFlow | null,
): UnitAddOccupantStep | null {
  if (currentStep === 'confirm') return 'assign'
  if (currentStep === 'assign') return flow === 'create' ? 'create' : 'search'
  if (currentStep === 'search' || currentStep === 'create') return 'choose'
  return null
}

export function useUnitAddOccupantDrawer(defaultOccupancyType = 'tenant') {
  const flow = ref<UnitAddOccupantFlow | null>(null)
  const currentStep = ref<UnitAddOccupantStep>('choose')
  const selectedPerson = ref<Person | null>(null)
  const personForm = ref<AddOccupantPersonForm>(createEmptyPersonForm())
  const occupancyForm = ref<UnitOccupancyAssignForm>(createEmptyOccupancyForm(defaultOccupancyType))
  const successSummary = ref<UnitAddOccupantSuccessSummary | null>(null)

  const visibleSteps = computed(() => resolveVisibleSteps(flow.value))

  const stepIndex = computed(() => {
    if (currentStep.value === 'success') return visibleSteps.value.length
    const index = visibleSteps.value.indexOf(currentStep.value as UnitAddOccupantStepperStep)
    return index >= 0 ? index : 0
  })

  function snapshot(): UnitAddOccupantDrawerSnapshot {
    return {
      flow: flow.value!,
      currentStep: currentStep.value,
      selectedPerson: selectedPerson.value,
      personForm: { ...personForm.value },
      occupancyForm: { ...occupancyForm.value },
    }
  }

  function restoreSnapshot(state: UnitAddOccupantDrawerSnapshot) {
    flow.value = state.flow
    currentStep.value = state.currentStep
    selectedPerson.value = state.selectedPerson
    personForm.value = { ...state.personForm }
    occupancyForm.value = { ...state.occupancyForm }
    successSummary.value = null
  }

  function resetDrawer() {
    flow.value = null
    currentStep.value = 'choose'
    selectedPerson.value = null
    personForm.value = createEmptyPersonForm()
    occupancyForm.value = createEmptyOccupancyForm(defaultOccupancyType)
    successSummary.value = null
  }

  function startSearchFlow() {
    flow.value = 'search'
    currentStep.value = 'search'
  }

  function startCreateFlow() {
    flow.value = 'create'
    currentStep.value = 'create'
    selectedPerson.value = null
  }

  function selectPerson(person: Person) {
    selectedPerson.value = person
    currentStep.value = 'assign'
  }

  function clearSelectedPerson() {
    selectedPerson.value = null
    currentStep.value = 'search'
  }

  function goToAssignFromCreate() {
    currentStep.value = 'assign'
  }

  function goToConfirm() {
    currentStep.value = 'confirm'
  }

  function showSuccess(summary: UnitAddOccupantSuccessSummary) {
    successSummary.value = summary
    currentStep.value = 'success'
    clearDrawerState()
    saveSuccessState(summary)
  }

  function restoreSuccess() {
    const summary = loadSuccessState()
    if (!summary) return false

    successSummary.value = summary
    currentStep.value = 'success'
    flow.value = 'search'
    return true
  }

  function goBack() {
    const previous = resolveBackStep(currentStep.value, flow.value)
    if (!previous) return

    currentStep.value = previous
    if (previous === 'choose') {
      flow.value = null
      selectedPerson.value = null
    }
  }

  function buildSubmitPayload() {
    const occupancy = {
      occupancy_type: occupancyForm.value.occupancy_type,
      can_authorize_visits: occupancyForm.value.can_authorize_visits,
      starts_at: occupancyForm.value.starts_at,
      ...(occupancyForm.value.ends_at ? { ends_at: occupancyForm.value.ends_at } : {}),
    }

    if (flow.value === 'search' && selectedPerson.value?.id) {
      return {
        unit_occupancy: {
          person_id: selectedPerson.value.id,
          ...occupancy,
        },
      }
    }

    const person = { ...personForm.value }

    return {
      unit_occupancy: occupancy,
      person: {
        first_name: person.first_name,
        last_name: person.last_name,
        document_number: person.document_number,
        email: person.email || undefined,
        person_type: 'natural',
      },
    }
  }

  function buildSuccessSummary(
    occupancyTypeLabel: string,
    unitTitle: string,
  ): UnitAddOccupantSuccessSummary {
    const personDisplayName =
      flow.value === 'search' && selectedPerson.value
        ? selectedPerson.value.display_name
        : buildDisplayName(personForm.value.first_name, personForm.value.last_name)

    return {
      personDisplayName,
      occupancyTypeLabel,
      unitTitle,
      canAuthorizeVisits: occupancyForm.value.can_authorize_visits,
      startsAt: occupancyForm.value.starts_at,
      endsAt: occupancyForm.value.ends_at || null,
    }
  }

  return {
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
  }
}
