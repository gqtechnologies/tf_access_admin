import { computed, ref } from 'vue'

export const UNIT_ADD_OWNER_STEPS = ['choose', 'search', 'create', 'assign'] as const

export type UnitAddOwnerStep = (typeof UNIT_ADD_OWNER_STEPS)[number]

export function useUnitAddOwnerDrawer() {
  const currentStep = ref<UnitAddOwnerStep>('choose')

  const stepIndex = computed(() => UNIT_ADD_OWNER_STEPS.indexOf(currentStep.value))

  function resetDrawer() {
    currentStep.value = 'choose'
  }

  function goToStep(step: UnitAddOwnerStep) {
    currentStep.value = step
  }

  function goBack() {
    const index = stepIndex.value
    if (index <= 0) return

    currentStep.value = UNIT_ADD_OWNER_STEPS[index - 1]
  }

  return {
    currentStep,
    stepIndex,
    resetDrawer,
    goToStep,
    goBack,
  }
}
