import { computed, ref } from 'vue'
import {
  todayIsoDate,
  type AddOwnerPersonForm,
  type UnitOwnershipAssignForm,
} from '@/lib/schemas/unit_ownership'
import type { Person } from '@/types/person'

export const UNIT_ADD_OWNER_STEPS = ['choose', 'search', 'create', 'assign'] as const

export type UnitAddOwnerStep = (typeof UNIT_ADD_OWNER_STEPS)[number]
export type UnitAddOwnerFlow = 'search' | 'create'

export type UnitAddOwnerDrawerSnapshot = {
  flow: UnitAddOwnerFlow
  currentStep: UnitAddOwnerStep
  selectedPerson: Person | null
  personForm: AddOwnerPersonForm
  ownershipForm: UnitOwnershipAssignForm
}

const DRAWER_STATE_KEY = 'unitAddOwnerDrawerState'

export function createEmptyPersonForm(): AddOwnerPersonForm {
  return {
    document_number: '',
    first_name: '',
    last_name: '',
    email: '',
  }
}

export function createEmptyOwnershipForm(): UnitOwnershipAssignForm {
  return {
    ownership_percentage: 50,
    starts_at: todayIsoDate(),
    ends_at: '',
  }
}

export function saveDrawerState(snapshot: UnitAddOwnerDrawerSnapshot) {
  sessionStorage.setItem(DRAWER_STATE_KEY, JSON.stringify(snapshot))
}

export function loadDrawerState(): UnitAddOwnerDrawerSnapshot | null {
  const raw = sessionStorage.getItem(DRAWER_STATE_KEY)
  if (!raw) return null

  try {
    return JSON.parse(raw) as UnitAddOwnerDrawerSnapshot
  } catch {
    return null
  }
}

export function clearDrawerState() {
  sessionStorage.removeItem(DRAWER_STATE_KEY)
}

export function isOwnershipDrawerError(errors?: Record<string, string[]>) {
  if (!errors || Object.keys(errors).length === 0) return false

  const keys = Object.keys(errors)
  return keys.some((key) =>
    ['ownership_percentage', 'starts_at', 'ends_at', 'person_id', 'base', 'document_number', 'email', 'display_name'].includes(key),
  )
}

export function useUnitAddOwnerDrawer() {
  const flow = ref<UnitAddOwnerFlow | null>(null)
  const currentStep = ref<UnitAddOwnerStep>('choose')
  const selectedPerson = ref<Person | null>(null)
  const personForm = ref<AddOwnerPersonForm>(createEmptyPersonForm())
  const ownershipForm = ref<UnitOwnershipAssignForm>(createEmptyOwnershipForm())

  const visibleSteps = computed(() => {
    if (flow.value === 'search') return ['choose', 'search', 'assign'] as const
    if (flow.value === 'create') return ['choose', 'create'] as const
    return ['choose'] as const
  })

  const stepIndex = computed(() => {
    const index = visibleSteps.value.indexOf(currentStep.value as (typeof visibleSteps.value)[number])
    return index >= 0 ? index : 0
  })

  function snapshot(): UnitAddOwnerDrawerSnapshot {
    return {
      flow: flow.value!,
      currentStep: currentStep.value,
      selectedPerson: selectedPerson.value,
      personForm: { ...personForm.value },
      ownershipForm: { ...ownershipForm.value },
    }
  }

  function restoreSnapshot(state: UnitAddOwnerDrawerSnapshot) {
    flow.value = state.flow
    currentStep.value = state.currentStep
    selectedPerson.value = state.selectedPerson
    personForm.value = { ...state.personForm }
    ownershipForm.value = { ...state.ownershipForm }
  }

  function resetDrawer() {
    flow.value = null
    currentStep.value = 'choose'
    selectedPerson.value = null
    personForm.value = createEmptyPersonForm()
    ownershipForm.value = createEmptyOwnershipForm()
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

  function goBack() {
    if (currentStep.value === 'assign') {
      currentStep.value = 'search'
      return
    }

    if (currentStep.value === 'search' || currentStep.value === 'create') {
      currentStep.value = 'choose'
      flow.value = null
      selectedPerson.value = null
    }
  }

  function buildSubmitPayload() {
    const ownership = {
      ownership_percentage: ownershipForm.value.ownership_percentage,
      starts_at: ownershipForm.value.starts_at,
      ...(ownershipForm.value.ends_at ? { ends_at: ownershipForm.value.ends_at } : {}),
    }

    if (flow.value === 'search' && selectedPerson.value?.id) {
      return {
        unit_ownership: {
          person_id: selectedPerson.value.id,
          ...ownership,
        },
      }
    }

    const person = { ...personForm.value }

    return {
      unit_ownership: ownership,
      person: {
        first_name: person.first_name,
        last_name: person.last_name,
        document_number: person.document_number,
        email: person.email || undefined,
        person_type: 'natural',
      },
    }
  }

  return {
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
    goBack,
    buildSubmitPayload,
  }
}
